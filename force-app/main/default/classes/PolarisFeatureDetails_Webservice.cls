/*****************************************************************************************
Description : PRDOPS21-339
              Rest api used by polaris team 
Developer :   Chaitra  
Date :        12/2020
 * @last modified on  : 12-29-2025
 * Modifications Log
 * Ver   Date           Author        Modification
 * 1.0   12-2020        Chaitra       Initial Version - PRDOPS21-339
 * 2.0   12-29-2025     Prashik       RSC Instnace De-Provisioning - FY26WL-567
*****************************************************************************************/
/**
 * @author Chaitra
 * @description Rest api used by polaris team
 */
@RestResource(urlMapping='/polaris/getFeatureDetails')
global with sharing class PolarisFeatureDetails_Webservice {
  /**************************************************************
Input : accountId 
        featureType : Try N Buy ; POC ;  Revenue
        fieldset : list of extra fields to be set in response
           {
            accountid:001W000000vYD9ZIAW
            featuretype:Try N Buy
            fieldset:order.account.name,SBQQ__Asset__r.name
           }
Output : Latest order product details based on feature type  
*****************************************************************/
  /**
   * @author Prashant Kumar
   * @date 05-06-2025
   * @description fetchFeatureDetails method to provide json related to Entitlement and orderitems.
   */
  @HttpGet
  global static void fetchFeatureDetails() {
    RestRequest request = RestContext.request;
    Custom_Error_Log__c IntegrationLog = new Custom_Error_Log__c(
      Class__c = 'PolarisFeatureDeatils_Webservice',
      Functionality__c = 'Polaris',
      Server_Endpoint__c = '/polaris/getFeatureDetails'
    );
    System.debug(logginglevel.INFO, JSON.serializepretty(request));
    RestResponse res = RestContext.response;
    string resBody;
    string featureType;
    Map<string, object> featureDeatils = new Map<string, object>();
    Id accountId;
    String rscInstanceId; //Added for FY26WL-567
    String sdpEndUserId; //Added for FY26WL-567
    List<orderItem> OIList = new List<orderItem>();
    set<string> prodCode = new Set<string>();
    string fieldStr;
    list<Entitlement> ettList = new List<Entitlement>();
    list<string> fieldSet = new List<string>();
    Map<String, string> reqHeader = new Map<String, string>();
    List<Setup_Integration_Log__mdt> logCntrlr = new List<Setup_Integration_Log__mdt>();
    string whereClause;
    List<Map<string, object>> ordDetails = new List<Map<string, object>>();
    List<Account> currentAccount = new List<Account>();
    List<RSCInstance__c> currentRSCInstnaces = new List<RSCInstance__c>(); //Added for FY26WL-567
    Map<String, orderitem> compareLatestEnttAndOIMap = new Map<String, orderitem>();
    set<string> prodCodeEtt = new Set<string>();
    Map<String, Contractlineitem> productCodeToContractlineMap = new Map<String, Contractlineitem>();
    Boolean ManuallyReviewReqd = false;
    set<Id> pdmEnabledproductIds = new Set<Id>();
    Map<Id, List<String>> prodIdToBundleFeature = new Map<Id, List<String>>(); // to store bundle features corresponding to productId
    String regExp = '(^[\'"]|[\'"]$)|\\b(?i)null\\b';  //Added for FY26WL-567
    Boolean isSharedInstance = false; //Added for FY26WL-567

    try {
      logCntrlr = [SELECT id, Enable_Custom_Logs__c FROM Setup_Integration_Log__mdt WHERE DeveloperName = 'Polaris'];
      reqHeader = request.headers;
      IntegrationLog.Http_Request__c = JSON.serialize(reqHeader);
      featureType = reqHeader.get('featuretype');
      accountId = (Id) reqHeader.get('accountid');
      fieldStr = (string) reqHeader.get('fieldset');
      String rscRawValue = reqHeader.get('rscinstanceid');
      String sdpRawValue = reqHeader.get('sdpenduserid');
      rscInstanceId = (rscRawValue != null && String.isNotBlank(rscRawValue.replaceAll(regExp, '').trim())) ? (rscRawValue.replaceAll(regExp, '').trim()) : null;
      sdpEndUserId = (sdpRawValue != null && String.isNotBlank(sdpRawValue.replaceAll(regExp, '').trim())) ? (sdpRawValue.replaceAll(regExp, '').trim()) : null;
      if (rscInstanceId != null) {
        // Query RSC record
        currentRSCInstnaces = [
          SELECT Id, AccountId__c, SDPEndUser__c, ContractType__c
          FROM RSCInstance__c
          WHERE Id = :rscInstanceId
          WITH SECURITY_ENFORCED
          LIMIT 1
        ];
        system.debug(logginglevel.DEBUG, 'currentRSCInstnaces >>' + currentRSCInstnaces);
        if (!currentRSCInstnaces.isEmpty()) {
          accountId = currentRSCInstnaces[0].AccountId__c;
          sdpEndUserId = currentRSCInstnaces[0].SDPEndUser__c;
          isSharedInstance = (currentRSCInstnaces[0].ContractType__c == Constants.RSCINSTANCE_CONTRACT_TYPE_SHARED);
          
          featureDeatils.put('rscInstanceId', rscInstanceId);
          featureDeatils.put('sdpEndUserId', sdpEndUserId);
        } else {
          res.statusCode = 400;
          resBody = '{"status":"unsuccessful","message":"Invalid rscid provided"}';
          res.responseBody = Blob.valueof(resBody);
          return;
        }
      }
      if (accountId == null || string.isBlank(featureType)) {
        res.statusCode = 400;
        resBody = '{"status":"unsuccessful","Bad Request - Either accountid or featureType is missing"}';
        res.responseBody = Blob.valueof(resBody);
        return;
      }
      currentAccount = [SELECT Id, Owner.Email, Rubrik_Sales_Engineer__r.Email FROM Account WHERE Id = :accountId];
      if(!isSharedInstance){
        string ettquery = 'SELECT Id, Product__r.name, ContractLineItem.SBQQSC__Account__c,contractlineitem.enddate, contractlineitem.quantity,Order_Service_Item__r.Support_Start_Date__c, Order_Service_Item__r.product2.ProductCode,Order_Service_Item__r.product2Id, Order_Service_Item__r.Support_End_Date__c,Order_Service_Item__r.User_license_count__c, Order_Service_Item__r.createddate, Order_Service_Item__r.LastModifiedDate, Order_Service_Item__r.product2.Bundle_Features__c,Product__r.PDM_Feature_Enabled__c FROM Entitlement';
        string ettWhereClause = ' WHERE type!=\'Manufacturing Entitlement\' AND accountId= :accountId AND Order_Service_Item__c!=null AND Order_Service_Item__r.order.accountId !=: accountId';
        if (String.isNotBlank(sdpEndUserId)) {
          ettWhereClause += ' AND MSP_End_User_Lookup__c = :sdpEndUserId AND Order_Service_Item__r.order.Opportunity.MSP_End_User_Lookup__c !=: sdpEndUserId';
        }
        if ('revenue'.equalsIgnoreCase(featureType)) {
          ettWhereClause += ' AND Order_Service_Item__r.Order.Type =\'revenue\'';
        } else {
          ettWhereClause += ' AND Order_Service_Item__r.Order.Type=\'POC\' AND Order_Service_Item__r.Order.Order_Sub_Type__c =:featureType';
        }
        system.debug(LoggingLevel.DEBUG, 'ettWhereClause is ' + ettWhereClause);
        if (string.isNotBlank(ettWhereClause)) {
          ettquery += ettWhereClause;
        }
        ettquery += ' order by enddate desc';
        ettList = database.query(ettquery);

        for (Entitlement ett : ettList) {
          if (ett.Product__r.PDM_Feature_Enabled__c) {
            pdmEnabledproductIds.add(ett.Product__c);
          }
        }

        String query = 'SELECT product2.PDM_Feature_Enabled__c, product2.ProductCode, Support_End_Date__c, User_license_count__c, createddate, lastmodifieddate, Order.Account.Owner.Email, Order.Account.Rubrik_Sales_Engineer__r.Email, product2.Bundle_Features__c';
        List<String> existingFieldsList = query.replace('SELECT', '').deletewhitespace().toLowerCase().split(',');
        if (!String.isBlank(fieldStr)) {
          fieldSet = fieldStr.split(',');
          existingFieldsList.addAll(fieldStr.deletewhitespace().toLowerCase().split(','));
        }
        Set<String> existingFields = new Set<String>(existingFieldsList);
        existingFieldsList.clear();
        existingFieldsList.addAll(existingFields);
        query = 'SELECT ' + String.join(existingFieldsList, ', ') + ' from orderItem';
        whereClause = ' WHERE order.accountId =: accountId';
        if (sdpEndUserId != null) {
          whereClause += ' AND order.opportunity.MSP_End_User_Lookup__c = :sdpEndUserId';
        }
        if ('revenue'.equalsIgnoreCase(featureType)) {
          whereClause += ' AND Order.Type =\'revenue\'';
        } else {
          whereClause += ' AND Order.Type=\'POC\' AND Order.Order_Sub_Type__c =:featureType';
        }
        if (string.isNotBlank(whereClause)) {
          query += whereClause;
        }
        query += ' order by createddate desc';
        system.debug(logginglevel.INFO, query);
        OIList = database.query(query);
        for (orderItem OI : OIList) {
          if (OI.product2.PDM_Feature_Enabled__c) {
            pdmEnabledproductIds.add(OI.product2Id);
          }
        }

        prodIdToBundleFeature = getPDMFeaturesBasedIfEnabled(pdmEnabledproductIds);

        for (orderItem OI : OIList) {
          Map<string, object> OrdItems = new Map<string, object>();
          if (prodCode.contains(OI.product2.ProductCode)) {
            continue;
          }
          OrdItems.put('productName', OI.product2.ProductCode);
          OrdItems.put('supportEndDate', OI.Support_End_Date__c);
          OrdItems.put('userLicenseCount', OI.User_license_count__c);
          OrdItems.put('createdDate', OI.createddate);
          OrdItems.put('lastModifiedDate', OI.LastModifiedDate);
          prodCode.add(OI.product2.ProductCode);
          if (prodIdToBundleFeature.containskey(OI.product2Id)) {
            OrdItems.put('OIfeature', String.join(prodIdToBundleFeature.get(OI.product2Id), ';'));
          }

          for (string field : fieldSet) {
            List<string> fields = new List<string>(field.split('\\.'));
            Sobject obj = OI;
            try {
              for (integer i = 0; i < fields.size(); i++) {
                if (obj == null) {
                  OrdItems.put(field, 'Empty reference field');
                  break;
                } else if (i == fields.size() - 1) {
                  OrdItems.put(field, obj.get(fields[i]));
                } else {
                  obj = obj.getSobject(fields[i]);
                }
              }
            } catch (exception exp) {
              OrdItems.put(field, exp.getmessage());
            }
          }
          ordDetails.add(OrdItems);
        }

        for (Entitlement ett : ettList) {
          if (prodCodeEtt.contains(ett.Product__r.name))
            continue;
          prodCodeEtt.add(ett.Product__r.name);
          if (
            (compareLatestEnttAndOIMap.containskey(ett.Product__r.name) && ett.EndDate > compareLatestEnttAndOIMap.get(ett.Product__r.name).EndDate) ||
            !compareLatestEnttAndOIMap.containskey(ett.Product__r.name)
          ) {
            productCodeToContractlineMap.put(ett.Product__r.name, ett.ContractLineItem);
            compareLatestEnttAndOIMap.put(ett.Product__r.name, ett.Order_Service_Item__r);
            ManuallyReviewReqd = true;
          }
        }
        compareLatestEnttAndOIMap.remove(null);

        for (String str : compareLatestEnttAndOIMap.keyset()) {
          //Frame api Response => PDM Features , ContractDetails
          Map<string, object> OrdItems = new Map<string, object>();

          orderItem OI = compareLatestEnttAndOIMap.get(str);
          OrdItems.put('productName', OI.product2.ProductCode);
          OrdItems.put('supportEndDate', OI.Support_End_Date__c);
          OrdItems.put('userLicenseCount', OI.User_license_count__c);
          OrdItems.put('createdDate', OI.createddate);
          OrdItems.put('lastModifiedDate', OI.LastModifiedDate);
          if (productCodeToContractlineMap.containskey(OI.product2.ProductCode))
            OrdItems.put('contract', productCodeToContractlineMap.get(OI.product2.ProductCode));
          if (prodIdToBundleFeature.containskey(OI.product2Id)) {
            OrdItems.put('OIfeature', String.join(prodIdToBundleFeature.get(OI.product2Id), ';'));
          }
          OrdItems.put('product2.Bundle_Features__c', OI.product2.Bundle_Features__c);
          ordDetails.add(OrdItems);
          for (Entitlement ett : OI.entitlements__r) {
            if (ett.AccountId != OI.order.accountId) {
              ManuallyReviewReqd = true;
              break;
            }
          }
        }
      }

      if (!currentAccount.isEmpty()) {
        featureDeatils.put('accountExecutive', currentAccount[0].Owner.Email);
        featureDeatils.put('rubrikSalesEngineer', currentAccount[0].Rubrik_Sales_Engineer__r?.Email);
      }
      featureDeatils.put('accountId', accountId);
      featureDeatils.put('ManualReviewReqd', ManuallyReviewReqd);
      featureDeatils.put('featureType', featureType);
      featureDeatils.put('featureDetails', ordDetails);
      if (!OIList.isEmpty()) {
        featureDeatils.put('description', 'NA');
      } else {
        featureDeatils.put('description', 'No records found');
      }
      res.statusCode = 200;
      featureDeatils.put('status', 'successful');
    } catch (exception ex) {
      system.debug(logginglevel.DEBUG,ex.getMessage());
      system.debug(logginglevel.DEBUG,ex.getStackTraceString());
      res.statusCode = 500;
      featureDeatils.put('status', 'unsuccessful');
      featureDeatils.put('description', 'An unexpected exception occurred. Please try again later.');
      IntegrationLog.Http_Response__c = ex.getMessage();
    }
    if (!logCntrlr.isEmpty() && logCntrlr[0].Enable_Custom_Logs__c && res.statusCode != 200) {
      insert IntegrationLog;
    }
    res.responseBody = Blob.valueof(JSON.Serialize(featureDeatils));
  }
  /**
   * @author Prashant Kumar
   * @date 05-06-2025
   * @description populateFieldsOnInsert Method Called in Before Insert
   * @param pdmEnabledproductIds
   * @return Map<Id, List<String>>
   */
  public static Map<Id, List<String>> getPDMFeaturesBasedIfEnabled(set<Id> pdmEnabledproductIds) {
    Map<Id, List<String>> prodIdToBundleFeature = new Map<Id, List<String>>(); // to store bundle features corresponding to productId
    //List<Product_Feature__c> pdmFeature = [SELECT id, Feature__c, Product_Name__c FROM Product_Feature__c];
    for (Product_Feature__c pf : [
      SELECT id, Feature__c, Product_Name__c
      FROM Product_Feature__c
      WHERE Product_Name__c IN :pdmEnabledproductIds
    ]) {
      if (!prodIdToBundleFeature.containsKey(pf.Product_Name__c)) {
        prodIdToBundleFeature.put(pf.Product_Name__c, new List<String>());
      }

      prodIdToBundleFeature.get(pf.Product_Name__c).add(pf.Feature__c);
    }
    return prodIdToBundleFeature;
  }
}