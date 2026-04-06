/***********************************************************************************
 * @description       : Order update Trigger helper
 * @author            : Chaitra
 * @last modified on  : 01-20-2021
 * @last modified by  : Chaitra
 * Modifications Log
 * Ver   Date          Author        Modification
 * 1.0   01-20-2021   chaitra        Initial Version
 * 2.0   10-22-2021   shiva          RWD-366
 * 2.1   06-14-2022   moises         PRDOPS23-433 Adding order id to error logs V5 Deplouymenbt
 *********************************************************************************/
public class OrderUpdateHelper {
  private static OrderUpdateHelper instance = null;
  private set<Id> processedMFG_OI = new Set<Id>();
  private static boolean isSplitOrderExecuted = false;
  @testvisible
  private OrderInsertHelper helper;
  private final String TRAINING_PRODUCT = 'Training';
  private final String STAGE_PO_CANCELLATION = 'Rejected , This order has been rejected, please contact your Rubrik business contact for further information';
  private final set<string> THIRD_PARTY_HARDWARE = new Set<string>{ 'DELL', 'UCS', 'HPE' };
  private Map<string, Id> projNameOrdId = new Map<string, Id>();
  private List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
  private static List<Scale_Utility_Overage__c> suOveragesToSync;
  PSTaskService psService = new PSTaskService();
  @testvisible
  private OrderUpdateHelper() {
    helper = OrderInsertHelper.getInstance();
  }
  final static ShGl_DisableBusinessLogic__c businessLogicCS = ShGl_DisableBusinessLogic__c.getInstance();
  /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : get Instance of class
   * @return : instance
   */
  public static OrderUpdateHelper getInstance() {
    if (instance == null)
      instance = new OrderUpdateHelper();
    return instance;
  }

  /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : UpdateStagePO
   * @param newOrd new order record
   * @param POStgToUpdate A map where the key is the PO stage Id and the value is the PO stage object to be updated.
   */
  public void updateStagePO(Order newOrd, Map<Id, PO_Stage__c> POStgToUpdate) {
    PO_Stage__c poStg = new PO_Stage__c();
    if (newOrd.Order_Status__c == 'Order Accepted') {
      poStg.PO_Validation_Status__c = 'Order Accepted';
    } else if (newOrd.Order_Status__c == 'Rejected') {
      poStg.PO_Validation_Status__c = 'Order Rejected';
      poStg.Rejection_Reason__c = STAGE_PO_CANCELLATION;
    }
    poStg.id = newOrd.Stage_PO__c;
    poStg.Est_Ship_Date__c = newOrd.Est_Ship_Date__c;
    POStgToUpdate.put(poStg.id, poStg);
  }
  /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : Mark order status activated based on some condition
   * @param newOrd new order record
   */
  public void activateOrders(Order newOrd) {
    if (newOrd.Stage_PO__c != null) {
      newOrd.EDI_Sync_Status__c = 'Y';
    } else {
      newOrd.EDI_Sync_Status__c = 'N';
    }
    newOrd.Status = 'Activated';
  }

  /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : calculation of cma records on orderlevel
   * @param newOrd new order record
   * @param oldOrd The old order record
   * @param OIList A list of OrderItem objects
   */

  public void updateCma(Order newOrd, Order oldOrd, List<OrderItem> OIList) {
    system.debug(LoggingLevel.DEBUG, 'update cma is called');
    Map<String, CMAllocation_For_Non_Aspen_Products__mdt> allocationMapByProdName = DemandMatrixCalculation.distiMetadataMap;
    Map<Id, String> opptyWithQuarter = OrderHandler.opptyHistoryMap;
    Map<String, ContractManufacturerAllocation__c> cmaForAllQuarter = DemandMatrixCalculation.cmAllocationForNonAspenMap;
    Map<String, ContractManufacturerAllocation__c> cmaToUpsert = new Map<String, ContractManufacturerAllocation__c>();

    if (OIList != null) {
      system.debug(LoggingLevel.DEBUG, 'OIList size is ##### ' + OIList.size());
      for (OrderItem OI : OIList) {
        system.debug(LoggingLevel.DEBUG, 'allocationMapByProdName keyset is ##### ' + allocationMapByProdName.keyset());
        if (allocationMapByProdName.containskey(OI.product2.Name) && allocationMapByProdName.get(OI.product2.Name) != null) {
          system.debug(LoggingLevel.DEBUG, 'filtered productname is ' + OI.product2.Name + OI.product2Id);
          system.debug(LoggingLevel.DEBUG, 'allocation logic is working');
          String Quarter;
          if (OI.Order.OpportunityId != null && opptyWithQuarter != null && opptyWithQuarter.containskey(OI.Order.OpportunityId)) {
            Quarter = opptyWithQuarter.get(OI.Order.OpportunityId);
          }
          if (cmaForAllQuarter != null) {
            ContractManufacturerAllocation__c newCma = cmaForAllQuarter.get(Quarter + '-' + OI.product2Id + '-' + newOrd.Contract_Manufacturer__c);
            ContractManufacturerAllocation__c oldCma = cmaForAllQuarter.get(Quarter + '-' + OI.product2Id + '-' + oldOrd.Contract_Manufacturer__c);
            system.debug(LoggingLevel.DEBUG, 'newCma is ##### ' + newCma);
            system.debug(LoggingLevel.DEBUG, 'oldCma is ##### ' + oldCma);
            if (newCma != null) {
              //newCma.TotalFulfillment__c =  newCma.TotalFulfillment__c + OI.Quantity;
              if (
                cmaToUpsert != null &&
                cmaToUpsert.containskey(Quarter + '-' + OI.product2Id + '-' + newOrd.Contract_Manufacturer__c) &&
                cmaToUpsert.get(Quarter + '-' + OI.product2Id + '-' + newOrd.Contract_Manufacturer__c) != null
              ) {
                cmaToUpsert.get(Quarter + '-' + OI.product2Id + '-' + newOrd.Contract_Manufacturer__c).TotalFulfillment__c = newCma.TotalFulfillment__c + OI.Quantity;
                system.debug(LoggingLevel.DEBUG, 'new cma allocation found');
              } else {
                newCma.TotalFulfillment__c = newCma.TotalFulfillment__c + OI.Quantity;
                cmaToUpsert.put(Quarter + '-' + OI.product2Id + '-' + newOrd.Contract_Manufacturer__c, newCma);
              }
              system.debug(LoggingLevel.DEBUG, 'cmaToUpsert keysetis for new is ####' + cmaToUpsert.keyset());
              system.debug(LoggingLevel.DEBUG, 'cmaToUpsert values for new is ####' + cmaToUpsert);

              // cmaToUpsert.add(newCma);
            } else {
              ContractManufacturerAllocation__c contractmanufacturer = new ContractManufacturerAllocation__c(
                ContractManufacturer__c = newOrd.Contract_Manufacturer__c,
                Product__c = OI.product2Id,
                Quarter__c = Quarter,
                TotalFulfillment__c = OI.quantity,
                Type__c = 'Non Aspen',
                Distributor__c = newOrd.accountId
              );
              cmaToUpsert.put(Quarter + '-' + OI.quantity + '-' + newOrd.Contract_Manufacturer__c, contractmanufacturer);
            }
            if (oldCma != null) {
              if (
                cmaToUpsert != null &&
                cmaToUpsert.containskey(Quarter + '-' + OI.product2Id + '-' + oldOrd.Contract_Manufacturer__c) &&
                cmaToUpsert.get(Quarter + '-' + OI.product2Id + '-' + oldOrd.Contract_Manufacturer__c) != null
              ) {
                cmaToUpsert.get(Quarter + '-' + OI.product2Id + '-' + oldOrd.Contract_Manufacturer__c).TotalFulfillment__c = oldCma.TotalFulfillment__c - OI.Quantity;
              } else {
                oldCma.TotalFulfillment__c = oldCma.TotalFulfillment__c - OI.Quantity;
                cmaToUpsert.put(Quarter + '-' + OI.product2Id + '-' + oldOrd.Contract_Manufacturer__c, oldCma);
              }
              system.debug(LoggingLevel.DEBUG, 'cmaToUpsert keysetis for oldcma is ####' + cmaToUpsert.keyset());
              system.debug(LoggingLevel.DEBUG, 'cmaToUpsert values for oldcma is ####' + cmaToUpsert);

              // cmaToUpsert.add(oldCma);
            } else {
              ContractManufacturerAllocation__c contractmanufacturer = new ContractManufacturerAllocation__c(
                ContractManufacturer__c = oldOrd.Contract_Manufacturer__c,
                Product__c = OI.product2Id,
                Quarter__c = Quarter,
                TotalFulfillment__c = OI.quantity,
                Type__c = 'Non Aspen',
                Distributor__c = oldOrd.accountId
              );
              cmaToUpsert.put(Quarter + '-' + OI.quantity + '-' + oldOrd.Contract_Manufacturer__c, contractmanufacturer);
            }
          }
        }
      }
    }
    system.debug(LoggingLevel.DEBUG, 'cmaToUpsert keysetis actual is ####' + cmaToUpsert.keyset());
    system.debug(LoggingLevel.DEBUG, 'cmaToUpsert values actual is ####' + cmaToUpsert);

    OrderHandler.cmaToUpsertNew = cmaToUpsert;
  }

