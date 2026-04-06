/**
 * @description Asynchronous processor for entitlement generation operations that implements Queueable interface.
 *              This class handles the end-to-end process of entitlement creation and management, including:
 *                1. Generation of multiple entitlement types (PhoneSuport, Manufacturing, POC etc)
 *                2. Association of contacts with entitlements
 *                3. Order stage transitions through the SC_or_Entitlement_Stage__c field
 *                4. Dynamic calculation and adjustment of entitlement dates based on business rules
 *              The class is designed to be executed as an asynchronous job and called from the ContractOrders batch to
 *              handle the overall ent generation process
 * @author      ProdOps
 * @date        [Creation/Last Modified Date]
 *              [2024-10-04/2025-04-14]
 *
 * Updates
 * 2025-04-14 | [Sonal Agrawal(Bluvium)] | [PRDOPS26-282] | [Automatically add 'Polaris' + Primary Contact + RSC Contact to MFG Entitlements]
 */
public class CustomEntitlementGenerationQueueable implements Queueable {
  private Queueable nextJob;
  private String operationType;
  private set<Id> processedMFG_OI = new Set<Id>();
  private List<Order> successOrders;
  private List<Order> ordersToProcess = new List<Order>();
  private List<Entitlement> entitlementsToInsert = new List<Entitlement>();
  private List<Entitlement> entitlementToUpdate = new List<Entitlement>();
  private Map<Id, List<OrderItem>> orderItemsByOrderId = new Map<Id, List<OrderItem>>();
  private Map<Id, List<Entitlement>> entitlementsByOrderItemId = new Map<Id, List<Entitlement>>();
  private Map<String, Asset> assetBySerialNumber = new Map<String, Asset>();
  private Map<Id, Order> ordersToUpdateById = new Map<Id, Order>();
  private Map<id, Order> orderByOrderItemId = new Map<id, Order>();

  public static Map<String, SCorEntitlementStageMapping> serviceContractEntStageMap = new Map<String, SCorEntitlementStageMapping>{
    //New Records mapping
    Constants.SC_ENT_STAGE_CREATE_CUSTOM_ENT => new SCorEntitlementStageMapping(Constants.SC_ENT_STAGE_CUSTOM_ENT_CREATED, Constants.SC_ENT_STAGE_CUSTOM_ENT_CREATION_FAILED),
    Constants.SC_ENT_STAGE_EXTEND_POC_ENT => new SCorEntitlementStageMapping(Constants.SC_ENT_STAGE_POC_EXTENDED, Constants.SC_ENT_STAGE_POC_EXTENSION_FAILED),
    Constants.SC_ENT_STAGE_CREATE_MANUFACTURING_ENT => new SCorEntitlementStageMapping(
      Constants.SC_ENT_STAGE_MANUFACTURING_ENT_CREATED,
      Constants.SC_ENT_STAGE_MANUFACTURING_ENT_CREATION_FAILED
    ),
    Constants.SC_ENT_STAGE_CREATE_SERVICE_CONTRACT => new SCorEntitlementStageMapping(Constants.SC_ENT_STAGE_SC_CREATION_SUCCESSFUL, Constants.SC_ENT_STAGE_SC_CREATION_FAILED),
    Constants.SC_ENT_STAGE_CREATE_POC_ENT => new SCorEntitlementStageMapping(Constants.SC_ENT_STAGE_POC_ENT_CREATED, Constants.SC_ENT_STAGE_POC_ENT_CREATION_FAILED),
    //Failed Records mapping
    Constants.SC_ENT_STAGE_CUSTOM_ENT_CREATION_FAILED => new SCorEntitlementStageMapping(
      Constants.SC_ENT_STAGE_CUSTOM_ENT_CREATED,
      Constants.SC_ENT_STAGE_CUSTOM_ENT_CREATION_FAILED
    ),
    Constants.SC_ENT_STAGE_POC_EXTENSION_FAILED => new SCorEntitlementStageMapping(Constants.SC_ENT_STAGE_POC_EXTENDED, Constants.SC_ENT_STAGE_POC_EXTENSION_FAILED),
    Constants.SC_ENT_STAGE_MANUFACTURING_ENT_CREATION_FAILED => new SCorEntitlementStageMapping(
      Constants.SC_ENT_STAGE_MANUFACTURING_ENT_CREATED,
      Constants.SC_ENT_STAGE_MANUFACTURING_ENT_CREATION_FAILED
    ),
    Constants.SC_ENT_STAGE_SC_CREATION_FAILED => new SCorEntitlementStageMapping(Constants.SC_ENT_STAGE_SC_CREATION_SUCCESSFUL, Constants.SC_ENT_STAGE_SC_CREATION_FAILED),
    Constants.SC_ENT_STAGE_POC_ENT_CREATION_FAILED => new SCorEntitlementStageMapping(Constants.SC_ENT_STAGE_POC_ENT_CREATED, Constants.SC_ENT_STAGE_POC_ENT_CREATION_FAILED)
  };

