/*****************************************************************************************
Description : PRDOPS25-123
              
Developer :   Krapy Tuli 
Date :        02/2024
*****************************************************************************************/
@RestResource(urlMapping='/getAccounts/*')
global with sharing class AccountDetails_WebService {
  private static final String REQUIRED_HEADER_VALUE = 'getdata'; // these values should be present in the request header
  private static final Set<String> GET_DATA_VALUES = new Set<String>{ 'latestFeature' }; // accepted values of getdata
  private static final String OPTIONAL_HEADER_PRODUCT_NAME = 'productname'; // productName is optional parameter in the request header
  private static final String OPTIONAL_HEADER_BUNDLE_FEATURE = 'bundlefeature'; // bundleFeature is optional parameter in the request header
  private static Map<Id, List<String>> prodIdToBundleFeature = new Map<Id, List<String>>(); // to store bundle features corresponding to productId
  private static final String MANUFACTURING_ENTITLEMENT = 'Manufacturing Entitlement'; // Entitlement type
  private static final List<String> ORDER_TYPES = new List<String>{ 'POC', 'Revenue' }; // list to store Order types
  /**************************************************************
  Input : getData, productName or bundleFeature
        
  Output : latest Entitlements details per product/bundle
*****************************************************************/
  @HttpGet
  global static void getAccountDetails() {
    RestRequest request = RestContext.request;
    RestResponse response = RestContext.response;
    Map<String, String> reqHeader = new Map<String, String>();
    try {
      reqHeader = request.headers;
      if ((reqHeader.keySet().contains(REQUIRED_HEADER_VALUE) && GET_DATA_VALUES.contains(reqHeader.get(REQUIRED_HEADER_VALUE)))) {
        if (reqHeader.get(REQUIRED_HEADER_VALUE) == 'latestFeature') {
          if (validateHeaderForLatestEntitlements(reqHeader)) {
            getLatestEntitlements(reqHeader);
          } else {
            response.responseBody = Blob.valueof(JSON.Serialize(generateResponse(400, 'unsuccessful', 'incorrect/no headers found.')));
            return;
          }
        }
      } else {
        response.responseBody = Blob.valueof(JSON.Serialize(generateResponse(400, 'unsuccessful', 'Bad request: incorrect data requested')));
        return;
      }
    } catch (exception ex) {
      response.responseBody = Blob.valueof(JSON.Serialize(generateResponse(500, 'unsuccessful', 'Exception: ' + ex.getMessage())));
      return;
    }
  }

  /**
   * method name : validateHeaderForLatestEntitlements (to validate if all the required and optional header are present in the request for latest Entitlements)
   * param : request header
   * return : true/false (whether the header is correct or not)
   */
  private static Boolean validateHeaderForLatestEntitlements(Map<String, String> headers) {
    if (!headers.containsKey(OPTIONAL_HEADER_PRODUCT_NAME) && !headers.containsKey(OPTIONAL_HEADER_BUNDLE_FEATURE)) {
      return false; // Missing optional headers
    }
    if (headers.containsKey(OPTIONAL_HEADER_PRODUCT_NAME) && headers.containsKey(OPTIONAL_HEADER_BUNDLE_FEATURE)) {
      return false;
    }
    return true; // Headers pass validation
  }

  /**
   * method name : getLatestEntitlements (to get the active entitlements and generate the response)
   * param : request header
   */

  private static void getLatestEntitlements(Map<String, String> reqHeader) {
    RestResponse response = RestContext.response;
    Set<Id> productIds = new Set<Id>();
    Map<String, Object> accountDetails = new Map<String, Object>();
    List<Map<string, object>> allEntDetails = new List<Map<string, object>>();
    productIds = filterProducts(reqHeader);
    if (!productIds.isEmpty()) {
      Map<String, Entitlement> latestEntitlementByAccountId = findLatestEntitlements(productIds);
      accountDetails.put('totalAccounts', countAccounts(productIds));
      allEntDetails = buildEntitlementDetails(latestEntitlementByAccountId);
      if (allEntDetails.size() <= 30000) {
        accountDetails.put('details', allEntDetails);
        response.responseBody = Blob.valueof(JSON.Serialize(accountDetails));
      } else {
        response.responseBody = Blob.valueof(JSON.Serialize(generateResponse(400, 'unsuccessful', 'Response is too large.')));
      }
    } else {
      response.responseBody = Blob.valueof(JSON.Serialize(generateResponse(200, 'successful', 'No records found.')));
    }
  }
  /**
   * method name : countAccounts (to count accounts according to the criteria)
   * param : set of productIds
   * return : Integer
   */
  private static Integer countAccounts(Set<Id> productIds) {
    List<AggregateResult> result = new List<AggregateResult>();
    result = [
      SELECT COUNT_DISTINCT(AccountId) Total_Accounts
      FROM Entitlement
      WHERE Status = 'Active' AND Type != :MANUFACTURING_ENTITLEMENT AND Product__c IN :productIds AND Order_Service_Item__r.Order.Type IN :ORDER_TYPES AND EndDate != NULL
    ];
    return (Integer) result[0].get('Total_Accounts');
  }

  /**
   * method name : buildEntitlementDetails (to create the final response)
   * param : Map<String, Entitlement>
   * return : List<Map<String, Object>>
   */

  private static List<Map<String, Object>> buildEntitlementDetails(Map<String, Entitlement> latestEntitlementByAccountId) {
    Set<Id> entitlementsProcessed = new Set<Id>();
    List<Map<string, object>> allEntDetails = new List<Map<string, object>>();
    for (Entitlement entToSend : latestEntitlementByAccountId.values()) {
      if (!entitlementsProcessed.contains(entToSend.Id)) {
        Map<String, Object> entDetail = new Map<String, Object>();
        entDetail.put('entId', entToSend.Id);
        entDetail.put('accountId', entToSend.AccountId);
        entDetail.put('polarisURL', entToSend.Account.Customer_URL__c);
        entDetail.put('entitlementName', entToSend.Name);
        entDetail.put('expiryDate', entToSend.EndDate);
        entDetail.put('orderType', entToSend.Order_Service_Item__r.Order.Type);
        entDetail.put('orderSubType', entToSend.Order_Service_Item__r.Order.Order_Sub_Type__c);
        allEntDetails.add(entDetail);
        entitlementsProcessed.add(entToSend.Id);
      }
    }
    return allEntDetails;
  }

  /**
   * method name : filterProducts (to filter the products based on name or bundle feature)
   * param : request header
   * return : eligible productIds
   */
  private static Set<Id> filterProducts(Map<String, String> reqHeader) {
    Set<Id> productIds = new Set<Id>();
    String inputProdNames;
    String inputbundleFeatures;
    List<String> productNames = new List<String>();
    List<String> bundleFeatures = new List<String>();
    inputProdNames = reqHeader.containsKey('productname') ? reqHeader.get('productname') : '';
    inputbundleFeatures = reqHeader.containsKey('bundlefeature') ? reqHeader.get('bundlefeature') : '';
    if (String.isNotBlank(inputProdNames)) {
      productNames = inputProdNames.split(',');
    }
    if (String.isNotBlank(inputbundleFeatures)) {
      bundleFeatures = inputbundleFeatures.split(',');
    }
    String queryString = buildProductQuery(productNames, bundleFeatures);
    productIds.addAll(collectProductIds(queryString, bundleFeatures, productNames));
    return productIds;
  }

  /**
   * method name : buildProductQuery (to build the query)
   * param : List of products and bundlefeatures
   */

  private static String buildProductQuery(List<String> productNames, List<String> bundleFeatures) {
    String queryString = 'SELECT Id, PDM_Feature_Enabled__c, Bundle_Features__c FROM Product2 WHERE ';
    Set<Id> productIdSet = new Set<Id>();
    if (!bundleFeatures.isEmpty()) {
      for (Product_Feature__c pf : [SELECT Id, Product_Name__c, Feature__c FROM Product_Feature__c WHERE Feature__c IN :bundleFeatures AND Product_Name__r.PDM_Feature_Enabled__c = TRUE]) {
        productIdSet.add(pf.Product_Name__c);
        if (!prodIdToBundleFeature.containsKey(pf.Product_Name__c)) {
          prodIdToBundleFeature.put(pf.Product_Name__c, new List<String>());
        }

        prodIdToBundleFeature.get(pf.Product_Name__c).add(pf.Feature__c.toLowerCase());
      }
      String bundledFeaturesCond = 'Bundle_Features__c INCLUDES (\'' + String.join(bundleFeatures, '\',\'') + '\')';
      queryString += '( PDM_Feature_Enabled__c = false AND ' + bundledFeaturesCond + ' ) ';
      queryString += 'OR Id IN (\'' + String.join(productIdSet, '\',\'') + '\')';
    }

    if (!productNames.isEmpty()) {
      queryString += 'Name IN :productNames';
    }

    return queryString;
  }

  /**
   * method name : collectProductIds (to create the final resp$onse)
   * param : queryString, productNames and bundleFeatures
   * return : set of productIds
   */

  private static Set<Id> collectProductIds(String queryString, List<String> bundleFeatures, List<String> productNames) {
    Set<Id> productIds = new Set<Id>();
    queryString = !productNames.isEmpty() ? String.escapeSingleQuotes(queryString) : queryString;
    for (Product2 prod : Database.query(queryString)) {
      productIds.add(prod.Id);
      if (!bundleFeatures.isEmpty()) {
        if (!prod.PDM_Feature_Enabled__c) {
          List<String> productBundleFeatures = prod.Bundle_Features__c.toLowerCase().split(';');
          for (String requestedFeature : bundleFeatures) {
            requestedFeature = requestedFeature.toLowerCase();
            if (productBundleFeatures.contains(requestedFeature)) {
              if (!prodIdToBundleFeature.containsKey(prod.Id)) {
                prodIdToBundleFeature.put(prod.Id, new List<String>());
              }
              prodIdToBundleFeature.get(prod.Id).add(requestedFeature);
            }
          }
        }
      }
    }
    return productIds;
  }

  /**
   * method name : findLatestEntitlements(to get the latest entitlement based on the productIds)
   * param : set of productIds
   * return : Map<String, Entitlement>
   */

  private static Map<String, Entitlement> findLatestEntitlements(Set<Id> productIds) {
    Map<String, Entitlement> accIdToLatest = new Map<String, Entitlement>();
    for (Entitlement ent : [
      SELECT Id, Name, EndDate, AccountId, Account.Customer_URL__c, Product__r.Name, Order_Service_Item__r.Order.Type, Order_Service_Item__r.Order.Order_Sub_Type__c
      FROM Entitlement
      WHERE Status = 'Active' AND Type != :MANUFACTURING_ENTITLEMENT AND Product__c IN :productIds AND Order_Service_Item__r.Order.Type IN :ORDER_TYPES AND EndDate != NULL
      ORDER BY EndDate DESC
    ]) {
      if (prodIdToBundleFeature.isEmpty()) {
        accIdToLatest = buildLatestEntitlementsMap(ent, null, accIdToLatest);
      } else {
        for (String feature : prodIdToBundleFeature.get(ent.Product__c)) {
          accIdToLatest = buildLatestEntitlementsMap(ent, feature, accIdToLatest);
        }
      }
    }
    return accIdToLatest;
  }

  /**
   * method name : buildLatestEntitlementsMap(to get the latest entitlement based on the productIds)
   * param : Entitlement, String, Map<String, Entitlement>
   * return : Map<String, Entitlement>
   */

  private static Map<String, Entitlement> buildLatestEntitlementsMap(Entitlement ent, String feature, Map<String, Entitlement> accIdToLatestUpdated) {
    String accIdWithType = ent.AccountId + '-' + (feature != null ? feature + '-' : ent.Product__r.Name + '-') + ent.Order_Service_Item__r.Order.Type;
    if (!accIdToLatestUpdated.containsKey(accIdWithType) || (accIdToLatestUpdated.containsKey(accIdWithType) && accIdToLatestUpdated.get(accIdWithType).EndDate < ent.EndDate)) {
      accIdToLatestUpdated.put(accIdWithType, ent);
    }
    return accIdToLatestUpdated;
  }

  /**
   * method name : generateResponse (to generate response consisting of statuscode, status and description)
   * param : status code, status, productIds, description
   * return : response
   */

  private static Map<String, Object> generateResponse(Integer statusCode, String status, String description) {
    Map<String, Object> response = new Map<String, Object>();
    response.put('statusCode', statusCode);
    response.put('status', status);
    response.put('description', description);
    return response;
  }
}