  /**
   * @description : RebateCalculation
   *
   * @param newOrd The new order object record
   * @param bkg The booking record associated with the order.
   * @param newOIList A list of new OrderItem objects to be included in the rebate calculation.
   * @param rebateList A set of Rebate_Table__c records used to apply the rebate logic.
   * @param opp The opportunity related to the order
   * @param BLIimpactList A list of Booking Line Item
   * @param BLIToInsert A set of new Booking Line Items to be inserted
   * @param mapBKgIdToNetRenewal A map that links Booking Ids to their corresponding net renewal amounts.
   * @param mapBKgIdToNetNew A map that links Booking Ids to their corresponding net new amounts.
   * @param mapBKgIdToGrossACVAmt A map that links Booking Ids to their corresponding gross ACV amounts.
   * @param mapBKgIdToGrossNewACV A map that links Booking Ids to their corresponding gross new ACV amounts.
   * @param mapBKgIdToGrossRenewalACV A map that links Booking Ids to their corresponding gross renewal ACV amounts.
   */
  public void rebateCalculation(
    Order newOrd,
    booking__c bkg,
    List<OrderItem> newOIList,
    set<Rebate_Table__c> rebateList,
    Opportunity opp,
    List<BLI_Impact__mdt> BLIimpactList,
    set<Booking_Line_Item__c> BLIToInsert,
    Map<Id, Decimal> mapBKgIdToNetRenewal,
    Map<Id, Decimal> mapBKgIdToNetNew,
    Map<Id, Decimal> mapBKgIdToGrossACVAmt,
    Map<Id, Decimal> mapBKgIdToGrossNewACV,
    Map<Id, Decimal> mapBKgIdToGrossRenewalACV
  ) {
    Account acc = helper.accountMap?.get(opp.AccountId);
    Date bkgdate;
    String orginalOrdSubType;
    if (newOrd.Type == 'Revenue') {
      bkgdate = bkg.CreatedDate.date();
      orginalOrdSubType = newOrd.Order_Sub_Type__c;
    } else if (newOrd.Type == 'Booking Adjustment') {
      bkgdate = bkg.Original_Booking__r?.CreatedDate?.date();
      orginalOrdSubType = bkg.Original_Booking__r?.Order__r?.Order_Sub_Type__c;
    }

    if (bkgdate != null) {
      for (Rebate_Table__c rebate : rebateList) {
        system.debug(logginglevel.DEBUG, 'rebate ::' + rebate);
        if (
          rebate.Rebate_Deal_Type__c != null &&
          rebate.Rebate_Type__c == 'Distributor Fee' &&
          newOrd.Bill_To_Name__c != null &&
          newOrd.Bill_To_Name__c == rebate.Distributor__c &&
          bkgdate > rebate.Start_Date__c &&
          (bkgdate < rebate.End_Date__c ||
          rebate.End_Date__c == null) &&
          (rebate.Rebate_Deal_Type__c == 'All' ||
          (rebate.Rebate_Deal_Type__c == 'All except MSP' && (orginalOrdSubType == 'Renewal' || orginalOrdSubType == null || orginalOrdSubType == 'Amendment')) ||
          (rebate.Rebate_Deal_Type__c == 'MSP' &&
          (orginalOrdSubType == 'MSP Consumption' ||
          orginalOrdSubType == 'MSP Overage' ||
          orginalOrdSubType == 'MSP Consumption Renewal')) ||
          (rebate.Rebate_Deal_Type__c == Constants.REBATE_DEAL_TYPE_GC_OFFER && Constants.ORDER_SUB_TYPES_SCALE_UTILITY.contains(orginalOrdSubType)))
        ) {
          BLIToInsert.add(
            CreateRebateBLI(
              newOrd,
              newOIList,
              rebate,
              bkg,
              opp,
              BLIimpactList,
              mapBKgIdToNetRenewal,
              mapBKgIdToNetNew,
              mapBKgIdToGrossACVAmt,
              mapBKgIdToGrossNewACV,
              mapBKgIdToGrossRenewalACV
            )
          );
        }
      }
    }
  }
  /**
   * @description : method to create BookingLineItem for each order of qualified opportunity.
   *
   * @param newOrd The new order object record
   * @param OIList A list of OrderItem
   * @param rebatable The Rebate_Table__c record
   * @param bkg The booking record related to the rebate BLI creation.
   * @param opp The opportunity linked to the order
   * @param BLIimpactList A list of BLI_Impact__mdt metadata records
   * @param mapBKgIdToNetRenewal A map that links Booking Ids to their corresponding net renewal amounts.
   * @param mapBKgIdToNetNew A map that links Booking Ids to their corresponding net new amounts.
   * @param mapBKgIdToGrossACVAmt A map that links Booking Ids to their corresponding gross ACV amounts.
   * @param mapBKgIdToGrossNewACV A map that links Booking Ids to their corresponding gross new ACV amounts.
   * @param mapBKgIdToGrossRenewalACV A map that links Booking Ids to their corresponding gross renewal ACV amounts.
   * @return A new Booking_Line_Item__c object representing the created rebate BLI.
   */
  public Booking_Line_Item__c createRebateBLI(
    Order newOrd,
    List<OrderItem> OIList,
    Rebate_Table__c rebatable,
    Booking__c bkg,
    Opportunity opp,
    List<BLI_Impact__mdt> BLIimpactList,
    Map<Id, Decimal> mapBKgIdToNetRenewal,
    Map<Id, Decimal> mapBKgIdToNetNew,
    Map<Id, Decimal> mapBKgIdToGrossACVAmt,
    Map<Id, Decimal> mapBKgIdToGrossNewACV,
    Map<Id, Decimal> mapBKgIdToGrossRenewalACV
  ) {
    String distributor = '';
    if (newOrd.Bill_To_Name__c != null && OrderinsertHelper.getDistributorMetadata(newOrd.Bill_To_Name__c) != null)
      if (!Test.isRunningTest()) {
        distributor = OrderinsertHelper.getDistributorMetadata(newOrd.Bill_To_Name__c).Po_Disti_Type__c;
      } else {
        distributor = 'ARROW';
      }

    Booking_Line_Item__c BLI = new Booking_Line_Item__c();
    set<string> installProd = new Set<string>(); // to collect installation products for third party
    set<string> prodType = new Set<string>(); // to add value if order has third party product and has installationItem
    Decimal totalRebate = newOrd.ProcessType__c == 'Aspen' ? rebatable.ASPEN_Rebate__c : rebatable.Rebate__c;
    if (rebatable.Rebate_Type__c == 'Distributor Fee') {
      BLI.Type__c = 'Distributor Fee';
      if (mapBKgIdToNetRenewal.containsKey(bkg.Id) && mapBKgIdToNetRenewal.get(bkg.Id) != null) {
        BLI.Subsumed_Renewal_TCV__c = mapBKgIdToNetRenewal.get(bkg.Id) * totalRebate * -0.01;
      }

      if (mapBKgIdToNetNew.containsKey(bkg.Id) && mapBKgIdToNetNew.get(bkg.Id) != null) {
        BLI.New_Expansion_TCV__c = mapBKgIdToNetNew.get(bkg.Id) * totalRebate * -0.01;
      }
      if (mapBKgIdToGrossACVAmt.containsKey(bkg.Id) && mapBKgIdToGrossACVAmt.get(bkg.Id) != null) {
        BLI.Gross_ACV_Amount__c = mapBKgIdToGrossACVAmt.get(bkg.Id) * totalRebate * -0.01;
      }
      if (mapBKgIdToGrossNewACV.containsKey(bkg.Id) && mapBKgIdToGrossNewACV.get(bkg.Id) != null) {
        BLI.Gross_New_Expansion_ACV__c = mapBKgIdToGrossNewACV.get(bkg.Id) * totalRebate * -0.01;
      }
      if (mapBKgIdToGrossRenewalACV.containsKey(bkg.Id) && mapBKgIdToGrossRenewalACV.get(bkg.Id) != null) {
        BLI.Gross_Subsumed_Renewal_ACV__c = mapBKgIdToGrossRenewalACV.get(bkg.Id) * totalRebate * -0.01;
      }
      if (distributor != null && distributor == 'ARROW') {
        if (rebatable.Installation_Product__c != null) {
          installProd.addall(rebatable.Installation_Product__c.split(';'));
        }
        if (
          opp.Opportunity_Type__c == 'New Customer' &&
          opp.FocusedPartner__c == false &&
          rebatable != null &&
          rebatable.Value_Add_Distribution_fee__c != null &&
          (opp.Deal_Registration_Type__c == 'Partner Initiated Deal' ||
          opp.Deal_Registration_Type__c == 'Joint Initiated Deal')
        ) {
          totalRebate += rebatable.Value_Add_Distribution_fee__c;
        }
        if (!installProd.isEmpty() && OIList != null) {
          for (OrderItem OI : OIList) {
            if (OI.Product2 != null && OI.Product2.Family != null && THIRD_PARTY_HARDWARE.contains(OI.Product2.Family)) {
              prodType.add('ThirdPartyHardware');
            } else if (installProd.contains(OI.product2.Name)) {
              prodType.add('InstallProd');
              break;
            }
          }
          if (prodType.contains('ThirdPartyHardware') && !prodType.contains('InstallProd')) {
            totalRebate += rebatable.Distributor_Installation_Fee__c;
          }
        }
      }
    } else if (rebatable.Rebate_Type__c == 'Velocity Partner Program Rebate') {
      BLI.Type__c = 'Velocity Partner Program Rebate';
    }
    BLI.Booking__c = bkg.Id;
    BLI.Total_Price__c = newOrd.TotalAmount * totalRebate * -0.01;
    BLI.Rebate__c = totalRebate;
    BLI.Distributor__c = rebatable.Distributor__r.name;
    if (BLIimpactList != null)
      for (BLI_Impact__mdt BLIimpact : BLIimpactList) {
        if (BLI.Type__c == BLIimpact.Adjustment_Type__c) {
          BLI.Impacts_Gross_Bookings__c = BLIimpact.Impacts_Gross_Bookings__c;
          BLI.Impacts_Net_Bookings__c = BLIimpact.Impacts_Net_Bookings__c;
          BLI.Impacts_Commission__c = BLIimpact.Impacts_Commissions__c;
        }
      }
    return BLI;
  }
  /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : ProcessAcceptedOrders
   * @param newOrd The new Order object
   * @param OIList A list of OrderItem objects
   * @param OIEntMap A map of OrderItem IDs to corresponding lists of Entitlement records to be processed.
   * @param EntToInsert A set of Entitlement records to be inserted into the system during processing.
   * @param oppToUpdate A map of Opportunity IDs to corresponding Opportunity records that need to be updated.
   */
  public void processAcceptedOrders(Order newOrd, List<OrderItem> OIList, Map<Id, List<Entitlement>> OIEntMap, set<Entitlement> EntToInsert, Map<Id, Opportunity> oppToUpdate) {
    /*Opportunity opp = helper.oppMap?.get(newOrd.OpportunityId);
        if(opp!=null && opp.StageName!='7 Closed Won' && opp.StageName!='7 Closed Lost'){
            oppToUpdate.put(opp.id,new opportunity(Id = newOrd.OpportunityId, StageName = '7 Closed Won', CloseDate = newOrd.Order_Accepted_Timestamp__c != null ? newOrd.Order_Accepted_Timestamp__c.Date() : Date.Today(), Order_Sub_Type__c = newOrd.Order_Sub_Type__c));
        }*/
    Map<Id, Set<String>> OrdIdToSCorEntIds = new Map<Id, Set<String>>();
    if (OIList != null) {
      for (OrderItem OI : OIList) {
        Boolean createEnt = true;
        /*** Third party products **/
        if (OIEntMap != null && OIEntMap.get(OI.id) != null) {
          for (Entitlement ent : OIEntMap.get(OI.id)) {
            if (ent.Type == 'Manufacturing Entitlement') {
              createEnt = false;
              break;
            }
          }
        }
        if (createEnt == false)
          continue;
        if (
          ((!processedMFG_OI.contains(oi.id) && (OI.Product2.Product_Type__c == '3rd Party Hardware' && THIRD_PARTY_HARDWARE.contains(OI.Product2.Family)) ||
          //V1 (non RSC) logic:
          (String.isBlank(oI.Product2.Product_Level__c) &&
          oi.Product2.Family != null &&
          oi.Product2.Family == 'Rubrik Scale' &&
          oI.Product2.Product_Type__c != null &&
          (oI.Product2.Product_Type__c == 'Enterprise Edition' ||
          oI.Product2.Product_Type__c == 'Business Edition' ||
          oI.Product2.Product_Type__c == 'RCDM')) ||
          //V1 (non RSC) logic ends
          //V2 (RSC) logic:
          (oi.Product2.Product_Level__c != null &&
          oi.Product2.Product_Level__c == 'Hybrid Software' &&
          oi.Product2.Family != null &&
          oi.Product2.Family == 'Rubrik Scale' &&
          oi.Product2.Product_Subtype__c != 'Scale MSP' &&
          oI.Product2.Product_Type__c != null &&
          (oI.Product2.Product_Type__c == 'Enterprise Edition' ||
          oI.Product2.Product_Type__c == 'Business Edition' ||
          oI.Product2.Product_Type__c == 'Foundation Edition')) ||
          //V2 (RSC) logic ends
          (('RCDM' == oi.Product2.Product_Type__c ||
          oi.Product2.Product_Level__c == 'Hybrid Software' ||
          ((oI.Product2.Product_Level__c == 'OnPrem' || String.isBlank(oI.Product2.Product_Level__c)) &&
          (oI.Product2.Product_Type__c == 'Enterprise Edition' ||
          oI.Product2.Product_Type__c == 'Business Edition' ||
          oI.Product2.Product_Type__c == 'Foundation Edition') &&
          OI?.Product2?.Product_Subtype__c == null)) && oi.Product2.Family == 'Rubrik Scale') ||
          (oi.Product2.Family == 'Third Party License') ||
          (oi.Product2.Product_Type__c == 'MSP' &&
          oi.Product2.Family == 'RCDM' &&
          oi.SBQQ__SegmentIndex__c == 1 &&
          oi.Product2.MSP_Std_Actual__c != 'MSP Actual & Overage')) && newOrd.Order_Sub_Type__c != Constants.ORDER_SUB_TYPE_GC_OFFER) ||
          (!OrderinsertHelper.isCoreSULicenseByProductId.isEmpty() &&
          OrderinsertHelper.isCoreSULicenseByProductId.containskey(oi.product2id) &&
          newOrd.Order_Sub_Type__c == Constants.ORDER_SUB_TYPE_GC_OFFER) // PRDOPS25-683: create Manufacturing Entitlement for Core Scale Utility Products on the GC Offer order
        ) {
          string prodId;
          if (!Test.isRunningTest())
            prodId = Order_control__mdt.getInstance('Manufacturing_Entitlement_Product').Value__c;
          if (businessLogicCS.Follow_Existing_EntCreate_Process__c) {
            EntToInsert.add(createEntitlement(newOrd, OI, 'Manufacturing Entitlement', prodId, null, null));
          } else {
            OrdIdToSCorEntIds = UtilityClass.getupdatedOrdIdToScActionItemMap(newOrd, OrdIdToSCorEntIds, 'Create Manufacturing Entitlement');
          }
          processedMFG_OI.add(OI.id);
        }
      }
    }
    if (OrdIdToSCorEntIds.keyset().size() > 0) {
      Utilityclass.updateOrderFields(OrdIdToSCorEntIds.keyset(), Json.serialize(OrdIdToSCorEntIds));
    }
  }
  /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : update values on Opportunity
   * @param newOrd The new Order object record
   * @param oldOrd The old Order object record
   * @param oppToUpdate A map of Opportunity IDs to Opportunity records that need to be updated.
   * @param intOrder An integer representing some additional data related to the order processing.
   */
  public void processAfterUpdate(Order newOrd, Order oldOrd, Map<Id, Opportunity> oppToUpdate, Integer intOrder) {
    Opportunity opp = helper.oppMap?.get(newOrd.OpportunityId);
    if (opp != null) {
      system.debug(LoggingLevel.DEBUG, '::intOrder::' + intOrder);
      if (
        String.isNotBlank(newOrd.NetSuite_Order__c) &&
        newOrd.NetSuite_Order__c != oldOrd.NetSuite_Order__c &&
        opp.StageName != '7 Closed Won' &&
        opp.StageName != '7 Closed Lost'
      ) {
        oppToUpdate.put(
          opp.id,
          new opportunity(
            Id = newOrd.OpportunityId,
            StageName = '7 Closed Won',
            CloseDate = newOrd.Order_Accepted_Timestamp__c != null ? newOrd.Order_Accepted_Timestamp__c.Date() : Date.Today(),
            Order_Sub_Type__c = newOrd.Order_Sub_Type__c
          )
        );
      } else if (newOrd.Order_Accepted_Timestamp__c != null && newOrd.Order_Accepted_Timestamp__c != oldOrd.Order_Accepted_Timestamp__c && intOrder <= 1) {
          OpportunityObjectTriggerHandler.bypassClosedWonUpdateValidation = true;//SAL26-1054
          oppToUpdate.put(opp.id, new opportunity(Id = newOrd.OpportunityId, CloseDate = newOrd.Order_Accepted_Timestamp__c.Date()));
      }
    }
  }
  /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : Create custom entitlements
   * @param newOrd The new Order object record
   * @param OIList A list of OrderItem objects record
   * @param OIEntMap A map that associates OrderItem IDs with corresponding lists of Entitlement records to process.
   * @param serialNumAsset A map that associates serial numbers with Asset records for the order items.
   * @param EntToInsert A set of Entitlement records that need to be inserted.
   * @param EntToUpdate A map of Entitlement IDs to Entitlement records that need to be updated.
   * @param assetToUpsert A map of Asset serial numbers to Asset records that need to be upserted.
   * @param orderItemToUpdate A map of OrderItem IDs to OrderItem records that need to be updated.
   */
  public void processOrderItem(
    Order newOrd,
    List<OrderItem> OIList,
    Map<Id, List<Entitlement>> OIEntMap,
    Map<string, Asset> serialNumAsset,
    set<Entitlement> EntToInsert,
    Map<Id, Entitlement> EntToUpdate,
    Map<string, Asset> assetToUpsert,
    Map<Id, orderItem> orderItemToUpdate
  ) {
    system.debug(logginglevel.DEBUG, 'serialNumAsset' + JSON.serializePretty(serialNumAsset));
    system.debug(logginglevel.DEBUG, 'EntToInsert =>' + EntToInsert);
    string assetStatus = '';
    string entitlementType = '';
    Map<Id, Map<string, Date>> parentItemId_SupportDates = new Map<Id, Map<string, Date>>();
    Map<Id, OrderItem> oiForDatesToUpdateCSUMap = new Map<Id, OrderItem>(); //CSU-336-Prashant
    Map<String, OrderItem> mapCommitIdToONDOI = new Map<String, OrderItem>(); //PRDOPS24-974
    Map<Id, Set<String>> OrdIdToSCorEntIds = new Map<Id, Set<String>>();

    if (newOrd.Type == 'Revenue') {
      assetStatus = 'Purchased';
    } else if (newOrd.Type == 'POC') {
      if (
        newOrd.POC_Type__c == 'Standard POC' ||
        newOrd.POC_Type__c == 'Standard POC : RSC-G' ||
        newOrd.POC_Type__c == 'Partner Software Access' ||
        newOrd.POC_Type__c == 'CSAT Loaner' ||
        newOrd.POC_Type__c == 'Web Try and Buy' ||
        newOrd.POC_Type__c == 'Ransomware Recovery Software'
      ) {
        assetStatus = 'POC';
        entitlementType = 'Evaluation';
      } else if (newOrd.POC_Type__c == 'Conditional PO') {
        assetStatus = 'Conditional';
        entitlementType = 'Conditional PO';
      } else if (newOrd.POC_Type__c == 'EA Unit') {
        assetStatus = 'EA Test';
        entitlementType = 'Evaluation';
      } else if (newOrd.POC_Type__c == 'Business Loaner Unit' || newOrd.POC_Type__c == 'Support Loaner Unit') {
        assetStatus = 'Loaner';
        entitlementType = 'Loaner Unit';
      }
    }
    if (OIList != null) {
      for (OrderItem OI : OIList) {
        if (
          OI.product2.SBQQ__SubscriptionPricing__c != null ||
          (OI.Create_Entitlement__c &&
          ((OI.Product2.Entitlement_Conversion_Non_CPQ__c != null && OI.Product2.Entitlement_Conversion_Non_CPQ__c.EqualsIgnoreCase('One per unit')) ||
          (OI.Product2.SBQQSC__EntitlementConversion__c != null && OI.Product2.SBQQSC__EntitlementConversion__c.EqualsIgnoreCase('One per unit'))))
        ) {
          system.debug(logginglevel.DEBUG, 'OI.Support_Start_Date__c' + OI.Support_Start_Date__c);
          Id Key = OI.SBQQ__RequiredBy__c != null ? OI.SBQQ__RequiredBy__c : OI.Product2.Appliance_Model_HW__c != null ? OI.Id : null;
          if (Key != null) {
            if (!parentItemId_SupportDates.containsKey(Key)) {
              parentItemId_SupportDates.put(Key, new Map<string, date>{ 'startDate' => OI.Support_Start_Date__c, 'endDate' => OI.Support_End_Date__c });
            } else {
              if (parentItemId_SupportDates.get(Key).get('startDate') == null || parentItemId_SupportDates.get(Key).get('startDate') > OI.Support_Start_Date__c)
                parentItemId_SupportDates.get(Key).put('startDate', OI.Support_Start_Date__c);
              if (parentItemId_SupportDates.get(Key).get('endDate') == null || parentItemId_SupportDates.get(Key).get('endDate') < OI.Support_End_Date__c)
                parentItemId_SupportDates.get(Key).put('endDate', OI.Support_End_Date__c);
            }
          }
        }
        if (
          OI?.Product2?.Product_Subtype__c != null &&
          Constants.SCALE_UTILITY_PRODUCT_SUBTYPES_ONDEMAND.contains(OI?.Product2?.Product_Subtype__c) &&
          OI?.Product2?.License_Category__c != null &&
          OI?.Product2?.License_Category__c == Constants.LICENSE_CATEGORY
        ) {
          mapCommitIdToONDOI.put(OI.Global_Commit_ID__c, OI);
        }
        /* 
                if (OI.Order.Order_Sub_Type__c == Constants.ORDER_SUB_TYPE_GC_OFFER
                  && OI.Product2.Product_Subtype__c == Constants.PROD_SUB_TYPE_SCALE_MSP
                  && String.isBlank(OI.Product2.License_Category__c)
                ) {
                  OI.Support_Start_Date__c = newOrd.Actual_Order_Ship_Date__c;
                  if (oi.Support_Term__c != null) {
                    OI.Support_End_Date__c = newOrd.Actual_Order_Ship_Date__c?.addMonths(Integer.valueOf(OI.Support_Term__c)).addDays(-1);
                  } else {
                    OI.Support_End_Date__c = newOrd.Actual_Order_Ship_Date__c?.addMonths(Integer.valueOf(OI.SBQQ__SubscriptionTerm__c)).addDays(-1);
                  }
                  orderItemToUpdate.put(OI.id,oi);
                } */

        // Logic To Update Start Date And EndDate From Support Dates For GC Offer - CSU-336-Prashant
        if (OI.Order.Order_Sub_Type__c == Constants.ORDER_SUB_TYPE_GC_OFFER && OI.Support_Start_Date__c != null && OI.Support_End_Date__c != null) {
          if (OI.EndDate != OI.Support_End_Date__c) {
            OI.EndDate = OI.Support_End_Date__c;
            oiForDatesToUpdateCSUMap.put(OI.Id, OI);
          }
          if (OI.ServiceDate != OI.Support_Start_Date__c) {
            OI.ServiceDate = OI.Support_Start_Date__c;
            oiForDatesToUpdateCSUMap.put(OI.Id, OI);
          }
        }
      }

      // calling this Queueable to update the dates on the Segment which is not allowed directly unless CPQ triggers are disabled
      if (!oiForDatesToUpdateCSUMap.isEmpty()) {
        system.debug(LoggingLevel.DEBUG, 'calling UpdateSupportOrderLinesDatesForCSUClass from orderupdatehelper');
        System.enqueueJob(new UpdateSupportOrderLinesDatesForCSUClass(oiForDatesToUpdateCSUMap.values()));
      }

      system.debug(logginglevel.DEBUG, 'support dates' + parentItemId_SupportDates);

      for (OrderItem OI : OIList) {
        /* Copy the Support Start And End Date
         *  from Ond Line Sku to RSVX Line For last date of month issue
         *   PRDOPS24-974*/
        if (
          OI.Order.Order_Sub_Type__c == Constants.ORDER_SUB_TYPE_GC_OFFER &&
          OI.Product2.Product_Subtype__c == Constants.PROD_SUB_TYPE_SCALE_MSP &&
          String.isBlank(OI.Product2.License_Category__c) &&
          OI.Global_Commit_ID__c != null &&
          mapCommitIdToONDOI.containsKey(OI.Global_Commit_ID__c)
        ) {
          OI.Support_Start_Date__c = mapCommitIdToONDOI.get(OI.Global_Commit_ID__c).Support_Start_Date__c;
          OI.Support_End_Date__c = mapCommitIdToONDOI.get(OI.Global_Commit_ID__c).Support_End_Date__c;
          orderItemToUpdate.put(OI.Id, OI);
        }
        if (OI.Create_Entitlement__c || (newOrd.Type == 'POC' && OI.product2.SBQQ__SubscriptionPricing__c != null)) {
          Boolean createEnt = true;
          system.debug(logginglevel.DEBUG, 'OIEntMap' + JSON.serialize(OIEntMap));
          /*** Third party products **/
          if (OIEntMap != null && OIEntMap.get(OI.id) != null) {
            for (Entitlement ent : OIEntMap.get(OI.id)) {
              if (ent.Type != 'Manufacturing Entitlement') {
                createEnt = false;
                break;
              }
            }
          }
          if (createEnt == false)
            continue;
          List<Entitlement> upsertEntitlements = new List<Entitlement>();
          if (
            (OI.Product2.Entitlement_Conversion_Non_CPQ__c != null && OI.Product2.Entitlement_Conversion_Non_CPQ__c.EqualsIgnoreCase('One per quote line')) ||
            (OI.Product2.SBQQSC__EntitlementConversion__c != null && OI.Product2.SBQQSC__EntitlementConversion__c.EqualsIgnoreCase('One per quote line'))
          ) {
            if (newOrd.Type == 'POC') {
              if (businessLogicCS.Follow_Existing_EntCreate_Process__c) {
                EntToInsert.add(createEntitlement(newOrd, OI, 'POC Entitlement', null, entitlementType, null));
              } else {
                OrdIdToSCorEntIds = UtilityClass.getupdatedOrdIdToScActionItemMap(newOrd, OrdIdToSCorEntIds, 'Create POC Entitlement');
              }
            } else {
              if (businessLogicCS.Follow_Existing_EntCreate_Process__c) {
                EntToInsert.add(createEntitlement(newOrd, OI, 'Custom Entitlement', null, null, null));
              } else {
                OrdIdToSCorEntIds = UtilityClass.getupdatedOrdIdToScActionItemMap(newOrd, OrdIdToSCorEntIds, 'Create Custom Entitlement');
              }
            }
          } else if (
            (OI.Product2.Entitlement_Conversion_Non_CPQ__c != null && OI.Product2.Entitlement_Conversion_Non_CPQ__c.EqualsIgnoreCase('One per unit')) ||
            (OI.Product2.SBQQSC__EntitlementConversion__c != null && OI.Product2.SBQQSC__EntitlementConversion__c.EqualsIgnoreCase('One per unit')) && OI.Quantity != null
          ) {
            List<string> SerialNums = new List<string>();
            if (oi.SBQQ__RequiredBy__c != null && oi.SBQQ__RequiredBy__r.SerialNumber__c != null) {
              SerialNums = oi.SBQQ__RequiredBy__r.SerialNumber__c.replaceAll('\\s+', '').split(',');
            }
            for (Integer i = 0; i < OI.Quantity; i++) {
              Id assetId = SerialNums.size() >= i + 1 ? serialNumAsset?.get(SerialNums[i])?.id : null;
              if (newOrd.Type == 'POC') {
                if (businessLogicCS.Follow_Existing_EntCreate_Process__c) {
                  EntToInsert.add(createEntitlement(newOrd, OI, 'POC Entitlement', null, entitlementType, assetId));
                } else {
                  OrdIdToSCorEntIds = UtilityClass.getupdatedOrdIdToScActionItemMap(newOrd, OrdIdToSCorEntIds, 'Create POC Entitlement');
                }
              } else {
                if (businessLogicCS.Follow_Existing_EntCreate_Process__c) {
                  EntToInsert.add(createEntitlement(newOrd, OI, 'Custom Entitlement', null, null, assetId));
                } else {
                  OrdIdToSCorEntIds = UtilityClass.getupdatedOrdIdToScActionItemMap(newOrd, OrdIdToSCorEntIds, 'Create Custom Entitlement');
                }
              }
            }
          }
        }
        if (oi.SerialNumber__c != null) {
          for (String SN : OI.SerialNumber__c.replaceAll('\\s+', '').split(',')) {
            Asset asst = serialNumAsset?.get(SN);
            if (oi.Create_Asset__c == true) {
              if (asst != null) {
                if (newOrd.Type != 'RMA') {
                  helper.errorLogs.add(
                    new Error_Logs__c(
                      Error_Type__c = 'Duplicate Asset',
                      Error_Message__c = 'Asset with Serial Number ' + SN + ' already Exists.Cannot create an Asset ',
                      Type__c = 'SFDC',
                      Related_Order__c = newOrd.id
                    )
                  );
                }
              } else {
                // Used mainly to insert the asset record
                Asset newAsset = new Asset();
                newAsset.Product2Id = oi.Product2Id;
                newAsset.SerialNumber = SN;
                newAsset.Serial_number__c = SN;
                newAsset.Name = SN;
                newAsset.Status = 'Purchased';
                newAsset.PurchaseDate = newOrd.Actual_Order_Ship_Date__c;
                newAsset.Location__c = newOrd.ShippingCity;
                newAsset.Order_Service_Item__c = oi.Id;
                newAsset.SBQQ__CombineKey__c = oi.Id;
                newAsset.AccountId = newOrd.accountID;
                newAsset.Distributor__c = newOrd.Bill_To_Name__c;
                newAsset.Quantity = 1;
                if (OI.SBQQ__QuoteLine__r.Rubrik_Suite__c != null) {
                  newAsset.Rubrik_Suite__c = OI.SBQQ__QuoteLine__r.Rubrik_Suite__c;
                }
                if (OI.SBQQ__QuoteLine__r.Support_Type__c != null) {
                  newAsset.Support_Type__c = OI.SBQQ__QuoteLine__r.Support_Type__c;
                }
                if (OI.SBQQ__QuoteLine__r.Payment_Options__c != null) {
                  newAsset.Payment_Options__c = OI.SBQQ__QuoteLine__r.Payment_Options__c;
                }
                if (OI.SBQQ__QuoteLine__r.Licensing_Model__c != null) {
                  newAsset.Licensing_Model__c = OI.SBQQ__QuoteLine__r.Licensing_Model__c;
                }
                assetToUpsert.put(SN, newAsset);
              }
            } else if (
              asst != null &&
              asst.Order_Service_Item__c != oi.Id &&
              OI.product2.Appliance_Model_HW__c != null &&
              (newOrd.Order_Sub_Type__c == 'POC' ||
              (newOrd.Type == 'Revenue' &&
              (newOrd.Order_Sub_Type__c == 'Demo' ||
              newOrd.Order_Sub_Type__c == null ||
              newOrd.Order_Sub_Type__c == 'MSP Consumption' ||
              newOrd.Order_Sub_Type__c == Constants.ORDER_SUB_TYPE_GC_OFFER ||
              (newOrd.Order_Sub_Type__c == 'Amendment' &&
              asst.Order_Service_Item__c == null))))
            ) {
              Asset asstupdate = assetToUpsert.containsKey(SN) ? assetToUpsert.get(SN) : new asset(id = asst.id);
              asstupdate.Product2Id = oi.Product2Id;
              asstupdate.Status = assetStatus;
              asstupdate.PurchaseDate = Date.today();
              asstupdate.InstallDate = newOrd.Actual_Order_Ship_Date__c;
              //for POC which doesn't have POC request
              asstupdate.Support_Start_Date__c = newOrd.Order_Sub_Type__c == 'POC'
                ? newOrd.POC_Request__c != null ? newOrd.Actual_Order_Ship_Date__c : null
                : parentItemId_SupportDates?.get(oi.id)?.get('startDate');
              asstupdate.Premium_Support_End_Date__c = newOrd.Order_Sub_Type__c == 'POC'
                ? newOrd.POC_Request__c != null ? newOrd?.POC_Completion_Date__c.addDays(7) : null
                : parentItemId_SupportDates?.get(oi.id)?.get('endDate');
              asstupdate.Location__c = newOrd.ShippingCity;
              asstupdate.Order_Service_Item__c = oi.Id;
              asstupdate.SBQQ__CombineKey__c = oi.Id;
              asstupdate.AccountId = newOrd.accountID;
              asstupdate.Distributor__c = newOrd.Bill_To_Name__c;
              asstupdate.Quantity = 1;

              if (OI.SBQQ__QuoteLine__r.Rubrik_Suite__c != null) {
                asstupdate.Rubrik_Suite__c = OI.SBQQ__QuoteLine__r.Rubrik_Suite__c;
              }
              if (OI.SBQQ__QuoteLine__r.Support_Type__c != null) {
                asstupdate.Support_Type__c = OI.SBQQ__QuoteLine__r.Support_Type__c;
              }
              if (OI.SBQQ__QuoteLine__r.Payment_Options__c != null) {
                asstupdate.Payment_Options__c = OI.SBQQ__QuoteLine__r.Payment_Options__c;
              }
              if (OI.SBQQ__QuoteLine__r.Licensing_Model__c != null) {
                asstupdate.Licensing_Model__c = OI.SBQQ__QuoteLine__r.Licensing_Model__c;
              }
              assetToUpsert.put(SN, asstupdate);
            } else if (
              asst != null &&
              newOrd.Type == 'Revenue' &&
              newOrd.Order_Sub_Type__c == 'Renewal' &&
              (asst.Premium_Support_End_Date__c < oi.Support_End_Date__c) &&
              ((String.isBlank(OI.Product2.Product_Level__c) || OI.Product2.Product_Level__c == 'Support') &&
              (String.isNotBlank(OI.Product2.Product_Type__c) && OI.Product2.Product_Type__c == 'HW Support'))
            ) {
              Asset asstupdate = assetToUpsert.containsKey(SN) ? assetToUpsert.get(SN) : new asset(id = asst.id);
              asstupdate.Premium_Support_End_Date__c = oi.Support_End_Date__c;
              assetToUpsert.put(SN, asstupdate);
            } else if (asst == null) {
              helper.errorLogs.add(
                new Error_Logs__c(Error_Type__c = 'Invalid SerialNumber', Error_Message__c = 'Invalid Serial Number :: ' + OI.SerialNumber__c, Related_Order__c = newOrd.id)
              );
            }
          }
        }
        if (oi.Trade_Up_SerialNumber__c != null) {
          for (String tradeUpSerialNumber : oi.Trade_Up_SerialNumber__c.replaceAll('\\s+', '').split(',')) {
            Asset assetWithTradeUpSNum = assetToUpsert.containsKey(tradeUpSerialNumber) ? assetToUpsert.get(tradeUpSerialNumber) : serialNumAsset?.get(tradeUpSerialNumber);
            if (assetWithTradeUpSNum != null) {
              assetWithTradeUpSNum.Free_HW_Refresh_Forfeited__c = true;
              assetToUpsert.put(tradeUpSerialNumber, assetWithTradeUpSNum);
            }
          }
        }
        if (
          newOrd.type == 'POC' &&
          ((OI.Product2.Appliance_Model_HW__c == null && OI.SBQQ__RequiredBy__c != null) || OI.Product2.SBQQ__SubscriptionTerm__c != null) &&
          (newOrd.Order_Sub_Type__c != 'Try N Buy' &&
          newOrd.POC_Type__c != 'Ransomware Recovery Software')
        ) {
          OrderItem OItoUpdate = orderItemToUpdate != null && orderItemToUpdate.containsKey(OI.id) ? orderItemToUpdate.get(OI.id) : new OrderItem();
          OItoUpdate.id = OI.id;
          OItoUpdate.Support_Start_Date__c = newOrd.Actual_Order_Ship_Date__c;
          OItoUpdate.Support_End_Date__c = newOrd?.POC_Completion_Date__c?.addDays(7);
          orderItemToUpdate.put(OI.id, OItoUpdate);
        }
      }
    }
    if (OrdIdToSCorEntIds.keyset().size() > 0) {
      Utilityclass.updateOrderFields(OrdIdToSCorEntIds.keyset(), Json.serialize(OrdIdToSCorEntIds));
    }
    system.debug(LoggingLevel.DEBUG, 'asset upsert' + assetToUpsert);
    system.debug(LoggingLevel.DEBUG, 'EntToInsert' + EntToInsert);
  }
  /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : Create custom entitlements
   * @param newOrd The new Order object record
   * @param OIList A list of OrderItem objects record
   * @param serialNumAsset A map that associates serial numbers with Asset records related to the order items.
   * @param trnOIIds A set of OrderItem IDs related to training SKUs that need to be processed.
   */
  public void captureMissingAssetsAndTrainingSkus(Order newOrd, List<OrderItem> OIList, Map<string, Asset> serialNumAsset, set<id> trnOIIds) {
    if (OIList != null && serialNumAsset != null) {
      for (OrderItem OI : OIList) {
        if (string.isNotBlank(OI.SerialNumber__c)) {
          for (string SN : OI.SerialNumber__c.replaceAll('\\s+', '').split(',')) {
            if (serialNumAsset.get(SN) == null && OI.Create_Asset__c == false) {
              newOrd.Assets_Missing_In_System__c = newOrd.Assets_Missing_In_System__c == null ? SN : SN + ',' + newOrd.Assets_Missing_In_System__c;
            }
          }
        }
        if ('RBK-SVC-TRN'.containsIgnoreCase(OI.product2.ProductCode) || TRAINING_PRODUCT.equalsIgnoreCase(OI.Product2.Product_Type__c)) {
          trnOIIds.add(OI.id);
        }
      }
      String assetSerialLimit = newOrd.Assets_Missing_In_System__c;
      if (assetSerialLimit != null && assetSerialLimit.length() > 255) {
        newOrd.Assets_Missing_In_System__c = assetSerialLimit.substring(0, 252) + '...';
      }
    }
  }
  /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : RMA Orders delinking and creating new spare parts
   * @param newOrd
   * @param OIList
   * @param serialNumAsset
   * @param assetNodesSN
   * @param serialNumNode
   * @param serialNumChassis
   * @param serialNumPSU
   * @param serialNumHDDSSD
   * @param serialNumMemory
   * @param assetToUpsert
   * @param nodeToUpdate
   * @param chasisToInsert
   * @param PSUToInsert
   * @param HDDSSDToInsert
   * @param memoryToInsert
   * @param failedAssetWithEntitlement
   * @param EntToUpdate
   */
  public void rMAProcessShippedOrders(
    Order newOrd,
    List<OrderItem> OIList,
    Map<string, Asset> serialNumAsset,
    Map<string, List<string>> assetNodesSN,
    Map<string, Node__c> serialNumNode,
    Map<string, Chassis__c> serialNumChassis,
    Map<string, Power_Supply__c> serialNumPSU,
    Map<string, Drive__c> serialNumHDDSSD,
    Map<string, Memory__c> serialNumMemory,
    Map<string, Asset> assetToUpsert,
    Map<Id, Node__c> nodeToUpdate,
    set<Chassis__c> chasisToInsert,
    set<Power_Supply__c> PSUToInsert,
    set<Drive__c> HDDSSDToInsert,
    set<Memory__c> memoryToInsert,
    Map<String, List<Entitlement>> failedAssetWithEntitlement,
    Map<Id, Entitlement> EntToUpdate
  ) {
    if (OIList != null) {
      system.debug(LoggingLevel.DEBUG, 'serialNumAsset' + JSON.serializePretty(serialNumAsset));
      system.debug(LoggingLevel.DEBUG, ' serialNumChassis' + JSON.serializePretty(serialNumChassis));
      for (OrderItem OI : OIList) {
        Asset asst = assetToUpsert != null && assetToUpsert.get(OI.SerialNumber__c) != null ? assetToUpsert.get(OI.SerialNumber__c) : serialNumAsset.get(OI.SerialNumber__c);
        if (asst != null && Label.Unassigned_Account_Id.contains(asst.accountId)) {
          asst.Product2Id = OI.Product2Id;
          asst.Status = 'Dispatched';
          asst.PurchaseDate = Date.today();
          asst.Location__c = newOrd.ShippingCity;
          asst.Order_Service_Item__c = OI.Id;
          asst.AccountId = newOrd.accountID;
          asst.Quantity = 1;
        }
        system.debug(LoggingLevel.DEBUG, 'asst' + asst);
        system.debug(LoggingLevel.DEBUG, '### OI.SerialNumber__c :' + OI.SerialNumber__c);
        system.debug(LoggingLevel.DEBUG, '### OI.Failed_Serial_Number__c :' + OI.Failed_Serial_Number__c);
        // PRDOPS23-17
        String prodSubtype;
        if (String.isBlank(OI.RMA_Component_Type__c) && !String.isBlank(OI.product2.Product_Subtype__c)) {
          prodSubtype = OI.product2.Product_Subtype__c;
        }
        if (OI.SerialNumber__c != null && oi.Failed_Serial_Number__c != null) {
          if (OI.RMA_Component_Type__c == 'Appliance' || prodSubtype == 'Appliance') {
            Id serialNumber = serialNumAsset?.get(OI.SerialNumber__c).Id;
            if (
              failedAssetWithEntitlement != null &&
              failedAssetWithEntitlement.containskey(serialNumAsset.get(OI.Failed_Serial_Number__c).Id) &&
              failedAssetWithEntitlement.get(serialNumAsset.get(OI.Failed_Serial_Number__c).Id) != null
            ) {
              for (Entitlement ent : failedAssetWithEntitlement.get(serialNumAsset.get(OI.Failed_Serial_Number__c).Id)) {
                Entitlement entt = EntToUpdate.containsKey(ent.id) ? EntToUpdate.get(ent.id) : new Entitlement(id = ent.id);
                entt.AssetId = serialNumber;
                EntToUpdate.put(ent.id, entt);
              }
            }
            assetToUpsert.put(asst.SerialNumber, asst);
          } else if (OI.RMA_Component_Type__c == 'Node' || prodSubtype == 'Node') {
            if (asst != null && serialNumNode != null) {
              asst.ParentId = serialNumNode.get(OI.Failed_Serial_Number__c)?.asset__c;
              asst.Support_Start_Date__c = serialNumNode.get(OI.Failed_Serial_Number__c)?.asset__r?.Support_Start_Date__c;
              asst.Premium_Support_End_Date__c = serialNumNode.get(OI.Failed_Serial_Number__c)?.asset__r?.Premium_Support_End_Date__c;
              assetToUpsert.put(asst.SerialNumber, asst);
            }
            system.debug(LoggingLevel.DEBUG, 'RMA assetNodesSN' + assetNodesSN);
            if (assetNodesSN != null && assetNodesSN.get(OI.SerialNumber__c) != null)
              for (string nodeSN : assetNodesSN.get(OI.SerialNumber__c)) {
                Node__c node = new Node__c();
                node.Id = serialNumNode.get(nodeSN)?.id;
                node.chassis__c = serialNumNode.get(OI.Failed_Serial_Number__c).chassis__c;
                nodeToUpdate.put(node.Id, node);
              }
          } else if (OI.RMA_Component_Type__c == 'Chassis' || prodSubtype == 'Chassis') {
            if (serialNumChassis != null) {
              if (!serialNumChassis.containsKey(OI.SerialNumber__c)) {
                chasisToInsert.add(
                  new Chassis__c(Name = OI.SerialNumber__c, serial_number__c = OI.SerialNumber__c, asset__c = serialNumChassis?.get(OI.Failed_Serial_Number__c)?.asset__c)
                );
              }
              if (asst != null) {
                asst.ParentId = serialNumChassis?.get(OI.Failed_Serial_Number__c)?.asset__c;
                asst.Support_Start_Date__c = serialNumChassis.get(OI.Failed_Serial_Number__c)?.asset__r?.Support_Start_Date__c;
                asst.Premium_Support_End_Date__c = serialNumChassis.get(OI.Failed_Serial_Number__c)?.asset__r?.Premium_Support_End_Date__c;
                assetToUpsert.put(asst.SerialNumber, asst);
              }
            }
          } else if (OI.RMA_Component_Type__c == 'PSU' || prodSubtype == 'PSU') {
            if (serialNumPSU != null) {
              Power_Supply__c FailedPSU = serialNumPSU.get(OI.Failed_Serial_Number__c);
              if (!serialNumPSU.containsKey(OI.SerialNumber__c)) {
                PSUToInsert.add(
                  new Power_Supply__c(
                    Name = OI.SerialNumber__c,
                    serial_number__c = OI.SerialNumber__c,
                    asset__c = FailedPSU?.asset__c,
                    revision__c = FailedPSU?.revision__c,
                    part_number__c = FailedPSU?.part_number__c
                  )
                );
              }
              if (asst != null && FailedPSU != null) {
                asst.ParentId = FailedPSU.asset__c;
                asst.Support_Start_Date__c = FailedPSU.asset__r?.Support_Start_Date__c;
                asst.Premium_Support_End_Date__c = FailedPSU.asset__r?.Premium_Support_End_Date__c;
                assetToUpsert.put(asst.SerialNumber, asst);
              }
            }
          } else if (OI.RMA_Component_Type__c == 'HDD' || OI.RMA_Component_Type__c == 'SSD' || (prodSubtype == 'SSD' || prodSubtype == 'HDD')) {
            if (serialNumHDDSSD != null) {
              Drive__c FailedDrive = serialNumHDDSSD.get(OI.Failed_Serial_Number__c);
              if (!serialNumHDDSSD.containsKey(OI.SerialNumber__c)) {
                HDDSSDToInsert.add(
                  new Drive__c(
                    Name = OI.SerialNumber__c,
                    serial_number__c = OI.SerialNumber__c,
                    asset__c = FailedDrive?.asset__c,
                    type__c = FailedDrive?.type__c,
                    capacity__c = FailedDrive?.capacity__c,
                    node__c = FailedDrive?.node__c
                  )
                );
              }
              if (asst != null && FailedDrive != null) {
                asst.ParentId = FailedDrive.asset__c;
                asst.Support_Start_Date__c = FailedDrive.asset__r?.Support_Start_Date__c;
                asst.Premium_Support_End_Date__c = FailedDrive.asset__r?.Premium_Support_End_Date__c;
                assetToUpsert.put(asst.SerialNumber, asst);
              }
            }
          } else if (OI.RMA_Component_Type__c == 'Memory' || prodSubtype == 'Memory') {
            if (serialNumMemory != null) {
              Memory__c failedMemory = serialNumMemory.get(OI.Failed_Serial_Number__c);
              if (!serialNumMemory.containsKey(OI.SerialNumber__c)) {
                memoryToInsert.add(
                  new Memory__c(Name = OI.SerialNumber__c, serial_number__c = OI.SerialNumber__c, asset__c = failedMemory.asset__c, node__c = failedMemory.node__c)
                );
              }
              if (asst != null && failedMemory != null) {
                asst.ParentId = failedMemory.asset__c;
                asst.Support_Start_Date__c = failedMemory.asset__r?.Support_Start_Date__c;
                asst.Premium_Support_End_Date__c = failedMemory.asset__r?.Premium_Support_End_Date__c;
                assetToUpsert.put(asst.SerialNumber, asst);
              }
            }
          }
          system.debug(LoggingLevel.DEBUG, 'assetToUpsert' + JSON.serializePretty(assetToUpsert));
          system.debug(LoggingLevel.DEBUG, 'nodeToUpdate' + JSON.serializePretty(nodeToUpdate));
          system.debug(LoggingLevel.DEBUG, 'chasisToInsert' + JSON.serializePretty(chasisToInsert));
          system.debug(LoggingLevel.DEBUG, 'PSUToInsert' + JSON.serializePretty(PSUToInsert));
          system.debug(LoggingLevel.DEBUG, 'HDDSSDToInsert' + JSON.serializePretty(HDDSSDToInsert));
          system.debug(LoggingLevel.DEBUG, 'memoryToInsert' + JSON.serializePretty(memoryToInsert));
        }
      }
    }
  }
  /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : create custom entitlement
   * @param newOrd
   * @param OI
   * @param Type
   * @param proId
   * @param entType
   * @param assetId
   * @return Entitlement record
   */
  private Entitlement createEntitlement(Order newOrd, OrderItem OI, string Type, Id proId, string entType, Id assetId) {
    Entitlement ent = new Entitlement(
      AccountId = OI.Order.AccountId,
      Product__c = OI.product2Id,
      Name = OI.Product2.ProductCode,
      Order_Service_Item__c = OI.Id,
      Partner_Name__c = newOrd.Partner_Name__c
    );
    if (Type == 'Manufacturing Entitlement') {
      ent.Type = 'Manufacturing Entitlement';
      ent.Integration_Partner_Contact_Name__c = newOrd.Integration_Partner_Contact_Name__c;
      ent.Manufacturing_Integration_Partner__c = newOrd.Manufacturing_Integration_Partner__c;
      ent.Primary_Contact__c = newOrd.Welcome_Letter_Contact__c;
      ent.Product__c = proId;
      if (newOrd.Type == 'POC') {
        ent.StartDate = newOrd.Actual_Order_Ship_Date__c;
        ent.EndDate = newOrd?.POC_Completion_Date__c?.addDays(7);
      }
      if (newOrd.Order_Sub_Type__c == Constants.ORDER_SUB_TYPE_GC_OFFER) {
        ent.Quantity__c = String.isNotBlank(oi.TPH_Quantity__c) ? Decimal.valueOf(oi.TPH_Quantity__c) : 0;
      }
    } else if (Type == 'Custom Entitlement' && TRAINING_PRODUCT.equalsIgnoreCase(OI.Product2.Product_Type__c)) {
      ent.StartDate = system.today();
      ent.EndDate = system.today().addYears(1); // SF-7762
      ent.AssetId = assetId;
    } else if (Type == 'POC Entitlement') {
      ent.StartDate = newOrd.Order_sub_type__c == 'Try N Buy' ? oi.Support_Start_Date__c : newOrd.Actual_Order_Ship_Date__c;
      ent.EndDate = newOrd.Order_sub_type__c == 'Try N Buy' ? oi.Support_End_Date__c : newOrd?.POC_Completion_Date__c?.addDays(7);
      ent.Type = entType;
      ent.AssetId = assetId;
    }
    return ent;
  }
  /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : update Partner name on entitlements
   * @param entLists
   * @param EntToUpdate
   */
  public void updateEntitlementsPartner(List<List<Entitlement>> entLists, Map<Id, Entitlement> EntToUpdate) {
    if (entLists != null)
      for (List<Entitlement> entList : entLists) {
        for (Entitlement ent : entList) {
          if (ent.Partner_Name__c == null && ent.Order_Service_Item__c != null && ent.Order_Service_Item__r.order.Partner_Name__c != null) {
            EntToUpdate.put(ent.id, new Entitlement(id = ent.id, Partner_Name__c = ent?.Order_Service_Item__r?.order?.Partner_Name__c));
          }
        }
      }
    system.debug(LoggingLevel.DEBUG, 'EntToUpdate' + EntToUpdate);
  }
  /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : Create PS Project MKT22-378 Changes are made
   * @param newOrd
   * @param PSExternalRecId
   * @param PSProjects
   * @param acc
   * @param primaryOCR
   * @param PSProjToInsert
   * @param oppToPSProjectCount
   */
  public void createPSProject(
    Order newOrd,
    Id PSExternalRecId,
    List<PS_Project__c> PSProjects,
    Account acc,
    OpportunityContactRole primaryOCR,
    set<PS_Project__c> PSProjToInsert,
    Map<Id, Integer> oppToPSProjectCount,
    Map<Id, List<PS_Project__c>> accIdPSProjects
  ) {
    try {
      Opportunity opp = newOrd.type == 'POC' ? helper.oppMap?.get(newOrd.POC_Opportunity__c) : helper.oppMap?.get(newOrd.OpportunityId);
      // MKT22-378: Initialize with the existing count
      Integer index = oppToPSProjectCount.containsKey(opp.Id) ? oppToPSProjectCount.get(opp.Id) : 0;
      System.debug(LoggingLevel.INFO, 'PSProjects :: ' + PSProjects);
      Map<Id, List<PS_Project__c>> oppIdToPsProjectListMap = new Map<Id, List<PS_Project__c>>();
      if (PSProjects != null) {
        for (PS_Project__c proj : PSProjects) {
            if(!oppIdToPsProjectListMap.containsKey(proj.Opportunity__c)){
                oppIdToPsProjectListMap.put(proj.Opportunity__c, new List<PS_Project__c>());
            }
            oppIdToPsProjectListMap.get(proj.Opportunity__c).add(proj);
        }
          index = oppIdToPsProjectListMap.containsKey(newOrd.OpportunityId) ? oppIdToPsProjectListMap.get(newOrd.OpportunityId).size() : index;
      }
      index++;
      PS_Project__c proj = new PS_Project__c();
      String trimmedName;
      if (opp != null) {
        trimmedName = acc.Name + ' - ' + opp.name + '(' + index + ')';
      } else {
        trimmedName = acc.Name + '(' + index + ')';
      }
      if (trimmedName.length() > Schema.SObjectType.PS_Project__c.fields.Name.getLength()) {
        trimmedName = trimmedName.left(Schema.SObjectType.PS_Project__c.fields.Name.getLength() - 6) + '...' + '(' + index + ')';
      }
      proj.Name = trimmedName;
      /*system.debug(LoggingLevel.FINE,'Account.BillingState '+acc.BillingState+'\n Account_Billing_Address_Region__c '+newOrd.Account_Billing_Address_Region__c);
            if(acc.BillingState != null && acc.BillingCountry == 'United States') {
                String psProjectManagerMappingString = acc.BillingCountry+'-'+acc.BillingState;
                system.debug(LoggingLevel.FINE,'psProjectManagerMappingString '+psProjectManagerMappingString);
                if(acc.ETM_Area__c == 'AMER-FED') {
              psProjectManagerMappingString = acc.ETM_Area__c;
          }
          else if(acc.ETM_Area__c.contains('AMER-SLED')) {
              psProjectManagerMappingString = 'AMER-SLED';
          }
          else if (acc.BillingState == 'United States Minor Outlying Islands') {
              psProjectManagerMappingString = 'United States Minor Outlying Islands';
          }
                PS_Project_Manager_Mapping__c psProjectManagerMapping = PS_Project_Manager_Mapping__c.getValues(psProjectManagerMappingString);
                if(psProjectManagerMapping != null && psProjectManagerMapping.Project_Manager_User_Id__c != null) {
                    proj.Project_Manager__c = psProjectManagerMapping.Project_Manager_User_Id__c;
                }
            }
            else if( acc.BillingCountry != null && newOrd.Account_Billing_Address_Region__c != null) {
                PS_Project_Manager_Mapping__c psProjectManagerMapping = PS_Project_Manager_Mapping__c.getValues(newOrd.Account_Billing_Address_Region__c);
                if(psProjectManagerMapping != null && psProjectManagerMapping.Project_Manager_User_Id__c != null) {
                    proj.Project_Manager__c = psProjectManagerMapping.Project_Manager_User_Id__c;
                }
            }*/
      Id projectManager = psService.routePSProjectManager(newOrd);
      if ( !PSTaskService.setRubrikUOrderId.contains(newOrd.Id) && acc.PS_Project_Manager__c != null && acc.PS_Project_Manager__r.IsActive) { //Added for MKT26-773
        proj.Project_Manager__c = acc.PS_Project_Manager__c;
      } else if (projectManager != null) {
        proj.Project_Manager__c = projectManager;
      }
      proj.RecordTypeId = PSExternalRecId;
      proj.Project_Status__c = 'Not Started';
      proj.Project_Expected_Start_Date__c = system.today();
      proj.Project_Expected_End_Date__c = system.today();
      proj.Billable_Hours_Override__c = false;
      proj.Account__c = newOrd.AccountId;
      proj.Welcome_Letter_Contact__c = primaryOCR?.ContactId;
      proj.opportunity__c = opp?.Id;
      proj.PO_Number__c = newOrd.PONumber;
      PSProjToInsert.add(proj);
        if (accIdPSProjects.containsKey(proj.Account__c)) {
            accIdPSProjects.get(proj.Account__c).add(proj);
        } else {
            accIdPSProjects.put(proj.Account__c, new List<PS_Project__c>{ proj });
        }
      projNameOrdId.put(proj.name, newOrd.id);
    } catch (Exception ex) {
      System.debug(LoggingLevel.Error, 'err' + ex.getMessage());
      helper.errorLogs.add(new Error_Logs__c(Error_Type__c = 'Failure on createPSProject', Error_Message__c = ex.getMessage(), Type__c = 'SFDC', Related_Order__c = newOrd.id));
    }
  }

