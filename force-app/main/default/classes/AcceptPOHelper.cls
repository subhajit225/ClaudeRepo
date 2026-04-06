/*******************************************************************************
 * @description       : Helper for auto-accept PO functionality
 * @author            : moises, moises.contreras@rubrik.com
 * @group             : Stage PO Validations
 * @last modified on  : 05-10-2022
 * @last modified by  : Moises Nunez moises.contreras@rubrik.com
 * *****************************************************************************
 * History
 * Date                Modification           Author
 * 05-10-2022          PRDOPS23-93            moises.contreras@rubrik.com
 *******************************************************************************
 */
public with sharing class AcceptPOHelper {
  /**
   * @author Prashant Kumar
   * @date 20-08-2025
   * @description AutoAccept Method Calling When Opportunity is Moved to Stage 6
   * @param oldOppMap
   * @param newOppMap
   * @param oppEligibleIds
   */
  public static void autoAcceptPO(Map<id, Opportunity> oldOppMap, Map<id, Opportunity> newOppMap, set<id> oppEligibleIds) {
    Set<Id> oppEligible = new Set<Id>();
    if (newOppMap != null && oppEligibleIds == null) {
      for (Opportunity opp : newOppMap.values()) {
        if (opp.StageName != oldOppMap.get(opp.Id).StageName && opp.StageName == '6 PO With Channel')
          oppEligible.add(opp.Id);
      }
    } else {
      oppEligible = oppEligibleIds;
    }
    if (oppEligible.size() <= 10 && oppEligible.size() > 0) {
      List<CreateOrder__e> orderevtList = new List<CreateOrder__e>();
      for (Id oppId : oppEligible) {
        orderevtList.add(new CreateOrder__e(RecordId__c = oppId, Auto_Submit_Order__c = true));
      }
      try {
        if (!orderevtList.isEmpty())
          EventBus.publish(orderevtList);
      } catch (Exception error) {
                System.debug(LoggingLevel.DEBUG, 'Error>>' + error.getMessage());
                createErrorLogs(error.getMessage(), error.getLineNumber(), oppEligible);
      }
    }
  }
  /**
   * @author Siva Kumar
   * @date 12-22-2025
   * @description method to capture error logs
   * @param errorMsg
   * @param errorLine
   * @param oppEligible
   */
    public static void createErrorLogs(String errorMsg, Integer errorLine, set<Id> oppEligible){
        insert new Custom_Error_Log__c(
          Functionality__c = 'CreateOrder__e creation',
          Exception_Message__c =  errorMsg + ' at line no. ' + errorLine,
          FailedRecords__c = String.valueOf(oppEligible),
          Class__c = 'AcceptPOHelper'
        );
    }
    /**
   * @author Prashant Kumar
   * @date 20-08-2025
   * @description AutoSubmission Of Stage PO When Moving Opportunity to Stage6
   * @param oppId
   */
  public static void autoPoSubmission(Id oppId) {
    PO_Stage__c po;
    try {
      po = [
        SELECT
          Id,
          Name,
          Account_Name__c,
          Bill_To_Name_Str__c,
          EDI_DISTI_ID__c,
          End_User_PO__c,
          Expected_number_of_POs__c,
          partner_name__c,
          ShippingCountryCode__c,
          ShippingPostalCode__c,
          ShippingState__c,
          ShippingStateCode__c,
          ShippingStreet__c,
          TotalAmount__c,
          Note_on_Contingency_and_Special_Language__c,
          Payment_Terms__c,
          PO_Internal_Validation_Status__c,
          PO_Validation_Status__c,
          Ship_To_Phone_Number__c,
          Shipping_Account_Number__c,
          Shipping_Carrier__c,
          Shipping_Method__c,
          ShippingCity__c,
          ShippingCountry__c,
          PoDate__c,
          PoNumber__c,
          Quote__c,
          Quote_number__c,
          Service_Level__c,
          Ship_to_Account_Name__c,
          Ship_To_Contact_Name__c,
          Ship_to_Email__c,
          Customer_Requested_Ship_Date__c,
          Bill_To_Name__c,
          Bill_To_Name__r.Payment_Term__c,
          ContractManufacturer__c
        FROM PO_Stage__c
        WHERE Quote__r.SBQQ__Opportunity2__c = :oppId AND PO_Validation_Status__c LIKE 'Success%'
        ORDER BY CreatedDate DESC
        LIMIT 1
      ];
    } catch (QueryException e) {
      System.debug(LoggingLevel.DEBUG, e.getMessage());
      return;
    }

    AcceptPOController.isAutoAcceptPo = true;
    AcceptPOController poController = new AcceptPOController(new ApexPages.StandardController(po));
    if (
      !(poController.errorMessagesMap.values().contains('Failure') ||
      poController.errorMessagesMap.values().contains('Payment schedules required review') ||
      poController.errorMessagesMap.values().contains('Missing Shipping Carrier information') ||
      poController.disableButton)
    ) {
      Postagehelper.validateQuote = new Set<id>();
      poController.savePO();
    } else {
      updateStageErrorMessage(oppId, poController.errorMessagesMap);
    }
    AcceptPOController.isAutoAcceptPo = false;
  }

  /**
   * @description   Generic method to update PO_Stage_Errors__c.Order_Status_Message__c
   * based on Name + Opportunity + error message map.
   * @param oppId                Opportunity Id to match
   * @param errorMessagesMap     Map<String, String> where values may contain "Failure"
   */
  public static void updateStageErrorMessage(Id oppId, Map<String, String> errorMessagesMap) {
    // Query record
    List<PO_Stage_Errors__c> records = [
      SELECT Id, Order_Status_Message__c
      FROM PO_Stage_Errors__c
      WHERE Name = 'INT-02' AND Opportunity__c = :oppId
      LIMIT 1
    ];

    if (records.isEmpty())
      return;

    // Build error message from map
    String errorMessage = '';
    if (errorMessagesMap != null && !errorMessagesMap.isEmpty()) {
      List<String> failures = new List<String>();

      for (String key : errorMessagesMap.keySet()) {
        if (errorMessagesMap.get(key) == 'Failure') {
          failures.add(key);
        }
      }

      errorMessage = String.join(failures, '\n');
    }

    // Update the record
    PO_Stage_Errors__c errRecord = records[0];
    errRecord.Order_Status_Message__c = errorMessage;
    update errRecord;

  }
}