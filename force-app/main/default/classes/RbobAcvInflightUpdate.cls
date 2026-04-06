/**
 * @description : Batch class to reprocess inflight Quote Lines that have Replacement_Details__c
 * and recompute RBOBACV__c using entitlement ACV
 * Author: Mustakim Shaikh
 */
public without sharing class RbobAcvInflightUpdate implements Database.Batchable<SObject>, Database.Stateful  {
    private List<Id> qtIds = new List<Id>();
    private Boolean processApproved = false;
    private Boolean useLabelWhere = false;
    public Integer processedCount = 0;
    public Integer successCount = 0;
    public Integer errorCount = 0;
    public Set<Id> processedQuoteIds = new Set<Id>();
    private Boolean reProcessAll = false;
    private Date startCloseDate;
    private Date endCloseDate;
    
    /** 
     * @description Default constructor for processing all inflight QLIs 
     * */
    public RbobAcvInflightUpdate() {
        this.processApproved = false;
        this.qtIds = null;
        this.useLabelWhere = false;
    }

    /**
     *  @description Constructor to initialize batch with specific Quote IDs
     *  @param qtIds List of Quote IDs to process
     */
    public RbobAcvInflightUpdate(List<Id> qtIds) {
        this.qtIds = qtIds;
        this.processApproved = false;
        this.useLabelWhere = false;
    }

    /**
     * @description : Constructor to initialize batch with reProcessAll flag
     * @param processAgain - Boolean flag to indicate if all inflight QLIs should be reprocessed
     * @param includeApproved When true, processes only Approved quotes; when false, excludes Approved quotes
     */
    public RbobAcvInflightUpdate(Boolean processAgain, Boolean includeApproved) {
        this.reProcessAll = processAgain;
        this.processApproved = includeApproved;
        this.useLabelWhere = false;
    }
    
    /**
     * @description Constructor overload to explicitly control Approved-only processing (separate from reProcessAll)
     * @param includeApproved When true, processes only Approved quotes; when false, excludes Approved quotes
     * @param approvedToggle When 'true', processes only Approved quotes; when 'false', excludes Approved quotes
     */
    public RbobAcvInflightUpdate(Boolean includeApproved, String approvedToggle) {
        this.qtIds = null;
        this.processApproved = includeApproved == null ? false : includeApproved;
        this.useLabelWhere = false;
    }

    /**
     * @description Constructor to initialize batch with inclusive Opportunity CloseDate range filter.
     * The filter is applied only when both dates are non-null.
     * @param startDate Start of inclusive CloseDate range.
     * @param endDate End of inclusive CloseDate range.
     * @param processAgain - Boolean flag to indicate if inflight QLIs should be reprocessed
     * @param includeApproved When true, processes only Approved quotes; when false, excludes Approved quotes
     */
    public RbobAcvInflightUpdate(Date startDate, Date endDate, Boolean processAgain, Boolean includeApproved) {
        this.startCloseDate = startDate;
        this.endCloseDate = endDate;
        this.processApproved = includeApproved == null ? false : includeApproved;
        this.reProcessAll = processAgain == null ? false : processAgain;
        this.qtIds = null;
        this.useLabelWhere = false;
    }
    
    /**
     * @description Starts the batch process by querying Quote Lines with Replacement_Details__c for inflight Quotes.
     * @param bc The batchable context.
     * @return A QueryLocator for Quote Lines meeting the criteria.
     **/
    public Database.QueryLocator start(Database.BatchableContext bc) {
        
        String baseQuery = 'SELECT Id,SBQQ__Quote__c,SBQQ__ProrateMultiplier__c, Replacement_Details__c, SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c, RBOBACV__c,Quote_Line_Type__c,SBQQ__ProductCode__c,  RAMP_EXIT_RBOB__c '
            + 'FROM SBQQ__QuoteLine__c '
            + 'WHERE ';
        
        // Immediately after WHERE: if labelWhere mode is enabled and label has a predicate, return using it
        if (useLabelWhere) {
            String labelWhere = System.Label.RbobInflightBatchWhere;
            if (labelWhere == null || String.isBlank(labelWhere)) {
                // No label provided, return an empty scope to safely no-op
                return Database.getQueryLocator('SELECT Id FROM SBQQ__QuoteLine__c WHERE Id = null');
            } else {
                labelWhere = labelWhere.trim();
                if (labelWhere != '') {
                    String earlyQuery = baseQuery + labelWhere;
                    return Database.getQueryLocator(earlyQuery);
                }
            }
        }

        String whereClause = '  SBQQ__Quote__r.SBQQ__Status__c != \'Invalid\' AND (SBQQ__Quote__r.SBQQ__Status__c != \'Expired\' OR SBQQ__Quote__r.SBQQ__Primary__c = true) AND SBQQ__Quote__r.SBQQ__Opportunity2__r.IsClosed = false AND SBQQ__Quote__r.SBQQ__Opportunity2__r.StageName !=\'6 PO With Channel\' and SBQQ__Quote__r.SBQQ__Type__c IN(\'Renewal\', \'Renewal+Expansion\' )';
        
        if(!reProcessAll) { 
            whereClause += ' AND (RBOBACV__c = null OR RAMP_EXIT_RBOB__c = null)';
        }
        if(processApproved){
            whereClause += ' AND (SBQQ__Quote__r.SBQQ__Status__c = \'Approved\' OR SBQQ__Quote__r.SBQQ__Status__c = \'In Review\') ';
        } else {
            whereClause += ' AND SBQQ__Quote__r.SBQQ__Status__c != \'Approved\' AND SBQQ__Quote__r.SBQQ__Status__c != \'In Review\' ';
        }
        if (startCloseDate != null && endCloseDate != null) {
            whereClause += ' AND SBQQ__Quote__r.SBQQ__Opportunity2__r.CloseDate >= :startCloseDate'
                       + ' AND SBQQ__Quote__r.SBQQ__Opportunity2__r.CloseDate <= :endCloseDate ';
        }
        if (qtIds != null && !qtIds.isEmpty()) {
            whereClause += ' AND SBQQ__Quote__c IN :qtIds';
        } else {
            whereClause += ' Order By SBQQ__Quote__c';
        }
        String finalQuery = baseQuery + whereClause;
        return Database.getQueryLocator(finalQuery);
    }
    
    /**
     * @description execute the batch process post querying Quote Lines with Replacement_Details__c for inflight Quotes.
     * @param bc The batchable context.
     * @param  scope The list of Quote Lines to process in this batch chunk.
     **/
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<SBQQ__QuoteLine__c> qls = (List<SBQQ__QuoteLine__c>) scope;
        
        // Collect entitlement ids referenced inside Replacement_Details__c JSON
        Set<Id> entIds = new Set<Id>();
        List<Batch_Error_Log__c> batchErrLogList = new List<Batch_Error_Log__c>();
        Map<id,List<SBQQ__QuoteLine__c>> quoteIdvsLineItemsList = new Map<id,List<SBQQ__QuoteLine__c>>();
        Map<id,SBQQ__QuoteLine__c> quoteLineMap = new Map<id,SBQQ__QuoteLine__c>();
        
        for (SBQQ__QuoteLine__c ql : qls) {
            try {
                if (ql.SBQQ__Quote__c != null) {
                    processedQuoteIds.add(ql.SBQQ__Quote__c);
                }
                if (ql.Replacement_Details__c != null && String.isNotBlank(ql.Replacement_Details__c)) {
                    Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(ql.Replacement_Details__c);
                    if (parsed.containsKey('rowValues')) {
                        List<Object> rows = (List<Object>) parsed.get('rowValues');
                        for (Object r : rows) {
                            Map<String, Object> row = (Map<String, Object>) r;
                            if (row.containsKey('entId') && row.get('entId') != null) {
                                entIds.add(Id.valueOf(String.valueOf(row.get('entId'))));
                            }
                            
                            if(row.containsKey('upgradeLines') && row.get('upgradeLines') != null) {
                                List<Object> Uprows = (List<Object>) row.get('upgradeLines');
                                for(Object ugRow :  Uprows) {
                                    Map<String, Object> urow = (Map<String, Object>) ugRow;
                                    if(entIds.contains(String.valueOf(urow.get('childEntId')))) continue;
                                    entIds.add(String.valueOF(urow.get('childEntId')));
                                }
                            }
                        }
                    }
                }
                if (!quoteIdvsLineItemsList.containsKey(ql.SBQQ__Quote__c)) {
                    quoteIdvsLineItemsList.put(ql.SBQQ__Quote__c, new List<SBQQ__QuoteLine__c>());
                }
                quoteIdvsLineItemsList.get(ql.SBQQ__Quote__c).add(ql); 
                quoteLineMap =  updateProMultiplierForAllLines(quoteIdvsLineItemsList);
            } catch (Exception ex) {
                batchErrLogList.add(new Batch_Error_Log__c(Class_Name__c='RbobAcvInflightUpdate',Failure_Message__c=ex.getMessage(),Object_ID__c = ql.Id, Failure_Date__c = Date.today(), Failure_Job_ID__c = bc.getJobID()));
            }
        }
        
        Map<Id, Entitlement> mapEnts = new Map<Id, Entitlement>();
        if (!entIds.isEmpty()) {
            for (Entitlement e : [SELECT Id, Entitlement_ACV__c,Entitlement_RAMP_EXIT_ACV__c, Quantity__c FROM Entitlement WHERE Id IN :entIds]) {
                mapEnts.put(e.Id, e);
            }
        }
        
        Map<id,SBQQ__QuoteLine__c> toUpdateMap = new Map<id,SBQQ__QuoteLine__c>();
        for (SBQQ__QuoteLine__c ql : qls) {
            Decimal qlRbobAcv = 0;
            Decimal ramRbobExit = 0;
            try {
                if (ql.Replacement_Details__c != null && String.isNotBlank(ql.Replacement_Details__c)) {
                    Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(ql.Replacement_Details__c);
                    if (parsed.containsKey('rowValues')) {
                        List<Object> rows = (List<Object>) parsed.get('rowValues');
                        for (Object r : rows) {
                            Map<String, Object> row = (Map<String, Object>) r;
                            String entIdStr = row.containsKey('entId') && row.get('entId')!=null ? String.valueOf(row.get('entId')) : null;
                            Decimal selectedQty = 0;
                            if (row.containsKey('selectedQty') && row.get('selectedQty')!=null) {
                                try { selectedQty = Decimal.valueOf(String.valueOf(row.get('selectedQty'))); } catch (Exception ne) { selectedQty = 0; }
                            }
                            if (entIdStr != null) {
                                Id entId = Id.valueOf(entIdStr);
                                if (mapEnts.containsKey(entId)) {
                                    Entitlement entRec = mapEnts.get(entId);
                                    if (entRec != null && entRec.Entitlement_ACV__c != null && entRec.Entitlement_ACV__c > 0
                                        && entRec.Quantity__c != null && entRec.Quantity__c > 0 && selectedQty != null) {
                                            qlRbobAcv += (entRec.Entitlement_ACV__c / entRec.Quantity__c) * selectedQty;
                                        }
                                    if (entRec != null && entRec.Entitlement_RAMP_EXIT_ACV__c != null && entRec.Entitlement_RAMP_EXIT_ACV__c > 0
                                        && entRec.Quantity__c != null && entRec.Quantity__c > 0 && selectedQty != null) {
                                            ramRbobExit += (entRec.Entitlement_RAMP_EXIT_ACV__c / entRec.Quantity__c) * selectedQty;
                                        }
                                    if(row.containsKey('upgradeLines') && row.get('upgradeLines') != null) {
                                        List<Object> Uprows = (List<Object>) row.get('upgradeLines');
                                        for(Object ugRow :  Uprows) {
                                            Map<String, Object> urow = (Map<String, Object>) ugRow;
                                            String entId2 = String.valueOf(urow.get('childEntId'));
                                            if (mapEnts.containsKey(entId2)) {
                                                Entitlement entRec2 = mapEnts.get(entId2);
                                                if (entRec2 != null && entRec2.Entitlement_ACV__c != null && entRec2.Entitlement_ACV__c > 0
                                                    && entRec2.Quantity__c != null && entRec2.Quantity__c > 0 && selectedQty != null) {
                                                        qlRbobAcv += (entRec2.Entitlement_ACV__c / entRec2.Quantity__c) * selectedQty;
                                                    }
                                                if (entRec2 != null && entRec2.Entitlement_RAMP_EXIT_ACV__c != null && entRec2.Entitlement_RAMP_EXIT_ACV__c > 0
                                                    && entRec2.Quantity__c != null && entRec2.Quantity__c > 0 && selectedQty != null) {
                                                        ramRbobExit += (entRec2.Entitlement_RAMP_EXIT_ACV__c / entRec2.Quantity__c) * selectedQty;
                                                    }
                                            }
                                        }
                                    }   
                                }    
                            }
                        }
                    }
                }
            } catch (Exception ex) {
                System.debug(LoggingLevel.ERROR, '@@MS Error parsing Replacement_Details__c for QL Id ' + ql.Id + ': ' + ex.getMessage());
            }
            Decimal newVal = qlRbobAcv.setScale(2);
            Decimal newValExit = ramRbobExit.setScale(2);
            if (quoteLineMap.containsKey(ql.Id)) {
                SBQQ__QuoteLine__c maxQl = quoteLineMap.get(ql.Id);
                ql.Max_Prorate_Multiplier__c =
                    maxQl.Max_Prorate_Multiplier__c;
            }
            if ( ql.RBOBACV__c != newVal ||  ql.RAMP_EXIT_RBOB__c != newValExit) {
                ql.RBOBACV__c = newVal;
                ql.RAMP_EXIT_RBOB__c = newValExit;
            }
            toUpdateMap.put(ql.Id, ql);
        }
        
        for (Id qlId : quoteLineMap.keySet()) {
            
            if (!toUpdateMap.containsKey(qlId)) {
                SBQQ__QuoteLine__c ql = quoteLineMap.get(qlId);
                toUpdateMap.put(qlId, ql);
            }
        }
        
        if (!toUpdateMap.isEmpty()) {
            
            SBQQ.TriggerControl.disable();
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true;
            LockQuoteValidationByPass.byPassValidation = true;
            List<SBQQ__QuoteLine__c> updateList =
                new List<SBQQ__QuoteLine__c>(toUpdateMap.values());
            Database.SaveResult[] results = Database.update(updateList, false);
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    batchErrLogList.add(new Batch_Error_Log__c(Status__c='Completed',Class_Name__c='RbobAcvInflightUpdate',Failure_Message__c='Updated Successfully',Object_ID__c = updateList[i].Id, Failure_Job_ID__c = bc.getJobID()));
                } else {
                    for (Database.Error e : results[i].getErrors()) {
                        batchErrLogList.add(new Batch_Error_Log__c(Status__c='Error',Class_Name__c='RbobAcvInflightUpdate',Failure_Message__c=e.getMessage(),Object_ID__c = updateList[i].Id,Failure_Date__c = Date.today(), Failure_Job_ID__c = bc.getJobID()));
                    }
                }
            }
            processedCount += results.size();
            if (!batchErrLogList.isEmpty()) insert batchErrLogList;
        }
    }
    
    /**
     * @description finish the batch process.
     * @param bc The batchable context.
     **/
    public void finish(Database.BatchableContext bc) {
        if (!processedQuoteIds.isEmpty()) {
            Database.executeBatch(
                new QuoteRollupBatch(new List<Id>(processedQuoteIds)),
                200
            );
        }
        //System.debug('RbobAcvInflightUpdate Batch processed=' + processedCount + ' success=' + successCount + ' errors=' + errorCount);
        
        
    }

    /**
     * @description Update Max Prorate Multiplier for all Quote Lines based on Quote Line Type and Product Code combinations.
     * @param quoteIdVsLineItemsList Map of Quote IDs to their corresponding list of Quote Lines.
     * @return Map of Quote Line IDs to updated Quote Line records with Max Prorate Multiplier set.
     **/
    public static Map<id,SBQQ__QuoteLine__c> updateProMultiplierForAllLines(
        Map<Id, List<SBQQ__QuoteLine__c>> quoteIdVsLineItemsList
    ) {
        Map<id,SBQQ__QuoteLine__c> linesToUpdateMap = new Map<id,SBQQ__QuoteLine__c>();
        
        for (Id quoteId : quoteIdVsLineItemsList.keySet()) {
            
            // Step 1: Store max ProrateMultiplier per combination
            Map<String, Decimal> comboToMaxProrate = new Map<String, Decimal>();
            
            for (SBQQ__QuoteLine__c ql : quoteIdVsLineItemsList.get(quoteId)) {
                
                if (ql.Quote_Line_Type__c == null || ql.SBQQ__ProductCode__c == null) {
                    continue;
                }
                
                String comboKey =
                    ql.Quote_Line_Type__c + '|' + ql.SBQQ__ProductCode__c;
                
                Decimal currentVal =
                    ql.SBQQ__ProrateMultiplier__c == null
                    ? 0
                    : ql.SBQQ__ProrateMultiplier__c;
                
                if (!comboToMaxProrate.containsKey(comboKey)
                    || currentVal > comboToMaxProrate.get(comboKey)) {
                        
                        comboToMaxProrate.put(comboKey, currentVal);
                    }
            }
            
            // Step 2: Apply max value to ALL quote lines
            for (SBQQ__QuoteLine__c ql : quoteIdVsLineItemsList.get(quoteId)) {
                
                if (ql.Quote_Line_Type__c == null || ql.SBQQ__ProductCode__c == null) {
                    continue;
                }
                
                String comboKey =
                    ql.Quote_Line_Type__c + '|' + ql.SBQQ__ProductCode__c;
                
                ql.Max_Prorate_Multiplier__c = comboToMaxProrate.get(comboKey);
                linesToUpdateMap.put(ql.id,ql);
            }
        }
        if (linesToUpdateMap.keyset().size() > 0) {
            return linesToUpdateMap;
        }
        return null;
    }

    /**
     * @description Constructor to enable label-only WHERE execution. When enabled, the start() query
     *              ignores all internal toggles and uses only the predicate supplied via Custom Label
     *              RbobInflightBatchWhere. The label should contain a predicate starting with AND/OR
     *              (e.g., "AND SBQQ__Quote__r.SBQQ__Status__c = 'Approved'").
     * @param useLabelWhereOnly if true, start() will use only the label-driven WHERE clause.
     */
    public RbobAcvInflightUpdate(Boolean useLabelWhereOnly) {
        this.useLabelWhere = useLabelWhereOnly == null ? false : useLabelWhereOnly;
        this.qtIds = null;
        this.processApproved = false;
        this.reProcessAll = false;
        this.startCloseDate = null;
        this.endCloseDate = null;
    }
    
}