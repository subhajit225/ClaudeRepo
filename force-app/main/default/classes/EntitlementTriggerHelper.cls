/**************************************************************************************************
 * @description       : Order Trigger helper logic
 * @author            :
 * @last modified on  : 10-04-25
 * @last modified by  : shrutika
 * Modifications Log
 * Ver   Date          Author        Modification
 * 1.0   10-04-25   Shrutika        formatting and PMD rule
 ******************************************************************************/
public without sharing class EntitlementTriggerHelper {
  static final Decimal NUMBER_ASSET = 1;
  static final String ASSET_STATUS_PURCHASED = 'Purchased';
  private static Map<Id, OrderItem> orderItemMap = new Map<Id, OrderItem>();
  public static Map<Id, ContractLineItem> entitlementCLIById = new Map<Id, ContractLineItem>();
  public static Map<Id, OrderItem> entitlementOIById = new Map<Id, OrderItem>();
  // Bulk-safe index for Exit ACV selection: latest Support_End_Date__c OrderItem by OrderId+ProductCode
  private static Map<String, OrderItem> exitACVMap = new Map<String, OrderItem>();
  // Map Entitlement OI Id -> composed key (OrderId+ProductCode)
  private static Map<Id, String> oiKeyById = new Map<Id, String>();

  //CPQ22-6425 Common grouping cache per OrderId+ProductCode for ACV special subtypes
    private class SpecialCalcGroup {
    Date minStart; // Support_Start_Date__c minimum
    Date maxEnd;   // Support_End_Date__c maximum
    Integer lineCount = 0;
    Decimal totalPriceSum = 0;
  }
  private static Map<String, SpecialCalcGroup> specialCalcByKey = new Map<String, SpecialCalcGroup>();


  /**
   * @author
   * @description init method
   */
  public static void entitlementTriggerHelperInit() {
    Set<Id> cliIds = new Set<Id>();
    Set<Id> oiIds = new Set<Id>();
    Set<Id> orderIds = new Set<Id>();

      for (Entitlement newENT : (List<Entitlement>) Trigger.new) {
      if (newENT.ContractLineItemId != null && !entitlementCLIById.containsKey(newENT.ContractLineItemId)) {
          cliIds.add(newENT.ContractLineItemId);
        }
      if (newENT.Order_Service_Item__c != null && !entitlementOIById.containsKey(newENT.Order_Service_Item__c)) {
          oiIds.add(newENT.Order_Service_Item__c);
        }
      }

    if (!cliIds.isEmpty()) {
      for (ContractLineItem cli : [
          SELECT
            Id,
            Quantity,
            Storage_Region_Bundle__c,
            SBQQSC__OrderProduct__r.Quantity,
            SBQQSC__OrderProduct__r.Product2.SBQQSC__EntitlementConversion__c,
            SBQQSC__OrderProduct__r.Product2.Entitlement_Conversion_Non_CPQ__c,
            SBQQSC__OrderProduct__r.Product2.Product_Subtype__c,
            SBQQSC__OrderProduct__r.OrderId
          FROM ContractLineItem
          WHERE Id IN :cliIds
      ]) {
        entitlementCLIById.put(cli.Id, cli);
        if(cli.SBQQSC__OrderProduct__r != null && cli.SBQQSC__OrderProduct__r.OrderId != null) {
          orderIds.add(cli.SBQQSC__OrderProduct__r.OrderId);
        }
      }
    }

    if (!oiIds.isEmpty()) {
      for (OrderItem oi : [
          SELECT Id, Quantity, Product2.SBQQSC__EntitlementConversion__c, Product2.Category__c, Product2.Product_Type__c, OrderId, Order.Order_Sub_Type__c,
                Product2.ProductCode, Support_Start_Date__c, Support_End_Date__c, TotalPrice,
                SBQQ__QuoteLine__r.RAMP_EXIT_ACV__c, //SAL26-1359
                SBQQ__QuoteLine__r.ACV__c, //CPQ22-6126
                SBQQ__QuoteLine__r.SBQQ__NetTotal__c,
                SBQQ__QuoteLine__r.SBQQ__SubscriptionTerm__c,
                SBQQ__QuoteLine__r.SBQQ__Quantity__c,
                SBQQ__QuoteLine__r.Prepayment_Credit__c,
                SBQQ__QuoteLine__r.SBQQ__Product__r.Product_Type__c,
                SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r.Opportunity_Sub_Type__c,
                SBQQ__RequiredBy__c,
                SBQQ__RequiredBy__r.EndDate
          FROM OrderItem
          WHERE Id IN :oiIds or OrderId IN :orderIds
      ]) {
        entitlementOIById.put(oi.Id, oi);
        // Build key and update exitACVMap in a single pass
        if (oi.OrderId != null && oi.Product2 != null && String.isNotBlank(oi.Product2.ProductCode)) {
          String key = String.valueOf(oi.OrderId) + String.valueOf(oi.Product2.ProductCode);
          oiKeyById.put(oi.Id, key);
          if (!exitACVMap.containsKey(key)) {
            exitACVMap.put(key, oi);
          } else if (exitACVMap.get(key) != null) {
            Date existingEnd = exitACVMap.get(key).Support_End_Date__c;
            if (existingEnd == null || (oi.Support_End_Date__c != null && oi.Support_End_Date__c > existingEnd)) {
              exitACVMap.put(key, oi);
            }
          }

          //CPQ22-6425 Build common ACV grouping cache (min start, max end, count, sum price)
          SpecialCalcGroup grp = specialCalcByKey.containsKey(key) ? specialCalcByKey.get(key) : new SpecialCalcGroup();
          Date st = (Date) oi.get('Support_Start_Date__c');
          if (st != null && (grp.minStart == null || st < grp.minStart)) grp.minStart = st;
          if (oi.Support_End_Date__c != null && (grp.maxEnd == null || oi.Support_End_Date__c > grp.maxEnd)) grp.maxEnd = oi.Support_End_Date__c;
          if (oi.TotalPrice != null) grp.totalPriceSum += oi.TotalPrice;
          grp.lineCount++;
          specialCalcByKey.put(key, grp);

        }
      }
    }
  }
  /**
   * @author
   * @description Populate Prior Entitlement CPQ22-452
   * @param entIds
   */
  //Populate Prior Entitlement CPQ22-452
  @future
  public static void populatePriorEntitlement(List<Id> entIds) {
    System.debug(LoggingLevel.DEBUG, 'Inside populatePriorEntitlement');
    List<Entitlement> entList = new List<Entitlement>();
    List<Entitlement> InitialCLIEnt = new List<Entitlement>();
    List<Entitlement> toUpdateList = new List<Entitlement>();
    List<Entitlement> recordsToUpdateList = new List<Entitlement>();
    set<Id> CLIEntToBeFilled = new Set<Id>();
    set<Id> assignedEnt = new Set<Id>();
    Map<Id, List<Entitlement>> InitialCLIEntMap = new Map<Id, List<Entitlement>>();

    entList = [SELECT Id, PriorCLIId__c, AssetId, ContractLineItemId, ContractLineItem.Quantity, isAssigned__c FROM Entitlement WHERE Id IN :entIds];

    for (Entitlement et : entList) {
      if (et.PriorCLIId__c != null) {
        CLIEntToBeFilled.add(et.PriorCLIId__c);
      }
    }

    if (!CLIEntToBeFilled.isEmpty()) {
      InitialCLIEnt = [
        SELECT
          Id,
          Name,
          AssetId,
          ContractLineItemId,
          ContractLineItem.Quantity,
          isAssigned__c,
          ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__Product__r.SBQQSC__EntitlementConversion__c
        FROM Entitlement
        WHERE ContractLineItemId IN :CLIEntToBeFilled
      ];
      for (Entitlement obj : InitialCLIEnt) {
        if (InitialCLIEntMap.containsKey(obj.ContractLineItemId)) {
          List<Entitlement> PreEntList = InitialCLIEntMap.get(obj.ContractLineItemId);
          PreEntList.add(obj);
          InitialCLIEntMap.put(obj.ContractLineItemId, PreEntList);
        } else {
          List<Entitlement> InEntList = new List<Entitlement>();
          InEntList.add(obj);
          InitialCLIEntMap.put(obj.ContractLineItemId, InEntList);
        }
      }

      for (Entitlement ent : entList) {
        if (InitialCLIEntMap.containsKey(ent.PriorCLIId__c)) {
          for (Entitlement entL : InitialCLIEntMap.get(ent.PriorCLIId__c)) {
            if (entL.ContractLineItem.Quantity > 1 && entL.AssetId != null) {
              if (entL.AssetId == ent.AssetId) {
                ent.Prior_Entitlement__c = entL.Id;
                recordsToUpdateList.add(ent);
              }
            } else if (entL.ContractLineItem.Quantity > 1 && entL.AssetId == null) {
              if (entL.ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__Product__r.SBQQSC__EntitlementConversion__c == 'One per unit') {
                if (entL.isAssigned__c == false) {
                  ent.Prior_Entitlement__c = entL.Id;
                  entL.isAssigned__c = true;
                  toUpdateList.add(entL);
                  recordsToUpdateList.add(ent);
                  break;
                }
              } else if (entL.ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__Product__r.SBQQSC__EntitlementConversion__c == 'One per quote line') {
                ent.Prior_Entitlement__c = entL.Id;
                recordsToUpdateList.add(ent);
              }
            } else {
              ent.Prior_Entitlement__c = entL.Id;
              recordsToUpdateList.add(ent);
            }
          }
        }
      }

      if (!toUpdateList.isEmpty()) {
        update toUpdateList;
      }
      if (!recordsToUpdateList.isEmpty()) {
        update recordsToUpdateList;
      }
    }
  }

  //EL-237
  /**
   * @author
   * @date 2024-08-05
   * @description This method updates partner name on change JIRA: EL-237
   * @param updatedEntitlements
   * @param oldMap
   */
  public static void updatePartnerNameOnChange(List<Entitlement> updatedEntitlements, Map<Id, Entitlement> oldMap) {
    if (updatedEntitlements == null) {
      return;
    }
    Map<Id, Id> ordPartnerMap = new Map<Id, Id>();
    Map<Id, Id> ordMSPEndUserMap = new Map<Id, Id>();
    Set<Id> updatedEntOrderIds = new Set<Id>();

    for (Entitlement ent : updatedEntitlements) {
      if(ent.type == 'Phone Support')
        ent.Entitlement_Usage__c = null;
      if (!orderItemMap.containsKey(ent.Order_Service_Item__c)) {
        updatedEntOrderIds.add(ent.Order_Service_Item__c);
      }
    }
    if (!updatedEntOrderIds.isEmpty()) {
      for (OrderItem ord : [SELECT id, Order.Opportunity.MSP_End_User_Lookup__c, Order.Partner_Name__c, OrderId FROM OrderItem WHERE Id IN :updatedEntOrderIds]) {
        ordPartnerMap.put(ord.OrderId, ord.Order.Partner_Name__c);
        if (!ordMSPEndUserMap.containskey(ord.OrderId) && ord.OrderId != null && ord.order.OpportunityId != null && ord.order.Opportunity.MSP_End_User_Lookup__c != null) {
          ordMSPEndUserMap.put(ord.OrderId, ord.order.Opportunity.MSP_End_User_Lookup__c);
        }
        orderItemMap.put(ord.Id, ord);
      }
    }

    for (Entitlement ent : updatedEntitlements) {
      Entitlement oldEnt;
      if (Trigger.isUpdate) {
        oldEnt = oldMap.get(ent.Id);
      }
      if (
        oldEnt != null &&
        oldEnt.Partner_Name__c != ent.Partner_Name__c && ent.Order_Service_Item__c != null && orderItemMap.containsKey(ent.Order_Service_Item__c) && ordPartnerMap.containsKey(orderItemMap.get(ent.Order_Service_Item__c).OrderId)
      ) {
        ent.Partner_Name__c = ordPartnerMap.get(orderItemMap.get(ent.Order_Service_Item__c).OrderId); //EL-237
      }
      if (
        ent.Order_Service_Item__c != null &&
        orderItemMap.containsKey(ent.Order_Service_Item__c) &&
        ordMSPEndUserMap.containsKey(orderItemMap.get(ent.Order_Service_Item__c).OrderId)
      ) {
        ent.MSP_End_User_Lookup__c = ordMSPEndUserMap.get(orderItemMap.get(ent.Order_Service_Item__c).OrderId);
      }
    }
  }
  /**
   * @author Ravi
   * @date 2024-08-05
   * @description Update Partner name on insertion
   * @param updatedEntitlements
   */
  public static void updatePartnerNameOnInsert(List<Entitlement> updatedEntitlements) {
    Map<Id, Id> ordPartnerMap = new Map<Id, Id>();
    Map<Id, Id> ordMSPEndUserMap = new Map<Id, Id>();
    Set<Id> updatedEntOrderIds = new Set<Id>();

    for (Entitlement ent : updatedEntitlements) {
      if (Trigger.isUpdate) {
        updatedEntOrderIds.add(ent.Order_Service_Item__c);
      }
    }

    if (!updatedEntOrderIds.isEmpty()) {
      for (OrderItem ord : [SELECT id, Order.Opportunity.MSP_End_User_Lookup__c, Order.Partner_Name__c, OrderId FROM OrderItem WHERE Id IN :updatedEntOrderIds]) {
        ordPartnerMap.put(ord.OrderId, ord.Order.Partner_Name__c);
        if (!ordMSPEndUserMap.containskey(ord.OrderId) && ord.OrderId != null && ord.order.OpportunityId != null && ord.order.Opportunity.MSP_End_User_Lookup__c != null) {
          ordMSPEndUserMap.put(ord.OrderId, ord.order.Opportunity.MSP_End_User_Lookup__c);
        }
        orderItemMap.put(ord.Id, ord);
      }
    }

    for (Entitlement ent : updatedEntitlements) {
      if (
        ent.Order_Service_Item__c != null &&
        orderItemMap.containsKey(ent.Order_Service_Item__c) &&
        ordPartnerMap.containsKey(orderItemMap.get(ent.Order_Service_Item__c).OrderId)
      ) {
        ent.Partner_Name__c = ordPartnerMap.get(orderItemMap.get(ent.Order_Service_Item__c).OrderId); //EL-237
      }
      if (
        ent.Order_Service_Item__c != null &&
        orderItemMap.containsKey(ent.Order_Service_Item__c) &&
        ordMSPEndUserMap.containsKey(orderItemMap.get(ent.Order_Service_Item__c).OrderId)
      ) {
        ent.MSP_End_User_Lookup__c = ordMSPEndUserMap.get(orderItemMap.get(ent.Order_Service_Item__c).OrderId);
      }
    }
  }
  /**
   * @description Update AssetId
   * @param entitlementList
   **/
  public static void updateAssetId(List<Entitlement> entitlementList) {
    if (entitlementList == null) {
      return;
    }
    Set<Id> productIds = new Set<Id>();
    for (Entitlement ent : entitlementList) {
      if (ent.Product__c != null) {
        productIds.add(ent.Product__c);
      }
    }
    Map<Id, Product2> productsMap;
    if (!productIds.isEmpty()) {
      productsMap = new Map<Id, Product2>([SELECT Id, SBQQSC__EntitlementConversion__c, Product_Level__c, Product_Subtype__c FROM Product2 WHERE Id IN :productIds]);
    }
    for (Entitlement ent : entitlementList) {
      if (
        ent.Product__c != null &&
        ent.AssetId != null &&
        productsMap != null &&
        productsMap.containsKey(ent.Product__c) &&
        'One per quote line'.equalsIgnoreCase(productsMap.get(ent.Product__c).SBQQSC__EntitlementConversion__c) && (productsMap.get(ent.Product__c).Product_Level__c == 'Hybrid Software' || productsMap.get(ent.Product__c).Product_Level__c == 'LOD Software' || (productsMap.get(ent.Product__c).Product_Level__c == 'OnPrem' &&
        (productsMap.get(ent.Product__c).Product_Subtype__c == 'LOD Addon' ||
        productsMap.get(ent.Product__c).Product_Subtype__c == 'OnPrem LOD Addon')))
      ) {
        //Modification End PRODOPS25-199
        ent.AssetId = null;
      }
    }
  }

  private static Boolean isEligibleForRubrikSupport(Entitlement newENT, OrderItem entOI) {
    return entOI != null &&
      newENT.Order_Service_Item__c != null &&
      newENT.ContractLineItemId != null &&
      newENT.StartDate != null &&
      newENT.EndDate != null &&
      newENT.Type == Constants.ENT_TYPE_PHONE_SUPPORT &&
      newENT.SubType__c != Constants.ENT_SUBTYPE_RUBRIK_SUPPORT &&
      entOI.Product2.Category__c != Constants.PROD_CATEGORY_PROFESSIONAL_SERVICES &&
      entOI.Product2.Product_Type__c != Constants.PRODUCT_TYPE_TRAINING;
  }

  /**
   * @author Ravi
   * @date 2024-08-05
   * @description This method populates the fields on Before Insert JIRA: PRDOPS25-724
   */
  public static void populateFieldsOnUpsert() {
    for (Entitlement newENT : (List<Entitlement>) Trigger.new) {
      OrderItem entOI = (newENT.Order_Service_Item__c != null) && entitlementOIById.containsKey(newENT.Order_Service_Item__c)
        ? entitlementOIById.get(newENT.Order_Service_Item__c)
        : null;
      if (isEligibleForRubrikSupport(newENT, entOI)) {
        newENT.SubType__c = Constants.ENT_SUBTYPE_RUBRIK_SUPPORT;
      }
      if (Trigger.isInsert || (Trigger.isUpdate && newENT.Quantity__c == null)) {
        ContractLineItem entCli = (newENT.ContractLineItemId != null) && entitlementCLIById.containsKey(newENT.ContractLineItemId)
          ? entitlementCLIById.get(newENT.ContractLineItemId)
          : null;

        if (entOI != null) {
          if (newENT.Type == Constants.ENT_TYPE_PHONE_SUPPORT) {
            OrderItem cliOI = (entCli != null) ? entCli.SBQQSC__OrderProduct__r : null;

            if (
              cliOI != null &&
              (Constants.PROD_ENTCON_ONE_PER_UNIT.equalsIgnoreCase(cliOI.Product2?.SBQQSC__EntitlementConversion__c) ||
              Constants.PROD_SUBTYPE_GO_CNV.equals(cliOI.Product2?.Product_Subtype__c))
            ) {
              newENT.Quantity__c = 1;
            } else {
              newENT.Quantity__c = (entCli != null && entCli.Quantity != null) ? entCli.Quantity : (entOI != null ? entOI.Quantity : null);
            }
          } else if (entOI != null && newENT.Type == Constants.ENT_TYPE_EVALUATION) {
            if (Constants.PROD_ENTCON_ONE_PER_UNIT.equalsIgnoreCase(entOI.Product2?.SBQQSC__EntitlementConversion__c)) {
              newENT.Quantity__c = 1;
            } else {
              newENT.Quantity__c = entOI.Quantity;
            }
          } else if (entOI != null && newENT.Type == Constants.ENT_TYPE_MANUFACTURING_ENTITLEMENT) {
            newENT.Quantity__c = entOI.Quantity;
          }
        }
      }

      if(Trigger.isInsert || Trigger.isUpdate){
          if (entOI != null){
            //CPQ22-6126 - Start
            Entitlement oldEnt = Trigger.oldMap != null ? (Entitlement) Trigger.oldMap.get(newENT.Id) : null;
            
            if ((oldEnt == null || oldEnt.Order_Service_Item__c != newENT.Order_Service_Item__c) && newENT.Quantity__c != null) {
              newENT.Entitlement_ACV__c = populateEntACV(entOI, newENT.Quantity__c);
              newENT.Entitlement_RAMP_EXIT_ACV__c = populateEntRampExitACV(entOI, newENT.Quantity__c); //SAL26-1359
            }
            // Exit Entitlement Date population using trigger
            if (newENT.EntitlementExitDate__c == null) {
              if (newENT.exitEntitlementDateoverride__c != null) {
                newENT.EntitlementExitDate__c = newENT.exitEntitlementDateoverride__c;
              } else {
                String opptySubTypes = Label.StampSameEntACVforOpptySubTypes;
                List<String> specialSubTypes = opptySubTypes != null ? opptySubTypes.split(',') : new List<String>();
                String oppSubType = entOI?.SBQQ__QuoteLine__r?.SBQQ__Quote__r?.SBQQ__Opportunity2__r?.Opportunity_Sub_Type__c;
                Boolean isGC = oppSubType != null && specialSubTypes.contains(oppSubType);
                Date requiredByEnd = entOI?.SBQQ__RequiredBy__r?.EndDate;
                if (isGC && entOI?.SBQQ__RequiredBy__c != null && entOI?.SBQQ__RequiredBy__r?.EndDate != null && requiredByEnd != null) {
                  newENT.EntitlementExitDate__c = requiredByEnd;
                } else {
                  newENT.EntitlementExitDate__c = newENT.EndDate;
                }
              }
            }
            //CPQ22-6126 - End
        }
      }
    }
  }

  /**
   * @author Siva Kumar V
   * @date 2024-10-14
   * @description This method populates the Storage Region Bundle on Before Insert PRDOPS25-724
   */
  public static void populateStorageRegionBundleOnInsert() {
    if (!entitlementCLIById.isEmpty()) {
      for (Entitlement newENT : (List<Entitlement>) Trigger.new) {
        if (entitlementCLIById.containsKey(newENT.ContractLineItemId)) {
          newENT.Storage_Region__c = entitlementCLIById.get(newENT.ContractLineItemId).Storage_Region_Bundle__c;
        }
      }
    }
  }

  /***********************************************************************************************************
    * @description : Calculates Entitlement ACV based on Quote Line ACV and populates it on Entitlement record.
    * Method Name          : populateEntACV
    * Date Created/Modified: 16/12/2025 - CPQ22-6126
    * Author               : Mustakim Shaikh
    * @param entOi          : Order Item associated with Entitlement
    * @param entQuantity    : Entitlement Quantity
    * @return Decimal       : Calculated ACV value
  *********************************************************************************************************/
  public static Decimal populateEntACV(OrderItem entOi, Decimal entQuantity) {
    Decimal acv = 0;
    //CPQ22-6425
    if (entQuantity != null && entQuantity > 0 && entOi != null && entOi.SBQQ__QuoteLine__r != null) {
      SBQQ__QuoteLine__c qli = entOi.SBQQ__QuoteLine__r;
      String subType = qli?.SBQQ__Quote__r?.SBQQ__Opportunity2__r?.Opportunity_Sub_Type__c;
      String opptySubTypes = Label.StampSameEntACVforOpptySubTypes;
      List<String> opptySubTypesList = opptySubTypes != null ? opptySubTypes.split(',') : new List<String>();
      if ( subType != null && opptySubTypesList.contains(subType)) {
        if (entOi.Id != null && oiKeyById.containsKey(entOi.Id)) {
            String key = oiKeyById.get(entOi.Id);
            SpecialCalcGroup grp = specialCalcByKey.get(key);
            if (grp != null && grp.minStart != null && grp.maxEnd != null && grp.lineCount > 0) {
              Integer days = grp.minStart.daysBetween(grp.maxEnd.addDays(1));
              if (days <= 0) days = 1;
              // factor = (days * 12) / 365
              Decimal factor = (Decimal.valueOf(days) * 12) / 365;
              if (factor > 0) {
                // Step3: sum(totalPrice)/factor; Step4: *12; Step5: /lineCount
                Decimal step3 = grp.totalPriceSum / factor;
                Decimal step4 = step3 * 12;
                acv = step4 / grp.lineCount;
              }
            }
          }
          return acv; //CPQ22-6425
        }
      }

    if(entQuantity != null && entQuantity > 0 && entOi != null && entOi.SBQQ__QuoteLine__r != null) {
        SBQQ__QuoteLine__c qli = entOi.SBQQ__QuoteLine__r;
        System.debug(LoggingLevel.DEBUG, 'MS 6126 Inside populateEntACV Ent Quantity: ' + entQuantity + ' Quote Line ACV: ' + entOi.SBQQ__QuoteLine__r.ACV__c + ' Quote Line Quantity: ' + entOi.SBQQ__QuoteLine__r.SBQQ__Quantity__c);
      
        if (qli?.ACV__c > 0 && qli?.SBQQ__Quantity__c > 0){

          acv = (qli.ACV__c / qli.SBQQ__Quantity__c) * entQuantity;

        } else if (qli.SBQQ__Quantity__c != null && qli.SBQQ__Quantity__c > 0 &&
                    qli.SBQQ__Product__r?.Product_Type__c == 'HW Support' && 
                    entOi.SBQQ__QuoteLine__r?.SBQQ__Quote__r?.SBQQ__Opportunity2__r?.Opportunity_Sub_Type__c != 'Renewal'){
                      Decimal netTotal = qli.SBQQ__NetTotal__c;
                      Decimal subsTerm = qli.SBQQ__SubscriptionTerm__c;
                      Decimal prepayCredit = qli.Prepayment_Credit__c != null ? qli.Prepayment_Credit__c : 0;
                      //System.debug(LoggingLevel.DEBUG, 'MS 6126 Inside populateEntACV HW Support netTotal: ' + netTotal + ' subsTerm: ' + subsTerm + ' prepayCredit: ' + prepayCredit);

                      if (netTotal != null && subsTerm != null && subsTerm > 0) {
                        acv = (((netTotal + prepayCredit) * 12) / subsTerm) * (entQuantity / qli.SBQQ__Quantity__c);
                      }
        }
    }
    return acv;
  }

  /***********************************************************************************************************
    * @description         : Calculates Entitlement Ramp Exit ACV based on Quote Line RAMP_EXIT_ACV__c.
    * Method Name          : populateEntRampExitACV
    * Date Created/Modified: 25/12/2025 - SAL26-1359
    * Author               : Mustakim Shaikh
    * @param entOi          : Order Item associated with Entitlement
    * @param entQuantity    : Entitlement Quantity
    * @return Decimal       : Calculated ACV value
  ***********************************************************************************************************/
  public static Decimal populateEntRampExitACV(OrderItem entOi, Decimal entQuantity) {
    Decimal rampExit = 0;
    if (entQuantity != null && entQuantity > 0 && entOi != null && entOi.SBQQ__QuoteLine__r != null) {
      SBQQ__QuoteLine__c qli = entOi.SBQQ__QuoteLine__r;

      //CPQ22-6425 For GC Renewal / MSP Consumption Renewal / MSP -> use ExitACVMap logic derived from max Support_End_Date__c OrderItem to populate Ramp Exit ACV instead of Quote Line RAMP_EXIT_ACV__c field value
      String subType = qli?.SBQQ__Quote__r?.SBQQ__Opportunity2__r?.Opportunity_Sub_Type__c;
      String opptySubTypes = Label.StampSameEntACVforOpptySubTypes;
      List<String> opptySubTypesList = opptySubTypes != null ? opptySubTypes.split(',') : new List<String>();
      if (subType != null && opptySubTypesList.contains(subType)) {
        if (entOi.Id != null && oiKeyById.containsKey(entOi.Id)) {
          String key = oiKeyById.get(entOi.Id);
          OrderItem oi = exitACVMap.get(key);
          rampExit = (oi != null && oi.TotalPrice != null) ? oi.TotalPrice * 12 : 0;
        }
        return rampExit; //CPQ22-6425
      }
      
      if (qli?.RAMP_EXIT_ACV__c > 0  && qli.SBQQ__Quantity__c != null && qli.SBQQ__Quantity__c > 0) {
        rampExit = (qli.RAMP_EXIT_ACV__c / qli.SBQQ__Quantity__c) * entQuantity;
      }
    }
    return rampExit;
  }
}