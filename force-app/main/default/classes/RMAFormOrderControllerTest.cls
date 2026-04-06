@isTest
public class RMAFormOrderControllerTest {
  @isTest
  private static void getCaseNumber() {
    Case objCase = [
      SELECT Id
      FROM Case
      WHERE Account.Name = 'Test Account'
      LIMIT 1
    ];

    JSONGenerator objJsonGenerator = JSON.createGenerator(false);
    objJsonGenerator.writeStartObject();
    objJsonGenerator.writeStringField('TYPE', 'GET_CASE_NUMBER');

    Map<String, String> mapStrParamsStrValue = new Map<String, String>();
    mapStrParamsStrValue.put('caseId', (String) objCase.Id);
    objJsonGenerator.writeObjectField('params', mapStrParamsStrValue);
    objJsonGenerator.writeEndObject();

    objJsonGenerator.close();
    // {"params":{"caseId":"5006f00001dQm54AAC"},"TYPE":"GET_CASE_NUMBER"}
    String strRequestData = objJsonGenerator.getAsString();
    Test.startTest();
    String strResultData = RMAFormOrderController.singleSourceOfTruth(
      strRequestData
    );
    Test.stopTest();
    System.assert(true, 'message');
  }

  @isTest
  private static void getSmartHandsCountries() {
    JSONGenerator objJsonGenerator = JSON.createGenerator(false);
    objJsonGenerator.writeStartObject();
    objJsonGenerator.writeStringField(
      'TYPE',
      'GET_SMART_HAND_ELIGIBLE_COUNTRY_DATA'
    );

    Map<String, String> mapStrParamsStrValue = new Map<String, String>();
    objJsonGenerator.writeObjectField('params', mapStrParamsStrValue);
    objJsonGenerator.writeEndObject();

    objJsonGenerator.close();
    // {"params":{},"TYPE":"GET_SMART_HAND_ELIGIBLE_COUNTRY_DATA"}
    String strRequestData = objJsonGenerator.getAsString();
    Test.startTest();
    String strResultData = RMAFormOrderController.singleSourceOfTruth(
      strRequestData
    );
    Test.stopTest();
    System.assert(true, 'message');
  }

  @isTest
  private static void getRmaFailuresList() {
    JSONGenerator objJsonGenerator = JSON.createGenerator(false);
    objJsonGenerator.writeStartObject();
    objJsonGenerator.writeStringField('TYPE', 'GET_RMA_FAILURE_LIST');

    Map<String, String> mapStrParamsStrValue = new Map<String, String>();
    objJsonGenerator.writeObjectField('params', mapStrParamsStrValue);
    objJsonGenerator.writeEndObject();

    objJsonGenerator.close();
    // {"params":{},"TYPE":"GET_RMA_FAILURE_LIST"}
    String strRequestData = objJsonGenerator.getAsString();
    Test.startTest();
    String strResultData = RMAFormOrderController.singleSourceOfTruth(
      strRequestData
    );
    Test.stopTest();
    System.assert(true, 'message');
  }

  @isTest
  private static void getAssetsWithSmartHandEntitlement() {
    Account objAccount = [
      SELECT Id
      FROM aCCOUNT
      WHERE Name = 'Test Account'
      LIMIT 1
    ];

    JSONGenerator objJsonGenerator = JSON.createGenerator(false);
    objJsonGenerator.writeStartObject();
    objJsonGenerator.writeStringField(
      'TYPE',
      'GET_SMART_HAND_ELIGIBLE_ASSET_DATA'
    );

    Map<String, String> mapStrParamsStrValue = new Map<String, String>();
    mapStrParamsStrValue.put('accountId', (String) objAccount.Id);
    objJsonGenerator.writeObjectField('params', mapStrParamsStrValue);
    objJsonGenerator.writeEndObject();

    objJsonGenerator.close();
    // {"params":{"accountId":"0014000001eGcByAAK"},"TYPE":"GET_SMART_HAND_ELIGIBLE_ASSET_DATA"}
    String strRequestData = objJsonGenerator.getAsString();
    Test.startTest();
    String strResultData = RMAFormOrderController.singleSourceOfTruth(
      strRequestData
    );
    Test.stopTest();
    System.assert(true, 'message');
  }

  @isTest
  private static void getPsuData() {
    Account objAccount = [
      SELECT Id
      FROM ACCOUNT
      WHERE Name = 'Test Account'
      LIMIT 1
    ];

    JSONGenerator objJsonGenerator = JSON.createGenerator(false);
    objJsonGenerator.writeStartObject();
    objJsonGenerator.writeStringField('TYPE', 'GET_PSU_DATA');

    Map<String, String> mapStrParamsStrValue = new Map<String, String>();
    mapStrParamsStrValue.put('accountId', (String) objAccount.Id);
    objJsonGenerator.writeObjectField('params', mapStrParamsStrValue);
    objJsonGenerator.writeEndObject();

    objJsonGenerator.close();
    // {"params":{"accountId":"0014000001eGcByAAK"},"TYPE":"GET_PSU_DATA"}
    String strRequestData = objJsonGenerator.getAsString();
    Test.startTest();
    String strResultData = RMAFormOrderController.singleSourceOfTruth(
      strRequestData
    );
    Test.stopTest();
    System.assert(true, 'message');
  }

  @isTest
  private static void getNodeData() {
    Account objAccount = [
      SELECT Id
      FROM ACCOUNT
      WHERE Name = 'Test Account'
      LIMIT 1
    ];

    JSONGenerator objJsonGenerator = JSON.createGenerator(false);
    objJsonGenerator.writeStartObject();
    objJsonGenerator.writeStringField('TYPE', 'GET_NODE_DATA');

    Map<String, String> mapStrParamsStrValue = new Map<String, String>();
    mapStrParamsStrValue.put('accountId', (String) objAccount.Id);
    objJsonGenerator.writeObjectField('params', mapStrParamsStrValue);
    objJsonGenerator.writeEndObject();

    objJsonGenerator.close();
    // {"params":{"accountId":"0014000001eGcByAAK"},"TYPE":"GET_NODE_DATA"}
    String strRequestData = objJsonGenerator.getAsString();
    Test.startTest();
    String strResultData = RMAFormOrderController.singleSourceOfTruth(
      strRequestData
    );
    Test.stopTest();
    System.assert(true, 'message');
  }

  @isTest
  private static void getMemoryData() {
    Account objAccount = [
      SELECT Id
      FROM aCCOUNT
      WHERE Name = 'Test Account'
      LIMIT 1
    ];

    JSONGenerator objJsonGenerator = JSON.createGenerator(false);
    objJsonGenerator.writeStartObject();
    objJsonGenerator.writeStringField('TYPE', 'GET_MEMORY_DATA');

    Map<String, String> mapStrParamsStrValue = new Map<String, String>();
    mapStrParamsStrValue.put('accountId', (String) objAccount.Id);
    objJsonGenerator.writeObjectField('params', mapStrParamsStrValue);
    objJsonGenerator.writeEndObject();

    objJsonGenerator.close();
    // {"params":{"accountId":"0014000001eGcByAAK"},"TYPE":"GET_MEMORY_DATA"}
    String strRequestData = objJsonGenerator.getAsString();
    Test.startTest();
    String strResultData = RMAFormOrderController.singleSourceOfTruth(
      strRequestData
    );
    Test.stopTest();
    System.assert(true, 'message');
  }

  @isTest
  private static void getSsdData() {
    Account objAccount = [
      SELECT Id
      FROM aCCOUNT
      WHERE Name = 'Test Account'
      LIMIT 1
    ];

    JSONGenerator objJsonGenerator = JSON.createGenerator(false);
    objJsonGenerator.writeStartObject();
    objJsonGenerator.writeStringField('TYPE', 'GET_SSD_DATA');

    Map<String, String> mapStrParamsStrValue = new Map<String, String>();
    mapStrParamsStrValue.put('accountId', (String) objAccount.Id);
    objJsonGenerator.writeObjectField('params', mapStrParamsStrValue);
    objJsonGenerator.writeEndObject();

    objJsonGenerator.close();
    // {"params":{"accountId":"0014000001eGcByAAK"},"TYPE":"GET_SSD_DATA"}
    String strRequestData = objJsonGenerator.getAsString();
    Test.startTest();
    String strResultData = RMAFormOrderController.singleSourceOfTruth(
      strRequestData
    );
    Test.stopTest();
    System.assert(true, 'message');
  }

