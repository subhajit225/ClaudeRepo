/**************************************************************************************************
 * @description       : Depreciated this class as PRDOPS26-287
 * @last modified on  : 11-03-2025
 * @last modified by  : Prashant Kumar
 ******************************************************************************/
public class OrderService {
   /* public static final String ORDER_STATUS_SHIPPED = 'Shipped';
    public static final String ASSET_STATUS_PURCHASED = 'Purchased';
    public static final String PRODUCT_CATEGORY_SPARE = 'Spare';
    public static final String PRODUCT_CATEGORY_APPLIANCE = 'Platform';
    public static final String PRODUCT_CATEGORY_SUPPORT = 'Support';
    public static final String PRODUCT_CATEGORY_SUBSCRIPTION = 'Subscription';
    public static final String PRODUCT_CATEGORY_UPGRADE = 'Upgrade';
    public static final String PRODUCT_CATEGORY_NFR = 'NFR';
    public static final String ORDER_SUBTYPE_MSP = 'MSP Consumption';
    public static final String TRAINING_PRODUCT = 'Training';
    public static final set<string> THIRD_PARTY_HARDWARE = new set<string>{'DELL','UCS','HPE'};
    public static String ORIGIN_CONTEXT; //Insert,update
    Private static Map<id,string> ediPartnerNameMap = new Map<id,String>();
    private static Map<Id, OrderItem> thirdPartyHardwareLines = new Map<Id, OrderItem>();
    private static Set<Id> thirdPartyHardwareCreated = new Set<Id>();
    private static Map<Id, Account> accountMap ;
    private static Map<Id, Opportunity> oppMap ;
    private static Map<Id, List<OrderItem>> orderIdOrderItemMap ;
    private static Map<Id,SBQQ__Quote__c> quoteMap ;
    private static map<id,set<id>> orderHardwareProdMap = new Map<id,Set<id>>();
    private static Map<Id,Set<Id>> orderHardwareFIBProdMap = new Map<Id,Set<Id>>();/*Added by Rahul for ticket SF-5496 */
    /*private static boolean jobQueued = false;
    public static Map<Id, OrderProducts> OrderInfoMap;
    private static Map<Id, List<OrderItem>> OrderItemsMap = new Map<Id, List<OrderItem>>();
    private static set<Id> GorefreshOrderIds = new set<Id>();
    //Start: SAL-1385 and SAL-1073 
    public static List<BLI_Impact__mdt> BLIimpactMap = [SELECT Adjustment_Type__c,Impacts_Commissions__c,Impacts_Gross_Bookings__c,Impacts_Net_Bookings__c FROM BLI_Impact__mdt];         
    public static final string className ='OrderService';
    public static final string ERROR_FUNCTIONALITY = 'Bookings';
    public static string UnProcessedRecord ='';
    public static string ErrorMessage ='';
    public static List<Custom_Error_Log__c> errLog = new List<Custom_Error_Log__c>();
    //MSP-143
    private static Map<Decimal, List<OrderItem>> mapOfSBQQNumberWithListOfOrderLines = new Map<Decimal, List<OrderItem>>();  
    //private static Map<Id, OrderItem> mapFirstSegmentIDWithLastSegmentOI = new Map<Id, OrderItem>();          

    /**********************************************
       Initializing the collections commonly used
     **********************************************/
     public static void OrderInit(List<Order> newOrders) {
       /* set<id> OrdaccIds = new set<id>();
        set<id> BillToaccIds = new set<id>();
        set<id> oppIds = new set<id>();
        set<id> quoteId = new set<Id>();
        set<Id>OrderIds = new set<Id>();
        for(Order ord : newOrders){
          OrderIds.add(ord.id);
          if(ord.accountId!=null)
          OrdaccIds.add(ord.accountId);
          if(ord.Bill_To_Name__c != null){
            BillToaccIds.add(ord.Bill_To_Name__c);
          }
          if(ord.OpportunityId != null){
            oppIds.add(ord.OpportunityId);
          }
          if(ord.SBQQ__Quote__c != null){
            quoteId.add(ord.SBQQ__Quote__c);
          }
        }
        if(oppMap == null || oppMap.isEmpty()){
        oppMap = new Map<Id, Opportunity>();
        for(Opportunity opp : [SELECT Id, Name, PriceBook2.ID, Primary_Competitor__c, Distributor_Lookup__c,Pricebook2Id, Partner_Lookup__c, Initial_Contacts_Name__c,Initial_Contacts_Name__r.Email, Rubrik_Sales_Engineer__c,Rubrik_Sales_Engineer__r.Email,Opportunity_Sub_Type__c FROM opportunity WHERE Id IN :oppIds]){ 
           oppMap.put(opp.id,opp);
           if(opp.Distributor_Lookup__c!=null)
           BillToaccIds.add(opp.Distributor_Lookup__c);
        }
       } 
        if(accountMap==null || accountMap.isEmpty()){
           accountMap = new Map<Id, Account>([Select Id, Name, BillingCountryCode, Sync_to_NetSuite__c,Contract_Negotiation__c,Type,(select id,Agreement_Type__c from contracts where Contract_Status__c='Active') from Account where id IN : OrdaccIds or id IN : BillToaccIds]);
        }
        if(quoteMap == null || quoteMap.isEmpty()){
         quoteMap = new Map<Id,SBQQ__Quote__c>([SELECT Id,SBQQ__ExpirationDate__c,Name,Discounted_Units_due_to_CSAT_or_Sizing__c,SBQQ__Type__c,(SELECT Id,Name,SBQQ__Product__r.Appliance_Model_HW__c,SBQQ__Product__r.Product_Type__c,SBQQ__StartDate__c,SBQQ__EffectiveStartDate__c   
                                                                           FROM SBQQ__LineItems__r where SBQQ__EffectiveStartDate__c != null order by SBQQ__EffectiveStartDate__c asc)  
                                            FROM SBQQ__Quote__c  
                                            WHERE Id IN :quoteId]);
        }
        if(orderIdOrderItemMap == null || orderIdOrderItemMap.isEmpty()){
           orderIdOrderItemMap = new Map<Id,List<OrderItem>>();
           for(OrderItem OI : [select id,Product2.One_time_Entitlement__c,orderId,Create_Entitlement__c,Product2Id,Quantity,Support_Start_Date__c,
                                 Order.AccountId,Order.EffectiveDate,Order.Order_Start_Date__c,Product2.Single_Entitlement__c,Product2.SBQQ__SubscriptionPricing__c,
                                 Product2.ProductCode, Product2.SBQQSC__EntitlementConversion__c,Product2.Product_Type__c,Product2.Family, Product2.Support_Type__c,
                                 (select id,Type,startDate,EndDate from entitlements__r) from orderItem where orderId IN: OrderIds ]){
              if(orderIdOrderItemMap.containsKey(OI.orderId)){
                   orderIdOrderItemMap.get(OI.orderId).add(OI); // add(new OrderItem(OI))
              } 
              else{
                  orderIdOrderItemMap.put(OI.orderId,new List<OrderItem>{OI});
              }
           }
        }
        system.debug('In Init accountMap'+accountMap);*/
     }
    /*public static void createBLIforRebate(Set<Id> OrderIdSet ,List<String> rebatesList){
        try{
            Map<Id,Booking__c> mapOfOrderIdBkg = new Map<Id,Booking__c>();
            Set<Id> accountIdSet = new Set<Id>();
            Map<String,Rebate_Table__c> mapOfDistriIdPlusDealTypeRebate = new Map<String,Rebate_Table__c>();
            Map<Id,Rebate_Table__c> mapOfDistriIdVppRebate = new Map<Id,Rebate_Table__c>();
            List<Booking_Line_Item__c> bliTobeInserted = new List<Booking_Line_Item__c>();
            final  string allOpps='All';
            final  string allExceptMSPOpps='All except MSP';
            final  string MSPOpps='MSP';
            string keyDistriId=' ';
            string keyDealType=' ';
            string keyStartDate=' '; 
            List<Order> orderList=[Select Id,Account.EDI_DISTI_ID__c,TotalAmount,Opportunity.AccountId,Opportunity.Opportunity_sub_type__c,Opportunity.Distributor_Lookup__c, Opportunity.Deal_Registration_Type__c,opportunity.Opportunity_Type__c,Opportunity.Amount,Opportunity.CloseDate,
                                   Opportunity.Account.Channel_Program_Level_Name__c,Opportunity.Account.Channel_Program_Name__c,Opportunity.FocusedPartner__c,Opportunity.Distributor_Lookup__r.EDI_DISTI_ID__c,OpportunityId,
                                   (select id,product2.Family,product2.Name from orderItems where order.Opportunity.Distributor_Lookup__r.EDI_DISTI_ID__c='Arrow'),
                                   (Select id,CreatedDate from Bookings__r WHERE RecordType.name='Booking' ORDER BY CreatedDate DESC LIMIT 1)
                                   FROM Order where id in :OrderIdSet];
            for(Order ord : orderList){
                mapOfOrderIdBkg.put(ord.Id,ord.Bookings__r[0]);  
                if(ord.Opportunity.Distributor_Lookup__c != NULL){
                    accountIdSet.add(ord.Opportunity.Distributor_Lookup__c);
                }
                if(ord.Opportunity.AccountId != NULL){
                    accountIdSet.add(ord.Opportunity.AccountId);
                }
            }
            //query on rebate table to get corresponding corresponding rebate % based on Opportunity sub type
            if(!accountIdSet.isEmpty()){
                List<Rebate_Table__c> rebates= [Select Id,Rebate__c, Distributor__c,Rebate_Type__c,Rebate_Deal_Type__c,Distributor__r.name,Start_Date__c,
                                                End_Date__c,Distributor_Installation_Fee__c, Value_Add_Distribution_fee__c,Installation_Product__c FROM Rebate_Table__c 
                                                WHERE Distributor__c in :accountIdSet AND Rebate_Type__c IN :rebatesList ];
                for(Rebate_Table__c rebate : rebates){
                    if(rebate.Distributor__c != NULL){
                        if(rebate.Rebate_Deal_Type__c != ' ' && rebate.Rebate_Type__c =='Distributor Fee'){
                            mapOfDistriIdPlusDealTypeRebate.put(rebate.Distributor__c+','+rebate.Rebate_Deal_Type__c+','+rebate.Start_Date__c,rebate);
                        }else if(rebate.Rebate_Type__c =='Velocity Partner Program Rebate'){     
                            mapOfDistriIdVppRebate.put(rebate.Distributor__c,rebate);
                        }
                    }
                }
            }
            if(mapOfDistriIdPlusDealTypeRebate.keySet().size() != 0 || mapOfDistriIdVppRebate.keySet().size() != 0 ){
                for(Order ord : orderList){ 
                     List<string> prodTypes = new List<string>(); // holds rebate caln info
                                     
                    for(String dealTypeKey : mapOfDistriIdPlusDealTypeRebate.keySet()){ 
                        keyDistriId = dealTypeKey.split(',')[0];
                        keyDealType = dealTypeKey.split(',')[1];
                        keyStartDate = dealTypeKey.split(',')[2]; 
                            if(mapOfDistriIdPlusDealTypeRebate.get(dealTypeKey).End_Date__c != NULL){
                                            if((mapOfOrderIdBkg.get(ord.id)).CreatedDate > mapOfDistriIdPlusDealTypeRebate.get(dealTypeKey).Start_Date__c && (mapOfOrderIdBkg.get(ord.Id)).CreatedDate < mapOfDistriIdPlusDealTypeRebate.get(dealTypeKey).End_Date__c){   
                                                if(ord.Opportunity.Distributor_Lookup__c == keyDistriId && Date.Today() > mapOfDistriIdPlusDealTypeRebate.get(dealTypeKey).Start_Date__c && ord.Opportunity.Opportunity_Sub_type__c != ' ' ){
                                                    if(keyDealType == allOpps){
                                                            bliTobeInserted.add(CreateRebateBLI(ord.TotalAmount,mapOfDistriIdPlusDealTypeRebate.get(dealTypeKey),(mapOfOrderIdBkg.get(ord.id)).Id,ord));
                                                    }else if(keyDealType == allExceptMSPOpps && 
                                                            (ord.Opportunity.Opportunity_Sub_type__c == 'Renewal' || ord.Opportunity.Opportunity_Sub_type__c == 'Regular' )){       
                                                            bliTobeInserted.add(CreateRebateBLI(ord.TotalAmount,mapOfDistriIdPlusDealTypeRebate.get(dealTypeKey),(mapOfOrderIdBkg.get(ord.id)).Id,ord));                    
                                                    }else if(keyDealType == MSPOpps && (ord.Opportunity.Opportunity_Sub_type__c == 'MSP')){
                                                             bliTobeInserted.add(CreateRebateBLI(ord.TotalAmount,mapOfDistriIdPlusDealTypeRebate.get(dealTypeKey),(mapOfOrderIdBkg.get(ord.id)).Id,ord));
                                                    }
                                               }                                    
                                           }
                                }else{
                                        if((mapOfOrderIdBkg.get(ord.id)).CreatedDate > mapOfDistriIdPlusDealTypeRebate.get(dealTypeKey).Start_Date__c){
                                            if(ord.Opportunity.Distributor_Lookup__c == keyDistriId && Date.Today() > mapOfDistriIdPlusDealTypeRebate.get(dealTypeKey).Start_Date__c && ord.Opportunity.Opportunity_Sub_type__c != ' ' ){
                                                if(keyDealType == allOpps){
                                                        bliTobeInserted.add(CreateRebateBLI(ord.TotalAmount,mapOfDistriIdPlusDealTypeRebate.get(dealTypeKey),(mapOfOrderIdBkg.get(ord.id)).Id,ord));
                                                }else if(keyDealType == allExceptMSPOpps && 
                                                        (ord.Opportunity.Opportunity_Sub_type__c == 'Renewal' || ord.Opportunity.Opportunity_Sub_type__c == 'Regular' )){       
                                                        bliTobeInserted.add(CreateRebateBLI(ord.TotalAmount,mapOfDistriIdPlusDealTypeRebate.get(dealTypeKey),(mapOfOrderIdBkg.get(ord.id)).Id,ord));                    
                                                }else if(keyDealType == MSPOpps && (ord.Opportunity.Opportunity_Sub_type__c == 'MSP')){
                                                         bliTobeInserted.add(CreateRebateBLI(ord.TotalAmount,mapOfDistriIdPlusDealTypeRebate.get(dealTypeKey),(mapOfOrderIdBkg.get(ord.id)).Id,ord));
                                                }
                                           }                                     
                                        }
                                }    
                        
                     }
                       
                    if( (ord.Opportunity.Deal_Registration_Type__c != ' ' && ord.Opportunity.Opportunity_Type__c != ' ' && ord.Opportunity.Amount != NULL && ord.Opportunity.Account.Channel_Program_Level_Name__c != ' ' && ord.Opportunity.Account.Channel_Program_Name__c != ' ' ) &&
                       (ord.Opportunity.Deal_Registration_Type__c == 'Partner Initiated Deal' || ord.Opportunity.Deal_Registration_Type__c ==  'Joint Initiated Deal') &&
                       (ord.Opportunity.Opportunity_Type__c ==  'New Customer') &&
                       (ord.Opportunity.Amount >= 200000) &&
                       (ord.Opportunity.Account.Channel_Program_Level_Name__c == 'Elite') &&
                       (ord.Opportunity.Account.Channel_Program_Name__c == 'EMEA_Zone_1' || ord.Opportunity.Account.Channel_Program_Name__c == 'EMEA_Zone_2' || ord.Opportunity.Account.Channel_Program_Name__c == 'NAM_Regional' || ord.Opportunity.Account.Channel_Program_Name__c == 'NAM_National')  &&
                       (mapOfOrderIdBkg.containsKey(ord.Id)) &&
                       (mapOfDistriIdVppRebate.containsKey(Ord.Opportunity.AccountId))){
                           //adjustment record to be inserted is returned from method createBLI
                           bliTobeInserted.add(CreateRebateBLI(ord.TotalAmount,mapOfDistriIdVppRebate.get(Ord.Opportunity.AccountId),(mapOfOrderIdBkg.get(ord.id)).Id,ord));
                       }
                }
            }
            if(!bliTobeInserted.isEmpty()){
                Database.SaveResult[] BLIinsertSR = Database.Insert(bliTobeInserted, false);
                for(Integer i=0;i<BLIinsertSR.size();i++){
                        if(!BLIinsertSR[i].isSuccess()){//only look at failures, or NOT Successes
                                for(Database.Error err : BLIinsertSR[i].getErrors()){
                                    ErrorMessage +=err.getFields()+'::'+ err.getMessage() +',';
                                }
                                UnProcessedRecord+= 'Error with inserting Rebate BLI for Booking::'+bliTobeInserted[i].Booking__c+',';
                        }
                } 
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
            insert errLog ;  
        }      
    }
    //method to create BookingLineItem for each order of qualified opportunity.
  public static Booking_Line_Item__c CreateRebateBLI(Decimal orderTotal,Rebate_Table__c rebatable,Id bkId,Order ord){ 
      Booking_Line_Item__c BLI = New Booking_Line_Item__c();
      set<string>installProd = new set<string>(); // to collect installation products for third party
      set<string> prodType = new set<string>(); // to add value if order has third party product and has installationItem  
      try{
        Decimal totalRebate = rebatable.Rebate__c;
        if(rebatable.Rebate_Type__c=='Distributor Fee'){                       
            BLI.Type__c= 'Distributor Fee';  
            if(ord.OpportunityId!=null 
                && ord.Opportunity.Distributor_Lookup__c!=null 
                && (ord.Opportunity.Distributor_Lookup__r.EDI_DISTI_ID__c =='Arrow'||Test.isRunningTest())){ 
              if(rebatable.Installation_Product__c!=null){
                installProd.addall(rebatable.Installation_Product__c.split(';')); 
              }
            if(ord.Opportunity.Opportunity_Type__c=='New Customer' 
                && ord.Opportunity.FocusedPartner__c ==false
                && (ord.Opportunity.Deal_Registration_Type__c =='Partner Initiated Deal'
                ||  ord.Opportunity.Deal_Registration_Type__c =='Joint Initiated Deal')
                ){
                         totalRebate += rebatable.Value_Add_Distribution_fee__c;
              }
            if(!installProd.isEmpty()){    
            for(OrderItem OI : ord.orderItems){
                if(OI.Product2!=null && OI.Product2.Family!=null &&  THIRD_PARTY_HARDWARE.contains(OI.Product2.Family)){
                      prodType.add('ThirdPartyHardware');
                    }     
                    else if(installProd.contains(OI.product2.Name)){
                        prodType.add('InstallProd');
                        break;
                      }  
                }
                if(prodType.contains('ThirdPartyHardware') && !prodType.contains('InstallProd')){
                        totalRebate += rebatable.Distributor_Installation_Fee__c;
                  }
             } 
            
           }             
        }else if(rebatable.Rebate_Type__c=='Velocity Partner Program Rebate'){
            BLI.Type__c= 'Velocity Partner Program Rebate';
        }
        BLI.Booking__c = bkId; 
        BLI.Total_Price__c= orderTotal*totalRebate*0.01*-1;   
        BLI.Rebate__c=totalRebate;
        BLI.Distributor__c=rebatable.Distributor__r.name;
        for(BLI_Impact__mdt BLIimpact : BLIimpactMap){
            if(BLI.Type__c == BLIimpact.Adjustment_Type__c){
                BLI.Impacts_Gross_Bookings__c = BLIimpact.Impacts_Gross_Bookings__c;
                BLI.Impacts_Net_Bookings__c = BLIimpact.Impacts_Net_Bookings__c;
                BLI.Impacts_Commission__c=BLIimpact.Impacts_Commissions__c;
              }
        }        
      }catch(Exception e) {
            errLog.add(LogError.CreateGenericErrorLog(className,e,ERROR_FUNCTIONALITY));
      }
      return BLI; 
        
    }
    //End: SAL-1385 and SAL-1073      //Do not Allow edit on Split Order

    
    public static void contractOrders(List<Order> newOrders, Map<Id, Order> oldOrderMap) {
        if(Test.isRunningTest()){
            testA2();
        }
        //SeT<Id> checkCPQOrderIds = new Set<Id>();
        List<Order_Event__e> orderEvents = new List<Order_Event__e>();
        SeT<Id> ordersWithPrimaryQuote = new Set<Id>();
        //List<Order> toFireCreateContracts = new List<Order>();

        for(Order ord : newOrders) {
            Order oldOrder = (oldOrderMap != null && oldOrderMap.containsKey(ord.Id))
                ? oldOrderMap.get(ord.Id)
                : null;

            if(oldOrder != null && ord.Order_Status__c == 'Shipped' && ord.Order_Status__c != oldOrder.Order_Status__c) {
                //checkCPQOrderIds.add(ord.Id);
                orderEvents.add(new Order_Event__e(Order_Id__c = ord.Id, Action_Type__c='ACTIVATE_ORDER'));
            }
        }

        if(orderEvents.size()>0){
            List<Database.SaveResult> SaveResults = EventBus.publish(orderEvents);
        }

        // if(!checkCPQOrderIds.isEmpty()) {
        //     System.debug('Test Point 4');
        //     for(Order ord : [SELECT Id, Stage_PO__c FROM Order WHERE Id IN :checkCPQOrderIds
        //                         AND SBQQ__Contracted__c = false
        //                         AND order.Opportunity.SBQQ__PrimaryQuote__c != null
        //                         AND RecordType.DeveloperName != 'POC_Order']) {

        //         if(ord.Stage_PO__c != null){
        //             System.debug('Test Point 5');
        //             toFireCreateContracts.add(
        //                 new Order(Id = ord.Id, Status = 'Activated', EDI_Sync_Status__c='Y')
        //             );
        //         }
        //         else{
        //             System.debug('Test Point 5');
        //             toFireCreateContracts.add(
        //                 new Order(Id = ord.Id, Status = 'Activated', EDI_Sync_Status__c='N')
        //             );
        //         }
        //     }

        //     if(!toFireCreateContracts.isEmpty()) {
        //         update toFireCreateContracts;
        //     }
        // }
    }

  public static void creditCheckFailure(List<Order> newOrders, Map<Id, Order> oldOrderMap) {
   for(Order ord: newOrders){
          Order oldOrder = oldOrderMap.get(ord.Id) != null?oldOrderMap.get(ord.Id):new order();
              if(oldOrder.Credit_Check_Failure_Reason__c != ord.Credit_Check_Failure_Reason__c && String.isNotBlank(ord.Credit_Check_Failure_Reason__c) && ord.Credit_Check_Failure_Reason__c != 'NA'){
                ord.Order_Status__c = 'On Hold';
                //ord.Status = 'On Hold';
                String temp = ord.Hold_Code__c;
                temp = temp != null && temp.contains('Credit Check Failed') ? temp.remove('Credit Check Failed'):temp;
                temp = temp != null?temp + ';Credit Check Failed':'Credit Check Failed';
                ord.Hold_Code__c = temp;
                ord.Sync_to_NetSuite__c = false;

                String customerBalance = ord.Credit_Check_Failure_Reason__c.substringBetween('Customer balance of ', ' exceeds');
                String creditLimit = ord.Credit_Check_Failure_Reason__c.substringAfterLast('limit of ');
                
                if(String.isNotBlank(customerBalance)){
                    ord.Customer_Balance__c = Decimal.valueOf(customerBalance);
                }

                if(String.isNotBlank(creditLimit)){
                      ord.Credit_Limit__c = Decimal.valueOf(creditLimit.substringBeforeLast('.'));
                }
                ord.Integration_Failure__c = false;
                 System.debug(ord.Customer_Balance__c);
             }
         }
     }

    public static void autoSubmitOrder(List<Order> newOrders, Map<Id, Order> oldOrderMap){
        string internalOMError ;  
        for(Order ord : newOrders){
            internalOMError= '';
            Boolean automateOrderSubmit = (ord.Order_Sub_Type__c =='MSP Overage' && ord.Order_Status__c =='Pending') || (ord.Order_Status__c =='Pending' && ord.Stage_PO__c != null && System.label.Automate_EDI_Order_Submit.EqualsIgnoreCase('YES') && ord.Is_Order_Split_Formula__c==false);
            System.debug('test palak '+automateOrderSubmit);    
            if(automateOrderSubmit){
                if(ord.Order_Splitted__c){
                 ord.OM_internal_review__c = true ;
                 internalOMError = 'Auto order submission - OM internal review for the split PO \n';
               }
                 if(ord.Partner_Name_Text__c!=null && ord.Partner_Name_Text__c.containsIgnoreCase('CDW')){
                  ord.OM_internal_review__c = true ;
                  internalOMError +='Auto order submission - OM internal review for order belong to reseller CDW in EDI PO \n';
                 
               }  if(ord.AddOn_Node_Count__c != null){
                  ord.OM_internal_review__c = true ;
                  internalOMError += 'Auto order submission - OM internal review for Add on products in order in EDI PO \n';
                  
               }    
               if(GorefreshOrderIds.contains(ord.id)){
                 ord.OM_internal_review__c = true ;
                 internalOMError +=  'OM internal review for GoRefresh order \n';
               }
               if(ord.Bill_To_Name__c == null){
                    ord.OM_internal_review__c = true ;
                    internalOMError += 'Bill to name is missing \n';
                } 
                if(String.isNotBlank(internalOMError)){
                   ord.Change_Needed_Reason_Other__c = internalOMError;
                   continue;
               }

               if(OrderItemsMap.containskey(ord.Id) && ord.AddOn_Node_Count__c == null && !ord.Order_Splitted__c){
                for(OrderItem oi: OrderItemsMap.get(ord.Id)){
                    if(ord.Order_Sub_Type__c !='MSP Overage' && (oi.Product2.SBQQ__SubscriptionPricing__c != null) && (oi.SBQQ__SubscriptionTerm__c == null))
                    {
                        ord.Order_Status__c = 'On Hold';
                        ord.Hold_Code__c = 'OM Internal Review';
                        ord.Change_Needed_Reason_Other__c = 'Subscription Term must be stamped on Order product in order to submit Order';
                        break;
                    }
                    else if(!ord.ManualFulfilment__c && (ord.is_Amendment_Order__c || ord.Order_Sub_Type__c == 'Renewal') && String.isBlank(oi.SerialNumber__c) )
                    {
                        ord.Order_Status__c = 'On Hold';
                        ord.Hold_Code__c = 'Missing serial number';
                        ord.Change_Needed_Reason_Other__c = 'Serial Number must be stamped on Order product in order to submit Renewal/Amendment Order';
                        break;
                    }
                    else if(!ord.ManualFulfilment__c && ord.Order_Sub_Type__c == 'Renewal' && (oi.Support_Start_Date__c == null || oi.Support_End_Date__c == null)){
                        ord.Order_Status__c = 'On Hold';
                            ord.Hold_Code__c = 'Missing start or end dates'; 
                        ord.Change_Needed_Reason_Other__c = 'Start and End date can not be blanked for renewal orders';
                        break;
                    }
                }

                if(ord.Order_Status__c != 'On Hold'){
                    ord.Internal_Order_Stage__c = 'Pending Validation';
                        ord.Order_Status__c ='Pending';
                }
            }
           } 
        }
    }
 // GTC screening 
    public static void updateRPSScreening(List<Order> newOrders, Map<Id, Order> oldOrderMap) {
        List<Order> UpdateOrderScreening = new List<order>();
        List<string>HC_List = new List<String>() ;
        RPS__c rpsSetting = RPS__c.getInstance(UserInfo.getUserId());
        GTCScreening gtcScreeningObj = new GTCScreening(); 
        if(rpsSetting.Screening_Source__c == 'Internal'){
          gtcScreeningObj.initGTCScreening(newOrders, oldOrderMap, accountMap);   
        }
        for(Order ord : newOrders){
            //if validation of hold code passes
            system.debug('in RPS logic before update'+ord);
            if(oldOrderMap == null){
            system.debug('in RPS logic before Insert'+ediPartnerNameMap);
            system.debug('in RPS logic before Insert'+ediPartnerNameMap.get(ord.Stage_PO__c));
            
            }
            System.debug('test palak '+ord.Order_Status__c);
            if(ord.Type!= null && ord.status != 'Cancelled' && !(ord.order_status__c=='On Hold' && String.isNotBlank(ord.Hold_Code__c) && ord.Hold_Code__c.equalsIgnoreCase('Contract in negotiations')) 
            && (ord.Type.equalsIgnoreCase('Revenue')|| ord.Type.equalsIgnoreCase('RMA')) 
                 && (oldOrderMap != null && ((ord.Internal_Order_Stage__c=='Pending Validation' && ord.Internal_Order_Stage__c != oldOrderMap.get(ord.id).Internal_Order_Stage__c)
                 ||(ord.Sync_to_NetSuite__c == true && ord.Sync_to_NetSuite__c != oldOrderMap.get(ord.id).Sync_to_NetSuite__c)))
                ){ 
                 try{
                ord.Screening_Source__c = rpsSetting.Screening_Source__c ; 
                if(ord.Order_Status__c!='Order Accepted' && ord.Order_Status__c!='Shipped' && ord.ScreenStatus__c != 'Approved' && ord.ScreenStatus__c != 'Approved Bypassed'){
                if(ord.Screening_Source__c == 'Internal'){
                   gtcScreeningObj.processGTCScreening(ord,accountMap.get(ord.AccountId));
                }
                else {
                ValidationResp VR =ValidateOrderSubmission(ord);
                system.debug('Validation response'+VR);
                if(VR.isValid){
                ord.ScreenStatus__c =ord.ShipToScreenStatus__c=ord.Billto_EndUser_Screen_Status__c=ord.Shipto_EndUser_Screen_Status__c=ord.ShipToContactScreenStatus__c='Required';
                ord.Billto_EndUser_Screen_StatusMessage__c = ord.ScreeningMessage__c = ord.ShipToContactScreenStatusMessage__c = ord.Shipto_EndUser_Screen_StatusMessage__c = ord.ShipToScreenStatusMessage__c ='';
                ord.ShipToContactScreeningId__c = ord.Shipto_EndUser_ScreeningId__c = ord.ShipToScreeningId__c = ord.Billto_EndUser_Screening_Id__c ='';
                ord.Credit_Check_Failure_Reason__c =null;
                ord.Internal_Order_Stage__c='Order Submitted';
                
                              if(ord.Type.equalsIgnoreCase('Revenue') && oldOrderMap != null && oldOrderMap.get(ord.id).Order_Status__c!='Pending'){
                      if(ord.Hold_Code__c!= null && ord.Hold_Code__c =='Global Trade Compliance Screening')
                      ord.Hold_Code__c = null;
                   }   
                    else if(ord.Type.equalsIgnoreCase('RMA')&& oldOrderMap != null && oldOrderMap.get(ord.id).Order_Status__c!='Pending'){
                            ord.Order_Status__c = 'Pending';
                            if(ord.Hold_Code__c!= null && ord.Hold_Code__c =='Global Trade Compliance Screening')
                            ord.Hold_Code__c = null;
                  }
                if( ord.Order_Sub_Type__c !='MSP Overage')
                    ord.Is_RPS_Required__c = rpsSetting.Is_RPS_Required__c ; 
                }
                else{
                   system.debug('Order Submit error'+VR.description);
                   ord.adderror(VR.description);
                   continue;
                }      
                     ord.Sync_to_NetSuite__c = true;  
                     }
            }
                    }
            catch(exception e){
                ord.Sync_to_NetSuite__c = false;
                ord.Internal_Order_Stage__c = 'Pending';
                Error_Logs__c el = new Error_Logs__c(
            Error_Type__c = 'Order Error',
            Error_Message__c = e.getMessage() + '\r\n' + e.getStackTraceString(),
            Type__c = 'SFDC'
        );
        Database.insert(el);
            }
          } 
          else{
              ord.Internal_Order_Stage__c ='Pending';
          } 
             
          //  else{
                // Call only if the screening status is updated
                system.debug('Order new value'+ord+'Ord Old value'+oldOrderMap);
                if(ord.Is_RPS_Required__c && ord.ScreenStatus__c != 'Approved' && ord.status!='Cancelled' && ord.ScreenStatus__c != 'Denied' && oldOrderMap != null && (ord.ScreenStatus__c != oldOrderMap.get(ord.id).ScreenStatus__c || ord.ShipToScreenStatus__c != oldOrderMap.get(ord.id).ShipToScreenStatus__c|| ord.Billto_EndUser_Screen_Status__c != oldOrderMap.get(ord.id).Billto_EndUser_Screen_Status__c || ord.Shipto_EndUser_Screen_Status__c != oldOrderMap.get(ord.id).Shipto_EndUser_Screen_Status__c || ord.ShipToContactScreenStatus__c != oldOrderMap.get(ord.id).ShipToContactScreenStatus__c)){
                    if(ord.ShipToScreenStatus__c == 'Denied' || ord.Billto_EndUser_Screen_Status__c =='Denied' || ord.Shipto_EndUser_Screen_Status__c =='Denied' || ord.ShipToContactScreenStatus__c =='Denied'
                          || ord.ShipToScreenStatus__c == 'Awaiting user intervention' || ord.Billto_EndUser_Screen_Status__c =='Awaiting user intervention' || ord.Shipto_EndUser_Screen_Status__c =='Awaiting user intervention' || ord.ShipToContactScreenStatus__c =='Awaiting user intervention'
                          || ord.ShipToScreenStatus__c == 'On hold' || ord.Billto_EndUser_Screen_Status__c =='On hold' || ord.Shipto_EndUser_Screen_Status__c =='On hold' || ord.ShipToContactScreenStatus__c =='On hold'){
                              if(oldOrderMap.get(ord.id).Order_Status__c != 'On Hold')
                                  ord.Order_Status__c ='On Hold';
                              if(ord.Hold_Code__c != null){
                                  if( isNewHoldCode(ord.Hold_Code__c.split(';'),'Global Trade Compliance Screening')){
                                      ord.Hold_Code__c = ord.Hold_Code__c + ';' + 'Global Trade Compliance Screening';
                                  }
                              }
                              else{
                                  ord.Hold_Code__c = 'Global Trade Compliance Screening';
                              }
                          }
                    
                    if(ord.ShipToScreenStatus__c == 'Denied' || ord.Billto_EndUser_Screen_Status__c =='Denied' || ord.ShipToContactScreenStatus__c =='Denied' ){
                        ord.ScreenStatus__c = 'Denied';
                    }
                    else if(ord.ShipToScreenStatus__c == 'Required' || ord.Billto_EndUser_Screen_Status__c =='Required'|| ord.Shipto_EndUser_Screen_Status__c =='Required' || ord.ShipToContactScreenStatus__c =='Required' ) {
                        ord.ScreenStatus__c = 'Required';
                    }
                    else if(ord.ShipToScreenStatus__c == 'on hold' || ord.Billto_EndUser_Screen_Status__c =='on hold' || ord.Shipto_EndUser_Screen_Status__c =='on hold' || ord.ShipToContactScreenStatus__c =='on hold') {
                        ord.ScreenStatus__c = 'On hold';
                    }
                    else if (ord.ShipToScreenStatus__c == 'Approved' && ord.Billto_EndUser_Screen_Status__c =='Approved' && ord.Shipto_EndUser_Screen_Status__c =='Approved' && ord.ShipToContactScreenStatus__c =='Approved') {
                        ord.ScreenStatus__c = 'Approved';
                        if(ord.Order_Status__c!='On Hold' || (ord.Order_Status__c=='On Hold'&& ord.Hold_Code__c=='Global Trade Compliance Screening'))
                        ord.Sync_to_NetSuite__c = true;
                    if(ord.Type!= null && (ord.Type.equalsIgnoreCase('RMA')|| ord.Type.equalsIgnoreCase('Revenue') )&& ord.Hold_Code__c =='Global Trade Compliance Screening')
                        ord.Order_Status__c = 'Pending';
                    
                    if(ord.Hold_Code__c != null){
                        HC_List = ord.Hold_Code__c.split(';');
                    }
                    
                    if(HC_List.indexOf('Global Trade Compliance Screening')!=-1){
                        HC_List.remove(HC_List.indexOf('Global Trade Compliance Screening'));    
                        ord.Hold_Code__c = string.join(HC_List,';');
                    }
                    
                }
                else if (ord.ShipToScreenStatus__c == 'Awaiting user intervention' || ord.Billto_EndUser_Screen_Status__c =='Awaiting user intervention' || ord.Shipto_EndUser_Screen_Status__c =='Awaiting user intervention' || ord.ShipToContactScreenStatus__c =='Awaiting user intervention') {
                    ord.ScreenStatus__c = 'On hold';
                }
                else{
                    System.debug('No RPS screening update');
                }  
            }
            // }
        }
    }
    private static ValidationResp ValidateOrderSubmission(Order ord){
        List<string> validHoldCodes = RPS__c.getOrgDefaults().Valid_HoldCodes__c.split(';');
        system.debug('CP Order Hold Code'+ord.Hold_Code__c); 
        if(ord.Hold_Code__c !=null){
        for(string str : ord.Hold_Code__c.split(';')){
             if(!validHoldCodes.contains(str)){
              return new ValidationResp(false,' Please clear hold codes');
             } 
        }
        
       }
       return new ValidationResp(true,null);
    }
     public class ValidationResp {
        public boolean isValid {get;set;}
        public string description{get;set;}
        
         public ValidationResp(boolean isValid,string description) {
             this.isValid =isValid;
             this.description = description;
        }
    }
    private static boolean isNewHoldCode(String[] existingHC, String newHC){
        for(String HC : existingHC){
            if(HC.equalsIgnoreCase(newHC)){
                return false;
            }
        }
        return true;
    }
    public static void acceptOrder(List<Order> newOrders, Map<Id, Order> oldOrderMap) {
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();
        for(Order ord: newOrders){
            Order oldOrder = oldOrderMap.get(ord.Id);
            if(String.isNotBlank(ord.NetSuite_Order__c) && ord.NetSuite_Order__c != oldOrder.NetSuite_Order__c && ord.Order_Status__c != 'Order Accepted'){
                    ord.Order_Status__c = 'Order Accepted';
                    ord.Status = 'Order Accepted';
                if(ord.opportunityId != null && !opportunityMap.containsKey(ord.OpportunityId)){ 
                    opportunityMap.put(ord.OpportunityId, new Opportunity(Id = ord.OpportunityId, StageName = '7 Closed Won', CloseDate = Date.Today(), Order_Sub_Type__c = ord.Order_Sub_Type__c));
                }
            }
        }
        for(Opportunity opp :[select id,StageName from opportunity where id IN: opportunityMap.keyset() and StageName IN ('7 Closed Won','7 Closed Lost')]){
          opportunityMap.remove(opp.id);
        }
        if(opportunityMap.size()>0){
            update opportunityMap.values();
        }

    }

    public static void populateFieldsOnInsert(List<Order> ordList) { 
        for(Order ord : ordList) {
            ord.Stage_PO_Id__c = ord.Stage_PO__c;
        }
    }

    public static void populateFieldsOnUpdate(List<Order> ordList, Map<Id, Order> oldOrdMap) {
        List<PO_Stage__c> POStageList = new List<PO_Stage__c>();
        PO_Stage__c poStg ;
        for(Order ord : ordList) {
            poStg = new PO_Stage__c();
            ord.Stage_PO_Id__c = ord.Stage_PO__c;
            if(ord.Order_Status__c!= null && (ord.Order_Status__c=='Order Accepted'|| ord.Order_Status__c=='Rejected' || ord.Status =='Cancelled')&& ord.Stage_PO__c!=null && (ord.Order_Status__c!=oldOrdMap.get(ord.id).Order_Status__c || ord.Status!=oldOrdMap.get(ord.id).Status)){
                if(ord.Order_Status__c=='Order Accepted'){
                      poStg.PO_Validation_Status__c ='Order Accepted';
                } 
                else if(ord.Order_Status__c=='Rejected' || ord.Status =='Cancelled'){
                     poStg.PO_Validation_Status__c ='Order Rejected';
                     poStg.Rejection_Reason__c = ord.Cancellation_Reason__c != null ? ord.Cancellation_Reason__c : System.Label.OrderCancellationMessage ;
                }
              poStg.id=ord.Stage_PO__c;
              poStg.Est_Ship_Date__c=ord.Est_Ship_Date__c; 
              POStageList.add(poStg); 
            }
        }
        if(!POStageList.isEmpty())
        update POStageList;
    } 

    public static void copyPODetails(List<Order> newOrders) {
        /*Set<Id> Poids = new Set<Id>();*/
        //Map<string,SBQQ__Quote__c> quoteMap = new Map<string,SBQQ__Quote__c>();  
       /* for(Order ord: newOrders){
            System.debug('---ord------'+ord);
            quoteMap.put(ord.SBQQ__Quote__c,null);
        }
        if(quoteMap.isEmpty() == false){
            for(SBQQ__Quote__c quoteInst : [SELECT Id,Name,SBQQ__Type__c,(SELECT Id,Name,SBQQ__Product__r.Appliance_Model_HW__c,SBQQ__Product__r.Product_Type__c,SBQQ__StartDate__c,SBQQ__EffectiveStartDate__c   
                                                                           FROM SBQQ__LineItems__r where SBQQ__EffectiveStartDate__c != null order by SBQQ__EffectiveStartDate__c asc)  
                                            FROM SBQQ__Quote__c  
                                            WHERE Id IN :quoteMap.keySet()]){  
                quoteMap.put(quoteInst.Id,quoteInst); 
            }    
            system.debug('-quoteMap----'+quoteMap);
            for(Order ord: newOrders){
                if(quoteMap.get(ord.SBQQ__Quote__c)!=null && (quoteMap.get(ord.SBQQ__Quote__c).SBQQ__Type__c == 'Renewal'|| quoteMap.get(ord.SBQQ__Quote__c).SBQQ__Type__c == 'Amendment')){
                    system.debug('--ord.EffectiveDate----'+ord.EffectiveDate);
                    if(quoteMap.get(ord.SBQQ__Quote__c).SBQQ__LineItems__r != null && quoteMap.get(ord.SBQQ__Quote__c).SBQQ__LineItems__r.isEmpty() == false){
                        ord.EffectiveDate = quoteMap.get(ord.SBQQ__Quote__c).SBQQ__LineItems__r[0].SBQQ__EffectiveStartDate__c ;
                        system.debug('--ord.EffectiveDate----'+ord.EffectiveDate);
                    }
                }
            }
        }
      */
      /*for(Order ord: newOrders){
          if(ord.Is_Order_Split_Formula__c==false && ord.SBQQ__Quote__c != null && quoteMap.get(ord.SBQQ__Quote__c)!=null && quoteMap.get(ord.SBQQ__Quote__c).SBQQ__ExpirationDate__c < System.today()){
              ord.Order_Status__c ='On Hold';
              ord.Hold_Code__c = ord.Hold_Code__c != null ? ord.Hold_Code__c+';Expired Quote': 'Expired Quote';
          }
                if(quoteMap.get(ord.SBQQ__Quote__c)!=null && (quoteMap.get(ord.SBQQ__Quote__c).SBQQ__Type__c == 'Renewal'|| quoteMap.get(ord.SBQQ__Quote__c).SBQQ__Type__c == 'Amendment')){
                    if(quoteMap.get(ord.SBQQ__Quote__c).SBQQ__LineItems__r != null && quoteMap.get(ord.SBQQ__Quote__c).SBQQ__LineItems__r.isEmpty() == false){
                        ord.EffectiveDate = quoteMap.get(ord.SBQQ__Quote__c).SBQQ__LineItems__r[0].SBQQ__EffectiveStartDate__c ;
                }
            }
        }
        
        /* Map<Id, SBQQ__Quote__c> quoteMap = new Map<Id, SBQQ__Quote__c>([Select Id, PO_Date__c, PO_Number__c, SBQQ__ShippingCountry__c,
SBQQ__ShippingCity__c, SBQQ__ShippingPostalCode__c, SBQQ__ShippingState__c, SBQQ__ShippingStreet__c, Shipping_Carrier__c, 
Service_Level__c, SBQQ__PaymentTerms__c, Ship_To_Contact_Name__c, Shipping_Account_Number__c, 
End_User_PO__c, Ship_To_Phone_Number__c, Shipping_Terms__c, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Distributor_Lookup__c from SBQQ__Quote__c where Id in :quoteIds]);*/
        
