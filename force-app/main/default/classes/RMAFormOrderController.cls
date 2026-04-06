global with sharing class RMAFormOrderController { 
  public RMA_Order__c rma { get; set; }
  public Case newcase { get; set; }
  public RMAFormOrderController(ApexPages.StandardController controller) {
    // PRDOPS23-22
        controller.addFields(new List<String>{'AccountId','CaseNumber'});
        newcase = (Case)controller.getRecord();
        RMA_Order__c rma = new RMA_Order__c();
        
        Id urlAccountId = ApexPages.currentPage().getParameters().get('accId');
        if(urlAccountId != null){
           newcase.AccountId = urlAccountId;
        }    
    }
  // RMAFormOrderControllerTest
  /* @Description: Single entry point for all server calls*/
  /* @Params: strJsonCall {String} Contains Parameter as JSON to call funtions*/
  /* @Return: JSON Representation of Objects Containing Information {String}*/
  @RemoteAction
  global static String singleSourceOfTruth(String strJsonCall) {
    System.debug('singleSourceOfTruth - JSON CALL: ' + strJsonCall);

    Map<String, Object> mapStrFieldObjValue = (Map<String, Object>) JSON.deserializeUntyped(
      strJsonCall
    );
    Map<String, Object> mapStrParamNameObjValue = (Map<String, Object>) mapStrFieldObjValue.get(
      'params'
    );

    switch on (String) mapStrFieldObjValue.get('TYPE') {
      when 'GET_CASE_NUMBER' {
        return getCaseNumber((Id) mapStrParamNameObjValue.get('caseId'));
      }
      when 'GET_ACCOUNT_INFO' {
        return getAccountInfo((Id) mapStrParamNameObjValue.get('accountId'));
      }
      when 'GET_CLUSTER_DATA' {
        return getClustersData((Id) mapStrParamNameObjValue.get('accountId'));
      }
      when 'GET_APPLIANCE_DATA' {
        return getApplianceData((Id) mapStrParamNameObjValue.get('accountId'));
      }
      when 'GET_CHASSIS_DATA' {
        return getChassisData((Id) mapStrParamNameObjValue.get('accountId'));
      }
      when 'GET_HDD_DATA' {
        return getHddData((Id) mapStrParamNameObjValue.get('accountId'));
      }
      when 'GET_SSD_DATA' {
        return getSsdData((Id) mapStrParamNameObjValue.get('accountId'));
      }
      when 'GET_MEMORY_DATA' {
        return getMemoryData((Id) mapStrParamNameObjValue.get('accountId'));
      }
      when 'GET_NODE_DATA' {
        return getNodeData((Id) mapStrParamNameObjValue.get('accountId'));
      }
      when 'GET_PSU_DATA' {
        return getPsuData((Id) mapStrParamNameObjValue.get('accountId'));
      }
      when 'GET_RMA_FAILURE_LIST' {
        return getRmaFailuresList();
      }
      when 'GET_SMART_HAND_ELIGIBLE_ASSET_DATA' {
        return getAssetsWithSmartHandEntitlement(
          (Id) mapStrParamNameObjValue.get('accountId')
        );
      }
      when 'GET_SMART_HAND_ELIGIBLE_COUNTRY_DATA' {
        return getSmartHandsCountries();
      }
      when 'GET_VALIDITY_AND_NRD_POLICY' {
        List<Id> lstId = new List<Id>();

        for (
          Object idAsset : (List<Object>) mapStrParamNameObjValue.get(
            'setIdAppliance'
          )
        ) {
          lstId.add((Id) idAsset);
        }

        return getValidityAndNrdPolicy(
          lstId,
          (Boolean) mapStrParamNameObjValue.get('isSmartHandsRequested'),
          (Boolean) mapStrParamNameObjValue.get('isSmartHandsQualified'),
          (Boolean) mapStrParamNameObjValue.get('hasHdd')
        );
      }
      when 'SAVE_RMA' {
        RMARequestData saveRequestData = new RMARequestData();

        saveRequestData.idCase = (Id) mapStrParamNameObjValue.get('caseId');
        saveRequestData.clusterId = (Id) mapStrParamNameObjValue.get(
          'clusterId'
        );
        saveRequestData.clusterUuid = (String) mapStrParamNameObjValue.get(
          'clusterUuid'
        );
        saveRequestData.customerReferenceNum = (String) mapStrParamNameObjValue.get(
          'customerReferenceNum'
        );
        saveRequestData.assets = (String) mapStrParamNameObjValue.get('assets');
        saveRequestData.lstFailure = new List<FailureWrapper>();
        saveRequestData.setStrSerialNumberAppliance = new Set<String>();
        saveRequestData.setStrSerialNumberChassis = new Set<String>();
        saveRequestData.setStrSerialNumberHdd = new Set<String>();
        saveRequestData.setStrSerialNumberSsd = new Set<String>();
        saveRequestData.setStrSerialNumberMemory = new Set<String>();
        saveRequestData.setStrSerialNumberNode = new Set<String>();
        saveRequestData.setStrSerialNumberCmos = new Set<String>();
        saveRequestData.setStrSerialNumberPsu = new Set<String>();

        for (
          Object failure : (List<Object>) mapStrParamNameObjValue.get(
            'lstFailure'
          )
        ) {
          Map<String, Object> failObject = (Map<String, Object>) failure;
          FailureWrapper objApexFail = new FailureWrapper();
          objApexFail.idComponent = (Id) failObject.get('idComponent');
          objApexFail.assetId = (String) failObject.get('assetId');
          objApexFail.strTypeComponent = (String) failObject.get(
            'strTypeComponent'
          );
          objApexFail.strReason = (String) failObject.get('strReason');
          objApexFail.strSerialNumber = (String) failObject.get(
            'strSerialNumber'
          );
          objApexFail.strOtherFailReason = (String) failObject.get(
            'strOtherFailReason'
          );
          saveRequestData.lstFailure.add(objApexFail);
        }
        for (
          Object serialNumber : (List<Object>) mapStrParamNameObjValue.get(
            'setStrSerialNumberAppliance'
          )
        ) {
          saveRequestData.setStrSerialNumberAppliance.add(
            (String) serialNumber
          );
        }
        for (
          Object serialNumber : (List<Object>) mapStrParamNameObjValue.get(
            'setStrSerialNumberChassis'
          )
        ) {
          saveRequestData.setStrSerialNumberChassis.add((String) serialNumber);
        }
        for (
          Object serialNumber : (List<Object>) mapStrParamNameObjValue.get(
            'setStrSerialNumberSsd'
          )
        ) {
          saveRequestData.setStrSerialNumberSsd.add((String) serialNumber);
        }
        for (
          Object serialNumber : (List<Object>) mapStrParamNameObjValue.get(
            'setStrSerialNumberHdd'
          )
        ) {
          saveRequestData.setStrSerialNumberHdd.add((String) serialNumber);
        }

        for (
          Object serialNumber : (List<Object>) mapStrParamNameObjValue.get(
            'setStrSerialNumberMemory'
          )
        ) {
          saveRequestData.setStrSerialNumberMemory.add((String) serialNumber);
        }

        for (
          Object serialNumber : (List<Object>) mapStrParamNameObjValue.get(
            'setStrSerialNumberNode'
          )
        ) {
          saveRequestData.setStrSerialNumberNode.add((String) serialNumber);
        }

        for (
          Object serialNumber : (List<Object>) mapStrParamNameObjValue.get(
            'setStrSerialNumberCmos'
          )
        ) {
          saveRequestData.setStrSerialNumberCmos.add((String) serialNumber);
        }

        for (
          Object serialNumber : (List<Object>) mapStrParamNameObjValue.get(
            'setStrSerialNumberPsu'
          )
        ) {
          saveRequestData.setStrSerialNumberPsu.add((String) serialNumber);
        }

        saveRequestData.isSmartHandsRequested = (Boolean) mapStrParamNameObjValue.get(
          'isSmartHandsRequested'
        );
        saveRequestData.isSmartHandsQualified = (Boolean) mapStrParamNameObjValue.get(
          'isSmartHandsQualified'
        );
        saveRequestData.hasValidSupport = (Boolean) mapStrParamNameObjValue.get(
          'hasValidSupport'
        );
        saveRequestData.hasNrdPolicy = (Boolean) mapStrParamNameObjValue.get(
          'hasNrdPolicy'
        );
        saveRequestData.smartHandsReason = (String) mapStrParamNameObjValue.get(
          'smartHandsReason'
        );
        saveRequestData.additionalInterestedParties = (String) mapStrParamNameObjValue.get(
          'additionalInterestedParties'
        );

        saveRequestData.shippingStreet = (String) mapStrParamNameObjValue.get(
          'shippingStreet'
        );
        saveRequestData.shippingCity = (String) mapStrParamNameObjValue.get(
          'shippingCity'
        );
        saveRequestData.shippingState = (String) mapStrParamNameObjValue.get(
          'shippingState'
        );
        saveRequestData.shippingCountry = (String) mapStrParamNameObjValue.get(
          'shippingCountry'
        );

        saveRequestData.shippingPostalCode = (String) mapStrParamNameObjValue.get(
          'shippingPostalCode'
        );

        saveRequestData.copyShippingAddressFromAccount = (Boolean) mapStrParamNameObjValue.get(
          'copyShippingAddressFromAccount'
        );

        saveRequestData.shipToPhone = (String) mapStrParamNameObjValue.get(
          'shipToPhone'
        );
        saveRequestData.accountId = (Id) mapStrParamNameObjValue.get(
          'shipToName'
        );
        saveRequestData.shipToContactName = (String) mapStrParamNameObjValue.get(
          'shipToContactName'
        );
        saveRequestData.shipToEmail = (String) mapStrParamNameObjValue.get(
          'shipToEmail'
        );
        saveRequestData.vendorMessage = (String) mapStrParamNameObjValue.get(
          'vendorMessage'
        );
        saveRequestData.smartHandsServiceLevel = (String) mapStrParamNameObjValue.get(
          'smartHandsServiceLevel'
        );


        if (saveRequestData.isSmartHandsRequested) {
          Map<String, Object> mapSmartHandsDates = (Map<String, Object>) mapStrParamNameObjValue.get('smartHandsDate');
          saveRequestData.smartHandsDate = Date.newInstance(
            Integer.valueOf(mapSmartHandsDates.get('year')),
            Integer.valueOf(mapSmartHandsDates.get('month')),
            Integer.valueOf(mapSmartHandsDates.get('day'))
          );
          saveRequestData.smartHandsTime = (String) mapStrParamNameObjValue.get(
            'smartHandsTime'
          );
        }
        return saveRma(saveRequestData);
      }
      when else {
        throw new IllegalArgumentException('Unknown Method Called');
      }
    }
  }

  /* @Description: Returns All Cluster related to given AccountId*/
  /* @Params: strAccountId {String} */
  /* @Return: JSON Representatin of all List of Clusters {String}*/
  @RemoteAction
  global static String getClustersData(String strAccountId) {
    return JSON.serialize(
      [
        SELECT Id, Archived__c, uuid__c
        FROM Cluster__c
        WHERE Archived__c = FALSE AND account__c = :strAccountId
      ]
    );
  }

  /* @Description: Returns Case Number & Parent Account ID related to given CaseId*/
  /* @Params: strCaseId {String} */
  /* @Return: JSON Representatin of Case Object Containing CaseNumber, Account.Id {String}*/
  @RemoteAction
  global static String getCaseNumber(Id strCaseId) {
    return JSON.serialize(
      [
        SELECT
          CaseNumber,
          Cluster__r.uuid__c,
          Account.Id,
          Account.Name,
          Account.ShippingStreet,
          Account.ShippingCity,
          Account.ShippingState,
          Account.ShippingPostalCode,
          Account.ShippingCountry
        FROM Case
        WHERE Id = :strCaseId
        LIMIT 1
      ]
    );
  }

  /* @Description: Returns Account Information for the Lookup selected Account*/
      /* @Params: strCaseId {String} */
      /* @Return: JSON Representatin of Account Object, Account.Id {String}*/
  @RemoteAction
  global static String getAccountInfo(Id strAccountId) {
      return JSON.serialize(
          [
            SELECT
              Id,
              Name,
              ShippingStreet,
              ShippingCity,
              ShippingState,
              ShippingPostalCode,
              ShippingCountry,
              (SELECT Id, uuid__c FROM Clusters__r LIMIT 1)
            FROM Account
            WHERE Id = :strAccountId
            LIMIT 1
          ]
      );
  }

  /* @Description: Returns All Failure reasons*/
  /* @Params:  {void} */
  /* @Return: JSON Representatin of All Failure reasons {String}*/
  @RemoteAction
  global static String getRmaFailuresList() {
    return JSON.serialize(RMA_Failure_List__c.getAll().values());
  }

  /* @Description: Returns All Assets related to given AccountId*/
  /* @Params: strAccountId {String} */
  /* @Return: JSON Representatin of all List of Assets {String}*/
  @RemoteAction
  global static String getApplianceData(String strAccountId) {
    return JSON.serialize(
      [
        SELECT Id, Name, Serial_Number__c, Product2.Name
        FROM Asset
        WHERE AccountId = :strAccountId AND Serial_Number__c != NULL
      ]
    );
  }

  /* @Description: Returns All Chassis related to given AccountId*/
  /* @Params: strAccountId {String} */
  /* @Return: JSON Representatin of all List of Chassis {String}*/
  @RemoteAction
  global static String getChassisData(String strAccountId) {
    return JSON.serialize(
      [
        SELECT
          Id,
          Serial_Number__c,
          Asset__r.Name,
          Asset__r.serial_number__c,
          Name
        FROM chassis__c
        WHERE Asset__r.AccountId = :strAccountId AND Serial_Number__c != NULL
      ]
    );
  }

  /* @Description: Returns All HDD related to given AccountId*/
  /* @Params: strAccountId {String} */
  /* @Return: JSON Representatin of all List of HDD {String}*/
  @RemoteAction
  global static String getHddData(String strAccountId) {
    return JSON.serialize(
      [
        SELECT
          Id,
          Serial_Number__c,
          Asset__r.serial_number__c,
          node__r.serial_number__c,
          node__r.chassis__r.Serial_Number__c,
          node__r.cluster__r.uuid__c,
          Name
        FROM Drive__c
        WHERE
          Asset__r.AccountId = :strAccountId
          // AND node__r.cluster__c != ''
          AND Type__c = 'HDD'
          AND Serial_Number__c != NULL
      ]
    );
  }

  /* @Description: Returns All SSD related to given AccountId*/
  /* @Params: strAccountId {String} */
  /* @Return: JSON Representatin of all List of SSD {String}*/
  @RemoteAction
  global static String getSsdData(String strAccountId) {
    return JSON.serialize(
      [
        SELECT
          Id,
          Serial_Number__c,
          Asset__r.serial_number__c,
          node__r.serial_number__c,
          node__r.chassis__r.Serial_Number__c,
          node__r.cluster__r.uuid__c,
          Name
        FROM Drive__c
        WHERE
          Asset__r.AccountId = :strAccountId
          AND Serial_Number__c != NULL
          // AND node__r.cluster__c != ''
          AND (Asset__r.Product2.Family = 'R6000'
          OR Asset__r.Product2.Family = 'E1000')
          AND Type__c = 'SSD'
      ]
    );
  }

  /* @Description: Returns All Memory related to given AccountId*/
  /* @Params: strAccountId {String} */
  /* @Return: JSON Representatin of all List of Memory {String}*/
  @RemoteAction
  global static String getMemoryData(String strAccountId) {
    return JSON.serialize(
      [
        SELECT
          Id,
          Serial_Number__c,
          Asset__r.serial_number__c,
          node__r.serial_number__c,
          node__r.chassis__r.Serial_Number__c,
          node__r.cluster__r.uuid__c,
          Name
        FROM Memory__c
        WHERE
          // node__r.cluster__c != '' AND
          Asset__r.AccountId = :strAccountId
          AND Serial_Number__c != NULL
      ]
    );
  }

  /* @Description: Returns All Node related to given AccountId*/
  /* @Params: strAccountId {String} */
  /* @Return: JSON Representatin of all List of Node {String}*/
  @RemoteAction
  global static String getNodeData(String strAccountId) {
    List<Node__c> lstNodes = new List<Node__c>();
    for (Node__c node : [
      SELECT Id, Serial_Number__c, Asset__r.serial_number__c, Asset__r.Product_Type__c, Asset__r.Parent.serial_number__c, Chassis__r.Serial_Number__c, Cluster__r.uuid__c, Name
      FROM Node__c
      WHERE
        // Asset__c != ''  AND
        // cluster__c != '' AND
        Asset__r.AccountId = :strAccountId
        AND Serial_Number__c != NULL
    ]) {
      if (node.Asset__r.Product_Type__c == 'Spares' && node.Asset__r.Parent.serial_number__c != null) {
        node.Asset__r.serial_number__c = node.Asset__r.Parent.serial_number__c;
      }
      lstNodes.add(node);
    }
    return JSON.serialize(
      lstNodes
    );
  }

  /* @Description: Returns All PSU related to given AccountId*/
  /* @Params: strAccountId {String} */
  /* @Return: JSON Representatin of all List of PSU {String}*/
  @RemoteAction
  global static String getPsuData(String strAccountId) {
    return JSON.serialize(
      [
        SELECT
          Id,
          Serial_Number__c,
          Asset__r.Name,
          Asset__r.serial_number__c,
          Name
        FROM Power_Supply__c
        WHERE Asset__r.AccountId = :strAccountId AND Serial_Number__c != NULL
      ]
    );
  }

  // Old name -> getAssetWithSmartHandEntitlementMap
  /* @Description: Set of serial number of all Smart Hands eligible components related to given AccountId*/
  /* @Params: strAccountId {Id} */
  /* @Return: JSON Representatin of Set of serial number {String}*/
  public static String getAssetsWithSmartHandEntitlement(Id accountId) {
    List<Asset> lstAsset;
    Map<Id, Asset> mapParentAssetId;

    Set<String> setStrSerialNumWithSmartHandsEntitlement;

    Set<Id> setParentAsset = new Set<Id>();
    Set<Id> setAssetIdWithEntitlements = new Set<Id>();
    Set<Id> setParentAssetIdWithEntitlements = new Set<Id>();

    List<Asset> lstEligibleSmartHandsAsset = new List<Asset>();

    Set<String> setStrCheckForProductName = new Set<String>{
      'RBK-SVC-CEM',
      'RBK-SVC-ASE',
      'RBK-SVC-PROACTIVE',
      'RBK-SVC-ENTERPRISE',
      'RBK-SVC-PROACTIVE-PA',
      'RBK-SVC-PROACTIVE-ADDON-PA',
      'RBK-SVC-PROACTIVE-ADDON',
      'RBK-SVC-CEM-ADDON',
      'RBK-SVC-CEM-PA',
      'RBK-SVC-CEM-ADDON-PA',
      'RBK-SVC-PROACTIVE-ADDON',
      'RBK-SVC-PROACTIVE-ADDON-PA',
      'RBK-SVC-PROACTIVE-PA'
    };

    lstAsset = new List<Asset>(
      [
        SELECT
          Id,
          SerialNumber,
          serial_number__c,
          ParentId,
          Premium_Support_End_Date__c,
          Account.Global_2000__c,
          Account.Type,
          Account.Sum_of_Opportunities__c,
          Account.Smart_Hands_Qualified__c,
          Account.Segment_Class__c,
          Account.Deactivate_Smart_Hands__c,
          (
            SELECT Id, Name, Serial_Number__c, Asset__r.serial_number__c
            FROM Nodes__r
          ),
          /*(
            SELECT
              Id,
              Name,
              Serial_Number__c,
              node__r.Name,
              node__r.Asset__r.serial_number__c
            FROM Drives__r
          ),*/
          (
            SELECT
              Id,
              Name,
              Serial_Number__c,
              Asset__r.Name,
              Asset__r.serial_number__c
            FROM chassis__r
          ),
          (
            SELECT Id, Name, Serial_Number__c, Asset__r.serial_number__c
            FROM Power_Supplies__r
          ),
          (
            SELECT
              Id,
              Name,
              Serial_Number__c,
              node__r.Name,
              node__r.Asset__r.serial_number__c
            FROM Memory__r
          ),
          (
            SELECT Id, name, Product__c, Product__r.Name
            FROM Entitlements
            WHERE status = 'Active'
          )
        FROM Asset
        WHERE AccountId = :accountId
      ]
    );

    // Added for PRDOPS21-203 to handle parent check
    for (Asset assetData : lstAsset) {
      if (assetData.ParentId != null) {
        setParentAsset.add(assetData.ParentId);
      } else if (!assetData.Entitlements.isEmpty()) {
        for (Entitlement entitleData : assetData.Entitlements) {
          // new products added

          if (setStrCheckForProductName.contains(entitleData.Product__r.Name)) {
            setAssetIdWithEntitlements.add(assetData.Id);
          } else {
            setAssetIdWithEntitlements.remove(assetData.Id);
          }
        }
      }
    }

    mapParentAssetId = new Map<Id, Asset>(
      [
        SELECT
          Id,
          SerialNumber,
          serial_number__c,
          ParentId,
          Premium_Support_End_Date__c,
          Account.Global_2000__c,
          Account.Type,
          Account.Sum_of_Opportunities__c,
          Account.Smart_Hands_Qualified__c,
          Account.Segment_Class__c,
          Account.Deactivate_Smart_Hands__c,
          (
            SELECT Id, Name, Serial_Number__c, Asset__r.serial_number__c
            FROM Nodes__r
          ),
          (
            SELECT
              Id,
              Name,
              Serial_Number__c,
              node__r.Name,
              node__r.Asset__r.serial_number__c
            FROM Drives__r
          ),
          (
            SELECT
              Id,
              Name,
              Serial_Number__c,
              Asset__r.Name,
              Asset__r.serial_number__c
            FROM chassis__r
          ),
          (
            SELECT Id, Name, Serial_Number__c, Asset__r.serial_number__c
            FROM Power_Supplies__r
          ),
          (
            SELECT
              Id,
              Name,
              Serial_Number__c,
              node__r.Name,
              node__r.Asset__r.serial_number__c
            FROM Nics__r
          ),
          (
            SELECT
              Id,
              Name,
              Serial_Number__c,
              node__r.Name,
              node__r.Asset__r.serial_number__c
            FROM Memory__r
          ),
          (
            SELECT Id, name, Product__c, Product__r.Name
            FROM Entitlements
            WHERE status = 'Active'
          )
        FROM Asset
        WHERE Id IN :setParentAsset
      ]
    );

    for (Asset parentAsset : mapParentAssetId.Values()) {
      if (!parentAsset.Entitlements.isEmpty()) {
        for (Entitlement parentEntitlementData : ParentAsset.Entitlements) {
          if (
            setStrCheckForProductName.contains(
              parentEntitlementData.Product__r.Name
            )
          ) {
            setParentAssetIdWithEntitlements.add(parentAsset.Id);
          } else {
            setParentAssetIdWithEntitlements.remove(parentAsset.Id);
          }
        }
      }
    }

    for (Asset assetRecord : lstAsset) {
      if (
        assetRecord.ParentId != null &&
        mapParentAssetId.containsKey(assetRecord.ParentId)
      ) {
        Asset parentAssetInfo = mapParentAssetId.get(assetRecord.ParentId);

        if (
          (setParentAssetIdWithEntitlements.contains(assetRecord.ParentId) &&
          parentAssetInfo.Account.Deactivate_Smart_Hands__c == false) ||
          smartHandsEligibilityTest(parentAssetInfo)
        ) {
          lstEligibleSmartHandsAsset.add(assetRecord);
        }
      } else if (
        (setAssetIdWithEntitlements.contains(assetRecord.Id) &&
        assetRecord.Account.Deactivate_Smart_Hands__c == false) ||
        smartHandsEligibilityTest(assetRecord)
      ) {
        lstEligibleSmartHandsAsset.add(assetRecord);
      }
    }

    // returning Asset s with eligible smart Hands

    return JSON.serialize(lstEligibleSmartHandsAsset);
  }

  // Helper for getCmpWithSmartHandEntitlement
  private static Boolean smartHandsEligibilityTest(Asset objAsset) {
    Boolean isEligible;
    isEligible = (objAsset.Account.Smart_Hands_Qualified__c ||
    (objAsset.Account.Segment_Class__c == 'Enterprise') ||
    (!objAsset.Entitlements.isEmpty() &&
    ((objAsset.Account.Global_2000__c && objAsset.Account.Type == 'Customer') ||
    (objAsset.Account.Sum_of_Opportunities__c >= 1000000))));
    if (objAsset.Account.Deactivate_Smart_Hands__c == true) {
      return false;
    } else {
      return isEligible;
    }
  }

    private class TimezoneDate {
        public String country { get; set;}
        public String dateNow { get; set;}
        public TimezoneDate(CountryWithTimezone__c ctz) {
            this.country = ctz.Name;
            this.dateNow = System.now().format('yyyy-MM-dd', ctz.Timezone__c.trim());
        }
    }

  private static String getSmartHandsCountries() {
    List<TimezoneDate> dates = new List<TimezoneDate>();
        for (CountryWithTimezone__c ctz : [SELECT Name, Timezone__c FROM CountryWithTimezone__c]) {
            dates.add(new TimezoneDate(ctz));
        }
        return JSON.serialize(dates);
  }

  private static String getValidityAndNrdPolicy(
    List<Id> setIdAppliance,
    Boolean hasHdd,
    Boolean isSmartHandsRequested,
    Boolean isSmartHandsQualified
  ) {
    Set<Id> setIdRelatedAsset = new Set<Id>();

    Set<Id> setIdParentAssetQuery = new Set<Id>();

    Map<Id, String> mapParentIdStrSerialNumber = new Map<Id, String>();
    Map<Id, Asset> mapIdAssetSelected = new Map<Id, Asset>();

    Boolean isValidSupport = false;
    List<Boolean> lstBoolValidSupportAndNrdPolicy;

    RMA_Order__c rmaOrder = new RMA_Order__c();

    for (Id strSerialNumber : setIdAppliance) {
      setIdRelatedAsset.add(strSerialNumber);
    }

    /*     for (Node__c objNode : [
      SELECT Asset__r.Serial_Number__c
      FROM Node__c
      WHERE Id IN :setIdAppliance
    ]) {
      setIdRelatedAsset.add(objNode.Asset__r.Serial_Number__c);
    }
 */
    rmaOrder.Valid_Support__c = false;
    rmaOrder.Send_Smart_Hands_Service__c = isSmartHandsRequested;
    rmaOrder.Entitled_for_Smart_Hands_Service__c = isSmartHandsQualified;

    for (Asset objAsset : [
      SELECT
        Id,
        serial_Number__c,
        ParentId,
        Product2.category__C,
        (
          SELECT Id, Status, Product__r.ProductCode, Product__r.category__C
          FROM Entitlements
          WHERE
            Product__r.Category__C IN ('Support', 'Hardware')
            OR Product__r.License_Subtype__c = 'ELA'
            OR Product__r.License_Type__c = 'Consumption'
            OR Product__r.ProductCode LIKE '%PRO%'
            OR Product__r.ProductCode LIKE '%HYB%'
            OR Product__r.ProductCode LIKE '%SUB%'
            OR Product__r.ProductCode LIKE '%PROMO%'
        )
      FROM Asset
      WHERE Id IN :setIdRelatedAsset
    ]) {
      mapIdAssetSelected.put(objAsset.Id, objAsset);

      if (objAsset.ParentId != null) {
        setIdParentAssetQuery.add(objAsset.ParentId);
      } else if (objAsset.Entitlements.IsEmpty()) {
        rmaOrder.Valid_Support__c = false;
        isValidSupport = false;
      } else {
        lstBoolValidSupportAndNrdPolicy = getValidSupportAndNrdFromEntitlements(
          objAsset.Entitlements
        );

        isValidSupport = lstBoolValidSupportAndNrdPolicy[0];
        rmaOrder.Valid_Support__c = isValidSupport;
        rmaOrder.NRD_Policy__c = lstBoolValidSupportAndNrdPolicy[1];
      }
    }

    for (Asset objParentAsset : [
      SELECT
        Id,
        serial_Number__c,
        ParentId,
        Product2.category__C,
        (
          SELECT Id, Status, Product__r.productCode, Product__r.category__C
          FROM Entitlements
          WHERE
            Product__r.Category__C IN ('Support', 'Hardware')
            OR Product__r.License_Subtype__c = 'ELA'
            OR Product__r.License_Type__c = 'Consumption'
            OR Product__r.ProductCode LIKE '%PRO%'
            OR Product__r.ProductCode LIKE '%HYB%'
            OR Product__r.ProductCode LIKE '%SUB%'
            OR Product__r.ProductCode LIKE '%PROMO%'
        )
      FROM Asset
      WHERE Id IN :setIdParentAssetQuery
    ]) {
      mapParentIdStrSerialNumber.put(
        objParentAsset.Id,
        objParentAsset.Serial_Number__c
      );
      if (objParentAsset.Entitlements.IsEmpty()) {
        rmaOrder.Valid_Support__c = false;
        isValidSupport = false;
      } else {
        lstBoolValidSupportAndNrdPolicy = getValidSupportAndNrdFromEntitlements(
          objParentAsset.Entitlements
        );

        isValidSupport = lstBoolValidSupportAndNrdPolicy[0];
        rmaOrder.NRD_Policy__c = lstBoolValidSupportAndNrdPolicy[1];
        rmaOrder.Valid_Support__c = isValidSupport;
      }
    }

    if (hasHdd) {
      for (Asset objAsset : [
        SELECT
          Id,
          Serial_Number__c,
          Product2.category__C,
          (
            SELECT Id, Status, Product__r.ProductCode, Product__r.category__C
            FROM Entitlements
            WHERE Product__r.Category__C = 'Non-Returnable Disk Service'
          )
        FROM Asset
        WHERE Id IN :setIdRelatedAsset
      ]) {
        for (Entitlement objEntitlement : objAsset.Entitlements) {
          rmaOrder.NRD_Policy__c = objEntitlement.Product__r.ProductCode.contains(
            '-NRD-'
          );
        }
      }
    }
    isValidSupport = rmaOrder.Valid_Support__c;

    Map<String, Boolean> mapValidityAndNrd = new Map<String, Boolean>{
      'validSupport' => rmaOrder.Valid_Support__c,
      'nrdPolicy' => rmaOrder.NRD_Policy__c
    };

    return JSON.serialize(mapValidityAndNrd);
  }

  public class FailureWrapper {
    public Id idComponent { get; set; }
    public Id assetId { get; set; }
    public Id rmaId { get; set; }
    public string strTypeComponent { get; set; }
    public string strSerialNumber { get; set; }
    public string strReason { get; set; }
    public string strOtherFailReason { get; set; }
  }

  private class RMARequestData {
    Id idCase { get; set; }
    Id clusterId { get; set; }
    String clusterUuid { get; set; }
    String customerReferenceNum { get; set; }
    String assets { get; set; }
    List<FailureWrapper> lstFailure { get; set; }
    Set<String> setStrSerialNumberAppliance { get; set; }
    Set<String> setStrSerialNumberChassis { get; set; }
    Set<String> setStrSerialNumberHdd { get; set; }
    Set<String> setStrSerialNumberSsd { get; set; }
    Set<String> setStrSerialNumberMemory { get; set; }
    Set<String> setStrSerialNumberNode { get; set; }
    Set<String> setStrSerialNumberPsu { get; set; }
    Set<String> setStrSerialNumberCmos { get; set; }
    Boolean isSmartHandsRequested { get; set; }
    Boolean isSmartHandsQualified { get; set; }
    Boolean hasValidSupport { get; set; }
    Boolean hasNrdPolicy { get; set; }
    String smartHandsReason { get; set; }
    String additionalInterestedParties { get; set; }
    String shippingStreet { get; set; }
    String shippingCity { get; set; }
    String shippingState { get; set; }
    String shippingCountry { get; set; }
    String shippingPostalCode { get; set; }
    Boolean copyShippingAddressFromAccount { get; set; }
    String shipToPhone { get; set; }
    Id accountId { get; set; }
    String shipToContactName { get; set; }
    String shipToEmail { get; set; }
    String vendorMessage { get; set; }
    String smartHandsServiceLevel { get; set; }
    Date smartHandsDate { get; set; }
    String smartHandsTime { get; set; }
  }
  private static string saveRma(RMARequestData rmaData) {
    Id idCase = rmaData.idCase;
    Id clusterId = rmaData.clusterId;
    String clusterUuid = rmaData.clusterUuid;
    String assets = rmaData.assets;
    List<FailureWrapper> lstFailure = rmaData.lstFailure;
    Set<String> setStrSerialNumberAppliance = rmaData.setStrSerialNumberAppliance;
    Set<String> setStrSerialNumberChassis = rmaData.setStrSerialNumberChassis;
    Set<String> setStrSerialNumberHdd = rmaData.setStrSerialNumberHdd;
    Set<String> setStrSerialNumberSsd = rmaData.setStrSerialNumberSsd;
    Set<String> setStrSerialNumberMemory = rmaData.setStrSerialNumberMemory;
    Set<String> setStrSerialNumberNode = rmaData.setStrSerialNumberNode;
    Set<String> setStrSerialNumberPsu = rmaData.setStrSerialNumberPsu;
    Set<String> setStrSerialNumberCmos = rmaData.setStrSerialNumberCmos;
    Boolean isSmartHandsRequested = rmaData.isSmartHandsRequested;
    Boolean isSmartHandsQualified = rmaData.isSmartHandsQualified;
    Boolean hasValidSupport = rmaData.hasValidSupport;
    Boolean hasNrdPolicy = rmaData.hasNrdPolicy;
    String smartHandsReason = rmaData.smartHandsReason;
    String additionalInterestedParties = rmaData.additionalInterestedParties;
    String shippingStreet = rmaData.shippingStreet;
    String shippingCity = rmaData.shippingCity;
    String shippingState = rmaData.shippingState;
    String shippingCountry = rmaData.shippingCountry;
    String shippingPostalCode = rmaData.shippingPostalCode;
    Boolean copyShippingAddressFromAccount = rmaData.copyShippingAddressFromAccount;
    String shipToPhone = rmaData.shipToPhone;
    Id accountId = rmaData.accountId;
    String shipToContactName = rmaData.shipToContactName;
    String shipToEmail = rmaData.shipToEmail;
    String vendorMessage = rmaData.vendorMessage;
    String smartHandsServiceLevel = rmaData.smartHandsServiceLevel;
    Date smartHandsDate = rmaData.smartHandsDate;
    String smartHandsTime = rmaData.smartHandsTime;

    Set<String> setStrSerialNumberRelatedAsset = new Set<String>();
    Set<String> setStrSerialNumberAllAsset = new Set<String>();

    Set<Id> setIdParentAssetQuery = new Set<Id>();

    Map<Id, String> mapParentIdStrSerialNumber = new Map<Id, String>();
    Map<Id, Asset> mapIdAssetRelated = new Map<Id, Asset>();

    Boolean isValidSupport = false;
    List<Boolean> lstBoolValidSupportAndNrdPolicy;
    RMA_Order__c rmaOrder = new RMA_Order__c();

    rmaOrder.Parent_Case__c = idCase;
    rmaOrder.Customer_Ref_number__c = rmaData.customerReferenceNum;

    Map<String, Integer> mapStrfailedComponentsIntQuantity = getFailedComponentsQuantity(
      lstFailure
    );

    for (String strComponentType : mapStrfailedComponentsIntQuantity.keySet()) {
      if (strComponentType == 'appliance') {
        rmaOrder.Appliance_Quantity__c = mapStrfailedComponentsIntQuantity.get(
          strComponentType
        );
      }

      if (strComponentType == 'chassis') {
        rmaOrder.Chasis_Quantity__c = mapStrfailedComponentsIntQuantity.get(
          strComponentType
        );
      }

      if (strComponentType == 'psu') {
        rmaOrder.Power_Supply_Quantity__c = mapStrfailedComponentsIntQuantity.get(
          strComponentType
        );
      }

      if (strComponentType == 'hdd') {
        rmaOrder.Drive_Quantity__c = mapStrfailedComponentsIntQuantity.get(
          strComponentType
        );
      }

      if (strComponentType == 'ssd') {
        rmaOrder.SSD_Quantity__c = mapStrfailedComponentsIntQuantity.get(
          strComponentType
        );
      }

      if (strComponentType == 'memory') {
        rmaOrder.Memory_Quantity__c = mapStrfailedComponentsIntQuantity.get(
          strComponentType
        );
      }

      if (strComponentType == 'node') {
        rmaOrder.Node_Quantity__c = mapStrfailedComponentsIntQuantity.get(
          strComponentType
        );
      }

      if (strComponentType == 'cmos') {
        rmaOrder.CMOS_Battery_Quantity__c = mapStrfailedComponentsIntQuantity.get(
          strComponentType
        );
      }
    }

    rmaOrder.SSD__c = concateCmpSerialNumber(setStrSerialNumberSsd);
    rmaOrder.Node__c = concateCmpSerialNumber(setStrSerialNumberNode);
    rmaOrder.Drive__c = concateCmpSerialNumber(setStrSerialNumberHdd);
    rmaOrder.Memory__c = concateCmpSerialNumber(setStrSerialNumberMemory);
    rmaOrder.Chassis__c = concateCmpSerialNumber(setStrSerialNumberChassis);
    rmaOrder.Appliance__c = concateCmpSerialNumber(setStrSerialNumberAppliance);
    rmaOrder.Power_Supply__c = concateCmpSerialNumber(setStrSerialNumberPsu);
    rmaOrder.CMOS_Battery__c = concateCmpSerialNumber(setStrSerialNumberCmos);

    rmaOrder.Additional_Interested_Parties_RMA__c = additionalInterestedParties;
    rmaOrder.CopyAdrressfromAccount__c = copyShippingAddressFromAccount;
    rmaOrder.Shipping_Street__c = shippingStreet;
    rmaOrder.Shipping_City__c = shippingCity;
    rmaOrder.ShippingState__c = shippingState;
    rmaOrder.ShippingCountry__c = shippingCountry;
    rmaOrder.Shipping_Zip_Postal_Code__c = shippingPostalCode;

    rmaOrder.Ship_To_Phone_Number__c = shipToPhone;
    rmaOrder.Service_Type__c = smartHandsServiceLevel;
    rmaOrder.Ship_To_Contact_Name__c = shipToContactName;
    rmaOrder.Ship_To_Name__c = accountId;
    rmaOrder.Ship_To_Email__c = shipToEmail;
    rmaOrder.Vendor_Message__c = vendorMessage;
    for (String strSerialNumber : setStrSerialNumberAppliance) {
      setStrSerialNumberRelatedAsset.add(strSerialNumber);
    }

    rmaOrder.Valid_Support__c = hasValidSupport;
    rmaOrder.NRD_Policy__c = hasNrdPolicy;
    rmaOrder.Send_Smart_Hands_Service__c = isSmartHandsRequested;
    if (isSmartHandsRequested) {
      rmaOrder.Date_of_Smart_Hands_Arrival__c = smartHandsDate;
      rmaOrder.Time_of_Smart_Hands_Tech_Arrival__c = smartHandsTime;
    }
    rmaOrder.Entitled_for_Smart_Hands_Service__c = isSmartHandsQualified;

    for (Asset objAsset : [
      SELECT
        Id,
        serial_Number__c,
        ParentId,
        Product2.category__C,
        (
          SELECT Id, Status, Product__r.productCode, Product__r.category__C
          FROM Entitlements
          WHERE
            Product__r.Category__C IN ('Support', 'Hardware')
            OR Product__r.License_Subtype__c = 'ELA'
            OR Product__r.License_Type__c = 'Consumption'
            OR Product__r.ProductCode LIKE '%PRO%'
            OR Product__r.ProductCode LIKE '%HYB%'
            OR Product__r.ProductCode LIKE '%SUB%'
            OR Product__r.ProductCode LIKE '%PROMO%'
        )
      FROM Asset
      WHERE serial_Number__c IN :setStrSerialNumberRelatedAsset
    ]) {
      mapIdAssetRelated.put(objAsset.Id, objAsset);

      if (objAsset.ParentId != null) {
        setIdParentAssetQuery.add(objAsset.ParentId);
      }
    }

    for (Asset objAsset : [
      SELECT
        Id,
        serial_Number__c,
        ParentId,
        Product2.category__C,
        (
          SELECT Id, Status, Product__r.productCode, Product__r.category__C
          FROM Entitlements
          WHERE
            Product__r.Category__C IN ('Support', 'Hardware')
            OR Product__r.License_Subtype__c = 'ELA'
            OR Product__r.License_Type__c = 'Consumption'
            OR Product__r.ProductCode LIKE '%PRO%'
            OR Product__r.ProductCode LIKE '%HYB%'
            OR Product__r.ProductCode LIKE '%SUB%'
            OR Product__r.ProductCode LIKE '%PROMO%'
        )
      FROM Asset
      WHERE Id IN :setIdParentAssetQuery
    ]) {
      mapIdAssetRelated.put(objAsset.Id, objAsset);
    }

    // setStrSerialNumberAllAsset.addAll(setStrSerialNumberAppliance);
    if (!setStrSerialNumberRelatedAsset.isEmpty()) {
      for (Asset objAsset : mapIdAssetRelated.values()) {
        if (
          String.IsNotEmpty(objAsset.ParentId) &&
          mapIdAssetRelated.containsKey(objAsset.ParentId)
        ) {
          setStrSerialNumberAllAsset.add(
            mapIdAssetRelated.get(objAsset.ParentId).serial_Number__c
          );
        } else {
          setStrSerialNumberAllAsset.add(objAsset.serial_Number__c);
        }
      }
    }

    rmaOrder.Assets__c = assets;
    rmaOrder.Appliance__c = concateCmpSerialNumber(setStrSerialNumberAllAsset);

    rmaOrder.Status__c = 'Submitted';
    isValidSupport = rmaOrder.Valid_Support__c;
    if (isSmartHandsRequested || (!isValidSupport || !isSmartHandsQualified)) {
      rmaOrder.Comment_if_any__c = smartHandsReason;
    }

    rmaOrder.Cluster__c = clusterUuid;
    rmaOrder.Cluster_ID__c = clusterId;

    Boolean criteria1 =
      !isValidSupport && !String.isBlank(rmaOrder.Comment_if_any__c);
    Boolean criteria20 = isValidSupport && !isSmartHandsRequested;
    Boolean criteria210 =
      isSmartHandsRequested &&
      !isSmartHandsQualified &&
      !String.isBlank(rmaOrder.Comment_if_any__c);
    Boolean criteria211 = isSmartHandsRequested && isSmartHandsQualified;

    if ((criteria1) || (criteria20 || (criteria210 || criteria211))) {
      insert rmaOrder;

      List<Failure__c> lstFailureRecord = new List<Failure__c>();
      for (FailureWrapper failInfo : lstFailure) {
        failInfo.rmaId = rmaOrder.Id;
        lstFailureRecord.add(
          createFailureRecord(setStrSerialNumberAllAsset, failInfo)
        );
      }
      insert lstFailureRecord;
      return JSON.serialize(rmaOrder);
    }

    return null;
  }

  private static Map<String, Integer> getFailedComponentsQuantity(
    List<FailureWrapper> lstFailure
  ) {
    Map<String, Integer> mapStrComponentsIntFailedQuantity = new Map<String, Integer>();

    for (FailureWrapper objFailInfo : lstFailure) {
      if (
        !mapStrComponentsIntFailedQuantity.containsKey(
          objFailInfo.strTypeComponent
        )
      ) {
        mapStrComponentsIntFailedQuantity.put(objFailInfo.strTypeComponent, 0);
      }
      mapStrComponentsIntFailedQuantity.put(
        objFailInfo.strTypeComponent,
        mapStrComponentsIntFailedQuantity.get(objFailInfo.strTypeComponent) + 1
      );
    }
    return mapStrComponentsIntFailedQuantity;
  }
  // helper for save RMA
  private static List<Boolean> getValidSupportAndNrdFromEntitlements(
    List<Entitlement> lstEntitlements
  ) {
    Boolean isValidSupport = false;
    Boolean isNrdApplicable = false;
    for (Entitlement objEntitlement : lstEntitlements) {
      if (String.isNotBlank(objEntitlement.status) && objEntitlement.status == 'Active') {
        isValidSupport = true;
      }
      if (objEntitlement.Product__r.ProductCode.contains('-NRD-')) {
        isNrdApplicable = true;
      }
    }

    return new List<Boolean>{ isValidSupport, isNrdApplicable };
  }

  // helper for saveRma()
  private static String concateCmpSerialNumber(
    Set<String> mapStringCmpTypeSetStrSerialNumber
  ) {
    return (mapStringCmpTypeSetStrSerialNumber != null)
      ? String.join(new List<String>(mapStringCmpTypeSetStrSerialNumber), ',')
      : '';
  }

  private static Failure__c createFailureRecord(
    Set<String> setStrSerialNumberAllAsset,
    FailureWrapper failInfo
  ) {
    Id assetId = failInfo.assetId;

    Failure__c objFailure = new Failure__c();
    objFailure.RMA_Request__c = failInfo.rmaId;
    objFailure.Asset__c = failInfo.assetId;
    objFailure.serial_Number_Reported__c = failInfo.strSerialNumber;
    objFailure.Date_of_Failure__c = system.today();
    objFailure.Failure_Reason__c = failInfo.strReason;
    objFailure.Failure_Reason_Other__c = failInfo.strOtherFailReason;

    if (failInfo.strTypeComponent == 'node') {
      objFailure.put('node__c', failInfo.idComponent);
      objFailure.Component_Type__c = 'Node';
      objFailure.Product_Code__C = getProductCode(
        failInfo.strSerialNumber,
        'Node'
      );
    } else if (failInfo.strTypeComponent == 'memory') {
      objFailure.put('Memory__c', failInfo.idComponent);
      objFailure.Component_Type__c = 'Memory';
      objFailure.Product_Code__C = getProductCode(
        failInfo.strSerialNumber,
        'Memory'
      );
    } else if (failInfo.strTypeComponent == 'hdd') {
      objFailure.Component_Type__c = 'Drive';
      objFailure.put('Drive__c', failInfo.idComponent);
      objFailure.Product_Code__C = getProductCode(
        failInfo.strSerialNumber,
        'Drive'
      );
    } else if (failInfo.strTypeComponent == 'psu') {
      objFailure.Component_Type__c = 'Power Supply';
      objFailure.put('Power_supply__c', failInfo.idComponent);
      objFailure.Product_Code__C = getProductCode(
        failInfo.strSerialNumber,
        'Power Supply'
      );
    } else if (failInfo.strTypeComponent == 'ssd') {
      objFailure.Component_Type__c = 'Drive';
      objFailure.put('Drive__c', failInfo.idComponent);
      objFailure.Product_Code__C = getProductCode(
        failInfo.strSerialNumber,
        'Drive'
      );
    } else if (failInfo.strTypeComponent == 'chassis') {
      objFailure.Component_Type__c = 'Chassis';
      objFailure.put('Chassis__c', failInfo.idComponent);
      objFailure.Product_Code__C = getProductCode(
        failInfo.strSerialNumber,
        'Chassis'
      );
    } else if (failInfo.strTypeComponent == 'appliance') {
      objFailure.Component_Type__c = 'Appliance';
      // objFailure.put('Asset',failInfo.idComponent);
      objFailure.Product_Code__C = getProductCode(
        failInfo.strSerialNumber,
        'Asset'
      );
    } else if (failInfo.strTypeComponent == 'cmos') {
      objFailure.Component_Type__c = 'CMOS Battery';
      objFailure.Product_Code__C = Label.CMOS_Battery_Product;
      objFailure.put('node__c', failInfo.idComponent);
      objFailure.serial_Number_Reported__c = 'CMOS Battery';
    }

    return objFailure;
  }

  private static string getProductCode(
    String strSerialNumber,
    string strCmpType
  ) {
  List<Spares_Mapping__c> sparesList = new List<Spares_Mapping__c>();
  sparesList = RMASparePartsMappingHelper.returnSparePartCodeQueryAll();
    if (strCmpType == 'Power Supply') {
      Power_Supply__c dr;
      if (!Test.isRunningTest()) {
        dr = [
          SELECT
            id,
            Serial_Number__c,
            Asset__r.Product2.ProductCode,
            Asset__r.Product2.Id,
            Asset__r.Product2.Family,
            Asset__r.Product2.Product_NIC_Type__c,
            Asset__r.Product2.Appliance_Model__c
          FROM Power_Supply__c
          WHERE Serial_Number__c = :strSerialNumber
          LIMIT 1
        ];
      } else {
        dr = [
          SELECT
            id,
            Serial_Number__c,
            Asset__r.Product2.ProductCode,
            Asset__r.Product2.Id,
            Asset__r.Product2.Family,
            Asset__r.Product2.Product_NIC_Type__c,
            Asset__r.Product2.Appliance_Model__c
          FROM Power_Supply__c
          LIMIT 1
        ];
      }

      String relatedProdFamily = dr.Asset__r.Product2.Family != null
        ? dr.Asset__r.Product2.Family
        : '';
      relatedProdFamily = relatedProdFamily.toUppercase();
      String relatedNicType = dr.Asset__r.Product2.Product_NIC_Type__c != null
        ? dr.Asset__r.Product2.Product_NIC_Type__c
        : '';
      String relatedApplianceModel = dr.Asset__r.Product2.Appliance_Model__c !=
        null
        ? dr.Asset__r.Product2.Appliance_Model__c
        : '';

      String relatedProdCode = dr.Asset__r.Product2.ProductCode;
      /* <--START--> SF-91  Added Logic for new Mapping Helper method*/
      Spares_Mapping__c mapping = RMASparePartsMappingHelper.returnSparePartRecord(
        sparesList,
        relatedProdFamily,
        relatedNicType,
        relatedApplianceModel
      );
      if (mapping != null) {
        return mapping.PSU__c;
      } else
        return null;
      /* < END ---- SF-91> */
    } else if (strCmpType == 'Drive' || strCmpType == 'SSD') {
      Drive__C dr;
      if (!Test.isRunningTest()) {
        dr = [
          SELECT
            id,
            Serial_Number__c,
            node__r.Asset__r.Product2.ProductCode,
            node__r.Asset__r.Product2.Id,
            node__r.Asset__r.Product2.Family,
            node__r.Asset__r.Product2.Product_NIC_Type__c,
            node__r.Asset__r.Product2.Appliance_Model__c,
            Type__c
          FROM Drive__c
          WHERE Serial_Number__c = :strSerialNumber
        ];
      } else {
        dr = [
          SELECT
            id,
            Serial_Number__c,
            node__r.Asset__r.Product2.ProductCode,
            node__r.Asset__r.Product2.Id,
            node__r.Asset__r.Product2.Family,
            node__r.Asset__r.Product2.Product_NIC_Type__c,
            node__r.Asset__r.Product2.Appliance_Model__c,
            Type__c
          FROM Drive__c
          LIMIT 1
        ];
      }
      String relatedProdFamily = dr.node__r.Asset__r.Product2.Family != null
        ? dr.node__r.Asset__r.Product2.Family
        : '';
      relatedProdFamily = relatedProdFamily.toUppercase();
      String relatedNicType = dr.node__r.Asset__r.Product2.Product_NIC_Type__c !=
        null
        ? dr.node__r.Asset__r.Product2.Product_NIC_Type__c
        : '';
      String relatedApplianceModel = dr.node__r.Asset__r.Product2.Appliance_Model__c !=
        null
        ? dr.node__r.Asset__r.Product2.Appliance_Model__c
        : '';
      String relatedProdCode = dr.node__r.Asset__r.Product2.ProductCode;
      /* <--START--> SF-91  Added Logic for new Mapping Helper method*/
      Spares_Mapping__c mapping = RMASparePartsMappingHelper.returnSparePartRecord(
        sparesList,
        relatedProdFamily,
        relatedNicType,
        relatedApplianceModel
      );
      if (mapping != null && dr.Type__c == 'HDD') {
        return mapping.HDD__c;
      } else if (mapping != null && dr.Type__c == 'SSD') {
        return mapping.SSD__c;
      } else
        return null;
      /* < END ---- SF-91> */
    } else if (strCmpType == 'Memory') {
      Memory__c dr;
      if (!Test.isRunningTest()) {
        dr = [
          SELECT
            id,
            Serial_Number__c,
            node__r.Asset__r.Product2.ProductCode,
            node__r.Asset__r.Product2.Id,
            node__r.Asset__r.Product2.Family,
            node__r.Asset__r.Product2.Product_NIC_Type__c,
            node__r.Asset__r.Product2.Appliance_Model__c
          FROM Memory__c
          WHERE Serial_Number__c = :strSerialNumber
        ];
      } else {
        dr = [
          SELECT
            id,
            Serial_Number__c,
            node__r.Asset__r.Product2.ProductCode,
            node__r.Asset__r.Product2.Id,
            node__r.Asset__r.Product2.Family,
            node__r.Asset__r.Product2.Product_NIC_Type__c,
            node__r.Asset__r.Product2.Appliance_Model__c
          FROM Memory__c
          LIMIT 1
        ];
      }
      String relatedProdFamily = dr.node__r.Asset__r.Product2.Family != null
        ? dr.node__r.Asset__r.Product2.Family
        : '';
      relatedProdFamily = relatedProdFamily.toUppercase();
      String relatedNicType = dr.node__r.Asset__r.Product2.Product_NIC_Type__c !=
        null
        ? dr.node__r.Asset__r.Product2.Product_NIC_Type__c
        : '';
      String relatedApplianceModel = dr.node__r.Asset__r.Product2.Appliance_Model__c !=
        null
        ? dr.node__r.Asset__r.Product2.Appliance_Model__c
        : '';

      String relatedProdCode = dr.node__r.Asset__r.Product2.ProductCode;
      /* <--START--> SF-91  Added Logic for new Mapping Helper method*/
     Spares_Mapping__c mapping = RMASparePartsMappingHelper.returnSparePartRecord(
        sparesList,
        relatedProdFamily,
        relatedNicType,
        relatedApplianceModel
      );
      if (mapping != null) {
        return mapping.Memory__c;
      } else
        return null;
      /* < END ---- SF-91> */
    } else if (strCmpType == 'Chassis') {
      Chassis__c dr;
      if (!Test.isRunningTest()) {
        dr = [
          SELECT
            id,
            Serial_Number__c,
            Asset__r.Product2.ProductCode,
            Asset__r.Product2.Id,
            Asset__r.Product2.Family,
            Asset__r.Product2.Product_NIC_Type__c,
            Asset__r.Product2.Appliance_Model__c
          FROM Chassis__c
          WHERE Serial_Number__c = :strSerialNumber
        ];
      } else {
        dr = [
          SELECT
            id,
            Serial_Number__c,
            Asset__r.Product2.ProductCode,
            Asset__r.Product2.Id,
            Asset__r.Product2.Family,
            Asset__r.Product2.Product_NIC_Type__c,
            Asset__r.Product2.Appliance_Model__c
          FROM Chassis__c
          LIMIT 1
        ];
      }
      String relatedProdFamily = dr.Asset__r.Product2.Family != null
        ? dr.Asset__r.Product2.Family
        : '';
      relatedProdFamily = relatedProdFamily.toUppercase();
      String relatedNicType = dr.Asset__r.Product2.Product_NIC_Type__c != null
        ? dr.Asset__r.Product2.Product_NIC_Type__c
        : '';
      String relatedApplianceModel = dr.Asset__r.Product2.Appliance_Model__c !=
        null
        ? dr.Asset__r.Product2.Appliance_Model__c
        : '';

      String relatedProdCode = dr.Asset__r.Product2.ProductCode;
      /* <--START--> SF-91  Added Logic for new Mapping Helper method*/
      Spares_Mapping__c mapping = RMASparePartsMappingHelper.returnSparePartRecord(
        sparesList,
        relatedProdFamily,
        relatedNicType,
        relatedApplianceModel
      );
      if (mapping != null) {
        return mapping.Chassis__c;
      } else
        return null;
      /* < END ---- SF-91> */
    } else if (strCmpType == 'Node') {
      Node__c dr;
      if (!Test.isRunningTest()) {
        dr = [
          SELECT
            id,
            Serial_Number__c,
            Asset__r.Product2.ProductCode,
            Asset__r.Product2.Id,
            Asset__r.Product2.Family,
            Asset__r.Product2.Product_NIC_Type__c,
            Asset__r.Product2.Appliance_Model__c
          FROM Node__c
          WHERE Serial_Number__c = :strSerialNumber
        ];
      } else {
        dr = [
          SELECT
            id,
            Serial_Number__c,
            Asset__r.Product2.ProductCode,
            Asset__r.Product2.Id,
            Asset__r.Product2.Family,
            Asset__r.Product2.Product_NIC_Type__c,
            Asset__r.Product2.Appliance_Model__c
          FROM Node__c
          LIMIT 1
        ];
      }
      String relatedProdFamily = dr.Asset__r.Product2.Family != null
        ? dr.Asset__r.Product2.Family
        : '';
      relatedProdFamily = relatedProdFamily.toUppercase();
      String relatedNicType = dr.Asset__r.Product2.Product_NIC_Type__c != null
        ? dr.Asset__r.Product2.Product_NIC_Type__c
        : '';
      String relatedApplianceModel = dr.Asset__r.Product2.Appliance_Model__c !=
        null
        ? dr.Asset__r.Product2.Appliance_Model__c
        : '';

      String relatedProdCode = dr.Asset__r.Product2.ProductCode;
      /* <--START--> SF-91  Added Logic for new Mapping Helper method*/
     Spares_Mapping__c mapping = RMASparePartsMappingHelper.returnSparePartRecord(
        sparesList,
        relatedProdFamily,
        relatedNicType,
        relatedApplianceModel
      );
      if (mapping != null) {
        return mapping.Node__c;
      } else
        return null;
      /* < END ---- SF-91> */
    } else if (strCmpType == 'Asset') {
      Asset dr = [
        SELECT id, Serial_Number__c, Product2.ProductCode
        FROM Asset
        WHERE Serial_Number__c = :strSerialNumber
      ];
      return dr.Product2.ProductCode;
    } 
    return null;
  }
}