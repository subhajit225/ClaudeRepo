/*************************************************************************************
 * @description       : This class has the logic to make the API Call for Polaris Fulfilment
 * @author            : Hemant
 * @last modified on  : 07-25-2025
 * @last modified by  : Hemant
 * Modifications Log
 * Ver   Date          Author        Modification
 * 1.0   07-25-2025    Hemant        Initial Version - PRDOPS26-701
 * 2.0   03-11-2025    Prashik       Multi-Accounting Update for RSCInstance - FY26WL-127
 ************************************************************************************/
public with sharing class PolarisFulfilmentAPI {
  public static Map<String, Polaris_Api_Access_Token__mdt> polarisAndPacmanApiDetails = Polaris_Api_Access_Token__mdt.getAll();
  public static Map<String, Order_control__mdt> polarisAPIMetadata = Order_control__mdt.getAll();
  public static final String PACMAN_API_PROD = 'PolarisFulfilmentAPI';
  public static final String PACMAN_API_DEV = 'PolarisFulfilmentAPISandbox';
  public static final String ENABLE_LOGS = 'Enable_Polaris_Fulfilment_Logs';
  public static final String ENABLE_LOG_REQUEST = 'Enable_Polaris_Fulfilment_Log_Request';
  public static final String USE_UAT_VALUE = 'Polaris_Fulfilment_useUat_Tag';
  public static final String ORDER_QUERY = 'PolarisFulfilmentOrderQuery';
  public static final String ORDER_ITEM_QUERY = 'PolarisFulfilmentOrderItemQuery';
  public static final String RSCINSATNCE_QUERY = 'PolarisFulfilmentRSCInstanceQuery'; //FY26WL-127
  public static final String ENABLE_MULTIACCOUNT_JSON = 'Enable_Multi_Account_Provisioning_JSON'; //FY26WL-127
  public static final String IS_MANUAL = 'isManual';
  public static final String ORDER_ID = 'orderId';
  public static final String ORDER_JSON = 'orderJson';
  public static final String USE_UAT = 'useUat';
  public static final String NON_RETRY_STATUS_CODE = 'Polaris_Fulfilment_Non_Retry_Status_Code';
  public static final String LOG_FUNCTIONALITY = 'Polaris';
  public static final String LOG_TYPE = 'Outbound Integration';
  public static final String RSCINSTANCE_CONTRACT_TYPE_DEDICATED = 'Dedicated';
  public static final String RSCINSTANCE_ACCOUNT_RELATIONSHIP_PRIMARY = 'Primary';
  public static final String RSCINSTANCE_ACCOUNT_RELATIONSHIP_CHILD = 'Child';
  public static final String RSCINSTANCE_ACCOUNT_TYPE_POC = 'POC';
  public static final String RSCINSTANCE_ACCOUNT_TYPE_PROD = 'Revenue';
  public static String rscQueryString = ''; //FY26WL-127

  /**
   * @description : This method is used to make the API Call for the Polaris Fulfilment/Provision
   * @param ordId : Id of the Order
   * @param errorLogList : List of Custom Error Logs
   * @param token : String of the access token
   * @return LCC_ButtonsController.response_Wrapper
   */
  public static LCC_ButtonsController.response_Wrapper restProvisionApiCall(String ordId, List<Custom_Error_Log__c> errorLogList, String token) {
    String requestTime, responseTime, ordJson, useUat, requestBody;
    Exception excp;
    Http http = new Http();
    HttpRequest request = new HttpRequest();
    HttpResponse response = new HttpResponse();
    Polaris_Api_Access_Token__mdt postApiDetails = getPolarisApiMetadata();
    try {
      if (token != null || Test.isRunningTest()) {
        ordJson = getPolarisOrderJSON(ordId);
        useUat = getControlValue(USE_UAT_VALUE, 'false');
        Map<String, Object> requestBodyMap = new Map<String, Object>();
        requestBodyMap.put(IS_MANUAL, true);
        requestBodyMap.put(ORDER_ID, String.valueOf(ordId));
        requestBodyMap.put(ORDER_JSON, ordJson);
        requestBodyMap.put(USE_UAT, Boolean.valueOf(useUat));
        requestBody = JSON.serialize(requestBodyMap);
        request = buildHttpRequest(postApiDetails.Endpoint__c, postApiDetails.Request_Method__c, token, requestBody);
        requestTime = String.valueOf(system.now());
        response = http.send(request);
        responseTime = String.valueOf(system.now());
      }
    } catch (exception ex) {
      excp = ex;
    }

    if (shouldLogIntegration()) {
      errorLogList.add(buildIntegrationLog('PolarisFulfilmentAPI', LOG_FUNCTIONALITY, LOG_TYPE, requestTime, responseTime, request, response, excp, ordId));
    }
    return buildApiResponse(response, excp);
  }

  /**
   * @description method to create json for order
   * @param orderId
   * @return String
   */
  public static String getPolarisOrderJSON(String orderId) {
    String query = '';

    Map<String, StoreSOQLQuery__mdt> soqlQueryMdtByName = new Map<String, StoreSOQLQuery__mdt>();
    for (StoreSOQLQuery__mdt soqlQuery : [
      SELECT Id, DeveloperName, Label, Query__c
      FROM StoreSOQLQuery__mdt
      WHERE DeveloperName IN :new List<String>{ ORDER_QUERY, ORDER_ITEM_QUERY, RSCINSATNCE_QUERY }
    ]) {
      soqlQueryMdtByName.put(soqlQuery.DeveloperName, soqlQuery);
    }
    //FY26WL-127
    if (soqlQueryMdtByName != null && soqlQueryMdtByName.containsKey(RSCINSATNCE_QUERY) && String.isNotBlank(soqlQueryMdtByName.get(RSCINSATNCE_QUERY).Query__c)) {
      rscQueryString = soqlQueryMdtByName.get(RSCINSATNCE_QUERY).Query__c;
    }

    if (soqlQueryMdtByName != null && soqlQueryMdtByName.containsKey(ORDER_QUERY) && String.isNotBlank(soqlQueryMdtByName.get(ORDER_QUERY).Query__c)) {
      query = (String) soqlQueryMdtByName.get(ORDER_QUERY).Query__c;
    }

    if (soqlQueryMdtByName != null && soqlQueryMdtByName.containsKey(ORDER_ITEM_QUERY) && String.isNotBlank(soqlQueryMdtByName.get(ORDER_ITEM_QUERY).Query__c)) {
      query += soqlQueryMdtByName.get(ORDER_ITEM_QUERY).Query__c;
    }

    query += ',Product2.Id, Product2.Name, SBQQ__SubscriptionTerm__c, product2.Product_Type__c, product2.Support_Type__c, product2.Product_Payment_Option__c, product2.Description, Support_Start_Date__c from orderItems), Polaris_Fulfillment_Timestamp__c from Order';
    if (orderId != null) {
      query += ' WHERE Id = \'' + orderId + '\'';
    }
    List<Order> orderList = Database.Query(query);
    OrderWithFeaturesWrapper finalResponse = polarisFulfilmentJSON(orderList);
    SingleOrderWithOIFeaturesWrapper postReq = new SingleOrderWithOIFeaturesWrapper(finalResponse.OrderItems[0], finalResponse.OIFeature);
    return JSON.serialize(postReq);
  }

  /**
   * @description This Method creats the JSON Request for the Polaris Fulfilment Callout
   * @param orderList List of Order
   * @return OrderWithFeaturesWrapper
   */
  public static OrderWithFeaturesWrapper polarisFulfilmentJSON(List<Order> orderList) {
    //FY26WL-127
    Set<Id> productIdSet = new Set<Id>();
    RSCInstanceQueryInput input = new RSCInstanceQueryInput();

    for (Order ord : orderList) {
      //FY26WL-127 - START
      input.accountIds.add(ord.AccountId);
      if (ord.Type == Constants.RSCINSTANCE_ACCOUNT_TYPE_POC && String.isNotBlank(ord.POC_Request__c) && ord.POC_Request__r != null) {
        input.pocRSCInstanceIds.add(ord.POC_Request__r.RSCInstance__c);
      } else {
        if (ord.Opportunity.Managed_Services_Deal_type__c == Constants.OPP_MSP_DEAL_TYPE_DEDICATED_DEAL && ord.Opportunity.MSP_End_User_Lookup__c != null) {
          input.dedicatedSDPEndUserIds.add(ord.Opportunity.MSP_End_User_Lookup__c);
          input.accountsNeedingDedicated.add(ord.AccountId);
        }

        if (ord.Opportunity.Managed_Services_Deal_type__c == null) {
          input.accountsNeedingPrimary.add(ord.AccountId);
        }
      }
      //FY26WL-127 - END
      for (orderItem objOrderItem : ord.orderItems) {
        Product2 oiProduct = objOrderItem.PricebookEntry.Product2;
        if (objOrderItem != null && oiProduct.Product_Level__c != null) {
          if (oiProduct.Bundle_Features__c == null && oiProduct.Product_Type__c != null) {
            oiProduct.Bundle_Features__c = oiProduct.Product_Type__c == 'EDGE' ? 'Hybrid Edge' : oiProduct.Product_Type__c;
          }
        }

        //PRDOPS23-23-Start
        if (
          oiProduct.Bundle_Features__c != null &&
          oiProduct.Bundle_Features__c.split(';').indexOf('Polaris Radar') != -1 &&
          oiProduct.Bundle_Features__c.split(';').indexOf('Incident Containment') == -1
        ) {
          if (
            (oiProduct.Upgrade_Path__c != null && Label.Upgrade_Path.contains(oiProduct.Upgrade_Path__c)) ||
            (oiProduct.Product_Type__c == 'Enterprise Edition' &&
            oiProduct.Product_Level__c == null) ||
            oiProduct.Product_Type__c == 'Complete Edition Elite'
          ) {
            objOrderItem.PricebookEntry.Product2.Bundle_Features__c += ';Incident Containment';
          }
        } //PRDOPS23-23END
        productIdSet.add(objOrderItem.PricebookEntry.Product2Id);
      }
    }
    //FY26WL-127
    RSCInstanceQueryResult result = getRSCInstance(input);

    List<Product_Feature__c> productFeatureList = [
      SELECT id, Feature__c, Value__c, Unit__c, Product_Name__c, Fixed__c
      FROM Product_Feature__c
      WHERE
        Status__c = 'ACTIVE'
        AND (Feature_EOL__c = NULL
        OR Feature_EOL__c >= today)
        AND Feature_start_date__c <= today
        AND Value__c != 'Not Applicable'
        AND Product_Name__c IN :productIdSet
    ];
    Map<Id, List<Product_Feature__c>> prodIdFeatureListMap = new Map<Id, List<Product_Feature__c>>();

    for (Product_Feature__c pfObj : productFeatureList) {
      List<Product_Feature__c> productFeatureListTemp = new List<Product_Feature__c>();

      if (prodIdFeatureListMap != null && prodIdFeatureListMap.keyset().contains(pfObj.Product_Name__c)) {
        productFeatureListTemp = prodIdFeatureListMap.get(pfObj.Product_Name__c);
      }
      productFeatureListTemp.add(pfObj);
      prodIdFeatureListMap.put(pfObj.Product_Name__c, productFeatureListTemp);
    }

    List<orderItemWithFeature> Resp11 = new List<orderItemWithFeature>();
    for (Order ord : orderList) {
      //FY26WL-127
      ord = attachFilteredRSCInstancesToAccount(ord, result);

      for (orderItem objOrderItem : ord.orderItems) {
        List<featureDetails> featureDetailsList = new List<featureDetails>();
        if (prodIdFeatureListMap != null && prodIdFeatureListMap.keyset().contains(objOrderItem.PricebookEntry.Product2Id)) {
          for (Product_Feature__c pfObj : prodIdFeatureListMap.get(objOrderItem.PricebookEntry.Product2Id)) {
            featureDetails detail = new featureDetails();
            detail.Name = pfObj.Feature__c;
            detail.UOM = pfObj.Unit__c;
            if (!String.isBlank(pfObj.Value__c) && pfObj.Value__c.isNumericSpace()) {
              detail.TotalQuantity = pfObj.Fixed__c ? Integer.valueOf(pfObj.Value__c) : Integer.valueOf(pfObj.Value__c) * objOrderItem.Quantity;
            }
            if (!String.isBlank(objOrderItem.Storage_Tier__c)) {
              detail.Tier = objOrderItem.Storage_Tier__c;
            }
            if (!String.isBlank(objOrderItem.Storage_Region_Bundle__c)) {
              detail.Region = objOrderItem.Storage_Region_Bundle__c;
            }
            featureDetailsList.add(detail);
          }
        }
        orderItemWithFeature oiWithFeature = new orderItemWithFeature();
        oiWithFeature.orderItemId = objOrderItem.Id;
        oiWithFeature.featureDetails = featureDetailsList;
        Resp11.add(oiWithFeature);
      }
    }
    OrderWithFeaturesWrapper finalResponse = new OrderWithFeaturesWrapper(orderList, Resp11);
    return finalResponse;
  }

  /**
   * @description This method is used to check the max length of the string.
   * @param input
   * @param maxLength
   * @return String
   */
  private static String truncateString(String input, Integer maxLength) {
    return input != null && input.length() > maxLength ? input.substring(0, maxLength) : input;
  }

  /**
   * @description This method queries RSC Instances and sorts by Account Id - FY26WL-127
   * @param input
   * @return RSCInstanceQueryResult
   */
  private static RSCInstanceQueryResult getRSCInstance(RSCInstanceQueryInput input) {
    List<String> conditions = new List<String>();

    Set<Id> accountIds = input.accountIds;
    Set<Id> dedicatedSDPEndUserIds = input.dedicatedSDPEndUserIds;
    Set<Id> accountsNeedingPrimary = input.accountsNeedingPrimary;
    Set<Id> accountsNeedingDedicated = input.accountsNeedingDedicated;
    Set<Id> pocRSCInstanceIds = input.pocRSCInstanceIds;

    if (!dedicatedSDPEndUserIds.isEmpty()) {
      conditions.add(
        '(RSCAccountRelationship__c = :RSCINSTANCE_ACCOUNT_RELATIONSHIP_CHILD AND AccountId__c IN :accountsNeedingDedicated AND SDPEndUser__c IN :dedicatedSDPEndUserIds AND ContractType__c =: RSCINSTANCE_CONTRACT_TYPE_DEDICATED)'
      );
    }

    if (!accountsNeedingPrimary.isEmpty()) {
      conditions.add(
        '(RSCAccountRelationship__c = :RSCINSTANCE_ACCOUNT_RELATIONSHIP_PRIMARY AND RSCAccountType__c = :RSCINSTANCE_ACCOUNT_TYPE_PROD AND AccountId__c IN :accountsNeedingPrimary)'
      );
    }

    if (!pocRSCInstanceIds.isEmpty()) {
      conditions.add('(Id IN :pocRSCInstanceIds)');
    }

    conditions.add('AccountId__c IN :accountIds');

    rscQueryString += String.join(conditions, ' OR ') + ')';
    RSCInstanceQueryResult result = new RSCInstanceQueryResult();
    List<RSCInstance__c> filteredRSCInstances = Database.query(rscQueryString);

    for (RSCInstance__c rscInstance : filteredRSCInstances) {
      Id accountId = rscInstance.AccountId__c;
      if (!result.rscInstancesByAccountId.containsKey(accountId)) {
        result.rscInstancesByAccountId.put(accountId, new List<RSCInstance__c>());
      }
      result.rscInstancesByAccountId.get(accountId).add(rscInstance);
      result.rscInstanceById.put(rscInstance.Id, rscInstance);
    }

    return result;
  }

  /**
   * @description This method checks if the RSC Instance matches the order criteria - FY26WL-127
   * @param rsci
   * @param ord
   * @param requiredAccountType
   * @return Boolean
   */
  private static Boolean matchesOrderCriteria(RSCInstance__c rsci, Order ord, String requiredAccountType) {
    if (rsci.RSCAccountType__c != requiredAccountType) {
      return false;
    }

    if (ord.Opportunity.Managed_Services_Deal_type__c == Constants.OPP_MSP_DEAL_TYPE_DEDICATED_DEAL) {
      return (rsci.SDPEndUser__c == ord.Opportunity.MSP_End_User_Lookup__c &&
      rsci.RSCAccountRelationship__c == Constants.RSCINSTANCE_ACCOUNT_RELATIONSHIP_CHILD &&
      rsci.AccountId__c == ord.AccountId &&
      rsci.ContractType__c == Constants.RSCINSTANCE_CONTRACT_TYPE_DEDICATED);
    } else {
      return (rsci.AccountId__c == ord.AccountId && rsci.RSCAccountRelationship__c == Constants.RSCINSTANCE_ACCOUNT_RELATIONSHIP_PRIMARY);
    }
  }

  /**
   * @description This method filter the RSC Instances for the Order and addes them to the RSC Instance List inside Account
   * @param ord
   * @param results
   * @return Order
   */
  private static Order attachFilteredRSCInstancesToAccount(Order ord, RSCInstanceQueryResult results) {
    List<RSCInstance__c> filteredInstances = new List<RSCInstance__c>();
    if (ord.Type == Constants.RSCINSTANCE_ACCOUNT_TYPE_POC && ord.POC_Request__r != null && ord.POC_Request__r.RSCInstance__c != null) {
      RSCInstance__c instance = results.rscInstanceById.get(ord.POC_Request__r.RSCInstance__c);

      if (instance != null) {
        filteredInstances.add(instance);
      }
    } else {
      if (results.rscInstancesByAccountId.containsKey(ord.AccountId)) {
        List<RSCInstance__c> accountInstances = results.rscInstancesByAccountId.get(ord.AccountId);
        String requiredAccountType = ord.Type == Constants.RSCINSTANCE_ACCOUNT_TYPE_POC ? Constants.RSCINSTANCE_ACCOUNT_TYPE_POC : Constants.RSCINSTANCE_ACCOUNT_TYPE_PROD;

        for (RSCInstance__c rsci : accountInstances) {
          if (matchesOrderCriteria(rsci, ord, requiredAccountType)) {
            filteredInstances.add(rsci);
          }
        }
      }
    }

    if (
      ord.Type != Constants.RSCINSTANCE_ACCOUNT_TYPE_POC &&
      ord.Opportunity.Managed_Services_Deal_type__c == null &&
      filteredInstances.isEmpty() &&
      results.rscInstancesByAccountId.containsKey(ord.AccountId)
    ) {
      List<RSCInstance__c> accountInstances = results.rscInstancesByAccountId.get(ord.AccountId);
      RSCInstance__c mostRecentPOC;

      for (RSCInstance__c rsci : accountInstances) {
        if (
          rsci.RSCAccountType__c == Constants.RSCINSTANCE_ACCOUNT_TYPE_POC &&
          rsci.RSCAccountRelationship__c == Constants.RSCINSTANCE_ACCOUNT_RELATIONSHIP_PRIMARY &&
          rsci.AccountId__c == ord.AccountId
        ) {
          mostRecentPOC = rsci;
          break;
        }
      }

      if (mostRecentPOC != null) {
        filteredInstances.add(mostRecentPOC);
      }
    }

    Map<String, Object> accountMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(ord.Account));

    // Build relationship structure
    Map<String, Object> relationshipData = new Map<String, Object>{ 'totalSize' => filteredInstances.size(), 'done' => true, 'records' => filteredInstances };

    // Add relationship to account map
    accountMap.put('RSCInstances__r', relationshipData);

    // Deserialize back to Account
    Account accountWithInstances = (Account) JSON.deserialize(JSON.serialize(accountMap), Account.class);

    ord.Account = accountWithInstances;

    return ord;
  }

  /**
   * @description This method is used to build the Integration Log.
   * @param className
   * @param functionality
   * @param type
   * @param requestTime
   * @param responseTime
   * @param request
   * @param response
   * @param ex
   * @param  failedRecords
   * @return Custom_Error_Log__c
   */
  public static Custom_Error_Log__c buildIntegrationLog(
    String className,
    String functionality,
    String type,
    String requestTime,
    String responseTime,
    HttpRequest request,
    HttpResponse response,
    Exception ex,
    String failedRecords
  ) {
    Custom_Error_Log__c errorLog = new Custom_Error_Log__c();
    errorLog.Class__c = className;
    errorLog.Functionality__c = functionality;
    errorLog.Type__c = type;
    errorLog.FailedRecords__c = failedRecords;
    errorLog.Request_Time__c = requestTime;
    errorLog.Response_Time__c = responseTime;

    if (ex != null) {
      errorLog.Result__c = 'Salesforce Exception';
      errorLog.Exception_Message__c = truncateString(ex.getMessage(), 131072);
      errorLog.ErrorTrace__c = truncateString(ex.getStackTraceString(), 131072);
    } else if (response != null && response.getStatusCode() != 200) {
      errorLog.Result__c = 'Application Failure';
    } else {
      errorLog.Result__c = 'Success';
    }

    if (request != null && request.getBody() != null && (shouldLogRequest() || Test.isRunningTest())) {
      errorLog.Http_Request__c = truncateString(request.getBody(), 131072);
      errorLog.Server_Endpoint__c = request.getEndpoint();
    }

    if (response != null) {
      errorLog.Http_StatusCode__c = String.valueOf(response.getStatusCode());
      String responseBody = response.getBody();
      if (String.isNotBlank(responseBody)) {
        errorLog.Http_Response__c = truncateString(responseBody, 131072);
      }
    }
    return errorLog;
  }
  /**
   * @description This method is used to create the HTTPRequest for callout.
   * @param  endpoint
   * @param method
   * @param token
   * @param requestBody
   * @return HttpRequest
   */
  public static HttpRequest buildHttpRequest(String endpoint, String method, String token, String requestBody) {
    HttpRequest request = new HttpRequest();
    request.setEndpoint(endpoint);
    request.setMethod(method);
    request.setHeader('Grpc-metadata-user', token);
    request.setHeader('Content-Type', 'application/json');
    request.setBody(requestBody);
    request.setTimeout(30000); // Added for FY26WL-374
    return request;
  }

  /**
   * @description This method is used to build the API Response to handle the record updates and retry.
   * @param response
   * @param ex
   * @return LCC_ButtonsController.response_Wrapper
   */
  private static LCC_ButtonsController.response_Wrapper buildApiResponse(HttpResponse response, Exception ex) {
    LCC_ButtonsController.response_Wrapper result = new LCC_ButtonsController.response_Wrapper();

    if (ex != null) {
      result.isSuccess = ex.getMessage().contains('Read timed out') ? true : false;
      result.errorMessage = ex.getMessage();
      result.rscRecId = ex.getMessage().contains('Read timed out') ? '0' : null;
      return result;
    }

    if (response != null) {
      result.rscRecId = String.valueOf(response.getStatusCode());

      String responseBody = response.getBody();
      Boolean isSuccess = result.rscRecId == '200';
      result.isSuccess = isSuccess;

      if (String.isNotBlank(responseBody)) {
        try {
          Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

          if (isSuccess && responseMap.containsKey('fulfillment_not_needed') && Boolean.valueOf(responseMap.get('fulfillment_not_needed'))) {
            result.rscRecId = 'Not Needed';
          } else if (isSuccess && responseMap.containsKey('taskchain_id')) {
            result.rscRecId = String.valueOf(responseMap.get('taskchain_id'));
          } else if (!isSuccess && responseMap.containsKey('error')) {
            result.errorMessage = String.valueOf(responseMap.get('error'));
          }
        } catch (Exception jsonEx) {
          // Non-JSON or malformed JSON response
          if (!isSuccess) {
            result.errorMessage = 'Invalid JSON : ' + truncateString(responseBody, 250);
          }
        }
      } else if (!isSuccess) {
        result.errorMessage = 'Empty response received with status  ' + response.getStatus();
      }
    } else {
      // No response object and no exception: rare, but safe to handle
      result.isSuccess = false;
      result.errorMessage = 'No response received from API.';
    }

    return result;
  }

  /**
   * @description This method is used to get the Polaris API Metadata for the Key
   * @return Polaris_Api_Access_Token__mdt
   */
  private static Polaris_Api_Access_Token__mdt getPolarisApiMetadata() {
    Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
    String key = isSandbox ? PACMAN_API_DEV : PACMAN_API_PROD;
    return polarisAndPacmanApiDetails.containsKey(key) ? polarisAndPacmanApiDetails.get(key) : null;
  }

  /**
   * @description This method is used to get the Order Control Metadata for the key
   * @param key
   * @param defaultValue
   * @return String
   */
  private static String getControlValue(String key, String defaultValue) {
    return polarisAPIMetadata.containsKey(key) && String.isNotBlank(polarisAPIMetadata.get(key).Value__c) ? polarisAPIMetadata.get(key).Value__c : defaultValue;
  }

  /**
   * @description This method is used to check logging enabled for Polaris API's
   * @return Boolean
   */
  private static Boolean shouldLogIntegration() {
    return Boolean.valueOf(getControlValue(ENABLE_LOGS, 'false'));
  }

  /**
   * @description This method is used to check if we need to store request body for logs
   * @return Boolean
   */
  private static Boolean shouldLogRequest() {
    return Boolean.valueOf(getControlValue(ENABLE_LOG_REQUEST, 'false'));
  }

  /**
   * @description This class is used to create the OrderWithFeatures Object for Polaris Provisioning API's
   */
  public class OrderWithFeaturesWrapper {
    public List<Order> OrderItems;
    public List<OrderItemWithFeature> OIFeature;
    public Boolean use_rsc_instances;

    /**
     * @description Constructor
     * @param OrderItems
     * @param OIFeature
     */
    public OrderWithFeaturesWrapper(List<Order> OrderItems, List<OrderItemWithFeature> OIFeature) {
      this.orderItems = OrderItems;
      this.OIFeature = OIFeature;
      this.use_rsc_instances = Boolean.valueOf(getControlValue(ENABLE_MULTIACCOUNT_JSON, 'false'));
    }
  }

  /**
   * @description This class is used to create the OrderItemWithFeature Object
   */
  public class OrderItemWithFeature {
    public id orderItemId;
    public List<FeatureDetails> featureDetails;
  }

  /**
   * @description This class is used to create the FeatureDetails Object
   */
  public class FeatureDetails {
    public string Name;
    public String UOM;
    public Decimal TotalQuantity;
    public String Tier;
    public String Region;
  }

  /**
   * @description This is a wrapper class for post api request body
   */
  public class SingleOrderWithOIFeaturesWrapper {
    public Order OrderItems;
    public List<OrderItemWithFeature> OIFeature;
    public Boolean use_rsc_instances;

    /**
     * @description Constructor
     * @param OrderItems
     * @param OIFeature
     */
    public SingleOrderWithOIFeaturesWrapper(Order OrderItems, List<OrderItemWithFeature> OIFeature) {
      this.orderItems = OrderItems;
      this.OIFeature = OIFeature;
      this.use_rsc_instances = Boolean.valueOf(getControlValue(ENABLE_MULTIACCOUNT_JSON, 'false'));
    }
  }

  /**
   * @description This is RSC Instance Query Input Wrapper
   */
  public class RSCInstanceQueryInput {
    public Set<Id> accountIds = new Set<Id>();
    public Set<Id> dedicatedSDPEndUserIds = new Set<Id>();
    public Set<Id> accountsNeedingPrimary = new Set<Id>();
    public Set<Id> accountsNeedingDedicated = new Set<Id>();
    public Set<Id> pocRSCInstanceIds = new Set<Id>();
  }

  /**
   * @description This is RSC Instnace Query Result Wrapper
   */
  public class RSCInstanceQueryResult {
    public Map<Id, List<RSCInstance__c>> rscInstancesByAccountId = new Map<Id, List<RSCInstance__c>>();
    public Map<Id, RSCInstance__c> rscInstanceById = new Map<Id, RSCInstance__c>();
  }
}