  /**
    @description : Create PS Tasks
    Consult_Onsite :  RBK-PS-CNSLT-ONST
    Consult_Remote :RBK-PS-CNSLT-RMOT
    InstallProducts:RBK-PS-INST
    TE  : RBK-PS-TE
    MigrationProducts:  RBK-DATA-MIGRATION
    ConsultProducts : RBK-PS-CONSULT
    reProducts : RBK-PS-RES
    * @param newOrd
    * @param OIList
    * @param psTaskToInsert
    * @param orderItemToUpdate
    */
  public void createPSTask(Order newOrd, List<OrderItem> OIList, set<PS_Task__c> psTaskToInsert, Map<Id, orderItem> orderItemToUpdate) {
    /* set<string> Consult_Onsite = new set<string>();
        set<string> Consult_Remote = new set<string>();
        set<string> TE = new set<string>();
        set<string> installProducts = new set<string>();
        set<string> migrationProducts = new set<string>();
        set<string> consultProducts = new set<string>();
        set<string> reProducts = new set<string>();

        Consult_Onsite.AddAll(Label.Consult_Onsite.Split(','));
        Consult_Remote.AddAll(Label.Consult_Remote.Split(','));
        installProducts.AddAll(Label.RBK_INSTALL.Split(','));
        TE.AddAll(Label.RBK_T_E.Split(','));
        migrationProducts.AddAll(Label.RBK_DATA_MIGRATION.Split(','));
        consultProducts.AddAll(Label.RBK_CONSULT.Split(','));
        reProducts.AddAll(Label.RBK_PS_RES.Split(','));*/
    Date todayDate = system.today();
    Date cutOffDate = Date.newInstance(todayDate.year(), todayDate.month(), 25);
    if (OIList != null)
      for (OrderItem OI : OIList) {
        if (OI.Product2.Allow_PSO_Task_Creation__c == true) {
          String uniqueString = OI.orderItemNumber + Datetime.now().millisecond();

          PS_Task__c task = new PS_Task__c(
            Task_Status__c = 'Not Started',
            Project__c = newOrd.PS_Project__c,
            Order_Item__c = OI.Id,
            Order_Number__c = newOrd.OrderNumber,
            SKU_Name__c = OI.Product2.Name
          );
          if (PS_Task_Meta__mdt.getInstance(OI.Product2.ProductCode.replace('-', '_')) != null) {
            PS_Task_Meta__mdt meta = PS_Task_Meta__mdt.getInstance(OI.Product2.ProductCode.replace('-', '_'));
            task.Task_Type__c = meta.Task_Type__c;
            task.Revenue_Type__c = meta.Revenue_Type__c;
            task.Unique_External_ID__c = uniqueString + meta.Task_Type__c;
            task.Billable_Hours_Expected__c = meta.Billable_Hours__c != null ? (OI.Quantity * meta.Billable_Hours__c) : null;
            if (meta.End_Date__c == '1 Year') {
              task.Task_End_date__c = system.today().addYears(1);
            } else if (meta.End_Date__c == '6 Months') {
              task.Task_End_date__c = system.today().addMonths(6) - 1;
            }
            if (meta.Account__c) {
              task.Account__c = newOrd.AccountId;
            }
            if (meta.Consult_Quantity__c) {
              task.Consult_Quantity__c = OI.Quantity;
            }
            if (meta.Start_Date__c == 'Formula') {
              //RBK-T&E*
              task.Task_Start_Date__c = OI.Required_by_Product_Code__c != 'RBK-PS-RES' ? system.today() : null;
            } else if (meta.Start_Date__c == 'Today') {
              task.Task_Start_Date__c = System.today();
            } else if (meta.Start_Date__c == 'Null') {
              task.Task_Start_Date__c = null;
            } else if (meta.Start_Date__c == '6 Months') {
              task.Task_Start_Date__c = System.today().addMonths(6);
            }

            if (task.Task_Type__c != null && task.Task_Type__c.contains('Non-Billable')) {
              task.Sync_to_Net_Suite__c = 'No Sync Required';
            }
            if (meta.OrderItem_Update__c) {
              if (newOrd.Actual_Order_Ship_Date__c != null) {
                OrderItem OItoUpdate = orderItemToUpdate != null && orderItemToUpdate.containsKey(OI.id) ? orderItemToUpdate.get(OI.id) : new OrderItem();
                OItoUpdate.id = OI.id;
                OItoUpdate.Support_Start_Date__c = newOrd.Actual_Order_Ship_Date__c;
                OItoUpdate.Support_End_Date__c = newOrd.Actual_Order_Ship_Date__c.addMonths(6) - 1;
                orderItemToUpdate.put(OI.id, OItoUpdate);
              }
            }
          }

          /*PS_Task__c task= new PS_Task__c(Billable_Hours_Expected__c = OI.Quantity * 8,
                                                    Task_Status__c = 'Not Started',
                                                    Project__c = newOrd.PS_Project__c,
                                                    Task_Start_Date__c  = system.today(),
                                                    Order_Item__c = OI.Id);
                    if(OI.Product2.ProductCode =='RBK-INSTALL'){ //Old SKU INSTALL
                        task.Task_Start_Date__c  = null;//New Changes
                        task.Task_Type__c='Install';
                        task.Unique_External_ID__c = uniqueString;
                    }
                    else if(OI.Product2.ProductCode == 'RBK-CONSULT'){  //Old SKU CONSULT
                        task.Task_Start_Date__c  = null;//New Changes
                        task.Task_Type__c='Consult';
                        task.Consult_Quantity__c = OI.Quantity;
                        task.Unique_External_ID__c = uniqueString+'CONSULT';
                    }
                    else if(Consult_Onsite.Contains(OI.Product2.ProductCode)){  //CONSULT-ONSITE
                        task.Task_Type__c='Consult-Onsite';
                        task.Consult_Quantity__c = OI.Quantity;
                        task.Unique_External_ID__c = uniqueString+'Consult-Onsite';
                        if(OI.Product2.ProductCode.contains('ONST-PD')){
                            task.Task_Type__c='Consult-Onsite-PD';
                        }
                    }
                    else if( Consult_Remote.Contains(OI.Product2.ProductCode)) {  //CONSULT-REMOTE
                        task.Task_Type__c='Consult-Remote';
                        task.Consult_Quantity__c = OI.Quantity;
                        task.Unique_External_ID__c = uniqueString+'Consult-Remote';
                        if(OI.Product2.ProductCode.contains('RMOT-PD')){
                            task.Task_Type__c='Consult-Remote-PD';
                        }
                    }

                    else if( TE.Contains(OI.Product2.ProductCode)) {  //RBK-T&E*
                        task.Task_Type__c='T&E';
                        task.Billable_Hours_Expected__c = 0;
                        task.Task_Start_Date__c  = OI.Required_by_Product_Code__c != 'RBK-PS-RES' ? system.today() : null;
                        task.Consult_Quantity__c = OI.Quantity;
                        task.Unique_External_ID__c = uniqueString+'TE';
                    }
                    else if(installProducts.Contains(OI.Product2.ProductCode)) { // RBK-INSTALL-RE
                        task.Task_Type__c='Install';
                        task.Billable_Hours_Expected__c = OI.Quantity * 12;
                        task.Account__c = newOrd.AccountId;
                        task.Consult_Quantity__c = OI.Quantity;
                        task.Task_End_date__c    = system.today().addMonths(6)-1;
                        task.Unique_External_ID__c = uniqueString+'INSTALL';
                        if(OI.Product2.ProductCode.Contains('RCDM')){//RBK-PS-RCDM-INST - Billable - 1hrs
                            task.Billable_Hours_Expected__c = OI.Quantity * 1;
                            task.Task_Type__c='RCDM-Install';
                        }
                        if(OI.Product2.ProductCode.contains('INST-PD')){
                            task.Task_Type__c='Install-PD';
                        }
                        if(newOrd.Actual_Order_Ship_Date__c != null){
                            OrderItem OItoUpdate = orderItemToUpdate!=null && orderItemToUpdate.containsKey(OI.id) ? orderItemToUpdate.get(OI.id) : new OrderItem();
                            OItoUpdate.id =OI.id ;
                            OItoUpdate.Support_Start_Date__c = newOrd.Actual_Order_Ship_Date__c ; // OI.servicedate
                            OItoUpdate.Support_End_Date__c = newOrd.Actual_Order_Ship_Date__c.addMonths(6)-1; //OI.enddate
                            orderItemToUpdate.put(OI.id,OItoUpdate);
                        }
                    }
                    else if(migrationProducts.Contains(OI.Product2.ProductCode)) { // RBK-DATA-MIGRATION
                        task.Task_Type__c='Migration';
                        task.Billable_Hours_Expected__c = 0;
                        task.Consult_Quantity__c = OI.Quantity;
                        task.Unique_External_ID__c = uniqueString+'MIGRATION';
                        task.Account__c = newOrd.AccountId ;
                        task.Task_End_date__c = system.today().addYears(1);// New Changes
                    }
                    else if(reProducts.Contains(OI.Product2.ProductCode)) { // RBK-CONSULT-RE
                        task.Task_Type__c    ='Resident Engineer';
                        task.Account__c = newOrd.AccountId;
                        task.Task_Start_Date__c  = null;
                        task.Consult_Quantity__c = OI.Quantity;
                        task.Unique_External_ID__c = uniqueString+'Resident Engineer';
                        if(OI.Product2.ProductCode.contains('RBK-PS-RES-PD')){
                            task.Task_Type__c='Resident Engineer-PD';
                        }
                    }
                    else if(consultProducts.Contains(OI.Product2.ProductCode)) {
                        task.Task_Type__c='Consult';
                        task.Account__c = newOrd.AccountId;
                        task.Consult_Quantity__c = OI.Quantity;
                        task.Task_End_date__c    = system.today().addMonths(6)-1;
                        task.Unique_External_ID__c = uniqueString+'CONSULT';
                        if(newOrd.Actual_Order_Ship_Date__c != null){
                            OrderItem OItoUpdate = orderItemToUpdate!=null && orderItemToUpdate.containsKey(OI.id) ? orderItemToUpdate.get(OI.id) : new OrderItem();
                            OItoUpdate.id =OI.id ;
                            OItoUpdate.Support_Start_Date__c = newOrd.Actual_Order_Ship_Date__c ;
                            OItoUpdate.Support_End_Date__c = newOrd.Actual_Order_Ship_Date__c.addMonths(6)-1;
                            orderItemToUpdate.put(OI.id,OItoUpdate);
                        }

                    }*/
          if (task.Task_Type__c != null) {
            psTaskToInsert.add(task);
          }
        }
      }
  }
  /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : recalculate price on cancelling/updating order
   * @param newOrd
   * @param BLIList
   * @param bookingId
   * @param bookingToUpdate
   * @param BLIToUpdate
   * @param BLIToInsert
   * @param newOIList
   * @param mapBKgIdToNetRenewal
   * @param mapBKgIdToNetNew
   * @param mapBKgIdToGrossACVAmt
   * @param mapBKgIdToGrossNewACV
   * @param mapBKgIdToGrossRenewalACV
   */
  public void resyncBooking(
    Order newOrd,
    List<Booking_Line_Item__c> BLIList,
    Id bookingId,
    Map<Id, booking__c> bookingToUpdate,
    Map<Id, Booking_Line_Item__c> BLIToUpdate,
    set<Booking_Line_Item__c> BLIToInsert,
    List<OrderItem> newOIList,
    Map<Id, Decimal> mapBKgIdToNetRenewal,
    Map<Id, Decimal> mapBKgIdToNetNew,
    Map<Id, Decimal> mapBKgIdToGrossACVAmt,
    Map<Id, Decimal> mapBKgIdToGrossNewACV,
    Map<Id, Decimal> mapBKgIdToGrossRenewalACV
  ) {
    if (newOrd.Order_Status__c == 'Rejected') {
      for (Booking_Line_Item__c BLI : BLIList) {
        BLI.Total_Price__c = BLI.Total_List_Price__c = BLI.New_Expansion_TCV__c = BLI.Subsumed_Renewal_TCV__c = BLI.Gross_ACV_Amount__c = BLI.Gross_New_Expansion_ACV__c = BLI.Gross_Subsumed_Renewal_ACV__c = 0.0;
        BLIToUpdate.put(BLI.id, BLI);
      }
      BookingToUpdate.put(bookingId, new Booking__c(id = bookingId, Status__c = 'Cancelled'));
    } else {
      Map<Id, Decimal> mapOrderIdToRebate = new Map<Id, Decimal>();
      for (Booking_Line_Item__c BLI : BLIList) {
        if (BLI.Type__c == 'Distributor Fee') {
          Decimal rebate = newOrd.TotalAmount * BLI.Rebate__c * -0.01;

          if (!mapOrderIdToRebate.containsKey(newOrd.Id)) {
            mapOrderIdToRebate.put(newOrd.Id, BLI.Rebate__c);
          }
          if (rebate != BLI.Total_Price__c) {
            BLIToUpdate.put(
              BLI.id,
              new Booking_Line_Item__c(
                id = BLI.id,
                Total_Price__c = rebate,
                Subsumed_Renewal_TCV__c = mapBKgIdToNetRenewal.containsKey(BLI.Booking__c) && mapBKgIdToNetRenewal.get(BLI.Booking__c) != null
                  ? mapBKgIdToNetRenewal.get(BLI.Booking__c) * BLI.Rebate__c * -0.01
                  : BLI.Subsumed_Renewal_TCV__c,
                New_Expansion_TCV__c = mapBKgIdToNetNew.containsKey(BLI.Booking__c) && mapBKgIdToNetNew.get(BLI.Booking__c) != BLI.New_Expansion_TCV__c
                  ? mapBKgIdToNetNew.get(BLI.Booking__c) * BLI.Rebate__c * -0.01
                  : BLI.New_Expansion_TCV__c,
                Gross_ACV_Amount__c = mapBKgIdToGrossACVAmt.containsKey(BLI.Booking__c) && mapBKgIdToGrossACVAmt.get(BLI.Booking__c) != BLI.Gross_ACV_Amount__c
                  ? mapBKgIdToGrossACVAmt.get(BLI.Booking__c) * BLI.Rebate__c * -0.01
                  : BLI.Gross_ACV_Amount__c,
                Gross_New_Expansion_ACV__c = mapBKgIdToGrossNewACV.containsKey(BLI.Booking__c) && mapBKgIdToGrossNewACV.get(BLI.Booking__c) != BLI.Gross_New_Expansion_ACV__c
                  ? mapBKgIdToGrossNewACV.get(BLI.Booking__c) * BLI.Rebate__c * -0.01
                  : BLI.Gross_New_Expansion_ACV__c,
                Gross_Subsumed_Renewal_ACV__c = mapBKgIdToGrossRenewalACV.containsKey(BLI.Booking__c) &&
                  mapBKgIdToGrossRenewalACV.get(BLI.Booking__c) != BLI.Gross_Subsumed_Renewal_ACV__c
                  ? mapBKgIdToGrossRenewalACV.get(BLI.Booking__c) * BLI.Rebate__c * -0.01
                  : BLI.Gross_Subsumed_Renewal_ACV__c
              )
            );
          }
          break;
        }
      }

      if (newOIList != null) {
        for (OrderItem OI : newOIList) {
          system.debug(LoggingLevel.DEBUG, '::OI::' + OI.TotalPrice);
          Decimal qtyFactor = (OI.Opportunity_Product__c != null &&
            OI.Quantity != null &&
            OI.Quantity != 0.0 &&
            OI.Opportunity_Product__r.Quantity != null)
            ? OI.Quantity / OI.Opportunity_Product__r?.Quantity
            : 1;
          Decimal Net_TCV_Amount = 0.00;
          Decimal Net_New_Expansion_TCV = 0.00;
          Decimal Net_Subsumed_Renewal_TCV = 0.00;
          Decimal Net_ACV_Amount = 0.00;
          Decimal Net_New_Expansion_ACV = 0.00;
          Decimal Net_Subsumed_Renewal_ACV = 0.00;
          if (mapOrderIdToRebate.containsKey(OI.orderId) && mapOrderIdToRebate.get(OI.orderId) != null) {
            Net_TCV_Amount = OI.TotalPrice != null && mapOrderIdToRebate.containsKey(OI.orderId) ? OI.TotalPrice * ((100 - mapOrderIdToRebate.get(OI.orderId)) * 0.01) : 0.0;
            Net_New_Expansion_TCV = OI.Opportunity_Product__r?.New_Expansion_TCV__c != null
              ? OI.Opportunity_Product__r.New_Expansion_TCV__c * ((100 - mapOrderIdToRebate.get(OI.orderId)) * 0.01)
              : 0.0;
            Net_Subsumed_Renewal_TCV = OI.Opportunity_Product__r?.Subsumed_Renewal_TCV__c != null
              ? (OI.Opportunity_Product__r.Subsumed_Renewal_TCV__c) * ((100 - mapOrderIdToRebate.get(OI.orderId)) * 0.01)
              : 0.0;

            Net_ACV_Amount = OI.Opportunity_Product__r?.ACV_Amount__c != null
              ? OI.Opportunity_Product__r?.ACV_Amount__c * ((100 - mapOrderIdToRebate.get(OI.orderId)) * 0.01)
              : 0.0;
            Net_New_Expansion_ACV = OI.Opportunity_Product__r.New_Expansion_ACV__c != null
              ? OI.Opportunity_Product__r.New_Expansion_ACV__c * ((100 - mapOrderIdToRebate.get(OI.orderId)) * 0.01)
              : 0.0;
            Net_Subsumed_Renewal_ACV = OI.Opportunity_Product__r.SubsRenAmt__c != null
              ? OI.Opportunity_Product__r.SubsRenAmt__c * ((100 - mapOrderIdToRebate.get(OI.orderId)) * 0.01)
              : 0.0;
          }

          if (OI.Booking_Line_Items__r.isEmpty()) {
            BLIToInsert.add(
              new Booking_Line_Item__c(
                Booking__c = bookingId,
                Total_Price__c = OI.TotalPrice,
                Type__c = 'Revenue',
                Impacts_Gross_Bookings__c = true,
                Impacts_Net_Bookings__c = true,
                Impacts_Commission__c = true,
                Product_Code__c = OI.Product2.ProductCode,
                Total_List_Price__c = OI.SBQQ__QuoteLine__r.SBQQ__ListTotal__c,
                Total_Discount__c = OI.SBQQ__QuoteLine__r.SBQQ__TotalDiscountRate__c,
                Product2_Description__c = OI.Product2.Description,
                Product_Quantity__c = OI.Quantity,
                Subscription_Term__c = OI.SBQQ__SubscriptionTerm__c,
                Product_Payment_Option__c = OI.Product2.Product_Payment_Option__c,
                Product_Name__c = OI.Product2Id,
                Product_Category__c = OI.Product2.Category__c,
                License_Type__c = OI.Product2.License_Type__c,
                Product_Family__c = OI.Product2.Family,
                OrderProduct__c = OI.id,
                New_Expansion_TCV__c = OI.Opportunity_Product__r?.New_Expansion_TCV__c == null ? 0.0 : (OI.Opportunity_Product__r?.New_Expansion_TCV__c * qtyFactor),
                Subsumed_Renewal_TCV__c = OI.Opportunity_Product__r?.Subsumed_Renewal_TCV__c == null ? 0.0 : (OI.Opportunity_Product__r?.Subsumed_Renewal_TCV__c * qtyFactor),
                Gross_ACV_Amount__c = OI.Opportunity_Product__r?.ACV_Amount__c != null ? (OI.Opportunity_Product__r?.ACV_Amount__c) : 0.0,
                Gross_New_Expansion_ACV__c = OI.Opportunity_Product__r.New_Expansion_ACV__c != null ? (OI.Opportunity_Product__r.New_Expansion_ACV__c) : 0.0,
                Gross_Subsumed_Renewal_ACV__c = OI.Opportunity_Product__r.SubsRenAmt__c != null ? (OI.Opportunity_Product__r.SubsRenAmt__c) : 0.0,
                Net_TCV_Amount__c = Net_TCV_Amount,
                Net_New_Expansion_TCV__c = Net_New_Expansion_TCV,
                Net_Subsumed_Renewal_TCV__c = Net_Subsumed_Renewal_TCV,
                Net_ACV_Amount__c = Net_ACV_Amount,
                Net_New_Expansion_ACV__c = Net_New_Expansion_ACV,
                Net_Subsumed_Renewal_ACV__c = Net_Subsumed_Renewal_ACV,
                PromoDiscTCV__c = OI.Opportunity_Product__r?.PromoDiscTCV__c != null ? (OI.Opportunity_Product__r?.PromoDiscTCV__c * qtyFactor) : 0.0,
                Prepayment_Credit__c = OI.Opportunity_Product__r?.Prepayment_Credit__c != null ? (OI.Opportunity_Product__r?.Prepayment_Credit__c * qtyFactor) : 0.0,
                Oppty_Trade_Up_Discount__c = OI.Opportunity_Product__r?.Oppty_Trade_Up_Discount__c != null
                  ? (OI.Opportunity_Product__r?.Oppty_Trade_Up_Discount__c * qtyFactor)
                  : 0.0
              )
            );
          } else {
            Booking_Line_Item__c BLI = OI.Booking_Line_Items__r[0];
            system.debug(LoggingLevel.DEBUG, '::BLI1087::' + BLI);
            if (BLI.Type__c == 'Revenue' && (OI.TotalPrice != BLI.Total_Price__c || OI.Quantity != BLI.Product_Quantity__c)) {
              BLIToUpdate.put(
                BLI.id,
                new Booking_Line_Item__c(
                  id = BLI.id,
                  Total_Price__c = OI.TotalPrice,
                  Product_Quantity__c = OI.Quantity,
                  New_Expansion_TCV__c = OI.Opportunity_Product__r?.New_Expansion_TCV__c == null ? 0.0 : (OI.Opportunity_Product__r?.New_Expansion_TCV__c * qtyFactor),
                  Subsumed_Renewal_TCV__c = OI.Opportunity_Product__r?.Subsumed_Renewal_TCV__c == null ? 0.0 : (OI.Opportunity_Product__r?.Subsumed_Renewal_TCV__c * qtyFactor),
                  Gross_ACV_Amount__c = OI.Opportunity_Product__r?.ACV_Amount__c != null ? (OI.Opportunity_Product__r?.ACV_Amount__c) : 0.0,
                  Gross_New_Expansion_ACV__c = OI.Opportunity_Product__r.New_Expansion_ACV__c != null ? (OI.Opportunity_Product__r.New_Expansion_ACV__c) : 0.0,
                  Gross_Subsumed_Renewal_ACV__c = OI.Opportunity_Product__r.SubsRenAmt__c != null ? (OI.Opportunity_Product__r.SubsRenAmt__c) : 0.0,
                  Net_TCV_Amount__c = Net_TCV_Amount,
                  Net_New_Expansion_TCV__c = Net_New_Expansion_TCV,
                  Net_Subsumed_Renewal_TCV__c = Net_Subsumed_Renewal_TCV,
                  Net_ACV_Amount__c = Net_ACV_Amount,
                  Net_New_Expansion_ACV__c = Net_New_Expansion_ACV,
                  Net_Subsumed_Renewal_ACV__c = Net_Subsumed_Renewal_ACV,
                  PromoDiscTCV__c = OI.Opportunity_Product__r?.PromoDiscTCV__c != null ? (OI.Opportunity_Product__r?.PromoDiscTCV__c * qtyFactor) : 0.0,
                  Prepayment_Credit__c = OI.Opportunity_Product__r?.Prepayment_Credit__c != null ? (OI.Opportunity_Product__r?.Prepayment_Credit__c * qtyFactor) : 0.0,
                  Oppty_Trade_Up_Discount__c = OI.Opportunity_Product__r?.Oppty_Trade_Up_Discount__c != null
                    ? (OI.Opportunity_Product__r?.Oppty_Trade_Up_Discount__c * qtyFactor)
                    : 0.0
                )
              );
            }
          }
        }
      }
    }
  }
  /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : HoldCOde tracker logic
   * @param newOrd
   * @param oldOrd
   * @param existingHoldCodeMap
   * @param holdCodeTrackToInsert
   * @param holdCodeTrackToUpdate
   * @param oppToUpdate
   */
  public void updateHoldCodeTracker(
    Order newOrd,
    Order oldOrd,
    Map<string, Hold_Off_Tracking__c> existingHoldCodeMap,
    set<Hold_Off_Tracking__c> holdCodeTrackToInsert,
    Map<Id, Hold_Off_Tracking__c> holdCodeTrackToUpdate,
    Map<Id, Opportunity> oppToUpdate
  ) {
    system.debug(logginglevel.FINE, 'Existing holdCodeMap' + existingHoldCodeMap);
    List<string> newHoldCodes = new List<string>();
    List<string> oldHoldCodes = new List<string>();
    if (String.isNotBlank(newOrd.Hold_Code__c)) {
      newHoldCodes = newOrd.Hold_Code__c.split(';');
    }
    if (String.isNotBlank(oldOrd.Hold_Code__c)) {
      oldHoldCodes = oldOrd.Hold_Code__c.split(';');
    }
    for (string newHC : newHoldCodes) {
      if (oldHoldCodes.indexOf(newHC) != -1) {
        oldHoldCodes.remove(oldHoldCodes.indexOf(newHC));
      }
      if (existingHoldCodeMap == null || !existingHoldCodeMap.containsKey(newHC)) {
        holdCodeTrackToInsert.add(new Hold_Off_Tracking__c(Hold_Off_Time_Stamp__c = System.Now(), Hold_Code__c = newHC, Related_Order__c = newOrd.id));
      }
    }
    for (string oldHC : oldHoldCodes) {
      if (newHoldCodes.indexOf(oldHC) == -1 && existingHoldCodeMap != null && existingHoldCodeMap.containsKey(oldHC)) {
        Hold_Off_Tracking__c HT = existingHoldCodeMap.get(oldHC);
        HT.Is_Released__c = true;
        HT.Release_Date_Time__c = system.Now();
        holdCodeTrackToUpdate.put(HT.id, HT);
      }
    }
  }
  /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : schedule the schedular class five min from now
   */
  public static void executeSplitOrderBatch() {
    if (isSplitOrderExecuted == true || system.isBatch())
      return;
    isSplitOrderExecuted = true;
    List<CronTrigger> currentRunningApex = [
      SELECT CronJobDetailId, CronJobDetail.Name
      FROM CronTrigger
      WHERE State = 'waiting' AND CronJobDetail.Name = 'SplitOrderSchedularFromTrigger'
    ];
    if (currentRunningApex == null || currentRunningApex.size() == 0) {
      SplitOrderSchedular sc = new SplitOrderSchedular();
      sc.abortJob = true;
      Datetime dt = Datetime.now() + (0.00347222); // i.e. 5 mins
      String timeForScheduler = dt.format('s m H d M \'?\' yyyy');
      Id schedId = System.Schedule('SplitOrderSchedularFromTrigger', timeForScheduler, sc);
    }
  }
  /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : update Onhold Orders
   * @param newOrd
   * @param oldOrd
   */
  public void onHoldOrders(Order newOrd, Order oldOrd) {
    if (newOrd.Order_Status__c != null && newOrd.Order_Status__c != oldOrd.Order_Status__c) {
      newOrd.Sync_to_NetSuite__c = false;
    }
    if (oldOrd.Hold_Code__c != 'On Hold') {
      if (newOrd.Order_Status__c == 'Pending' || newOrd.Order_Status__c == 'PO Received') {
        newOrd.Order_Status__c = 'On Hold';
      }
      newOrd.Hold_Off_Timestamp__c = DateTime.now();
    }
  }

