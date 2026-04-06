public class GTC_ScreenAccountsBatch implements Database.Batchable<sObject>, Database.Stateful, System.Schedulable {
  public static Date beforeOneYear = System.today().addYears(-1);
  public static integer batchSize = 500;
  public Database.QueryLocator start(Database.BatchableContext BC) {
    String query = 'Select id,Name,Account_Screening__c,Account_Screening__r.Screening_Eligibility__c,(Select id,MSP_End_User_Lookup__c from Entitlements where MSP_End_User_Lookup__c != null) from Account where ';
    String accountsWithEntitlementClause = 'Entitlement_Count__c>0';
    string accountScreeningClause = ' Account_Screening__r.Screening_Eligibility__c = true';
    query = query + accountsWithEntitlementClause + ' OR ' + accountScreeningClause;
    System.debug(JSON.Serialize(query));
    return Database.getQueryLocator(query);
  }

  public void execute(SchedulableContext SC) {
    Database.executeBatch(new GTC_ScreenAccountsBatch(), batchSize);
  }
  public void execute(Database.BatchableContext BC, List<Account> accounts) {
    Map<Id, Account_Screening__c> accountScreeningsTobeUpdated = new Map<Id, Account_Screening__c>();
    Map<Id, Account_Screening__c> accountScreeningsTobeInserted = new Map<Id, Account_Screening__c>();
    List<Database.SaveResult> saveResults = new List<Database.SaveResult>();
    List<Account> accountstoBeupdated = new List<Account>();
    List<Batch_Error_Log__c> errorsToInsert = new List<Batch_Error_Log__c>();
    List<Id> chunkedAccountIds = new List<id>();
    Map<Id, Id> sdpIdToParentAccId = new Map<Id, Id>();
    Map<Id, Set<Id>> mainAccToSdpAccIds = new Map<Id, Set<Id>>();
    for (Account acc : accounts) {
      chunkedAccountIds.add(acc.id);
      for (Entitlement ent : acc.Entitlements) {
        if (ent.MSP_End_User_Lookup__c != null) {
          sdpIdToParentAccId.put(ent.MSP_End_User_Lookup__c, acc.Id);
          if (!mainAccToSdpAccIds.containskey(acc.id)) {
            mainAccToSdpAccIds.put(acc.id, new Set<Id>());
          }
          mainAccToSdpAccIds.get(acc.id).add(ent.MSP_End_User_Lookup__c);
        }
      }
    }
    Date last365Days = Date.today().addYears(-1);

    List<String> selectedEntitlementTypes = Order_control__mdt.getInstance('GTC_Account_Screening_Entitlement_Types').value__c.Split(',');
    Map<Id, Account> accountRecords = new Map<Id, Account>(
      [
      SELECT
        Id,
        Account_Screening__c,
        Name,
        Account_Screening__r.Screening_Eligibility__c,
        (SELECT Id, Name FROM Entitlements WHERE StartDate < TODAY AND EndDate >= :last365Days AND (Type IN :selectedEntitlementTypes OR Entitlement_Subtype__c = 'Free Trial')),
        (SELECT id FROM Account_Screenings__r)
      FROM Account
      WHERE Id IN :chunkedAccountIds OR Id IN :sdpIdToParentAccId.KeySet()
      ]
    );

    Set<Id> eligibleSdpAccIds = new Set<Id>();
    Map<Id, String> mainAccToScrEligibility = new Map<Id, String>();
    // Main Account Processing
    for (Account eachAccount : accountRecords.values()) {
      String scrEligibility = null;
      if (!chunkedAccountIds.contains(eachAccount.id)) {
        continue;
      }
      if (mainAccToSdpAccIds.containskey(eachAccount.id)) {
        eligibleSdpAccIds.addall(mainAccToSdpAccIds.get(eachAccount.id));
      }
      if (eachAccount.Entitlements.size() > 0 && eachAccount.Account_Screening__c != null && !eachAccount.Account_Screening__r.Screening_Eligibility__c) {
        prepareExistingScreeningUpdate(eachAccount, accountScreeningsTobeUpdated, true, 'Start');
        scrEligibility = 'Start';
      } else if (
        eachAccount.Entitlements.size() > 0 &&
        eachAccount.Account_Screening__c == null &&
        eachAccount.Account_Screenings__r.size() == 0 &&
        !accountScreeningsTobeInserted.containskey(eachAccount.id)
      ) {
        prepareScreeningToInsert(eachAccount, accountScreeningsTobeInserted);
        scrEligibility = 'New';
      } else if (eachAccount.Entitlements.size() == 0 && eachAccount.Account_Screening__c != null && eachAccount.Account_Screening__r.Screening_Eligibility__c) {
        prepareExistingScreeningUpdate(eachAccount, accountScreeningsTobeUpdated, false, 'Stop');
        scrEligibility = 'Stop';
      }
      mainAccToScrEligibility.put(eachAccount.id, scrEligibility);
    }
    // SDP End User processing only if Main Account Is eligible.
    // Additional requirement:
    // Only STOP a child SDP account when its parent Account_Screening__r.Screening_Eligibility__c is 'Stop' (false).
    for (Account eachAccount : accountRecords.values()) {
      if (sdpIdToParentAccId.containskey(eachAccount.id) && eligibleSdpAccIds.contains(eachAccount.id)) {
        //if SDP Account also exists as  Main Account
        Boolean skipExecution = false;
        if (mainAccToScrEligibility.containskey(eachAccount.id)) {
          String scrEligibility = mainAccToScrEligibility.get(eachAccount.id);
          skipExecution = scrEligibility == 'Start' || scrEligibility == 'New';
        }
        if (skipExecution) {
          continue;
        } //skip execution if the same account validated as a main account.
        // Resolve parent account for this SDP child
        Id parentAccId = sdpIdToParentAccId.get(eachAccount.id);
        // Account parentAcc = accountRecords.get(parentAccId);
        // Default parent eligibility to null when unknown
        String parAccEligibility = mainAccToScrEligibility.containskey(parentAccId) ? mainAccToScrEligibility.get(parentAccId) : null;

        if (
          (parAccEligibility == 'Start' ||
          parAccEligibility == 'New') &&
          eachAccount.Account_Screening__c != null &&
          !eachAccount.Account_Screening__r.Screening_Eligibility__c
        ) {
          // Child currently ineligible -> request Start as before
          prepareExistingScreeningUpdate(eachAccount, accountScreeningsTobeUpdated, true, 'Start');
        } else if (eachAccount.Account_Screening__c == null && eachAccount.Account_Screenings__r.size() == 0 && !accountScreeningsTobeInserted.containskey(eachAccount.id)) {
          prepareScreeningToInsert(eachAccount, accountScreeningsTobeInserted);
        } else if (parAccEligibility == 'Stop' && eachAccount.Account_Screening__c != null && eachAccount.Account_Screening__r.Screening_Eligibility__c) {
          prepareExistingScreeningUpdate(eachAccount, accountScreeningsTobeUpdated, false, 'Stop');
        }
      }
    }
    if (!accountScreeningsTobeInserted.values().isEmpty()) {
      saveResults.addAll(Database.Insert(accountScreeningsTobeInserted.values(), false));
    }

    for (Account_Screening__c accscr : accountScreeningsTobeInserted.values()) {
      Account acc = new Account();
      acc.Account_Screening__c = accscr.id;
      acc.id = accscr.Account__c;
      accountstoBeupdated.add(acc);
    }
    if (accountstoBeupdated.size() > 0) {
      FlowControll.accountTrigger = false;
      saveResults.addAll(Database.Update(accountstoBeupdated, false));
    }

    if (!accountScreeningsTobeUpdated.values().isEmpty()) {
      saveResults.addAll(Database.update(accountScreeningsTobeUpdated.values(), false));
    }

    for (Database.SaveResult sr : saveResults) {
      if (!sr.isSuccess() || Test.isRunningTest()) {
        errorsToInsert.add(
          new Batch_Error_Log__c(
            Class_Name__c = 'GTC_ScreenAccountsBatch',
            Failure_Job_ID__c = BC.getJobId(),
            Failure_Message__c = String.valueOf(sr.getErrors()),
            Object_ID__c = sr.getId(),
            Failure_Date__c = Date.today()
          )
        );
      }
    }

    if (errorsToInsert.size() > 0 && Schema.SobjectType.Batch_Error_Log__c.isCreateable()) {
      Database.Insert(errorsToInsert, false);
    }
  }
  public void finish(Database.BatchableContext BC) {
  }
  /**
   * Prepares an existing Account_Screening__c record for update.
   * Updates eligibility, action, and status fields and adds the record
   * to the provided update list.
   *
   * @param eachAccount                  The Account whose screening record will be updated
   * @param accountScreeningsTobeUpdated The map to which the updated screening record is added
   * @param eligibilityFlag              Indicates whether the account is eligible (true/false)
   * @param actionType                   The screening action (e.g., 'Start', 'Stop')
   */
  private void prepareExistingScreeningUpdate(Account eachAccount, Map<Id, Account_Screening__c> accountScreeningsTobeUpdated, Boolean eligibilityFlag, String actionType) {
    Account_Screening__c acctscr = accountScreeningsTobeUpdated != null && accountScreeningsTobeUpdated.containskey(eachAccount.id)
      ? accountScreeningsTobeUpdated.get(eachAccount.id)
      : new Account_Screening__c();
    acctscr.Id = eachAccount.Account_Screening__c;
    acctscr.Screening_Eligibility__c = eligibilityFlag;
    acctscr.Screening_Action__c = actionType;
    acctscr.Screening_Action_Status__c = 'Ready';
    accountScreeningsTobeUpdated.put(eachAccount.Id, acctscr);
  }
  /**
   * Creates a new Account_Screening__c record for an Account and
   * prepares it to be inserted. Sets default values such as eligibility,
   * action, status, parent references, and adds it to the insert list.
   *
   * @param eachAccount                  The Account for which a new screening record is created
   * @param accountScreeningsTobeInserted The Map to which the new screening record is added
   */
  private void prepareScreeningToInsert(Account eachAccount, Map<Id, Account_Screening__c> accountScreeningsTobeInserted) {
    Account_Screening__c acctscr = new Account_Screening__c();
    acctscr.Name = eachAccount.Name;
    acctscr.Screening_Eligibility__c = true;
    acctscr.Screening_Action__c = 'Start';
    acctscr.Screening_Action_Status__c = 'Ready';
    acctscr.Account__c = eachAccount.Id;
    acctscr.Unique_Parent_Id__c = eachAccount.Id;
    accountScreeningsTobeInserted.put(eachAccount.id, acctscr);
  }
}