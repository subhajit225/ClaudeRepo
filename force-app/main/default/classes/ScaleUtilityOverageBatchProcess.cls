global class ScaleUtilityOverageBatchProcess implements Database.Batchable<sObject> {
  public String jobType = '';
  public Date snapShotDt = null;
  public Set<Id> setOfOrderItemIds;
  public String Query;
  public static List<Error_Logs__c> errorLogs = new List<Error_Logs__c>();
  public static Set<Id> SFFeedToReprocess = new Set<Id>();
  Map<String, StoreSOQLQuery__mdt> soqlQueryMdtByName = new Map<String, StoreSOQLQuery__mdt>();
  
  global ScaleUtilityOverageBatchProcess(String jobType, Date snapShotDt, Set<Id> SFFeedToReprocess, Set<Id> setOfOrderItemIds) {
      this.jobType = jobType;
      this.snapShotDt = snapShotDt;
      this.setOfOrderItemIds = setOfOrderItemIds;
      ScaleUtilityOverageBatchProcess.SFFeedToReprocess = SFFeedToReprocess;
      for (StoreSOQLQuery__mdt soqlQuery : [
          SELECT Id, DeveloperName, Label, Query__c
          FROM StoreSOQLQuery__mdt
          WHERE (DeveloperName = :Constants.SCALE_UTILITY_OVERAGE_BATCH_QUERY OR DeveloperName = :Constants.SCALE_UTILITY_OVERAGE_BATCH_OI_QUERY)
      ]) {
          soqlQueryMdtByName.put(soqlQuery.DeveloperName, soqlQuery); 
      }
      if (
          soqlQueryMdtByName != null &&
          soqlQueryMdtByName.containsKey(Constants.SCALE_UTILITY_OVERAGE_BATCH_OI_QUERY) &&
          String.isNotBlank(soqlQueryMdtByName.get(Constants.SCALE_UTILITY_OVERAGE_BATCH_OI_QUERY).Query__c)
      ) {
          query = (String) soqlQueryMdtByName.get(Constants.SCALE_UTILITY_OVERAGE_BATCH_OI_QUERY).Query__c;
      }
      if (query != null) {
          query = query + ' WHERE Order.Order_Sub_Type__c = \'GC Offer\' AND Order.Is_Order_Active__c = true AND Order.order_status__c = \'Shipped\'';
      }
      if(setOfOrderItemIds != null){
          query = query + ' AND Id IN :setOfOrderItemIds';
      }
      if(query != null){
        query = query + ' ORDER BY Order.OrderNumber';
      }
  }
  
  global Database.QueryLocator start(Database.BatchableContext bc) {
      return Database.getQueryLocator(query);
  }
  
  global void execute(Database.BatchableContext bc, List<OrderItem> gcOfferOrderItems) {
      try {
          Map<Id, calcOverageWrapper> calcWrap = new Map<Id, calcOverageWrapper>();
          Map<Id, List<OrderItem>> orderItemsByOrderId = new Map<Id, List<OrderItem>>();
          Map<Id, Id> orderItemIdToEntId = new Map<Id, Id>();
          Map<Id, OrderItem> licenseIdToOndemandOI = new Map<Id, OrderItem>();
          Map<Id, Id> LicenseOIToOrderId = new Map<Id, Id>();
          Map<Id, Scale_Utility_Overage__c> currentMthOverageRecords = new Map<Id, Scale_Utility_Overage__c>();
          Map<Id, Scale_Utility_Overage_Lines__c> currentMnthOverageLines = new Map<Id, Scale_Utility_Overage_Lines__c>();
          //Boolean isReprocess = !SFFeedToReprocess.isEmpty();
          Set<String> clusterUUIDs = new Set<String>();
          Map<String, List<Scale_Utility_Cluster_Registration__c>> clusterRegsByAcctIdAndClustId = new Map<String, List<Scale_Utility_Cluster_Registration__c>>();
          List<Snowflake_Feed__c> snowflakeFeedsToUpdate = new List<Snowflake_Feed__c>();
          Map<Id, List<Snowflake_Feed__c>> licenseIdToSnowflakeFeeds = new Map<Id, List<Snowflake_Feed__c>>();
          set<Id> originalOrderIds = new Set<Id>();
          Map<Id, OrderItem> orderItemsById = new Map<Id, OrderItem>(gcOfferOrderItems);
          for (OrderItem oi : orderItemsById.values()) {
              if(oi.Product2.Product_Subtype__c == Constants.PROD_SUB_TYPE_SCALE_MSP && oi.Product2.License_Category__c == Constants.PROD_LICENSE_CATEGORY_SAAS && (oi.Support_Start_Date__c == null || oi.Support_End_Date__c == null)){
                  continue;
              }
              if (!orderItemsByOrderId.containsKey(oi.orderId)) {
                  orderItemsByOrderId.put(oi.orderId, new List<OrderItem>());
              }
              orderItemsByOrderId.get(oi.orderId).add(oi);
              
              if (!oi.Entitlements__r.isEmpty() && oi.Entitlements__r.size() > 0) {
                  orderItemIdToEntId.put(oi.id, oi.Entitlements__r[0].id);
              }
              if (
                  oi.Product2.Product_Subtype__c == Constants.PRODUCT_SUBTYPE_ONDEMAND &&
                  oi.Product2.License_Category__c == Constants.LICENSE_CATEGORY
              ) {
                  licenseIdToOndemandOI.put(oi.SBQQ__RequiredBy__c, oi);
              }
              if (
                  oi.Product2.Product_Subtype__c == Constants.PROD_SUB_TYPE_SCALE_MSP &&
                  oi.Product2.License_Category__c == null
              ){
                  LicenseOIToOrderId.put(oi.id, oi.orderId);
              }
          }
          Map<Id, currentMonthLineDetail> currentMonthOrderItemById = getCurrentMonthOrderLine(
              orderItemsByOrderId,
              LicenseOIToOrderId
          );
          //if(!isReprocess){
          currentMthOverageRecords = createInitialSUO(orderItemsById, orderItemsByOrderId, licenseIdToOndemandOI, orderItemIdToEntId, currentMonthOrderItemById);
          currentMnthOverageLines = new Map<Id, Scale_Utility_Overage_Lines__c>([Select id,Scale_Utility_Overage__c from Scale_Utility_Overage_Lines__c where Scale_Utility_Overage__c IN :currentMthOverageRecords.keySet()]);
          //}
          System.debug('testingoutcome1 '+Json.serializePretty(currentMthOverageRecords));
          System.debug('testingoutcome2 '+Json.serializePretty(currentMnthOverageLines));            
          String Query;
          if(soqlQueryMdtByName != null){
              for(String soql: soqlQueryMdtByName.keySet()){
                  if(soql == Constants.SCALE_UTILITY_OVERAGE_BATCH_QUERY && String.isNotBlank(soqlQueryMdtByName.get(Constants.SCALE_UTILITY_OVERAGE_BATCH_QUERY).Query__c)){
                      Query = (String) soqlQueryMdtByName.get(Constants.SCALE_UTILITY_OVERAGE_BATCH_QUERY).Query__c;
                  }
              }
          }
          query = query + ' where CreatedDate = THIS_MONTH';
          List<Snowflake_Feed__c> snowflakeFeeds = (List<Snowflake_Feed__c>) Database.query(query);
          for (Snowflake_Feed__c sfFeed : snowflakeFeeds) {
                if (String.isNotBlank(sfFeed.Cluster_UUID__c)) {
                  clusterUUIDs.add(sfFeed.Cluster_UUID__c);
              }
          }
          for (Scale_Utility_Cluster_Registration__c clusterRegistration : [
              SELECT
              id,
              Account_ID__c,
              Cluster_UUID__c,
              Global_Commit_ID__c,
              License_ID__c,
              License_Order_Product__c,
              License_Order_Product__r.orderid
              FROM Scale_Utility_Cluster_Registration__c
              WHERE Cluster_UUID__c IN :clusterUUIDs
          ]) {
              if (
                    String.isNotBlank(clusterRegistration.Cluster_UUID__c)
              ) {
                    if (!clusterRegsByAcctIdAndClustId?.containskey(clusterRegistration.Cluster_UUID__c)) {
                        clusterRegsByAcctIdAndClustId.put(clusterRegistration.Cluster_UUID__c, new List<Scale_Utility_Cluster_Registration__c>{clusterRegistration});
                  }else{
                        clusterRegsByAcctIdAndClustId.get(clusterRegistration.Cluster_UUID__c).add(clusterRegistration); 
                  }
              }
          }
          for (Snowflake_Feed__c sfFeed : snowflakeFeeds) {     
              String keyAcctIdAndClustId;
              if (String.isBlank(sfFeed.Cluster_UUID__c) && sfFeed.Type__c != 'CNP') {
                  continue;
              }
              if(sfFeed.Type__c != 'CNP'){
                    keyAcctIdAndClustId = sfFeed.Cluster_UUID__c;
              }
              if(sfFeed.Original_Order__c != null){
                  originalOrderIds.add(sfFeed.Original_Order__c);
              }
              if (keyAcctIdAndClustId != null && clusterRegsByAcctIdAndClustId.containskey(keyAcctIdAndClustId)) {
                  sfFeed.Global_Commit_ID__c = clusterRegsByAcctIdAndClustId?.get(keyAcctIdAndClustId)[0]?.Global_Commit_ID__c;
                  if (clusterRegsByAcctIdAndClustId?.get(keyAcctIdAndClustId)[0]?.License_Order_Product__r?.orderid != null) {
                      sfFeed.Original_Order__c = clusterRegsByAcctIdAndClustId?.get(keyAcctIdAndClustId)[0]
                          ?.License_Order_Product__r
                          ?.orderid;
                      originalOrderIds.add(sfFeed.Original_Order__c);
                  }
                  
              }
              if (String.isNotBlank(sfFeed.Global_Commit_ID__c)) {
                  String licenseSFId = sfFeed.Global_Commit_ID__c.substringBetween('-', '-');
                  if(String.isNotBlank(licenseSFId)){
                      if (licenseIdToSnowflakeFeeds.containsKey(licenseSFId)) {
                          licenseIdToSnowflakeFeeds.get(licenseSFId).add(sfFeed); 
                      }else{
                          licenseIdToSnowflakeFeeds.put(licenseSFId, new List<Snowflake_Feed__c>{ sfFeed });
                      } 
                  }
              }
              snowflakeFeedsToUpdate.add(sfFeed);
          }
          if (!snowflakeFeedsToUpdate.isEmpty()) {
              update snowflakeFeedsToUpdate;
          }
          for (Id oi : licenseIdToSnowflakeFeeds.keySet()) {
              if (currentMonthOrderItemById.get(oi) == null) {
                  continue;
              }
              for (Snowflake_Feed__c SFlakeFeed : licenseIdToSnowflakeFeeds.get(oi)) {
                  if (calcWrap.containsKey(oi)) {
                      Decimal SFFeedUsage = (SFlakeFeed.Is_UCL__c
                                             ? SFlakeFeed.Cluster_Usage_FETB__c
                                             : orderItemsByOrderId?.get(LicenseOIToOrderId.get(oi))[0]?.Order.Metering__c == 'BETB'
                                             ? SFlakeFeed.Cluster_Usage_BETB__c
                                             : SFlakeFeed.Cluster_Usage_FETB__c);
                      calcWrap.get(oi).usageQty = calcWrap.get(oi).usageQty + (SFFeedUsage != null ? SFFeedUsage : 0);
                      calcWrap.get(oi).lstOfSnowFlake.add(SFlakeFeed);
                  } else {
                      if(currentMonthOrderItemById?.get(oi) != null){
                          calcWrap.put(
                              oi,
                              new calcOverageWrapper(
                                  SFlakeFeed,
                                  orderItemIdToEntId?.get(oi),
                                  orderItemsByOrderId,
                                  currentMonthOrderItemById?.get(oi),
                                  licenseIdToOndemandOI?.get(oi),
                                  orderItemsById.get(oi)
                              )
                          );
                      } 
                  }
              }
          }
          if (calcWrap != null && !calcWrap.isEmpty()) {
              Map<Id, Scale_Utility_Overage__c> overagerecords = createScaleUtilityOverageRecord(calcWrap, currentMthOverageRecords, currentMnthOverageLines);
          }
      } catch (Exception err) {
          errorLogs.add(
              new Error_Logs__c(
                  Error_Type__c = 'ScaleUtilityOverageBatchProcess',
                  Error_Message__c = err.getMessage() + '\r\n' + err.getStackTraceString(),
                  Type__c = 'SFDC'
              )
          );
      }
      if (!errorLogs.isEmpty()) { 
          Database.insert(errorLogs);
      }
  }
  
  global void finish(Database.BatchableContext bc) {
      handleScaleUtiliyPDFAssociation();
  }
  private Map<Id, Scale_Utility_Overage__c> createScaleUtilityOverageRecord(Map<Id, calcOverageWrapper> calcWrap, Map<Id, Scale_Utility_Overage__c> createdOverageRecords,  Map<Id, Scale_Utility_Overage_Lines__c> currentMnthOverageLines) {
      List<Scale_Utility_Overage__c> suOveragesToUpsert = new List<Scale_Utility_Overage__c>();
      Map<Id, Scale_Utility_Overage__c> insertedOverageRecords;
      Map<String, Scale_Utility_Overage__c> globalCommitToSUO = new Map<String, Scale_Utility_Overage__c>();
      if(createdOverageRecords != null){
          for(Scale_Utility_Overage__c suo : createdOverageRecords.values()){
              globalCommitToSUO.put(suo.Global_Commit_ID__c, suo);
          }  
      }
      for (Id ordItem : calcWrap.keyset()) {
          calcOverageWrapper wrap = calcWrap.get(ordItem);
          Scale_Utility_Overage__c scaleUty = globalCommitToSUO.containskey(wrap.gcid) && globalCommitToSUO.get(wrap.gcid) != null ? globalCommitToSUO.get(wrap.gcid) : new Scale_Utility_Overage__c();
          scaleUty.Account_ID__c = wrap.accId;
          scaleUty.Global_Commit_ID__c = wrap.gcid;
          scaleUty.Process_Flag__c = Constants.PROCESS_FLAG_DO_NOT_PROCESS;
          scaleUty.Original_Order__c = wrap.ordId;
          scaleUty.License_Order_Product__c = ordItem;
          scaleUty.On_Demand_Period_Start_Date__c = wrap.periodStartDate;
          scaleUty.On_Demand_Period_End_Date__c = wrap.snopshotDate;
          scaleUty.Usage_in_TB__c = wrap.usageQty;
          scaleUty.Snapshot_Date__c = wrap.snopshotDate;
          scaleUty.Entitlement_Id__c = wrap.entitlementId;
          scaleUty.Reserve_Order_Line__c = wrap.rservLineItem.id;
          scaleUty.PO_Number__c = wrap.PoNumber;
          scaleUty.Disti_Account_ID__c = wrap.DistributorLookup;
          //scaleUty.Snowflake_Feed_Id__c = wrap.lstOfSnowFlake[0].Id;
          scaleUty.is_First_Item__c = wrap.isFirstItem;
          scaleUty.OnDemand_Order_Product__c = wrap.onDemandLineItem.id;
          //scaleUty.Sync_Status__c = Constants.SYNC_READY;
          suOveragesToUpsert.add(scaleUty);
      }
      if (!suOveragesToUpsert.isEmpty()) {
          upsert suOveragesToUpsert;
          insertedOverageRecords = new Map<Id, Scale_Utility_Overage__c>(suOveragesToUpsert);
          createoveragelines(suOveragesToUpsert, calcWrap, currentMnthOverageLines);
      }
      return insertedOverageRecords;
  }
  
  private void createoveragelines(
      List<Scale_Utility_Overage__c> scaleUtilityLst,
      Map<Id, calcOverageWrapper> calcWrap,
      Map<Id, Scale_Utility_Overage_Lines__c> currentMnthOverageLines
  ) {
      List<Scale_Utility_Overage_Lines__c> lstscOvgLine = new List<Scale_Utility_Overage_Lines__c>();
      Set<Snowflake_Feed__c> setOfSnowFlakeToUpd = new Set<Snowflake_Feed__c>();
      Map<Id, Scale_Utility_Overage_Lines__c> SUOveragetoLine = new Map<Id, Scale_Utility_Overage_Lines__c>();
      for (Scale_Utility_Overage__c sc : scaleUtilityLst) {
          calcOverageWrapper wrap = calcWrap.get(sc.License_Order_Product__c);
          if(wrap.lstOfSnowFlake != null){
              for (Snowflake_Feed__c SFFeed : wrap.lstOfSnowFlake) {
                  SFFeed.Scale_Utility_Overage_ID__c = sc.id;
                  //SFFeed.Sync_Status__c = Constants.SYNC_READY;
                  setOfSnowFlakeToUpd.add(SFFeed);
              }  
          }
          if(currentMnthOverageLines != null){
              for (Scale_Utility_Overage_Lines__c scaleoverageLine : currentMnthOverageLines.values()){
                  SUOveragetoLine.put(scaleoverageLine.Scale_Utility_Overage__c, scaleoverageLine);
              }
          }
          Scale_Utility_Overage_Lines__c scOvgLine = SUOveragetoLine.containsKey(sc.id) && SUOveragetoLine.get(sc.id) != null ? SUOveragetoLine.get(sc.id) : new Scale_Utility_Overage_Lines__c();
          scOvgLine.Scale_Utility_Overage__c = sc.id;
          scOvgLine.Minimum_Reserve_Consumption__c = wrap.allocatedUsg;
          scOvgLine.Max_Contract_Consumption__c = wrap.contractedusg;
          scOvgLine.SKU_Id__c = wrap.onDemandLineItem.Product2Id;
          scOvgLine.Actual_Usage_TB__c = wrap.usageQty;
          scOvgLine.OnDemand_Usage_TB__c = (wrap.usageQty - wrap.allocatedUsg) > 0.0
              ? (wrap.usageQty - wrap.allocatedUsg)
              : 0.0;
          scOvgLine.Unit_Net_Price__c = wrap.unitprice;
          scOvgLine.Net_Price__c = scOvgLine.OnDemand_Usage_TB__c != 0.0
              ? (scOvgLine.OnDemand_Usage_TB__c * wrap.unitprice)
              : 0.0;
          //scOvgLine.Sync_Status__c = Constants.SYNC_READY;
          lstscOvgLine.add(scOvgLine);
      }
      if (!lstscOvgLine.isEmpty()) {
          upsert lstscOvgLine;
      }
      if (!setOfSnowFlakeToUpd.isEmpty()) {
          update new List<Snowflake_Feed__c>(setOfSnowFlakeToUpd);
      }
  }
  
  private Map<Id, currentMonthLineDetail> getCurrentMonthOrderLine(
      Map<Id, List<OrderItem>> orderItemsByOrderId,
      Map<Id, Id> LicenseOIToOrderId
  ) {
      Map<Id, currentMonthLineDetail> currentMonthOrderItemById = new Map<Id, currentMonthLineDetail>();
      Date periodEndDate = Date.newInstance(Constants.CURRENT_YEAR, Constants.CURRENT_MONTH, 25);
      for (Id licenseId : LicenseOIToOrderId.Keyset()) {
          System.debug('erroritem '+licenseId);
          for (OrderItem segmentOrdItem : orderItemsByOrderId.get(LicenseOIToOrderId.get(licenseId))) {
              if (
                  segmentOrdItem.Product2.Product_Subtype__c == Constants.PROD_SUB_TYPE_SCALE_MSP &&
                  segmentOrdItem.Product2.License_Category__c == Constants.PROD_LICENSE_CATEGORY_SAAS &&
                  segmentOrdItem.SBQQ__RequiredBy__c == licenseId &&
                  segmentOrdItem.Support_Start_Date__c <= periodEndDate &&
                  segmentOrdItem.Support_End_Date__c >= periodEndDate
              ) {
                  if (
                      segmentOrdItem.SBQQ__SegmentIndex__c == 1 || segmentOrdItem.SBQQ__SegmentIndex__c == segmentOrdItem.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c
                  ) {
                      Decimal proRatedPrice = 0.0;
                      Integer dayForProRataCalc = segmentOrdItem.Support_Start_Date__c.daysBetween(periodEndDate) + 1;
                      proRatedPrice = dayForProRataCalc * 12 * (segmentOrdItem.Sales_Price__c / 365);
                      currentMonthOrderItemById.put(licenseId, new currentMonthLineDetail(segmentOrdItem.Quantity, segmentOrdItem, true, proRatedPrice.setScale(2)));
                  }
                  else{
                      currentMonthOrderItemById.put(
                          licenseId,
                          new currentMonthLineDetail(segmentOrdItem.Quantity, segmentOrdItem, false, segmentOrdItem.Sales_Price__c)
                      );
                  }
              }
          } 
      }
      return currentMonthOrderItemById;
  }
  private Map<Id,Scale_Utility_Overage__c> createInitialSUO(Map<Id, OrderItem> orderItemsById, Map<Id, List<OrderItem>> orderItemsByOrderId, Map<Id, OrderItem> licenseIdToOndemandOI, Map<Id, Id> orderItemIdToEntId, Map<Id, currentMonthLineDetail> currentMonthOrderItemById){
      Map<Id, calcOverageWrapper> calcWrap = new Map<Id, calcOverageWrapper>();
      for(Id oi : licenseIdToOndemandOI.Keyset()){
          System.debug('erroroi '+oi);
          if(currentMonthOrderItemById.get(oi) != null){
              calcWrap.put(
                  oi,
                  new calcOverageWrapper(
                      null,
                      orderItemIdToEntId?.get(oi),
                      orderItemsByOrderId,
                      currentMonthOrderItemById?.get(oi),
                      licenseIdToOndemandOI?.get(oi),
                      orderItemsById?.get(oi)
                  )
              ); 
          }   
      }
      return createScaleUtilityOverageRecord(calcWrap, null, null);
      
  }
  private class calcOverageWrapper {
      Id ordId;
      Decimal usageQty;
      String gcid;
      String PoNumber;
      Id DistributorLookup;
      Date snopshotDate;
      Decimal allocatedUsg;
      Decimal contractedusg;
      Date periodStartDate;
      Id accId;
      Decimal unitprice;
      List<Snowflake_Feed__c> lstOfSnowFlake;
      Id entitlementId;
      OrderItem rservLineItem;
      Boolean isFirstItem;
      orderItem onDemandLineItem;
      
      private calcOverageWrapper(
          Snowflake_Feed__c snowflakeFeed,
          Id entitlementId,
          Map<Id, List<OrderItem>> orderItemsByOrderId,
          currentMonthLineDetail currentMnthDetailWrap,
          OrderItem onDemandLineItem,
          OrderItem licenseOrderLineItem
      ) {
          Decimal SFFeedUsage;
          Date LastMonth = snowflakeFeed != null ? snowflakeFeed.Snapshot_Date__c.addmonths(-1) : Date.newInstance(Constants.CURRENT_YEAR, Constants.CURRENT_MONTH, 26).addmonths(-1);
          Date LastMonthPeriodStDate = Date.newInstance(Lastmonth.year(), lastmonth.month(), 26);
          ordId = licenseOrderLineItem.orderId;
          if(snowflakeFeed != null){
              SFFeedUsage = snowflakeFeed.Is_UCL__c
                  ? snowflakeFeed.Cluster_Usage_FETB__c
                  : orderItemsByOrderId?.get(snowflakeFeed.Original_Order__c)[0]?.Order.Metering__c == 'BETB'
                      ? snowflakeFeed.Cluster_Usage_BETB__c
                      : snowflakeFeed.Cluster_Usage_FETB__c;
          }
          usageQty = SFFeedUsage != null ? SFFeedUsage : 0;
          gcid = licenseOrderLineItem.Global_Commit_ID__c;
          snopshotDate = snowflakeFeed != null ? snowflakeFeed.Snapshot_Date__c : Date.newInstance(Constants.CURRENT_YEAR, Constants.CURRENT_MONTH, 25);
          this.allocatedUsg = currentMnthDetailWrap.allocatedusage;
          accId = licenseOrderLineItem.Order.AccountId;
          this.periodStartDate = currentMnthDetailWrap.isFirstItem ? licenseOrderLineItem.Support_Start_Date__c : LastMonthPeriodStDate;
          this.contractedusg = licenseOrderLineItem.quantity;
          this.unitprice = currentMnthDetailWrap.unitPrice;
          this.PoNumber = licenseOrderLineItem.Order.PoNumber;
          this.DistributorLookup = licenseOrderLineItem.Order.Opportunity.Distributor_Lookup__c;
          if(snowflakeFeed != null){
              this.lstOfSnowFlake = new List<Snowflake_Feed__c>{ snowflakeFeed };
                  }
          this.entitlementId = entitlementId;
          this.rservLineItem = currentMnthDetailWrap.rservLineItem;
          this.isFirstItem = currentMnthDetailWrap.isFirstItem;
          this.onDemandLineItem = onDemandLineItem;
      }
  }
  private class currentMonthLineDetail {
      Decimal allocatedusage;
      OrderItem rservLineItem;
      Boolean isFirstItem;
      Decimal unitPrice;
      private currentMonthLineDetail(
          Decimal allocatedusage,
          OrderItem rservLineItem,
          Boolean isFirstItem,
          Decimal unitPrice
      ) {
          this.allocatedusage = allocatedusage;
          this.rservLineItem = rservLineItem;
          this.isFirstItem = isFirstItem;
          this.unitPrice = unitPrice;
      }
  }
  private static void handleScaleUtiliyPDFAssociation() {
      Date currentSnapshotDate = Date.newInstance(Constants.CURRENT_YEAR, Constants.CURRENT_MONTH, 25);
      Map<String, Scale_Utility_Overage__c> newSUOverageByStaleSUOverage = new Map<String, Scale_Utility_Overage__c>();
      Map<Id, String> staleSUOGlobalCommitIdById = new Map<Id, String>();
      Map<String, Id> staleScaleUtilityOverages = new Map<String, Id>();
      List<Attachment> newAttachmentToCreate = new List<Attachment>();
      List<ContentDocumentLink> newContentDocumentLinksToCreate = new List<ContentDocumentLink>();
      try {
          List<Scale_Utility_Overage__c> currentMonthScaleUtilityOverages = [
              SELECT Id, License_Order_Product__c, Global_Commit_ID__c, Process_Flag__c
              FROM Scale_Utility_Overage__c
              WHERE Snapshot_Date__c = :currentSnapshotDate
              ORDER BY createddate DESC
          ];
          for (Scale_Utility_Overage__c suOverage : currentMonthScaleUtilityOverages) {
              if (suOverage.Process_Flag__c == Constants.PROCESS_FLAG_STALE) {                
                  if (!staleScaleUtilityOverages.containskey(suOverage.Global_Commit_ID__c)) {
                      staleScaleUtilityOverages.put(suOverage.Global_Commit_ID__c, suOverage.id);
                  }
                  staleSUOGlobalCommitIdById.put(suOverage.Id, suOverage.Global_Commit_ID__c);
              }
              if (suOverage.Process_Flag__c == Constants.PROCESS_FLAG_DO_NOT_PROCESS) {
                  newSUOverageByStaleSUOverage.put((suOverage.Global_Commit_ID__c), suOverage);
              }
          }
          Set<Id> staleSUOverageUniqueIds;
          if (!staleScaleUtilityOverages.values().isempty()) {
              staleSUOverageUniqueIds = new Set<Id>(staleScaleUtilityOverages.values());
          }
          if (staleSUOverageUniqueIds != null) {
              for (Attachment attachmentOnStaleSU : [SELECT Id, Body, Name, ParentId FROM Attachment WHERE ParentId IN :staleSUOverageUniqueIds]) {
                  String globalCommitIdFromAttachment = staleSUOGlobalCommitIdById.get(attachmentOnStaleSU.ParentId);
                  if (newSUOverageByStaleSUOverage.containskey(globalCommitIdFromAttachment) && newSUOverageByStaleSUOverage.get(globalCommitIdFromAttachment)?.Id != null) {
                      Attachment newAttachment = attachmentOnStaleSU.clone();
                      newAttachment.ParentId = newSUOverageByStaleSUOverage.get(globalCommitIdFromAttachment).Id;
                      newAttachmentToCreate.add(newAttachment); 
                  } 
              }
              
              for (ContentDocumentLink contDocumentLinkOnStaleSU : [
                  SELECT ContentDocument.title, ContentDocument.ownerId, Id, ContentDocument.FileExtension, ContentDocumentId, ShareType, LinkedEntityId
                  FROM ContentDocumentLink
                  WHERE LinkedEntityId IN :staleSUOverageUniqueIds
              ]) {
                  String globalCommitIdFromAttachment = staleSUOGlobalCommitIdById.get(contDocumentLinkOnStaleSU.LinkedEntityId);
                  if (newSUOverageByStaleSUOverage.containskey(globalCommitIdFromAttachment) && newSUOverageByStaleSUOverage.get(globalCommitIdFromAttachment)?.Id != null) {
                      ContentDocumentLink newContentDocumentLink = contDocumentLinkOnStaleSU.clone();
                      newContentDocumentLink.LinkedEntityId = newSUOverageByStaleSUOverage.get(globalCommitIdFromAttachment).Id;
                      newContentDocumentLinksToCreate.add(newContentDocumentLink);
                  }
              }
              
          }
          if (!newAttachmentToCreate.isEmpty()) {
              insert newAttachmentToCreate;
          }
          
          if (!newContentDocumentLinksToCreate.isEmpty()) {
              insert newContentDocumentLinksToCreate;
          }
      } catch (Exception e) {
          UtilityClass.logException(e, 'SclaeUtilityOverageBatchProcess', 'handleScaleUtilityPDFAssociation', 'Scale_Utility_Overage__c + Attachment');
      }
  }
}