  @isTest
  private static void getHddData() {
    Account objAccount = [
      SELECT Id
      FROM ACCOUNT
      WHERE Name = 'Test Account'
      LIMIT 1
    ];

    JSONGenerator objJsonGenerator = JSON.createGenerator(false);
    objJsonGenerator.writeStartObject();
    objJsonGenerator.writeStringField('TYPE', 'GET_HDD_DATA');

    Map<String, String> mapStrParamsStrValue = new Map<String, String>();
    mapStrParamsStrValue.put('accountId', (String) objAccount.Id);
    objJsonGenerator.writeObjectField('params', mapStrParamsStrValue);
    objJsonGenerator.writeEndObject();

    objJsonGenerator.close();
    // {"params":{"accountId":"0014000001eGcByAAK"},"TYPE":"GET_HDD_DATA"}
    String strRequestData = objJsonGenerator.getAsString();
    Test.startTest();
    String strResultData = RMAFormOrderController.singleSourceOfTruth(
      strRequestData
    );
    Test.stopTest();
    System.assert(true, 'message');
  }

  @isTest
  private static void getChassisData() {
    Account objAccount = [
      SELECT Id
      FROM aCCOUNT
      WHERE Name = 'Test Account'
      LIMIT 1
    ];

    JSONGenerator objJsonGenerator = JSON.createGenerator(false);
    objJsonGenerator.writeStartObject();
    objJsonGenerator.writeStringField('TYPE', 'GET_CHASSIS_DATA');

    Map<String, String> mapStrParamsStrValue = new Map<String, String>();
    mapStrParamsStrValue.put('accountId', (String) objAccount.Id);
    objJsonGenerator.writeObjectField('params', mapStrParamsStrValue);
    objJsonGenerator.writeEndObject();

    objJsonGenerator.close();
    // {"params":{"accountId":"0014000001eGcByAAK"},"TYPE":"GET_CHASSIS_DATA"}
    String strRequestData = objJsonGenerator.getAsString();
    Test.startTest();
    String strResultData = RMAFormOrderController.singleSourceOfTruth(
      strRequestData
    );
    Test.stopTest();
    System.assert(true, 'message');
  }

  @isTest
  private static void getApplianceData() {
    Account objAccount = [
      SELECT Id
      FROM aCCOUNT
      WHERE Name = 'Test Account'
      LIMIT 1
    ];

    JSONGenerator objJsonGenerator = JSON.createGenerator(false);
    objJsonGenerator.writeStartObject();
    objJsonGenerator.writeStringField('TYPE', 'GET_APPLIANCE_DATA');

    Map<String, String> mapStrParamsStrValue = new Map<String, String>();
    mapStrParamsStrValue.put('accountId', (String) objAccount.Id);
    objJsonGenerator.writeObjectField('params', mapStrParamsStrValue);
    objJsonGenerator.writeEndObject();

    objJsonGenerator.close();
    // {"params":{"accountId":"0014000001eGcByAAK"},"TYPE":"GET_APPLIANCE_DATA"}
    String strRequestData = objJsonGenerator.getAsString();
    Test.startTest();
    String strResultData = RMAFormOrderController.singleSourceOfTruth(
      strRequestData
    );
    Test.stopTest();
    System.assert(true, 'message');
  }

  @isTest
  private static void getClusterData() {
    Account objAccount = [
      SELECT Id
      FROM aCCOUNT
      WHERE Name = 'Test Account'
      LIMIT 1
    ];

    JSONGenerator objJsonGenerator = JSON.createGenerator(false);
    objJsonGenerator.writeStartObject();
    objJsonGenerator.writeStringField('TYPE', 'GET_CLUSTER_DATA');

    Map<String, String> mapStrParamsStrValue = new Map<String, String>();
    mapStrParamsStrValue.put('accountId', (String) objAccount.Id);
    objJsonGenerator.writeObjectField('params', mapStrParamsStrValue);
    objJsonGenerator.writeEndObject();

    objJsonGenerator.close();
    // {"params":{"accountId":"0014000001eGcByAAK"},"TYPE":"GET_CLUSTER_DATA"}
    String strRequestData = objJsonGenerator.getAsString();
    Test.startTest();
    String strResultData = RMAFormOrderController.singleSourceOfTruth(
      strRequestData
    );
    Test.stopTest();
    System.assert(true, 'message');
  }

  @isTest
  private static void getValidityAndNrdPolicyNoParentValidProductName() {
    Account objAccount = [
      SELECT Id
      FROM Account
      WHERE Name = 'Test Account'
      LIMIT 1
    ];
    Asset objAsset = [SELECT Id FROM Asset WHERE AccountID = :objAccount.Id AND Name = 'SN3' LIMIT 1];
    List<Id> lstIdAsset = new List<Id>();
    lstIdAsset.add(objAsset.Id);

    JSONGenerator objJsonGenerator = JSON.createGenerator(false);
    objJsonGenerator.writeStartObject();
    objJsonGenerator.writeStringField('TYPE', 'GET_VALIDITY_AND_NRD_POLICY');

    Map<String, Object> mapStrParamsStrValue = new Map<String, Object>{
      'setIdAppliance' => lstIdAsset,
      'isSmartHandsRequested' => true,
      'isSmartHandsQualified' => true
    };

    objJsonGenerator.writeObjectField('params', mapStrParamsStrValue);
    objJsonGenerator.writeEndObject();

    objJsonGenerator.close();
    String strRequestData = objJsonGenerator.getAsString();
    Test.startTest();
    String strResultData = RMAFormOrderController.singleSourceOfTruth(
      strRequestData
    );
    Test.stopTest();
    System.assert(true, 'message');
  }

  @isTest
  private static void getValidityAndNrdPolicyNoParent() {
    Account objAccount = [
      SELECT Id
      FROM Account
      WHERE Name = 'Test Account'
      LIMIT 1
    ];
    Asset objAsset = [SELECT Id FROM Asset WHERE AccountID = :objAccount.Id AND Name = 'SN2' LIMIT 1];
    List<Id> lstIdAsset = new List<Id>();
    lstIdAsset.add(objAsset.Id);

    JSONGenerator objJsonGenerator = JSON.createGenerator(false);
    objJsonGenerator.writeStartObject();
    objJsonGenerator.writeStringField('TYPE', 'GET_VALIDITY_AND_NRD_POLICY');

    Map<String, Object> mapStrParamsStrValue = new Map<String, Object>{
      'setIdAppliance' => lstIdAsset,
      'isSmartHandsRequested' => true,
      'isSmartHandsQualified' => true
    };

    objJsonGenerator.writeObjectField('params', mapStrParamsStrValue);
    objJsonGenerator.writeEndObject();

    objJsonGenerator.close();
    String strRequestData = objJsonGenerator.getAsString();
    Test.startTest();
    String strResultData = RMAFormOrderController.singleSourceOfTruth(
      strRequestData
    );
    Test.stopTest();
    System.assert(true, 'message');
  }

  @isTest
  private static void getValidityAndNrdPolicy() {
    Account objAccount = [
      SELECT Id
      FROM Account
      WHERE Name = 'Test Account'
      LIMIT 1
    ];
    List<Asset> lstAsset = new List<Asset>(
      [SELECT Id FROM Asset WHERE AccountID = :objAccount.Id]
    );
    List<Id> lstIdAsset = new List<Id>();
    for (Asset objAsset : lstAsset) {
      lstIdAsset.add(objAsset.Id);
    }
    JSONGenerator objJsonGenerator = JSON.createGenerator(false);
    objJsonGenerator.writeStartObject();
    objJsonGenerator.writeStringField('TYPE', 'GET_VALIDITY_AND_NRD_POLICY');

    Map<String, Object> mapStrParamsStrValue = new Map<String, Object>{
      'setIdAppliance' => lstIdAsset,
      'isSmartHandsRequested' => false,
      'isSmartHandsQualified' => true
    };

    objJsonGenerator.writeObjectField('params', mapStrParamsStrValue);
    objJsonGenerator.writeEndObject();

    objJsonGenerator.close();
    String strRequestData = objJsonGenerator.getAsString();
    Test.startTest();
    String strResultData = RMAFormOrderController.singleSourceOfTruth(
      strRequestData
    );
    Test.stopTest();
    System.assert(true, 'message');
  }