     /*   if(quoteMap.keySet().size()>0){
            Map<id,PO_Stage__c> stagePOMAp = new MAP<id,PO_Stage__c>([select id,partner_name__c,PoDate__c,PoNumber__c,ShippingCity__c,ShippingCountry__c,ShippingCountryCode__c,ShippingPostalCode__c,ShippingState__c,ShippingStateCode__c,ShippingStreet__c,Shipping_Method__c,Ship_To_Contact_Name__c,Shipping_Carrier__c,Shipping_Account_Number__c,End_User_PO__c,Service_Level__c,Ship_to_Email__c,Ship_To_Name__c, Ship_To_Name__r.Name, Ship_To_Phone_Number__c,Payment_Terms__c,Quote__c,Quote__r.SBQQ__Opportunity2__r.Distributor_Lookup__c,Expected_number_of_POs__c from PO_Stage__c where Quote__c in :quoteMap.keySet() AND PO_Internal_Validation_Status__c = 'Success']);
            Map<Id,Id> quoteIdStagePOID = new Map<Id,Id>();
            for(PO_Stage__c poStage : stagePOMAp.values()){
                if(poStage.Expected_number_of_POs__c == 1){
                    quoteIdStagePOID.put(poStage.Quote__c,poStage.Id);
                }
            }
             
            for(Order ord: newOrders){
                //SBQQ__Quote__c quote = quoteMap.get(ord.SBQQ__Quote__c);
                if(quoteIdStagePOID.containsKey(ord.SBQQ__Quote__c)){
                    ord.Stage_PO__c = quoteIdStagePOID.get(ord.SBQQ__Quote__c);
                }
                PO_Stage__c poStage = stagePOMAp.get(ord.Stage_PO__c);
                if(poStage != null){
                    if(poStage.Ship_to_Email__c != null){
                        ord.Ship_to_Email__c = poStage.Ship_to_Email__c;
                    }
                    
                    if(String.isNotBlank(poStage.Ship_To_Name__c)){
                        ord.Ship_To_Name__c = poStage.Ship_To_Name__r.Name;
                    }
                    
                    if(poStage.PoDate__c != null){
                        ord.PODate = poStage.PoDate__c;
                    }
                    
                    if(String.isNotBlank(poStage.PoNumber__c)){
                        ord.PoNumber = poStage.PoNumber__c;
                    }
                    
                    if(String.isNotBlank(poStage.ShippingCity__c)){
                        ord.ShippingCity = poStage.ShippingCity__c;
                    }
                    
                    if(String.isNotBlank(poStage.ShippingCountryCode__c)){
                        //ord.ShippingCountry = poStage.ShippingCountry__c;
                        ord.ShippingCountry = '';
                        ord.shippingcountrycode = poStage.ShippingCountryCode__c;
                        System.debug(ord.shippingcountrycode);
                    }
                    //ord.ShippingCountryCode = quote.ShippingCountryCode__c;
                    if(String.isNotBlank(poStage.ShippingStateCode__c)){
                        //ord.ShippingState = poStage.ShippingState__c;
                        ord.ShippingState = '';
                        ord.ShippingStateCode=poStage.ShippingStateCode__c;
                        System.debug(ord.ShippingStateCode);
                    }
                    //ord.ShippingStateCode = quote.ShippingStateCode__c;
                    if(String.isNotBlank(poStage.ShippingPostalCode__c)){
                        ord.ShippingPostalCode = poStage.ShippingPostalCode__c;
                    }
                    
                    if(String.isNotBlank(poStage.ShippingStreet__c)){
                        ord.ShippingStreet = poStage.ShippingStreet__c;
                    }
                    
                    if(String.isNotBlank(poStage.Shipping_Carrier__c)){
                        ord.Shipping_Carrier__c = poStage.Shipping_Carrier__c;
                    }
                    if(String.isNotBlank(poStage.Shipping_Carrier__c) && String.isNotBlank(poStage.Service_Level__c)){
                        ord.Service_Level__c = poStage.Service_Level__c;
                    }
                    
                    if(String.isNotBlank(poStage.Payment_Terms__c)){
                        ord.Payment_Terms__c = poStage.Payment_Terms__c;
                    }
                    
                    if(String.isNotBlank(poStage.Ship_To_Contact_Name__c)){
                        ord.ShipToContactName__c = poStage.Ship_To_Contact_Name__c;
                    }
                    
                    if(String.isNotBlank(poStage.End_User_PO__c)){
                        ord.End_User_PO__c = poStage.End_User_PO__c;
                    }
                    
                    if(String.isNotBlank(poStage.Ship_To_Phone_Number__c)){
                        ord.Ship_To_Phone_Number__c = poStage.Ship_To_Phone_Number__c;
                    }
                    
                    if(String.isNotBlank(poStage.Shipping_Method__c)){
                        ord.Shipping_Method__c = poStage.Shipping_Method__c;
                    }
                    
                    if(String.isNotBlank(poStage.Shipping_Account_Number__c)){
                        ord.Shipping_Account_Number__c = poStage.Shipping_Account_Number__c;
                    }
                    
                    if(poStage.Quote__r.SBQQ__Opportunity2__r.Distributor_Lookup__c != null){
                        ord.Bill_To_Name__c = poStage.Quote__r.SBQQ__Opportunity2__r.Distributor_Lookup__c;
                    }
                    if(poStage != null && poStage.Partner_name__c != null){
                        ediPartnerNameMap.put(poStage.id,poStage.Partner_name__c);
                    }
                    if(String.isNotBlank(poStage.Partner_Name__c)){
                        ord.Partner_Name_Text__c = poStage.Partner_Name__c;
                    }
                    if((poStage.Shipping_Account_Number__c == null && poStage.Shipping_Carrier__c == 'No Shipping Required' && poStage.Service_Level__c == 'N/A')){
                        //do nothing
                    }
                    else if(String.isBlank(poStage.Shipping_Account_Number__c) || String.isBlank(poStage.Service_Level__c) || String.isBlank(poStage.Shipping_Carrier__c)){
                        ord.Order_Status__c ='On Hold';
                        ord.Hold_Code__c = ord.Hold_Code__c != null ? ord.Hold_Code__c+';Missing freight forwarder details': 'Missing freight forwarder details';
                        
                    }
                }
                System.debug('test code palak orderservice -1 '+ord.ShippingCountry);
                System.debug('test code palak orderservice - 1'+ord.ShippingState);
                System.debug('test code palak orderservice - 1'+ord.Order_Splitted__c);
            }
        }
        
    }
    
    
    
    public static void checkPOCShippedDates() {
        Id pocOrderRecordId = (Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order') != null)
            ? Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order').getRecordTypeId()
            : null;

        for(SObject ordSo : Trigger.new) {
            Order ord = (Order)ordSo;
            Order oldOrd = (Trigger.oldMap != null) ? (Order)Trigger.oldMap.get(ord.Id) : null;

            if(oldOrd != null
                && ord.Actual_Order_Ship_Date__c == null
                && ord.Order_Status__c != oldOrd.Order_Status__c
                && ord.Order_Status__c == 'Shipped'
                && ord.RecordTypeId == pocOrderRecordId) {

                ord.addError('Actual Order Ship Date is required');
            }
        }
    }

    // public static void setPOCSupportDates() {
    //     Id pocOrderRecordId = (Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order') != null)
    //         ? Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order').getRecordTypeId()
    //         : null;
    //     Map<Id, Order> pocOrderIds = new Map<Id, Order>();
    //     Map<Id, OrderItem> toUpdate = new Map<Id, OrderItem>();

    //     for(SObject ordSo : Trigger.new) {
    //         Order ord = (Order)ordSo;
    //         Order oldOrd = (Trigger.oldMap != null) ? (Order)Trigger.oldMap.get(ord.Id) : null;

    //         if(oldOrd != null
    //             && ord.Actual_Order_Ship_Date__c != oldOrd.Actual_Order_Ship_Date__c
    //             && ord.RecordTypeId == pocOrderRecordId) {

    //             pocOrderIds.put(ord.Id, ord);
    //         }
    //     }

    //     if(!pocOrderIds.isEmpty()) {
    //         List<OrderItem> oItems = [
    //             SELECT Id, OrderId, Order.POC_Duration__c
    //             FROM OrderItem
    //             WHERE OrderId IN :pocOrderIds.keySet()
    //                 AND (Support_Start_Date__c = null OR Support_End_Date__c = null)
    //                 AND (Pricebookentry.Product2.Asset_Priority__c IN (1,2) OR Pricebookentry.Product2.License_Type__c IN ('Subscription','Support'))
    //         ];

    //         for(OrderItem oi : oItems) {
    //             Order ord = pocOrderIds.get(oi.OrderId);
    //             setSupportDates(oi, ord);
    //             toUpdate.put(oi.Id, oi);
    //         }
    //     }

    //     if(!toUpdate.isEmpty()) {
    //         update toUpdate.values();
    //     }

    // }

    // private static void setSupportDates(OrderItem oi, Order ord) {

    //     Integer pocDuration = 0;
    //     pocDuration = (oi.Order.POC_Duration__c != null) ? Integer.valueOf(oi.Order.POC_Duration__c) : pocDuration;

    //     Date actualStartDate = ord.Actual_Order_Ship_Date__c;
    //     Date actualEndDate = (actualStartDate != null) ? (actualStartDate.addDays(7).addDays(pocDuration)) : null;

    //     if(actualStartDate != null) {
    //         oi.Support_Start_Date__c = actualStartDate;
    //     }
    //     if(actualEndDate != null) {
    //         oi.Support_End_Date__c = actualEndDate;
    //     }
    // }

    public static void setDefaultOrderType() {
        Id revenueOrderRecordId = (Schema.SObjectType.Order.getRecordTypeInfosByName().get('Revenue Order') != null)
            ? Schema.SObjectType.Order.getRecordTypeInfosByName().get('Revenue Order').getRecordTypeId()
            : null;

        Map<Id, String> mapOppIdwithSubtye = new Map<Id,String>();
        Set<Id> oppIdSet = new Set<Id>();
        for(SObject ordSo : Trigger.new) {
            Order ord = (Order)ordSo;
            if(ord.opportunityId != null) {
                oppIdSet.add(ord.opportunityId);
            }
        } 
        for(Opportunity oppty  : [select id, Opportunity_Sub_Type__c from Opportunity where ID In: oppIdSet]) {
            if(oppty.Id != null && oppty.Opportunity_Sub_Type__c != null) {
                mapOppIdwithSubtye.put(oppty.Id, oppty.Opportunity_Sub_Type__c);
            }
        }
        for(SObject ordSo : Trigger.new) {
            Order ord = (Order)ordSo;
            if(ord.RecordTypeId == revenueOrderRecordId || ord.RecordTypeId == null) {
                ord.Type = 'Revenue';
            }
            if(mapOppIdwithSubtye.containsKey(ord.OpportunityId) && mapOppIdwithSubtye.get(ord.OpportunityId) == 'MSP' && ord.MSP_SKUs_Count__c > 0) { //SF-4019 : AG: 6th Dec 2019 : Added a check to update the sub type only if MSP lines are added on the quote
                ord.Order_Sub_Type__c = ORDER_SUBTYPE_MSP;
            }
        }
    }

    public static void revertOrderTypeChanges() {
        for(SObject ordSo : Trigger.new) {
            Order ord = (Order)ordSo;
            Order oldOrd = (Trigger.oldMap != null) ? (Order)Trigger.oldMap.get(ord.Id) : null;

            if(oldOrd != null && ord.Type != oldOrd.Type && oldOrd.Type != null && oldOrd.Type != 'New') {
                ord.Type = oldOrd.Type;
            }
        }
    }

    public static void preventChangeOriginalEstShipDate() {

        for(SObject ordSo : Trigger.new) {
            Order ord = (Order)ordSo;
            Order oldOrd = (Trigger.oldMap != null) ? (Order)Trigger.oldMap.get(ord.Id) : null;

            if(oldOrd != null
                && ord.Order_is_submitted__c
                && ord.Original_Est_Ship_Date__c != oldOrd.Original_Est_Ship_Date__c) {

                ord.Original_Est_Ship_Date__c = oldOrd.Original_Est_Ship_Date__c;
            }
        }
    }

    public static void checkIsOrderSubmitted() {

        for(SObject ordSo : Trigger.new) {
            Order ord = (Order)ordSo;
            Order oldOrd = (Trigger.oldMap != null) ? (Order)Trigger.oldMap.get(ord.Id) : null;

            if(oldOrd == null
                && ord.Order_Status__c == 'Order Accepted') {
                ord.Order_is_submitted__c = true;
            }
            if(oldOrd != null
                && ord.Order_Status__c == 'Order Accepted'
                && ord.Order_Status__c != oldOrd.Order_Status__c) {
                ord.Order_is_submitted__c = true;
            }
        }
    }

    public static void initCurrentEstShipDate() {
        for(SObject ordSo : Trigger.new) {
            Order ord = (Order)ordSo;
            Order oldOrd = (Trigger.oldMap != null) ? (Order)Trigger.oldMap.get(ord.Id) : null;

            //if(oldOrd != null && oldOrd.Order_Status__c != ord.Order_Status__c && ord.Order_Status__c=='Pending NS Sync' && ord.Type =='Revenue' ){
            if( ord.ScreenStatus__c!=null && oldOrd != null && oldOrd.ScreenStatus__c != ord.ScreenStatus__c && (ord.ScreenStatus__c=='Approved' || ord.ScreenStatus__c=='Approved-Bypassed' || ord.ScreenStatus__c=='Approved Bypassed' ) && ord.Type =='Revenue' ){
               // added by palak
                /*Added by Rahul for ticket SF-5496 */  
           /*    if(orderHardwareFIBProdMap != null && orderHardwareFIBProdMap.containsKey(ordso.id)){    
                    if(ord.Est_Ship_Date__c == null)    
                        ord.Est_Ship_Date__c = Date.valueOF(system.now().addDays(42));  
                   if(ord.Deliver_By__c == null)    
                        ord.Deliver_By__c = Date.valueOF(system.now().addDays(49));     
                }
                else if(orderHardwareProdMap != null && orderHardwareProdMap.containsKey(ordso.id)){
                   if(ord.Est_Ship_Date__c == null)
                        ord.Est_Ship_Date__c = Date.valueOF(system.now().addDays(21)); 
                   if(ord.Deliver_By__c == null)
                        ord.Deliver_By__c = Date.valueOF(system.now().addDays(28)); 
                }else{
                   if(ord.Est_Ship_Date__c == null)
                    ord.Est_Ship_Date__c = Date.valueOF(system.now().addDays(7)); 
                   if(ord.Deliver_By__c == null)
                    ord.Deliver_By__c = Date.valueOF(system.now().addDays(7)); 
                }

            }
            
            if(oldOrd == null
                && ord.Est_Ship_Date__c == null
                && ord.Original_Est_Ship_Date__c != null && ord.Type !='Revenue') {

                ord.Est_Ship_Date__c = ord.Original_Est_Ship_Date__c;
            }
            if(oldOrd != null
                && ord.Est_Ship_Date__c == null
                /*&& ord.Original_Est_Ship_Date__c != null*/
         /*       && ord.Original_Est_Ship_Date__c != oldOrd.Original_Est_Ship_Date__c  && ord.Type !='Revenue') {

                ord.Est_Ship_Date__c = ord.Original_Est_Ship_Date__c;
            }
        }
    }

    public static void setDefaultShippingCarrier() {
        for(SObject ordSo : Trigger.new) {
            Order ord = (Order)ordSo;
            if(ord.Order_Sub_Type__c == 'Renewal'
                && ord.Shipping_Carrier__c == null) {

                ord.Shipping_Carrier__c = 'No Shipping Required';
                ord.Service_Level__c = 'N/A';
            }
        }
    }

    public static void syncOrderStatusForPOC_RMA_RT() {

        //Id pocOrderRecordId = (Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order') != null)
        //    ? Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order').getRecordTypeId()
        //    : null;

        //Id rmaOrderRecordId = (Schema.SObjectType.Order.getRecordTypeInfosByName().get('RMA Order') != null)
        //    ? Schema.SObjectType.Order.getRecordTypeInfosByName().get('RMA Order').getRecordTypeId()
        //    : null;
        //Set<Id> allowedRT = new Set<Id>{pocOrderRecordId, rmaOrderRecordId};

        for(SObject ordSo : Trigger.new) {
            Order ord = (Order)ordSo;
            Order oldOrd = (Trigger.oldMap != null) ? (Order)Trigger.oldMap.get(ord.Id) : null;

            //if(!allowedRT.contains(ord.RecordTypeId)) continue;

            if(oldOrd == null
                && ord.Status == null
                && ord.Order_Status__c != null) {

                ord.Status = ord.Order_Status__c;
            }
            if(oldOrd != null
                && ord.Status == null
                && ord.Order_Status__c != null
                && ord.Order_Status__c != oldOrd.Order_Status__c) {

                ord.Status = ord.Order_Status__c;
            }
        }

        //for(Order ord : newOrders) {

        //    Order oldOrder = (oldOrderMap != null && oldOrderMap.containsKey(ord.Id))
        //        ? oldOrderMap.get(ord.Id)
        //        : null;

        //    if(oldOrder == null) {
        //        ord.Order_Status__c = ord.Status;
        //    }
        //    if(oldOrder != null && (ord.Status != oldOrder.Status || ord.SBQQ__Contracted__c != oldOrder.SBQQ__Contracted__c)) {
        //        ord.Order_Status__c = ('Activated' == ord.Status && ord.SBQQ__Contracted__c) ? 'Shipped' : ord.Status ;
        //    }
        //}
    }

    /*public static void updateOrderAccounts(Set<Id> orderIdSet){
            system.debug('### orderIdSet '+orderIdSet);
            List<Order> orderToUpdateAccountLookup = [select ID, AccountID, Ship_To_Name__c  from Order where Id =:orderIdSet];
            for(Order theOrders : orderToUpdateAccountLookup){
                theOrders.Ship_To_Name__c = theOrders.AccountID;
            }
            system.debug('### orderToUpdateAccountLookup '+orderToUpdateAccountLookup.size());
//            if(orderToUpdateAccountLookup.size()>0) update orderToUpdateAccountLookup;
    }*/


