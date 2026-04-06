/**
* @File Name : AutoApprovalTriggerUtility.cls
* @description : FY26WL-227 , FY26WL-237 - Custom Smart approval implementation
* @Author : Ankita Varma
* @Last Modified By : Paritosh Bhatia 
* @Last Modified On :  October 27, 2025
* @Modification Log :
* Test Class : 
*************************************************************************************************/
public without sharing class AutoApprovalTriggerUtility {
  
  public static Boolean isQueueRunning = false;
  /**
  * @description          : Before Insert : Update status and description for Smart approval
  * @param  approvals      : Approval Record
  */
  public static void autoApprove(List<SBAA__Approval__c> approvals) {
    Set<Id> approvalRuleIds = new Set<Id>();
    Id quoteId ;
    Map<Id, Approval_Snapshot__c> quoteSnapMap = new Map<Id, Approval_Snapshot__c>();
    Map<Id, Approval_Snapshot__c> qlSnapMap = new Map<Id, Approval_Snapshot__c>();
    Map<Id, List<Id>> sortedRuleMap = new  Map<Id, List<Id>>();
    try{
      //create map of quote to approvals records
      for (sbaa__Approval__c approval : approvals){
        if(approval.sbaa__Status__c != Constants.STATUS_APPROVED ) {
          quoteId = approval.Quote__c;
          approvalRuleIds.add(approval.sbaa__Rule__c);

          //create chain to Rule map
          if(!String.isBlank(approval.sbaa__ApprovalChain__c)) {
            if(!sortedRuleMap.containsKey(approval.sbaa__ApprovalChain__c)) {
              sortedRuleMap.put(approval.sbaa__ApprovalChain__c, new List<Id>());
            }
            sortedRuleMap.get(approval.sbaa__ApprovalChain__c).add(approval.sbaa__Rule__c);
          }
        }
      }
      if(approvalRuleIds.isEmpty()) {
        return;
      }
      //get smart conditions for above approval rules
      List<sbaa__ApprovalCondition__c> allConditions = getAllApprovalConditions(approvalRuleIds);
      Map<Id, List<sbaa__ApprovalCondition__c>> ruleSmartConditions = getSmartConditions(allConditions);
      if (ruleSmartConditions.isEmpty()) {
        return;
      }
      //get Sorted Rules
      for(Id chainId : sortedRuleMap.keySet()) {
        List<Id> sortedRuleIds = new List<Id>();
        for(sbaa__ApprovalRule__c ruleId : getRuleIndexes(sortedRuleMap.get(chainId), getConiditionsSteps(allConditions))) {
          sortedRuleIds.add(ruleId.Id);
        }
        sortedRuleMap.put(chainId, sortedRuleIds);
      }
      //get tracked fields and operator
      Map<Id, Map<String, String>> ruleToFieldNameOperator = getRuleToFieldOperator(ruleSmartConditions);
      Map<Id, Map<String, Object>> snapshotHistoryMap = new Map<Id, Map<String, Object>>();
      //get quote and snapshot data
      SBQQ__Quote__c quote = getQuoteData(quoteId, ruleSmartConditions, ruleToFieldNameOperator);
      for (Approval_Snapshot__c snap : quote.Approval_Snapshots__r){
        if (snap.Quote_Line__c != null){
          qlSnapMap.put(snap.Quote_Line__c, snap);
        } else if (snap.Quote__c != null){
          quoteSnapMap.put(snap.Quote__c, snap);
        }
        //Snapshot with deserialized history
        if(!String.isBlank(snap.History__c)) {
          Map<String, Object> historyMap = (Map<String, Object>) JSON.deserializeUntyped(snap.History__c);
          snapshotHistoryMap.put(snap.Id, historyMap);
        }
      }

      //get applicable quotelines for each rule, which satisfy the conditions 
      ResponseDetails result = evaluateApprovalRules(quote, ruleSmartConditions);
      Map<Id, List<SBQQ__Quoteline__c>> ruleToApplicableLines = result.ruleToApplicableLines;

      //if approval needs to be auto approved, update the fields accordingly 
      for (sbaa__Approval__c approval : approvals){
        Boolean isAutoApproved = true;
        Id ruleId = approval.sbaa__Rule__c;

        //skip non smart rules and rules with no applicable lines
        if(!ruleSmartConditions.containsKey(ruleId) || !ruleToApplicableLines.containsKey(ruleId) || ruleToApplicableLines.get(ruleId).isEmpty()) {
            continue;
        }
        
        //test each quoteline against the snapshot
        for(SBQQ__Quoteline__c ql : ruleToApplicableLines.get(ruleId)) {
          Approval_Snapshot__c snapshot = qlSnapMap.containsKey(ql.Id) 
            ? qlSnapMap.get(ql.Id) : new Approval_Snapshot__c();
          if(isAutoApproved) {
            //if no snapshot or no rule history, first time approval
            if(snapshot == null || snapshot.Id == null || String.isBlank(snapshot.History__c) || !snapshot.History__c.contains(ruleId)) {
              isAutoApproved = false;
            }
            //if values in tracked fields mismatching with snapshot
            else {
              Map<String, Object> historyMap = snapshot.Id != null && snapshotHistoryMap.containsKey(snapshot.Id) 
                ? snapshotHistoryMap.get(snapshot.Id) : new Map<String, Object>();
              Map<String, Object> ruleHistory = historyMap.containsKey(ruleId) 
                ? (Map<String, Object>) historyMap.get(ruleId) : new Map<String, Object>();

              Map<String, Object> updatedValues = compareRecordWithRuleHistory(ql, ruleHistory, ruleToFieldNameOperator.get(ruleId));
              
              if(!updatedValues.isEmpty()) {
                  isAutoApproved = false;
              }
            }
          }
        }
        //Approve all Smart approval Rules
        if(isAutoApproved) {
          approval.sbaa__ApprovedBy__c = System.Label.Smart_Approved;
          approval.Approval_Date__c = Date.today();
          approval.Auto_Approved__c = true;
          approval.sbaa__AssignedTo__c = null;   
          //FY26WL-542 commented below 
          //approval.sbaa__CommentsLong__c = Constants.SMART_APPROVED;
          approval.sbaa__Status__c = Constants.STATUS_APPROVED ;
          //Remove all the rules that are already approved - Start
          if(sortedRuleMap.containsKey(approval.sbaa__ApprovalChain__c)
            && sortedRuleMap.get(approval.sbaa__ApprovalChain__c).contains(approval.sbaa__Rule__c)) {
            List<Id> ruleList = sortedRuleMap.get(approval.sbaa__ApprovalChain__c);
            for (Integer i = ruleList.size() - 1; i >= 0; i--) {
              if (ruleList[i] == approval.sbaa__Rule__c) {
                ruleList.remove(i);  // ✔ remove by index
                break;
              }
            }
            sortedRuleMap.put(approval.sbaa__ApprovalChain__c, ruleList);
          } //-End
        }
      }
      //Update Approval Request that is "In Queue"
      Boolean isQuoteApproved = true;
      for (sbaa__Approval__c approval : approvals){
          if(approval.sbaa__Status__c == Constants.STATUS_ASSIGNED
          && sortedRuleMap.containsKey(approval.sbaa__ApprovalChain__c)
          && !sortedRuleMap.get(approval.sbaa__ApprovalChain__c).isEmpty()
          && sortedRuleMap.get(approval.sbaa__ApprovalChain__c).contains(approval.sbaa__Rule__c)
          && sortedRuleMap.get(approval.sbaa__ApprovalChain__c)[0] == approval.sbaa__Rule__c) {
              approval.sbaa__Status__c = Constants.STATUS_REQUESTED;
          }
          if(approval.sbaa__Status__c !=  Constants.STATUS_APPROVED ) {
            isQuoteApproved = false;
          }
      }
      if(isQuoteApproved) {
        updateQuoteStatus(quoteId);
      }
    }catch(Exception e) {
        insert new Custom_Error_Log__c(
            Class__c = 'AutoApprovalTriggerUtility',
            Functionality__c = 'autoApprove Method failed',
            Exception_Message__c= e.getMessage(),
            ErrorTrace__c=  e.getStackTraceString()
        );
    }
  }

  /**
  * @description          : Update Quote status if all approval requests are approved
  * @param  quoteId      :
  */
  public static void updateQuoteStatus(Id quoteId) {
    if(Schema.sObjectType.SBQQ__Quote__c.isUpdateable() || Test.isRunningTest()){
      SBQQ__Quote__c quoteRec = new SBQQ__Quote__c(Id = quoteId, 
      SBQQ__Status__c =  Constants.STATUS_SMART_APPROVED);
      Database.update(quoteRec,true);
    }
  }

  /**
  * @description          :  After Update : Create/Update Snapshot record
  * @param  listApproval  : New Approval Record
  * @param  oldMap        : Old approval record
  */
  public static void createSnapshots(List<sbaa__Approval__c> listApproval, Map<Id, sbaa__Approval__c> oldMap){
    Id quoteId;
    Set<Id> ruleIds = new Set<Id>();
    List<Approval_Snapshot__c> snapshotsToInsert = new List<Approval_Snapshot__c>();
    List<Approval_Snapshot__c> snapshotsToUpdate = new List<Approval_Snapshot__c>();
    Map<Id, Approval_Snapshot__c> quoteSnapMap = new Map<Id, Approval_Snapshot__c>();
    Map<Id, Approval_Snapshot__c> qlSnapMap = new Map<Id, Approval_Snapshot__c>();
    try {
      for (sbaa__Approval__c approval : listApproval){
        quoteId = approval.Quote__c;
        if(approval.sbaa__Status__c == Constants.STATUS_APPROVED 
        && oldMap.get(approval.Id).sbaa__Status__c != approval.sbaa__Status__c
        && approval.Approvals_from_Source_Quote__c == false) {
          ruleIds.add(approval.sbaa__Rule__c);
        }
      }
      if(ruleIds.isEmpty()) {
        return;
      }

      Map<Id, List<sbaa__ApprovalCondition__c>> ruleSmartConditions = getSmartConditions(getAllApprovalConditions(ruleIds));
      if (ruleSmartConditions.isEmpty()) {
        return;
      }
      // Determine fields to track for each rule
      Map<Id, Map<String, String>> ruleToFieldNameOperator = getRuleToFieldOperator(ruleSmartConditions);
      //get quote and snapshot data
      SBQQ__Quote__c quote = getQuoteData(quoteId, ruleSmartConditions, ruleToFieldNameOperator);
      for (Approval_Snapshot__c snap : quote.Approval_Snapshots__r){
        if (snap.Quote_Line__c != null){
          qlSnapMap.put(snap.Quote_Line__c, snap);
        } else if (snap.Quote__c != null){
          quoteSnapMap.put(snap.Quote__c, snap);
        }
      }
      //get applicable quotelines for each rule, which satisfy the conditions 
      ResponseDetails result = evaluateApprovalRules(quote, ruleSmartConditions);
      Map<Id, Set<Id>> ruleToApplicableLineIds = new Map<Id, Set<Id>>();
      if(result != null && result.ruleToApplicableLines != null && !result.ruleToApplicableLines.isEmpty()) {
        for(Id ruleId : result.ruleToApplicableLines.keySet()) {
          for(SBQQ__Quoteline__c ql : result.ruleToApplicableLines.get(ruleId)) {
            if(!ruleToApplicableLineIds.containsKey(ruleId)) {
              ruleToApplicableLineIds.put(ruleId, new Set<Id>());
            }
            ruleToApplicableLineIds.get(ruleId).add(ql.Id);
          }
        }
      }
      //test ql data against snapshot. Update if values have changed or create new
      //TBD - test only applicable quote lines
      for (SBQQ__QuoteLine__c ql : quote.SBQQ__LineItems__r){
        Boolean updateSnapshot = false;
        Approval_Snapshot__c snapshot;
        Map<String, Object> historyMap = new Map<String, Object>();
       //get existing snapshot or create new
       if (qlSnapMap.containsKey(ql.Id)){
         snapshot = qlSnapMap.get(ql.Id);
         if (!String.isBlank(snapshot.History__c)) {
          //TBD - check why try catch
          historyMap = (Map<String, Object>) JSON.deserializeUntyped(snapshot.History__c);
         }
       } else {
        snapshot = new Approval_Snapshot__c();
        snapshot.Quote_Line__c = ql.Id;
        snapshot.Quote__c = quote.Id;
       }

       //evaluate quoteline against each rule
       for (Id ruleId : ruleSmartConditions.keySet()){
        if(ruleToApplicableLineIds.containsKey(ruleId) && ruleToApplicableLineIds.get(ruleId).contains(ql.Id)) {
          //create or get rule level history
          Map<String, Object> ruleHistory = historyMap.containsKey(ruleId) 
                    ? (Map<String, Object>) historyMap.get(ruleId) : new Map<String, Object>();
          Map<String, Object> updatedValues = compareRecordWithRuleHistory(ql, ruleHistory, ruleToFieldNameOperator.get(ruleId));
            // Update history for this rule
          if (!updatedValues.isEmpty()){
            updateSnapshot = true;
            for (String field : updatedValues.keySet()){
              ruleHistory.put(field, updatedValues.get(field));
            }
            historyMap.put(ruleId, ruleHistory);
          }
        }
      }
      if (updateSnapshot){
        snapshot.History__c = JSON.serialize(historyMap);
        if (snapshot.Id != null){
          snapshotsToUpdate.add(snapshot);
        }
        else {
          snapshotsToInsert.add(snapshot);
        }
      }
    }

    if (!snapshotsToInsert.isEmpty()) {
      insert snapshotsToInsert;
    }

    if (!snapshotsToUpdate.isEmpty()) {
      update snapshotsToUpdate;
    }
   } catch(Exception e) {
    insert new Custom_Error_Log__c(
        Class__c = 'AutoApprovalTriggerUtility',
        Functionality__c = 'createSnaphots Method failed',
        Exception_Message__c= e.getMessage(),
        ErrorTrace__c=  e.getStackTraceString()
      );
    }
  }

  /**
    * @description          : Comparision with old Snapshot field to QL record
    * @param  recordObj     : Quote line record
    * @param  ruleHistory        : History field
    * @param  fieldToNameOperator  : Field value to it's operator
    * @return : Map
  */
  public static Map<String, Object> compareRecordWithRuleHistory(
    SObject recordObj, Map<String, Object> ruleHistory, Map<String, String> fieldToNameOperator) {
    Map<String, Object> updatedValues = new Map<String, Object>();
    //compare each tracked field
    //if tier changed, no auto-approval and discard existing values
    if (fieldToNameOperator.containsKey(Constants.QL_RWD_APPROVAL_TIER)){
        String field = Constants.QL_RWD_APPROVAL_TIER;
        String oldVal = (String)ruleHistory.get(field) !=null ? (String)ruleHistory.get(field) : '';
        String newVal = (String)recordObj.get(field) != null ? (String)recordObj.get(field) : '';
        
        Boolean result = false;
        if(newVal.contains(Constants.STRING_TIER)) {
            String qLRange = newVal.substringAfter(Constants.STRING_TIER);
            if (qLRange.contains('|')) {
                qLRange = qLRange.substringBefore('|').trim();
                result = qLRange != oldVal;
            }
            if(result) {
                //Values is changed
                updatedValues.put(field, qLRange);
                //discard other values
                ruleHistory = new Map<String, Object>();
            }
        }
    }
    
    for (String field : fieldToNameOperator.keySet()){
        if (field != Constants.QL_RWD_APPROVAL_TIER){
            Object oldVal = ruleHistory.get(field);
            Object newVal = recordObj.get(field);
            String operator = fieldToNameOperator.get(field);

            if ((operator == Constants.EQUALS_OPERATOR && !ConditionsEvaluator.operate(newVal, operator, oldVal))
            || ((operator == Constants.GREATER_THAN_OPERATOR || operator == Constants.LESS_THAN_OPERATOR ) 
                && ConditionsEvaluator.operate(newVal, operator, oldVal))
            || (oldVal == null && newVal != null)) {
                //Values is changed
                updatedValues.put(field, newVal);
            }
        }
    }

    return updatedValues;
}

  /**
  * @description    :get smart conditions for approval rules
  * @param allConditions :approval Conditions
  * @return 
  */
  public static Map<Id, List<sbaa__ApprovalCondition__c>> getSmartConditions(List<sbaa__ApprovalCondition__c> allConditions){

    Map<Id, List<sbaa__ApprovalCondition__c>> ruleSmartConditions = new Map<Id, List<sbaa__ApprovalCondition__c>>();

    for(sbaa__ApprovalCondition__c  condition : allConditions) {
      if(condition.Custom_Smart_Approval__c) {
        if(!ruleSmartConditions.containsKey(condition.sbaa__ApprovalRule__c)) {
            ruleSmartConditions.put(condition.sbaa__ApprovalRule__c , new List<sbaa__ApprovalCondition__c>());
        }
        ruleSmartConditions.get(condition.sbaa__ApprovalRule__c).add(condition);
      }
    }
    return ruleSmartConditions;
  }
  /**
  * @description    :get smart conditions for approval rules
  * @param allConditions : approval Conditions
  * @return 
  */
  public static Map<Id, List<sbaa__ApprovalCondition__c>> getConiditionsSteps(List<sbaa__ApprovalCondition__c> allConditions) {
    Map<Id, List<sbaa__ApprovalCondition__c>> ruleConditions = new Map<Id, List<sbaa__ApprovalCondition__c>>();
    for(sbaa__ApprovalCondition__c  condition : allConditions) {
      if(!ruleConditions.containsKey(condition.sbaa__ApprovalRule__c)) {
          ruleConditions.put(condition.sbaa__ApprovalRule__c , new List<sbaa__ApprovalCondition__c>());
      }
      ruleConditions.get(condition.sbaa__ApprovalRule__c).add(condition);
    }
    return ruleConditions;
  }
  /**
    * @description    :get smart conditions for approval rules
    * @param approvalRuleIds : set of approval Ids
    * @return 
    */
  public static List<sbaa__ApprovalCondition__c> getAllApprovalConditions(Set<Id> approvalRuleIds) {
    List<sbaa__ApprovalCondition__c> allConditions = new List<sbaa__ApprovalCondition__c>();
    allConditions = [SELECT 
        sbaa__ApprovalRule__r.sbaa__TargetObject__c, 
        sbaa__ApprovalRule__r.sbaa__ApprovalStep__c,
        Id, sbaa__Index__c, sbaa__EnableSmartApproval__c, sbaa__TestedField__c, 
        sbaa__TestedVariable__c, sbaa__TestedVariable__r.sbaa__TargetObject__c, 
        sbaa__TestedVariable__r.sbaa__AggregateField__c, 
        sbaa__TestedVariable__r.sbaa__AggregateFunction__c, 
        sbaa__TestedVariable__r.sbaa__FilterField__c, 
        sbaa__TestedVariable__r.sbaa__FilterValue__c, 
        sbaa__TestedVariable__r.sbaa__Operator__c, 
        sbaa__Operator__c, sbaa__FilterType__c, sbaa__FilterField__c, 
        sbaa__FilterValue__c, sbaa__FilterVariable__c, 
        sbaa__FilterVariable__r.sbaa__TargetObject__c, 
        sbaa__FilterVariable__r.sbaa__AggregateField__c, 
        sbaa__FilterVariable__r.sbaa__AggregateFunction__c, 
        sbaa__FilterVariable__r.sbaa__FilterField__c, 
        sbaa__FilterVariable__r.sbaa__FilterValue__c, 
        sbaa__FilterVariable__r.sbaa__Operator__c, 
        Custom_Smart_Approval__c,
        Track_Fields__c
    FROM sbaa__ApprovalCondition__c 
    WHERE sbaa__ApprovalRule__c IN :approvalRuleIds
      ORDER BY sbaa__ApprovalRule__r.sbaa__ApprovalStep__c ASC];
    return allConditions;
  }

    /**
    * @description    :get quote and quotelines data as per the smart condition fields
    * @param quoteId : Quote Id
    * @param ruleSmartConditions : Map of Approval Rule Id to it's conditions
    * @param ruleToFieldNameOperator : Map of Rule Id and Field api name and it's operator mentioned on approval condition
    * @return 
    */
  public static SBQQ__Quote__c getQuoteData(Id quoteId, Map<Id, List<sbaa__ApprovalCondition__c>> ruleSmartConditions, Map<Id, Map<String, String>> ruleToFieldNameOperator){

    Map<String, Set<String>> objectFields = new Map<String, Set<String>>();
    Set<String> qlFields = new Set<String>{};

    //get fields for tested smart conditions
    for (Id ruleId : ruleSmartConditions.keySet()) {
        for (sbaa__ApprovalCondition__c cond : ruleSmartConditions.get(ruleId)){
            if (!objectFields.containsKey(cond.sbaa__ApprovalRule__r.sbaa__TargetObject__c)){
                objectFields.put(cond.sbaa__ApprovalRule__r.sbaa__TargetObject__c, new Set<String>());
            }
            if (cond.sbaa__TestedField__c != null){
                objectFields.get(cond.sbaa__ApprovalRule__r.sbaa__TargetObject__c).add(cond.sbaa__TestedField__c);
            }
            if (cond.sbaa__FilterField__c != null){
                objectFields.get(cond.sbaa__ApprovalRule__r.sbaa__TargetObject__c).add(cond.sbaa__FilterField__c);
            }
            if (cond.sbaa__TestedVariable__r != null){
                
                sbaa__ApprovalVariable__c approvVar = cond.sbaa__TestedVariable__r;
                if (approvVar.sbaa__AggregateField__c != null){
                    qlFields.add(approvVar.sbaa__AggregateField__c);
                }
                if (approvVar.sbaa__FilterField__c != null){
                    qlFields.add(approvVar.sbaa__FilterField__c);
                }
            }
            if (cond.sbaa__FilterVariable__r != null){
                sbaa__ApprovalVariable__c approvVar = cond.sbaa__FilterVariable__r;

                if (approvVar.sbaa__AggregateField__c != null){
                    qlFields.add(approvVar.sbaa__AggregateField__c);
                }
                if (approvVar.sbaa__FilterField__c != null){
                    qlFields.add(approvVar.sbaa__FilterField__c);
                }
            }
        }
    }

    //get fields for tracked fields
    Set<String> trackedFields = new Set<String>();
    for (Map<String, String> fieldToNameOperator : ruleToFieldNameOperator.values()){
        for (String field : fieldToNameOperator.keySet()){
            trackedFields.add(field);
        }
    }
    qlFields.addAll(trackedFields);
    //query quote, quotelines and snapshots
    String key = 'SBQQ__Quote__c';
    String query ='SELECT Id ';
    if(objectFields.containsKey(key) && !objectFields.get(key).isEmpty()) {
        query += ',' + String.join(new List<String>(objectFields.get(key)), ', ');
    }
    if(qlFields.size() > 0){
        query += ', (SELECT Id, ' + String.join(new List<String>(qlFields), ', ') + ' FROM SBQQ__LineItems__r)';
    }
    query += ', (SELECT History__c, Quote_Line__c, Quote__c FROM Approval_Snapshots__r)';
    query += ' FROM SBQQ__Quote__c WHERE Id = :quoteId';

    return Database.query(query.trim());
  }

    /**
    * @description    :evaluate approval rules against quote lines
    * @param quote : Quote record
    * @param ruleSmartConditions : Map of Approval Rule Id to it's conditions
    * @return 
    */
    public static ResponseDetails evaluateApprovalRules(SBQQ__Quote__c quote, Map<Id, List<sbaa__ApprovalCondition__c>> ruleSmartConditions) {

      ResponseDetails result = new ResponseDetails();
      Map<Id, List<SBQQ__QuoteLine__c>> ruleToApplicableLines = new Map<Id, List<SBQQ__QuoteLine__c>>();

      for (Id ruleId : ruleSmartConditions.keySet()){
        //evaluate smart conditions against quote lines
        List<SBQQ__Quoteline__c> applicableLines = evaluateSmartApprovalConditions(ruleSmartConditions.get(ruleId), quote.SBQQ__LineItems__r);
        ruleToApplicableLines.put(ruleId, applicableLines);
      }

      result.ruleToApplicableLines = ruleToApplicableLines;
      result.ruleSmartConditions = ruleSmartConditions;
      return result; //Return filtered Smart Approval Rules, Corresponding Conditions, Rule info
    }

    /**
    * @description Executes before insert trigger logic on Approval.
    * @param smartConditions  : List of Approval Conditions to be evaluated.
    * @param quotelines  : List of Quote Lines to be evaluated against the conditions.
    * @return
    */
    public static List<SBQQ__Quoteline__c> evaluateSmartApprovalConditions(
      List<sbaa__ApprovalCondition__c> smartConditions, List<SBQQ__Quoteline__c> quotelines) {
    
      List<SBQQ__Quoteline__c> applicableLines = new List<SBQQ__Quoteline__c>();

      for(SBQQ__Quoteline__c ql : quotelines) {
        Boolean evaluateResult = false;
        for (sbaa__ApprovalCondition__c cond : smartConditions){
            if(cond.sbaa__TestedVariable__c != null && cond.sbaa__TestedVariable__r.sbaa__FilterField__c != null) {
                //evaluate approval variable level filter
                evaluateResult = ConditionsEvaluator.operate(
                ql.get(cond.sbaa__TestedVariable__r.sbaa__FilterField__c), 
                cond.sbaa__TestedVariable__r.sbaa__Operator__c, 
                cond.sbaa__TestedVariable__r.sbaa__FilterValue__c);
                //evaluate condition level filter
                evaluateResult = evaluateResult & ConditionsEvaluator.operate(
                ql.get(cond.sbaa__TestedVariable__r.sbaa__AggregateField__c.toString()), 
                cond.sbaa__Operator__c, 
                cond.sbaa__FilterValue__c);
            }
            if(evaluateResult) {
                break;
            }
        }
        if(evaluateResult) {
            applicableLines.add(ql);
        }
      }
      return applicableLines;
    }

    /**
    * @description : Get the approval rule and all fields to track with it's operator
    * @param ruleSmartConditions  : List of Approval Conditions to be evaluated.
    * @return
    */
    public static Map<Id, Map<String, String>> getRuleToFieldOperator(
      Map<Id, List<sbaa__ApprovalCondition__c>> ruleSmartConditions){
      Map<Id, Map<String, String>> ruleToFieldNameOperator = new Map<Id, Map<String, String>>();

      //Create Map for Field API name and it operator 
      for (Id ruleId : ruleSmartConditions.keySet()) {
        Map<String, String> fieldAPIToOpertor = new Map<String, String>(); 
        for(sbaa__ApprovalCondition__c condition : ruleSmartConditions.get(ruleId)) {
            if(!String.isBlank(condition.Track_Fields__c)) {
                if(condition.Track_Fields__c.contains(';')) {
                    String fieldName = '';
                    String operator = '';
                    for(String fieldApi : condition.Track_Fields__c.split(';')) {
                        fieldName = fieldApi.contains(':') 
                            ? fieldApi.substringBefore(':').trim()
                            : fieldApi;
                        operator = fieldApi.contains(':') 
                            ? fieldApi.substringAfter(':').trim()
                            : Constants.GREATER_THAN_OPERATOR;
                        fieldAPIToOpertor.put(fieldName, operator);
                    }
                }
            }
        }

        ruleToFieldNameOperator.put(ruleId, fieldAPIToOpertor);
      }
      return ruleToFieldNameOperator;
    }

    /**
    * @description : Update the In Queue Requests in a chain ==> perform this action in before update
    * @param rulesInChain
    * @param ruleSmartConditions
    * @return
    */
    public static List<sbaa__ApprovalRule__c> getRuleIndexes(List<Id> rulesInChain,
                                Map<Id, List<sbaa__ApprovalCondition__c>> ruleSmartConditions) {
      List<sbaa__ApprovalRule__c> approvalRules = new List<sbaa__ApprovalRule__c>();
      for(Id ruleId : ruleSmartConditions.keySet()) {
        if(!rulesInChain.isEmpty() && rulesInChain.contains(ruleId)) {
            Integer stepNumber = 
                !ruleSmartConditions.get(ruleId).isEmpty()
                ? Integer.valueOf(ruleSmartConditions.get(ruleId)[0].sbaa__ApprovalRule__r.sbaa__ApprovalStep__c)
                : 0;
            approvalRules.add(
                new sbaa__ApprovalRule__c(Id = ruleId, sbaa__ApprovalStep__c = stepNumber)
            );
        }
      }
      //Sort
      approvalRules = sortList(approvalRules);
      return approvalRules;
    }
    /**
    * @description : Sort Approval Rules based on ApprovalStep
    * @param approvalRules
    * @return
    */
    public static List<sbaa__ApprovalRule__c> sortList(List<sbaa__ApprovalRule__c> approvalRules) {
      for (Integer i = 0; i < approvalRules.size(); i++) {
        for (Integer j = i + 1; j < approvalRules.size(); j++) {

            Integer a = Integer.valueOf(approvalRules[i].sbaa__ApprovalStep__c);
            Integer b = Integer.valueOf(approvalRules[j].sbaa__ApprovalStep__c);

            if (a == null || b == null) continue;

            // swap if out of order
            if (a > b) {
                sbaa__ApprovalRule__c temp = approvalRules[i];
                approvalRules[i] = approvalRules[j];
                approvalRules[j] = temp;
            }
        }
      }
      return approvalRules;
    }

    /**
    * @description : Wrapper class for response
    */
    public class ResponseDetails {
        public Map<Id, List<sbaa__ApprovalCondition__c>> ruleSmartConditions; //rule to smart conditions
        public Map<Id, List<SBQQ__Quoteline__c>> ruleToApplicableLines;//rule to applicable quotelines
    }

}