  /**
   * @description : Constructor for the CustomEntitlementGenerationQueueable class.
   *                Initializes the class with the given success orders, operation type, and the next queueable job to be executed.
   *
   * @param successOrders A list of Order records
   * @param operationType A string that indicates the type of operation to be performed.
   * @param nextJob The next queueable job to be executed after the current job completes.
   */
  public CustomEntitlementGenerationQueueable(List<Order> successOrders, String operationType, Queueable nextJob) {
    this.successOrders = successOrders;
    this.operationType = operationType;
    this.nextJob = nextJob;
  }

  /**
   * @description :Executes the custom entitlement generation logic asynchronously.
   * This method is called when the queueable job is executed.
   *
   * @param qc The context for this queueable job
   */
  public void execute(QueueableContext qc) {
    try {
      Set<String> operationTypeSet = new Set<String>(operationType.split(';'));

      Set<String> pocExtensionStageIntersections = new Set<String>(Constants.POC_EXTENSION_STAGES);
      pocExtensionStageIntersections.retainAll(operationTypeSet);

      Set<String> entitlementCreationStageIntersections = new Set<String>(Constants.CUSTOM_ENTITLEMENT_CREATION_STAGES);
      entitlementCreationStageIntersections.retainAll(operationTypeSet);

      if (!pocExtensionStageIntersections.isEmpty()) {
        updatePOCExtensionDate();
      }
      if (!entitlementCreationStageIntersections.isEmpty()) {
        collectRecordsToProcess();
        createCustomEntitlement();
      }
      commitRecords();
    } catch (Exception e) {
      updateFailedOrders();

      List<Error_Logs__c> errorLogsInsert = new List<Error_Logs__c>();

      errorLogsInsert.add(
        UtilityClass.createlogExceptionRecord(
          e,
          'ContractOrders: CustomEntitlementGenerationHelper',
          'CustomEntitlementGenerationHelper',
          'Entitlement',
          successOrders[0].Id,
          null,
          false,
          ''
        )
      );

      if (!errorLogsInsert.isEmpty()) {
        insert errorLogsInsert;
      }
    }
    if (this.nextJob != null && !Test.isRunningTest()) {
      System.enqueueJob(this.nextJob);
    }
  }

  /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : Commits records to the database
   */
  public void commitRecords() {
    if (!entitlementsToInsert.isEmpty()) {
      system.debug(LoggingLevel.DEBUG, '### entitlementsToInsert:' + entitlementsToInsert);
      insert entitlementsToInsert;
      if (!orderByOrderItemId.isEmpty()) {
        Set<EntitlementContact> entContactToInsert = new Set<EntitlementContact>();
        for (Entitlement entitlement : entitlementsToInsert) {
          if (entitlement.Type == 'Manufacturing Entitlement') {
            Order relatedOrder = orderByOrderItemId.get(entitlement.Order_Service_Item__c);
            if (relatedOrder != null) {
              entContactToInsert.addAll(addEntitlementContacts(entitlement, relatedOrder));
            }
          }
        }

        if (!entContactToInsert.isEmpty()) {
          insert new List<EntitlementContact>(entContactToInsert);
        }
      }
    }
    if (!entitlementToUpdate.isEmpty()) {
      update entitlementToUpdate;
    }
    if (!ordersToUpdateById.Values().isEmpty()) {
      update ordersToUpdateById.values();
    }
  }

