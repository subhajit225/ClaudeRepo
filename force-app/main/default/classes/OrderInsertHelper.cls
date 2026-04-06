/**************************************************************************************************
 * @description       : Order Trigger helper logic
 * @author            : Chaitra
 * @last modified on  : 01-20-2021
 * @last modified by  : Chaitra
 * Modifications Log
 * Ver   Date          Author        Modification
 * 1.0   01-20-2021   chaitra        Initial Version
 * 2.0   10-12-2021   shiva          CS21-666
 * 2.1   05-12-2022   moises         PRDOPS23-80-RBKQA
 * 2.2   06-14-2022   moises         PRDOPS23-433 Adding order id to error logs
 ******************************************************************************/

 public class OrderInsertHelper {
  /** Global variables  **/

  public String ORIGIN_CONTEXT; //Insert,update
  public set<Error_Logs__c> errorLogs = new Set<Error_Logs__c>();
  public Map<Id, Account> accountMap;
  public boolean isResyncDates = false;
  public Map<Id, Contact> contactMap = new Map<Id, Contact>();
  public set<id> pocOppIds = new Set<id>();
  public Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
  public Map<Id,POC__c> pocRequestById = new Map<Id,POC__c>(); //FY26WL-117
  public Map<Id, List<OrderItem>> orderIdOrderItemMap = new Map<Id, List<OrderItem>>();
  public Map<Id, SBQQ__Quote__c> quoteMap;
  public Map<Id, List<SBQQ__QuoteLine__c>> qlisByQuoteIdMap = new Map<Id,List<SBQQ__QuoteLine__c>>(); //PRDOPS26-1267
  public static Map<String, Sfdc_Disti_Mapping__mdt> distiMetadataMap;
  public static Map<String, Sfdc_Disti_Mapping__mdt> distiMetadataMapBasedOnLabel;
  public static Map<String, Skus_Mapping__mdt> productSkuMap;
  public static Map<Id, Boolean> isCoreSULicenseByProductId = new Map<Id, Boolean>(); // PRDOPS25-683: this variable stores whether license is Core Scale Utility or not. We are storing this data to ensure that Manufacturing Entitlements are generated only for Core SU SKus and non-Core will be excluded
  private Id RevRecTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Revenue Order')?.getRecordTypeId();
  private set<id> GorefreshOrderIds = new Set<Id>();
  private set<id> upgradeOrderIds = new Set<Id>();
  private static OrderInsertHelper instance = null;
  private set<id> ordIdsWithQuoteMismatch = new Set<id>();
  private set<id> ordIdsWithNonPrimaryQuote = new Set<id>();
  private final set<string> THIRD_PARTY_HARDWARE = new Set<string>{ 'DELL', 'UCS', 'HPE' };
  private final string RCDMT_EOL_Date_MSG = 'RCDM-T EOL Date is in the past on this order, please remove the line prior to booking this order';
  private final string QUOTE_MISMATCH_ERROR = 'Order can not be marked for sync to NetSuite as the quotes referred by Order and order line do not match.';
  private final string NON_PRIMARY_QUOTE_ERROR = 'Order can not be marked for sync to NetSuite as the quote referred by Order is not primary.';
  Map<String, X0_RCDM_Dates__mdt> rcdmMdt = new Map<String, X0_RCDM_Dates__mdt>();
  public static Map<Id, ContractLineItem> idToOldCLIMap = new Map<Id, ContractLineItem>();
  public static Map<Id, Decimal> PONonEDIOrdersAmtMap = new Map<Id, Decimal>(); // This map is storing initial's Order Amount as part of Fedramp 2a: RGCF2-129
   private Map<Id,string> quotePhantomOrdNo = new Map<Id,string>();
  private static boolean isDeniedPartylist = false;
  public List<Order_Configuration__c> orderConfigList = new List<Order_Configuration__c>(); //Order Configuration- PRDOPS25-417
  public Order_control__mdt checkRSCPostCall = Order_control__mdt.getInstance('Enable_Polaris_Fulfilment_SFPost');

  /********************************************************************  
      Description : get Instance of class 
      *******************************************************************/
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description Getting Instance of OrderInsertHelper
   * @return OrderInsertHelper
   */
  public static OrderInsertHelper getInstance() {
    if (instance == null)
      instance = new OrderInsertHelper();
    return instance;
  }
  /***********************************************************************  
      Description : Data collection used in entire order trigger transaction 
      ***********************************************************************/
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description Data collection used in entire order trigger transaction
   */
  public void orderInit() {
    set<id> OrdaccIds = new Set<id>();
    set<id> oppIds = new Set<id>();
    set<id> quoteId = new Set<Id>();
    set<Id> OrderIds = new Set<Id>();
    for (Order ord : (List<Order>) Trigger.new) {
      OrderIds.add(ord.id);
      if (ord.accountId != null)
        OrdaccIds.add(ord.accountId);
      if (ord.Bill_To_Name__c != null) {
        OrdaccIds.add(ord.Bill_To_Name__c);
      }
      if (ord.Partner_Name__c != null) {
        OrdaccIds.add(ord.Partner_Name__c);
      }
      if (ord.OpportunityId != null) {
        oppIds.add(ord.OpportunityId);
      }
      if (ord.POC_Opportunity__c != null) {
        oppIds.add(ord.POC_Opportunity__c);
        pocOppIds.add(ord.POC_Opportunity__c);
      }
      if (ord.SBQQ__Quote__c != null) {
        quoteId.add(ord.SBQQ__Quote__c);
      }
      if (ord.SBQQ__Quote__c != null && ord.type == 'Booking Adjustment')
        ord.SBQQ__Quote__c = null;
    }
    system.debug(LoggingLevel.DEBUG, 'OrderIds' + OrderIds);
    system.debug(LoggingLevel.DEBUG, 'OrdaccIds' + OrdaccIds);
    system.debug(LoggingLevel.DEBUG, 'pocOppIds' + pocOppIds);
    system.debug(LoggingLevel.DEBUG, 'quoteId' + quoteId);
    if (TransactionalDataCollection.oppMainList.isEmpty()) {
      TransactionalDataCollection.oppMainList = [
        SELECT
          Id,
          AccountId,
          StageName,
          Name,
          Hold_Code__c,
          RecordtypeId,
          PriceBook2.ID,
          Primary_Competitor__c,
          Distributor_Lookup__c,
          Pricebook2Id,
          Partner_Lookup__c,
          ContractManufacturer__c,
          Partner_Lookup__r.name,
          IsClosed,
          Rubrik_Sales_Engineer__c,
          Initial_Contacts_Name__c,
          Initial_Contacts_Name__r.name,
          Initial_Contacts_Name__r.Email,
          Rubrik_Sales_Engineer__r.Email,
          Opportunity_Sub_Type__c,
          Polaris_Portal_Contact__c,
          Polaris_Portal_Contact__r.name,
          Polaris_Portal_Contact__r.Email,
          SBQQSC__RenewedServiceContract__c,
          Mosaic_Customer_Environment__c,
          SBQQ__PrimaryQuote__c,
          SBQQ__PrimaryQuote__r.Renewal_Opportunity__c,
          SBQQ__PrimaryQuote__r.Renewal_Opportunity__r.Is_Order_Split__c,
          SBQQ__PrimaryQuote__r.SBQQ__Type__c,
          Owner.email,
          Owner.Manager.email,
          Partner_Rep_Email_Address__c,
          Partner_Lookup__r.Primary_Contact_Email__c,
          Owner.FirstName,
          Owner.LastName,
          Opportunity_Type__c,
          FocusedPartner__c,
          Deal_Registration_Type__c,
          Amount,
          Sell_to_Partner__c,
          Is_Order_Split__c,
          Fulfillment_Hold__c,
          On_Hold_Notes__c,
          Override__c,
          Aspen_Eligibility__c,
          Rubrik_Security_Cloud_Gov_t_Owner__c,
          Rubrik_Security_Cloud_Gov_t_Owner__r.Email,
          Rubrik_Security_Cloud_Gov_t_Owner__r.phone,
          SuggestedURL__c,
          Polaris_Region__c,
          MSP_End_User_Lookup__c,
          MSP_End_User_Lookup__r.Name,
          MSP_End_User_Lookup__r.Website,
          Managed_Services_Deal_type__c,
          Account.Name,
            (SELECT Id,
            Associated_Order_Numbers__c,
            SBQQ__Quote__c
            FROM Orders),
            (SELECT Id,
            SBQQSC__Order__c 
            FROM SBQQSC__ServiceContracts__r)
        FROM opportunity
        WHERE Id IN :oppIds
      ];
    }
    for (Opportunity opp : TransactionalDataCollection.oppMainList) {
      oppMap.put(opp.id, opp);
      if (opp.Distributor_Lookup__c != null)
        if (opp.Distributor_Lookup__c != null)
          OrdaccIds.add(opp.Distributor_Lookup__c);
      if (opp.accountId != null)
        if (opp.accountId != null)
          OrdaccIds.add(opp.accountId);
      if (opp.Partner_Lookup__c != null)
        OrdaccIds.add(opp.Partner_Lookup__c);
    	if(opp.Orders != null){ 
            for(Order ord : opp.Orders){
                  if(ord.SBQQ__Quote__c != null && ord.Associated_Order_Numbers__c != null){
                     quotePhantomOrdNo.put(ord.SBQQ__Quote__c,ord.Associated_Order_Numbers__c);
                  }
              }
          }
    }
    //FY26WL-117
    if(pocRequestById.isEmpty()){
      pocRequestById = new Map<Id,POC__c>([
        SELECT 
          Id, 
          Opportunity__c,
          Opportunity__r.AccountId, 
          Opportunity__r.Opportunity_Type__c, 
          RSCAccountType__c, 
          RSCInstance__c, 
          POC_Type__c,
          RSCSuggestedURL__c,
          Polaris_Region__c,
          Account__c, 
          Account_Name__c,
          Opportunity__r.Polaris_Portal_Contact__c, 
          Opportunity__r.Polaris_Portal_Contact__r.Email,
          Polaris_Contact__r.Email
        FROM POC__c
        WHERE Opportunity__c IN :TransactionalDataCollection.oppMainList
      ]);
    }
    if (TransactionalDataCollection.accMainList.isEmpty()) {
      TransactionalDataCollection.accMainList = [
        SELECT
          Id,
          Name,
          Sync_to_NetSuite__c,
          RSC_G_Support__c,
          U_S_citizen_service__c,
          Contract_Negotiation__c,
          GTC_Screen_Status__c,
          EULA_revision_Required__c, // PRDOPS22-518
          Type,
          Owner.Name,
          BillingState,
          BillingCountry,
          BillingCountryCode,
          Primary_Contact_Email__c,
          Channel_Program_Level_Name__c,
          Channel_Program_Name__c,
          Account_SAM__r.Email,
          RSC_G_Eligible__c,
          Eligible_for_RCDM_T__c,
          ETM_Area__c,
          PS_Project_Manager__c,
          PS_Project_Manager__r.IsActive,
          RSC_G_Account_Sync_status__c,
          Payment_Term__c,
          NS_Internal_Id__c,
          (
            SELECT id, Agreement_Type__c
            FROM contracts
            WHERE Contract_Status__c = 'Active'
          ),
          (
            SELECT
              id,
              ShippingStreet,
              ShippingPostalCode,
              ShippingCity,
              ShippingCountry,
              Shippingstate,
              ShippingCountryCode,
              ShipToContactName__c,
              PoDate,
              PoNumber,
              End_User_PO__c,
              Payment_Terms__c,
              Ship_to_Email__c,
              Ship_To_Name__c
            FROM Orders
            WHERE type = 'Revenue' AND Order_Sub_Type__c = NULL AND Order_Status__c = 'Shipped'
            ORDER BY ActivatedDate DESC
            LIMIT 1
          ) // PRDOPS25-837: Get mandatory Fields From Previous New Sale Revenue Order
        FROM Account
        WHERE id IN :OrdaccIds
      ];
    }

    if (TransactionalDataCollection.quoteMainList.isEmpty()) {
      TransactionalDataCollection.quoteMainList = [
        SELECT
          Id,
          SBQQ__ExpirationDate__c,
          Manual_Fulfillment_Quote__c,
          Co_Term__c,
          Is_Conditional_PO__c,
          Legal_Approved_Verbiage__c,
          Name,
          Discounted_Units_due_to_CSAT_or_Sizing__c,
          SBQQ__Type__c,
          MSP_SKUs_Count__c,
          SBQQ__Opportunity2__c,
          Is_RWD_Polaris_Quote__c,
          Renewal_Opportunity__c,
          ProcessType__c,
          Opportunity_Program__c,
          Distributor_s_Name__c,
          SBQQ__Opportunity2__r.ContractManufacturer__c,
          SBQQ__Opportunity2__r.Aspen_Eligibility__c,
            Additional_Terms_Required__c,
          Arry_Count_Of_Lines_Renewed__c,
          SBQQ__Account__r.Name,
          SBQQSC__MasterServiceContract__r.SBQQSC__Order__r.OrderNumber,
          RCDMT_EOL_Date__c,
          RWD_Deal_Ops_Exception__c,
          RWD_Sales_Rep_Exception__c,
                Credit_Calculation_Start_Date__c,
          SBQQ__PaymentTerms__c,Total_New_Hardware_Products__c,      
          (
            SELECT Id, Name, Quote__c, RecordTypeId, Quote_ShipmentValidation__c, Quote_MissingShipmentDetails__c
            FROM ShipmentDetails__r
            WHERE RecordTypeId = :Constants.overViewRecordTypeId
          ),
          (
            SELECT
              Id,
              Name,
              Line_Type__c,
              SBQQ__StartDate__c,
              SBQQ__Product__r.Appliance_Model_HW__c,
              SBQQ__Product__r.Product_Type__c,
              SBQQ__Product__r.Product_Level__c,
              SBQQ__Product__r.ProductCode,
              SBQQ__RequiredBy__r.SBQQ__ProductCode__c,
              SBQQ__RequiredBy__c,
              SBQQ__EffectiveStartDate__c,
              SBQQ__ProductCode__c,
              SBQQ__Existing__c,
              SBQQ__Quantity__c,
              SBQQ__NetTotal__c,
              Wrapper_Line__c,
              SBQQ__Optional__c,
              SBQQ__EffectiveQuantity__c
            FROM SBQQ__LineItems__r
            // WHERE SBQQ__EffectiveStartDate__c != NULL
            ORDER BY SBQQ__EffectiveStartDate__c ASC NULLS LAST
          )
        FROM SBQQ__Quote__c
        WHERE Id IN :quoteId OR SBQQ__Opportunity2__c IN :pocOppIds
      ];
      for(SBQQ__Quote__c quote : TransactionalDataCollection.quoteMainList){
        if(!qlisByQuoteIdMap.containsKey(quote.Id)){
          qlisByQuoteIdMap.put(quote.Id, new List<SBQQ__QuoteLine__c>());
        }
        for(SBQQ__QuoteLine__c qli : quote.SBQQ__LineItems__r){
          qlisByQuoteIdMap.get(quote.Id).add(qli);
        } 
      }
    }
      if (TransactionalDataCollection.allOrderItems.isEmpty()) {
        TransactionalDataCollection.allOrderItems = [
        SELECT
          id,
                Credit_Amount__c,
          SBQQ__Contracted__c,
          orderId,
          orderItemNumber,
            Previous_Transaction_Reference__c,
            Replacement_Type__c,
          EndDate,
          ServiceDate,
          TPH_Models_Gen__c, //PRDOPS26-393
            TPH_OEM__c,    //PRDOPS26-393
          Cluster_Order_Type__c,
          Global_Commit_ID__c,
          Order.Opportunity.recordtypeId,
          Order.Bill_To_Name__r.Name,
          Order.Sell_to_Partner__r.Name,
          Order.Order_Status__c,
          Order.SBQQ__Quote__c,
          Order.OpportunityId,
          Order.Order_Sub_Type__c,
          Order.Actual_Order_Ship_Date__c,
          NTAP_Part_number__c,
          NTAP_Order_number__c,
          Create_Entitlement__c,
          Quantity,
          Sales_Price__c,
          Line_Type__c,
          Program__c, //SKU-52
          UnitPrice,
          Support_Start_Date__c,
          Support_End_Date__c,
          POC_Option__c,
          Is_Refresh__c,
          Upgraded_From__c,
          Create_Asset__c,
          SBQQ__RequiredBy__c,
          Required_by_Product_Code__c,
          RMA_Component_Type__c,
          Is_Hardware_Line__c,
          SBQQ__SubscriptionTerm__c,
          Order.AccountId,
          PricebookEntryId,
          PricebookEntry.Product2.Product_Type__c,
          SBQQ__QuoteLine__r.SBQQ__Quote__r.Co_Term__c,
          Order.EffectiveDate,
          Order.Order_Start_Date__c,
          Order.type,
          Order.Opportunity.New_Expansion_TCV__c,
          Order.Opportunity.Subsumed_Renewal_TCV__c,
          Order.Opportunity.ACV_Amount__c,
          Order.Opportunity.New_Expansion_ACV__c,
          Order.Opportunity.Renewal_Subsumed_ACV__c,
          Order.Stage_PO__r.PO_Validation_Status__c,
          Order.SBQQ__Quote__r.LoD_refreshed_to_Subscription_Deal__c,
          SBQQ__QuoteLine__c,
            SBQQ__QuoteLine__r.Special_Program__c,
          SBQQ__QuoteLine__r.SBQQ__Quote__c,
          SBQQ__QuoteLine__r.SBQQ__Quote__r.Opportunity_Program__c,
          SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Primary__c,
          SBQQ__QuoteLine__r.GPL__c,
          SBQQ__QuoteLine__r.SBQQ__ListTotal__c,
          SBQQ__QuoteLine__r.SBQQ__TotalDiscountRate__c,
          SBQQ__QuoteLine__r.SBQQ__NetPrice__c,
          SBQQ__QuoteLine__r.RWD_Deal_Ops_Exception__c,
          SBQQ__QuoteLine__r.Name,
            SBQQ__QuoteLine__r.Replacement_Details__c, //SR-Field which stores the json Info
          Failed_Serial_Number__c,
          SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Level__c,
          SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Level__c,
          SBQQ__QuoteLine__r.Licensing_Model__c,
          SBQQ__QuoteLine__r.Rubrik_Suite__c,
          SBQQ__QuoteLine__r.Support_Type__c,
          SBQQ__QuoteLine__r.Payment_Options__c,
          SBQQ__QuoteLine__r.Line_Type__c,
          SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c,
          SBQQ__QuoteLine__r.SBQQ__Quote__r.Renewal_Opportunity__c,
          SBQQ__RequiredBy__r.SerialNumber__c,
          Product2Id,
          Product2.Name,
          Product2.License_Category__c,
          SBQQ__RequiredBy__r.Product2.Product_Level__c,
            SBQQ__RequiredBy__r.Product2.Family,
          SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.Product2.Product_Level__c,
          SerialNumber__c,
          Trade_Up_SerialNumber__c,
          Product_Type__c,
          Product2.Single_Entitlement__c,
          Product2.PDM_Feature_Enabled__c, // SF-50997
          Product2.Asset_Priority__c,
          Product2.SBQQ__SubscriptionPricing__c,
          Product2.Product_Level__c,
          Product2.License_Type__c,
          Product2.SBQQ__SubscriptionTerm__c,
          Product2.ProductCode,
          Product2.SBQQSC__EntitlementConversion__c,
          Product2.Product_Type__c,
          Product2.Bundle_Features__c,
          Product2.Appliance_Model_HW__c,
          Product2.Family,
          Product2.One_time_Entitlement__c,
          Product2.Product_Payment_Option__c,
          Product2.Category__c,
          Product2.Support_Type__c,
          Product2.Allow_PSO_Task_Creation__c,
          Product2.MSP_Std_Actual__c,
          Product2.Shipping_Lead_Time__c,
          product2.OrderSubmission__c,
          Product2.Product_Subtype__c, //PRDOPS22-518
          Product2.Description,
          Product2.Edition__c,
          SBQQ__SegmentIndex__c,
          Need_manual_fulfilment__c,
          Product2.Entitlement_Conversion_Non_CPQ__c,
          TotalPrice,
          SBQQSC__ContractLineItem__c,
          Storage_Tier__c,
          TPH_Quantity__c,
          Support_Term__c,
          Product2.Eligible_for_RCDM_T__c,
          SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Subtype__c,
          SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Subtype__c,
          SBQQ__RequiredBy__r.Product2.Eligible_for_RCDM_T__c,
          SBQQ__QuoteLine__r.SBQQ__RequiredBy__c,
          Previous_Contract_Line_Items__c,
          Opportunity_Product__r.OpportunityId,
          Opportunity_Product__r.Quantity,
          Opportunity_Product__r.Subsumed_Renewal_TCV__c,
          Opportunity_Product__r.New_Expansion_TCV__c,
          Opportunity_Product__r.ACV_Amount__c,
          Opportunity_Product__r.New_Expansion_ACV__c,
          Opportunity_Product__r.SubsRenAmt__c,
          Opportunity_Product__r.Subsumed_Renewal_Amount__c,
          Opportunity_Product__r.PromoDiscTCV__c,
          Opportunity_Product__r.Prepayment_Credit__c,
          Opportunity_Product__r.Oppty_Trade_Up_Discount__c,
          (
            SELECT
              id,
              Product_Quantity__c,
              Total_Price__c,
              Rebate__c,
              Type__c,
              OrderProduct__c,
              New_Expansion_TCV__c,
              Subsumed_Renewal_TCV__c,
              Net_TCV_Amount__c,
              Net_New_Expansion_TCV__c,
              Net_Subsumed_Renewal_TCV__c,
              Net_ACV_Amount__c,
              Net_New_Expansion_ACV__c,
              Net_Subsumed_Renewal_ACV__c,
              Gross_ACV_Amount__c,
              Gross_New_Expansion_ACV__c,
              Gross_Subsumed_Renewal_ACV__c
            FROM Booking_Line_Items__r
          ),
          (
            SELECT Id, Type
            FROM Entitlements__r
          ),
          (
            SELECT Id
            FROM SBQQSC__ContractLineItems__r
          ),
          (SELECT Id, End_of_Paid_Term__c FROM Order_Item_Extensions__r)  
        FROM orderItem
          WHERE (Order.SBQQ__Quote__c IN :quoteId OR orderId IN :OrderIds) // OrderIds are needed where Quote is not present. Ex. POC, RMA
          ORDER BY Support_Start_Date__c ASC NULLS LAST];
    }
    accountMap = new Map<Id, Account>(TransactionalDataCollection.accMainList);
    quoteMap = new Map<Id, SBQQ__Quote__c>(TransactionalDataCollection.quoteMainList);

    set<Id> orderIdForItem = new Set<Id>();
    String previousCliItems, previousCli;
    List<String> previousCliList = new List<String>();
      Boolean isOrderItemMainListBlank = TransactionalDataCollection.orderItemMainList.isEmpty();// Used to ensure orderItemMainList is only populated once during the transaction (if it was initially empty)    
        for(OrderItem OI: TransactionalDataCollection.allOrderItems){
          if(OrderIds.contains(OI.OrderId)){
              if(isOrderItemMainListBlank){
                	TransactionalDataCollection.orderItemMainList.add(OI);// Stores the triggering Order's related OrderItems
              	}
              if(orderIdOrderItemMap.containskey(OI.OrderId))
        orderIdForItem.add(OI.OrderId);
      previousCliItems = OI.Previous_Contract_Line_Items__c;
      if (String.isNotBlank(previousCliItems)) {
        previousCliList = previousCliItems.trim().split(',');
        previousCli = previousCliList[0];
        previousCli = previousCli.trim().substring(0, 15);
        if (idToOldCLIMap == null || !idToOldCLIMap.containskey(previousCli)) {
          idToOldCLIMap.put(previousCli, new ContractLineItem());
        }
      }
    }
        }    
            
    for (OrderItem OI : TransactionalDataCollection.orderItemMainList) {
      if (!orderIdForItem.contains(OI.orderId)) {
        if (orderIdOrderItemMap.containsKey(OI.OrderId)) {
          orderIdOrderItemMap.get(OI.OrderId).add(OI);
        } else {
          orderIdOrderItemMap.put(OI.OrderId, new List<OrderItem>{ OI });
        }
      }
    }

    if (!idToOldCLIMap.keySet().isEmpty()) {
      idToOldCLIMap = new Map<Id, ContractLineItem>([SELECT id, SBQQSC__Product__r.Product_Level__c FROM ContractLineItem WHERE Id IN :idToOldCLIMap.keyset()]);
    }
    system.debug(LoggingLevel.DEBUG, 'In Init accountMap' + JSON.Serialize(accountMap));
    system.debug(LoggingLevel.DEBUG, 'In Init quoteMap' + quoteMap);
    system.debug(LoggingLevel.DEBUG, 'In Init oppMap' + JSON.Serialize(oppMap));
    system.debug(LoggingLevel.DEBUG, 'In Init OrderItemMap' + JSON.Serialize(orderIdOrderItemMap));
  }

  /***********************************************************************  
    Description : Method called in before Insert 
    ******************************************************/
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description populateFieldsOnInsert Method Called in Before Insert
   * @param newOrd
   * @param stagePOList
   * @param disableHold
   * @param isConditionalPO
   */
  public void populateFieldsOnInsert(order newOrd, List<PO_Stage__c> stagePOList, boolean disableHold, boolean isConditionalPO) {
    Order_control__mdt manualOrdSum = Order_control__mdt.getInstance('Manual_order_submission');
    SBQQ__Quote__c quote = quoteMap?.get(newOrd.SBQQ__Quote__c);
    Opportunity opp = oppMap?.get(newOrd.OpportunityId);
    Account acc = accountMap?.get(newOrd.AccountId);
        if(newOrd.Type != 'Revenue Internal'){
    newOrd.Screening_Source__c = RPS__c.getInstance(UserInfo.getUserId()).Screening_Source__c;
        }
    newOrd.SD_Status__c = '';
    Boolean quoteRSCGException = (quote != null && (quote?.RWD_Sales_Rep_Exception__c != null && quote.RWD_Sales_Rep_Exception__c.contains('25% Premium RSC-G Replacement')) ||
    (quote?.RWD_Deal_Ops_Exception__c != null && quote.RWD_Deal_Ops_Exception__c.contains('$0 RSC-G Replacement')));
    Set<String> ordSubTypeToskipForPolaris = new Set<String>{ 'MSP Overage', Constants.ORDER_SUB_TYPE_GC_ONDEMAND };
    String holdNotes = '';
    if (quote != null && (quote.SBQQ__Opportunity2__r?.Aspen_Eligibility__c == 'Actual non-Aspen' || quote.ProcessType__c == 'Aspen')) {
      newOrd.Contract_Manufacturer__c = opp.ContractManufacturer__c;
    }
    if (newOrd.Type != 'Revenue' && newOrd.Est_Ship_Date__c == null && newOrd.Original_Est_Ship_Date__c != null) {
      newOrd.Est_Ship_Date__c = newOrd.Original_Est_Ship_Date__c;
    }
    if (newOrd.RecordTypeId == RevRecTypeId || newOrd.RecordTypeId == null || newOrd.Type == 'New') {
      newOrd.Type = 'Revenue';
    }
    if (!ordSubTypeToskipForPolaris.contains(newOrd.Order_Sub_Type__c) && (newOrd.Type == 'revenue' || newOrd.Type == 'POC')) {
      newOrd.Polaris_Fulfillment_Status__c = 'Not Started';
    }
    if (newOrd.Order_Split_Type__c == null) {
      newOrd.Bill_To_Name__c = newOrd.Type == 'POC'
        ? oppMap?.get(newOrd.POC_Opportunity__c)?.Distributor_Lookup__c
        : opp != null ? opp.Distributor_Lookup__c : newOrd.Bill_To_Name__c;
      newOrd.Order_Split_Type__c = 'Not needed'; // FCUS-142: Order is not going to on Hold when Quote is expired so setted to Not needed
    }
    if (newOrd.Type == 'POC') {
      newOrd.SBQQ__PriceCalcStatus__c = 'Not Needed';
    }
    if (opp != null) {
      newOrd.Pricebook2Id = opp.Pricebook2Id;
      newOrd.Primary_Competitor__c = opp.Primary_Competitor__c;
      newOrd.Partner_Name__c = opp.Partner_Lookup__c; //EL-236
      newOrd.Polaris_Contact__c = opp.Polaris_Portal_Contact__c;
      newOrd.Polaris_Contact_Email__c = opp.Polaris_Portal_Contact__r?.Email;
      newOrd.Sell_to_Partner__c = opp.Sell_to_Partner__c;
      if (
        (opp.Override__c == false && opp.Aspen_Eligibility__c != null && opp.Aspen_Eligibility__c.contains('Actual Aspen') && quote?.SBQQ__Type__c != 'Renewal+Expansion') ||
        (quote?.SBQQ__Type__c == 'Renewal+Expansion' &&
        quote?.ProcessType__c == 'Aspen')
      ) {
        newOrd.ProcessType__c = 'Aspen';
      } else {
        newOrd.ProcessType__c = '';
      }
      if (opp.Owner != null) {
        newOrd.Oppotunity_Owner__c = opp.Owner.FirstName + ' ' + opp.Owner.LastName;
        newOrd.Opportunity_Owners_Email__c = opp?.Owner?.email;
      }
      if (String.isNotBlank(opp.Owner.Manager.Email)) {
        newOrd.Opportunity_manager_Email__c = opp.Owner.Manager.Email;
      }
    }
    if (newOrd.Partner_Name__c == null) {
      newOrd.Partner_Screen_Status__c = Constants.ORDER_SCREEN_STATUS_NA;
    }
    if (newOrd.Polaris_Contact__c == null) {
      newOrd.Polaris_Contact_Screen_Status__c = Constants.ORDER_SCREEN_STATUS_NA;
    }
            
    if (opp == null || (opp != null && opp.MSP_End_User_Lookup__c == null)){
      newOrd.SDPScreenStatus__c = Constants.ORDER_SCREEN_STATUS_NA;
    }
            
    if (newOrd.Type == 'RMA') {
      newOrd.Primary_Contact_Screen_Status__c = Constants.ORDER_SCREEN_STATUS_NA;
      if (newOrd.Order_Sub_Type__c == 'Tech Order' && newOrd.Smart_Hands_Provider__c == 'TSP Inc.') {
        newOrd.Shipping_Carrier__c = 'TSP';
        newOrd.SCAC__c = 'TPSCHD';
      }
    }
    if (disableHold == false && opp != null && opp.Hold_Code__c != null) {
      newOrd.Hold_Code__c = opp.Hold_Code__c;
      holdNotes = String.isNotBlank(opp.On_Hold_Notes__c) ? opp.On_Hold_Notes__c + '\n' : holdNotes;
      newOrd.Order_Status__c = 'On Hold';
    }
    if (quote != null && newOrd.Order_Split_Type__c == 'Not needed' && quote.SBQQ__ExpirationDate__c < System.today()) {
      newOrd.Order_Status__c = 'On Hold';
      newOrd.Hold_Code__c = newOrd.Hold_Code__c != null ? newOrd.Hold_Code__c + ';Expired Quote' : 'Expired Quote';
    }
    // PRDOPS24-867
    if (
      (newOrd.SBQQ__Quote__c == null ||
      newOrd.OpportunityId == null) &&
      newOrd.Type == 'Revenue' &&
      newOrd.Order_Sub_Type__c != Constants.ORDER_SUB_TYPE_GC_ONDEMAND &&
      newOrd.Order_Sub_Type__c != Constants.ORDER_SUB_TYPE_MSP_OVERAGE
    ) {
      newOrd.Order_Status__c = 'On Hold';
      newOrd.Hold_Code__c = String.isBlank(newOrd.Hold_Code__c)
        ? 'Opportunity/Quote missing'
        : !newOrd.Hold_Code__c.contains('Opportunity/Quote missing') ? newOrd.Hold_Code__c + ';Opportunity/Quote missing' : newOrd.Hold_Code__c;
    }
    newOrd.SBQQ__contracted__c = false;
    newOrd.Status = 'Pending';
    if (newOrd.Order_Status__c == null) {
      newOrd.Order_Status__c = 'Pending';
    }
    if (opp != null && opp.Opportunity_Sub_Type__c == 'Renewal') {
      newOrd.Order_Sub_Type__c = 'Renewal';
      if (newOrd.Shipping_Carrier__c == null) {
        newOrd.Shipping_Carrier__c = 'No Shipping Required';
        newOrd.Service_Level__c = 'N/A';
      }
    } else if (opp != null && opp.Opportunity_Sub_Type__c == Constants.ORDER_SUB_TYPE_GC_OFFER) {
      // added by Nitin for Scale Utility
      newOrd.Order_Sub_Type__c = Constants.ORDER_SUB_TYPE_GC_OFFER;
      newOrd.SBQQ__ContractingMethod__c = Constants.ORDER_CONTRACTING_METHOD;
    } else if (quote != null && quote.SBQQ__Type__c == 'Amendment') {
      newOrd.Order_Sub_Type__c = 'Amendment';
    } else if (opp != null && quote != null && quote.MSP_SKUs_Count__c > 0) {
      if (opp.Opportunity_Sub_Type__c == 'MSP' && opp.SBQQSC__RenewedServiceContract__c == null) {
        newOrd.Order_Sub_Type__c = 'MSP Consumption';
      } else if (opp.Opportunity_Sub_Type__c == 'MSP Consumption Renewal' && opp.SBQQSC__RenewedServiceContract__c != null) {
        newOrd.Order_Sub_Type__c = 'MSP Consumption Renewal';
        newOrd.RecordTypeId = RevRecTypeId;
      }
    } else if (opp != null && opp.Opportunity_Sub_Type__c == 'Demo' && newOrd.Type == 'Revenue') {
      newOrd.Order_Sub_Type__c = 'Demo';
    } else if (opp != null && opp.Opportunity_Sub_Type__c == 'CSAT') {
      newOrd.Order_Sub_Type__c = 'CSAT Extension';
    }
    if (Constants.ORDER_SUB_TYPES_SCALE_UTILITY.contains(newOrd.Order_Sub_Type__c))
      newOrd.PDF_Sync_Status__c = Constants.SYNC_READY;

    if (
      quote != null &&
      qlisByQuoteIdMap.containsKey(quote.Id) &&
      qlisByQuoteIdMap.get(quote.Id).size() > 0 &&
      qlisByQuoteIdMap.get(quote.Id)[0].SBQQ__EffectiveStartDate__c != NULL &&
      (quote.SBQQ__Type__c == 'Renewal' ||
      (quote.SBQQ__Type__c == 'Amendment' && quote.Co_Term__c) ||
      (quote.Opportunity_Program__c != null && quote.Opportunity_Program__c.containsIgnoreCase('Conversion')) ||
      quote.SBQQ__Type__c == 'Renewal+Expansion' ||
      quoteRSCGException)
    ) {
      if (quoteRSCGException && qlisByQuoteIdMap.get(quote.Id)[0].SBQQ__EffectiveStartDate__c > System.today()) {
        newOrd.EffectiveDate = System.today();
      } else {
        newOrd.EffectiveDate = qlisByQuoteIdMap.get(quote.Id)[0].SBQQ__EffectiveStartDate__c; // minimum of all quote line Items
      }
    }
    if (newOrd.Type == 'Revenue') {
      newOrd.Ship_to_Email__c = opp?.Initial_Contacts_Name__r?.Email;
      newOrd.Non_shipment_order__c = isConditionalPO; // PRDOPS22-17
    }

    // Copy All Mandotory Fields From Previous Order on Account
    // PRDOPS25-496 For RCDM-T Extension Project
    if (quote != null && quote.RWD_Deal_Ops_Exception__c == constants.RCDMT_EXT_RWD_DEAL_OPS_EXCEPTION && acc != null) {
      Order oldOrder = acc.orders[0];
      copyPreviousOrderDetailsForRCDMTExtension(newOrd, oldOrder);
    }
    system.debug(LoggingLevel.DEBUG, 'OpportunityObjectTriggerHandler.isOppAutoManual' + OpportunityObjectTriggerHandler.isOppAutoManual);
    if (OpportunityObjectTriggerHandler.isOppAutoManual != null) {
      if (OpportunityObjectTriggerHandler.isOppAutoManual == 'AutoGenerated') {
        newOrd.Auto_Manual_Split__c = 'System Generated';
        if (
          newOrd.Sell_to_Partner__c != null &&
          newOrd.Bill_To_Name__c == newOrd.Sell_to_Partner__c &&
          Label.NetApp_Account_Ids.contains(string.valueof(newOrd.Sell_to_Partner__c))
        ) {
          newOrd.Reason_For_Split__c = 'System Split based on Netapp rules';
        } else if (quote != null && quote.SBQQ__Type__c == 'Renewal+Expansion') {
          if (quote.Renewal_Opportunity__c != null) {
            if (newOrd.Order_Split_Type__c == 'Not Needed') {
              newOrd.Reason_For_Split__c = 'System split based on R+E';
            } else {
              newOrd.Reason_For_Split__c = 'System split based on PO and R+E';
            }
          } else {
            newOrd.Reason_For_Split__c = 'System Split based on PO';
          }
        } else {
          newOrd.Reason_For_Split__c = 'System Split based on PO';
        }
      }
    } else if (
      String.isBlank(OpportunityObjectTriggerHandler.isOppAutoManual) &&
      newOrd.Auto_Manual_Split__c != 'Manual' &&
      ((newOrd.Sell_to_Partner__c != null && Label.NetApp_Account_Ids.contains(string.valueof(newOrd.Sell_to_Partner__c))) ||
      (quote != null &&
      quote.SBQQ__Type__c == 'Renewal+Expansion' &&
      quote.Renewal_Opportunity__c != null))
    ) {
      newOrd.Auto_Manual_Split__c = 'System Generated';
      if (newOrd.Sell_to_Partner__c != null && Label.NetApp_Account_Ids.contains(string.valueof(newOrd.Sell_to_Partner__c))) {
        newOrd.Reason_For_Split__c = 'System split based on Netapp rules';
      }
      if (quote != null && quote.SBQQ__Type__c == 'Renewal+Expansion') {
        if (quote.Renewal_Opportunity__c != null) {
          newOrd.Reason_For_Split__c = 'System split based on R+E';
        }
      }
    }

    if (stagePOList != null) {
      copyPODetails(newOrd, stagePOList, null);
      //PRDOPS23-80
    }

    if (distiMetadataMap == null || distiMetadataMap.isempty()) {
      Sfdc_Disti_Mapping__mdt getmeta = OrderInserthelper.getDistributorMetadata(null);
    }
    Boolean checkifDistiEnabled = (newOrd.Bill_To_Name__c != null &&
    distiMetadataMap != null &&
    !distiMetadataMap.isempty() &&
    distiMetadataMap.containskey(newOrd.Bill_To_Name__c) &&
    distiMetadataMap.get(newOrd.Bill_To_Name__c)?.Additional_Terms_Agreement_Confirmed__c);
    Boolean notesAndContigencyPopulatedOnPo = (newOrd.Stage_PO__c != null &&
    orderhandler.StagePoMap != null &&
    !orderhandler.StagePoMap.isempty() &&
    orderhandler.StagePoMap.containskey(newOrd.Stage_PO__c) &&
    !string.isblank(orderhandler.StagePoMap.get(newOrd.Stage_PO__c)?.Note_on_Contingency_and_Special_Language__c));

    if (newOrd.SBQQ__Quote__c != null && quoteMap != null && !quoteMap.isempty() && (quoteMap.get(newOrd.SBQQ__Quote__c).Legal_Approved_Verbiage__c != null  || quoteMap.get(newOrd.SBQQ__Quote__c).Additional_Terms_Required__c))
      newOrd.Additional_Terms_Agreement_Required__c = true;
    if (checkifDistiEnabled || notesAndContigencyPopulatedOnPo) {
      newOrd.Additional_Terms_Agreement_Confirmed__c = true;
    } else if (newOrd.Additional_Terms_Agreement_Required__c && !newOrd.Additional_Terms_Agreement_Confirmed__c
        && !(newOrd.Type == 'Revenue' && newOrd.Stage_PO__c == null)) {
      newOrd.OM_internal_review__c = true;
      holdNotes += 'OM internal review for contingency/special verbiage\n';
      newOrd.Order_Status__c = 'on Hold';
      newOrd.Hold_Code__c = newOrd.Hold_Code__c != null
        ? newOrd.Hold_Code__c + ';Missing Distributor Acceptance of Addl Quote Terms'
        : 'Missing Distributor Acceptance of Addl Quote Terms';
    }

    //SF-25870-Aspen Orders - Additional Terms - Start
    //Default Order-Payment Terms to Value set in AspenConfig Custom Metadata based on Distributor
    if (quote != null && quote.ProcessType__c == 'Aspen' && newOrd.RecordTypeId == RevRecTypeId) {
      Map<String, AspenConfig__mdt> aspenConfigMap = AspenConfig__mdt.getAll();
      for (AspenConfig__mdt ac : aspenConfigMap.values()) {
        if (ac.Id__c == newOrd.Bill_To_Name__c) {
          Map<String, Object> valuesMap = (Map<String, Object>) JSON.deserializeUntyped(ac.Value__c);
          if (valuesMap.containsKey('Payment_Terms__c') && !String.isBlank(valuesMap.get('Payment_Terms__c').toString())) {
            newOrd.Payment_Terms__c = valuesMap.get('Payment_Terms__c').toString();
          }
        }
      }
    }
    //SF-25870-Aspen Orders - Additional Terms - End
    if (newOrd.Sell_to_Partner__c != null && Label.NetApp_Account_Ids.contains(newOrd.Sell_to_Partner__c) && newOrd.Bill_To_Name__c != newOrd.Sell_to_Partner__c) {
      newOrd.OM_internal_review__c = true;
      holdNotes += 'OM internal review for Netapp order\n';
    }
    if (quote != null && (quote.SBQQ__Type__c == 'Renewal+Expansion' && quote.Arry_Count_Of_Lines_Renewed__c > 0)) {
      if (manualOrdSum.value__c != null && String.isNotBlank(manualOrdSum.value__c)) {
        for (String OrdType : manualOrdSum.value__c.replaceAll('\\s+', '').split(',')) {
          if (OrdType == 'R+E' || OrdType.contains('R+E')) {
            newOrd.OM_internal_review__c = true;
            holdNotes += 'OM internal review for renewal and expansion flow\n';
          }
        }
      }
    }
    if (newOrd.Order_Process__c != null && newOrd.Order_Process__c == 'PO PDF') {
      if (newOrd.Shipping_Method__c == null) {
        newOrd.OM_internal_review__c = true;
        holdNotes += 'Review for the missing Shipping terms\n';
      }
      if (newOrd.Shipping_Carrier__c == null) {
        newOrd.OM_internal_review__c = true;
        holdNotes += 'Review for the missing Shipping carrier\n';
      }
    }
    Boolean isManualQuoteFulfillment = (newOrd.SBQQ__Quote__c != null &&
    !quoteMap.isEmpty() &&
    quoteMap.containskey(newOrd.SBQQ__Quote__c) &&
    String.isNotBlank(quoteMap.get(newOrd.SBQQ__Quote__c).Manual_Fulfillment_Quote__c));

    //PRDOPS23-80
        if (newOrd.Type != 'Revenue Internal' && (
            (newOrd.Type != 'RMA' && // @Author: Sukesh K @Description: DGWD-151
            newOrd.Sell_to_Partner__c != null && (newOrd.Shipping_Method__c == 'DDP' || newOrd.Shipping_Method__c == 'DAP')) ||
            (opp != null && ((opp.RecordtypeId == Constants.OPPORTUNITY_RECORDTYPEID_RENEWAL && newOrd.Order_Sub_Type__c == constants.ORDER_SUB_TYPE_GC_OFFER) || 
      opp.Fulfillment_Hold__c ||
      (opp.Hold_Code__c != null && (opp.Hold_Code__c?.contains('OM Internal Review') || opp.Hold_Code__c?.contains('Contingency with order'))))) ||
      isManualQuoteFulfillment
        )) {
      newOrd.ManualFulfilment__c = true;
    } else {
      newOrd.ManualFulfilment__c = false;
    }

    if (opp != null && opp.RecordtypeId == Constants.OPPORTUNITY_RECORDTYPEID_RENEWAL && newOrd.Order_Sub_Type__c == constants.ORDER_SUB_TYPE_GC_OFFER)
      newOrd.Memo__c = Order_control__mdt.getInstance('Memo_For_SU_GC_Offer')?.Value__c;

    if (isManualQuoteFulfillment) {
      String manualFulfillmentQuote = quoteMap.get(newOrd.SBQQ__Quote__c).Manual_Fulfillment_Quote__c.replace(';', ',');
      if (String.isBlank(newOrd.Memo__c) || !newOrd.Memo__c.contains(manualFulfillmentQuote)) {
        newOrd.Memo__c = (String.isBlank(newOrd.Memo__c) ? manualFulfillmentQuote : newOrd.Memo__c + ',' + manualFulfillmentQuote).abbreviate(255);
      }
    }
    if (
      opp != null &&
      opp.Hold_Code__c != null &&
      ((opp.Hold_Code__c?.contains('OM Internal Review') || opp.Hold_Code__c?.contains('Contingency with order')) && String.isNotBlank(opp.On_Hold_Notes__c))
    ) {
      if (String.isBlank(newOrd.Memo__c) || !newOrd.Memo__c.deleteWhitespace().contains(opp.On_Hold_Notes__c.unescapeJava().deleteWhitespace())) {
        newOrd.Memo__c = (String.isBlank(newOrd.Memo__c) ? opp.On_Hold_Notes__c : newOrd.Memo__c + ',' + opp.On_Hold_Notes__c).abbreviate(255);
      }
    }

    if (quote != null && quote.RCDMT_EOL_Date__c != null) {
      newOrd.Quote_RCDM_T_EOL_Date__c = quote.RCDMT_EOL_Date__c;
    }

    newOrd.Stage_PO_Id__c = newOrd.Stage_PO__c;
    if (newOrd.Ship_To_Name__c == null)
      newOrd.Ship_To_Name__c = acc?.Name;

    if (newOrd.Type == 'Revenue' && accountMap.get(newOrd.accountId) != null && accountMap.get(newOrd.accountId).Contract_Negotiation__c) {
      newOrd.Order_Status__c = 'On Hold';
      newOrd.Hold_Code__c = String.isBlank(newOrd.Hold_Code__c)
        ? 'Contract in negotiations'
        : !newOrd.Hold_Code__c.contains('Contract in negotiations') ? newOrd.Hold_Code__c + ';Contract in negotiations' : newOrd.Hold_Code__c;
    }
    if (
      (newOrd.Order_Status__c == 'Pending' ||
      newOrd.Order_Status__c == 'Order Accepted' ||
      newOrd.Order_Status__c == 'On Hold') &&
      accountMap.get(newOrd.accountId) != null &&
      accountMap.get(newOrd.accountId).GTC_Screen_Status__c == 'Denied Party List'
    ) {
      isDeniedPartylist = true;
      newOrd.Order_Status__c = 'On Hold';
      newOrd.Hold_Code__c = String.isBlank(newOrd.Hold_Code__c)
        ? accountMap.get(newOrd.accountId).GTC_Screen_Status__c
        : !newOrd.Hold_Code__c.contains(accountMap.get(newOrd.accountId).GTC_Screen_Status__c)
            ? newOrd.Hold_Code__c + ';' + accountMap.get(newOrd.accountId).GTC_Screen_Status__c
            : newOrd.Hold_Code__c;
    }

    // Jira#RWD-182
    if (newOrd.Is_RWD_Polaris_Quote__c) {
      if (newOrd.Internal_Order_Stage__c == null) {
        newOrd.Order_Index__c = 1;
        newOrd.Total_no_of_orders__c = 1;
        newOrd.Internal_Order_Stage__c = 'Validated';
      } else if (newOrd.Order_Split_Type__c == 'Split Completed') {
        newOrd.Internal_Order_Stage__c = 'Validated';
      } else if (newOrd.Stage_PO__c == null) {
        newOrd.Internal_Order_Stage__c = 'Required';
      }
      if (!String.isBlank(newOrd.Order_Sub_Type__c)) {
        newOrd.Internal_Order_Stage__c = 'Validated';
      }
    } else {
      newOrd.Internal_Order_Stage__c = 'Pending';
    }
    newOrd.HasRansomwareRecoveryWarrenty__c = false; //Added for CS21-768 - Veera - to cover Clone and Split Order
    newOrd.CEM_CSM_Email__c = acc.Account_SAM__r.Email; //Added for CS21-767 : Store Account CEM/CEM Email address on Order
    if (String.isNotBlank(holdNotes)) {
      newOrd.Change_Needed_Reason_Other__c = holdNotes;
    }
  }
  /***********************************************************************  
  Description : copy single stage PO details to order
  ************************************************************************/
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description copy single stage PO details to order
   * @param ord
   * @param stagePOList
   * @param lstOrderItem
   */
  public void copyPODetails(order ord, List<PO_Stage__c> stagePOList, List<OrderItem> lstOrderItem) {
    List<Schema.sObjectField> fields = new List<Schema.sObjectField>{ Order.Shipping_Carrier__c, Order.Shipping_Method__c };
    Map<String, Map<String, String>> storeAlloptions = new Map<String, Map<String, String>>();
    for (Schema.sObjectField field : fields) {
      List<Schema.PicklistEntry> entries = field.getDescribe().getPickListValues();
      for (Schema.PicklistEntry entry : entries) {
        if (entry.isActive()) {
          String value = entry.getValue();
          if (!storeAlloptions.containsKey(field.getDescribe().getName())) {
            storeAlloptions.put(field.getDescribe().getName(), new Map<String, String>());
          }
          storeAlloptions.get(field.getDescribe().getName()).put(value.toLowerCase(), value);
        }
      }
    }
    if (ord.Stage_PO__c == null) {
      Id QuoteLine = lstOrderItem != null && lstOrderItem[0]?.SBQQ__QuoteLine__r?.SBQQ__Quote__r?.SBQQ__Type__c == 'Renewal+Expansion' ? lstOrderItem[0]?.SBQQ__QuoteLine__c : null;
      if (QuoteLine != null && stagePOList.size() > 1) {
        for (PO_Stage__c poStage : stagePOList) {
          for (PO_Item_Stage__c poItem : poStage.PO_Item_Stage__r) {
            if (poItem.Quote_Line__c == QuoteLine) {
              ord.Stage_PO__c = poItem.Stage_PO__c;
            }
          }
        }
      } else if (stagePOList.size() == 1) {
        ord.Stage_PO__c = stagePOList[0].id;
      }
    }
    for (PO_Stage__c poStage : stagePOList) {
      if (poStage.id != ord.Stage_PO__c) {
        continue;
      }
      if (poStage.EDI_DISTI_ID__c != null && poStage.EDI_DISTI_ID__c == 'PO PDF') {
        ord.Order_Process__c = 'PO PDF';
      } else {
        ord.Order_Process__c = 'EDI';
      }

      system.debug(LoggingLevel.DEBUG, 'poStage' + poStage);
      System.debug(LoggingLevel.DEBUG, 'copyPO Ord' + ord);
      ord.Ship_to_Email__c = poStage?.Ship_to_Email__c;
      ord.Ship_To_Name__c = poStage?.Ship_to_Account_Name__c;
      ord.PODate = poStage?.PoDate__c;
      ord.PoNumber = poStage.PoNumber__c;
      ord.ShippingCity = poStage.ShippingCity__c;

      boolean isValidated = true;
      Date customerReqDate;

      try {
        if (poStage.Customer_Requested_Ship_Date__c != null && poStage.Customer_Requested_Ship_Date__c != '') {
          customerReqDate = Date.valueOf(poStage.Customer_Requested_Ship_Date__c);
        }
      } catch (TypeException e) {
        isvalidated = false;
      }
      if (isValidated) {
        ord.customer_required_ship_date__c = customerReqDate;
      }

      if (ord.shippingcountrycode != poStage?.ShippingCountryCode__c || string.isBlank(ord.shippingcountrycode))
        ord.ShippingCountry = '';
      ord.shippingcountrycode = poStage?.ShippingCountryCode__c;
      if (ord.ShippingStateCode != poStage?.ShippingStateCode__c || string.isBlank(ord.ShippingStateCode))
        ord.ShippingState = '';
      ord.ShippingStateCode = poStage?.ShippingStateCode__c;
      ord.ShippingPostalCode = poStage?.ShippingPostalCode__c;
      ord.ShippingStreet = poStage?.ShippingStreet__c;
      if (
        storeAlloptions != null &&
        storeAlloptions.containskey('Shipping_Carrier__c') &&
        poStage?.Shipping_Carrier__c != null &&
        storeAlloptions.get('Shipping_Carrier__c')?.containskey(poStage?.Shipping_Carrier__c.toLowerCase())
      ) {
        ord.Shipping_Carrier__c = storeAlloptions.get('Shipping_Carrier__c').get(poStage?.Shipping_Carrier__c.toLowerCase());
      }
      if (
        storeAlloptions != null &&
        storeAlloptions.containskey('Shipping_Method__c') &&
        poStage?.Shipping_Method__c != null &&
        storeAlloptions.get('Shipping_Method__c')?.containskey(poStage?.Shipping_Method__c.toLowerCase())
      ) {
        ord.Shipping_Method__c = storeAlloptions.get('Shipping_Method__c').get(poStage?.Shipping_Method__c.toLowerCase());
      }
      ord.Payment_Terms__c = poStage?.Payment_Terms__c;
      ord.ShipToContactName__c = poStage?.Ship_To_Contact_Name__c;
      ord.End_User_PO__c = poStage?.End_User_PO__c;
      ord.Ship_To_Phone_Number__c = poStage?.Ship_To_Phone_Number__c;
      ord.Shipping_Account_Number__c = poStage?.Shipping_Account_Number__c;
      ord.Partner_Name_Text__c = poStage?.Partner_Name__c;
      if (ord.Order_Sub_Type__c == 'Renewal') {
        ord.Shipping_Carrier__c = 'No Shipping Required';
        ord.Service_Level__c = 'N/A';
        ord.Shipping_Account_Number__c = null;
      }

      if (string.isNotBlank(poStage?.Service_Level__c) && string.isNotBlank(ord.Shipping_Carrier__c)) {
        Map<String, List<String>> dependentPicklistValuesMap = getDependentPicklistValues(Order.Service_Level__c);
        if (dependentPicklistValuesMap.containsKey(ord.Shipping_Carrier__c) && dependentPicklistValuesMap.get(ord.Shipping_Carrier__c)?.contains(poStage?.Service_Level__c)) {
          ord.Service_Level__c = poStage?.Service_Level__c;
        }
      }

      if (
        !(poStage.Shipping_Account_Number__c == null && poStage.Shipping_Carrier__c == 'No Shipping Required' && poStage.Service_Level__c == 'N/A') &&
        (String.isBlank(poStage.Shipping_Account_Number__c) ||
        String.isBlank(poStage.Service_Level__c) ||
        String.isBlank(poStage.Shipping_Carrier__c))
      ) {
        ord.Order_Status__c = 'On Hold';
        ord.Hold_Code__c = ord.Hold_Code__c != null ? ord.Hold_Code__c + ';Missing freight forwarder details' : 'Missing freight forwarder details';
      }
    }
  }

  /***********************************************************************  
    Description : Method returns map of dependent picklist values  
    ************************************************************************/
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description  Method returns map of dependent picklist values
   * @param dependToken
   * @return Map<String, List<String>>
   */
  public static Map<String, List<String>> getDependentPicklistValues(Schema.sObjectField dependToken) {
    Schema.DescribeFieldResult depend = dependToken.getDescribe();
    Schema.sObjectField controlToken = depend.getController();
    if (controlToken == null) {
      return new Map<String, List<String>>();
    }

    Schema.DescribeFieldResult control = controlToken.getDescribe();
    List<Schema.PicklistEntry> controlEntries;
    if (control.getType() != Schema.DisplayType.Boolean) {
      controlEntries = control.getPicklistValues();
    }

    String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    Map<String, List<String>> dependentPicklistValues = new Map<String, List<String>>();
    for (Schema.PicklistEntry entry : depend.getPicklistValues()) {
      if (entry.isActive() && String.isNotEmpty(String.valueOf(((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')))) {
        List<String> base64chars = String.valueOf(((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')).split('');
        for (Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++) {
          Object controlValue = (controlEntries == null ? (Object) (index == 1) : (Object) (controlEntries[index].isActive() ? controlEntries[index].getLabel() : null));
          Integer bitIndex = index / 6;
          if (bitIndex > base64chars.size() - 1) {
            break;
          }
          Integer bitShift = 5 - Math.mod(index, 6);
          if (controlValue == null || (base64map.indexOf(base64chars[bitIndex]) & (1 << bitShift)) == 0)
            continue;
          if (!dependentPicklistValues.containsKey((String) controlValue)) {
            dependentPicklistValues.put((String) controlValue, new List<String>());
          }
          dependentPicklistValues.get((String) controlValue).add(entry.getLabel());
        }
      }
    }
    return dependentPicklistValues;
  }
  /***********************************************************************  
      Description : Method called in before Update 
      ************************************************************************/
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description Method called in before Update
   * @param newOrd
   * @param oldOrd
   * @param primaryOCR
   * @param beforeUpdateHistory
   */
  public void populateFieldsOnUpdate(Order newOrd, Order oldOrd, OpportunityContactRole primaryOCR, set<string> beforeUpdateHistory) {
    System.debug(LoggingLevel.DEBUG, 'primaryOCR' + primaryOCR);
      string replacementType = '';
    Boolean isRunningAsAPIUser = false;
    if (
      String.isNotBlank(Order_control__mdt.getInstance('Order_API_User_Ids').Values__c) &&
      Order_control__mdt.getInstance('Order_API_User_Ids').Values__c.contains(UserInfo.getUserId())
    ) {
      isRunningAsAPIUser = true;
    }

    boolean hasASEProd,
      hasPOCCloudVault,
      hasThirdPartyProd,
      hasPSProduct,
      needManualFulfilment,
      hasHardware,
      updatedClusterType,
      hasRCDM,
      hasPolarisProduct,
      hasSaas,
      hasNASCD,
      hasNewHWOrLicense,
      hasSubscribtionClstr,
      hasSpecificSku,
     hasonPremProduct,
      hasDpsmCustUcl,
      hasNascdPdmFeature;
    hasASEProd = hasPOCCloudVault = hasThirdPartyProd = hasPSProduct = needManualFulfilment = hasHardware = updatedClusterType = hasRCDM = hasPolarisProduct = hasSaas = hasNASCD = hasNewHWOrLicense = hasSubscribtionClstr = hasSpecificSku =  hasonPremProduct = hasNascdPdmFeature = hasDpsmCustUcl = false;
    Set<String> hasSpecificProduct = new Set<String>();
    // PRDOPS22-267
    Integer duration = 0;
    Integer LODOrd = 0;
    Integer HybridOrd = 0;
    String ntapDetails;
    Date orderCreationDate = null;
    set<String> ntappSet = new Set<String>();
    set<Id> pdfFeatureEnabledProductIds = new Set<Id>(); // SF-50997 : store unique Product IDs that have PDM enabled
        Set<String> OIPrograms =  new Set<String>();
    getProductSkus();
    Set<Id> setFedAndNonIds = new Set<Id>();
    Map<Id, Boolean> checkForUpgradeLine = new Map<Id, Boolean>(); // CSU-473 : Define variable for Upgraded Skus
    Boolean isLicenceSkusForCoreRSCUtility = false; // PRDOPS25-683
      Set<String> orderItemTypes = new Set<String>(); //SR: This set is to check if Order Split is required for the Non-EDI scenario(When disti is Arrow or Promark and PO is not involved)

      
      for(X0_RCDM_Dates__mdt mdt : X0_RCDM_Dates__mdt.getAll().values()){
          if(mdt.Product_Name__c != null){
        rcdmMdt.put(mdt.Product_Name__c, mdt);
      }
    }
    Opportunity opp = newOrd.Type == 'POC' ? oppMap?.get(newOrd.POC_Opportunity__c) : oppMap?.get(newOrd.OpportunityId);
    SBQQ__Quote__c quote = quoteMap?.get(newOrd.SBQQ__Quote__c);
    List<String> featureTypes = new List<String>();
    List<String> ransomwareProducts = Label.RansomwareProduct.toUpperCase().split(','); // added for CS21-768 - Veera
    Set<Id> productSubtypeGOCNVIds = new Set<Id>(); //PRDOPS22-518 - for this story we have created this field
    Date rsvxLineSupportStartDate;

    if (isDeniedPartylist && !newOrd.Hold_Code__c.contains('Denied Party List')) {
      newOrd.Order_Status__c = 'On Hold';
      newOrd.Hold_Code__c = String.isBlank(newOrd.Hold_Code__c)
        ? accountMap.get(newOrd.accountId).GTC_Screen_Status__c
        : !newOrd.Hold_Code__c.contains(accountMap.get(newOrd.accountId).GTC_Screen_Status__c)
            ? newOrd.Hold_Code__c + ';' + accountMap.get(newOrd.accountId).GTC_Screen_Status__c
            : newOrd.Hold_Code__c;
    }

    String distributor = '';
    Boolean isDisabledDisti = false;
    boolean rscgReplacementQuote =
      quote != null &&
      ((quote?.RWD_Sales_Rep_Exception__c != null && quote.RWD_Sales_Rep_Exception__c.contains('25% Premium RSC-G Replacement')) ||
      (quote?.RWD_Deal_Ops_Exception__c != null && quote.RWD_Deal_Ops_Exception__c.contains('$0 RSC-G Replacement')));
    if (opp != null && opp.Distributor_Lookup__c != null && getDistributorMetadata(opp.Distributor_Lookup__c) != null) {
      distributor = getDistributorMetadata(opp.Distributor_Lookup__c).Po_Disti_Type__c;
      isDisabledDisti = getDistributorMetadata(opp.Distributor_Lookup__c).Disable_Distii__c;
    }
    //RollBack to Old order Information
    if (newOrd.Type == 'RMA') {
      newOrd.Shipping_Carrier__c = oldOrd.Shipping_Carrier__c; //Added by Ikyatha  @DGWD-160
      newOrd.Service_Level__c = oldOrd.Service_Level__c;
      neword.scac__c = oldord.scac__c;
    }

    //PRDOPS26-316 - Welcome Letter Date Enhancement
    if (newOrd.Welcome_Letter_Sent_At__c != oldOrd.Welcome_Letter_Sent_At__c && oldOrd.Welcome_Letter_Sent_At__c != null && newOrd.Welcome_Letter_Sent_At__c != null) {
      newOrd.Welcome_Letter_Email_Resent_Date__c = newOrd.Welcome_Letter_Sent_At__c;
      newOrd.Welcome_Letter_Sent_At__c = oldOrd.Welcome_Letter_Sent_At__c;
    }

    /* data collection from Order Items START  */
    if (orderIdOrderItemMap.get(newOrd.id) != null) {
      newOrd.Have_Hardware_Products__c = false;
      newOrd.HasRansomwareRecoveryWarrenty__c = false; //Added for CS21-768 - Veera
      boolean hasRSCGProducts = false;

      for (orderItem OI : orderIdOrderItemMap.get(newOrd.id)) {
            //SR-Checking the onPrem sku availability.
            if(OI.product2?.License_Category__c == 'On Prem'){
                hasonPremProduct = true;
            }
        // SF-50997 : Store All PDM Enabled ProductIds.
        if (OI.product2.PDM_Feature_Enabled__c) {
          pdfFeatureEnabledProductIds.add(OI.product2Id);
        }
      }

      //SF-50997 : Set Laminar and DSPM flags if Feature Start Date on PDM object is less than toda date
      if (!pdfFeatureEnabledProductIds.isempty()) {
        for (Product_Feature__c pdmObj : getActivePdmFeaturesFromProductsIds(pdfFeatureEnabledProductIds, true)) {
          if (pdmObj.Feature__c == constants.PRODUCT_FEATURE_DSPM)
            hasDpsmCustUcl = true;
          //PRDOPS26-186
          if (pdmObj.Feature__c == constants.PRODUCT_TYPE_NAS_CLOUD_DIRECT)
            hasNascdPdmFeature = true;
        }
      }
      for (orderItem OI : orderIdOrderItemMap.get(newOrd.id)) {
                
            boolean isReplacementProgram = OI?.Program__c != Null && Constants.REPLACEMENT_PROGRAMS.contains(OI.Program__c);
          
            if (OI?.Program__c != null && 
                (isReplacementProgram || OI.Program__c == Constants.PROGRAM_REFRESH) &&
                 OI?.Previous_Transaction_Reference__c != null) {
                OIPrograms.add(OI.Program__c);
            }

            orderItemTypes.add(isReplacementProgram ? 'Replacement' : 'Non-Replacement');

        /**
         * CSU-473 : Setting the Value for checkForUpgradeLine if Upgrade sku Found
         */
        if (OrderItemTriggerHelper.isScaleUtilityUpgradeSKU(OI.Product2)) {
          checkForUpgradeLine.put(OI.OrderId, true);
        }
        if (
          OI.Order.Order_Sub_Type__c == Constants.ORDER_SUB_TYPE_GC_OFFER &&
          OI.Product2.Product_Subtype__c == Constants.PROD_SUB_TYPE_SCALE_MSP &&
          String.isBlank(OI.Product2.License_Category__c)
        ) {
          rsvxLineSupportStartDate = OI.Support_Start_Date__c;
        }
        // Check For RSVX Line  For PRDOPS25-683
        if (
          OI.Product2.ProductCode.contains(Constants.PRODUCT_CODE_RSVX) &&
          OI.Product2.Product_Subtype__c == Constants.PROD_SUB_TYPE_SCALE_MSP &&
          OI.Product2.Product_Level__c == constants.RSC_HYBRID_PRODUCT_LEVEL
        ) {
          isCoreSULicenseByProductId.put(OI.Product2Id, true);
          isLicenceSkusForCoreRSCUtility = true;
        }

        if (!rcdmMdt.isEmpty() && rcdmMdt.containskey(OI.product2.name) && OI.Order.Bill_To_Name__c != null && system.label.NetApp_Account_Ids.contains(OI.Order.Bill_To_Name__c))
          hasRCDM = true;

        if (
          ((OI.Product2?.Product_Level__c == 'Support' && OI.Product2?.Product_Type__c == 'HW Support') ||
          (OI.Product2?.Product_Level__c == 'Hybrid Software' ||
          (OI.product2.Product_Level__c == 'OnPrem' &&
          (OI.Product2?.Product_Type__c == 'Foundation Edition' ||
          OI.Product2?.Product_Type__c == 'Business Edition' ||
          OI.Product2?.Product_Type__c == 'Enterprise Edition')) ||
          (OI.Product2?.Product_Type__c == 'RCDM Support' &&
          OI.SBQQ__RequiredBy__c != null &&
          OI.SBQQ__RequiredBy__r?.Product2?.Product_Level__c == 'LOD Software'))) && OI.SBQQ__QuoteLine__r.Line_Type__c == 'New'
        ) {
          hasNewHWOrLicense = true;
        }

        if (OI.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c == 'Renewal+Expansion' && OI.SBQQ__QuoteLine__r.Line_Type__c == 'Renewal' && newOrd.Order_Sub_Type__c != 'Renewal') {
          newOrd.OpportunityId = OI.SBQQ__QuoteLine__r.SBQQ__Quote__r.Renewal_Opportunity__c;
          newOrd.Order_Sub_Type__c = 'Renewal';
          newOrd.Shipping_Carrier__c = 'No Shipping Required';
          newOrd.Service_Level__c = 'N/A';
          newOrd.Shipping_Account_Number__c = null;
        }
              //SR-set the order sub type value as Replacement.
              //if(replacementType != 'Partial' && OI.Replacement_Type__c != null){
              if(!replacementType.contains('Partial') && OI.Replacement_Type__c != null){
                  replacementType = OI.Replacement_Type__c ;
              }
        //Start - PRDOPS22-518 - AS per the story, we have added the below logic by Sreeramulu Redladinne on 02/02/2022
        if (OI.product2.Product_Subtype__c == 'GO CNV') {
          productSubtypeGOCNVIds.add(OI.OrderId);
        }
        //End - PRDOPS22-518
        if (
          OI.Program__c == 'Conversion' ||
          newOrd.Order_Sub_Type__c == 'Renewal' ||
          newOrd.Order_Sub_Type__c == 'CSAT Extension' ||
          newOrd.Order_Sub_Type__c == 'MSP Consumption Renewal' ||
          (quote != null &&
          quote.SBQQ__Type__c == 'Amendment' &&
          quote.Co_Term__c) ||
          rscgReplacementQuote
        ) {
          orderCreationDate = orderIdOrderItemMap.get(newOrd.id)[0].Support_Start_Date__c;
        }

        if ((OI.Support_Start_Date__c == null || rscgReplacementQuote) && orderCreationDate != null) {
          orderCreationDate = orderCreationDate > newOrd.CreatedDate.Date() ? newOrd.CreatedDate.Date() : orderCreationDate;
        }

        //Added By Prashant - PRDOPS22-295
        String netAppIds = system.label.NetApp_Account_Ids;
        if (oi.NTAP_Part_number__c != null && oi.NTAP_Order_number__c != null && (netAppIds.contains(oi.Order.Bill_To_Name__c))) {
          String result = oi.NTAP_Part_number__c.substringAfter('^');
          ntapDetails = 'SO ' + oi.NTAP_Order_number__c + ' PO ' + newOrd.ponumber + ' SN ' + result;
          ntappSet.add(ntapDetails);
        }

        if ((productSkuMap != null && productSkuMap.containsKey(OI.Product2.ProductCode) && productSkuMap.get(OI.Product2.ProductCode) != null) || hasRCDM) {
          hasSpecificSku = true;
        }

        if (
          (!newOrd.Is_RWD_Polaris_Quote__c && oi.Product_Type__c == 'O365') ||
          (newOrd.Is_RWD_Polaris_Quote__c &&
          oi.Product2.License_Category__c == 'SaaS' &&
          (oi.Product2.Product_Level__c == 'Standalone Software Addon' ||
          oi.Product2.Product_Level__c == 'SaaS Software Addon' ||
          oi.Product2.Product_Level__c == 'Hybrid Software' ||
          oi.Product2.Product_Level__c == 'LOD Software' ||
          (oi.Product2.Product_Level__c == 'OnPrem' &&
          (oi.Product2.Product_Type__c == 'Foundation Edition' ||
          oi.Product2.Product_Type__c == 'Enterprise Edition' ||
          oi.Product2.Product_Type__c == 'Business Edition') &&
          OI.Product2.product_subtype__c == null)))
        ) {
          hasSaas = true;
        }

        if (oi.Product2.Product_Type__c == 'US Citizen Support' && newOrd.Type == 'Revenue') {
          hasSpecificProduct.add('US Citizen Support');
        }
        //added new conditions for ITNPI-202
        if (
          ((OI.Product2.Product_Type__c == Constants.PRODUCT_TYPE_NAS_CLOUD_DIRECT &&
          OI.Product2.Product_Subtype__c != Constants.PRODUCT_SUB_TYPE_BE_ADDON) ||
          OI.Product2.Product_Type__c == Constants.PRODUCT_TYPE_IGNEOUS_LEGACY ||
          OI.Product2.Product_Subtype__c == Constants.PRODUCT_TYPE_NAS_CLOUD_DIRECT ||
          OI.Product2.Product_Subtype__c == Constants.NAS_DATA_SECURITY ||
          hasNascdPdmFeature) && !(OI.Order.type == 'Revenue' && OI.Order.Order_Sub_Type__c == 'Renewal')
        ) {
          hasNASCD = true;
        }

        if (OI.Cluster_Order_Type__c == 'Subscription' && (newOrd.type == 'POC' || newOrd.type == 'Revenue')) {
          hasSubscribtionClstr = true;
        }

        //Added logic to check ransomeware Product - CS21-768 - Veera
        //if (oi.product2 != null && oi.product2.Name.equalsignorecase(Label.RansomwareProduct)) {
        if (oi.product2 != null && ransomwareProducts.contains(oi.product2.Name.toUpperCase())) {
          newOrd.HasRansomwareRecoveryWarrenty__c = true;
        }
        //CS21-768 - End

        system.debug(LoggingLevel.FINER, 'OrderItem OI' + JSON.serializePretty(OI));

        if ((OI.Product2.Product_Level__c == 'Hardware' && (OI.Product2.Product_Type__c == 'Hardware' || OI.Product2.Product_Type__c == 'Add-On Node'))) {
          hasHardware = true;
        }
        // PRDOPS22-267
        // Added Logic For the Calculating Maximum shipping Date
        // And Delivery Date Of All Order Lines
        if (OI.product2.Shipping_Lead_Time__c != null) {
          duration = Integer.ValueOf(math.max(duration, OI.product2.Shipping_Lead_Time__c));
        }

        if (OI.Need_manual_fulfilment__c) {
          //newOrd.ManualFulfilment__c = true;
          needManualFulfilment = true;
        }
        if (newOrd.Type == 'Revenue') {
          if (oi.SBQQ__QuoteLine__c != null) {
            if (newOrd.SBQQ__Quote__c != OI.SBQQ__QuoteLine__r.SBQQ__Quote__c) {
              ordIdsWithQuoteMismatch.add(newOrd.id);
            }
            if (!oi.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Primary__c) {
              ordIdsWithNonPrimaryQuote.add(newOrd.id);
            }
          }

          if (newOrd.Bill_To_Name__c != newOrd.Sell_to_Partner__c && OI.SBQQ__QuoteLine__c != null && OI.SBQQ__QuoteLine__r.GPL__c == 'NetApp') {
            newOrd.Bill_To_Name__c = newOrd.Sell_to_Partner__c;
          }
        }
        {
          Product2 prod = OI.Product2;
          if (newOrd.Type == 'POC' && (prod.Product_Type__c == 'Cloud Vault Backup' || prod.Product_Type__c == 'Cloud Vault Archive')) {
            hasPOCCloudVault = true;
          }
          Boolean isRSCPProduct = prod.ProductCode != null && prod.ProductCode.startsWith(Constants.PRODUCT_CODE_PREFIX_RSCP); // PRDOPS-544
                hasPolarisProduct = newOrd.Type != 'Revenue Internal' && (hasPolarisProduct || (!isRSCPProduct && ((newOrd.Order_Sub_Type__c != Constants.ORDER_SUB_TYPE_GC_ONDEMAND && newOrd.Order_Sub_Type__c != 'MSP Overage') && (prod.Product_Type__c == 'EDGE' || hasDpsmCustUcl || OI.Product2?.Product_Type__c == 'Laminar' ||
            (!newOrd.Is_RWD_Polaris_Quote__c &&
            ((prod.Family == 'POLARIS' ||
            (prod.Bundle_Features__c != null &&
            (prod.Bundle_Features__c.containsIgnoreCase('Polaris') ||
            prod.Bundle_Features__c.containsIgnoreCase('Cloud Native Protection') ||
            prod.Bundle_Features__c.containsIgnoreCase('SAP HANA'))) ||
            (prod.License_Type__c == 'Perpetual' &&
            prod.Product_Type__c == 'RCDM')))) ||
            (newOrd.Is_RWD_Polaris_Quote__c &&
                  ((prod.Product_Level__c == 'Hybrid Software'  || (prod.Product_Level__c == 'OnPrem' && (prod.Product_Type__c == 'Foundation Edition' || prod.Product_Type__c == 'Enterprise Edition' || prod.Product_Type__c == 'Business Edition') && prod.product_subtype__c == null) ||  prod.Product_Level__c == 'SaaS Software Addon' ||
                  prod.Product_Level__c == 'Standalone Software Addon' || prod.Product_Level__c == 'LOD Software' ||  prod.Product_Level__c == CPQ_Constants.PAYGO|| //GTMIT-142
                  prod.Product_Type__c == 'On Prem CDM') || OI?.SBQQ__QuoteLine__r?.RWD_Deal_Ops_Exception__c == constants.RCDMT_EXT_RWD_DEAL_OPS_EXCEPTION)))))
              );

        }
        if (
          (hasThirdPartyProd == false &&
          newOrd.Order_Sub_Type__c != Constants.ORDER_SUB_TYPE_GC_OFFER &&
          ((OI.Product2.Product_Type__c == '3rd Party Hardware' && THIRD_PARTY_HARDWARE.contains(OI.Product2.Family)) ||
          (('RCDM' == oi.Product2.Product_Type__c || 'Enterprise Edition' == oi.Product2.Product_Type__c || 'Business Edition' == oi.Product2.Product_Type__c) &&
          oi.Product2.Family == 'Rubrik Scale') ||
          (oi.Product2.Family == 'Third Party License') ||
          (oi.Product2.Product_Type__c == 'MSP' &&
          oi.Product2.Family == 'RCDM' &&
          oi.SBQQ__SegmentIndex__c == 1 &&
          oi.Product2.MSP_Std_Actual__c != 'MSP Actual & Overage'))) ||
          (!hasThirdPartyProd &&
          OI.TPH_Quantity__c != null &&
          newOrd.Order_Sub_Type__c == Constants.ORDER_SUB_TYPE_GC_OFFER &&
          OI.Product2.Product_Subtype__c == Constants.PROD_SUB_TYPE_SCALE_MSP &&
          OI.Product2.License_Category__c == null)
        ) {
          hasThirdPartyProd = true;
        }
        if (OI.Product2.Allow_PSO_Task_Creation__c == true) {
          //newOrd.Have_PS_Products__c = true;
          hasPSProduct = true; //Added CS 21-666
        }
        if (OI.Product2.Family == 'ASE' || OI.Product2.Support_Type__c == 'Proactive' || (OI.Product2.Description != null && OI.Product2.Description.toLowerCase().contains('assigned support engineer'))) {
          hasASEProd = true;
        }
        if (OI.Is_Hardware_Line__c) {
          newOrd.Have_Hardware_Products__c = true;
        }
        if (oi.Is_Refresh__c) {
          GorefreshOrderIds.add(newOrd.id);
        }
        if (OI.Product2.OrderSubmission__c == 'Manual') {
          upgradeOrderIds.add(newOrd.id);
        }
        if (accountMap?.get(newOrd.accountId)?.RSC_G_Eligible__c) {
          if (OI?.Product2?.Product_Subtype__c == 'FEDRAMP') {
            hasRSCGProducts = true;
            if (!newOrd.RSC_G_Enabled__c) {
              setFedAndNonIds.add(OI.Id);
              newOrd.RSC_G_Enabled__c = true;
              newOrd.Polaris_Fulfillment_Status__c = 'Not Started';

              // newOrd.Memo__c = (String.isNotBlank(newOrd.Memo__c) ? newOrd.Memo__c+','+'RSC-G Order - special provisioning required' : 'RSC-G Order - special provisioning required').abbreviate(255); //PRDOPS25-660
            }
          } else {
            if (
              OI?.SBQQ__QuoteLine__r?.SBQQ__RequiredBy__r?.SBQQ__Product__r?.Product_Subtype__c != 'FEDRAMP' &&
              OI?.SBQQ__QuoteLine__r?.SBQQ__RequiredBy__r?.SBQQ__RequiredBy__r?.SBQQ__Product__r?.Product_Subtype__c != 'FEDRAMP' &&
              OI?.Product2?.Category__c != 'Professional Services' &&
              OI?.Product2?.Product_Type__c != 'Training'
            ) {
              setFedAndNonIds.add(OI.Id);
            }
          }
        }
        String quoteSalesOrDealException;
        if (quote != null && newOrd.RSC_G_Enabled__c) {
          quoteSalesOrDealException = quote.RWD_Sales_Rep_Exception__c != null && quote.RWD_Sales_Rep_Exception__c.contains('25% Premium RSC-G Replacement')
            ? '25% Premium RSC-G Replacement'
            : quote.RWD_Deal_Ops_Exception__c != null && quote.RWD_Deal_Ops_Exception__c.contains('$0 RSC-G Replacement') ? '$0 RSC-G Replacement' : null;
        }
        if (string.isNotBlank(quoteSalesOrDealException)) {
          newOrd.Program__c = quoteSalesOrDealException;
        }
      }
            if(!SplitOrder.isNonEDISplit && newOrd.Type == 'Revenue' && newOrd.Order_Sub_Type__c != Constants.ORDER_SUB_TYPE_GC_OFFER){
                newOrd.Line_Types__c = !OIPrograms.isEmpty() ? String.join(new List<String>(OIPrograms), ';') : null;
            }

      //PRDOPS26-664
       if(newOrd.Type == 'Revenue' && !newOrd.Have_Hardware_Products__c && newOrd.Shipping_Carrier__c == null){
          newOrd.Shipping_Carrier__c = 'No Shipping Required';
          newOrd.Service_Level__c = 'N/A';
        }
      // Set Field Has_Non_Software_Bundle__c to true based on M365 and SU skus
      // CSU-475- Prashant
      //CSU-569 : Setting Has Third Party Hardware Flag False For Amendment Scale utitlity Order
      if (
        !newOrd.is_Amendment_Order__c &&
        newOrd.Order_Sub_Type__c == constants.ORDER_SUB_TYPE_GC_OFFER &&
        (newOrd.Number_Of_Third_Party_Hardware_lines__c > 0 || isLicenceSkusForCoreRSCUtility)
      )
        newOrd.Has_Non_Software_Bundle__c = true;

      //end OI loop
      //FEDR-30  To Handle Split Case Scenario
      if (!hasRSCGProducts) {
        // if(newOrd.RSC_G_Enabled__c) newOrd.Memo__c =  null ; //PRDOPS25-660
        newOrd.RSC_G_Enabled__c = false;
        // newOrd.Memo__c = null;
      } /*else{
            needManualFulfilment = true;
          }  */ //Commented else part of Fedramp2b
      if (
        (opp != null &&
        opp.Override__c == false &&
        opp.Aspen_Eligibility__c != null &&
        opp.Aspen_Eligibility__c.contains('Actual Aspen') &&
        quote?.SBQQ__Type__c != 'Renewal+Expansion') || (hasNewHWOrLicense && quote?.SBQQ__Type__c == 'Renewal+Expansion' && quote?.ProcessType__c == 'Aspen')
      ) {
        newOrd.ProcessType__c = 'Aspen';
      } else {
        newOrd.ProcessType__c = '';
      }

      if (
        newOrd?.Program__c != null &&
        newOrd?.Program__c.contains('RSC-G Replacement') &&
        (newOrd.Order_Split_Type__c == 'Not needed' ||
        newOrd.Order_Split_Type__c == 'Split Completed')
      ) {
        newOrd.ProcessType__c = '';
      }
      //Non-EDI conversion split - Effective Date
      if (newOrd.Status == 'Pending' && newOrd.Status != 'Activated' && newOrd.Type == 'Revenue' && newOrd.Order_Sub_Type__c != constants.ORDER_SUB_TYPE_GC_ONDEMAND) {
        newOrd.EffectiveDate = orderCreationDate != null ? orderCreationDate : newOrd.createdDate.Date();
      }

      if (hasHardware && newOrd.HW_Order__c == null) {
        newOrd.HW_Order__c = newOrd.Related_Order__c = newOrd.Related_Orders__c = newOrd.OrderNumber;
      }

      if (
        newOrd.Sell_to_Partner__c != null &&
        Label.NetApp_Account_Ids.contains(newOrd.Sell_to_Partner__c) &&
        newOrd.Bill_To_Name__c == newOrd.Sell_to_Partner__c &&
        newOrd.OM_internal_review__c == true &&
        String.isNotBlank(newOrd.Change_Needed_Reason_Other__c) &&
        newOrd.Change_Needed_Reason_Other__c.contains('OM internal review for Netapp order')
      ) {
        newOrd.OM_internal_review__c = false;
        newOrd.Change_Needed_Reason_Other__c = (newOrd.Change_Needed_Reason_Other__c == 'OM internal review for Netapp order\n')
          ? ''
          : newOrd.Change_Needed_Reason_Other__c.remove('OM internal review for Netapp order');
      }

      Boolean isManualQuoteFulfillment = (newOrd.SBQQ__Quote__c != null &&
      !quoteMap.isEmpty() &&
      quoteMap.containskey(newOrd.SBQQ__Quote__c) &&
      String.isNotBlank(quoteMap.get(newOrd.SBQQ__Quote__c).Manual_Fulfillment_Quote__c));

      if (
        (newOrd.Type != 'RMA' && newOrd.Type != 'Revenue Internal' &&
        newOrd.Sell_to_Partner__c != null &&
        (newOrd.Shipping_Method__c == 'DDP' ||
        newOrd.Shipping_Method__c == 'DAP')) ||
        needManualFulfilment ||
        (opp != null &&
        ((opp.RecordtypeId != null &&
        opp.RecordtypeId == Constants.OPPORTUNITY_RECORDTYPEID_RENEWAL &&
        newOrd.Order_Sub_Type__c == constants.ORDER_SUB_TYPE_GC_OFFER) ||
        opp.Fulfillment_Hold__c ||
        (opp.Hold_Code__c != null && (opp.Hold_Code__c?.contains('OM Internal Review') || opp.Hold_Code__c?.contains('Contingency with order'))))) ||
        isManualQuoteFulfillment ||
        String.isNotBlank(newOrd.Manual_Fulfilment_Selection_Reason__c)
      ) {
        newOrd.ManualFulfilment__c = true;
      } else {
        newOrd.ManualFulfilment__c = false;
      }

      if (
        opp != null &&
        opp.RecordtypeId != null &&
        opp.RecordtypeId == Constants.OPPORTUNITY_RECORDTYPEID_RENEWAL &&
        newOrd.Order_Sub_Type__c == constants.ORDER_SUB_TYPE_GC_OFFER
      ) {
        if (rsvxLineSupportStartDate != null)
          newOrd.EffectiveDate = rsvxLineSupportStartDate;
      }
      newOrd.Have_Polaris_Products__c = hasPolarisProduct;
      // PRDOPS-544: Stamp 'Not Needed' for RSCP-only orders that do not require RSC provisioning
      if (!hasPolarisProduct && !newOrd.RSC_G_Enabled__c && (newOrd.Type == 'Revenue' || newOrd.Type == 'POC')) {
        newOrd.Polaris_Fulfillment_Status__c = Constants.POLARIS_FULFILLMENT_STATUS_NOT_NEEDED; // PRDOPS-544
      }
      //RWD-129 Changes End
      if (newOrd.Order_Status__c == 'Shipped' && oldOrd.Order_Status__c != newOrd.Order_Status__c) {
        //PRDOPS22-295- Prashant
        if ((ntappSet != null && ntappSet.size() == 1)) {
          String details = new List<String>(ntappSet).get(0);
          newOrd.NTAP_Number__c = details;
        }
        newOrd.Product_Category__c = null;
        if (hasSpecificSku) {
          newOrd.Product_Category__c = newOrd.Product_Category__c != null ? newOrd.Product_Category__c + ';RCDM' : 'RCDM';
        }
        if (hasSaas) {
          newOrd.Product_Category__c = newOrd.Product_Category__c != null ? newOrd.Product_Category__c + ';Saas' : 'Saas';
        }
        if (hasSpecificProduct.contains('US Citizen Support')) {
          newOrd.Product_Category__c = newOrd.Product_Category__c != null ? newOrd.Product_Category__c + ';US Citizen Support' : 'US Citizen Support';
        }
      }

      if (newOrd.Order_Status__c == 'Pending' && newOrd.Order_Sub_Type__c != 'MSP Overage') {
        if (newOrd.Third_Party_Hardware_fulfilment_status__c != 'Completed') {
          if (hasThirdPartyProd) {
            newOrd.Third_Party_Hardware_fulfilment_status__c = 'Pending';
          } else {
            newOrd.Third_Party_Hardware_fulfilment_status__c = 'Not Needed';
          }
        }
      }
    }
        //SR-Reset the OrderSubType value if upgrade/conversion lines removed.
        if(string.isNotBlank(replacementType) && replacementType.contains('Partial')){
                newOrd.Associated_Order_Numbers__c = quotePhantomOrdNo?.get(newOrd.SBQQ__Quote__c);
        }
        
        if ( newOrd.Type == 'POC' && newOrd.Order_Status__c != 'Shipped' && 
              !newOrd.Have_Hardware_Products__c && !newOrd.ManualFulfilment__c &&  
      (!newOrd.Have_Polaris_Products__c || newOrd.Polaris_Fulfillment_Status__c == 'Completed') &&
      (newOrd.ScreenStatus__c == 'Approved' ||
      newOrd.ScreenStatus__c == 'Approved Bypassed')
    ) {
      newOrd.Order_Status__c = 'Shipped';
      newOrd.Actual_Order_Ship_Date__c = Date.today();
      if (opp != null && primaryOCR != null && newOrd.Polaris_Fulfillment_Status__c == 'Completed') {
        newOrd.Has_WelcomeLetter_Contact__c = true;
      }
    }
    //PRDOPS23-198 - Updated as Part of PRDOPS26-534
    if (newOrd.Order_Status__c == 'Shipped' && oldOrd.Order_Status__c != newOrd.Order_Status__c &&
        newOrd.Polaris_Fulfillment_Status__c == 'Completed' &&
        newOrd.Polaris_Fulfillment_Status__c != 'Resync Support Dates' &&
        ((hasPOCCloudVault && (hasSaas || newOrd.Have_Hardware_Products__c)) || hasSubscribtionClstr || newOrd.type == 'POC')
      ) {
        isResyncDates = true;
        newOrd.Polaris_Fulfillment_Status__c = 'Resync Support Dates';
    	//PRDOPS26-701
        if(!newOrd.RSC_G_Enabled__c && String.isNotBlank(checkRSCPostCall.Value__c) && Boolean.valueOf(checkRSCPostCall.Value__c)){
            newOrd.Polaris_Fulfillment_Status__c = 'Resync Dates Requested';
          }
      }

    /* data collection from Order Items END  */
    newOrd.Have_PS_Products__c = hasPSProduct; //Added CS 21-666
    if (newOrd.Distributor_Email__c == null || newOrd.Bill_To_Name__c != oldOrd.Bill_To_Name__c) {
      newOrd.Distributor_Email__c = accountMap?.get(newOrd.Bill_To_Name__c)?.Primary_Contact_Email__c;
    }
    if (newOrd.Hold_Code__c != null && newOrd.Hold_Code__c != oldOrd.Hold_Code__c && (newOrd.Order_Status__c == 'Pending' || newOrd.Order_Status__c == 'PO Received')) {
      newOrd.Order_Status__c = 'On Hold';
    }
    if (opp != null) {
      newOrd.Partner_Name__c = opp.Partner_Lookup__c;
      if (newOrd.Partner_Email__c == null || newOrd.Oppotunity_Owner__c == null) {
        if (opp.Partner_Lookup__c != null && opp.Partner_Lookup__r.Primary_Contact_Email__c != null) {
          newOrd.Partner_Email__c = opp.Partner_Lookup__r?.Primary_Contact_Email__c;
        } else {
          newOrd.Partner_Email__c = opp.Partner_Rep_Email_Address__c;
        }
        if (opp.Owner != null) {
          newOrd.Oppotunity_Owner__c = opp.Owner.FirstName + ' ' + opp.Owner.LastName;
          newOrd.Opportunity_Owners_Email__c = opp?.Owner?.email;
        }
      }
    }
    if (newOrd.Order_is_submitted__c 
        && newOrd.Original_Est_Ship_Date__c != oldOrd.Original_Est_Ship_Date__c 
        && newOrd.Order_Status__c != oldOrd.Order_Status__c
        && newOrd.Order_Status__c != 'Order Accepted')
      newOrd.Original_Est_Ship_Date__c = oldOrd.Original_Est_Ship_Date__c;
    if (newOrd.Type != oldOrd.Type && oldOrd.Type != null && oldOrd.Type != 'New')
      newOrd.Type = oldOrd.Type;
    if (newOrd.Status == 'Cancelled') {
      newOrd.Order_Status__c = 'Rejected';
      if (newOrd.Type == 'POC') {
        newOrd.Polaris_Fulfillment_Status__c = 'Not Needed';
      }
    }
    if (newOrd.Order_Number__c != newOrd.OrderNumber)
      newOrd.Order_Number__c = newOrd.OrderNumber;

    if (
      newOrd.Order_Status__c != 'Shipped' &&
      newOrd.Order_Status__c != 'Rejected' &&
      String.isNotBlank(newOrd.NetSuite_Order__c) &&
      newOrd.NetSuite_Order__c != oldOrd.NetSuite_Order__c
    ) {
      newOrd.Order_Status__c = 'Order Accepted';
      newOrd.Product_Category__c = null;
      newOrd.Order_Accepted_Timestamp__c = DateTime.now();
      if (hasSpecificSku) {
        newOrd.Product_Category__c = newOrd.Product_Category__c != null ? newOrd.Product_Category__c + ';RCDM' : 'RCDM';
      }
      if (hasSaas) {
        newOrd.Product_Category__c = newOrd.Product_Category__c != null ? newOrd.Product_Category__c + ';Saas' : 'Saas';
      }
      if (hasNASCD) {
        if (newOrd.Product_Category__c != null && !newOrd.Product_Category__c.contains('NASCD')) {
          newOrd.Product_Category__c += ';NASCD';
        } else if (newOrd.Product_Category__c == null) {
          newOrd.Product_Category__c = 'NASCD';
        }
      }

      //PRDOPS22-267 , PRDOPS23-146
            //SR-Setting the value of ESD, EDD as 1st of next month if on-Prem sku exists in the order.
    if((newOrd.Type == 'POC' || newOrd.Type == 'revenue') && newOrd.Est_Ship_Date__c == null && newOrd.NetSuite_Order__c != oldOrd.NetSuite_Order__c){
        Date EstimatedDate = null;
        if (!orderConfigList.isEmpty()) {
          for (Order_Configuration__c ordConfig : orderConfigList) {
            if (
              ordConfig.Start_Date__c != null &&
              ordConfig.End_Date__c >= newOrd.createdDate.Date() &&
              ordConfig.Start_Date__c <= newOrd.createdDate.Date() &&
              ((newOrd.Type == 'revenue' &&
              String.isNotblank(ordConfig?.Order_Type_to_be_considered__c) &&
              ((String.isNotblank(newOrd.Order_Sub_Type__c) && ordConfig.Order_Type_to_be_considered__c.contains(newOrd.Order_Sub_Type__c)) ||
              (ordConfig.Order_Type_to_be_considered__c.contains('New Sale') && newOrd.Order_Sub_Type__c == null))) || newOrd.Type == 'POC') &&
              ordConfig.Target_Date__c != null
            ) {
              EstimatedDate = ordConfig.Target_Date__c;
              if (EstimatedDate > Date.valueOF(system.now().addDays(duration * 7)) || EstimatedDate <= Date.valueOF(system.now())) {
                Date orderAccpetancePlus7 = Date.valueOF(system.now().addDays(7));
                newOrd.Est_Ship_Date__c = duration == 0 ? EstimatedDate > orderAccpetancePlus7 ? EstimatedDate : orderAccpetancePlus7 : EstimatedDate;
                newOrd.Deliver_By__c = duration == 0 ? EstimatedDate > orderAccpetancePlus7 ? EstimatedDate : orderAccpetancePlus7 : EstimatedDate.addDays(7);
              }
            }
          }
        }

        if (duration != 0 && ((Date.valueOF(system.now().addDays(duration * 7)) > EstimatedDate) || EstimatedDate == null)) {
          newOrd.Est_Ship_Date__c = Date.valueOF(system.now().addDays(duration * 7));
          newOrd.Deliver_By__c = Date.valueOF(newOrd.Est_Ship_Date__c.addDays(7));
        } else if (duration == 0 && EstimatedDate == null) {
          newOrd.Est_Ship_Date__c = Date.valueOF(system.now().addDays(7));
          newOrd.Deliver_By__c = Date.valueOF(system.now().addDays(7));
        }

        if (newOrd.customer_required_ship_date__c != null && newOrd.customer_required_ship_date__c > newOrd.Est_Ship_Date__c) {
          newOrd.Est_Ship_Date__c = newOrd.customer_required_ship_date__c;
          newOrd.Sync_to_NetSuite__c = true;
        }
        if(newOrd.Type == 'Revenue' && newOrd.Original_Est_Ship_Date__c == null){
            newOrd.Original_Est_Ship_Date__c = newOrd.Est_Ship_Date__c;
        }
      }

      newOrd.Status = 'Order Accepted';
      if (newOrd.Has_Third_Party_Hardware_Product__c && newOrd.Order_Sub_Type__c != 'MSP Consumption') {
        newOrd.Third_Party_Hardware_fulfilment_status__c = 'Completed';
      }
    }
    // Runs on every order update after 'order accepted' stage
    if (
      newOrd.Order_Status__c == 'Order Accepted' &&
      (newOrd.Type == 'Revenue' ||
      newOrd.Type == 'RMA') &&
      oldOrd.Sync_to_NetSuite__c == false &&
      oldOrd.BookingStatus__c == newOrd.BookingStatus__c &&
      (newOrd.Polaris_Fulfillment_Status__c != 'In Progress' || (newOrd.Order_Accepted_Timestamp__c != oldOrd.Order_Accepted_Timestamp__c)) &&
      (!isRunningAsAPIUser || (newOrd.RSC_G_Enabled__c && newOrd.Polaris_Fulfillment_Status__c == 'Completed' && oldOrd.Polaris_Fulfillment_Status__c != 'Completed'))
    ) {
      newOrd.Sync_to_NetSuite__c = true;
      newOrd.Update_Netsuite_Last_Flagged__c = DateTime.Now();
    }

    //based on order type START
    if (newOrd.Type == 'Revenue') {
      if (newOrd.Sync_to_NetSuite__c == true && oldOrd.Sync_to_NetSuite__c == false && newOrd.NetSuite_Order__c == null) {
        newOrd.Order_Status__c = 'Pending';
      }
      if (
        newOrd.Order_Status__c == 'Order Accepted' &&
        newOrd.Order_Sub_Type__c != 'MSP Overage' && // Jira#RWD-129
        newOrd.Have_Polaris_Products__c == true && // PRDOPS-544: Skip callout for RSCP-only orders
        newOrd.Send_for_Polaris_Fulfilment__c == false &&
        (oldOrd.Order_Status__c != newOrd.Order_Status__c ||
        oldOrd.Polaris_Fulfillment_Status__c != newOrd.Polaris_Fulfillment_Status__c) &&
        (newOrd.Polaris_Fulfillment_Status__c == 'Not Started' ||
        newOrd.Polaris_Fulfillment_Status__c == 'In Progress')
      ) {
        newOrd.Send_for_Polaris_Fulfilment__c = true;
        if(!newOrd.RSC_G_Enabled__c && String.isNotBlank(checkRSCPostCall.Value__c) && Boolean.valueOf(checkRSCPostCall.Value__c)){
          newOrd.Polaris_Fulfillment_Status__c = 'Provisioning Requested';
        }
      }
      // credit check
      if (
        oldOrd.Credit_Check_Failure_Reason__c != newOrd.Credit_Check_Failure_Reason__c &&
        String.isNotBlank(newOrd.Credit_Check_Failure_Reason__c) &&
        newOrd.Credit_Check_Failure_Reason__c != 'NA'
      ) {
        newOrd.Order_Status__c = 'On Hold';
        newOrd.Hold_Code__c = String.isBlank(newOrd.Hold_Code__c)
          ? 'Credit Check Failed'
          : !newOrd.Hold_Code__c.contains('Credit Check Failed') ? newOrd.Hold_Code__c + ';Credit Check Failed' : newOrd.Hold_Code__c;
        newOrd.Sync_to_NetSuite__c = false;
        newOrd.Integration_Failure__c = false;
        String customerBalance = newOrd.Credit_Check_Failure_Reason__c?.substringBetween('Customer balance of ', ' exceeds');
        String creditLimit = newOrd.Credit_Check_Failure_Reason__c?.substringAfterLast('limit of ');

        if (String.isNotBlank(customerBalance)) {
          newOrd.Customer_Balance__c = Decimal.valueOf(customerBalance);
        }

        if (String.isNotBlank(creditLimit)) {
          newOrd.Credit_Limit__c = Decimal.valueOf(creditLimit.substringBeforeLast('.'));
        }
      } else if (
        newOrd.Integration_Failure__c == true &&
        oldOrd.Integration_Failure__c == false &&
        (newOrd.Order_Status__c == 'Pending' ||
        newOrd.Order_Status__c == 'PO Received')
      ) {
        newOrd.Order_Status__c = 'On Hold';
        newOrd.Hold_Code__c = 'OM Internal Review';
        newOrd.Change_Needed_Reason_Other__c = newOrd.Last_Synced_Message__c;
        newOrd.Integration_Failure__c = false;
      }
    } else {
      if (newOrd.Est_Ship_Date__c == null && newOrd.Original_Est_Ship_Date__c != oldOrd.Original_Est_Ship_Date__c) {
        newOrd.Est_Ship_Date__c = newOrd.Original_Est_Ship_Date__c;
      }
      if (newOrd.Integration_Failure__c == true && oldOrd.Integration_Failure__c == false && (newOrd.Order_Status__c == 'Pending' || newOrd.Order_Status__c == 'PO Received')) {
        newOrd.Order_Status__c = 'On Hold';
        newOrd.Hold_Code__c = 'OM Internal Review';
        newOrd.Change_Needed_Reason_Other__c = newOrd.Last_Synced_Message__c;
        newOrd.Integration_Failure__c = false;
      }
    }
    if (newOrd.Order_Status__c != null && newOrd.Order_Status__c != oldOrd.Order_Status__c) {
      if (newOrd.Order_Status__c == 'Order Accepted') {
        newOrd.Order_is_submitted__c = true;
        newOrd.Has_ASE_Product__c = hasASEProd;
        newOrd.Welcome_Letter_Contact__c = primaryOCR?.ContactId;
        newOrd.RSC_G_Contact__c = Opp?.Rubrik_Security_Cloud_Gov_t_Owner__c; // primaryOCR?.ContactId;//
        newOrd.RSC_G_Contact_Email__c = opp?.Rubrik_Security_Cloud_Gov_t_Owner__r?.Email; //primaryOCR?.Contact?.Email; //
        newOrd.RSC_G_Contact_Phone__c = opp?.Rubrik_Security_Cloud_Gov_t_Owner__r.phone; //primaryOCR?.Contact?.Phone;  //
        if (newOrd.Order_Accepted_By__c == null)
          newOrd.Order_Accepted_By__c = UserInfo.getUserId();
        if (newOrd.Has_Third_Party_Hardware_Product__c && newOrd.Order_Sub_Type__c != 'MSP Consumption') {
          newOrd.Third_Party_Hardware_fulfilment_status__c = 'Completed';
        }
      } else if (newOrd.Order_Status__c == 'Shipped' && !beforeUpdateHistory.contains('Shipped')) {
        newOrd.Welcome_Letter_Contact__c = primaryOCR?.ContactId;
        newOrd.Welcome_Letter_Contact_Email__c = primaryOCR?.Contact?.Email;
        newOrd.RSC_G_Contact__c = Opp?.Rubrik_Security_Cloud_Gov_t_Owner__c; // primaryOCR?.ContactId;//
        newOrd.RSC_G_Contact_Email__c = opp?.Rubrik_Security_Cloud_Gov_t_Owner__r?.Email; //primaryOCR?.Contact?.Email; //
        newOrd.RSC_G_Contact_Phone__c = opp?.Rubrik_Security_Cloud_Gov_t_Owner__r.phone; //primaryOCR?.Contact?.Phone;  //
        newOrd.Rubrik_Sales_Engineer__c = opp?.Rubrik_Sales_Engineer__r?.Email;
        if (
          newOrd.Welcome_Letter_Contact__c != null &&
          ((newOrd.Type != 'POC' && newOrd.Order_Sub_Type__c != Constants.ORDER_SUB_TYPE_GC_ONDEMAND) || newOrd.Type == 'POC' && newOrd.Have_Hardware_Products__c)
        ) {
          newOrd.Has_WelcomeLetter_Contact__c = true;
        }
        if (newOrd.Type == 'Revenue' && newOrd.Status != 'Activated' && opp != null && newOrd.SBQQ__Quote__c != null) {
          if (newOrd.Stage_PO__c != null) {
            newOrd.EDI_Sync_Status__c = 'Y';
          } else {
            newOrd.EDI_Sync_Status__c = 'N';
          }
          newOrd.Status = 'Activated';
        }
      }
      if (
        newOrd.Type == 'Revenue' &&
        (newOrd.Order_Status__c == 'Pending' ||
        newOrd.Order_Status__c == 'On Hold' ||
        newOrd.Order_Status__c == 'Order Accepted' ||
        newOrd.Order_Status__c == 'PO Received') &&
        accountMap.get(newOrd.accountId) != null &&
        accountMap.get(newOrd.accountId).Contract_Negotiation__c
      ) {
        newOrd.Order_Status__c = 'On Hold';
        newOrd.Hold_Code__c = String.isBlank(newOrd.Hold_Code__c)
          ? 'Contract in negotiations'
          : !newOrd.Hold_Code__c.contains('Contract in negotiations') ? newOrd.Hold_Code__c + ';Contract in negotiations' : newOrd.Hold_Code__c;
      }
    }
    //Start - PRDOPS22-518
    if (
      !productSubtypeGOCNVIds.isEmpty() &&
      productSubtypeGOCNVIds.contains(newOrd.Id) &&
      (newOrd.Order_Status__c == 'Pending' ||
      newOrd.Order_Status__c == 'On Hold' ||
      newOrd.Order_Status__c == 'Order Accepted' ||
      newOrd.Order_Status__c == 'PO Received') &&
      accountMap.get(newOrd.accountId) != null &&
      accountMap.get(newOrd.accountId).EULA_revision_Required__c
    ) {
      newOrd.Order_Status__c = 'On Hold';
      newOrd.Hold_Code__c = String.isBlank(newOrd.Hold_Code__c)
        ? 'EULA Revision Required'
        : !newOrd.Hold_Code__c.contains('EULA Revision Required') ? newOrd.Hold_Code__c + ';EULA Revision Required' : newOrd.Hold_Code__c;
    }
    //End - PRDOPS22-518
    if (newOrd.Order_Accepted_Timestamp__c != oldOrd.Order_Accepted_Timestamp__c && newOrd.Order_Accepted_Timestamp__c > newOrd.Hold_Off_Timestamp__c) {
      Decimal decDiff = decimal.valueOf((newOrd.Order_Accepted_Timestamp__c.getTime() - newOrd.Hold_Off_Timestamp__c.getTime()) / (1000 * 60 * 60)) / 24;
      Integer daysBetween = Integer.valueOf(decDiff.round(System.RoundingMode.CEILING));
      newOrd.Original_Days_On_Hold__c = newOrd.Original_Days_On_Hold__c == null ? daysBetween : newOrd.Original_Days_On_Hold__c + daysBetween;
    }
    if (newOrd.Type == 'Revenue' && (newOrd.Order_Split_Type__c == null || newOrd.Order_Split_Type__c == 'Not needed')) {
      if (
        newOrd.Sell_to_Partner__c != null &&
        newOrd.Bill_To_Name__c == newOrd.Sell_to_Partner__c &&
        Label.NetApp_Account_Ids.contains(string.valueof(newOrd.Sell_to_Partner__c))
      ) {
        newOrd.Order_Split_Type__c = 'Netapp';
      } else if (opp != null && distributor != null && (distributor == 'ARROW' || distributor == 'INGRAM')) {
        if (
          (opp?.SBQQ__PrimaryQuote__r.SBQQ__Type__c == 'Renewal+Expansion' &&
          newOrd.Order_Sub_Type__c == 'Renewal' &&
          opp?.SBQQ__PrimaryQuote__r?.Renewal_Opportunity__c != null &&
          opp?.SBQQ__PrimaryQuote__r?.Renewal_Opportunity__r?.Is_Order_Split__c) ||
          (opp.Is_Order_Split__c && !(opp?.SBQQ__PrimaryQuote__r.SBQQ__Type__c == 'Renewal+Expansion' && newOrd.Order_Sub_Type__c == 'Renewal')) ||
          ((opp.Is_Order_Split__c || newOrd.Stage_PO__c != null) &&
          newOrd.RSC_G_Enabled__c &&
          !setFedAndNonIds.isEmpty() &&
          setFedAndNonIds.size() > 1)
        ) {
          newOrd.Order_Split_Type__c = 'EDI';
          } else if (
          (newOrd.ProcessType__c != 'Aspen' &&
          UtilityClass.isReplacementOrder(newOrd) &&
          orderItemTypes.size() > 1 &&
          newOrd.SBQQ__Quote__c != null &&
          quotemap.containskey(neword.SBQQ__Quote__c) &&
          quotemap.get(neword.SBQQ__Quote__c).Total_New_Hardware_Products__c > 0) || (newOrd.RSC_G_Enabled__c && !setFedAndNonIds.isEmpty() && setFedAndNonIds.size() > 1)
        ) {
            newOrd.Order_Split_Type__c = 'Non-EDI';
          } 
      } else if (
        oldOrd.Order_Split_Type__c != 'Non-EDI' &&
        ((newOrd.ProcessType__c != 'Aspen' &&
        UtilityClass.isReplacementOrder(newOrd) &&
        orderItemTypes.size() > 1 &&
        newOrd.SBQQ__Quote__c != null &&
        quotemap.containskey(neword.SBQQ__Quote__c) &&
        quotemap.get(neword.SBQQ__Quote__c).Total_New_Hardware_Products__c > 0) || (newOrd.RSC_G_Enabled__c && !setFedAndNonIds.isEmpty() && setFedAndNonIds.size() > 1))
      ) {
        newOrd.Order_Split_Type__c = 'Non-EDI';
      }
      /**
       * CSU-473 : Setting Split Type as  GC Offer Amendment
       * For Scale Utility Amendment Order which has Upgraded Orderlines
       */
      if (
        oldOrd.Order_Split_Type__c != Constants.ORDER_SPLIT_TYPE_GC_OFFER_AMENDMENT &&
        newOrd.is_Amendment_Order__c &&
        newOrd.Order_Sub_Type__c == constants.ORDER_SUB_TYPE_GC_OFFER &&
        !checkForUpgradeLine.isEmpty() &&
        checkForUpgradeLine.containskey(newOrd.Id) &&
        checkForUpgradeLine.get(newOrd.Id)
      ) {
        newOrd.Order_Split_Type__c = Constants.ORDER_SPLIT_TYPE_GC_OFFER_AMENDMENT;
      }
    }
    // Jira#RWD-182
    if (newOrd.Is_RWD_Polaris_Quote__c && newOrd.Total_no_of_orders__c == 1 && newOrd.HW_Order__c == null) {
      if (hasHardware) {
        newOrd.HW_Order__c = newOrd.Order_Number__c;
        newOrd.Related_Order__c = newOrd.Order_Number__c;
        newOrd.Related_orders__c = newOrd.Order_Number__c;
        newOrd.Related_Order_Count__c = 1;
      }
    }
    if (
      newOrd.Is_RWD_Polaris_Quote__c &&
      newOrd.Stage_PO__c == null &&
      ORIGIN_CONTEXT != 'Insert' &&
      ((newOrd.SBQQ__PriceCalcStatus__c != oldOrd.SBQQ__PriceCalcStatus__c && newOrd.SBQQ__PriceCalcStatus__c == 'Queued') || (newOrd.TotalAmount != oldOrd.TotalAmount)) &&
      newOrd.Total_no_of_orders__c != 1
    ) {
      newOrd.Internal_Order_Stage__c = 'Required';
    }
    if (
      newOrd.Is_RWD_Polaris_Quote__c &&
      !string.isBlank(newOrd.Order_Sub_Type__c) &&
      newOrd.Internal_Order_Stage__c != 'Validated' &&
      oldOrd.Internal_Order_Stage__c == 'Required'
    ) {
      newOrd.Internal_Order_Stage__c = 'Validated';
    }
    System.debug(LoggingLevel.FINER, 'OrderSet' + JSON.serializePretty(newOrd));
    // PRDOPS24-710 - Auto sync between salesforce and netsuite
    // PRDOPS24-885 - Fix for Debook Oppty Not Moved to Close/Won
    if (
      ((newOrd.Scale_Utility_SKUs_Count__c != oldOrd.Scale_Utility_SKUs_Count__c ||
      newOrd.TotalAmount != oldOrd.TotalAmount ||
      newOrd.Bill_To_Name__c != oldOrd.Bill_To_Name__c ||
      newOrd.SBQQ__Quote__c != oldOrd.SBQQ__Quote__c ||
      newOrd.OpportunityId != oldOrd.OpportunityId ||
      newOrd.PoNumber != oldOrd.PoNumber ||
      newOrd.End_User_PO__c != oldOrd.End_User_PO__c ||
      newOrd.Customer_message__c != oldOrd.Customer_message__c ||
      newOrd.Vendor_message__c != oldOrd.Vendor_message__c ||
      newOrd.Memo__c != oldOrd.Memo__c ||
      newOrd.Ship_To_Name__c != oldOrd.Ship_To_Name__c ||
      newOrd.ShippingCountry != oldOrd.ShippingCountry ||
      newOrd.ShippingState != oldOrd.ShippingState ||
      newOrd.ShippingPostalCode != oldOrd.ShippingPostalCode) &&
      newOrd.Order_Status__c == 'Order Accepted' &&
      (newOrd.type == 'Revenue' ||
      newOrd.type == 'RMA')) ||
      (String.isNotBlank(newOrd.NetSuite_Order__c) &&
      (newOrd.customer_required_ship_date__c != oldOrd.customer_required_ship_date__c ||
      newOrd.Est_Ship_Date__c != oldOrd.Est_Ship_Date__c))
    ) {
      newOrd.Sync_to_NetSuite__c = true;
    }
  }

  /************************************************
Description : Retrieve the metadata for RCDM RelatedSku
*************************************************/
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description Retrieve the metadata for RCDM RelatedSku
   */
  public static void getProductSkus() {
    if (productSkuMap == null || productSkuMap.isEmpty()) {
      productSkuMap = new Map<String, Skus_Mapping__mdt>();
      Map<String, Skus_Mapping__mdt> allProductskus = Skus_Mapping__mdt.getAll();
      for (String developerName : allProductskus.keySet()) {
        productSkuMap.put(allProductskus.get(developerName).Product_Sku__c, allProductskus.get(developerName));
      }
    }
  }

  /***********************************************************************  
      Description : Auto submit EDI Orders
      ************************************************************************/
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description Auto submit EDI Orders
   * @param newOrd
   * @param oldOrd
   * @param stagePos
   * @param amtValidatedOrders
   */

  public void autoSubmitOrder(Order newOrd, Order oldOrd, List<PO_Stage__c> stagePos, Map<Id, Order> amtValidatedOrders) {
    Map<String, String> mandatoryFieldList = new Map<String, String>{
      'ShippingStreet' => 'Shipping Street',
      'ShippingPostalCode' => 'Shipping PostalCode',
      'ShippingCity' => 'Shipping City',
      'ShippingCountryCode' => 'Shipping Country',
      'ShipToContactName__c' => 'Ship To Contact Name',
      'PoDate' => 'Po Date',
      'PoNumber' => 'PO Number',
      'End_User_PO__c' => 'End User PO Number',
      'Shipping_Carrier__c' => 'Shipping Carrier',
      'Payment_Terms__c' => 'Payment Term',
      'Ship_To_Name__c' => 'Ship To Name',
      'Service_Level__c' => 'Service Level',
      'Bill_To_Name__c' => 'Bill To Name',
      'Ship_to_Email__c' => 'Ship to Email',
      'Shipping_Method__c' => 'Shipping Term'
    };
    Date crsdDate = newOrd.customer_required_ship_date__c;
    Boolean checkifFutureQuarter = false;
    if (crsdDate != null) {
      Integer crsdQuarter = isFutureQuarter(crsdDate);
      Date today = Date.today();
      Integer todaysDateQuarter = isFutureQuarter(today);
      if (crsdQuarter > todaysDateQuarter)
        checkifFutureQuarter = true;
    }

    List<String> missingFields = new List<String>();
    string internalOMError = '';
    Decimal differenceAmount = 0.0;
    Boolean automateOrderSubmit =
      ((newOrd.Order_Sub_Type__c == 'MSP Overage' || newOrd.Order_Sub_Type__c == Constants.ORDER_SUB_TYPE_GC_ONDEMAND) && newOrd.Order_Status__c == 'Pending') ||
      ((newOrd.Order_Status__c == 'Pending' ||
      newOrd.Order_Status__c == 'On Hold') &&
      newOrd.Stage_PO__c != null &&
      System.label.Automate_EDI_Order_Submit.EqualsIgnoreCase('YES') &&
      (newOrd.Order_Split_Type__c == 'Not needed' ||
      newOrd.Order_Split_Type__c == 'Split Completed'));
    System.debug(LoggingLevel.DEBUG, 'autoSubmitOrder ' + automateOrderSubmit);
    Map<id, PO_Stage__c> mapStagePOWithId = new Map<id, PO_Stage__c>();
    List<String> lstOrderItemNumber = new List<String>();
    for (PO_Stage__c po : stagePos) {
      mapStagePOWithId.put(po.id, po);
    }
    if (automateOrderSubmit) {
      if (newOrd.Order_Split_Type__c == 'Split Completed' && !newOrd.Is_RWD_Polaris_Quote__c && (newOrd.Order_Sub_Type__c != 'MSP Overage')) {
        newOrd.OM_internal_review__c = true;
        internalOMError = 'Auto order submission - OM internal review for the split PO \n';
      }
      Opportunity opp = oppMap?.get(newOrd.OpportunityId);
      Id renewalOpptyId;
      if (!quotemap.isempty() && quotemap.containskey(neword.SBQQ__Quote__c)) {
        renewalOpptyId = quotemap.get(neword.SBQQ__Quote__c).Renewal_Opportunity__c;
      }
      if (
        newOrd.Type == Constants.ORDER_TYPE_REVENUE &&
        newOrd.Order_Sub_Type__c == Constants.ORDER_SUB_TYPE_RENEWAL &&
        ((opp != null && opp.Opportunity_Sub_Type__c != newOrd.Order_Sub_Type__c) || (opp == null && newOrd.OpportunityId != renewalOpptyId))
      ) {
        internalOMError += 'Opportunity sub-type mismatch with Order \n';
        newOrd.OM_internal_review__c = true;
      }
      Set<String> FieldSet = mandatoryFieldList.keySet();
      for (String fieldName : FieldSet) {
        if (String.isBlank(String.valueOf(newOrd.get(fieldName)))) {
          missingFields.add(mandatoryFieldList.get(fieldName));
        }
      }
      //PRDOPS26-664
      if(String.isBlank(newOrd.Ship_To_Phone_Number__c) && newOrd.Have_Hardware_Products__c){
      	missingFields.add('Ship to Phone Number');
      }
      if (missingFields.size() > 0 && (newOrd.Order_Sub_Type__c != 'MSP Overage' && newOrd.Order_Sub_Type__c != Constants.ORDER_SUB_TYPE_GC_ONDEMAND)) {
        newOrd.OM_internal_review__c = true;
        newOrd.Order_Status__c = 'On Hold';
        newOrd.Hold_Code__c = 'OM Internal Review';
        internalOMError += 'Please make sure ' + String.join(missingFields, ',') + ' filled in.\n';
      }
      /*commented for PRDOPS23-563 
        if (
          newOrd.Partner_Name_Text__c != null &&
          newOrd.Partner_Name_Text__c.containsIgnoreCase('CDW')
        ) {
          newOrd.OM_internal_review__c = true;
          internalOMError += 'Auto order submission - OM internal review for order belong to reseller CDW in EDI PO \n';
        }
        if (newOrd.AddOn_Node_Count__c != null) {
          newOrd.OM_internal_review__c = true;
          internalOMError += 'Auto order submission - OM internal review for Add on products in order in EDI PO \n';
        }
        if (GorefreshOrderIds.contains(newOrd.id)) {
          newOrd.OM_internal_review__c = true;
          internalOMError += 'OM internal review for GoRefresh order \n';
        }
        */
      if (upgradeOrderIds.contains(newOrd.id) && (newOrd.Order_Sub_Type__c != 'MSP Overage' && newOrd.Order_Sub_Type__c != Constants.ORDER_SUB_TYPE_GC_ONDEMAND)) {
        newOrd.OM_internal_review__c = true;
        internalOMError += 'One or more order line requires manual review \n';
      }
      if (newOrd.Bill_To_Name__c == null && (newOrd.Order_Sub_Type__c != 'MSP Overage' && newOrd.Order_Sub_Type__c != Constants.ORDER_SUB_TYPE_GC_ONDEMAND)) {
        newOrd.OM_internal_review__c = true;
        internalOMError += 'Bill to name is missing \n';
      }

      if(newOrd.Type == 'Revenue' && newOrd.Have_Hardware_Products__c && newOrd.Shipping_Carrier__c == 'No Shipping Required'){
        newOrd.OM_internal_review__c = true;
        newOrd.Order_Status__c = 'On Hold'; 	
        newOrd.Hold_Code__c = 'OM Internal Review';
        internalOMError += 'Order contains a hardware product, \'No shipping required\' is an invalid shipping carrier and the order cannot be submitted. \n';
      
      }
    if(newOrd.type == 'Revenue' && !quoteMap.isempty() && quoteMap.containskey(newOrd.SBQQ__Quote__c)
        && quoteMap.get(newOrd.SBQQ__Quote__c)?.SBQQ__PaymentTerms__c!=newOrd.Payment_Terms__c
        && accountMap != null && accountMap.containskey(newOrd.Bill_To_Name__c)
        && accountMap.get(newOrd.Bill_To_Name__c)?.Payment_Term__c !=newOrd.Payment_Terms__c ){
            newOrd.Order_Status__c = 'On Hold'; 	
            newOrd.Hold_Code__c = 'OM Internal Review';
            newOrd.Change_Needed_Reason_Other__c = 'Payment Term Mismatch';
            
        }
      if (
        orderIdOrderItemMap.get(newOrd.id) != null &&
        newOrd.Stage_PO__c != null &&
        mapStagePOWithId.get(newOrd.Stage_PO__c) != null &&
        (newOrd.Order_Sub_Type__c != 'MSP Overage' &&
        newOrd.Order_Sub_Type__c != Constants.ORDER_SUB_TYPE_GC_ONDEMAND) &&
        !amtValidatedOrders.containskey(newOrd.id)
      ) {
        if (Orderhandler.amountOfOrdersOnStage?.get(newOrd.Stage_PO__c) != null) {
          differenceAmount = mapStagePOWithId?.get(newOrd.Stage_PO__c).TotalAmount__c - Orderhandler.amountOfOrdersOnStage?.get(newOrd.Stage_PO__c);
        } else {
          differenceAmount = mapStagePOWithId?.get(newOrd.Stage_PO__c).TotalAmount__c - newOrd?.TotalAmount;
        }
        Map<Id, Order> amtValidatedOrdersForNotNeededMap= new Map<Id, Order>();
        if (
          newOrd.Order_Split_Type__c == 'Not needed' &&
          !quotemap.isempty() &&
          quotemap.containskey(neword.SBQQ__Quote__c) &&
          quotemap.get(neword.SBQQ__Quote__c).SBQQ__Type__c == 'Renewal+Expansion'
        ) {
          amtValidatedOrdersForNotNeededMap = OrderValidationService.validateTotAmtForMultipleOrders((Map<Id, Order>) Trigger.newMap, stagePos, orderIdOrderItemMap);
        }        
        differenceAmount = differenceAmount < 0 ? differenceAmount * -1 : differenceAmount;
        if (differenceAmount > EDI_Pricing_Difference_Threshold__mdt.getInstance('Threshold_Value').Threshold_Value__c && !amtValidatedOrdersForNotNeededMap.containskey(newOrd.id)) {
          newOrd.OM_internal_review__c = true;
          newOrd.Order_Status__c = 'On Hold';
          newOrd.Hold_Code__c = 'PO/Order Pricing Mismatch';
          internalOMError += 'PO/Order Pricing Mismatch \n';
        }
      }
      if (
        String.isBlank(newOrd.ShippingStateCode) &&
        (newOrd.ShippingCountryCode == 'US' ||
        newOrd.ShippingCountryCode == 'CA') &&
        newOrd.Order_Sub_Type__c != Constants.ORDER_SUB_TYPE_GC_ONDEMAND &&
        (newOrd.Order_Sub_Type__c != 'MSP Overage')
      ) {
        newOrd.OM_internal_review__c = true;
        newOrd.Order_Status__c = 'On Hold';
        newOrd.Hold_Code__c = 'Missing ship to information';
        internalOMError += 'State is required for selected country \n';
      }
      // PRDOPS24-867
      if (
        (newOrd.SBQQ__Quote__c == null ||
        newOrd.OpportunityId == null) &&
        newOrd.Type == 'Revenue' &&
        newOrd.Order_Sub_Type__c != Constants.ORDER_SUB_TYPE_GC_ONDEMAND &&
        newOrd.Order_Sub_Type__c != Constants.ORDER_SUB_TYPE_MSP_OVERAGE
      ) {
        newOrd.Order_Status__c = 'On Hold';
        newOrd.Hold_Code__c = String.isBlank(newOrd.Hold_Code__c)
          ? 'Opportunity/Quote missing'
          : !newOrd.Hold_Code__c.contains('Opportunity/Quote missing') ? newOrd.Hold_Code__c + ';Opportunity/Quote missing' : newOrd.Hold_Code__c;
      }
        if (!Boolean.valueOf(Order_control__mdt.getInstance('Disable_Quantity_And_Price_Validation').Value__c) && newOrd.Order_Sub_Type__c != Constants.ORDER_SUB_TYPE_GC_OFFER && newOrd.Order_Sub_Type__c != Constants.ORDER_SUB_TYPE_MSP_OVERAGE && newOrd.Type != 'Revenue Internal') {
        internalOMError = validateOIandPOI(newOrd, internalOMError);
      }
      if (String.isNotBlank(internalOMError)) {
        newOrd.Change_Needed_Reason_Other__c = internalOMError;
        return;
      }

      if (newOrd.Order_Split_Type__c != 'Split Completed' || (newOrd.Order_Split_Type__c == 'Split Completed' && newOrd.Is_RWD_Polaris_Quote__c)) {
        if (orderIdOrderItemMap.get(newOrd.id) != null) {
          for (OrderItem oi : orderIdOrderItemMap.get(newOrd.Id)) {
            if (
              !rcdmMdt.isEmpty() &&
              rcdmMdt.containskey(oi.product2.Name) &&
              newOrd.Quote_RCDM_T_EOL_Date__c != null &&
              newOrd.Quote_RCDM_T_EOL_Date__c < System.Today() &&
              newOrd.Type == 'Revenue' &&
              String.isBlank(newOrd.Order_Sub_Type__c)
            ) {
              newOrd.Order_Status__c = 'On Hold';
              newOrd.Hold_Code__c = 'OM Internal Review';
              if (String.isBlank(newOrd.Memo__c) || !newOrd.Memo__c.contains(RCDMT_EOL_Date_MSG)) {
                newOrd.Memo__c = (String.isBlank(newOrd.Memo__c) ? RCDMT_EOL_Date_MSG : newOrd.Memo__c + ',' + RCDMT_EOL_Date_MSG).abbreviate(255);
              }
              if (String.isBlank(newOrd.Change_Needed_Reason_Other__c) || !newOrd.Change_Needed_Reason_Other__c.contains(RCDMT_EOL_Date_MSG)) {
                newOrd.Change_Needed_Reason_Other__c = (String.isBlank(newOrd.Change_Needed_Reason_Other__c)
                    ? RCDMT_EOL_Date_MSG
                    : newOrd.Change_Needed_Reason_Other__c + ',' + RCDMT_EOL_Date_MSG)
                  .abbreviate(255);
              }
              break;
            } else if (
              newOrd.Order_Sub_Type__c != 'MSP Overage' &&
              newOrd.Order_Sub_Type__c != Constants.ORDER_SUB_TYPE_GC_ONDEMAND &&
              (oi.Product2.SBQQ__SubscriptionPricing__c != null) &&
              (oi.SBQQ__SubscriptionTerm__c == null)
            ) {
              newOrd.Order_Status__c = 'On Hold';
              newOrd.Hold_Code__c = 'OM Internal Review';
              newOrd.Change_Needed_Reason_Other__c = 'Subscription Term must be stamped on Order product in order to submit Order';
              break;
            } else if (
              newOrd.Type ==
              'revenue' && // Bypassing PriceMatch For Scale Utility Upgraded OR FUE  Skus
              oi.SBQQ__QuoteLine__c != null &&
              oi.SBQQ__QuoteLine__r.SBQQ__NetPrice__c != null &&
              oi.Sales_Price__c != null &&
              !OrderItemTriggerHelper.isScaleUtilityUpgradeSKU(oi.Product2) &&
              (Math.abs(oi.SBQQ__QuoteLine__r.SBQQ__NetPrice__c.round(System.RoundingMode.HALF_EVEN) - oi.Sales_Price__c.round(System.RoundingMode.HALF_EVEN))) > 0
            ) {
              lstOrderItemNumber.add(oi.SBQQ__QuoteLine__r.Name);
            } else if (
              (!newOrd.ManualFulfilment__c && (newOrd.is_Amendment_Order__c || newOrd.Order_Sub_Type__c == 'Renewal') && String.isBlank(oi.SerialNumber__c)) &&
              (!newOrd.Is_RWD_Polaris_Quote__c ||
              (newOrd.Is_RWD_Polaris_Quote__c &&
              ((oi.Product2.Product_Level__c == 'Hybrid Software' &&
              (oi.Product2.Product_Subtype__c == 'SaaS Cloud' ||
              oi.Product2.Product_Type__c == 'Complete Edition' ||
              oi.Product2.Product_Type__c == 'Complete Edition Elite' ||
              oi.Product2.Product_Type__c == 'Complete Edition Pro')) ||
              (oi.Product2.Product_Level__c == 'OnPrem' &&
              (oi.Product2.Product_Type__c == 'Foundation Edition' ||
              oi.Product2.Product_Type__c == 'Business Edition' ||
              oi.Product2.Product_Type__c == 'Enterprise Edition') &&
              OI.Product2.product_subtype__c == null) ||
              (oi.Product2.Product_Level__c == 'LOD Software')) &&
              !(oi.Product2.Family == 'Third Party License' ||
              String.isNotBlank(oi.TPH_OEM__c) ||
              String.isNotBlank(oi.TPH_Models_Gen__c)))) //PRDOPS26-393
            ) {
              newOrd.Order_Status__c = 'On Hold';
              newOrd.Hold_Code__c = 'Missing serial number';
              newOrd.Change_Needed_Reason_Other__c = 'Serial Number must be stamped on Order product in order to submit Renewal/Amendment Order';
              break;
            } else if (
              !newOrd.ManualFulfilment__c &&
              (newOrd.Order_Sub_Type__c == 'Renewal' ||
              (newOrd.Order_Sub_Type__c == 'Amendment' &&
              oi.SBQQ__QuoteLine__c != null &&
              oi.SBQQ__QuoteLine__r.SBQQ__Quote__r.Co_Term__c)) &&
              oi.Product2.Product_Type__c != 'Reinstate Fee' &&
              (oi.Support_Start_Date__c == null ||
              oi.Support_End_Date__c == null)
            ) {
              newOrd.Order_Status__c = 'On Hold';
              newOrd.Hold_Code__c = 'Missing start or end dates';
              newOrd.Change_Needed_Reason_Other__c = 'Start and End date can not be blanked for Renewal/Amendment orders';
              break;
            }
          }

          if (!lstOrderItemNumber.isEmpty()) {
            newOrd.Order_Status__c = 'On Hold';
            newOrd.Hold_Code__c = 'OM Internal Review';
            newOrd.Change_Needed_Reason_Other__c = 'Mismatch of quoteline and orderItem net unit price for ' + lstOrderItemNumber;
          }

          if (newOrd.Order_Status__c != 'On Hold' && newOrd.type == 'Revenue' && String.isBlank(internalOMError)) {
            String crsdHoldCodeString = evaluateCRSDHoldReason(newOrd, orderIdOrderItemMap, checkifFutureQuarter);
            if (crsdHoldCodeString != null) {
              newOrd.Hold_Code__c = crsdHoldCodeString;
              newOrd.Change_Needed_Reason_Other__c = crsdHoldCodeString;
              newOrd.Order_Status__c = 'On Hold';
            }
          }
          /*
            @Author: Shrutika
            @Description : populate Auto_Submission_Date_Time__c when Order Status is not 'On Hold' and Old Auto submission Date is null.
            @Ticket No. PRDOPS22-261
            */
          if (oldOrd.Auto_Submission_Date_Time__c == null && newOrd.Order_Status__c != 'On Hold') {
            newOrd.Auto_Submission_Date_Time__c = DateTime.now();
          }
        }
        if (newOrd.Order_Status__c != 'On Hold') {
          newOrd.Internal_Order_Stage__c = 'Pending Validation';
          newOrd.Order_Status__c = 'Pending';
            if(newOrd.Order_Split_Type__c == 'Split Completed'){ 
                SplitOrder.submittedReplOrd.add(newOrd.Ordernumber);    
            }
            
        }
      }
    } else if (
      !quotemap.isempty() &&
      quotemap.containskey(neword.SBQQ__Quote__c) &&
      quotemap.get(neword.SBQQ__Quote__c).RWD_Deal_Ops_Exception__c == constants.RCDMT_EXT_RWD_DEAL_OPS_EXCEPTION
    ) {
      // Check If Quote Is Of Type RCDM-T Manual Extension
      // Then AutoSubmission Parameters and auto Sync To NS
      //PRDOPS25-496
      newOrd.Sync_to_NetSuite__c = true;
      newOrd.Internal_Order_Stage__c = 'Order Submitted';
      if (oldOrd.Auto_Submission_Date_Time__c == null && newOrd.Order_Status__c != 'On Hold') {
        newOrd.Auto_Submission_Date_Time__c = DateTime.now();
        newOrd.Screening_Source__c = 'None';
        newOrd.ScreenStatus__c = 'Approved Bypassed';
      }
    }
    /*
      @Author: Sukesh k
      @Description: DGWD-17
        */
    if (
      // Not Shipped Already
      !(newOrd.Status == 'Shipped' ||
      newOrd.Status == 'Order Accepted' ||
      newOrd.Order_Status__c == 'Shipped' ||
      newOrd.Order_Status__c == 'Order Accepted' ||
      newOrd.Order_Status__c == 'Returned') &&
      // completed price calculations
      !(newOrd.Is_CPQ_Price_Book__c &&
      newOrd.SBQQ__PriceCalcStatus__c != 'Completed' &&
      newOrd.SBQQ__PriceCalcStatus__c != 'Not Needed') &&
      // RMA Related Order
      (newOrd.Type.equals('RMA') && (newOrd.Order_Sub_Type__c.equals('Tech Order') || newOrd.Order_Sub_Type__c.equals('Part Order')))
    ) {
      // System.debug('Check for Price of Order Items: ');
      Boolean orderPriceFree = (newOrd.TotalAmount == 0);
      if (orderPriceFree && String.isBlank(newOrd.Hold_Code__c)) {
        newOrd.Internal_Order_Stage__c = 'Pending Validation';
      }
    }
  }

  private class AggregatedLineItems {
    private Decimal allItemsTotalQuant;
    private Decimal allItemsTotalPrice;
    private Boolean byPassQuantValidation;

    AggregatedLineItems(Decimal allItemsTotalQuant, Decimal allItemsTotalPrice, Boolean byPassQuantValidation) {
      this.allItemsTotalQuant = allItemsTotalQuant;
      this.allItemsTotalPrice = allItemsTotalPrice;
      this.byPassQuantValidation = byPassQuantValidation;
    }
  }

  /***********************************************************************
      Description : This method is Validating all the OIs and POIs Quantiy and Price with QLI 
  ************************************************************************/
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description This method is Validating all the OIs and POIs Quantiy and Price with QLI
   * @param newOrd
   * @param internalOMError
   * @return String
   */
  public String validateOIandPOI(Order newOrd, String internalOMError) {
    Map<Id, List<OrderItem>> quoteIdOrderItemMap = new Map<Id, List<OrderItem>>();
    Map<Id, AggregatedLineItems> mapQLIWithAggregatedOIs = new Map<Id, AggregatedLineItems>();
    Map<Id, AggregatedLineItems> mapQLIWithAggregatedPOIs = new Map<Id, AggregatedLineItems>();

    for (OrderItem OI : TransactionalDataCollection.orderItemMainList) {
      if(OI.Order.SBQQ__Quote__c != null){
      if (quoteIdOrderItemMap.containsKey(OI.Order?.SBQQ__Quote__c)) {
        quoteIdOrderItemMap.get(OI.Order?.SBQQ__Quote__c).add(OI);
      } else {
        quoteIdOrderItemMap.put(OI.Order?.SBQQ__Quote__c, new List<OrderItem>{ OI });
      }
    }
    }

    Decimal thresholdValue = EDI_Pricing_Difference_Threshold__mdt.getInstance('Threshold_Value').Threshold_Value__c;

  if (newOrd.SBQQ__Quote__c != null && quoteIdOrderItemMap.containsKey(newOrd.SBQQ__Quote__c)) {
    for (OrderItem OI : quoteIdOrderItemMap.get(newOrd?.SBQQ__Quote__c)) {
      if (OI.SBQQ__QuoteLine__c == null)
        continue;
      AggregatedLineItems tempAggregatedLine = mapQLIWithAggregatedOIs.get(OI.SBQQ__QuoteLine__c);
      if (tempAggregatedLine == null) {
        tempAggregatedLine = new AggregatedLineItems(0, 0, false);
      }
      tempAggregatedLine.allItemsTotalQuant += OI.Quantity;
      tempAggregatedLine.allItemsTotalPrice += OI.TotalPrice;
      mapQLIWithAggregatedOIs.put(OI.SBQQ__QuoteLine__c, tempAggregatedLine);
    }
    }

    for (PO_Stage__c PO : TransactionalDataCollection.stagePo) {
      String distributor = '';
      String billtoName = PO?.Bill_To_Name__c;
      if (billtoName != null && OrderInserthelper.getDistributorMetadata(billtoName) != null) {
        distributor = OrderInserthelper.getDistributorMetadata(billtoName).Po_Disti_Type__c;
      }
      if (newOrd.SBQQ__Quote__c != PO.Quote__c)
        continue;
      for (PO_Item_Stage__c POI : PO.PO_Item_Stage__r) {
        if (POI.Quote_Line__c == null)
          continue;
        Boolean byPassValidation = (distributor != null && distributor == 'INGRAM' && POI?.Product__r?.Product_Payment_Option__c == 'Annual') ? true : false;
        AggregatedLineItems tempAggregatedLine = mapQLIWithAggregatedPOIs.get(POI.Quote_Line__c);
        if (tempAggregatedLine == null) {
          tempAggregatedLine = new AggregatedLineItems(0, 0, byPassValidation);
        }
        tempAggregatedLine.allItemsTotalQuant += POI.Quantity__c;
        tempAggregatedLine.allItemsTotalPrice += POI.UnitPrice__c * POI.Quantity__c;
        mapQLIWithAggregatedPOIs.put(POI.Quote_Line__c, tempAggregatedLine);
      }
    }
    system.debug(LoggingLevel.DEBUG, '### mapQLIWithAggregatedPOIs:' + mapQLIWithAggregatedPOIs);
    if (quoteMap.containsKey(newOrd?.SBQQ__Quote__c)) {
      SBQQ__Quote__c quote = quoteMap.get(newOrd.SBQQ__Quote__c);
      for (SBQQ__QuoteLine__c QLI : quote.SBQQ__LineItems__r) {
        if (QLI.Wrapper_Line__c || QLI.SBQQ__Optional__c || (QLI.SBQQ__Existing__c && QLI.SBQQ__EffectiveQuantity__c == 0))
          continue;
        if (
          (mapQLIWithAggregatedOIs.containsKey(QLI.Id) && QLI.SBQQ__Quantity__c != mapQLIWithAggregatedOIs.Get(QLI.Id).allItemsTotalQuant) ||
          (mapQLIWithAggregatedPOIs.containsKey(QLI.Id) &&
          !mapQLIWithAggregatedPOIs.Get(QLI.Id)?.byPassQuantValidation &&
          QLI.SBQQ__Quantity__c != mapQLIWithAggregatedPOIs.Get(QLI.Id).allItemsTotalQuant)
        ) {
          newOrd.Order_Status__c = 'On Hold';
          if (newOrd.Hold_Code__c != null && !newOrd.Hold_Code__c.contains('Quantity mismatch at the line level')) {
            newOrd.Hold_Code__c += ';Quantity mismatch at the line level';
          } else if (newOrd.Hold_Code__c == null) {
            newOrd.Hold_Code__c = 'Quantity mismatch at the line level';
          }
          if (!internalOMError.contains('Quantity mismatch at the line level')) {
            internalOMError += 'Quantity mismatch at the line level \n';
          }
        }
        if (
          (mapQLIWithAggregatedOIs.containsKey(QLI.Id) && Math.abs((QLI.SBQQ__NetTotal__c - mapQLIWithAggregatedOIs.Get(QLI.Id).allItemsTotalPrice)) > thresholdValue) ||
          (mapQLIWithAggregatedPOIs.containsKey(QLI.Id) && Math.abs((QLI.SBQQ__NetTotal__c - mapQLIWithAggregatedPOIs.Get(QLI.Id).allItemsTotalPrice)) > thresholdValue)
        ) {
          newOrd.Order_Status__c = 'On Hold';
          if (newOrd.Hold_Code__c != null && !newOrd.Hold_Code__c.contains('Price mismatch at the line level')) {
            newOrd.Hold_Code__c += ';Price mismatch at the line level';
          } else if (newOrd.Hold_Code__c == null) {
            newOrd.Hold_Code__c = 'Price mismatch at the line level';
          }
          if (!internalOMError.contains('Price mismatch at the line level')) {
            internalOMError += 'Price mismatch at the line level \n';
          }
        }
      }
    }
    return internalOMError;
  }

  /***********************************************************************  
      Description : Global trade compliance screnning 
      ************************************************************************/
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description copy single stage PO details to order
   * @param newOrd
   * @param oldOrd
   * @param acc
   * @param opp
   * @param screenPartyList
   * @param excludePartyList
   */
  public void complianceScreen(Order newOrd, order oldOrd, Account acc, Opportunity opp, List<GTC_Screening__c> screenPartyList, set<string> excludePartyList) {
    List<Order> UpdateOrderScreening = new List<order>();
    List<string> HC_List = new List<String>();
    RPS__c screenSetting = RPS__c.getInstance(UserInfo.getUserId());
    if (
      (newOrd.Type == 'Revenue' ||
      newOrd.Type == 'RMA' ||
      newOrd.Type == 'POC') &&
      newOrd.status != 'Cancelled' &&
      !(newOrd.order_status__c == 'On Hold' &&
      String.isNotBlank(newOrd.Hold_Code__c) &&
      newOrd.Hold_Code__c.equalsIgnoreCase('Contract in negotiations'))
    ) {
      if (!oldOrd.Manual_Approve__c && newOrd.Manual_Approve__c && newOrd.Screening_Source__c == 'Internal' && newOrd.ScreenStatus__c == 'On hold') {
        if (newOrd.Type != 'POC')
          newOrd.Sync_to_NetSuite__c = true;
        newOrd.ScreenStatus__c = 'Approved Bypassed';
        newOrd.Internal_Order_Stage__c = 'Order Submitted';
      }
      if (
        oldOrd != null &&
        ((newOrd.Internal_Order_Stage__c == 'Pending Validation' &&
        newOrd.Internal_Order_Stage__c != oldOrd.Internal_Order_Stage__c) ||
        (ORIGIN_CONTEXT == 'Insert' &&
        newOrd.Type == 'POC' &&
        newOrd.POC_Type__c != 'Conditional PO') ||
        (newOrd.Sync_to_NetSuite__c == true &&
        newOrd.Sync_to_NetSuite__c != oldOrd.Sync_to_NetSuite__c))
      ) {
        try {
          if (
            newOrd.Order_Status__c != 'Order Accepted' &&
            newOrd.Order_Status__c != 'Shipped' &&
            newOrd.ScreenStatus__c != 'Approved' &&
            newOrd.ScreenStatus__c != 'Approved Bypassed'
          ) {
            newOrd.Screening_Source__c = screenSetting.Screening_Source__c;
            if (newOrd.Screening_Source__c == 'Internal') {
              InternalScreening(newOrd, acc, screenPartyList, excludePartyList);
              newOrd.Partner_Screen_Status__c = newOrd.Partner_Name__c != null ? Constants.ORDER_SCREEN_STATUS_REQUIRED : Constants.ORDER_SCREEN_STATUS_NA;
              newOrd.Primary_Contact_Screen_Status__c = newOrd.Type == 'RMA' ? Constants.ORDER_SCREEN_STATUS_NA : Constants.ORDER_SCREEN_STATUS_REQUIRED;
              newOrd.Polaris_Contact_Screen_Status__c = newOrd.Polaris_Contact__c != null ? Constants.ORDER_SCREEN_STATUS_REQUIRED : Constants.ORDER_SCREEN_STATUS_NA;
              newOrd.SDPScreenStatus__c = opp != null && opp.MSP_End_User_Lookup__c != null && opp.Managed_Services_Deal_type__c == Constants.OPP_MSP_DEAL_TYPE_DEDICATED_DEAL ? Constants.ORDER_SCREEN_STATUS_REQUIRED : Constants.ORDER_SCREEN_STATUS_NA;
            } else if (newOrd.Screening_Source__c == 'None') {
              if (newOrd.Type != 'POC')
                newOrd.Sync_to_NetSuite__c = true;
              newOrd.ScreenStatus__c = 'Approved Bypassed';
              newOrd.Internal_Order_Stage__c = 'Order Submitted';
            } else if (newOrd.Screening_Source__c == 'External') {
              ValidationResp VR = ValidateOrderSubmission(newOrd);
              system.debug(LoggingLevel.FINE, 'Validation response' + VR);
              if (VR.isValid) {
                newOrd.ScreenStatus__c = newOrd.ShipToScreenStatus__c = newOrd.Billto_EndUser_Screen_Status__c = newOrd.Shipto_EndUser_Screen_Status__c = newOrd.ShipToContactScreenStatus__c = Constants.ORDER_SCREEN_STATUS_REQUIRED;
                newOrd.Polaris_Contact_Screen_Status__c = newOrd.Polaris_Contact__c != null ? Constants.ORDER_SCREEN_STATUS_REQUIRED : Constants.ORDER_SCREEN_STATUS_NA;
                newOrd.SDPScreenStatus__c = opp != null && opp.MSP_End_User_Lookup__c != null && opp.Managed_Services_Deal_type__c == Constants.OPP_MSP_DEAL_TYPE_DEDICATED_DEAL ? Constants.ORDER_SCREEN_STATUS_REQUIRED : Constants.ORDER_SCREEN_STATUS_NA;
                newOrd.Partner_Screen_Status__c = newOrd.Partner_Name__c != null ? Constants.ORDER_SCREEN_STATUS_REQUIRED : Constants.ORDER_SCREEN_STATUS_NA;
                newOrd.Primary_Contact_Screen_Status__c = newOrd.Type == 'RMA' ? Constants.ORDER_SCREEN_STATUS_NA : Constants.ORDER_SCREEN_STATUS_REQUIRED;
                newOrd.Billto_EndUser_Screen_StatusMessage__c = newOrd.ScreeningMessage__c = newOrd.ShipToContactScreenStatusMessage__c = newOrd.Shipto_EndUser_Screen_StatusMessage__c = newOrd.ShipToScreenStatusMessage__c = newOrd.Primary_Contact_Screen_StatusMessage__c = newOrd.Polaris_Contact_Screen_StatusMessage__c = newOrd.Partner_Screen_StatusMessage__c = newOrd.Third_Party_Screen_Status__c = newOrd.SDPScreenStatusMessage__c = '';
                newOrd.ShipToContactScreeningId__c = newOrd.Shipto_EndUser_ScreeningId__c = newOrd.ShipToScreeningId__c = newOrd.Billto_EndUser_Screening_Id__c = '';
                newOrd.Credit_Check_Failure_Reason__c = null;
                newOrd.Internal_Order_Stage__c = 'Order Submitted';
                if (newOrd.Type == 'Revenue' && oldOrd != null && oldOrd.Order_Status__c != 'Pending') {
                  if (newOrd.Hold_Code__c != null && newOrd.Hold_Code__c == 'Global Trade Compliance Screening')
                    newOrd.Hold_Code__c = null;
                } else if (newOrd.Type.equalsIgnoreCase('RMA') && oldOrd != null && oldOrd.Order_Status__c != 'Pending') {
                  newOrd.Order_Status__c = 'Pending';
                  if (newOrd.Hold_Code__c != null && newOrd.Hold_Code__c == 'Global Trade Compliance Screening')
                    newOrd.Hold_Code__c = null;
                }
                newOrd.Is_RPS_Required__c = screenSetting.Is_RPS_Required__c;
              } else {
                System.debug(LoggingLevel.WARN, 'Order Submit error' + VR.description);
                newOrd.adderror(VR.description);
                return;
              }
            }
          } else if (newOrd.Internal_Order_Stage__c == 'Pending Validation') {
            //To justify Jira#RWD-182 added below If condidation.
            newOrd.Internal_Order_Stage__c = 'Pending';
          }
          if (newOrd.Type != 'POC') {
            newOrd.Sync_to_NetSuite__c = true;
          }
        } catch (exception e) {
          newOrd.Sync_to_NetSuite__c = false;
          newOrd.Internal_Order_Stage__c = 'Pending';
          errorLogs.add(
            new Error_Logs__c(Error_Type__c = 'Order Error', Error_Message__c = e.getMessage() + '\r\n' + e.getStackTraceString(), Related_Order__c = newOrd.id, Type__c = 'SFDC')
          );
          System.debug(LoggingLevel.Error, 'Error Logsa :: ' + JSON.Serialize(errorLogs));
        }
      } else if (newOrd.Internal_Order_Stage__c == 'Pending Validation') {
        //To justify Jira#RWD-182 added below If condidation.
        newOrd.Internal_Order_Stage__c = 'Pending';
      }
    }
    //  else{
    // Call only if the screening status is updated
    System.debug(LoggingLevel.INFO, ' Order new value' + neword + 'Ord Old value' + oldOrd);
    if (
      newOrd.Screening_Source__c == 'External' &&
      newOrd.ScreenStatus__c != 'Completed' &&
      newOrd.status != 'Cancelled' &&
      newOrd.ScreenStatus__c != 'Denied' &&
      oldOrd != null &&
      (newOrd.ScreenStatus__c != oldOrd.ScreenStatus__c ||
      newOrd.ShipToScreenStatus__c != oldOrd.ShipToScreenStatus__c ||
      newOrd.Billto_EndUser_Screen_Status__c != oldOrd.Billto_EndUser_Screen_Status__c ||
      newOrd.Shipto_EndUser_Screen_Status__c != oldOrd.Shipto_EndUser_Screen_Status__c ||
      newOrd.ShipToContactScreenStatus__c != oldOrd.ShipToContactScreenStatus__c ||
      newOrd.Partner_Screen_Status__c != oldOrd.Partner_Screen_Status__c ||
      newOrd.SDPScreenStatus__c != oldOrd.SDPScreenStatus__c ||
      newOrd.Primary_Contact_Screen_Status__c != oldOrd.Primary_Contact_Screen_Status__c ||
      newOrd.Polaris_Contact_Screen_Status__c != oldOrd.Polaris_Contact_Screen_Status__c ||
      (newOrd.Third_Party_Screen_Status__c != oldOrd.Third_Party_Screen_Status__c &&
      (newOrd.Third_Party_Screen_Status__c == 'HOLD' ||
      oldOrd.Third_Party_Screen_Status__c == 'HOLD')))
    ) {
      if (
        newOrd.ShipToScreenStatus__c == 'Denied' ||
        newOrd.Billto_EndUser_Screen_Status__c == 'Denied' ||
        newOrd.Shipto_EndUser_Screen_Status__c == 'Denied' ||
        newOrd.ShipToContactScreenStatus__c == 'Denied' ||
        newOrd.Partner_Screen_Status__c == 'Denied' ||
        newOrd.SDPScreenStatus__c == 'Denied' ||
        newOrd.Primary_Contact_Screen_Status__c == 'Denied' ||
        newOrd.Polaris_Contact_Screen_Status__c == 'Denied' ||
        newOrd.ShipToScreenStatus__c == 'Awaiting user intervention' ||
        newOrd.Billto_EndUser_Screen_Status__c == 'Awaiting user intervention' ||
        newOrd.Shipto_EndUser_Screen_Status__c == 'Awaiting user intervention' ||
        newOrd.ShipToContactScreenStatus__c == 'Awaiting user intervention' ||
        newOrd.Partner_Screen_Status__c == 'Awaiting user intervention' ||
        newOrd.SDPScreenStatus__c == 'Awaiting user intervention' ||
        newOrd.Primary_Contact_Screen_Status__c == 'Awaiting user intervention' ||
        newOrd.Polaris_Contact_Screen_Status__c == 'Awaiting user intervention' ||
        newOrd.ShipToScreenStatus__c == 'On hold' ||
        newOrd.Billto_EndUser_Screen_Status__c == 'On hold' ||
        newOrd.Shipto_EndUser_Screen_Status__c == 'On hold' ||
        newOrd.ShipToContactScreenStatus__c == 'On hold' ||
        newOrd.Partner_Screen_Status__c == 'On hold' ||
        newOrd.SDPScreenStatus__c == 'On hold' ||
        newOrd.Primary_Contact_Screen_Status__c == 'On hold' ||
        newOrd.Polaris_Contact_Screen_Status__c == 'On hold' ||
        newOrd.Third_Party_Screen_Status__c == 'HOLD'
      ) {
        if (oldOrd.Order_Status__c != 'On Hold')
          newOrd.Order_Status__c = 'On Hold';
        if (newOrd.Hold_Code__c != null) {
          if (isNewHoldCode(newOrd.Hold_Code__c.split(';'), 'Global Trade Compliance Screening')) {
            newOrd.Hold_Code__c = newOrd.Hold_Code__c + ';' + 'Global Trade Compliance Screening';
          }
        } else {
          newOrd.Hold_Code__c = 'Global Trade Compliance Screening';
        }
      }

      if (
        newOrd.ShipToScreenStatus__c == 'Denied' ||
        newOrd.Billto_EndUser_Screen_Status__c == 'Denied' ||
        newOrd.ShipToContactScreenStatus__c == 'Denied' ||
        newOrd.Partner_Screen_Status__c == 'Denied' ||
        newOrd.SDPScreenStatus__c == 'Denied' ||
        newOrd.Primary_Contact_Screen_Status__c == 'Denied' ||
        newOrd.Polaris_Contact_Screen_Status__c == 'Denied'
      ) {
        newOrd.ScreenStatus__c = 'Denied';
      } else if (
        newOrd.ShipToScreenStatus__c == 'Required' ||
        newOrd.Billto_EndUser_Screen_Status__c == 'Required' ||
        newOrd.Shipto_EndUser_Screen_Status__c == 'Required' ||
        newOrd.ShipToContactScreenStatus__c == 'Required' ||
        newOrd.Partner_Screen_Status__c == 'Required' ||
        newOrd.SDPScreenStatus__c == 'Required' ||
        newOrd.Primary_Contact_Screen_Status__c == 'Required' ||
        newOrd.Polaris_Contact_Screen_Status__c == 'Required'
      ) {
        newOrd.ScreenStatus__c = 'Required';
      } else if (
        newOrd.ShipToScreenStatus__c == 'on hold' ||
        newOrd.Billto_EndUser_Screen_Status__c == 'on hold' ||
        newOrd.Shipto_EndUser_Screen_Status__c == 'on hold' ||
        newOrd.ShipToContactScreenStatus__c == 'on hold' ||
        newOrd.Partner_Screen_Status__c == 'on hold' ||
        newOrd.SDPScreenStatus__c == 'on hold' ||
        newOrd.Primary_Contact_Screen_Status__c == 'on hold' ||
        newOrd.Polaris_Contact_Screen_Status__c == 'on hold' ||
        newOrd.Third_Party_Screen_Status__c == 'HOLD'
      ) {
        newOrd.ScreenStatus__c = 'On hold';
      } else if (
        newOrd.ShipToScreenStatus__c == 'Approved' &&
        newOrd.Billto_EndUser_Screen_Status__c == 'Approved' &&
        newOrd.Shipto_EndUser_Screen_Status__c == 'Approved' &&
        newOrd.ShipToContactScreenStatus__c == 'Approved' &&
        (newOrd.Primary_Contact_Screen_Status__c == 'Approved' ||
        newOrd.Primary_Contact_Screen_Status__c == Constants.ORDER_SCREEN_STATUS_NA) &&
        (newOrd.Partner_Screen_Status__c == 'Approved' ||
          newOrd.Partner_Screen_Status__c == Constants.ORDER_SCREEN_STATUS_NA) &&
        (newOrd.SDPScreenStatus__c == 'Approved' ||
          newOrd.SDPScreenStatus__c == Constants.ORDER_SCREEN_STATUS_NA) &&
        (newOrd.Polaris_Contact_Screen_Status__c == 'Approved' ||
          newOrd.Polaris_Contact_Screen_Status__c == Constants.ORDER_SCREEN_STATUS_NA)
      ) {
        newOrd.ScreenStatus__c = 'Approved';
        if (newOrd.Type != 'POC' && (newOrd.Order_Status__c != 'On Hold' || (newOrd.Order_Status__c == 'On Hold' && newOrd.Hold_Code__c == 'Global Trade Compliance Screening'))) {
          newOrd.Sync_to_NetSuite__c = true;
        }
        if (
          newOrd.Type != null &&
          (newOrd.Type.equalsIgnoreCase('RMA') ||
          newOrd.Type.equalsIgnoreCase('Revenue') ||
          newOrd.Type.equalsIgnoreCase('POC')) &&
          newOrd.Hold_Code__c == 'Global Trade Compliance Screening'
        ) {
          newOrd.Order_Status__c = String.isNotBlank(newOrd.NetSuite_Order__c) ? 'Order Accepted' : 'Pending';
          if (oldOrd.Order_Status__c != newOrd.Order_Status__c && newOrd.Order_Status__c == 'Order Accepted' && newOrd.Order_Accepted_Timestamp__c == null) {
            newOrd.Order_Accepted_Timestamp__c = DateTime.now();
          }
        }
        if (newOrd.Hold_Code__c != null) {
          HC_List = newOrd.Hold_Code__c.split(';');
        }

        if (HC_List.indexOf('Global Trade Compliance Screening') != -1) {
          HC_List.remove(HC_List.indexOf('Global Trade Compliance Screening'));
          newOrd.Hold_Code__c = string.join(HC_List, ';');
        }
      } else if (
        newOrd.ShipToScreenStatus__c == 'Awaiting user intervention' ||
        newOrd.Billto_EndUser_Screen_Status__c == 'Awaiting user intervention' ||
        newOrd.Shipto_EndUser_Screen_Status__c == 'Awaiting user intervention' ||
        newOrd.ShipToContactScreenStatus__c == 'Awaiting user intervention' ||
        newOrd.Partner_Screen_Status__c == 'Awaiting user intervention' ||
        newOrd.SDPScreenStatus__c == 'Awaiting user intervention' ||
        newOrd.Primary_Contact_Screen_Status__c == 'Awaiting user intervention' ||
        newOrd.Polaris_Contact_Screen_Status__c == 'Awaiting user intervention'
      ) {
        newOrd.ScreenStatus__c = 'On hold';
      } else {
        System.debug(LoggingLevel.ERROR, 'No RPS screening update');
      }
    }
    // }
    if (oldOrd.ScreenStatus__c != newOrd.ScreenStatus__c && (newOrd.ScreenStatus__c == 'Approved' || newOrd.ScreenStatus__c == 'Approved Bypassed')) {
      if (newOrd.Type == 'POC' && newOrd.Have_Polaris_Products__c == true) { // PRDOPS-544: Skip callout for RSCP-only orders
        newOrd.Send_for_Polaris_Fulfilment__c = true;
        if(!newOrd.RSC_G_Enabled__c && String.isNotBlank(checkRSCPostCall.Value__c) && Boolean.valueOf(checkRSCPostCall.Value__c)){
          newOrd.Polaris_Fulfillment_Status__c = 'Provisioning Requested';
        }
      }
    }
  }
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description Validate order before submission.
   * @param newOrd
   * @return ValidationResp
   */
  private ValidationResp validateOrderSubmission(Order newOrd) {
    List<string> validHoldCodes = RPS__c.getOrgDefaults().Valid_HoldCodes__c.split(';');
    System.debug(LoggingLevel.FINE, 'Order Hold Code' + newOrd.Hold_Code__c);
    if (newOrd.Hold_Code__c != null) {
      for (string str : newOrd.Hold_Code__c.split(';')) {
        if (!validHoldCodes.contains(str)) {
          return new ValidationResp(false, ' Please clear hold codes');
        }
      }
    }
    return new ValidationResp(true, null);
  }
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description Wrapper class to Set Desciption and isvalid variables.
   */
  public class ValidationResp {
    /**
     * @description isValid
     * @return Boolean
     */
    public boolean isValid { get; set; } // This comment is ignored by the parser
    /**
     * @description description
     * @return String
     */
    public string description { get; set; }

    /**
     * @author Prashant Kumar
     * @date 05-03-2025
     * @description constructor ValidationResp to  Set Desciption and isvalid variables.
     * @param isValid
     * @param description
     */
    public ValidationResp(boolean isValid, string description) {
      this.isValid = isValid;
      this.description = description;
    }
  }
  private boolean isNewHoldCode(String[] existingHC, String newHC) {
    for (String HC : existingHC) {
      if (HC.equalsIgnoreCase(newHC)) {
        return false;
      }
    }
    return true;
  }
  /*************************************
    Internal screening
    ***********************************/

  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description Internal screening of the order
   * @param newOrd
   * @param acc
   * @param screenPartyList
   * @param excludePartyList
   */
  public void internalScreening(Order newOrd, Account acc, List<GTC_Screening__c> screenPartyList, set<string> excludePartyList) {
    newOrd.Is_RPS_Required__c = false;
    List<string> onHoldReasons = new List<string>();
    Set<string> screenedAddress = new Set<string>(); //{BillToAcc,ShipToAcc,ShipToContact,ShipToName}
    Opportunity opp = newOrd.Type == 'POC' ? oppMap?.get(newOrd.POC_Opportunity__c) : oppMap?.get(newOrd.OpportunityId);
    Account partnerAcc = accountMap?.get(newOrd.Partner_Name__c);
    if (screenPartyList != null) {
      for (GTC_Screening__c gtcRec : screenPartyList) {
        if (String.isBlank(newOrd.ShippingCountryCode) || newOrd.ShippingCountryCode == gtcRec.CountryCode__c) {
          if (!screenedAddress.contains('ShipToAcc')) {
            scanOrder(onHoldReasons, screenedAddress, gtcRec, getWordSet(acc.name), 'ShipToAcc', excludePartyList);
            system.debug(LoggingLevel.DEBUG, 'screenedAddress' + screenedAddress);
          }
          if (!screenedAddress.contains('ShipToName')) {
            if (string.isNotBlank(newOrd.Ship_To_Name__c)) {
              scanOrder(onHoldReasons, screenedAddress, gtcRec, getWordSet(newOrd.Ship_To_Name__c), 'ShipToName', excludePartyList);
            } else {
              onHoldReasons.add('Ship to name is blank');
            }
          }
          if (!screenedAddress.contains('ShipToContact')) {
            if (string.isNotBlank(newOrd.ShipToContactName__c)) {
              scanOrder(onHoldReasons, screenedAddress, gtcRec, getWordSet(newOrd.ShipToContactName__c), 'ShipToContact', excludePartyList);
            } else {
              onHoldReasons.add('Ship to contact name is blank');
            }
          }
          if (!screenedAddress.contains('PrimaryContact')) {
            if (opp != null && opp.Initial_Contacts_Name__c != null) {
              scanOrder(onHoldReasons, screenedAddress, gtcRec, getWordSet(opp.Initial_Contacts_Name__r.name), 'PrimaryContact', excludePartyList);
            } else if (newOrd.Type == 'RMA') {
              screenedAddress.add('PrimaryContact');
            } else {
              onHoldReasons.add('PrimaryContact is blank');
            }
          }
          if (!screenedAddress.contains('PolarisContact')) {
            if (newOrd.Polaris_Contact__c != null && contactMap.containsKey(newOrd.Polaris_Contact__c)) {
              scanOrder(onHoldReasons, screenedAddress, gtcRec, getWordSet(contactMap.get(newOrd.Polaris_Contact__c).name), 'PolarisContact', excludePartyList);
            } else {
              screenedAddress.add('PolarisContact');
            }
          }
        }
        if (!screenedAddress.contains('BillToAcc') && (String.isBlank(acc.BillingCountryCode) || acc.BillingCountryCode == gtcRec.CountryCode__c)) {
          scanOrder(onHoldReasons, screenedAddress, gtcRec, getWordSet(acc.name), 'BillToAcc', excludePartyList);
        }
        if (partnerAcc == null) {
          screenedAddress.add('partnerAcc');
        } else if (!screenedAddress.contains('PartnerAcc') && (String.isBlank(partnerAcc.BillingCountryCode) || partnerAcc.BillingCountryCode == gtcRec.CountryCode__c)) {
          scanOrder(onHoldReasons, screenedAddress, gtcRec, getWordSet(partnerAcc.name), 'PartnerAcc', excludePartyList);
        }
        if (
          screenedAddress.contains('BillToAcc') &&
          screenedAddress.contains('ShipToAcc') &&
          screenedAddress.contains('ShipToContact') &&
          screenedAddress.contains('ShipToName') &&
          screenedAddress.contains('PartnerAcc') &&
          screenedAddress.contains('PolarisContact') &&
          screenedAddress.contains('PrimaryContact')
        ) {
          break;
        }
      }
    }
    system.debug(LoggingLevel.FINE, 'onHoldReasons' + JSON.serialize(onHoldReasons));
    if (!onHoldReasons.isEmpty()) {
      string errorMsg = string.join(onHoldReasons, '\n');
      if (errorMsg.length() > 131072) {
        errorMsg = errorMsg.substring(0, 131072);
      }
      newOrd.ScreenStatus__c = 'On hold';
      newOrd.Screening_Notes__c = errorMsg;
      newOrd.Hold_Code__c = String.isBlank(newOrd.Hold_Code__c)
        ? 'Global Trade Compliance Screening'
        : !newOrd.Hold_Code__c.contains('Global Trade Compliance Screening') ? newOrd.Hold_Code__c + ';Global Trade Compliance Screening' : newOrd.Hold_Code__c;
      newOrd.Order_Status__c = 'On Hold';
    } else {
      newOrd.ScreenStatus__c = 'Approved';
      if (newOrd.Type == 'Revenue' || newOrd.Type == 'RMA') {
        newOrd.Sync_to_NetSuite__c = true;
      }
    }
    newOrd.Internal_Order_Stage__c = 'Order Submitted';
  }
  private void scanOrder(
    List<string> onHoldReasons,
    Set<string> screenedAddress,
    GTC_Screening__c gtcRec,
    Set<String> nameWordSet,
    String screeningType,
    set<string> excludePartyList
  ) {
    string onHoldReason = null;
    for (String wordStr : nameWordSet) {
      wordStr = wordStr.replaceAll('%', '');
      System.debug(
        LoggingLevel.FINE,
        'match word' +
          wordStr +
          ' - ' +
          gtcRec.Party_Name__c +
          '\n excludePartyList::' +
          excludePartyList +
          'screenedAddress' +
          screenedAddress +
          '\n screeningType' +
          screeningType
      );
      if (
        (excludePartyList == null || !excludePartyList.contains(wordStr.toLowerCase())) &&
        String.isNotBlank(gtcRec.Party_Name__c) &&
        gtcRec.Party_Name__c.containsIgnoreCase(wordStr)
      ) {
        onHoldReasons.add(screeningType + ' - ' + wordStr + ' ; Ref: ' + gtcRec.id);
        screenedAddress.add(screeningType);
        system.debug(LoggingLevel.FINE, 'onHoldReason scanOrder' + JSON.serialize(onHoldReasons));
        break;
      }
    }
  }
  /*****************************************************  
    Description : return set of words from a string
 *******************************************************/
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description return set of words from a string
   * @param searchStr
   * @return Set<String>
   */
  public Set<String> getWordSet(String searchStr) {
    Set<String> wordSet = new Set<String>();
    if (String.isNotBlank(searchStr)) {
      searchStr = searchStr.replaceAll(',', ' ');
      searchStr = searchStr.replaceAll('-', ' ');
      searchStr = searchStr.replaceAll('\\s+', ' ');
      List<String> wordList = searchStr.split(' ');
      for (String s : wordList) {
        if (String.isNotBlank(s) && s.length() > 3) {
          wordSet.add('%' + String.escapeSingleQuotes(s) + '%');
        }
      }
      if (wordSet.isEmpty()) {
        wordSet.add('%' + String.escapeSingleQuotes(searchStr) + '%');
      }
    }
    system.debug(LoggingLevel.FINE, 'searchStr' + searchStr + 'wordSet' + wordSet);
    return wordSet;
  }

  /***********************************************************************  
    Description : To update opportunity hold code tracking with ref orderId
    ************************************************************************/
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description To update opportunity hold code tracking with ref orderId
   * @param newOrd
   * @param trackingList
   * @param trackingToUpdate
   */
  public void updateHoldCodeTracking(order newOrd, List<Hold_Off_Tracking__c> trackingList, Map<Id, Hold_Off_Tracking__c> trackingToUpdate) {
    for (Hold_Off_Tracking__c HC : trackingList) {
      HC.Related_Order__c = newOrd.Id;
      trackingToUpdate.put(HC.id, HC);
    }
  }
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description Send Email To Multiple Hold Codes.
   * @param orderIds
   */
  public void sendEmailforMultipleHoldCodes(Set<ID> orderIds) {
    List<Order> OrderswithHoldCodes = new List<Order>();
    String[] ReslOwnEmail = new List<String>();
    Map<String, List<String>> MapOrderIDEmailAddress = new Map<String, List<String>>();
    OrderswithHoldCodes = [SELECT id, Order_Status__c, Hold_Code__c, Resolution_Owner__c, status, Opportunity_Owners_Email__c FROM Order WHERE ID IN :orderIds];
    if (OrderswithHoldCodes.size() > 0) {
      for (Order ord : OrderswithHoldCodes) {
        if (String.isNotBlank(ord.Opportunity_Owners_Email__c)) {
          ReslOwnEmail.add(ord.Opportunity_Owners_Email__c);
        }
        MapOrderIDEmailAddress.put(Ord.Id, ReslOwnEmail);
      }
    }
    String[] toAddresses = new List<String>();
    List<String> ccAddresses = new List<String>();
    List<Messaging.SingleEmailMessage> allEmails = new List<Messaging.SingleEmailMessage>();
    User u = [SELECT Id FROM User WHERE IsActive = TRUE AND Id = :UserInfo.getUserId() LIMIT 1];
    EmailTemplate et = [SELECT id, Name, Subject, Body FROM EmailTemplate WHERE name = 'EMail_MultipleHoldCodes' LIMIT 1];
    Email_Preferences__mdt mdt = [SELECT Id, from__c, cc__c, Email_Subject__c FROM Email_Preferences__mdt WHERE MasterLabel = 'MultipleHoldCodeEmail' LIMIT 1];
    OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :mdt.from__c];
    if (mdt.cc__c != null) {
      for (String address : mdt.cc__c.split(',')) {
        ccAddresses.add(address.trim());
      }
    }
    for (Id od : MapOrderIDEmailAddress.keyset()) {
      if (MapOrderIDEmailAddress.get(od).size() > 0) {
        toAddresses.addall(MapOrderIDEmailAddress.get(od));
      }
      Messaging.SingleEmailMessage emails = new Messaging.SingleEmailMessage();
      emails.setWhatId(od);
      emails.setTargetObjectId(u.id);
      emails.setToAddresses(toAddresses);
      emails.setCcAddresses(ccAddresses);
      emails.setTemplateId(et.Id);
      emails.setSaveAsActivity(false);
      if (owea.size() > 0) {
        emails.setOrgWideEmailAddressId(owea.get(0).Id);
      }
      allEmails.add(emails);
    }
            if(!test.isRunningTest()){
      Messaging.sendEmail(allEmails);
  }
      }

  //sending email for salesops
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description sending email for salesops
   * @param orderIds
   */
  public void sendEmailResOwnerSalesOps(Set<id> orderIds) {
    List<Order> OnHoldOrders = new List<Order>();
    Map<String, String> MapOrderIDoppownerEmail = new Map<String, String>();
    OnHoldOrders = [SELECT id, Order_Status__c, Hold_Code__c, Resolution_Owner__c, status, Opportunity_Owners_Email__c FROM Order WHERE ID IN :orderIds];
    system.debug(LoggingLevel.DEBUG, 'OnHoldOrders' + OnHoldOrders);
    List<String> toAddresses = new List<String>();
    List<String> ccAddresses = new List<String>();
    if (OnHoldOrders.size() > 0) {
      for (Order ord : OnHoldOrders) {
        if (String.isNotBlank(ord.Opportunity_Owners_Email__c)) {
          MapOrderIDoppownerEmail.put(Ord.Id, ord.Opportunity_Owners_Email__c);
        }
      }
    }
    List<Messaging.SingleEmailMessage> allEmails = new List<Messaging.SingleEmailMessage>();
    User u = [SELECT Id FROM User WHERE IsActive = TRUE AND Id = :UserInfo.getUserId() LIMIT 1];
    EmailTemplate et = [SELECT id, Name, developerName, Subject, Body FROM EmailTemplate WHERE developerName = 'resolution_Owner_Sales_Ops' LIMIT 1];
    Email_Preferences__mdt mdt = [SELECT Id, Receipient__c, from__c, cc__c, Email_Subject__c FROM Email_Preferences__mdt WHERE MasterLabel = 'SendEmailSalesOps' LIMIT 1];
    OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :mdt.from__c];
    if (mdt.cc__c != null) {
      for (String address : mdt.cc__c.split(',')) {
        ccAddresses.add(address.trim());
      }
    }
    if (mdt.Receipient__c != null) {
      for (String address : mdt.Receipient__c.split(',')) {
        toAddresses.add(address.trim());
      }
    }
    if (orderIds.size() > 0) {
      for (id ordId : orderIds) {
        if (string.isNotEmpty(MapOrderIDoppownerEmail.get(ordId))) {
          toAddresses.add(MapOrderIDoppownerEmail.get(ordId));
        }
        Messaging.SingleEmailMessage emails = new Messaging.SingleEmailMessage();
        emails.setWhatId(ordId);
        emails.setTargetObjectId(u.id);
        emails.setToAddresses(toAddresses);
        emails.setCcAddresses(ccAddresses);
        emails.setTemplateId(et.Id);
        emails.setSaveAsActivity(false);
        if (owea.size() > 0) {
          emails.setOrgWideEmailAddressId(owea.get(0).Id);
        }
        allEmails.add(emails);
      }
      if (!Test.isRunningTest())
        Messaging.sendEmail(allEmails);
    }
  }

  /*********************************************************
    Description : Send Slack alert for Mosaic SKU fulfilment
    **********************************************************/
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description Send Slack alert for Mosaic SKU fulfilment
   * @param mosaicOrds
   */
  public void sendSlackAlertsForMosaicOrders(Set<order> mosaicOrds) {
    system.debug(LoggingLevel.FINE, 'mosaicOrds' + mosaicOrds);
    List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
    OrgWideEmailAddress emailAddress = [
      SELECT Id
      FROM OrgWideEmailAddress
      WHERE DisplayName = 'Salesforce Support'
    ];
    Id senderEmailId = emailAddress.Id;

    Email_Preferences__mdt mdt = [
      SELECT Id, Receipient__c, cc__c, Email_Subject__c
      FROM Email_Preferences__mdt
      WHERE MasterLabel = 'MOSAIC Order Slack Alert'
      LIMIT 1
    ];

    for (Order ord : mosaicOrds) {
      Account acc = accountMap.get(ord.AccountId);
      if (ord == null)
        continue;
      String orderURL = URL.getSalesforceBaseUrl().toExternalForm() + '/' + ord.Id;

      String emailTextHtmlExt = '';

      emailTextHtmlExt = '<p>Hello Fulfillment Team, </p> <p/> <p>Below Order requires MOSAIC fulfillment.</p>';
      emailTextHtmlExt += '<p>Account Name: ' + acc.Name + '</p>';
      emailTextHtmlExt += '<p>Contact Email: ' + ord.Ship_to_Email__c + '</p>';
      emailTextHtmlExt += '<p>Account Owner: ' + acc.Owner.Name + '</p>';
      emailTextHtmlExt += '<p>Order Number: ' + ord.OrderNumber + '</p>';
      emailTextHtmlExt += '<p>Order Product Details: </p>';

      Integer count = 1;
      for (String productCodeStr : ord.Mosaic_SKUs__c.split(',')) {
        emailTextHtmlExt += '<p>' + count + '. ' + productCodeStr + '</p>';
        count++;
      }

      emailTextHtmlExt += '<p>Mosaic Customer Environment: ' + oppMap.get(ord.OpportunityId).Mosaic_Customer_Environment__c + '</p>';
      emailTextHtmlExt += '<p>Order Link: <a href="' + orderURL + '">' + orderURL + '</a></p>';

      if (String.isNotBlank(emailTextHtmlExt)) {
        Messaging.SingleEmailMessage message = generateEmail(emailTextHtmlExt, senderEmailId, mdt);
        message.Subject += ' ' + ord.OrderNumber;
        emailList.add(message);
      }
    }
    system.debug(LoggingLevel.FINE, 'emailList' + emailList);
    if (!emailList.isEmpty()) {
      if (!Test.isRunningTest())
        Messaging.SendEmailResult[] results = Messaging.sendEmail(emailList);
    }
  }
  /**************************************
    create email
******************************************/
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description Apex class used to send emails based on  Email_Preferences__mdt
   * @param htmlBody
   * @param orgWideEmailAddressId
   * @param mdt
   * @return Messaging.SingleEmailMessage
   */
  private Messaging.SingleEmailMessage generateEmail(String htmlBody, Id orgWideEmailAddressId, Email_Preferences__mdt mdt) {
    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
    List<String> ccAddresses = new List<String>();
    message.toAddresses = new List<String>{ mdt.Receipient__c };
    message.setSubject(mdt.Email_Subject__c);
    message.setHtmlBody(htmlBody);
    message.setOrgWideEmailAddressId(orgWideEmailAddressId);
    if (mdt.cc__c != null) {
      for (String address : mdt.cc__c.split(',')) {
        ccAddresses.add(address.trim());
      }
    }
    if (!ccAddresses.isEmpty()) {
      message.setCcAddresses(ccAddresses);
    }
    return message;
  }
  /***********************************************************************************
 Description : update account for NS Sync ,GoRefresh  
               SF-920, Update Netsuite flag on account when it is marked true on order
************************************************************************************/
  /**
  * @author Prashant Kumar
  * @date 05-03-2025
  * @description update account for NS Sync ,GoRefresh  
               SF-920, Update Netsuite flag on account when it is marked true on order
  * @param newOrd
  * @param process
  * @param accToUpdate
  */
  public void updateAccount(order newOrd, string process, Map<Id, Account> accToUpdate) {
    Account acc = accToUpdate != null && accToUpdate.get(newOrd.AccountId) != null ? accToUpdate.get(newOrd.AccountId) : new Account(id = newOrd.AccountId);
    if (process == 'Update NetSuit Flag') {
      acc.Sync_to_NetSuite__c = true;
    } else if (process == 'Update GoRefresh Flag') {
      acc.Is_Refreshed__c = true;
    } else if (process == 'Update RSC-G Support Flag') {
      acc.RSC_G_Support__c = acc.RSC_G_Support__c == null ? 'RSC-G' : acc.RSC_G_Support__c + ';RSC-G';
      acc.US_Federal_Account__c = true;
    } else if (process == 'Update US citizen field') {
      acc.U_S_citizen_service__c = acc.U_S_citizen_service__c == null ? 'Purchased' : acc.U_S_citizen_service__c + ';Purchased';
    }
    accToUpdate.put(acc.id, acc);
  }

  /**
   * @author Ashish Thakur
   * @description update account for US Citizen product
   * @param newOrd
   * @param accToUpdate
   * @param orderWithUSCitizenProducts
   * @param acc
   */
  public void updateUSCitizenFieldOnAccount(Order newOrd, Map<Id, Account> accToUpdate, Set<Id> orderWithUSCitizenProducts, Account acc) {
    if (orderWithUSCitizenProducts != null && orderWithUSCitizenProducts.contains(newOrd.Id)) {
      Account mapAcc = accToUpdate != null && accToUpdate.get(newOrd.AccountId) != null ? accToUpdate.get(newOrd.AccountId) : new Account(id = newOrd.AccountId);
      mapAcc.U_S_citizen_service__c = acc.U_S_citizen_service__c;
      accToUpdate.put(mapAcc.Id, mapAcc);

      updateAccount(newOrd, 'Update US citizen field', accToUpdate);
    }
  }

  /*
*********************************************************
@Method Name    : copyPreviousOrderDetailsForRCDMTExtension
@author         : Prashant Kumar
@description    : Method is used to Copy the latest Order For a particular Account to the new Renewal Order that is created For RCDM Extension Project
@param          : newOrd
@param          : oldOrder
@Ticket         : PRDOPS25-496
********************************************************
*/
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description Method is used to Copy the latest Order For a particular Account to the new Renewal Order that is created For RCDM Extension Project
   * @param newOrd
   * @param oldOrder
   */
  public static void copyPreviousOrderDetailsForRCDMTExtension(Order newOrd, order oldOrder) {
    newOrd.ShippingStreet = oldOrder.ShippingStreet;
    newOrd.ShippingPostalCode = oldOrder.ShippingPostalCode;
    newOrd.ShipToContactName__c = oldOrder.ShipToContactName__c;
    newOrd.PoDate = oldOrder.PoDate;
    newOrd.PoNumber = oldOrder.PoNumber;
    newOrd.End_User_PO__c = constants.RCDMT_EXT_END_USER_PO;
    newOrd.Payment_Terms__c = oldOrder.Payment_Terms__c;
    newOrd.ShippingCountry = oldOrder.ShippingCountry;
    newOrd.ShippingState = oldOrder.ShippingState;
    newOrd.ShippingCity = oldOrder.ShippingCity;
    newOrd.Ship_to_Email__c = oldOrder.Ship_to_Email__c;
    newOrd.Ship_To_Name__c = oldOrder.Ship_To_Name__c;
  }

  /***************************************
  Description : Order validation
****************************************/
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description Validations on the order
   * @param newOrd
   */
  public void orderValidation(Order newOrd) {
    if (ordIdsWithNonPrimaryQuote.contains(newOrd.id))
      newOrd.addError(NON_PRIMARY_QUOTE_ERROR);
    else if (ordIdsWithQuoteMismatch.contains(newOrd.id))
      newOrd.addError(QUOTE_MISMATCH_ERROR);
  }

  /**************************************************************************
    Description: (SF-6644)InvalidateQuote for conditional PO 
  ****************************************************************************/
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description (SF-6644)InvalidateQuote for conditional PO
   * @param neword
   * @param quoteDocs
   * @param quoteToUpdate
   * @param quoteDocToUpdate
   */
  public void invalidateQuote(Order neword, List<SBQQ__QuoteDocument__c> quoteDocs, Map<Id, SBQQ__Quote__c> quoteToUpdate, Map<Id, SBQQ__QuoteDocument__c> quoteDocToUpdate) {
    if (quoteDocToUpdate == null)
      quoteDocToUpdate = new Map<Id, SBQQ__QuoteDocument__c>();
    for (SBQQ__QuoteDocument__c QD : quoteDocs) {
      if (QD.SBQQ__Quote__r.SBQQ__Ordered__c == false) {
        QD.Invalid__c = true;
        QD.Invalid_Reason__c = 'Missing Conditional PO Verbiage';
        QD.Name = '[INVALID]' + QD.Name;
        quoteDocToUpdate.put(QD.id, QD);
        quoteToUpdate.put(QD.SBQQ__Quote__c, new sbqq__quote__c(id = QD.SBQQ__Quote__c, POC_duration__c = neword.POC_Duration__c, Is_Conditional_PO__c = true));
      }
    }

    system.debug(LoggingLevel.DEBUG, 'quoteToUpdate' + quoteToUpdate);
    system.debug(LoggingLevel.DEBUG, 'quoteDocToUpdate' + quoteDocToUpdate);
  }

  /*
*********************************************************
@Method Name    : getActivePdmFeaturesFromProductsIds
@author         : Prashant Kumar
@description    : Method is used to Query the All PDM Feature Records whose Start Date less than todays date for PDM feature enabled products
@param          : A Set of Product IDs to filter the Product_Feature__c records.
@Ticket         : SF-50997
@return         : List of Product_Feature__c records that match the given product IDs and have a start date on or before today.
********************************************************
*/
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description Method is used to Query the All PDM Feature Records whose Start Date less than todays date for PDM feature enabled products
   * @param productId
   * @param getAllPdmFeature
   * @return List<Product_Feature__c>
   */
  public static List<Product_Feature__c> getActivePdmFeaturesFromProductsIds(Set<Id> productId, Boolean getAllPdmFeature) {
    // Construct the SOQL query to select Product_Feature__c records
    // Filter by Product_Name__c in the given productId Set and ensure Feature_start_date__c is on or before today
    String query = 'SELECT Id, Name, Feature__c, Feature_EOL__c FROM Product_Feature__c  WHERE Product_Name__c IN :productId';
    if (getAllPdmFeature)
      query += ' AND Feature_start_date__c <= TODAY  AND (Feature_EOL__c = NULL OR Feature_EOL__c >= TODAY)';

    // Execute the SOQL query and return the resulting list of Product_Feature__c records
    return Database.query(query);
  }

  /************************************************
  Description : Retrieve the metadata for Disty Mapping
  *************************************************/
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description Retrieve the metadata for Disty Mapping
   * @param recordId
   * @return Sfdc_Disti_Mapping__mdt
   */
  public static Sfdc_Disti_Mapping__mdt getDistributorMetadata(String recordId) {
    //Map<String,Sfdc_Disti_Mapping__mdt> distiMetadataMap = new Map<String,Sfdc_Disti_Mapping__mdt>();
    if (distiMetadataMap == null || distiMetadataMap.isEmpty()) {
      distiMetadataMap = new Map<String, Sfdc_Disti_Mapping__mdt>();
      distiMetadataMapBasedOnLabel = new Map<String, Sfdc_Disti_Mapping__mdt>();
      Map<String, Sfdc_Disti_Mapping__mdt> distiAllValuesMap = Sfdc_Disti_Mapping__mdt.getAll();
      for (String developerName : distiAllValuesMap.keySet()) {
        distiMetadataMap.put(distiAllValuesMap.get(developerName).Sfdc_Id__c, distiAllValuesMap.get(developerName));
        distiMetadataMapBasedOnLabel.put(distiAllValuesMap.get(developerName).PO_Disti_Name__c.toLowercase().deleteWhitespace(), distiAllValuesMap.get(developerName));
      }
    }
    if (recordId != null && recordId != '') {
      if (distiMetadataMap.get(recordId) != null) {
        return distiMetadataMap.get(recordId);
      } else {
        return new Sfdc_Disti_Mapping__mdt();
      }
    } else {
      return null;
    }
  }

  /************************************************  
   Description : update Sobjects in after insert
   *************************************************/
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description update Sobjects in after insert
   * @param NewOrdIDs
   * @param MosaicOrds
   * @param trackingToUpdate
   * @param accToUpdate
   * @param quoteToUpdate
   * @param quoteDocToUpdate
   */
  public void updateAfterInsertRec(
    set<Id> NewOrdIDs,
    set<order> MosaicOrds,
    Map<Id, Hold_Off_Tracking__c> trackingToUpdate,
    Map<Id, Account> accToUpdate,
    Map<Id, SBQQ__Quote__c> quoteToUpdate,
    Map<Id, SBQQ__QuoteDocument__c> quoteDocToUpdate
  ) {
    system.debug(LoggingLevel.DEBUG, 'trackingToUpdate' + JSON.serialize(trackingToUpdate));
    system.debug(LoggingLevel.DEBUG, 'accToUpdate' + JSON.serialize(accToUpdate));
    system.debug(LoggingLevel.DEBUG, 'quoteToUpdate' + JSON.serialize(quoteToUpdate));
    system.debug(LoggingLevel.DEBUG, 'quoteDocToUpdate' + JSON.serialize(quoteDocToUpdate));

    Map<Id, ShipmentDetail__c> overviewSDToCreate = new Map<Id, ShipmentDetail__c>();
    for (Order newOrd : (List<Order>) Trigger.new) {
      SBQQ__Quote__c quote = quoteMap?.get(newOrd.SBQQ__Quote__c);
      if (quote != null && quote.ProcessType__c == 'Aspen' && quote.ShipmentDetails__r.isEmpty() && !overviewSDToCreate.containsKey(quote.Id)) {
        overviewSDToCreate.put(quote.Id, new ShipmentDetail__c(Quote__c = quote.Id, RecordTypeId = Constants.overViewRecordTypeId));
      }
    }
    if (trackingToUpdate != null && !trackingToUpdate.isEmpty()) {
      database.update(trackingToUpdate.values(), false);
    }
    if (accToUpdate != null && !accToUpdate.isEmpty()) {
      database.update(accToUpdate.values(), false);
    }
    if (quoteToUpdate != null && !quoteToUpdate.isEmpty()) {
      database.update(quoteToUpdate.values(), false);
    }

    if (quoteDocToUpdate != null && !quoteDocToUpdate.isEmpty()) {
      database.update(quoteDocToUpdate.values(), false);
    }
    if (MosaicOrds != null && !MosaicOrds.isEmpty()) {
      SendSlackAlertsForMosaicOrders(MosaicOrds);
    }
    if (NewOrdIDs != null && !NewOrdIDs.isEmpty()) {
      SendEmailforMultipleHoldCodes(NewOrdIDs);
    }
    if (overviewSDToCreate != null && !overviewSDToCreate.isEmpty()) {
      database.insert(overviewSDToCreate.values(), false);
    }
  }
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description order validation for RCDM-T Before Submission
   * @param newOrd
   */
  public void submitOrderValidationForRCDMT(Order newOrd) {
    String RCDMTError = '';
    Boolean eligbleForRCDM = false;
    Map<String, OrderItem> eligibleOIForRCDM = new Map<String, OrderItem>();
    // Map<String,OrderItem> eligibleOrderItemsForRCDM = new Map<String,OrderItem>();
    String rcdmSupportStartDate = Order_control__mdt.getInstance('RCDM_T_Start_Date').Value__c;
    Map<String, List<OrderItem>> parentOIVsListOfOrderItems = new Map<String, List<OrderItem>>();
    SBQQ__Quote__c quote = quoteMap?.get(newOrd.SBQQ__Quote__c);
    String previousCliItems, previousCli;
    List<String> previousCliList = new List<String>();
    if (
      newOrd.Type == 'Revenue' &&
      accountMap != null &&
      !accountMap.isEmpty() &&
      accountMap.get(newOrd.AccountId) != null &&
      accountMap.get(newOrd.AccountId).Eligible_for_RCDM_T__c &&
      (quote?.RWD_Deal_Ops_Exception__c == null || !quote?.RWD_Deal_Ops_Exception__c.contains('Allow removal of 0$ On Prem SKU'))
    ) {
      eligbleForRCDM = true;
    }
    if (orderIdOrderItemMap.containsKey(newOrd.Id)) {
      for (OrderItem oi : orderIdOrderItemMap.get(newOrd.Id)) {
        previousCliItems = oi.Previous_Contract_Line_Items__c;
        previousCli = '';
        if (String.isNotBlank(previousCliItems)) {
          previousCliList = previousCliItems.trim().split(',');
          previousCli = previousCliList[0];
          previousCli = previousCli.trim().substring(0, 15);
        }
        if (
          oi.Product2.Eligible_for_RCDM_T__c &&
          ((String.isBlank(newOrd.Order_Sub_Type__c) && oi.Program__c != 'Conversion') ||
          (oi.Support_Start_Date__c < Date.valueof(rcdmSupportStartDate) &&
          (String.isNotBlank(previousCli) &&
          idToOldCLIMap.containsKey(previousCli) &&
          idToOldCLIMap.get(previousCli)?.SBQQSC__Product__r?.Product_Level__c == null))) &&
          eligbleForRCDM
        ) {
          eligibleOIForRCDM.put(oi.Id, oi);
        }
        /* if(oi.Product2.Eligible_for_RCDM_T__c && (String.isBlank(newOrd.Order_Sub_Type__c) 
            || (oi.Support_Start_Date__c < Date.valueof(rcdmSupportStartDate) && 
            (String.isNotBlank(previousCli) && idToOldCLIMap.containsKey(previousCli) && idToOldCLIMap.get(previousCli)?.SBQQSC__Product__r?.Product_Level__c == null))) && eligbleForRCDM) {
              eligibleOrderItemsForRCDM.put(oi.Id,oi);
        } */
        if (rcdmMdt.containsKey(oi.Product2.ProductCode) && newOrd.type == 'Revenue') {
          if (oi.SBQQ__RequiredBy__c != null) {
            if (!parentOIVsListOfOrderItems.containsKey(oi.SBQQ__RequiredBy__c)) {
              parentOIVsListOfOrderItems.put(oi.SBQQ__RequiredBy__c, new List<OrderItem>{ oi });
            } else {
              parentOIVsListOfOrderItems.get(oi.SBQQ__RequiredBy__c).add(oi);
            }
          }
        }
      }
    }
    for (String eligibleOI : eligibleOIForRCDM.keySet()) {
      if (parentOIVsListOfOrderItems.containsKey(eligibleOI)) {
        for (OrderItem rcdmItem : parentOIVsListOfOrderItems.get(eligibleOI)) {
          if (
            rcdmItem.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c == null || (eligibleOIForRCDM.get(eligibleOI).SBQQ__QuoteLine__c != rcdmItem.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c)
          ) {
            newOrd.OM_internal_review__c = true;
            newOrd.Order_Status__c = 'On Hold';
            newOrd.Hold_Code__c = 'OM Internal Review';
            RCDMTError = 'Missing RCDM-T on QLI related to lineitem : ' + eligibleOI;
            break;
          }
        }
      } else {
        newOrd.OM_internal_review__c = true;
        newOrd.Order_Status__c = 'On Hold';
        newOrd.Hold_Code__c = 'OM Internal Review';
        RCDMTError = 'Missing RCDM-T on lineitem : ' + eligibleOI;
      }
    }
    /* for(String rcdmtOI : parentOIVsListOfOrderItems.keySet()) {
       if(!eligibleOrderItemsForRCDM.containsKey(rcdmtOI)) {
          newOrd.OM_internal_review__c = true;
          newOrd.Order_Status__c = 'On Hold';
          newOrd.Hold_Code__c = 'OM Internal Review';
          RCDMTError = 'Extra RCDM-T found in the order : '+parentOIVsListOfOrderItems.get(rcdmtOI)[0].ID;
       }
    } */
    if (RCDMTError != '' && newOrd.Change_Needed_Reason_Other__c != null && !newOrd.Change_Needed_Reason_Other__c.contains(RCDMTError)) {
      newOrd.Change_Needed_Reason_Other__c += ', ' + RCDMTError;
    } else if (newOrd.Change_Needed_Reason_Other__c == null && RCDMTError != '') {
      newOrd.Change_Needed_Reason_Other__c = RCDMTError;
    }
  }
  //Validate Order on the basis of criteria
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description Validate Order on the basis of criteria
   * @param orderList
   */
  public void validateOrder(List<Order> orderList) {
    String criteria = Order_control__mdt.getInstance('Welcome_Letter_Configuration').Values__c;
    List<String> quoteNameList = new List<String>();
    Map<String, String> criteriaMap = (Map<String, String>) JSON.deserialize(criteria, Map<String, String>.class);
    String quotenames, startDate, endDate;
    if (!criteriaMap.keySet().isEmpty()) {
      if (criteriaMap.containskey('SBQQ__Quote__c') && String.isNotBlank(criteriaMap.get('SBQQ__Quote__c'))) {
        quotenames = (String) criteriaMap.get('SBQQ__Quote__c');
        quoteNameList = quotenames.split(',');
      }
      if (
        criteriaMap.containskey('StartDate') &&
        String.isNotBlank(criteriaMap.get('StartDate')) &&
        criteriaMap.containskey('EndDate') &&
        String.isNotBlank(criteriaMap.get('EndDate'))
      ) {
        startDate = (String) criteriaMap.get('StartDate');
        endDate = (String) criteriaMap.get('EndDate');
      }
    }
    if (!orderList.isEmpty()) {
      for (Order odr : orderList) {
        if (
          (String.isNotBlank(startDate) && String.isNotBlank(endDate) && Date.today() <= Date.valueOf(endDate) && Date.today() >= Date.valueOf(startDate)) ||
          ((!quoteNameList.isEmpty() &&
          odr.SBQQ__Quote__c != null &&
          quoteNameList.contains(quoteMap.get(odr.SBQQ__Quote__c).Name)))
        ) {
          odr.Welcome_Letter_Status__c = 'Hold';
        }
      }
    }
  }
  /**
   * @author Prashant Kumar
   * @date 20-06-2025
   * @description check if Eligible for SC Creation.
   * @param inputDate
   * @return Boolean
   */
  public static integer isFutureQuarter(Date inputDate) {
    Integer year = inputDate.year();
    Integer month = inputDate.month();
    Integer quarter;
    if (month >= 2 && month <= 4) {
      quarter = 1;
    } else if (month >= 5 && month <= 7) {
      quarter = 2;
    } else if (month >= 8 && month <= 10) {
      quarter = 3;
    } else {
      // month == 11 || 12 || 1
      quarter = 4;
      if (month == 1) {
        year -= 1; // January belongs to previous fiscal year
      }
    }
    return year * 10 + quarter; // e.g., 20254 for Q4 of FY2025
  }
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description check if Eligible for SC Creation.
   * @param ordsToValidate
   * @param newOrdersMap
   * @param helper
   */
  public static void validateOrdisEligibleSCGen(List<Order> ordsToValidate, Map<Id, Order> newOrdersMap, OrderInsertHelper helper) {
    for (Order ord : ordsToValidate) {
      Boolean hasRelatedEntsorCLIorSC = false;
      if (helper.orderIdOrderItemMap.containskey(ord.id)) {
        for (orderitem oi : helper.orderIdOrderItemMap.get(ord.id)) {
          if (oi.Entitlements__r?.size() > 0) {
            for (Entitlement ent : oi.Entitlements__r) {
              if (ent.Type == 'Phone Support') {
                hasRelatedEntsorCLIorSC = true;
              }
            }
          }
          if (oi.SBQQSC__ContractLineItems__r?.size() > 0) {
            hasRelatedEntsorCLIorSC = true;
          }
        }
      }
      if (!hasRelatedEntsorCLIorSC && helper.oppMap.containskey(ord.opportunityid)) {
        Opportunity opp = helper.oppMap.get(ord.opportunityid);
        if (opp.SBQQSC__ServiceContracts__r.size() > 0) {
          for (ServiceContract SC : opp.SBQQSC__ServiceContracts__r) {
            if (SC.SBQQSC__Order__c == ord.id) {
              hasRelatedEntsorCLIorSC = true;
            }
          }
        }
      }
      if (hasRelatedEntsorCLIorSC && !Test.isRunningTest()) {
        newOrdersMap.get(ord.id).addError('Order is already Linked with the ServiceContract/Entitlement/ContractLineItem.');
      } else {
        ord.SBQQ__Contracted__c = false;
      }
    }
  }

  /**
   * @author Prashant Kumar
   * @date 22-06-2025
   * @description Return Correct Hold Code based on CRSD Date.
   * @param newOrder
   * @param orderItemMap
   * @param isFutureQuarter
   * @return String
   */

  public static String evaluateCRSDHoldReason(Order newOrder, Map<Id, List<OrderItem>> orderItemMap, Boolean isFutureQuarter) {
    // Check core conditions before evaluating

    // Check if this is a Renewal order with Order Items
    if (!orderItemMap.get(newOrder.Id).isEmpty() && orderItemMap.containsKey(newOrder.Id)) {
      // Get the earliest Support Start Date
      Date earliestSupportStartDate = orderItemMap.get(newOrder.Id)[0].Support_Start_Date__c;

      // Compare CRSD with start date
      if (
        constants.ORDER_SUB_TYPES_RENEWAL.contains(newOrder.Order_Sub_Type__c) &&
        earliestSupportStartDate != null &&
        newOrder.Customer_Required_Ship_Date__c > earliestSupportStartDate
      ) {
        return constants.ORDER_CRSD_HOLD_CODE_RENEWAL; // CRSD after renewal start date
      } else if (isFutureQuarter) {
        return constants.ORDER_CRSD_HOLD_CODE; // CRSD is in future quarter
      }
    }

    // No hold reason needed
    return null;
  }

  /**
   * @description : This method is a after Update Helper for  Order. - PRDOPS26-701
   * @param newOrdList
   * @param oldMap
   */
  public void processAfterUpdate(List<Order> newOrdList,Map<Id,Order> oldMap){
    List<Id> ordRSCProvisionList = new List<Id>();
    List<String> rscSyncStatus = new List<String>{'Provisioning Requested','Resync Dates Requested'};
    for (Order newOrd : newOrdList) {
      Order oldOrd = oldMap?.get(newOrd.id);
      if(oldOrd.Polaris_Fulfillment_Status__c != newOrd.Polaris_Fulfillment_Status__c  
         && rscSyncStatus.contains(newOrd.Polaris_Fulfillment_Status__c)
         && newOrd.Send_for_Polaris_Fulfilment__c == true)
        {
          ordRSCProvisionList.add(newOrd.Id);
        }
    }
    if(!ordRSCProvisionList.isEmpty() && String.isNotBlank(checkRSCPostCall.Value__c) && Boolean.valueOf(checkRSCPostCall.Value__c) && !Test.isRunningTest()){
        system.enqueueJob(new PolarisFulfilmentQueueable(ordRSCProvisionList,new Set<Id>(),null));
    }
  }
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description firing event when Sync to NS is true.
   * @param syncToNsEvents
   */
  public static void firingEventWhenSyncToNSIsTrue(List<Sync_To_NS_On_Order_Event__e> syncToNsEvents) {
    Database.SaveResult[] results = EventBus.publish(syncToNsEvents);
    for (Integer i = 0; i < results.size(); i++) {
      // Check if the result was successful
      String message = 'Success';
      if (!results[i].isSuccess()) {
        Database.Error error = results.get(i).getErrors().get(0);
        String failedDML = error.getMessage();
        message = failedDML + syncToNsEvents[i].OrderId__c;
      }
      errorLogMethod(syncToNsEvents[i], message);
    }
    syncToNsEvents.clear();
  }

  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description generate Error Log.
   * @param event
   * @param message
   */
  public static void errorLogMethod(Sync_To_NS_On_Order_Event__e event, String message) {
    Error_Logs__c Log = new Error_Logs__c(
      Order_ID__c = event.OrderId__c,
      Account__c = event.AccountId__c,
      Class__c = 'Orderhandler',
      Type__c = 'SFDC',
      Method__c = 'afterUpdate',
      Object__c = 'Sync_To_NS_On_Order_Event__e',
      Error_Message__c = message
    );
    Orderhandler.lstErrorLogs.add(Log);
  }  
}