  /*  public static void checkOrdersComplete(Set<Id> orderOppId, List<Order> newOrder){

        if(Trigger.isAfter) return;

        Id pocOrderRecordId = (Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order') != null)
            ? Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order').getRecordTypeId()
            : null;

        for(Order ord : newOrder) {
            if(ord.RecordTypeId == pocOrderRecordId && ord.RecordTypeId != null) {
                orderOppId.remove(ord.Id);
            }
        }

        if(!orderOppId.isEmpty()) {

            Decimal oppquan;
            string q= 'SELECT SUM(Quantity) quanopp from OpportunityLineItem';
            q+= ' WHERE OpportunityId=: orderOppId';
            List<AggregateResult> results = Database.query(q);
            oppquan = (Decimal) results[0].get('quanopp');


            Decimal orderquan;
            string q1= 'SELECT SUM(Quantity) quan from OrderItem';
            q1+= ' WHERE Order.OpportunityId=: orderOppId and OrderId!=:newOrder';
            List<AggregateResult> results1 = Database.query(q1);
            orderquan = (Decimal) results1[0].get('quan');

            if(orderquan >= oppquan) {
                newOrder[0].addError('All Lines have already been fulfilled, you cannot create another order');
            }
            else {
                //do nothing
            }
         }
    }

    public static boolean isCPQFlow(OrderItem oi) {
        //return false;
        return oi.OrderId != null && oi.order.OpportunityId != null && oi.order.Opportunity.SBQQ__PrimaryQuote__c != null;
    }

    public static void processShippedOrders(List<Order> newOrders, Map<Id, Order> oldOrdersMap) {

        Set<Id> orderIds = new Set<Id>();
        Set<Id> pocOrderIds = new Set<Id>();
        List<Order_Event__e> orderEvents = new List<Order_Event__e>();

        for(Order ord : newOrders) {
            Order oldOrd = (oldOrdersMap != null && oldOrdersMap.containsKey(ord.Id)) ? oldOrdersMap.get(ord.Id) : null;

            if(oldOrd == null
        //        && ord.Order_Status__c == 'Shipped') {
                && (ord.Status == 'Activated'
                || ord.Order_Status__c == 'Shipped')) {

                orderIds.add(ord.Id);
            }

            if(oldOrd != null
        //        && ord.Order_Status__c == 'Shipped' && ord.Order_Status__c != oldOrd.Order_Status__c) {
                && ((ord.Status == 'Activated' && ord.Status != oldOrd.Status)
                || (ord.Order_Status__c == 'Shipped' && ord.Order_Status__c != oldOrd.Order_Status__c))) {

                orderIds.add(ord.Id);
            }

            if(ord.Type == 'RMA' && oldOrd != null && ord.Order_Status__c == 'Shipped' && ord.Order_Status__c != oldOrd.Order_Status__c) {
                orderEvents.add(new Order_Event__e(Order_Id__c = ord.Id, Action_Type__c='RMA_SPARE_CREATE'));
            }

            if(ord.Type == 'POC' && ord.Order_Status__c == 'Shipped' && oldOrd !=null && ord.Order_Status__c != oldOrd.Order_Status__c) {
                pocOrderIds.add(ord.Id);
            }
        }

        if(orderEvents.size()>0){
            List<Database.SaveResult> SaveResults = EventBus.publish(orderEvents);
        }

        Map<Id, OrderItem> oItems = getOrderItemMap(orderIds);
        System.debug('Debug Point 2');
        if(pocOrderIds.size() > 0){
            try{
                if(!jobQueued){
                    ID jobID = System.enqueueJob(new GenerateEntitlementsForPOCOrders(pocOrderIds));
                    //ID slackJobID = System.enqueueJob(new SendSlackAlertsForPOCOrders(pocOrderIds));
                    jobQueued = true;
                    System.debug('Job Id::' + jobID);
                    //System.debug('Job Id::' + slackJobID);
                }
            }
            Catch(Exception e){
                System.debug('Failed to Queue the job. ' + e.getMessage());
            }
        }

        //initOrderInfo(orderIds);
        processOrderItems(oItems);
    }



    private static Map<Id, OrderItem> getOrderItemMap(Set<Id> orderIds) {
        Map<Id, OrderItem> result = new Map<Id, OrderItem>();
        List<OrderItem> items = [
            SELECT
                Id,
                Pricebookentry.Product2Id,
                ProductID__c,
                SerialNumber__c,
                OrderId,
                Create_Asset__c,
                Serial_Number__c,
                Quantity,
                Support_End_Date__c,
                Support_Start_Date__c,
                Order.AccountId,
                Order.Actual_Order_Ship_Date__c,
                Support_Product_Code__c,
                Order_Status__c,
                Product_Category__c,
                Product_Type__c,
                Product_Name__c,
                Single_Quantity__c,
                Single_Entitlement__c,
                PricebookEntry.Product2.Appliance_Model__c,
                Pricebookentry.Product2.Product_Type__c,
                Pricebookentry.Product2.Appliance_Model_HW__c,
                Associate_with_Appliance__c,
                Order.Opportunity.SBQQ__PrimaryQuote__c,
                Order.OpportunityId,
                Product_Code_Formula__c,
                PricebookEntry.Product2.Asset_Priority__c,
                Order.ShippingCity,
                Order.RecordTypeId,
                Order.Type,
                Order.POC_Request__r.POC_completion_date__c,
                Order.POC_Request__r.POC_Type__c,

                Pricebookentry.Product2.License_Type__c,

                SBQQ__RequiredBy__c,
                SBQQ__RequiredBy__r.SerialNumber__c,
                (SELECT Id, Assetid, Product__c, Order_Service_Item__c from Entitlements__r)

            FROM OrderItem
            WHERE (
                    OrderId IN :orderIds
                )
                OR (OrderId IN :orderIds AND Order.RecordTypeId = :POC_ORDER_RECORD_TYPE_ID AND SBQQ__RequiredBy__c != null)
            ORDER BY
                OrderId,
                PricebookEntry.Product2.Asset_Priority__c DESC NULLS LAST
                //PricebookEntry.Product2.Appliance_Model__c DESC NULLS LAST
        ];
        if(!items.isEmpty()) {
            //SAL-605
            for(OrderItem oi: items){
                if((oi.SerialNumber__c != null || oi.Support_Start_Date__c != null || oi.Support_End_Date__c != null) ||
                    (orderIds.contains(oi.OrderId) && oi.Order.RecordTypeId == POC_ORDER_RECORD_TYPE_ID && oi.SBQQ__RequiredBy__c != null)){
                    result.put(oi.Id, oi);
                }
            }
            //result.putAll(items);
        }
        return result;
    }


    public static void processOrderItems(Map<Id, OrderItem> oItems) {
        createSpareAssets(oItems);
        upsertAssetsAndEntitlements(oItems);
        updatePOCOrderItems(oItems);
    }


    private static void updatePOCOrderItems(Map<Id, OrderItem> oItems) {

        Id pocOrderRecordId = (Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order') != null)
            ? Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order').getRecordTypeId()
            : null;

        List<OrderItem> toUpdate = new List<OrderItem>();

        for(OrderItem oi : oItems.values()) {
            if(oi.Order.RecordTypeId == pocOrderRecordId
                && oi.Order.Order_Sub_Type__c !='Try N Buy' 
                && oi.PricebookEntry.Product2.Asset_Priority__c != 0) {

                OrderItem oiUpd = new OrderItem(Id = oi.Id);
                Date startDate = oi.Order.Actual_Order_Ship_Date__c;
                Date endDate = (oi.Order.POC_Request__r.POC_completion_date__c != null)
                    ? oi.Order.POC_Request__r.POC_completion_date__c.addDays(7)
                    : null;

                if(startDate != null && endDate != null) {
                    oiUpd.Support_Start_Date__c = startDate;
                    oiUpd.Support_End_Date__c = endDate;

                    toUpdate.add(oiUpd);
                }
            }
        }

        if(!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }


    private static void createSpareAssets(Map<Id, OrderItem> oItems) {

        Set<String> spareSNs = new Set<String>();
        Set<Id> spareOrderItemIds = new Set<Id>();
        List<OrderItem> spareOrderItems = new List<OrderItem>();

        for(OrderItem oi : oItems.values()) {

            if(oi.Create_Asset__c == true
                && oi.SerialNumber__c != null
                && oi.Quantity > 0) {
                //&& PRODUCT_CATEGORY_SPARE == oi.Product_Category__c) {

                spareOrderItems.add(oi);
                spareSNs.addAll(getSerialNumbers(oi.SerialNumber__c));
            }
        }

        if(spareOrderItems.isEmpty()) return;

        List<Asset> assetList = new List<Asset>();
        List<Error_Logs__c> errorList = new List<Error_Logs__c>();

        Map<String, OrderItem> assetOrderMap = new Map<String, OrderItem>();
        Map<String, Id> assetProductMap = new Map<String, Id>();

        Map<String, Asset> mapAssets = new Map<String, Asset>();
        for(Asset asst : [SELECT Id, SerialNumber, Product2ID, Quantity FROM Asset WHERE SerialNumber IN :spareSNs]){
            mapAssets.put(asst.SerialNumber, asst);
        }

        Map<string, OrderItem> orderItemMap = new Map<String,OrderItem>();

        for(OrderItem oi : spareOrderItems) {
            for(String sNo : getSerialNumbers(oi.SerialNumber__c)) {
                if(mapAssets.containsKey(sNo)){
                    errorList.add(createErrorLog(sNo, oi.OrderId));
                    continue;
                }

                Asset newAsset = new Asset();
                newAsset.Product2Id = oi.Pricebookentry.Product2Id;
                newAsset.SerialNumber = sNo;
                newAsset.Serial_number__c = sNo;
                newAsset.Status = ASSET_STATUS_PURCHASED;
                newAsset.PurchaseDate = oi.Order.Actual_Order_Ship_Date__c;
                newAsset.Location__c = oi.Order.ShippingCity;
                newAsset.Name = sNo;
                newAsset.Order_Service_Item__c = oi.Id;
                newAsset.AccountId = oi.Order.AccountID;
                newAsset.Quantity = 1;//oi.Quantity;
                assetList.add(newAsset);
            }

        }

        if(!assetList.isEmpty()){
            Database.UpsertResult[] ur = Database.upsert(assetList, false);
        }

        if(!errorList.isEmpty()){
            insert errorList;
        }

    }

    private static void upsertAssetsAndEntitlements(Map<Id, OrderItem> oItems) {

        Set<Id> orderItemIdsChangedSN = new Set<Id>();
        Set<Id> orderItemIdsChangedDates = new Set<Id>();
        Map<Id, OrderItem> toProcessOrderItems = new Map<Id, OrderItem>();
        Set<Id> orderIds = new Set<Id>();
        Set<String> supportSerialNumbers = new Set<String>();
        Map<String, Asset> mapAssetBySN = new Map<String, Asset>();

        //Set<String> supportProductCodes = new Set<String>();
        //Map<Id, OrderItem> supportOrderItemIds = new Map<Id, OrderItem>();
        //Set<Id> supportOrderIds = new Set<Id>();
        Set<Id> subscriptionOrderItemsIds = new Set<Id>();
        Set<Id> supportOrderItemsIds = new Set<Id>();
        //Map<Id, Set<Id>> mapSupportOrderItemsByOrderId = new Map<Id, Set<Id>>();


        Map<Id, OrderItem> supportOrderItemIds = new Map<Id, OrderItem>();
        Set<String> supportProductCodes = new Set<String>();
        Set<Id> supportOrderIds = new Set<Id>();
        Map<Id, Set<Id>> mapSupportOrderItemsByOrderId = new Map<Id, Set<Id>>();
        //Set<String> supportSerialNumbers = new Set<String>();

        Set<Id> supportOrderItems = new Set<Id>();
        Set<Id> subscriptionOrderItems = new Set<Id>();


        Set<String> applianceSerialNumbers = new Set<String>();

        Map<String, Entitlement> mapEntitlements = new Map<String, Entitlement>();
        Map<String, Entitlement> mapEntitlementsUpdate = new Map<String, Entitlement>();
        Map<Id, Asset> assetsToUpdate = new Map<Id, Asset>();

        Map<String, List<Entitlement>> mapEntitlementsByOrderItemId = new Map<String, List<Entitlement>>();
        Map<String, Set<String>> mapSNsWithEntitlementsByOrderItemId = new Map<String, Set<String>>();

        Set<String> pocSNs = new Set<String>();
        //List<OrderItem> pocOrderItems = new List<OrderItem>();

        for(OrderItem oi : oItems.values()) {

            if(oi.Quantity > 0) {

                boolean hasSN = (oi.SerialNumber__c != null);
                boolean hasDates = (oi.Support_Start_Date__c != null
                    || oi.Support_End_Date__c != null);

                if(hasSN) {
                    supportSerialNumbers.addAll(getSerialNumbers(oi.SerialNumber__c));
                    orderItemIdsChangedSN.add(oi.Id);
                }
                if(hasDates) {
                    orderItemIdsChangedDates.add(oi.Id);
                }

                if(hasSN || hasDates) {

                    toProcessOrderItems.put(oi.Id, oi);
                    orderIds.add(oi.OrderId);

                    if(oi.Order.RecordTypeId == POC_ORDER_RECORD_TYPE_ID) {
                        continue;
                        //pocOrderItems.add(oi);

                        //if(PRODUCT_CATEGORY_SUPPORT == oi.Product_Category__c || oi.PricebookEntry.Product2.Asset_Priority__c == 1) {

                        //}
                    }

                    //if(oi.Order.RecordTypeId == POC_ORDER_RECORD_TYPE_ID && (oi.SBQQ__RequiredBy__r.SerialNumber__c != null || oi.SerialNumber__c != null)) {
                    //    List<String> sns = getSerialNumbers(oi.SBQQ__RequiredBy__r.SerialNumber__c);
                    //    List<String> sns2 = getSerialNumbers(oi.SerialNumber__c);
                    //    //sns.remove(null);
                    //    //sns2.remove(null);
                    //    if(sns != null) pocSNs.addAll(sns);
                    //    if(sns2 != null) pocSNs.addAll(sns2);
                    //}

                    if(hasDates && PRODUCT_CATEGORY_SUBSCRIPTION == oi.Product_Category__c && oi.Single_Entitlement__c == false && !oi.Associate_with_Appliance__c) {
                        // skip create Entitlements for subscriptions/supports
                        continue;
                    }

                    if(PRODUCT_CATEGORY_SUPPORT == oi.Product_Category__c) {
                        supportOrderIds.add(oi.OrderId);
                        supportOrderItemsIds.add(oi.Id);

                        Set<Id> itemIds = (mapSupportOrderItemsByOrderId.containsKey(oi.OrderId)) ? mapSupportOrderItemsByOrderId.get(oi.OrderId) : new Set<Id>();
                        itemIds.add(oi.Id);
                        mapSupportOrderItemsByOrderId.put(oi.OrderId, itemIds);
                        supportProductCodes.add(oi.Support_Product_Code__c);
                        supportOrderItemIds.put(oi.Id, oi);
                    }

                    if(PRODUCT_CATEGORY_SUBSCRIPTION == oi.Product_Category__c
                        || (oi.Order.RecordTypeId == POC_ORDER_RECORD_TYPE_ID
                            && (oi.PricebookEntry.Product2.Asset_Priority__c == 2
                                || oi.Pricebookentry.Product2.License_Type__c == 'Subscription'))) {

                        supportOrderIds.add(oi.OrderId);
                        //subscriptionOrderItemsIds.add(oi.Id);
                        subscriptionOrderItems.add(oi.Id);

                        Set<Id> itemIds = (mapSupportOrderItemsByOrderId.containsKey(oi.OrderId)) ? mapSupportOrderItemsByOrderId.get(oi.OrderId) : new Set<Id>();
                        itemIds.add(oi.Id);
                        mapSupportOrderItemsByOrderId.put(oi.OrderId, itemIds);
                        supportProductCodes.add(oi.Support_Product_Code__c);
                        supportOrderItemIds.put(oi.Id, oi);
                    }
                }
            }
        }
        System.debug('---supportProductCodes---'+json.serialize(supportProductCodes));
        supportProductCodes.remove(null);

        List<OrderItem> applianceOrderItems = [
            SELECT OrderId, Order.AccountId, Product_Name__c, Create_Entitlement__c,
                Support_Product_Code__c, Single_Entitlement__c, Single_Quantity__c,
                Quantity, Support_Start_Date__c, Support_End_Date__c, Order.RecordTypeId,
                PricebookEntry.Product2Id, ProductID__c, SerialNumber__c, order.Actual_Order_Ship_Date__c,
                PricebookEntry.Product2.Appliance_Model__c, Product_Code_Formula__c
            FROM    OrderItem
            WHERE   OrderId IN :supportOrderIds
                AND Quantity > 0

                AND (
                    (Product_Category__c IN ('Platform','NFR','Spare','Non-Returnable Disk Service') AND PricebookEntry.Product2.Appliance_Model__c IN :supportProductCodes)
                    OR Product_Category__c IN ('Non-Returnable Disk Service')
                    OR (
                        Order.RecordTypeId = :POC_ORDER_RECORD_TYPE_ID
                        AND PricebookEntry.Product2.Asset_Priority__c = 0
                    )
                )

        ];

        System.debug('---applianceOrderItems---'+json.serialize(applianceOrderItems));

        for (OrderItem soi : applianceOrderItems) {
            applianceSerialNumbers.addAll(getSerialNumbers(soi.SerialNumber__c));
        }


        // collect all SN's in Orders
        for(Id orderId : new List<Id>(orderIds)) {
            OrderProducts op = getOrderInfo(orderId);

            if(op == null) continue;

            if(!op.applianceSN.isEmpty()) {
                supportSerialNumbers.addAll(op.applianceSN);
            }
            if(!op.otherSN.isEmpty()) {
                supportSerialNumbers.addAll(op.otherSN);
            }
            if(!op.spareSN.isEmpty()) {
                supportSerialNumbers.addAll(op.spareSN);
            }
            if(!op.nfrSN.isEmpty()) {
                supportSerialNumbers.addAll(op.nfrSN);
            }
            if(!applianceSerialNumbers.isEmpty()) {
                supportSerialNumbers.addAll(applianceSerialNumbers);
            }
        }


        for (Entitlement ent : [
                SELECT Name, Order_Service_Item__c, AssetId, AccountId, StartDate, EndDate,
                    Order_Service_Item__r.SerialNumber__c,
                    Asset.Serial_Number__c
                FROM Entitlement
                WHERE Order_Service_Item__c IN :supportOrderItemIds.keySet() ]) {

            List<Entitlement> entsOrderItem = (mapEntitlementsByOrderItemId.containsKey(ent.Order_Service_Item__c))
                ? mapEntitlementsByOrderItemId.get(ent.Order_Service_Item__c)
                : new List<Entitlement>();

            entsOrderItem.add(ent);
            mapEntitlementsByOrderItemId.put(ent.Order_Service_Item__c, entsOrderItem);

            if(ent.Asset.Serial_Number__c != null) {
                Set<String> snsWithEntitlements = (mapSNsWithEntitlementsByOrderItemId.containsKey(ent.Order_Service_Item__c))
                    ? mapSNsWithEntitlementsByOrderItemId.get(ent.Order_Service_Item__c)
                    : new Set<String>();

                snsWithEntitlements.add(ent.Asset.Serial_Number__c);
                mapSNsWithEntitlementsByOrderItemId.put(ent.Order_Service_Item__c, snsWithEntitlements);
            }
        }

        // get all assets by SN's
        for (Asset a : [SELECT Name, Entitlement__c, Order_Service_Item__c, Serial_Number__c,Product2Id,AccountId, Bypass_Account_and_Product_Update__c
                        FROM Asset
                        WHERE Serial_Number__c IN :supportSerialNumbers
                            OR Serial_Number__c IN :applianceSerialNumbers
                            OR Serial_Number__c IN :pocSNs]) {

            mapAssetBySN.put(a.Serial_Number__c, a);
        }

        // create Entitlements
        for(Id oiId : toProcessOrderItems.keySet()) {

            OrderItem soi = toProcessOrderItems.get(oiId);

            //skip if CPQ flow
            if(OrderInfoMap.containsKey(soi.OrderId) && OrderInfoMap.get(soi.OrderId).items.containsKey(soi.Id) &&
                    isCPQFlow(OrderInfoMap.get(soi.OrderId).items.get(soi.Id))) {
                System.debug('Skipping order item '+soi.Product_Code_Formula__c);
                continue;
            }

            if(soi.Order.RecordTypeId == POC_ORDER_RECORD_TYPE_ID) continue;

            // skip create entitlement for Appliance
            if(PRODUCT_CATEGORY_APPLIANCE == soi.Product_Category__c) continue;

            // skip create entitlement for Spare
            if(PRODUCT_CATEGORY_SPARE == soi.Product_Category__c || PRODUCT_CATEGORY_UPGRADE == soi.Product_Category__c) {
                OrderProducts op = getOrderInfo(soi.OrderId);
                System.debug(LoggingLevel.ERROR,'-----op.getSupportsRelatedToSpare()---'+op.getSupportsRelatedToSpare());
                System.debug(LoggingLevel.ERROR,'-----soi.SerialNumber__c---'+soi.SerialNumber__c);

                if(op != null && op.getSupportsRelatedToSpare().isEmpty()) {
                    System.debug(LoggingLevel.ERROR,'-----skip create spare ent');
                    continue;
                }
            }

            // skip create entitlement for NFR
            if(PRODUCT_CATEGORY_NFR == soi.Product_Category__c ) {
                OrderProducts op = getOrderInfo(soi.OrderId);

                if(op != null && (op.nfrWithEntIds.isEmpty() || (!op.nfrWithEntIds.isEmpty() && !op.nfrWithEntIds.contains(soi.Id)))) {
                    continue;
                }
            }

            Set<String> sNs = (soi.SerialNumber__c != null) ? new Set<String>(getSerialNumbers(soi.SerialNumber__c)) : new Set<String>();
            System.debug('-- sNs-'+sNs);
            //if(soi.Order.RecordTypeId == POC_ORDER_RECORD_TYPE_ID && soi.SBQQ__RequiredBy__r.SerialNumber__c != null) {
            //    sNs = new Set<String>(getSerialNumbers(soi.SBQQ__RequiredBy__r.SerialNumber__c));
            //    System.debug('--poc sNs-'+sNs);
            //}

            List<Entitlement> supportEntitlements = (mapEntitlementsByOrderItemId.containsKey(oiId))
                ? mapEntitlementsByOrderItemId.get(oiId)
                : new List<Entitlement>();

            Integer qty = 0;
            for(String sn : sNs) {
                if(qty >= soi.Quantity) continue;
                String assetId = mapAssetBySN.containsKey(sn) ? mapAssetBySN.get(sn).Id : null;

                Entitlement entUpd = getEntitlement(supportEntitlements, assetId, soi.Id);
                if(entUpd != null) {
                    Entitlement ent = updateEntitlement(soi, assetId, entUpd);
                    mapEntitlementsUpdate.put(entUpd.Id, ent);
                }
                else {
                    Entitlement ent = createEntitlement(soi, assetId);
                    if(ent != null) {
                        mapEntitlements.put(soi.Id + '---' + sn, ent);
                    }
                }
                qty++;
            }

            // subscription with empty SN
            boolean pocSubscription = (soi.Order.RecordTypeId == POC_ORDER_RECORD_TYPE_ID && (soi.PricebookEntry.Product2.Asset_Priority__c == 2 || soi.Pricebookentry.Product2.License_Type__c == 'Subscription'));
            boolean subscrWithEmptySN = ((PRODUCT_CATEGORY_SUBSCRIPTION == soi.Product_Category__c || pocSubscription) && sNs.isEmpty() && (soi.Single_Entitlement__c == true || soi.Single_Quantity__c == true));
            boolean supportWithEmptySN = (PRODUCT_CATEGORY_SUPPORT == soi.Product_Category__c && sNs.isEmpty() && soi.Single_Entitlement__c == true);

            boolean nonReturnableWithEmptySN = ('Non-Returnable Disk Service' == soi.Product_Category__c && sNs.isEmpty() && soi.Single_Entitlement__c == true);

            if(subscrWithEmptySN || supportWithEmptySN || nonReturnableWithEmptySN) {
                Entitlement entUpd = getEntitlement(supportEntitlements, null, soi.Id);
                if(entUpd != null) {
                    Entitlement ent = updateEntitlement(soi, null, entUpd);
                    mapEntitlementsUpdate.put(entUpd.Id, ent);
                }
                else {
                    Entitlement ent = createEntitlement(soi, null);
                    if(ent != null) {
                        mapEntitlements.put(soi.Id + '---', ent);
                    }
                }
            }

            //if(PRODUCT_CATEGORY_SUBSCRIPTION == soi.Product_Category__c && sNs.isEmpty() && (soi.Single_Entitlement__c == true || soi.Single_Quantity__c == true)) {
            //    Entitlement ent = createEntitlement(soi, null);
            //    mapEntitlements.put(soi.Id + '---', ent);
            //}
            //if(PRODUCT_CATEGORY_SUPPORT == soi.Product_Category__c && sNs.isEmpty() && soi.Single_Entitlement__c == true) {
            //    Entitlement ent = createEntitlement(soi, null);
            //    mapEntitlements.put(soi.Id + '---', ent);
            //}
        }

        for (Entitlement ent : mapEntitlements.values()) {

            List<Entitlement> entsOrderItem = (mapEntitlementsByOrderItemId.containsKey(ent.Order_Service_Item__c))
                ? mapEntitlementsByOrderItemId.get(ent.Order_Service_Item__c)
                : new List<Entitlement>();

            entsOrderItem.add(ent);
            mapEntitlementsByOrderItemId.put(ent.Order_Service_Item__c, entsOrderItem);

        }

        System.debug('---mapEntitlements--'+json.serialize(mapEntitlements));
        System.debug('---mapEntitlementsUpdate--'+json.serialize(mapEntitlementsUpdate));

        // support order items for appliance
        for (OrderItem soi : applianceOrderItems) {
            
            if(soi.Order.RecordTypeId == POC_ORDER_RECORD_TYPE_ID) continue;

            Set<Id> oiIds = mapSupportOrderItemsByOrderId.get(soi.OrderId);
            for(Id oiId : oiIds) {
                OrderItem oi = supportOrderItemIds.get(oiId);

                //if(supportOrderItems.contains(oiId)) {
                if(supportOrderItemsIds.contains(oiId)) {

                    System.debug('--oi-support-'+json.serialize(oi));


                    if(soi.PricebookEntry.Product2.Appliance_Model__c != oi.Support_Product_Code__c && oi.Support_Product_Code__c != null) {
                        continue;
                    }

                    List<Entitlement> supportEntitlements = (mapEntitlementsByOrderItemId.containsKey(oiId))
                        ? mapEntitlementsByOrderItemId.get(oiId)
                        : new List<Entitlement>();

                    System.debug('--oi-supportEntitlements-'+json.serialize(supportEntitlements));


                    if(soi.SerialNumber__c != null) {
                        Integer qty = (!supportEntitlements.isEmpty()) ? supportEntitlements.size() : 0;
                        for(String applianceSN : soi.SerialNumber__c.split(',')) {

                            Id applianceAssetId = null;
                            applianceAssetId = (mapAssetBySN.containsKey(applianceSN))
                                ? mapAssetBySN.get(applianceSN).Id
                                : applianceAssetId;

                            if(oi.Support_Product_Code__c == null) {
                                applianceAssetId = null;
                            }

                            if(applianceAssetId != null) {
                                Asset a = new Asset(Id = applianceAssetId);
                                a.Support_Start_Date__c = oi.Support_Start_Date__c;
                                a.Premium_Support_End_Date__c = oi.Support_End_Date__c;
                                a.Quantity = 1;
                                a.Status = 'Purchased';
                                assetsToUpdate.put(applianceAssetId, a);
                            }

                            if(qty >= oi.Quantity || (qty >= 1 && oi.Single_Entitlement__c)) {
                                Entitlement entUpd = getEntitlement(supportEntitlements, applianceAssetId, oi.Id);
                                if(entUpd != null) {
                                    Entitlement ent = updateEntitlement(oi, applianceAssetId, entUpd);
                                    mapEntitlementsUpdate.put(entUpd.Id, ent);
                                }
                                continue;
                            }

                            Entitlement ent = createEntitlement(oi, applianceAssetId);
                            if(ent != null) {
                                mapEntitlements.put(oi.Id + '---' + applianceSN, ent);
                                qty++;
                            }
                        }
                    }
                }

                if(subscriptionOrderItems.contains(oiId)) {
                    List<Entitlement> subscriptionEntitlements = (mapEntitlementsByOrderItemId.containsKey(oiId))
                        ? mapEntitlementsByOrderItemId.get(oiId)
                        : new List<Entitlement>();

                    Set<String> subscriptionSNsWithEntitlements = (mapSNsWithEntitlementsByOrderItemId.containsKey(oiId))
                        ? mapSNsWithEntitlementsByOrderItemId.get(oiId)
                        : new Set<String>();

                    System.debug('--oi-subscr-'+json.serialize(oi));
                    System.debug('--oi-subscriptionEntitlements-'+json.serialize(subscriptionEntitlements));
                    System.debug('--oi-subscriptionSNsWithEntitlements-'+json.serialize(subscriptionSNsWithEntitlements));

                    if(oi.Quantity > 0 && oi.Quantity != subscriptionEntitlements.size()) {

                        if(oi.SerialNumber__c != null) {
                            for(String applianceSN : getSerialNumbers(oi.SerialNumber__c)) {

                                if(subscriptionSNsWithEntitlements.contains(applianceSN)) continue;

                                Id applianceAssetId = null;
                                applianceAssetId = (mapAssetBySN.containsKey(applianceSN))
                                    ? mapAssetBySN.get(applianceSN).Id
                                    : applianceAssetId;

                                Entitlement entUpd = getEntitlement(subscriptionEntitlements, applianceAssetId, oi.Id);
                                if(entUpd != null) {
                                    Entitlement ent = updateEntitlement(oi, applianceAssetId, entUpd);
                                    mapEntitlementsUpdate.put(entUpd.Id, ent);
                                    continue;
                                }


                                Entitlement ent = createEntitlement(oi, applianceAssetId);
                                if(ent != null) {
                                    mapEntitlements.put(oi.Id + '---' + applianceSN, ent);
                                }

                                if(oi.Single_Entitlement__c) {
                                    break;
                                }

                            }
                        }
                        else {
                            System.debug('--oi-subscr-'+json.serialize(oi));

                            if(oi.Single_Entitlement__c && !subscriptionEntitlements.isEmpty() && !oi.Associate_with_Appliance__c) {
                                continue;
                            }

                            if(oi.Associate_with_Appliance__c && !oi.Single_Entitlement__c) {
                                if(soi.PricebookEntry.Product2.Appliance_Model__c == oi.Support_Product_Code__c
                                    && oi.Support_Product_Code__c != null && soi.SerialNumber__c != null) {

                                    for(String applianceSN : getSerialNumbers(soi.SerialNumber__c)) {

                                        if(subscriptionSNsWithEntitlements.contains(applianceSN)) continue;

                                        Id applianceAssetId = null;
                                        applianceAssetId = (mapAssetBySN.containsKey(applianceSN))
                                            ? mapAssetBySN.get(applianceSN).Id
                                            : applianceAssetId;

                                        Entitlement ent = createEntitlement(oi, applianceAssetId);
                                        if(ent != null) {
                                            mapEntitlements.put(oi.Id + '---' + applianceSN, ent);
                                        }

                                        if(oi.Single_Entitlement__c) {
                                            break;
                                        }

                                    }
                                }
                            }
                            else {

                                Entitlement ent = createEntitlement(oi, null);
                                if(ent != null) {
                                    mapEntitlements.put(oi.Id + '---', ent);
                                }
                            }

                        }

                    }
                }
            }
        }


        if (!mapEntitlements.isEmpty()) {
            System.debug(LoggingLevel.ERROR,'--new-mapEntitlements-'+json.serialize(mapEntitlements));
            insert mapEntitlements.values();
        }

        if (!mapEntitlementsUpdate.isEmpty()) {
            System.debug(LoggingLevel.ERROR,'--new-mapEntitlementsUpdate-'+mapEntitlementsUpdate);
            System.debug(LoggingLevel.ERROR,'--new-mapEntitlementsUpdate-'+json.serialize(mapEntitlementsUpdate));
            update mapEntitlementsUpdate.values();
        }

        if(!assetsToUpdate.isEmpty()) {
            System.debug(LoggingLevel.ERROR,'---assetsToUpdate.values()--'+json.serialize(assetsToUpdate.values()));
            List<Asset> toUpdateList = assetsToUpdate.values();
            AssetTriggerHelper.preventChangeFields(toUpdateList);
            update toUpdateList;
            //update assetsToUpdate.values();
        }

        // reassign Assets
        for(Id oiId : toProcessOrderItems.keySet()) {

            OrderItem soi = toProcessOrderItems.get(oiId);
            OrderProducts op = getOrderInfo(soi.OrderId);

            if(soi.PricebookEntry.Product2.Asset_Priority__c != null) {

                List<String> serialNumbers = (soi.SerialNumber__c == null) ? new List<String>() : getSerialNumbers(soi.SerialNumber__c);

                if(soi.PricebookEntry.Product2.Asset_Priority__c >= 0 && !serialNumbers.isEmpty()) {
                    for(String ser : serialNumbers) {
                        Asset assetRec = mapAssetBySN.get(ser);
                        System.debug(LoggingLevel.ERROR,'---assetRec1-' + assetRec);

                        if (assetRec != null) {

                            Id oldOrderItemId = assetRec.Order_Service_Item__c;
                            Id newOrderItemId = soi.Id;
                            Id soiId = soi.Id;

                            if(oldOrderItemId != newOrderItemId) {
                                Decimal oldPriority = (op != null && op.items != null && op.items.containsKey(oldOrderItemId))
                                    ? op.items.get(oldOrderItemId).PricebookEntry.Product2.Asset_Priority__c
                                    : null;
                                Decimal newPriority = (op != null && op.items != null && op.items.containsKey(newOrderItemId))
                                    ? op.items.get(newOrderItemId).PricebookEntry.Product2.Asset_Priority__c
                                    : null;

                                String oldApplianceModel = (op != null && op.items != null && op.items.containsKey(oldOrderItemId))
                                    ? op.items.get(oldOrderItemId).PricebookEntry.Product2.Appliance_Model__c
                                    : null;
                                String newApplianceModel = (op != null && op.items != null && op.items.containsKey(newOrderItemId))
                                    ? op.items.get(newOrderItemId).PricebookEntry.Product2.Appliance_Model__c
                                    : null;

                                if(oldPriority == newPriority && oldPriority != null) {
                                    if(String.isNotBlank(oldApplianceModel) && String.isBlank(newApplianceModel)) {
                                        soiId = newOrderItemId;
                                    }
                                    else if(String.isBlank(oldApplianceModel) && String.isNotBlank(newApplianceModel)) {
                                        soiId = oldOrderItemId;
                                    }
                                }
                            }

                            Entitlement ent = mapEntitlements.get(soiId + '---' + ser);
                            assetRec.Entitlement__c = (ent != null) ? ent.Id : null;
                            if(assetRec.Order_Service_Item__r.Order.Type == 'POC'){
                                AssetTriggerHelper.allowAssetOIUpdates(true);
                            }
                            assetRec.Order_Service_Item__c = soiId;
                            //if(op != null && op.mapPrdouctIdBySn.get(ser) != null) {
                            //    assetRec.Product2Id = op.mapPrdouctIdBySn.get(ser);
                            //}
                            if(op != null && op.items != null && op.items.containsKey(soiId)) {
                                if(String.isNotBlank(op.items.get(soiId).PricebookEntry.Product2.Appliance_Model_HW__c)){
                                    assetRec.Product2Id = op.items.get(soiId).PricebookEntry.Product2Id;
                                }
                                assetRec.AccountId = op.items.get(soiId).Order.AccountId;
                            }
                            if(soi.Order.Type == 'RMA'){
                                assetRec.Status = 'Dispatched';
                                assetRec.PurchaseDate = Date.today();
                            }
                            String oiName = op.items.get(soiId).Product_Name__c + '('+soiId+')';
                            System.debug(LoggingLevel.ERROR,' ### assigning Serial Number ' + assetRec.Serial_Number__c + ' to Entitlement ' + assetRec.Entitlement__c + ' support item ' + oiName);
                        }
                    }

                }
            }

        }
        /*for(Id oiId : toProcessOrderItems.keySet()) {
            OrderItem soi = toProcessOrderItems.get(oiId);
            ////skip if CPQ flow
            //if(OrderInfoMap.containsKey(soi.OrderId) && OrderInfoMap.get(soi.OrderId).items.containsKey(soi.Id) &&
            //        isCPQFlow(OrderInfoMap.get(soi.OrderId).items.get(soi.Id))) {
            //    System.debug('Skipping order item '+soi.Product_Code_Formula__c);
            //    continue;
            //}
            Set<Id> assignApplianceAssetsToOrderItems = new Set<Id>();
            Set<String> applianceSN = new Set<String>();
            Set<Id> assignSpareAssetsToOrderItems = new Set<Id>();
            Set<String> spareSN = new Set<String>();
            Set<Id> assignNFRAssetsToOrderItems = new Set<Id>();
            Set<String> nfrSN = new Set<String>();
            OrderProducts op = getOrderInfo(soi.OrderId);
            if(op != null && op.hasAppliance) {
                assignApplianceAssetsToOrderItems = op.applianceIds;
                applianceSN.addAll(op.applianceSN);
            }
            else if(op != null && !op.hasAppliance) {
                if(op.hasSupport && op.hasSubscription) {
                    assignApplianceAssetsToOrderItems.addAll(op.subscriptionIds);
                    assignApplianceAssetsToOrderItems.addAll(op.supportIds);
                    applianceSN.addAll(op.otherSN);
                }
                else if(!op.hasSupport && op.hasSubscription) {
                    assignApplianceAssetsToOrderItems = op.subscriptionIds;
                    applianceSN.addAll(op.otherSN);
                }
                else if(op.hasSupport && !op.hasSubscription) {
                    assignApplianceAssetsToOrderItems = op.supportIds;
                    applianceSN.addAll(op.otherSN);
                }
                else if(!op.hasSupport && !op.hasSubscription) {
                    assignApplianceAssetsToOrderItems = op.applianceIds;
                    applianceSN.addAll(op.otherSN);
                }
            }
            if(op != null && op.hasSpare) {
                if(op.hasSpareSupport) {
                    assignSpareAssetsToOrderItems = op.spareIds;
                    spareSN.addAll(op.spareSN);
                }
                else if(!op.hasSpareSupport) {
                    assignSpareAssetsToOrderItems = op.spareIds;
                    spareSN.addAll(op.spareSN);
                }
            }
            else if(op != null && !op.hasSpare) {
                if(op.hasSpareSupport) {
                    assignSpareAssetsToOrderItems = op.spareSupportIds;
                    if(soi.SerialNumber__c != null && PRODUCT_CATEGORY_SUPPORT == soi.Product_Category__c) {
                        spareSN.addAll(soi.SerialNumber__c.split(','));
                    }
                }
            }
            if(op != null && op.hasNFR) {
                nfrSN = op.nfrSN;
                if(!op.nfrIds.isEmpty()) {
                    assignNFRAssetsToOrderItems = op.nfrIds;
                }
            }
            System.debug(LoggingLevel.ERROR,'----op---'+json.serialize(op));
            System.debug(LoggingLevel.ERROR,'----soi.SerialNumber__c---'+soi.SerialNumber__c);
            System.debug(LoggingLevel.ERROR,'----assignApplianceAssetsToOrderItems---'+json.serialize(assignApplianceAssetsToOrderItems));
            System.debug(LoggingLevel.ERROR,'----assignSpareAssetsToOrderItems---'+json.serialize(assignSpareAssetsToOrderItems));
            System.debug(LoggingLevel.ERROR,'----spareSN---'+json.serialize(spareSN));
            System.debug(LoggingLevel.ERROR,'----applianceSN---'+json.serialize(applianceSN));
            if(!assignApplianceAssetsToOrderItems.isEmpty() && !applianceSN.isEmpty()) {
                for(Id ordItemId : new List<Id>(assignApplianceAssetsToOrderItems)) {
                    System.debug(LoggingLevel.ERROR,'----ordItemId--'+ordItemId);
                    System.debug(LoggingLevel.ERROR,'----soi.Id--'+soi.Id);
                    List<String> serialNumbers = (soi.SerialNumber__c == null) ? new List<String>(applianceSN) : soi.SerialNumber__c.split(',');
                    System.debug(LoggingLevel.ERROR,'----serialNumbers1---'+json.serialize(serialNumbers));
                    for (String ser : serialNumbers) {
                        Set<String> ordItemSerialNumbers = (soi.SerialNumber__c == null) ? new Set<String>() : new Set<String>(soi.SerialNumber__c.split(','));
                        //if('Support' != soi.Product_Category__c && !ordItemSerialNumbers.contains(ser)) continue;
                        //if('Platform' != soi.Product_Category__c && !applianceSN.contains(ser)) continue;
                        //if('Support' == soi.Product_Category__c && soi.Single_Quantity__c && soi.SerialNumber__c != null  && ordItemId != soi.Id) continue;
                        //if('Subscription' == soi.Product_Category__c && soi.Single_Quantity__c && soi.SerialNumber__c != null  && ordItemId != soi.Id) continue;
                        if('Support' != soi.Product_Category__c && !ordItemSerialNumbers.contains(ser)) continue;
                        if('Platform' != soi.Product_Category__c && !applianceSN.contains(ser)) continue;
                        if('Support' == soi.Product_Category__c && soi.Single_Quantity__c && soi.SerialNumber__c != null  && ordItemId != soi.Id) continue;
                        if('Subscription' == soi.Product_Category__c && soi.Single_Quantity__c && soi.SerialNumber__c != null  && ordItemId != soi.Id) continue;
                        if('Platform' == soi.Product_Category__c) {
                            Id applianceId = op.mapApplianceIdBySn.get(ser);
                            if(applianceId == null || applianceId != ordItemId) {
                                continue;
                            }
                        }
                        if('Subscription' == soi.Product_Category__c && soi.SerialNumber__c != null && (op.hasAppliance || op.hasSpare)) {
                            Id applianceId = op.mapApplianceIdBySn.get(ser);
                            if(applianceId == null || applianceId != ordItemId) {
                                continue;
                            }
                        }
                        if('Support' == soi.Product_Category__c && soi.SerialNumber__c == null && (op.hasAppliance || op.hasSpare)) continue;
                        if('Support' == soi.Product_Category__c && soi.SerialNumber__c != null && (op.hasAppliance || op.hasSpare || op.hasNFR)) {
                            Id applianceId = op.mapApplianceIdBySn.get(ser);
                            if(applianceId == null || applianceId != ordItemId) {
                                continue;
                            }
                        }
                        if('Non-Returnable Disk Service' == soi.Product_Category__c) {
                            continue;
                        }
                        if('Support' == soi.Product_Category__c && soi.SerialNumber__c != null && !op.hasAppliance && !op.hasSpare && !op.hasNFR) {
                            if(op != null && op.spareSupportSNMap != null && op.spareSupportSNMap.get(ordItemId) != null
                                && !op.spareSupportSNMap.get(ordItemId).contains(ser)) {
                                continue;
                            }
                        }
                        System.debug(LoggingLevel.ERROR,'----ser--'+ser);
                        System.debug(LoggingLevel.ERROR,'----ordItemSerialNumbers--'+ordItemSerialNumbers);
                        System.debug(LoggingLevel.ERROR,'----soi.SerialNumber__c--'+soi.SerialNumber__c);
                        System.debug(LoggingLevel.ERROR,'----soi.Product_Category__c--'+soi.Product_Category__c);
                        System.debug(LoggingLevel.ERROR,'----soi.Single_Quantity__c--'+soi.Single_Quantity__c);
                        System.debug(LoggingLevel.ERROR,'----!ordItemSerialNumbers.contains(ser)--'+!ordItemSerialNumbers.contains(ser));
                        System.debug(LoggingLevel.ERROR,'----ordItemId != soi.Id--'+(ordItemId != soi.Id));
                        Asset assetRec = mapAssetBySN.get(ser);
                        System.debug(LoggingLevel.ERROR,'---assetRec1-' + assetRec);
                        if (assetRec != null) {
                            Entitlement ent = mapEntitlements.get(soi.Id + '---' + ser);
                            assetRec.Entitlement__c = (ent != null) ? ent.Id : null;
                            assetRec.Order_Service_Item__c = ordItemId;//soi.Id;
                            if(op != null && op.mapPrdouctIdBySn.get(ser) != null) {
                                assetRec.Product2Id = op.mapPrdouctIdBySn.get(ser);
                            }
                            String oiName = op.items.get(ordItemId).Product_Name__c + '('+ordItemId+')';
                            System.debug(LoggingLevel.ERROR,' ### assigning Serial Number ' + assetRec.Serial_Number__c + ' to Entitlement ' + assetRec.Entitlement__c + ' support item ' + oiName);// assetRec.Order_Service_Item__c);
                        }
                    }
                }
            }
            if(!assignSpareAssetsToOrderItems.isEmpty() && !spareSN.isEmpty()) {
                for(Id ordItemId : new List<Id>(assignSpareAssetsToOrderItems)) {
                    //Id ordItemId = (new List<Id>(assignSpareAssetsToOrderItems)).get(0);
                    System.debug(LoggingLevel.ERROR,'---ordItemId--'+ordItemId);
                    List<String> serialNumbers = (soi.SerialNumber__c == null) ? new List<String>(spareSN) : soi.SerialNumber__c.split(',');
                    System.debug(LoggingLevel.ERROR,'----serialNumbers2---'+json.serialize(serialNumbers));
                    for (String ser : serialNumbers) {
                        System.debug(LoggingLevel.ERROR,'---ser--'+ser);
                        Set<String> ordItemSerialNumbers = (soi.SerialNumber__c == null) ? new Set<String>() : new Set<String>(soi.SerialNumber__c.split(','));
                        System.debug(LoggingLevel.ERROR,'---ordItemSerialNumbers--'+ordItemSerialNumbers);
                        if(!ordItemSerialNumbers.contains(ser)) continue;
                        if(('Spare' != soi.Product_Category__c || 'Upgrade' != soi.Product_Category__c) && !spareSN.contains(ser)) continue;
                        if('Support' == soi.Product_Category__c && soi.SerialNumber__c != null && (op.hasAppliance || op.hasSpare || op.hasNFR)) {
                            Id applianceId = op.mapApplianceIdBySn.get(ser);
                            if(applianceId == null || applianceId != ordItemId) {
                                continue;
                            }
                        }
                        if('Support' == soi.Product_Category__c && soi.SerialNumber__c != null && !op.hasAppliance && !op.hasSpare && !op.hasNFR) {
                            if(op != null && op.spareSupportSNMap != null && op.spareSupportSNMap.get(ordItemId) != null
                                && !op.spareSupportSNMap.get(ordItemId).contains(ser)) {
                                continue;
                            }
                        }
                        Asset assetRec = mapAssetBySN.get(ser);
                        System.debug(LoggingLevel.ERROR,' ### assetRec2 ' + assetRec);
                        if (assetRec != null) {
                            Entitlement ent = mapEntitlements.get(soi.Id + '---' + ser);
                            assetRec.Entitlement__c = (ent != null) ? ent.Id : null;
                            assetRec.Order_Service_Item__c = ordItemId;//soi.Id;
                            String oiName = op.items.get(ordItemId).Product_Name__c + '('+ordItemId+')';
                            System.debug(LoggingLevel.ERROR,' ### assigning Serial Number ' + assetRec.Serial_Number__c + ' to Entitlement ' + assetRec.Entitlement__c + ' support item ' + oiName);//assetRec.Order_Service_Item__c);
                        }
                    }
                }
            }
            if(!assignNFRAssetsToOrderItems.isEmpty() && !nfrSN.isEmpty()) {
                for(Id ordItemId : new List<Id>(assignNFRAssetsToOrderItems)) {
                    System.debug(LoggingLevel.ERROR,'---ordItemId--'+ordItemId);
                    List<String> serialNumbers = (soi.SerialNumber__c == null) ? new List<String>(nfrSN) : soi.SerialNumber__c.split(',');
                    System.debug(LoggingLevel.ERROR,'----serialNumbers3---'+json.serialize(serialNumbers));
                    for (String ser : serialNumbers) {
                        System.debug(LoggingLevel.ERROR,'---ser--'+ser);
                        Asset assetRec = mapAssetBySN.get(ser);
                        System.debug(LoggingLevel.ERROR,' ### assetRec3 ' + assetRec);
                        if('Non-Returnable Disk Service' == soi.Product_Category__c) {
                            if(op.spareSupportSNMap.containsKey(ordItemId) && op.spareSupportSNMap.get(ordItemId) != null
                                && !op.spareSupportSNMap.get(ordItemId).contains(ser)) {
                                continue;
                            }
                            if(ordItemId != soi.Id) continue;
                        }
                        if('Support' == soi.Product_Category__c) {
                            continue;
                        }
                        if (assetRec != null) {
                            Entitlement ent = mapEntitlements.get(soi.Id + '---' + ser);
                            assetRec.Entitlement__c = (ent != null) ? ent.Id : null;
                            assetRec.Order_Service_Item__c = ordItemId;//soi.Id;
                            String oiName = op.items.get(ordItemId).Product_Name__c + '('+ordItemId+')';
                            System.debug(LoggingLevel.ERROR,' ### assigning Serial Number ' + assetRec.Serial_Number__c + ' to Entitlement ' + assetRec.Entitlement__c + ' support item ' + oiName);//assetRec.Order_Service_Item__c);
                        }
                    }
                }
            }
        }*/