  /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description * Creates EntitlementContact records for a Manufacturing Entitlement.
   *
   * This method generates EntitlementContact records based on the Entitlement and its related Order:
   *
   * 1. If the Entitlement has a Primary Contact ('Primary_Contact__c'), it links this Contact to the Entitlement.
   * 2. If the Entitlement is TPH-MFG-ENT, it create entitlment Contact with default "Polaris Contact" from metadata.
   * 3. If the related Order has a RCA contact ('Polaris_Contact__c'), it links this Contact to the Entitlement.
   *
   * @return The method returns a Set of EntitlementContact records created under these conditions.
   * @param entitlement The Entitlement record for which EntitlementContact will be created.
   * @param order The Order record associated with the Entitlement.
   */
  private Set<EntitlementContact> addEntitlementContacts(Entitlement entitlement, Order order) {
    Set<EntitlementContact> entContactToInsert = new Set<EntitlementContact>();
    if (String.isNotBlank(entitlement.Primary_Contact__c)) {
      entContactToInsert.add(new EntitlementContact(EntitlementId = entitlement.Id, ContactId = entitlement.Primary_Contact__c));
    }
    if (entitlement.Product__c == Order_control__mdt.getInstance('Manufacturing_Entitlement_Product').Value__c) {
      entContactToInsert.add(new EntitlementContact(EntitlementId = entitlement.Id, ContactId = Order_control__mdt.getInstance('Polaris_Contact').Value__c));
    }
    if (String.isNotBlank(order.Polaris_Contact__c)) {
      entContactToInsert.add(new EntitlementContact(EntitlementId = entitlement.Id, ContactId = order.Polaris_Contact__c));
    }

    return entContactToInsert;
  }

  /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : Update SC or ENT Stage on the Order
   */
  public void updateFailedOrders() {
    List<Order> failedOrdersUpdate = new List<Order>();
    for (Order failedOrd : successOrders) {
      String existingStages = failedOrd.SC_or_Entitlement_Stage__c;
      List<String> stages = existingStages.split(';'); // Split the multi-picklist values

      for (String stage : stages) {
        if (!serviceContractEntStageMap.containsKey(stage))
          continue;
        String failureMessage = serviceContractEntStageMap.get(stage).failureMessage;
        if (existingStages.contains(stage)) {
          existingStages.replace(stage, failureMessage);
        }
      }
      failedOrdersUpdate.add(new Order(Id = failedOrd.Id, SC_or_Entitlement_Stage__c = existingStages));
    }
    if (!failedOrdersUpdate.isEmpty()) {
      update failedOrdersUpdate;
    }
  }

  /**
   * @description :The method also updates the Order's stage based on whether the extension is approved or not.
   */
  public void updatePOCExtensionDate() {
    for (Entitlement ent : [
      SELECT
        Id,
        EndDate,
        Order_Service_Item__r.Order.POC_Request__r.New_Expected_End_Date__c,
        Order_Service_Item__r.Order.Id,
        Order_Service_Item__r.Order.SC_or_Entitlement_Stage__c
      FROM Entitlement
      WHERE
        Order_Service_Item__r.Order.POC_Request__r.Approval_Status__c = 'Extension Approved'
        AND Order_Service_Item__r.Order.POC_Request__r.New_Expected_End_Date__c != NULL
        AND Order_Service_Item__r.OrderId IN :successOrders
    ]) {
      ent.EndDate = ent.Order_Service_Item__r.Order.POC_Request__r.New_Expected_End_Date__c;
      entitlementToUpdate.add(ent);

      String currentEntitlementStage = ent.Order_Service_Item__r.Order?.SC_or_Entitlement_Stage__c.contains(Constants.SC_ENT_STAGE_EXTEND_POC_ENT)
        ? Constants.SC_ENT_STAGE_EXTEND_POC_ENT
        : Constants.SC_ENT_STAGE_POC_EXTENSION_FAILED;
      updateOrderStage(ent.Order_Service_Item__r.Order, currentEntitlementStage);
    }
  }

