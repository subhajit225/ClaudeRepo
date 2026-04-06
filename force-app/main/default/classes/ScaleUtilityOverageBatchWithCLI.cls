/***********************************************************************************
  * @description       : This is the batch class which is used to generate the SU Overage header and SU overage lines on monthly basis for both
  * 					 Initial and amendment Orders, this batch automatically get triggers from mulesoft on every month 26th.
  * Project            : Scale Utility
  * JIRA(s)            : CSU-486
  * @author            : NaveenkumarSelvaraj
  * @last modified on  : 05-12-2023
  * @last modified by  : NaveenkumarSelvaraj
  *******************************************************************************/
  global class ScaleUtilityOverageBatchWithCLI implements Database.Batchable<sObject> {
    public String jobType = '';
    public Date snapShotDt = null;
    public String Query;
    public static List<Error_Logs__c> errorLogs = new List<Error_Logs__c>();    
    public Set<Id> serviceContractIds = new Set<Id>();
    Map<String, StoreSOQLQuery__mdt> soqlQueryMdtByName = new Map<String, StoreSOQLQuery__mdt>();
    
    /***********************************************************************************
  * @description       : Constructor method which used to initialize jobType, snapShotDt, serviceContractIds.  Also this method help to form the initial query. 
  * Project            : Scale Utility
  * JIRA(s)            : CSU-486
  * @author            : NaveenkumarSelvaraj
  * @last modified on  : 05-12-2023
  * @last modified by  : NaveenkumarSelvaraj
  * arguments          : jobType --> Initial processing or reprocessing, snapshotDt --> month of generation, 
  * 					 serviceContractIds --> generate SU for particular Servicecontracts
  * return             : void
  * Modifications Log
  * 
  *******************************************************************************/ 
    global ScaleUtilityOverageBatchWithCLI(String jobType, Date snapShotDt, Set<Id> serviceContractIds) {  
        this.jobType = jobType;
        this.snapShotDt = snapShotDt;
		this.serviceContractIds = serviceContractIds;
        for (StoreSOQLQuery__mdt soqlQuery : [
            SELECT Id, DeveloperName, Label, Query__c
            FROM StoreSOQLQuery__mdt
            WHERE (DeveloperName = :Constants.SCALE_UTILITY_OVERAGE_SC_QUERY OR DeveloperName = :Constants.SCALE_UTILITY_OVERAGE_BATCH_QUERY)
        ]) {
            soqlQueryMdtByName.put(soqlQuery.DeveloperName, soqlQuery); 
        }
        if (
            soqlQueryMdtByName != null &&
            soqlQueryMdtByName.containsKey(Constants.SCALE_UTILITY_OVERAGE_SC_QUERY) &&
            String.isNotBlank(soqlQueryMdtByName.get(Constants.SCALE_UTILITY_OVERAGE_SC_QUERY).Query__c)
        ) {
            query = (String) soqlQueryMdtByName.get(Constants.SCALE_UTILITY_OVERAGE_SC_QUERY).Query__c;
        }
        if (query != null) {
            query = query + ' WHERE SBQQSC__Order__r.Order_Sub_Type__c = \'GC Offer\' AND SBQQSC__Order__r.Is_Order_Active__c = true AND SBQQSC__Order__r.order_status__c = \'Shipped\'';
            if(serviceContractIds != null){
               query = query + ' AND Id IN :serviceContractIds';
            }
        }
        if(query != null){
            query = query + ' ORDER BY CreatedDate DESC';
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<ServiceContract> gcServiceContracts) {
        try{
            Map<Id, List<ContractLineItem>> SCToListOfCli = new Map<Id, List<ContractLineItem>>();
            Date periodEndDate = Date.newInstance(Constants.CURRENT_YEAR, Constants.CURRENT_MONTH, 25);
            Map<String, currentMonthLineDetail> currentMonthCLIById = new Map<String, currentMonthLineDetail>();
            Map<Id, Scale_Utility_Overage__c> currentMthOverageRecords = new Map<Id, Scale_Utility_Overage__c>();
            Map<Id, Scale_Utility_Overage_Lines__c> currentMnthOverageLines = new Map<Id, Scale_Utility_Overage_Lines__c>();
            Map<String, ContractLineItem> gcIdToOndemandCLI = new Map<String, ContractLineItem>();
            Set<String> clusterUUIDs = new Set<String>();
            Map<String, List<Scale_Utility_Cluster_Registration__c>> clusterRegsByAcctIdAndClustId = new Map<String, List<Scale_Utility_Cluster_Registration__c>>();
            set<Id> originalOrderIds = new Set<Id>();
            Map<String, List<Snowflake_Feed__c>> gcIdToSnowflakeFeeds = new Map<String, List<Snowflake_Feed__c>>();
            List<Snowflake_Feed__c> snowflakeFeedsToUpdate = new List<Snowflake_Feed__c>();
            Map<String, calcOverageWrapper> calcWrap = new Map<String, calcOverageWrapper>();
            Map<String, ContractLineItem> gcIdToLicenseCLI = new Map<String, ContractLineItem>();
            
            for(ServiceContract sc: gcServiceContracts){
                SCToListOfCli.put(sc.id, sc.ContractLineItems);
                for(ContractLineItem cli: sc.ContractLineItems){
                    if(cli.SBQQSC__Product__r.Product_Subtype__c == Constants.PROD_SUB_TYPE_SCALE_MSP && cli.SBQQSC__Product__r.License_Category__c == Constants.PROD_LICENSE_CATEGORY_SAAS && (cli.StartDate == null || cli.EndDate == null)){
                        continue;
                    }
                    if (
                        cli.SBQQSC__Product__r.Product_Subtype__c == Constants.PROD_SUB_TYPE_SCALE_MSP &&
                        cli.SBQQSC__Product__r.License_Category__c == Constants.PROD_LICENSE_CATEGORY_SAAS &&
                        cli.StartDate <= periodEndDate &&
                        cli.EndDate >= periodEndDate && cli.Global_Commit_ID__c != null
                    ) {
                        
                        if(cli.SBQQSC__RevisedSubscription__c == null){
							if (cli.SBQQSC__SegmentIndex__c == 1 || cli.SBQQSC__SegmentIndex__c == cli.SBQQSC__QuoteLine__r.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c) {
							  Integer dayForProRataCalc = cli.StartDate.daysBetween(periodEndDate) + 1;
                                if(currentMonthCLIById.containskey(cli.Global_Commit_ID__c)){
                                    currentMonthLineDetail tempCurMntDetail = getUpdatedCurrentMnthLineDetail(currentMonthCLIById.get(cli.Global_Commit_ID__c), cli, true, cli.unitPrice, dayForProRataCalc);
                                    currentMonthCLIById.put(cli.Global_Commit_ID__c, tempCurMntDetail);
                                }
                                else{
							  currentMonthCLIById.put(cli.Global_Commit_ID__c, new currentMonthLineDetail(cli.Quantity, cli, true, cli.UnitPrice, dayForProRataCalc));
                                }
							} else {
                                if(currentMonthCLIById.containskey(cli.Global_Commit_ID__c)){
                                    currentMonthLineDetail tempCurMntDetail = getUpdatedCurrentMnthLineDetail(currentMonthCLIById.get(cli.Global_Commit_ID__c), cli, false, cli.unitPrice, null);
                                    currentMonthCLIById.put(cli.Global_Commit_ID__c, tempCurMntDetail);
                                }
                                else{
							  currentMonthCLIById.put(cli.Global_Commit_ID__c, new currentMonthLineDetail(cli.Quantity, cli, false, cli.UnitPrice, null));
							}
						}     
						}
                        if(cli.SBQQSC__RevisedSubscription__c != null){
                            if(currentMonthCLIById.containskey(cli.Global_Commit_ID__c)){
                            currentMonthLineDetail tempCurMntDetail = currentMonthCLIById.get(cli.Global_Commit_ID__c);
                            tempCurMntDetail.allocatedusage = tempCurMntDetail.allocatedusage + cli.Quantity;
                                currentMonthCLIById.put(cli.Global_Commit_ID__c, tempCurMntDetail);
                            }
                            else{
                                currentMonthCLIById.put(cli.Global_Commit_ID__c, new currentMonthLineDetail(cli.Quantity, null, null, null, null));
                            }
                        }
                    }
                    Boolean isExistingOND = cli?.SBQQSC__Product__r?.Product_Subtype__c == Constants.PRODUCT_SUBTYPE_ONDEMAND && cli?.SBQQSC__Product__r?.License_Category__c == Constants.LICENSE_CATEGORY;
                    Boolean isOndSR = cli?.SBQQSC__QuoteLine__r?.Scale_Utility_Product_Identifier__c =='OND SR';
                    Boolean isOndAR = cli?.SBQQSC__QuoteLine__r?.Scale_Utility_Product_Identifier__c =='OND AR';
                    if(cli.SBQQSC__TerminatedDate__c != null && cli.SBQQSC__TerminatedDate__c > system.today() && cli.Global_Commit_ID__c != null){
                        if (isExistingOND) {
                            gcIdToOndemandCLI.put(cli.Global_Commit_ID__c+'-'+'Existing-OND', cli);
                        }
                        if(isOndSR) {
                            gcIdToOndemandCLI.put(cli.Global_Commit_ID__c+'-'+'OND-SR', cli);
                        }
                        if(isOndAR) {
                            gcIdToOndemandCLI.put(cli.Global_Commit_ID__c+'-'+'OND-AR', cli);
                        }
                    } else if (cli.SBQQSC__TerminatedDate__c ==  null && cli.Global_Commit_ID__c != null && cli.startDate <= System.today()) {
                        if(isExistingOND && !gcIdToOndemandCLI.containskey(cli.Global_Commit_ID__c+'-'+'Existing-OND')){
                            gcIdToOndemandCLI.put(cli.Global_Commit_ID__c+'-'+'Existing-OND', cli);
                        }
                        if(isOndSR && !gcIdToOndemandCLI.containskey(cli.Global_Commit_ID__c+'-'+'OND-SR')){
                            gcIdToOndemandCLI.put(cli.Global_Commit_ID__c+'-'+'OND-SR', cli);
                        }
                        if(isOndAR && !gcIdToOndemandCLI.containskey(cli.Global_Commit_ID__c+'-'+'OND-AR')){
                            gcIdToOndemandCLI.put(cli.Global_Commit_ID__c+'-'+'OND-AR', cli);
                        }
                    }
                    if(cli.SBQQSC__Product__r.Product_Subtype__c == Constants.PROD_SUB_TYPE_SCALE_MSP && cli.SBQQSC__Product__r.License_Category__c == null && cli.Global_Commit_ID__c != null){
                        gcIdToLicenseCLI.put(cli.Global_Commit_ID__c, cli);
                    } 
                    
                }
            }
            
            if(!currentMonthCLIById.values().isEmpty() && !SCToListOfCli.values().isEmpty() && !gcIdToOndemandCLI.values().isEmpty() && !gcIdToLicenseCLI.values().isEmpty()){
                if(jobType == 'ProcessManualSnowFlake'){
                    currentMthOverageRecords.putAll([select id,Global_Commit_ID__c,Service_Contract__c from Scale_Utility_Overage__c where Service_Contract__c IN :serviceContractIds]);
                }else{
                    currentMthOverageRecords = createInitialSUO(SCToListOfCli, gcIdToOndemandCLI, currentMonthCLIById, gcIdToLicenseCLI);
                }
                currentMnthOverageLines = new Map<Id, Scale_Utility_Overage_Lines__c>([Select id,Type__c,Scale_Utility_Overage__c from Scale_Utility_Overage_Lines__c where Scale_Utility_Overage__c IN :currentMthOverageRecords.keySet()]);
            }
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
                License_Order_Product__r.orderid,
                Service_Contract_ID__c
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
                    sfFeed.Service_Contract__c = clusterRegsByAcctIdAndClustId?.get(keyAcctIdAndClustId)[0]?.Service_Contract_ID__c;
                    if (clusterRegsByAcctIdAndClustId?.get(keyAcctIdAndClustId)[0]?.License_Order_Product__r?.orderid != null) {
                        sfFeed.Original_Order__c = clusterRegsByAcctIdAndClustId?.get(keyAcctIdAndClustId)[0]
                            ?.License_Order_Product__r
                            ?.orderid;
                        originalOrderIds.add(sfFeed.Original_Order__c);
                    }
                    
                }
                if (String.isNotBlank(sfFeed.Global_Commit_ID__c)) {
                    if (!gcIdToSnowflakeFeeds.containsKey(sfFeed.Global_Commit_ID__c)) {
                        gcIdToSnowflakeFeeds.put(sfFeed.Global_Commit_ID__c, new List<Snowflake_Feed__c>()); 
                    }
                    gcIdToSnowflakeFeeds?.get(sfFeed.Global_Commit_ID__c).add(sfFeed);
                }
                snowflakeFeedsToUpdate.add(sfFeed);
            }
            if(!snowflakeFeedsToUpdate.isEmpty()){
                update snowflakeFeedsToUpdate;
            }
            for (String gcId : gcIdToSnowflakeFeeds.keySet()) {
                if (currentMonthCLIById.get(gcId) == null) {
                    continue;
                }
                for (Snowflake_Feed__c SFlakeFeed : gcIdToSnowflakeFeeds.get(gcId)) {
                    if (calcWrap.containsKey(gcId)) {
                        Decimal SFFeedUsage = (SFlakeFeed.Is_UCL__c
                                               ? SFlakeFeed.Cluster_Usage_FETB__c
                                               : SCToListOfCli?.get(SFlakeFeed.Service_Contract__c)[0]?.SBQQSC__OrderProduct__r.Order.Metering__c == 'BETB'
                                               ? SFlakeFeed.Cluster_Usage_BETB__c
                                               : SFlakeFeed.Cluster_Usage_FETB__c);
                        calcWrap.get(gcId).usageQty = calcWrap.get(gcId).usageQty + (SFFeedUsage != null ? SFFeedUsage : 0);
                        calcWrap.get(gcId).lstOfSnowFlake.add(SFlakeFeed);
                    } else {
                        if(currentMonthCLIById?.get(gcId) != null){
                            calcWrap.put(
                                gcId,
                                new calcOverageWrapper(
                                    SFlakeFeed,
                                    SCToListOfCli,
                                    currentMonthCLIById?.get(gcId),
                                    gcIdToOndemandCLI?.get(gcId+'-'+'Existing-OND'),
                                    gcIdToOndemandCLI?.get(gcId+'-'+'OND-SR'),
                                    gcIdToOndemandCLI?.get(gcId+'-'+'OND-AR'),
                                    gcIdToLicenseCLI?.get(gcId) 
                                )
                            );
                        } 
                    }
                }
            }
            if (calcWrap != null && !calcWrap.isEmpty()) {
                Map<Id, Scale_Utility_Overage__c> overagerecords = createScaleUtilityOverageRecord(calcWrap, currentMthOverageRecords, currentMnthOverageLines);
            }
        }
        Catch(Exception e){
            UtilityClass.logException(e, 'ScaleUtilityOverageBatchWithCLI', 'excute', 'Scale_Utility_Overage__c');
        }
        
    }
    
    global void finish(Database.BatchableContext bc) {
        try{
            handleScaleUtiliyPDFAssociation();  
            //PRDOPS25-320: This flow will send out an email regarding all the newly created Scale Utility Overage Records 
            Map<String, Object> flowInputs = new Map<String, Object>(); 
            Flow.Interview.Schedule_Triggered_Scale_Utility_Overage_Records_Creation_Email f = new Flow.Interview.Schedule_Triggered_Scale_Utility_Overage_Records_Creation_Email(flowInputs);
            f.start();
        }
        Catch(Exception e){
            UtilityClass.logException(e, 'ScaleUtilityOverageBatchWithCLI ', 'Finish', 'Scale_Utility_Overage__c');
        }
    }
    /***********************************************************************************
  * @description       : getUpdatedCurrentMnthLineDetail method to update the currentMonthLineDetail wrapper  
  * Project            : Scale Utility
  * JIRA(s)            : PRDOPS25-1284
  * @author            : NaveenkumarSelvaraj
  * @last modified on  : 05-12-2024
  * @last modified by  : NaveenkumarSelvaraj
  * arguments          : currentMonthLineDetail -- > wrapper info,rservLineItem ---> current month reserv line, isFirstItem --> to identify its true or false, unitPrice --> unitprice of current month resrv
  * 					 line, onDemandPeriodInDays --> prorated days incase of first or last month  
  * return             : currentMonthLineDetail --> updated wrapper info.
  * Modifications Log
  * 
  *******************************************************************************/
    
    Public static currentMonthLineDetail getUpdatedCurrentMnthLineDetail(currentMonthLineDetail tempCurMntDetail, contractlineitem rservLineItem, Boolean isFirstItem, Decimal unitPrice, Integer onDemandPeriodInDays){
          currentMonthLineDetail CurMntDetail = tempCurMntDetail;
          CurMntDetail.allocatedusage = CurMntDetail.allocatedusage + rservLineItem.Quantity;
          CurMntDetail.rservLineItem = rservLineItem;
          CurMntDetail.isFirstItem = isFirstItem;
          CurMntDetail.unitPrice =  rservLineItem.UnitPrice;
          CurMntDetail.onDemandPeriodInDays = onDemandPeriodInDays;
          return CurMntDetail;
      }
    
    /***********************************************************************************
  * @description       : createInitialSUO method which used to route through the Overage header upsert. 
  * Project            : Scale Utility
  * JIRA(s)            : CSU-486
  * @author            : NaveenkumarSelvaraj
  * @last modified on  : 05-12-2023
  * @last modified by  : NaveenkumarSelvaraj
  * arguments          : cliToSCIds --> ScID with Realted clis, gcIdToOndemandCLI --> ondemandcli info against gcId, currentMonthCLIById --> Current SegmentLine Detail, 
  * 					 gcIdToLicenseCLI --> License Cli against gcId
  * return             : Map<Id,Scale_Utility_Overage__c>
  * Modifications Log
  * 
  *******************************************************************************/
    private Map<Id,Scale_Utility_Overage__c> createInitialSUO(Map<Id, List<ContractlineItem>> cliToSCIds, Map<String, ContractlineItem> gcIdToOndemandCLI,Map<String, currentMonthLineDetail> currentMonthCLIById,Map<String, ContractlineItem> gcIdToLicenseCLI){
        Map<String, calcOverageWrapper> calcWrap = new Map<String, calcOverageWrapper>();
        for(String gcId : gcIdToLicenseCLI.Keyset()){
            System.debug('erroroi '+gcId);
            if(currentMonthCLIById.get(gcId) != null){
                calcWrap.put(
                    gcId,
                    new calcOverageWrapper(
                        null,
                        cliToSCIds,
                        currentMonthCLIById?.get(gcId),
                        gcIdToOndemandCLI?.get(gcId+'-'+'Existing-OND'),
                        gcIdToOndemandCLI?.get(gcId+'-'+'OND-SR'),
                        gcIdToOndemandCLI?.get(gcId+'-'+'OND-AR'),
                        gcIdToLicenseCLI?.get(gcId) 
                    )
                ); 
            }   
        }
        return createScaleUtilityOverageRecord(calcWrap, null, null);
        
    }
    /***********************************************************************************
  * @description       : createScaleUtilityOverageRecord method which used to upsert Overage header record with all the necessary info. 
  * Project            : Scale Utility
  * JIRA(s)            : CSU-486
  * @author            : NaveenkumarSelvaraj
  * @last modified on  : 05-12-2023
  * @last modified by  : NaveenkumarSelvaraj
  * arguments          : calcWrap --> wrapper with all the header info against gcId , createdOverageRecords --> existing overageHeaders created for current month, 
  * 					 currentMnthOverageLines --> existing overageLines created for current month
  * return             : Map<Id,Scale_Utility_Overage__c>
  * Modifications Log
  * 
  *******************************************************************************/
    private Map<Id, Scale_Utility_Overage__c> createScaleUtilityOverageRecord(Map<String, calcOverageWrapper> calcWrap, Map<Id, Scale_Utility_Overage__c> createdOverageRecords,  Map<Id, Scale_Utility_Overage_Lines__c> currentMnthOverageLines) {
        List<Scale_Utility_Overage__c> suOveragesToUpsert = new List<Scale_Utility_Overage__c>();
        Map<Id, Scale_Utility_Overage__c> insertedOverageRecords;
        Map<String, Scale_Utility_Overage__c> globalCommitToSUO = new Map<String, Scale_Utility_Overage__c>();
        if(createdOverageRecords != null){
            for(Scale_Utility_Overage__c suo : createdOverageRecords.values()){
                globalCommitToSUO.put(suo.Global_Commit_ID__c, suo);
            }  
        }
        for (String gcId : calcWrap.keyset()) {
            calcOverageWrapper wrap = calcWrap.get(gcId);
            Scale_Utility_Overage__c scaleUty = globalCommitToSUO.containskey(wrap.gcid) && globalCommitToSUO.get(wrap.gcid) != null ? globalCommitToSUO.get(wrap.gcid) : new Scale_Utility_Overage__c();
            scaleUty.Account_ID__c = wrap.licenseCLI.SBQQSC__Account__c;
            scaleUty.Global_Commit_ID__c = wrap.gcid;
            scaleUty.Process_Flag__c = Constants.PROCESS_FLAG_DO_NOT_PROCESS;
            scaleUty.Original_Order__c = wrap.ordId;
            scaleUty.Current_Month_Commited_Usage__c = wrap.allocatedUsg;
            scaleUty.Max_Commited_Usage__c = wrap.maxcommit;
            scaleUty.License_Order_Product__c = wrap.licenseCLI.SBQQSC__OrderProduct__c;
            scaleUty.On_Demand_Period_Start_Date__c = wrap.periodStartDate;
            scaleUty.On_Demand_Period_End_Date__c = wrap.snopshotDate;
            scaleUty.Usage_in_TB__c = wrap.usageQty;
            scaleUty.Snapshot_Date__c = wrap.snopshotDate;
            scaleUty.Reserve_Order_Line__c = wrap.rservLineItem.SBQQSC__OrderProduct__c;
            scaleUty.PO_Number__c = wrap.licenseCLI.SBQQSC__OrderProduct__r.Order.PoNumber;
            scaleUty.Service_Contract__c = wrap.licenseCLI.ServiceContractId;
            scaleUty.Disti_Account_ID__c = wrap.licensecli.SBQQSC__OrderProduct__r.Order.Opportunity.Distributor_Lookup__c;
            scaleUty.is_First_Item__c = wrap.isFirstItem;
            scaleUty.OnDemand_AR_CLI_ID__c = wrap.onDemandARCLI != null ? wrap.onDemandARCLI.id : null;
            scaleUty.OnDemand_SR_CLI_ID__c = wrap.onDemandSRCLI != null ? wrap.onDemandSRCLI.id : null;
            scaleUty.Ondemand_CLI__c = wrap.existingonDemandCLI != null ? wrap.existingonDemandCLI.Id : null;
            suOveragesToUpsert.add(scaleUty);
        }
        if (!suOveragesToUpsert.isEmpty()) {
            upsert suOveragesToUpsert;
            insertedOverageRecords = new Map<Id, Scale_Utility_Overage__c>(suOveragesToUpsert);
            createoveragelines(suOveragesToUpsert, calcWrap, currentMnthOverageLines);
        }
        return insertedOverageRecords;
    }
    /***********************************************************************************
  * @description       : createoveragelines method which used to upsert Overage lines record with all the necessary info. 
  * Project            : Scale Utility
  * JIRA(s)            : CSU-486
  * @author            : NaveenkumarSelvaraj
  * @last modified on  : 05-12-2023
  * @last modified by  : NaveenkumarSelvaraj
  * arguments          : scaleUtilityLst --> overage header records , calcWrap --> wrapper with all the header info against gcId, 
  * 					 currentMnthOverageLines --> existing overageLines created for current month
  * return             : void
  * Modifications Log
  * 
  *******************************************************************************/
    private void createoveragelines(
        List<Scale_Utility_Overage__c> scaleUtilityLst,
        Map<String, calcOverageWrapper> calcWrap,
        Map<Id, Scale_Utility_Overage_Lines__c> currentMnthOverageLines
    ) {
        List<Scale_Utility_Overage_Lines__c> lstOfOvgLines = new List<Scale_Utility_Overage_Lines__c>();
        Set<Snowflake_Feed__c> setOfSnowFlakeToUpd = new Set<Snowflake_Feed__c>();
        Map<String, Scale_Utility_Overage_Lines__c> SUOveragetoLine = new Map<String, Scale_Utility_Overage_Lines__c>();
        for (Scale_Utility_Overage__c sc : scaleUtilityLst) {
            
            calcOverageWrapper wrap = calcWrap.get(sc.Global_Commit_ID__c);
            if(wrap.lstOfSnowFlake != null){
                for (Snowflake_Feed__c SFFeed : wrap.lstOfSnowFlake) {
                    SFFeed.Scale_Utility_Overage_ID__c = sc.id;
                    setOfSnowFlakeToUpd.add(SFFeed);
                }  
            }
            if(currentMnthOverageLines != null){
                for (Scale_Utility_Overage_Lines__c scaleoverageLine : currentMnthOverageLines.values()){
                    SUOveragetoLine.put(scaleoverageLine.Scale_Utility_Overage__c+'-'+scaleoverageLine.Type__c, scaleoverageLine);
                }
            }
            if(wrap.licensecli != null  && wrap.maxcommit != null){
                if(wrap.allocatedUsg != wrap.maxcommit){
                    if((wrap.usageQty - wrap.maxcommit) > 0){
                        if(wrap.onDemandARCLI != null){
                            Scale_Utility_Overage_Lines__c extOvgLine = SUOveragetoLine.containskey(sc.id+'-'+'Above Reserved') && SUOveragetoLine.get(sc.id+'-'+'Above Reserved') != null ?  SUOveragetoLine.get(sc.id+'-'+'Above Reserved') : new Scale_Utility_Overage_Lines__c();
                            lstOfOvgLines.add(prepareOvgLines('Above Reserved', wrap, sc, wrap.usageQty - wrap.maxcommit, SUOveragetoLine.get(sc.id+'-'+'Above Reserved'))); 
                            
                        }
                        if(wrap.onDemandSRCLI != null){
                            Decimal tempOnDemandQty = (wrap.usageQty - wrap.allocatedUsg) - (wrap.usageQty - wrap.maxcommit) > 0 ? (wrap.usageQty - wrap.allocatedUsg) - (wrap.usageQty - wrap.maxcommit) : (wrap.usageQty - wrap.allocatedUsg);
                                Scale_Utility_Overage_Lines__c extOvgLine = SUOveragetoLine.containskey(sc.id+'-'+'Sub Reserved') && SUOveragetoLine.get(sc.id+'-'+'Sub Reserved') != null ?  SUOveragetoLine.get(sc.id+'-'+'Sub Reserved') : new Scale_Utility_Overage_Lines__c();
                            lstOfOvgLines.add(prepareOvgLines('Sub Reserved', wrap, sc, tempOnDemandQty, extOvgLine));
                        }
                        if(wrap.existingonDemandCLI != null){
                            Scale_Utility_Overage_Lines__c extOvgLine = SUOveragetoLine.containskey(sc.id+'-'+'Sub Reserved') && SUOveragetoLine.get(sc.id+'-'+'Sub Reserved') != null ?  SUOveragetoLine.get(sc.id+'-'+'Sub Reserved') : new Scale_Utility_Overage_Lines__c();                   
                            Decimal tempOnDemandQty = (wrap.usageQty - wrap.allocatedUsg) > 0.0 ? (wrap.usageQty - wrap.allocatedUsg) : 0.0;
                            lstOfOvgLines.add(prepareOvgLines('Sub Reserved', wrap, sc, tempOnDemandQty, extOvgLine));
                        }
                    }
                    else{
                        Scale_Utility_Overage_Lines__c extOvgLine = SUOveragetoLine.containskey(sc.id+'-'+'Sub Reserved') && SUOveragetoLine.get(sc.id+'-'+'Sub Reserved') != null ?  SUOveragetoLine.get(sc.id+'-'+'Sub Reserved') : new Scale_Utility_Overage_Lines__c();                   
                        Decimal tempOnDemandQty = (wrap.usageQty - wrap.allocatedUsg) > 0.0 ? (wrap.usageQty - wrap.allocatedUsg) : 0.0;
                        lstOfOvgLines.add(prepareOvgLines('Sub Reserved', wrap, sc, tempOnDemandQty, extOvgLine));
                        
                    }                
                }
                else if(wrap.allocatedUsg == wrap.maxcommit){
                    Scale_Utility_Overage_Lines__c extOvgLine = SUOveragetoLine.containskey(sc.id+'-'+'Above Reserved') && SUOveragetoLine.get(sc.id+'-'+'Above Reserved') != null ?  SUOveragetoLine.get(sc.id+'-'+'Above Reserved') : new Scale_Utility_Overage_Lines__c()	;
                    Decimal tempOnDemandQty = (wrap.usageQty - wrap.allocatedUsg) > 0.0 ? (wrap.usageQty - wrap.allocatedUsg) : 0.0;
                    lstOfOvgLines.add(prepareOvgLines('Above Reserved', wrap, sc, tempOnDemandQty, extOvgLine));
                }
                
            }
              
        }
        if (!lstOfOvgLines.isEmpty()) {
            upsert lstOfOvgLines;
        }
        if (!setOfSnowFlakeToUpd.isEmpty()) {
            update new List<Snowflake_Feed__c>(setOfSnowFlakeToUpd);
        }
    }
    /***********************************************************************************
  * @description       : prepareOvgLines method which used to upsert Overage lines record with all the necessary info. 
  * Project            : Scale Utility
  * JIRA(s)            : CSU-486
  * @author            : NaveenkumarSelvaraj
  * @last modified on  : 05-12-2023
  * @last modified by  : NaveenkumarSelvaraj
  * arguments          : type --> AR / SR , wrap --> wrapper with all the header info against gcId, sc --> Overage header record, 
  * 					 ondemandQty --> Ondemand usage qty, scOvgLine --> existing overage line. 
  * return             : Scale_Utility_Overage_Lines__c
  * Modifications Log
  * 
  *******************************************************************************/
    private Scale_Utility_Overage_Lines__c prepareOvgLines(String type, calcOverageWrapper wrap, Scale_Utility_Overage__c sc, Decimal ondemandQty, Scale_Utility_Overage_Lines__c scOvgLine){
        Scale_Utility_Overage_Lines__c ovgLine = scOvgLine != null ? scOvgLine : new Scale_Utility_Overage_Lines__c();
        ovgLine.Scale_Utility_Overage__c = sc.id;
        ovgLine.Type__c = type;
        ovgLine.Minimum_Reserve_Consumption__c = wrap.allocatedUsg;
        ovgLine.Max_Contract_Consumption__c = wrap.maxcommit;                  
        ovgLine.SKU_Id__c =  wrap.existingonDemandCLI != null ? wrap.existingonDemandCLI.SBQQSC__Product__c : type == 'Above Reserved' ? wrap.onDemandARCLI.SBQQSC__Product__c : type == 'Sub Reserved' ? wrap.onDemandSRCLI.SBQQSC__Product__c : null;
        ovgLine.OnDemand_CLI__c = wrap.existingonDemandCLI != null ? wrap.existingonDemandCLI?.id : type == 'Above Reserved' ? wrap.onDemandARCLI?.id : type == 'Sub Reserved' ? wrap.onDemandSRCLI?.id : null;
        ovgLine.Actual_Usage_TB__c = wrap.usageQty;
        ovgLine.OnDemand_Usage_TB__c = ondemandQty;
        Contractlineitem eligibleCLI = wrap.existingonDemandCLI != null ? wrap.existingonDemandCLI : type == 'Above Reserved' ? wrap.onDemandARCLI : type == 'Sub Reserved' ? wrap.onDemandSRCLI : null;
        if(eligibleCLI != null){
            if(wrap.existingonDemandCLI != null){
                ovgLine.Unit_Net_Price__c = wrap.unitprice;
            }else{
                if(eligibleCLI.SBQQSC__QuoteLine__r.OnDemand_Discount__c != null && eligibleCLI.SBQQSC__QuoteLine__r.OnDemand_Discount__c != 0){
                    //ovgLine.Unit_Net_Price__c = (eligibleCLI.SBQQSC__QuoteLine__r.SBQQ__ProratedListPrice__c / eligibleCLI.SBQQSC__QuoteLine__r.SBQQ__ProrateMultiplier__c) * (eligibleCLI.SBQQSC__QuoteLine__r.OnDemand_Discount__c * 0.01); 
                    ovgLine.Unit_Net_Price__c = (eligibleCLI.SBQQSC__QuoteLine__r.SBQQ__ProratedListPrice__c / eligibleCLI.SBQQSC__QuoteLine__r.SBQQ__ProrateMultiplier__c) - ((eligibleCLI.SBQQSC__QuoteLine__r.SBQQ__ProratedListPrice__c / eligibleCLI.SBQQSC__QuoteLine__r.SBQQ__ProrateMultiplier__c) * (eligibleCLI.SBQQSC__QuoteLine__r.OnDemand_Discount__c * 0.01)); 
                }else{
                    ovgLine.Unit_Net_Price__c = (eligibleCLI.SBQQSC__QuoteLine__r.SBQQ__ProratedListPrice__c / eligibleCLI.SBQQSC__QuoteLine__r.SBQQ__ProrateMultiplier__c); 
                } 
            }  
        ovgLine.Unit_Net_Price__c = wrap.isFirstItem && wrap.onDemandPeriodInDays != null ? (wrap.onDemandPeriodInDays * 12 * (ovgLine.Unit_Net_Price__c / 365))?.setScale(2): ovgLine.Unit_Net_Price__c;
        }
        ovgLine.Net_Price__c = ovgLine.OnDemand_Usage_TB__c != 0.0 && ovgLine.OnDemand_Usage_TB__c != null ? (ovgLine.OnDemand_Usage_TB__c * (ovgLine.Unit_Net_Price__c != null ? ovgLine.Unit_Net_Price__c : 0.0)) : 0.0;
        return ovgLine;
    }
    /***********************************************************************************
  * @description       : calcOverageWrapper class which used to capture neccessary details to create overage header / lines. 
  * Project            : Scale Utility
  * JIRA(s)            : CSU-486
  * @author            : NaveenkumarSelvaraj
  * @last modified on  : 05-12-2023
  * @last modified by  : NaveenkumarSelvaraj
  * arguments          : NA 
  * return             : NA
  * Modifications Log
  * 
  *******************************************************************************/
    private class calcOverageWrapper {
        Id ordId;
        Decimal usageQty;
        String gcid;
        Date snopshotDate;
        Decimal allocatedUsg;
        Decimal maxcommit;
        Date periodStartDate;
        Decimal unitprice;
        List<Snowflake_Feed__c> lstOfSnowFlake;
        ContractLineItem rservLineItem;
        Boolean isFirstItem;
        ContractlineItem existingonDemandCLI;
        ContractlineItem onDemandSRCLI;
        ContractlineItem onDemandARCLI;
        ContractlineItem licenseCLI;
        Integer onDemandPeriodInDays;
      /***********************************************************************************
      * @description       : calcOverageWrapper constructor method which assign calcOverageWrapper class variable values. 
      * Project            : Scale Utility
      * JIRA(s)            : CSU-486
      * @author            : NaveenkumarSelvaraj
      * @last modified on  : 05-12-2023
      * @last modified by  : NaveenkumarSelvaraj
      * arguments          : snowflakeFeed --> snowflake feed record,  SCToCliList --> Service contract id against list of Clis, currentMnthDetailWrap --> Current month segment info,
      * 					 existingonDemandCLI --> eligible existing ondemand cli, onDemandARCLI -> eligible AR Cli, onDemandSRCLI --> eligible SR cli, licensecli --> license sku 
      * return             : NA
      * Modifications Log
      * 
      *******************************************************************************/
        private calcOverageWrapper(
            Snowflake_Feed__c snowflakeFeed,
            Map<Id, List<ContractLineItem>> SCToCliList,
            currentMonthLineDetail currentMnthDetailWrap,
            ContractlineItem existingonDemandCLI,
            ContractlineItem onDemandSRCLI,
            ContractlineItem onDemandARCLI,
            ContractLineItem licensecli
        ) {
            Decimal SFFeedUsage;
            Date LastMonth = snowflakeFeed != null ? snowflakeFeed.Snapshot_Date__c.addmonths(-1) : Date.newInstance(Constants.CURRENT_YEAR, Constants.CURRENT_MONTH, 26).addmonths(-1);
            Date LastMonthPeriodStDate = Date.newInstance(Lastmonth.year(), lastmonth.month(), 26);
            ordId = licensecli.SBQQSC__OrderProduct__r.OrderId;
            if(snowflakeFeed != null){
                SFFeedUsage = snowflakeFeed.Is_UCL__c
                    ? snowflakeFeed.Cluster_Usage_FETB__c
                    : SCToCliList?.get(snowflakeFeed.Service_Contract__c)[0]?.SBQQSC__OrderProduct__r.Order.Metering__c == 'BETB'
                        ? snowflakeFeed.Cluster_Usage_BETB__c
                        : snowflakeFeed.Cluster_Usage_FETB__c;
            }
            usageQty = SFFeedUsage != null ? SFFeedUsage : 0;
            gcid = licensecli.Global_Commit_ID__c;
            snopshotDate = snowflakeFeed != null ? snowflakeFeed.Snapshot_Date__c : Date.newInstance(Constants.CURRENT_YEAR, Constants.CURRENT_MONTH, 25);
            this.allocatedUsg = currentMnthDetailWrap.allocatedusage;
            this.periodStartDate = currentMnthDetailWrap.isFirstItem ? licensecli.SBQQSC__StartDate__c : LastMonthPeriodStDate;
            this.unitprice = currentMnthDetailWrap.unitPrice;
            if(snowflakeFeed != null){
                this.lstOfSnowFlake = new List<Snowflake_Feed__c>{ snowflakeFeed };
                    }
            this.rservLineItem = currentMnthDetailWrap.rservLineItem;
            this.isFirstItem = currentMnthDetailWrap.isFirstItem;
            this.existingonDemandCLI = existingonDemandCLI;
            this.onDemandSRCLI = onDemandSRCLI;
            this.onDemandARCLI = onDemandARCLI;
            this.licenseCLI = licensecli;
            this.onDemandPeriodInDays = currentMnthDetailWrap.onDemandPeriodInDays != null ? currentMnthDetailWrap.onDemandPeriodInDays : null; 
            this.maxcommit = (existingonDemandCLI != null && existingonDemandCLI.Max_Commit__c != null) ? existingonDemandCLI.Max_Commit__c : (onDemandARCLI != null && onDemandARCLI.Max_Commit__c != null ) ?  onDemandARCLI.Max_Commit__c : 0.0; 
        }
    }
     /***********************************************************************************
  * @description       : currentMonthLineDetail class which used to capture neccessary details of current month segment lines info. 
  * Project            : Scale Utility
  * JIRA(s)            : CSU-486
  * @author            : NaveenkumarSelvaraj
  * @last modified on  : 05-12-2023
  * @last modified by  : NaveenkumarSelvaraj
  * arguments          : NA 
  * return             : NA
  * Modifications Log
  * 
  *******************************************************************************/
    private class currentMonthLineDetail {
        Decimal allocatedusage;
        ContractLineItem rservLineItem;
        Boolean isFirstItem;
        Decimal unitPrice;
        Integer onDemandPeriodInDays;
         /***********************************************************************************
      * @description       : currentMonthLineDetail constructor method which assign currentMonthLineDetail class variable values. 
      * Project            : Scale Utility
      * JIRA(s)            : CSU-486
      * @author            : NaveenkumarSelvaraj
      * @last modified on  : 05-12-2023
      * @last modified by  : NaveenkumarSelvaraj
      * arguments          : allocatedusage --> allocated usage for a month,  rservLineItem --> current month segment line, isFirstItem --> if true denotes for the first month,
      * 					 unitPrice --> unit price for the current month, onDemandPeriodInDays -> Ondemand period in days 
      * return             : NA
      * Modifications Log
      * 
      *******************************************************************************/
        private currentMonthLineDetail(
            Decimal allocatedusage,
            ContractLineItem rservLineItem,
            Boolean isFirstItem,
            Decimal unitPrice,
            Integer onDemandPeriodInDays
        ) {
            this.allocatedusage = allocatedusage;
            this.rservLineItem = rservLineItem;
            this.isFirstItem = isFirstItem;
            this.unitPrice = unitPrice;
            this.onDemandPeriodInDays = onDemandPeriodInDays;
        }
    }
     /***********************************************************************************
      * @description       : handleScaleUtiliyPDFAssociation constructor method which assign currentMonthLineDetail class variable values. 
      * Project            : Scale Utility
      * JIRA(s)            : CSU-486
      * @author            : NaveenkumarSelvaraj
      * @last modified on  : 05-12-2023
      * @last modified by  : NaveenkumarSelvaraj
      * arguments          : NA
      * return             : NA
      * Modifications Log
      * version  Date          modified by               comments
      * 1.0		 05-12-2023    NaveenkumarSelvaraj       Moved logic from the ScaleUtilityOverageBatchProcess batch to ScaleUtilityOverageBatchWithCLI batch  
      *******************************************************************************/
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
            UtilityClass.logException(e, 'ScaleUtilityOverageBatchWithCLI', 'handleScaleUtilityPDFAssociation', 'Scale_Utility_Overage__c + Attachment');
        }
    }
}