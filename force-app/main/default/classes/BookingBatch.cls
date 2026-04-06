/*******************************************************************************************************************
* @description       : create bookings and update bookingstatus on Order and in finish call the BookingLineItemBatch
* @author            : 
* @last modified on  : 01-08-2026
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
global class BookingBatch implements Database.batchable<sObject>, Database.Stateful {

  /**
   * @description global class CustomException
   */
  global class CustomException extends Exception {
  }
  //Variable to collect all Booking records generated successfully through all the Batches
  global set<id> allSuccessBookingIds = new Set<id>();
  global string ERROR_FUNCTIONALITY = 'Bookings';
  global integer totalSizeRecords = 0;
  public static Boolean isTestMode = false;
  global List<Custom_Error_Log__c> errLog = new List<Custom_Error_Log__c>();
  global final string className = 'BookingBatch';
  global final String selectedBookingStatus = 'Booking Failed';
  global string UnProcessedOrderNumber = ' ';
  global string ErrorMessage = ' ';
  global string WhereClause = ' (BookingStatus__c=\'' + String.escapeSingleQuotes(selectedBookingStatus) + '\'' + ' OR BookingStatus__c = NULL) ';
  //Fetch custom metadata BookingsMapping & ConfigureOrderBooking records
  global final List<Booking_Mapping__mdt> bookingMapsList = [
    SELECT Booking_Field_name__c, Order_Field_Name__c, (SELECT OrderAPIName__c, Operator__c, OrderValue__c FROM ConfigureOrderBookings__r LIMIT 1000)
    FROM Booking_Mapping__mdt
    LIMIT 1000
  ];
  global final Date currentDate = Date.Today();
  global String currentQuarter = ' ';
  global String fiscalPeriodQuarter = ' ';
  global String fiscalPeriodYear = ' ';
  global final List<Financial_Year__mdt> quarterMap = Financial_Year__mdt.getAll().values(); //[SELECT Quarter__c,Quarter_End_Month__c,Quarter_Start_Month__c FROM Financial_Year__mdt];

  /**
   * @description start method
   * @param bc
   * @return list of Orders
   */
  global Database.QueryLocator start(Database.BatchableContext bc) {
    String finalQuery = ' ';
    set<string> excludeProdCodes = new Set<string>();
    try {
      //get current quarter details from financial year custom metadata
      for (Financial_Year__mdt fy : quarterMap) {
        if (currentDate.Month() >= fy.Quarter_Start_Month__c && currentDate.Month() <= fy.Quarter_End_Month__c) {
          currentQuarter = fy.Quarter__c;
        } else if (currentDate.Month() >= 11 || currentDate.Month() == 1) {
          currentQuarter = '4';
        }
      }
      if (bookingMapsList.isEmpty())
        throw new CustomException('Missing Booking Mapping metadata');
      for (Booking_Mapping__mdt b : bookingMapsList) {
        for (integer i = 0; i < b.ConfigureOrderBookings__r.size(); i++) {
          whereClause +=
            ' AND ' +
            b.ConfigureOrderBookings__r[i].OrderAPIName__c +
            ' ' +
            b.ConfigureOrderBookings__r[i].Operator__c +
            ' ' +
            b.ConfigureOrderBookings__r[i].OrderValue__c;
        }
      }
      for (Integer i = 0; i < bookingMapsList.size(); i++) {
        if (i == 0)
          finalQuery =
            'Select Opportunity.CCR__c,Opportunity.CCR__r.Opportunity__c,Opportunity.CCR__r.Opportunity__r.Opportunity_Type__c,Opportunity.CCR__r.Opportunity__r.Opportunity_Sub_Type__c,Opportunity.CCR__r.CCR_Type__c,Opportunity.CCR__r.Affective_Person__c,OrderNumber,Opportunity.CCR__r.Booking__r.id,Opportunity.CCR__r.Booking__r.createdDate,Order_Accepted_Timestamp__c,Opportunity.FiscalQuarter,Opportunity.FiscalYear,Opportunity.Ops_Fiscal_Quarter__c, ' +
            bookingMapsList[i].Order_Field_Name__c;
        else
          finalQuery += ' ,' + bookingMapsList[i].Order_Field_Name__c;

        if (i == bookingMapsList.size() - 1)
          finalQuery += ' ,(select id from bookings__r),(select id from orderItems where Product2.ProductCode NOT IN : excludeProdCodes) FROM Order where ' + WhereClause;
      }
    } catch (CustomException e) {
      errLog.add(LogError.CreateGenericErrorLog(className, e, ERROR_FUNCTIONALITY));
    } catch (Exception e) {
      errLog.add(LogError.CreateGenericErrorLog(className, e, ERROR_FUNCTIONALITY));
    }
    return Database.getQueryLocator(finalQuery);
  }

  /**
   * @description execute method
   * @param bc
   * @param scope
   */
  global void execute(Database.BatchableContext bc, List<Order> scope) {
    //Count of order records processed from all the batch iterations
    totalSizeRecords += scope.size();
    List<Booking__c> bookings = new List<Booking__c>();
    List<string> splitOrdField = new List<string>();
    Set<Id> scopeIds = new Set<Id>();
    set<id> ProcessedOppIds = new Set<id>();
    List<Order> ordersToUpdate = new List<Order>();
    List<Booking_Split__c> bkgSplits = new List<Booking_Split__c>();
    try {
      for (integer i = 0; i < scope.size(); i++) {
        if (scope[i].orderItems.isEmpty()) {
          scope.remove(i);
        }
      }
      //iterate over orders queried
      for (Order ord : scope) {
        if (ord.bookings__r.size() == 0) {
        
          scopeIds.add(ord.id);
          Booking__c bookingRecord = new Booking__c();
          Date oppCloseDate = ord?.Opportunity?.CloseDate;
          if (oppCloseDate != null) {
            fiscalPeriodYear = String.valueOf(oppCloseDate.Month() >= 2 ? oppCloseDate.Year() + 1 : oppCloseDate.Year());
            for (Financial_Year__mdt fy : quarterMap) {
              if (oppCloseDate.Month() >= fy.Quarter_Start_Month__c && oppCloseDate.Month() <= fy.Quarter_End_Month__c) {
                fiscalPeriodQuarter = fy.Quarter__c;
              } else if (oppCloseDate.Month() >= 11 || oppCloseDate.Month() == 1) {
                fiscalPeriodQuarter = '4';
              }
            }
            bookingRecord.Fiscal_Period__c = 'Q' + fiscalPeriodQuarter + '-' + fiscalPeriodYear;
            bookingRecord.Fiscal_Quarter__c = fiscalPeriodQuarter;
            bookingRecord.Fiscal_Year__c = string.valueof(fiscalPeriodYear);
          } else {
            bookingRecord.Fiscal_Period__c = 'Q' + ord.Opportunity.FiscalQuarter + '-' + ord.Opportunity.FiscalYear;
            bookingRecord.Fiscal_Quarter__c = string.valueOf(ord.Opportunity.FiscalQuarter);
            bookingRecord.Fiscal_Year__c = string.valueOf(ord.Opportunity.FiscalYear);
          }
          bookingRecord.RecordTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking').getRecordTypeId();
          //Populate values to Booking fields from order,Opportunity,Account as per Booking Mapping Metadata
          if (!bookingMapsList.isEmpty()) {
            //bookingRecord.Booking_Name__c=Ord.Opportunity.Name +' - '+Ord.OrderNumber;
            for (Booking_Mapping__mdt bookingMap : bookingMapsList) {
              if (bookingMap.Booking_Field_name__c == 'Address__c') {
                if (bookingMap.Order_Field_Name__c != null) {
                  String billingAddressString = bookingMap.Order_Field_Name__c;
                  List<String> billingAddressSplit = billingAddressString.split(',');
                  String billingAddressMerge = ' ';
                  for (String s : billingAddressSplit) {
                    if (Ord.get(s) != null) {
                      billingAddressMerge = billingAddressMerge + Ord.get(s) + ' ';
                    }
                  }

                  if (billingAddressMerge != ' ') {
                    bookingRecord.put('Address__c', billingAddressMerge);
                  } else {
                    String shippingAddressString = 'ShippingStreet,ShippingCity,ShippingState,ShippingPostalCode,ShippingCountry,ShippingStateCode,ShippingCountryCode,ShippingLatitude,ShippingLongitude,ShippingGeocodeAccuracy';
                    List<String> shippingAddressSplit = shippingAddressString.split(',');
                    String shippingAddressMerge = ' ';
                    for (String sa : shippingAddressSplit) {
                      if (Ord.get(sa) != null) {
                        shippingAddressMerge = shippingAddressMerge + Ord.get(sa) + ' ';
                      }
                    }
                    bookingRecord.put('Shipping_Adresss__c', shippingAddressMerge);
                  }
                }
              } else if (bookingMap.Booking_Field_name__c != 'Shipping_Adresss__c') {
                splitOrdField = bookingMap.Order_Field_Name__c.split('\\.');
                sObject OrdSobj = ord;
                for (Integer i = 0; i < (splitOrdField.size() - 1) && OrdSobj != null; i++) {
                  if (OrdSobj.getSObject(splitOrdField[i]) == null) {
                    OrdSobj = null;
                    break;
                  }

                  OrdSobj = OrdSobj.getSObject(splitOrdField[i]);
                }

                if (OrdSobj != null && OrdSobj.get(splitOrdField.get(splitOrdField.size() - 1)) != null) {
                  bookingRecord.put(bookingMap.Booking_Field_name__c, OrdSobj.get(splitOrdField.get(splitOrdField.size() - 1)));
                }
              }
            }
            if (
              ord.Opportunity.CCR__c != null &&
              ord.Opportunity.CCR__r.CCR_Type__c != null &&
              Constants.CCR_TYPES.contains(ord.Opportunity.CCR__r.CCR_Type__c)
            ) {
              bookingRecord.RecordTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking Adjustment').getRecordTypeId();
              bookingRecord.Affected_Person__c = ord.Opportunity.CCR__r.Affective_Person__c;
              bookingRecord.Original_Booking__c = ord.Opportunity.CCR__r.Booking__r.id;
              Date bkgEffectivedate = ord.Opportunity.Closedate;
              fiscalPeriodYear = String.valueOf(bkgEffectivedate.Month() >= 2 ? bkgEffectivedate.Year() + 1 : bkgEffectivedate.Year());
              for (Financial_Year__mdt fy : quarterMap) {
                if (bkgEffectivedate.Month() >= fy.Quarter_Start_Month__c && bkgEffectivedate.Month() <= fy.Quarter_End_Month__c) {
                  bookingRecord.Fiscal_Quarter__c = fy.Quarter__c;
                } else if (bkgEffectivedate.Month() >= 11 || bkgEffectivedate.Month() == 1) {
                  bookingRecord.Fiscal_Quarter__c = '4';
                }
              }
              bookingRecord.Fiscal_Period__c = 'Q' + bookingRecord.Fiscal_Quarter__c + '-' + fiscalPeriodYear;
              bookingRecord.Fiscal_Year__c = string.valueof(fiscalPeriodYear);
              bookingRecord.Order_Type__c = 'Booking Adjustment';
              bookingRecord.Opportunity__c = ord.Opportunity.CCR__r.Opportunity__c;
              ProcessedOppIds.add(ord.Opportunity.CCR__r.Opportunity__c);
              bookingRecord.Opportunity_Type__c = ord.Opportunity.CCR__r.Opportunity__r.Opportunity_Type__c;
              bookingRecord.Opportunity_Sub_Type__c = ord.Opportunity.CCR__r.Opportunity__r.Opportunity_Sub_Type__c;
            }
            
            if(isTestMode){
              bookingRecord.Fiscal_Year__c = '786545434343';
            }
            bookings.add(bookingRecord);
          }
        }
      }
      //insert List of Booking records
      Set<ID> allSuccessBookingIdsLocal = new Set<ID>();
      List<database.SaveResult> myResult = new List<database.SaveResult>();
      integer i = 0;
      if (!bookings.isEmpty()) {
        myResult = database.insert(bookings, false);
      }
      for (database.SaveResult sr : myResult) {
        //Collect Booking record Ids inserted successfully
        if (sr.isSuccess()) {
          allSuccessBookingIds.add(sr.getId());
          allSuccessBookingIdsLocal.add(sr.getId());
        } else {
          for (Database.Error err : sr.getErrors()) {
            errorMessage += err.getMessage() + ',';
            
          }
        }
        i++;
      }

      //collect all order ids failed to generate Bookings
      for (Order ordFailed : [
        SELECT id, OrderNumber
        FROM Order
        WHERE ID NOT IN (SELECT Order__c FROM booking__c WHERE id IN :allSuccessBookingIds) AND ID IN :scopeIds
      ]) {
        ordFailed.BookingStatus__c = 'Booking Failed';
        ordersToUpdate.add(ordFailed);
        UnProcessedOrderNumber += ordFailed.OrderNumber + ',';
      }
      //collect all orders succefully generated bookings
      for (Order ordWithBooking : [
        SELECT id, OpportunityId, OrderNumber
        FROM Order
        WHERE ID IN (SELECT Order__c FROM booking__c WHERE id IN :allSuccessBookingIds) AND ID IN :scopeIds
      ]) {
        ordWithBooking.BookingStatus__c = 'Booking Created';
        ordersToUpdate.add(ordWithBooking);
        if (ordWithBooking.OpportunityId != null) {
          ProcessedOppIds.add(ordWithBooking.OpportunityId);
        }
      }
      // start PRDOPS21-178
      Map<id, Opportunity> oppMap = new Map<id, Opportunity>(
        [
          SELECT
            id,
            ETM_Theatre__c,
            ETM_Area__c,
            ETM_Region__c,
            ETM_Territory__c,
            Opp_PLS_ETM_Area__c,
            Opp_PLS_ETM_Region__c,
            Opp_PLS_ETM_Territory__c,
            Opp_PLS_ETM_Theatre__c,
            Opp_PLS_NCD_ETM_Area__c, Opp_PLS_NCD_ETM_Region__c, Opp_PLS_NCD_ETM_Territory__c, Opp_PLS_NCD_ETM_Theatre__c, Opp_PLS_SaaS_ETM_Area__c, Opp_PLS_SaaS_ETM_Region__c, Opp_PLS_SaaS_ETM_Territory__c, Opp_PLS_SaaS_ETM_Theatre__c,
            split__c,
            Opportunity_Split_Parent__c,
            amount,
            Split_percentage__c,
            Split_Amount__c,
            OwnerId,
            (
              SELECT
                id,
                Split_percentage__c,
                Split_Amount__c,
                split__c,
                amount,
                ETM_Theatre__c,
                ETM_Area__c,
                ETM_Region__c,
                ETM_Territory__c,
                OwnerId,
                Opp_PLS_ETM_Area__c,
                Opp_PLS_ETM_Region__c,
                Opp_PLS_ETM_Territory__c,
                Opp_PLS_ETM_Theatre__c,Opp_PLS_NCD_ETM_Area__c, Opp_PLS_NCD_ETM_Region__c, Opp_PLS_NCD_ETM_Territory__c, Opp_PLS_NCD_ETM_Theatre__c, Opp_PLS_SaaS_ETM_Area__c, Opp_PLS_SaaS_ETM_Region__c, Opp_PLS_SaaS_ETM_Territory__c, Opp_PLS_SaaS_ETM_Theatre__c
              FROM Split_Opportunities__r
            )
          FROM Opportunity
          WHERE id IN :ProcessedOppIds AND Opportunity_Type__c != 'Debooking'
        ]
      );
      for (Booking__c bkg : [SELECT id, Opportunity__c FROM booking__c WHERE id IN :allSuccessBookingIdsLocal]) {
        if (oppMap.containsKey(bkg.Opportunity__c)) {
          Opportunity opp = oppMap.get(bkg.Opportunity__c);
          Booking_Split__c primarySplit = new Booking_Split__c();
          primarySplit.Booking__c = bkg.id;
          primarySplit.Sales_Rep__c = opp.OwnerId;
          primarySplit.Opportunity_Split__c = opp.Split_percentage__c; // Changed by Deep for PRDOPS24-844 ;
          primarySplit.Theatre__c = opp.ETM_Theatre__c;
          primarySplit.Area__c = opp.ETM_Area__c;
          primarySplit.Region__c = opp.ETM_Region__c;
          primarySplit.Territory__c = opp.ETM_Territory__c;
          primarySplit.Opportunity__c = opp.id;
          primarySplit.Opp_PLS_ETM_Area__c = opp.Opp_PLS_ETM_Area__c;
          primarySplit.Opp_PLS_ETM_Region__c = opp.Opp_PLS_ETM_Region__c;
          primarySplit.Opp_PLS_ETM_Territory__c = opp.Opp_PLS_ETM_Territory__c;
          primarySplit.Opp_PLS_ETM_Theatre__c = opp.Opp_PLS_ETM_Theatre__c;
          primarySplit.Opp_PLS_NCD_ETM_Area__c = opp.Opp_PLS_NCD_ETM_Area__c;
          primarySplit.Opp_PLS_NCD_ETM_Region__c = opp.Opp_PLS_NCD_ETM_Region__c;
          primarySplit.Opp_PLS_NCD_ETM_Territory__c = opp.Opp_PLS_NCD_ETM_Territory__c;
          primarySplit.Opp_PLS_NCD_ETM_Theatre__c = opp.Opp_PLS_NCD_ETM_Theatre__c;
          primarySplit.Opp_PLS_SaaS_ETM_Area__c = opp.Opp_PLS_SaaS_ETM_Area__c;
          primarySplit.Opp_PLS_SaaS_ETM_Region__c = opp.Opp_PLS_SaaS_ETM_Region__c;
          primarySplit.Opp_PLS_SaaS_ETM_Territory__c = opp.Opp_PLS_SaaS_ETM_Territory__c;
          primarySplit.Opp_PLS_SaaS_ETM_Theatre__c = opp.Opp_PLS_SaaS_ETM_Theatre__c;
          bkgSplits.add(primarySplit);
          for (Opportunity spliopp : opp.Split_Opportunities__r) {
            Booking_Split__c bkgChildSplit = new Booking_Split__c();
            bkgChildSplit.Booking__c = bkg.id;
            bkgChildSplit.Sales_Rep__c = spliopp.OwnerId;
            if (opp.Split_percentage__c != null) {
              bkgChildSplit.Opportunity_Split__c = spliopp.Split_percentage__c;
            }
            bkgChildSplit.Theatre__c = spliopp.ETM_Theatre__c;
            bkgChildSplit.Area__c = spliopp.ETM_Area__c;
            bkgChildSplit.Region__c = spliopp.ETM_Region__c;
            bkgChildSplit.Territory__c = spliopp.ETM_Territory__c;
            bkgChildSplit.Opp_PLS_ETM_Area__c = spliopp.Opp_PLS_ETM_Area__c;
            bkgChildSplit.Opp_PLS_ETM_Region__c = spliopp.Opp_PLS_ETM_Region__c;
            bkgChildSplit.Opp_PLS_ETM_Territory__c = spliopp.Opp_PLS_ETM_Territory__c;
            bkgChildSplit.Opp_PLS_ETM_Theatre__c = spliopp.Opp_PLS_ETM_Theatre__c;
            bkgChildSplit.Opportunity__c = spliopp.id;
            bkgChildSplit.Opp_PLS_NCD_ETM_Area__c = spliopp.Opp_PLS_NCD_ETM_Area__c;
            bkgChildSplit.Opp_PLS_NCD_ETM_Region__c = spliopp.Opp_PLS_NCD_ETM_Region__c;
            bkgChildSplit.Opp_PLS_NCD_ETM_Territory__c = spliopp.Opp_PLS_NCD_ETM_Territory__c;
            bkgChildSplit.Opp_PLS_NCD_ETM_Theatre__c = spliopp.Opp_PLS_NCD_ETM_Theatre__c;
            bkgChildSplit.Opp_PLS_SaaS_ETM_Area__c = spliopp.Opp_PLS_SaaS_ETM_Area__c;
            bkgChildSplit.Opp_PLS_SaaS_ETM_Region__c = spliopp.Opp_PLS_SaaS_ETM_Region__c;
            bkgChildSplit.Opp_PLS_SaaS_ETM_Territory__c = spliopp.Opp_PLS_SaaS_ETM_Territory__c;
            bkgChildSplit.Opp_PLS_SaaS_ETM_Theatre__c = spliopp.Opp_PLS_SaaS_ETM_Theatre__c;
            bkgSplits.add(bkgChildSplit);
          }
        }
      }
      if (!bkgSplits.isEmpty()) {
        database.insert(bkgSplits, false);
      }
      // end PRDOPS21-178
      if (String.isNotBlank(UnProcessedOrderNumber)) {
        errLog.add(getErrorForMessage(className, UnProcessedOrderNumber, ErrorMessage, ERROR_FUNCTIONALITY));
      }
      //Update Booking generation status on Order
      if (!ordersToUpdate.isEmpty()) {
        Database.SaveResult[] ordersToUpdateResult = database.Update(ordersToUpdate, false);
        for (Integer j = 0; j < ordersToUpdateResult.size(); j++) {
          if (!ordersToUpdateResult[j].isSuccess()) {
            for (Database.Error err : ordersToUpdateResult[j].getErrors()) {
              String recIds = ID.valueof(ordersToUpdate[j].Id);
              errLog.add(LogError.CreateDMLErrorLog(className, recIds, err.getMessage(), ERROR_FUNCTIONALITY));
            }
          }
        }
      }
    } catch (Exception e) {
      errLog.add(LogError.CreateGenericErrorLog(className, e, ERROR_FUNCTIONALITY));
    }
  }
  /**
   * @description Finish method
   * @param BC
   */
  global void finish(Database.BatchableContext BC) {
    try{
      Map<Id, Order> mapIdToUpdateOrders = new Map<Id , Order>();
      if(!allSuccessBookingIds.isEmpty()){
          for(Booking__c objBooking : [Select Id, Order__r.Id, Order__r.BookingStatus__c From Booking__c Where Id IN : allSuccessBookingIds and Order__r.BookingStatus__c = null]){
              if(!mapIdToUpdateOrders.containsKey(objBooking.Order__r.Id))
              	mapIdToUpdateOrders.put(objBooking.Order__r.Id,  new Order(Id = objBooking.Order__r.Id, BookingStatus__c = 'Booking Created'));
          } 
          update mapIdToUpdateOrders.values();
      }
      }Catch(Exception ex){
        errLog.add(LogError.CreateGenericErrorLog(className, ex, ERROR_FUNCTIONALITY));  
      }
    if (!errLog.isEmpty()) {
      insert errLog;
    }
    //Invoke BLI Batch
    List<id> allSuccessBookingIdsList = new List<id>();
    allSuccessBookingIdsList.addAll(allSuccessBookingIds);
    BookingLineItemBatch BLI = new BookingLineItemBatch(allSuccessBookingIdsList);
    database.executebatch(BLI);
  }

    /**
   * @author Shrutika
   * @date 05-09-2025
   * @description  Method to return the customError 
   * @return Custom_Error_Log__c
   * @param className
   * @param UnProcessedOrderNumber
   * @param ErrorMessage
   * @param ERROR_FUNCTIONALITY
   */

  public static Custom_Error_Log__c getErrorForMessage(String className, String UnProcessedOrderNumber, String ErrorMessage, String ERROR_FUNCTIONALITY){
    if (UnProcessedOrderNumber.length() > 255)
    	UnProcessedOrderNumber = UnProcessedOrderNumber.substring(0, 255);
    if (ErrorMessage.length() > 131072)
    	ErrorMessage = ErrorMessage.substring(0, 131072);
        return LogError.CreateDMLErrorLog(className, UnProcessedOrderNumber, ErrorMessage, ERROR_FUNCTIONALITY);
    }
}