  /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : DML on Other SObjects
   * @param PSProjToInsert
   */
  public void commitabeforeUpdateRecords(set<PS_Project__c> PSProjToInsert) {
    Map<id, id> ordIdProjId = new Map<id, id>();
    List<PS_Project_Team_Member__c> PSProjMemberToInsert = new List<PS_Project_Team_Member__c>();
    if (!PSProjToInsert.isEmpty()) {
      insert new List<PS_Project__c>(PSProjToInsert);
      for (PS_Project__c proj : PSProjToInsert) {
        if (projNameOrdId.get(proj.name) != null) {
          ordIdProjId.put(projNameOrdId.get(proj.name), proj.id);
        }
        if (proj.Project_Manager__c != null) {
          PSProjMemberToInsert.add(new PS_Project_Team_Member__c(PS_Project__c = proj.Id, Team_Member__c = proj.Project_Manager__c));
        }
      }

      if (Trigger.new != null && Trigger.new.size() > 0) {
        for (Order ord : (List<order>) Trigger.new) {
          if (ordIdProjId.containskey(ord.id))
            ord.PS_Project__c = ordIdProjId.get(ord.id);
        }
      }
      if (!PSProjMemberToInsert.isEmpty()) {
        insert PSProjMemberToInsert;
      }
    }
    PSProjToInsert.clear();
    System.debug(LoggingLevel.FINER, 'Before Update Commit' + JSON.serializePretty(Trigger.new));
  }
  /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : Email for training Sku's
   * @param trnOIIds
   */
  public void notifyTrainingSKU(set<Id> trnOIIds) {
    try {
      Id templateId = [SELECT id FROM EmailTemplate WHERE developername = 'Notification_for_Training_Product'].id;
      Id orgEmailId = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'donotreply@rubrik.com' LIMIT 1].id;
      for (Id OIId : trnOIIds) {
        Messaging.SingleEmailMessage email = trainingEmail(templateId, OIId);
        email.setTemplateId(templateId);
        List<string> sendingToAdd = new List<string>{ System.Label.TrainingInfo };
        email.setToAddresses(sendingToAdd);
        email.setOrgWideEmailAddressId(orgEmailId);
        email.setSaveAsActivity(false);
        email.setWhatId(OIId);
        emailList.add(email);
      }
    } catch (Exception ex) {
      System.debug(LoggingLevel.Error, 'TrainingSKU err' + ex.getMessage());
      helper.errorLogs.add(
        new Error_Logs__c(
          Error_Type__c = 'Training SKU Notification failure',
          Error_Message__c = ex.getMessage() + '\n ItemId:' + String.join(new List<Id>(trnOIIds), ','),
          Type__c = 'SFDC'
        )
      );
    }
  }
  /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : Email creation for training Sku's
   * @param templateId
   * @param OIId
   * @return Messaging.SingleEmailMessage instance of email
   */
  public static Messaging.SingleEmailMessage trainingEmail(Id templateId, Id OIId) {
    Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(templateId, null, OIId);
    return email;
  }
  /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description :
   * @param newOrd
   */
  public void shipPOCOrder(Order newOrd) {
    if (
      !newOrd.Have_Hardware_Products__c &&
      newOrd.Order_Sub_Type__c != Constants.ORDER_SUB_TYPE_GC_ONDEMAND &&
      !newOrd.ManualFulfilment__c &&
      (!newOrd.Have_Polaris_Products__c || newOrd.Polaris_Fulfillment_Status__c == 'Completed') &&
      (newOrd.ScreenStatus__c == 'Approved' ||
      newOrd.ScreenStatus__c == 'Approved Bypassed')
    ) {
      newOrd.Order_Status__c = 'Shipped';
      newOrd.Actual_Order_Ship_Date__c = Date.today();
      newOrd.Has_WelcomeLetter_Contact__c = true;
    }
  }
  /**   
    * PMD Rule: AvoidComplexity (complexity)
    * @description : Desc:ASPEN-21 , update shipment details
           Update hardware details on orderItem,asset,contract and entitlement
    * @param newOrd
    * @param OIList
    * @param hardwareItems
    * @param SDProdQuant
    * @param orderItemToUpdate
    * @param scaleEntToInsert
    * @param assetToUpsert
    * @param serialNumAsset
    * @param OIEntMap
    * @param EntToUpdate
    */
  public void updateHardwareInfo(
    Order newOrd,
    List<OrderItem> OIList,
    List<ShipmentDetail__c> hardwareItems,
    Map<string, Decimal> SDProdQuant,
    Map<Id, orderItem> orderItemToUpdate,
    set<Scale_Entitlement__c> scaleEntToInsert,
    Map<string, Asset> assetToUpsert,
    Map<string, Asset> serialNumAsset,
    Map<Id, List<Entitlement>> OIEntMap,
    Map<Id, Entitlement> EntToUpdate
  ) {
    Map<string, List<orderItem>> hwProdNameSuppSWQlIds = new Map<string, List<orderItem>>();
    Map<string, id> HWProdCodeIdMap = new Map<string, id>();
    SBQQ__Quote__c quote = helper.quoteMap?.get(newOrd.SBQQ__Quote__c);
    Map<id, orderItem> qliIdOItm = new Map<id, orderItem>();
    Map<string, string> ProdNameType = new Map<string, string>();
    Map<string, Decimal> sparePCQuant = new Map<string, Decimal>();
    Map<string, set<Id>> hwProdCodeQLIds = new Map<string, set<Id>>();
    Map<Id, ContractLineItem> contractLinesToUpdateById = new Map<Id, ContractLineItem>();
    Map<String, Set<String>> newSerialNumsByOld = new Map<String, Set<String>>();
    for (ShipmentDetail__c SD : hardwareItems) {
      hwProdCodeQLIds.put(SD.ProductName__c, new Set<Id>());
      SD.Quote__c = newOrd.SBQQ__Quote__c;
      if (SD.Quote__c != null && SD.Parent_Shipment_Detail__c == null && TransactionalDataCollection.quoteIdHWItems.containsKey(SD.Quote__c)) {
        SD.Parent_Shipment_Detail__c = TransactionalDataCollection.quoteIdHWItems.get(newOrd.SBQQ__Quote__c).Id;
      }
    }
    for (OrderItem OI : OIList) {
      Id QLIId = (OI.Product2.Product_Type__c == 'RCDM Support' &&
        OI.SBQQ__RequiredBy__c != null &&
        OI.SBQQ__RequiredBy__r.Product2.Product_Level__c == 'LOD Software')
        ? OI.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c
        : OI.SBQQ__QuoteLine__c;
      qliIdOItm.put(QLIId, OI);
      if (OI.Product2.Product_Level__c == 'Support' && OI.Required_by_Product_Code__c != null) {
        ProdNameType.put(OI.Required_by_Product_Code__c, null);
      }
    }
    if (quote != null) {
      for (SBQQ__QuoteLine__c qli : quote.SBQQ__LineItems__r) {
        Id qliId = qli.SBQQ__Product__r.Product_Level__c == 'Hardware' ? qli.SBQQ__RequiredBy__c : qli.SBQQ__Product__r.Product_Level__c == 'Support' ? qli.id : null;
        Id hwQLIId = qli.SBQQ__Product__r.Product_Level__c == 'Hardware' ? qli.id : qli.SBQQ__Product__r.Product_Level__c == 'Support' ? qli.SBQQ__RequiredBy__c : null;
        string prodCode = qli.SBQQ__Product__r.Product_Level__c == 'Hardware'
          ? qli.SBQQ__ProductCode__c
          : qli.SBQQ__Product__r.Product_Level__c == 'Support' ? qli.SBQQ__RequiredBy__r.SBQQ__ProductCode__c : null;
        if (!hwProdCodeQLIds.containsKey(prodCode))
          continue;
        if ('Accessories' != qli.SBQQ__Product__r?.Product_Type__c) {
          // PRDOPS24-857
          if (qliId != null && qliIdOItm.containsKey(qliId) && 'Spares' != qli.SBQQ__Product__r.Product_Type__c) {
            if (hwProdNameSuppSWQlIds.containsKey(prodCode + '-' + hwQLIId)) {
              hwProdNameSuppSWQlIds.get(prodCode + '-' + hwQLIId).add(qliIdOItm.get(qliId));
            } else {
              hwProdNameSuppSWQlIds.put(prodCode + '-' + hwQLIId, new List<orderItem>{ qliIdOItm.get(qliId) });
            }
            hwProdCodeQLIds.get(prodCode).add(hwQLIId);
          }
          if ('Hardware' == qli.SBQQ__Product__r.Product_Level__c) {
            HWProdCodeIdMap.put(qli.SBQQ__ProductCode__c, qli.SBQQ__Product__c);
          }
        }
        if (
          ((qli.SBQQ__Product__r.Product_Level__c == 'Hardware' && qli.SBQQ__Product__r.Product_Type__c == 'Hardware' && ProdNameType.containsKey(qli.SBQQ__ProductCode__c)) ||
          qli.SBQQ__Product__r.Product_Type__c != 'Hardware')
        ) {
          ProdNameType.put(qli.SBQQ__ProductCode__c, qli.SBQQ__Product__r.Product_Type__c);
        }
      }
    }
    for (ShipmentDetail__c hwItm : hardwareItems) {
      if (String.isNotBlank(hwItm.ProductName__c) && Constants.INVALIDATE_ACCESSORIES.contains(hwItm.ProductName__c)) {
        // PRDOPS24-857
        hwItm.Status__c = 'Success';
        hwItm.ProcessHistory__c = 'NA';
        continue;
      }
      Boolean isSpare = 'Spares' == ProdNameType.get(hwItm.ProductName__c);
      date minDate, maxDate;
      hwItm.OrderItemIds__c = '';
      hwItm.Product_Type__c = '';
      if ('Spares' == ProdNameType.get(hwItm.ProductName__c)) {
        sparePCQuant.put(hwItm.ProductName__c, 0.0);
      }
      String combineKey = '';
      Map<String, String> orderItemIdByAssetName = new Map<String, String>();
      try {
        date.parse(hwItm.ShippedDate__c); // valid date format mm/dd/yyyy'
      } catch (exception e) {
        hwItm.ProcessHistory__c = 'Invalid date,valid date format mm/dd/yyyy';
        hwItm.Status__c = 'Failed';
        continue;
      }
      if (hwItm.Type__c != 'Aspen' || newOrd.ProcessType__c != 'Aspen') {
        hwItm.Status__c = 'Failed';
        hwItm.ProcessHistory__c = 'Invalid shipment details for non-aspen';
        if (SDProdQuant != null) {
          SDProdQuant.clear();
          SDProdQuant.put('Failed', 0);
        }
      } else if (!(newOrd.Type == 'Revenue' && (newOrd.Order_Sub_Type__c == null || newOrd.Order_Sub_Type__c == Constants.ORDER_SUB_TYPE_GC_OFFER))) {
        hwItm.Status__c = 'Failed';
        hwItm.ProcessHistory__c = 'Invalid Shipment details';
        if (SDProdQuant != null) {
          SDProdQuant.clear();
          SDProdQuant.put('Failed', 0);
        }
      } else if (
        hwItm.QuoteNumber__c == null ||
        hwItm.QuoteNumber__c.equalsIgnoreCase('Undefined') ||
        (newOrd.SBQQ__Quote__c != null &&
        helper.quoteMap.get(newOrd.SBQQ__Quote__c).name != hwItm.QuoteNumber__c)
      ) {
        hwItm.Status__c = 'Failed';
        hwItm.ProcessHistory__c = 'Invalid Quote';
        hwItm.Quote__c = null;
      } else if (hwItm.Status__c == 'New' && newOrd.Order_Status__c == 'Shipped' && newOrd.SBQQ__Contracted__c) {
        hwItm.ProcessHistory__c = '';
        system.debug(LoggingLevel.DEBUG, 'hwProdNameSuppSWQlIds' + JSON.serialize(hwProdNameSuppSWQlIds));
        if ('Accessories' != ProdNameType.get(hwItm.ProductName__c) && (String.isBlank(hwItm.HW_SerialNumber__c) || hwItm.HW_SerialNumber__c.equalsIgnoreCase('Undefined'))) {
          hwItm.Status__c = 'Failed';
          hwItm.ProcessHistory__c = 'Serial number is mandatory';
          continue;
        }
        if (String.isBlank(hwItm.ProductName__c) || hwItm.ProductName__c.equalsIgnoreCase('Undefined')) {
          hwItm.Status__c = 'Failed';
          hwItm.ProcessHistory__c = 'Product name is mandatory';
          continue;
        }
        hwItm.ProductName__c = hwItm.ProductName__c.trim().toUpperCase();
        if (!ProdNameType.containsKey(hwItm.ProductName__c)) {
          hwItm.Status__c = 'Failed';
          hwItm.ProcessHistory__c = 'No matching Product found against Order';
          continue;
        }
        if (isSpare) {
          hwItm.Product_Type__c = ProdNameType.get(hwItm.ProductName__c);
          Decimal processedSDQuant = sparePCQuant.containsKey(hwItm.ProductName__c)
            ? SDProdQuant.get(hwItm.ProductName__c) - sparePCQuant.get(hwItm.ProductName__c)
            : SDProdQuant.get(hwItm.ProductName__c);
          Decimal currentQuant = isSpare ? Decimal.ValueOf(hwItm.HW_SerialNumber__c.split(',').size()) : hwItm.Quantity__c;
          if (SDProdQuant.containsKey(hwItm.ProductName__c) && processedSDQuant >= currentQuant) {
            if (isSpare) {
              sparePCQuant.put(hwItm.ProductName__c, sparePCQuant.containsKey(hwItm.ProductName__c) ? sparePCQuant.get(hwItm.ProductName__c) + currentQuant : currentQuant);
            } else {
              SDProdQuant.put(hwItm.ProductName__c, SDProdQuant.get(hwItm.ProductName__c) - currentQuant);
              hwItm.Status__c = 'Success';
              continue;
            }
          } else {
            hwItm.Status__c = 'Failed';
            hwItm.ProcessHistory__c = SDProdQuant.get(hwItm.ProductName__c) == 0.0 ? 'Duplicate' : 'Quantity Mismatch';
            hwItm.Quote_Line__c = hwItm.Quote_Item_Ids__c = null;
            continue;
          }
        }
        hwItm.HW_SerialNumber__c = hwItm.HW_SerialNumber__c.replaceAll('\\s+', '');

        if (hwProdCodeQLIds.containsKey(hwItm.ProductName__c)) {
          if (isSpare) {
            validateSerialNumber(hwItm, serialNumAsset, HWProdCodeIdMap.get(hwItm.ProductName__c), assetToUpsert, newOrd, null);
          } else {
            List<asset> assets = new List<asset>();
            if (validateSerialNumber(hwItm, serialNumAsset, HWProdCodeIdMap.get(hwItm.ProductName__c), assetToUpsert, newOrd, assets)) {
              for (Id qliId : hwProdCodeQLIds.get(hwItm.ProductName__c)) {
                if (hwProdNameSuppSWQlIds.containsKey(hwItm.ProductName__c + '-' + qliId)) {
                  List<orderItem> OItmList = hwProdNameSuppSWQlIds.get(hwItm.ProductName__c + '-' + qliId);
                  if (OItmList != null) {
                    if (serialNumAsset != null && !serialNumAsset.isEmpty()) {
                      boolean isMatch = true;
                      for (orderItem OI : OItmList) {
                        if (
                          OI.product2.Product_Level__c == 'Hybrid Software' ||
                          (OI.product2.Product_Level__c == 'OnPrem' &&
                          (OI.product2.Product_Type__c == 'Foundation Edition' ||
                          OI.product2.Product_Type__c == 'Enterprise Edition' ||
                          OI.product2.Product_Type__c == 'Business Edition') &&
                          OI?.Product2?.Product_Subtype__c == null) ||
                          OI.Product2.Product_Type__c == 'RCDM Support'
                        )
                          continue;
                        if (OI.product2.Product_Level__c == 'Support' && OI.Product2.Product_Type__c == 'HW Support') {
                          if (OI.Quantity != assets.size()) {
                            hwItm.Status__c = 'Failed';
                            hwItm.ProcessHistory__c = 'Support and Hardware quantity mismatch' + OI.id;
                            isMatch = false;
                            break;
                          } else if (OI.Quantity == assets.size() && hwItm.ProcessHistory__c.contains('Support and Hardware quantity mismatch')) {
                            hwItm.Status__c = 'New';
                            hwItm.ProcessHistory__c = '';
                          }
                        } else if (OI.SerialNumber__c != null) {
                          hwItm.Status__c = 'Failed';
                          hwItm.ProcessHistory__c = 'Asset is already assigned for ' + OI.id + '\n';
                          isMatch = false;
                          break;
                        }
                      }
                      if (!isMatch)
                        continue;
                    }
                    if (hwItm.Status__c != 'Failed') {
                      hwItm.ProcessHistory__c = '';
                      hwItm.Product_Type__c = hwItm.Product_Type__c != null ? hwItm.Product_Type__c : 'Appliance';
                      for (orderItem OI : OItmList) {
                        hwItm.OrderItemIds__c += OI.id + ',';
                        if (OI.product2.Product_Level__c == 'Support')
                          hwItm.Quote_Line__c = hwItm.Quote_Item_Ids__c = OI.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c;
                        OrderItem OrdItm = orderItemToUpdate.containsKey(OI.id) ? orderItemToUpdate.get(OI.id) : new OrderItem(id = OI.id, SerialNumber__c = OI.SerialNumber__c);
                        OrdItm.SerialNumber__c = (OI.product2.Product_Level__c == 'Support' &&
                          OI.Product2.Product_Type__c != 'RCDM Support')
                          ? hwItm.HW_SerialNumber__c
                          : string.isBlank(OrdItm.SerialNumber__c) ? hwItm.HW_SerialNumber__c : OrdItm.SerialNumber__c + ',' + hwItm.HW_SerialNumber__c;
                        orderItemToUpdate.put(OrdItm.id, OrdItm);
                        OI.SerialNumber__c = OrdItm.SerialNumber__c;
                        // Get the mapping of old serial numbers to new serial numbers for the refresh program line item in the newSerialNumsByOld
                        UtilityClass.getNewAssetsByOldAssetMapping(OI, newSerialNumsByOld);
                        //This if block is related to CPQ22-1959... orderItemIdByAssetName is defined above and used while setting the Combinekey on the Assets
                        if (OI.product2.Product_Level__c == 'Support' && OI.Product2.Product_Type__c == 'HW Support') {
                          for (Asset anAsset : assets) {
                            orderItemIdByAssetName.put(anAsset.SerialNumber, OI.Id);
                          }
                        }
                        if (
                          OI.product2.Product_Level__c == 'Support' &&
                          OI.Product2.Product_Type__c != 'RCDM Support' && //PRDOPS23-853
                          OI.SBQQSC__ContractLineItem__c != null &&
                          !assets.isEmpty()
                        ) {
                          contractLinesToUpdateById.put(
                            OI.SBQQSC__ContractLineItem__c,
                            new ContractLineItem(Id = OI.SBQQSC__ContractLineItem__c, SBQQSC__RequiredById__c = assets[0]?.Id)
                          );
                        }
                        if (OIEntMap != null && OIEntMap.containsKey(OI.id)) {
                          if (OI.product2.Product_Level__c == 'Support' && OI.Product2.Product_Type__c != 'RCDM Support') {
                            List<Entitlement> entList = new List<Entitlement>();
                            entList.addall(OIEntMap.get(OI.id));
                            system.debug(LoggingLevel.DEBUG, 'entList' + entList.size() + 'assets' + assets.size());
                            if (!entList.isEmpty() && !assets.isEmpty() && entList.size() == assets.size()) {
                              for (Integer i = 0; i < entList.size() && i < assets.size(); i++) {
                                if (entList[i].AssetId != assets[i].id) {
                                  Entitlement ent = EntToUpdate.containsKey(entList[i].id) ? EntToUpdate.get(entList[i].id) : new Entitlement(id = entList[i].id);
                                  ent.AssetId = assets[i].id;
                                  ent.Order_Service_Item__c = entList[i].Order_Service_Item__c;
                                  EntToUpdate.put(ent.id, ent);
                                }
                              }
                            }
                          } else if (
                            OI.product2.Product_Level__c == 'Hybrid Software' ||
                            (OI.product2.Product_Level__c == 'OnPrem' &&
                            (OI.product2.Product_Type__c == 'Foundation Edition' ||
                            OI.product2.Product_Type__c == 'Enterprise Edition' ||
                            OI.product2.Product_Type__c == 'Business Edition') &&
                            OI?.Product2?.Product_Subtype__c == null) ||
                            (OI.Product2.Product_Type__c == 'RCDM Support' &&
                            OI.SBQQ__RequiredBy__c != null &&
                            OI.SBQQ__RequiredBy__r.Product2.Product_Level__c == 'LOD Software')
                          ) {
                            Entitlement ent = new Entitlement();
                            for (Entitlement entObj : OIEntMap.get(OI.id)) {
                              if (String.isNotBlank(entObj.Type) && entObj.Type == 'Phone Support') {
                                ent = entObj;
                                break;
                              }
                            }
                            combineKey = OI.id;
                            if (ent != null && String.isNotBlank(ent.Id)) {
                              for (asset asst : assets) {
                                scaleEntToInsert.add(
                                  new Scale_Entitlement__c(
                                    Asset__c = asst.id,
                                    Type__c = 'Non-Scale',
                                    Contract_Line_Item__c = ent.ContractLineItemId,
                                    Order_Product__c = OI.id,
                                    Entitlement__c = ent.id
                                  )
                                );
                              }
                            }
                          }
                          minDate = (minDate != null &&
                            OI.Support_Start_Date__c != null)
                            ? (minDate < OI.Support_Start_Date__c ? minDate : OI.Support_Start_Date__c)
                            : minDate != null ? minDate : OI.Support_Start_Date__c != null ? OI.Support_Start_Date__c : null;
                          maxDate = (maxDate != null &&
                            OI.Support_End_Date__c != null &&
                            ((String.isBlank(OI.Product2.Product_Level__c) || OI.Product2.Product_Level__c == 'Support') &&
                            (String.isNotBlank(OI.Product2.Product_Type__c) && OI.Product2.Product_Type__c == 'HW Support')))
                            ? (maxDate > OI.Support_End_Date__c ? maxDate : OI.Support_End_Date__c)
                            : maxDate != null
                                ? maxDate
                                : (OI.Support_End_Date__c != null &&
                                    ((String.isBlank(OI.Product2.Product_Level__c) || OI.Product2.Product_Level__c == 'Support') &&
                                    (String.isNotBlank(OI.Product2.Product_Type__c) && OI.Product2.Product_Type__c == 'HW Support')))
                                    ? OI.Support_End_Date__c
                                    : null;
                        }
                      }
                      hwItm.OrderItemIds__c = hwItm.OrderItemIds__c.removeEnd(',');

                      for (asset asst : assets) {
                        Asset newAsst = assetToUpsert.containsKey(asst.id) ? assetToUpsert.get(asst.id) : asst;
                        newAsst.Status = 'Purchased';
                        try {
                          newAsst.PurchaseDate = date.parse(hwItm.ShippedDate__c);
                        } catch (exception e) {
                          hwItm.ProcessHistory__c = 'Invalid date,valid date format mm/dd/yyyy';
                          hwItm.Status__c = 'Failed';
                        }
                        newAsst.SerialNumber = asst.SerialNumber;
                        newAsst.Location__c = newOrd.ShippingCity;
                        newAsst.AccountId = newOrd.accountID;
                        newAsst.Quantity = 1;
                        newAsst.Product2Id = HWProdCodeIdMap?.get(hwItm.ProductName__c);
                        newAsst.SBQQ__CombineKey__c = combineKey;
                        if (orderItemIdByAssetName != null && orderItemIdByAssetName.get(asst.SerialNumber) != null) {
                          newAsst.SBQQ__CombineKey__c = orderItemIdByAssetName.get(asst.SerialNumber);
                        } else {
                          newAsst.SBQQ__CombineKey__c = combineKey;
                        }
                        newAsst.Distributor__c = newOrd.Bill_To_Name__c;
                        newAsst.ContractManufacturer__c = hwItm.ContractManufacturer__c;
                        newAsst.SBQQ__QuoteLine__c = hwItm.Quote_Line__c;
                        newAsst.Support_Start_Date__c = (minDate != null &&
                          newAsst.Support_Start_Date__c != null)
                          ? (minDate < newAsst.Support_Start_Date__c ? minDate : newAsst.Support_Start_Date__c)
                          : minDate != null ? minDate : newAsst.Support_Start_Date__c != null ? newAsst.Support_Start_Date__c : null;
                        newAsst.Premium_Support_End_Date__c = (maxDate != null &&
                          newAsst.Premium_Support_End_Date__c != null)
                          ? (maxDate > newAsst.Premium_Support_End_Date__c ? maxDate : newAsst.Premium_Support_End_Date__c)
                          : maxDate != null ? maxDate : newAsst.Premium_Support_End_Date__c != null ? newAsst.Premium_Support_End_Date__c : null;
                        assetToUpsert.put(newAsst.SerialNumber, newAsst);
                      }
                      hwProdNameSuppSWQlIds.remove(hwItm.ProductName__c + '-' + qliId);
                      if (hwProdCodeQLIds.containsKey(hwItm.ProductName__c) && hwProdCodeQLIds.get(hwItm.ProductName__c).contains(qliId)) {
                        hwProdCodeQLIds.get(hwItm.ProductName__c).remove(qliId);
                      }
                      break;
                    }
                    if (String.isNotBlank(hwItm.ProcessHistory__c)) {
                      hwItm.Status__c = 'Failed';
                    }
                  } else {
                    System.debug(LoggingLevel.WARN, 'NO MATCHING ORDERITEM FOUND FOR' + hwItm.id + 'Or Serial number validation failed');
                  }
                }
              }
            } else {
              System.debug(LoggingLevel.WARN, 'Serial number validation failed for ' + hwItm.id);
            }
          }
        } else {
          hwItm.Status__c = 'Failed';
          hwItm.ProcessHistory__c = 'No matching hardware was found against quote';
        }
      }
    }
    if (!newSerialNumsByOld.isEmpty() && UtilityClass.hasAtLeastOneNonEmptyValue(newSerialNumsByOld)) {
      Map<Id, Asset> assetsToUpdate = new Map<Id, Asset>();

      ReplacementEntSplitManager manager = new ReplacementEntSplitManager();
      manager.syncLinkedAssetsForRefreshAndReplacementLicenses(
        newSerialNumsByOld,
        TransactionalDataCollection.allOrderItems,
        OIEntMap,
        assetToUpsert,
        orderItemToUpdate,
        scaleEntToInsert,
        assetsToUpdate,
        new Set<String>(),
        false
      );

      if (!assetsToUpdate.isEmpty() && !assetsToUpdate.values().isEmpty()) {
        update assetsToUpdate.values();
      }
    }
    system.debug(LoggingLevel.DEBUG, 'Final SDProdQuant' + SDProdQuant);
    if (!contractLinesToUpdateById.isEmpty()) {
      TriggerControl.stopSCTrigger = true;
      TriggerControl.stopCLITrigger = true;
      update contractLinesToUpdateById.values();
    }
  }
  /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : DML on Other SObjects
   * @param EntToInsert
   * @param BLIToInsert
   * @param BLIToUpdate
   * @param holdCodeTrackToInsert
   * @param holdCodeTrackToUpdate
   * @param EntToUpdate
   * @param bookingToUpdate
   * @param oppToUpdate
   * @param accToUpdate
   * @param POStgToUpdate
   * @param psTaskToInsert
   * @param CreatePortalUserOrderIds
   * @param nodeToUpdate
   * @param assetToUpsert
   * @param chasisToInsert
   * @param PSUToInsert
   * @param HDDSSDToInsert
   * @param memoryToInsert
   * @param orderItemToUpdate
   * @param ordIdHWItems
   * @param scaleEntToInsert
   * @param quoteSDProdQuant
   * @param cmaToUpsert
   * @param acceptedGCOnDemandOrderIds
   * @param quoteIdHWItems
   * @param lstErrorLogs
   * @param updateParentRecordForRCDMTExtentionObj
   */
  public void commitAfterUpdateRecords(
    set<Entitlement> EntToInsert,
    set<Booking_Line_Item__c> BLIToInsert,
    Map<Id, Booking_Line_Item__c> BLIToUpdate,
    set<Hold_Off_Tracking__c> holdCodeTrackToInsert,
    Map<Id, Hold_Off_Tracking__c> holdCodeTrackToUpdate,
    Map<Id, Entitlement> EntToUpdate,
    Map<Id, booking__c> bookingToUpdate,
    Map<Id, Opportunity> oppToUpdate,
    Map<Id, Account> accToUpdate,
    Map<Id, PO_Stage__c> POStgToUpdate,
    set<PS_Task__c> psTaskToInsert,
    set<id> CreatePortalUserOrderIds,
    Map<Id, Node__c> nodeToUpdate,
    Map<string, Asset> assetToUpsert,
    set<Chassis__c> chasisToInsert,
    set<Power_Supply__c> PSUToInsert,
    set<Drive__c> HDDSSDToInsert,
    set<Memory__c> memoryToInsert,
    Map<Id, orderItem> orderItemToUpdate,
    Map<id, List<ShipmentDetail__c>> ordIdHWItems,
    set<Scale_Entitlement__c> scaleEntToInsert,
    Map<Id, Map<string, Decimal>> quoteSDProdQuant,
    Map<String, ContractManufacturerAllocation__c> cmaToUpsert,
    List<Id> acceptedGCOnDemandOrderIds,
    Map<id, ShipmentDetail__c> quoteIdHWItems,
    Map<Id, String> quoteIdToAction,
    List<Error_Logs__c> lstErrorLogs,
    Map<Id, Quote_and_Order_Staging__c> updateParentRecordForRCDMTExtentionObj,
    Boolean isSerialNumUpdated,
    Map<Id, Set<Id>> eligibleOrdItmForPhantOrdByQuoteId
  ) {
    List<Order_Trigger_Event__e> orderEvents = new List<Order_Trigger_Event__e>();
    List<Booking_Line_Item__c> BLIupsertList = new List<Booking_Line_Item__c>();
    List<Hold_Off_Tracking__c> holdCodeUpsertList = new List<Hold_Off_Tracking__c>();
    List<Entitlement> EntToInsertList = new List<Entitlement>();
    set<EntitlementContact> entContactInsert = new Set<EntitlementContact>();
    Map<id, id> OIIdSDId = new Map<id, id>();
    Map<string, id> AsstSDId = new Map<string, id>();
    Map<string, string> SDUpdObjIds = new Map<string, string>();
    Map<id, order> ordToUpdate = new Map<id, order>();
    Map<id, SBQQ__Quote__c> quoteToUpdate = new Map<id, SBQQ__Quote__c>();
    List<ShipmentDetail__c> shipDetailsToUpdate = new List<ShipmentDetail__c>();
    OrderHandler Ordhandler = OrderHandler.getInstance();
    set<id> errOrderIds = new Set<id>();
    Map<id, Order> orderNewMap = (Map<Id, Order>) Trigger.newMap;
    Map<id, Order> orderOldMap = (Map<Id, Order>) Trigger.oldMap;
    Map<id, string> ordIdMissingSNs = new Map<id, string>(); // used for aspen ASN validation
    ShipmentDetail__c overViewSD = new ShipmentDetail__c();
    system.debug(logginglevel.DEBUG, 'upsertAssetlist' + assetToUpsert);
    system.debug(logginglevel.DEBUG, 'chasisToInsert' + chasisToInsert);
    system.debug(logginglevel.DEBUG, 'PSUToInsert' + PSUToInsert);
    system.debug(logginglevel.DEBUG, 'HDDSSDToInsert' + HDDSSDToInsert);
    system.debug(logginglevel.DEBUG, 'memoryToInsert' + memoryToInsert);
    system.debug(logginglevel.DEBUG, 'orderItemToUpdate' + orderItemToUpdate);
    system.debug(logginglevel.DEBUG, 'EntToUpdate' + EntToUpdate.values());
    system.debug(logginglevel.DEBUG, 'EntToInsert' + EntToInsert);
    system.debug(logginglevel.DEBUG, 'psTaskToInsert' + JSON.serializepretty(psTaskToInsert));
    try {
      if (ordIdHWItems != null && !ordIdHWItems.isEmpty()) {
        for (Id ordId : ordIdHWItems.keyset()) {
          errOrderIds.add(ordId);
          if (
            orderNewMap.get(ordId).ProcessType__c == 'Aspen' &&
            orderNewMap.get(ordId).Type == 'revenue' &&
            (orderNewMap.get(ordId).Order_Status__c != 'Shipped' ||
            orderNewMap.get(ordId).SBQQ__Contracted__c == false)
          ) {
            ordToUpdate.put(ordId, new order(id = ordId, SD_Status__c = 'ASN Received', SD_Failure_Reason__c = 'Order is not shipped or doesn’t have a service contract'));
            errOrderIds.remove(ordId);
          } else {
            if (ordIdHWItems.get(ordId) != null) {
              shipDetailsToUpdate.addall(ordIdHWItems.get(ordId));
            } else if (orderOldMap.get(ordId).SD_Status__c != 'Success') {
              ordToUpdate.put(ordId, new order(id = ordId, SD_Status__c = 'Internal Failure', SD_Failure_Reason__c = 'NO NEW SHIPMENT RECORDS FOUND'));
              system.debug(LoggingLevel.DEBUG, 'NO SHIPMENT RECORDS FOUND');
            }
            if (helper.orderIdOrderItemMap.containsKey(ordId) && orderOldMap.get(ordId).SD_Status__c != 'Success') {
              for (OrderItem OI : helper.orderIdOrderItemMap.get(ordId)) {
                if (OI.product2.Product_Level__c == 'Support' && OI.Product2.Product_Type__c == 'HW Support') {
                  if (OI.SerialNumber__c == null && (!orderItemToUpdate.containsKey(OI.id) || orderItemToUpdate.get(OI.id).SerialNumber__c == null)) {
                    if (ordIdMissingSNs.containsKey(ordId)) {
                      ordIdMissingSNs.put(ordId, ordIdMissingSNs.get(ordId) + ',' + OI.Required_by_Product_Code__c);
                    } else {
                      ordIdMissingSNs.put(ordId, OI.Required_by_Product_Code__c);
                    }
                  }
                }
              }
            }
          }
          if (orderOldMap.get(ordId).SD_Status__c == 'Success') {
            ordToUpdate.put(ordId, new order(id = ordId, SD_Status__c = 'Success', SD_Failure_Reason__c = ''));
          }
        }
        system.debug(logginglevel.DEBUG, 'shipDetailsToUpdate' + shipDetailsToUpdate);
        for (ShipmentDetail__c sd : shipDetailsToUpdate) {
          if (sd.Status__c == 'New' || (sd.Product_Type__c == 'Accessories' && sd.Status__c == 'Success')) {
            errOrderIds.remove(sd.order__c);
            if (sd.Product_Type__c == 'Accessories' && sd.order__c != null && (!ordToUpdate.containsKey(sd.order__c) || ordToUpdate.get(sd.order__c).SD_Status__c == 'Start')) {
              ordToUpdate.put(sd.order__c, new order(id = sd.order__c, SD_Status__c = 'Success', SD_Failure_Reason__c = ''));
            }
            if (String.IsNotBlank(sd.OrderItemIds__c)) {
              for (Id OrdItmId : sd.OrderItemIds__c.split('\\,')) {
                OIIdSDId.put(OrdItmId, sd.id);
              }
            }
            SDUpdObjIds.put(sd.id + 'EntSucc', '');
            SDUpdObjIds.put(sd.id + 'EntFail', '');
            SDUpdObjIds.put(sd.id + 'OISucc', '');
            SDUpdObjIds.put(sd.id + 'OIFail', '');
            SDUpdObjIds.put(sd.id + 'AsstSucc', '');
            SDUpdObjIds.put(sd.id + 'AsstFail', '');
            if (sd.HW_SerialNumber__c != null) {
              for (string SN : sd.HW_SerialNumber__c.split('\\,')) {
                AsstSDId.put(SN, sd.id);
              }
            }
          }
        }
      }
      if (BLIToInsert != null && !BLIToInsert.isEmpty()) {
        BLIupsertList.addall(BLIToInsert);
      }
      if (BLIToUpdate != null && !BLIToUpdate.isEmpty()) {
        BLIupsertList.addall(BLIToUpdate.values());
      }
      if (holdCodeTrackToInsert != null && !holdCodeTrackToInsert.isEmpty()) {
        holdCodeUpsertList.addall(holdCodeTrackToInsert);
      }
      if (holdCodeTrackToUpdate != null && !holdCodeTrackToUpdate.isEmpty()) {
        holdCodeUpsertList.addall(holdCodeTrackToUpdate.values());
      }
      if (EntToUpdate != null && !EntToUpdate.isEmpty()) {
        if (shipDetailsToUpdate == null || shipDetailsToUpdate.isEmpty()) {
          update EntToUpdate.values();
        } else {
          List<Entitlement> entList = new List<entitlement>();
          entList = EntToUpdate.values();
          Integer i = 0;
          for (Database.SaveResult result : Database.update(entList, false)) {
            Id SDId = OIIdSDId?.get(entList[i].Order_Service_Item__c);
            if (SDId != null) {
              if (result.isSuccess()) {
                SDUpdObjIds.put(SDId + 'EntSucc', SDUpdObjIds.get(SDId + 'EntSucc') + entList[i].id + ',');
              } else {
                SDUpdObjIds.put(SDId + 'EntFail', SDUpdObjIds.get(SDId + 'EntFail') + entList[i].id + '-' + result.getErrors()[0].getMessage() + ',');
                // failedSDOrder.add(entList[i].Order_Service_Item__r.orderId);
              }
            }
            i++;
          }
        }
      }
      if (EntToInsert != null && !EntToInsert.isEmpty()) {
        EntToInsertList.addall(EntToInsert);
        insert EntToInsertList;
      }
      /**
       * Project: Scale Utility - CSU
       *
       * All the associated Scale Utility Overage records are updated
       * as SYNC READY to start syncing with the Netsuite as the GC OnDemand order is already accepted / synced
       * This will trigger the Snowflake feeds update to Sync ready in SUO Trigger i.e. ScaleUtilityOverageTriggerHelper.createOverageOpptyAndOrder
       */
      if (!acceptedGCOnDemandOrderIds.isEmpty() && suOveragesToSync == null) {
        suOveragesToSync = [
          SELECT Id, Sync_Status__c
          FROM Scale_Utility_Overage__c
          WHERE Overage_Order__c IN :acceptedGCOnDemandOrderIds
        ];
        for (Scale_Utility_Overage__c suOverage : suOveragesToSync) {
          if (suOverage.Sync_Status__c != Constants.SYNC_READY && suOverage.Sync_Status__c != Constants.SYNC_SUCCESS) {
            suOverage.Sync_Status__c = Constants.SYNC_READY;
          }
        }
        update suOveragesToSync;
      }
      if (BookingToUpdate != null && !BookingToUpdate.isEmpty()) {
        update BookingToUpdate.values();
      }
      if (cmaToUpsert != null && !cmaToUpsert.isEmpty()) {
        upsert cmaToUpsert.values();
      }

      if (!lstErrorLogs.isEmpty()) {
        insert lstErrorLogs;
        OrderHandler.lstErrorLogs = new List<Error_Logs__c>();
      }

      if (!BLIupsertList.isEmpty()) {
        upsert BLIupsertList;
      }

      if (!holdCodeUpsertList.isEmpty()) {
        upsert holdCodeUpsertList;
      }
      if (oppToUpdate != null && !oppToUpdate.isEmpty()) {
        update oppToUpdate.values();
      }
      if (updateParentRecordForRCDMTExtentionObj != null && !updateParentRecordForRCDMTExtentionObj.isEmpty()) {
        TriggerControl.stopQuoteAndOrderStagingTrigger = true;
        update updateParentRecordForRCDMTExtentionObj.values();
        TriggerControl.stopQuoteAndOrderStagingTrigger = false;
      }
      if (POStgToUpdate != null && !POStgToUpdate.isEmpty()) {
        update POStgToUpdate.values();
      }
      if (psTaskToInsert != null && !psTaskToInsert.isEmpty()) {
        insert new List<PS_Task__c>(psTaskToInsert);
      }
      set<Id> contactIds = new Set<Id>();
      for (Entitlement ent : EntToInsertList) {
        if (ent.Type == 'Manufacturing Entitlement' && String.isNotBlank(ent.Primary_Contact__c)) {
          entContactInsert.add(new EntitlementContact(EntitlementId = ent.Id, ContactId = ent.Primary_Contact__c));
          contactIds.add(ent.Primary_Contact__c);
        }
        if (ent.Type == 'Manufacturing Entitlement' && ent.Product__c == Order_control__mdt.getInstance('Manufacturing_Entitlement_Product').Value__c) {
          entContactInsert.add(new EntitlementContact(EntitlementId = ent.Id, ContactId = Order_control__mdt.getInstance('Polaris_Contact').Value__c));
        }
      }
      if (!entContactInsert.isEmpty()) {
        insert new List<EntitlementContact>(entContactInsert);
      }
      if (CreatePortalUserOrderIds != null && !CreatePortalUserOrderIds.isEmpty()) {
        orderEvents.add(new Order_Trigger_Event__e(Action_Type__c = 'CreateCommunityUser', Input_Data__c = string.join(new List<Id>(CreatePortalUserOrderIds), ',')));
      }

      if (assetToUpsert != null && !assetToUpsert.isEmpty()) {
        if (shipDetailsToUpdate == null || shipDetailsToUpdate.isEmpty()) {
          upsert assetToUpsert.values();
        } else {
          List<Asset> AssetList = new List<Asset>();
          AssetList = assetToUpsert.values();
          Integer i = 0;
          for (Database.upsertResult result : Database.upsert(AssetList, false)) {
            Id SDId = AsstSDId?.get(AssetList[i].SerialNumber);
            system.debug(LoggingLevel.DEBUG, 'AssetList::' + AssetList[i].SerialNumber + '::' + AsstSDId);
            if (SDId != null) {
              if (result.isSuccess()) {
                SDUpdObjIds.put(SDId + 'AsstSucc', SDUpdObjIds.get(SDId + 'AsstSucc') + AssetList[i].id + ',');
              } else {
                SDUpdObjIds.put(SDId + 'AsstFail', SDUpdObjIds.get(SDId + 'AsstFail') + AssetList[i].SerialNumber + '-' + result.getErrors()[0].getMessage() + ',');
              }
            }
            i++;
          }
        }
      }
      if (!scaleEntToInsert.isEmpty()) {
        List<Scale_Entitlement__c> scaleEntList = new List<Scale_Entitlement__c>();
        scaleEntList.addall(scaleEntToInsert);
        Integer i = 0;
        for (Database.UpsertResult result : Database.upsert(scaleEntList, false)) {
          system.debug(LoggingLevel.DEBUG, 'scale ent' + scaleEntList[i].Order_Product__c);
          Id SDId = OIIdSDId?.get(scaleEntList[i].Order_Product__c);
          if (SDId != null) {
            if (result.isSuccess()) {
              SDUpdObjIds.put(SDId + 'EntSucc', SDUpdObjIds.get(SDId + 'EntSucc') + scaleEntList[i].id + ',');
            } else {
              SDUpdObjIds.put(SDId + 'EntFail', SDUpdObjIds.get(SDId + 'EntFail') + scaleEntList[i].id + '-' + result.getErrors()[0].getMessage() + ',');
            }
          }
          i++;
        }
      }
      if (chasisToInsert != null && !chasisToInsert.isEmpty()) {
        insert new List<Chassis__c>(chasisToInsert);
      }
      if (PSUToInsert != null && !PSUToInsert.isEmpty()) {
        insert new List<Power_Supply__c>(PSUToInsert);
      }
      if (HDDSSDToInsert != null && !HDDSSDToInsert.isEmpty()) {
        insert new List<Drive__c>(HDDSSDToInsert);
      }
      if (memoryToInsert != null && !memoryToInsert.isEmpty()) {
        insert new List<Memory__c>(memoryToInsert);
      }
      if (nodeToUpdate != null && !nodeToUpdate.isEmpty()) {
        update nodeToUpdate.values();
      }
      if (orderItemToUpdate != null && !orderItemToUpdate.isEmpty()) {
        if (shipDetailsToUpdate == null || shipDetailsToUpdate.isEmpty() || isSerialNumUpdated) {
          update orderItemToUpdate.values();
        } else {
          triggerControl.stopOrderItemTrigger = true;
          for (Database.SaveResult result : Database.update(orderItemToUpdate.values(), false)) {
            Id SDId = OIIdSDId?.get(result.getId());
            if (SDId != null) {
              if (result.isSuccess()) {
                SDUpdObjIds.put(SDId + 'OISucc', SDUpdObjIds.get(SDId + 'OISucc') + result.getId() + ',');
              } else {
                SDUpdObjIds.put(SDId + 'OIFail', SDUpdObjIds.get(SDId + 'OIFail') + result.getId() + '-' + result.getErrors()[0].getMessage() + ',');
              }
            }
          }
          triggerControl.stopOrderItemTrigger = false;
        }
      }
      system.debug(LoggingLevel.DEBUG, 'SDUpdObjIds' + JSON.serialize(SDUpdObjIds));
      if (shipDetailsToUpdate != null && !shipDetailsToUpdate.isEmpty()) {
        for (ShipmentDetail__c sd : shipDetailsToUpdate) {
          if (sd.Status__c == 'New') {
            if (String.isNotBlank(SDUpdObjIds.get(sd.id + 'EntSucc'))) {
              sd.ProcessHistory__c += 'Succ ENT: ' + SDUpdObjIds.get(sd.id + 'EntSucc').removeEnd(',') + '\n';
            }
            if (String.isNotBlank(SDUpdObjIds.get(sd.id + 'EntFail'))) {
              sd.ProcessHistory__c += 'Fail ENT : ' + SDUpdObjIds.get(sd.id + 'EntFail').removeEnd(',') + '\n';
              sd.Status__c = 'Internal Failure';
            }
            if (String.isNotBlank(SDUpdObjIds.get(sd.id + 'OISucc'))) {
              sd.ProcessHistory__c += 'Succ OI: ' + SDUpdObjIds.get(sd.id + 'OISucc').removeEnd(',') + '\n';
            }
            if (String.isNotBlank(SDUpdObjIds.get(sd.id + 'OIFail'))) {
              sd.ProcessHistory__c += 'Fail OI : ' + SDUpdObjIds.get(sd.id + 'OIFail').removeEnd(',') + '\n';
              sd.Status__c = 'Internal Failure';
            }
            if (String.isNotBlank(SDUpdObjIds.get(sd.id + 'AsstSucc'))) {
              sd.ProcessHistory__c += 'Succ Asst: ' + SDUpdObjIds.get(sd.id + 'AsstSucc').removeEnd(',') + '\n';
            }
            if (String.isNotBlank(SDUpdObjIds.get(sd.id + 'AsstFail'))) {
              sd.ProcessHistory__c += 'Fail Asst : ' + SDUpdObjIds.get(sd.id + 'AsstFail');
              sd.Status__c = 'Internal Failure';
            }
          }
          if (businessLogicCS.Enable_Logs__c) {
            system.debug(LoggingLevel.DEBUG, 'Before quoteSDProdQuant' + Json.serialize(quoteSDProdQuant));
          }
          Boolean updateOrder = orderOldMap.get(sd.Order__c).SD_Status__c == 'Success' ? false : true;
          if (
            (sd.Status__c == 'Failed' || sd.Status__c == 'Internal Failure') &&
            ((!ordToUpdate.containsKey(sd.Order__c) || ordToUpdate.get(sd.Order__c).SD_Status__c != 'Internal Failure') || !ordToUpdate.containsKey(sd.Order__c))
          ) {
            if (updateOrder)
              ordToUpdate.put(sd.Order__c, new order(id = sd.Order__c, SD_Status__c = sd.Status__c, SD_Failure_Reason__c = '', Tracking_No__c = sd.TrackingNumber__c));
            errOrderIds.add(sd.Order__c);
          } else if (sd.Status__c == 'New') {
            sd.Status__c = 'Success';
            if (quoteSDProdQuant.containsKey(sd.Quote__c) && quoteSDProdQuant.get(sd.Quote__c).containsKey(sd.ProductName__c)) {
              if (quoteSDProdQuant.get(sd.Quote__c).get(sd.ProductName__c) == sd.Quantity__c) {
                quoteSDProdQuant.get(sd.Quote__c).remove(sd.ProductName__c);
              } else {
                quoteSDProdQuant.get(sd.Quote__c).put(sd.ProductName__c, quoteSDProdQuant.get(sd.Quote__c).get(sd.ProductName__c) - sd.Quantity__c);
              }
            } else {
              system.debug(LoggingLevel.DEBUG, 'Missing quoteline for ' + sd.id);
            }

            if (updateOrder && !errOrderIds.contains(sd.Order__c))
              ordToUpdate.put(sd.Order__c, new order(id = sd.Order__c, SD_Status__c = 'Success', SD_Failure_Reason__c = '', Tracking_No__c = sd.TrackingNumber__c));
          }
        }
      }
      if (!ordIdMissingSNs.isEmpty()) {
        for (Id ordId : ordIdMissingSNs.keyset()) {
          if (orderOldMap.get(ordId).SD_Status__c == 'Success')
            continue;
          Order ordRec = ordToUpdate.containsKey(ordId) ? ordToUpdate.get(ordId) : new order(id = ordId);
          ordRec.SD_Status__c = 'Failed';
          if (orderNewMap.get(ordId).ProcessType__c == 'Aspen' && orderNewMap.get(ordId).Type == 'revenue') {
            ordRec.SD_Failure_Reason__c = 'Received Incomplete ASN, missed products being :' + ordIdMissingSNs.get(ordId);
          }
          ordToUpdate.put(ordId, ordRec);
        }
      }
      if (!errOrderIds.isEmpty()) {
        system.debug(LoggingLevel.DEBUG, 'NO NEW SHIPMENT RECORDS FOUND TO UPDATE for' + errOrderIds);
        for (Id ordId : errOrderIds) {
          if (orderOldMap.get(ordId).SD_Status__c != 'Success' && ordToUpdate?.get(ordId)?.SD_Status__c == null) {
            ordToUpdate.put(ordId, new order(id = ordId, SD_Status__c = 'Internal Failure', SD_Failure_Reason__c = 'NO NEW SHIPMENT RECORDS FOUND TO UPDATE'));
          }
        }
      }
      if (businessLogicCS.Enable_Logs__c) {
        system.debug(LoggingLevel.DEBUG, 'After quoteSDProdQuant' + Json.serialize(quoteSDProdQuant));
      }
      if (!quoteSDProdQuant.isEmpty()) {
        for (Id quoteId : quoteSDProdQuant.keyset()) {
          if (quoteIdHWItems.containsKey(quoteId)) {
            overViewSD = quoteIdHWItems.get(quoteId);
          }
          if (overViewSD.Id != null && quoteId != null && quoteSDProdQuant.get(quoteId).isEmpty() && quoteIdHWItems.containsKey(quoteId)) {
            overViewSD.Quote_ShipmentValidation__c = 'Complete';
            overViewSD.Quote_MissingShipmentDetails__c = '';
          } else if (!quoteSDProdQuant.get(quoteId)?.containsKey('Failed')) {
            Boolean match = true;
            for (string prodName : quoteSDProdQuant.get(quoteId).keyset()) {
              if (quoteSDProdQuant.get(quoteId).get(prodName) > 0.0) {
                match = false;
              } else {
                quoteSDProdQuant.get(quoteId).remove(prodName);
              }
            }
            if (quoteId != null && overViewSD.Id != null) {
              if (match && quoteIdHWItems.containsKey(quoteId)) {
                overViewSD.Quote_ShipmentValidation__c = 'Complete';
                overViewSD.Quote_MissingShipmentDetails__c = '';
              } else if (quoteIdHWItems.containsKey(quoteId)) {
                overViewSD.Quote_ShipmentValidation__c = 'Failed';
                overViewSD.Quote_MissingShipmentDetails__c = quoteSDProdQuant.get(quoteId).toString();
              }
            }
          }
        }
      }
      if (overViewSD.Id != null) {
        shipDetailsToUpdate.add(overViewSD);
      }
      if (shipDetailsToUpdate != null && !shipDetailsToUpdate.isEmpty()) {
        TriggerHandler.bypass('ShipmentDetailHandler');
        update shipDetailsToUpdate;
        TriggerHandler.clearbypass('ShipmentDetailHandler');
      }
      if (accToUpdate != null && !accToUpdate.isEmpty()) {
          TriggerConditionsBypass.addFlag('USCitizenValidationByPass');
          try {
              update accToUpdate.values();
          }
          finally{
              TriggerConditionsBypass.removeFlag('USCitizenValidationByPass');
          }
      }
      if (!ordToUpdate.isEmpty()) {
        TriggerHandler.bypass('OrderHandler');
        update ordToUpdate.values();
        TriggerHandler.clearbypass('OrderHandler');
        for (Order ord : ordToUpdate.values()) {
          if (
            (errOrderIds.contains(ord.id) || ordIdHWItems.containsKey(ord.id) && (ord.SD_Status__c == 'Internal Failure' || ord.SD_Status__c == 'Failed')) &&
            !businessLogicCS.DisableShipmentDetailEmailAlerts__c &&
            ord.Email_Sent_For__c != 'Don\'t Send Shipment Failure Message'
          ) {
            Messaging.SingleEmailMessage emailRec = (new ShipmentNoticeFailureMessage(
                helper.quoteMap.get(orderNewMap.get(ord.id).SBQQ__Quote__c),
                ord.SD_Status__c,
                ordIdHWItems.get(ord.id),
                orderNewMap.get(ord.id),
                new Set<string>{ ord.SD_Failure_Reason__c }
              ))
              .getSingleEmail();
            if (emailRec != null)
              emailList.add(emailRec);
          }
        }
      }
      ordIdHWItems.clear();
      if (!quoteToUpdate.isEmpty()) {
        SBQQ.TriggerControl.disable();
        TriggerControls.disableQuoteTrigger = true;
        update quoteToUpdate.values();
        TriggerControls.disableQuoteTrigger = false;
        SBQQ.TriggerControl.enable();
      }
      if (emailList != null && !emailList.isEmpty()) {
        if (!Test.isRunningTest())
          Messaging.SendEmailResult[] results = Messaging.sendEmail(emailList);
        emailList.clear();
      }
      if (!contactIds.isEmpty() && System.Label.Enable_Portal_User_Creation == 'TRUE') {
        orderEvents.add(new Order_Trigger_Event__e(Action_Type__c = 'UpdateToCommunityUser', Input_Data__c = string.join(new List<Id>(contactIds), ',')));
      }
      if (!orderEvents.isEmpty()) {
        EventBus.publish(orderEvents);
      }
      if (!quoteIdToAction.isEmpty()) {
        phantomOrderAndLineUpdate(JSON.serialize(quoteIdToAction), JSON.serialize(eligibleOrdItmForPhantOrdByQuoteId));
      }
    } catch (Exception e) {
      helper.errorLogs.add(
        new Error_Logs__c(
          Error_Type__c = 'Order Error',
          Error_Message__c = e.getMessage() + '\r\n' + e.getStackTraceString(),
          Type__c = 'SFDC',
          Method__c = 'CommitAfterUpdateRecords'
        )
      );
    }
  }
  /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : updatePOCProductsOnOppty
   * @param newOrders
   * @param oldOrderMap
   */
  public static void updatePOCProductsOnOppty(List<Order> newOrders, Map<Id, Order> oldOrderMap) {
    Set<Id> pocIds = new Set<Id>();
    List<POC__c> updatePOCs = new List<POC__c>();
    for (Order ord : newOrders) {
      if (ord.POC_Request__c != null && ord.Order_Status__c == 'Shipped' && ord.Order_Status__c != oldOrderMap.get(ord.Id).Order_Status__c) {
        pocIds.add(ord.POC_Request__c);
      }
    }
    if (!pocIds.isEmpty()) {
      Map<Id, Opportunity> opptyToUpdate = new Map<Id, Opportunity>();
      for (POC__c poc : [
        SELECT Id, Opportunity__c, Opportunity__r.POC_Products__c, Product_Categories__c, POC_Type__c, Cloud_Cluster_Location__c
        FROM POC__c
        WHERE Id IN :pocIds
      ]) {
        updatePOCs.add(new POC__c(Id = poc.Id, Order_Shipped__c = 'Yes'));
        Opportunity oppty = opptyToUpdate.containsKey(poc.Opportunity__c)
          ? opptyToUpdate.get(poc.Opportunity__c)
          : new Opportunity(Id = poc.Opportunity__c, POC_Products__c = poc.Opportunity__r.POC_Products__c);
        if (oppty.POC_Products__c == null)
          oppty.POC_Products__c = '';
        for (String productName : poc.Product_Categories__c.split(';')) {
          if ('UCL (Cloud Cluster, Cloud Native & Entra ID)' == productName)
            productName = productName + ' - ' + poc.Cloud_Cluster_Location__c;
          if (!oppty.POC_Products__c.contains(productName)) {
            oppty.POC_Products__c = oppty.POC_Products__c + ';' + productName;
            opptyToUpdate.put(oppty.Id, oppty);
          }
        }
      }
      if (!opptyToUpdate.isEmpty()) {
        update opptyToUpdate.values();
      }
      if (!updatePOCs.isEmpty()) {
        update updatePOCs;
      }
    }
  }
  /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : Validate the asset association (Aspen)
   * @return : boolean flag will be return
   * @param SD
   * @param serialNumAsset
   * @param prodId
   * @param assetToUpsert
   * @param newOrd
   * @param assets
   */
  @testvisible
  private boolean validateSerialNumber(ShipmentDetail__c SD, Map<string, Asset> serialNumAsset, id prodId, Map<string, Asset> assetToUpsert, Order newOrd, List<asset> assets) {
    string missingAsset = '';
    string asstInUse = '';
    Map<String, Asset> tempAsstList = new Map<String, Asset>();
    if (serialNumAsset != null && !serialNumAsset.isEmpty()) {
      for (string SN : SD.HW_SerialNumber__c.split('\\,')) {
        system.debug(LoggingLevel.DEBUG, 'serialNumAsset' + serialNumAsset.get(SN));
        if (serialNumAsset.get(SN) != null && SD.Product_Type__c != 'Spares') {
          if (Test.isRunningTest() || (!tempAsstList.containsKey(SN) && Label.Unassigned_Account_Id.contains(serialNumAsset.get(SN).accountId))) {
            tempAsstList.put(SN, serialNumAsset.get(SN));
          } else {
            asstInUse += SN + ',';
          }
        } else if (SD.Product_Type__c == 'Spares') {
          if (
            tempAsstList.containsKey(SN) || (serialNumAsset != null && serialNumAsset.get(SN) != null && !Label.Unassigned_Account_Id.contains(serialNumAsset.get(SN).accountId))
          ) {
            asstInUse += SN + ',';
          }
          if (asstInUse == '') {
            tempAsstList.put(
              SN,
              new Asset(
                Name = SN,
                SerialNumber = SN,
                serial_number__c = SN,
                Location__c = newOrd.ShippingCity,
                AccountId = newOrd.accountID,
                Quantity = 1,
                Product2Id = prodId,
                Distributor__c = newOrd.Bill_To_Name__c,
                ContractManufacturer__c = SD.ContractManufacturer__c,
                SBQQ__QuoteLine__c = SD.Quote_Line__c
              )
            );
          }
        } else {
          missingAsset += SN + ',';
        }
        if (missingAsset != '' || asstInUse != '') {
          SD.Status__c = 'Failed';
          if (missingAsset != '')
            SD.ProcessHistory__c = 'No Matching asset found in system for ' + missingAsset.removeEnd(',');
          if (asstInUse != '')
            SD.ProcessHistory__c = 'Assets are already assigned : ' + asstInUse.removeEnd(',');
          break;
        }
      }
      if (!tempAsstList.isEmpty() && string.isBlank(missingAsset) && string.isBlank(asstInUse)) {
        if (SD.Product_Type__c == 'Spares') {
          assetToUpsert.putall(tempAsstList);
        } else {
          assets.addall(tempAsstList.values());
        }
        for (String SN : tempAsstList.Keyset()) {
          if (serialNumAsset != null && serialNumAsset.get(SN) != null) {
            serialNumAsset.get(SN).accountId = newOrd.accountID;
          } else {
            serialNumAsset.put(SN, tempAsstList.get(SN));
          }
        }
      }
    }
    return SD.Status__c != 'Failed';
  }

 /**
   * @description  Future method to create phantom Orders
   * update Related replacement orders on phantom order
   * @param quoteIdToActionMap
   * @param eligibleOrdItmForPhantOrd
   */
  @future
  public static void phantomOrderAndLineUpdate(String quoteIdToActionMap, String eligibleOrdItmForPhantOrd) {
    Map<Id, String> quoteToAction = (Map<Id, String>) JSON.deserialize(quoteIdToActionMap, Map<Id, String>.class);
    Map<Id, Set<Id>> eligibleOrdItmForPhantOrdByQuoteId = (Map<Id, Set<Id>>) JSON.deserialize(eligibleOrdItmForPhantOrd, Map<Id, Set<Id>>.class);
    phantomOrderAndLineUpdate(quoteToAction, eligibleOrdItmForPhantOrdByQuoteId);
  }
  /**
   * @description  This method is used to create phantom Orders
   * update related replacement orders on phantom order
   * @param quoteToAction
   * @param eligibleOrdItmForPhantOrdByQuoteId
   * @return String it return error message captured in catch block
   */
  public static String phantomOrderAndLineUpdate(Map<Id, String> quoteToAction, Map<Id, Set<Id>> eligibleOrdItmForPhantOrdByQuoteId) {
    String errorMsg;
        Savepoint sp = Database.setSavepoint(); 
    Map<String, Order> orderNoToOrder = new Map<String, Order>();
    List<Order> OrdToInsert = new List<Order>();
    Map<Id, list<OrderItem>> quotePhtmLines = new Map<Id, list<OrderItem>>();
    Map<string, Order> ordersToUpdate = new Map<string, Order>(); //CP
    Map<string, string> phtmOrdReplOrdNums = new Map<string, string>();
    Map<Id, PreviousTransRefWrapper.ReplacementLines> QuoteReplOrds = new Map<Id, PreviousTransRefWrapper.ReplacementLines>();
    List<OrderItem> phtmOIToInsert = new List<OrderItem>();
    Set<Id> preEntIds = new Set<Id>();
        try{
        List<Order> orders = [Select Id, OrderNumber,Sync_to_NetSuite__c,Line_Types__c, SBQQ__Quote__c, Associated_Order_Numbers__c, Type, Order_Sub_Type__c, Bill_To_Name__c, Pricebook2Id, AccountId,(Select Id, Previous_Transaction_Reference__c, Order.OrderNumber, Storage_Tier__c From OrderItems where Replacement_Type__c INCLUDES ('Partial')) From Order Where SBQQ__Quote__c IN: quoteToAction.keySet() AND Type = 'Revenue'];
      if (!orders.isEmpty()) {
        for (Order ord : orders) {
          if (quoteToAction.containsKey(ord.SBQQ__Quote__c)) {
            Set<Id> eligibleOrderItems = eligibleOrdItmForPhantOrdByQuoteId != null && eligibleOrdItmForPhantOrdByQuoteId.containskey(ord.SBQQ__Quote__c)
              ? eligibleOrdItmForPhantOrdByQuoteId.get(ord.SBQQ__Quote__c)
              : new Set<Id>();
            if (ord.Line_Types__c != null && (ord.Line_Types__c.contains('Conversion') || ord.Line_Types__c.contains('Upgrade'))) {
              orderNoToOrder.put(ord.OrderNumber, ord);
              if (quoteToAction.get(ord.SBQQ__Quote__c) == 'create') {
                if (ord.OrderItems != null) {
                  PreviousTransRefWrapper.ReplacementLines repItm = QuoteReplOrds.containsKey(ord.SBQQ__Quote__c) ? QuoteReplOrds.get(ord.SBQQ__Quote__c) : (new PreviousTransRefWrapper.ReplacementLines());
                  for (OrderItem replOI : ord.OrderItems) {
                    if (!eligibleOrderItems.contains(replOI.Id)) {
                      continue;
                    }
                    if (replOI.Previous_Transaction_Reference__c != null) {
                      List<PreviousTransRefWrapper> wrapper = (List<PreviousTransRefWrapper>) JSON.deserialize(replOI.Previous_Transaction_Reference__c, List<PreviousTransRefWrapper>.class);
                      system.debug(LoggingLevel.DEBUG, 'wrapper ' + wrapper);
                      for (PreviousTransRefWrapper wrapperInstance : wrapper) {
                        if (wrapperInstance.orderItemRemainingQuantity > 0) {
                          if (!repItm.preOIDetails.containskey(wrapperInstance.orderItemId)) {
                            repItm.preOIDetails.put(wrapperInstance.orderItemId, wrapperInstance);
                          }
                          repItm.replOrds.add(ord.ordernumber);
                          QuoteReplOrds.put(ord.SBQQ__Quote__c, repItm);
                          preEntIds.add(wrapperInstance.entId);
                        }
                      }
                    }
                                      
                  }
                                    if(ord.Sync_to_NetSuite__c && QuoteReplOrds.containsKey(ord.SBQQ__Quote__c)){
                                        QuoteReplOrds.get(ord.SBQQ__Quote__c).SubmitOrd = true ;
                  }
                }
                            }else if(quoteToAction.get(ord.SBQQ__Quote__c)=='update'){
                                    if(phtmOrdReplOrdNums.containsKey(ord.Associated_Order_Numbers__c)){
                                        phtmOrdReplOrdNums.put(ord.Associated_Order_Numbers__c,phtmOrdReplOrdNums.get(ord.Associated_Order_Numbers__c)+','+ord.OrderNumber);
                                    }else{
                                        phtmOrdReplOrdNums.put(ord.Associated_Order_Numbers__c,ord.OrderNumber);
                }
              }
            }
          }
        }
      }
      // To create Phantom Orders and its line items , update replacement orders with phantom order number
            	  if(!QuoteReplOrds.isEmpty()){
                    Map<Id, Entitlement> entIdMap ;
        if (!preEntIds.isEmpty()) {
                       entIdMap = new Map<Id, Entitlement>([ SELECT
                id,
                EndDate,
                Order_Service_Item__c,
                Order_Service_Item__r.order.Partner_Name__c,
                Order_Service_Item__r.Quantity,
                Order_Service_Item__r.EndDate,
                Order_Service_Item__r.TotalPrice,
                Order_Service_Item__r.ServiceDate,
                Order_Service_Item__r.Licence_Type__c,
                Order_Service_Item__r.OrderId,
                Order_Service_Item__r.PricebookEntryId,
                Order_Service_Item__r.Order.Pricebook2Id,
                Order_Service_Item__r.Order.AccountId,
                Order_Service_Item__r.Order.Bill_To_Name__c,
                Order_Service_Item__r.Order.Sync_to_NetSuite__c,
                Order_Service_Item__r.Order.NetSuite_Order__c,
                Order_Service_Item__r.Storage_Tier__c,
                ContractLineItemId,
                Phantom_OrderItemID__c,
                Terminated_Date__c
              FROM Entitlement
                                                WHERE Id IN: preEntIds]) ;
        }

        Map<Id, Entitlement> survEntByOrgEntId = new Map<Id, Entitlement>();
        for (Entitlement_Links__c survEntLink : [
          SELECT Id, Previous_Entitlement__c, Renewed_Entitlement__r.Phantom_OrderItemID__c
          FROM Entitlement_Links__c
          WHERE
            Previous_Entitlement__c IN :preEntIds
            AND Previous_Entitlement__r.Terminated_Date__c != NULL
            AND Type__c = 'Split-Surviving'
            AND Renewed_Entitlement__r.Phantom_OrderItemID__c != NULL
        ]) {
          survEntByOrgEntId.put(survEntLink.Previous_Entitlement__c, survEntLink.Renewed_Entitlement__r);
        }

        for (Id quoteId : QuoteReplOrds.keyset()) {
          PreviousTransRefWrapper.ReplacementLines ReplItm = QuoteReplOrds.get(quoteId);
          Order phtmOrd = new Order();
          phtmOrd = generatePhantom();
                            phtmOrd.Sync_to_NetSuite__c = ReplItm.SubmitOrd ;
                            if(!ReplItm.replOrds.isEmpty()){
                                phtmOrd.Associated_Order_Numbers__c = String.join(new List<string>(ReplItm.replOrds), ',') ; 
          }
                            if(ReplItm != null && ReplItm.preOIDetails != null){
                                for(Id replOId : ReplItm.preOIDetails.keyset()){
              Entitlement orgEnt = entIdMap.get(ReplItm.preOIDetails.get(replOId).entId);
              OrderItem OItm = new OrderItem();
              PreviousTransRefWrapper.PhantomPrevLineDetail prevLine = (PreviousTransRefWrapper.PhantomPrevLineDetail) JSON.deserialize(JSON.serialize(ReplItm.preOIDetails.get(replOId)), PreviousTransRefWrapper.PhantomPrevLineDetail.class);
              if (orgEnt.Terminated_Date__c == null && orgEnt.Phantom_OrderItemID__c != null) {
                prevLine.phantomOrderItemId = orgEnt?.Phantom_OrderItemID__c;
                                    }else if(survEntByOrgEntId.containsKey(orgEnt.Id) && survEntByOrgEntId.get(orgEnt.Id).Phantom_OrderItemID__c != Null){
                prevLine.phantomOrderItemId = survEntByOrgEntId.get(orgEnt.Id).Phantom_OrderItemID__c;
              }
              OItm.Previous_Transaction_Reference__c = JSON.serialize(prevLine);
              OItm.Support_End_Date__c = orgEnt.EndDate;
              OItm.Quantity = ReplItm.preOIDetails.get(replOId).orderItemRemainingQuantity;
              OItm.UnitPrice = 0.0;
              OItm.Storage_Tier__c = orgEnt?.Order_Service_Item__r?.Storage_Tier__c;
              OItm.Licence_Type__c = orgEnt?.Order_Service_Item__r?.Licence_Type__c;
              OItm.PricebookEntryId = orgEnt.Order_Service_Item__r.PricebookEntryId;
                                    if(!quotePhtmLines.containsKey(quoteId)){
                                        quotePhtmLines.put(quoteId,new list<orderItem>());
              }
              quotePhtmLines.get(quoteId).add(OItm);
                                    if(phtmOrd.AccountId == null){
                phtmOrd.Pricebook2Id = orgEnt.Order_Service_Item__r.Order.Pricebook2Id;
                phtmOrd.AccountId = orgEnt.Order_Service_Item__r.Order.AccountId;
                phtmOrd.Bill_To_Name__c = orgEnt.Order_Service_Item__r.Order.Bill_To_Name__c;
              }
            }
          }
          OrdToInsert.add(phtmOrd);

        }
        String message = '';
                    try{    
          //Insert Phantom order
                    if(!OrdToInsert.isEmpty()){
                        Insert OrdToInsert;
          }

          if (!OrdToInsert.isEmpty()) {
            List<Order> phantomOrdersCreated = new List<Order>();
            Map<String, String> replQuotePhtmOrd = new Map<String, String>();
                    phantomOrdersCreated = [Select Id, OrderNumber, Associated_Order_Numbers__c From Order Where RecordType.Name = 'Phantom Order' AND Id IN: OrdToInsert];
            // Update Phantom order number on replacement orders
            if (!phantomOrdersCreated.isEmpty()) {
                        for (Order ord: phantomOrdersCreated) {
                            if(ord.Associated_Order_Numbers__c != null){
                                for(string replOrdNum : ord.Associated_Order_Numbers__c.split(',')){
                    replQuotePhtmOrd.put(orderNoToOrder.get(replOrdNum).sbqq__quote__c, ord.Id);
                                    ordersToUpdate.put(replOrdNum,new Order(Id = orderNoToOrder.get(replOrdNum).Id, Associated_Order_Numbers__c = ord.OrderNumber));
                  }
                }
              }
            }
            if (!quotePhtmLines.isEmpty()) {
                        for (Id quoteId: quotePhtmLines.keyset()) {
                            for(OrderItem phtmOI : quotePhtmLines.get(quoteId)){
                  phtmOI.OrderId = replQuotePhtmOrd.get(quoteId);

                  phtmOIToInsert.add(phtmOI);
                }
              }
            }
            //Insert Phantom orderItem
                    try{
                        if(!phtmOIToInsert.isEmpty()){
                insert phtmOIToInsert;
              }
                    }catch(Exception exp){
              Database.rollback(sp);
              message = errorMsg = 'Error while creating Phantom Order Lines: ' + exp.getMessage();
            }
          }
            }catch(Exception ex){
          Database.rollback(sp);
          message = errorMsg = 'Error while creating Phantom Order: ' + ex.getMessage();
        }
      }
      // To update phantomOrders
      if (!phtmOrdReplOrdNums.isEmpty()) {
            for(Order phOrd : [Select Id, OrderNumber, SBQQ__Quote__c, Associated_Order_Numbers__c, Type, Order_Sub_Type__c From Order Where OrderNumber IN: phtmOrdReplOrdNums.keyset()]){
                if(phtmOrdReplOrdNums.containsKey(phOrd.OrderNumber)){
                    ordersToUpdate.put(phOrd.OrderNumber,new Order(id =phOrd.id,Associated_Order_Numbers__c =phtmOrdReplOrdNums.get(phOrd.OrderNumber), Line_Types__c = 'Partial Surviving'));
          }
                orderNoToOrder.put(phOrd.OrderNumber,phOrd);
        }
      }
            try{
                if(!ordersToUpdate.isEmpty()){
          TriggerHandler.bypass('OrderHandler');
          update ordersToUpdate.values();
          TriggerHandler.clearbypass('OrderHandler');
        }
            }catch(Exception expt){
        Database.rollback(sp);
        errorMsg = 'Error while updating Orders -' + expt.getMessage();
      }
    } catch (Exception expt) {
      errorMsg = 'Error-' + expt.getMessage();
      system.debug(LoggingLevel.DEBUG, 'Failed');
    }
    return errorMsg;
  }
  /***********************************************
   *@description : To create phantom order instance
   *@return It returns Phantom OrderInstance
   **************************************************/

  public static Order generatePhantom() {
    Id phtmRecTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Phantom_Order').getRecordTypeId();
    Order phantomOrder = new Order(
      Type = 'Revenue Internal',
      EffectiveDate = System.today(),
      Status = 'Draft',
      RecordTypeId = phtmRecTypeId,
      Polaris_Fulfillment_Status__c = 'Not Needed',
      Have_Polaris_Products__c = false,
      Order_Status__c = 'Pending',
      ScreenStatus__c = 'Approved Bypassed',
      Screening_Source__c = 'None',
      ManualFulfilment__c = false,
      Line_Types__c = 'Partial Surviving'
    );
    return phantomOrder;
  }
}