  /**
   * @description :Collect necessarry records to process
   */
  private void collectRecordsToProcess() {
    ordersToProcess = [
      SELECT
        Id,
        Type,
        Partner_Name__c,
        Integration_Partner_Contact_Name__c,
        Manufacturing_Integration_Partner__c,
        Welcome_Letter_Contact__c,
        Actual_Order_Ship_Date__c,
        POC_Completion_Date__c,
        Order_Sub_Type__c,
        AccountId,
        Name,
        EffectiveDate,
        Status,
        BillToContactId,
        SC_or_Entitlement_Stage__c,
        POC_Type__c,
        Polaris_Contact__c,
        (
          SELECT
            Id,
            Create_Entitlement__c,
            Product2Id,
            Product2.Entitlement_Conversion_Non_CPQ__c,
            Product2.SBQQSC__EntitlementConversion__c,
            Product2.SBQQ__SubscriptionPricing__c,
            Product2.ProductCode,
            Product2.Family,
            Product2.Product_Type__c,
            Product2.Product_Level__c,
            Product2.Product_Subtype__c,
            Product2.License_Category__c,
            Product2.MSP_Std_Actual__c,
            Product2.Bundle_Features__c,
            Quantity,
            SBQQ__RequiredBy__c,
            SBQQ__RequiredBy__r.SerialNumber__c,
            Support_Start_Date__c,
            Support_End_Date__c,
            TPH_Quantity__c,
            SerialNumber__c,
            Trade_Up_SerialNumber__c,
            Failed_Serial_Number__c,
            UnitPrice,
            TotalPrice,
            SBQQ__SegmentIndex__c
          FROM OrderItems
        )
      FROM Order
      WHERE Id IN :successOrders
    ];

    // Process each order and its related order items
    for (Order order : ordersToProcess) {
      for (OrderItem OI : order.OrderItems) {
        if (orderItemsByOrderId.containsKey(order.Id)) {
          orderItemsByOrderId.get(order.Id).add(OI);
        } else {
          orderItemsByOrderId.put(order.Id, new List<OrderItem>{ OI });
        }

        // Process serial numbers and map them
        if (String.isNotBlank(OI.SerialNumber__c)) {
          for (String SN : OI.SerialNumber__c.replaceAll('\\s+', '').split(',')) {
            assetBySerialNumber.put(SN, null);
          }
        }
        if (String.isNotBlank(OI.Trade_Up_SerialNumber__c)) {
          for (String tradeUpSerialNumber : OI.Trade_Up_SerialNumber__c.replaceAll('\\s+', '').split(',')) {
            assetBySerialNumber.put(tradeUpSerialNumber, null);
          }
        }
        if (String.isNotBlank(OI.Failed_Serial_Number__c)) {
          assetBySerialNumber.put(OI.Failed_Serial_Number__c, null);
        }
      }
    }

    for (Asset asst : [SELECT Id, SerialNumber FROM Asset WHERE SerialNumber IN :assetBySerialNumber.keySet()]) {
      assetBySerialNumber.put(asst.SerialNumber, asst);
    }

    // Fetch existing entitlements for the orders
    for (Entitlement ent : [
      SELECT
        Id,
        AssetId,
        Type,
        StartDate,
        EndDate,
        Partner_Name__c,
        Product__r.Gorefresh_Mark_SW_End_Date__c,
        Order_Service_Item__c,
        Order_Service_Item__r.Order.Partner_Name__c,
        ContractLineItemId,
        Status,
        IsDeleted
      FROM Entitlement
      WHERE Order_Service_Item__r.OrderId IN :successOrders
    ]) {
      if (entitlementsByOrderItemId.containsKey(ent.Order_Service_Item__c)) {
        entitlementsByOrderItemId.get(ent.Order_Service_Item__c).add(ent);
      } else {
        entitlementsByOrderItemId.put(ent.Order_Service_Item__c, new List<Entitlement>{ ent });
      }
    }
  }

  /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : Main method to handle custom entitlement generation
   */
  public void createCustomEntitlement() {
    for (Order order : ordersToProcess) {
      List<OrderItem> orderItems = orderItemsByOrderId?.get(order.Id);
      if (orderItems == null)
        continue;

      for (OrderItem orderItem : orderItems) {
        Boolean isEntitlementCreationNeeded = false;
        Boolean isManufacturingEntitlementPresent = false;

        if (orderItem.Create_Entitlement__c || (order.Type == 'POC' && orderItem.Product2.SBQQ__SubscriptionPricing__c != null)) {
          isEntitlementCreationNeeded = true;
        }

        if (entitlementsByOrderItemId.containsKey(orderItem.Id)) {
          for (Entitlement entitlement : entitlementsByOrderItemId.get(orderItem.Id)) {
            // Check if non-manufacturing entitlement is already present
            if (entitlement.Type != Constants.ENT_TYPE_MANUFACTURING_ENTITLEMENT) {
              isEntitlementCreationNeeded = false;
            }
            // Check if manufacturing entitlement is already present
            if (entitlement.Type == Constants.ENT_TYPE_MANUFACTURING_ENTITLEMENT) {
              isManufacturingEntitlementPresent = true;
            }
            // Early exit if both conditions are false
            if (!isEntitlementCreationNeeded && !isManufacturingEntitlementPresent) {
              break;
            }
          }
        }

        if (isEntitlementCreationNeeded) {
          processEntitlement(order, orderItem);
        }

        if (!isManufacturingEntitlementPresent) {
          processManufacturingEntitlement(order, orderItem);
        }
      }
    }
  }