  @IsTest
  private static void saveRmaAppliance() {
    Case objCase = [SELECT Id, AccountId FROM Case LIMIT 1];
    Id idAccount = objCase.AccountId;
    Map<Id, Asset> mapIdAsset = new Map<Id, Asset>(
      [
        SELECT Id, Name, Serial_Number__c, Product2.Name
        FROM Asset
        WHERE AccountId = :idAccount
      ]
    );
    List<Asset> lstAsset = mapIdAsset.values();
    List<Cluster__c> lstCluster = new List<Cluster__c>(
      [
        SELECT Id, Archived__c, uuid__c
        FROM Cluster__c
        WHERE Archived__c = FALSE AND account__c = :idAccount
      ]
    );

    Map<String, List<String>> lstStrCmpTypeLstStrFailReason = new Map<String, List<String>>();
    List<RMA_Failure_List__c> lstRMAFail = new List<RMA_Failure_List__c>(
      [SELECT Id, Name, Failure_Type__c FROM RMA_Failure_List__c]
    );
    for (RMA_Failure_List__c objFailReason : lstRMAFail) {
      lstStrCmpTypeLstStrFailReason.put(
        objFailReason.Name.toLowerCase(),
        new List<String>(objFailReason.Failure_Type__c.split(';'))
      );
    }


    RMAFormOrderController.FailureWrapper objFailWrapperAppliance = new RMAFormOrderController.FailureWrapper();
    objFailWrapperAppliance.idComponent = lstAsset[0].Id;
    objFailWrapperAppliance.assetId = lstAsset[0].Id;
    objFailWrapperAppliance.strTypeComponent = 'appliance';
    objFailWrapperAppliance.strSerialNumber = lstAsset[0].serial_number__c;
    objFailWrapperAppliance.strReason = lstStrCmpTypeLstStrFailReason.get(
      'appliance'
    )[0];

    Map<String, Object> mapStrObjSaveRmaRequest = new Map<String, Object>{
      'TYPE' => 'SAVE_RMA',
      'params' => new Map<String, Object>{
        'caseId' => (String) objCase.Id,
        'clusterId' => (String) lstCluster[0].Id,
        'clusterUuid' => (String) lstCluster[0].uuid__c,
        'lstFailure' => new List<Object>{ (Object) objFailWrapperAppliance },
        'setStrSerialNumberAppliance' => new List<String>{
          lstAsset[0].serial_number__c
        },
        'setStrSerialNumberChassis' => new List<String>(),
        'setStrSerialNumberHdd' => new List<String>(),
        'setStrSerialNumberSsd' => new List<String>(),
        'setStrSerialNumberMemory' => new List<String>(),
        'setStrSerialNumberNode' => new List<String>(),
        'setStrSerialNumberPsu' => new List<String>(),
        'setStrSerialNumberCmos' => new List<String>(),
        'isSmartHandsRequested' => false,
        'isSmartHandsQualified' => true,
        'hasValidSupport' => true,
        'hasNrdPolicy' => true,
        'smartHandsReason' => '',
        'additionalInterestedParties' => '',
        'shippingStreet' => 'abc',
        'shippingCity' => 'def',
        'shippingCountry' => 'India',
        'shippingState' => '',
        'shippingPostalCode' => '123455',
        'copyShippingAddressFromAccount' => false,
        'shipToPhone' => '992145',
        'shipToName' => idAccount,
        'shipToContactName' => 'Test Contact',
        'shipToEmail' => 'test@example.com',
        'smartHandsServiceLevel' => 'Next Business Day: 10:30am',
        'smartHandsDate' =>  '',
        'smartHandsTime' => ''
      }
    };

    String strRequestData = JSON.serialize(mapStrObjSaveRmaRequest);

    Test.startTest();
    String strResponseData = RMAFormOrderController.singleSourceOfTruth(
      strRequestData
    );
    Test.stopTest();
    System.assert(true, 'message');
  }

  @IsTest
  private static void saveRmaChassis() {
    Case objCase = [SELECT Id, AccountId FROM Case LIMIT 1];
    Id idAccount = objCase.AccountId;
    Map<Id, Asset> mapIdAsset = new Map<Id, Asset>(
      [
        SELECT Id, Name, Serial_Number__c, Product2.Name
        FROM Asset
        WHERE AccountId = :idAccount
      ]
    );
    List<Asset> lstAsset = mapIdAsset.values();
    List<Cluster__c> lstCluster = new List<Cluster__c>(
      [
        SELECT Id, Archived__c, uuid__c
        FROM Cluster__c
        WHERE Archived__c = FALSE AND account__c = :idAccount
      ]
    );

    List<Chassis__c> lstChassis = new List<Chassis__c>(
      [
        SELECT
          Id,
          Serial_Number__c,
          Asset__r.Name,
          Asset__r.serial_number__c,
          Name
        FROM chassis__c
        WHERE Asset__r.AccountId = :idAccount
      ]
    );

    Map<String, List<String>> lstStrCmpTypeLstStrFailReason = new Map<String, List<String>>();
    List<RMA_Failure_List__c> lstRMAFail = new List<RMA_Failure_List__c>(
      [SELECT Id, Name, Failure_Type__c FROM RMA_Failure_List__c]
    );
    for (RMA_Failure_List__c objFailReason : lstRMAFail) {
      lstStrCmpTypeLstStrFailReason.put(
        objFailReason.Name.toLowerCase(),
        new List<String>(objFailReason.Failure_Type__c.split(';'))
      );
    }
    System.debug(lstRMAFail);
    System.debug(lstStrCmpTypeLstStrFailReason);


    RMAFormOrderController.FailureWrapper objFailWrapperChassis = new RMAFormOrderController.FailureWrapper();
    objFailWrapperChassis.idComponent = lstChassis[2].Id;
    objFailWrapperChassis.assetId = lstChassis[2].Asset__c;
    objFailWrapperChassis.strTypeComponent = 'chassis';
    objFailWrapperChassis.strSerialNumber = lstChassis[2].serial_number__c;
    objFailWrapperChassis.strReason = lstStrCmpTypeLstStrFailReason.get(
      'chassis'
    )[0];

    Map<String, Object> mapStrObjSaveRmaRequest = new Map<String, Object>{
      'TYPE' => 'SAVE_RMA',
      'params' => new Map<String, Object>{
        'caseId' => (String) objCase.Id,
        'clusterId' => (String) lstCluster[0].Id,
        'clusterUuid' => (String) lstCluster[0].uuid__c,
        'lstFailure' => new List<Object>{ (Object) objFailWrapperChassis },
        'setStrSerialNumberAppliance' => new List<String>{
          lstAsset[1].serial_number__c
        },
        'setStrSerialNumberChassis' => new List<String>{
          objFailWrapperChassis.strSerialNumber
        },
        'setStrSerialNumberHdd' => new List<String>(),
        'setStrSerialNumberSsd' => new List<String>(),
        'setStrSerialNumberMemory' => new List<String>(),
        'setStrSerialNumberNode' => new List<String>(),
        'setStrSerialNumberPsu' => new List<String>(),
        'setStrSerialNumberCmos' => new List<String>(),
        'isSmartHandsRequested' => true,
        'isSmartHandsQualified' => false,
        'hasValidSupport' => false,
        'hasNrdPolicy' => false,
        'smartHandsReason' => 'Test',
        'additionalInterestedParties' => 'test@rubrik.com',
        'shippingStreet' => 'abc',
        'shippingCity' => 'def',
        'shippingCountry' => 'India',
        'shippingState' => '',
        'shippingPostalCode' => '123455',
        'copyShippingAddressFromAccount' => false,
        'shipToPhone' => '992145',
        'shipToName' => idAccount,
        'shipToContactName' => 'Test Contact',
        'shipToEmail' => 'test@example.com',
        'smartHandsServiceLevel' => 'Next Business Day: 10:30am',
        'smartHandsDate' =>   new Map<String, String>{
          'month' => '07',
          'day' => '29',
          'year' => String.valueOf(Date.today().year() + 1)
        },
        'smartHandsTime' => '12:00'
      }
    };

    String strRequestData = JSON.serialize(mapStrObjSaveRmaRequest);
    Test.startTest();
    String strResponseData = RMAFormOrderController.singleSourceOfTruth(
      strRequestData
    );
    Test.stopTest();
    System.assert(true, 'message');
  }

  @IsTest
  private static void saveRmaHdd() {
    Case objCase = [SELECT Id, AccountId FROM Case LIMIT 1];
    Id idAccount = objCase.AccountId;
    Map<Id, Asset> mapIdAsset = new Map<Id, Asset>(
      [
        SELECT Id, Name, Serial_Number__c, Product2.Name
        FROM Asset
        WHERE AccountId = :idAccount
      ]
    );
    List<Asset> lstAsset = mapIdAsset.values();
    List<Cluster__c> lstCluster = new List<Cluster__c>(
      [
        SELECT Id, Archived__c, uuid__c
        FROM Cluster__c
        WHERE Archived__c = FALSE AND account__c = :idAccount
      ]
    );

    List<Drive__c> lstHdd = new List<Drive__c>(
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
          Asset__r.AccountId = :idAccount
          AND node__r.cluster__c != ''
          AND Type__c = 'HDD'
      ]
    );

