/*******************************************************************************************************************
* @description       : Sync booking and Booking line item
* @author            : 
* @last modified on  : 01-08-2026
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
SAL-1539  :: To create Sync between Opportunity and Bookings    
Job Run   :: This job runs in sync with BookingBatch every 12 hours during normal and every 30 min in Quarter End             
Developer :: Aneeja     
Last Modified by : Deep Banerjee
********************************************************************************************************************/
global class BookingSyncBatch implements Database.batchable<sObject>, Database.stateful {
  private Date currentDate;
  private Date QuarterStartDate;
  private Date QuarterEndDate;

  /**
   * @description Date Parameter
   * @param dateParam
   */
  public BookingSyncBatch(Date dateParam) {
    currentDate = dateParam;
  }

  /**
   * @description global class CustomException
   */
  global class CustomException extends Exception {
  }
  //Global variable declaration
  global List<Custom_Error_Log__c> errLog = new List<Custom_Error_Log__c>();
  //global List<Booking_Audit__c> bookingAudits = new List<Booking_Audit__c>();
  global final DateTime currentTime = DateTime.now();
  global final string className = 'BookingSyncBatch';
  global string ERROR_FUNCTIONALITY = 'Bookings';
  global final String selectedBookingRecordType = 'Booking';
  global final String selectedBookingStatus = 'Core Attributes - Frozen';
  global final List<Booking_Sync_Mapping__mdt> bookingSyncMapsList = [
    SELECT Booking_Field_name__c, Opportunity_Field_Name__c, Type__c, (SELECT Booking_API_Name__c, Operator__c, Booking_Value__c FROM ConfigureBookingSyncs__r LIMIT 1000)
    FROM Booking_Sync_Mapping__mdt
    LIMIT 1000
  ];
  global final List<Financial_Year__mdt> quarterMap = Financial_Year__mdt.getAll().values(); //[SELECT Quarter__c,Quarter_End_Month__c,Quarter_Start_Month__c FROM Financial_Year__mdt];
  global String currentQuarter = ' ';
  global Integer currentQuarterNextMonth = 0;
  global String bookingCreatedQuarter = ' ';
  global Date quarterEndPlusDay1;
  global Map<Booking__c, List<Booking__c>> mapOfIdAndBookings = new Map<Booking__c, List<Booking__c>>();
  /**
   * @description currentDateTimeAMPMcheck
   */
  global string currentDateTimeAMPMcheck = Integer.ValueOf(string.valueOf(DateTime.Now()).subString(11, 13)) < 12 ? 'AM' : 'PM';
  //global string currentDateTimeAMPMcheck='PM';

  //Start method
  /**
   * @description start method
   * @param bc
   * @return list of Bookings
   */
  global Database.QueryLocator start(Database.BatchableContext bc) {
    String finalQuery = '';
    String whereClause = ' ';
    Date currentDateTemp;
    try {
      if (!quarterMap.isEmpty()) {
        //Current date is falling between QuarteEnd plus 1 to 5 days, still we should force the current date to be in previous quarter
        if (
          (currentDate >= Date.NewInstance(currentDate.Year(), 2, 1) &&
          currentDate < Date.NewInstance(currentDate.Year(), 2, 5)) ||
          (currentDate >= Date.NewInstance(currentDate.Year(), 5, 1) &&
          currentDate < Date.NewInstance(currentDate.Year(), 5, 5)) ||
          (currentDate >= Date.NewInstance(currentDate.Year(), 8, 1) &&
          currentDate < Date.NewInstance(currentDate.Year(), 8, 5)) ||
          (currentDate >= Date.NewInstance(currentDate.Year(), 11, 1) &&
          currentDate < Date.NewInstance(currentDate.Year(), 11, 5)) ||
          (currentDate > Date.NewInstance(currentDate.Year(), 2, 1) &&
          currentDate <= Date.NewInstance(currentDate.Year(), 2, 5)) ||
          (currentDate > Date.NewInstance(currentDate.Year(), 5, 1) &&
          currentDate <= Date.NewInstance(currentDate.Year(), 5, 5)) ||
          (currentDate > Date.NewInstance(currentDate.Year(), 8, 1) &&
          currentDate <= Date.NewInstance(currentDate.Year(), 8, 5)) ||
          (currentDate > Date.NewInstance(currentDate.Year(), 11, 1) &&
          currentDate <= Date.NewInstance(currentDate.Year(), 11, 5))
        ) {
          currentDateTemp = currentDate.addDays(-6);
        } else {
          currentDateTemp = currentDate;
        }
        system.debug(LoggingLevel.DEBUG, 'AS-->currentDateTemp' + currentDateTemp + ' currentDate' + currentDate);

        for (Financial_Year__mdt fy : quarterMap) {
          //Get current Quarter details
          if (currentDateTemp.Month() >= fy.Quarter_Start_Month__c && currentDateTemp.Month() <= fy.Quarter_End_Month__c) {
            currentQuarter = fy.Quarter__c;
            if (currentQuarter != '1') {
              QuarterStartDate = Date.NewInstance(currentDateTemp.Year(), fy.Quarter_Start_Month__c.intValue(), 1);
              QuarterEndDate = Date.NewInstance(currentDateTemp.Year(), fy.Quarter_End_Month__c.IntValue(), 31);
            } else {
              QuarterStartDate = Date.NewInstance(currentDateTemp.Year(), fy.Quarter_Start_Month__c.intValue(), 1);
              QuarterEndDate = Date.NewInstance(currentDateTemp.Year(), fy.Quarter_End_Month__c.IntValue(), 30);
            }
          } else if (currentDateTemp.Month() >= 11) {
            currentQuarter = '4';
            QuarterStartDate = Date.NewInstance(currentDateTemp.Year(), 11, 1);
            QuarterEndDate = Date.NewInstance(currentDateTemp.Year() + 1, 1, 31);
          } else if (currentDateTemp.Month() == 1) {
            currentQuarter = '4';
            QuarterStartDate = Date.NewInstance(currentDateTemp.Year() - 1, 11, 1);
            QuarterEndDate = Date.NewInstance(currentDateTemp.Year(), 1, 31);
          }
        }
        quarterEndPlusDay1 = QuarterEndDate.addDays(1);
      }
      if (bookingSyncMapsList.isEmpty())
        throw new CustomException('Missing BookingSYnc Mapping metadata');

      //get Bookings from current quarter Start and End Dates
      whereClause = ' Opportunity_Close_Date__c >= :QuarterStartDate AND Opportunity_Close_Date__c <= :QuarterEndDate  ';

      for (Booking_Sync_Mapping__mdt b : bookingSyncMapsList) {
        for (integer i = 0; i < b.ConfigureBookingSyncs__r.size(); i++) {
          whereClause +=
            ' AND ' +
            b.ConfigureBookingSyncs__r[i].Booking_API_Name__c +
            ' ' +
            b.ConfigureBookingSyncs__r[i].Operator__c +
            ' ' +
            b.ConfigureBookingSyncs__r[i].Booking_Value__c;
        }
      }

      string tempString = '';
      for (Integer i = 0; i < bookingSyncMapsList.size(); i++) {
        if (i == 0) {
          finalQuery = 'Select  ' + bookingSyncMapsList[i].Booking_Field_name__c + ' , ' + bookingSyncMapsList[i].Opportunity_Field_Name__c;
          tempString += bookingSyncMapsList[i].Booking_Field_name__c;
        } else {
          finalQuery += ' , ' + bookingSyncMapsList[i].Booking_Field_name__c + ' , ' + bookingSyncMapsList[i].Opportunity_Field_Name__c;
          tempString += ' , ' + bookingSyncMapsList[i].Booking_Field_name__c;
        }
        if (i == bookingSyncMapsList.size() - 1)
          finalQuery +=
            ' ,RecordType.Name,id,Field_Update_Status__c,CreatedDate,BookingName__c,(select id ,Field_Update_Status__c, ' +
            tempString +
            ' from BookingAdjustments__r) FROM Booking__c where ' +
            WhereClause;
      }
    } catch (CustomException e) {
      errLog.add(LogError.CreateGenericErrorLog(className, e, ERROR_FUNCTIONALITY));
    } catch (Exception e) {
      errLog.add(LogError.CreateGenericErrorLog(className, e, ERROR_FUNCTIONALITY));
    }
    system.debug(LoggingLevel.DEBUG, 'Query is' + finalQuery);

    /**
     * @description apex job SAL-1818 start
     */
    AsyncApexJob[] jobs = [SELECT id FROM AsyncApexJob WHERE status = 'Processing' AND ApexClass.Name = :className AND JobType = 'BatchApex'];
    if (jobs.size() > 0) {
      finalQuery += ' LIMIT 0';
    }
    //SAL-1818 end
    return Database.getQueryLocator(finalQuery);
  }

  //Execue method
  /**
   * @description execute method
   * @param bc
   * @param scope
   */
  global void execute(Database.BatchableContext bc, List<Booking__c> scope) {
    List<Booking__c> bookingsToBeUpdated = new List<Booking__c>();
    List<Booking__c> adjustmentsToBeUpdated = new List<Booking__c>();
    string ErrorMessage = '';
    string UnProcessedRecord = '';
    string ErrorMessageAdj = '';
    string UnProcessedAdj = '';
    // PRDOPS23-284 - Prashant
    set<id> ProcessedOppIds = new Set<id>();
    List<Booking_Split__c> bkgSplits = new List<Booking_Split__c>();
    Set<Id> SuccessBookingupdateIdSet = new Set<Id>();
    List<string> splitOppField = new List<string>();
    List<Booking_Line_Item__c> lstBLIUpdate = new List<Booking_Line_Item__c>(); // PRDOPS25-1224-BLIs To Update
    try {
      if (!scope.isEmpty()) {
        for (Booking__c bkg : scope) {
          //Get Booking Created Quarter Details
          if (!quarterMap.isEmpty()) {
            for (Financial_Year__mdt fy : quarterMap) {
              if (bkg.CreatedDate.Month() >= fy.Quarter_Start_Month__c && bkg.CreatedDate.Month() <= fy.Quarter_End_Month__c) {
                bookingCreatedQuarter = fy.Quarter__c;
              } else if (bkg.CreatedDate.Month() >= 11 || bkg.CreatedDate.Month() == 1) {
                bookingCreatedQuarter = '4';
              }
            }
          }
          system.debug(LoggingLevel.DEBUG, 'AS-->bookingCreatedQuarter' + bookingCreatedQuarter);
          Booking__c bookingRecord = new Booking__c(id = bkg.id);

          if (!bookingSyncMapsList.isEmpty()) {
            for (Booking_Sync_Mapping__mdt bookingMap : bookingSyncMapsList) {
              //Booking_Audit__c bkgAudit = new Booking_Audit__c();
              splitOppField = bookingMap.Opportunity_Field_Name__c.split('\\.');
              sObject bkgSobj = bkg;
              for (Integer i = 0; i < (splitOppField.size() - 1) && bkgSobj != null; i++) {
                if (bkgSobj.getSObject(splitOppField[i]) == null) {
                  bkgSobj = null;
                  break;
                }
                bkgSobj = bkgSobj.getSObject(splitOppField[i]);
              }

              if (currentDate <= quarterEndPlusDay1) {
                //Update all Core and Commisionalbe fields if BookingStatus is NULL
                if (String.isBlank(bkg.Field_Update_Status__c) && bkg?.RecordType?.Name == 'Booking') {
                  if (bkgSobj != null && bkgSobj.get(splitOppField.get(splitOppField.size() - 1)) != null) {
                    if (bkg.get(bookingMap.Booking_Field_name__c) != bkgSobj.get(splitOppField.get(splitOppField.size() - 1))) {
                      bookingRecord.put(bookingMap.Booking_Field_name__c, bkgSobj.get(splitOppField.get(splitOppField.size() - 1)));
                    }
                  }
                }
                // PRDOPS23-284 - Prashant
                ProcessedOppIds.add(bkg.Opportunity__c);
              }
            }

            system.debug(LoggingLevel.DEBUG, 'ProcessedOppIds is #### ' + ProcessedOppIds);
            //If Current Date is Quarter End plus 1 day
            if (currentDate == quarterEndPlusDay1 && currentDateTimeAMPMcheck == 'PM' && String.isBlank(bkg.Field_Update_Status__c)) {
              bookingRecord.Field_Update_Status__c = 'Freeze Completed';
            }
          }

          bookingsToBeUpdated.add(bookingRecord);
          if (!bkg.BookingAdjustments__r.isEmpty())
            mapOfIdAndBookings.put(bookingRecord, bkg.BookingAdjustments__r);
        }
      }

      //Update Bookings and capture success Ids/Error message
      if (!bookingsToBeUpdated.isEmpty()) {
        system.debug(LoggingLevel.DEBUG, 'AS-->bookingsToBeUpdated' + bookingsToBeUpdated);
        Database.saveResult[] bkgupdateSR = Database.update(bookingsToBeUpdated, false);
        // Iterate through each returned result
        for (Integer i = 0; i < bkgupdateSR.size(); i++) {
          if (!bkgupdateSR[i].isSuccess()) {
            //only look at failures, or NOT Successes
            for (Database.Error err : bkgupdateSR[i].getErrors()) {
              ErrorMessage += err.getFields() + '::' + err.getMessage() + ',';
            }
            UnProcessedRecord += bookingsToBeUpdated[i].BookingName__c + ',';
          } else {
            SuccessBookingupdateIdSet.add(bkgupdateSR[i].getId());
          }
        }
      }

      system.debug(LoggingLevel.DEBUG, 'AS__>SuccessBookingupdateIdSet' + SuccessBookingupdateIdSet);
      //Update Adjustments for successfully updated Bookings
      if (!SuccessBookingupdateIdSet.isEmpty()) {
        for (Booking__c bkg : mapOfIdAndBookings.keySet()) {
          if (SuccessBookingupdateIdSet.contains(bkg.Id) && !mapOfIdAndBookings.get(bkg).isEmpty()) {
            for (Booking__c adjustment : mapOfIdAndBookings.get(bkg)) {
              Booking__c adjBooking = new Booking__c(Id = adjustment.id);
              if (!bookingSyncMapsList.isEmpty()) {
                for (Booking_Sync_Mapping__mdt bookingMap : bookingSyncMapsList) {
                  if (bkg.get(bookingMap.Booking_Field_name__c) != null && adjustment.get(bookingMap.Booking_Field_name__c) != bkg.get(bookingMap.Booking_Field_name__c)) {
                    adjBooking.put(bookingMap.Booking_Field_name__c, bkg.get(bookingMap.Booking_Field_name__c));
                  }
                }
                if (adjustment.Field_Update_Status__c != bkg.Field_Update_Status__c) {
                  adjBooking.Field_Update_Status__c = bkg.Field_Update_Status__c;
                }
              }
              adjustmentsToBeUpdated.add(adjBooking);
            }
          }
        }
      }

      // PRDOPS23-284 - Prashant
      if (!ProcessedOppIds.isEmpty()) {
        List<Booking_Split__c> splitToDelete = new List<Booking_Split__c>();
        Map<Id, List<booking_split__c>> getSplit = new Map<Id, List<booking_split__c>>();
        Map<Id, Id> bookingSplitWithOpportunity = new Map<Id, Id>();
        Map<id, Opportunity> oppMap = new Map<id, Opportunity>();
        Set<Id> setCCRAmountBased = new Set<Id>();
        Map<Id, Opportunity> mapCCRIdToDebookOpp = new Map<Id, Opportunity>();
        List<Booking_Line_Item__c> lstBLIRecords = [
          SELECT
            Id,
            CCR__r.Amount__c,
            Booking__c,
            Net_TCV_Amount__c,
            OrderProduct__r.Opportunity_Product__r.Quantity,
            OrderProduct__r.Quantity,
            OrderProduct__r.TotalPrice,
            Booking__r.Order__c,
            CCR__r.Opportunity__r.Amount,
            CCR__r.Opportunity__r.New_Expansion_TCV__c,
            CCR__r.Opportunity__r.Subsumed_Renewal_TCV__c,
            CCR__r.Opportunity__r.ACV_Amount__c,
            CCR__r.Customer_Returns_Type__c,
            CCR__r.Opportunity__r.New_Expansion_ACV__c,
            CCR__r.Opportunity__r.Renewal_Subsumed_ACV__c,
            CCR__c,
            CCR__r.Opportunity__c,
            Total_Price__c,
            OrderProduct__r.Opportunity_Product__r.Opportunity.Opportunity_Sub_Type__c,
            Gross_New_Expansion_ACV__c,
            Subsumed_Renewal_TCV__c,
            Gross_Subsumed_Renewal_ACV__c,
            OrderProduct__c,
            OrderProduct__r.Opportunity_Product__c,
            Type__c,
            PromoDiscTCV__c,
            Prepayment_Credit__c,
            Oppty_Trade_Up_Discount__c,
            OrderProduct__r.Opportunity_Product__r.New_Expansion_TCV__c,
            OrderProduct__r.Opportunity_Product__r.Subsumed_Renewal_TCV__c,
            OrderProduct__r.Opportunity_Product__r.New_Expansion_ACV__c,
            OrderProduct__r.Opportunity_Product__r.Subsumed_Renewal_Amount__c,
            OrderProduct__r.Opportunity_Product__r.ACV_Amount__c,
            OrderProduct__r.Opportunity_Product__r.PromoDiscTCV__c,
            OrderProduct__r.Opportunity_Product__r.Oppty_Trade_Up_Discount__c,
            OrderProduct__r.Opportunity_Product__r.Prepayment_Credit__c,
            Booking__r.Order__r.Opportunity.CCR__r.Customer_Returns_Type__c,
            Booking__r.Field_Update_Status__c,
            Booking__r.Opportunity__c,
            Rebate__c,
            Booking__r.Opportunity__r.New_Expansion_TCV__c,
            Booking__r.Opportunity__r.Subsumed_Renewal_TCV__c,
            Booking__r.Opportunity__r.ACV_Amount__c,
            Booking__r.Opportunity__r.New_Expansion_ACV__c,
            Booking__r.Opportunity__r.Renewal_Subsumed_ACV__c,
            OrderProduct__r.Opportunity_Product__r.TotalPrice,
            Net_Subsumed_Renewal_TCV__c,
            Gross_ACV_Amount__c,
            New_Expansion_TCV__c,
            Net_ACV_Amount__c,
            Net_New_Expansion_ACV__c,
            Net_New_Expansion_TCV__c,
            Net_Subsumed_Renewal_ACV__c
          FROM Booking_Line_Item__c
          WHERE Booking__r.Field_Update_Status__c != 'Freeze Completed' AND Booking__r.Opportunity__c IN :ProcessedOppIds AND
          Booking__r.Opportunity_Close_Date__c >= :QuarterStartDate AND Booking__r.Opportunity_Close_Date__c <= :QuarterEndDate
          ORDER BY createdDate ASC
        ]; // ASC
        Map<Id, List<Booking_Line_Item__c>> mapCCRIdToListOfBlis = new Map<Id, List<Booking_Line_Item__c>>();
        Map<String, Id> mapBookingIdTCVToCCRId = new Map<String, Id>();
        for (Booking_Line_Item__c objbLI : lstBLIRecords) {
          if (objbLI.CCR__c != null && objbLI?.CCR__r?.Customer_Returns_Type__c == 'Amount Based') {
            setCCRAmountBased.add(objbLI.CCR__c);
            if (!mapCCRIdToListOfBlis.containsKey(objbLI.CCR__c)) {
              mapCCRIdToListOfBlis.put(objbLI.CCR__c, new List<Booking_Line_Item__c>{ objbLI });
            } else {
              mapCCRIdToListOfBlis.get(objbLI.CCR__c).add(objbLI);
            }
            if (objbLI?.CCR__r?.Amount__c != null) {
              mapBookingIdTCVToCCRId.put(objbLI.Booking__c + '-' + objbLI.CCR__r.Amount__c, objbLI.CCR__c);
            }
          }
        }
        system.debug(LoggingLevel.DEBUG, ':::setCCRAmountBased::' + setCCRAmountBased);
        if (!ProcessedOppIds.isEmpty() || !setCCRAmountBased.isEmpty()) {
          oppMap = new Map<id, Opportunity>(
            [
              SELECT
                id,
                CCR__c,
                ACV_Amount__c,
                Renewal_Subsumed_ACV__c,
                New_Expansion_ACV__c,
                New_Expansion_TCV__c,
                Subsumed_Renewal_TCV__c,
                Name,
                ETM_Theatre__c,
                ETM_Area__c,
                ETM_Region__c,
                ETM_Territory__c,
                split__c,
                Opportunity_Split_Parent__c,
                amount,
                Split_percentage__c,
                Split_Amount__c,
                OwnerId,
                Opp_PLS_ETM_Area__c,
                Opp_PLS_ETM_Region__c,
                Opp_PLS_ETM_Territory__c,
                Opp_PLS_ETM_Theatre__c,
                Opp_PLS_NCD_ETM_Area__c,
                Opp_PLS_NCD_ETM_Region__c,
                Opp_PLS_NCD_ETM_Territory__c,
                Opp_PLS_NCD_ETM_Theatre__c,
                Opp_PLS_SaaS_ETM_Area__c,
                Opp_PLS_SaaS_ETM_Region__c,
                Opp_PLS_SaaS_ETM_Territory__c,
                Opp_PLS_SaaS_ETM_Theatre__c,
                (SELECT Id, Opportunity__c, Opportunity_Split__c, Sales_Rep__c, Opp_PLS_ETM_Area__c, Opp_PLS_ETM_Region__c, Opp_PLS_ETM_Territory__c, Opp_PLS_ETM_Theatre__c,Opp_PLS_NCD_ETM_Area__c, Opp_PLS_NCD_ETM_Region__c, Opp_PLS_NCD_ETM_Territory__c, Opp_PLS_NCD_ETM_Theatre__c, Opp_PLS_SaaS_ETM_Area__c, Opp_PLS_SaaS_ETM_Region__c, Opp_PLS_SaaS_ETM_Territory__c, Opp_PLS_SaaS_ETM_Theatre__c, Theatre__c, Area__c, Region__c, Territory__c FROM booking_splits__r),
                (
                  SELECT
                    id,
                    Name,
                    Split_percentage__c,
                    Split_Amount__c,
                    split__c,
                    amount,
                    ETM_Theatre__c,
                    ETM_Area__c,
                    ETM_Region__c,
                    Opportunity_Split_Parent__c,
                    ETM_Territory__c,
                    OwnerId,
                    Opp_PLS_ETM_Area__c,
                    Opp_PLS_ETM_Region__c,
                    Opp_PLS_ETM_Territory__c,
                    Opp_PLS_ETM_Theatre__c,
                    Opp_PLS_NCD_ETM_Area__c,
                    Opp_PLS_NCD_ETM_Region__c,
                    Opp_PLS_NCD_ETM_Territory__c,
                    Opp_PLS_NCD_ETM_Theatre__c,
                    Opp_PLS_SaaS_ETM_Area__c,
                    Opp_PLS_SaaS_ETM_Region__c,
                    Opp_PLS_SaaS_ETM_Territory__c,
                    Opp_PLS_SaaS_ETM_Theatre__c
                  FROM Split_Opportunities__r
                )
              FROM Opportunity
              WHERE id IN :ProcessedOppIds OR Opportunity_Split_Parent__c IN :ProcessedOppIds OR CCR__c IN :setCCRAmountBased
            ]
          );

          for (Opportunity objOpp : oppMap.values()) {
            if (objOpp.CCR__c != null && setCCRAmountBased.contains(objOpp.CCR__c)) {
              mapCCRIdToDebookOpp.put(objOpp.CCR__c, objOpp);
            }
          }
        }

        if (!lstBLIRecords.isEmpty()) {
          lstBLIUpdate = getBookingLineItems(lstBLIRecords, mapCCRIdToDebookOpp, mapBookingIdTCVToCCRId, mapCCRIdToListOfBlis);
        }
        Set<Id> splitOpptId = new Set<Id>();
        List<Booking_Split__c> listToBeDeleted = new List<Booking_Split__c>();
        for (Booking__c bkg : [
          SELECT
            id,
            Opportunity__c,
            Opportunity__r.Opportunity_Split_Parent__c,
            (
              SELECT Id, Opportunity__c, Sales_Rep__c, Opportunity_Split__c, Opp_PLS_ETM_Area__c, Opp_PLS_ETM_Region__c, Opp_PLS_ETM_Territory__c, Opp_PLS_ETM_Theatre__c, Opp_PLS_NCD_ETM_Area__c, Opp_PLS_NCD_ETM_Region__c, Opp_PLS_NCD_ETM_Territory__c, Opp_PLS_NCD_ETM_Theatre__c, Opp_PLS_SaaS_ETM_Area__c, Opp_PLS_SaaS_ETM_Region__c, Opp_PLS_SaaS_ETM_Territory__c, Opp_PLS_SaaS_ETM_Theatre__c, Theatre__c, Area__c, Region__c, Territory__c, Opportunity__r.Opportunity_Split_Parent__c
              FROM Booking_Splits__r
            )
          FROM booking__c
          WHERE id IN :SuccessBookingupdateIdSet
        ]) {
          if (!oppMap.isEmpty() && oppMap.containsKey(bkg.Opportunity__c)) {
            Opportunity opp = oppMap.get(bkg.Opportunity__c);
            if (bkg.Booking_Splits__r.size() > 0) {
              for (Booking_Split__c sb : bkg.Booking_Splits__r) {
                // Logic If Split opportunity is Deleted then Delete Booking Split
                if (sb.Opportunity__c == null) {
                  listToBeDeleted.add(sb);
                }
                // Logic If opportunity Has changed field values then Update Booking Split
                if (oppMap.containskey(sb.Opportunity__c)) {
                  Opportunity opptyOnBs = oppMap.get(sb.Opportunity__c);
                  Decimal splitPercentage;
                  if (sb.Opportunity_Split__c != opptyOnBs.Split_percentage__c && opptyOnBs.Split_percentage__c != null) {
                    splitPercentage = opptyOnBs.Split_percentage__c;
                  }
                  if (
                    splitPercentage != null ||
                    sb.Sales_Rep__c != opptyOnBs.OwnerId ||
                    sb.Theatre__c != opptyOnBs.ETM_Theatre__c ||
                    sb.Area__c != opptyOnBs.ETM_Area__c ||
                    sb.Region__c != opptyOnBs.ETM_Region__c ||
                    sb.Territory__c != opptyOnBs.ETM_Territory__c ||
                    sb.Opp_PLS_ETM_Area__c != opptyOnBs.Opp_PLS_ETM_Area__c ||
                    sb.Opp_PLS_ETM_Region__c != opptyOnBs.Opp_PLS_ETM_Region__c ||
                    sb.Opp_PLS_ETM_Territory__c != opptyOnBs.Opp_PLS_ETM_Territory__c ||
                    sb.Opp_PLS_ETM_Theatre__c != opptyOnBs.Opp_PLS_ETM_Theatre__c ||
                    sb.Opp_PLS_NCD_ETM_Area__c != opptyOnBs.Opp_PLS_NCD_ETM_Area__c ||
                    sb.Opp_PLS_NCD_ETM_Region__c != opptyOnBs.Opp_PLS_NCD_ETM_Region__c ||
                    sb.Opp_PLS_NCD_ETM_Territory__c != opptyOnBs.Opp_PLS_NCD_ETM_Territory__c ||
                    sb.Opp_PLS_NCD_ETM_Theatre__c != opptyOnBs.Opp_PLS_NCD_ETM_Theatre__c ||
                    sb.Opp_PLS_SaaS_ETM_Area__c != opptyOnBs.Opp_PLS_SaaS_ETM_Area__c ||
                    sb.Opp_PLS_SaaS_ETM_Region__c != opptyOnBs.Opp_PLS_SaaS_ETM_Region__c ||
                    sb.Opp_PLS_SaaS_ETM_Territory__c != opptyOnBs.Opp_PLS_SaaS_ETM_Territory__c ||
                    sb.Opp_PLS_SaaS_ETM_Theatre__c != opptyOnBs.Opp_PLS_SaaS_ETM_Theatre__c
                  ) {
                    bkgSplits.add(
                      new Booking_split__c(
                        Opportunity_Split__c = splitPercentage,
                        Sales_Rep__c = opptyOnBs.OwnerId,
                        Theatre__c = opptyOnBs.ETM_Theatre__c,
                        Area__c = opptyOnBs.ETM_Area__c,
                        Region__c = opptyOnBs.ETM_Region__c,
                        Territory__c = opptyOnBs.ETM_Territory__c,
                        Id = sb.Id,
                        Opp_PLS_ETM_Area__c = opptyOnBs.Opp_PLS_ETM_Area__c,
                        Opp_PLS_ETM_Region__c = opptyOnBs.Opp_PLS_ETM_Region__c,
                        Opp_PLS_ETM_Territory__c = opptyOnBs.Opp_PLS_ETM_Territory__c,
                        Opp_PLS_ETM_Theatre__c = opptyOnBs.Opp_PLS_ETM_Theatre__c,
                        Opp_PLS_NCD_ETM_Area__c = opptyOnBs.Opp_PLS_NCD_ETM_Area__c,
                        Opp_PLS_NCD_ETM_Region__c = opptyOnBs.Opp_PLS_NCD_ETM_Region__c,
                        Opp_PLS_NCD_ETM_Territory__c = opptyOnBs.Opp_PLS_NCD_ETM_Territory__c,
                        Opp_PLS_NCD_ETM_Theatre__c = opptyOnBs.Opp_PLS_NCD_ETM_Theatre__c,
                        Opp_PLS_SaaS_ETM_Area__c = opptyOnBs.Opp_PLS_SaaS_ETM_Area__c,
                        Opp_PLS_SaaS_ETM_Region__c = opptyOnBs.Opp_PLS_SaaS_ETM_Region__c,
                        Opp_PLS_SaaS_ETM_Territory__c = opptyOnBs.Opp_PLS_SaaS_ETM_Territory__c,
                        Opp_PLS_SaaS_ETM_Theatre__c = opptyOnBs.Opp_PLS_SaaS_ETM_Theatre__c
                      )
                    );
                  }
                }
              }
            }
            if (oppMap.containskey(opp.Id) && oppMap.get(opp.Id).booking_splits__r.size() == 0) {
              Booking_Split__c bkgChildSplit = new Booking_Split__c();
              bkgChildSplit = getBookingSplit(bkg.id, opp);
              bkgSplits.add(bkgChildSplit);
            }
            // Logic If Split Opportunity Has No Child Booking Split then create one.
            for (Opportunity spliopp : opp.Split_Opportunities__r) {
              if (spliopp.Opportunity_Split_Parent__c != null) {
                if (oppMap.containskey(spliopp.id) && oppMap.get(spliopp.Id).booking_splits__r.size() == 0) {
                  Booking_Split__c bkgChildSplit = new Booking_Split__c();
                  bkgChildSplit = getBookingSplit(bkg.id, spliopp);
                  bkgSplits.add(bkgChildSplit);
                }
              }
            }
          }
        }

        if (!bkgSplits.isEmpty()) {
          database.upsert(bkgSplits, false);
        }
        if (!listToBeDeleted.isEmpty()) {
          database.delete(listToBeDeleted, false);
        }
        // PRDOPS25-1224 - Update BLI after calculation of ACV and TCV
        if (!lstBLIUpdate.isEmpty()) {
          database.update(lstBLIUpdate, false);
        }
      }
      // end PRDOPS23-284

      //Update Adjustments and capture error details if any
      if (!adjustmentsToBeUpdated.isEmpty()) {
        system.debug(LoggingLevel.DEBUG, 'AS-->adjustmentsToBeUpdated' + adjustmentsToBeUpdated);
        Database.saveResult[] bkgAdjupdateSR = Database.update(adjustmentsToBeUpdated, false);
        // Iterate through each returned result
        for (Integer i = 0; i < bkgAdjupdateSR.size(); i++) {
          if (!bkgAdjupdateSR[i].isSuccess()) {
            //only look at failures, or NOT Successes
            for (Database.Error err : bkgAdjupdateSR[i].getErrors()) {
              ErrorMessageAdj += err.getFields() + '::' + err.getMessage() + ',';
            }
            UnProcessedAdj += adjustmentsToBeUpdated[i].BookingName__c + ',';
          }
        }
      }
      if (String.isNotBlank(UnProcessedRecord)) {
        errLog.add(getErrorForMessage(UnProcessedRecord, ErrorMessage, 'Error with Updating Bookings:', className, ERROR_FUNCTIONALITY));
      }

      if (String.isNotBlank(UnProcessedAdj)) {
        errLog.add(getErrorForMessage(UnProcessedAdj, UnProcessedAdj, 'Error with Updating Adjustments:', className, ERROR_FUNCTIONALITY));
      }
    } catch (CustomException e) {
      errLog.add(LogError.CreateGenericErrorLog(className, e, ERROR_FUNCTIONALITY));
    } catch (Exception e) {
      system.debug(LoggingLevel.DEBUG, 'AS-->exception is' + e);
      errLog.add(LogError.CreateGenericErrorLog(className, e, ERROR_FUNCTIONALITY));
      system.debug(LoggingLevel.DEBUG, 'AS-->exception added to errlog is' + errLog);
    }
  }

  //Finish method
  /**
   * @description Finish method
   * @param BC
   */
  global void finish(Database.BatchableContext BC) {
    system.debug(LoggingLevel.DEBUG, 'BookingSyncBatch::errLog2' + errLog);
    if (!errLog.isEmpty()) {
      insert errLog;
    }
  }

  /**
   * @author Shrutika
   * @date 22-08-2025
   * @description  Method to return the customError 
   * @return Custom_Error_Log__c
   * @param UnProcessedRecord
   * @param ErrorMessage
   * @param strBookingOrAdj
   * @param className
   * @param ERROR_FUNCTIONALITY
   **/
  public static Custom_Error_Log__c getErrorForMessage(String UnProcessedRecord, String ErrorMessage, String strBookingOrAdj, String className, String ERROR_FUNCTIONALITY){
    list<Custom_Error_Log__c> errLog = new List<Custom_Error_Log__c>();
    if (UnProcessedRecord.length() > 255)
      UnProcessedRecord = UnProcessedRecord.substring(0, 255);
    if (ErrorMessage.length() > 131072)
    ErrorMessage = ErrorMessage.substring(0, 131072);
    return LogError.CreateDMLErrorLog(className, strBookingOrAdj +':'+ UnProcessedRecord, ErrorMessage, ERROR_FUNCTIONALITY);
  }

  //Method to return the Booking Line Item
  /**
   * @author Prashant Kumar
   * @date 18-12-2024
   * @description  Method to return the Booking Line Item Enhancement to update values in booking line & booking split  if changes are made on the opportunity before the snapshot is taken Ticket - PRDOPS25-1224
   * @return List of booking Line item
   * @param lstBLIRecords
   * @param mapCCRIdToDebookOpp
   * @param mapBookingIdTCVToCCRId
   * @param mapCCRIdToListOfBlis
   */
  public List<Booking_Line_Item__c> getBookingLineItems(
    List<Booking_line_Item__c> lstBLIRecords,
    Map<Id, Opportunity> mapCCRIdToDebookOpp,
    Map<String, Id> mapBookingIdTCVToCCRId,
    Map<Id, List<Booking_Line_Item__c>> mapCCRIdToListOfBlis
  ) {
    Map<Id, Booking_Line_Item__c> mapBLIIdtoBLIRecords = new Map<Id, Booking_Line_Item__c>();
    Map<Id, Decimal> mapBKGIdToRebate = new Map<Id, Decimal>(); // Distributor Fee
    Map<Id, Booking_Line_Item__c> mapOppIdToPRFRecord = new Map<Id, Booking_Line_Item__c>(); // PRF
    // Map<Id, Decimal> mapOrgOppIdToAmount = new Map<Id, Decimal>(); //original Amount
    Map<Id, Decimal> mapBKGIdToGrossTCV = new Map<Id, Decimal>();
    Map<Id, Decimal> mapBKGIdToNewTCV = new Map<Id, Decimal>();
    Map<Id, Decimal> mapBKGIdToRenewalTCV = new Map<Id, Decimal>();
    Map<Id, Decimal> mapBKGIdToGrossACV = new Map<Id, Decimal>();
    Map<Id, Decimal> mapBKGIdToNewACV = new Map<Id, Decimal>();
    Map<Id, Decimal> mapBKGIdToRenewalACV = new Map<Id, Decimal>();
    List<Booking_Line_Item__c> lstUpdateBLI = new List<Booking_Line_Item__c>();
    if (!lstBLIRecords.isEmpty()) {
      for (Booking_Line_Item__c objBLI : lstBLIRecords) {
        mapBLIIdtoBLIRecords.put(objBLI.Id, objBLI);
        if (objBLI.Type__c == 'Distributor Fee' && objBLI.Rebate__c != null) {
          mapBKGIdToRebate.put(objBLI.Booking__c, objBLI.Rebate__c);

          if (objBLI.Total_Price__c > 0) {
            Decimal totalPrice = (objBLI.Total_Price__c / (objBLI.Rebate__c * 0.01)).setScale(2, RoundingMode.HALF_UP);
            if (totalPrice != null && mapBookingIdTCVToCCRId.containsKey(String.valueOf(objBLI.Booking__c + '-' + totalPrice.setScale(2, RoundingMode.HALF_UP)))) {
              Id CCRId = mapBookingIdTCVToCCRId.get(String.valueOf(objBLI.Booking__c + '-' + totalPrice.setScale(2, RoundingMode.HALF_UP)));
              if (mapCCRIdToListOfBlis.containsKey(CCRId)) {
                mapCCRIdToListOfBlis.get(CCRId).add(objBLI);
              }
            }
          }
          system.debug(LoggingLevel.DEBUG, '::mapCCRIdToListOfBlis::' + mapCCRIdToListOfBlis);
        } else if (objBLI.Type__c == 'Partner Referral Fee' && objBLI.CCR__c != null) {
          // mapOrgOppIdToAmount.put(objBLI.CCR__r.Opportunity__c, objBLI.CCR__r.Opportunity__r.Amount);
          mapOppIdToPRFRecord.put(objBLI.OrderProduct__r.Opportunity_Product__r.OpportunityId, objBLI);
        } else {
          if (objBLI.Booking__r.Order__c != null && objBLI?.OrderProduct__r?.Opportunity_Product__c != null) {
            OpportunityLineItem objOppLine = objBLI?.OrderProduct__r?.Opportunity_Product__r;
            Decimal qtyFactor = objOppLine?.Quantity != null && objBLI?.OrderProduct__r?.Quantity != 0.0 ? objBLI.OrderProduct__r.Quantity / objOppLine.Quantity : 1;

            Decimal grossTCV = objBLI.OrderProduct__r.TotalPrice;
            Decimal newTCV = objOppLine?.New_Expansion_TCV__c == null ? null : (objOppLine?.New_Expansion_TCV__c * qtyFactor);
            Decimal renewalTCV = objOppLine?.Subsumed_Renewal_TCV__c == null ? null : (objOppLine?.Subsumed_Renewal_TCV__c * qtyFactor);
            Decimal grossACV = objOppLine?.ACV_Amount__c == null ? null : (objOppLine?.ACV_Amount__c * qtyFactor);
            Decimal grossNewACV = objOppLine?.New_Expansion_ACV__c == null ? null : (objOppLine?.New_Expansion_ACV__c * qtyFactor);
            Decimal grossRenewalACV = objOppLine?.Subsumed_Renewal_Amount__c == null ? null : (objOppLine?.Subsumed_Renewal_Amount__c * qtyFactor);

            if (grossTCV != null) {
              if (!mapBKGIdToGrossTCV.containsKey(objBLI.Booking__c)) {
                mapBKGIdToGrossTCV.put(objBLI.Booking__c, grossTCV);
              } else {
                mapBKGIdToGrossTCV.put(objBLI.Booking__c, mapBKGIdToGrossTCV.get(objBLI.Booking__c) + grossTCV);
              }
            }
            if (newTCV != null) {
              if (!mapBKGIdToNewTCV.containsKey(objBLI.Booking__c)) {
                mapBKGIdToNewTCV.put(objBLI.Booking__c, newTCV);
              } else {
                mapBKGIdToNewTCV.put(objBLI.Booking__c, mapBKGIdToNewTCV.get(objBLI.Booking__c) + newTCV);
              }
            }

            if (renewalTCV != null) {
              if (!mapBKGIdToRenewalTCV.containsKey(objBLI.Booking__c)) {
                mapBKGIdToRenewalTCV.put(objBLI.Booking__c, renewalTCV);
              } else {
                mapBKGIdToRenewalTCV.put(objBLI.Booking__c, mapBKGIdToRenewalTCV.get(objBLI.Booking__c) + renewalTCV);
              }
            }
            if (grossACV != null) {
              if (!mapBKGIdToGrossACV.containsKey(objBLI.Booking__c)) {
                mapBKGIdToGrossACV.put(objBLI.Booking__c, grossACV);
              } else {
                mapBKGIdToGrossACV.put(objBLI.Booking__c, mapBKGIdToGrossACV.get(objBLI.Booking__c) + grossACV);
              }
            }
            if (grossNewACV != null) {
              if (!mapBKGIdToNewACV.containsKey(objBLI.Booking__c)) {
                mapBKGIdToNewACV.put(objBLI.Booking__c, grossNewACV);
              } else {
                mapBKGIdToNewACV.put(objBLI.Booking__c, mapBKGIdToNewACV.get(objBLI.Booking__c) + grossNewACV);
              }
            }
            if (grossRenewalACV != null) {
              if (!mapBKGIdToRenewalACV.containsKey(objBLI.Booking__c)) {
                mapBKGIdToRenewalACV.put(objBLI.Booking__c, grossRenewalACV);
              } else {
                mapBKGIdToRenewalACV.put(objBLI.Booking__c, mapBKGIdToRenewalACV.get(objBLI.Booking__c) + grossRenewalACV);
              }
            }
          }
        }
      }
      if (!mapBLIIdtoBLIRecords.isEmpty()) {
        for (Booking_Line_Item__c obBLI : mapBLIIdtoBLIRecords.values()) {
          if (
            obBLI.Type__c == 'Distributor Fee' &&
            (obBLI.Total_Price__c < 0 ||
            (obBLI?.Booking__r?.Order__r?.Opportunity?.CCR__r != null &&
            obBLI?.Booking__r?.Order__r?.Opportunity?.CCR__r?.Customer_Returns_Type__c == 'LineItem Based'))
          ) {
             Booking_Line_Item__c objBLI = new Booking_Line_Item__c(
                Id = obBLI.Id,
              New_Expansion_TCV__c = getdifference(obBLI.New_Expansion_TCV__c, getDistifeeValue(mapBKGIdToNewTCV, obBLI.Booking__c), obBLI.Rebate__c * -0.01, obBLI.Type__c),
              Subsumed_Renewal_TCV__c = getdifference(
                obBLI.Subsumed_Renewal_TCV__c,
                getDistifeeValue(mapBKGIdToRenewalTCV, obBLI.Booking__c),
                obBLI.Rebate__c * -0.01,
                obBLI.Type__c
              ),
              Gross_ACV_Amount__c = getdifference(obBLI.Gross_ACV_Amount__c, getDistifeeValue(mapBKGIdToGrossACV, obBLI.Booking__c), obBLI.Rebate__c * -0.01, obBLI.Type__c),
              Gross_New_Expansion_ACV__c = getdifference(
                obBLI.Gross_New_Expansion_ACV__c,
                getDistifeeValue(mapBKGIdToNewACV, obBLI.Booking__c),
                obBLI.Rebate__c * -0.01,
                obBLI.Type__c
              ),
              Gross_Subsumed_Renewal_ACV__c = getdifference(
                obBLI.Gross_Subsumed_Renewal_ACV__c,
                getDistifeeValue(mapBKGIdToRenewalACV, obBLI.Booking__c),
                obBLI.Rebate__c * -0.01,
                obBLI.Type__c
              )
              );
            if (
              hasSignificantDifference(objBLI.New_Expansion_TCV__c, obBLI.New_Expansion_TCV__c) ||
              hasSignificantDifference(objBLI.Subsumed_Renewal_TCV__c, obBLI.Subsumed_Renewal_TCV__c) ||
              hasSignificantDifference(objBLI.Gross_ACV_Amount__c, obBLI.Gross_ACV_Amount__c) ||
              hasSignificantDifference(objBLI.Gross_New_Expansion_ACV__c, obBLI.Gross_New_Expansion_ACV__c) ||
              hasSignificantDifference(objBLI.Gross_Subsumed_Renewal_ACV__c, obBLI.Gross_Subsumed_Renewal_ACV__c)
            ) {
            	lstUpdateBLI.add(objBLI);
            }
          } else if (obBLI.Type__c == 'Partner Referral Fee' && obBLI.CCR__c != null) {
            if (mapOppIdToPRFRecord.containsKey(obBLI.CCR__r.Opportunity__c)) {
              // Booking_Line_Item__c  PRF_Bli = mapOppIdToPRFRecord.get(obBLI.CCR__r.Opportunity__c);
              Booking_Line_Item__c objPRF = new Booking_Line_Item__c(Id = obBLI.Id);
              objPRF.Gross_ACV_Amount__c = objPRF.Net_ACV_Amount__c = obBLI.Total_Price__c * (obBLI.CCR__r.Opportunity__r.ACV_Amount__c / obBLI.CCR__r.Opportunity__r.Amount);
              objPRF.Net_New_Expansion_ACV__c = objPRF.Gross_New_Expansion_ACV__c =
                objPRF.Gross_ACV_Amount__c * (obBLI.CCR__r.Opportunity__r.New_Expansion_ACV__c / obBLI.CCR__r.Opportunity__r.ACV_Amount__c);
              objPRF.Net_Subsumed_Renewal_ACV__c = objPRF.Gross_Subsumed_Renewal_ACV__c =
                objPRF.Gross_ACV_Amount__c * (obBLI.CCR__r.Opportunity__r.Renewal_Subsumed_ACV__c / obBLI.CCR__r.Opportunity__r.ACV_Amount__c);
              objPRF.Net_New_Expansion_TCV__c = objPRF.New_Expansion_TCV__c =
                obBLI.Total_Price__c * (obBLI.CCR__r.Opportunity__r.New_Expansion_TCV__c / obBLI.CCR__r.Opportunity__r.Amount);
              objPRF.Net_Subsumed_Renewal_TCV__c = objPRF.Subsumed_Renewal_TCV__c =
                obBLI.Total_Price__c * (obBLI.CCR__r.Opportunity__r.Subsumed_Renewal_TCV__c / obBLI.CCR__r.Opportunity__r.Amount);
              lstUpdateBLI.add(objPRF);
            }
          } else {
            if (obBLI?.OrderProduct__r?.Opportunity_Product__c != null) {
              OpportunityLineItem objOppLine = obBLI?.OrderProduct__r?.Opportunity_Product__r;
              Decimal rebatePercentage = mapBKGIdToRebate.containsKey(obBLI?.Booking__c) ? mapBKGIdToRebate.get(obBLI?.Booking__c) : 0;
              
              Decimal qtyFactor = (
                obBLI.OrderProduct__r.Quantity != null &&
                obBLI.OrderProduct__r.Quantity != 0.0)
                ? obBLI.OrderProduct__r.Quantity / objOppLine.Quantity
                : 1;

                

              if (
                hasSignificantDifference((objOppLine?.New_Expansion_TCV__c ?? 0) * qtyFactor, obBLI.New_Expansion_TCV__c) ||
                hasSignificantDifference((objOppLine?.Subsumed_Renewal_TCV__c ?? 0) * qtyFactor, obBLI.Subsumed_Renewal_TCV__c) ||
                hasSignificantDifference((objOppLine?.ACV_Amount__c ?? 0) * qtyFactor, obBLI.Gross_ACV_Amount__c) ||
                hasSignificantDifference((objOppLine?.New_Expansion_ACV__c ?? 0) * qtyFactor, obBLI.Gross_New_Expansion_ACV__c) ||
                hasSignificantDifference((objOppLine?.Subsumed_Renewal_Amount__c ?? 0) * qtyFactor, obBLI.Gross_Subsumed_Renewal_ACV__c)  ||
                hasSignificantDifference((objOppLine?.PromoDiscTCV__c ?? 0) * qtyFactor, obBLI.PromoDiscTCV__c) ||
                hasSignificantDifference((objOppLine?.Oppty_Trade_Up_Discount__c ?? 0) * qtyFactor, obBLI.Oppty_Trade_Up_Discount__c) ||
                hasSignificantDifference((objOppLine?.Prepayment_Credit__c ?? 0) * qtyFactor, obBLI.Prepayment_Credit__c)
              ) {
                Booking_Line_Item__c bliOb = new Booking_Line_Item__c(Id = obBLI.Id);
                bliOb.Net_TCV_Amount__c = ((obBLI?.OrderProduct__r?.TotalPrice ?? 0) * ((100 - rebatePercentage) * 0.01)).setScale(2, RoundingMode.HALF_UP);
                bliOb.New_Expansion_TCV__c = getdifference(obBLI.New_Expansion_TCV__c, ((objOppLine?.New_Expansion_TCV__c ?? 0) * qtyFactor), null, obBLI.Type__c);
                bliOb.Net_New_Expansion_TCV__c = getdifference(bliOb.New_Expansion_TCV__c, null, rebatePercentage, obBLI.Type__c);
                bliOb.Subsumed_Renewal_TCV__c = getdifference(obBLI.Subsumed_Renewal_TCV__c, ((objOppLine?.Subsumed_Renewal_TCV__c ?? 0) * qtyFactor), null, obBLI.Type__c);
                bliOb.Net_Subsumed_Renewal_TCV__c = getdifference(bliOb.Subsumed_Renewal_TCV__c, null, rebatePercentage, obBLI.Type__c);
                bliOb.Gross_ACV_Amount__c = getdifference(obBLI.Gross_ACV_Amount__c, ((objOppLine?.ACV_Amount__c ?? 0) * qtyFactor), null, obBLI.Type__c);
                bliOb.Net_ACV_Amount__c = getdifference(bliOb.Gross_ACV_Amount__c, null, rebatePercentage, obBLI.Type__c);
                bliOb.Gross_New_Expansion_ACV__c = getdifference(obBLI.Gross_New_Expansion_ACV__c, ((objOppLine?.New_Expansion_ACV__c ?? 0) * qtyFactor), null, obBLI.Type__c);
                bliOb.Net_New_Expansion_ACV__c = getdifference(bliOb.Gross_New_Expansion_ACV__c, null, rebatePercentage, obBLI.Type__c);
                bliOb.Gross_Subsumed_Renewal_ACV__c = getdifference(
                  obBLI.Gross_Subsumed_Renewal_ACV__c,
                  ((objOppLine?.Subsumed_Renewal_Amount__c ?? 0) * qtyFactor),
                  null,
                  obBLI.Type__c
                );
                bliOb.Net_Subsumed_Renewal_ACV__c = getdifference(bliOb.Gross_Subsumed_Renewal_ACV__c, null, rebatePercentage, obBLI.Type__c);
                bliOb.PromoDiscTCV__c = getdifference(bliOb.PromoDiscTCV__c, (objOppLine?.PromoDiscTCV__c ?? 0) * qtyFactor, null, null);
                bliOb.Oppty_Trade_Up_Discount__c = getdifference(bliOb.Oppty_Trade_Up_Discount__c, (objOppLine?.Oppty_Trade_Up_Discount__c ?? 0) * qtyFactor, null, null);
                bliOb.Prepayment_Credit__c = getdifference(bliOb.Prepayment_Credit__c, (objOppLine?.Prepayment_Credit__c ?? 0) * qtyFactor, null, null);
                if (bliOb != null){
                  lstUpdateBLI.add(bliOb);
              }
            }
          }
        }
      }
    }
    }
    //debook Amount based resync
    if (!mapCCRIdToListOfBlis.isEmpty()) {
      for (Id ccrId : mapCCRIdToListOfBlis.keySet()) {
        system.debug(LoggingLevel.DEBUG, '::ccrId::' + ccrId);
        for (Booking_Line_Item__c objBLI : mapCCRIdToListOfBlis.get(ccrId)) {
          if (objBLI.CCR__c != null && mapCCRIdToDebookOpp.containsKey(objBLI.CCR__c)) {
            Decimal rebatePercentage = mapBKGIdToRebate.containsKey(objBLI?.Booking__c) ? mapBKGIdToRebate.get(objBLI?.Booking__c) : 0;
            Opportunity debookOpp = mapCCRIdToDebookOpp.get(objBLI.CCR__c);

            if (
              hasSignificantDifference((debookOpp?.New_Expansion_TCV__c ?? 0), objBLI.New_Expansion_TCV__c) ||
              hasSignificantDifference((debookOpp?.Subsumed_Renewal_TCV__c ?? 0), objBLI.Subsumed_Renewal_TCV__c) ||
              hasSignificantDifference((debookOpp?.ACV_Amount__c ?? 0), objBLI.Gross_ACV_Amount__c) ||
              hasSignificantDifference((debookOpp?.New_Expansion_ACV__c ?? 0), objBLI.Gross_New_Expansion_ACV__c) ||
              hasSignificantDifference((debookOpp?.Renewal_Subsumed_ACV__c ?? 0), objBLI.Gross_Subsumed_Renewal_ACV__c)
            ) {
              Booking_Line_Item__c bliOb = new Booking_Line_Item__c(Id = objBLI.Id);
              bliOb.Net_TCV_Amount__c = debookOpp?.Amount != null
                ? (debookOpp?.Amount * ((100 - rebatePercentage) * 0.01)).setScale(2, RoundingMode.HALF_UP)
                : objBLI.Net_TCV_Amount__c;

              bliOb.New_Expansion_TCV__c = getdifference(objBLI.New_Expansion_TCV__c, debookOpp?.New_Expansion_TCV__c ?? 0, null, objBLI.Type__c);
              bliOb.Net_New_Expansion_TCV__c = getdifference(bliOb.New_Expansion_TCV__c, null, rebatePercentage, objBLI.Type__c);
              bliOb.Subsumed_Renewal_TCV__c = getdifference(objBLI.Subsumed_Renewal_TCV__c, debookOpp?.Subsumed_Renewal_TCV__c ?? 0, null, objBLI.Type__c);
              bliOb.Net_Subsumed_Renewal_TCV__c = getdifference(bliOb.Subsumed_Renewal_TCV__c, null, rebatePercentage, objBLI.Type__c);
              bliOb.Gross_ACV_Amount__c = getdifference(objBLI.Gross_ACV_Amount__c, debookOpp?.ACV_Amount__c ?? 0, null, objBLI.Type__c);
              bliOb.Net_ACV_Amount__c = getdifference(bliOb.Gross_ACV_Amount__c, null, rebatePercentage, objBLI.Type__c);
              bliOb.Gross_New_Expansion_ACV__c = getdifference(objBLI.Gross_New_Expansion_ACV__c, debookOpp?.New_Expansion_ACV__c ?? 0, null, objBLI.Type__c);
              bliOb.Net_New_Expansion_ACV__c = getdifference(bliOb.Gross_New_Expansion_ACV__c, null, rebatePercentage, objBLI.Type__c);
              bliOb.Gross_Subsumed_Renewal_ACV__c = getdifference(objBLI.Gross_Subsumed_Renewal_ACV__c, debookOpp?.Renewal_Subsumed_ACV__c ?? 0, null, objBLI.Type__c);
              bliOb.Net_Subsumed_Renewal_ACV__c = getdifference(bliOb.Gross_Subsumed_Renewal_ACV__c, null, rebatePercentage, objBLI.Type__c);

              if (bliOb != null)
                lstUpdateBLI.add(bliOb);
            }
          } else if (objBLI.Type__c == 'Distributor Fee' && mapCCRIdToDebookOpp.containsKey(ccrId)) {
            Opportunity debookOpp = mapCCRIdToDebookOpp.get(ccrId);
            Booking_Line_Item__c bliOb = new Booking_Line_Item__c(Id = objBLI.Id);

            bliOb.Subsumed_Renewal_TCV__c = getdifference(objBLI.Subsumed_Renewal_TCV__c, debookOpp.Subsumed_Renewal_TCV__c ?? 0, objBLI.Rebate__c * -0.01, objBLI.Type__c);
            bliOb.New_Expansion_TCV__c = getdifference(objBLI.New_Expansion_TCV__c, debookOpp.New_Expansion_TCV__c ?? 0, objBLI.Rebate__c * -0.01, objBLI.Type__c);
            bliOb.Gross_ACV_Amount__c = getdifference(objBLI.Gross_ACV_Amount__c, debookOpp.ACV_Amount__c ?? 0, objBLI.Rebate__c * -0.01, objBLI.Type__c);
            bliOb.Gross_New_Expansion_ACV__c = getdifference(objBLI.Gross_New_Expansion_ACV__c, debookOpp.New_Expansion_ACV__c ?? 0, objBLI.Rebate__c * -0.01, objBLI.Type__c);
            bliOb.Gross_Subsumed_Renewal_ACV__c = getdifference(
              objBLI.Gross_Subsumed_Renewal_ACV__c,
              debookOpp.Renewal_Subsumed_ACV__c ?? 0,
              objBLI.Rebate__c * -0.01,
              objBLI.Type__c
            );

            if (
              hasSignificantDifference(bliOb.New_Expansion_TCV__c, objBLI.New_Expansion_TCV__c) ||
              hasSignificantDifference(bliOb.Subsumed_Renewal_TCV__c, objBLI.Subsumed_Renewal_TCV__c) ||
              hasSignificantDifference(bliOb.Gross_ACV_Amount__c, objBLI.Gross_ACV_Amount__c) ||
              hasSignificantDifference(bliOb.Gross_New_Expansion_ACV__c, objBLI.Gross_New_Expansion_ACV__c) ||
              hasSignificantDifference(bliOb.Gross_Subsumed_Renewal_ACV__c, objBLI.Gross_Subsumed_Renewal_ACV__c)
            )
              lstUpdateBLI.add(bliOb);
          }
        }
      }
    }

    return lstUpdateBLI;
  }
  /**
   * @description getDistifeeValue value for Disti fee
   * @param mapBookingIdToValue
   * @param BookingId
   * @return decimal
   **/
  public decimal getDistifeeValue(Map<Id, Decimal> mapBookingIdToValue, Id BookingId) {
    return mapBookingIdToValue.containsKey(BookingId) && mapBookingIdToValue.get(BookingId) != null ? mapBookingIdToValue.get(BookingId) : 0;
  }
  /**
   * @description getdiffence value for BLI
   * @param bliValue
   * @param debookOppValue
   * @param rebatePercentage
   * @param Type
   * @return bliValue
   * */

  public Decimal getdifference(Decimal bliValue, Decimal debookOppValue, Decimal rebatePercentage, String Type) {
    Decimal newBLIValue = bliValue;
    if (debookOppValue != null && debookOppValue != bliValue) {
      if (Type == 'Distributor Fee' && rebatePercentage != null) {
        newBLIValue = ((debookOppValue * rebatePercentage).setScale(2, RoundingMode.HALF_UP));
      } else if (rebatePercentage == null) {
        newBLIValue = debookOppValue;
      }
    } else {
      if (rebatePercentage != null) {
        newBLIValue = (bliValue != null ? (bliValue * ((100 - rebatePercentage) * 0.01)).setScale(2, RoundingMode.HALF_UP) : null);
      }
    }
    return newBLIValue;
  }

  // PRDOPS23-284 - Prashant
  // Method to return booking Split Instance
  /**
   * @description Method to return booking Split Instance
   * @param bookingId
   * @param oppty
   * @return list og booking Split
   */
  public Booking_Split__c getBookingSplit(Id bookingId, Opportunity oppty) {
    Booking_Split__c bkgChildSplit = new Booking_Split__c();
    bkgChildSplit.Booking__c = bookingId;
    bkgChildSplit.Sales_Rep__c = oppty.OwnerId;
    if (oppty.Split_percentage__c != null) {
      bkgChildSplit.Opportunity_Split__c = oppty.Split_percentage__c;
    }
    bkgChildSplit.Theatre__c = oppty.ETM_Theatre__c;
    bkgChildSplit.Area__c = oppty.ETM_Area__c;
    bkgChildSplit.Region__c = oppty.ETM_Region__c;
    bkgChildSplit.Territory__c = oppty.ETM_Territory__c;
    bkgChildSplit.Opportunity__c = oppty.id;
    bkgChildSplit.Opp_PLS_ETM_Area__c = oppty.Opp_PLS_ETM_Area__c;
    bkgChildSplit.Opp_PLS_ETM_Region__c = oppty.Opp_PLS_ETM_Region__c;
    bkgChildSplit.Opp_PLS_ETM_Territory__c = oppty.Opp_PLS_ETM_Territory__c;
    bkgChildSplit.Opp_PLS_ETM_Theatre__c = oppty.Opp_PLS_ETM_Theatre__c;
    bkgChildSplit.Opp_PLS_NCD_ETM_Area__c = oppty.Opp_PLS_NCD_ETM_Area__c;
    bkgChildSplit.Opp_PLS_NCD_ETM_Region__c = oppty.Opp_PLS_NCD_ETM_Region__c;
    bkgChildSplit.Opp_PLS_NCD_ETM_Territory__c = oppty.Opp_PLS_NCD_ETM_Territory__c;
    bkgChildSplit.Opp_PLS_NCD_ETM_Theatre__c = oppty.Opp_PLS_NCD_ETM_Theatre__c;
    bkgChildSplit.Opp_PLS_Saas_ETM_Area__c = oppty.Opp_PLS_SaaS_ETM_Area__c;
    bkgChildSplit.Opp_PLS_SaaS_ETM_Region__c = oppty.Opp_PLS_SaaS_ETM_Region__c;
    bkgChildSplit.Opp_PLS_SaaS_ETM_Territory__c = oppty.Opp_PLS_SaaS_ETM_Territory__c;
    bkgChildSplit.Opp_PLS_SaaS_ETM_Theatre__c = oppty.Opp_PLS_SaaS_ETM_Theatre__c;
    return bkgChildSplit;
  }

  /**
   * @description Method to return true or false if given numbers has some difference
   * @param previousVal
   * @param currentValue
   * @return Boolean if there is significantDifference
   */
  public Boolean hasSignificantDifference(Decimal previousVal, Decimal currentValue) {
    previousVal = previousVal != null ? previousVal : 0;
    currentValue = currentValue != null ? currentValue : 0;
    Decimal diffVal = (currentValue - previousVal);
    if (diffVal >= 1 || diffVal <= -1) {
      return true;
    }
    return false;
  }
  /**
   * @description Method to call Flow and scheduled the batch after 15 min
   */
  public static void executeSyncBookingBatch() {
    
  try{
    List<CronTrigger> currentRunningApex = [
      SELECT CronJobDetailId, CronJobDetail.Name
      FROM CronTrigger
      WHERE (State = 'WAITING' OR State = 'ACQUIRED' OR State = 'EXECUTING' ) AND CronJobDetail.Name = 'SyncBookingBatchSchedularFromTrigger'
    ];
    if (currentRunningApex == null || currentRunningApex.size() == 0) {
      BookingSyncScheduler sc = new BookingSyncScheduler();
      sc.abortJob = true;
      Datetime dt = Datetime.now().addMinutes(15); // i.e. 15 mins
      String timeForScheduler = dt.format('s m H d M \'?\' yyyy');
      Id schedId = System.Schedule('SyncBookingBatchSchedularFromTrigger', timeForScheduler, sc);
    }
  }catch(Exception ex){
   System.debug(LoggingLevel.DEBUG,'Error occurred: ' + ex.getMessage());
  }
  }
}