  // Processes the entitlement based on the rules
  private void processEntitlement(Order order, OrderItem orderItem) {
    String entitlementType = getEntitlementType(order);
    String type = getType(order);

    if (isOnePerQuoteLine(orderItem)) {
      entitlementsToInsert.add(createEntitlement(order, orderItem, type, entitlementType, null));
    } else if (isOnePerUnit(orderItem)) {
      entitlementsToInsert.addAll(createEntitlementsForOnePerUnit(order, orderItem, type, entitlementType));
    }
  }

  // Processes the Manufacturing entitlement
  private void processManufacturingEntitlement(Order order, OrderItem orderItem) {
    if (isLicenseOrderItem(order, orderItem)) {
      String manufacturingEntitlementType = Constants.ENT_TYPE_MANUFACTURING_ENTITLEMENT;
      entitlementsToInsert.add(createEntitlement(Order, orderItem, manufacturingEntitlementType, manufacturingEntitlementType, null));
      processedMFG_OI.add(orderItem.id);
    }
  }

  private Boolean isLicenseOrderItem(Order ord, OrderItem oi) {
    if (processedMFG_OI.contains(oi.Id)) {
      return false;
    }

    String productType = oi.Product2.Product_Type__c;
    String productFamily = oi.Product2.Family;
    String productLevel = oi.Product2.Product_Level__c;
    String productSubtype = oi.Product2.Product_Subtype__c;
    String orderSubType = ord.Order_Sub_Type__c;

    Set<String> v1ProductTypes = new Set<String>{ Constants.RSC_ENTERPRISE_PRODUCT_TYPE, Constants.RSC_BUSINESS_PRODUCT_TYPE, Constants.PRODUCT_TYPE_RCDM };
    Set<String> v2ProductTypes = new Set<String>{ Constants.RSC_ENTERPRISE_PRODUCT_TYPE, Constants.RSC_BUSINESS_PRODUCT_TYPE, Constants.RSC_FOUNDATION_PRODUCT_TYPE };

    Boolean isV1Logic = String.isBlank(productLevel) && productFamily == Constants.PROD_FAMILY_RUBRIK_SCALE && v1ProductTypes.contains(productType);

    Boolean isV2Logic =
      productLevel == Constants.RSC_HYBRID_PRODUCT_LEVEL &&
      productFamily == Constants.PROD_FAMILY_RUBRIK_SCALE &&
      productSubtype != Constants.PROD_SUB_TYPE_SCALE_MSP &&
      v2ProductTypes.contains(productType);

    Boolean isRCDM =
      (productType == Constants.PRODUCT_TYPE_RCDM ||
      productLevel == Constants.RSC_HYBRID_PRODUCT_LEVEL ||
      ((productLevel == Constants.RSC_ONPREM_PRODUCT_LEVEL || String.isBlank(productLevel)) &&
      v2ProductTypes.contains(productType) &&
      productSubtype == null)) && productFamily == Constants.PROD_FAMILY_RUBRIK_SCALE;

    Boolean isThirdPartyLicense = productFamily == Constants.PROD_FAMILY_THIRD_PARTY_LICENSE;

    Boolean isMspCondition =
      productType == Constants.PROD_PRODUCT_TYPE_MSP &&
      productFamily == Constants.PRODUCT_TYPE_RCDM &&
      oi.SBQQ__SegmentIndex__c == 1 &&
      oi.Product2.MSP_Std_Actual__c != Constants.PROD_MSP_STD_ACTUAL_MSP_ACTUAL_OVERAGE;

    Boolean isGCOffer =
      orderSubType == Constants.ORDER_SUB_TYPE_GC_OFFER &&
      productSubtype == Constants.PROD_SUB_TYPE_SCALE_MSP &&
      String.isBlank(oi.Product2.License_Category__c) &&
      !oi.Product2.Bundle_Features__c.containsIgnoreCase(Constants.PROD_BUNDLE_FEATURES_M365H);

    return (((productType == Constants.PROD_Product_Type_THIRD_PARTY_HARDWARE && Constants.THIRD_PARTY_HARDWARE.contains(productFamily)) ||
      isV1Logic ||
      isV2Logic ||
      isRCDM ||
      isThirdPartyLicense ||
      isMspCondition) && orderSubType != Constants.ORDER_SUB_TYPE_GC_OFFER) || isGCOffer;
  }

