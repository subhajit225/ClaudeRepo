/*****************************************************************************
* @description       : Order trigger handler
Holds logic for disabling the trigger execution
Max recursion
* @author            : Chaitra
* @last modified on  : 01-20-2021
* @last modified by  : Chaitra
* Modifications Log
* Ver   Date          Author        Modification
* 1.0   01-20-2021   Chaitra        Initial Version
* 2.0   09-04-2021   Nitin          PRDOPS22-17
* 2.1   06-14-2022   moises         PRDOPS23-433 Adding order id to error logs
* 2.2   06-02-2022   Moises         PRDOPS23-372
* 2.3   03-16-2023   Saakshi        CS21-1517 QA & UAT: Welcome letter has not triggered for all the orders in a set
******************************************************************************/

public class OrderHandler extends TriggerHandler {  
    private Boolean isHoldOffLogicDisabled = false;
    private static OrderHandler instance = null;
    public OrderInsertHelper helper;
    public Map<string, Asset> serialNumAsset;
    public OrderUpdateHelper updateHelper;
    public Boolean isAssetQueryExecuted = false;
    private Integer BkgCuttoffcount;
  public static boolean bypassShippedOrderValidation = false;
    public static List<Sync_To_NS_On_Order_Event__e > syncToNsEvents = new List<Sync_To_NS_On_Order_Event__e>();
    public static set<Id> orderIdsToFireEventOnce = new Set<Id>();

    //SFDCSOX-341
    public static boolean IsInsertTransaction = false;
    public static boolean isPermissionToFieldUpdate = false;
  public static Map<Id, PO_Stage__c> StagePoMap = new Map<Id, PO_Stage__c>();
    public static boolean isDisabledOrderTracking = false; 
    public Map<Id, Map<string, Hold_Off_Tracking__c>> oppIdHCtracker = new Map<Id, Map<string, Hold_Off_Tracking__c>>();
    public set<string> beforeUpdateHistory = new Set<string>();
    public set<string> afterUpdateHistory = new Set<string>();
    public ShGl_DisableBusinessLogic__c disableBusinessLog = ShGl_DisableBusinessLogic__c.getInstance();
    public static Map<String,ContractManufacturerAllocation__c> cmaForAllQuarter = new Map<String,ContractManufacturerAllocation__c>();
    public static Map<String,ContractManufacturerAllocation__c> cmaToUpsertNew = new Map<String,ContractManufacturerAllocation__c>();
    public static Map<ID, string> opptyHistoryMap = new Map<ID, string>();
    public static Map<String,CMAllocation_For_Non_Aspen_Products__mdt> allocationMapByProdName;
    public static boolean autoSubmit =false;
    public static Map<Id,Decimal> amountOfOrdersOnStage = new Map<Id,Decimal>();
    public static  Boolean enablePushBasedOrderSync = Boolean.valueOf(Order_control__mdt.getInstance('Enable_push_based_order_sync').Value__c);  

    private static Map<Id,Map<string,Decimal>> quoteSDProdQuant = new Map<Id,Map<string,Decimal>>();
    public static List<Error_Logs__c> lstErrorLogs = new List<Error_Logs__c>(); //PRDOPS25-461
    
    private OrderHandler() {
        ShGl_DisableFunctionalityLogic__c disabledFunctionality = ShGl_DisableFunctionalityLogic__c.getInstance();
        isHoldOffLogicDisabled = disabledFunctionality.DisableHoldOffLogic__c;
        helper = OrderInsertHelper.getInstance();
    }

