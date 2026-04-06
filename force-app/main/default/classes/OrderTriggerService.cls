/******************************************************************************
 * @description       : RSC Instance Helper/Utility Class
 * @author            : Prashik
 * @last modified on  : 11-17-2025
 * @last modified by  : Prashik
 * Modifications Log
 * Ver   Date          Author        Modification
 * 1.0   11-17-2025    Prashik       Initial Version - FY26WL-117
 * 2.0   02-16-2025    Prashik       Updated logic for RSC Instance Creation - FY26WL-812
 ******************************************************************************/
public class OrderTriggerService {
  private static OrderInsertHelper helper = OrderInsertHelper.getInstance();
  public static List<RSCInstance__c> allInstances = new List<RSCInstance__c>();

  /**
   * @description This method handles the RSC Instnace Creation
   * @param newOrdList
   * @param oldMap
   */
  public static void handleRSCInstanceCreation(List<Order> newOrdList, Map<Id, Order> oldMap) {
    Set<String> allSuggestedUrls = new Set<String>();
    Map<Id, Opportunity> opptyForInstanceCreation = new Map<Id, Opportunity>();
    Map<Id, POC__c> pocForInstanceCreation = new Map<Id, POC__c>();
    Map<Id, List<Order>> ordersBySourceRecordId = new Map<Id, List<Order>>();

    for (Order newOrd : newOrdList) {
      Order oldOrd = oldMap?.get(newOrd.id);
      if (newOrd.Send_for_Polaris_Fulfilment__c && newOrd.Send_for_Polaris_Fulfilment__c != oldOrd.Send_for_Polaris_Fulfilment__c) {
        if (newOrd.POC_Request__c != null) {
          POC__c poc = helper.pocRequestById != null ? helper.pocRequestById.get(newOrd.POC_Request__c) : null;
          if (poc != null && poc.RSCInstance__c == null) {
            pocForInstanceCreation.put(newOrd.POC_Request__c, poc);
            if (!ordersBySourceRecordId.containsKey(newOrd.POC_Request__c)) {
              ordersBySourceRecordId.put(newOrd.POC_Request__c, new List<Order>());
            }
            ordersBySourceRecordId.get(newOrd.POC_Request__c).add(newOrd);
            if (String.isNotBlank(poc.RscSuggestedUrl__c)) {
              allSuggestedUrls.add(poc.RscSuggestedUrl__c);
            }
          }
        } else {
          Opportunity relatedOpp = helper.oppMap != null ? helper.oppMap.get(newOrd.OpportunityId) : null;
          if (relatedOpp != null && !isSharedDeal(relatedOpp)) {
            opptyForInstanceCreation.put(newOrd.OpportunityId, relatedOpp);
            if (!ordersBySourceRecordId.containsKey(relatedOpp.Id)) {
              ordersBySourceRecordId.put(relatedOpp.Id, new List<Order>());
            }
            ordersBySourceRecordId.get(relatedOpp.Id).add(newOrd);

            if (String.isNotBlank(relatedOpp.SuggestedURL__c)) {
              allSuggestedUrls.add(relatedOpp.SuggestedURL__c);
            }
          }
        }
      }
    }

    if (!opptyForInstanceCreation.isEmpty() || !pocForInstanceCreation.isEmpty()) {
      dedupeAndInsertRSCInstance(allSuggestedUrls, opptyForInstanceCreation, pocForInstanceCreation, ordersBySourceRecordId);
    }
  }