    Map<String, List<String>> lstStrCmpTypeLstStrFailReason = new Map<String, List<String>>();
    List<RMA_Failure_List__c> lstRMAFail = new List<RMA_Failure_List__c>(
      [SELECT Id, Name, Failure_Type__c FROM RMA_Failure_List__c]
    );
    for (RMA_Failure_List__c objFailReason : lstRMAFail) {
      lstStrCmpTypeLstStrFailReason.put(
        objFailReason.Name.toLowerCase(),
        new List<String>(objFailReason.Failure_Type__c.split(';'))
      );
    }
    System.debug(lstRMAFail);
    System.debug(lstStrCmpTypeLstStrFailReason);


    RMAFormOrderController.FailureWrapper objFailWrapperHdd = new RMAFormOrderController.FailureWrapper();
    objFailWrapperHdd.idComponent = lstHdd[0].Id;
    objFailWrapperHdd.assetId = lstHdd[0].Asset__c;
    objFailWrapperHdd.strTypeComponent = 'hdd';
    objFailWrapperHdd.strSerialNumber = lstHdd[0].serial_number__c;
    objFailWrapperHdd.strReason = lstStrCmpTypeLstStrFailReason.get('hdd')[0];

    Map<String, Object> mapStrObjSaveRmaRequest = new Map<String, Object>{
      'TYPE' => 'SAVE_RMA',
      'params' => new Map<String, Object>{
        'caseId' => (String) objCase.Id,
        'clusterId' => (String) lstCluster[0].Id,
        'clusterUuid' => (String) lstCluster[0].uuid__c,
        'lstFailure' => new List<Object>{ (Object) objFailWrapperHdd },
        'setStrSerialNumberAppliance' => new List<String>{
          lstAsset[0].serial_number__c
        },
        'setStrSerialNumberChassis' => new List<String>(),
        'setStrSerialNumberHdd' => new List<String>{
          objFailWrapperHdd.strSerialNumber
        },
        'setStrSerialNumberSsd' => new List<String>(),
        'setStrSerialNumberMemory' => new List<String>(),
        'setStrSerialNumberNode' => new List<String>(),
        'setStrSerialNumberPsu' => new List<String>(),
        'setStrSerialNumberCmos' => new List<String>(),
        'isSmartHandsRequested' => false,
        'isSmartHandsQualified' => true,
        'hasValidSupport' => true,
        'hasNrdPolicy' => true,
        'smartHandsReason' => '',
        'additionalInterestedParties' => '',
        'shippingStreet' => 'abc',
        'shippingCity' => 'def',
        'shippingCountry' => 'India',
        'shippingState' => '',
        'shippingPostalCode' => '123455',
        'copyShippingAddressFromAccount' => false,
        'shipToPhone' => '992145',
        'shipToName' => idAccount,
        'shipToContactName' => 'Test Contact',
        'shipToEmail' => 'test@example.com',
        'smartHandsServiceLevel' => 'Next Business Day: 10:30am',
        'smartHandsDate' =>  '',
        'smartHandsTime' => ''
      }
    };

    String strRequestData = JSON.serialize(mapStrObjSaveRmaRequest);
    Test.startTest();