  // Checks if entitlement should be created per quote line
  private Boolean isOnePerQuoteLine(OrderItem orderItem) {
    return (orderItem.Product2.Entitlement_Conversion_Non_CPQ__c != null &&
      orderItem.Product2.Entitlement_Conversion_Non_CPQ__c.equalsIgnoreCase(Constants.PROD_ENTCON_ONE_PER_QUOTELINE)) ||
      (orderItem.Product2.SBQQSC__EntitlementConversion__c != null &&
      orderItem.Product2.SBQQSC__EntitlementConversion__c.equalsIgnoreCase(Constants.PROD_ENTCON_ONE_PER_QUOTELINE));
  }

  // Checks if entitlement should be created per unit
  private Boolean isOnePerUnit(OrderItem orderItem) {
    return (orderItem.Product2.Entitlement_Conversion_Non_CPQ__c != null &&
      orderItem.Product2.Entitlement_Conversion_Non_CPQ__c.equalsIgnoreCase(Constants.PROD_ENTCON_ONE_PER_UNIT)) ||
      (orderItem.Product2.SBQQSC__EntitlementConversion__c != null && orderItem.Product2.SBQQSC__EntitlementConversion__c.equalsIgnoreCase(Constants.PROD_ENTCON_ONE_PER_UNIT)) &&
      orderItem.Quantity != null;
  }

  // Gets the entitlement type based on the order
  private String getType(Order order) {
    return order.Type == Constants.ORDER_TYPE_POC ? 'POC Entitlement' : 'Custom Entitlement';
  }

  private String getEntitlementType(Order order) {
    if (order.Type != 'POC' || String.isBlank(order.POC_Type__c)) {
      return null;
    }
    return 'Evaluation';
  }

  // Creates entitlements for 'One per unit' rule
  private List<Entitlement> createEntitlementsForOnePerUnit(Order order, OrderItem orderItem, String Type, String entitlementType) {
    List<Entitlement> entitlements = new List<Entitlement>();
    List<String> serialNumbers = getSerialNumbers(orderItem);

    for (Integer i = 0; i < orderItem.Quantity; i++) {
      Id assetId = serialNumbers.size() > i && assetBySerialNumber?.containsKey(serialNumbers[i]) ? assetBySerialNumber?.get(serialNumbers[i])?.Id : null;
      entitlements.add(createEntitlement(order, orderItem, Type, entitlementType, assetId));
    }
    return entitlements;
  }

  // Retrieves serial numbers from the order item
  private List<String> getSerialNumbers(OrderItem orderItem) {
    if (orderItem.SBQQ__RequiredBy__c != null && orderItem.SBQQ__RequiredBy__r.SerialNumber__c != null) {
      return orderItem.SBQQ__RequiredBy__r.SerialNumber__c.replaceAll('\\s+', '').split(',');
    }
    return new List<String>();
  }