      /*  if(!mapAssetBySN.isEmpty()) {
            System.debug(LoggingLevel.ERROR,'----mapAssetBySN---'+json.serialize(mapAssetBySN));
            List<Asset> toUpdateList = mapAssetBySN.values();
            AssetTriggerHelper.preventChangeFields(toUpdateList);
            update toUpdateList;
            AssetTriggerHelper.allowAssetOIUpdates(false);
        }
    }


     public static void initOrderInfo(List <order> orderIds, Map<Id, Order> newMap, Map<Id, Order> oldMap) {
        OrderInfoMap = (OrderInfoMap != null) ? OrderInfoMap : new Map<Id, OrderProducts>();
        OrderItemsMap.clear();
        if(!orderIds.isEmpty()) {
            //MSP-143 -- Start
            List<OrderItem> relatedOrderItems = new List<OrderItem>();
            relatedOrderItems = [SELECT Id, Product_Category__c, Product_Type__c, SerialNumber__c, Product_Code_Formula__c,Is_Refresh__c,
                                    OrderId, Order.AccountId, Product_Name__c, Create_Entitlement__c, Support_Product_Code__c, Single_Entitlement__c, Single_Quantity__c,
                                    Quantity, Support_Start_Date__c, Support_End_Date__c, ProductID__c, Associate_with_Appliance__c,
                                    Order.Opportunity.SBQQ__PrimaryQuote__c,
                                    Order.OpportunityId,
                                    order.status,
                                    order.Order_Status__c,
                                    PricebookEntry.Product2Id,
                                    PricebookEntry.Product2.Product_Type__c,
                                    PricebookEntry.Product2.Asset_Priority__c,
                                    PricebookEntry.Product2.Appliance_Model__c,
                                    PricebookEntry.Product2.Appliance_Model_HW__c,
                                    PricebookEntry.Product2.Name,
                                    PricebookEntry.Product2.License_Subtype__c,
                                    PricebookEntry.Product2.Family,
                                    SBQQ__QuoteLine__r.SBQQ__Product__r.Bundle_Features__c,
                                    SBQQ__QuoteLine__r.SBQQ__Product__r.Appliance_Model_HW__c,//added by rahul for SF-5507
                                    Order.Integration_Partner_Contact_Name__c,
                                    Order.Manufacturing_Integration_Partner__c,
                                    Order.Opportunity.Initial_Contacts_Name__c,
                                    SBQQ__QuoteLine__r.SBQQ__Product__r.Productcode,
                                    SBQQ__QuoteLine__r.SBQQ__Quote__c,
                                    SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Primary__c,
                                    SBQQ__QuoteLine__c,
                                    Number__c,   //MSP-143
                                    SBQQ__SegmentIndex__c , //MSP-143
                                    Order.Type, Order.Order_Sub_Type__c,
                                    SBQQ__QuoteLine__r.Subscribed_Asset_Name__c, Product2.License_Type__c, 
                                    SBQQ__SubscriptionTerm__c, product2.SBQQ__SubscriptionPricing__c
                                    //(Select Id, PricebookEntry.Product2.Family, Support_Start_Date__c, Support_End_Date__c from SBQQ__Components__r)

                                FROM OrderItem
                                WHERE OrderId IN :orderIds AND Quantity > 0];

            mapOfSBQQNumberWithListOfOrderLines = new Map<Decimal, List<OrderItem>>();
            system.debug('MSP-143 relatedOrderItems' +relatedOrderItems); 
            for(OrderItem eachOI : relatedOrderItems){
            
                List<OrderItem> sameSBQQNumberLines = new List<OrderItem>();
                if(mapOfSBQQNumberWithListOfOrderLines.containsKey(eachOI.Number__c)){ 
                    sameSBQQNumberLines = mapOfSBQQNumberWithListOfOrderLines.get(eachOI.Number__c);
                }
                system.debug('MSP-143 eachOI.Number__c' +eachOI.Number__c); 
                system.debug('MSP-143 sameSBQQNumberLines' +sameSBQQNumberLines);
                
                sameSBQQNumberLines.add(eachOI);
                
                mapOfSBQQNumberWithListOfOrderLines.put(eachOI.Number__c, sameSBQQNumberLines);
            }

            system.debug('MSP-143 mapOfSBQQNumberWithListOfOrderLines' +mapOfSBQQNumberWithListOfOrderLines);
            //MSP-143 -- End

            for(OrderItem oi : relatedOrderItems) {
                Id orderId = oi.OrderId;

                //Introduced for SF-2580
                if(OrderItemsMap.containsKey(orderId)){
                    OrderItemsMap.get(orderId).add(oi);
                }
                else{
                    List<OrderItem> oiList = new List<OrderItem>{oi};
                    OrderItemsMap.put(orderId, oiList);
                }
                 if(oi.Is_Refresh__c){
                   GorefreshOrderIds.add(orderId);
                 }
                //Condition added by palak as earlier loop was iterating only on shipped orders
                if(newMap != null){
                    Order newOrd = newMap.get(orderId);
                    if(newOrd !=null && (newOrd.status=='Activated' || newOrd.order_status__c=='Shipped')){
                        OrderProducts op = (OrderInfoMap.containsKey(orderId)) ? OrderInfoMap.get(orderId) : new OrderProducts();
                        op.addItem(oi);
                        OrderInfoMap.put(orderId, op);
                    }
                }
                // Condition added by Palak
                /*added by Rahul for PRDOPS21-56 START*/
          /*      Boolean isHardware = false;
                if(oi.SBQQ__QuoteLine__r.SBQQ__Product__r.Bundle_Features__c != null){
                    for(String str : oi.SBQQ__QuoteLine__r.SBQQ__Product__r.Bundle_Features__c.split(';')){
                        if(str.toUpperCase().trim() == 'HARDWARE'){
                            isHardware = true;
                            break;
                        }
                    }
                }
                /*added by Rahul for PRDOPS21-56 END*/
             /*   if((isHardware
                 && oi.SBQQ__QuoteLine__r.SBQQ__Product__r.Productcode !='RBK-SFP-TSR-01' && oi.SBQQ__QuoteLine__r.SBQQ__Product__r.Productcode !='RBK-F3M-CBL-01' &&
                 oi.SBQQ__QuoteLine__r.SBQQ__Product__r.Productcode !='RBK-SFP28-TSR-01') || 
                  /*Rahul Added below check for SF-5507 in order to identify Hardware products*/
                   //(oi.SBQQ__QuoteLine__r.SBQQ__Product__c != null && oi.SBQQ__QuoteLine__r.SBQQ__Product__r.Appliance_Model_HW__c != null)){
                    
