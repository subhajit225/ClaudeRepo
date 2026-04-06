public class BookingLineItemBatch implements Database.Batchable<sObject>, Database.Stateful {
  public class CustomException extends Exception {
  }
  // Variable Declartion
  public List<BookingProduct_Mapping__mdt> BIMappingList = new List<BookingProduct_Mapping__mdt>();
  public string ERROR_FUNCTIONALITY = 'Bookings';
  public Map<Id, Order> OrderMap = new Map<Id, Order>();
  public List<Custom_Error_Log__c> errLog = new List<Custom_Error_Log__c>();
  public final string className = 'BookingLineItemBatch';
  public Map<ID, ID> mapOfOppIdNdBkg = new Map<ID, ID>();
  public Map<ID, ID> mapOfCCRIdNdBookingId = new Map<ID, ID>();
  public List<CCR__c> ccrList = new List<CCR__c>();
  public List<CCR__c> grossCCRList = new List<CCR__c>();
  public Set<Id> setBookingsIds = new Set<Id>();
  //Collect Financial year quarter record details from custom metadata
  public List<Financial_Year__mdt> quarterMap = Financial_Year__mdt.getAll().values(); //[SELECT Quarter__c,Quarter_End_Month__c,Quarter_Start_Month__c FROM Financial_Year__mdt];
  public Map<string, BLI_Impact__mdt> BLITypeCommission = new Map<string, BLI_Impact__mdt>();
  public set<string> excludeProdCodes = new Set<string>();
  public BookingLineItemBatch(List<Id> BookingIds) {
    try {
      BIMappingList = BookingProduct_Mapping__mdt.getAll().values(); //[Select BookingLineItem_Field_name__c, OrderItem_Field_Name__c from BookingProduct_Mapping__mdt];
      if (BIMappingList.isEmpty())
        throw new CustomException('Missing BookingLineItem Mapping metadata');
      setBookingsIds = new Set<Id>(BookingIds);
      for (Order ord : [
        SELECT
          id,
          ordernumber,
          Opportunity.id,
          Type,
          Opportunity.CCR__r.Opportunity__c,
          (SELECT id FROM bookings__r WHERE id IN :BookingIds LIMIT 1),
          (SELECT id FROM OrderItems WHERE Product2.ProductCode NOT IN :excludeProdCodes)
        FROM order
        WHERE id IN (SELECT Order__c FROM booking__c WHERE id IN :BookingIds)
      ]) {
        OrderMap.put(ord.id, ord);
        if (ord.Type == 'Revenue') {
          mapOfOppIdNdBkg.put(ord.Opportunity.id, ord.bookings__r[0].id);
        } else if (ord?.Opportunity?.CCR__r?.Opportunity__c != null) {
          mapOfOppIdNdBkg.put(ord.Opportunity.CCR__r.Opportunity__c, ord.bookings__r[0].id);
        }
      }
      for (BLI_Impact__mdt BLI : BLI_Impact__mdt.getAll().values()) {
        BLITypeCommission.put(BLI.Adjustment_Type__c, BLI);
      }
    } catch (CustomException e) {
      errLog.add(LogError.CreateGenericErrorLog(className, e, ERROR_FUNCTIONALITY));
    } catch (Exception e) {
      errLog.add(LogError.CreateGenericErrorLog(className, e, ERROR_FUNCTIONALITY));
    }
  }

  public Database.QueryLocator start(Database.BatchableContext BC) {
    string query;
    List<Id> OrderIds = new List<id>();
    try {
      OrderIds.addall(OrderMap.keyset());
      for (Integer i = 0; i < BIMappingList.size(); i++) {
        if (i == 0)
          query =
            'Select Opportunity.Opportunity_Sub_Type__c,Opportunity.CCR__r.Booking__r.Id,Opportunity.id,Opportunity.CCR__c,Opportunity.CCR__r.CCR_Type__c,Opportunity.CCR__r.Impacts_Commission__c,Opportunity.CCR__r.Opportunity__c,(Select id from Bookings__r limit 1), ( Select OrderId, SBQQ__QuoteLine__c, Opportunity_Product__r.Quantity, Opportunity_Product__r.Subsumed_Renewal_TCV__c, Opportunity_Product__r.New_Expansion_TCV__c ,Opportunity_Product__r.New_Expansion_ACV__c,Opportunity_Product__r.Subsumed_Renewal_Amount__c, Opportunity_Product__r.OpportunityId, Opportunity_Product__r.ACV_Amount__c, Opportunity_Product__r.PromoDiscTCV__c, Opportunity_Product__r.Prepayment_Credit__c, Opportunity_Product__r.Oppty_Trade_Up_Discount__c, ' +
            BIMappingList[i].OrderItem_Field_Name__c;
        else
          query += ' ,' + BIMappingList[i].OrderItem_Field_Name__c;

        if (i == BIMappingList.size() - 1)
          query += ' from orderItems where Product2.ProductCode NOT IN : excludeProdCodes)from order where Id IN: OrderIds';
      }
      system.debug('Query' + query);
    } catch (Exception e) {
      errLog.add(LogError.CreateGenericErrorLog(className, e, ERROR_FUNCTIONALITY));
    }
    return Database.getQueryLocator(query);
  }

  public void execute(Database.BatchableContext BC, List<order> Order) {
    try {
      ccrList = new List<CCR__c>();
      Set<ID> oppIds = new Set<ID>();
      List<Booking_Line_Item__c> NewBLI = new List<Booking_Line_Item__c>();
      string UnProcessedOrderNumber = '';
      List<Id> SuccessBLIId = new List<id>();
      set<Id> ProcessedOrderId = new Set<Id>();
      set<Id> ExecOrderList = new Set<Id>();
      Booking_Line_Item__c SuccessBLI;
      List<Order> ProcessedOrderList = new List<Order>();
      List<Booking__c> ProcessedBkgList = new List<Booking__c>();
      List<Booking_Line_Item__c> DeleteBLI = new List<Booking_Line_Item__c>();
      List<database.SaveResult> BLISaveRes = new List<database.SaveResult>();
      Set<ID> ccrsIdsToBeUpdated = new Set<Id>();
      List<CCR__c> ccrsToBeUpdated = new List<CCR__c>();
      Set<CCR__c> ccrsToBeUpdatedSet = new Set<CCR__c>();
      Date ccrApprovedDate = Date.Today();
      Map<Id, Decimal> mapOrderIdToRebate = new Map<Id, Decimal>();
      String quarter = ' ';
      String quarter1 = ' ';
      Set<ID> oppIdSet = new Set<ID>();
      List<Opportunity> debookingOppsToBeInserted = new List<Opportunity>();
      string ErrorMessage = '';
      Map<Id, Id> mapOfOrigBkgIdBkgAdj = new Map<Id, Id>();
      Map<Id, Map<string, Decimal>> origOppIdReferalFee = new Map<Id, Map<string, Decimal>>(); // OPPId => {'PRF'=>'' ,'DebookAmount'=>''};
      set<id> OriginalOppIds = new Set<Id>(); // to store original opportunity Ids of booking adjustment records
      // integer j=0; // (REMOVE)To check deletion of line item negative scenario
      BLI_Impact__mdt BLIimpact = new BLI_Impact__mdt();

      if (!setBookingsIds.isEmpty()) {
        for (Booking_Line_Item__c objBLI : [
          SELECT Id, Rebate__c, Booking__c, Booking__r.Order__c
          FROM Booking_Line_Item__c
          WHERE Booking__c IN :setBookingsIds AND Type__c = 'Distributor Fee'
        ]) {
          system.debug('::objBLI::');
          if (!mapOrderIdToRebate.containsKey(objBLI.Booking__r.Order__c)) {
            mapOrderIdToRebate.put(objBLI.Booking__r.Order__c, objBLI.Rebate__c);
          }
        }
      }
      Map<Id, Decimal> mapOppIdToGrossNewTCV = new Map<Id, Decimal>();
      Map<Id, Decimal> mapOppIdToGrossRenewalTCV = new Map<Id, Decimal>();
      Map<Id, Decimal> mapOppIdToGrossTCVAmt = new Map<Id, Decimal>();
      Map<Id, Decimal> mapOppIdToGrossNewACV = new Map<Id, Decimal>();
      Map<Id, Decimal> mapOppIdToGrossACVAmt = new Map<Id, Decimal>();
      Map<Id, Decimal> mapOppIdToGrossRenewalACV = new Map<Id, Decimal>();

      for (Order OrdObj : Order) {
        oppIds.add(OrdObj.Opportunity.id);
        ExecOrderList.add(OrdObj.Id);
        Id BookingId = OrderMap.get(OrdObj.id).Bookings__r[0].id;
        for (orderItem OrdProd : OrdObj.OrderItems) {
          //   j++ ;  // (REMOVE)To check deletion of line item negative scenario
          Booking_Line_Item__c BLI = new Booking_Line_Item__c();
          BLI.OrderProduct__c = OrdProd.id;
          BLI.put('Type__c', 'Revenue');
          //    if(j!=1) // (REMOVE)To check deletion of line item negative scenario
          BLI.put('Booking__c', BookingId);
          for (BookingProduct_Mapping__mdt BIMapping : BIMappingList) {
            List<String> OIFieldSet = BIMapping.OrderItem_Field_Name__c.split('\\.');
            sObject OPSobj = OrdProd;
            for (Integer i = 0; i < (OIFieldSet.size() - 1) && OPSobj != null; i++) {
              if (OPSobj.getSObject(OIFieldSet[i]) == null) {
                OPSobj = null;
                break;
              } else
                OPSobj = OPSobj.getSObject(OIFieldSet[i]);
            }
            if (OPSobj != null && OPSobj.get(OIFieldSet.get(OIFieldSet.size() - 1)) != null)
              BLI.put(BIMapping.BookingLineItem_Field_name__c, OPSobj.get(OIFieldSet.get(OIFieldSet.size() - 1)));
          }
          if (BLITypeCommission.containskey(BLI.Type__c)) {
            BLIimpact = BLITypeCommission.get(BLI.Type__c);
            BLI.Impacts_Gross_Bookings__c = BLIimpact.Impacts_Gross_Bookings__c;
            BLI.Impacts_Net_Bookings__c = BLIimpact.Impacts_Net_Bookings__c;
            BLI.Impacts_Commission__c = BLIimpact.Impacts_Commissions__c;
          }
          Decimal qtyFactor = (OrdProd.Opportunity_Product__c != null &&
            OrdProd.Quantity != null &&
            OrdProd?.Opportunity_Product__r?.Quantity != 0.0)
            ? OrdProd.Quantity / OrdProd.Opportunity_Product__r.Quantity
            : 1;
          if (OrdProd.Opportunity_Product__c != null) {
            BLI.New_Expansion_TCV__c = OrdProd.Opportunity_Product__r?.New_Expansion_TCV__c == null
              ? 0.0
              : (OrdProd.Opportunity_Product__r?.New_Expansion_TCV__c * qtyFactor).setScale(2, RoundingMode.HALF_UP);
            BLI.Subsumed_Renewal_TCV__c = OrdProd.Opportunity_Product__r?.Subsumed_Renewal_TCV__c == null
              ? 0.0
              : (OrdProd.Opportunity_Product__r?.Subsumed_Renewal_TCV__c * qtyFactor).setScale(2, RoundingMode.HALF_UP);

            BLI.Gross_ACV_Amount__c = OrdProd.Opportunity_Product__r?.ACV_Amount__c != null
              ? (OrdProd.Opportunity_Product__r?.ACV_Amount__c * qtyFactor).setScale(2, RoundingMode.HALF_UP)
              : 0.0;
            BLI.Gross_New_Expansion_ACV__c = OrdProd.Opportunity_Product__r?.New_Expansion_ACV__c != null
              ? (OrdProd.Opportunity_Product__r.New_Expansion_ACV__c * qtyFactor).setScale(2, RoundingMode.HALF_UP)
              : 0.0;
            BLI.Gross_Subsumed_Renewal_ACV__c = OrdProd.Opportunity_Product__r?.Subsumed_Renewal_Amount__c != null
              ? (OrdProd.Opportunity_Product__r.Subsumed_Renewal_Amount__c * qtyFactor).setScale(2, RoundingMode.HALF_UP)
              : 0.0;
            Decimal rebatePercentage = mapOrderIdToRebate.containsKey(OrdObj.Id) ? mapOrderIdToRebate.get(OrdObj.Id) : 0;
            if (rebatePercentage != null) {
              BLI.Net_TCV_Amount__c = BLI.Total_Price__c != null ? (BLI.Total_Price__c * ((100 - rebatePercentage) * 0.01)).setScale(2, RoundingMode.HALF_UP) : 0.0;
              BLI.Net_New_Expansion_TCV__c = BLI.New_Expansion_TCV__c != null
                ? (BLI.New_Expansion_TCV__c * ((100 - rebatePercentage) * 0.01)).setScale(2, RoundingMode.HALF_UP)
                : 0.0;
              BLI.Net_Subsumed_Renewal_TCV__c = BLI.Subsumed_Renewal_TCV__c != null
                ? (BLI.Subsumed_Renewal_TCV__c * ((100 - rebatePercentage) * 0.01)).setScale(2, RoundingMode.HALF_UP)
                : 0.0;

              BLI.Net_ACV_Amount__c = BLI.Gross_ACV_Amount__c != null ? (BLI.Gross_ACV_Amount__c * ((100 - rebatePercentage) * 0.01)).setScale(2, RoundingMode.HALF_UP) : 0.0;
              BLI.Net_New_Expansion_ACV__c = BLI.Gross_New_Expansion_ACV__c != null
                ? (BLI.Gross_New_Expansion_ACV__c * ((100 - rebatePercentage) * 0.01)).setScale(2, RoundingMode.HALF_UP)
                : 0.0;
              BLI.Net_Subsumed_Renewal_ACV__c = BLI.Gross_Subsumed_Renewal_ACV__c != null
                ? (BLI.Gross_Subsumed_Renewal_ACV__c * ((100 - rebatePercentage) * 0.01)).setScale(2, RoundingMode.HALF_UP)
                : 0.0;
                BLI.PromoDiscTCV__c = OrdProd.Opportunity_Product__r?.PromoDiscTCV__c != null ? (OrdProd.Opportunity_Product__r.PromoDiscTCV__c * qtyFactor): 0.0;
                BLI.Oppty_Trade_Up_Discount__c = OrdProd.Opportunity_Product__r?.Oppty_Trade_Up_Discount__c != null ? (OrdProd.Opportunity_Product__r.Oppty_Trade_Up_Discount__c * qtyFactor): 0.0;
                BLI.Prepayment_Credit__c = OrdProd.Opportunity_Product__r?.Prepayment_Credit__c != null ? (OrdProd.Opportunity_Product__r.Prepayment_Credit__c * qtyFactor): 0.0;
            }

            if (BLI.Total_Price__c != null) {
              if (!mapOppIdToGrossTCVAmt.containsKey(OrdProd.Opportunity_Product__r.OpportunityId)) {
                mapOppIdToGrossTCVAmt.put(OrdProd.Opportunity_Product__r.OpportunityId, BLI.Total_Price__c);
              } else {
                mapOppIdToGrossTCVAmt.put(
                  OrdProd.Opportunity_Product__r.OpportunityId,
                  mapOppIdToGrossTCVAmt.get(OrdProd.Opportunity_Product__r.OpportunityId) + BLI.Total_Price__c
                );
              }
            }
            if (BLI.New_Expansion_TCV__c != null) {
              if (!mapOppIdToGrossNewTCV.containsKey(OrdProd.Opportunity_Product__r.OpportunityId)) {
                mapOppIdToGrossNewTCV.put(OrdProd.Opportunity_Product__r.OpportunityId, BLI.New_Expansion_TCV__c);
              } else {
                mapOppIdToGrossNewTCV.put(
                  OrdProd.Opportunity_Product__r.OpportunityId,
                  mapOppIdToGrossNewTCV.get(OrdProd.Opportunity_Product__r.OpportunityId) + BLI.New_Expansion_TCV__c
                );
              }
            }
            if (BLI.Subsumed_Renewal_TCV__c != null) {
              if (!mapOppIdToGrossRenewalTCV.containsKey(OrdProd.Opportunity_Product__r.OpportunityId)) {
                mapOppIdToGrossRenewalTCV.put(OrdProd.Opportunity_Product__r.OpportunityId, BLI.Subsumed_Renewal_TCV__c);
              } else {
                mapOppIdToGrossRenewalTCV.put(
                  OrdProd.Opportunity_Product__r.OpportunityId,
                  mapOppIdToGrossRenewalTCV.get(OrdProd.Opportunity_Product__r.OpportunityId) + BLI.Subsumed_Renewal_TCV__c
                );
              }
            }
            if (BLI.Gross_ACV_Amount__c != null) {
              if (!mapOppIdToGrossACVAmt.containsKey(OrdProd.Opportunity_Product__r.OpportunityId)) {
                mapOppIdToGrossACVAmt.put(OrdProd.Opportunity_Product__r.OpportunityId, BLI.Gross_ACV_Amount__c);
              } else {
                mapOppIdToGrossACVAmt.put(
                  OrdProd.Opportunity_Product__r.OpportunityId,
                  mapOppIdToGrossACVAmt.get(OrdProd.Opportunity_Product__r.OpportunityId) + BLI.Gross_ACV_Amount__c
                );
              }
            }
            if (BLI.Gross_New_Expansion_ACV__c != null) {
              if (!mapOppIdToGrossNewACV.containsKey(OrdProd.Opportunity_Product__r.OpportunityId)) {
                mapOppIdToGrossNewACV.put(OrdProd.Opportunity_Product__r.OpportunityId, BLI.Gross_New_Expansion_ACV__c);
              } else {
                mapOppIdToGrossNewACV.put(
                  OrdProd.Opportunity_Product__r.OpportunityId,
                  mapOppIdToGrossNewACV.get(OrdProd.Opportunity_Product__r.OpportunityId) + BLI.Gross_New_Expansion_ACV__c
                );
              }
            }
            if (BLI.Gross_Subsumed_Renewal_ACV__c != null) {
              if (!mapOppIdToGrossRenewalACV.containsKey(OrdProd.Opportunity_Product__r.OpportunityId)) {
                mapOppIdToGrossRenewalACV.put(OrdProd.Opportunity_Product__r.OpportunityId, BLI.Gross_Subsumed_Renewal_ACV__c);
              } else {
                mapOppIdToGrossRenewalACV.put(
                  OrdProd.Opportunity_Product__r.OpportunityId,
                  mapOppIdToGrossRenewalACV.get(OrdProd.Opportunity_Product__r.OpportunityId) + BLI.Gross_Subsumed_Renewal_ACV__c
                );
              }
            }
          }

          //If BLI is for booking of debooking order,create negative lines
          if (
            OrdObj.Opportunity.CCR__c != null &&
            Constants.CCR_TYPES.contains(OrdObj.Opportunity.CCR__r.CCR_Type__c)
          ) {
            BLI.Type__c = OrdObj.Opportunity.CCR__r.CCR_Type__c;
            BLI.Impacts_Commission__c = OrdObj.Opportunity.CCR__r.Impacts_Commission__c;
            //   BLI.Total_Price__c= BLI.Total_Price__c != NULL ?  BLI.Total_Price__c : 0;
            BLI.Gross_ACV_Amount__c = BLI.Gross_ACV_Amount__c != null ? BLI.Gross_ACV_Amount__c : 0;
            BLI.CCR__c = OrdObj.Opportunity.CCR__c;
            OriginalOppIds.add(OrdObj.Opportunity.CCR__r.Opportunity__c);

            //START SAL-1772
            if (OrdObj.Opportunity.Opportunity_Sub_Type__c == 'Full' && mapOfOppIdNdBkg.containsKey(OrdObj.Opportunity.Id) && mapOfOppIdNdBkg.get(OrdObj.Opportunity.Id) != null) {
              mapOfOrigBkgIdBkgAdj.put(OrdObj.Opportunity.CCR__r.Booking__r.Id, mapOfOppIdNdBkg.get(OrdObj.Opportunity.Id));
            }
            //END SAL-1772
          }

          NewBLI.add(BLI);
        }
      }
      //ARY-195
      Map<Id, Decimal> mapOppIdToTotalAmount = new Map<Id, Decimal>();
      List<OpportunityLineItem> lstOppLineItem = [
        SELECT
          Id,
          TotalPrice,
          ProductCode,
          OpportunityId,
          Opportunity.Amount,
          Opportunity.New_Expansion_TCV__c,
          Opportunity.Subsumed_Renewal_TCV__c,
          New_Expansion_TCV__c,
          Subsumed_Renewal_TCV__c,
          Opportunity.Renewal_Subsumed_ACV__c,
          Opportunity.New_Expansion_ACV__c,
          Opportunity.ACV_Amount__c
        FROM OpportunityLineItem
        WHERE OpportunityId IN :oppIds OR OpportunityId IN :OriginalOppIds /*and  ProductCode = : System.Label.OpportunitySplitProduct*/
      ];
      Decimal TotalPriceSplit = 0.0;
      Map<Id, Decimal> mapOppIdToGrossTCV = new Map<Id, Decimal>();
      Map<Id, Decimal> mapOppIdToNewTCV = new Map<Id, Decimal>();
      Map<Id, Decimal> mapOppIdToRenewalTCV = new Map<Id, Decimal>();
      Map<Id, Decimal> mapOppIdToGrossACV = new Map<Id, Decimal>();
      Map<Id, Decimal> mapOppIdToNewACV = new Map<Id, Decimal>();
      Map<Id, Decimal> mapOppIdToRenewalACV = new Map<Id, Decimal>();
      Map<Id, OpportunityLineItem> mapOppIdToOLI = new Map<Id, OpportunityLineItem>();

      for (OpportunityLineItem objOppLI : lstOppLineItem) {
        if (OriginalOppIds.contains(objOppLI.OpportunityId)) {
          if (objOppLI.Opportunity.Amount != null && !mapOppIdToGrossTCV.containsKey(objOppLI.OpportunityId)) {
            mapOppIdToGrossTCV.put(objOppLI.OpportunityId, objOppLI.Opportunity.Amount.setScale(2, System.RoundingMode.HALF_UP));
          }
          if (objOppLI.Opportunity.New_Expansion_TCV__c != null && !mapOppIdToNewTCV.containsKey(objOppLI.OpportunityId)) {
            mapOppIdToNewTCV.put(objOppLI.OpportunityId, objOppLI.Opportunity.New_Expansion_TCV__c.setScale(2, System.RoundingMode.HALF_UP));
          }
          if (objOppLI.Opportunity.Subsumed_Renewal_TCV__c != null && !mapOppIdToRenewalTCV.containsKey(objOppLI.OpportunityId)) {
            mapOppIdToRenewalTCV.put(objOppLI.OpportunityId, objOppLI.Opportunity.Subsumed_Renewal_TCV__c.setScale(2, System.RoundingMode.HALF_UP));
          }
          if (objOppLI.Opportunity.ACV_Amount__c != null && !mapOppIdToGrossACV.containsKey(objOppLI.OpportunityId)) {
            mapOppIdToGrossACV.put(objOppLI.OpportunityId, objOppLI.Opportunity.ACV_Amount__c.setScale(2, System.RoundingMode.HALF_UP));
          }
          if (objOppLI.Opportunity.New_Expansion_ACV__c != null && !mapOppIdToNewACV.containsKey(objOppLI.OpportunityId)) {
            mapOppIdToNewACV.put(objOppLI.OpportunityId, objOppLI.Opportunity.New_Expansion_ACV__c.setScale(2, System.RoundingMode.HALF_UP));
          }
          if (objOppLI.Opportunity.Renewal_Subsumed_ACV__c != null && !mapOppIdToRenewalACV.containsKey(objOppLI.OpportunityId)) {
            mapOppIdToRenewalACV.put(objOppLI.OpportunityId, objOppLI.Opportunity.Renewal_Subsumed_ACV__c.setScale(2, System.RoundingMode.HALF_UP));
          }
        }
        if (objOppLI.ProductCode == System.Label.OpportunitySplitProduct) {
          TotalPriceSplit += Math.abs(objOppLI.TotalPrice);
          mapOppIdToTotalAmount.put(objOppLI.OpportunityId, TotalPriceSplit);
        }
      }
      Map<Id, Decimal> mapOrgOppIdToAmount = new Map<Id, Decimal>();
      for (CCR__c ccr : [
        SELECT
          Id,
          Impacts_Commission__c,
          Referral_Fee_Amount__c,
          CCR_Type__c,
          Amount__c,
          Opportunity__c,
          Opportunity__r.Amount,
          Effective_Date__c,
          Opportunity__r.SBQQ__PrimaryQuote__r.SBQQ__NetAmount__c,
          AssignmentStatus__c
        FROM CCR__c
        WHERE
          (Opportunity__c IN :oppIds
          OR Opportunity__c IN :OriginalOppIds)
          AND (CCR_Type__c = : Constants.PARTNER_REFERRAL_FEE OR CCR_Type__c IN : Constants.CCR_TYPES)
          AND User__c = 'Approved'
      ]) {
        if (
          oppIds.contains(ccr.Opportunity__c) &&
          ccr.AssignmentStatus__c != 'Assigned' &&
          (ccr.CCR_Type__c == Constants.PARTNER_REFERRAL_FEE || Constants.CCR_TYPESWITHOUTREFUND.contains(ccr.CCR_Type__c))
        ) {
          ccrList.Add(ccr);
          if (ccr.CCR_Type__c == 'Partner Referral Fee') {
            grossCCRList.add(ccr);
            oppIdSet.add(ccr.Opportunity__c);
          }
          if (mapOfOppIdNdBkg.containsKey(ccr.Opportunity__c) && ccr.Opportunity__c != null) {
            mapOfCCRIdNdBookingId.put(ccr.id, mapOfOppIdNdBkg.get(ccr.Opportunity__c));
          }
        }
        if (OriginalOppIds.contains(ccr.Opportunity__c)) {
          if (!origOppIdReferalFee.containsKey(ccr.Opportunity__c)) {
            mapOrgOppIdToAmount.put(ccr.Opportunity__c, ccr.Opportunity__r.Amount);
            origOppIdReferalFee.put(
              ccr.Opportunity__c,
              new Map<string, Decimal>{
                'PRF' => 0.0,
                'DebookAmount' => 0.0,
                'NetBooking' => (!mapOppIdToTotalAmount.isEmpty() || mapOppIdToTotalAmount != null) && mapOppIdToTotalAmount.containsKey(ccr.Opportunity__c)
                  ? (ccr.Opportunity__r.Amount + mapOppIdToTotalAmount.get(ccr.Opportunity__c))
                  : ccr.Opportunity__r.Amount
              }
            );
          }
          if (ccr.CCR_Type__c == 'Partner Referral Fee' && ccr.Referral_Fee_Amount__c != null) {
            origOppIdReferalFee.get(ccr.Opportunity__c).put('PRF', origOppIdReferalFee.get(ccr.Opportunity__c).get('PRF') + ccr.Referral_Fee_Amount__c);
          } else if (ccr.CCR_Type__c != 'Partner Referral Fee' && ccr.Amount__c != null) {
            origOppIdReferalFee.get(ccr.Opportunity__c).put('DebookAmount', origOppIdReferalFee.get(ccr.Opportunity__c).get('DebookAmount') + ccr.Amount__c);
          }
        }
      }
      for (Id orgOppId : origOppIdReferalFee.keyset()) {
        Map<string, Decimal> amountMap = origOppIdReferalFee?.get(orgOppId);
        if (
          mapOfOppIdNdBkg.containsKey(orgOppId) &&
          amountMap != null &&
          amountMap != null &&
          amountMap.get('PRF') != 0.0 &&
          math.abs(amountMap.get('NetBooking') - amountMap.get('DebookAmount')) <= decimal.valueOf(System.Label.PRF_Tolerable_Adjustment)
        ) {
          Booking_Line_Item__c PRF_Bli = new Booking_Line_Item__c(
            Type__c = 'Partner Referral Fee',
            Booking__c = mapOfOppIdNdBkg.get(orgOppId),
            Total_Price__c = amountMap.get('PRF'),
            Net_TCV_Amount__c = amountMap.get('PRF')
          );
          if (PRF_Bli.Total_Price__c != null) {
            if (
              mapOppIdToGrossACV.containsKey(orgOppId) &&
              mapOppIdToGrossACV.get(orgOppId) != null &&
              mapOppIdToGrossACV.get(orgOppId) != 0.00 &&
              mapOrgOppIdToAmount.containsKey(orgOppId) &&
              mapOrgOppIdToAmount.get(orgOppId) != null &&
              mapOrgOppIdToAmount.get(orgOppId) != 0.00
            ) {
              PRF_Bli.Gross_ACV_Amount__c = PRF_Bli.Net_ACV_Amount__c = PRF_Bli.Total_Price__c * (mapOppIdToGrossACV.get(orgOppId) / mapOrgOppIdToAmount.get(orgOppId));
              PRF_Bli.Net_New_Expansion_ACV__c = PRF_Bli.Gross_New_Expansion_ACV__c = mapOppIdToNewACV.containsKey(orgOppId) && mapOppIdToNewACV.get(orgOppId) != null
                ? PRF_Bli.Gross_ACV_Amount__c * (mapOppIdToNewACV.get(orgOppId) / mapOppIdToGrossACV.get(orgOppId))
                : 0.00;
              PRF_Bli.Net_Subsumed_Renewal_ACV__c = PRF_Bli.Gross_Subsumed_Renewal_ACV__c = mapOppIdToRenewalACV.containsKey(orgOppId) && mapOppIdToRenewalACV.get(orgOppId) != null
                ? PRF_Bli.Gross_ACV_Amount__c * (mapOppIdToRenewalACV.get(orgOppId) / mapOppIdToGrossACV.get(orgOppId))
                : 0.00;
            }

            if (mapOppIdToGrossTCV.containsKey(orgOppId) && mapOppIdToGrossTCV.get(orgOppId) != null && mapOppIdToGrossTCV.get(orgOppId) != 0.00) {
              PRF_Bli.Net_New_Expansion_TCV__c = PRF_Bli.New_Expansion_TCV__c = mapOppIdToNewTCV.containsKey(orgOppId) && mapOppIdToNewTCV.get(orgOppId) != null
                ? PRF_Bli.Total_Price__c * (mapOppIdToNewTCV.get(orgOppId) / mapOppIdToGrossTCV.get(orgOppId))
                : 0.00;
              PRF_Bli.Net_Subsumed_Renewal_TCV__c = PRF_Bli.Subsumed_Renewal_TCV__c = mapOppIdToRenewalTCV.containsKey(orgOppId) && mapOppIdToRenewalTCV.get(orgOppId) != null
                ? PRF_Bli.Total_Price__c * (mapOppIdToRenewalTCV.get(orgOppId) / mapOppIdToGrossTCV.get(orgOppId))
                : 0.00;
            }
          }
          if (BLITypeCommission.containskey('Partner Referral Fee')) {
            BLIimpact = BLITypeCommission.get('Partner Referral Fee');
            PRF_Bli.Impacts_Gross_Bookings__c = BLIimpact.Impacts_Gross_Bookings__c;
            PRF_Bli.Impacts_Net_Bookings__c = BLIimpact.Impacts_Net_Bookings__c;
            PRF_Bli.Impacts_Commission__c = BLIimpact.Impacts_Commissions__c;
          }
          NewBLI.add(PRF_Bli);
        }
      }

      //Get unasigned CCRs and  create BLIs, assign booking
      if (!ccrList.isEmpty()) {
        for (CCR__c ccr : ccrList) {
          Booking_Line_Item__c BLI1 = new Booking_Line_Item__c();
          if (mapOfCCRIdNdBookingId.containsKey(ccr.id) && mapOfCCRIdNdBookingId.get(ccr.id) != null) {
            BLI1.Booking__c = mapOfCCRIdNdBookingId.get(ccr.id);
          }

          if (ccr.CCR_Type__c == 'Partner Referral Fee') {
            BLI1.Net_TCV_Amount__c = BLI1.Total_Price__c = ccr.Referral_Fee_Amount__c != null ? ccr.Referral_Fee_Amount__c * -1 : 0;

            if (BLI1.Total_Price__c != null) {
              if (
                mapOppIdToGrossACVAmt.containsKey(ccr.Opportunity__c) &&
                mapOppIdToGrossACVAmt.get(ccr.Opportunity__c) != null &&
                mapOppIdToGrossACVAmt.get(ccr.Opportunity__c) != 0.00 &&
                mapOppIdToGrossTCVAmt.containsKey(ccr.Opportunity__c) &&
                mapOppIdToGrossTCVAmt.get(ccr.Opportunity__c) != null &&
                mapOppIdToGrossTCVAmt.get(ccr.Opportunity__c) != 0.00
              ) {
                BLI1.Gross_ACV_Amount__c = BLI1.Net_ACV_Amount__c =
                  BLI1.Total_Price__c * (mapOppIdToGrossACVAmt.get(ccr.Opportunity__c) / mapOppIdToGrossTCVAmt.get(ccr.Opportunity__c));
                BLI1.Net_New_Expansion_ACV__c = BLI1.Gross_New_Expansion_ACV__c = mapOppIdToGrossNewACV.containsKey(ccr.Opportunity__c) &&
                  mapOppIdToGrossNewACV.get(ccr.Opportunity__c) != null
                  ? BLI1.Gross_ACV_Amount__c * (mapOppIdToGrossNewACV.get(ccr.Opportunity__c) / mapOppIdToGrossACVAmt.get(ccr.Opportunity__c))
                  : 0.00;
                BLI1.Net_Subsumed_Renewal_ACV__c = BLI1.Gross_Subsumed_Renewal_ACV__c = mapOppIdToGrossRenewalACV.containsKey(ccr.Opportunity__c) &&
                  mapOppIdToGrossRenewalACV.get(ccr.Opportunity__c) != null
                  ? BLI1.Gross_ACV_Amount__c * (mapOppIdToGrossRenewalACV.get(ccr.Opportunity__c) / mapOppIdToGrossACVAmt.get(ccr.Opportunity__c))
                  : 0.00;
              }

              if (
                mapOppIdToGrossTCVAmt.containsKey(ccr.Opportunity__c) &&
                mapOppIdToGrossTCVAmt.get(ccr.Opportunity__c) != null &&
                mapOppIdToGrossTCVAmt.get(ccr.Opportunity__c) != 0.00
              ) {
                BLI1.Net_New_Expansion_TCV__c = BLI1.New_Expansion_TCV__c = mapOppIdToGrossNewTCV.containsKey(ccr.Opportunity__c) &&
                  mapOppIdToGrossNewTCV.get(ccr.Opportunity__c) != null
                  ? BLI1.Total_Price__c * (mapOppIdToGrossNewTCV.get(ccr.Opportunity__c) / mapOppIdToGrossTCVAmt.get(ccr.Opportunity__c))
                  : 0.00;
                BLI1.Net_Subsumed_Renewal_TCV__c = BLI1.Subsumed_Renewal_TCV__c = mapOppIdToGrossRenewalTCV.containsKey(ccr.Opportunity__c) &&
                  mapOppIdToGrossRenewalTCV.get(ccr.Opportunity__c) != null
                  ? BLI1.Total_Price__c * (mapOppIdToGrossRenewalTCV.get(ccr.Opportunity__c) / mapOppIdToGrossTCVAmt.get(ccr.Opportunity__c))
                  : 0.00;
              }
            }
          } else if (Constants.CCR_TYPESWITHOUTREFUND.contains(ccr.CCR_Type__c)) {
            BLI1.Total_Price__c = ccr.Amount__c != null ? ccr.Amount__c * -1 : 0;
          }
          BLI1.Impacts_Commission__c = ccr.Impacts_Commission__c;
          BLI1.Type__c = ccr.CCR_Type__c;
          BLI1.CCR__c = ccr.id;
          if (BLITypeCommission.containskey(BLI1.Type__c)) {
            BLIimpact = BLITypeCommission.get(BLI1.Type__c);
            BLI1.Impacts_Gross_Bookings__c = BLIimpact.Impacts_Gross_Bookings__c;
            BLI1.Impacts_Net_Bookings__c = BLIimpact.Impacts_Net_Bookings__c;
            if (BLI1.Type__c != 'Change in Booking Policy / De-Risk Decision' && BLI1.Type__c != 'Incorrect Order/Mis-quote') {
              BLI1.Impacts_Commission__c = BLIimpact.Impacts_Commissions__c;
            }
          }
          NewBLI.add(BLI1);
        }
      }

      //create debooking Opportunity for Approved  PRF CCR before Order/Booking
      if (!grossCCRList.isEmpty()) {
        //Collect Original Opps from Opportunities Ids collected
        Map<id, Opportunity> oldIdnewOpp = new Map<id, Opportunity>();
        Map<Id, Opportunity> mapIdOriginalToOpp = new Map<Id, Opportunity>();

        //PRDOPS25-947: Removal of Cloud_Partner_Led_Activity__c, Polaris_Portal_Contact__c ,Cloud_Type__c, Holdover_Requested__c ,Holdover_Extension__c field reference from debooking opportunity for specific fields
        List<Opportunity> originalOppsList = [
          SELECT
            id,
            name,
            accountid,
            StageName,
            CloseDate,
            ForecastCategoryName,
            Initial_Contacts_Name__c,
            Business_Unit__c,
            ownerid,
            Deal_Registration_Type__c,
            SE_Forecast_Category__c,
            Pricebook2Id,
            Partner_Lookup__c,
            Distributor_Lookup__c,
            Future_State__c,
            Compelling_Bus_Driver__c,
            Current_State__c,
            Cloud_Environment__c,
            ETM_Theatre__c,
            ETM_Area__c,
            ETM_Region__c,
            ETM_Territory__c,
            Negative_Consequences__c,
            /*Help_Needed_From__c,*/ Rubrik_Sales_Engineer__c,
            Lost_To_Won_Against__c,
            Positive_Business_Outcomes__c,
            Rubrik_CDM_Release_on_source_cluster__c,
            Customer_AWS_Account_Number__c,
            Customer_AWS_Account_Region__c,
            Number_of_CluodON_Products__c,
            amount,
            Referral_Program__c,
            DB_Type__c,
            Number_of_TB__c,
            Cloud_Type__c,
            Holdover_Extension_End_Date__c,
            Holdover_Extension_Reason__c,
            Installation_Assigned_To__c,
            Lost_Reason__c,
            Lost_To__c,
            Primary_Competitor__c,
            POC_Stage__c,
            Polaris_Region__c,
            Technical_Validation_Next_Step__c,
            Win_Loss_Comments__c,
            Security_Alliance_Contribution__c,
            Direct_Marketplace__c,
            Renewal_Subsumed_ACV__c,
            Subsumed_Renewal_TCV__c,
            New_Expansion_ACV__c,
            New_Expansion_TCV__c,
            ACV_Amount__c,
            Core_PLS_Source__c,
            Opp_PLS_ETM_Theatre__c,
            Opp_PLS_ETM_Area__c,
            Opp_PLS_ETM_Region__c,
            Opp_PLS_ETM_Territory__c,
            Co_Owner__c
          FROM Opportunity
          WHERE Id IN :oppIdSet
        ]; // removing VM_Count__c from query SAL24-157 //SAL24-387 deprecated
        for (Opportunity opp : originalOppsList) {
          Opportunity oppy = opp.clone();
          oppy.StageName = '1 Discovery';
          oppy.ForecastCategoryName = 'Omitted';
          oppy.Polaris_Portal_Contact__c = null;
          oppy.Has_Polaris_Product__c = false;
          oldIdnewOpp.put(opp.id, oppy);
          mapIdOriginalToOpp.put(opp.Id, opp);
        }

        //Attach CCR on new debooking Opportunity
        for (CCR__c ccr : grossCCRList) {
          if (oldIdnewOpp.containsKey(ccr.Opportunity__c)) {
            Opportunity newOpp = oldIdnewOpp.get(ccr.Opportunity__c);
            newOpp.CCR__c = ccr.Id;
            newOpp.Opportunity_Type__c = 'Debooking';
            if (ccr.CCR_Type__c == 'Partner Referral Fee') {
              newOpp.name = newOpp.name + ' - ' + 'Debooking' + ' - ' + 'Referral Fee';
              newOpp.Opportunity_Sub_Type__c = 'Referral Fee';
              newOpp.amount = ccr.Referral_Fee_Amount__c * -1;
              Opportunity originalOpp = mapIdOriginalToOpp?.containsKey(ccr.Opportunity__c) ? mapIdOriginalToOpp.get(ccr.Opportunity__c) : null;
              Decimal percentDebooking = 0.00;
              if (originalOpp.Amount != 0.00 && originalOpp.Amount != null) {
                percentDebooking = (newOpp.Amount / originalOpp.Amount);
              }
              if (originalOpp.ACV_Amount__c != null) {
                newOpp.ACV_Amount__c =
                  /*newOpp.Opportunity_Sub_Type__c != 'Full' &&*/ percentDebooking != null ? (originalOpp.ACV_Amount__c * percentDebooking) : originalOpp.ACV_Amount__c * -1;
              }
              Decimal renewalACV = originalOpp.Renewal_Subsumed_ACV__c != null ? (percentDebooking * originalOpp.Renewal_Subsumed_ACV__c) : 0.00;
              Decimal renewalTCV = originalOpp.Subsumed_Renewal_TCV__c != null ? (percentDebooking * originalOpp.Subsumed_Renewal_TCV__c) : 0.00;
              Decimal expAVC = originalOpp.New_Expansion_ACV__c != null ? (percentDebooking * originalOpp.New_Expansion_ACV__c) : 0.00;
              Decimal expTCV = originalOpp.New_Expansion_TCV__c != null ? (percentDebooking * originalOpp.New_Expansion_TCV__c) : 0.00;
              newOpp.Renewal_Subsumed_ACV__c = renewalACV > 0 ? 0.00 : renewalACV;
              newOpp.Subsumed_Renewal_TCV__c = renewalTCV > 0 ? 0.00 : renewalTCV;
              newOpp.New_Expansion_ACV__c = expAVC > 0 ? 0.00 : expAVC;
              newOpp.New_Expansion_TCV__c = expTCV > 0 ? 0.00 : expTCV;
            }
            if (ccr.Effective_Date__c != null && ccr.Effective_Date__c <= system.today()) {
              newopp.CloseDate = ccr.Effective_Date__c;
            }
            debookingOppsToBeInserted.add(newOpp);
          }
        }
      }

      if (!NewBLI.isEmpty())
        BLISaveRes = database.insert(NewBLI, false);

      for (database.SaveResult SR : BLISaveRes) {
        if (SR.isSuccess()) {
          SuccessBLI = new Booking_Line_Item__c();
          SuccessBLIId.add(SR.getId());
        } else {
          for (Database.Error err : SR.getErrors()) {
            ErrorMessage += err.getMessage() + ',';
            system.debug(LoggingLevel.DEBUG,'err.getMessage()');
          }
        }
      }

      for (booking__c b : [
        SELECT id, Order__c, Order__r.OrderNumber, (SELECT id, CCR__c, CCR__r.id, CCR__r.AssignmentStatus__c FROM Booking_Line_Items__r)
        FROM booking__c
        WHERE id IN (SELECT Booking__c FROM Booking_Line_Item__c WHERE id IN :SuccessBLIId)
      ]) {
        if (b.Booking_Line_Items__r.size() >= OrderMap.get(b.Order__c).OrderItems.size()) {
          ProcessedOrderList.add(new order(id = b.Order__c, BookingStatus__c = 'Completed'));
          ProcessedBkgList.add(new Booking__c(id = b.id, Status__c = 'Completed'));
          ProcessedOrderId.add(b.Order__c);
          //Update CCR assignment status to Assigned when BLI created successfully
          for (Booking_Line_Item__c BLItem : b.Booking_Line_Items__r) {
            if (BLItem.CCR__c != null)
              ccrsToBeUpdated.add(new CCR__c(id = BLItem.CCR__r.id, AssignmentStatus__c = 'Assigned'));
          }
        } else {
          ProcessedOrderList.add(new order(id = b.Order__c, BookingStatus__c = 'Booking LineItem Failed'));
          DeleteBLI.addall(b.Booking_Line_Items__r);
        }
      }
      // One which failed for complete BLI insert change the order status
      if (!ccrsToBeUpdated.isEmpty()) {
        ccrsToBeUpdatedSet.addAll(ccrsToBeUpdated);
        ccrsToBeUpdated.clear();
        ccrsToBeUpdated.addAll(ccrsToBeUpdatedSet);
        update ccrsToBeUpdated;
        if (!debookingOppsToBeInserted.isEmpty()) {
          insert debookingOppsToBeInserted;
          for (Opportunity opp : debookingOppsToBeInserted) {
            opp.StageName = '7 Closed Won';
          }
          upsert debookingOppsToBeInserted;
        }
      }

      if (!ProcessedOrderId.equals(ExecOrderList)) {
        for (Id OrdId : ExecOrderList) {
          if (!ProcessedOrderId.contains(OrdId))
            UnProcessedOrderNumber += OrderMap.get(OrdId).orderNumber + ',';
        }
      }
      system.debug(LoggingLevel.DEBUG,'ProcessedOrder-->' + ProcessedOrderList+'   UnProcessedOrderNumber-->' + UnProcessedOrderNumber);
      if (!ProcessedBkgList.isEmpty())
        update ProcessedBkgList;
      if (!ProcessedOrderList.isEmpty()) {
        Database.SaveResult[] processedOrderListResults = database.Update(ProcessedOrderList, false);
        for (Integer i = 0; i < processedOrderListResults.size(); i++) {
          if (!processedOrderListResults[i].isSuccess()) {
            for (Database.Error err : processedOrderListResults[i].getErrors()) {
              String recIds = ID.valueof(ProcessedOrderList[i].Id);
              errLog.add(LogError.CreateDMLErrorLog(className, recIds, err.getMessage(), ERROR_FUNCTIONALITY));
            }
          }
        }
      }
      if (!DeleteBLI.isEmpty())
        delete DeleteBLI;
      if (String.isNotBlank(UnProcessedOrderNumber)) {
        UnProcessedOrderNumber = UnProcessedOrderNumber.removeEnd(',');
        ErrorMessage = ErrorMessage.removeEnd(',');
        if (UnProcessedOrderNumber.length() > 255)
          UnProcessedOrderNumber = UnProcessedOrderNumber.substring(0, 255);
        if (ErrorMessage.length() > 131072)
          ErrorMessage = ErrorMessage.substring(0, 131072);
        errLog.add(LogError.CreateDMLErrorLog(className, UnProcessedOrderNumber, ErrorMessage, ERROR_FUNCTIONALITY));
      }
    } catch (Exception e) {
      errLog.add(LogError.CreateGenericErrorLog(className, e, ERROR_FUNCTIONALITY));
    }
  }
   /**
   * @description Finish method
   * @param BC
   */
  public void finish(Database.BatchableContext BC) {
    if (!errLog.isEmpty()) {
      insert errLog;
    }
  }
}