  // Creates an entitlement record
  private Entitlement createEntitlement(Order order, OrderItem orderItem, String type, String entitlementType, Id assetId) {
    String currentEntitlementStage;
    Entitlement entitlement = new Entitlement(
      AccountId = Order.AccountId,
      Product__c = orderItem.Product2Id,
      Name = orderItem.Product2.ProductCode,
      Order_Service_Item__c = orderItem.Id,
      Partner_Name__c = order.Partner_Name__c,
      AssetId = assetId,
      Type = entitlementType,
      RecordTypeId = Constants.ENT_RECORDTYPEID_SUPPORT
    );

    if (type == Constants.ENT_TYPE_MANUFACTURING_ENTITLEMENT) {
      orderByOrderItemId.put(orderItem.Id, order);
      String productId = Order_control__mdt.getInstance('Manufacturing_Entitlement_Product')?.Value__c;
      entitlement.Integration_Partner_Contact_Name__c = order.Integration_Partner_Contact_Name__c;
      entitlement.Manufacturing_Integration_Partner__c = order.Manufacturing_Integration_Partner__c;
      entitlement.Primary_Contact__c = order.Welcome_Letter_Contact__c;
      entitlement.Product__c = productId;
      entitlement.RecordTypeId = Constants.ENT_RECORDTYPEID_MANUFACTURING;
      if (order.Type == Constants.ORDER_TYPE_POC) {
        entitlement.StartDate = order.Actual_Order_Ship_Date__c;
        entitlement.EndDate = order.POC_Completion_Date__c;
      } else {
        entitlement.StartDate = orderItem?.Support_Start_Date__c != null ? orderItem.Support_Start_Date__c : null;
        entitlement.EndDate = orderItem?.Support_End_Date__c != null ? orderItem.Support_End_Date__c : null;
      }
      currentEntitlementStage = order?.SC_or_Entitlement_Stage__c != null && order?.SC_or_Entitlement_Stage__c.contains(Constants.SC_ENT_STAGE_CREATE_MANUFACTURING_ENT)
        ? Constants.SC_ENT_STAGE_CREATE_MANUFACTURING_ENT
        : Constants.SC_ENT_STAGE_MANUFACTURING_ENT_CREATION_FAILED;
    } else if (type == 'Custom Entitlement' && Constants.PRODUCT_TYPE_TRAINING.equalsIgnoreCase(orderItem.Product2.Product_Type__c)) {
      entitlement.StartDate = system.today();
      entitlement.EndDate = system.today().addYears(1); // SF-7762
      entitlement.AssetId = assetId;
      currentEntitlementStage = order?.SC_or_Entitlement_Stage__c != null && order?.SC_or_Entitlement_Stage__c.contains(Constants.SC_ENT_STAGE_CREATE_CUSTOM_ENT)
        ? Constants.SC_ENT_STAGE_CREATE_CUSTOM_ENT
        : Constants.SC_ENT_STAGE_CUSTOM_ENT_CREATION_FAILED;
    } else if (type == 'POC Entitlement') {
      entitlement.StartDate = order.Order_sub_type__c == Constants.ORDER_SUBTYPE_TRY_N_BUY ? orderItem.Support_Start_Date__c : order.Actual_Order_Ship_Date__c;
      entitlement.EndDate = order.Order_sub_type__c == Constants.ORDER_SUBTYPE_TRY_N_BUY ? orderItem.Support_End_Date__c : order?.POC_Completion_Date__c?.addDays(7);
      entitlement.Type = entitlementType;
      entitlement.AssetId = assetId;
      currentEntitlementStage = order?.SC_or_Entitlement_Stage__c != null && order?.SC_or_Entitlement_Stage__c.contains(Constants.SC_ENT_STAGE_CREATE_POC_ENT)
        ? Constants.SC_ENT_STAGE_CREATE_POC_ENT
        : Constants.SC_ENT_STAGE_POC_ENT_CREATION_FAILED;
    }
    updateOrderStage(order, currentEntitlementStage);

    return entitlement;
  }

  private void updateOrderStage(Order order, String stageKey) {
    String existingSCorENTStage = order?.SC_or_Entitlement_Stage__c;
    system.debug(LoggingLevel.DEBUG, '### existingSCorENTStage:' + existingSCorENTStage);
    system.debug(LoggingLevel.DEBUG, '### stageKey:' + stageKey);
    if (String.isNotBlank(existingSCorENTStage) && stageKey != null && existingSCorENTStage.contains(stageKey)) {
      String updatedSCorENTStage = existingSCorENTStage.replace(stageKey, serviceContractEntStageMap.get(stageKey).successMessage);
      ordersToUpdateById.put(order.Id, new Order(Id = order.Id, SC_or_Entitlement_Stage__c = updatedSCorENTStage));
    }
  }

  /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : This class is used to store success and failure messages related to entitlement stage transitions.
   */
  public class SCorEntitlementStageMapping {
    public String successMessage;
    public String failureMessage;

    /**
     * @description :Constructor to initialize the success and failure messages.
     *
     * @param success The message to be displayed when the entitlement stage is successfully processed.
     * @param failure The message to be displayed when the entitlement stage processing fails.
     */
    SCorEntitlementStageMapping(String success, String failure) {
      this.successMessage = success;
      this.failureMessage = failure;
    }
  }
}