    String strResponseData = RMAFormOrderController.singleSourceOfTruth(
      strRequestData
    );
    Test.stopTest();
    System.assert(true, 'message');
  }

  @IsTest
  private static void saveRmaSsd() {
    Case objCase = [SELECT Id, AccountId FROM Case LIMIT 1];
    Id idAccount = objCase.AccountId;
    Map<Id, Asset> mapIdAsset = new Map<Id, Asset>(
      [
        SELECT Id, Name, Serial_Number__c, Product2.Name
        FROM Asset
        WHERE AccountId = :idAccount
      ]
    );
    List<Asset> lstAsset = mapIdAsset.values();
    List<Cluster__c> lstCluster = new List<Cluster__c>(
      [
        SELECT Id, Archived__c, uuid__c
        FROM Cluster__c
        WHERE Archived__c = FALSE AND account__c = :idAccount
      ]
    );

    List<Drive__c> lstSsd = new List<Drive__c>(
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
          Asset__r.AccountId = :idAccount
          AND node__r.cluster__c != ''
          AND Type__c = 'SSD'
      ]
    );

    Map<String, List<String>> lstStrCmpTypeLstStrFailReason = new Map<String, List<String>>();
    List<RMA_Failure_List__c> lstRMAFail = new List<RMA_Failure_List__c>(
      [SELECT Id, Name, Failure_Type__c FROM RMA_Failure_List__c]
    );
    for (RMA_Failure_List__c objFailReason : lstRMAFail) {
      lstStrCmpTypeLstStrFailReason.put(
        objFailReason.Name.toLowerCase(),
        new List<String>(objFailReason.Failure_Type__c.split(';'))
      );
    }
    System.debug(lstRMAFail);
    System.debug(lstStrCmpTypeLstStrFailReason);


    RMAFormOrderController.FailureWrapper objFailWrapperSsd = new RMAFormOrderController.FailureWrapper();
    objFailWrapperSsd.idComponent = lstSsd[0].Id;
    objFailWrapperSsd.assetId = lstSsd[0].Asset__c;
    objFailWrapperSsd.strTypeComponent = 'ssd';
    objFailWrapperSsd.strSerialNumber = lstSsd[0].serial_number__c;
    objFailWrapperSsd.strReason = lstStrCmpTypeLstStrFailReason.get('ssd')[0];

    Map<String, Object> mapStrObjSaveRmaRequest = new Map<String, Object>{
      'TYPE' => 'SAVE_RMA',
      'params' => new Map<String, Object>{
        'caseId' => (String) objCase.Id,
        'clusterId' => (String) lstCluster[0].Id,
        'clusterUuid' => (String) lstCluster[0].uuid__c,
        'lstFailure' => new List<Object>{ (Object) objFailWrapperSsd },
        'setStrSerialNumberAppliance' => new List<String>{
          lstAsset[0].serial_number__c
        },
        'setStrSerialNumberChassis' => new List<String>(),
        'setStrSerialNumberHdd' => new List<String>(),
        'setStrSerialNumberSsd' => new List<String>{
          objFailWrapperSsd.strSerialNumber
        },
        'setStrSerialNumberMemory' => new List<String>(),
        'setStrSerialNumberNode' => new List<String>(),
        'setStrSerialNumberPsu' => new List<String>(),
        'setStrSerialNumberCmos' => new List<String>(),
        'isSmartHandsRequested' => false,
        'isSmartHandsQualified' => true,
        'hasValidSupport' => true,
        'hasNrdPolicy' => true,
        'smartHandsReason' => '',
        'additionalInterestedParties' => '',
        'shippingStreet' => 'abc',
        'shippingCity' => 'def',
        'shippingCountry' => 'India',
        'shippingState' => '',
        'shippingPostalCode' => '123455',
        'copyShippingAddressFromAccount' => false,
        'shipToPhone' => '992145',
        'shipToName' => idAccount,
        'shipToContactName' => 'Test Contact',
        'shipToEmail' => 'test@example.com',
        'smartHandsServiceLevel' => 'Next Business Day: 10:30am',
        'smartHandsDate' =>  '',
        'smartHandsTime' => ''
      }
    };

    String strRequestData = JSON.serialize(mapStrObjSaveRmaRequest);
    Test.startTest();
    String strResponseData = RMAFormOrderController.singleSourceOfTruth(
      strRequestData
    );
    Test.stopTest();
    System.assert(true, 'message');
  }

  @IsTest
  private static void saveRmaMemory() {
    Case objCase = [SELECT Id, AccountId FROM Case LIMIT 1];
    Id idAccount = objCase.AccountId;
    Map<Id, Asset> mapIdAsset = new Map<Id, Asset>(
      [
        SELECT Id, Name, Serial_Number__c, Product2.Name
        FROM Asset
        WHERE AccountId = :idAccount
      ]
    );
    List<Asset> lstAsset = mapIdAsset.values();
    List<Cluster__c> lstCluster = new List<Cluster__c>(
      [
        SELECT Id, Archived__c, uuid__c
        FROM Cluster__c
        WHERE Archived__c = FALSE AND account__c = :idAccount
      ]
    );

    List<Memory__c> lstMemory = new List<Memory__c>(
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
        WHERE node__r.cluster__c != '' AND Asset__r.AccountId = :idAccount
      ]
    );

    Map<String, List<String>> lstStrCmpTypeLstStrFailReason = new Map<String, List<String>>();
    List<RMA_Failure_List__c> lstRMAFail = new List<RMA_Failure_List__c>(
      [SELECT Id, Name, Failure_Type__c FROM RMA_Failure_List__c]
    );
    for (RMA_Failure_List__c objFailReason : lstRMAFail) {
      lstStrCmpTypeLstStrFailReason.put(
        objFailReason.Name.toLowerCase(),
        new List<String>(objFailReason.Failure_Type__c.split(';'))
      );
    }
    System.debug(lstRMAFail);
    System.debug(lstStrCmpTypeLstStrFailReason);


    RMAFormOrderController.FailureWrapper objFailWrapperMemory = new RMAFormOrderController.FailureWrapper();
    objFailWrapperMemory.idComponent = lstMemory[0].Id;
    objFailWrapperMemory.assetId = lstMemory[0].Asset__r.Id;
    objFailWrapperMemory.strTypeComponent = 'memory';
    objFailWrapperMemory.strSerialNumber = lstMemory[0].serial_number__c;
    objFailWrapperMemory.strReason = lstStrCmpTypeLstStrFailReason.get(
      'memory'
    )[0];

    Map<String, Object> mapStrObjSaveRmaRequest = new Map<String, Object>{
      'TYPE' => 'SAVE_RMA',
      'params' => new Map<String, Object>{
        'caseId' => (String) objCase.Id,
        'clusterId' => (String) lstCluster[0].Id,
        'clusterUuid' => (String) lstCluster[0].uuid__c,
        'lstFailure' => new List<Object>{ (Object) objFailWrapperMemory },
        'setStrSerialNumberAppliance' => new List<String>{
          lstAsset[0].serial_number__c
        },
        'setStrSerialNumberChassis' => new List<String>(),
        'setStrSerialNumberHdd' => new List<String>(),
        'setStrSerialNumberSsd' => new List<String>(),
        'setStrSerialNumberMemory' => new List<String>{
          objFailWrapperMemory.strSerialNumber
        },
        'setStrSerialNumberNode' => new List<String>(),
        'setStrSerialNumberPsu' => new List<String>(),
        'setStrSerialNumberCmos' => new List<String>(),
        'isSmartHandsRequested' => true,
        'isSmartHandsQualified' => false,
        'hasValidSupport' => false,
        'hasNrdPolicy' => false,
        'smartHandsReason' => 'Test',
        'additionalInterestedParties' => 'test@rubrik.com',
        'shippingStreet' => 'abc',
        'shippingCity' => 'def',
        'shippingCountry' => 'India',
        'shippingState' => '',
        'shippingPostalCode' => '123455',
        'copyShippingAddressFromAccount' => false,
        'shipToPhone' => '992145',
        'shipToName' => idAccount,
        'shipToContactName' => 'Test Contact',
        'shipToEmail' => 'test@example.com',
        'smartHandsServiceLevel' => 'Next Business Day: 10:30am',
        'smartHandsDate' =>   new Map<String, String>{
          'month' => '07',
          'day' => '29',
          'year' => String.valueOf(Date.today().year() + 1)
        },
        'smartHandsTime' => '12:00'
      }
    };

    String strRequestData = JSON.serialize(mapStrObjSaveRmaRequest);
    Test.startTest();
    String strResponseData = RMAFormOrderController.singleSourceOfTruth(
      strRequestData
    );
    Test.stopTest();
    System.assert(true, 'message');
  }

  @IsTest
  private static void saveRmaNode() {
    Case objCase = [SELECT Id, AccountId FROM Case LIMIT 1];
    Id idAccount = objCase.AccountId;
    Map<Id, Asset> mapIdAsset = new Map<Id, Asset>(
      [
        SELECT Id, Name, Serial_Number__c, Product2.Name
        FROM Asset
        WHERE AccountId = :idAccount
      ]
    );
    List<Asset> lstAsset = mapIdAsset.values();
    List<Cluster__c> lstCluster = new List<Cluster__c>(
      [
        SELECT Id, Archived__c, uuid__c
        FROM Cluster__c
        WHERE Archived__c = FALSE AND account__c = :idAccount
      ]
    );

    List<Node__c> lstNode = new List<Node__c>(
      [
        SELECT
          Id,
          Serial_Number__c,
          Asset__r.serial_number__c,
          Chassis__r.Serial_Number__c,
          Cluster__r.uuid__c,
          Name
        FROM Node__c
        WHERE
          Asset__c != ''
          AND cluster__c != ''
          AND Asset__r.AccountId = :idAccount
      ]
    );

    Map<String, List<String>> lstStrCmpTypeLstStrFailReason = new Map<String, List<String>>();
    List<RMA_Failure_List__c> lstRMAFail = new List<RMA_Failure_List__c>(
      [SELECT Id, Name, Failure_Type__c FROM RMA_Failure_List__c]
    );
    for (RMA_Failure_List__c objFailReason : lstRMAFail) {
      lstStrCmpTypeLstStrFailReason.put(
        objFailReason.Name.toLowerCase(),
        new List<String>(objFailReason.Failure_Type__c.split(';'))
      );
    }
    System.debug(lstRMAFail);
    System.debug(lstStrCmpTypeLstStrFailReason);


    RMAFormOrderController.FailureWrapper objFailWrapperNode = new RMAFormOrderController.FailureWrapper();
    objFailWrapperNode.idComponent = lstNode[0].Id;
    objFailWrapperNode.assetId = lstNode[0].Asset__r.Id;
    objFailWrapperNode.strTypeComponent = 'node';
    objFailWrapperNode.strSerialNumber = lstNode[0].Asset__r.serial_number__c;
    objFailWrapperNode.strReason = lstStrCmpTypeLstStrFailReason.get('node')[0];

    Map<String, Object> mapStrObjSaveRmaRequest = new Map<String, Object>{
      'TYPE' => 'SAVE_RMA',
      'params' => new Map<String, Object>{
        'caseId' => (String) objCase.Id,
        'clusterId' => (String) lstCluster[0].Id,
        'clusterUuid' => (String) lstCluster[0].uuid__c,
        'lstFailure' => new List<Object>{ (Object) objFailWrapperNode },
        'setStrSerialNumberAppliance' => new List<String>{
          lstAsset[0].serial_number__c
        },
        'setStrSerialNumberChassis' => new List<String>(),
        'setStrSerialNumberHdd' => new List<String>(),
        'setStrSerialNumberSsd' => new List<String>(),
        'setStrSerialNumberMemory' => new List<String>(),
        'setStrSerialNumberNode' => new List<String>{
          objFailWrapperNode.strSerialNumber
        },
        'setStrSerialNumberPsu' => new List<String>(),
        'setStrSerialNumberCmos' => new List<String>(),
        'isSmartHandsRequested' => true,
        'isSmartHandsQualified' => false,
        'hasValidSupport' => false,
        'hasNrdPolicy' => false,
        'smartHandsReason' => 'Test',
        'additionalInterestedParties' => 'test@rubrik.com',
        'shippingStreet' => 'abc',
        'shippingCity' => 'def',
        'shippingCountry' => 'India',
        'shippingState' => '',
        'shippingPostalCode' => '123455',
        'copyShippingAddressFromAccount' => false,
        'shipToPhone' => '992145',
        'shipToName' => idAccount,
        'shipToContactName' => 'Test Contact',
        'shipToEmail' => 'test@example.com',
        'smartHandsServiceLevel' => 'Next Business Day: 10:30am',
        'smartHandsDate' =>   new Map<String, String>{
          'month' => '07',
          'day' => '29',
          'year' => String.valueOf(Date.today().year() + 1)
        },
        'smartHandsTime' => '12:00'
      }
    };

    String strRequestData = JSON.serialize(mapStrObjSaveRmaRequest);
    Test.startTest();
    String strResponseData = RMAFormOrderController.singleSourceOfTruth(
      strRequestData
    );
    Test.stopTest();
    System.assert(true, 'message');
  }

  @IsTest
  private static void saveRmaCmos() {
    Case objCase = [SELECT Id, AccountId FROM Case LIMIT 1];
    Id idAccount = objCase.AccountId;
    Map<Id, Asset> mapIdAsset = new Map<Id, Asset>(
      [
        SELECT Id, Name, Serial_Number__c, Product2.Name
        FROM Asset
        WHERE AccountId = :idAccount
      ]
    );
    List<Asset> lstAsset = mapIdAsset.values();
    List<Cluster__c> lstCluster = new List<Cluster__c>(
      [
        SELECT Id, Archived__c, uuid__c
        FROM Cluster__c
        WHERE Archived__c = FALSE AND account__c = :idAccount
      ]
    );

    List<Node__c> lstNode = new List<Node__c>(
      [
        SELECT
          Id,
          Serial_Number__c,
          Asset__r.serial_number__c,
          Chassis__r.Serial_Number__c,
          Cluster__r.uuid__c,
          Name
        FROM Node__c
        WHERE
          Asset__c != ''
          AND cluster__c != ''
          AND Asset__r.AccountId = :idAccount
      ]
    );

    Map<String, List<String>> lstStrCmpTypeLstStrFailReason = new Map<String, List<String>>();
    List<RMA_Failure_List__c> lstRMAFail = new List<RMA_Failure_List__c>(
      [SELECT Id, Name, Failure_Type__c FROM RMA_Failure_List__c]
    );
    for (RMA_Failure_List__c objFailReason : lstRMAFail) {
      lstStrCmpTypeLstStrFailReason.put(
        objFailReason.Name.toLowerCase(),
        new List<String>(objFailReason.Failure_Type__c.split(';'))
      );
    }
    System.debug(lstRMAFail);
    System.debug(lstStrCmpTypeLstStrFailReason);


    RMAFormOrderController.FailureWrapper objFailWrapperCmos1 = new RMAFormOrderController.FailureWrapper();
    objFailWrapperCmos1.idComponent = lstNode[0].Id;
    objFailWrapperCmos1.assetId = lstNode[0].Asset__r.Id;
    objFailWrapperCmos1.strTypeComponent = 'cmos';
    objFailWrapperCmos1.strSerialNumber = lstNode[0].Asset__r.serial_number__c;
    objFailWrapperCmos1.strReason = lstStrCmpTypeLstStrFailReason.get('cmos')[0];

    Map<String, Object> mapStrObjSaveRmaRequest = new Map<String, Object>{
      'TYPE' => 'SAVE_RMA',
      'params' => new Map<String, Object>{
        'caseId' => (String) objCase.Id,
        'clusterId' => (String) lstCluster[0].Id,
        'clusterUuid' => (String) lstCluster[0].uuid__c,
        'lstFailure' => new List<Object>{ (Object) objFailWrapperCmos1 },
        'setStrSerialNumberAppliance' => new List<String>{
          lstAsset[0].serial_number__c
        },
        'setStrSerialNumberChassis' => new List<String>(),
        'setStrSerialNumberHdd' => new List<String>(),
        'setStrSerialNumberSsd' => new List<String>(),
        'setStrSerialNumberMemory' => new List<String>(),
        'setStrSerialNumberNode' => new List<String>(),
        'setStrSerialNumberPsu' => new List<String>(),
        'setStrSerialNumberCmos' => new List<String>{
          objFailWrapperCmos1.strSerialNumber
        },
        'isSmartHandsRequested' => true,
        'isSmartHandsQualified' => false,
        'hasValidSupport' => false,
        'hasNrdPolicy' => false,
        'smartHandsReason' => 'Test',
        'additionalInterestedParties' => 'test@rubrik.com',
        'shippingStreet' => 'abc',
        'shippingCity' => 'def',
        'shippingCountry' => 'India',
        'shippingState' => '',
        'shippingPostalCode' => '123455',
        'copyShippingAddressFromAccount' => true,
        'shipToPhone' => '992145',
        'shipToName' => idAccount,
        'shipToContactName' => 'Test Contact',
        'shipToEmail' => 'test@example.com',
        'smartHandsServiceLevel' => 'Next Business Day: 10:30am',
        'smartHandsDate' =>   new Map<String, String>{
          'month' => '07',
          'day' => '29',
          'year' => String.valueOf(Date.today().year() + 1)
        },
        'smartHandsTime' => '12:00'
      }
    };

    String strRequestData = JSON.serialize(mapStrObjSaveRmaRequest);
    Test.startTest();
    String strResponseData = RMAFormOrderController.singleSourceOfTruth(
      strRequestData
    );
    Test.stopTest();
    System.assert(true, 'message');
  }

  @IsTest
  private static void saveRmaPsu() {
    Case objCase = [SELECT Id, AccountId FROM Case LIMIT 1];
    Id idAccount = objCase.AccountId;
    Map<Id, Asset> mapIdAsset = new Map<Id, Asset>(
      [
        SELECT Id, Name, Serial_Number__c, Product2.Name
        FROM Asset
        WHERE AccountId = :idAccount
      ]
    );
    List<Asset> lstAsset = mapIdAsset.values();
    List<Cluster__c> lstCluster = new List<Cluster__c>(
      [
        SELECT Id, Archived__c, uuid__c
        FROM Cluster__c
        WHERE Archived__c = FALSE AND account__c = :idAccount
      ]
    );

    List<Power_supply__c> lstPsu = new List<Power_Supply__c>(
      [
        SELECT
          Id,
          Serial_Number__c,
          Asset__r.Name,
          Asset__r.serial_number__c,
          Name
        FROM Power_Supply__c
        WHERE Asset__r.AccountId = :idAccount
      ]
    );
    Map<String, List<String>> lstStrCmpTypeLstStrFailReason = new Map<String, List<String>>();
    List<RMA_Failure_List__c> lstRMAFail = new List<RMA_Failure_List__c>(
      [SELECT Id, Name, Failure_Type__c FROM RMA_Failure_List__c]
    );
    for (RMA_Failure_List__c objFailReason : lstRMAFail) {
      lstStrCmpTypeLstStrFailReason.put(
        objFailReason.Name.toLowerCase(),
        new List<String>(objFailReason.Failure_Type__c.split(';'))
      );
    }
    System.debug(lstRMAFail);
    System.debug(lstStrCmpTypeLstStrFailReason);


    RMAFormOrderController.FailureWrapper objFailWrapperPsu = new RMAFormOrderController.FailureWrapper();
    objFailWrapperPsu.idComponent = lstPsu[0].Id;
    objFailWrapperPsu.assetId = lstPsu[0].Asset__r.Id;
    objFailWrapperPsu.strTypeComponent = 'psu';
    objFailWrapperPsu.strSerialNumber = lstPsu[0].Asset__r.serial_number__c;
    objFailWrapperPsu.strReason = lstStrCmpTypeLstStrFailReason.get('psu')[0];

    Map<String, Object> mapStrObjSaveRmaRequest = new Map<String, Object>{
      'TYPE' => 'SAVE_RMA',
      'params' => new Map<String, Object>{
        'caseId' => (String) objCase.Id,
        'clusterId' => (String) lstCluster[0].Id,
        'clusterUuid' => (String) lstCluster[0].uuid__c,
        'lstFailure' => new List<Object>{ (Object) objFailWrapperPsu },
        'setStrSerialNumberAppliance' => new List<String>{
          lstAsset[0].serial_number__c
        },
        'setStrSerialNumberChassis' => new List<String>(),
        'setStrSerialNumberHdd' => new List<String>(),
        'setStrSerialNumberSsd' => new List<String>(),
        'setStrSerialNumberMemory' => new List<String>(),
        'setStrSerialNumberNode' => new List<String>(),
        'setStrSerialNumberPsu' => new List<String>{
          objFailWrapperPsu.strSerialNumber
        },
        'setStrSerialNumberCmos' => new List<String>(),
        'isSmartHandsRequested' => true,
        'isSmartHandsQualified' => true,
        'hasValidSupport' => true,
        'hasNrdPolicy' => true,
        'smartHandsReason' => 'Test',
        'additionalInterestedParties' => 'test@rubrik.com',
        'shippingStreet' => 'abc',
        'shippingCity' => 'def',
        'shippingCountry' => 'India',
        'shippingState' => '',
        'shippingPostalCode' => '123455',
        'copyShippingAddressFromAccount' => false,
        'shipToPhone' => '992145',
        'shipToName' => idAccount,
        'shipToContactName' => 'Test Contact',
        'shipToEmail' => 'test@example.com',
        'smartHandsServiceLevel' => 'Next Business Day: 10:30am',
        'smartHandsDate' =>   new Map<String, String>{
          'month' => '07',
          'day' => '29',
          'year' => String.valueOf(Date.today().year() + 1)
        },
        'smartHandsTime' => '12:00'
      }
    };

    String strRequestData = JSON.serialize(mapStrObjSaveRmaRequest);
    Test.startTest();
    String strResponseData = RMAFormOrderController.singleSourceOfTruth(
      strRequestData
    );
    Test.stopTest();
    System.assert(true, 'message');
  }

  @IsTest
  private static void saveRmaPsuWithVendorMessage() {
    Case objCase = [SELECT Id, AccountId FROM Case LIMIT 1];
    Id idAccount = objCase.AccountId;
    Map<Id, Asset> mapIdAsset = new Map<Id, Asset>(
      [
        SELECT Id, Name, Serial_Number__c, Product2.Name
        FROM Asset
        WHERE AccountId = :idAccount
      ]
    );
    List<Asset> lstAsset = mapIdAsset.values();
    List<Cluster__c> lstCluster = new List<Cluster__c>(
      [
        SELECT Id, Archived__c, uuid__c
        FROM Cluster__c
        WHERE Archived__c = FALSE AND account__c = :idAccount
      ]
    );

    List<Power_supply__c> lstPsu = new List<Power_Supply__c>(
      [
        SELECT
          Id,
          Serial_Number__c,
          Asset__r.Name,
          Asset__r.serial_number__c,
          Name
        FROM Power_Supply__c
        WHERE Asset__r.AccountId = :idAccount
      ]
    );
    Map<String, List<String>> lstStrCmpTypeLstStrFailReason = new Map<String, List<String>>();
    List<RMA_Failure_List__c> lstRMAFail = new List<RMA_Failure_List__c>(
      [SELECT Id, Name, Failure_Type__c FROM RMA_Failure_List__c]
    );
    for (RMA_Failure_List__c objFailReason : lstRMAFail) {
      lstStrCmpTypeLstStrFailReason.put(
        objFailReason.Name.toLowerCase(),
        new List<String>(objFailReason.Failure_Type__c.split(';'))
      );
    }
    System.debug(lstRMAFail);
    System.debug(lstStrCmpTypeLstStrFailReason);

    RMAFormOrderController.FailureWrapper objFailWrapperPsu = new RMAFormOrderController.FailureWrapper();
    objFailWrapperPsu.idComponent = lstPsu[0].Id;
    objFailWrapperPsu.assetId = lstPsu[0].Asset__r.Id;
    objFailWrapperPsu.strTypeComponent = 'psu';
    objFailWrapperPsu.strSerialNumber = lstPsu[0].Asset__r.serial_number__c;
    objFailWrapperPsu.strReason = lstStrCmpTypeLstStrFailReason.get('psu')[0];

    Map<String, Object> mapStrObjSaveRmaRequest = new Map<String, Object>{
      'TYPE' => 'SAVE_RMA',
      'params' => new Map<String, Object>{
        'caseId' => (String) objCase.Id,
        'clusterId' => (String) lstCluster[0].Id,
        'clusterUuid' => (String) lstCluster[0].uuid__c,
        'lstFailure' => new List<Object>{ (Object) objFailWrapperPsu },
        'setStrSerialNumberAppliance' => new List<String>{
          lstAsset[0].serial_number__c
        },
        'setStrSerialNumberChassis' => new List<String>(),
        'setStrSerialNumberHdd' => new List<String>(),
        'setStrSerialNumberSsd' => new List<String>(),
        'setStrSerialNumberMemory' => new List<String>(),
        'setStrSerialNumberNode' => new List<String>(),
        'setStrSerialNumberPsu' => new List<String>{
          objFailWrapperPsu.strSerialNumber
        },
        'setStrSerialNumberCmos' => new List<String>(),
        'isSmartHandsRequested' => true,
        'isSmartHandsQualified' => true,
        'hasValidSupport' => true,
        'hasNrdPolicy' => true,
        'smartHandsReason' => 'Test',
        'additionalInterestedParties' => 'test@rubrik.com',
        'shippingStreet' => 'abc',
        'shippingCity' => 'def',
        'shippingCountry' => 'India',
        'shippingState' => '',
        'shippingPostalCode' => '123455',
        'copyShippingAddressFromAccount' => false,
        'shipToPhone' => '992145',
        'shipToName' => idAccount,
        'shipToContactName' => 'Test Contact',
        'shipToEmail' => 'test@example.com',
        'vendorMessage' => 'Test Message',
        'smartHandsServiceLevel' => 'Next Business Day: 10:30am',
        'smartHandsDate' =>  new Map<String, String>{
          'month' => '07',
          'day' => '29',
          'year' => String.valueOf(Date.today().year() + 1)
        },
        'smartHandsTime' => '12:00'
      }
    };

    String strRequestData = JSON.serialize(mapStrObjSaveRmaRequest);
    Test.startTest();
    String strResponseData = RMAFormOrderController.singleSourceOfTruth(
      strRequestData
    );
    Test.stopTest();
    System.assert(true, 'message');
  }

  @IsTest
  private static void throwException() {

    Case objCase = [
      SELECT Id
      FROM Case
      WHERE Account.Name = 'Test Account'
      LIMIT 1
    ];

    JSONGenerator objJsonGenerator = JSON.createGenerator(false);
    objJsonGenerator.writeStartObject();
    objJsonGenerator.writeStringField('TYPE', 'NOT_GET_CASE_NUMBER');

    Map<String, String> mapStrParamsStrValue = new Map<String, String>();
    mapStrParamsStrValue.put('caseId', (String) objCase.Id);
    objJsonGenerator.writeObjectField('params', mapStrParamsStrValue);
    objJsonGenerator.writeEndObject();

    objJsonGenerator.close();
    // {"params":{"caseId":"5006f00001dQm54AAC"},"TYPE":"GET_CASE_NUMBER"}
    String strRequestData = objJsonGenerator.getAsString();
    Boolean threwException = false;
    Test.startTest();
    try {

      String strResultData = RMAFormOrderController.singleSourceOfTruth(
        strRequestData
      );
    } catch (IllegalArgumentException e){
      threwException = true;
    }
    Test.stopTest();
    System.assert(threwException, 'message');

  }
  @TestSetup
  private static void makeData() {
    Account objAccount = new Account(
      Name = 'Test Account',
      Phone = '123-456-7890',
      BillingStreet = '123 street',
      BillingCity = 'Santa Clara',
      BillingState = 'California',
      BillingPostalCode = '95050',
      BillingCountry = 'United States'
    );
    insert objAccount;
    Map<String, Object> mapContactObject = new Map<String, Object>{
      'AccountId' => objAccount.Id
    };
    Contact objContact = (Contact) ShGl_TestFactory.createSObject(
      new Contact(),
      mapContactObject
    );
    insert objContact;
    Map<String, Object> mapCaseObject = new Map<String, Object>{
      'Subject' => 'RMA Test',
      'ContactId' => objContact.Id,
      'Jira_Reference_urls__c' => 'test',
      'Priority' => 'P2',
      'AccountId' => objAccount.Id
    };
    Case caseTest = (Case) ShGl_TestFactory.createSObject(
      new Case(),
      mapCaseObject
    );
    insert caseTest;

    List<Product2> lstProduct = new List<Product2>{
      new Product2(
        Name = 'RBK-SVC-NRD-ENTERPRISE',
        ProductCode = 'RBK-SVC-NRD-ENTERPRISE',
        Category__c = 'Platform',
        Family = 'R300',
        Support_Type__c = 'PREM',
        //Product_NIC_Type__c='SFP+',
        Appliance_Model__c = 'R348',
        Appliance_Model_HW__c = 'R348',
        License_Type__c = 'Consumption',
        Create_Asset_Entitlement__c = true,
        Asset_Priority__c = 0,
        IsActive = true
      ),
      new Product2(
        Name = 'RBK-SVC-PROACTIVE-ADDON-PA',
        ProductCode = 'RBK-SVC-PROACTIVE-ADDON-PA',
        Category__c = 'Platform',
        Family = 'R300',
        Support_Type__c = 'PREM',
        //Product_NIC_Type__c='SFP+',
        Appliance_Model__c = 'R348',
        Appliance_Model_HW__c = 'R348',
        License_Type__c = 'Consumption',
        Create_Asset_Entitlement__c = true,
        Asset_Priority__c = 0,
        IsActive = true
      )
    };
    insert lstProduct;

    List<Asset> lstAsset = new List<Asset>{
      new Asset(
        Name = 'SN1',
        SW_Version__c = '0.1',
        SerialNumber = 'SN1',
        Serial_Number__c = 'SN1',
        Product2Id = lstProduct[0].Id,
        Accountid = objAccount.Id
      ),
      new Asset(
        Name = 'SN2',
        SW_Version__c = '0.2',
        SerialNumber = 'SN2',
        Serial_Number__c = 'SN2',
        Product2Id = lstProduct[0].Id,
        Accountid = objAccount.Id
      ),
      new Asset(
        Name = 'SN3',
        SW_Version__c = '0.3',
        SerialNumber = 'SN3',
        Serial_Number__c = 'SN3',
        Product2Id = lstProduct[1].Id,
        Accountid = objAccount.Id
      ),
      new Asset(
        Name = 'SN4',
        SW_Version__c = '0.4',
        SerialNumber = 'SN4',
        Serial_Number__c = 'SN4',
        Product2Id = lstProduct[0].Id,
        Accountid = objAccount.Id
      ),
      new Asset(
        Name = 'SN5',
        SW_Version__c = '0.5',
        SerialNumber = 'SN5',
        Serial_Number__c = 'SN5',
        Product2Id = lstProduct[0].Id,
        Accountid = objAccount.Id
      ),
      new Asset(
        Name = 'SN6',
        SW_Version__c = '0.6',
        SerialNumber = 'SN6',
        Serial_Number__c = 'SN6',
        Product2Id = lstProduct[0].Id,
        Accountid = objAccount.Id
      )
    };
    insert lstAsset;


    TriggerControl__c customSettingTriggerCtrl = new TriggerControl__c();
    customSettingTriggerCtrl.Name = 'Entitlement';
    customSettingTriggerCtrl.DisableTrigger__c = false;
    insert customSettingTriggerCtrl;

    List<Entitlement> lstEntitlement = new List<Entitlement>{
      (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null),
      (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null),
      (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null),
      (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null),
      (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null),
      (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null),
      (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null),
      (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null)
    };

    for(Integer i = 0; i < 8; ++i ) {
      lstEntitlement[i].AccountId = objAccount.Id;
      lstEntitlement[i].StartDate = Date.today().addDays(-365);
      lstEntitlement[i].EndDate = Date.today().addDays(365);
      lstEntitlement[i].Product__c = lstProduct[0].Id;

      lstEntitlement[i].AssetId = lstAsset[i<4 ? 1:0].Id;
      if (i == 8) {
        lstEntitlement[i].Product__c = lstProduct[1].Id;
        lstEntitlement[i].AssetId = lstAsset[2].Id;
      }
    }
    insert lstEntitlement;



    lstAsset[0].ParentId = lstAsset[1].Id;
    update lstAsset;

    List<Cluster__c> lstCluster = new List<Cluster__c>{
      new Cluster__c(UUID__c = 'Test1', Name = 'Test1'),
      new Cluster__c(UUID__c = 'Test2', Name = 'Test2')
    };
    insert lstCluster;
    List<Chassis__c> lstChassis = new List<Chassis__c>{
      new Chassis__c(
        Name = 'C8270FH18NB0100',
        serial_number__c = 'C8270FH18NB0100',
        asset__c = lstAsset[0].Id,
        manufactured_date__c = System.now()
      ),
      new Chassis__c(
        Name = 'C8270FH18NB0101',
        serial_number__c = 'C8270FH18NB0101',
        asset__c = lstAsset[0].Id,
        manufactured_date__c = System.now()
      ),
      new Chassis__c(
        Name = 'C8270FH18NB0102',
        serial_number__c = 'C8270FH18NB0102',
        asset__c = lstAsset[1].Id,
        manufactured_date__c = System.now()
      )
    };

    insert lstChassis;

    List<Node__c> lstNode = new List<Node__c>{
      new Node__c(
        Cluster__c = lstCluster.get(0).Id,
        Asset__c = lstAsset.get(0).Id,
        Serial_Number__c = 'SNN-1-1',
        software_version__c = '1.0.1',
        Name = 'SNN-1-1',
        chassis__c = lstChassis[0].Id
      ),
      new Node__c(
        Cluster__c = lstCluster.get(0).Id,
        Asset__c = lstAsset.get(0).Id,
        Serial_Number__c = 'SNN-1-2',
        software_version__c = '1.0.1',
        Name = 'SNN-1-2',
        chassis__c = lstChassis[0].Id
      )
    };
    insert lstNode;
    List<Drive__c> lstHddAndSsd = new List<Drive__c>{
      new Drive__c(
        Name = '0RV5TST01',
        asset__c = lstAsset[0].Id,
        serial_number__c = '0RV5TST01',
        node__c = lstNode[0].Id,
        type__c = 'HDD',
        manufactured_date__c = System.now()
      ),
      new Drive__c(
        Name = '0RV5TST02',
        asset__c = lstAsset[0].Id,
        serial_number__c = '0RV5TST02',
        node__c = lstNode[0].Id,
        type__c = 'HDD',
        manufactured_date__c = System.now()
      ),
      new Drive__c(
        Name = '0RV5SSD01',
        asset__c = lstAsset[0].Id,
        serial_number__c = '0RV5SSD01',
        node__c = lstNode[0].Id,
        type__c = 'SSD',
        manufactured_date__c = System.now()
      ),
      new Drive__c(
        Name = '0RV5SSD02',
        asset__c = lstAsset[0].Id,
        serial_number__c = '0RV5SSD02',
        node__c = lstNode[0].Id,
        type__c = 'SSD',
        manufactured_date__c = System.now()
      )
    };

    insert lstHddAndSsd;

    List<Memory__c> lstMemory = new List<Memory__c>{
      new Memory__c(
        Name = '0RV5MEM01',
        asset__c = lstAsset[0].Id,
        serial_number__c = '0RV5MEM01',
        node__c = lstNode[0].Id,
        manufactured_date__c = System.now()
      ),
      new Memory__c(
        Name = '0RV5MEM02',
        asset__c = lstAsset[0].Id,
        serial_number__c = '0RV5MEM02',
        node__c = lstNode[0].Id,
        manufactured_date__c = System.now()
      )
    };
    insert lstMemory;

    List<Power_Supply__c> lstPsu = new List<Power_Supply__c>{
      new Power_Supply__c(
        Name = 'P2K22CI46AT3000',
        asset__c = lstAsset[0].Id,
        revision__c = '1.3',
        serial_number__c = 'P2K22CI46AT3000',
        part_number__c = 'PWS-2K22A-1R',
        manufactured_date__c = System.now()
      ),
      new Power_Supply__c(
        Name = 'P2K22CI46AT3001',
        asset__c = lstAsset[0].Id,
        revision__c = '1.3',
        serial_number__c = 'P2K22CI46AT3001',
        part_number__c = 'PWS-2K22A-1R',
        manufactured_date__c = System.now()
      )
    };

    insert lstPsu;

    List<RMA_Failure_List__c> lstFailureType = new List<RMA_Failure_List__c>{
      new RMA_Failure_List__c(
        Name = 'HDD',
        Failure_Type__c = 'Buffer IO Errors;Drive Missing;Bad Sectors;SMART Failure;Drive too hot;Suspected Software Issue;Other'
      ),
      new RMA_Failure_List__c(
        Name = 'SSD',
        Failure_Type__c = 'Buffer IO Errors;Drive Missing;Bad Sectors;SMART Failure;Drive too hot;Suspected Software Issue;Other'
      ),
      new RMA_Failure_List__c(
        Name = 'Appliance',
        Failure_Type__c = 'Damaged InTransit;Suspected Software Issue'
      ),
      new RMA_Failure_List__c(
        Name = 'Chassis',
        Failure_Type__c = 'Missing HDDs;Chassis Sag;Bent Frame;Bent ears;Fan Out of Range;Other;Suspected Software Issue'
      ),
      new RMA_Failure_List__c(
        Name = 'PSU',
        Failure_Type__c = 'Amber fail LED & Beeping;Unresponsive and dead;PSU Missing;Failure Detected;Other;Suspected Software Issue'
      ),
      new RMA_Failure_List__c(
        Name = 'Memory',
        Failure_Type__c = 'Uncorrectable Memory Error;DIMM not found;Too many correctable errors;Other;Suspected Software Issue'
      ),
      new RMA_Failure_List__c(
        Name = 'Node',
        Failure_Type__c = 'Would not power on;No video;Boot Failure;Bad SSD;MCE Error;Bad network card;Bad 1GbE ports;Voltage Out of Range;Temperature too hot;PCIE Uncorrectable Errors;Other;Suspected Software Issue'
      ),
      new RMA_Failure_List__c(
        Name = 'CMOS',
        Failure_Type__c = 'VBAT Out of Range;Other'
      )
    };
    insert lstFailureType;

    List<Asset> lstAssetRetrieved = new List<Asset> (
      [
        SELECT Id, serial_number__c,
          (
            SELECT Id, Status, Product__r.ProductCode, Product__r.Category__c
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
      ] 
    );
    System.debug('Print asset Entitlements:');
    for (Asset objAsset : lstAssetRetrieved) {
      System.debug(objAsset.Entitlements);
    }

}
}