  /**
   * @description This method handles RSC instance creation with deduplication
   * @param allSuggestedUrls
   * @param opptyForInstanceCreation
   * @param pocForInstanceCreation
   * @param ordersBySourceRecordId
   */
  public static void dedupeAndInsertRSCInstance(
    Set<String> allSuggestedUrls,
    Map<Id, Opportunity> opptyForInstanceCreation,
    Map<Id, POC__c> pocForInstanceCreation,
    Map<Id, List<Order>> ordersBySourceRecordId
  ) {
    Set<Id> oppAccountIds = new Set<Id>();
    Set<Id> oppEndUserIds = new Set<Id>();
	  Map<Id, Boolean> accountHasPrimaryProduction = new Map<Id, Boolean>();
    Map<Id, Boolean> accountHasPrimaryPoC = new Map<Id, Boolean>();

    for (Opportunity opp : opptyForInstanceCreation.values()) {
      oppAccountIds.add(opp.AccountId);
      if (opp.MSP_End_User_Lookup__c != null && String.isBlank(opp.SuggestedURL__c)) {
        oppEndUserIds.add(opp.MSP_End_User_Lookup__c);
      }
      if (String.isBlank(opp.SuggestedURL__c)) {
        accountHasPrimaryProduction.put(opp.AccountId,false);
      }
    }
    for (POC__c poc : pocForInstanceCreation.values()) {
      if (String.isBlank(poc.RscSuggestedUrl__c) && poc.Opportunity__r != null) {
          accountHasPrimaryPoC.put(poc.Opportunity__r.AccountId,false);
      }
    }

    if (allInstances.isEmpty()) {
      allInstances = [
        SELECT Id, RSCSuggestedURL__c, AccountId__c, RSCURL__c, SDPEndUser__c, RSCAccountType__c, RSCAccountRelationship__c, Status__c
        FROM RSCInstance__c
        WHERE
          (RSCSuggestedURL__c IN :allSuggestedUrls
          OR RSCURL__c IN :allSuggestedUrls
          OR (AccountId__c IN :oppAccountIds
          AND SDPEndUser__c IN :oppEndUserIds)
          OR (AccountId__c IN :accountHasPrimaryProduction.keySet()
          AND RSCAccountType__c = :Constants.RSCINSTANCE_ACCOUNT_TYPE_PROD
          AND RSCAccountRelationship__c = :Constants.RSCINSTANCE_ACCOUNT_RELATIONSHIP_PRIMARY)
          OR (AccountId__c IN :accountHasPrimaryPoC.keySet()
          AND RSCAccountType__c = :Constants.RSCINSTANCE_ACCOUNT_TYPE_POC
          AND RSCAccountRelationship__c = :Constants.RSCINSTANCE_ACCOUNT_RELATIONSHIP_PRIMARY))
          AND Status__c NOT IN :Constants.RSCINSTANCE_DELETED_STATUS_LIST
        ORDER BY CreatedDate DESC
      ];
    }

    Set<String> activeRSCURLs = new Set<String>();
    Map<String, RSCInstance__c> activeInstanceByAcctAndEndUser = new Map<String, RSCInstance__c>();

    for (RSCInstance__c inst : allInstances) {
      boolean isActive = !Constants.RSCINSTANCE_DELETED_STATUS_LIST.contains(inst.Status__c);
      String key = inst.AccountId__c + ':' + inst.SDPEndUser__c;
      activeInstanceByAcctAndEndUser.put(key, inst);

      if (isActive) {
        // Add to active URLs
        if (String.isNotBlank(inst.RSCSuggestedURL__c)){
          activeRSCURLs.add(inst.RSCSuggestedURL__c);
        }
        if (String.isNotBlank(inst.RSCURL__c)){
          activeRSCURLs.add(inst.RSCURL__c);
        }
      }

      if (isActive &&
          inst.RSCAccountType__c == Constants.RSCINSTANCE_ACCOUNT_TYPE_PROD &&
          inst.RSCAccountRelationship__c == Constants.RSCINSTANCE_ACCOUNT_RELATIONSHIP_PRIMARY) {
          accountHasPrimaryProduction.put(inst.AccountId__c, true);
      }

      if (isActive &&
          inst.RSCAccountType__c == Constants.RSCINSTANCE_ACCOUNT_TYPE_POC &&
          inst.RSCAccountRelationship__c == Constants.RSCINSTANCE_ACCOUNT_RELATIONSHIP_PRIMARY) {
          accountHasPrimaryPoC.put(inst.AccountId__c, true);
      }
    }
    // Create new instances
    List<RSCInstance__c> newInstances = new List<RSCInstance__c>();
    List<Id> sourceIdList = new List<Id>();
    Map<Id, RscInstance__c> rscInstanceByPOCId = new Map<Id, RscInstance__c>();
    // Process Opportunity-based instances
    for (Opportunity opp : opptyForInstanceCreation.values()) {
      Boolean shouldCreateOppRSCInstance = false;
      String logMessage = '';
      if (String.isNotBlank(opp.SuggestedURL__c)) {
          shouldCreateOppRSCInstance = !activeRSCURLs.contains(opp.SuggestedURL__c);
          if(!shouldCreateOppRSCInstance){
              logMessage = 'Duplicate Instance Exists for RSCSuggested URL';
          }
      } else if (isDedicatedDeal(opp) && String.isNotBlank(opp.MSP_End_User_Lookup__r?.Website)) {
          String key = opp.AccountId + ':' + opp.MSP_End_User_Lookup__c;
          shouldCreateOppRSCInstance = !activeInstanceByAcctAndEndUser.containsKey(key);
      } else if (String.isBlank(opp.SuggestedURL__c)) {
          shouldCreateOppRSCInstance = accountHasPrimaryProduction.containsKey(opp.AccountId) && !accountHasPrimaryProduction.get(opp.AccountId) ;
      }

      if (shouldCreateOppRSCInstance) {
        RSCInstance__c newInstance = createRSCInstanceFromOpportunity(opp);

        if (newInstance != null) {
          newInstances.add(newInstance);
          sourceIdList.add(opp.Id);
        }
      } else if (String.isNotBlank(logMessage)) {
          List<Order> relatedOrders = ordersBySourceRecordId.get(opp.Id);
          if (relatedOrders != null) {
              for (Order ord : relatedOrders) {
                createRSCLog(ord, logMessage);
              }
          }
      }
    }

    // Process POC-based instances
    for (POC__c poc : pocForInstanceCreation.values()) {
      Boolean createPocInstance = false;
      String logMessage = '';
      if (String.isNotBlank(poc.RscSuggestedUrl__c)) {
          createPocInstance = !activeRSCURLs.contains(poc.RscSuggestedUrl__c);
          if (!createPocInstance) {
              logMessage = 'Duplicate Instance Exists for RSCSuggested URL';
          }
      } else {
          Id accountId = poc.Opportunity__r?.AccountId;
          createPocInstance = (accountId != null && accountHasPrimaryPoC.containsKey(accountId) && !accountHasPrimaryPoC.get(accountId));
      }

      if (createPocInstance) {
        RSCInstance__c newInstance = createRSCInstanceFromPOC(poc);
        if (newInstance != null) {
          newInstances.add(newInstance);
          sourceIdList.add(poc.Id);
          rscInstanceByPOCId.put(poc.Id, newInstance);
        }
      } else if (String.isNotBlank(logMessage)) {
        List<Order> relatedOrders = ordersBySourceRecordId.get(poc.Id);
        if (relatedOrders != null) {
          for (Order ord : relatedOrders) {
            createRSCLog(ord, logMessage);
          }
        }
      }
    }

    // Insert and handle errors
    if (!newInstances.isEmpty()) {
      List<Database.SaveResult> instanceInsertResults = Database.insert(newInstances, false);

      for (Integer i = 0; i < instanceInsertResults.size(); i++) {
        Database.SaveResult sr = instanceInsertResults[i];
        String message = 'Success';
        if (!sr.isSuccess()) {
          List<Database.Error> errors = sr.getErrors();
          message = 'RSCInstanceException: ' + (errors.isEmpty() ? 'Unknown error occurred' : errors[0].getMessage());
        }
        List<Order> relatedOrders = ordersBySourceRecordId.get(sourceIdList[i]);
        for (Order ord : relatedOrders) {
          createRSCLog(ord, message);
        }
      }

      if (!rscInstanceByPOCId.isEmpty()) {
        List<POC__C> pocToUpdate = new List<POC__C>();
        for (Id pocId : rscInstanceByPOCId.keySet()) {
          if (String.isNotBlank(rscInstanceByPOCId.get(pocId).Id)) {
            pocToUpdate.add(new POC__c(Id = pocId, RscInstance__c = rscInstanceByPOCId.get(pocId).Id));
          }
        }
        FlowControll.POCRequestTriggerHandler = false;
        update pocToUpdate;
        FlowControll.POCRequestTriggerHandler = true;
      }
    }
  }