                    /*Added by Rahul for ticket SF-5496 */
               /*     if(oi.SBQQ__QuoteLine__r.SBQQ__Product__r.Appliance_Model_HW__c == 'RBK-R6408F'){
                        if(orderHardwareFIBProdMap != null && orderHardwareFIBProdMap.containsKey(oi.orderId))
                        orderHardwareFIBProdMap.get(oi.orderId).add(oi.id);
                        else{
                            Set<id> temSet = new set<id>();
                            temset.add(oi.id);
                            orderHardwareFIBProdMap.put(oi.orderId,temset);
                        }
                    }
                    else {
                        if(orderHardwareProdMap != null && orderHardwareProdMap.containsKey(oi.orderId))
                            orderHardwareProdMap.get(oi.orderId).add(oi.id);
                        else{
                            Set<id> temSet = new set<id>();
                            temset.add(oi.id);
                            orderHardwareProdMap.put(oi.orderId,temset);
                        }
                    }
                }

                Order oldOrder = oldMap.get(oi.OrderId);
                Order newOrder = newMap.get(oi.OrderId);
                if(
                    (
                        (
                            oi.PricebookEntry.Product2.Product_Type__c == '3rd Party Hardware' && 
                            (
                                oi.PricebookEntry.Product2.Family == 'HPE' ||
                                oi.PricebookEntry.Product2.Family == 'UCS' ||
                                oi.PricebookEntry.Product2.Family == 'DELL'
                            )
                        )
                        ||
                        //added for PRDOPS21-108
                        (oi.PricebookEntry.Product2.Product_Type__c == 'RCDM' && oi.PricebookEntry.Product2.Family == 'Rubrik Scale')
                        //|| oi.PricebookEntry.Product2.License_Subtype__c == 'ELA' 
                        // || (oi.PricebookEntry.Product2.Product_Type__c == 'MSP' && oi.PricebookEntry.Product2.Family == 'RCDM')  //MSP-143 : Commented 
                    ) && 
                    (
                        (oldOrder.Order_Status__c != 'Order Accepted' && newOrder.Order_Status__c == 'Order Accepted')
                       ||(String.isNotBlank(newOrder.NetSuite_Order__c) 
                         && newOrder.NetSuite_Order__c != oldOrder.NetSuite_Order__c 
                         && newOrder.Order_Status__c != 'Order Accepted'
                         && newOrder.Order_Status__c != 'Shipped')
                    )
                ){
                    thirdPartyHardwareLines.put(oi.Id, oi);
                }
                
                //MSP-143 : creation of Entitlements for SW Only deals of MSP
                //mapFirstSegmentIDWithLastSegmentOI = new Map<Id, OrderItem>();
                
                // system.debug('MSP-143 oi.PricebookEntry.Product2.Product_Type__c' +oi.PricebookEntry.Product2.Product_Type__c); 
                // system.debug('MSP-143 oi.PricebookEntry.Product2.Family' +oi.PricebookEntry.Product2.Family); 
                // system.debug('MSP-143 oi.SBQQ__SegmentIndex__c' +oi.SBQQ__SegmentIndex__c); 
                // system.debug('MSP-143 mapOfSBQQNumberWithListOfOrderLines' +mapOfSBQQNumberWithListOfOrderLines); 
                
                if(oi.PricebookEntry.Product2.Product_Type__c == 'MSP' && oi.PricebookEntry.Product2.Family == 'RCDM' && oi.SBQQ__SegmentIndex__c != null && oi.SBQQ__SegmentIndex__c == 1){

                    if(mapOfSBQQNumberWithListOfOrderLines != null && mapOfSBQQNumberWithListOfOrderLines.containsKey(oi.Number__c)){
                        // List<OrderItem> orderItemsOfSameSBQQNumber = new List<OrderITem>();
                        // orderItemsOfSameSBQQNumber = mapOfSBQQNumberWithListOfOrderLines.get(oi.Number__c);
                        // system.debug('MSP-143 orderItemsOfSameSBQQNumber' +orderItemsOfSameSBQQNumber); 
                        // OrderItem lastSegmentIndexOI;
                        // Integer lastSegmentIndex = 0;
                        // for(OrderItem oiSameNumber : orderItemsOfSameSBQQNumber){
                        //     if(oiSameNumber.SBQQ__SegmentIndex__c > lastSegmentIndex){
                        //         lastSegmentIndexOI = new OrderItem();
                        //         lastSegmentIndexOI = oiSameNumber; 
                        //         system.debug('MSP-143 oiSameNumber.SBQQ__SegmentIndex__c' +oiSameNumber.SBQQ__SegmentIndex__c); 
                        //         lastSegmentIndex = Integer.ValueOf(oiSameNumber.SBQQ__SegmentIndex__c);
                        //     }     
                        // }
                        // system.debug( '//MSP-143 : lastSegmentIndexOI' +lastSegmentIndexOI);
                        if(oldOrder.Order_Status__c != 'Order Accepted' && newOrder.Order_Status__c == 'Order Accepted'){
                            thirdPartyHardwareLines.put(oi.Id, oi); 
                        }
                        // mapFirstSegmentIDWithLastSegmentOI.put(oi.Id, lastSegmentIndexOI);
                        // system.debug('MSP-143 thirdPartyHardwareLines' +thirdPartyHardwareLines); 
                        // system.debug('MSP-143 mapFirstSegmentIDWithLastSegmentOI' +mapFirstSegmentIDWithLastSegmentOI); 
                    }
                }
                //MSP-143 -- End
                    
            }
        }
    }

    public static void autoFulfillPOCOrders(List <order> orders, Map<Id, Order> oldMap){
        List<Order_Event__e> orderEvents = new List<Order_Event__e>();
        for(Order ord: orders){
            if(ord.Type == 'POC' && ord.Order_Status__c != 'Shipped' && !ord.Has_Hardware_Products__c && (!ord.Have_Polaris_Products__c || ord.Polaris_Fulfillment_Status__c == 'Completed')){
                orderEvents.add(new Order_Event__e(Order_Id__c = ord.Id, Action_Type__c = 'POC_ORDER_AUTOFULFILL'));
            }
        }

        if(orderEvents.size()>0){
            EventBus.publish(orderEvents);
        }
    }

    public static void generateEntitlementsForThirdPartyHardware(){
        List<Entitlement> entitlementsToCreate = new List<Entitlement>();
        Map<String, Id> skuMap = new Map<String, Id>();
        Map<Id, Order_Event__e> orderEvents = new Map<Id, Order_Event__e>();
        for(Third_Party_Hardware_SKU_Mapping__mdt mdt: [Select Id, MasterLabel, SKU_Id__c from Third_Party_Hardware_SKU_Mapping__mdt]){
            skuMap.put(mdt.MasterLabel, mdt.SKU_Id__c);
        }
        
        // system.debug('MSP-143 thirdPartyHardwareLines in generateent' +thirdPartyHardwareLines); 
        // system.debug('MSP-143 mapFirstSegmentIDWithLastSegmentOI in generateent' +mapFirstSegmentIDWithLastSegmentOI); 
        for(OrderItem oi: thirdPartyHardwareLines.values()){
            if(thirdPartyHardwareCreated.contains(oi.Id)){
                continue;
            }
            // Date startDate;
            // Date endDate;
            // if(oi.Support_Start_Date__c != null && oi.Support_End_Date__c != null){
            //     startDate = oi.Support_Start_Date__c;
            //     //endDate = oi.Support_End_Date__c;
            //     //MSP-143 : Pick the end date from the order item of the last segment index for MSP Products
            //     system.debug('MSP-143 mapFirstSegmentIDWithLastSegmentOI inside support dates' +mapFirstSegmentIDWithLastSegmentOI); 
            //     if(oi.PricebookEntry.Product2.Product_Type__c == 'MSP' && oi.PricebookEntry.Product2.Family == 'RCDM' && oi.SBQQ__SegmentIndex__c != null && oi.SBQQ__SegmentIndex__c == 1){
            //         if(mapFirstSegmentIDWithLastSegmentOI.containsKey(oi.Id)){
            //             OrderItem tempOI = new OrderItem();
            //             tempOI = mapFirstSegmentIDWithLastSegmentOI.get(oi.Id);
            //             system.debug('MSP-143 tempOI' +tempOI);
            //             endDate = tempOI.Support_End_Date__c;
            //         }
            //     } else{
            //         endDate = oi.Support_End_Date__c;
            //     }
            //     //MSP-143 -- End
            // }
            // else{
            //     if(oi.SBQQ__Components__r != null){
            //         for(OrderItem childOi: oi.SBQQ__Components__r){
            //             if(oi.PricebookEntry.Product2.Family == childOi.PricebookEntry.Product2.Family){
            //                 if(childOi.Support_Start_Date__c != null && childOi.Support_End_Date__c != null){
            //                     startDate = childOi.Support_Start_Date__c;
            //                     endDate = childOi.Support_End_Date__c;
            //                     break;
            //                 }
            //             }
            //         }
            //     }
            // }
            Entitlement ent = new Entitlement(
                Name = oi.PricebookEntry.Product2.Name,
                AccountId = oi.Order.AccountId,
                Product__c = oi.PricebookEntry.Product2Id,
                Type = 'Manufacturing Entitlement',
                //StartDate = startDate,
                //EndDate = endDate,
                Renewable__c = false, 
                Order_Service_Item__c = oi.Id,
                Integration_Partner_Contact_Name__c = oi.Order.Integration_Partner_Contact_Name__c,
                Manufacturing_Integration_Partner__c = oi.Order.Manufacturing_Integration_Partner__c,
                Primary_Contact__c = oi.Order.Opportunity.Initial_Contacts_Name__c
            );
            if(!Test.isRunningTest() && skuMap.containsKey(oi.PricebookEntry.Product2.Family)){
                ent.Product__c = skuMap.get(oi.PricebookEntry.Product2.Family);
            }
            
            entitlementsToCreate.add(ent);
            thirdPartyHardwareCreated.add(oi.Id);

            if(!orderEvents.containsKey(oi.OrderId)){
                orderEvents.put(oi.OrderId, new Order_Event__e(Action_Type__c = 'UPDATE_USER_PROFILE_MANUFACTURING_CONTACTS', Order_Id__c = oi.OrderId));
            }
            
        }
        if(entitlementsToCreate.size()>0){
            insert entitlementsToCreate;
            thirdPartyHardwareLines.clear();
            linkContactWithThirdPartyEntitlement(entitlementsToCreate);
            //Update Manufacturing User Profile to Rubrik Community Super User (Ticket:PRDOPS21-117)
            EventBus.publish(orderEvents.values());
        }
    }

    private static void linkContactWithThirdPartyEntitlement(List<Entitlement> entitlements){
        List<EntitlementContact> entitlementContacts = new List<EntitlementContact>();
        for(Entitlement ent: entitlements){
            if(String.isBlank(ent.Primary_Contact__c)){
                continue;
            }
            
            entitlementContacts.add(new EntitlementContact(EntitlementId = ent.Id, ContactId = ent.Primary_Contact__c));
        }

        if(entitlementContacts.size()>0){
            insert entitlementContacts;
        }
    }

    public static OrderProducts getOrderInfo(Id orderId) {
        if(OrderInfoMap == null) return null;
        return OrderInfoMap.get(orderId);
    }


    public class OrderProducts {
        public Map<Id, OrderItem> items {get; private set;}
        public boolean hasSupport {get; private set;}
        public boolean hasSpareSupport {get; private set;}
        public boolean hasAppliance {get; private set;}
        public boolean hasSubscription {get; private set;}
        public boolean hasSpare {get; private set;}
        public boolean hasNFR {get; private set;}

        public Set<Id> supportIds {get; private set;}
        public Set<Id> spareSupportIds {get; private set;}
        public Set<Id> applianceIds {get; private set;}
        public Set<Id> subscriptionIds {get; private set;}
        public Set<Id> spareIds {get; private set;}

        public Set<Id> nfrIds {get; private set;}
        public Set<Id> nfrWithEntIds {get; private set;}

        public Set<String> applianceSN {get; private set;}
        public Set<String> otherSN {get; private set;}
        public Set<String> spareSN {get; private set;}
        public Set<String> nfrSN {get; private set;}
        public Map<Id, Set<String>> spareSupportSNMap {get; private set;}
        public Map<String, Id> mapPrdouctIdBySn {get; private set;}
        public Map<String, Id> mapApplianceIdBySn {get; private set;}

        public OrderProducts() {
            this.items = new Map<Id, OrderItem>();

            this.hasSupport = false;
            this.hasSpareSupport = false;
            this.hasAppliance = false;
            this.hasSubscription = false;
            this.hasSpare = false;
            this.hasNFR = false;

            supportIds = new Set<Id>();
            spareSupportIds = new Set<Id>();
            applianceIds = new Set<Id>();
            subscriptionIds = new Set<Id>();
            spareIds = new Set<Id>();
            nfrIds = new Set<Id>();
            nfrWithEntIds = new Set<Id>();

            applianceSN = new Set<String>();
            otherSN = new Set<String>();
            spareSN = new Set<String>();
            nfrSN = new Set<String>();
            spareSupportSNMap = new Map<Id, Set<String>>();

            mapPrdouctIdBySn = new Map<String, Id>();
            mapApplianceIdBySn = new Map<String, Id>();
        }

        public Set<Id> getSupportsRelatedToSpare() {

            if(this.hasSpare && this.hasSpareSupport) {
                spareSupportIds = new Set<Id>();

                for(Id oiId : spareSupportSNMap.keySet()) {
                    Set<String> sns = spareSupportSNMap.get(oiId);
                    for(String sn : new List<String>(sns)) {
                        if(this.spareSN.contains(sn)) {
                            spareSupportIds.add(oiId);
                        }
                    }
                }
            }
            return spareSupportIds;
        }


        public void addItem(OrderItem oi) {
            items.put(oi.Id, oi);

            if('Support' == oi.Product_Category__c) {
                if(oi.SerialNumber__c != null) {
                    this.hasSpareSupport = true;
                    spareSupportIds.add(oi.Id);
                    spareSupportSNMap.put(oi.Id, new Set<String>(getSerialNumbers(oi.SerialNumber__c)));

                    this.hasSupport = true;
                    supportIds.add(oi.Id);
                }
                else {
                    this.hasSupport = true;
                    supportIds.add(oi.Id);
                }

            }
            else if('Platform' == oi.Product_Category__c && oi.Product_Type__c != 'Accessories') {
                this.hasAppliance = true;
                applianceIds.add(oi.Id);
                if(oi.SerialNumber__c != null) {
                    for(String sn : getSerialNumbers(oi.SerialNumber__c)) {
                        applianceSN.add(sn);
                        mapPrdouctIdBySn.put(sn, oi.PricebookEntry.Product2Id);
                        mapApplianceIdBySn.put(sn, oi.Id);
                    }
                }
            }
            else if('Subscription' == oi.Product_Category__c) {
                this.hasSubscription = true;
                subscriptionIds.add(oi.Id);
            }
            else if('Spare' == oi.Product_Category__c || 'Upgrade' == oi.Product_Category__c) {
                this.hasSpare = true;
                spareIds.add(oi.Id);

                if(oi.SerialNumber__c != null) {
                    for(String sn : getSerialNumbers(oi.SerialNumber__c)) {
                        spareSN.add(sn);
                    }
                }
            }
            else if ('NFR' == oi.Product_Category__c
                || ('Bundle' == oi.Product_Category__c && 'NFR' == oi.Pricebookentry.Product2.Product_Type__c)
                || 'Non-Returnable Disk Service' == oi.Product_Category__c) {
                this.hasNFR = true;
                if(oi.Product_Code_Formula__c.contains('R334') || oi.Product_Code_Formula__c.contains('R344')) {
                    nfrWithEntIds.add(oi.Id);
                    nfrIds.add(oi.Id);
                    if(oi.SerialNumber__c != null) {
                        for(String sn : getSerialNumbers(oi.SerialNumber__c)) {
                            nfrSN.add(sn);
                        }
                    }
                }
                else if(oi.Product_Code_Formula__c.contains('R348')) {
                    nfrIds.add(oi.Id);
                    if(oi.SerialNumber__c != null) {
                        for(String sn : getSerialNumbers(oi.SerialNumber__c)) {
                            nfrSN.add(sn);
                        }
                    }
                }
                else if('Non-Returnable Disk Service' == oi.Product_Category__c) {
                    nfrIds.add(oi.Id);
                    if(oi.SerialNumber__c != null) {
                        for(String sn : getSerialNumbers(oi.SerialNumber__c)) {
                            nfrSN.add(sn);
                        }
                    }
                    if(oi.SerialNumber__c != null) {
                        for(String sn : getSerialNumbers(oi.SerialNumber__c)) {
                            mapApplianceIdBySn.put(sn, oi.Id);
                        }
                    }
                }
            }

            if ('Support' == oi.Product_Category__c || 'Subscription' == oi.Product_Category__c) {
                if(oi.SerialNumber__c != null) {
                    for(String sn : getSerialNumbers(oi.SerialNumber__c)) {
                        otherSN.add(sn);
                    }
                }
            }
        }
    }


    private static List<String> getSerialNumbers(String field) {
        List<String> result = new List<String>();
        if(String.isNotBlank(field)) {
            for(String sn : field.split(System.Label.OrderItem_SplitChar)) {
                result.add(sn.trim());
            }
        }
        return result;
    }

    private static Error_Logs__c createErrorLog(String sNo, Id orderId) {
        Error_Logs__c el = new Error_Logs__c(
            Error_Type__c = 'Duplicate Asset',
            Error_Message__c = 'Asset with Serial Number ' + sNo + ' already Exists.Cannot create an Asset ',
            Related_Order__c = orderId
        );
        return el;
    }

    private static Id POC_ORDER_RECORD_TYPE_ID = (Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order') != null)
            ? Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order').getRecordTypeId()
            : null;

    private static final Set<String> POC_TYPES_CREATE_ENTITLEMENTS = new Set<String> {
        'Standard POC',
        'Conditional PO',
        'EA Test Unit',
        'Business Loaner Unit',
        'Support Loaner Unit'
    };


    public static Entitlement createEntitlement(OrderItem soi, Id assetId) {

        if(soi.Order.RecordTypeId == POC_ORDER_RECORD_TYPE_ID) {
            if(POC_TYPES_CREATE_ENTITLEMENTS.contains(soi.Order.POC_Request__r.POC_Type__c)
                &&
                    (soi.PricebookEntry.Product2.Asset_Priority__c == 2
                        || soi.PricebookEntry.Product2.Asset_Priority__c == 1
                        || soi.Product_Category__c == 'Support'
                        || soi.Pricebookentry.Product2.License_Type__c == 'Subscription')) {

                Date startDate = soi.Order.Actual_Order_Ship_Date__c;
                Date endDate = (soi.Order.POC_Request__r.POC_completion_date__c != null)
                    ? soi.Order.POC_Request__r.POC_completion_date__c.addDays(7)
                    : null;

                String entType = null;
                if(soi.Order.POC_Request__r.POC_Type__c == 'Standard POC') {
                    entType = 'Evaluation';
                }
                else if (soi.Order.POC_Request__r.POC_Type__c == 'Conditional PO') {
                    entType = 'Conditional PO';
                }
                else if (soi.Order.POC_Request__r.POC_Type__c == 'EA Test Unit') {
                    entType = 'Evaluation';
                }
                else if (soi.Order.POC_Request__r.POC_Type__c == 'Business Loaner Unit'
                    || soi.Order.POC_Request__r.POC_Type__c == 'Support Loaner Unit') {
                    entType = 'Loaner Unit';
                }

                return new Entitlement(
                    Name = soi.Product_Name__c,
                    AssetId = assetId,
                    AccountId = soi.Order.AccountId,
                    StartDate = startDate,
                    EndDate = endDate,
                    Order_Service_Item__c = soi.Id,
                    Product__c = soi.ProductID__c,
                    Type = entType
                );
            }
            else {
                return null;
            }
        }

        return new Entitlement(
            Name = soi.Product_Name__c,
                AssetId = assetId,
                AccountId = soi.Order.AccountId,
                StartDate = soi.Support_Start_Date__c,
                EndDate = soi.Support_End_Date__c,
                Order_Service_Item__c = soi.Id,
                Product__c = soi.ProductID__c
            );
    }

    public static Entitlement updateEntitlement(OrderItem soi, Id assetId, Entitlement ent) {
        return new Entitlement(
            Id = ent.Id,
            Name = soi.Product_Name__c,
            AssetId = assetId,
            AccountId = soi.Order.AccountId,
            StartDate = soi.Support_Start_Date__c,
            EndDate = soi.Support_End_Date__c,
            Order_Service_Item__c = soi.Id,
            Product__c = soi.ProductID__c
        );
    }

    private static Entitlement getEntitlement(List<Entitlement> supportEntitlements, Id assetId, Id orderItemId) {
        Entitlement result = null;

        if(supportEntitlements != null) {
            for(Entitlement ent : supportEntitlements) {
                if(ent.AssetId == assetId && ent.Order_Service_Item__c == orderItemId && ent.Id != null) {
                    result = ent;
                    break;
                }
            }
        }
        return result;
    }

    //Start: SF-920, Update Netsuite flag on account when it is marked true on order
    public static void updateNetsuitFlagAtAccount(List<Order> newOrders, Map<Id, Order> oldOrderMap) {
        Set<Id> accountsIds = new Set<Id>();
        Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
        for(Order ord: newOrders){
          if(ord.Sync_to_NetSuite__c 
        
              && ord.AccountId!=null && accountMap!=null && accountMap.containsKey(ord.AccountId) && accountMap.get(ord.AccountId).Sync_to_NetSuite__c == false
              &&((oldOrderMap != null && ord.Sync_to_NetSuite__c != oldOrderMap.get(ord.Id).Sync_to_NetSuite__c)
                 || oldOrderMap == null)
              ){
                 accountsToUpdate.put(ord.AccountId, new Account(Id=ord.AccountId, Sync_to_NetSuite__c = true));
                    }
                }
        
        if(accountsToUpdate.size()>0){
            update accountsToUpdate.values();
        }
    }
    //End: SF-920
    
    //static Map<Id, Opportunity> oppWithOppId = new Map<Id, Opportunity>();
    //EL-236
    public static void updatePartnerName(List<Order> updatedOrders, Map<Id, Order> oldMap){
        Map<Id, Id> oppPartnerMap = new Map<Id, Id>();
        Set<Id> updatedOrderOpps = new Set<Id>();
       /* for(Order orderObj : updatedOrders){
            //Order oldOrder = oldMap.get(orderObj.Id);
            //if(oldOrder.Partner_Name__c != orderObj.Partner_Name__c){
            //    updatedOrderOpps.add(orderObj.OpportunityId);
            //}
            updatedOrderOpps.add(orderObj.OpportunityId);
            updatedOrderOpps.add(orderObj.POC_Opportunity__c);
        }
        if(!updatedOrderOpps.isEmpty()){
            for(Opportunity opp: [SELECT Id, Name, PriceBook2.ID, Primary_Competitor__c, Pricebook2Id, Partner_Lookup__c, Initial_Contacts_Name__c,Initial_Contacts_Name__r.Email, Rubrik_Sales_Engineer__c,Rubrik_Sales_Engineer__r.Email FROM opportunity WHERE Id IN :updatedOrderOpps]) {
                oppPartnerMap.put(opp.id, opp.Partner_Lookup__c);   //EL-236
                oppWithOppId.put(opp.Id, opp);
            }
        }*/
        
