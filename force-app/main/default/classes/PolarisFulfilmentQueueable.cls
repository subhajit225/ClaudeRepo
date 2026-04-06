/*************************************************************************************
 * @description       : Queueable class to make Polaris Fulfilment/Provision API Call
 * @author            : Siva
 * @last modified on  : 07-25-2025
 * @last modified by  : Siva
 * Modifications Log
 * Ver   Date          Author        Modification
 * 1.0   07-25-2025    Siva        Initial Version - PRDOPS26-701
 ************************************************************************************/
public class PolarisFulfilmentQueueable implements Queueable, Database.AllowsCallouts {
  public List<Id> ordIdList;
  public Set<Id> failedOrderIdSet = new Set<Id>();
  public String tokenResp;
  public static final String CACHE_PARTITION_NAME = 'PacmanAccessToken';
  public static Map<String, Order_control__mdt> polarisAPIMetadata = Order_control__mdt.getAll();
  /**
   * @description :This is a constructor class.
   * This is used to pass the order id for the queueable job is execution
   * @param orderIdList
   * @param failedOrderIdSet
   * @param tokenResp
   */
  public PolarisFulfilmentQueueable(List<Id> orderIdList, Set<Id> failedOrderIdSet, String tokenResp) {
    this.ordIdList = orderIdList;
    this.failedOrderIdSet = failedOrderIdSet;
    this.tokenResp = tokenResp;
  }
  /**
   * @description :Executes the Polaris Fulfilment/Provision API logic asynchronously.
   * This method is called when the queueable job is executed.
   *
   * @param qc The context for this queueable job
   */
  public void execute(QueueableContext qc) {
    if (tokenresp == null) {
      tokenresp = getRefreshAccessToken(false); //Can we store this in the PlatformCache
    }

    List<Custom_Error_Log__c> errorLogList = new List<Custom_Error_Log__c>();
    List<Order> orderToUpdate = new List<Order>();
    String ordId = ordIdList[0];
    LCC_ButtonsController.response_Wrapper retResponse = PolarisFulfilmentAPI.restProvisionApiCall(ordId, errorLogList, tokenresp);
    if (retResponse.isSuccess && retResponse.rscRecId != 'Not Needed') {
      orderToUpdate.add(new Order(Id = ordId, Polaris_Fulfillment_Status__c = 'Provisioning In Progress'));
      ordIdList.remove(0);
    } else {
      List<String> errorCodeList = polarisAPIMetadata.get(PolarisFulfilmentAPI.NON_RETRY_STATUS_CODE).Value__c.split(',');
      if (retResponse.rscRecId == '401') {
        getRefreshAccessToken(true);
      }
      ordIdList.remove(0);
      if((errorCodeList.isEmpty() || !errorCodeList.contains(retResponse.rscRecId)) && !retResponse.isSuccess){
        if(!failedOrderIdSet.contains(ordId)) {
          failedOrderIdSet.add(ordId);
          ordIdList.add(ordId);
        } else {
          orderToUpdate.add(new Order(Id = ordId, Polaris_Fulfillment_Status__c = 'Not Started'));
        }
      }
    }
    if (!ordIdList.isEmpty() && !Test.isRunningTest()) {
      system.enqueueJob(new PolarisFulfilmentQueueable(ordIdList, failedOrderIdSet, tokenresp));
    }
    try {
      if (!orderToUpdate.isEmpty()) {
        update orderToUpdate;
      }
    } catch (exception ex) {
      errorLogList.add(
        PolarisFulfilmentAPI.buildIntegrationLog(
          'PolarisFulfilmentQueueable',
          PolarisFulfilmentAPI.LOG_FUNCTIONALITY,
          PolarisFulfilmentAPI.LOG_TYPE,
          null,
          null,
          null,
          null,
          ex,
          ordId
        )
      );
    }
    if (!errorLogList.isEmpty()) {
      insert errorLogList;
    }
  }

  /**
   * @description : This method is used to get the Access Token from the Platform Cache
   * @param generateNewToken : Boolean value to generate a new token
   * @return String : String of the access token
   */
  public static String getRefreshAccessToken(Boolean generateNewToken) {
    String accessToken = getAccessTokenFromCache();

    if (accessToken == null || generateNewToken) {
      accessToken = PolarisApi.getAccessToken().access_token; // Implement your token refresh logic
      if (accessToken != null) {
        storeAccessTokenInCache(accessToken);
      }
    }
    return accessToken;
  }
  /**
   * @description : This method is used to store the Access Token in the Platform Cache
   * @param accessToken : String of the access token
   */
  private static void storeAccessTokenInCache(String accessToken) {
    Integer expiresInSeconds = 3600; // This should come from your OAuth response
    DateTime expiryDateTime = System.now().addSeconds(expiresInSeconds);

    Cache.OrgPartition orgPart = Cache.Org.getPartition('local.' + CACHE_PARTITION_NAME);

    if (orgPart != null) {
      // Store the token and expiry. Use a TTL slightly less than the actual expiry for safety.
      // Platform Cache TTL is in seconds.
      Integer cacheTTL = expiresInSeconds;
      orgPart.put('accessToken', accessToken, cacheTTL);
      orgPart.put('tokenExpiryTime', expiryDateTime, cacheTTL); // Store expiry also for explicit check
    } else {
      System.debug(LoggingLevel.DEBUG, 'Error: Platform Cache partition not found: ' + CACHE_PARTITION_NAME);
    }
  }
  /**
   * @description : This method is used to get the Access Token from the Platform Cache
   * @return String : String of the access token
   */
  private static String getAccessTokenFromCache() {
    Cache.OrgPartition orgPart = Cache.Org.getPartition('local.' + CACHE_PARTITION_NAME);

    if (orgPart != null) {
      String token = (String) orgPart.get('accessToken');
      DateTime expiry = (DateTime) orgPart.get('tokenExpiryTime');

      if (token != null && expiry != null && expiry > System.now()) {
        return token;
      }
    }
    return null; // Token not found or expired
  }
}