  /**
   * @description  RSC instance record creation from POC Request
   * @param poc
   * @return RSCInstance__c
   */
  public static RSCInstance__c createRSCInstanceFromPOC(POC__c poc) {
    RSCInstance__c newRSCI = new RSCInstance__c();
    newRSCI.Status__c = Constants.RSCINSTANCE_STATUS_PENDING_CREATION;
    newRSCI.AccountId__c = poc.Opportunity__r.AccountId;
    newRSCI.RSCOwnerEmail__c = String.isBlank(poc.Polaris_Contact__r?.Email) ? poc.Opportunity__r?.Polaris_Portal_Contact__r?.Email : poc.Polaris_Contact__r?.Email;
    newRSCI.RSCAccountType__c = poc.RSCAccountType__c;
    newRSCI.RSCSuggestedURL__c = String.isNotBlank(poc.RscSuggestedUrl__c) ? poc.RscSuggestedUrl__c : '';
    newRSCI.RSCAccountName__c = poc.Account_Name__c;
    newRSCI.RSCAccountRelationship__c = poc.Opportunity__r.Opportunity_Type__c != Constants.OPP_TYPE
      ? Constants.RSCINSTANCE_ACCOUNT_RELATIONSHIP_PRIMARY
      : Constants.RSCINSTANCE_ACCOUNT_RELATIONSHIP_CHILD;
    newRSCI.RSCRegion__c = poc.Polaris_Region__c;
    return newRSCI;
  }

