public without sharing class DemandMatrixCalculation { //....

    enum CMA_KEY_TYPE { COMPACT, SUMMARY, FULL }
    
    
    public static Map<String,CMAllocation_For_Non_Aspen_Products__mdt> distiMetadataMap;
    public static Map<String,CMAllocation_For_Non_Aspen_Products__mdt> distiMetadataMapAspen;
    public static Map<ID, string> opptyHistoryMap;
    public static String cmForDemandMatrixUpdate;
    public static Map<String,ContractManufacturerAllocation__c> cmaAllocation;
    public static Map<Id,List<SBQQ__QuoteLine__c>> mapOfQuoteWithLinesWhenStage6 = new Map<Id,List<SBQQ__QuoteLine__c>>();
    public static Map<Id,List<SBQQ__QuoteLine__c>> mapOfQuoteWithLinesWhenNotStage6 = new Map<Id,List<SBQQ__QuoteLine__c>>();
    public static Map<String,ContractManufacturerAllocation__c> cmAllocationForNonAspenMap = new Map<String,ContractManufacturerAllocation__c>();


    final static String DML_STATUS_VAL_ACTIVE = 'Active';
    final static String DML_STATUS_VAL_INACTIVE = 'Inactive';
    final static String KEY_DELIMETER = ':';
    final static Boolean ENABLE_DEBUG_LOGS;
    final static String CURRENT_FY_QUARTER = GeneralUtility.determineFinancialYearAndQuarter(System.today());
    final static List<String> ACTIVE_CMS;
    final static String CM_SPARES_SE_OVERRIDE;
    static {
        ACTIVE_CMS = new List<String>();
          for (String accountId : OpportunityObjectTriggerHelper.aspenConfigCM.keyset()) {
        AspenConfig__mdt config = OpportunityObjectTriggerHelper.aspenConfigCM.get(accountId);
        ACTIVE_CMS.add(config.MasterLabel);
        if (config.IsDefaultCMForSpares__c) {
                CM_SPARES_SE_OVERRIDE = config.MasterLabel;
            }
        }
        ENABLE_DEBUG_LOGS = ShGl_DisableBusinessLogic__c.getInstance()?.Enable_Logs__c;
    }
    final static Map<CMA_KEY_TYPE, Integer> CMA_KEY_MAX_INDEX = new Map<CMA_KEY_TYPE, Integer>{
        CMA_KEY_TYPE.COMPACT => 1,
        CMA_KEY_TYPE.SUMMARY => 2,
        CMA_KEY_TYPE.FULL => 3
    };
    final static Map<CMA_KEY_TYPE, List<Schema.sObjectField>> CMA_KEY_FIELDS_BY_TYPE = new Map<CMA_KEY_TYPE, List<Schema.sObjectField>>{
        CMA_KEY_TYPE.COMPACT => new List<Schema.sObjectField>{
            Schema.ContractManufacturerAllocation__c.Quarter__c,
            Schema.ContractManufacturerAllocation__c.ContractManufacturer__c
        },
        CMA_KEY_TYPE.SUMMARY => new List<Schema.sObjectField>{
            Schema.ContractManufacturerAllocation__c.Quarter__c,
            Schema.ContractManufacturerAllocation__c.ContractManufacturer__c,
            Schema.ContractManufacturerAllocation__c.Product__c
        },
        CMA_KEY_TYPE.FULL => new List<Schema.sObjectField>{
            Schema.ContractManufacturerAllocation__c.Quarter__c,
            Schema.ContractManufacturerAllocation__c.ContractManufacturer__c,
            Schema.ContractManufacturerAllocation__c.Product__c,
            Schema.ContractManufacturerAllocation__c.Distributor__c
        }
    };

    final Map<Id, SBQQ__Quote__c> quoteMap;

    Map<String, ContractManufacturerAllocation__c> cmaMap;
    Map<String, ContractManufacturerAllocation__c> summaryCmaMap;
    Map<String, ContractManufacturerAllocation__c> compactCmaMap;

    public static List<ContractManufacturerAllocation__c> cmaList = new List<ContractManufacturerAllocation__c>();
    public static List<DemandMatrixLine__c> dmLineList = new List<DemandMatrixLine__c>();
    public static List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
    public static List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c>();
    public static List<OpportunityFieldHistory> oppHistList = new List<OpportunityFieldHistory>(); 
    public static List<ContractManufacturerAllocation__c> currentQuaterCmaList = new List<ContractManufacturerAllocation__c>();
    
    public DemandMatrixCalculation(Map<Id,string> oppCMNotif) {
        Set<Id> oppIds = oppCMNotif.keySet();
        Date lastDateOfLastFY;
        String lastFY;
        {
            String lastQuarter;
            Integer currentFyYear = Integer.valueOf(CURRENT_FY_QUARTER.substringBetween('FY', 'Q'));
            Integer currentFyQuarter = Integer.valueOf(CURRENT_FY_QUARTER.substringAfter('Q'));
            Integer lastFyYear = currentFyYear;
            Integer lastFyQuarter = currentFyQuarter - 1;
            if (currentFyQuarter == 1) { 
                --lastFyYear;
                lastFyQuarter = 4;
            }

            lastFY = String.valueOf('FY' + lastFyyear + 'Q' + lastFyQuarter);
            lastDateOfLastFY = GeneralUtility.getlastDateOfQuarter(lastFyYear, lastFyQuarter);
        }

        final Date today = System.today();
        final String cmaExpiringComment = today.year() + '-' + today.month() + '-' + today.day() + '\n' + 'This is Expired End of Quarter';

        cmaMap = new Map<String, ContractManufacturerAllocation__c>();
        summaryCmaMap = new Map<String, ContractManufacturerAllocation__c>();
        compactCmaMap = new Map<String, ContractManufacturerAllocation__c>();
        List<ContractManufacturerAllocation__c> cmasPrevQuarter = new List<ContractManufacturerAllocation__c>();
        if(cmaList.isEmpty()){
            cmaList = [SELECT  ContractManufacturer__c, Distributor__c, Distributor__r.Name, Product__c, Quarter__c, EndDate__c, Comments__c, TotalFulfillment__c
            FROM ContractManufacturerAllocation__c
            WHERE (Quarter__c = :CURRENT_FY_QUARTER OR (Quarter__c = :lastFY AND EndDate__c = NULL)) AND Type__c = 'Aspen'
                ORDER BY Quarter__c DESC];
        }
        for (ContractManufacturerAllocation__c cma : cmaList) {
            if (cma.Quarter__c == lastFY) {
                cma.EndDate__c = lastDateOfLastFY;
                cma.Type__c = 'Aspen';
                cma.Comments__c = String.isBlank(cma.Comments__c) ? cmaExpiringComment : cma.Comments__c + '\n' + cmaExpiringComment;
                cmasPrevQuarter.add(cma);
                continue;
            }
            if (cma.EndDate__c == null) cmaMap.put(getCmaKey(CMA_KEY_TYPE.FULL, cma), cma);
            ContractManufacturerAllocation__c summaryCma = summaryCmaMap.get(getCmaKey(CMA_KEY_TYPE.SUMMARY, cma));
            ContractManufacturerAllocation__c compactCma = compactCmaMap.get(getCmaKey(CMA_KEY_TYPE.COMPACT, cma));
            if (summaryCma == null) {
                summaryCma = new ContractManufacturerAllocation__c(
                    ContractManufacturer__c = cma.ContractManufacturer__c,
                    Product__c = cma.Product__c,
                    Type__c = 'Aspen',
                    Quarter__c = CURRENT_FY_QUARTER,
                    TotalFulfillment__c = 0,
                    Distributor__c = cma.Distributor__c
                );
            }
            summaryCma.TotalFulfillment__c += cma.TotalFulfillment__c;
            summaryCmaMap.put(getCmaKey(CMA_KEY_TYPE.SUMMARY, summaryCma), summaryCma);

            if (compactCma == null) {
                compactCma = new ContractManufacturerAllocation__c(
                    ContractManufacturer__c = cma.ContractManufacturer__c,
                    Quarter__c = CURRENT_FY_QUARTER,
                    TotalFulfillment__c = 0,
                    Type__c = 'Aspen',
                    Product__c = null,
                    Distributor__c = cma.Distributor__c
                );
            }
            compactCma.TotalFulfillment__c += cma.TotalFulfillment__c;
            compactCmaMap.put(getCmaKey(CMA_KEY_TYPE.COMPACT, compactCma), compactCma);
        } 

        Map<Id, Map<Id, DemandMatrixLine__c>> demandMatrixLinesByQuoteQli = new Map<Id, Map<Id, DemandMatrixLine__c>>();
        List<DemandMatrixLine__c> oldOrOrphanedDmLines = new List<DemandMatrixLine__c>();
        Set<Id> opptyWithOrphaDmLine = new Set<Id>();
        if(dmLineList.isEmpty()){
            dmLineList = [SELECT Quote__c, Status__c, Product__c, Quarter__c, Quantity__c, QuoteLine__c, Distributor__c, Opportunity__c, FinalCM_PerQuote__c, FinalCM_PerQuoteLine__c, Quote__r.SBQQ__Primary__c, ManufacturerByCM_PerItem__c, ManufacturerByDISTI_PerItem__c
            FROM DemandMatrixLine__c
                WHERE Quarter__c = :CURRENT_FY_QUARTER AND Status__c = :DML_STATUS_VAL_ACTIVE AND Opportunity__c IN :oppIds];
        }
        for (DemandMatrixLine__c dmLine : dmLineList) {
            if (String.isBlank(dmLine.Quote__c) || String.isBlank(dmLine.QuoteLine__c) || !dmLine.Quote__r.SBQQ__Primary__c || !ACTIVE_CMS.contains(dmLine.FinalCM_PerQuote__c)) {
                opptyWithOrphaDmLine.add(dmLine.Opportunity__c);
                oldOrOrphanedDmLines.add(dmLine);
                continue;
            }
            if (!demandMatrixLinesByQuoteQli.containsKey(dmLine.Quote__c)) {
                demandMatrixLinesByQuoteQli.put(dmLine.Quote__c, new Map<Id, DemandMatrixLine__c>());
            }
            demandMatrixLinesByQuoteQli.get(dmLine.Quote__c).put(dmLine.QuoteLine__c, dmLine);
        }
        quoteMap = new Map<Id, SBQQ__Quote__c>();
        CMAllocation_For_Non_Aspen_Products__mdt getmeta = getNonAspenProductMetadata(null);

        if(quoteList.isEmpty()){
            quoteList = [SELECT
                Id, Name, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.StageName, SBQQ__Opportunity2__r.CM_Notification_To_Distributor__c, SBQQ__Opportunity2__r.ContractManufacturer__c, 
                SBQQ__Opportunity2__r.Distributor_Lookup__r.Name, SBQQ__Opportunity2__r.Distributor_Lookup__c,
                (SELECT Id, Name,SBQQ__Product__r.name, SBQQ__Product__c, SBQQ__Product__r.Appliance_Model_HW__c, SBQQ__Product__r.Product_Type__c, SBQQ__Quote__r.SBQQ__Opportunity2__c, SBQQ__Quantity__c
                    FROM SBQQ__LineItems__r
                    WHERE SBQQ__Product__r.name IN : distiMetadataMapAspen.keySet() ) FROM SBQQ__Quote__c
                WHERE Id IN (SELECT SBQQ__PrimaryQuote__c FROM Opportunity WHERE Id IN :oppIds)];
        }
        for (SBQQ__Quote__c quote : quoteList) {
            Boolean hasOldDmLine = opptyWithOrphaDmLine.contains(quote.SBQQ__Opportunity2__c);
            Map<Id, DemandMatrixLine__c> demandMatrixLinesByQli = demandMatrixLinesByQuoteQli.get(quote.Id);
            if (demandMatrixLinesByQli == null) {
                quoteNeedsRecal.add(quote.Id);
                quoteMap.put(quote.Id, quote);
                continue;
            }
            for (SBQQ__QuoteLine__c quoteLine : quote.SBQQ__LineItems__r) {
                DemandMatrixLine__c existingDmLine = demandMatrixLinesByQli.get(quoteLine.Id);
                if (String.isBlank(quote.SBQQ__Opportunity2__r.ContractManufacturer__c)) {
                    quote.SBQQ__Opportunity2__r.ContractManufacturer__c = existingDmLine.FinalCM_PerQuote__c;
                }                
                if (
                    existingDmLine == null ||
                    existingDmLine.QuoteLine__c != quoteLine.Id ||
                    existingDmLine.Product__c != quoteLine.SBQQ__Product__c ||
                    existingDmLine.Quantity__c != quoteLine.SBQQ__Quantity__c ||
                    existingDmLine.Opportunity__c != quote.SBQQ__Opportunity2__c ||
                    existingDmLine.Distributor__c != quote.SBQQ__Opportunity2__r.Distributor_Lookup__c
                ) {
                    hasOldDmLine = true;
                    break;
                }
            }
            string oppCMval = oppCMNotif.get(quote.SBQQ__Opportunity2__c);
            if (
                hasOldDmLine || 
                (String.isBlank(oppCMval) || oppCMval.contains('Recalculate') || oppCMval.contains('Resent'))
            ) {
                quoteNeedsRecal.add(quote.Id);
                oldOrOrphanedDmLines.addAll(demandMatrixLinesByQli.values());
            }
            quoteMap.put(quote.Id, quote);
        }
        List<DemandMatrixLine__c> deactivatedDemandMatrix = updateOldOrOrphanedDmLines(oldOrOrphanedDmLines);
        if (ENABLE_DEBUG_LOGS)
            System.debug(LoggingLevel.FINE, 'Constructor Info:\n' +  JSON.serialize( new Map<String, Object>{
                'Today' => today, 'LastFY' => lastFY, 'CURRENT_FY_QUARTER' => CURRENT_FY_QUARTER, 'LastDateLastFY' => lastDateOfLastFY,
                'ACTIVE_CMS' => ACTIVE_CMS, 'CM_SPARES_SE_OVERRIDE' => CM_SPARES_SE_OVERRIDE,
                'FullCMAMap' => cmaMap, 'SummaryCMAMap' => summaryCmaMap, 'CompactCMAMap' => compactCmaMap, 'CMAsPreviousQuarter' => cmasPrevQuarter,
                'OppprtunityIds' => oppIds, 'QuoteMap' => quoteMap, 'QuotesNeedRecalculations' => quoteNeedsRecal,
                'DMLinesBundled' => demandMatrixLinesByQuoteQli, 'DeactivatedDMLines' => deactivatedDemandMatrix
            }));
        execute(oppIds, deactivatedDemandMatrix, cmasPrevQuarter);
    }

    static String getCmaKey(CMA_KEY_TYPE keyType, ContractManufacturerAllocation__c cma) {
        String key = '';
        String region = null;
        List<Schema.sObjectField> keyFields = CMA_KEY_FIELDS_BY_TYPE.get(keyType);
        List<String> keyValues = new List<String>();
        for (Schema.sObjectField field : keyFields) {
            keyValues.add(String.valueOf(cma.get(field)));
        }
        if(OpportunityObjectTriggerHelper.nonUsDistii!=null && 
           OpportunityObjectTriggerHelper.nonUsDistii.contains(cma.Distributor__c)){
               region = 'International';
           }else {
               region = 'US';
           }
        if(region != null){
            keyValues.add(region);
        }
        return String.join(keyValues, KEY_DELIMETER);
    }
    Set<Id> quoteNeedsRecal = new Set<Id>();
    public void execute(
        Set<Id> oppIds,
        List<DemandMatrixLine__c> deactivatedDemandMatrix,
        List<ContractManufacturerAllocation__c> cmasPrevQuarter
    ) {
        try {
            demandMatrixLinesToUpsert = new List<DemandMatrixLine__c>(deactivatedDemandMatrix);
            doCalculations();
            upsert demandMatrixLinesToUpsert;
            List<ContractManufacturerAllocation__c> cmasToUpsert = new List<ContractManufacturerAllocation__c>(cmaMap.values());
            cmasToUpsert.addAll(cmasPrevQuarter);
            upsert cmasToUpsert;
        } catch (Exception e) {
            String debugLines = JSON.serialize( new Map<String, Object>{ 'getCause: ' => e.getCause(), 'getMessage: ' => e.getMessage(), 'ExceptionType: ' => e.getTypeName(), 'getStackTraceString: ' => e.getStackTraceString(), 'For OppIds in Transaction:' => JSON.serialize(oppIds)});

            Batch_Error_Log__c errlog = new Batch_Error_Log__c();
            errlog.Class_Name__c = 'DemandMatrixCalculation';
            errlog.name = 'DemandMatrixCalculation: ' + e.getTypeName();
            errlog.Failure_Message__c = debugLines;
            insert errLog;

            List<ContentVersion> contents = new List<ContentVersion>{
                new ContentVersion(origin = 'H',PathOnClient = 'CMA Map ' + System.now() + '.json',title = 'CMA Map',versionData = Blob.valueOf(JSON.serialize(cmaMap))),
                new ContentVersion(origin = 'H',PathOnClient = 'Deactivated DM Lines ' + System.now() + '.json',title = 'Deactivated DM Lines Bundled Map',versionData = Blob.valueOf(JSON.serialize(deactivatedDemandMatrix))),
                new ContentVersion(origin = 'H',PathOnClient = 'DM Lines to Upsert ' + System.now() + '.json',title = 'DM Lines Bundled Map',versionData = Blob.valueOf(JSON.serialize(demandMatrixLinesToUpsert)))
            };
            insert contents;
            if (ENABLE_DEBUG_LOGS)
                System.debug( LoggingLevel.ERROR, 'Notes Content for Exception Found ' + JSON.serialize( new Map<String, Object>{ 
                    'ExceptionFound' => debugLines, 'CMA Map' => cmaMap, 'Deactivated DM Lines' => deactivatedDemandMatrix, 'DM Lines to Upsert' => demandMatrixLinesToUpsert
                }));

            Set<Id> contentVersionIds = new Set<Id>();
            for (ContentVersion cv : contents) { contentVersionIds.add(cv.Id); }
            List<ContentDocumentLink> contentLinks = new List<ContentDocumentLink>();
            for (ContentVersion content : [ SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersionIds]) {
                contentLinks.add( new ContentDocumentLink( LinkedEntityId = errLog.Id,contentdocumentid = content.ContentDocumentId,ShareType = 'V',Visibility = 'AllUsers'));
            }
            insert contentLinks;
        }
    }
    Set<Id> quoteLinesforOldDM = new Set<Id>();
    public Map<Id, String> oppIdCMCalculated = new Map<Id, String>();
    void doCalculations() {
        for (SBQQ__Quote__c quote : quoteMap.values()) {
            Id oppId = quote.SBQQ__Opportunity2__c;
            String cmSelected = quote.SBQQ__Opportunity2__r.ContractManufacturer__c;
            Id distributor = quote.SBQQ__Opportunity2__r.Distributor_Lookup__c;
            String distributorName = quote.SBQQ__Opportunity2__r.Distributor_Lookup__r.Name;
            Boolean isRecalNeeded = quoteNeedsRecal.contains(quote.Id);
            if (!isRecalNeeded) {
                if (ENABLE_DEBUG_LOGS) System.debug( LoggingLevel.FINEST, 'RestoringCM' + JSON.serialize(new Map<String, Object>{ 'opp Id' => oppId, 'CM Selected' => cmSelected }) );
                oppIdCMCalculated.put(oppId, cmSelected);
                continue;
            }
            ContractManufacturerAllocation__c dummyCma = new ContractManufacturerAllocation__c(
                Quarter__c = CURRENT_FY_QUARTER,
                ContractManufacturer__c = cmSelected,
                Type__c = 'Aspen',
                TotalFulfillment__c = 0,
                Distributor__c = distributor
            );
            Map<String, Object> calculationRes = cmCalculationAlgoForQuote(quote, dummyCma);
            String cmCalculated = (String) calculationRes.get('Preferred CM');
            List<DemandMatrixLine__c> dmLinesCalculated = (List<DemandMatrixLine__c>) calculationRes.get('DMLinesUpsert');
            dummyCma.Distributor__c = distributor;
            adjustCma(dummyCma, dmLinesCalculated, cmCalculated);
            demandMatrixLinesToUpsert.addAll(dmLinesCalculated);
            oppIdCMCalculated.put(oppId, cmCalculated);
            if (ENABLE_DEBUG_LOGS)
                System.debug(LoggingLevel.FINEST, 'Recalculated CM for' + JSON.serialize( new Map<String, Object>{
                    'opp Id' => oppId,  'New CM Calculated' => cmCalculated, 'Prev CM Selected' => cmSelected, 'DM Lines Calculated' => dmLinesCalculated
                }));
        }
    }
    Integer getFulfilledQtyFromMatrixByKey(String key, Map<String, ContractManufacturerAllocation__c> cmas) {
        Integer fulfilledQty = Integer.valueOf(cmas.get(key)?.TotalFulfillment__c);
        return (fulfilledQty != null) ? fulfilledQty : 0;
    }

    List<DemandMatrixLine__c> updateOldOrOrphanedDmLines(List<DemandMatrixLine__c> dmLineToDeactivate) {
        List<DemandMatrixLine__c> deactivatedDmLines = new List<DemandMatrixLine__c>();
        for (DemandMatrixLine__c dmLine : dmLineToDeactivate) {
            quoteNeedsRecal.add(dmLine.Quote__c);
            dmLine.Status__c = DML_STATUS_VAL_INACTIVE;
            ContractManufacturerAllocation__c dummyCma = new ContractManufacturerAllocation__c(
                Quarter__c = CURRENT_FY_QUARTER,
                ContractManufacturer__c = dmLine.FinalCM_PerQuote__c,
                Type__c = 'Aspen',
                TotalFulfillment__c = 0,
                Distributor__c = dmLine.Distributor__c,
                Product__c = dmLine.Product__c
            );
            String cmaKey;
            ContractManufacturerAllocation__c cma;
            {
                cmaKey = getCmaKey(CMA_KEY_TYPE.FULL, dummyCma);
                if(cmaMap.containsKey(cmaKey)){
                cma = cmaMap.get(cmaKey);
                cma.TotalFulfillment__c -= dmLine.Quantity__c;
                cmaMap.put(cmaKey, cma);
                }
            }
            {
                cmaKey = getCmaKey(CMA_KEY_TYPE.SUMMARY, dummyCma);
                if(summaryCmaMap.containsKey(cmaKey)){
                cma = summaryCmaMap.get(cmaKey);
                cma.TotalFulfillment__c -= dmLine.Quantity__c;
                summaryCmaMap.put(cmaKey, cma);
                }
            }
            {
                cmaKey = getCmaKey(CMA_KEY_TYPE.COMPACT, dummyCma);
                if(compactCmaMap.containsKey(cmaKey)){
                cma = compactCmaMap.get(cmaKey);
                cma.TotalFulfillment__c -= dmLine.Quantity__c;
                compactCmaMap.put(cmaKey, cma);
                }
            }
            deactivatedDmLines.add(dmLine);
        }
        return deactivatedDmLines;
    }
    private void adjustCma(
        ContractManufacturerAllocation__c dummyCma,
        List<DemandMatrixLine__c> dmLinesCalculated,
        String newCm
    ) {
        dummyCma.ContractManufacturer__c = newCm;
        for (DemandMatrixLine__c dmLine : dmLinesCalculated) {
            String cmaKey;
            ContractManufacturerAllocation__c cma;
            dummyCma.Product__c = dmLine.Product__c;
            {
                cmaKey = getCmaKey(CMA_KEY_TYPE.FULL, dummyCma);
                cma = cmaMap.get(cmaKey);
                if (cma == null) {
                    cma = new ContractManufacturerAllocation__c(
                        Quarter__c = CURRENT_FY_QUARTER,
                        Distributor__c = dmLine.Distributor__c,
                        Type__c = 'Aspen',
                        Product__c = dmLine.Product__c,
                        TotalFulfillment__c = 0,
                        ContractManufacturer__c = dmLine.FinalCM_PerQuote__c
                    );
                }
                cma.TotalFulfillment__c += dmLine.Quantity__c;
                cmaMap.put(cmaKey, cma);
            }
            {
                cmaKey = getCmaKey(CMA_KEY_TYPE.SUMMARY, dummyCma);
                cma = summaryCmaMap.get(cmaKey);
                if (cma == null) {
                    cma = new ContractManufacturerAllocation__c(
                        Quarter__c = CURRENT_FY_QUARTER,
                        Product__c = dmLine.Product__c,
                        Type__c = 'Aspen',
                        TotalFulfillment__c = 0,
                        ContractManufacturer__c = dmLine.FinalCM_PerQuote__c
                    );
                }
                cma.TotalFulfillment__c += dmLine.Quantity__c;
                summaryCmaMap.put(cmaKey, cma);
            }
            {
                cmaKey = getCmaKey(CMA_KEY_TYPE.COMPACT, dummyCma);
                cma = compactCmaMap.get(cmaKey);
                if (cma == null) {
                    cma = new ContractManufacturerAllocation__c(
                        Quarter__c = CURRENT_FY_QUARTER,
                        TotalFulfillment__c = 0,
                        Type__c = 'Aspen',
                        ContractManufacturer__c = dmLine.FinalCM_PerQuote__c
                    );
                }
                cma.TotalFulfillment__c += dmLine.Quantity__c;
                compactCmaMap.put(cmaKey, cma);
            }
        }
    }

    List<DemandMatrixLine__c> demandMatrixLinesToUpsert;
    private Map<String, Object> cmCalculationAlgoForQuote(
        SBQQ__Quote__c quote,
        ContractManufacturerAllocation__c dummyCma
    ) {
    Boolean checkForUsDistii = (OpportunityObjectTriggerHelper.nonUsDistii!=null && OpportunityObjectTriggerHelper.nonUsDistii.contains(quote?.SBQQ__Opportunity2__r?.Distributor_Lookup__c)); 
    
        List<DemandMatrixLine__c> dmLinesToUpsertHere = new List<DemandMatrixLine__c>();
        String lastCm = null;
        Boolean isCmConsistent = true;
        Boolean isFullAllocationScmci = false;
        Boolean isSoftwareEncryptQuote = false;
        String preferredCmByQuote;
        String strNotes;
        for (SBQQ__QuoteLine__c quoteLine : quote.SBQQ__LineItems__r) {
            DemandMatrixLine__c dmLine = cmCalculationAlgoForQli(quoteLine, dummyCma);
            if (lastCm == null) lastCm = dmLine.FinalCM_PerQuoteLine__c;
        isFullAllocationScmci = isFullAllocationScmci || (distiMetadataMapAspen.containskey(quoteLine.SBQQ__Product__r.Name) && distiMetadataMapAspen.get(quoteLine.SBQQ__Product__r.Name).SMCI_Percentage__c == 100);
            isCmConsistent = isCmConsistent && (lastCm == dmLine.FinalCM_PerQuoteLine__c);
            dmLinesToUpsertHere.add(dmLine);
        }
        if(cmForDemandMatrixUpdate != null) {
            preferredCmByQuote = cmForDemandMatrixUpdate;
             strNotes = 'CM was overriden from Opportunity based on Stage Po';
         }
        else if ((CM_SPARES_SE_OVERRIDE != null && isFullAllocationScmci) || checkForUsDistii) preferredCmByQuote = CM_SPARES_SE_OVERRIDE;
    else if (isCmConsistent) preferredCmByQuote = lastCm;
        else {
            String lowestCompactFulfilmentCM;
            Integer lowestCompactFulfilment;
            Integer lowestCompactFulfilmentCmPref;
            for (String cm : ACTIVE_CMS) {
                dummyCma.ContractManufacturer__c = cm;
                Integer totalFulfilledQtyByCm = getFulfilledQtyFromMatrixByKey(
                    getCmaKey(CMA_KEY_TYPE.COMPACT, dummyCma),
                    compactCmaMap
                );
                if (lowestCompactFulfilment == null || totalFulfilledQtyByCm < lowestCompactFulfilment) {
                    lowestCompactFulfilment = totalFulfilledQtyByCm;
                    lowestCompactFulfilmentCM = cm;
                }
            }
            preferredCmByQuote = lowestCompactFulfilmentCM;
        }

        for (DemandMatrixLine__c newDmLine : dmLinesToUpsertHere) {
            newDmLine.FinalCM_PerQuote__c = preferredCmByQuote;
            newDmLine.Distributor__c = quote.SBQQ__Opportunity2__r.Distributor_Lookup__c;
            newDmLine.Status__c = DML_STATUS_VAL_ACTIVE;
            newDmLine.Quarter__c = CURRENT_FY_QUARTER;
            newDmLine.Notes__c = strNotes != null ? strNotes : null;
        }
        if (ENABLE_DEBUG_LOGS) {
            System.debug( LoggingLevel.FINEST, 'CmAlogQuote' +  '\n' + JSON.serialize( new Map<String, Object>{
                'QuoteName'=> quote.Name, 'PreferredCM' => preferredCmByQuote, 'DMLinesUpsert' => dmLinesToUpsertHere,
                'Spares/SE Overridden' => ((CM_SPARES_SE_OVERRIDE != null) && (isFullAllocationScmci)),
                'CMConsistentForQLIs' => isCmConsistent
            }));
        }
        return new Map<String, Object>{ 'DMLinesUpsert' => dmLinesToUpsertHere, 'Preferred CM' => preferredCmByQuote };
    }

    private DemandMatrixLine__c cmCalculationAlgoForQli(
        SBQQ__QuoteLine__c quoteLine,
        ContractManufacturerAllocation__c dummyCma
    ) {
        dummyCma.Product__c = quoteLine.SBQQ__Product__c;
        DemandMatrixLine__c dmLine = new DemandMatrixLine__c(
            QuoteLine__c = quoteLine.Id,
            Quote__c = quoteLine.SBQQ__Quote__c,
            Quantity__c = quoteLine.SBQQ__Quantity__c,
            Product__c = quoteLine.SBQQ__Product__c,
            Distributor__c = dummyCma.Distributor__c,
            Opportunity__c = quoteLine.SBQQ__Quote__r.SBQQ__Opportunity2__c
        );

        String lowestDetailFulfilmentCM;
        String lowestSummaryFulfilmentCM;
        String lowestCompactFulfilmentCM;

        Integer lowestDetailFulfilment;
        Integer lowestSummaryFulfillment;
        Integer lowestCompactFulfilment;

        Integer lowestDetailFulfilmentCmPref;
        Integer lowestSummaryFulfilmentCmPref;
        Integer lowestCompactFulfilmentCmPref;

        for (String cm : ACTIVE_CMS) {
            dummyCma.ContractManufacturer__c = cm;

            Integer totalFulfilledQtyByCmForDistiForItem = getFulfilledQtyFromMatrixByKey( getCmaKey(CMA_KEY_TYPE.FULL, dummyCma),cmaMap);
            Integer totalFulfilledQtyByCmForItem = getFulfilledQtyFromMatrixByKey( getCmaKey(CMA_KEY_TYPE.SUMMARY, dummyCma),summaryCmaMap);
            Integer totalFulfilledQtyByCm = getFulfilledQtyFromMatrixByKey( getCmaKey(CMA_KEY_TYPE.COMPACT, dummyCma),compactCmaMap);

            if (lowestDetailFulfilmentCM == null || totalFulfilledQtyByCmForDistiForItem < lowestDetailFulfilment) {
                lowestDetailFulfilment = totalFulfilledQtyByCmForDistiForItem;
                lowestDetailFulfilmentCM = cm;
            }
            if (lowestSummaryFulfillment == null || totalFulfilledQtyByCmForItem < lowestSummaryFulfillment) {
                lowestSummaryFulfillment = totalFulfilledQtyByCmForItem;
                lowestSummaryFulfilmentCM = cm;
            }
            if (lowestCompactFulfilment == null || totalFulfilledQtyByCm < lowestCompactFulfilment) {
                lowestCompactFulfilment = totalFulfilledQtyByCm;
                lowestCompactFulfilmentCM = cm;
            }
        }
        dmLine.FinalCM_PerQuoteLine__c = (lowestSummaryFulfilmentCM == lowestDetailFulfilmentCM) ? lowestSummaryFulfilmentCM : lowestCompactFulfilmentCM;
        dmLine.ManufacturerByCM_PerItem__c = lowestSummaryFulfilmentCM;
        dmLine.ManufacturerByDISTI_PerItem__c = lowestDetailFulfilmentCM;
        return dmLine;
    }
    
          public static void getAllLines(set<Id> stage6oppty,set<Id> nonstage6oppty,Set<Id> primaryQuote,Map<Id,opportunity> newOppMap){
        CMAllocation_For_Non_Aspen_Products__mdt getmeta = getNonAspenProductMetadata(null);

        if(qliList.isEmpty() && (!stage6oppty.isEmpty() || !nonstage6oppty.isEmpty())){
            qliList = [SELECT Id, Line_Type__c, Name, SBQQ__Product__c,SBQQ__Quote__r.SBQQ__Opportunity2__c,SBQQ__Product__r.Name, SBQQ__Quote__r.SBQQ__Opportunity2__r.ContractManufacturer__c, SBQQ__Quantity__c
                       FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN : primaryQuote AND (SBQQ__Quote__r.SBQQ__Opportunity2__c IN : stage6oppty OR SBQQ__Quote__r.SBQQ__Opportunity2__c IN : nonstage6oppty)];
        }      
          for (SBQQ__QuoteLine__c qli :qliList ){
                                                        if(qli.Line_Type__c !=null && qli.Line_Type__c == 'New') { 
                                                            if(stage6oppty.contains(qli.SBQQ__Quote__r.SBQQ__Opportunity2__c)){
                                                                if(!mapOfQuoteWithLinesWhenStage6.containsKey(qli.SBQQ__Quote__c)) {
                                                                    mapOfQuoteWithLinesWhenStage6.put(qli.SBQQ__Quote__c, new List<SBQQ__QuoteLine__c>());
                                                            }
                                                            mapOfQuoteWithLinesWhenStage6.get(qli.SBQQ__Quote__c).add(qli);

                                                            }
                                                        }
                                                         if(nonstage6oppty.contains(qli.SBQQ__Quote__r.SBQQ__Opportunity2__c)){
                                                             system.debug('logic for ');
                                                             if(!mapOfQuoteWithLinesWhenNotStage6.containsKey(qli.SBQQ__Quote__c)) {
                                                                 mapOfQuoteWithLinesWhenNotStage6.put(qli.SBQQ__Quote__c, new List<SBQQ__QuoteLine__c>());
                                                             }
                                                             mapOfQuoteWithLinesWhenNotStage6.get(qli.SBQQ__Quote__c).add(qli);

                                                         }                                                         

                                                     }

      //  CURRENT_FY_QUARTER = GeneralUtility.determineFinancialYearAndQuarter(System.today());
        Set<String> fieldHistoryQuarter = new Set<String>();
        opptyHistoryMap = opptyWithQuarter(newOppMap.keyset());
        for(Id opptyId : newOppMap.keyset()){
            if(!opptyHistoryMap.containskey(opptyId))
                opptyHistoryMap.put(opptyId,CURRENT_FY_QUARTER);
        }
        fieldHistoryQuarter.addAll(opptyHistoryMap.values());
        cmaAllocationForQuarter(fieldHistoryQuarter);

    }

     public static Map<ID, string> opptyWithQuarter(Set<Id> opptyId){
        Map<ID, string> opptyHistoryMap = new Map<ID, string>();
        
         if(oppHistList.isEmpty() && !opptyId.isEmpty()){
             oppHistList = [Select Id,opportunityId, CreatedById, CreatedDate,
                            Field, NewValue, OldValue from OpportunityFieldHistory Where Field = 'StageName' AND  opportunityId IN : opptyId order by CreatedDate DESC];
         } 
         for(OpportunityFieldHistory oph : oppHistList){
                                               if(oph.NewValue == '6 PO With Channel'){
                                                   if(!opptyHistoryMap.containskey(oph.opportunityId)){
                                                       Date stage6Date = oph.CreatedDate.Date();
                                                       String findQuarter = GeneralUtility.determineFinancialYearAndQuarter(stage6Date);
                                                      // fieldHistoryQuarter.add(findQuarter);
                                                   opptyHistoryMap.put(oph.opportunityId,findQuarter);    
                                                   }

                                               }
                                           }

    return opptyHistoryMap;
    } 

    public static void operationsDeductCmaAllocation(Map<Id,opportunity> opptyId){
        system.debug('operationsDeductCmaAllocation is calling');
        for (Id quoteId : mapOfQuoteWithLinesWhenNotStage6.keySet()){
            for(SBQQ__QuoteLine__c quoteLine : mapOfQuoteWithLinesWhenNotStage6.get(quoteId))
            {
                    String determineQuarter;
                if(opptyHistoryMap.containskey(quoteLine.SBQQ__Quote__r.SBQQ__Opportunity2__c)){
                    determineQuarter = opptyHistoryMap.get(quoteLine.SBQQ__Quote__r.SBQQ__Opportunity2__c);
                }

                if(distiMetadataMap.containskey(quoteLine.SBQQ__Product__r.Name) && distiMetadataMap.get(quoteLine.SBQQ__Product__r.Name)!=null){
                    ContractManufacturerAllocation__c cma = cmAllocationForNonAspenMap.get(determineQuarter + '-' + quoteLine.SBQQ__Product__c + '-' + quoteLine?.SBQQ__Quote__r.SBQQ__Opportunity2__r.ContractManufacturer__c);
                    if(cma!=null){
                       if((cma.TotalFulfillment__c - quoteLine.SBQQ__Quantity__c) < 0)continue;
                        if(OpportunityObjectTriggerHelper.updateCmaAllocation.containskey(determineQuarter + '-' + quoteLine.SBQQ__Product__c + '-' + quoteLine?.SBQQ__Quote__r.SBQQ__Opportunity2__r.ContractManufacturer__c)){

                            OpportunityObjectTriggerHelper.updateCmaAllocation.get(determineQuarter + '-' + quoteLine.SBQQ__Product__c + '-' + quoteLine?.SBQQ__Quote__r.SBQQ__Opportunity2__r.ContractManufacturer__c).TotalFulfillment__c =cma.TotalFulfillment__c - quoteLine.SBQQ__Quantity__c;
                        }else{
                            cma.TotalFulfillment__c = cma.TotalFulfillment__c - quoteLine.SBQQ__Quantity__c;
                            OpportunityObjectTriggerHelper.updateCmaAllocation.put(determineQuarter + '-' + quoteLine.SBQQ__Product__c + '-' + quoteLine?.SBQQ__Quote__r.SBQQ__Opportunity2__r.ContractManufacturer__c,cma);
                        }
                       // OpportunityObjectTriggerHelper.updateCmaAllocation.add(cma);
                    }

                }
            }
        }

    }
    public static void  operationsForNonAspen(Map<Id,opportunity> nonaspenIds){
        system.debug('when oppty moved to 6 ');
        Map<Id,SBQQ__QuoteLine__c> mapOfQli = new Map<Id,SBQQ__QuoteLine__c>();
        Map<Id,String> mapOfCm = new Map<Id,String>();
        List<ContractManufacturerAllocation__c> cmaList = new List<ContractManufacturerAllocation__c>();
        String smci =  Order_control__mdt.getInstance('Smci').Value__c;
        String flex =Order_control__mdt.getInstance('Flex').Value__c;
        Decimal totalFulfillmentForFlex = 0;
        Decimal totalFulfillmentForsmci = 0;
        Decimal flexonqli =0;
        Decimal smcionqli =0;
        Decimal fullAllocation =0;
        system.debug('mapOfQuoteWithLinesWhenNotStage6 is ###### ' + mapOfQuoteWithLinesWhenStage6);
        for (Id quoteId : mapOfQuoteWithLinesWhenStage6.keySet()){
            Map<String,SBQQ__QuoteLine__c> mapOfProductWithQuoteLineTotalQuantity = new Map<String,SBQQ__QuoteLine__c>(); 
            for (SBQQ__QuoteLine__c quoteLine : mapOfQuoteWithLinesWhenStage6.get(quoteId)) {
                if(mapOfProductWithQuoteLineTotalQuantity.containskey(quoteLine.SBQQ__Product__c)){
                    mapOfProductWithQuoteLineTotalQuantity.get(quoteLine.SBQQ__Product__c).SBQQ__Quantity__c +=quoteLine.SBQQ__Quantity__c;
                }else{
                    mapOfProductWithQuoteLineTotalQuantity.put(quoteLine.SBQQ__Product__c,quoteLine.clone(true, true, false, false));
                }
            }
            system.debug('mapOfProductWithQuoteLineTotalQuantity is ##### ' + mapOfProductWithQuoteLineTotalQuantity);  
            Id opptyId; 
            for (SBQQ__QuoteLine__c quoteLine : mapOfProductWithQuoteLineTotalQuantity.values()) {
               system.debug('quoteLine is ###### ' + quoteLine);
                opptyId = quoteLine.SBQQ__Quote__r.SBQQ__Opportunity2__c;    
                if(distiMetadataMap.containskey(quoteLine.SBQQ__Product__r.Name) && distiMetadataMap.get(quoteLine.SBQQ__Product__r.Name)!=null){
                    CMAllocation_For_Non_Aspen_Products__mdt metaRecord = distiMetadataMap.get(quoteLine.SBQQ__Product__r.Name);
                    if(metaRecord!=null){
                        mapOfQli.put(quoteLine.Id,quoteLine);
                            ContractManufacturerAllocation__c cmaFlex = cmAllocationForNonAspenMap.get(CURRENT_FY_QUARTER + '-' + quoteLine.SBQQ__Product__c + '-' + flex);
                        ContractManufacturerAllocation__c cmaSmci = cmAllocationForNonAspenMap.get(CURRENT_FY_QUARTER + '-' + quoteLine.SBQQ__Product__c + '-' + smci);
                        if(cmaFlex!=null)
                            totalFulfillmentForFlex = cmaFlex?.TotalFulfillment__c;
                        if(cmaSmci!=null)
                            totalFulfillmentForsmci = cmaSmci.TotalFulfillment__c;
                        String cmperquoteline;
                        if(metaRecord.SMCI_Percentage__c!=100){
                            system.debug('quoteLine product is  ##### ' + quoteLine.SBQQ__Product__c);
                            system.debug('quoteLine.SBQQ__Quantity__c is ##### ' + quoteLine.SBQQ__Quantity__c);
                            system.debug('dividied by ' + (totalFulfillmentForFlex  + totalFulfillmentForsmci + quoteLine.SBQQ__Quantity__c));
                            if(((quoteLine.SBQQ__Quantity__c + totalFulfillmentForFlex)/(totalFulfillmentForFlex  + totalFulfillmentForsmci + quoteLine.SBQQ__Quantity__c))*100 < metaRecord.Flex_Percentage__c){
                                flexonqli++;
                                cmperquoteline = flex;
                            }else{
                                smcionqli++;
                                cmperquoteline = smci;

                            }
                        }else{
                            fullAllocation++;
                            cmperquoteline = smci;

                        }   

                    }
                }

            }

            String contractmanufaturer;
            system.debug('smcionqli is ######' + smcionqli);
            system.debug('flexonqli is ######' + flexonqli);
            if(fullAllocation > 0 || smcionqli >= flexonqli){
                contractmanufaturer = smci;
            }else{
                contractmanufaturer = flex;    
            }
            system.debug('contractmanufaturer is #####   ' + contractmanufaturer);
            mapOfCm.put(quoteId, contractmanufaturer);
            if(nonaspenIds.containskey(opptyId)){
                system.debug('update CM of opty');
                opportunity oppty =  nonaspenIds.get(opptyId);
                oppty.ContractManufacturer__c = contractmanufaturer;
            }
        }
        for(Id quoteLineId : mapOfQli.keySet()){
            SBQQ__QuoteLine__c qli = mapOfQli.get(quoteLineId);
            if(mapOfCm!=null && mapOfCm.containsKey(qli.SBQQ__Quote__c)){
                ContractManufacturerAllocation__c cma = cmAllocationForNonAspenMap.get(CURRENT_FY_QUARTER + '-' + qli.SBQQ__Product__c + '-' + mapOfCm.get(qli.SBQQ__Quote__c));
                if(cma!=null){
                    if(OpportunityObjectTriggerHelper.updateCmaAllocation.containskey(CURRENT_FY_QUARTER + '-' + qli.SBQQ__Product__c + '-' + mapOfCm.get(qli.SBQQ__Quote__c))){
                      //  ContractManufacturerAllocation__c getCmaAtKey = OpportunityObjectTriggerHelper.updateCmaAllocation.get(CURRENT_FY_QUARTER + '-' + qli.SBQQ__Product__c + '-' + mapOfCm.get(qli.SBQQ__Quote__c));
                       // getCmaAtKey.TotalFulfillment__c = cma.TotalFulfillment__c + qli.SBQQ__Quantity__c;
                        OpportunityObjectTriggerHelper.updateCmaAllocation.get(CURRENT_FY_QUARTER + '-' + qli.SBQQ__Product__c + '-' + mapOfCm.get(qli.SBQQ__Quote__c)).TotalFulfillment__c =cma.TotalFulfillment__c + qli.SBQQ__Quantity__c;
                    }else{
                        cma.TotalFulfillment__c = cma.TotalFulfillment__c + qli.SBQQ__Quantity__c;
                        OpportunityObjectTriggerHelper.updateCmaAllocation.put(CURRENT_FY_QUARTER + '-' + qli.SBQQ__Product__c + '-' + mapOfCm.get(qli.SBQQ__Quote__c),cma);

                    }
                }else{
                    ContractManufacturerAllocation__c contractmanufacturer = new ContractManufacturerAllocation__c(
                        ContractManufacturer__c = mapOfCm.get(qli.SBQQ__Quote__c),
                        Product__c = qli.SBQQ__Product__c,
                        Quarter__c = CURRENT_FY_QUARTER,
                        TotalFulfillment__c = qli.SBQQ__Quantity__c,
                        Type__c = 'Non Aspen',
                        Distributor__c = nonaspenIds.get(qli.SBQQ__Quote__r.SBQQ__Opportunity2__c)?.Distributor_Lookup__c
                    );
                    if(!OpportunityObjectTriggerHelper.updateCmaAllocation.containskey(CURRENT_FY_QUARTER + '-' + qli.SBQQ__Product__c + '-' + mapOfCm.get(qli.SBQQ__Quote__c)))
                    OpportunityObjectTriggerHelper.updateCmaAllocation.put(CURRENT_FY_QUARTER + '-' + qli.SBQQ__Product__c + '-' + mapOfCm.get(qli.SBQQ__Quote__c),contractmanufacturer);

                   // OpportunityObjectTriggerHelper.updateCmaAllocation.add(contractmanufacturer);

                }
            }
            system.debug('OpportunityObjectTriggerHelper.updateCmaAllocation is #### ' + OpportunityObjectTriggerHelper.updateCmaAllocation);
           // upsert updateCmaAllocation;

        }
    }


 public static  void cmaAllocationForQuarter(Set<String> quarter){
        Date lastDateOfLastFY;
        String lastFY;
        String lastQuarter;
       
         if(currentQuaterCmaList.isEmpty() && !quarter.isEmpty()){
             currentQuaterCmaList = [SELECT  ContractManufacturer__c, Distributor__c, Distributor__r.Name, Product__c,Product__r.name, Quarter__c, EndDate__c, Comments__c, TotalFulfillment__c
                                    FROM ContractManufacturerAllocation__c WHERE Quarter__c IN  :quarter  AND Type__c = 'Non Aspen' ORDER BY Quarter__c DESC];
         }
         for (ContractManufacturerAllocation__c cma : currentQuaterCmaList){
                 cmAllocationForNonAspenMap.put(cma.Quarter__c + '-' + cma.Product__c + '-' + cma.ContractManufacturer__c,cma);    

         }
     //return cmAllocationForNonAspen;


    }    

public static CMAllocation_For_Non_Aspen_Products__mdt getNonAspenProductMetadata(String recordId){
if(distiMetadataMap == null || distiMetadataMap.isEmpty()){
distiMetadataMap  = new Map<String,CMAllocation_For_Non_Aspen_Products__mdt>();
distiMetadataMapAspen  = new Map<String,CMAllocation_For_Non_Aspen_Products__mdt>();

Map<String, CMAllocation_For_Non_Aspen_Products__mdt> distiAllValuesMap = CMAllocation_For_Non_Aspen_Products__mdt.getAll();
for(String developerName : distiAllValuesMap.keySet()){
    CMAllocation_For_Non_Aspen_Products__mdt metadataRecord = distiAllValuesMap.get(developerName);
    if(metadataRecord.Type__c =='Aspen'){
                distiMetadataMapAspen.put(distiAllValuesMap.get(developerName).Product_Name__c,distiAllValuesMap.get(developerName));

    }else if(metadataRecord.Type__c =='Non Aspen'){ 
        distiMetadataMap.put(distiAllValuesMap.get(developerName).Product_Name__c,distiAllValuesMap.get(developerName));

    }
}
}
if(recordId!=null && recordId!=''){
if(distiMetadataMap.get(recordId)!=null){
return distiMetadataMap.get(recordId);
}else{
return new CMAllocation_For_Non_Aspen_Products__mdt();
}
}else{
return null;
}
}
  
    
}