      /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description Getting Instance of OrderHandler
   * @return Orderhandler
   */
    public static OrderHandler getInstance() {
        if (instance == null)
            instance = new OrderHandler();
        return instance;
    }

  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description Calling before Insert For OrderTrigger
   */
    public override void beforeInsert() {
        helper.ORIGIN_CONTEXT = 'Insert';
        helper.orderInit();
        autoSubmit = true;
        //SFDCSOX-341
        IsInsertTransaction = true;
        isDisabledOrderTracking = true;
        Map<id, List<PO_Stage__c>> quoteIdStagePOs = new Map<id, List<PO_Stage__c>>();
        
        set<Id> conditionalPOReqOpp = new Set<Id>();
        if (!helper.quoteMap.isEmpty()) {
            if (TransactionalDataCollection.stagePo.isEmpty()) {
        TransactionalDataCollection.stagePo = [
          SELECT
            id,
            EDI_DISTI_ID__c,
            partner_name__c,
            PoDate__c,
            PoNumber__c,
            ShippingCity__c,
            ShippingCountry__c,
            ShippingCountryCode__c,
            ShippingPostalCode__c,
            ShippingState__c,
            ShippingStateCode__c,
            ShippingStreet__c,
            Shipping_Method__c,
            Ship_To_Contact_Name__c,
            Shipping_Carrier__c,
            Shipping_Account_Number__c,
            End_User_PO__c,
            Service_Level__c,
            Ship_to_Email__c,
            Ship_To_Phone_Number__c,
            Payment_Terms__c,
            Quote__c,
            Expected_number_of_POs__c,
            Bill_To_Name__c,
            TotalAmount__c,
            Ship_to_Account_Name__c,
            Customer_Requested_Ship_Date__c,
            Note_on_Contingency_and_Special_Language__c,
            (SELECT id, Quote_Line__c, Type__c, Stage_PO__c, Quantity__c, UnitPrice__c, Product__r.Product_Payment_Option__c, Total_Price__c  FROM PO_Item_Stage__r 
    where ProductCode__c NOT IN :Constants.DUMMY_PRODUCTS)
                    FROM PO_Stage__c
          WHERE
            Quote__c IN :helper.quoteMap.keySet()
            AND (PO_Validation_Status__c = 'Success'
            OR PO_Validation_Status__c = 'Success - 855 Sent'
            OR PO_Validation_Status__c = 'Order Accepted'
            OR PO_Validation_Status__c = 'Order Accepted - 855 Sent'
            )
                    AND PO_Internal_Validation_Status__c = 'Success'
                ];

            }
            for (PO_Stage__c stgPO : TransactionalDataCollection.stagePo) {
        StagePoMap.put(stgPO.Id, stgPO);
                if (quoteIdStagePOs.containsKey(stgPO.Quote__c)) {
                    quoteIdStagePOs.get(stgPO.Quote__c).add(stgPO);
                } else {
                    quoteIdStagePOs.put(stgPO.Quote__c, new List<PO_Stage__c>{ stgPO });
                }
            }
        }
        // PRDOPS22-17
        for(POC__c objPoc : helper.pocRequestById.values()){
          if(objPoc.POC_Type__c == 'Conditional PO'){
             conditionalPOReqOpp.add(objPoc.Opportunity__c);
        }
        }

        for (Order newOrd : (List<Order>) Trigger.new) {
            system.debug(LoggingLevel.DEBUG,'quoteIdStagePOs :: ' + Json.serializePretty(quoteIdStagePOs));
            system.debug(LoggingLevel.DEBUG,'newOrd ::' + Json.serializePretty(newOrd));
            boolean isConditionalPO = conditionalPOReqOpp.contains(newOrd.OpportunityId) ? true : false;
            if (quoteIdStagePOs.containsKey(newOrd.SBQQ__Quote__c) && !quoteIdStagePOs.get(newOrd.SBQQ__Quote__c).isEmpty()) {
                helper.populateFieldsOnInsert(newOrd, quoteIdStagePOs.get(newOrd.SBQQ__Quote__c), isHoldOffLogicDisabled,isConditionalPO);
            } else {
                helper.populateFieldsOnInsert(newOrd, null, isHoldOffLogicDisabled,isConditionalPO);
            }
        }
    helper.validateOrder(Trigger.new);
    }
    
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description Calling after Insert For OrderTrigger
   */
    public override void afterInsert() {
        set<order> MosaicOrds = new Set<order>();
        set<ID> NewOrdIDs= new Set<ID>();
        Map<Id, List<SBQQ__QuoteDocument__c>> pocOppIdQuoteDocs = new Map<Id, List<SBQQ__QuoteDocument__c>>();
        Map<Id, Hold_Off_Tracking__c> trackingToUpdate = new Map<Id, Hold_Off_Tracking__c>();
        Map<Id, Account> accToUpdate = new Map<Id, Account>();
        Map<Id, SBQQ__Quote__c> quoteToUpdate = new Map<Id, SBQQ__Quote__c>();
        Map<Id, SBQQ__QuoteDocument__c> quoteDocToUpdate = new Map<Id, SBQQ__QuoteDocument__c>();
        Set<Id> quoteIds = new Set<Id>();
        Map<Id, Id> mapOfOrdToQutDoc = new Map<Id, Id>();
        Set<Id> setOfAttIds = new Set<Id>();
        List<SBQQ__QuoteDocument__c> lstOfQutDoc = new List<SBQQ__QuoteDocument__c>();
        for (Hold_Off_Tracking__c HC : [
            SELECT
            id,
            Hold_Code__c,
            Release_Date_Time__c,
            Related_Opportunity__c,
            Related_Order__c
            FROM Hold_Off_Tracking__c
            WHERE
            Is_Released__c = FALSE
            AND Related_Opportunity__c IN :helper.oppMap.keyset()
        ]) {
            if (oppIdHCtracker.containsKey(HC.Related_Opportunity__c)) {
                oppIdHCtracker.get(HC.Related_Opportunity__c).put(HC.Hold_Code__c, HC);
            } else {
                oppIdHCtracker.put(HC.Related_Opportunity__c, new Map<string, Hold_Off_Tracking__c>{ HC.Hold_Code__c => HC });
            }
        }
        for(Order ord : (List<Order>) Trigger.new){
            if(Constants.ORDER_SUB_TYPES_SCALE_UTILITY.contains(ord.Order_Sub_Type__c)){
                quoteIds.add(ord.SBQQ__Quote__c);
            }
        }
        if (!helper.pocOppIds?.isEmpty() || !quoteIds?.isEmpty()) {
      lstOfQutDoc = [
        SELECT
                Id,
                SBQQ__Quote__c,
                Name,
                SBQQ__Quote__r.SBQQ__Opportunity2__c,
                SBQQ__Quote__r.SBQQ__Ordered__c,
                Invalid_Reason__c,
                SBQQ__ViewRecordId__c,
                Invalid__c,
                SBQQ__Version__c
                FROM SBQQ__QuoteDocument__c
        WHERE SBQQ__Quote__r.SBQQ__Opportunity2__c IN :helper.pocOppIds OR SBQQ__Quote__c IN :quoteIds
        ORDER BY SBQQ__Version__c DESC
      ];
        }

        for(SBQQ__QuoteDocument__c qutDoc : lstOfQutDoc){
            if(helper.pocOppIds?.contains(qutDoc.SBQQ__Quote__r.SBQQ__Opportunity2__c)){
                if (
                    pocOppIdQuoteDocs.get(qutDoc.SBQQ__Quote__r.SBQQ__Opportunity2__c) == null
                ) {
                    pocOppIdQuoteDocs.put(qutDoc.SBQQ__Quote__r.SBQQ__Opportunity2__c,new List<SBQQ__QuoteDocument__c>{ qutDoc });
                } else {
                    pocOppIdQuoteDocs.get(qutDoc.SBQQ__Quote__r.SBQQ__Opportunity2__c).add(qutDoc);
                }
            }
            if(quoteIds.contains(qutDoc.SBQQ__Quote__c)){
                setOfAttIds.add(qutDoc.SBQQ__ViewRecordId__c);
                for(Order newOrd : (List<Order>) Trigger.new){
                    if(mapOfOrdToQutDoc.containsKey(newOrd.id)){
                        continue;
                    }
                    else if(Constants.ORDER_SUB_TYPES_SCALE_UTILITY.contains(newOrd.Order_Sub_Type__c)){
                        mapOfOrdToQutDoc.put(newOrd.id, qutDoc.SBQQ__ViewRecordId__c);
                    }
                }
            }
        }

        for (Order newOrd : (List<Order>) Trigger.new) {
            system.debug(logginglevel.INFO,'AFter Insert newOrd' + JSON.serializePretty(newOrd));
            Opportunity opp = helper.oppMap?.get(newOrd.OpportunityId);
            Account acc = helper.accountMap?.get(newOrd.accountId);
            SBQQ__Quote__c quote = helper.quoteMap?.get(newOrd.SBQQ__Quote__c);
            if( disableBusinessLog.Disable_Order_Email_Alerts__c == false &&
               newOrd.OpportunityId != null &&
               String.isNotBlank(newOrd.Mosaic_SKUs__c) &&
               opp.Mosaic_Customer_Environment__c == 'AWS') {
                  MosaicOrds.add(newOrd);
              }
              if(newOrd.Order_Status__c =='On Hold' && String.isNotBlank(newOrd.Hold_Code__c) && newOrd.Hold_Code__c.contains(';')){
                NewOrdIDs.add(newOrd.ID);
               }
            system.debug(logginglevel.DEBUG, 'pocOppIdQuoteDocs' + pocOppIdQuoteDocs);
            system.debug(logginglevel.DEBUG, 'oppIdHCtracker' + oppIdHCtracker);

            // SF-656
            if (!isHoldOffLogicDisabled && oppIdHCtracker.get(newOrd.OpportunityId) != null) {
                helper.updateHoldCodeTracking(newOrd, oppIdHCtracker.get(newOrd.OpportunityId).values(),trackingToUpdate);
            }
            if( newOrd.Sync_to_NetSuite__c && acc != null && acc.Sync_to_NetSuite__c == false && !enablePushBasedOrderSync) {
                helper.updateAccount(newOrd, 'Update NetSuit Flag', accToUpdate);
            }
            if( newOrd.RSC_G_Enabled__c && acc != null && acc.RSC_G_Eligible__c && (acc.RSC_G_Support__c == null ? True : !acc.RSC_G_Support__c.split(';').contains('RSC-G'))) {
                Account mapAcc = accToUpdate != null && accToUpdate.get(newOrd.AccountId) != null ? accToUpdate.get(newOrd.AccountId): new Account(id = newOrd.AccountId);
                mapAcc.RSC_G_Support__c = acc.RSC_G_Support__c;
                accToUpdate.put(mapAcc.Id,mapAcc);
                helper.updateAccount(newOrd, 'Update RSC-G Support Flag', accToUpdate);
            }
            if(newOrd.POC_Request__c != null && newOrd.POC_Type__c == 'Conditional PO' &&
               newOrd.POC_Opportunity__c != null && pocOppIdQuoteDocs.get(newOrd.POC_Opportunity__c) != null &&
               newOrd.POC_Opportunity__r.IsClosed == false) {
                   helper.invalidateQuote(
                       newOrd,
                       pocOppIdQuoteDocs.get(newOrd.POC_Opportunity__c),
                       quoteToUpdate,
                       quoteDocToUpdate
                   );
               }
        }
        helper.updateAfterInsertRec(
            NewOrdIDs,
            MosaicOrds,
            trackingToUpdate,
            accToUpdate,
            quoteToUpdate,
            quoteDocToUpdate
        );
        if(!mapOfOrdToQutDoc.isEmpty()){
             UtilityClass.createAttachment(mapOfOrdToQutDoc, setOfAttIds);
        }
    }

  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description Calling before Update For OrderTrigger
   */
    public override void beforeUpdate() {
        System.debug(LoggingLevel.INFO,'before update history :: ' + beforeUpdateHistory);
        BookingHelper.bypassBookingValidationRule = true;
        updateHelper = OrderUpdateHelper.getInstance();
        List<OrderItem> newOIList = new List<OrderItem>();
        Map<Id, List<PS_Project__c>> accIdPSProjects = new Map<Id, List<PS_Project__c>>();
        //MKT22-378 PS name   End//
        Set<Id> orderAccepteddOppIds = new Set<Id>();
        set<Id> orderAcceptedAccIds = new Set<Id>(); 
        set<id> trainingOrderItemIds = new Set<Id>();
        set<Id> primaryOppIds = new Set<Id>();
        set<Id> contactIds = new Set<id>();
        set<string> screenWords = new Set<string>();
        set<string> shipBillCC = new Set<string>(); // shipping ,billing count code
        set<string> excludePartyList;
        List<GTC_Screening__c> screenPartyList;
        set<PS_Project__c> PSProjToInsert = new Set<PS_Project__c>();
        Map<Id, OpportunityContactRole> oppId_OCRMap = new Map<Id, OpportunityContactRole>();
        Id PSExternalRecId = Schema.SObjectType.PS_Project__c.getRecordTypeInfosByName().get('External').getRecordTypeId();
        set<string> beforeUpdateHistoryLocal = new Set<string>();
        Set<id> SDOrdIds = new set<id>();
        Map<Id,Order> orderMap = new Map<Id,Order>();
        List<Date> createdOrderDate = new List<Date>();
        //Welcome Letter - attributes - Polaris & ASPEN - CS21-778,CS21-748
        Set<String> fullfilmentNameSet = new Set<String>();
        Map<String,Set<String>> fulfillmentSetOrderIdMap = new Map<String,Set<String>>();
        Map<String,Set<String>> softwareWelcomeLetterOrderIdMap = new Map<String,Set<String>>();
        Map<String,Set<String>> welcomeLetterSentOrderIdMap = new Map<String,Set<String>>();
        //Welcome Letter - attributes - Polaris & ASPEN - End

        Map<Id, Integer> oppToPSProjectCount = new Map<Id, Integer>();
        Map<id,Map<string,string>> quoteIdPCSNs = new Map<id,Map<string,string>>();
        Order_control__mdt manualOrdSum = Order_control__mdt.getInstance('Manual_order_submission');
        String rcdmtValidation = Order_control__mdt.getInstance('RCDM_T_Validation').Value__c;
        List<String> disableRCDM_ValidationForUsers = new List<String>(); 
        List<Order> ordToValidateSCGen = new List<Order>();
        if(String.isNotBlank(Order_control__mdt.getInstance('Disable_RCDM_T_Validation_For_User').Value__c)) {
            disableRCDM_ValidationForUsers = Order_control__mdt.getInstance('Disable_RCDM_T_Validation_For_User').Value__c.split(',');
        }
        /**************************************
         *  Data Collection for querying records  //MKT23-355 JIRA
        ****************************************/
        helper.orderInit();
        RPS__c screenSetting = RPS__c.getInstance(UserInfo.getUserId());
        //SFDCSOX-341
    User currentUser = [SELECT Id, User_Type__c, RBAC_Group__c, Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    Boolean hasPOCOrderEditCustomPermission = FeatureManagement.checkPermission('Order_POC_Edit_Access');
    Boolean hasRMAOrderEditCustomPermission = FeatureManagement.checkPermission('Order_RMA_Edit_Access');
    Boolean hasRevenueOrderEditCustomPermission = FeatureManagement.checkPermission('Order_Revenue_Edit_Access');
    Boolean orderAccessPSForShippedOrder = FeatureManagement.checkPermission('CanEditFulfilledOrder');
    Boolean isUserGroupValid =
      currentUser.RBAC_Group__c == null ||
                                (!currentUser.RBAC_Group__c.contains('IT Prod Ops Support') &&
                                !currentUser.RBAC_Group__c.contains('API') &&
                                !currentUser.RBAC_Group__c.contains('System - IT'));
    Boolean isUserGroupOM = 
      currentUser.RBAC_Group__c != null && 
      (currentUser.RBAC_Group__c.contains('Order - Management') || 
      currentUser.RBAC_Group__c.contains('Order - Team'));
        Boolean isUserTypeValid = currentUser.User_Type__c != 'API' && currentUser.User_Type__c != 'System';
        Boolean isSystemStateValid = !System.isFuture() && !System.isBatch() && !System.isScheduled();
        Boolean isOrderEditValidationDisabled = !Boolean.valueOf(Order_control__mdt.getInstance('Disable_Order_Edit_Validation').Value__c);
        Order_control__mdt crsdGracePeriod = Order_control__mdt.getInstance('CRSD_Grace_Period'),
        crsdOrderErrorMessage = Order_control__mdt.getInstance('CRSD_Order_Error_Message');

        
        for (Order newOrd : (List<order>) Trigger.new) {
            Order oldOrd = (Order) Trigger.oldMap.get(newOrd.id);
            SBQQ__Quote__c quote = helper.quoteMap.containsKey(newOrd.SBQQ__Quote__c) ? helper.quoteMap.get(newOrd.SBQQ__Quote__c) : null;
            //SFDCSOX-341: ProdOps - Restrictions on Order
            if(isUserGroupValid && isUserTypeValid && isSystemStateValid && isOrderEditValidationDisabled && !IsInsertTransaction && !Test.isRunningTest()){
                if(!hasPOCOrderEditCustomPermission && newOrd.Type == 'POC'){
                    newOrd.addError('You don\'t have permission to Edit the POC Order');
                } else if (!hasRMAOrderEditCustomPermission && newOrd.Type == 'RMA') {
                    newOrd.addError('You don\'t have permission to Edit the RMA Order');
                }
                else if (!hasRevenueOrderEditCustomPermission && newOrd.Type == Constants.ORDER_TYPE_REVENUE) {
                    newOrd.addError('You don\'t have permission to Edit the Revenue Order');
                }
                else if(newOrd.Type == 'Booking Adjustment' || newOrd.Type == Constants.ORDER_TYPE_REVENUE_INTERNAL){
                    newOrd.addError('You don\'t have permission to Edit the Booking Adjustment/Revenue Internal Order');
                }
                else if(!orderAccessPSForShippedOrder && !bypassShippedOrderValidation && oldOrd.Order_Status__c == 'Shipped' && newOrd.Type == 'Revenue'){
                    newOrd.addError('You do not have permission to update Shipped orders.');
        } else if(newOrd.Type == 'Revenue' && newOrd.Order_Status__c != oldOrd.Order_Status__c 
          && (newOrd.Order_Status__c == 'Shipped' || newOrd.Order_Status__c == 'Order Accepted') 
          && !(newOrd.Order_Status__c == 'Order Accepted' && oldOrd.Order_Status__c == 'On Hold' && String.isNotBlank(newOrd.NetSuite_Order__c) && isUserGroupOM)){
          newOrd.addError('Order Status cannot be set to \'Shipped\' or \'Order Accepted\'');
                } 
            }
            //FY25SR-1070: Throws Validation Exception if CRSD date updated as beyond 15 days of the Credit Start Date
            if(!disableBusinessLog.Disable_CRSD_GracePeriod_Validation_Rule__c && newOrd.customer_required_ship_date__c != Null && newOrd.customer_required_ship_date__c != oldOrd.customer_required_ship_date__c){
                Date creditCalculationDate = quote?.Credit_Calculation_Start_Date__c;
                if(creditCalculationDate != Null && helper?.orderIdOrderItemMap.ContainsKey(newOrd.Id)){
                    for(OrderItem OI : helper.orderIdOrderItemMap.get(newOrd.Id)){
                        if(OI.Credit_Amount__c != Null && OI.Credit_Amount__c > 0 && Constants.REPLACEMENT_PROGRAMS.contains(OI.Program__c)){
                            if (Date.valueof(newOrd.customer_required_ship_date__c) > creditCalculationDate?.addDays(Integer.valueOf(crsdGracePeriod.Value__c))) {
                                newOrd.addError((String)crsdOrderErrorMessage?.Value__c);
                            }
                        }
                    }
                }
            }
            createdOrderDate.add(newOrd.CreatedDate.Date());
            Opportunity opp = newOrd.Type == 'POC' ? helper.oppMap?.get(newOrd.POC_Opportunity__c) : helper.oppMap?.get(newOrd.OpportunityId);
            Account acc = helper.accountMap?.get(newOrd.accountId);
            if (serialNumAsset == null) {serialNumAsset = new Map<string, Asset>();}
            if (newOrd.Order_Status__c == 'Shipped' && !beforeUpdateHistory.contains('Shipped')) {
                    for (OrderItem OI : TransactionalDataCollection.orderItemMainList) {
                        if (string.isNotBlank(OI.SerialNumber__c)) {
                            for (string SN : OI.SerialNumber__c.replaceAll('\\s+', '').split(',')) {
                                serialNumAsset.put(SN, null);
                            }
                        }
                        if (String.isNotBlank(OI.Trade_Up_SerialNumber__c)){
                            for (string tradeUpSerialNumber : OI.Trade_Up_SerialNumber__c.replaceAll('\\s+', '').split(',')) {
                                serialNumAsset.put(tradeUpSerialNumber, null);
                            }
                        }
                        if (string.isNotBlank(OI.Failed_Serial_Number__c)) {
                            serialNumAsset.put(OI.Failed_Serial_Number__c, null);
                        }
                    }

                if (opp != null) {
                    orderAccepteddOppIds.add(opp.Id);
                    primaryOppIds.add(opp.Id);
                }
            } else if(newOrd.Order_Status__c != 'Shipped' && String.isNotBlank(newOrd.NetSuite_Order__c) &&  !beforeUpdateHistory.contains('OrderAccepted')) {
                if (newOrd.AccountId != null) orderAcceptedAccIds.add(newOrd.AccountId);
                if (opp != null) primaryOppIds.add(opp.Id);
            }
            if (newOrd.Type == 'POC') {
                if (opp != null) primaryOppIds.add(opp.Id);
            }
            if(acc != null && oldOrd.NetSuite_Order__c == null && newOrd.NetSuite_Order__c != null && newOrd.Polaris_Fulfillment_Status__c == 'Not Started' && newOrd.RSC_G_Enabled__c &&  oldOrd.Ready_for_Gov_Sync__c != 'Sync Ready'){
                if(acc.RSC_G_Account_Sync_status__c == 'Success'){
                    newOrd.Ready_for_Gov_Sync__c = 'Sync Ready';
                }else{
                    newOrd.Ready_for_Gov_Sync__c = 'Account Not Sync';
                }
            }
            if (!beforeUpdateHistory.contains('GTC') &&
                screenSetting.Screening_Source__c == 'Internal' &&
                (newOrd.Internal_Order_Stage__c == 'Pending Validation' || newOrd.Sync_to_NetSuite__c == true) &&
                newOrd.ScreenStatus__c != 'Approved' &&
                newOrd.ScreenStatus__c != 'Approved Bypassed'
               ) {
                   Account partnerAcc = helper.accountMap?.get(newOrd.Partner_Name__c);
                   if (acc != null) {
                       screenWords.addall(helper.getWordSet(acc.Name));
                   }
                   if (newOrd.Ship_To_Name__c != null) {
                       screenWords.addall(helper.getWordSet(newOrd.Ship_To_Name__c));
                   }
                   if (newOrd.ShipToContactName__c != null) {
                       screenWords.addall(helper.getWordSet(newOrd.ShipToContactName__c));
                   }
                   if (opp != null ) {
                     if(newOrd.Polaris_Contact__c != null ) contactIds.add(newOrd.Polaris_Contact__c);
                     if(opp.Initial_Contacts_Name__c != null) screenWords.addall(helper.getWordSet(opp.Initial_Contacts_Name__r.name));
                    }
                    if(partnerAcc != null){
                        screenWords.addall(helper.getWordSet(partnerAcc.name));
                        shipBillCC.add(partnerAcc.BillingCountryCode);
                    }
                   shipBillCC.add(newOrd.ShippingCountryCode);
                   shipBillCC.add(acc.BillingCountryCode);
               }

            //Welcome Letter Email Changes - CS21-778, CS21-748
            if( newOrd.Fulfilment_Set_Name__c != null
               && (newOrd.Order_Status__c == 'Shipped'
                   && !beforeUpdateHistory.contains('Shipped'))
               || (newOrd.ProcessType__c == 'Aspen'
                   && newOrd.SD_Status__c != oldOrd.SD_Status__c
                   && newOrd.SD_Status__c == 'Success')) {//ASPEN-247
                fullfilmentNameSet.add(newOrd.Fulfilment_Set_Name__c);
                orderMap.put(newOrd.Id, newOrd);
            }
            //Welcome Letter Email Changes - CS21-778, CS21-748 - End

        if(newOrd.SD_Status__c == 'Start' && newOrd.SD_Status__c!= oldOrd.SD_Status__c ){
            newOrd.SD_Failure_Reason__c = ''; 
            SDOrdIds.add(newOrd.id); 
            quoteSDProdQuant.put(newOrd.SBQQ__Quote__c, new Map<string,Decimal>());
            quoteIdPCSNs.put(newOrd.SBQQ__Quote__c, new Map<string,string>());
            TransactionalDataCollection.ordIdHWItems.put(newOrd.id,new List<ShipmentDetail__c>()); 
        }
    }
        System.debug(LoggingLevel.DEBUG, 'screenWords' + screenWords);
        System.debug(LoggingLevel.DEBUG, 'shipBillCC' + shipBillCC);
        System.debug(LoggingLevel.DEBUG, 'serialNumAsset' + serialNumAsset);
        System.debug(LoggingLevel.DEBUG,'OrderAcceptedAccIds ::' + orderAcceptedAccIds);

        createdOrderDate.sort();
        Date minDate = createdOrderDate.get(0);
		Date maxDate = createdOrderDate.get(createdOrderDate.size()-1);
        if(!createdOrderDate.isEmpty()){
            helper.orderConfigList = [SELECT Start_Date__c, End_Date__c, Target_Date__c, Configure__c, Order_Type_to_be_considered__c 
                                      FROM Order_Configuration__c
                                      WHERE Configure__c = 'Estimated Ship Date' AND 
                                     Start_Date__c <=: maxDate AND End_Date__c >=: minDate];
        }
        
        /***********************
        * Local scope query
        ***********************/
        //Welcome Letter Email Changes - CS21-778, CS21-748
        if(!fullfilmentNameSet.isEmpty()) {
            orderMap.putAll(new Map<Id,Order>([SELECT Id, Fulfilment_Set_Name__c, Fulfilment_Count__c,
                                            Is_RWD_Polaris_Quote__c,
                                          Welcome_letter_sent_for_the_first_time__c,
                                          WelcomeEmailSentforSoftwareProducts__c, ProcessType__c
                                          FROM Order
                                          WHERE Fulfilment_Set_Name__c IN :fullfilmentNameSet]));

            for(Order odr : orderMap.values()) {
                if(odr.Is_RWD_Polaris_Quote__c){
                    if(!fulfillmentSetOrderIdMap.containsKey(odr.Fulfilment_Set_Name__c)) {
                        fulfillmentSetOrderIdMap.put(odr.Fulfilment_Set_Name__c,new Set<String>());
                    }
                    fulfillmentSetOrderIdMap.get(odr.Fulfilment_Set_Name__c).add(odr.Id);

                    if(!odr.WelcomeEmailSentforSoftwareProducts__c && odr.ProcessType__c == 'Aspen') {
                        if(!softwareWelcomeLetterOrderIdMap.containsKey(odr.Fulfilment_Set_Name__c)){
                            softwareWelcomeLetterOrderIdMap.put(odr.Fulfilment_Set_Name__c,new Set<String>());
                        }
                        softwareWelcomeLetterOrderIdMap.get(odr.Fulfilment_Set_Name__c).add(odr.Id);
                    }

                    if(!odr.Welcome_letter_sent_for_the_first_time__c) {
                        if(!welcomeLetterSentOrderIdMap.containsKey(odr.Fulfilment_Set_Name__c)){
                            welcomeLetterSentOrderIdMap.put(odr.Fulfilment_Set_Name__c,new Set<String>());
                        }
                        welcomeLetterSentOrderIdMap.get(odr.Fulfilment_Set_Name__c).add(odr.Id);
                    }
                }
            }
        }
        //Welcome Letter Email Changes - CS21-778, CS21-748 - End

     if(!SDOrdIds.isEmpty() && !helper.quoteMap.isEmpty()){
        for(Id quoteId : helper.quoteMap.keyset()){
            if(quoteSDProdQuant.containsKey(quoteId) && helper.qlisByQuoteIdMap.containsKey(quoteId) && helper.qlisByQuoteIdMap.get(quoteId).size() > 0 ){
                for(SBQQ__QuoteLine__c qli :helper.qlisByQuoteIdMap.get(quoteId)){
                    if(qli.SBQQ__Product__r.Product_Level__c == 'Hardware' && !qli.SBQQ__Existing__c && 'Accessories' != qli.SBQQ__Product__r?.Product_Type__c){ // PRDOPS24-857 
                        if (qli.Line_Type__c !=null && qli.Line_Type__c == 'New') {
                           quoteSDProdQuant.get(quoteId).put(qli.SBQQ__ProductCode__c,quoteSDProdQuant.get(quoteId).containsKey(qli.SBQQ__ProductCode__c) ? quoteSDProdQuant.get(quoteId).get(qli.SBQQ__ProductCode__c)+qli.SBQQ__Quantity__c:qli.SBQQ__Quantity__c );
                        }
                        if(qli.SBQQ__Product__r.Product_Type__c == 'Spares') {
                            quoteIdPCSNs.get(quoteId).put(qli.SBQQ__ProductCode__c,quoteIdPCSNs.get(quoteId).containsKey(qli.SBQQ__ProductCode__c) ? quoteIdPCSNs.get(quoteId).get(qli.SBQQ__ProductCode__c)+','+qli.id:qli.id);
                        }
                    }
                }
            }
        }

        for (ShipmentDetail__c sd : [SELECT id,Order__c,Order__r.SBQQ__Quote__c,Quote__c,HW_SerialNumber__c,ProductName__c,ProcessHistory__c,Quantity__c,ShippedDate__c,Status__c,TrackingNumber__c,Type__c,ContractManufacturer__c,QuoteNumber__c,Product_Type__c,Quote_Line__c,OrderItemIds__c,RecordTypeId,Quote_MissingShipmentDetails__c,Quote_ShipmentValidation__c,Parent_Shipment_Detail__c FROM ShipmentDetail__c WHERE 
                                          (Order__c IN:SDOrdIds AND Status__c ='New') OR ( Quote__c IN: quoteSDProdQuant.keySet() AND Status__c ='Success') 
                                           OR (Quote__c IN: quoteSDProdQuant.keySet() AND RecordTypeId =: Constants.overViewRecordTypeId)]) 
        {
        if (sd.Status__c == 'Success') {
          if (quoteSDProdQuant.get(sd.Quote__c)?.get(sd.ProductName__c) != null) {
            quoteSDProdQuant.get(sd.Quote__c).put(sd.ProductName__c, quoteSDProdQuant.get(sd.Quote__c).get(sd.ProductName__c) - sd.Quantity__c);
          }
        } else {
              if(sd.ProductName__c!= null && sd.Order__r?.SBQQ__Quote__c!= null && quoteIdPCSNs.get(sd.Order__r.SBQQ__Quote__c).containsKey(sd.ProductName__c.trim().toUpperCase())){
                sd.Quote_Line__c = quoteIdPCSNs.get(sd.Order__r.SBQQ__Quote__c).get(sd.ProductName__c.trim().toUpperCase()).substringBefore(',');
                sd.Quote_Item_Ids__c = quoteIdPCSNs.get(sd.Order__r.SBQQ__Quote__c).get(sd.ProductName__c.trim().toUpperCase());
              }
              if(sd.RecordTypeId != Constants.overViewRecordTypeId) {
                  TransactionalDataCollection.ordIdHWItems.get(sd.Order__c).add(sd);
              } else if(sd.RecordTypeId == Constants.overViewRecordTypeId) {
                  TransactionalDataCollection.quoteIdHWItems.put(sd.Quote__c, sd);
              }
              if(sd.HW_SerialNumber__c != null){
                for(string SN : sd.HW_SerialNumber__c.replaceAll('\\s+','').split('\\,')){
                      if(string.isNotBlank(SN)){
                        if(isAssetQueryExecuted)
                        isAssetQueryExecuted = false;
                        serialNumAsset.put(SN,null);
                      }
                }
              }
         }
      }
      for (Order newOrd : (List<order>) Trigger.new) {
        Order oldOrd = (Order) Trigger.oldMap.get(newOrd.id);
        if(newOrd.SD_Status__c == 'Start' && newOrd.SD_Status__c!= oldOrd.SD_Status__c && newOrd.SBQQ__Quote__c != null && TransactionalDataCollection.quoteIdHWItems.containsKey(newOrd.SBQQ__Quote__c)){
            newOrd.Overview_Shipment_Detail__c = TransactionalDataCollection.quoteIdHWItems.get(newOrd.SBQQ__Quote__c).Id;
        }
      }
    }
      Profile PROFILE = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
        if (!beforeUpdateHistory.contains('OrderAccepted')) {
            if (!orderAcceptedAccIds.isEmpty()) {
                for (PS_Project__c proj : [ SELECT Id, Name, Account__c, Opportunity__c
                                           FROM PS_Project__c
                                           WHERE Account__c IN :orderAcceptedAccIds
                                           ORDER BY createddate DESC]) {
                                               if (accIdPSProjects.containsKey(proj.Account__c)) {
                                                   accIdPSProjects.get(proj.Account__c).add(proj);
                                               } else {
                                                   accIdPSProjects.put(proj.Account__c,new List<PS_Project__c>{ proj });
                                               }
                                           }
            }
        }
        
        if (serialNumAsset!= null && !serialNumAsset.isEmpty() && 
            (TransactionalDataCollection.assetMainList.isEmpty() ||
            (!isAssetQueryExecuted ))){
            isAssetQueryExecuted = true;

            TransactionalDataCollection.assetMainList = [
                SELECT
                Id,
                SerialNumber,
                Serial_number__c,
                Product2ID,
                Quantity,
                accountId,
                PurchaseDate,
                Order_Service_Item__c,
                Support_Start_Date__c,
                Premium_Support_End_Date__c,
                ParentId,
                Free_HW_Refresh_Forfeited__c
                FROM asset
                WHERE SerialNumber IN :serialNumAsset.keyset()
            ];
            for (Asset asst : TransactionalDataCollection.assetMainList) {
                serialNumAsset.put(asst.SerialNumber, asst);
            }
        }
    system.debug(LoggingLevel.DEBUG, 'quotautoSubmit ' + autoSubmit);
        if (BkgCuttoffcount == null && autoSubmit) {
            DateTime currentTime = system.now();
            BkgCuttoffcount = database.countQuery('select count() from BookingCutOff__c where StartDate__c <=: currentTime and EndDate__c >=: currentTime');
        }
        if (!primaryOppIds.isEmpty()) {
            for (OpportunityContactRole ocr : [SELECT Id, ContactId, Contact.Email, OpportunityId, Contact.Phone
                                               FROM OpportunityContactRole
                                               WHERE OpportunityId IN :primaryOppIds AND IsPrimary = TRUE
                                              ]) {
                                                  oppId_OCRMap.put(ocr.OpportunityId, ocr);
                                              }
        }

        if(!orderAccepteddOppIds.isEmpty()){
            //MKT22-378: Initialize with the number of PS Projects
            for (AggregateResult ar : [SELECT Opportunity__c, count(Id)
                                        FROM PS_Project__c
                                        WHERE Opportunity__c IN :orderAccepteddOppIds
                                        GROUP BY Opportunity__c]){
                oppToPSProjectCount.put(String.valueOf(ar.get('Opportunity__c')), Integer.valueOf(ar.get('expr0')));
            }

          //MKT22-378: Initialize with the number of PS Projects//
        }

        if (!screenWords.isEmpty() && excludePartyList == null) {
            excludePartyList = new Set<string>();
            screenPartyList = new List<GTC_Screening__c>();
            if(!contactIds.isEmpty()){
                for(Contact con : [select id,name from contact where id IN: contactIds]){
                    if(con.name != null){
                       helper.contactMap.put(con.id,con);
                       screenWords.addall(helper.getWordSet(con.Name));
                    }
               }
            }

            for (GTC_Screening__c screen : [SELECT Id, Party_Name__c, CountryCode__c, Type__c
                                            FROM GTC_Screening__c
                                            WHERE Party_Name__c LIKE :screenWords AND CountryCode__c IN :shipBillCC]) {
                                                if (screen.Type__c == 'Exclude') {
                                                    excludePartyList.add(screen.Party_Name__c.toLowerCase());
                                                } else if (screen.Type__c == 'Include') {
                                                    screenPartyList.add(screen);
                                                }
                                            }
        }
        System.debug(LoggingLevel.DEBUG, 'screenPartyList' + screenPartyList);
        System.debug(LoggingLevel.DEBUG, 'excludePartyList' + excludePartyList);
        Map<Id, Order> amtValidatedOrders = new Map<Id, Order>();
        if(!OpportunityBulkUpdateQueueable.isBulkDeal){
            amtValidatedOrders =  OrderValidationService.validateTotAmtForMultipleOrders((Map<Id, Order>) Trigger.newMap, TransactionalDataCollection.stagePo,helper.orderIdOrderItemMap);
        }
        // Processing Logic
    if( !beforeUpdateHistory.contains('OrderAccepted') && PSTaskService.setRubrikUOrderId == null ) {
      PSTaskService.setOrderswithRubrikU(helper.orderIdOrderItemMap, (Map<Id, Order>)trigger.newMap, null); //Added for MKT26-773
    }
        for (Order newOrd : (List<order>) Trigger.new) {
            newOIList = helper.orderIdOrderItemMap.get(newOrd.Id);
            Order oldOrd = (Order) Trigger.oldMap.get(newOrd.id);
            Opportunity opp = newOrd.Type == 'POC'? helper.oppMap?.get(newOrd.POC_Opportunity__c): helper.oppMap?.get(newOrd.OpportunityId);
            Account acc = helper.accountMap?.get(newOrd.accountId);
            SBQQ__Quote__c quote = helper.quoteMap?.get(newOrd.SBQQ__Quote__c);
            OpportunityContactRole primaryOCR = opp != null ? oppId_OCRMap.get(opp.id) : null;
            Boolean arryAutoSubmit = true;
            if(!isPermissionToFieldUpdate && (String.isNotBlank(Order_control__mdt.getInstance('Profile_Names').Value__c) && Order_control__mdt.getInstance('Profile_Names').Value__c.contains(PROFILE.Name)) &&
              (newOrd.ContractId != oldOrd.ContractId || newOrd.AccountId != oldOrd.AccountId || newOrd.EffectiveDate != oldOrd.EffectiveDate || newOrd.ContractId != oldOrd.ContractId||
               newOrd.EndDate != oldOrd.EndDate|| newOrd.RecordTypeId != oldOrd.RecordTypeId || newOrd.Status != oldOrd.Status || newOrd.OwnerId != oldOrd.OwnerId || newOrd.SBQQ__Contracted__c != oldOrd.SBQQ__Contracted__c)){
                   newOrd.addError('You don\'t have permission to update Order Fields.');
               }
            If(quote != null && (quote.SBQQ__Type__c == 'Renewal+Expansion' && quote.Arry_Count_Of_Lines_Renewed__c > 0)){
                If(manualOrdSum.value__c != null && String.isNotBlank(manualOrdSum.value__c)){
                    for(String OrdType: manualOrdSum.value__c.replaceAll('\\s+', '').split(',')){
                        If(OrdType == 'R+E' || OrdType.contains('R+E')){
                            arryAutoSubmit = false;
                        }
                    }
                }
            }

            //Welcome Letter Email Changes - CS21-778, CS21-748
            if (newOrd.ProcessType__c != 'Aspen') {
                if (fulfillmentSetOrderIdMap.containsKey(newOrd.Fulfilment_Set_Name__c)
                    && newOrd.Fulfilment_Count__c > fulfillmentSetOrderIdMap.get(newOrd.Fulfilment_Set_Name__c).size()) {
                    newOrd.Welcome_letter_sent_for_the_first_time__c = true;
                } else if (welcomeLetterSentOrderIdMap.containsKey(newOrd.Fulfilment_Set_Name__c)
                           && welcomeLetterSentOrderIdMap.get(newOrd.Fulfilment_Set_Name__c).size() > 1) {
                    newOrd.Welcome_letter_sent_for_the_first_time__c = true;
                    welcomeLetterSentOrderIdMap.get(newOrd.Fulfilment_Set_Name__c).remove(newOrd.Fulfilment_Set_Name__c);
                }
            } else {
                if (fulfillmentSetOrderIdMap.containsKey(newOrd.Fulfilment_Set_Name__c)
                    && newOrd.Fulfilment_Count__c > fulfillmentSetOrderIdMap.get(newOrd.Fulfilment_Set_Name__c).size()) {
                    if (newOrd.SD_Status__c == 'Success') {//ASPEN1B-247
                        newOrd.Welcome_letter_sent_for_the_first_time__c = true;
                    } else {
                        newOrd.WelcomeEmailSentforSoftwareProducts__c = true;
                    }
                } else if (softwareWelcomeLetterOrderIdMap.containsKey(newOrd.Fulfilment_Set_Name__c)
                           && softwareWelcomeLetterOrderIdMap.get(newOrd.Fulfilment_Set_Name__c).size() > 1
                           && newOrd.SD_Status__c != 'Success') {//ASPEN1B-247
                    newOrd.WelcomeEmailSentforSoftwareProducts__c = true;
                    softwareWelcomeLetterOrderIdMap.get(newOrd.Fulfilment_Set_Name__c).remove(newOrd.Fulfilment_Set_Name__c);
                    welcomeLetterSentOrderIdMap.get(newOrd.Fulfilment_Set_Name__c).remove(newOrd.Fulfilment_Set_Name__c);
                } else if (welcomeLetterSentOrderIdMap.containsKey(newOrd.Fulfilment_Set_Name__c)
                           && welcomeLetterSentOrderIdMap.get(newOrd.Fulfilment_Set_Name__c).size() > 1
                           && newOrd.SD_Status__c == 'Success')//ASPEN1B-247
                {
                    newOrd.Welcome_letter_sent_for_the_first_time__c = true;
                    welcomeLetterSentOrderIdMap.get(newOrd.Fulfilment_Set_Name__c).remove(newOrd.Fulfilment_Set_Name__c);
                }
            }
            //Welcome Letter Email Changes - CS21-778, CS21-748 - End
            helper.populateFieldsOnUpdate(newOrd,oldOrd,primaryOCR,beforeUpdateHistory);
            if(newOrd.Stage_PO__c == null){ 
                helper.copyPODetails(newOrd, TransactionalDataCollection.stagePo, newOIList);
            } 
            if(rcdmtValidation == 'true' && (disableRCDM_ValidationForUsers.isEmpty() || (!disableRCDM_ValidationForUsers.isEmpty() && !disableRCDM_ValidationForUsers.contains(UserInfo.getUserId()))) && (autoSubmit|| (newOrd.Internal_Order_Stage__c == 'Pending Validation' &&
                newOrd.Internal_Order_Stage__c != oldOrd.Internal_Order_Stage__c))) { 
                  helper.submitOrderValidationForRCDMT(newOrd); 
            }
            if (autoSubmit && newOrd.Order_Status__c != 'On Hold' && (newOrd.Type != 'revenue' || (newOrd.Type == 'revenue' && (BkgCuttoffcount == null || BkgCuttoffcount == 0))) &&
                newOrd.Sell_to_Partner__c == null && newOrd.Type != 'POC' && newOrd.POC_Type__c  != 'Conditional PO' && arryAutoSubmit && newOrd.Type != 'Revenue Internal') {
                   helper.autoSubmitOrder(newOrd, oldOrd, TransactionalDataCollection.stagePo, amtValidatedOrders);
            }
            helper.complianceScreen(newOrd, oldOrd, acc, opp, screenPartyList, excludePartyList);
            if(newOrd.Order_Status__c == 'On Hold' && newOrd.Change_Needed_Reason_Other__c != null && newOrd.Change_Needed_Reason_Other__c.contains('RCDM-T') && newOrd.Sync_to_NetSuite__c == true && 
               rcdmtValidation == 'true' && (disableRCDM_ValidationForUsers.isEmpty() || (!disableRCDM_ValidationForUsers.isEmpty() && !disableRCDM_ValidationForUsers.contains(UserInfo.getUserId())))) {
                  newOrd.Sync_to_NetSuite__c = false;
            }
            if(newOrd.Type == 'POC' && newOrd.Order_Status__c != 'Shipped'){
                updateHelper.shipPOCOrder(newOrd);
            }

            if (newOrd.Sync_to_NetSuite__c && newOrd.type == 'Revenue'){
                newOrd.Revised_By__c = OrderValidationService.storeLoggedInUserEmailWhenSyncIsTrue(newOrd.Revised_By__c);
            }
            if(!orderIdsToFireEventOnce.contains(newOrd.Id)){
                if((newOrd.Type == 'RMA' || newOrd.Type =='Revenue' || newOrd.Type =='Revenue Internal')
                  && (newOrd.ScreenStatus__c == 'Approved' || newOrd.ScreenStatus__c == 'Approved Bypassed')
                  && newOrd.Order_Status__c!='Shipped'
                && newOrd.Sync_to_NetSuite__c
                && ((!oldOrd.Sync_to_NetSuite__c && newOrd.Sync_to_NetSuite__c)
                || (oldOrd.Order_Status__c!=newOrd.Order_Status__c && newOrd.Order_Status__c == 'Order Accepted' && newOrd.Sync_to_NetSuite__c)
                || (newOrd.Order_Status__c != 'Shipped' && oldOrd.Polaris_Fulfillment_Status__c!= newOrd.Polaris_Fulfillment_Status__c && (newOrd.Polaris_Fulfillment_Status__c == 'Completed' || newOrd.Polaris_Fulfillment_Status__c == 'Not needed'))
                || (newOrd.Sync_to_NetSuite__c && IsInsertTransaction)
                || (newOrd.ScreenStatus__c != oldOrd.ScreenStatus__c && (newOrd.ScreenStatus__c == 'Approved' || newOrd.ScreenStatus__c == 'Approved Bypassed')))){
                orderIdsToFireEventOnce.add(newOrd.Id);
                syncToNsEvents.add(new Sync_To_NS_On_Order_Event__e(OrderId__c = newOrd.Id, AccountId__c = string.isBlank(acc.NS_Internal_Id__c)? acc.Id:null));
                
                }
                }

            if (newOrd.Sync_to_NetSuite__c)
                helper.orderValidation(newOrd);
            if (newOrd.Order_Status__c != null && newOrd.Order_Status__c != oldOrd.Order_Status__c) {
                if (newOrd.Order_Status__c == 'Order Accepted') {
                    if (opp != null && newOrd.PS_Project__c == null && newOrd.Have_PS_Products__c && acc != null && !beforeUpdateHistory.contains('OrderAccepted')) {

                       //MKT22-378: Initialize with the number of PS Projects
                        updateHelper.createPSProject( newOrd, PSExternalRecId, accIdPSProjects.get(newOrd.accountId),acc, primaryOCR,PSProjToInsert,oppToPSProjectCount, accIdPSProjects);
                    }
                    OrderValidationService.updateExpectedDateForReplacement(newOrd, helper.orderIdOrderItemMap); //PRDOPS26-1145
                    beforeUpdateHistoryLocal.add('OrderAccepted');
                } else if (  newOrd.Order_Status__c == 'Shipped' && oldOrd.Order_Status__c != 'Shipped' &&!beforeUpdateHistory.contains('Shipped')) {
                    updateHelper.CaptureMissingAssetsAndTrainingSkus(newOrd,
                                                                     newOIList,
                                                                     serialNumAsset,
                                                                     trainingOrderItemIds);
                    beforeUpdateHistoryLocal.add('Shipped');
                }
            }
            if (newOrd.Order_Status__c == 'On Hold') {
                updateHelper.onHoldOrders(newOrd, oldOrd);
            }
            if(newOrd.Type == 'Revenue' && oldOrd.Internal_Order_Stage__c != 'Order Submitted' && newOrd.Internal_Order_Stage__c == 'Order Submitted'
               && newOrd.Booked_By__c == null){
                   newOrd.Booked_By__c = UserInfo.getUserId();
            }
            if((acc != null  && newOrd.RSC_G_Enabled__c &&  oldOrd.Ready_for_Gov_Sync__c != 'Sync Ready' && newOrd.Type == 'POC' && newOrd.Send_for_Polaris_Fulfilment__c ) && 
	        (!oldOrd.Send_for_Polaris_Fulfilment__c || 
            (newOrd.Support_End_Date__c != oldOrd.Support_End_Date__c && newOrd.Polaris_Fulfillment_Status__c == 'Not Started') || 
            helper.isResyncDates)){
                newOrd.Ready_for_Gov_Sync__c = acc.RSC_G_Account_Sync_status__c == 'Success' ? 'Sync Ready' : 'Account Not Sync';
            }
            if(newOrd.Order_Status__c == 'Shipped' && newOrd.SBQQ__Contracted__c == false && newOrd.Type == 'Revenue' && newOrd.Order_Sub_Type__c != 'MSP Overage' 
               && newOrd.Order_Sub_Type__c != 'GC OnDemand' && newOrd.SBQQ__Quote__c != null && newOrd.Status == 'Activated' 
               && (newOrd.Welcome_letter_sent_for_the_first_time__c || newOrd.WelcomeEmailSentforSoftwareProducts__c)){
                   if(!disableBusinessLog.Follow_Existing_EntCreate_Process__c){
                       String existingVal = newOrd.SC_or_Entitlement_Stage__c;
                       if(existingVal == null || !existingVal.contains('Create Service Contract')){
                           if(String.isEmpty(existingVal)){
                               newOrd.SC_or_Entitlement_Stage__c = 'Create Service Contract';
                           }
                           else{
                               newOrd.SC_or_Entitlement_Stage__c =  existingVal + ';' + 'Create Service Contract';
                           }
                       }
                   }	
            }
            if(newOrd.SC_or_Entitlement_Stage__c != null && newOrd.SC_or_Entitlement_Stage__c?.contains('Create Service Contract') && ((oldOrd.SC_or_Entitlement_Stage__c != null && !oldOrd.SC_or_Entitlement_Stage__c?.contains('Create Service Contract')) || oldOrd.SC_or_Entitlement_Stage__c == null)) {
                ordToValidateSCGen.add(newOrd);
            }
            //disabled orderItemTrigger
            if(newOrd.Order_Status__c == 'Shipped' && oldOrd.Order_Status__c != newOrd.Order_Status__c){
                OrderValidationService.executeQueableJobOnShipped(newOrd, helper.orderIdOrderItemMap);
            }
    
        }
        system.debug(LoggingLevel.DEBUG,'trainingOrderItemIds' + trainingOrderItemIds);
        if (!trainingOrderItemIds.isEmpty() && disableBusinessLog.Disable_Order_Email_Alerts__c == false) {
            updateHelper.NotifyTrainingSKU(trainingOrderItemIds);
        }
        if(!ordToValidateSCGen.isEmpty()){
            OrderInsertHelper.validateOrdisEligibleSCGen(ordToValidateSCGen, (Map<Id, Order>) Trigger.newMap, helper);
        }
        beforeUpdateHistory.addall(beforeUpdateHistoryLocal);
        updateHelper.CommitabeforeUpdateRecords(PSProjToInsert);
    }

  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description This method is used to update the Latest Estimated Shipment And Delivery dates on all the related orders
   * @param   lstOrderNumbers
   */
    @future
    private static void updateShipDates(List<String> lstOrderNumbers) {

        Map<String, Order> mapOrders = new Map<String,Order>();
        Map<String,Order> mapOrdersUpdate = new Map<String,Order>();
        for(Order ord : [SELECT Id, OrderNumber, Related_Orders__c, Est_Ship_Date__c, Deliver_By__c, Sync_to_NetSuite__c FROM Order WHERE OrderNumber IN :lstOrderNumbers]){
            mapOrders.put(ord.OrderNumber.trim(), ord);
        }

        for(Order ord : mapOrders.values()){
            if(mapOrdersUpdate.containskey(ord.OrderNumber)) continue;
            if(String.isBlank(ord.Related_Orders__c)) continue;
            List<Date> tempEstShipDates = new List<Date>();
            List<Date> tempEstDelDates = new List<Date>();
            for(String ordNum : ord.Related_Orders__c.split(',')){
                if(mapOrders.containsKey(ordNum)){
                    tempEstShipDates.add(mapOrders.get(ordNum).Est_Ship_Date__c);
                    tempEstDelDates.add(mapOrders.get(ordNum).Deliver_By__c);
                }
            }
            if(tempEstShipDates.isEmpty() && tempEstDelDates.isEmpty()) continue;

            tempEstShipDates.sort();
            tempEstDelDates.sort();

            for(String ordNum : ord.Related_Orders__c.split(',')){
                if(!mapOrders.containsKey(ordNum)) continue;
                if(mapOrdersUpdate.containsKey(ordNum)) continue;
                Order ordUpdate = mapOrders.get(ordNum);
                if(tempEstShipDates.size()>=1){
                    date maxEstShipDate = tempEstShipDates.size() == 1 ? tempEstShipDates[0] : tempEstShipDates[tempEstShipDates.size() - 1];
                    if(ordUpdate.Est_Ship_Date__c != maxEstShipDate){
                        ordUpdate.Est_Ship_Date__c = maxEstShipDate;
                        ordUpdate.Sync_to_NetSuite__c = true;
                        mapOrdersUpdate.put(ordNum,ordUpdate);
                    }
                }
                if(tempEstDelDates.size()>=1){
                    date maxEstDelDate = tempEstDelDates.size() == 1 ? tempEstDelDates[0] : tempEstDelDates[tempEstDelDates.size() - 1];
                    if(ordUpdate.Deliver_By__c != maxEstDelDate){
                        ordUpdate.Deliver_By__c = maxEstDelDate;
                        ordUpdate.Sync_to_NetSuite__c = true;
                        mapOrdersUpdate.put(ordNum,ordUpdate);
                    }
                }
            }
        }

        if(!mapOrdersUpdate.isEmpty()){
            TriggerControl.stopOrderTrigger = true;
            TriggerControl.stopOrderItemTrigger = true;
            update mapOrdersUpdate.values();
        }
    }

    /*************************************************************************************
    after Update
    Desciption :
    *************************************************************************************/
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description Calling after Update For OrderTrigger
   */
    public override void afterUpdate() {
        set<string> afterUpdateHistoryLocal = new Set<string>();
        System.debug(LoggingLevel.INFO,'after update history :: ' + afterUpdateHistory);
        set<id> salesopsOrdIDs = new set<id>();
        updateHelper = OrderUpdateHelper.getInstance();
        List<OrderItem> newOIList = new List<OrderItem>();
        Map<Id, List<Rebate_Table__c>> accIdRebates;
        set<id> resyncOrdIds = new Set<id>();
        Map<Id, List<Entitlement>> OIEntMap;
        List<string> failedSerial = new List<String>();
        Map<String,List<Entitlement>> failedAssetWithEntitlement = new Map<String,List<Entitlement>>();
        List<BLI_Impact__mdt> BLIimpactMap;
        Map<Id, Booking__c> ordIdBooking;
        Map<string, Node__c> serialNumNode;
        Map<string, Chassis__c> serialNumChassis;
        Map<string, Power_Supply__c> serialNumPSU;
        Map<string, Drive__c> serialNumHDDSSD; // both hdd and ssd
        Map<string, Memory__c> serialNumMemory;
        Map<Id, List<Booking_Line_Item__c>> bookingIdBLIs;
        Map<string, List<string>> assetNodesSN = new Map<string, List<string>>();
        set<Id> RMAShippedOrdId = new Set<Id>();
        set<Id> ShippedPrimaryConId = new Set<Id>();
        set<string> queryKeys = new Set<string>();
        set<id> NodeReplacementOrdIds = new Set<Id>();
        set<string> RMA_NodeSN = new Set<string>();
        set<string> RMA_ChassisSN = new Set<string>();
        set<string> RMA_PSUSN = new Set<string>();
        set<string> RMA_HDD_SSD_SN = new Set<string>();
        set<string> RMA_MemorySN = new Set<string>();
        set<Id> onHoldOppIds = new Set<id>();
        set<Id> upgradeAssetIds = new Set<Id>();
        set<string> newNodeAssetSN = new Set<string>();
        Map<Id, user> portalConUserMap = new Map<Id, user>();
        //added by varsha
        Set<Id> UpdatedOrderIds =New Set<ID>();
        /* DML collection START */
        Map<Id, Account> accToUpdate = new Map<Id, Account>();
        set<Entitlement> EntToInsert = new Set<Entitlement>();
        Map<Id, booking__c> bookingToUpdate = new Map<Id, booking__c>();
        set<Booking_Line_Item__c> BLIToInsert = new Set<Booking_Line_Item__c>();
    Map<Id, Decimal> mapBKgIdToNetRenewal = new Map<Id, Decimal>();
    Map<Id, Decimal> mapBKgIdToNetNew = new Map<Id, Decimal>();
    Map<Id, Decimal> mapBKgIdToGrossACVAmt = new Map<Id, Decimal>();
    Map<Id, Decimal> mapBKgIdToGrossNewACV = new Map<Id, Decimal>();
    Map<Id, Decimal> mapBKgIdToGrossRenewalACV = new Map<Id, Decimal>();
    Map<Id, Booking_Line_Item__c> BLIToUpdate = new Map<Id, Booking_Line_Item__c>();
    Set<Id> opptyWhenCmChanged = new Set<Id>();
    Set<Id> orderWhenCmChanged = new Set<Id>();
    Map<Id,Quote_and_Order_Staging__c> updateParentRecordForRCDMTExtentionObj;
    Map<Id,Id> accountIdToOrderMatchMap = new Map<Id,Id>();
    Map<Id,Id> rcdmQuoteLineIdToOrderItem  = new Map<Id,Id>();   
    

        Map<Id, Opportunity> oppToUpdate = new Map<Id, Opportunity>();
        Map<Id, Node__c> nodeToUpdate = new Map<Id, Node__c>();
        set<Chassis__c> chasisToInsert = new Set<Chassis__c>();
        set<Power_Supply__c> PSUToInsert = new Set<Power_Supply__c>();
        set<Drive__c> HDDSSDToInsert = new Set<Drive__c>();
        set<Memory__c> memoryToInsert = new Set<Memory__c>();
        Map<string, Asset> assetToUpsert = new Map<string, Asset>(); // Map<serialnumber,asset>
        set<Scale_Entitlement__c> scaleEntToInsert = new set<Scale_Entitlement__c>();
        set<PS_Project__c> PSProjToInsert = new Set<PS_Project__c>();
        set<id> CreatePortalUserOrderIds = new Set<id>();
        Map<Id, PO_Stage__c> POStgToUpdate = new Map<Id, PO_Stage__c>();
        set<PS_Task__c> psTaskToInsert = new Set<PS_Task__c>();
        set<Hold_Off_Tracking__c> holdCodeTrackToInsert = new Set<Hold_Off_Tracking__c>();
        Map<Id, orderItem> orderItemToUpdate = new Map<Id, orderItem>();
        Boolean isSerialNumUpdated = false;
        Map<Id, Hold_Off_Tracking__c> holdCodeTrackToUpdate = new Map<Id, Hold_Off_Tracking__c>();
        Map<Id, Entitlement> EntToUpdate = new Map<Id, Entitlement>();
        List<String> allOrdsLst = new List<String>();
        // Project: ScaleUtility 
        // Use: will store the GC OnDemand order ids that later will be used to get Scale_Utility_Overage__c records and mark them Sync Ready for NS
        List<Id> acceptedGCOnDemandOrderIds = new List<Id>();
        Set<Id> orderReadyTosyncwithGovOrg = new set<Id>();
        Map<Id, String> quoteIdToAction = new Map<Id, String>();
    Map<Id, Set<Id>> eligibleOrdItmForPhantOrdByQuoteId = new Map<Id, Set<Id>>();
        /* DML collection END */

        Set<String> replacedFromSerialNumbers = new Set<String>();

    // ---- CS21-3192 ----
        Set<Id> orderWithUSCitizenProducts = new Set<Id>();
        
        /* CS21-3477: If order has RSC product */
        Set<Id> OrderHasRSCProduct = new Set<Id>();
        system.debug(LoggingLevel.DEBUG,'oppIdHCtracker after update' + oppIdHCtracker);
        if (queryKeys.isEmpty()) {
            Map<String, OrderItem> originalOrdItemById = new Map<String, OrderItem>();
            Set<String> originalOrdItemIds = new Set<String>();
            for(Order newOrd : (List<order>) Trigger.new){
                Order oldOrd = (Order) Trigger.oldMap?.get(newOrd.id);
                if(!System.isBatch() && newOrd.Type == 'Revenue' 
                   && !UtilityClass.isReplacementOrder(oldOrd) && UtilityClass.isReplacementOrder(newOrd))
                {
                    newOIList = helper.orderIdOrderItemMap.get(newOrd.Id);
                    for(OrderItem newOrdItem: newOIList){
                        if(newOrdItem.Previous_Transaction_Reference__c != null){
                            List<PreviousTransRefWrapper> prevLineDetailsList = (List<PreviousTransRefWrapper>)JSON.deserialize(newOrdItem.Previous_Transaction_Reference__c, List<PreviousTransRefWrapper>.class);
                            for(PreviousTransRefWrapper wrapperInstance : prevLineDetailsList){
                                originalOrdItemIds.add(wrapperInstance.orderItemId);    
                            }
                        }    
                    }
                }    
            }
            if(!originalOrdItemIds.isEmpty()){
                originalOrdItemById = new Map<String,OrderItem>([SELECT Id, credit_amount__c, Support_Start_Date__c, Support_End_Date__c,
                                            Program__c, Replacement_Type__c, Order.SBQQ__Quote__c, Order.Associated_Order_Numbers__c,
                                            (SELECT Id, End_of_Paid_Term__c FROM Order_Item_Extensions__r)
                                                              FROM OrderItem WHERE Id IN :originalOrdItemIds]);    
            }
            for (Order newOrd : (List<order>) Trigger.new) {
                Order oldOrd = (Order) Trigger.oldMap?.get(newOrd.id);
                SBQQ__Quote__c quote = helper.quoteMap?.get(newOrd.SBQQ__Quote__c);
                if(newOrd.SC_or_Entitlement_Stage__c != null && newOrd.SC_or_Entitlement_Stage__c?.contains('Create Service Contract') && 
                ((oldOrd.SC_or_Entitlement_Stage__c != null && !oldOrd.SC_or_Entitlement_Stage__c?.contains('Create Service Contract')) || oldOrd.SC_or_Entitlement_Stage__c == null) &&
                newOrd.SBQQ__Contracted__c == false) {
                    if(helper.orderIdOrderItemMap.containskey(newOrd.Id)){
                        for(OrderItem oi : helper.orderIdOrderItemMap.get(newOrd.Id)){
                            if(oi.SBQQ__Contracted__c == false){
                                continue;
                            }
                            if(orderItemToUpdate.containskey(oi.id)){
                                orderItemToUpdate.get(oi.id).SBQQ__Contracted__c = false;
                            }else{
                                oi.SBQQ__Contracted__c =false;
                                orderItemToUpdate.put(oi.id, oi);
                            }
                        }
                    }

                }
                if(quote!=null && quote.RWD_Deal_Ops_Exception__c == constants.RCDMT_EXT_RWD_DEAL_OPS_EXCEPTION){
                    accountIdToOrderMatchMap.put(newOrd.accountId,neword.Id);
                }
                if(newOrd.OpportunityId!=null && oldOrd.Contract_Manufacturer__c!=newOrd.Contract_Manufacturer__c && (oldOrd.CM_Updated__c!=newOrd.CM_Updated__c && newOrd.CM_Updated__c && oldOrd.Order_Status__c!=newOrd.Order_Status__c && newOrd.Order_Status__c == 'Shipped')){
                    opptyWhenCmChanged.add(newOrd.OpportunityId);
                    orderWhenCmChanged.add(newOrd.Id);
                }

                if (newOrd.Order_Status__c == 'Order Accepted' && !afterUpdateHistory.contains('Order Accepted')){
                    queryKeys.add('OrderAccepted');
                }
                if (newOrd.BookingStatus__c == 'Booking Created' && !afterUpdateHistory.contains('Rebate')) {
                    queryKeys.add('Bookings');
                }
                if ((newOrd.Order_Status__c == 'Rejected' && !afterUpdateHistory.contains('Rejected')) ||
                    ((newOrd.SBQQ__PriceCalcStatus__c == 'Queued' || oldOrd.SBQQ__PriceCalcStatus__c == 'Queued') &&
                         newOrd.SBQQ__PriceCalcStatus__c != oldOrd.SBQQ__PriceCalcStatus__c && !afterUpdateHistory.contains('Rebate'))){
                    resyncOrdIds.add(newOrd.id);
                }
                if (newOrd.Order_Status__c == 'Shipped' && !afterUpdateHistory.contains('Shipped')) {
                    if (newOrd.type == 'RMA') {
                        RMAShippedOrdId.add(newOrd.id);
                    }
                    if (newOrd.Welcome_Letter_Contact__c != null) {
                        ShippedPrimaryConId.add(newOrd.Welcome_Letter_Contact__c);
                    }
                    if (helper.orderIdOrderItemMap.get(newOrd.id) != null) {
                        for (OrderItem OI : helper.orderIdOrderItemMap.get(newOrd.id)) {
                            if (OI.Upgraded_From__c != null) {
                                for(String eachAsset: OI.Upgraded_From__c.replaceAll('\\s+', '').split(',')){
                                    if(serialNumAsset != null && serialNumAsset.containsKey(eachAsset) && serialNumAsset.get(eachAsset) != null){
                                        upgradeAssetIds.add(serialNumAsset.get(eachAsset).id);
                                    }
                                }
                                if (string.isNotBlank(OI.Upgraded_From__c) && (Constants.REPLACEMENT_PROGRAMS.contains(OI.Program__c) || OI.Program__c == CONSTANTS.PROGRAM_REFRESH)) {
                                    replacedFromSerialNumbers.addAll(new List<String>(OI.Upgraded_From__c.split(',')));
                                }
                            }
                            if((OI?.PricebookEntry?.Product2?.Product_Type__c == null) || !(OI?.PricebookEntry?.Product2?.Product_Type__c.contains(System.label.PredibaseProduct))){
                                OrderHasRSCProduct.add(newOrd.id);
                            }
                        }
                    }
                }
                 if (helper.orderIdOrderItemMap.get(newOrd.id) != null) {
                    for (OrderItem OI : helper.orderIdOrderItemMap.get(newOrd.id)) {
                        if(OI.SBQQ__QuoteLine__r.RWD_Deal_Ops_Exception__c == constants.RCDMT_EXT_RWD_DEAL_OPS_EXCEPTION && !rcdmQuoteLineIdToOrderItem.containskey(OI.SBQQ__QuoteLine__c)){
                            rcdmQuoteLineIdToOrderItem.put(OI.SBQQ__QuoteLine__c,OI.Id);
                        }
                         // ---- CS21-3192 ----
                        if(OI.PricebookEntry != null && System.Label.Account_us_citizen_products.equalsIgnoreCase(OI?.PricebookEntry?.Product2?.Product_Type__c)){
                            orderWithUSCitizenProducts.add(newOrd.Id);
                        }
                    }
                }
                if (newOrd.opportunityId != null &&
                    oppIdHCtracker.get(newOrd.opportunityId) == null &&
                    (newOrd.Order_Status__c == 'On Hold' || oldOrd.Order_Status__c == 'On Hold') &&
                    !afterUpdateHistory.contains('updateHoldCode')) {
                    onHoldOppIds.add(newOrd.opportunityId);
                }
                if(newOrd.Related_Order_Count__c > 1 &&  String.isNotBlank(newOrd.Related_Orders__c) && ((newOrd.Est_Ship_Date__c != oldOrd.Est_Ship_Date__c)
                    || (newOrd.Deliver_By__c != oldOrd.Deliver_By__c))){
                        allOrdsLst.addall(newOrd.Related_Orders__c.trim().Split(','));
                                                                                                         }
                if (!System.isBatch() && newOrd.Type == 'Revenue' && !UtilityClass.isReplacementOrder(oldOrd) && UtilityClass.isReplacementOrder(newOrd) && newOrd.Associated_Order_Numbers__c == null) {
                    newOIList = helper.orderIdOrderItemMap.get(newOrd.Id);
                    if (!newOIList.isEmpty()) {
                        for (OrderItem oi: newOIList) {
                            if(String.isNotBlank(oi.Previous_Transaction_Reference__c) && UtilityClass.isPartialReplacementOrderItem(oi) ){ //FY25SR-1067
                                List<PreviousTransRefWrapper> wrapper = (List<PreviousTransRefWrapper>)JSON.deserialize(oi.Previous_Transaction_Reference__c, List<PreviousTransRefWrapper>.class);
                                for(PreviousTransRefWrapper wrapperInstance : wrapper){
                                    OrderItem oldOrdItem = (originalOrdItemById.containsKey(wrapperInstance.orderItemId))? originalOrdItemById.get(wrapperInstance.orderItemId) : null;
                                    Date oiExtnEndOfPaidTerms;
                                    if(oldOrdItem != null && oldOrdItem.Order_Item_Extensions__r != null && oldOrdItem.Order_Item_Extensions__r.size() > 0){
                                        oiExtnEndOfPaidTerms = oldOrdItem.Order_Item_Extensions__r[0]?.End_of_Paid_Term__c;
      }
                                    if(wrapperInstance.orderItemRemainingQuantity > 0 && oldOrdItem != null && oiExtnEndOfPaidTerms != null &&
                                       ((oi.credit_amount__c != null && oi.credit_amount__c > 0 && oldOrdItem.Support_End_Date__c == oiExtnEndOfPaidTerms) || oldOrdItem.Support_End_Date__c != oiExtnEndOfPaidTerms))
                                    {
                                      if(!quoteIdToAction.containskey(newOrd.SBQQ__Quote__c)){
                                          quoteIdToAction.put(newOrd.SBQQ__Quote__c, 'create');
                                      }
                                      if(!eligibleOrdItmForPhantOrdByQuoteId.containskey(newOrd.SBQQ__Quote__c)){
                                          eligibleOrdItmForPhantOrdByQuoteId.put(newOrd.SBQQ__Quote__c, new Set<Id>());
                                      }
                                      eligibleOrdItmForPhantOrdByQuoteId.get(newOrd.SBQQ__Quote__c).add(oi.Id);
                                    }
                                }
                            }
                        }
                    }
                }

                if (!System.isBatch() && newOrd.Type == 'Revenue' && 
                    ((!UtilityClass.isReplacementOrder(newOrd) && UtilityClass.isReplacementOrder(oldOrd)) || 
                       UtilityClass.isReplacementOrder(newOrd)) && newOrd.Associated_Order_Numbers__c != null) {
                        quoteIdToAction.put(newOrd.SBQQ__Quote__c, 'update');
                }
            }
            if(!allOrdsLst.isEmpty()){
                updateShipDates(allOrdsLst);
            }
        }

           if(!accountIdToOrderMatchMap.isEmpty()){
          System.debug(LoggingLevel.DEBUG,'### rcdmQuoteLineIdToOrderItem: ' + rcdmQuoteLineIdToOrderItem);
          updateParentRecordForRCDMTExtentionObj = new Map<Id,Quote_and_Order_Staging__c>([SELECT Id,
                                                                                           Extended_Order_Item__c,
                                                                                           Account_OM__c,
                                                                                           Order__c,
                                                                                           Process_Status_OM__c,
                                                                                           QuoteLine_Id__c,
                                                                                           Process_Type__c 
                                                                                           FROM Quote_and_Order_Staging__c where 
                                                                                           Account_OM__c IN : accountIdToOrderMatchMap.keyset()]);
          for(Quote_and_Order_Staging__c quoteOrderObj : updateParentRecordForRCDMTExtentionObj.values()){
            if(accountIdToOrderMatchMap.containskey(quoteOrderObj.Account_OM__c)){
              //if(quoteOrderObj.Process_Type__c == constants.RCDMT_EXT_INITIAL_PROCESS_TYPE)    
                quoteOrderObj.Order__c = accountIdToOrderMatchMap.get(quoteOrderObj.Account_OM__c);
              quoteOrderObj.Process_Status_OM__c  = constants.RCDMT_EXT_COMPLETED_PROCESS_STATUS ;
                
              if(rcdmQuoteLineIdToOrderItem.containskey(quoteOrderObj.QuoteLine_Id__c) && quoteOrderObj.Process_Type__c == constants.RCDMT_EXT_LOAD_DATA_PROCESS_TYPE) {
                  quoteOrderObj.Extended_Order_Item__c = rcdmQuoteLineIdToOrderItem.get(quoteOrderObj.QuoteLine_Id__c);
              }
            }
          }
      system.debug(LoggingLevel.DEBUG, '### updateParentRecordForRCDMTExtentionObj:' + updateParentRecordForRCDMTExtentionObj);
        }
        
        if(!opptyWhenCmChanged.isEmpty()){
            CMAllocation_For_Non_Aspen_Products__mdt getmeta = DemandMatrixCalculation.getNonAspenProductMetadata(null);
            opptyHistoryMap = DemandMatrixCalculation.opptyWithQuarter(opptyWhenCmChanged);
        }
    system.debug(LoggingLevel.DEBUG, 'opptyHistoryMap is #####' + opptyHistoryMap);
    if (!opptyHistoryMap.isEmpty()) {
            Set<String> allQuarters = new Set<String>();
            allQuarters.addAll(opptyHistoryMap.values());
            system.debug(LoggingLevel.DEBUG, 'allQuarters is #####' + allQuarters);
            DemandMatrixCalculation.cmaAllocationForQuarter(allQuarters);
        }

        if (OIEntMap == null) {
            OIEntMap = new Map<Id, List<Entitlement>>();
            for (Entitlement ent : [ SELECT
                                    id,
                                    AssetId,
                                    Type,
                                    startDate,
                                    EndDate,
                                    Partner_Name__c,
                                    Product__r.Gorefresh_Mark_SW_End_Date__c,
                                    Order_Service_Item__c,
                                    Order_Service_Item__r.order.Partner_Name__c,
                                    ContractLineItemId,
                                    Asset.SerialNumber,
                                    Product__r.Product_Level__c,
                                    Product__r.Edition__c,
                                    Order_Service_Item__r.Order.SBQQ__Quote__c,
                                    (SELECT Id, Asset__r.SerialNumber FROM Scale_Entitlements__r)
                                    FROM entitlement
            WHERE Order_Service_Item__r.orderId IN :Trigger.new OR AssetId IN :upgradeAssetIds OR AssetId IN : failedSerial OR Asset.SerialNumber IN :replacedFromSerialNumbers
            OR Order_Service_Item__r.Order.SBQQ__Quote__c IN :helper.quoteMap.keyset()]) {
                if(upgradeAssetIds.contains(ent.AssetId) || Trigger.newMap.containskey(ent.Order_Service_Item__r.OrderId) || helper.quoteMap.containsKey(ent.Order_Service_Item__r?.Order?.SBQQ__Quote__c)){
                if (OIEntMap.containsKey(ent.Order_Service_Item__c)) {
                    OIEntMap.get(ent.Order_Service_Item__c).add(ent);
                } else {
                    OIEntMap.put(ent.Order_Service_Item__c, new List<Entitlement>{ ent });
                    }
                }else if(failedSerial.contains(ent.AssetId)){
                    if (failedAssetWithEntitlement.containsKey(ent.AssetId)) {
                        failedAssetWithEntitlement.get(ent.AssetId).add(ent);
                    }else{
                        failedAssetWithEntitlement.put(ent.AssetId, new List<Entitlement>{ ent });
                    }
                }
                //Framing old V1 license data to create a linked asset with the new serial number in the case of a refresh (V1 → V2).
                if (UtilityClass.isV1LicenseProduct(ent?.Product__r) && replacedFromSerialNumbers.contains(ent?.Asset?.SerialNumber)) {
                    ReplacementEntSplitManager.oldV1Entitlements.put(Ent.Id, Ent);
                }
            }
        }

        system.debug(LoggingLevel.DEBUG, 'accIdRebates' + accIdRebates);

        if (queryKeys.contains('Bookings')) {
            if (accIdRebates == null)
                accIdRebates = new Map<Id, List<Rebate_Table__c>>();
            for (Rebate_Table__c rebate : [ SELECT
                                           Id,
                                           Rebate__c,
                                           ASPEN_Rebate__c,
                                           Distributor__c,
                                           Rebate_Type__c,
                                           Rebate_Deal_Type__c,
                                           Distributor__r.name,
                                           Start_Date__c,
                                           End_Date__c,
                                           Distributor_Installation_Fee__c,
                                           Value_Add_Distribution_fee__c,
                                           Installation_Product__c
                                           FROM Rebate_Table__c
                                           WHERE Distributor__c IN :helper.accountMap.keyset()]) {
                                               if (accIdRebates.containsKey(rebate.Distributor__c)) {
                                                   accIdRebates.get(rebate.Distributor__c).add(rebate);
                                               } else {
                                                   accIdRebates.put(rebate.Distributor__c, new List<Rebate_Table__c>{rebate});
                                               }
                                           }
            if (ordIdBooking == null)
                ordIdBooking = new Map<Id, Booking__c>();
                
            for (Booking__c bkg : [SELECT id, Order__c, CreatedDate,Original_Booking__r.CreatedDate ,
                             Original_Booking__r.Order__r.Order_Sub_Type__c, Gross_Bookings_Total__c,
                 Net_Bookings_Total__c, New_Expansion_TCV__c, Subsumed_Renewal_TCV__c
                                   FROM booking__c
                                   WHERE Order__c IN :Trigger.new
                                   ORDER BY CreatedDate DESC]) {
                                       if (!ordIdBooking.containsKey(bkg.Order__c))
                                           ordIdBooking.put(bkg.Order__c, bkg);
                                   }
            if (BLIimpactMap == null) {
                BLIimpactMap = new List<BLI_Impact__mdt>();
                BLIimpactMap = BLI_Impact__mdt.getAll().values(); 
            }
        }

        if (!resyncOrdIds.isEmpty()) {
            if (bookingIdBLIs == null)
                bookingIdBLIs = new Map<Id, List<Booking_Line_Item__c>>();
            if (ordIdBooking == null)
                ordIdBooking = new Map<Id, Booking__c>();
      for (Booking_Line_Item__c BLI : [
        SELECT id, Booking__c, Booking__r.id, Booking__r.Order__c, Product_Quantity__c, Booking__r.createddate, Total_Price__c, Rebate__c, Type__c, OrderProduct__r.TotalPrice, OrderProduct__r.Quantity, OrderProduct__c, New_Expansion_TCV__c, Subsumed_Renewal_TCV__c, Gross_ACV_Amount__c, Gross_New_Expansion_ACV__c, Gross_Subsumed_Renewal_ACV__c
        FROM Booking_Line_Item__c
        WHERE Booking__r.Order__c IN :resyncOrdIds
      ]) {
        if (bookingIdBLIs.containsKey(BLI.Booking__c)) {
          bookingIdBLIs.get(BLI.Booking__c).add(BLI);
        } else {
          bookingIdBLIs.put(BLI.Booking__c, new List<Booking_Line_Item__c>{ BLI });
          ordIdBooking.put(BLI.Booking__r.Order__c, BLI.Booking__r);
}
         if(BLI.Type__c == 'Revenue'){
             if(BLI.Subsumed_Renewal_TCV__c != null){
             if(!mapBKgIdToNetRenewal.containsKey(BLI.Booking__c)){
                 mapBKgIdToNetRenewal.put(BLI.Booking__c, BLI.Subsumed_Renewal_TCV__c);
             }else {
                mapBKgIdToNetRenewal.put(BLI.Booking__c, mapBKgIdToNetRenewal.get(BLI.Booking__c) +BLI.Subsumed_Renewal_TCV__c); 
             }
             }
             if(BLI.New_Expansion_TCV__c != null){
            if(!mapBKgIdToNetNew.containsKey(BLI.Booking__c)){
                 mapBKgIdToNetNew.put(BLI.Booking__c, BLI.New_Expansion_TCV__c);
             }else {
                mapBKgIdToNetNew.put(BLI.Booking__c, mapBKgIdToNetNew.get(BLI.Booking__c) + BLI.New_Expansion_TCV__c); 
             } 
             }
                                                     if(BLI.Gross_ACV_Amount__c != null){
                                                        if(!mapBKgIdToGrossACVAmt.containsKey(BLI.Booking__c)){
                                                         mapBKgIdToGrossACVAmt.put(BLI.Booking__c, BLI.Gross_ACV_Amount__c);
                                                     }else {
                                                        mapBKgIdToGrossACVAmt.put(BLI.Booking__c, mapBKgIdToGrossACVAmt.get(BLI.Booking__c) +BLI.Gross_ACV_Amount__c); 
                                                     } 
                                                     }
                                                     if(BLI.Gross_New_Expansion_ACV__c != null){
                                                     if(!mapBKgIdToGrossNewACV.containsKey(BLI.Booking__c)){
                                                         mapBKgIdToGrossNewACV.put(BLI.Booking__c, BLI.Gross_New_Expansion_ACV__c);
                                                     }else {
                                                        mapBKgIdToGrossNewACV.put(BLI.Booking__c, mapBKgIdToGrossNewACV.get(BLI.Booking__c) +BLI.Gross_New_Expansion_ACV__c); 
                                                     } 
                                                     }
                                                     
                                                     if(BLI.Gross_Subsumed_Renewal_ACV__c != null){
                                                     if(!mapBKgIdToGrossRenewalACV.containsKey(BLI.Booking__c)){
                                                         mapBKgIdToGrossRenewalACV.put(BLI.Booking__c, BLI.Gross_Subsumed_Renewal_ACV__c);
                                                     }else {
                                                        mapBKgIdToGrossRenewalACV.put(BLI.Booking__c, mapBKgIdToGrossRenewalACV.get(BLI.Booking__c) +BLI.Gross_Subsumed_Renewal_ACV__c); 
                                                     } 
                                                     }
                                                    }

                              
                                                 }
                                             }
        

        if (!RMAShippedOrdId.isEmpty()) {
            for (Id shippedOrdId : RMAShippedOrdId) {
                for (OrderItem OI : helper.orderIdOrderItemMap.get(shippedOrdId)) {
                    if (OI.RMA_Component_Type__c == 'Node') {
                        if (OI.Failed_Serial_Number__c != null) {
                            RMA_NodeSN.add(OI.Failed_Serial_Number__c);
                        }
                        if (OI.SerialNumber__c != null) {
                            newNodeAssetSN.add(OI.SerialNumber__c);
                        }
                    } else if (OI.RMA_Component_Type__c == 'Chassis') {
                        if (OI.Failed_Serial_Number__c != null)
                            RMA_ChassisSN.add(OI.Failed_Serial_Number__c);
                        if (OI.SerialNumber__c != null)
                            RMA_ChassisSN.add(OI.SerialNumber__c);
                    } else if (OI.RMA_Component_Type__c == 'PSU') {
                        if (OI.Failed_Serial_Number__c != null)
                            RMA_PSUSN.add(OI.Failed_Serial_Number__c);
                        if (OI.SerialNumber__c != null)
                            RMA_PSUSN.add(OI.SerialNumber__c);
                    } else if ( OI.RMA_Component_Type__c == 'HDD' || OI.RMA_Component_Type__c == 'SSD') {
                        if (OI.Failed_Serial_Number__c != null)
                            RMA_HDD_SSD_SN.add(OI.Failed_Serial_Number__c);
                        if (OI.SerialNumber__c != null)
                            RMA_HDD_SSD_SN.add(OI.SerialNumber__c);
                    } else if (OI.RMA_Component_Type__c == 'Memory') {
                        if (OI.Failed_Serial_Number__c != null)
                            RMA_MemorySN.add(OI.Failed_Serial_Number__c);
                        if (OI.SerialNumber__c != null)
                            RMA_MemorySN.add(OI.SerialNumber__c);
                    }
                }
            }
                if (!newNodeAssetSN.isEmpty() || !RMA_NodeSN.isEmpty()) {
                    if (serialNumNode == null)
                        serialNumNode = new Map<string, Node__c>();
                    for (Node__c node : [SELECT
                                         Id,
                                         name,
                                         asset__c,
                                         asset__r.Name,
                                         asset__r.PurchaseDate,
                                         asset__r.Support_Start_Date__c,
                                         asset__r.Premium_Support_End_Date__c,
                                         chassis__c
                                         FROM Node__c
                                         WHERE asset__r.name IN :newNodeAssetSN OR name IN :RMA_NodeSN]) {
                                             serialNumNode.put(node.name, node);
                                             if (assetNodesSN.containskey(node.asset__r.Name)) {
                                                 assetNodesSN.get(node.asset__r.Name).add(node.name);
                                             } else {
                                                 assetNodesSN.put(node.asset__r.Name, new List<String>{ node.name });
                                             }
                                         }
                }
                if (!RMA_ChassisSN.isEmpty()) {
                    if (serialNumChassis == null)
                        serialNumChassis = new Map<string, Chassis__c>();
                    for (Chassis__c chasis : [SELECT
                                              Name,
                                              serial_number__c,
                                              asset__c,
                                              asset__r.PurchaseDate,
                                              asset__r.Support_Start_Date__c,
                                              asset__r.Premium_Support_End_Date__c
                                              FROM Chassis__c
                                              WHERE serial_number__c IN :RMA_ChassisSN]) {
                                                  serialNumChassis.put(chasis.serial_number__c, chasis);
                                              }
                }
                if (!RMA_PSUSN.isEmpty()) {
                    if (serialNumPSU == null)
                        serialNumPSU = new Map<string, Power_Supply__c>();
                    for (Power_Supply__c PSU : [SELECT
                                                Id,
                                                Name,
                                                asset__c,
                                                revision__c,
                                                asset__r.PurchaseDate,
                                                serial_number__c,
                                                part_number__c,
                                                asset__r.Support_Start_Date__c,
                                                asset__r.Premium_Support_End_Date__c
                                                FROM Power_Supply__c
                                                WHERE serial_number__c IN :RMA_PSUSN]) {
                                                    serialNumPSU.put(PSU.serial_number__c, PSU);
                                                }
                }
                if (!RMA_HDD_SSD_SN.isEmpty()) {
                    if (serialNumHDDSSD == null)
                        serialNumHDDSSD = new Map<string, Drive__c>();
                    for (Drive__c drive : [SELECT
                                           Id,
                                           serial_number__c,
                                           Name,
                                           node__c,
                                           asset__c,
                                           asset__r.PurchaseDate,
                                           asset__r.Support_Start_Date__c,
                                           asset__r.Premium_Support_End_Date__c,
                                           type__c,
                                           capacity__c
                                           FROM Drive__c
                                           WHERE serial_number__c IN :RMA_HDD_SSD_SN]) {
                                               serialNumHDDSSD.put(drive.serial_number__c, drive);
                                           }
                }
                if (!RMA_MemorySN.isEmpty()) {
                    if (serialNumMemory == null)
                        serialNumMemory = new Map<string, Memory__c>();
                    for (Memory__c memory : [SELECT
                                             id,
                                             serial_number__c,
                                             Name,
                                             asset__c,
                                             asset__r.PurchaseDate,
                                             asset__r.Support_Start_Date__c,
                                             asset__r.Premium_Support_End_Date__c,
                                             node__c
                                             FROM Memory__c
                                             WHERE serial_number__c IN :RMA_MemorySN]) {
                                                 serialNumMemory.put(memory.serial_number__c, memory);
                                             }
                }
            }
        if (!onHoldOppIds.isEmpty()) {
            for (Hold_Off_Tracking__c HC : [SELECT id, Related_Opportunity__c, Hold_Code__c
                                            FROM Hold_Off_Tracking__c
                                            WHERE Related_Opportunity__c IN :onHoldOppIds AND Is_Released__c = FALSE]) {
                                                if (oppIdHCtracker.containsKey(HC.Related_Opportunity__c)) {
                                                    oppIdHCtracker.get(HC.Related_Opportunity__c).put(HC.Hold_Code__c, HC);
                                                } else {
                                                    oppIdHCtracker.put(HC.Related_Opportunity__c, new Map<string, Hold_Off_Tracking__c>{ HC.Hold_Code__c => HC });
                                                }
                                            }
        }
        if (!ShippedPrimaryConId.isEmpty()) {
            for (User usr : [SELECT id, contactId FROM user WHERE contactId IN :ShippedPrimaryConId]) {
                portalConUserMap.put(usr.contactId, usr);
            }
        }

        System.debug(LoggingLevel.DEBUG, 'oppIdHCtracker' + oppIdHCtracker);
        System.debug(LoggingLevel.DEBUG, 'portalConUserMap' + portalConUserMap);
        System.debug(LoggingLevel.DEBUG, 'assetNodesSN' + assetNodesSN);
        System.debug(LoggingLevel.DEBUG, 'ordIdBooking' + ordIdBooking);
        System.debug(LoggingLevel.DEBUG, 'OIEntMap' + OIEntMap);

        Map<Id, Opportunity> mapOpps ;
        if(!TransactionalDataCollection.oppMainList.isEmpty()) {
            mapOpps = new Map<Id, Opportunity>(TransactionalDataCollection.oppMainList);
        }

        for (Order newOrd : (List<order>) Trigger.new) {
            Set<String> POAcceptedStatus = new set<String>{'Order Accepted', 'Order Accepted - 855 Sent'}; //PRDOPS23-376
            Order oldOrd = (Order) Trigger.oldMap?.get(newOrd.id);
            newOIList = helper.orderIdOrderItemMap.get(newOrd.Id);
            Opportunity opp = newOrd.Type == 'POC'? helper.oppMap?.get(newOrd.POC_Opportunity__c): helper.oppMap?.get(newOrd.OpportunityId);
            Account acc = helper.accountMap?.get(newOrd.accountId);
            System.debug(LoggingLevel.INFO, 'newOrd: ' + JSON.Serialize(newOrd));
            System.debug(LoggingLevel.INFO, 'opp: ' + opp);
            System.debug(LoggingLevel.INFO, 'acc: ' + acc);
            //RWD-157 Changes

            //PRDOPS23-13 - start
            Integer intOrder = 0;
            if(mapOpps != null && !mapOpps.isEmpty()){
               intOrder =  mapOpps.containskey(newOrd.OpportunityId) && !mapOpps.get(newOrd.OpportunityId).Orders.isEmpty() ? mapOpps.get(newOrd.OpportunityId).Orders.size() : 0;
            }
            updateHelper.processAfterUpdate(newOrd, oldOrd, oppToUpdate, intOrder);


            if ( newOrd.Order_Status__c != null && newOrd.Order_Status__c != oldOrd.Order_Status__c) {
                if (newOrd.Order_Status__c == 'Order Accepted' &&!afterUpdateHistory.contains('Order Accepted')) {
                        if(neword.Type != 'POC'){
            updateHelper.ProcessAcceptedOrders( newOrd,
                                                       newOIList,
                                                       OIEntMap,
                                                       EntToInsert,
                                                       oppToUpdate);
            }       
                    if (newOrd.Stage_PO__c != null && !newOIList.isEmpty() && !POAcceptedStatus.contains(newOIList[0].Order.Stage_PO__r.PO_Validation_Status__c)) {
                        updateHelper.UpdateStagePO(newOrd, POStgToUpdate);
                    }
                    if (newOrd.Is_Refreshed_Credit_SKU_Eligibility__c && !newOrd.Account_Is_Refreshed_Check__c) {
                        helper.updateAccount(newOrd, 'Update GoRefresh Flag', accToUpdate);
                    }
                    if(newOrd.Order_Sub_Type__c == Constants.ORDER_SUB_TYPE_GC_ONDEMAND) {
                      acceptedGCOnDemandOrderIds.add(newOrd.Id);
                    }
                    if((acc?.U_S_citizen_service__c == null) || !(acc?.U_S_citizen_service__c?.split(';').contains('Purchased'))){
                        helper.updateUSCitizenFieldOnAccount(newOrd, accToUpdate, orderWithUSCitizenProducts,acc);
                    }
                    afterUpdateHistoryLocal.add('Order Accepted');
                } else if (newOrd.Order_Status__c == 'Shipped' && oldOrd.Order_Status__c != 'Shipped' && !afterUpdateHistory.contains('Shipped')) {
                    if (neword.Type == 'POC') {
                        updateHelper.ProcessAcceptedOrders(newOrd, newOIList, OIEntMap, EntToInsert, oppToUpdate);
                    }    
                    updateHelper.processOrderItem( newOrd,
                                                  newOIList,
                                                  OIEntMap,
                                                  serialNumAsset,
                                                  EntToInsert,
                                                  EntToUpdate,
                                                  assetToUpsert,
                                                  orderItemToUpdate);
                    
                    if (!portalConUserMap.containsKey(newOrd.Welcome_Letter_Contact__c) && OrderHasRSCProduct.contains(newOrd.id)) {
                        CreatePortalUserOrderIds.add(newOrd.id);
                    }
                    if (newOrd.Type == 'RMA') {
                        updateHelper.RMAProcessShippedOrders(
                                                             newOrd,
                                                             newOIList,
                                                             serialNumAsset,
                                                             assetNodesSN,
                                                             serialNumNode,
                                                             serialNumChassis,
                                                             serialNumPSU,
                                                             serialNumHDDSSD,
                                                             serialNumMemory,
                                                             assetToUpsert,
                                                             nodeToUpdate,
                                                             chasisToInsert,
                                                             PSUToInsert,
                                                             HDDSSDToInsert,
                                                             memoryToInsert,
                                                             failedAssetWithEntitlement,
                                                             EntToUpdate
                                                            );
                    }
            if(orderWhenCmChanged.contains(newOrd.Id)){
            List<OrderItem> OIListForCma = new List<OrderItem>();
            OIListForCma = helper.orderIdOrderItemMap.get(newOrd.Id);

            updateHelper.updateCma(newOrd, oldOrd, OIListForCma);
          }
                    if((acc?.U_S_citizen_service__c == null) || !(acc?.U_S_citizen_service__c?.split(';').contains('Purchased'))){
                        helper.updateUSCitizenFieldOnAccount(newOrd, accToUpdate, orderWithUSCitizenProducts,acc);
            }
                    afterUpdateHistoryLocal.add('Shipped');
                } else if ( newOrd.Order_Status__c == 'Rejected' && !afterUpdateHistory.contains('Rejected')) {
                    if (newOrd.Stage_PO__c != null)
                        updateHelper.UpdateStagePO(newOrd, POStgToUpdate);
                     Id bookingId = ordIdBooking?.get(newOrd.id)?.id;
                     if (bookingId != null && bookingIdBLIs != null && bookingIdBLIs.get(bookingId) != null){
            updateHelper.ResyncBooking(newOrd,bookingIdBLIs.get(bookingId),bookingId,BookingToUpdate,BLIToUpdate,BLIToInsert,newOIList, mapBKgIdToNetRenewal, mapBKgIdToNetNew, mapBKgIdToGrossACVAmt, mapBKgIdToGrossNewACV, mapBKgIdToGrossRenewalACV);
                         afterUpdateHistoryLocal.add('Rebate');
                      }
                 }
             }
            if(newOrd.Type == 'Revenue'  && (newOrd.SBQQ__PriceCalcStatus__c == 'Queued' || oldOrd.SBQQ__PriceCalcStatus__c == 'Queued') && newOrd.SBQQ__PriceCalcStatus__c != oldOrd.SBQQ__PriceCalcStatus__c  && !afterUpdateHistory.contains('Rebate')){
                Id bookingId = ordIdBooking?.get(newOrd.id)?.id;
                if (bookingId != null && bookingIdBLIs != null && bookingIdBLIs.get(bookingId) != null){
            updateHelper.ResyncBooking(newOrd,bookingIdBLIs.get(bookingId),bookingId,BookingToUpdate,BLIToUpdate,BLIToInsert,newOIList, mapBKgIdToNetRenewal, mapBKgIdToNetNew, mapBKgIdToGrossACVAmt, mapBKgIdToGrossNewACV, mapBKgIdToGrossRenewalACV);
                    afterUpdateHistoryLocal.add('Rebate');
                }
            }
            if ( (newOrd.Type == 'Revenue'|| newOrd.Type == 'Booking Adjustment') &&
                newOrd.BookingStatus__c == 'Booking Created' &&
                newOrd.BookingStatus__c != oldOrd.BookingStatus__c &&
                ordIdBooking != null &&
                ordIdBooking.containsKey(newOrd.id) &&
                opp != null &&
                !afterUpdateHistory.contains('Rebate')) {
                    set<Rebate_Table__c> rebList = new Set<Rebate_Table__c>();

                    if (accIdRebates.get(newOrd.Bill_To_Name__c) != null)
                        rebList.addall(accIdRebates.get(newOrd.Bill_To_Name__c));
                    if (accIdRebates.get(opp.AccountId) != null)
                        rebList.addall(accIdRebates.get(opp.AccountId));
                    rebList.remove(null);
                    if (!rebList.isEmpty()) {
                        if(!newOIList.isEmpty()){
                            for(OrderItem objOI : newOIList){
                                if(objOI.Order.Type == 'Revenue'){
                                    Decimal qtyFactor =  (objOI.Opportunity_Product__c != null && objOI.Quantity != null && objOI.Quantity != 0.0) ? objOI.Quantity/objOI.Opportunity_Product__r.Quantity : 1;
                                    Decimal newTCV = null;
                                    Decimal renewalTCV = null;
                                    Decimal grossACV = null;
                                    Decimal grossNewACV = null;
                                    Decimal grossRenewalACV = null;
                                    
                                    if(objOI.Opportunity_Product__c != null){
                                        newTCV = objOI.Opportunity_Product__r?.New_Expansion_TCV__c == null ? 0.0 :(objOI.Opportunity_Product__r?.New_Expansion_TCV__c * qtyFactor) ;
                                        renewalTCV = objOI.Opportunity_Product__r?.Subsumed_Renewal_TCV__c == null ? 0.0 :(objOI.Opportunity_Product__r?.Subsumed_Renewal_TCV__c * qtyFactor) ; 
                                        grossACV = objOI.Opportunity_Product__r?.ACV_Amount__c == null ? 0.0 :(objOI.Opportunity_Product__r?.ACV_Amount__c * qtyFactor) ;
                                        grossNewACV = objOI.Opportunity_Product__r?.New_Expansion_ACV__c == null ? 0.0 :(objOI.Opportunity_Product__r?.New_Expansion_ACV__c * qtyFactor) ;
                                        grossRenewalACV = objOI.Opportunity_Product__r?.Subsumed_Renewal_Amount__c == null ? 0.0 :(objOI.Opportunity_Product__r?.Subsumed_Renewal_Amount__c * qtyFactor) ;  
                                    }  
                                    if(newTCV != null){
                                        if(!mapBKgIdToNetNew.containsKey(ordIdBooking.get(objOI.OrderId).Id)){
                                            mapBKgIdToNetNew.put(ordIdBooking.get(objOI.OrderId).Id, newTCV);
                                        }else {
                                            mapBKgIdToNetNew.put(ordIdBooking.get(objOI.OrderId).Id, mapBKgIdToNetNew.get(ordIdBooking.get(objOI.OrderId).Id) + newTCV); 
                                         }
                                    }
                                    if(renewalTCV != null){
                                        if(!mapBKgIdToNetRenewal.containsKey(ordIdBooking.get(objOI.OrderId).Id)){
                                            mapBKgIdToNetRenewal.put(ordIdBooking.get(objOI.OrderId).Id, renewalTCV);
                                        }else {
                                            mapBKgIdToNetRenewal.put(ordIdBooking.get(objOI.OrderId).Id, mapBKgIdToNetRenewal.get(ordIdBooking.get(objOI.OrderId).Id) + renewalTCV); 
                                         }
                                    }
                                    if(grossACV != null){
                                        if(!mapBKgIdToGrossACVAmt.containsKey(ordIdBooking.get(objOI.OrderId).Id)){
                                            mapBKgIdToGrossACVAmt.put(ordIdBooking.get(objOI.OrderId).Id, grossACV);
                                        }else {
                                            mapBKgIdToGrossACVAmt.put(ordIdBooking.get(objOI.OrderId).Id, mapBKgIdToGrossACVAmt.get(ordIdBooking.get(objOI.OrderId).Id) + grossACV); 
                                        } 
                                    }
                                    if(grossNewACV != null){
                                        if(!mapBKgIdToGrossNewACV.containsKey(ordIdBooking.get(objOI.OrderId).Id)){
                                            mapBKgIdToGrossNewACV.put(ordIdBooking.get(objOI.OrderId).Id, grossNewACV);
                                        }else {
                                            mapBKgIdToGrossNewACV.put(ordIdBooking.get(objOI.OrderId).Id, mapBKgIdToGrossNewACV.get(ordIdBooking.get(objOI.OrderId).Id) +grossNewACV); 
                                        } 
                                    }
                                    if(grossRenewalACV != null){
                                        if(!mapBKgIdToGrossRenewalACV.containsKey(ordIdBooking.get(objOI.OrderId).Id)){
                                            mapBKgIdToGrossRenewalACV.put(ordIdBooking.get(objOI.OrderId).Id, grossRenewalACV);
                                        }else {
                                            mapBKgIdToGrossRenewalACV.put(ordIdBooking.get(objOI.OrderId).Id, mapBKgIdToGrossRenewalACV.get(ordIdBooking.get(objOI.OrderId).Id) + grossRenewalACV); 
                                        } 
                                    }
                                    
                                }
                            }
            if (!newOIList.isEmpty() && newOIList[0]?.Order?.Type != null && newOIList[0]?.Order?.Type == 'Booking Adjustment') {
              system.debug(LoggingLevel.DEBUG, '::test::' + ordIdBooking.get(newOIList[0].OrderId).Id);
                                mapBKgIdToNetNew.put(ordIdBooking.get(newOIList[0].OrderId).Id, newOIList[0].Order.Opportunity.New_Expansion_TCV__c);
                              mapBKgIdToNetRenewal.put(ordIdBooking.get(newOIList[0].OrderId).Id, newOIList[0].Order.Opportunity.Subsumed_Renewal_TCV__c);
                              mapBKgIdToGrossACVAmt.put(ordIdBooking.get(newOIList[0].OrderId).Id, newOIList[0].Order.Opportunity.ACV_Amount__c);
                                      mapBKgIdToGrossNewACV.put(ordIdBooking.get(newOIList[0].OrderId).Id, newOIList[0].Order.Opportunity.New_Expansion_ACV__c);
                                      mapBKgIdToGrossRenewalACV.put(ordIdBooking.get(newOIList[0].OrderId).Id, newOIList[0].Order.Opportunity.Renewal_Subsumed_ACV__c);
                            }
                            
                        }
                        updateHelper.RebateCalculation(newOrd,
                                                       ordIdBooking.get(newOrd.id),
                                                       newOIList,
                                                       rebList,
                                                       opp,
                                                       BLIimpactMap,
                                                       BLIToInsert,
                                                      mapBKgIdToNetRenewal,
                                                      mapBKgIdToNetNew,
                                                      mapBKgIdToGrossACVAmt, 
                                                      mapBKgIdToGrossNewACV, 
                                                       mapBKgIdToGrossRenewalACV);
        }
                    afterUpdateHistoryLocal.add('Rebate');
                }
            if (newOrd.Sync_to_NetSuite__c &&
                oldOrd.Sync_to_NetSuite__c == false &&
                acc != null &&
                acc.Sync_to_NetSuite__c == false &&
                !afterUpdateHistory.contains('AccSync') && 
                !enablePushBasedOrderSync) {

                    helper.updateAccount(newOrd, 'Update NetSuit Flag', accToUpdate);
                    afterUpdateHistoryLocal.add('AccSync');
                }
            if(newOrd.RSC_G_Enabled__c  &&  acc != null &&
                acc.RSC_G_Eligible__c && (acc.RSC_G_Support__c == null ? True : !acc.RSC_G_Support__c.split(';').contains('RSC-G'))){
                Account mapAcc = accToUpdate != null && accToUpdate.get(newOrd.AccountId) != null ? accToUpdate.get(newOrd.AccountId): new Account(id = newOrd.AccountId);
                mapAcc.RSC_G_Support__c = acc.RSC_G_Support__c;
                accToUpdate.put(mapAcc.Id,mapAcc);

                helper.updateAccount(newOrd, 'Update RSC-G Support Flag', accToUpdate);
                }
            if ( isHoldOffLogicDisabled == false &&
                newOrd.opportunityId != null &&
                (newOrd.Hold_Code__c != oldOrd.Hold_Code__c ||
                 helper.ORIGIN_CONTEXT == 'Insert') &&
                (newOrd.Order_Status__c == 'On Hold' ||
                 oldOrd.Order_Status__c == 'On Hold') &&
                !afterUpdateHistory.contains('updateHoldCode')) {

                    updateHelper.UpdateHoldCodeTracker( newOrd,
                                                       oldOrd,
                                                       oppIdHCtracker.get(newOrd.opportunityId),
                                                       holdCodeTrackToInsert,
                                                       holdCodeTrackToUpdate,
                                                       oppToUpdate);
                    afterUpdateHistoryLocal.add('updateHoldCode');
                }
            if (newOrd.PS_Project__c != null &&
                oldOrd.PS_Project__c == null &&
                !newOIList.isEmpty() &&
                !afterUpdateHistory.contains('PSTask')) {

                    updateHelper.createPSTask(newOrd,
                                              newOIList,
                                              psTaskToInsert,
                                              orderItemToUpdate);
                    afterUpdateHistoryLocal.add('PSTask');
                }
                //added for PRDOPS22_209 sending  email for Multiple Hold Codes
                if(newOrd.Order_Status__c == 'On Hold'  && newOrd.Hold_Code__c!=null && newOrd.Hold_Code__c != oldOrd.Hold_Code__c  &&  newOrd.Hold_Code__c.contains(';')
                &&((oldOrd.Hold_Code__c != null  && newOrd.Hold_Code__c.length() > oldOrd.Hold_Code__c.length() )||(oldOrd.Hold_Code__c == null ))){
                    UpdatedOrderIds.add(newOrd.Id);
                }

                if(UpdatedOrderIds.size() > 0){
                    helper.SendEmailforMultipleHoldCodes(UpdatedOrderIds);
                }
                   if((newOrd.Order_Status__c != oldOrd.Order_Status__c && newOrd.Order_Status__c =='On Hold') && String.isNotBlank(newOrd.Hold_Code__c) && (newOrd.Hold_Code__c=='Missing start or end dates' || newOrd.Hold_Code__c=='Missing serial number' || newOrd.Hold_Code__c == 'Missing List / Extended Price')){
                    salesopsOrdIDs.add(newOrd.id);
                }
        if(newOrd.SD_Status__c == 'Start'  && newOrd.SD_Status__c!= oldOrd.SD_Status__c && newOIList!= null && !newOIList.isEmpty()
           && !TransactionalDataCollection.ordIdHWItems.isEmpty() && !TransactionalDataCollection.ordIdHWItems.get(newOrd.id).isEmpty() && quoteSDProdQuant.containsKey(newOrd.SBQQ__Quote__c)
            && !afterUpdateHistory.contains('HWDetails')){
             updateHelper.UpdateHardwareInfo(newOrd,newOIList,TransactionalDataCollection.ordIdHWItems.get(newOrd.id),quoteSDProdQuant.get(newOrd.SBQQ__Quote__c),orderItemToUpdate,
                                              scaleEntToInsert,assetToUpsert,serialNumAsset,OIEntMap,EntToUpdate);
            afterUpdateHistory.add('HWDetails');
            if(!isSerialNumUpdated){
              isSerialNumUpdated = true;
            }
        }
        if(newOrd.Ready_for_Gov_Sync__c == 'Sync Ready' && oldOrd.Ready_for_Gov_Sync__c != 'Sync Ready'){
            orderReadyTosyncwithGovOrg.add(newOrd.Id); 
        }
        }
        if(!orderReadyTosyncwithGovOrg.isEmpty() && !afterUpdateHistory.contains('GovSyncCalled')){
            UtilityClass.publishGovOrgSyncEvents(orderReadyTosyncwithGovOrg, 'Order');
            afterUpdateHistoryLocal.add('GovSyncCalled');
        }
        if(salesopsOrdIDs.size() >0){
            system.debug(LoggingLevel.DEBUG,'Calling SendEmailforSalesOps');
            helper.SendEmailResOwnerSalesOps(salesopsOrdIDs);
         }
        if (!OIEntMap.isEmpty()) {
            updateHelper.updateEntitlementsPartner(OIEntMap.values(), EntToUpdate);
        }
        afterUpdateHistory.addall(afterUpdateHistoryLocal);
        system.debug(LoggingLevel.INFO, 'afterUpdateHistory' + afterUpdateHistory);
        if (!syncToNsEvents.isEmpty()) {
            Orderinserthelper.firingEventWhenSyncToNSIsTrue(syncToNsEvents);
        }  
OrderTriggerService.handleRSCInstanceCreation((List<order>) Trigger.new, (Map<Id,Order>) Trigger.oldMap); //FY26WL-117
        updateHelper.CommitAfterUpdateRecords(
            EntToInsert,
            BLIToInsert,
            BLIToUpdate,
            holdCodeTrackToInsert,
            holdCodeTrackToUpdate,
            EntToUpdate,
            BookingToUpdate,
            oppToUpdate,
            accToUpdate,
            POStgToUpdate,
            psTaskToInsert,
            CreatePortalUserOrderIds,
            nodeToUpdate,
            assetToUpsert,
            chasisToInsert,
            PSUToInsert,
            HDDSSDToInsert,
            memoryToInsert,
            orderItemToUpdate,
            TransactionalDataCollection.ordIdHWItems,
            scaleEntToInsert,
            quoteSDProdQuant,
            cmaToUpsertNew,
            acceptedGCOnDemandOrderIds,
            TransactionalDataCollection.quoteIdHWItems,
            quoteIdToAction,
			lstErrorLogs,
            updateParentRecordForRCDMTExtentionObj,
            isSerialNumUpdated,
            eligibleOrdItmForPhantOrdByQuoteId
        );

        for (Order newOrd : (List<order>) Trigger.new) {
            Order oldOrd = (Order) Trigger.oldMap?.get(newOrd.id);
    /**
    * CSU-473 : Here we are Executing SplitOrderBatch If Order_Split_Type__c is of TYPE GC Offer Amendment
    */
       if ((oldOrd.Order_Split_Type__c != newOrd.Order_Split_Type__c &&
    (newOrd.Order_Split_Type__c == 'EDI' || 
    newOrd.Order_Split_Type__c == 'Non-EDI' || 
    newOrd.Order_Split_Type__c == 'Netapp' || 
    newOrd.Order_Split_Type__c == Constants.ORDER_SPLIT_TYPE_GC_OFFER_AMENDMENT))) {
    OrderUpdateHelper.executeSplitOrderBatch();
    break;
    }
        }
        OrderUpdateHelper.updatePOCProductsOnOppty((List<Order>)Trigger.new,  (Map<id,Order>)Trigger.oldMap);
        /* Calling trackFieldsHistory method of CustomHistoryTracker class to track the hitsory of fields defined in the Field Set */
        Order_control__mdt DisableCustomHistoryTracker = Order_control__mdt.getInstance('Disable_Order_Custom_History_Tracker');
        
        if(!CustomHistoryTracker.recurssionHandlerSobjectSet.contains('Order') && DisableCustomHistoryTracker?.Value__c != null  && !boolean.valueOf(DisableCustomHistoryTracker?.Value__c) && !isDisabledOrderTracking){ 
            CustomHistoryTracker.trackFieldsHistory(trigger.new, Trigger.oldMap, 'Order__c');
        }
    //PRDOPS26-701
    helper.processAfterUpdate((List<Order>)Trigger.new, (Map<Id,Order>)Trigger.oldMap);
    }
}