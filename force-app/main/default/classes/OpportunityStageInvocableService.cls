/*******************************************************************************
 * @description       : OpportunityStageInvocableService Class Used
 * to handle all the processes When Opportunity Moved to Stage 6
 *
 *******************************************************************************
 */
public class OpportunityStageInvocableService {
  @InvocableMethod(label='Update Opportunity Stage to 6')
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description Processing When Opportunity is set to Stage 6.
   * @param records
   */
  public static void updateOpportunityStage(List<FlowInputs> records) {
    Set<Id> errorLogIds = extractErrorLogIds(records);
    if (errorLogIds.isEmpty())
      return;
    Map<Id, List<PO_Stage_Errors__c>> oppIdToErrors = fetchErrorsGroupedByOpportunity(errorLogIds);
    if (oppIdToErrors.isEmpty())
      return;
    // Process errors → decide Opp updates or error log updates
    List<Opportunity> oppsToUpdate = new List<Opportunity>();
    Map<Id, PO_Stage_Errors__c> errorUpdates = new Map<Id, PO_Stage_Errors__c>();
    prepareUpdates(oppIdToErrors, oppsToUpdate, errorUpdates);
    // Update Opportunities
    List<Database.SaveResult> results = updateOpportunities(oppsToUpdate);
    // Build error updates based on success/failure
    processOpportunityUpdateResults(oppsToUpdate, results, oppIdToErrors, errorUpdates);
    // Update error logs
    if (!errorUpdates.isEmpty()) {
      update errorUpdates.values();
    }
  }

  /**
   * @author Prashant Kumar
   * @description Getting Error Ids for INT-02 sent from Flow.
   * @param records
   * @return Set<Id>
   */
  private static Set<Id> extractErrorLogIds(List<FlowInputs> records) {
    Set<Id> errorLogIds = new Set<Id>();
    for (FlowInputs input : records) {
      if (input.stageErrorRec != null) {
        errorLogIds.add(input.stageErrorRec.Id);
      }
    }
    return errorLogIds;
  }
  /**
   * @author Prashant Kumar
   * @description Set map in which one Oppty and INT-02 error per opportunity.
   * @param errorLogIds
   * @return Map<Id, List<PO_Stage_Errors__c>>
   */
  private static Map<Id, List<PO_Stage_Errors__c>> fetchErrorsGroupedByOpportunity(Set<Id> errorLogIds) {
    Map<Id, List<PO_Stage_Errors__c>> oppIdToErrors = new Map<Id, List<PO_Stage_Errors__c>>();
    for (PO_Stage_Errors__c err : [
      SELECT Id, Error_Message__c, Opportunity_Update_Status__c, Opportunity_Update_Message__c,Quote__c, Opportunity__c,Opportunity__r.Opportunity_Sub_Type__c , Opportunity__r.Renewals_Forecast_Risk__c, Opportunity__r.StageName, PO_Stage_Id__r.Opportunity__c, Quote__r.SBQQ__Uncalculated__c
      FROM PO_Stage_Errors__c
      WHERE Id IN :errorLogIds  AND Opportunity__c != NULL AND Quote__c != NULL
    ]) {
      Id oppId = err.Opportunity__c;
      if (!oppIdToErrors.containskey(oppId))
        oppIdToErrors.put(oppId, new List<PO_Stage_Errors__c>());
      oppIdToErrors.get(oppId).add(err);
    }
    return oppIdToErrors;
  }
  /**
   * @author Prashant Kumar
   * @description Processing in which opportunity is set to stage Six
   * @param oppIdToErrors
   * @param oppsToUpdate
   * @param errorUpdates
   */
  private static void prepareUpdates(Map<Id, List<PO_Stage_Errors__c>> oppIdToErrors, List<Opportunity> oppsToUpdate, Map<Id, PO_Stage_Errors__c> errorUpdates) {
    for (Id oppId : oppIdToErrors.keySet()) {
      PO_Stage_Errors__c err = oppIdToErrors.get(oppId)[0];
      Boolean quoteUncalculated = err.Quote__r.SBQQ__Uncalculated__c == true;
      // Quote uncalculated → mark error only
      if (quoteUncalculated) {
        errorUpdates.put(
          oppId,
          new PO_Stage_Errors__c(
            Id = err.Id,
            Opportunity_Update_Status__c = constants.OPPORTUNITY_FOR_UNCALCULATEONQUOTE_STATUS,
            Opportunity_Update_Message__c = constants.QUOTE_UPDATED_FAILED_MESSAGE
          )
        );
        continue;
      }
      // Valid → update the Opportunity stage
      if(err?.Opportunity__r?.Opportunity_Sub_Type__c == 'Renewal' &&
        err?.Opportunity__r?.Renewals_Forecast_Risk__c == 'Subscription'  &&
        !constants.VALID_OPPTY_STAGES.contains(err?.Opportunity__r?.StageName)){
          oppsToUpdate.add(new Opportunity(Id = oppId, StageName = constants.ON_DEMAND_OPPORTUINITY_STAGENAME));
        }
      }
  }
  /**
   * @author Prashant Kumar
   * @description Processing in which opportunity is set to stage Six
   * @param oppsToUpdate
   * @return List<Database.SaveResult>
   */
  private static List<Database.SaveResult> updateOpportunities(List<Opportunity> oppsToUpdate) {
    if (oppsToUpdate.isEmpty()) {
      return new List<Database.SaveResult>();
    }
    return Database.update(oppsToUpdate, false);
  }
  /**
   * @author Prashant Kumar
   * @description Updating Details on INT-02 Record on Success and Failure of Opportunity.
   * @param oppsToUpdate
   * @param results
   * @param oppIdToErrors
   * @param errorUpdates
   */
  private static void processOpportunityUpdateResults(
    List<Opportunity> oppsToUpdate,
    List<Database.SaveResult> results,
    Map<Id, List<PO_Stage_Errors__c>> oppIdToErrors,
    Map<Id, PO_Stage_Errors__c> errorUpdates
  ) {
    for (Integer i = 0; i < results.size(); i++) {
      Opportunity opp = oppsToUpdate[i];
      Database.SaveResult sr = results[i];
      PO_Stage_Errors__c err = oppIdToErrors.get(opp.Id)[0];
      PO_Stage_Errors__c updateErr = new PO_Stage_Errors__c(Id = err.Id);
      if (sr.isSuccess()) {
        updateErr.Opportunity_Update_Status__c = constants.OPPORTUNITY_SUCCESS_STATUS;
        updateErr.Opportunity_Update_Message__c = constants.OPPORTUNITY_SUCCESS_MESSAGE;
      } else {
        updateErr.Opportunity_Update_Status__c = constants.OPPORTUNITY_FOR_UNCALCULATEONQUOTE_STATUS;
        updateErr.Opportunity_Update_Message__c = sr.getErrors()[0].getMessage();
      }
      errorUpdates.put(opp.Id, updateErr);
    }
  }
  /*******************************************************************************
   * @description       : Variable defined for PO_Stage_Errors__c object.
   *
   *******************************************************************************
   */ public class FlowInputs {
    @InvocableVariable
    public PO_Stage_Errors__c stageErrorRec;
  }
}