/******************************************************************************
 * @description       : This Class has all the default values for test data creation sObject records
 * @author            : Prashik
 * @last modified on  : 11-08-2025
 * @last modified by  :
 * Modifications Log
 * Ver   Date          Author        Modification
 * 1.0   11-08-2025    Prashik       Initial Version
 ******************************************************************************/
@isTest
public with sharing class ProdOpsTestDataFactoryDefaults {
  public static final Id pricebookId = Test.getStandardPricebookId();

  public static final Map<String, Object> mapUserCommonFields = new Map<String, Object>{
    'EmailEncodingKey' => 'UTF-8',
    'LanguageLocaleKey' => 'en_US',
    'LocaleSidKey' => 'en_US',
    'TimeZoneSidKey' => 'America/Los_Angeles'
  };

  public static final Map<String, Object> mapAccountCommonFields = new Map<String, Object>{ 'Name' => 'Test Account' };

  public static final Map<String, Object> mapContactCommonFields = new Map<String, Object>{ 'FirstName' => 'John', 'LastName' => 'Doe', 'Email' => 'john.doe@test.com' };

  public static final Map<String, Object> mapOpportunityCommonFields = new Map<String, Object>{
    'StageName' => '1 Discovery',
    'CloseDate' => System.Today().addDays(30),
    'Name' => 'Test Opportunity',
    'Pricebook2Id' => pricebookId
  };

  public static final Map<String, Object> mapProductCommonFields = new Map<String, Object>{
    'Name' => 'RS-TB-EE-RSVX-PE',
    'ProductCode' => 'RS-TB-EE-RSVX-PE',
    'isActive' => true,
    'Product_Level__c' => 'Hybrid Software',
    'Product_Type__c' => 'Enterprise Edition',
    'Product_Subtype__c' => 'Scale MSP',
    'License_Category__c' => 'SaaS',
    'License_Type__c' => 'Consumption',
    'Quotable_Date__c' => system.today(),
    'SBQQ__Hidden__c' => false,
    'Support_Type__c' => 'Premium',
    'SBQQ__ExcludeFromOpportunity__c' => true,
    'SBQQSC__EntitlementConversion__c' => 'One per quote line',
    'New_CPQ_Product__c' => true,
    'SBQQ__SubscriptionPricing__c' => 'Fixed Price',
    'SBQQ__SubscriptionTerm__c' => 1
  };

  public static final Map<String, Object> mapPriceBookEntryCommonFields = new Map<String, Object>{ 'Pricebook2Id' => pricebookId, 'IsActive' => true, 'UnitPrice' => 100.0 };

  public static final Map<String, Object> mapQuoteCommonFields = new Map<String, Object>{
    'SBQQ__PriceBook__c' => pricebookId,
    'SBQQ__Primary__c' => true,
    'SBQQ__SubscriptionTerm__c' => 12
  };

  public static final Map<String, Object> mapQuoteLineCommonFields = new Map<String, Object>{
    'SBQQ__Quantity__c' => 1.0,
    'SBQQ__SubscriptionPricing__c' => 'Fixed Price',
    'SBQQ__DefaultSubscriptionTerm__c' => 1,
    'SBQQ__ListPrice__c' => 100.0,
    'SBQQ__NetPrice__c' => 100.0
  };

  public static final Map<String, Object> mapAssetCommonFields = new Map<String, Object>{
    'Name' => 'SN12345',
    'SerialNumber' => 'SN12345',
    'Serial_Number__c' => 'SN12345',
    'SW_Version__c' => '0.1'
  };

  public static final Map<String, Object> mapCaseCommonFields = new Map<String, Object>{ 'Status' => 'New', 'Origin' => 'Internal' };

  public static final Map<String, Object> mapOrderCommonFields = new Map<String, Object>{
    'Status' => 'Draft',
    'EffectiveDate' => Date.today(),
    'Polaris_Fulfillment_Status__c' => 'Completed',
    'Pricebook2Id' => pricebookId
  };

  public static final Map<String, Object> mapOrderItemCommonFields = new Map<String, Object>{ 'Quantity' => 1, 'UnitPrice' => 100.0 };

  public static final Map<String, Object> mapContractCommonFields = new Map<String, Object>{
    'Name' => 'Test Contract',
    'StartDate' => System.today(),
    'Pricebook2Id' => pricebookId
  };

  public static final Map<String, Object> mapCLICommonFields = new Map<String, Object>{ 'Quantity' => 1, 'UnitPrice' => 100 };

  public static final Map<String, Object> mapClusterCommonFields = new Map<String, Object>{ 'Name' => 'TestCluster', 'UUID__c' => 'TestUUID' };

  public static final Map<String, Object> mapChassisCommonFields = new Map<String, Object>{
    'Name' => 'C8270FH18NB0100',
    'serial_number__c' => 'C8270FH18NB0100',
    'manufactured_date__c' => System.now()
  };

  public static final Map<String, Object> mapPSUCommonFields = new Map<String, Object>{
    'Name' => 'P2K22CI46AT3000',
    'revision__c' => '1.3',
    'serial_number__c' => 'P2K22CI46AT3000',
    'part_number__c' => 'PWS-2K22A-1R',
    'manufactured_date__c' => System.now()
  };

  public static final Map<String, Object> mapNodeCommonFields = new Map<String, Object>{ 'Serial_Number__c' => 'SNN-1-1', 'software_version__c' => '1.0.1', 'Name' => 'SNN-1-1' };

  public static final Map<String, Object> mapDriveCommonFields = new Map<String, Object>{
    'serial_number__c' => '0RV5TST01',
    'type__c' => 'HDD',
    'manufactured_date__c' => System.now()
  };

  public static final Map<String, Object> mapMemoryCommonFields = new Map<String, Object>{ 'serial_number__c' => '0RV5MEM01', 'manufactured_date__c' => System.now() };

  public static final Map<String, Object> mapSparesMappingCommonFields = new Map<String, Object>{
    'Name' => 'Mapping-R348',
    'HDD__c' => 'RBK-R348-01',
    'SSD__c' => 'RBK-R348-01',
    'Product_Family__c' => 'R300',
    'Memory__c' => 'RBK-R348-01',
    'Chassis__c' => 'RBK-R348-01',
    'PSU__c' => 'RBK-R348-01',
    'Node__c' => 'RBK-R348-01',
    'Appliance_Model__c' => 'R348'
  };

  public static final Map<String, Object> mapOrderConfigCommonFields = new Map<String, Object>{
    'Start_Date__c' => System.today().addDays(-10),
    'End_Date__c' => System.today().addDays(10),
    'Target_Date__c' => System.today().addDays(-1),
    'Order_Type_to_be_considered__c' => 'Demo'
  };

  public static final Map<String, Object> mapRMAOrderCommonFields = new Map<String, Object>{
    'SSD_Quantity__c' => 1,
    'SSD__c' => '0RV5SSD01',
    'Service_Type__c' => 'Next Business Day: 8am',
    'Ship_To_Contact_Name__c' => 'Gaurav Jain',
    'Ship_To_Email__c' => 'gaurav.j@rubrik.com.test.sandbox',
    'Ship_To_Phone_Number__c' => '8971371780',
    'ShippingCountry__c' => 'India',
    'Shipping_City__c' => 'Bengaluru',
    'Shipping_Street__c' => 'Bellandur',
    'Shipping_Zip_Postal_Code__c' => '560103',
    'Type__c' => 'Advanced Replacement',
    'Valid_Support__c' => true,
    'Status__c' => 'Submitted'
  };

  public static final Map<String, Object> mapPOStageCommonFields = new Map<String, Object>{
    'Name' => 'PO Stage',
    'PO_Validation_Status__c' => 'Pending',
    'Shipment_Method_of_Payment__c' => 'PP',
    'Shipping_Account_Number__c' => '1234',
    'Shipping_Carrier__c' => 'MainFreight',
    'Service_Level__c' => 'Economy',
    'Payment_Terms__c' => 'Net 45'
  };

  public static final Map<String, Object> mapPOCCommonFields = new Map<String, Object>{
    'Name' => 'POC Deployment 1',
    'Status__c' => 'In Progress',
    'POC_Duration__c' => '60 Days',
    'Planned_Installation_Date__c' => Date.today().addDays(90),
    'Support_Awareness_needed__c' => 'Yes',
    'POC_Type__c' => 'EA Unit',
    'Product_Categories__c' => 'Rubrik Appliance'
  };

  /**
   * @description This method is used to get the default field mappings for sObject
   * @param sObjectType
   * @return Map<String, Object>
   */
  public static Map<String, Object> getDefaultFields(String sObjectType) {
    if (String.isBlank(sObjectType)) {
      return new Map<String, Object>();
    }

    switch on sObjectType.toLowerCase() {
      when 'user' {
        return mapUserCommonFields;
      }
      when 'account' {
        return mapAccountCommonFields;
      }
      when 'contact' {
        return mapContactCommonFields;
      }
      when 'opportunity' {
        return mapOpportunityCommonFields;
      }
      when 'product2' {
        return mapProductCommonFields;
      }
      when 'pricebookentry' {
        return mapPriceBookEntryCommonFields;
      }
      when 'sbqq__quoteline__c' {
        return mapQuoteLineCommonFields;
      }
      when 'sbqq__quote__c' {
        return mapQuoteCommonFields;
      }
      when 'asset' {
        return mapAssetCommonFields;
      }
      when 'case' {
        return mapCaseCommonFields;
      }
      when 'order' {
        return mapOrderCommonFields;
      }
      when 'orderitem' {
        return mapOrderItemCommonFields;
      }
      when 'servicecontract' {
        return mapContractCommonFields;
      }
      when 'contractlineitem' {
        return mapCLICommonFields;
      }
      when 'cluster__c' {
        return mapClusterCommonFields;
      }
      when 'chassis__c' {
        return mapChassisCommonFields;
      }
      when 'power_supply__c' {
        return mapPSUCommonFields;
      }
      when 'node__c' {
        return mapNodeCommonFields;
      }
      when 'drive__c' {
        return mapDriveCommonFields;
      }
      when 'memory__c' {
        return mapMemoryCommonFields;
      }
      when 'spares_mapping__c' {
        return mapSparesMappingCommonFields;
      }
      when 'rma_order__c' {
        return mapRMAOrderCommonFields;
      }
      when 'order_configuration__c' {
        return mapOrderConfigCommonFields;
      }
      when 'poc__c' {
        return mapPOCCommonFields;
      }
      when 'po_stage__c' {
        return mapPOStageCommonFields;
      }
      when else {
        return new Map<String, Object>();
      }
    }
  }

  public static final Map<String, List<Map<String, Object>>> businessModelProducts = new Map<String, List<Map<String, Object>>>{
    'PolarisV2' => new List<Map<String, Object>>{
      new Map<String, Object>{
        'Name' => 'RS-BT-EE-PE-PP',
        'ProductCode' => 'RS-BT-EE-PE-PP',
        'isActive' => true,
        'Product_Level__c' => 'Hybrid Software',
        'Quotable_Date__c' => system.today(),
        'Product_Subtype__c' => 'SaaS Cloud',
        'Family' => 'Rubrik Licence',
        'Bundle_Features__c' => 'Polaris Radar;App Flows;Cloud Native Protection;Sonar;Hybrid RCDM;Kubernetes;Cloud Cluster ES;NoSQL;Threat Hunting and Containment;Active Directory;Microsoft Entra ID;Threat Monitoring;Cloud Unstructured'
      },
      new Map<String, Object>{
        'Name' => 'RH-6416S-01',
        'ProductCode' => 'RH-6416S-01',
        'isActive' => true,
        'Product_Level__c' => 'Hardware',
        'Quotable_Date__c' => system.today(),
        'Product_Subtype__c' => null,
        'Family' => 'R6000'
      },
      new Map<String, Object>{
        'Name' => 'RC-F3M-CBL-01',
        'ProductCode' => 'RC-F3M-CBL-01',
        'isActive' => true,
        'Product_Level__c' => 'Hardware',
        'Quotable_Date__c' => system.today(),
        'Product_Subtype__c' => 'Cable',
        'Family' => 'CABLE'
      },
      new Map<String, Object>{
        'Name' => 'RC-SFP-TSR-01',
        'ProductCode' => 'RC-SFP-TSR-01',
        'isActive' => true,
        'Product_Level__c' => 'Hardware',
        'Quotable_Date__c' => system.today(),
        'Product_Subtype__c' => 'SFP',
        'Family' => 'SFP'
      },
      new Map<String, Object>{
        'Name' => 'RS-HW-SVC-PE-S3',
        'ProductCode' => 'RS-HW-SVC-PE-S3',
        'isActive' => true,
        'Product_Level__c' => 'Support',
        'Quotable_Date__c' => system.today(),
        'Product_Subtype__c' => null,
        'Family' => 'Support'
      }
    },
    'Aspen' => new List<Map<String, Object>>{
      new Map<String, Object>{
        'Name' => 'RS-BT-BE-PE-PP',
        'ProductCode' => 'RS-BT-BE-PE-PP',
        'isActive' => true,
        'Product_Level__c' => 'Hybrid Software',
        'Quotable_Date__c' => system.today(),
        'Product_Subtype__c' => 'SaaS Cloud',
        'Family' => 'Rubrik Licence',
        'Bundle_Features__c' => 'Polaris Radar;Cloud Native Protection;Hybrid RCDM;Kubernetes;Cloud Cluster ES;NoSQL;Active Directory;Microsoft Entra ID;Cloud Unstructured'
      },
      new Map<String, Object>{
        'Name' => 'RHA-6304S-01',
        'ProductCode' => 'RHA-6304S-01',
        'isActive' => true,
        'Product_Level__c' => 'Hardware',
        'Quotable_Date__c' => system.today(),
        'Product_Subtype__c' => null,
        'Family' => 'R6000'
      },
      new Map<String, Object>{
        'Name' => 'RS-BT-APFL-PE-PP',
        'ProductCode' => 'RS-BT-APFL-PE-PP',
        'isActive' => true,
        'Product_Level__c' => 'SaaS Software Addon',
        'Quotable_Date__c' => system.today(),
        'Product_Subtype__c' => null,
        'Family' => 'POLARIS',
        'License_Category__c' => 'SaaS',
        'License_Sub_Category__c' => 'RSC Addons'
      },
      new Map<String, Object>{
        'Name' => 'RCA-F3M-CBL-01',
        'ProductCode' => 'RCA-F3M-CBL-01',
        'isActive' => true,
        'Product_Level__c' => 'Hardware',
        'Product_Type__c' => 'Accessories',
        'Quotable_Date__c' => system.today(),
        'Product_Subtype__c' => 'Cable',
        'Family' => 'CABLE'
      },
      new Map<String, Object>{
        'Name' => 'RCA-SFP-TSR-01',
        'ProductCode' => 'RCA-SFP-TSR-01',
        'isActive' => true,
        'Product_Level__c' => 'Hardware',
        'Product_Type__c' => 'Accessories',
        'Quotable_Date__c' => system.today(),
        'Product_Subtype__c' => 'SFP',
        'Family' => 'SFP'
      },
      new Map<String, Object>{
        'Name' => 'RS-HW-SVC-PE-S1',
        'ProductCode' => 'RS-HW-SVC-PE-S1',
        'isActive' => true,
        'Product_Level__c' => 'Support',
        'Quotable_Date__c' => system.today(),
        'Product_Subtype__c' => null,
        'Family' => 'Support',
        'Product_Type__c' => 'HW Support'
      }
    },
    'Arroyo' => new List<Map<String, Object>>{
      new Map<String, Object>{ 'Name' => 'RS-BT-EE-PE-PP', 'ProductCode' => 'RS-BT-EE-PE-PP', 'Family' => 'Rubrik Licence', 'IsActive' => true },
      new Map<String, Object>{ 'Name' => 'RS-BT-RCDM-T', 'ProductCode' => 'RS-BT-RCDM-T', 'Family' => 'Rubrik Licence', 'IsActive' => true }
    },
    'NetApp' => new List<Map<String, Object>>{
      new Map<String, Object>{
        'Name' => 'RS-BT-FE-PE-PP',
        'ProductCode' => 'RS-BT-FE-PE-PP',
        'isActive' => true,
        'Product_Level__c' => 'Hybrid Software',
        'SBQQ__Hidden__c' => true,
        'Support_Type__c' => 'Premium',
        'SBQQ__ExcludeFromOpportunity__c' => true,
        'New_CPQ_Product__c' => true,
        'GPL_Name__c' => 'NetApp'
      },
      new Map<String, Object>{
        'Name' => 'RH-6416S-02',
        'ProductCode' => 'RH-6416S-02',
        'Category__c' => 'Platform',
        'Family' => 'R6000',
        'Usable_Capacity__c' => 50,
        'Product_Type__c' => 'Hardware',
        'Product_Level__c' => 'Hardware',
        'Appliance_Model__c' => 'RBK-R6416S',
        'Appliance_Model_HW__c' => 'RBK-R6416S',
        'SBQQ__AssetConversion__c' => null,
        'SBQQSC__EntitlementConversion__c' => 'None',
        'Create_Asset_Entitlement__c' => true,
        'isActive' => true,
        'Asset_Priority__c' => 0,
        'New_CPQ_Product__c' => true,
        'GPL_Name__c' => 'NetApp'
      },
      new Map<String, Object>{
        'Name' => 'RS-HW-SVC-PE',
        'ProductCode' => 'RS-HW-SVC-PE',
        'Category__c' => 'Support',
        'Product_Type__c' => 'HW Support',
        'Product_Level__c' => 'Support',
        'SBQQ__AssetConversion__c' => 'None',
        'SBQQSC__EntitlementConversion__c' => 'One per unit',
        'SBQQ__SubscriptionPricing__c' => 'Fixed Price',
        'SBQQ__SubscriptionTerm__c' => 12,
        'SBQQ__SubscriptionBase__c' => 'List',
        'SBQQ__SubscriptionType__c' => 'Renewable',
        'isActive' => true,
        'Support_Type__c' => 'L3',
        'Asset_Priority__c' => 1,
        'New_CPQ_Product__c' => true,
        'GPL_Name__c' => 'NetApp'
      },
      new Map<String, Object>{
        'Name' => 'Professional-Services',
        'ProductCode' => 'Professional-Services',
        'Category__c' => 'Professional Services',
        'Product_Type__c' => '',
        'Product_Level__c' => '',
        'SBQQ__AssetConversion__c' => 'None',
        'SBQQSC__EntitlementConversion__c' => null,
        'SBQQ__SubscriptionPricing__c' => null,
        'SBQQ__SubscriptionTerm__c' => null,
        'SBQQ__SubscriptionBase__c' => null,
        'SBQQ__SubscriptionType__c' => null,
        'isActive' => true,
        'New_CPQ_Product__c' => true,
        'GPL_Name__c' => 'NetApp'
      },
      new Map<String, Object>{
        'Name' => 'RC-F3M-CBL-01',
        'ProductCode' => 'RC-F3M-CBL-01',
        'Category__c' => 'Platform',
        'Product_Type__c' => 'Accessories',
        'Product_Level__c' => 'Hardware',
        'Family' => 'CABLE',
        'SBQQ__AssetConversion__c' => 'None',
        'SBQQSC__EntitlementConversion__c' => 'One per unit',
        'SBQQ__SubscriptionPricing__c' => 'Fixed Price',
        'SBQQ__SubscriptionTerm__c' => 12,
        'SBQQ__SubscriptionBase__c' => 'List',
        'SBQQ__SubscriptionType__c' => 'Renewable',
        'isActive' => true,
        'Support_Type__c' => null,
        'Asset_Priority__c' => 1,
        'New_CPQ_Product__c' => true,
        'GPL_Name__c' => 'NetApp'
      },
      new Map<String, Object>{
        'Name' => 'RS-BT-NDA-PE-PP',
        'ProductCode' => 'RS-BT-NDA-PE-PP',
        'Category__c' => 'Software',
        'Product_Type__c' => 'NAS',
        'Product_Level__c' => 'SaaS Software Addon',
        'Family' => 'POLARIS',
        'SBQQ__AssetConversion__c' => 'None',
        'SBQQSC__EntitlementConversion__c' => 'One per quote line',
        'SBQQ__SubscriptionPricing__c' => 'Fixed Price',
        'SBQQ__SubscriptionTerm__c' => 1,
        'SBQQ__SubscriptionBase__c' => 'List',
        'SBQQ__SubscriptionType__c' => 'Renewable',
        'isActive' => true,
        'Support_Type__c' => null,
        'Asset_Priority__c' => 1,
        'New_CPQ_Product__c' => true,
        'GPL_Name__c' => 'NetApp'
      },
      new Map<String, Object>{
        'Name' => 'RS-NRD-R6000S',
        'ProductCode' => 'RS-NRD-R6000S',
        'Category__c' => 'Support',
        'Product_Type__c' => null,
        'Product_Level__c' => null,
        'Family' => 'Non-Returnable Disk Service',
        'SBQQ__AssetConversion__c' => 'None',
        'SBQQSC__EntitlementConversion__c' => 'One per unit',
        'SBQQ__SubscriptionPricing__c' => 'Fixed Price',
        'SBQQ__SubscriptionTerm__c' => 1,
        'SBQQ__SubscriptionBase__c' => 'List',
        'SBQQ__SubscriptionType__c' => 'Renewable',
        'isActive' => true,
        'Support_Type__c' => null,
        'Asset_Priority__c' => 1,
        'New_CPQ_Product__c' => true,
        'GPL_Name__c' => 'NetApp'
      },
      new Map<String, Object>{
        'Name' => 'RS-BT-RCDM-T',
        'ProductCode' => 'RS-BT-RCDM-T',
        'License_Category__c' => 'On Prem',
        'Category__c' => 'Software',
        'Product_Level__c' => 'OnPrem',
        'Family' => 'OnPrem',
        'SBQQSC__EntitlementConversion__c' => 'One per quote line',
        'SBQQ__SubscriptionPricing__c' => 'Fixed Price',
        'SBQQ__SubscriptionTerm__c' => 1,
        'SBQQ__SubscriptionBase__c' => 'List',
        'SBQQ__SubscriptionType__c' => 'One-time',
        'isActive' => true,
        'Support_Type__c' => 'Premium',
        'New_CPQ_Product__c' => false,
        'GPL_Name__c' => 'NetApp'
      }
    },
    'ScaleUtility' => new List<Map<String, Object>>{
      new Map<String, Object>{
        'Name' => 'RS-TB-EE-RSV-PE',
        'ProductCode' => 'RS-TB-EE-RSV-PE',
        'isActive' => true,
        'Product_Level__c' => 'Hybrid Software',
        'Product_Type__c' => 'Enterprise Edition',
        'Product_Subtype__c' => 'Scale MSP',
        'License_Category__c' => 'SaaS',
        'License_Type__c' => 'Consumption',
        'Quotable_Date__c' => system.today(),
        'SBQQ__Hidden__c' => false,
        'Support_Type__c' => 'Premium',
        'SBQQ__ExcludeFromOpportunity__c' => true,
        'SBQQSC__EntitlementConversion__c' => 'One per quote line',
        'New_CPQ_Product__c' => true
      },
      new Map<String, Object>{
        'Name' => 'RS-TB-EE-RSVX-PE',
        'ProductCode' => 'RS-TB-EE-RSVX-PE',
        'isActive' => true,
        'Product_Level__c' => 'Hybrid Software',
        'Product_Type__c' => 'Enterprise Edition',
        'Product_Subtype__c' => 'Scale MSP',
        'License_Category__c' => null,
        'License_Type__c' => 'Consumption',
        'Quotable_Date__c' => system.today(),
        'SBQQ__Hidden__c' => false,
        'Support_Type__c' => 'Premium',
        'SBQQ__ExcludeFromOpportunity__c' => true,
        'SBQQSC__EntitlementConversion__c' => 'One per quote line',
        'New_CPQ_Product__c' => true
      },
      new Map<String, Object>{
        'Name' => 'RS-TB-EE-OND-PE',
        'ProductCode' => 'RS-TB-EE-OND-PE',
        'isActive' => true,
        'Product_Level__c' => 'Hybrid Software',
        'Product_Type__c' => 'Enterprise Edition',
        'Product_Subtype__c' => 'On Demand',
        'License_Category__c' => 'SaaS',
        'License_Type__c' => 'Subscription',
        'Quotable_Date__c' => system.today(),
        'SBQQ__Hidden__c' => false,
        'Support_Type__c' => 'Premium',
        'SBQQ__ExcludeFromOpportunity__c' => true,
        'New_CPQ_Product__c' => true
      }
    },
    'POC' => new List<Map<String, Object>>{ new Map<String, Object>{ 'Name' => 'POC-SW-01', 'ProductCode' => 'POC-SW-01', 'Family' => 'POC Software', 'IsActive' => true } },
    'RMA' => new List<Map<String, Object>>{
      new Map<String, Object>{
        'Name' => 'RBK-SVC-NRD-ENTERPRISE',
        'ProductCode' => 'RBK-SVC-NRD-ENTERPRISE',
        'Category__c' => 'Platform',
        'Family' => 'R300',
        'Support_Type__c' => 'PREM',
        'Appliance_Model__c' => 'R348',
        'Appliance_Model_HW__c' => 'R348',
        'License_Type__c' => 'Consumption',
        'Create_Asset_Entitlement__c' => true,
        'Asset_Priority__c' => 0,
        'IsActive' => true
      },
      new Map<String, Object>{
        'Name' => 'RBK-SVC-PROACTIVE-ADDON-PA',
        'ProductCode' => 'RBK-SVC-PROACTIVE-ADDON-PA',
        'Category__c' => 'Platform',
        'Family' => 'R300',
        'Support_Type__c' => 'PREM',
        'Appliance_Model__c' => 'R348',
        'Appliance_Model_HW__c' => 'R348',
        'License_Type__c' => 'Consumption',
        'Create_Asset_Entitlement__c' => true,
        'Asset_Priority__c' => 0,
        'IsActive' => true
      }
    },
    'Replacement' => new List<Map<String, Object>>{
      new Map<String, Object>{ 'Name' => 'RS-BT-FE-PE-PP', 'ProductCode' => 'RS-BT-FE-PE-PP', 'Family' => 'Rubrik Licence', 'IsActive' => true }
    }
  };

  /**
   * @description This is a helper method for product creation for specific business model
   * @param bm
   * @return List<Map<String,Object>>
   */
  public static List<Map<String, Object>> getProductsForBM(String bm) {
    return businessModelProducts.containsKey(bm) ? businessModelProducts.get(bm) : new List<Map<String, Object>>{ mapProductCommonFields };
  }
}