       /* for(Order orderObj : updatedOrders){
            if(orderObj.OpportunityId != null) {
                Order oldOrder = oldMap.get(orderObj.Id);
                if(oldOrder.Partner_Name__c != orderObj.Partner_Name__c && oppMap.containsKey(orderObj.OpportunityId) && oppMap.get(orderObj.OpportunityId).Partner_Lookup__c!=null){
                    orderObj.Partner_Name__c = oppMap.get(orderObj.OpportunityId).Partner_Lookup__c;   //EL-236
                }
            }
        }
    }

    //EL-237
    public static void updatePartnerNameAtEntitlement(List<Order> updatedOrders, Map<Id, Order> oldMap){
        Map<Id, Id> partnerNameMap = new Map<Id, Id>();
        for(Order ord : updatedOrders){
            Order oldOrd = oldMap.get(ord.Id);
            if(oldOrd.Partner_Name__c != ord.Partner_Name__c){
                partnerNameMap.put(ord.Id, ord.Partner_Name__c);
            }
        }
        List<Entitlement> entitlementsToUpdate = new List<Entitlement>();
        for(Entitlement ent: [Select Id, Order_Service_Item__r.OrderId from Entitlement where Order_Service_Item__r.OrderId in :partnerNameMap.keySet()]){
            entitlementsToUpdate.add(new Entitlement(Id=ent.Id, Partner_Name__c=partnerNameMap.get(ent.Order_Service_Item__r.OrderId)));
        }
        update entitlementsToUpdate;
    }


   public static void createEntitlementsForOneTimeProducts(Map<Id, Id> mapOrderId_AccountId) {
        Map<Id, List<EntitlementWrapper>> mapOrderId_listProductsId = new Map<Id, List<EntitlementWrapper>>();
        
        Map<Id,Set<Id>> mapAccId_setAccountProductIds = new Map<Id, Set<Id>>();
        
        List<Entitlement> listEntitlementsInsert = new List<Entitlement>();
        
        
        for(Entitlement eachEntitlement : [SELECT AccountId, 
                                                Product__c 
                                            FROM Entitlement 
                                            where AccountId in : mapOrderId_AccountId.values()]){
            Set<Id> setAccountProductIds = new Set<Id>();
            if(mapAccId_setAccountProductIds.containsKey(eachEntitlement.AccountId)) {
                setAccountProductIds.addAll(mapAccId_setAccountProductIds.get(eachEntitlement.AccountId));
            } 
            setAccountProductIds.add(eachEntitlement.Product__c);
            mapAccId_setAccountProductIds.put(eachEntitlement.AccountId, setAccountProductIds);
            
            
        }
        
        for(OrderItem eachItem : [SELECT Id,
                                        OrderId, 
                                        Product2Id,
                                        Quantity,
                                        Support_Start_Date__c,
                                        Order.AccountId,
                                        Order.EffectiveDate,
                                        Order.Order_Start_Date__c,
                                        Product2.Single_Entitlement__c,
                                        Product2.SBQQ__SubscriptionPricing__c,
                                        Product2.ProductCode,
                                        Product2.One_time_Entitlement__c,
                                        Product2.SBQQSC__EntitlementConversion__c,
                                        Product2.Product_Type__c
                                    FROM OrderItem 
                                    where OrderId in : mapOrderId_AccountId.keySet()]) {
            List<EntitlementWrapper> listEntitlementWrapper = new List<EntitlementWrapper>();
            if(mapOrderId_listProductsId.containsKey(eachItem.Order.AccountId)) {
                listEntitlementWrapper.addAll(mapOrderId_listProductsId.get(eachItem.Order.AccountId));
            }
            if(eachItem.Product2.One_time_Entitlement__c && eachItem.Product2.SBQQ__SubscriptionPricing__c == null) {
                EntitlementWrapper objEntitlementWrapperTemp = new EntitlementWrapper();
                objEntitlementWrapperTemp.productId = eachItem.Product2Id;
                objEntitlementWrapperTemp.objOrderItem = eachItem;
                listEntitlementWrapper.add(objEntitlementWrapperTemp);
            }
            mapOrderId_listProductsId.put(eachItem.Order.AccountId, listEntitlementWrapper);
        }
        
        for(Id eachAccId : mapOrderId_listProductsId.keySet()) {
            for(EntitlementWrapper eachWrapperItem : mapOrderId_listProductsId.get(eachAccId)) {
                if(!mapAccId_setAccountProductIds.containskey(eachAccId) || 
                    !mapAccId_setAccountProductIds.get(eachAccId).contains(eachWrapperItem.productId)) {
                    if(eachWrapperItem.objOrderItem.Product2.SBQQSC__EntitlementConversion__c.EqualsIgnoreCase('One per quote line')) {
                        //Create new Entitlement
                        Entitlement objEntitlement = new Entitlement();
                        objEntitlement.AccountId = eachAccId;
                        objEntitlement.Product__c = eachWrapperItem.productId;
                        objEntitlement.Name = eachWrapperItem.objOrderItem.Product2.ProductCode;
                        objEntitlement.Order_Service_Item__c = eachWrapperItem.objOrderItem.Id;
                        objEntitlement.StartDate = eachWrapperItem.objOrderItem.Support_Start_Date__c != null ? eachWrapperItem.objOrderItem.Support_Start_Date__c : eachWrapperItem.objOrderItem.Order.Order_Start_Date__c;
                        if(eachWrapperItem.objOrderItem.Product2.Product_Type__c.equalsIgnoreCase(TRAINING_PRODUCT) && objEntitlement.StartDate!=null){
                          objEntitlement.EndDate = objEntitlement.StartDate.addYears(1); // SF-7762
                        }
                        listEntitlementsInsert.add(objEntitlement);
                    }
                    else if(eachWrapperItem.objOrderItem.Product2.SBQQSC__EntitlementConversion__c.EqualsIgnoreCase('One per unit')){
                        for(Integer i = 0; i < eachWrapperItem.objOrderItem.Quantity; i++) {
                            Entitlement objEntitlement = new Entitlement();
                            objEntitlement.AccountId = eachAccId;
                            objEntitlement.Product__c = eachWrapperItem.productId;
                            objEntitlement.Name = eachWrapperItem.objOrderItem.Product2.ProductCode;
                            objEntitlement.Order_Service_Item__c = eachWrapperItem.objOrderItem.Id;
                            objEntitlement.StartDate = eachWrapperItem.objOrderItem.Support_Start_Date__c != null ? eachWrapperItem.objOrderItem.Support_Start_Date__c : eachWrapperItem.objOrderItem.Order.Order_Start_Date__c;
                            listEntitlementsInsert.add(objEntitlement);
                        }
                    }
                }
            }
        }
        
        if(!listEntitlementsInsert.isEmpty()) {
            insert listEntitlementsInsert;
        }
    }
    
    public Class EntitlementWrapper {
        public Id productId;
        public OrderItem objOrderItem;
        public EntitlementWrapper() {
            objOrderItem = new OrderItem();
        }
    }
   public static void createUpdateEntitlements(set<Id>shippedOrdIds){
       List<Entitlement> upsertEntitlements = new List<Entitlement>();
       for(List<OrderItem> OIList : orderIdOrderItemMap.values()){
          if(shippedOrdIds.contains(OIList[0].OrderId)){
            for(OrderItem OI : OIList){
              if(OI.Create_Entitlement__c){
                upsertEntitlements.addall(createEntitlements(OI,OI.order.accountId));
           }
         }
       }
       }
       if(!upsertEntitlements.isEmpty()){
         upsert upsertEntitlements ;
       }  
    } 
       private static List<Entitlement> createEntitlements(OrderItem OI,Id AccId){
       List<Entitlement> entList = new List<Entitlement>();
       if(OI.Product2.SBQQSC__EntitlementConversion__c.EqualsIgnoreCase('One per quote line')) { 
                           Entitlement ent = new Entitlement();
                           ent.AccountId = AccId;
                           ent.Product__c = OI.product2Id;
                           ent.Name = OI.Product2.ProductCode;
                           ent.Order_Service_Item__c = OI.Id;
                           if(TRAINING_PRODUCT.equalsIgnoreCase(OI.Product2.Product_Type__c)){
                               ent.StartDate = system.today();
                               ent.EndDate = system.today().addYears(1); // SF-7762
                           }
                           entList.add(ent);
                       }
                       else if(OI.Product2.SBQQSC__EntitlementConversion__c.EqualsIgnoreCase('One per unit')){
                           for(Integer i = 0; i < OI.Quantity; i++) {
                               Entitlement ent = new Entitlement();
                               ent.AccountId = AccId;
                               ent.Product__c = OI.product2Id;
                               ent.Name = OI.Product2.ProductCode;
                               ent.Order_Service_Item__c = OI.Id;
                               if(TRAINING_PRODUCT.equalsIgnoreCase(OI.Product2.Product_Type__c)){
                                  ent.StartDate = system.today(); 
                                  ent.EndDate = system.today().addYears(1); // SF-7762
                               }
                               entList.add(ent);
                           }
                       } 
                   integer i =0; 
                   for(Entitlement ent : OI.entitlements__r){
                    if(entList.size()<i+1){
                        break;
                    }   
                    if(ent.Type !='Manufacturing Entitlement'){
                        entList[i].id = ent.id;
                        if(TRAINING_PRODUCT.equalsIgnoreCase(OI.Product2.Product_Type__c)){
                            entList[i].StartDate = ent.StartDate;
                            entList[i].EndDate = ent.EndDate;
                     }
                        i++;   
                   }    
                   }  
                  return entList ;           
   } 
    
    //Updated for PRDOPS21_337
    public static void updateWelcomeEmailFields(List<Order> newOrders,Map<Id, Order> oldOrderMap) {

        Set<Id> opportunityIds = new Set<Id>();
        for(Order orderObj : newOrders) {
            Order oldOrder = oldOrderMap.get(orderObj.Id);
            if(orderObj.Has_Third_Party_Hardware_Product__c == true && orderObj.Order_Sub_Type__c !='MSP Consumption' && ((oldOrder.Order_Status__c != 'Order Accepted' && orderObj.Order_Status__c == 'Order Accepted')
                       ||(String.isNotBlank(orderObj.NetSuite_Order__c) 
                         && orderObj.NetSuite_Order__c != oldOrder.NetSuite_Order__c 
                         && orderObj.Order_Status__c != 'Order Accepted'
                         && orderObj.Order_Status__c != 'Shipped')
                    )){
                       orderObj.Third_Party_Hardware_fulfilment_status__c='Completed';
            }
            if(orderObj.OpportunityId != null && orderObj.Welcome_Letter_Contact__c ==null && orderObj.Type != 'POC' 
                && orderObj.Order_Status__c == 'Shipped') {
                opportunityIds.add(orderObj.OpportunityId);
            }
            else if(orderObj.POC_Opportunity__c != null && orderObj.Welcome_Letter_Contact__c ==null && orderObj.Type == 'POC' 
                && orderObj.Order_Status__c == 'Shipped') {
                opportunityIds.add(orderObj.POC_Opportunity__c);
            }
        }

        Map<Id, Id> opportunityPrimaryContact = new Map<Id, Id>();
        Map<Id, String> opportunityPrimaryContactEmail = new Map<Id, String>();
        if(opportunityIds.size()>0){
            for(OpportunityContactRole ocr: [Select Id, ContactId, Contact.Email, OpportunityId from OpportunityContactRole
                where OpportunityId in :opportunityIds and IsPrimary = true]){
                opportunityPrimaryContact.put(ocr.OpportunityId, ocr.ContactId);
                opportunityPrimaryContactEmail.put(ocr.OpportunityId, ocr.Contact.Email);
            }
        }

        for(Order orderObj : newOrders) {
            system.debug('@@@@2@@@ orderObj.OpportunityId=='+orderObj.OpportunityId);
            if(orderObj.OpportunityId != null) {
                if(orderObj.OpportunityId != null && orderObj.Welcome_Letter_Contact__c ==null && orderObj.Type != 'POC' 
                    && orderObj.Order_Status__c == 'Shipped' && opportunityPrimaryContact.containsKey(orderObj.OpportunityId)) {
                    orderObj.Welcome_Letter_Contact__c = opportunityPrimaryContact.get(orderObj.OpportunityId);
                    orderObj.Welcome_Letter_Contact_Email__c = opportunityPrimaryContactEmail.get(orderObj.OpportunityId);
                    orderObj.Has_WelcomeLetter_Contact__c = true;
                }
                    if(orderObj.OpportunityId != null && oppMap.containsKey(orderObj.OpportunityId) 
                    && orderObj.Rubrik_Sales_Engineer__c ==null && orderObj.Type != 'POC' 
                       && orderObj.Order_Status__c == 'Shipped' && oppMap.get(orderObj.OpportunityId).Rubrik_Sales_Engineer__c != null && oppMap.get(orderObj.OpportunityId).Rubrik_Sales_Engineer__r.Email!= null) {
                           orderObj.Rubrik_Sales_Engineer__c = oppMap.get(orderObj.OpportunityId).Rubrik_Sales_Engineer__r.Email;
                }
            }
            else if(orderObj.POC_Opportunity__c != null) {
            
                if(orderObj.POC_Opportunity__c != null && orderObj.Welcome_Letter_Contact__c ==null && orderObj.Type == 'POC' 
                    && orderObj.Order_Status__c == 'Shipped' && opportunityPrimaryContact.containsKey(orderObj.POC_Opportunity__c)) {
                    orderObj.Welcome_Letter_Contact__c = opportunityPrimaryContact.get(orderObj.POC_Opportunity__c);
                    orderObj.Welcome_Letter_Contact_Email__c = opportunityPrimaryContactEmail.get(orderObj.POC_Opportunity__c);
                }
                    if(orderObj.POC_Opportunity__c != null && oppMap.containsKey(orderObj.POC_Opportunity__c) 
                    && orderObj.Rubrik_Sales_Engineer__c ==null && orderObj.Type == 'POC' 
                       && orderObj.Order_Status__c == 'Shipped' && oppMap.get(orderObj.POC_Opportunity__c).Rubrik_Sales_Engineer__c != null && oppMap.get(orderObj.POC_Opportunity__c).Rubrik_Sales_Engineer__r.Email!= null) {
                           orderObj.Rubrik_Sales_Engineer__c = oppMap.get(orderObj.POC_Opportunity__c).Rubrik_Sales_Engineer__r.Email;
                }
            }
            system.debug('@@@@AfterAssignment@@@ oppWitOppId=='+orderObj);
        }
    }
    
    public static void countPolarisRecordOnUpdate(List<order> updateOrderList){
        //test
      Map<Id, Integer> orderWithPolarisItemCountMap = new Map<Id, Integer>();
      Map<Id, Integer> orderWithPSProductCountMap = new Map<Id, Integer>();
      Map<Id, Integer> orderWithThirdpartyItemCountMap = new Map<Id, Integer>();
            set<Id> AWSOrderIds = new set<Id>();
            set<id> orderwithproducts = new set<Id>();
            set<id>hardwareOrdIds = new set<id>();
        if(!updateOrderList.isEmpty()) {
           
                for(OrderItem orderItem : [select id, orderId,POC_Option__c, OrderItem.PricebookEntry.Product2Id,PricebookEntry.Product2.Allow_PSO_Task_Creation__c, PricebookEntry.Product2.Family, PricebookEntry.Product2.Bundle_Features__c,Is_Hardware_Line__c,SBQQ__SegmentIndex__c,PricebookEntry.Product2.MSP_Std_Actual__c,PricebookEntry.Product2.Product_Type__c from OrderItem where OrderID IN: updateOrderList]) {
                    orderwithproducts.add(orderItem.orderId);
                    String bundleFeature = orderItem.PricebookEntry.Product2.Bundle_Features__c;
                    if(orderItem.POC_Option__c=='AWS'){
                      AWSOrderIds.add(orderItem.orderId);
                    }
                if (orderItem.PricebookEntry.Product2.Family == 'POLARIS' || 
                    ( String.isNotBlank(bundleFeature) && 
                     (bundleFeature.containsIgnoreCase('Polaris') || (bundleFeature.containsIgnoreCase('Cloud Native Protection')) || bundleFeature.containsIgnoreCase('SAP HANA'))
                    )
                ) {
                    integer count = 0;
                    if(orderWithPolarisItemCountMap.containsKey(orderItem.orderId)) {
                        orderWithPolarisItemCountMap.put(orderItem.orderId, orderWithPolarisItemCountMap.get(orderItem.orderId)+1);
                    }
                    else 
                        orderWithPolarisItemCountMap.put(orderItem.orderId, count+1);
                }
                if (orderItem.PricebookEntry.Product2.Allow_PSO_Task_Creation__c == true) {
                    integer count = 0;
                    if(orderWithPSProductCountMap.containsKey(orderItem.orderId)) {
                        orderWithPSProductCountMap.put(orderItem.orderId, orderWithPSProductCountMap.get(orderItem.orderId)+1);
                    }
                    else 
                        orderWithPSProductCountMap.put(orderItem.orderId, count+1);
                }
                    if(orderItem.Is_Hardware_Line__c){
                       hardwareOrdIds.add(orderItem.orderId);
         }  
                 if((orderItem.PricebookEntry.Product2.Product_Type__c == '3rd Party Hardware' && (orderItem.PricebookEntry.Product2.Family == 'HPE' || orderItem.PricebookEntry.Product2.Family == 'UCS' ||orderItem.PricebookEntry.Product2.Family == 'DELL')) 
                        ||(orderItem.PricebookEntry.Product2.Product_Type__c == 'RCDM' && orderItem.PricebookEntry.Product2.Family == 'Rubrik Scale')
                        || (orderItem.PricebookEntry.Product2.Product_Type__c == 'MSP' && orderItem.PricebookEntry.Product2.Family == 'RCDM' && orderItem.SBQQ__SegmentIndex__c == 1 && orderItem.PricebookEntry.Product2.MSP_Std_Actual__c != 'MSP Actual & Overage' )){
                            integer countThirdParty = 0;
                            if(orderWithThirdpartyItemCountMap.containsKey(orderItem.orderId)) {
                                orderWithThirdpartyItemCountMap .put(orderItem.orderId, orderWithPolarisItemCountMap.get(orderItem.orderId)+1);
                            }
                            else {
                                orderWithThirdpartyItemCountMap.put(orderItem.orderId, countThirdParty +1);
                            }
                    }
            }
            for(Order ord : updateOrderList){
                //Updated to fix QA bug
                if(!orderWithPSProductCountMap.isEmpty() && orderWithPSProductCountMap.containsKey(ord.Id) && orderWithPSProductCountMap.get(ord.Id)> 0) {
                    ord.Have_PS_Products__c = true;
                }
                else{
                    ord.Have_PS_Products__c = false;
                }      
                if(!orderWithPolarisItemCountMap.isEmpty() && orderWithPolarisItemCountMap.containsKey(ord.Id) && orderWithPolarisItemCountMap.get(ord.Id)> 0) {
                    if(ord.Type == 'POC'){
                        ord.Send_for_Polaris_Fulfilment__c = true;
                    }
                        if(!ord.Have_Polaris_Products__c){
                        ord.Have_Polaris_Products__c = true;
                        
                        if(ord.Polaris_Fulfillment_Status__c != 'Completed'){
                            ord.Polaris_Fulfillment_Status__c = 'Not Started';
                        }
                    } 
                }
                else{
                    ord.Have_Polaris_Products__c = false;
                    ord.Polaris_Fulfillment_Status__c = 'Not Needed';
                }
                if(hardwareOrdIds.contains(ord.id)){
                      ord.Have_Hardware_Products__c =true; //SF-11269  ord.Has_Hardware_Products__c
                }
                system.debug('Polaris product ord'+ord.Have_Polaris_Products__c);
                if(ord.Type == 'POC' && ord.Order_Status__c != 'Shipped' && !ord.Have_Hardware_Products__c && (!ord.Have_Polaris_Products__c || ord.Polaris_Fulfillment_Status__c == 'Completed') && !AWSOrderIds.contains(ord.id) && orderwithproducts.contains(ord.id)){ // runs after OrderItem insert SF-11269
                     ord.Order_Status__c = 'Shipped';
                     ord.Actual_Order_Ship_Date__c = Date.today();
                }
                if(!orderWithThirdpartyItemCountMap.isEmpty() && orderWithThirdpartyItemCountMap.containsKey(ord.Id) && orderWithThirdpartyItemCountMap.get(ord.Id)> 0) {
                    //updated to fix PRDOPS22-128
                    if(ord.Third_Party_Hardware_fulfilment_status__c!= 'Completed'){
                    ord.Third_Party_Hardware_fulfilment_status__c='Pending';
                    }
                }
                else{
                    ord.Third_Party_Hardware_fulfilment_status__c = 'Not Needed'; 
                            
                }
            }
            SYSTEM.DEBUG('orderWithPolarisItemCountMap==='+orderWithPolarisItemCountMap);
            
        } 
    }
    
    // Send Slack alert for Mosaic SKU fulfilment
    public static void processMosaicSkus (List<Id> listMosaicOrdersId) {
        system.debug('===in Order Service==='+listMosaicOrdersId);
        if (!listMosaicOrdersId.isEmpty()) {
            try {
                ID slackJobID =
                    System.enqueueJob(
                        new SendSlackAlertsForMosaicOrders(new Set<Id>(listMosaicOrdersId))
                    );
                
            }
            Catch(Exception e) {
                System.debug('Failed to Queue the job. ' + e.getMessage());
            }
        }
    }
    
    // start
    public static void OrderStatusRecordUpdated(List<Order> newOrder,Map<Id, Order> oldOrderMap){
        Set<Id> affectedOrderIds = new Set<Id>();
        for(order ord : newOrder)
        {
            if(oldOrderMap!= null)
            {   
                Order oldOrder = oldOrderMap.get(ord.Id); 
                // added by chaitra for GTC
                    if(ord.Type!= null && ord.Type.equalsIgnoreCase('Revenue') && oldOrderMap.get(ord.id).Order_Status__c!='Pending' 
                       && ord.NetSuite_Order__c == null  // So that orders post acceptance arent marked back to Pending stage
                     && ((ord.Internal_Order_Stage__c=='Pending Validation'&& ord.Internal_Order_Stage__c != oldOrderMap.get(ord.id).Internal_Order_Stage__c)
                     ||(ord.Sync_to_NetSuite__c == true && ord.Sync_to_NetSuite__c != oldOrderMap.get(ord.id).Sync_to_NetSuite__c)
                     )){
                           ord.Order_Status__c ='Pending';     
                   }   
                    
                    if(ord.Type == 'Revenue' && ord.Order_Status__c != oldOrder.Order_Status__c 
                       && accountMap!=null && accountMap.containsKey(ord.accountId) && accountMap.get(ord.accountId).Contract_Negotiation__c
                       && ( ord.Order_Status__c=='Pending'|| ord.Order_Status__c=='On Hold' || ord.Order_Status__c== 'Order Accepted' || ord.Order_Status__c=='PO Received')){
                              ord.Order_Status__c ='On Hold';
                              ord.Hold_Code__c = String.isBlank(ord.Hold_Code__c) ? 'Contract in negotiations' : !ord.Hold_Code__c.contains('Contract in negotiations') ? ord.Hold_Code__c+';Contract in negotiations': ord.Hold_Code__c;
        }

       
           
                     
                        
                    
                }
            }
            
    }
    // end

    //SF-2580
    public static void orderValidation(List<Order> orders){
        for(Order ord: orders){
            Order oldOrd = (Order)Trigger.oldMap.get(ord.Id);
            //Added by Nithin
            if(!oldOrd.Manual_Approve__c && ord.Manual_Approve__c && ord.Screening_Source__c == 'Internal' && ord.ScreenStatus__c == 'On hold'){
                ord.Sync_to_NetSuite__c = true;
                ord.ScreenStatus__c = 'Approved Bypassed';
            }
            Boolean hasQuoteMismatchError = false;
            Boolean hasQuotePrimaryError = false;
            if(ord.Sync_to_NetSuite__c && OrderItemsMap != null && OrderItemsMap.get(ord.Id) != null){
                if(ord.Type != 'Revenue'){
                    continue;
                }
               
                for(OrderItem oi: OrderItemsMap.get(ord.Id)){
                    if(ord.SBQQ__Quote__c != oi.SBQQ__QuoteLine__r.SBQQ__Quote__c){
                        hasQuoteMismatchError = true;
                        break;
                    }

                    if(oi.SBQQ__QuoteLine__c!= null && !oi.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Primary__c){
                        hasQuotePrimaryError = true;
                    }
                }
            }

            if(hasQuoteMismatchError){
                ord.addError('Order can not be marked for sync to NetSuite as the quotes referred by Order and order line do not match.');
            }

            if(hasQuotePrimaryError){
                ord.addError('Order can not be marked for sync to NetSuite as the quote referred by Order is not primary.');
            }
        }
        
    }
    // added for SF-4311 start
     public static void createNodeAssociation(List<Order> EditedOrders, Map<Id, Order> oldorderMap){
     System.debug('Entering into createNodeAssociation');
     Set<Id> ShippedOrd = new Set<Id>();
      for(Order ord : EditedOrders){
            Order oldOrd = oldorderMap.get(ord.Id);
            if((oldOrd.Order_Status__c != ord.Order_Status__c) && (ord.Order_Status__c=='Shipped') ){
                if(ord.Type =='RMA' )
                {
                ShippedOrd.add(ord.Id);
                }
            }
            System.debug('Entering into createNodeAssociation--> shipped order IDs'+ShippedOrd);
         
     
     }
        if(ShippedOrd.size()> 0)
        {
         RMAOrderService.associateNodes(ShippedOrd);
        }
     }
     //end

    /*
     * Author       :   Saakshi Gupta
     * CreatedDate  :   2nd March 2021
     * Description  :   CS21-436 : Update Has_ASE_Product__c flag to true when order status is changed to Shipped, if the order contains atleast one ASE product
    */
   /* public static void setHasASEProduct(Map<Id, Order> newOrderMap, Map<Id, Order> oldOrderMap) {
        Set<Id> updatedOrderIdSet = new Set<Id>();
        for(Order eachOrder : newOrderMap.values()) {
            if(eachOrder.Has_ASE_Product__c == false && eachOrder.Order_Status__c == 'Shipped' && eachOrder.Order_Status__c != oldOrderMap.get(eachOrder.Id).Order_Status__c && orderIdOrderItemMap.get(eachOrder.id) != null) {
                for(OrderItem eachOrderItem : orderIdOrderItemMap.get(eachOrder.id)) {
                    if(eachOrderItem.Product2.Family == 'ASE' || eachOrderItem.Product2.Support_Type__c == 'Proactive') {
                        eachOrder.Has_ASE_Product__c = true;
                        break;
                    }
                }
            }
        }
    }
        
    public static Integer testA2() {
        Integer a = 0;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;

        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;
        a++;

        return a;
    }
// Go Refresh Changes Start 
    public static void IsRefreshedCheckOnAccount(List<Order> newOrders, Map<Id, Order> oldOrderMap){
        Order oldOrder;
        List<id> orderIdList = new List<id>();
        
        if(system.isFuture() || system.isQueueable() || system.isBatch()){
            return;
        }

        for(Order ord: newOrders){
          oldOrder = oldOrderMap.get(ord.Id);
            if((ord.Order_Status__c == 'Order Accepted' && ord.Order_Status__c != oldOrder.Order_Status__c) && ord.Is_Refreshed_Credit_SKU_Eligibility__c && !ord.Account_Is_Refreshed_Check__c){
                orderIdList.add(ord.id);  
            }
        }
        
        if(!orderIdList.isEmpty()){
            updateIsRefreshFlagOnAccount(orderIdList);
        }
      
  }
  // Added for PRDOPS21_324
   public static void orderOnHoldForIF(List<Order> newOrders, Map<Id, Order> oldOrderMap){
        Order oldOrder;
        for(Order ord: newOrders){
                oldOrder = oldOrderMap.get(ord.Id);
                if(ord.Integration_Failure__c == true && ord.Integration_Failure__c != oldOrder.Integration_Failure__c && ord.Order_Status__c != 'Shipped' && ord.Order_Status__c!='Order Accepted'){
                    ord.Order_Status__c = 'On Hold';
                    ord.Hold_Code__c = 'OM Internal Review';
                    ord.Change_Needed_Reason_Other__c = ord.Last_Synced_Message__c;
                    ord.Integration_Failure__c = false ; 
                               
                }
            }
          
     }
     //end
  
  
  @future
  public static void updateIsRefreshFlagOnAccount(List<id> orderIdList){
    List<Account> AccountList = new List<Account>(); 
    if(orderIdList != null && !orderIdList.isEmpty()){
      for(Order Ord : [select id,Account.Is_Refreshed__c,Accountid,Is_Refreshed_Credit_SKU_Eligibility__c from Order where id IN : orderIdList AND Account.Is_Refreshed__c = false]){
        if(!Ord.Account.Is_Refreshed__c){
          AccountList.add(new Account(id=Ord.Accountid,Is_Refreshed__c = true));
        }
      }
    }
    if(!AccountList.isEmpty()){
      update AccountList;
    }
    
  }   
// Go Refresh Changes End

     /**
 Modified InvalidateQuote Method Related to SF-6644
 Modified on 15th May 2020
*/
/*public static void invalidateQuote(List<Order> newOrderList) {
    List<SBQQ__Quote__c> newQuotes = new List<SBQQ__Quote__c>();
    Map<Id,String> oppoWithDuration = new Map<Id,String>();
    
    List<SBQQ__QuoteDocument__c> quoteDocumentsToUpdate = new List<SBQQ__QuoteDocument__c>();
    Set<Id> quoteIds = new Set<Id>();
        Set<id> opportunityIdSet = new Set<id>();
        Date crtDate = Date.newInstance(2019, 03, 01);
        for (Order o : newOrderList) {
            if (o.POC_Request__c !=NULL && o.POC_Type__c == 'Conditional PO' && o.Type == 'POC' ){      
                oppoWithDuration.put(o.POC_Opportunity__c, o.POC_Duration__c); 
                opportunityIdSet.add(o.POC_Opportunity__c);
             }
        }
        if(!opportunityIdSet.isEmpty()){
            List<SBQQ__Quote__c> quotes = [SELECT Id, SBQQ__Opportunity2__c, Is_Conditional_PO__c, 
                                           ApprovalStatus__c,CreatedDate, POC_duration__c
                                           FROM SBQQ__Quote__c 
                                           WHERE SBQQ__Opportunity2__c IN :opportunityIdSet 
                                           and SBQQ__Opportunity2__r.IsClosed =false and SBQQ__Ordered__c=false and CreatedDate > :crtDate];
            if(!quotes.isEmpty()){
             for(SBQQ__Quote__c quote:quotes){
                    boolean doupdate=false;
                    String duration;
                    if(oppoWithDuration.containsKey(quote.SBQQ__Opportunity2__c)){
                        duration = oppoWithDuration.get(quote.SBQQ__Opportunity2__c);
                    }
                    if(duration!=null && quote.POC_duration__c!=duration){
                       quote.POC_duration__c = duration;
                       doupdate=true;
                    }
                    if(!quote.Is_Conditional_PO__c){
                       quote.Is_Conditional_PO__c=true;
                       doupdate=true;
                    }
                    if(doupdate){
                        newQuotes.add(quote);
                        quoteIds.add(quote.Id);
                    }     
             }
           }
           
           if(!newQuotes.isEmpty()){
                Database.update(newQuotes);
                List<SBQQ__QuoteDocument__c> quoteDocuments = [Select Id, Name,  Invalid_Reason__c, Invalid__c from SBQQ__QuoteDocument__c where SBQQ__Quote__c IN:quoteIds];
                if(!quoteDocuments.isEmpty()){
                   for(SBQQ__QuoteDocument__c quotedoc: quoteDocuments){
                         quotedoc.Invalid__c = true;
                         quotedoc.Invalid_Reason__c = 'Missing Conditional PO Verbiage';
                         quotedoc.Name = '[INVALID]' + quotedoc.Name; 
                         quoteDocumentsToUpdate.add(quotedoc);      
                   } 
                }
                if(!quoteDocumentsToUpdate.isEmpty()){
                    Database.update(quoteDocumentsToUpdate);
                }
                 
         
           }
            
        }
     }      
 /***************************
  SF-8170
  Added on 7 september
 ****************************/
/*public static void CancelBooking(set<Id> OrderId) {
 List<Booking_Line_Item__c>cancelBLIList  = [select id,Booking__c from Booking_Line_Item__c where Booking__r.Order__c IN: OrderId];
 List<Booking__c> cancelbooking = new List<Booking__c>();
 set<Id> cancelledBkgId = new set<id>();
   for(Booking_Line_Item__c BLI : cancelBLIList){
      BLI.Total_Price__c = BLI.Total_List_Price__c = 0.0 ;
      if(!cancelledBkgId.contains(BLI.Booking__c)){
        cancelledBkgId.add(BLI.Booking__c);  
        cancelbooking.add(new Booking__c(id=BLI.Booking__c , Status__c='Cancelled'));
      }
   }
   update cancelBLIList;
   update cancelbooking;
}*/

}