  /**
   * @description  RSC instance record creation from Opportunity
   * @param oppty
   * @return RSCInstance__c
   */
  public static RSCInstance__c createRSCInstanceFromOpportunity(Opportunity oppty) {
    RSCInstance__c newRSCI = new RSCInstance__c();
    newRSCI.RSCSuggestedURL__c = String.isNotBlank(oppty.SuggestedURL__c) ? oppty.SuggestedURL__c : '';
    newRSCI.AccountId__c = oppty.AccountId;
    newRSCI.RSCAccountName__c = oppty.MSP_End_User_Lookup__c != null ? oppty.MSP_End_User_Lookup__r.Name : oppty?.Account.Name;
    newRSCI.RSCOwnerEmail__c = oppty.Polaris_Portal_Contact__r?.Email;
    newRSCI.SDPEndUser__c = oppty.MSP_End_User_Lookup__c;
    newRSCI.SDPEndUserDomain__c = getDomainFromUrl(oppty.MSP_End_User_Lookup__r?.Website);
    newRSCI.RSCAccountType__c = Constants.RSCINSTANCE_ACCOUNT_TYPE_PROD;
    newRSCI.Status__c = Constants.RSCINSTANCE_STATUS_PENDING_CREATION;
    newRSCI.RSCRegion__c = oppty.Polaris_Region__c;
    newRSCI.RSCAccountRelationship__c = String.isNotBlank(oppty.Managed_Services_Deal_type__c)
      ? Constants.RSCINSTANCE_ACCOUNT_RELATIONSHIP_CHILD
      : Constants.RSCINSTANCE_ACCOUNT_RELATIONSHIP_PRIMARY;
    newRSCI.ContractType__c = oppty.Managed_Services_Deal_type__c == Constants.OPP_MSP_DEAL_TYPE_DEDICATED_DEAL
      ? Constants.RSCINSTANCE_CONTRACT_TYPE_DEDICATED
      : oppty.Managed_Services_Deal_type__c == Constants.OPP_MSP_DEAL_TYPE_SHARED_SERVICES ? Constants.RSCINSTANCE_CONTRACT_TYPE_SHARED : null;
    return newRSCI;
  }

  /**
   * @description This is a helper method to check if opportunity is dedicated deal
   * @param opp
   * @return Boolean
   */
  private static Boolean isDedicatedDeal(Opportunity opp) {
    return opp.Managed_Services_Deal_type__c == Constants.OPP_MSP_DEAL_TYPE_DEDICATED_DEAL && opp.MSP_End_User_Lookup__c != null;
  }

  /**
   * @description This is a helper method to check if opportunity is shared services deal
   * @param opp
   * @return Boolean
   */
  private static Boolean isSharedDeal(Opportunity opp) {
    return opp.Managed_Services_Deal_type__c == Constants.OPP_MSP_DEAL_TYPE_SHARED_SERVICES;
  }

  /**
   * @description This method cleans the url and returns the Domain
   * @param urlString
   * @return String
   */
  public static String getDomainFromUrl(String urlString) {
    if (String.isBlank(urlString)) {
      return null;
    }

    String regex = '(?i)^(?:https?://)?(?:www\\.)?([^/]+)';
    String domainWithPortAndPath = '';
    Pattern p = Pattern.compile(regex);
    Matcher m = p.matcher(urlString);

    if (m.find() && m.group(1) != null) {
      domainWithPortAndPath = m.group(1);

      Integer portIndex = domainWithPortAndPath.indexOf(':');
      if (portIndex > -1) {
        domainWithPortAndPath = domainWithPortAndPath.substring(0, portIndex);
      }
    }

    return domainWithPortAndPath;
  }

  /**
   * @description Creates an Error_Logs__c record for RSC Instance Creation.
   * @param ord  The Order being processed
   * @param message The error/success message to store
   */
  private static void createRSCLog(Order ord, String message) {
    Error_Logs__c log = new Error_Logs__c(
      Account__c = ord.AccountId,
      Order_Id__c = ord.Id,
      Related_Order__c = ord.Id,
      Class__c = 'OrderTriggerService',
      Type__c = 'SFDC',
      Method__c = 'handleRSCInstanceCreation',
      Object__c = 'RSCInstance__c',
      Error_Type__c = 'RSC Instance Creation',
      Error_Message__c = message
    );
    OrderHandler.lstErrorLogs.add(log);
  }
}