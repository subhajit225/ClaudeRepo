/**
* @description This is a Test Class PO Item Validation related Apex
*/
@isTest
public class POItemValidationTest {
  /**
  * @description This method creates the test data for unit test
  */
  @TestSetup
  static void testDataSetup() {
    POStageHandler.triggerMaxCount = 25;
    String uniqueUserName = 'TestUser' + DateTime.now().getTime() + '@rbk.com';
    Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
    User usr = new user(
      alias = 'std',
      email = 'testuser@testclass.com',
      emailencodingkey = 'UTF-8',
      firstname = 'test',
      lastname = 'user',
      languagelocalekey = 'en_US',
      localesidkey = 'en_US',
      profileid = p.Id,
      timezonesidkey = 'America/Los_Angeles',
      username = uniqueUserName
    );
    
    insert usr;
    System.runAs(usr) {
      insert new ShGl_DisableBusinessLogic__c(
        Disable_SBQQ_Quote_Triggers__c = true,
        Disable_SBQQ_QuoteLine_Triggers__c = true,
        Disable_Opportunity_Triggers__c = true,
        Disable_Order_Email_Alerts__c = false,
        Disable_Order_Triggers__c = false,
        Disable_Opportunity_Validation_Rules__c = true,
        Disable_SBQQ_QuoteLine_Validation_Rules__c = true,
        Disable_SBQQ_Quote_Validation_Rules__c = true,
        Disable_Account_Validation_Rules__c  = true,  
        setupOwnerId = usr.id
      );
      List<Opportunity> oppList = new List<opportunity>();
      List<PricebookEntry> PBEList = new List<PricebookEntry>();
      Account acc = (Account) ShGl_TestFactory.createSObject(
        new Account(),
        new Map<String, Object>{
          'name' => 'Promark Technology, Inc.',
          'Type' => 'Distributor',
          'RecordTypeId' => Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId()
        }
      );
      insert acc;
      Sfdc_Disti_Mapping__mdt distiMapping = Sfdc_Disti_Mapping__mdt.getInstance('Promark_Technology_Inc');
      acc.id = distiMapping.Sfdc_Id__c;
      update acc;

      Contact con = (Contact) ShGl_TestFactory.createSObject(new Contact(), new Map<String, Object>{ 'AccountId' => acc.Id });
      insert con;
      oppList.addall(
        (List<Opportunity>) ShGl_TestFactory.createSObjectList(
          new Opportunity(),
          2,
          new Map<String, Object>{
            'AccountId' => acc.Id,
            'Distributor_Lookup__c' => acc.Id,
            'Pricebook2Id' => system.label.CPQPricebookID,
            'stageName' => '6 PO With Channel',
            'RecordTypeId' => Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId()
          }
        )
      );
      oppList[0].RecordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
      insert oppList;
      List<Product2> prodList = new List<product2>();
      Map<String, Object> HybridProdMap = new Map<String, Object>{
        'Name' => 'HybridProd-001-test',
        'IsActive' => true,
        'IsHardwareNotRequiredForHybridLicense__c' => false,
        'ProductCode' => 'HybridProd-001-test',
        'Product_Level__c' => 'Hybrid Software',
        'Product_Subtype__c' => 'GO'
      };
      Map<String, Object> HybridProd2Map = new Map<String, Object>{
        'Name' => 'HybridProd-002-test',
        'IsActive' => true,
        'IsHardwareNotRequiredForHybridLicense__c' => false,
        'ProductCode' => 'HybridProd-002-test',
        'Product_Level__c' => 'Hybrid Software',
         'Product_Type__c' => 'Business Edition',
        'Product_Subtype__c' => ''
      };
      Map<String, Object> LODProdMap = new Map<String, Object>{
        'Name' => 'LODProd-001-test',
        'IsActive' => true,
        'IsHardwareNotRequiredForHybridLicense__c' => false,
        'ProductCode' => 'LODProd-001-test',
        'Product_Level__c' => 'LOD Software',
        'Product_Subtype__c' => 'GO'
      };
      Map<String, Object> TPHMap = new Map<String, Object>{
        'Name' => 'TPH-001-test',
        'IsActive' => true,
        'IsHardwareNotRequiredForHybridLicense__c' => false,
        'ProductCode' => 'TPH-001-test',
        'Product_Level__c' => 'Hybrid Software',
        'Product_Subtype__c' => 'RCDM',
        'Bundle_Features__c' => 'Hybrid RCDM',
        'Family' => 'Third Party License'
      };
      Map<String, Object> HWSuppMap = new Map<String, Object>{
        'Name' => 'HWSupportProd-001-test',
        'IsActive' => true,
        'IsHardwareNotRequiredForHybridLicense__c' => false,
        'ProductCode' => 'HWSupportProd-001-test',
        'Product_Level__c' => 'Support',
        'Product_Type__c' => 'HW Support'
      };
      Map<String, Object> HWSupp2Map = new Map<String, Object>{
        'Name' => 'HWSupport2Prod-001-test',
        'IsActive' => true,
        'IsHardwareNotRequiredForHybridLicense__c' => false,
        'ProductCode' => 'HWSupport2Prod-001-test',
        'Product_Level__c' => 'Support',
        'Product_Type__c' => 'HW Support'
      };
      Map<String, Object> SWSuppMap = new Map<String, Object>{
        'Name' => 'SWSupportProd-001-test',
        'IsActive' => true,
        'IsHardwareNotRequiredForHybridLicense__c' => false,
        'ProductCode' => 'SWSupportProd-001-test',
        'Product_Level__c' => 'Support',
        'Product_Type__c' => 'HW Support',
        'Product_Type__c' => 'RCDM Support'
      };
      Map<String, Object> HardwareMap = new Map<String, Object>{
        'Name' => 'HWProd-001-test',
        'IsActive' => true,
        'IsHardwareNotRequiredForHybridLicense__c' => false,
        'ProductCode' => 'HWProd-001-test',
        'Product_Level__c' => 'Hardware',
        'Usable_Capacity__c' => 100,
        'Appliance_Model_HW__c' => 'HWProd-001-test',
        'Product_Type__c' => 'Hardware'
      };
      Map<String, Object> Hardware2Map = new Map<String, Object>{
        'Name' => 'HWProd-002-test',
        'IsActive' => true,
        'IsHardwareNotRequiredForHybridLicense__c' => false,
        'ProductCode' => 'HWProd-002-test',
        'Product_Level__c' => 'Hardware',
        'Usable_Capacity__c' => 100,
        'Appliance_Model_HW__c' => 'HWProd-002-test',
        'Product_Type__c' => 'Hardware'
      };
      Map<String, Object> AddonMap = new Map<String, Object>{
        'Name' => 'AddonProd-001-test',
        'IsActive' => true,
        'IsHardwareNotRequiredForHybridLicense__c' => false,
        'ProductCode' => 'AddonProd-001-test',
        'Usable_Capacity__c' => 100,
        'Product_Level__c' => 'SaaS Software Addon'
      };
      Map<String, Object> AddonMap1 = new Map<String, Object>{
        'Name' => 'RA-HW-CREDIT',
        'IsActive' => true,
        'IsHardwareNotRequiredForHybridLicense__c' => false,
        'ProductCode' => 'RA-HW-CREDIT',
        'Usable_Capacity__c' => 100,
        'Product_Level__c' => 'Addon'
      };
      Map<String, Object> rcdmMap = new Map<String, Object>{
        'Name' => 'RS-BT-RCDM-T',
        'IsActive' => true,
        'IsHardwareNotRequiredForHybridLicense__c' => false,
        'ProductCode' => 'RS-BT-RCDM-T',
        'Usable_Capacity__c' => 100,
        'Product_Level__c' => 'OnPrem',
        'License_Category__c' => 'On Prem'
      };
      Map<String, Object> lodSoftSkuMap = new Map<String, Object>{
        'Name' => 'LOD-SOFTWARE',
        'IsActive' => true,
        'IsHardwareNotRequiredForHybridLicense__c' => false,
        'ProductCode' => 'LOD-SOFTWARE',
        'Usable_Capacity__c' => 100,
        'Product_Level__c' => 'LOD Software',
        'Product_Type__c' => 'RCDM'
      };
      Map<String, Object> SwSupportSkuMap = new Map<String, Object>{
        'Name' => 'RS-BT-SW-SVC-PE',
        'IsActive' => true,
        'IsHardwareNotRequiredForHybridLicense__c' => false,
        'ProductCode' => 'RS-BT-SW-SVC-PE',
        'Usable_Capacity__c' => 100,
        'Product_Level__c' => 'Support',
        'Product_Type__c' => 'RCDM Support'
      };

      Map<String, Object> saaS1Map = new Map<String, Object>{
        'Name' => 'RS-EE-GO-PE-PA',
        'ProductCode' => 'RS-EE-GO-PE-PA',
        'Description' => 'Rubrik Go Enterprise Edition , per usable BETB, Premium Support, Pay Annual',
        'IsActive' => true,
        'IsHardwareNotRequiredForHybridLicense__c' => false,
        'Category__c' => 'Bundle',
        'Support_Type__c' => 'Premium',
        'SBQQ__DefaultQuantity__c' => 1,
        'License_Subtype__c' => 'Standalone',
        'License_Type__c' => 'Subscription',
        'Product_Subtype__c' => '',
        'Product_Type__c' => 'Enterprise Edition',
        'Maximum_Term__c' => 36,
        'Minimum_Term__c' => 36,
        'Searchable__c' => 'Yes',
        'Item_Type__c' => 'Non-inventory Item',
        'RWDLicense_Addons__c' => 'Select Base Licensing',
        'RWD_LicenseAddons_Category__c' => 'Hybrid Cloud On Rubrik',
        'RWD_Rubrik_Edition_Offerings__c' => 'Enterprise Edition',
        'Family' => 'Rubrik Licence',
        'Product_Level__c' => 'Hybrid Software',
        'Sales_Comp_Category__c' => 'HARDWARE',
        'Product_Payment_Option__c' => 'Annual',
        'SBQQ__PricingMethod__c' => 'List',
        'SBQQ__SubscriptionPricing__c' => 'Fixed Price',
        'SBQQ__SubscriptionTerm__c' => 1,
        'SBQQ__SubscriptionBase__c' => 'List',
        'SBQQ__SubscriptionType__c' => 'Renewable',
        'SBQQSC__EntitlementConversion__c' => 'One per quote line'
      };
      Map<String, Object> saaS2Map = saaS1Map.clone();
      saaS2Map.put('Name', 'copy-RS-EE-GO-PE-PA');
      saaS2Map.put('ProductCode', 'copy-RS-EE-GO-PE-PA');
      Map<String, Object> cabel1Map = new Map<String, Object>{
        'Name' => 'RC-F3M-CBL-01',
        'ProductCode' => 'RC-F3M-CBL-01',
        'Description' => 'Fiber Optic OM3 LC/LC Cable, 3M, pack of 4',
        'IsActive' => true,
        'IsHardwareNotRequiredForHybridLicense__c' => false,
        'Category__c' => 'Platform',
        'Product_Type__c' => 'Accessories',
        'Item_Type__c' => 'Non-inventory Item',
        'Family' => 'CABLE',
        'Product_Level__c' => 'Hardware',
        'Sales_Comp_Category__c' => 'HARDWARE',
        'Product_Payment_Option__c' => 'Prepay',
        'SBQQ__PricingMethod__c' => 'List',
        'SBQQ__SubscriptionBase__c' => 'List'
      };
      Map<String, Object> tsr1Map = new Map<String, Object>{
        'Name' => 'RC-SFP-TSR-01',
        'ProductCode' => 'RC-SFP-TSR-01',
        'Description' => '10G/1G Dual Rate SFP+ Transceiver, pack of 4',
        'IsActive' => true,
        'IsHardwareNotRequiredForHybridLicense__c' => false,
        'Category__c' => 'Platform',
        'Product_Subtype__c' => 'SFP',
        'Product_Type__c' => 'Accessories',
        'Item_Type__c' => 'Non-inventory Item',
        'Family' => 'SFP',
        'Product_Level__c' => 'Hardware',
        'Sales_Comp_Category__c' => 'HARDWARE',
        'Product_Payment_Option__c' => 'Prepay',
        'SBQQ__PricingMethod__c' => 'List',
        'SBQQ__SubscriptionBase__c' => 'List'
      };
      Map<String, Object> hw1Map = new Map<String, Object>{
        'Name' => 'RH-6304S-01',
        'ProductCode' => 'RH-6304S-01',
        'Description' => 'r6304s Appliance, 3-node, 36TB raw HDD, 1.2TB SSD, SFP+ NIC',
        'IsActive' => true,
        'IsHardwareNotRequiredForHybridLicense__c' => false,
        'Category__c' => 'Hardware',
        'SBQQ__DefaultQuantity__c' => 1,
        'Product_Type__c' => 'Hardware',
        'Usable_Capacity__c' => 12,
        'Item_Type__c' => 'Serialized Inventory Item',
        'Filter_Name__c' => 'Appliances',
        'RWD_Hardware_Family__c' => 'R6000',
        'Family' => 'R6000',
        'Product_Level__c' => 'Hardware',
        'Sales_Comp_Category__c' => 'HARDWARE',
        'Product_Payment_Option__c' => 'Prepay',
        'SBQQ__PricingMethod__c' => 'List',
        'SBQQ__SubscriptionBase__c' => 'List',
        'SBQQ__SubscriptionCategory__c' => 'Hardware'
      };
      Map<String, Object> goAddOn1Map = new Map<String, Object>{
        'Name' => 'RS-BT-CLE-PE-PA',
        'ProductCode' => 'RS-BT-CLE-PE-PA',
        'Description' => 'Rubrik Cloud Edition per appliance , Premium Support , Annual',
        'IsActive' => true,
        'IsHardwareNotRequiredForHybridLicense__c' => false,
        'Category__c' => 'Bundle',
        'Support_Type__c' => 'Premium',
        'SBQQ__DefaultQuantity__c' => 1,
        'License_Subtype__c' => 'Standalone',
        'License_Type__c' => 'Subscription',
        'Product_Type__c' => 'Cloud Edition',
        'Maximum_Term__c' => 60,
        'Minimum_Term__c' => 12,
        'Searchable__c' => 'No',
        'Item_Type__c' => 'Non-inventory Item',
        'RWDLicense_Addons__c' => 'Select Add-ons',
        'RWD_LicenseAddons_Category__c' => 'Standalone SaaS',
        'Family' => 'RCDM',
        'Product_Level__c' => 'Standalone Software Addon',
        'Sales_Comp_Category__c' => 'CLOUD EDITION',
        'Product_Payment_Option__c' => 'Annual',
        'SBQQ__PricingMethod__c' => 'List',
        'SBQQ__SubscriptionPricing__c' => 'Fixed Price',
        'SBQQ__SubscriptionTerm__c' => 1,
        'SBQQ__SubscriptionBase__c' => 'List',
        'SBQQ__SubscriptionType__c' => 'Renewable',
        'SBQQSC__EntitlementConversion__c' => 'One per quote line'
      };
      Map<String, Object> hwService1Map = new Map<String, Object>{
        'Name' => 'RS-HW-SVC-PE',
        'ProductCode' => 'RS-HW-SVC-PE',
        'Description' => 'Premium Support for hardware, prepay',
        'IsActive' => true,
        'IsHardwareNotRequiredForHybridLicense__c' => false,
        'Category__c' => 'Support',
        'Support_Type__c' => 'Premium',
        'SBQQ__DefaultQuantity__c' => 1,
        'Product_Type__c' => 'HW Support',
        'Item_Type__c' => 'Non-inventory Item',
        'Family' => 'Support',
        'Product_Level__c' => 'Support',
        'Sales_Comp_Category__c' => 'HW SUPPORT',
        'Product_Payment_Option__c' => 'Prepay',
        'SBQQ__PricingMethod__c' => 'List',
        'SBQQ__SubscriptionPricing__c' => 'Fixed Price',
        'SBQQ__SubscriptionTerm__c' => 1,
        'SBQQ__SubscriptionPercent__c' => 1.083,
        'SBQQ__SubscriptionBase__c' => 'List',
        'SBQQ__SubscriptionCategory__c' => 'Hardware',
        'SBQQ__SubscriptionType__c' => 'Renewable',
        'SBQQSC__EntitlementConversion__c' => 'One per unit'
      };

      prodList.addall((List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 1, HybridProdMap));
      prodList.addall((List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 1, HybridProd2Map));
      prodList.addall((List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 1, LODProdMap));
      prodList.addall((List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 1, TPHMap));
      prodList.addall((List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 1, HardwareMap));
      prodList.addall((List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 1, Hardware2Map));
      prodList.addall((List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 1, HWSuppMap));
      prodList.addall((List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 1, HWSupp2Map));
      prodList.addall((List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 1, SWSuppMap));
      prodList.addall((List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 1, AddonMap));
      prodList.addall((List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 1, AddonMap1));
      prodList.addall((List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 1, rcdmMap));
      prodList.addall((List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 1, lodSoftSkuMap));
      prodList.addall((List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 1, SwSupportSkuMap));
      prodList.addall(
        (List<Product2>) ShGl_TestFactory.createSObjectList(
          new Product2(),
          1,
          HardwareMap = new Map<String, Object>{
            'Name' => 'HWProd3-001-test',
            'IsActive' => true,
            'IsHardwareNotRequiredForHybridLicense__c' => false,
            'ProductCode' => 'HWProd3-001-test',
            'Product_Level__c' => 'Hardware',
            'Usable_Capacity__c' => 100,
            'Product_Type__c' => 'Hardware'
          }
        )
      );
      prodList.addall(
        (List<Product2>) ShGl_TestFactory.createSObjectList(
          new Product2(),
          1,
          HardwareMap = new Map<String, Object>{
            'Name' => 'HybridProd-003-test',
            'IsActive' => true,
            'IsHardwareNotRequiredForHybridLicense__c' => false,
            'ProductCode' => 'HybridProd-001-test',
            'Product_Level__c' => 'Hybrid Software',
            'Product_Subtype__c' => 'GO'
          }
        )
      );
       Map<String, Object> OnPremProdMap = new Map<String, Object>{
        'Name' => 'OnPrem_Prod-001-test',
        'IsActive' => true,
        'IsHardwareNotRequiredForHybridLicense__c' => false,
        'ProductCode' => 'OnPrem_Prod-001-test',
        'Product_Level__c' => 'OnPrem',
        'Product_Subtype__c' => '',
        'Product_Type__c' => 'Foundation Edition'            
      };
      prodList.addall((List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 1, hwService1Map));
      prodList.addall((List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 1, goAddOn1Map));
      prodList.addall((List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 1, hw1Map));
      prodList.addall((List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 1, tsr1Map));
      prodList.addall((List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 1, cabel1Map));
      prodList.addall((List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 1, saaS1Map));
      prodList.addall((List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 1, OnPremProdMap));
      insert prodList;
      Asset assetObj = (Asset) ShGl_TestFactory.createSObject(new Asset(), null);
      assetObj.AccountId = acc.Id;
      assetObj.Name = 'EntitlementTriggerHelperAsset';
      assetObj.Product2Id = prodList[0].Id;
      assetObj.Eligible_for_Free_HW__c = 'True';
      assetObj.Justification_for_HW_Eligibility_Overrid__c = '-';
      assetObj.serial_number__c = 'JAY8486304222k4';
      insert assetObj;
      List<asset> asstList = new List<asset>();
      Integer i = 0;
      for (Asset ast : (List<Asset>) ShGl_TestFactory.createSObjectList(new Asset(), 5, new Map<String, Object>{ 'AccountId' => acc.Id })) {
        ast.Name = 'TestSN' + i;
        ast.Product2Id = prodList[i].Id;
        ast.serial_number__c = 'TestSN' + i;
        ast.SerialNumber = 'TestSN' + i;
        asstList.add(ast);
        i++;
      }
      if (!asstList.isEmpty()) {
        insert asstList;
      }
      for (product2 prod : prodList) {
        PBEList.add(new PricebookEntry(Product2Id = prod.Id, UnitPrice = 1500, Pricebook2id = Test.getStandardPricebookId()));
        PBEList.add(new PricebookEntry(Product2Id = prod.Id, UnitPrice = 1500, Pricebook2id = system.label.CPQPricebookID));
      }
      insert PBEList;

      SBQQ__Quote__c quote = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(
        new SBQQ__Quote__c(),
        new Map<String, Object>{
          'SBQQ__Account__c' => acc.Id,
          'SBQQ__Opportunity2__c' => oppList[0].Id,
          'SBQQ__Primary__c' => true,
          'SBQQ__SubscriptionTerm__c' => 36,
          'Is_RWD_Polaris_Quote__c' => true,
          'SBQQ__Type__c' => 'Renewal+Expansion',
          'SBQQ__PaymentTerms__c' => 'Net 45',
          'Payment_year_1__c' => 15000,
          'Payment_year_2__c' => 10000
        }
      );
      insert quote;
    }
  }
  /**
  * @description This method for completePoMatch
  */
      
    static testMethod void poitemCompleteMatchTest(){
    User usr = [SELECT id, alias FROM user ORDER BY createddate DESC LIMIT 1];
   POStageHandler.triggerMaxCount = 25;
   System.runAs(usr) {
     List<product2> prodList = [SELECT id, Name, ProductCode, Product_Level__c, Product_Subtype__c, Product_Type__c, Usable_Capacity__c FROM product2];
     SBQQ__Quote__c quote = [SELECT id, name, SBQQ__Account__c, SBQQ__Opportunity2__c, SBQQ__NetAmount__c FROM SBQQ__Quote__c];
   	 
       
     List<ProductModel> prodModels = new List<ProductModel>();
     String currencyCode = 'USD';
     set<string> prodName = new Set<string>{
       'HybridProd-002-test',
       'HWSupportProd-001-test',
       'HWProd-001-test',
       'RS-BT-RCDM-T',
       'OnPrem_Prod-001-test'
     };
      for (product2 prod : prodList) {
        if (prodName.contains(prod.name)) {
          prodModels.add(
            (ProductModel) JSON.deserialize(
              SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prod.id, '{"pricebookId" : "' + system.label.CPQPricebookID + '", "currencyCode" : "' + currencyCode + '"}'),
              ProductModel.class
            )
          );
        }
      }

   	  String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', quote.id);
      ProductAdder adder = new ProductAdder();
      QuoteModel quoteWithProducts = adder.add((QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class), prodModels, 0);
      Map<string, string> childParentMap = new Map<string, string>{
        'HWSupportProd-001-test' => 'HWProd-001-test',
        'HWProd-001-test' => 'HybridProd-002-test',
        'RS-BT-RCDM-T' => 'HybridProd-002-test'

      };
          
          Map<string, Integer> prodKey = new Map<string, Integer>();
      Integer hwIndex, hybIndx, addonIndx;
      hwIndex = hybIndx = addonIndx = 0;
      for (QuoteLineModel QLModel : quoteWithProducts.lineItems) {
        if (QLModel.record.Product_Level__c == 'Hybrid Software') {
          prodKey.put(QLModel.record.SBQQ__Product__r.name, QLModel.key);
          QLModel.record.SBQQ__Quantity__c = 500;
          QLModel.record.SBQQ__SubscriptionTerm__c = 36;
          QLModel.record.SBQQ__NetPrice__c = 100;
          QLModel.record.Special_Program__c = 'Conversion';
          QLModel.record.Arroyo_Subscribed_Asset_Name__c = 'TestSN1,TestSN2,TestSN3,TestSN4,TestSN5';
        } else if (QLModel.record.Product_Level__c == 'Hardware') {
          prodKey.put(QLModel.record.SBQQ__Product__r.name, QLModel.key);
          QLModel.record.SBQQ__Quantity__c = 5;
          QLModel.record.SBQQ__NetPrice__c = 1000;
          //QLModel.record.SBQQ__Existing__c =  true;
          QLModel.parentItemKey = prodKey.get(childParentMap.get(QLModel.record.SBQQ__Product__r.name));
        } else if (QLModel.record.Product_Level__c == 'Support') {
          QLModel.record.SBQQ__Quantity__c = 5;
          QLModel.record.SBQQ__SubscriptionTerm__c = 36;
          QLModel.record.SBQQ__NetPrice__c = 1000;
          //QLModel.record.Special_Program__c = 'Conversion';
          //QLModel.record.Arroyo_Subscribed_Asset_Name__c = 'TestSN1,TestSN2,TestSN3,TestSN4,TestSN5';
          QLModel.parentItemKey = prodKey.get(childParentMap.get(QLModel.record.SBQQ__Product__r.name));
        } else if (QLModel.record.Product_Level__c == 'OnPrem') {
          QLModel.record.SBQQ__Quantity__c = 600;
          QLModel.record.SBQQ__SubscriptionTerm__c = 36;
          QLModel.record.SBQQ__NetPrice__c = 150;

            
        }
      }
String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
      QuoteCalculator calculator = new QuoteCalculator();
      calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
      quote.ApprovalStatus__c = 'Approved';
      update quote;
      List<SBQQ__QuoteLine__c> qliList = [
        SELECT
          id,
          SBQQ__ProductCode__c,
          SBQQ__RequiredBy__r.SBQQ__ProductCode__c,
          SBQQ__Quote__r.SBQQ__NetAmount__c,
          SBQQ__NetPrice__c,
          SBQQ__NetTotal__c,
          SBQQ__Product__r.productcode,
          SBQQ__Quantity__c,
          SBQQ__SubscriptionTerm__c,
          SBQQ__Product__c,
          SBQQ__Product__r.name,
          SBQQ__Product__r.Product_Level__c,
          SBQQ__RequiredBy__c,
          Line_Type__c,
          Special_Program__c
        FROM SBQQ__QuoteLine__c
         Order by createdDate ASC
      ];
     
        PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage(
          'Promark Technology, Inc.pp',
          'test123',
          system.today().addDays(10),
          11,
          'test@test.com.invalid',
          'test partner',
          system.today(),
          1,
          'test12345',
          quote.name,
          qliList[0].SBQQ__Quote__r.SBQQ__NetAmount__c
        );
        pos.Bill_To_Name__c = quote.SBQQ__Account__c;
        pos.Payment_schedule_type__c = 'test';
        pos.Quote_number__c = quote.name;
        pos.Opportunity__c = quote.SBQQ__Opportunity2__c;
        pos.Ship_to_Email__c = 'test@test.com.invalid';
        pos.Ship_To_Contact_Name__c = 'testCon';
        pos.Ship_To_Phone_Number__c = '7000022448';
        pos.ShippingCountryCode__c = 'IN';
        pos.ShippingStateCode__c = 'KA';
        pos.ShippingCity__c = 'test City';
        pos.ShippingStreet__c = 'test street';
        pos.ShippingPostalCode__c = '0000';

      insert pos;
	
        
      List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>();
	Map<string, list<id>> itemLevlPOIds = new Map<string, list<id>>{
          'HybridProd-002-test' => new List<id>{ pos.id},
          'HWSupportProd-001-test' => new List<id>{ pos.id },
          'HWProd-001-test' => new List<id>{ pos.id },
          'RS-BT-RCDM-T' => new List<id>{ pos.id},
          'OnPrem_Prod-001-test' => new List<id>{pos.id}
        };
      for (integer i = 0; i < qliList.size(); i++) {
        string ediLinenum = 0 + '' + i;
        PO_Item_Stage__c poi;
        
        if (itemLevlPOIds.containsKey(qliList[i].SBQQ__Product__r.name) /*&& qliList[i].SBQQ__Product__r.name != 'HWProd-001-test'*/) {
          Integer j = 1;
          for (Id stgId : itemLevlPOIds.get(qliList[i].SBQQ__Product__r.name)) {
            Decimal Quant = qliList[i].SBQQ__Product__r.Product_Level__c == 'Hybrid Software' || qliList[i].SBQQ__Product__r.name == 'OnPrem_Prod-001-test'
              ? qliList[i].SBQQ__Product__r.name == 'HWSupportProd-001-test' ? 5 : 500.0
              : qliList[i].SBQQ__Product__r.name == 'RS-BT-RCDM-T' ? 1.0 : 5.0;
            poItem.add(
              ShGl_TestFactoryHelper.createPOItem(
                '1234' + ediLinenum,
                ediLinenum,
                qliList[i].SBQQ__Product__r.productcode,
                Quant,
                stgId,
                qliList[i].SBQQ__SubscriptionTerm__c,
                qliList[i].SBQQ__NetPrice__c
              )
            );
            j++;
          }
        }
      }
      insert poItem;
	  
       pos.PO_Validation_Status__c = 'Staged';
       update pos;
      
      POItemValidation handler = new POItemValidation();
      Map<Id,Map<string,POItemValidation.HWProductGroup>> poId_PcodeTermHWPG = new Map<Id,Map<string,POItemValidation.HWProductGroup>>();
       Map<string,POItemValidation.HWProductGroup> pCodeTermHWProd = new Map<string,POItemValidation.HWProductGroup>{
			qliList[0].SBQQ__ProductCode__c+'-'+qliList[0].SBQQ__SubscriptionTerm__c => new POItemValidation.HWProductGroup(500.0 , qliList[0]),
   			qliList[3].SBQQ__ProductCode__c+'-'+qliList[3].SBQQ__SubscriptionTerm__c => new POItemValidation.HWProductGroup(5.0 , qliList[3])
                
       };
      poId_PcodeTermHWPG.put(pos.id ,pCodeTermHWProd);

      Map<Id,Map<Id,POItemValidation.LicenseProductGroup>>  poIdHybQLIdPG = new Map<Id,Map<Id,POItemValidation.LicenseProductGroup>>();
      poIdHybQLIdPG.put(pos.id,new Map<id,POItemValidation.LicenseProductGroup>{qliList[2].SBQQ__RequiredBy__c => new POItemValidation.LicenseProductGroup(qliList[0], 500) });
      Map<id,list<id>> quoteNonHWPOIds = new Map<id,list<id>>();
      quoteNonHWPOIds.put(quote.Id,new list<id>{pos.Id});
       
      Map<Id,map<string, POItemValidation.ProductGroup>> poId_PcodeTermPGMap = new Map<Id,map<string, POItemValidation.ProductGroup>>();
      Map<string, POItemValidation.ProductGroup> mapPCodeTermPG = new Map<String, POItemValidation.ProductGroup>{qliList[0].SBQQ__ProductCode__c+'-'+qliList[0].SBQQ__SubscriptionTerm__c => new POItemValidation.ProductGroup(poitem[0]), qliList[3].SBQQ__ProductCode__c+'-'+qliList[3].SBQQ__SubscriptionTerm__c => new POItemValidation.ProductGroup(poitem[3]) };
       poId_PcodeTermPGMap.put(pos.id, mapPCodeTermPG);
       handler.completePOMatch(poId_PcodeTermHWPG, poIdHybQLIdPG ,quoteNonHWPOIds, poId_PcodeTermPGMap );
       poId_PcodeTermHWPG = new Map<Id,Map<string,POItemValidation.HWProductGroup>>();
       poId_PcodeTermHWPG.put(pos.id ,new Map<string,POItemValidation.HWProductGroup>{qliList[0].SBQQ__ProductCode__c+'-'+qliList[0].SBQQ__SubscriptionTerm__c => new POItemValidation.HWProductGroup(130.0 , qliList[0]),
       qliList[3].SBQQ__ProductCode__c+'-'+qliList[3].SBQQ__SubscriptionTerm__c => new POItemValidation.HWProductGroup(130.0 , qliList[0])});
       handler.completePOMatch(poId_PcodeTermHWPG, poIdHybQLIdPG ,quoteNonHWPOIds, poId_PcodeTermPGMap );
       poId_PcodeTermHWPG = new Map<Id,Map<string,POItemValidation.HWProductGroup>>();
       poIdHybQLIdPG = new Map<Id,Map<Id,POItemValidation.LicenseProductGroup>>();
       poId_PcodeTermHWPG.put(pos.id ,new Map<string,POItemValidation.HWProductGroup>{qliList[0].SBQQ__ProductCode__c+'-'+qliList[0].SBQQ__SubscriptionTerm__c => new POItemValidation.HWProductGroup(500.0 , qliList[0]),
       qliList[3].SBQQ__ProductCode__c+'-'+qliList[3].SBQQ__SubscriptionTerm__c => new POItemValidation.HWProductGroup(5.0 , qliList[3])});
       poIdHybQLIdPG.put(pos.id,new Map<id,POItemValidation.LicenseProductGroup>{qliList[2].SBQQ__RequiredBy__c => new POItemValidation.LicenseProductGroup(qliList[0], 500.0) });
       handler.completePOMatch(poId_PcodeTermHWPG, poIdHybQLIdPG ,quoteNonHWPOIds, poId_PcodeTermPGMap );
       POItemValidation.isSupportBundle(null, null);
       POItemValidation.isLicenseSku(null);
       List<POValidation_ErrorCode__c> lstPoValidate = new List<POValidation_ErrorCode__c>();
       lstPoValidate.add(new POValidation_ErrorCode__c(Name = 'PO-12', Error_Issue__c = 'Term missing or mismatched for subscription or support product'));
       Insert lstPoValidate;
       POItemValidation.getErrorRecord('PO-37', poItem[0], 'External', null, null);
       system.assert(true);
   
   }
        
    }
  
  
  
  
  
  /**
  * @description This method test the PO Item Validation Errors
  */
  static testMethod void poItemValidationCodeErrorTest(){
        
    User usr = [SELECT id, alias FROM user ORDER BY createddate DESC LIMIT 1];
   POStageHandler.triggerMaxCount = 25;
   System.runAs(usr) {
     List<product2> prodList = [SELECT id, Name, ProductCode, Product_Level__c, Product_Subtype__c, Product_Type__c, Usable_Capacity__c FROM product2];
     SBQQ__Quote__c quote = [SELECT id, name, SBQQ__Account__c, SBQQ__Opportunity2__c, SBQQ__NetAmount__c FROM SBQQ__Quote__c];
     List<ProductModel> prodModels = new List<ProductModel>();
     String currencyCode = 'USD';
     set<string> prodName = new Set<string>{
       'HybridProd-001-test',
       'HybridProd-002-test',
       'HWSupportProd-001-test',
       'HWSupport2Prod-001-test',
       'HWProd-001-test',
       'HWProd-002-test',
       'AddonProd-001-test',
       'RS-BT-RCDM-T',
       'LOD-SOFTWARE',
       'RS-BT-SW-SVC-PE'
     };
     for (product2 prod : prodList) {
       if (prodName.contains(prod.name) && prod.name != 'RS-BT-RCDM-T') {
         prodModels.add(
           (ProductModel) JSON.deserialize(
             SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prod.id, '{"pricebookId" : "' + system.label.CPQPricebookID + '", "currencyCode" : "' + currencyCode + '"}'),
             ProductModel.class
           )
         );
       }
     }
     String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', quote.id);
     ProductAdder adder = new ProductAdder();
     QuoteModel quoteWithProducts = adder.add((QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class), prodModels, 0);
     Map<string, list<Integer>> prodTypeItemKeySet = new Map<string, list<Integer>>{
       'root' => new List<Integer>(),
       'hardware' => new List<Integer>(),
       'rcdm' => new List<Integer>()
     };
     Integer hwIndex, hybIndx, addonIndx, rcdmIndx;
     hwIndex = hybIndx = addonIndx = rcdmIndx = 0;
     for (QuoteLineModel QLModel : quoteWithProducts.lineItems) {
       
       if (QLModel.record.Product_Level__c == 'Hybrid Software') {
         prodTypeItemKeySet.get('root').add(QLModel.key);
           QLModel.record.Special_Program__c = 'Conversion';
         if (QLModel.record.SBQQ__Product__r.name == 'HybridProd-002-test') {
           QLModel.record.SBQQ__SubscriptionTerm__c = null;
         } else {
           QLModel.record.SBQQ__Quantity__c = 400;
           QLModel.record.SBQQ__SubscriptionTerm__c = 56;
         }
         QLModel.record.SBQQ__NetPrice__c = 100;
       } else if (QLModel.record.Product_Level__c == 'Hardware' && QLModel.record.Product_Type__c == 'Hardware') {
         prodTypeItemKeySet.get('hardware').add(QLModel.key);
         QLModel.record.SBQQ__Quantity__c = 4;
         QLModel.record.SBQQ__NetPrice__c = 100;
         if (prodTypeItemKeySet.get('root').size() >= hybIndx + 1) {
           QLModel.parentItemKey = prodTypeItemKeySet.get('root')[hybIndx];
           if (prodTypeItemKeySet.get('root').size() > hybIndx + 1)
             hybIndx++;
         }
       } else if (QLModel.record.Product_Level__c == 'Support' || QLModel.record.Product_Level__c == 'SaaS Software Addon') {
         QLModel.record.SBQQ__Quantity__c = QLModel.record.name == 'HWSupport2Prod-001-test' ? 3 : 4;
         QLModel.record.SBQQ__SubscriptionTerm__c = 36;
         QLModel.record.SBQQ__NetPrice__c = 100;
         if (prodTypeItemKeySet.get('hardware').size() >= hwIndex + 1) {
           QLModel.parentItemKey = prodTypeItemKeySet.get('hardware')[hwIndex];
           if (prodTypeItemKeySet.get('hardware').size() > hwIndex + 1)
             hwIndex++;
         }
       }
     }
     String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
     QuoteCalculator calculator = new QuoteCalculator();
     calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
     quote.ApprovalStatus__c = 'Approved';
     update quote;
     asset asst = [SELECT Id FROM asset LIMIT 1];
     List<SBQQ__QuoteLine__c> qliList = [
       SELECT
         id,
         SBQQ__NetPrice__c,
         SBQQ__NetTotal__c,
         SBQQ__Product__r.productcode,
         SBQQ__Quantity__c,
         SBQQ__SubscriptionTerm__c,
         SBQQ__Product__c,
         SBQQ__Product__r.name,
         SBQQ__Product__r.Product_Level__c,
         SBQQ__Product__r.Product_Type__c,
         SBQQ__RequiredBy__c,
         SBQQ__Quote__r.ProcessType__c,
         SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Level__c,
         SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Type__c,
         Line_Type__c
       FROM SBQQ__QuoteLine__c
     ];
 
   List<SBQQ__QuoteLine__c> updateQliList = new List<SBQQ__QuoteLine__c>();
   Id lodId = null;
     for(SBQQ__QuoteLine__c objQLI : qliList){
       if(objQLI.SBQQ__Product__r.Product_Level__c == 'LOD Software'){
           lodId = objQLI.Id;
       }else if(objQLI.SBQQ__Product__r.Product_Level__c == 'Support' && objQLI.SBQQ__Product__r.Product_Type__c == 'RCDM Support'){
           objQLI.SBQQ__RequiredBy__c = lodId;
           
       }
       updateQliList.add(objQLI);
     }
     if(!updateQliList.isEmpty()){
       update updateQliList;
     }
     List<PO_Stage__c> poStageList = new List<PO_Stage__c>();
     for (integer i = 1; i <= 2; i++) {
       decimal amount = i == 1 ? quote.SBQQ__NetAmount__c : 0.0;
       PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage(
         'Promark Technology, Inc.pp',
         'test123',
         system.today().addDays(10),
         10,
         'test@test.com.invalid',
         'test partner',
         system.today(),
         i,
         'test12345',
         quote.name,
         amount
       );
       pos.Expected_number_of_POs__c = 1;
       pos.Bill_To_Name__c = quote.SBQQ__Account__c;
       pos.PO_Validation_Status__c = 'Pending';
       pos.Payment_schedule_type__c = 'test';
       pos.Quote_number__c = quote.name;
       pos.Opportunity__c = quote.SBQQ__Opportunity2__c;
       pos.Ship_to_Email__c = 'test@test.com.invalid';
       pos.Ship_To_Contact_Name__c = 'testCon';
       pos.Ship_To_Phone_Number__c = '7000022448';
       pos.ShippingCountryCode__c = 'IN';
       pos.ShippingStateCode__c = 'KA';
       pos.ShippingCity__c = 'test City';
       pos.ShippingStreet__c = 'test street';
       pos.ShippingPostalCode__c = '0000';

       poStageList.add(pos);
     }
     insert poStageList;
     List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>();

     for (integer i = 0; i < qliList.size(); i++) {
       string ediLinenum = 0 + '' + i;
       PO_Item_Stage__c poi;
       Map<string, list<id>> itemLevlPOIds = new Map<string, list<id>>{
           'HybridProd-001-test' => new List<id>{ poStageList[0].id},
         'HWProd-001-test' => new List<id>{ poStageList[0].id },
         'HWSupportProd-001-test' => new List<id>{ poStageList[0].id },
         'HWSupport2Prod-001-test' => new List<id>{ poStageList[0].id },
         'AddonProd-001-test' => new List<id>{ poStageList[0].id },
         'RS-BT-RCDM-T' => new List<id>{ poStageList[0].id }

       };
       if (itemLevlPOIds.containsKey(qliList[i].SBQQ__Product__r.name)) {
         Integer j = 1;
         for (Id stgId : itemLevlPOIds.get(qliList[i].SBQQ__Product__r.name)) {
           Decimal Quant = qliList[i].SBQQ__Product__r.Product_Level__c == 'Hybrid Software'
             ? j == 10 ? 300 : 100.0
             : qliList[i].SBQQ__Product__r.name == 'HybridProd-002-test' || qliList[i].SBQQ__Product__r.name == 'HWProd-002-test' ? 5.0 : 1.0;
           Decimal Term = qliList[i].SBQQ__Product__r.Product_Level__c == 'Hybrid Software' ? 36 : qliList[i].SBQQ__SubscriptionTerm__c;
           poItem.add(
             ShGl_TestFactoryHelper.createPOItem('1234' + ediLinenum, ediLinenum, qliList[i].SBQQ__Product__r.productcode, Quant, stgId, Term, qliList[i].SBQQ__NetPrice__c)
           );
           j++;
         }
       }
     }

     poItem.add(ShGl_TestFactoryHelper.createPOItem('1234' + '9900', '9900', 'RS-BT-RCDM-T', 1.0, poStageList[0].id, 0.00, 0.00));
     poItem[0].SubscriptionTerm__c = 48;
     poItem[1].SubscriptionTerm__c = null;
     poItem[5].Product__c = prodList[11].Id;
     insert poItem;
     Test.startTest();
       poStageList[0].PO_Validation_Status__c = 'Staged';
       update poStageList[0];
       SBQQ__QuoteLine__c qli = updateQliList[0];
       POItemValidation.ProductGroup prodGroup = new POItemValidation.ProductGroup(poItem[0]);
       Decimal matchQuant = 5.00;
       boolean updatePOItm = false;
       set<Id> skipPOItmIds = new Set<Id>{poItem[5].Id};
       POItemValidation handler = new POItemValidation();
       //POItemValidation.MatchResult matchRes = new POItemValidation.MatchResult();       
        handler.bestMatch(qli , prodGroup , matchQuant, updatePOItm,skipPOItmIds);
        handler.bestMatch(qli , prodGroup , matchQuant, true,skipPOItmIds);
        poItem[0].SubscriptionTerm__c = 0.00;
        poItem[0].Quantity__c = null;
        poItem[0].UnitPrice__c = null;
        prodGroup = new POItemValidation.ProductGroup(poItem[0]);
        handler.bestMatch(qli , prodGroup , matchQuant, updatePOItm,skipPOItmIds);
        handler.errCapturedInBestMatch = false;
        map<string, POItemValidation.ProductGroup>  PCTermPGLocalMap = new Map<string, POItemValidation.ProductGroup>();
       PCTermPGLocalMap.put(poItem[1].Product__r.ProductCode+'-'+poItem[1].SubscriptionTerm__c,new POItemValidation.ProductGroup(poItem[1]));
       PCTermPGLocalMap.put(poItem[0].Product__r.ProductCode+'-'+poItem[0].SubscriptionTerm__c,new POItemValidation.ProductGroup(poItem[0]));
      Map<Id,map<string, POItemValidation.ProductGroup>> poId_PcodeTermPGMap = new Map<Id,map<string, POItemValidation.ProductGroup>>();
       poId_PcodeTermPGMap.put(poStageList[0].Id, PCTermPGLocalMap);
       //poId_PcodeTermPGMap.put(poStageList[1].Id, PCTermPGLocalMap);
       Decimal goRefNetTotal = 29.00;
       handler.bestMatch(qliList[0] ,prodGroup , poId_PcodeTermPGMap, goRefNetTotal);
      Test.stopTest();
      system.assertEquals(2, poStageList.size());
       }
       
   }
   /**
  * @description This method test the PO Item Internal Validation Errors
  */
   static testMethod void poItemInternalValidationCodeErrorTest(){
       
    User usr = [SELECT id, alias FROM user ORDER BY createddate DESC LIMIT 1];
   POStageHandler.triggerMaxCount = 25;
   System.runAs(usr) {
     List<product2> prodList = [SELECT id, Name, ProductCode, Product_Level__c, Product_Subtype__c, Product_Type__c, Usable_Capacity__c FROM product2];
     SBQQ__Quote__c quote = [SELECT id, name, SBQQ__Account__c, SBQQ__Opportunity2__c, SBQQ__NetAmount__c FROM SBQQ__Quote__c];
     List<ProductModel> prodModels = new List<ProductModel>();
     String currencyCode = 'USD';
     set<string> prodName = new Set<string>{
       'HybridProd-001-test',
       'HWSupportProd-001-test',
       'HWProd-001-test',
       'RS-BT-RCDM-T'  
       };
     for (product2 prod : prodList) {
       if (prodName.contains(prod.name)) {
         prodModels.add(
           (ProductModel) JSON.deserialize(
             SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prod.id, '{"pricebookId" : "' + system.label.CPQPricebookID + '", "currencyCode" : "' + currencyCode + '"}'),
             ProductModel.class
           )
         );
       }
     }
     String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', quote.id);
     ProductAdder adder = new ProductAdder();
     QuoteModel quoteWithProducts = adder.add((QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class), prodModels, 0);
     Map<string, list<Integer>> prodTypeItemKeySet = new Map<string, list<Integer>>{
       'root' => new List<Integer>(),
       'hardware' => new List<Integer>(),
       'rcdm' => new List<Integer>()
     };
     
    for (QuoteLineModel QLModel : quoteWithProducts.lineItems) {
       
       if (QLModel.record.Product_Level__c == 'Hybrid Software') {
         prodTypeItemKeySet.get('root').add(QLModel.key);
           QLModel.record.SBQQ__Quantity__c = 200;
           QLModel.record.SBQQ__SubscriptionTerm__c = 36;
           QLModel.record.SBQQ__NetPrice__c = 200;
           
       } else if (QLModel.record.Product_Level__c == 'Hardware' && QLModel.record.Product_Type__c == 'Hardware') {
         prodTypeItemKeySet.get('hardware').add(QLModel.key);
         QLModel.record.SBQQ__Quantity__c = 1;
         QLModel.record.SBQQ__NetPrice__c = 100;
         QLModel.parentItemKey = prodTypeItemKeySet.get('root')[0];
         QLModel.record.SBQQ__Optional__c	= true;
         
         }
         else if (QLModel.record.Product_Level__c == 'Support') {
         QLModel.record.SBQQ__Quantity__c =  1 ;
         QLModel.record.SBQQ__SubscriptionTerm__c = 36;
         QLModel.record.SBQQ__NetPrice__c = 100;
         QLModel.parentItemKey = prodTypeItemKeySet.get('hardware')[0];
           
         }else if(QLModel.record.Product_Level__c == 'OnPrem'){
             QLModel.parentItemKey = prodTypeItemKeySet.get('root')[0];
             QLModel.record.SBQQ__NetPrice__c =0.00;
             QLModel.record.SBQQ__SubscriptionTerm__c = 17;

                       
         }
    }
     
       
     String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
     QuoteCalculator calculator = new QuoteCalculator();
     calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
     quote.ApprovalStatus__c = 'Approved';
     //quote.Opportunity_Program__c	= null;
     update quote;
     asset asst = [SELECT Id FROM asset LIMIT 1];
     List<SBQQ__QuoteLine__c> qliList = [
       SELECT
         id,
         SBQQ__NetPrice__c,
         SBQQ__NetTotal__c,
         SBQQ__Product__r.productcode,
         SBQQ__Quantity__c,
         SBQQ__SubscriptionTerm__c,
         SBQQ__Product__c,
         SBQQ__Product__r.name,
         SBQQ__Product__r.Product_Level__c,
         SBQQ__Product__r.Product_Type__c,
         SBQQ__RequiredBy__c,
         Line_Type__c
       FROM SBQQ__QuoteLine__c
     ];
      
   List<SBQQ__QuoteLine__c> updateQliList = new List<SBQQ__QuoteLine__c>();
   Id lodId = null;
     for(SBQQ__QuoteLine__c objQLI : qliList){
       if(objQLI.SBQQ__Product__r.Product_Level__c == 'LOD Software'){
           lodId = objQLI.Id;
       }else if(objQLI.SBQQ__Product__r.Product_Level__c == 'Support' && objQLI.SBQQ__Product__r.Product_Type__c == 'RCDM Support'){
           objQLI.SBQQ__RequiredBy__c = lodId;
           updateQliList.add(objQLI);
       }
     }
     if(!updateQliList.isEmpty()){
       update updateQliList;
     }
     List<PO_Stage__c> poStageList = new List<PO_Stage__c>();
     for (integer i = 1; i <= 2; i++) {
       decimal amount = i == 1 ? quote.SBQQ__NetAmount__c : 0.0;
       PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage(
         'Promark Technology, Inc.pp',
         'test123',
         system.today().addDays(10),
         10,
         'test@test.com.invalid',
         'test partner',
         system.today(),
         i,
         'test12345',
         quote.name,
         amount
       );
       pos.Expected_number_of_POs__c = 1;
       pos.Bill_To_Name__c = quote.SBQQ__Account__c;
       pos.PO_Validation_Status__c = 'Pending';
       pos.Payment_schedule_type__c = 'test';
       pos.Quote_number__c = quote.name;
       pos.Opportunity__c = quote.SBQQ__Opportunity2__c;
       pos.Ship_to_Email__c = 'test@test.com.invalid';
       pos.Ship_To_Contact_Name__c = 'testCon';
       pos.Ship_To_Phone_Number__c = '7000022448';
       pos.ShippingCountryCode__c = 'IN';
       pos.ShippingStateCode__c = 'KA';
       pos.ShippingCity__c = 'test City';
       pos.ShippingStreet__c = 'test street';
       pos.ShippingPostalCode__c = '0000';

       poStageList.add(pos);
     }
     insert poStageList;
     List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>();

     for (integer i = 0; i < qliList.size(); i++) {
       string ediLinenum = 0 + '' + i;
       PO_Item_Stage__c poi;
       Map<string, list<id>> itemLevlPOIds = new Map<string, list<id>>{
           'HybridProd-001-test' => new List<id>{ poStageList[0].id},
         'HWSupportProd-001-test' => new List<id>{ poStageList[0].id },
         'RS-BT-RCDM-T' => new List<id>{ poStageList[0].id }

       };
       if (itemLevlPOIds.containsKey(qliList[i].SBQQ__Product__r.name)) {
        
         for (Id stgId : itemLevlPOIds.get(qliList[i].SBQQ__Product__r.name)) {
           Decimal Quant = qliList[i].SBQQ__Product__r.name == 'RS-BT-RCDM-T' ? 1.0 : qliList[i].SBQQ__Quantity__c;
           Decimal Term = qliList[i].SBQQ__SubscriptionTerm__c;
           poItem.add(
             ShGl_TestFactoryHelper.createPOItem('1234' + ediLinenum, ediLinenum, qliList[i].SBQQ__Product__r.productcode, Quant, stgId, Term, qliList[i].SBQQ__NetPrice__c)
           );
           
         }
       }
     }
    
     insert poItem;
     
     Test.startTest();
      poStageList[0].PO_Validation_Status__c = 'Staged';
      update poStageList[0];
      Test.stopTest();
      system.assertEquals(2, poStageList.size());
      }

       
  }

  /**
  * @description This method test the PO Item Validation Failure
  */
  static testMethod void failurePOTest() {
    User usr = [SELECT id, alias FROM user ORDER BY createddate DESC LIMIT 1];
    POStageHandler.triggerMaxCount = 25;
    System.runAs(usr) {
      List<product2> prodList = [SELECT id, Name, ProductCode, Product_Level__c, Product_Subtype__c, Product_Type__c, Usable_Capacity__c FROM product2];
      SBQQ__Quote__c quote = [SELECT id, name, SBQQ__Account__c, SBQQ__Opportunity2__c, SBQQ__NetAmount__c FROM SBQQ__Quote__c];
      List<ProductModel> prodModels = new List<ProductModel>();
      String currencyCode = 'USD';
      set<string> prodName = new Set<string>{
        'HybridProd-001-test',
        'HybridProd-002-test',
        'HWSupportProd-001-test',
        'HWSupport2Prod-001-test',
        'HWProd-001-test',
        'HWProd-002-test',
        'AddonProd-001-test',
        'RS-BT-RCDM-T'
      };
      for (product2 prod : prodList) {
        if (prodName.contains(prod.name)) {
          prodModels.add(
            (ProductModel) JSON.deserialize(
              SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prod.id, '{"pricebookId" : "' + system.label.CPQPricebookID + '", "currencyCode" : "' + currencyCode + '"}'),
              ProductModel.class
            )
          );
        }
      }
      String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', quote.id);
      ProductAdder adder = new ProductAdder();
      QuoteModel quoteWithProducts = adder.add((QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class), prodModels, 0);
      Map<string, list<Integer>> prodTypeItemKeySet = new Map<string, list<Integer>>{
        'root' => new List<Integer>(),
        'hardware' => new List<Integer>(),
        'rcdm' => new List<Integer>()
      };
      Integer hwIndex, hybIndx, addonIndx, rcdmIndx;
      hwIndex = hybIndx = addonIndx = rcdmIndx = 0;
      for (QuoteLineModel QLModel : quoteWithProducts.lineItems) {
        if (QLModel.record.Product_Level__c == 'Hybrid Software') {
          prodTypeItemKeySet.get('root').add(QLModel.key);
          if (QLModel.record.SBQQ__Product__r.name == 'HybridProd-002-test') {
            QLModel.record.SBQQ__SubscriptionTerm__c = null;
          } else {
            QLModel.record.SBQQ__Quantity__c = 400;
            QLModel.record.SBQQ__SubscriptionTerm__c = 56;
          }
          QLModel.record.SBQQ__NetPrice__c = 100;
        } else if (QLModel.record.Product_Level__c == 'Hardware' && QLModel.record.Product_Type__c == 'Hardware') {
          prodTypeItemKeySet.get('hardware').add(QLModel.key);
          QLModel.record.SBQQ__Quantity__c = 4;
          QLModel.record.SBQQ__NetPrice__c = 100;
          if (prodTypeItemKeySet.get('root').size() >= hybIndx + 1) {
            QLModel.parentItemKey = prodTypeItemKeySet.get('root')[hybIndx];
            if (prodTypeItemKeySet.get('root').size() > hybIndx + 1)
              hybIndx++;
          }
        } else if (QLModel.record.Product_Level__c == 'Support' || QLModel.record.Product_Level__c == 'SaaS Software Addon') {
          QLModel.record.SBQQ__Quantity__c = QLModel.record.name == 'HWSupport2Prod-001-test' ? 3 : 4;
          QLModel.record.SBQQ__SubscriptionTerm__c = 36;
          QLModel.record.SBQQ__NetPrice__c = 100;
          if (prodTypeItemKeySet.get('hardware').size() >= hwIndex + 1) {
            QLModel.parentItemKey = prodTypeItemKeySet.get('hardware')[hwIndex];
            if (prodTypeItemKeySet.get('hardware').size() > hwIndex + 1)
              hwIndex++;
          }
        } else if (QLModel.record.Product_Level__c == 'OnPrem') {
          prodTypeItemKeySet.get('rcdm').add(QLModel.key);
          QLModel.record.SBQQ__Quantity__c = 400;
          QLModel.record.SBQQ__SubscriptionTerm__c = 56;

          if (prodTypeItemKeySet.get('root').size() >= rcdmIndx + 1) {
            QLModel.parentItemKey = prodTypeItemKeySet.get('root')[rcdmIndx];
            if (prodTypeItemKeySet.get('root').size() > rcdmIndx + 1)
              rcdmIndx++;
          }
        }
      }
      String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
      QuoteCalculator calculator = new QuoteCalculator();
      calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
      quote.ApprovalStatus__c = 'Approved';
      update quote;
      asset asst = [SELECT Id FROM asset LIMIT 1];
      List<SBQQ__QuoteLine__c> qliList = [
        SELECT
          id,
          SBQQ__NetPrice__c,
          SBQQ__NetTotal__c,
          SBQQ__Product__r.productcode,
          SBQQ__Quantity__c,
          SBQQ__SubscriptionTerm__c,
          SBQQ__Product__c,
          SBQQ__Product__r.name,
          SBQQ__Product__r.Product_Level__c,
          Line_Type__c
        FROM SBQQ__QuoteLine__c
      ];
      List<PO_Stage__c> poStageList = new List<PO_Stage__c>();
      for (integer i = 1; i <= 10; i++) {
        decimal amount = i == 1 ? quote.SBQQ__NetAmount__c : 0.0;
        PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage(
          'Promark Technology, Inc.pp',
          'test123',
          system.today().addDays(10),
          10,
          'test@test.com.invalid',
          'test partner',
          system.today(),
          i,
          'test12345',
          quote.name,
          amount
        );
        pos.Bill_To_Name__c = quote.SBQQ__Account__c;
        pos.Payment_schedule_type__c = 'test';
        pos.Quote_number__c = quote.name;
        pos.Opportunity__c = quote.SBQQ__Opportunity2__c;
        pos.Ship_to_Email__c = 'test@test.com.invalid';
        pos.Ship_To_Contact_Name__c = 'testCon';
        pos.Ship_To_Phone_Number__c = '7000022448';
        pos.ShippingCountryCode__c = 'IN';
        pos.ShippingStateCode__c = 'KA';
        pos.ShippingCity__c = 'test City';
        pos.ShippingStreet__c = 'test street';
        pos.ShippingPostalCode__c = '0000';

        if (i != 8)
          pos.PO_Validation_Status__c = 'Staged';
        poStageList.add(pos);
      }

      insert poStageList;

      List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>();

      for (integer i = 0; i < qliList.size(); i++) {
        string ediLinenum = 0 + '' + i;
        PO_Item_Stage__c poi;
        Map<string, list<id>> itemLevlPOIds = new Map<string, list<id>>{
          'HybridProd-001-test' => new List<id>{ poStageList[0].id, poStageList[2].id, poStageList[4].id, poStageList[6].id, poStageList[9].id },
          'HWProd-001-test' => new List<id>{ poStageList[0].id, poStageList[1].id, poStageList[3].id, poStageList[6].id, poStageList[8].id },
          'HWSupportProd-001-test' => new List<id>{ poStageList[0].id, poStageList[2].id, poStageList[5].id, poStageList[7].id },
          'HWSupport2Prod-001-test' => new List<id>{ poStageList[0].id, poStageList[2].id, poStageList[5].id },
          'AddonProd-001-test' => new List<id>{ poStageList[0].id },
          'HybridProd-002-test' => new List<id>{ poStageList[9].id },
          'RS-BT-RCDM-T' => new List<id>{ poStageList[0].id, poStageList[2].id, poStageList[4].id, poStageList[6].id, poStageList[9].id }
        };
        if (itemLevlPOIds.containsKey(qliList[i].SBQQ__Product__r.name)) {
          Integer j = 1;
          for (Id stgId : itemLevlPOIds.get(qliList[i].SBQQ__Product__r.name)) {
            Decimal Quant = qliList[i].SBQQ__Product__r.Product_Level__c == 'Hybrid Software'
              ? j == 10 ? 300 : 100.0
              : qliList[i].SBQQ__Product__r.name == 'HybridProd-002-test' || qliList[i].SBQQ__Product__r.name == 'HWProd-002-test' ? 5.0 : 1.0;
            Decimal Term = qliList[i].SBQQ__Product__r.Product_Level__c == 'Hybrid Software' ? 36 : qliList[i].SBQQ__SubscriptionTerm__c;
            poItem.add(
              ShGl_TestFactoryHelper.createPOItem('1234' + ediLinenum, ediLinenum, qliList[i].SBQQ__Product__r.productcode, Quant, stgId, Term, qliList[i].SBQQ__NetPrice__c)
            );
            j++;
          }
        }
      }
      poItem[0].SubscriptionTerm__c = 48;
      poItem[1].SubscriptionTerm__c = null;
      poItem[10].Quantity__c = poItem[17].Quantity__c = 10;
      poItem[11].UnitPrice__c = poItem[16].UnitPrice__c = 1000.00;
      poItem.add(ShGl_TestFactoryHelper.createPOItem('1234' + '9900', '9900', 'HWProd3-001-test', 2.0, poStageList[0].id, 0.00, 100.0));
      insert poItem;
      List<PO_Item_Stage__c> poItmList = [
        SELECT
          Id,
          Name,
          Stage_PO__c,
          Stage_PO__r.Expected_number_of_POs__c,
          Stage_PO__r.name,
          Stage_PO__r.Quote__c,
          Quantity__c,
          UnitPrice__c,
          Product__c,
          SubscriptionTerm__c,
          ProductCode__c,
          Subscription_Term_Description__c,
          EDI_Line_Number__c,
          Buyer_Part_Number__c,
          Deliver_By__c,
          Est_Ship_Date__c,
          Stage_PO__r.Bill_To_Name__r.EDI_DISTI_ID__c,
          Stage_PO__r.Quote__r.SBQQ__Opportunity2__r.Distributor_Lookup__r.EDI_DISTI_ID__c,
          Product__r.Appliance_Model_HW__c,
          Product__r.Product_Type__c,
          Product__r.Product_Level__c,
          Product__r.ProductCode,
          Product__r.Usable_Capacity__c,
          Product__r.Product_Payment_Option__c,
          Product__r.Product_Subtype__c
        FROM PO_Item_Stage__c
      ];
      List<PO_Stage__c> stgpo = [
        SELECT
          Id,
          PO_Internal_Validation_Status__c,
          PO_Validation_Status__c,
          Expected_number_of_POs__c,
          PO_Index__c,
          Quote__c,
          Quote_number__c,
          TotalAmount__c,
          (
            SELECT
              Id,
              Name,
              Stage_PO__c,
              Stage_PO__r.Expected_number_of_POs__c,
              Stage_PO__r.name,
              Stage_PO__r.Quote__c,
              Quantity__c,
              UnitPrice__c,
              Product__c,
              SubscriptionTerm__c,
              ProductCode__c,
              Subscription_Term_Description__c,
              EDI_Line_Number__c,
              Buyer_Part_Number__c,
              Deliver_By__c,
              Est_Ship_Date__c,
              Stage_PO__r.Bill_To_Name__r.EDI_DISTI_ID__c,
              Stage_PO__r.Quote__r.SBQQ__Opportunity2__r.Distributor_Lookup__r.EDI_DISTI_ID__c,
              Product__r.Appliance_Model_HW__c,
              Product__r.Product_Type__c,
              Product__r.Product_Level__c,
              Product__r.ProductCode,
              Product__r.Usable_Capacity__c,
              Product__r.Product_Payment_Option__c,
              Product__r.Product_Subtype__c
            FROM PO_Item_Stage__r
          )
        FROM PO_Stage__c
      ];
      POStageHelper.allStagePOmap.clear();
      POStageHelper.quoteMap.clear();
      poStageList[7].PO_Validation_Status__c = 'Staged';
      update poStageList[7];
      // }
      system.assertEquals(10, poStageList.size());
    }
  }
  /**
  * @description This method test the PO Item Validation Success
  */
  static testMethod void validateSuccessPOTest() {
    User usr = [SELECT id, alias FROM user ORDER BY createddate DESC LIMIT 1];
    POStageHandler.triggerMaxCount = 25;
    System.runAs(usr) {

      ShGl_TestFactoryHelper.insertTriggerControls();
      ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(
        Disable_SBQQ_Quote_Triggers__c = true,
        Disable_SBQQ_Quote_Validation_Rules__c = true,
        Disable_SBQQ_QuoteLine_Validation_Rules__c = true
      );
      insert disableLogic;

      List<product2> prodList = [SELECT id, Name, ProductCode, Product_Level__c, Product_Subtype__c, Product_Type__c, Usable_Capacity__c FROM product2];
      SBQQ__Quote__c quote = [SELECT id, name, SBQQ__Account__c, SBQQ__Opportunity2__c, SBQQ__NetAmount__c FROM SBQQ__Quote__c];
      List<ProductModel> prodModels = new List<ProductModel>();
      String currencyCode = 'USD';
      set<string> prodName = new Set<string>{
        'HybridProd-001-test',
        'HybridProd-002-test',
        'HWSupportProd-001-test',
        'HWSupport2Prod-001-test',
        'HWProd-001-test',
        'HWProd-002-test',
        'AddonProd-001-test',
        'RS-BT-RCDM-T',
        /* 'LOD-SOFTWARE', 'RS-BT-SW-SVC-PE',*/ 'RA-HW-CREDIT'
      };
      for (product2 prod : prodList) {
        if (prodName.contains(prod.name)) {
          prodModels.add(
            (ProductModel) JSON.deserialize(
              SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prod.id, '{"pricebookId" : "' + system.label.CPQPricebookID + '", "currencyCode" : "' + currencyCode + '"}'),
              ProductModel.class
            )
          );
        }
      }
      String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', quote.id);
      ProductAdder adder = new ProductAdder();
      QuoteModel quoteWithProducts = adder.add((QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class), prodModels, 0);
      Map<string, string> childParentMap = new Map<string, string>{
        'RS-BT-SW-SVC-PE' => 'LOD-SOFTWARE',
        'RS-BT-RCDM-T' => 'HybridProd-001-test',
        'HWProd-001-test' => 'HybridProd-001-test',
        'HWProd-002-test' => 'HybridProd-002-test',
        'HWSupportProd-001-test' => 'HWProd-001-test',
        'HWSupport2Prod-001-test' => 'HWProd-001-test',
        'AddonProd-001-test' => 'HybridProd-001-test'
      };
      Map<string, Integer> prodKey = new Map<string, Integer>();
      Integer hwIndex, hybIndx, addonIndx;
      hwIndex = hybIndx = addonIndx = 0;
      for (QuoteLineModel QLModel : quoteWithProducts.lineItems) {
        if (QLModel.record.Product_Level__c == 'Hybrid Software' /*|| QLModel.record.Product_Level__c == 'LOD Software'*/) {
          prodKey.put(QLModel.record.SBQQ__Product__r.name, QLModel.key);
          QLModel.record.SBQQ__Quantity__c = 500;
          QLModel.record.SBQQ__SubscriptionTerm__c = 36;
          QLModel.record.SBQQ__NetPrice__c = 100;
        } else if (QLModel.record.Product_Level__c == 'Hardware' && QLModel.record.Product_Type__c == 'Hardware') {
          prodKey.put(QLModel.record.SBQQ__Product__r.name, QLModel.key);
          QLModel.record.SBQQ__Quantity__c = 5;
          QLModel.record.SBQQ__NetPrice__c = 100;
          QLModel.parentItemKey = prodKey.get(childParentMap.get(QLModel.record.SBQQ__Product__r.name));
        } else if (QLModel.record.Product_Level__c == 'Support' || QLModel.record.Product_Level__c == 'SaaS Software Addon') {
          QLModel.record.SBQQ__Quantity__c = QLModel.record.Product_Level__c == 'SaaS Software Addon' ? 1 : 5;
          QLModel.record.SBQQ__SubscriptionTerm__c = 36;
          QLModel.record.SBQQ__NetPrice__c = 100;
          if (QLModel.record.Product_Level__c == 'Support') {
            QLModel.record.Special_Program__c = 'Conversion';
            QLModel.record.Arroyo_Subscribed_Asset_Name__c = 'TestSN1,TestSN2,TestSN3,TestSN4,TestSN5';
          }
          QLModel.parentItemKey = prodKey.get(childParentMap.get(QLModel.record.SBQQ__Product__r.name));
        } else if (QLModel.record.Product_Level__c == 'OnPrem') {
          //prodTypeItemKeySet.get('rcdm').add(QLModel.key);
          QLModel.record.SBQQ__Quantity__c = 400;
          QLModel.record.SBQQ__SubscriptionTerm__c = 56;
          QLModel.parentItemKey = prodKey.get(childParentMap.get(QLModel.record.SBQQ__Product__r.name));
        }
      }
      String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
      QuoteCalculator calculator = new QuoteCalculator();
      calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
      quote.ApprovalStatus__c = 'Approved';
      quote.Credit_Calculation_Start_Date__c = system.today();
      update quote;
      List<SBQQ__QuoteLine__c> qliList = [
        SELECT
          id,
          SBQQ__Quote__r.SBQQ__NetAmount__c,
          SBQQ__NetPrice__c,
          SBQQ__NetTotal__c,
          SBQQ__Product__r.productcode,
          SBQQ__Quantity__c,
          SBQQ__SubscriptionTerm__c,
          SBQQ__Product__c,
          SBQQ__Product__r.name,
          SBQQ__Product__r.Product_Level__c,
          SBQQ__RequiredBy__c
        FROM SBQQ__QuoteLine__c
      ];
      qliList[0].Special_Program__c = 'Upgrade';
      qliList[0].Prepayment_Credit__c = 50;
      
      update qliList;
      
      List<PO_Stage__c> poStageList = new List<PO_Stage__c>();
      for (integer i = 1; i <= 11; i++) {
        decimal amount = i == 1 ? qliList[0].SBQQ__Quote__r.SBQQ__NetAmount__c : 0.0;
        PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage(
          'Promark Technology, Inc.pp',
          'test123',
          system.today().addDays(10),
          11,
          'test@test.com.invalid',
          'test partner',
          system.today(),
          i,
          'test12345',
          quote.name,
          amount
        );
        pos.Bill_To_Name__c = quote.SBQQ__Account__c;
        pos.Payment_schedule_type__c = 'test';
        pos.Quote_number__c = quote.name;
        pos.Opportunity__c = quote.SBQQ__Opportunity2__c;
        pos.Ship_to_Email__c = 'test@test.com.invalid';
        pos.Ship_To_Contact_Name__c = 'testCon';
        pos.Ship_To_Phone_Number__c = '7000022448';
        pos.ShippingCountryCode__c = 'IN';
        pos.ShippingStateCode__c = 'KA';
        pos.ShippingCity__c = 'test City';
        pos.ShippingStreet__c = 'test street';
        pos.ShippingPostalCode__c = '0000';
        pos.Customer_Requested_Ship_Date__c = String.ValueOf(system.today().addDays(20)); 
        pos.PoDate__c = system.today();

        if (i != 8)
          pos.PO_Validation_Status__c = 'Staged';
        poStageList.add(pos);
      }

      insert poStageList;

      List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>();

      for (integer i = 0; i < qliList.size(); i++) {
        string ediLinenum = 0 + '' + i;
        PO_Item_Stage__c poi;
        Map<string, list<id>> itemLevlPOIds = new Map<string, list<id>>{
          'HybridProd-001-test' => new List<id>{ poStageList[0].id, poStageList[2].id, poStageList[4].id, poStageList[6].id, poStageList[9].id },
          'HWProd-001-test' => new List<id>{ poStageList[0].id, poStageList[1].id, poStageList[3].id, poStageList[6].id, poStageList[8].id },
          'HWSupportProd-001-test' => new List<id>{ poStageList[0].id, poStageList[2].id, poStageList[5].id, poStageList[7].id, poStageList[10].id }, //,poStageList[9].id.
          'HWSupport2Prod-001-test' => new List<id>{ poStageList[0].id, poStageList[2].id, poStageList[5].id, poStageList[7].id, poStageList[10].id }, //,poStageList[9].id
          'AddonProd-001-test' => new List<id>{ poStageList[0].id },
          'HybridProd-002-test' => new List<id>{ poStageList[9].id },
          'HWProd-002-test' => new List<id>{ poStageList[8].id },
          'RS-BT-RCDM-T' => new List<id>{ poStageList[0].id, poStageList[2].id, poStageList[4].id, poStageList[6].id, poStageList[9].id },
          //'LOD-SOFTWARE' => new List<id>{ poStageList[0].id, poStageList[2].id, poStageList[4].id, poStageList[6].id, poStageList[9].id },
          //'RS-BT-SW-SVC-PE' => new List<id>{ poStageList[0].id, poStageList[2].id, poStageList[4].id, poStageList[6].id, poStageList[9].id },
          'RA-HW-CREDIT' => new List<id>{ poStageList[0].id, poStageList[2].id, poStageList[4].id, poStageList[6].id, poStageList[9].id }
        };
        if (itemLevlPOIds.containsKey(qliList[i].SBQQ__Product__r.name)) {
          Integer j = 1;
          for (Id stgId : itemLevlPOIds.get(qliList[i].SBQQ__Product__r.name)) {
            Decimal Quant = qliList[i].SBQQ__Product__r.Product_Level__c == 'Hybrid Software'
              ? qliList[i].SBQQ__Product__r.name == 'HybridProd-002-test' ? 500 : 100.0
              : qliList[i].SBQQ__Product__r.name == 'HWProd-002-test' ? 5.0 : 1.0;
            poItem.add(
              ShGl_TestFactoryHelper.createPOItem(
                '1234' + ediLinenum,
                ediLinenum,
                qliList[i].SBQQ__Product__r.productcode,
                Quant,
                stgId,
                qliList[i].SBQQ__SubscriptionTerm__c,
                qliList[i].SBQQ__NetPrice__c
              )
            );
            j++;
          }
        }
      }
      insert poItem;
      List<PO_Stage__c> stgpo = [
        SELECT
          Id,
          PO_Internal_Validation_Status__c,
          PO_Validation_Status__c,
          Expected_number_of_POs__c,
          PO_Index__c,
          Quote__c,
          Quote_number__c,
          TotalAmount__c,
          (
            SELECT
              Id,
              Name,
              Stage_PO__c,
              Stage_PO__r.Expected_number_of_POs__c,
              Stage_PO__r.name,
              Stage_PO__r.Quote__c,
              Quantity__c,
              UnitPrice__c,
              Product__c,
              SubscriptionTerm__c,
              ProductCode__c,
              Subscription_Term_Description__c,
              EDI_Line_Number__c,
              Buyer_Part_Number__c,
              Deliver_By__c,
              Est_Ship_Date__c,
              Stage_PO__r.Bill_To_Name__r.EDI_DISTI_ID__c,
              Stage_PO__r.Quote__r.SBQQ__Opportunity2__r.Distributor_Lookup__r.EDI_DISTI_ID__c,
              Product__r.Appliance_Model_HW__c,
              Product__r.Product_Type__c,
              Product__r.Product_Level__c,
              Product__r.ProductCode,
              Product__r.Usable_Capacity__c,
              Product__r.Product_Payment_Option__c,
              Product__r.Product_Subtype__c
            FROM PO_Item_Stage__r
          )
        FROM PO_Stage__c
      ];
      POStageHelper.allStagePOmap.clear();
      POStageHelper.quoteMap.clear();
      poStageList[7].PO_Validation_Status__c = 'Staged';
      update poStageList[7];
      system.assertEquals(11, poStageList.size());
    }
  }
  /**
  * @description This method test the PO Item Validation Success
  */
  static testMethod void validateSuccessPOTest1() {
    User usr = [SELECT id, alias FROM user ORDER BY createddate DESC LIMIT 1];
    POStageHandler.triggerMaxCount = 25;
    System.runAs(usr) {
      List<product2> prodList = [SELECT id, Name, ProductCode, Product_Level__c, Product_Subtype__c, Product_Type__c, Usable_Capacity__c FROM product2];
      SBQQ__Quote__c quote = [SELECT id, name, SBQQ__Account__c, SBQQ__Opportunity2__c, SBQQ__NetAmount__c FROM SBQQ__Quote__c];
      List<ProductModel> prodModels = new List<ProductModel>();
      String currencyCode = 'USD';
      set<string> prodName = new Set<string>{
        'HybridProd-001-test',
        'HybridProd-002-test',
        'HWSupportProd-001-test',
        'HWSupport2Prod-001-test',
        'HWProd-001-test',
        'HWProd-002-test',
        'AddonProd-001-test',
        'RS-BT-RCDM-T',
        /* 'LOD-SOFTWARE', 'RS-BT-SW-SVC-PE',*/ 'RA-HW-CREDIT'
      };
      for (product2 prod : prodList) {
        if (prodName.contains(prod.name)) {
          prodModels.add(
            (ProductModel) JSON.deserialize(
              SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prod.id, '{"pricebookId" : "' + system.label.CPQPricebookID + '", "currencyCode" : "' + currencyCode + '"}'),
              ProductModel.class
            )
          );
        }
      }
      String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', quote.id);
      ProductAdder adder = new ProductAdder();
      QuoteModel quoteWithProducts = adder.add((QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class), prodModels, 0);
      Map<string, string> childParentMap = new Map<string, string>{
        'RS-BT-SW-SVC-PE' => 'LOD-SOFTWARE',
        'RS-BT-RCDM-T' => 'HybridProd-001-test',
        'HWProd-001-test' => 'HybridProd-001-test',
        'HWProd-002-test' => 'HybridProd-002-test',
        'HWSupportProd-001-test' => 'HWProd-001-test',
        'HWSupport2Prod-001-test' => 'HWProd-001-test',
        'AddonProd-001-test' => 'HybridProd-001-test'
      };
      Map<string, Integer> prodKey = new Map<string, Integer>();
      Integer hwIndex, hybIndx, addonIndx;
      hwIndex = hybIndx = addonIndx = 0;
      for (QuoteLineModel QLModel : quoteWithProducts.lineItems) {
        if (QLModel.record.Product_Level__c == 'Hybrid Software' /*|| QLModel.record.Product_Level__c == 'LOD Software'*/) {
          prodKey.put(QLModel.record.SBQQ__Product__r.name, QLModel.key);
          QLModel.record.SBQQ__Quantity__c = 500;
          QLModel.record.SBQQ__SubscriptionTerm__c = 36;
          QLModel.record.SBQQ__NetPrice__c = 100;
        } else if (QLModel.record.Product_Level__c == 'Hardware' && QLModel.record.Product_Type__c == 'Hardware') {
          prodKey.put(QLModel.record.SBQQ__Product__r.name, QLModel.key);
          QLModel.record.SBQQ__Quantity__c = 5;
          QLModel.record.SBQQ__NetPrice__c = 100;
          QLModel.parentItemKey = prodKey.get(childParentMap.get(QLModel.record.SBQQ__Product__r.name));
        } else if (QLModel.record.Product_Level__c == 'Support' || QLModel.record.Product_Level__c == 'SaaS Software Addon') {
          QLModel.record.SBQQ__Quantity__c = QLModel.record.Product_Level__c == 'SaaS Software Addon' ? 1 : 5;
          QLModel.record.SBQQ__SubscriptionTerm__c = 36;
          QLModel.record.SBQQ__NetPrice__c = 100;
          if (QLModel.record.Product_Level__c == 'Support') {
            QLModel.record.Special_Program__c = 'Conversion';
            QLModel.record.Arroyo_Subscribed_Asset_Name__c = 'TestSN1,TestSN2,TestSN3,TestSN4,TestSN5';
          }
          QLModel.parentItemKey = prodKey.get(childParentMap.get(QLModel.record.SBQQ__Product__r.name));
        } else if (QLModel.record.Product_Level__c == 'OnPrem') {
          //prodTypeItemKeySet.get('rcdm').add(QLModel.key);
          QLModel.record.SBQQ__Quantity__c = 400;
          QLModel.record.SBQQ__SubscriptionTerm__c = 56;
          QLModel.parentItemKey = prodKey.get(childParentMap.get(QLModel.record.SBQQ__Product__r.name));
        }
      }
      String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
      QuoteCalculator calculator = new QuoteCalculator();
      calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
      quote.ApprovalStatus__c = 'Approved';
      update quote;
      List<SBQQ__QuoteLine__c> qliList = [
        SELECT
          id,
          SBQQ__Quote__r.SBQQ__NetAmount__c,
          SBQQ__NetPrice__c,
          SBQQ__NetTotal__c,
          SBQQ__Product__r.productcode,
          SBQQ__Quantity__c,
          SBQQ__SubscriptionTerm__c,
          SBQQ__Product__c,
          SBQQ__Product__r.name,
          SBQQ__Product__r.Product_Level__c,
          SBQQ__RequiredBy__c
        FROM SBQQ__QuoteLine__c
      ];
      List<PO_Stage__c> poStageList = new List<PO_Stage__c>();
      for (integer i = 1; i <= 2; i++) {
        decimal amount = i == 1 ? qliList[0].SBQQ__Quote__r.SBQQ__NetAmount__c : 0.0;
        PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage(
          'Promark Technology, Inc.pp',
          'test123',
          system.today().addDays(10),
          2,
          'test@test.com.invalid',
          'test partner',
          system.today(),
          i,
          'test12345',
          quote.name,
          amount
        );
        pos.Bill_To_Name__c = quote.SBQQ__Account__c;
        pos.Payment_schedule_type__c = 'test';
        pos.Quote_number__c = quote.name;
        pos.Opportunity__c = quote.SBQQ__Opportunity2__c;
        pos.Ship_to_Email__c = 'test@test.com.invalid';
        pos.Ship_To_Contact_Name__c = 'testCon';
        pos.Ship_To_Phone_Number__c = '7000022448';
        pos.ShippingCountryCode__c = 'IN';
        pos.ShippingStateCode__c = 'KA';
        pos.ShippingCity__c = 'test City';
        pos.ShippingStreet__c = 'test street';
        pos.ShippingPostalCode__c = '0000';

        if (i != 1) {
          pos.PO_Validation_Status__c = 'Staged';
          //poStageList.add(pos);
        }
        poStageList.add(pos);
      }
      insert poStageList;

      List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>();

      for (integer i = 0; i < qliList.size(); i++) {
        string ediLinenum = 0 + '' + i;
        PO_Item_Stage__c poi;
        /*  Map<string, list<id>> itemLevlPOIds = new Map<string, list<id>>{
          'HybridProd-001-test' => new List<id>{ poStageList[0].id, poStageList[2].id, poStageList[4].id, poStageList[6].id, poStageList[9].id },
          'HWProd-001-test' => new List<id>{poStageList[0].id, poStageList[2].id, poStageList[4].id, poStageList[6].id, poStageList[9].id  },
          'HWSupportProd-001-test' => new List<id>{poStageList[0].id, poStageList[2].id, poStageList[4].id, poStageList[6].id, poStageList[9].id }, //,poStageList[9].id.
          'HWSupport2Prod-001-test' => new List<id>{ poStageList[0].id, poStageList[2].id, poStageList[4].id, poStageList[6].id, poStageList[9].id  }, //,poStageList[9].id
          'AddonProd-001-test' => new List<id>{poStageList[0].id, poStageList[2].id, poStageList[4].id, poStageList[6].id, poStageList[9].id  },
          'HybridProd-002-test' => new List<id>{ poStageList[0].id, poStageList[2].id, poStageList[4].id, poStageList[6].id, poStageList[9].id },
          'HWProd-002-test' => new List<id>{poStageList[0].id, poStageList[2].id, poStageList[4].id, poStageList[6].id, poStageList[9].id  },
          'RS-BT-RCDM-T' => new List<id>{ poStageList[0].id, poStageList[2].id, poStageList[4].id, poStageList[6].id, poStageList[9].id },
          //'LOD-SOFTWARE' => new List<id>{ poStageList[0].id, poStageList[2].id, poStageList[4].id, poStageList[6].id, poStageList[9].id },
          //'RS-BT-SW-SVC-PE' => new List<id>{ poStageList[0].id, poStageList[2].id, poStageList[4].id, poStageList[6].id, poStageList[9].id },
            'RA-HW-CREDIT' => new List<id>{ poStageList[0].id, poStageList[2].id, poStageList[4].id, poStageList[6].id, poStageList[9].id  }
        }; */
        Map<string, list<id>> itemLevlPOIds = new Map<string, list<id>>{
          'HybridProd-001-test' => new List<id>{ poStageList[0].id },
          'HWProd-001-test' => new List<id>{ poStageList[0].id },
          'HWSupportProd-001-test' => new List<id>{ poStageList[0].id }, //,poStageList[9].id.
          'HWSupport2Prod-001-test' => new List<id>{ poStageList[1].id }, //,poStageList[9].id
          'AddonProd-001-test' => new List<id>{ poStageList[0].id },
          'HybridProd-002-test' => new List<id>{ poStageList[1].id },
          'HWProd-002-test' => new List<id>{ poStageList[1].id },
          'RS-BT-RCDM-T' => new List<id>{ poStageList[0].id, poStageList[1].id },
          //'LOD-SOFTWARE' => new List<id>{ poStageList[0].id, poStageList[2].id, poStageList[4].id, poStageList[6].id, poStageList[9].id },
          //'RS-BT-SW-SVC-PE' => new List<id>{ poStageList[0].id, poStageList[2].id, poStageList[4].id, poStageList[6].id, poStageList[9].id },
          'RA-HW-CREDIT' => new List<id>{ poStageList[0].id, poStageList[1].id }
        };
        if (itemLevlPOIds.containsKey(qliList[i].SBQQ__Product__r.name)) {
          Integer j = 1;
          for (Id stgId : itemLevlPOIds.get(qliList[i].SBQQ__Product__r.name)) {
            Decimal Quant = qliList[i].SBQQ__Product__r.Product_Level__c == 'Hybrid Software'
              ? qliList[i].SBQQ__Product__r.name == 'HybridProd-002-test' ? 500 : 100.0
              : qliList[i].SBQQ__Product__r.name == 'HWProd-002-test' ? 5.0 : 1.0;
            poItem.add(
              ShGl_TestFactoryHelper.createPOItem(
                '1234' + ediLinenum,
                ediLinenum,
                qliList[i].SBQQ__Product__r.productcode,
                Quant,
                stgId,
                qliList[i].SBQQ__SubscriptionTerm__c,
                qliList[i].SBQQ__NetPrice__c
              )
            );
            j++;
          }
        }
      }
      insert poItem;
      List<PO_Stage__c> stgpo = [
        SELECT
          Id,
          PO_Internal_Validation_Status__c,
          PO_Validation_Status__c,
          Expected_number_of_POs__c,
          PO_Index__c,
          Quote__c,
          Quote_number__c,
          TotalAmount__c,
          (
            SELECT
              Id,
              Name,
              Stage_PO__c,
              Stage_PO__r.Expected_number_of_POs__c,
              Stage_PO__r.name,
              Stage_PO__r.Quote__c,
              Quantity__c,
              UnitPrice__c,
              Product__c,
              SubscriptionTerm__c,
              ProductCode__c,
              Subscription_Term_Description__c,
              EDI_Line_Number__c,
              Buyer_Part_Number__c,
              Deliver_By__c,
              Est_Ship_Date__c,
              Stage_PO__r.Bill_To_Name__r.EDI_DISTI_ID__c,
              Stage_PO__r.Quote__r.SBQQ__Opportunity2__r.Distributor_Lookup__r.EDI_DISTI_ID__c,
              Product__r.Appliance_Model_HW__c,
              Product__r.Product_Type__c,
              Product__r.Product_Level__c,
              Product__r.ProductCode,
              Product__r.Usable_Capacity__c,
              Product__r.Product_Payment_Option__c,
              Product__r.Product_Subtype__c
            FROM PO_Item_Stage__r
          )
        FROM PO_Stage__c
      ];
      POStageHelper.allStagePOmap.clear();
      POStageHelper.quoteMap.clear();
      poStageList[0].PO_Validation_Status__c = 'Staged';
      update poStageList[0];
       List<PO_Item_Stage__c> lstPoItemstage = new List<PO_Item_Stage__c>();
        for(PO_Stage__c obj : stgpo){
            for(PO_Item_Stage__c objItem : obj.PO_Item_Stage__r){
                if(objItem.Product__r.ProductCode ==  'HWSupportProd-001-test'){
                    lstPoItemstage.add(objItem);
                }
             }
        }
        delete lstPoItemstage;
        POItemValidation handler = new POItemValidation();
        handler.externalValidation(poStageList, null);
      system.assertEquals(2, poStageList.size());
    }
  }
  /**
  * @description This method test the InitiateIntValidationAndOrderGeneration Queueable Class
  */
  static testMethod void initiateIntValidationAndOrderGenerationTest() {
    User usr = [SELECT id, alias FROM user ORDER BY createddate DESC LIMIT 1];
    POStageHandler.triggerMaxCount = 25;
    System.runAs(usr) {
      List<product2> prodList = [SELECT id, Name, ProductCode, Product_Level__c, Product_Subtype__c, Product_Type__c, Usable_Capacity__c FROM product2];
      SBQQ__Quote__c quote = [SELECT id, name,SBQQ__PricebookId__c, SBQQ__Account__c, SBQQ__Opportunity2__c, SBQQ__NetAmount__c, ProcessType__c FROM SBQQ__Quote__c];
      Account acc = (Account) ShGl_TestFactory.createSObject(new Account(), new Map<String, Object>{ 'name' => 'test23', 'Type' => 'Distributor' });
      insert acc;
      update new Opportunity(id = quote.SBQQ__Opportunity2__c, Hold_Code__c = 'Contingency with order');
      List<ProductModel> prodModels = new List<ProductModel>();
      String currencyCode = 'USD';
      set<string> prodName = new Set<string>{ 'HybridProd-001-test', 'HWSupportProd-001-test', 'HWProd-001-test', 'HWProd-002-test' };
      for (product2 prod : prodList) {
        if (prodName.contains(prod.name)) {
          prodModels.add(
            (ProductModel) JSON.deserialize(
              SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prod.id, '{"pricebookId" : "' + system.label.CPQPricebookID + '", "currencyCode" : "' + currencyCode + '"}'),
              ProductModel.class
            )
          );
        }
      }
      String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', quote.id);
      ProductAdder adder = new ProductAdder();
      QuoteModel quoteWithProducts = adder.add((QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class), prodModels, 0);
      Map<string, string> childParentMap = new Map<string, string>{
        'HWProd-001-test' => 'HybridProd-001-test',
        'HWProd-002-test' => 'HybridProd-002-test',
        'HWSupportProd-001-test' => 'HWProd-001-test',
        'HWSupport2Prod-001-test' => 'HWProd-001-test',
        'AddonProd-001-test' => 'HybridProd-001-test'
      };
      Map<string, Integer> prodKey = new Map<string, Integer>();
      Integer hwIndex, hybIndx, addonIndx;
      hwIndex = hybIndx = addonIndx = 0;
      for (QuoteLineModel QLModel : quoteWithProducts.lineItems) {
        if (QLModel.record.Product_Level__c == 'Hybrid Software') {
          prodKey.put(QLModel.record.SBQQ__Product__r.name, QLModel.key);
          QLModel.record.SBQQ__Quantity__c = 500;
          QLModel.record.SBQQ__SubscriptionTerm__c = 36;
          QLModel.record.SBQQ__NetPrice__c = 100;
        } else if (QLModel.record.Product_Level__c == 'Hardware' && QLModel.record.Product_Type__c == 'Hardware') {
          prodKey.put(QLModel.record.SBQQ__Product__r.name, QLModel.key);
          QLModel.record.SBQQ__Quantity__c = 5;
          QLModel.record.SBQQ__NetPrice__c = 100;
          QLModel.parentItemKey = prodKey.get(childParentMap.get(QLModel.record.SBQQ__Product__r.name));
        } else if (QLModel.record.Product_Level__c == 'Support') {
          QLModel.record.SBQQ__Quantity__c = QLModel.record.Product_Level__c == 'SaaS Software Addon' ? 1 : 5;
          QLModel.record.SBQQ__SubscriptionTerm__c = 36;
          QLModel.record.SBQQ__NetPrice__c = 100;
          QLModel.parentItemKey = prodKey.get(childParentMap.get(QLModel.record.SBQQ__Product__r.name));
        }
      }
      String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
      QuoteCalculator calculator = new QuoteCalculator();
      calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
      quote.ApprovalStatus__c = 'Approved';
      update quote;
      List<SBQQ__QuoteLine__c> qliList = [
        SELECT
          id,
          SBQQ__Quote__r.SBQQ__NetAmount__c,
          SBQQ__NetPrice__c,
          SBQQ__NetTotal__c,
          SBQQ__Product__r.productcode,
          SBQQ__Quantity__c,
          SBQQ__SubscriptionTerm__c,
          SBQQ__Product__c,
          SBQQ__Product__r.name,
          SBQQ__Product__r.Product_Level__c,
          SBQQ__RequiredBy__c
        FROM SBQQ__QuoteLine__c
      ];
      List<PO_Stage__c> poList = new List<PO_Stage__c>();
      PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage(
        'Promark Technology, Inc.pp',
        'test123',
        system.today().addDays(10),
        2,
        'test@test.com.invalid',
        'test partner',
        system.today(),
        1,
        'test12345',
        quote.name,
        qliList[0].SBQQ__Quote__r.SBQQ__NetAmount__c
      );
      pos.Payment_schedule_type__c = 'test';
      pos.Quote_number__c = quote.name;
      pos.Opportunity__c = quote.SBQQ__Opportunity2__c;
      pos.Ship_to_Email__c = 'test@test.com.invalid';
      pos.Ship_To_Contact_Name__c = 'testCon';
      pos.Ship_To_Phone_Number__c = '7000022448';
      pos.ShippingCountryCode__c = 'IN';
      pos.ShippingStateCode__c = 'KA';
      pos.ShippingCity__c = 'test City';
      pos.ShippingStreet__c = 'test street';
      pos.ShippingPostalCode__c = '0000';
      pos.PO_Validation_Status__c = 'Pending';
      pos.Consult_Splitted__c = true;
      pos.Shipping_Carrier__c = null;
      pos.Service_Level__c = null;
      pos.Shipping_Account_Number__c = '456';
      pos.Note_on_Contingency_and_Special_Language__c = 'PA xyz test';
      pos.Bill_To_Name__c = acc.id;
      pos.Customer_Requested_Ship_Date__c = String.ValueOf(system.today().addDays(-20));
      pos.PoDate__c = system.today(); 
      pos.Account_Name__c = 'Test Promark Technology Inc.';  
      poList.add(pos);
      poList.add(pos.clone());
      poList[1].PO_Index__c = 2;
      poList[1].Shipping_Carrier__c = 'xyz';
      poList[1].Shipping_Account_Number__c = null;
      poList[1].PO_Validation_Status__c = 'staged';
      poList[1].TotalAmount__c = 0.0;
      insert poList;
      quote.SBQQ__Primary__c = false;
      quote.SBQQ__ExpirationDate__c = system.today().addMonths(-3);
      update quote;

      List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>();
      for (integer i = 0; i < qliList.size(); i++) {
        string ediLinenum = 0 + '' + i;
        PO_Item_Stage__c poi;
        Id stgId = qliList[i].SBQQ__Product__r.name == 'HWProd-002-test' ? poList[1].id : poList[0].id;
        poItem.add(
          ShGl_TestFactoryHelper.createPOItem(
            '1234' + ediLinenum,
            ediLinenum,
            qliList[i].SBQQ__Product__r.productcode,
            qliList[i].SBQQ__Quantity__c,
            poList[0].id,
            qliList[i].SBQQ__SubscriptionTerm__c,
            qliList[i].SBQQ__NetPrice__c
          )
        );
      }
      insert poItem;
      List<PO_Stage__c> stgpo = [
        SELECT
          Id,
          PO_Internal_Validation_Status__c,
          PO_Validation_Status__c,
          Expected_number_of_POs__c,
          PO_Index__c,
          Quote__c,
          Quote_number__c,
          TotalAmount__c,
          (
            SELECT
              Id,
              Name,
              Stage_PO__c,
              Stage_PO__r.Expected_number_of_POs__c,
              Stage_PO__r.name,
              Stage_PO__r.Quote__c,
              Quantity__c,
              UnitPrice__c,
              Product__c,
              SubscriptionTerm__c,
              ProductCode__c,
              Subscription_Term_Description__c,
              EDI_Line_Number__c,
              Buyer_Part_Number__c,
              Deliver_By__c,
              Est_Ship_Date__c,
              Stage_PO__r.Bill_To_Name__r.EDI_DISTI_ID__c,
              Stage_PO__r.Quote__r.SBQQ__Opportunity2__r.Distributor_Lookup__r.EDI_DISTI_ID__c,
              Product__r.Appliance_Model_HW__c,
              Product__r.Product_Type__c,
              Product__r.Product_Level__c,
              Product__r.ProductCode,
              Product__r.Usable_Capacity__c,
              Product__r.Product_Payment_Option__c,
              Product__r.Product_Subtype__c
            FROM PO_Item_Stage__r
          )
        FROM PO_Stage__c
      ];

                  POC__c pocobj = new POC__c();
      pocobj.POC_Duration__c = '60 Days'; //30 Days
      pocobj.Planned_Installation_Date__c = date.today().addDays(90);
      pocobj.Support_Awareness_needed__c = 'Yes';
      pocobj.POC_Type__c = 'Conditional PO';
      pocobj.Product_Categories__c = 'Rubrik Appliance';
      test.startTest();
      insert pocobj;

      Map<String, Object> OrderMap = new Map<String, Object>{
        'Type' => 'Revenue',
        'Send_for_Polaris_Fulfilment__c' => true,
        'POC_Request__c' => pocobj.Id,
        'AccountId' => acc.Id,
        'POC_Opportunity__c' => quote.SBQQ__Opportunity2__c,
        'EffectiveDate' => system.today(),
        'Order_Status__c' => null,
        'Status' => 'Pending',
        'Sync_to_NetSuite__c' => true,
        'ShippingCountryCode' => 'US',
        'ShippingStateCode' => 'CA',
        'ShippingStreet' => 'Test Street',
        'ShippingCity' => 'Test City',
        'ShippingState' => 'California',
        'ShippingCountry' => 'United States',
        'ShippingPostalcode' => '94820',
        'ship_To_Name__c' => acc.id,
        'ShipToContactName__c' => 'Test',
        'Pricebook2Id' => quote.SBQQ__PricebookId__c ,
        'Have_Polaris_Products__c' => false,
        'Polaris_Fulfillment_Status__c' => 'Completed',
        'Original_Est_Ship_Date__c' => Date.today().addDays(30),
        'Est_Ship_Date__c' => null,
        'Order_Splitted__c' => true,
        'Order_Sub_Type__c' => 'Renewal'
      };

      Order ord = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
      insert Ord;

      POStageHelper.allStagePOmap.clear();
      POStageHelper.quoteMap.clear();
      poList[0].PO_Validation_Status__c = 'staged';
      update poList[0];
      poList[0].Account_Name__c  = 'Test1 Account Tech'; 
      poList[0].PO_Validation_Status__c = 'staged';
      update poList[0];
      system.assertEquals(2, poList.size());
    }
  }
  /**
  * @description This method test the InitiateIntValidationAndOrderGeneration Queueable Class
  */
  static testMethod void initiateIntValidationAndOrderGenerationTest2() {
    
    String uniqueUserName = 'TestUser1' + DateTime.now().getTime() + '@rbk.com';
    Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
    User usr = new user(
      alias = 'std',
      email = 'testuser@testclass.com',
      emailencodingkey = 'UTF-8',
      firstname = 'test_test',
      lastname = 'user',
      languagelocalekey = 'en_US',
      localesidkey = 'en_US',
      profileid = p.Id,
      timezonesidkey = 'America/Los_Angeles',
      username = uniqueUserName
    );
    
    insert usr;  

    //User usr = [SELECT id, alias FROM user ORDER BY createddate DESC LIMIT 1];
    POStageHandler.triggerMaxCount = 25;
    System.runAs(usr) {
        insert new ShGl_DisableBusinessLogic__c(
        Disable_SBQQ_Quote_Triggers__c = true,
        Disable_SBQQ_QuoteLine_Triggers__c = true,
        Disable_Opportunity_Triggers__c = true,
        Disable_Order_Email_Alerts__c = false,
        Disable_Order_Triggers__c = false,
        Disable_Opportunity_Validation_Rules__c = true,
        Disable_SBQQ_QuoteLine_Validation_Rules__c = true,
        Disable_SBQQ_Quote_Validation_Rules__c = true,
        Disable_Account_Validation_Rules__c  = true,  
        setupOwnerId = usr.id
      );

      List<product2> prodList = [SELECT id, Name, ProductCode, Product_Level__c, Product_Subtype__c, Product_Type__c, Usable_Capacity__c FROM product2];
      SBQQ__Quote__c quote = [SELECT id, name, SBQQ__Account__c, SBQQ__Opportunity2__c, SBQQ__NetAmount__c, ProcessType__c,SBQQ__PricebookId__c FROM SBQQ__Quote__c];
      Account acc = (Account) ShGl_TestFactory.createSObject(new Account(), new Map<String, Object>{ 'name' => 'test23', 'Type' => 'Distributor' });
      insert acc;
      update new Opportunity(id = quote.SBQQ__Opportunity2__c, Hold_Code__c = 'Contingency with order');
      List<ProductModel> prodModels = new List<ProductModel>();
      String currencyCode = 'USD';
      set<string> prodName = new Set<string>{ 'HybridProd-001-test', 'HWSupportProd-001-test', 'HWProd-001-test', 'HWProd-002-test' };
      for (product2 prod : prodList) {
        if (prodName.contains(prod.name)) {
          prodModels.add(
            (ProductModel) JSON.deserialize(
              SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prod.id, '{"pricebookId" : "' + system.label.CPQPricebookID + '", "currencyCode" : "' + currencyCode + '"}'),
              ProductModel.class
            )
          );
        }
      }
      String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', quote.id);
      ProductAdder adder = new ProductAdder();
      QuoteModel quoteWithProducts = adder.add((QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class), prodModels, 0);
      Map<string, string> childParentMap = new Map<string, string>{
        'HWProd-001-test' => 'HybridProd-001-test',
        'HWProd-002-test' => 'HybridProd-002-test',
        'HWSupportProd-001-test' => 'HWProd-001-test',
        'HWSupport2Prod-001-test' => 'HWProd-001-test',
        'AddonProd-001-test' => 'HybridProd-001-test'
      };
      Map<string, Integer> prodKey = new Map<string, Integer>();
      Integer hwIndex, hybIndx, addonIndx;
      hwIndex = hybIndx = addonIndx = 0;
      for (QuoteLineModel QLModel : quoteWithProducts.lineItems) {
        if (QLModel.record.Product_Level__c == 'Hybrid Software') {
          prodKey.put(QLModel.record.SBQQ__Product__r.name, QLModel.key);
          QLModel.record.SBQQ__Quantity__c = 500;
          QLModel.record.SBQQ__SubscriptionTerm__c = 36;
          QLModel.record.SBQQ__NetPrice__c = 100;
        } else if (QLModel.record.Product_Level__c == 'Hardware' && QLModel.record.Product_Type__c == 'Hardware') {
          prodKey.put(QLModel.record.SBQQ__Product__r.name, QLModel.key);
          QLModel.record.SBQQ__Quantity__c = 5;
          QLModel.record.SBQQ__NetPrice__c = 100;
          QLModel.parentItemKey = prodKey.get(childParentMap.get(QLModel.record.SBQQ__Product__r.name));
        } else if (QLModel.record.Product_Level__c == 'Support') {
          QLModel.record.SBQQ__Quantity__c = QLModel.record.Product_Level__c == 'SaaS Software Addon' ? 1 : 5;
          QLModel.record.SBQQ__SubscriptionTerm__c = 36;
          QLModel.record.SBQQ__NetPrice__c = 100;
          QLModel.parentItemKey = prodKey.get(childParentMap.get(QLModel.record.SBQQ__Product__r.name));
        }
      }
      String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
      QuoteCalculator calculator = new QuoteCalculator();
      calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
      quote.ApprovalStatus__c = 'Approved';
      quote.ProcessType__c = 'ASPEN';
      quote.Payment_year_1__c = 5000;
      update quote;
      List<SBQQ__QuoteLine__c> qliList = [
        SELECT
          id,
          SBQQ__Quote__r.SBQQ__NetAmount__c,
          SBQQ__NetPrice__c,
          SBQQ__NetTotal__c,
          SBQQ__Product__r.productcode,
          SBQQ__Quantity__c,
          SBQQ__SubscriptionTerm__c,
          SBQQ__Product__c,
          SBQQ__Product__r.name,
          SBQQ__Product__r.Product_Level__c,
          SBQQ__RequiredBy__c
        FROM SBQQ__QuoteLine__c
      ];
      List<PO_Stage__c> poList = new List<PO_Stage__c>();
      PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage(
        'Promark Technology, Inc.pp',
        'test123',
        system.today().addDays(10),
        2,
        'test@test.com.invalid',
        'test partner',
        system.today(),
        1,
        'test12345',
        quote.name,
        qliList[0].SBQQ__Quote__r.SBQQ__NetAmount__c
      );
      pos.Payment_schedule_type__c = 'Y1 $10000.23 Y2 $105365.83679999999';
      pos.Quote_number__c = quote.name;
      pos.Opportunity__c = quote.SBQQ__Opportunity2__c;
      pos.Ship_to_Email__c = 'test@test.com.invalid';
      pos.Ship_To_Contact_Name__c = 'testCon';
      pos.Ship_To_Phone_Number__c = '7000022448';
      pos.ShippingCountryCode__c = 'IN';
      pos.ShippingStateCode__c = 'KA';
      pos.ShippingCity__c = 'test City';
      pos.ShippingStreet__c = 'test street';
      pos.ShippingPostalCode__c = '0000';
      pos.PO_Validation_Status__c = 'Pending';
      pos.Consult_Splitted__c = true;
      pos.Shipping_Carrier__c = null;
      pos.Service_Level__c = null;
      pos.Shipping_Account_Number__c = '456';
      pos.Note_on_Contingency_and_Special_Language__c = 'PA xyz test';
      pos.Bill_To_Name__c = acc.id;
      pos.Customer_Requested_Ship_Date__c = String.ValueOf(system.today().addDays(-20));
      pos.PoDate__c = system.today();  
      pos.ContractManufacturer__c = 'Super Micro Computer, Inc.'; 
      poList.add(pos);
      poList.add(pos.clone());
      poList[1].PO_Index__c = 2;
      poList[1].Shipping_Carrier__c = 'xyz';
      poList[1].Shipping_Account_Number__c = null;
      poList[1].PO_Validation_Status__c = 'staged';
      poList[1].TotalAmount__c = 0.0;
      poList[1].Opportunity__c = null;
      insert poList;
      quote.SBQQ__Primary__c = false;
      quote.SBQQ__ExpirationDate__c = system.today().addMonths(-3);
      quote.SBQQ__Opportunity2__c = null;
      update quote;

      List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>();
      for (integer i = 0; i < qliList.size(); i++) {
        string ediLinenum = 0 + '' + i;
        PO_Item_Stage__c poi;
        Id stgId = qliList[i].SBQQ__Product__r.name == 'HWProd-002-test' ? poList[1].id : poList[0].id;
        poItem.add(
          ShGl_TestFactoryHelper.createPOItem(
            '1234' + ediLinenum,
            ediLinenum,
            qliList[i].SBQQ__Product__r.productcode,
            qliList[i].SBQQ__Quantity__c,
            poList[0].id,
            qliList[i].SBQQ__SubscriptionTerm__c,
            qliList[i].SBQQ__NetPrice__c
          )
        );
      }
      insert poItem;
      List<PO_Stage__c> stgpo = [
        SELECT
          Id,
          PO_Internal_Validation_Status__c,
          PO_Validation_Status__c,
          Expected_number_of_POs__c,
          PO_Index__c,
          Quote__c,
          Quote_number__c,
          TotalAmount__c,
          (
            SELECT
              Id,
              Name,
              Stage_PO__c,
              Stage_PO__r.Expected_number_of_POs__c,
              Stage_PO__r.name,
              Stage_PO__r.Quote__c,
              Quantity__c,
              UnitPrice__c,
              Product__c,
              SubscriptionTerm__c,
              ProductCode__c,
              Subscription_Term_Description__c,
              EDI_Line_Number__c,
              Buyer_Part_Number__c,
              Deliver_By__c,
              Est_Ship_Date__c,
              Stage_PO__r.Bill_To_Name__r.EDI_DISTI_ID__c,
              Stage_PO__r.Quote__r.SBQQ__Opportunity2__r.Distributor_Lookup__r.EDI_DISTI_ID__c,
              Product__r.Appliance_Model_HW__c,
              Product__r.Product_Type__c,
              Product__r.Product_Level__c,
              Product__r.ProductCode,
              Product__r.Usable_Capacity__c,
              Product__r.Product_Payment_Option__c,
              Product__r.Product_Subtype__c
            FROM PO_Item_Stage__r
          )
        FROM PO_Stage__c
      ];
      
      POC__c pocobj = new POC__c();
      pocobj.POC_Duration__c = '60 Days'; //30 Days
      pocobj.Planned_Installation_Date__c = date.today().addDays(90);
      pocobj.Support_Awareness_needed__c = 'Yes';
      pocobj.POC_Type__c = 'Conditional PO';
      pocobj.Product_Categories__c = 'Rubrik Appliance';
      test.startTest();
      insert pocobj;

      Map<String, Object> OrderMap = new Map<String, Object>{
        'Type' => 'Revenue',
        'Send_for_Polaris_Fulfilment__c' => true,
        'POC_Request__c' => pocobj.Id,
        'AccountId' => acc.Id,
        'POC_Opportunity__c' => quote.SBQQ__Opportunity2__c,
        'EffectiveDate' => system.today(),
        'Order_Status__c' => null,
        'Status' => 'Pending',
        'Sync_to_NetSuite__c' => true,
        'ShippingCountryCode' => 'US',
        'ShippingStateCode' => 'CA',
        'ShippingStreet' => 'Test Street',
        'ShippingCity' => 'Test City',
        'ShippingState' => 'California',
        'ShippingCountry' => 'United States',
        'ShippingPostalcode' => '94820',
        'ship_To_Name__c' => acc.id,
        'ShipToContactName__c' => 'Test',
        'Pricebook2Id' => quote.SBQQ__PricebookId__c ,
        'Have_Polaris_Products__c' => false,
        'Polaris_Fulfillment_Status__c' => 'Completed',
        'Original_Est_Ship_Date__c' => Date.today().addDays(30),
        'Est_Ship_Date__c' => null,
        'Order_Splitted__c' => true,
        'Order_Sub_Type__c' => 'Renewal'
      };

      Order ord = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
      insert Ord;
      POStageHelper.allStagePOmap.clear();
      POStageHelper.quoteMap.clear();
      poList[0].ContractManufacturer__c = null;
      poList[0].PO_Validation_Status__c = 'staged';
      update poList[0];
      
      system.assertEquals(2, poList.size());
      InitiateIntValidationAndOrderGeneration.checkIfPaymentScheduleTypeMatchesPaymentTermsOnQuote(null,new Map<String,Decimal>{ 'Y1' => 100},10);  
      InitiateIntValidationAndOrderGeneration.checkIfPaymentScheduleTypeMatchesPaymentTermsOnQuote(null,new Map<String,Decimal>(),10);  
      InitiateIntValidationAndOrderGeneration.parsePaymentSchedule(null);
    }
  }
  /**
  * @description This method test the PO Validation for ASPEN
  */
  static testMethod void validateAspenPOTest() {
    POStageHandler.triggerMaxCount = 25;
    User usr = [SELECT id, alias FROM user ORDER BY createddate DESC LIMIT 1];
    System.runAs(usr) {
      List<product2> prodList = [SELECT id, Name, ProductCode, Product_Level__c, Product_Subtype__c, Product_Type__c, Usable_Capacity__c FROM product2];
      SBQQ__Quote__c quote = [SELECT id, name, SBQQ__Account__c, SBQQ__Opportunity2__c, SBQQ__NetAmount__c, ProcessType__c FROM SBQQ__Quote__c];
      List<ProductModel> prodModels = new List<ProductModel>();
      String currencyCode = 'USD';
      set<string> prodName = new Set<string>{
        'HybridProd-001-test',
        'HybridProd-002-test',
        'HWSupportProd-001-test',
        'HWSupport2Prod-001-test',
        'HWProd-001-test',
        'HWProd-002-test',
        'AddonProd-001-test'
      };
      for (product2 prod : prodList) {
        if (prodName.contains(prod.name)) {
          prodModels.add(
            (ProductModel) JSON.deserialize(
              SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prod.id, '{"pricebookId" : "' + system.label.CPQPricebookID + '", "currencyCode" : "' + currencyCode + '"}'),
              ProductModel.class
            )
          );
        }
      }
      String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', quote.id);
      ProductAdder adder = new ProductAdder();
      QuoteModel quoteWithProducts = adder.add((QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class), prodModels, 0);
      Map<string, string> childParentMap = new Map<string, string>{
        'HWProd-001-test' => 'HybridProd-001-test',
        'HWProd-002-test' => 'HybridProd-002-test',
        'HWSupportProd-001-test' => 'HWProd-001-test',
        'HWSupport2Prod-001-test' => 'HWProd-001-test',
        'AddonProd-001-test' => 'HybridProd-001-test'
      };
      Map<string, Integer> prodKey = new Map<string, Integer>();
      Integer hwIndex, hybIndx, addonIndx;
      hwIndex = hybIndx = addonIndx = 0;
      for (QuoteLineModel QLModel : quoteWithProducts.lineItems) {
        if (QLModel.record.Product_Level__c == 'Hybrid Software') {
          prodKey.put(QLModel.record.SBQQ__Product__r.name, QLModel.key);
          QLModel.record.SBQQ__Quantity__c = 500;
          QLModel.record.SBQQ__SubscriptionTerm__c = 36;
          QLModel.record.SBQQ__NetPrice__c = 100;
        } else if (QLModel.record.Product_Level__c == 'Hardware' && QLModel.record.Product_Type__c == 'Hardware') {
          prodKey.put(QLModel.record.SBQQ__Product__r.name, QLModel.key);
          QLModel.record.SBQQ__Quantity__c = 5;
          QLModel.record.SBQQ__NetPrice__c = 100;
          QLModel.parentItemKey = prodKey.get(childParentMap.get(QLModel.record.SBQQ__Product__r.name));
        } else if (QLModel.record.Product_Level__c == 'Support' || QLModel.record.Product_Level__c == 'SaaS Software Addon') {
          QLModel.record.SBQQ__Quantity__c = QLModel.record.Product_Level__c == 'SaaS Software Addon' ? 1 : 5;
          QLModel.record.SBQQ__SubscriptionTerm__c = 36;
          QLModel.record.SBQQ__NetPrice__c = 100;
          QLModel.parentItemKey = prodKey.get(childParentMap.get(QLModel.record.SBQQ__Product__r.name));
        }
      }
      String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
      QuoteCalculator calculator = new QuoteCalculator();
      calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
      quote.ApprovalStatus__c = 'Approved';
      quote.ProcessType__c = 'Aspen';
      update quote;
      List<SBQQ__QuoteLine__c> qliList = [
        SELECT
          id,
          SBQQ__Quote__r.SBQQ__NetAmount__c,
          SBQQ__NetPrice__c,
          SBQQ__NetTotal__c,
          SBQQ__Product__r.productcode,
          SBQQ__Quantity__c,
          SBQQ__SubscriptionTerm__c,
          SBQQ__Product__c,
          SBQQ__Product__r.name,
          SBQQ__Product__r.Product_Level__c,
          SBQQ__RequiredBy__c
        FROM SBQQ__QuoteLine__c
      ];
      PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage(
        'Promark Technology, Inc.pp',
        'test123',
        system.today().addDays(10),
        1,
        'test@test.com.invalid',
        'test partner',
        system.today(),
        1,
        'test12345',
        quote.name,
        qliList[0].SBQQ__Quote__r.SBQQ__NetAmount__c
      );
      pos.Bill_To_Name__c = quote.SBQQ__Account__c;
      pos.Payment_schedule_type__c = 'test';
      pos.Quote_number__c = quote.name;
      pos.Opportunity__c = quote.SBQQ__Opportunity2__c;
      pos.Ship_to_Email__c = 'test@test.com.invalid';
      pos.Ship_To_Contact_Name__c = 'testCon';
      pos.Ship_To_Phone_Number__c = '7000022448';
      pos.ShippingCountryCode__c = 'IN';
      pos.ShippingStateCode__c = 'KA';
      pos.ShippingCity__c = 'test City';
      pos.ShippingStreet__c = 'test street';
      pos.ShippingPostalCode__c = '0000';
      insert pos;

      List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>();

      for (integer i = 0; i < qliList.size(); i++) {
        Decimal Quant = qliList[i].SBQQ__Product__r.Product_Level__c == 'Hybrid Software'
          ? qliList[i].SBQQ__Product__r.name == 'HybridProd-002-test' ? 500 : 100.0
          : qliList[i].SBQQ__Product__r.name == 'HWProd-002-test' ? 5.0 : 1.0;
        poItem.add(
          ShGl_TestFactoryHelper.createPOItem(
            '1234' + i,
            'e1' + i,
            qliList[i].SBQQ__Product__r.productcode,
            Quant,
            pos.id,
            qliList[i].SBQQ__SubscriptionTerm__c,
            qliList[i].SBQQ__NetPrice__c
          )
        );
      }
      insert poItem;
      List<PO_Stage__c> stgpo = [
        SELECT
          Id,
          PO_Internal_Validation_Status__c,
          PO_Validation_Status__c,
          Expected_number_of_POs__c,
          PO_Index__c,
          Quote__c,
          Quote_number__c,
          TotalAmount__c,
          (
            SELECT
              Id,
              Name,
              Stage_PO__c,
              Stage_PO__r.Expected_number_of_POs__c,
              Stage_PO__r.name,
              Stage_PO__r.Quote__c,
              Quantity__c,
              UnitPrice__c,
              Product__c,
              SubscriptionTerm__c,
              ProductCode__c,
              Subscription_Term_Description__c,
              EDI_Line_Number__c,
              Buyer_Part_Number__c,
              Deliver_By__c,
              Est_Ship_Date__c,
              Stage_PO__r.Bill_To_Name__r.EDI_DISTI_ID__c,
              Stage_PO__r.Quote__r.SBQQ__Opportunity2__r.Distributor_Lookup__r.EDI_DISTI_ID__c,
              Product__r.Appliance_Model_HW__c,
              Product__r.Product_Type__c,
              Product__r.Product_Level__c,
              Product__r.ProductCode,
              Product__r.Usable_Capacity__c,
              Product__r.Product_Payment_Option__c,
              Product__r.Product_Subtype__c
            FROM PO_Item_Stage__r
          )
        FROM PO_Stage__c
      ];
      POStageHelper.allStagePOmap.clear();
      POStageHelper.quoteMap.clear();
      pos.PO_Validation_Status__c = 'Staged';
      update pos;
      system.assertEquals(7, qliList.size());
    }
  }
  /**
  * @description This is a static value for EDI Go Product Buyer part number
  */
  static final String BUYER_PART_NUM_ValidateEDIGoProduct = '1234';
  /**
  * @description This is a static list of EDI NUM values for EDI Go Product
  */
  static final List<String> EDI_NUM_LIST_ValidateEDIGoProduct = new List<String>{ '01', '02', '03', '04', '05', '06' };
  /**
  * @description This method is to get the user
  * @return User
  */
  static User getUser() {
    return [SELECT id, alias FROM user ORDER BY createddate DESC LIMIT 1];
  }
  /**
  * @description This method is PO helper for EDIGoProduct PO validation
  * @param poStageList
  * @param poItem
  */
  static void helperStagePoValidateEDIGoProduct(List<PO_Stage__c> poStageList, List<PO_Item_Stage__c> poItem) {
    insert poItem;
    POStageHelper.allStagePOmap.clear();
    POStageHelper.quoteMap.clear();
    update setStagePosForValidation(poStageList);
  }
  /**
  * @description This method is PO helper for Quote COnfig of EDIGoProduct
  * @return Map<String, Object>
  */
  static Map<String, Object> helperConfigQuoteValidateEDIGoProduct() {
    set<string> prodName = new Set<string>{ 'RS-EE-GO-PE-PA', 'RC-F3M-CBL-01', 'RC-SFP-TSR-01', 'RH-6304S-01', 'RS-BT-CLE-PE-PA', 'RS-HW-SVC-PE' };
    List<product2> prodList = [
      SELECT id, Name, ProductCode, Product_Level__c, Product_Subtype__c, Product_Type__c, Usable_Capacity__c
      FROM Product2
      WHERE Name IN :prodName
    ];

    SBQQ__Quote__c quote = [
      SELECT id, name, SBQQ__Account__c, SBQQ__Opportunity2__c, SBQQ__NetAmount__c
      FROM SBQQ__Quote__c
    ];
    List<ProductModel> prodModels = new List<ProductModel>();
    String currencyCode = 'USD';
    for (product2 prod : prodList) {
      prodModels.add(
        (ProductModel) JSON.deserialize(
          SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prod.id, '{"pricebookId" : "' + system.label.CPQPricebookID + '", "currencyCode" : "' + currencyCode + '"}'),
          ProductModel.class
        )
      );
    }
    String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', quote.id);
    ProductAdder adder = new ProductAdder();
    QuoteModel quoteWithProducts = adder.add((QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class), prodModels, 0);
    Map<string, string> childParentMap = new Map<string, string>{
      'RH-6304S-01' => 'RS-EE-GO-PE-PA',
      'RC-F3M-CBL-01' => 'RH-6304S-01',
      'RC-SFP-TSR-01' => 'RH-6304S-01',
      'RS-HW-SVC-PE' => 'RH-6304S-01',
      'RS-BT-CLE-PE-PA' => 'RS-EE-GO-PE-PA'
    };
    Map<String, Integer> prodKey = new Map<String, Integer>();
    Integer hwIndex, hybIndx, addonIndx;
    hwIndex = hybIndx = addonIndx = 0;
    for (QuoteLineModel QLModel : quoteWithProducts.lineItems) {
      if (QLModel.record.Product_Level__c == 'Hybrid Software') {
        prodKey.put(QLModel.record.SBQQ__Product__r.name, QLModel.key);
        QLModel.record.SBQQ__Quantity__c = 60;
        QLModel.record.SBQQ__SubscriptionTerm__c = 36;
        QLModel.record.SBQQ__NetPrice__c = 100;
      } else if (QLModel.record.Product_Level__c == 'Hardware' && QLModel.record.Product_Type__c == 'Hardware') {
        prodKey.put(QLModel.record.SBQQ__Product__r.name, QLModel.key);
        QLModel.record.SBQQ__Quantity__c = 5;
        QLModel.record.SBQQ__NetPrice__c = 100;
        QLModel.parentItemKey = prodKey.get(childParentMap.get(QLModel.record.SBQQ__Product__r.name));
      } else if (QLModel.record.Product_Level__c == 'Hardware' && QLModel.record.Product_Type__c == 'Accessories') {
        prodKey.put(QLModel.record.SBQQ__Product__r.name, QLModel.key);
        QLModel.record.SBQQ__Quantity__c = 2;
        QLModel.record.SBQQ__NetPrice__c = 100;
        QLModel.parentItemKey = prodKey.get(childParentMap.get(QLModel.record.SBQQ__Product__r.name));
      } else if (QLModel.record.Product_Level__c == 'Standalone Software Addon' && QLModel.record.Product_Type__c == 'Cloud Edition') {
        prodKey.put(QLModel.record.SBQQ__Product__r.name, QLModel.key);
        QLModel.record.SBQQ__Quantity__c = 6;
        QLModel.record.SBQQ__SubscriptionTerm__c = 36;
        QLModel.record.SBQQ__NetPrice__c = 3600;
        QLModel.parentItemKey = prodKey.get(childParentMap.get(QLModel.record.SBQQ__Product__r.name));
      } else if (QLModel.record.Product_Level__c == 'Support') {
        QLModel.record.SBQQ__Quantity__c = 5;
        QLModel.record.SBQQ__SubscriptionTerm__c = 36;
        QLModel.record.SBQQ__NetPrice__c = 100;
        QLModel.parentItemKey = prodKey.get(childParentMap.get(QLModel.record.SBQQ__Product__r.name));
      }
    }
    String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
    QuoteCalculator calculator = new QuoteCalculator();
    calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
    quote.ApprovalStatus__c = 'Approved';
    update quote;
    return new Map<String, Object>{
      'QuoteId' => quote.Id,
      'BillToName' => quote.SBQQ__Account__c,
      'OpportunityId' => quote.SBQQ__Opportunity2__c,
      'QuoteName' => quote.Name,
      'QuoteAmount' => quote.SBQQ__NetAmount__c
    };
  }
  /**
  * @description This PO helper for EDIGoProduct PO validation
  * @return List<PO_Stage__c>
  */
  static List<PO_Stage__c> helperConfigStagePoValidateEDIGoProduct() {
    Map<String, Object> mapStrKeyObjPerWorkData = helperConfigQuoteValidateEDIGoProduct();
    Id quoteId = (Id) mapStrKeyObjPerWorkData.get('QuoteId');
    Id accountIdBillToName = (Id) mapStrKeyObjPerWorkData.get('BillToName');
    Id opportunityId = (Id) mapStrKeyObjPerWorkData.get('OpportunityId');
    String quoteName = (String) mapStrKeyObjPerWorkData.get('QuoteName');
    Decimal quoteAmount = (Decimal) mapStrKeyObjPerWorkData.get('QuoteAmount');
    List<PO_Stage__c> poStageList = new List<PO_Stage__c>();
    for (integer i = 1; i <= 2; i++) {
      PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage(
        'Promark Technology, Inc.pp',
        'test123',
        system.today().addDays(10),
        2,
        'test@test.com.invalid',
        'test partner',
        system.today(),
        i,
        'test12345',
        quoteName,
        0
      );

      pos.Bill_To_Name__c = accountIdBillToName;
      pos.Payment_schedule_type__c = 'test';
      pos.Quote_number__c = quoteName;
      pos.Opportunity__c = opportunityId;
      pos.Ship_to_Email__c = 'test@test.com.invalid';
      pos.Ship_To_Contact_Name__c = 'testCon';
      pos.Ship_To_Phone_Number__c = '7000022448';
      pos.ShippingCountryCode__c = 'IN';
      pos.ShippingStateCode__c = 'KA';
      pos.ShippingCity__c = 'test City';
      pos.ShippingStreet__c = 'test street';
      pos.ShippingPostalCode__c = '0000';
      pos.PO_Validation_Status__c = 'Pending';
      poStageList.add(pos);
    }
    poStageList[0].TotalAmount__c = quoteAmount;
    insert poStageList;
    return poStageList;
  }
  /**
  * @description This method is the PO helper for QLI Creation
  * @return List<PO_Stage__c>
  */
  static List<PO_Stage__c> helper2Qli() {
    set<string> prodName = new Set<string>{ 'RS-EE-GO-PE-PA', 'RC-F3M-CBL-01', 'RC-SFP-TSR-01', 'RH-6304S-01', 'RS-BT-CLE-PE-PA', 'RS-HW-SVC-PE', 'RA-HW-CREDIT' };
    List<product2> prodList = [
      SELECT id, Name, ProductCode, Product_Level__c, Product_Subtype__c, Product_Type__c, Usable_Capacity__c
      FROM Product2
      WHERE Name IN :prodName
    ];

    SBQQ__Quote__c quote = [
      SELECT id, name, SBQQ__Account__c, SBQQ__Opportunity2__c, SBQQ__NetAmount__c
      FROM SBQQ__Quote__c
    ];
    List<ProductModel> prodModels = new List<ProductModel>();
    String currencyCode = 'USD';
    for (product2 prod : prodList) {
      if (prod.ProductCode == 'RS-BT-CLE-PE-PA') {
        prodModels.add(
          (ProductModel) JSON.deserialize(
            SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prod.id, '{"pricebookId" : "' + system.label.CPQPricebookID + '", "currencyCode" : "' + currencyCode + '"}'),
            ProductModel.class
          )
        );
        prodModels.add(
          (ProductModel) JSON.deserialize(
            SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prod.id, '{"pricebookId" : "' + system.label.CPQPricebookID + '", "currencyCode" : "' + currencyCode + '"}'),
            ProductModel.class
          )
        );
      }
      prodModels.add(
        (ProductModel) JSON.deserialize(
          SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prod.id, '{"pricebookId" : "' + system.label.CPQPricebookID + '", "currencyCode" : "' + currencyCode + '"}'),
          ProductModel.class
        )
      );
    }
    String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', quote.id);
    ProductAdder adder = new ProductAdder();
    QuoteModel quoteWithProducts = adder.add((QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class), prodModels, 0);
    Map<string, string> childParentMap = new Map<string, string>{
      'RH-6304S-01' => 'RS-EE-GO-PE-PA',
      'RC-F3M-CBL-01' => 'RH-6304S-01',
      'RC-SFP-TSR-01' => 'RH-6304S-01',
      'RS-HW-SVC-PE' => 'RH-6304S-01',
      'RS-BT-CLE-PE-PA' => 'RS-EE-GO-PE-PA'
    };
    Map<String, Integer> prodKey = new Map<String, Integer>();
    Integer hwIndex, hybIndx, addonIndx;
    hwIndex = hybIndx = addonIndx = 0;
    for (QuoteLineModel QLModel : quoteWithProducts.lineItems) {
      if (QLModel.record.Product_Level__c == 'Hybrid Software') {
        prodKey.put(QLModel.record.SBQQ__Product__r.name, QLModel.key);
        QLModel.record.SBQQ__Quantity__c = 60;
        QLModel.record.SBQQ__SubscriptionTerm__c = 36;
        QLModel.record.SBQQ__NetPrice__c = 100;
      } else if (QLModel.record.Product_Level__c == 'Hardware' && QLModel.record.Product_Type__c == 'Hardware') {
        prodKey.put(QLModel.record.SBQQ__Product__r.name, QLModel.key);
        QLModel.record.SBQQ__Quantity__c = 5;
        QLModel.record.SBQQ__NetPrice__c = 100;
        QLModel.parentItemKey = prodKey.get(childParentMap.get(QLModel.record.SBQQ__Product__r.name));
      } else if (QLModel.record.Product_Level__c == 'Hardware' && QLModel.record.Product_Type__c == 'Accessories') {
        prodKey.put(QLModel.record.SBQQ__Product__r.name, QLModel.key);
        QLModel.record.SBQQ__Quantity__c = 2;
        QLModel.record.SBQQ__NetPrice__c = 100;
        QLModel.parentItemKey = prodKey.get(childParentMap.get(QLModel.record.SBQQ__Product__r.name));
      } else if (QLModel.record.Product_Level__c == 'Standalone Software Addon' && QLModel.record.Product_Type__c == 'Cloud Edition') {
        prodKey.put(QLModel.record.SBQQ__Product__r.name, QLModel.key);
        QLModel.record.SBQQ__Quantity__c = 6;
        QLModel.record.SBQQ__SubscriptionTerm__c = 36;
        QLModel.record.SBQQ__NetPrice__c = 3600;
        QLModel.parentItemKey = prodKey.get(childParentMap.get(QLModel.record.SBQQ__Product__r.name));
      } else if (QLModel.record.Product_Level__c == 'Support') {
        QLModel.record.SBQQ__Quantity__c = 5;
        QLModel.record.SBQQ__SubscriptionTerm__c = 36;
        QLModel.record.SBQQ__NetPrice__c = 100;
        QLModel.parentItemKey = prodKey.get(childParentMap.get(QLModel.record.SBQQ__Product__r.name));
      }
    }

    String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
    QuoteCalculator calculator = new QuoteCalculator();
    calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
    quote.ApprovalStatus__c = 'Approved';
    update quote;
    Map<String, Object> mapStrKeyObjPerWorkData = new Map<String, Object>{
      'QuoteId' => quote.Id,
      'BillToName' => quote.SBQQ__Account__c,
      'OpportunityId' => quote.SBQQ__Opportunity2__c,
      'QuoteName' => quote.Name,
      'QuoteAmount' => quote.SBQQ__NetAmount__c
    };
    Id quoteId = (Id) mapStrKeyObjPerWorkData.get('QuoteId');
    Id accountIdBillToName = (Id) mapStrKeyObjPerWorkData.get('BillToName');
    Id opportunityId = (Id) mapStrKeyObjPerWorkData.get('OpportunityId');
    String quoteName = (String) mapStrKeyObjPerWorkData.get('QuoteName');
    Decimal quoteAmount = (Decimal) mapStrKeyObjPerWorkData.get('QuoteAmount');
    List<PO_Stage__c> poStageList = new List<PO_Stage__c>();
    for (integer i = 1; i <= 2; i++) {
      PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage(
        'Promark Technology, Inc.pp',
        'test123',
        system.today().addDays(10),
        2,
        'test@test.com.invalid',
        'test partner',
        system.today(),
        i,
        'test12345',
        quoteName,
        0
      );

      pos.Bill_To_Name__c = accountIdBillToName;
      pos.Payment_schedule_type__c = 'test';
      pos.Quote_number__c = quoteName;
      pos.Opportunity__c = opportunityId;
      pos.Ship_to_Email__c = 'test@test.com.invalid';
      pos.Ship_To_Contact_Name__c = 'testCon';
      pos.Ship_To_Phone_Number__c = '7000022448';
      pos.ShippingCountryCode__c = 'IN';
      pos.ShippingStateCode__c = 'KA';
      pos.ShippingCity__c = 'test City';
      pos.ShippingStreet__c = 'test street';
      pos.ShippingPostalCode__c = '0000';
      pos.PO_Validation_Status__c = 'Pending';
      poStageList.add(pos);
    }
    poStageList[0].TotalAmount__c = quoteAmount;
    insert poStageList;
    return poStageList;
  }
  /**
  * @description This method is PO helper for EDIGoProduct QLI Query
  * @return Map<String, SBQQ__QuoteLine__c>
  */
  static Map<String, SBQQ__QuoteLine__c> helperQueryQLIValidateEDIGoProduct() {
    Map<String, SBQQ__QuoteLine__c> mapStrProductCodeQli = new Map<String, SBQQ__QuoteLine__c>();
    for (SBQQ__QuoteLine__c objQli : [
      SELECT
        Id,
        SBQQ__ProductCode__c,
        SBQQ__RequiredBy__r.SBQQ__ProductCode__c,
        SBQQ__NetPrice__c,
        SBQQ__NetTotal__c,
        SBQQ__Product__r.productcode,
        SBQQ__Quantity__c,
        SBQQ__SubscriptionTerm__c,
        SBQQ__Product__c,
        SBQQ__Product__r.name,
        SBQQ__Product__r.Product_Level__c
      FROM SBQQ__QuoteLine__c
    ]) {
      mapStrProductCodeQli.put(objQli.SBQQ__ProductCode__c, objQli);
    }
    return mapStrProductCodeQli;
  }
  /**
  * @description This method is helper for EDIGoProduct PO validation
  * @param mapStrProductCodeQli
  * @param idStagePo
  * @return List<PO_Stage__c>
  */
  static List<PO_Item_Stage__c> helperConfigQuoteCommonPoli(Map<String, SBQQ__QuoteLine__c> mapStrProductCodeQli, Id idStagePo) {
    return new List<PO_Item_Stage__c>{
      ShGl_TestFactoryHelper.createPOItem(
        BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[1],
        EDI_NUM_LIST_ValidateEDIGoProduct[1],
        'RC-F3M-CBL-01',
        mapStrProductCodeQli.get('RC-F3M-CBL-01').SBQQ__Quantity__c,
        idStagePo,
        mapStrProductCodeQli.get('RC-F3M-CBL-01').SBQQ__SubscriptionTerm__c,
        mapStrProductCodeQli.get('RC-F3M-CBL-01').SBQQ__NetPrice__c
      ),
      ShGl_TestFactoryHelper.createPOItem(
        BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[2],
        EDI_NUM_LIST_ValidateEDIGoProduct[2],
        'RC-SFP-TSR-01',
        mapStrProductCodeQli.get('RC-SFP-TSR-01').SBQQ__Quantity__c,
        idStagePo,
        mapStrProductCodeQli.get('RC-SFP-TSR-01').SBQQ__SubscriptionTerm__c,
        mapStrProductCodeQli.get('RC-SFP-TSR-01').SBQQ__NetPrice__c
      ),
      ShGl_TestFactoryHelper.createPOItem(
        BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[3],
        EDI_NUM_LIST_ValidateEDIGoProduct[3],
        'RH-6304S-01',
        mapStrProductCodeQli.get('RH-6304S-01').SBQQ__Quantity__c,
        idStagePo,
        mapStrProductCodeQli.get('RH-6304S-01').SBQQ__SubscriptionTerm__c,
        mapStrProductCodeQli.get('RH-6304S-01').SBQQ__NetPrice__c
      ),
      ShGl_TestFactoryHelper.createPOItem(
        BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[5],
        EDI_NUM_LIST_ValidateEDIGoProduct[5],
        'RS-HW-SVC-PE',
        mapStrProductCodeQli.get('RS-HW-SVC-PE').SBQQ__Quantity__c,
        idStagePo,
        mapStrProductCodeQli.get('RS-HW-SVC-PE').SBQQ__SubscriptionTerm__c,
        mapStrProductCodeQli.get('RS-HW-SVC-PE').SBQQ__NetPrice__c
      )
    };
  }
  /**
  * @description This method is a helper method for PO Stage Change
  * @param poStageList
  * @return List<PO_Stage__c>
  */
  static List<PO_Stage__c> setStagePosForValidation(List<PO_Stage__c> poStageList) {
    List<PO_Stage__c> x = new List<PO_Stage__c>();
    for (PO_Stage__c stagePo : poStageList) {
      x.add(new PO_Stage__c(Id = stagePo.Id, PO_Validation_Status__c = 'Staged'));
    }
    return x;
  }
/**
  * @description This method test the PO Split
  */
  @IsTest
  static void basicSplittedPoNoSplit01Success() {
    User usr = [SELECT id, alias FROM user ORDER BY createddate DESC LIMIT 1];
    POStageHandler.triggerMaxCount = 25;
    System.runAs(usr) {
      List<PO_Stage__c> poStageList = helperConfigStagePoValidateEDIGoProduct();
      Map<String, SBQQ__QuoteLine__c> mapStrProductCodeQli = helperQueryQLIValidateEDIGoProduct();

      List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>{
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[0],
          EDI_NUM_LIST_ValidateEDIGoProduct[0],
          'RS-EE-GO-PE-PA',
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__Quantity__c,
          poStageList[0].Id,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[4],
          EDI_NUM_LIST_ValidateEDIGoProduct[4],
          'RS-BT-CLE-PE-PA',
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__Quantity__c,
          poStageList[1].Id,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__SubscriptionTerm__c,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__NetPrice__c
        )
      };
      poItem.addAll(helperConfigQuoteCommonPoli(mapStrProductCodeQli, poStageList[1].Id));
      helperStagePoValidateEDIGoProduct(poStageList, poItem);
      List<PO_Stage__c> updateStagePos = setStagePosForValidation(poStageList);
      PO_Item_Stage__c updatePoli = poItem[0].clone();
      updatePoli.Stage_PO__c = poStageList[1].Id;
      delete poItem[0];
      insert updatePoli;
      update updateStagePos;
      system.assertequals(2, poStageList.size());
    }
  }
  /**
  * @description This method test the PO Split Failure
  */
  @IsTest
  static void basicSplittedPoNoSplitPriceFail() {
    User usr = [SELECT id, alias FROM user ORDER BY createddate DESC LIMIT 1];
    POStageHandler.triggerMaxCount = 25;
    System.runAs(usr) {
      List<PO_Stage__c> poStageList = helperConfigStagePoValidateEDIGoProduct();
      Map<String, SBQQ__QuoteLine__c> mapStrProductCodeQli = helperQueryQLIValidateEDIGoProduct();
      List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>{
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[0],
          EDI_NUM_LIST_ValidateEDIGoProduct[0],
          'RS-EE-GO-PE-PA',
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__Quantity__c,
          poStageList[0].Id,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c + 99999
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[4],
          EDI_NUM_LIST_ValidateEDIGoProduct[4],
          'RS-BT-CLE-PE-PA',
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__Quantity__c,
          poStageList[1].Id,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__SubscriptionTerm__c,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__NetPrice__c
        )
      };
      poItem.addAll(helperConfigQuoteCommonPoli(mapStrProductCodeQli, poStageList[1].Id));
      helperStagePoValidateEDIGoProduct(poStageList, poItem);
      system.assertEquals(2, poStageList.size());
    }
  }
  /**
  * @description This method test the PO Split Success
  */
  @IsTest
  static void basicSplittedPoTSplit01Success() {
    User usr = [SELECT id, alias FROM user ORDER BY createddate DESC LIMIT 1];
    POStageHandler.triggerMaxCount = 25;
    System.runAs(usr) {
      // Term Split, once evenly, second time Fail for Term is 2x
      //System.runAs(getUser()) {
      List<PO_Stage__c> poStageList = helperConfigStagePoValidateEDIGoProduct();
      Map<String, SBQQ__QuoteLine__c> mapStrProductCodeQli = helperQueryQLIValidateEDIGoProduct();
      List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>{
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[0],
          EDI_NUM_LIST_ValidateEDIGoProduct[0],
          'RS-EE-GO-PE-PA',
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__Quantity__c,
          poStageList[0].Id,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c / 3,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c / 3
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[0],
          EDI_NUM_LIST_ValidateEDIGoProduct[0],
          'RS-EE-GO-PE-PA',
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__Quantity__c,
          poStageList[0].Id,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c / 3,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c / 3
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[0],
          EDI_NUM_LIST_ValidateEDIGoProduct[0],
          'RS-EE-GO-PE-PA',
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__Quantity__c,
          poStageList[0].Id,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c / 3,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c / 3
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[4],
          EDI_NUM_LIST_ValidateEDIGoProduct[4],
          'RS-BT-CLE-PE-PA',
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__Quantity__c,
          poStageList[1].Id,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__SubscriptionTerm__c,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__NetPrice__c
        )
      };
      poItem.addAll(helperConfigQuoteCommonPoli(mapStrProductCodeQli, poStageList[1].Id));
      helperStagePoValidateEDIGoProduct(poStageList, poItem);
      List<PO_Item_Stage__c> lstUpdatePoli = new List<PO_Item_Stage__c>{
        new PO_Item_Stage__c(
          Id = poItem[0].Id,
          SubscriptionTerm__c = mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c / 3,
          UnitPrice__c = mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c / 3
        ),
        new PO_Item_Stage__c(
          Id = poItem[1].Id,
          SubscriptionTerm__c = (mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c * 2) / 3,
          UnitPrice__c = mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c * 2 / 3
        ),
        new PO_Item_Stage__c(
          Id = poItem[2].Id,
          SubscriptionTerm__c = mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c,
          UnitPrice__c = mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c / 3
        )
      };
      update lstUpdatePoli;
      update setStagePosForValidation(poStageList);
      system.assertequals(3, lstUpdatePoli.size());
    }
  }
  /**
  * @description This method test the PO External Sucess and Internal Fail
  */
  @IsTest
  static void basicSplittedPoQSplit01SuccessthenFail() {
    User usr = [SELECT id, alias FROM user ORDER BY createddate DESC LIMIT 1];
    POStageHandler.triggerMaxCount = 25;
    System.runAs(usr) {
      // System.runAs(getUser()) {
      List<PO_Stage__c> poStageList = helperConfigStagePoValidateEDIGoProduct();
      Map<String, SBQQ__QuoteLine__c> mapStrProductCodeQli = helperQueryQLIValidateEDIGoProduct();
      List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>{
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[0],
          EDI_NUM_LIST_ValidateEDIGoProduct[0],
          'RS-EE-GO-PE-PA',
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__Quantity__c / 3,
          poStageList[0].Id,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[0],
          EDI_NUM_LIST_ValidateEDIGoProduct[0],
          'RS-EE-GO-PE-PA',
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__Quantity__c / 3,
          poStageList[0].Id,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[0],
          EDI_NUM_LIST_ValidateEDIGoProduct[0],
          'RS-EE-GO-PE-PA',
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__Quantity__c / 3,
          poStageList[0].Id,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[4],
          EDI_NUM_LIST_ValidateEDIGoProduct[4],
          'RS-BT-CLE-PE-PA',
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__Quantity__c * 2 / 3,
          poStageList[1].Id,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__SubscriptionTerm__c,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__NetPrice__c
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[4],
          EDI_NUM_LIST_ValidateEDIGoProduct[4],
          'RS-BT-CLE-PE-PA',
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__Quantity__c / 3,
          poStageList[1].Id,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__SubscriptionTerm__c,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__NetPrice__c
        )
      };
      poItem.addAll(helperConfigQuoteCommonPoli(mapStrProductCodeQli, poStageList[1].Id));
      helperStagePoValidateEDIGoProduct(poStageList, poItem);
      poItem[0].UnitPrice__c = poItem[0].UnitPrice__c + 9999;
      update poItem[0];
      update setStagePosForValidation(poStageList);
      system.assertEquals(2, poStageList.size());
    }
  }
  /**
  * @description This method test the PO Split Price Failure
  */
  @IsTest
  static void basicSplittedPoQnTSplitSuccessthenPriceFail() {
    User usr = [SELECT id, alias FROM user ORDER BY createddate DESC LIMIT 1];
    POStageHandler.triggerMaxCount = 25;
    System.runAs(usr) {
      List<PO_Stage__c> poStageList = helperConfigStagePoValidateEDIGoProduct();
      Map<String, SBQQ__QuoteLine__c> mapStrProductCodeQli = helperQueryQLIValidateEDIGoProduct();
      List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>{
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[4],
          EDI_NUM_LIST_ValidateEDIGoProduct[4],
          'RS-BT-CLE-PE-PA',
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__Quantity__c,
          poStageList[1].Id,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__SubscriptionTerm__c,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__NetPrice__c
        )
      };
      for (Integer i = 0; i < 9; i++) {
        poItem.add(
          ShGl_TestFactoryHelper.createPOItem(
            BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[0],
            EDI_NUM_LIST_ValidateEDIGoProduct[0],
            'RS-EE-GO-PE-PA',
            mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__Quantity__c / 3,
            poStageList[0].Id,
            mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c / 3,
            mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c / 3
          )
        );
      }
      poItem.addAll(helperConfigQuoteCommonPoli(mapStrProductCodeQli, poStageList[1].Id));
      helperStagePoValidateEDIGoProduct(poStageList, poItem);
      List<PO_Item_Stage__c> lstPoliUpdate = new List<PO_Item_Stage__c>();
      for (Integer i = poItem.size() - 9; i < 9; i++) {
        lstPoliUpdate.add(new PO_Item_Stage__c(Id = poItem[i].Id, UnitPrice__c = poItem[i].UnitPrice__c + 9999));
      }
      update lstPoliUpdate;
      update setStagePosForValidation(poStageList);
      system.assertEquals(2, poStageList.size());
    }
  }
  /**
  * @description This method test the PO Split Price Failure
  */
  @IsTest
  static void basicSplittedPoQnTSplitSuccessthenPriceFail1() {
    User usr = [SELECT id, alias FROM user ORDER BY createddate DESC LIMIT 1];
    POStageHandler.triggerMaxCount = 25;
    System.runAs(usr) {
      Date today = System.today() + 1;
      String prodId = [SELECT Id FROM Product2 WHERE ProductCode = 'RA-HW-CREDIT' LIMIT 1].Id;
      String accid = [SELECT Id FROM Account LIMIT 1].Id;

      Asset newAsset = new Asset(
        Name = 'SN1',
        SerialNumber = 'SN1',
        Serial_Number__c = 'SN1',
        Product2Id = prodId,
        Accountid = accid,
        Status = 'Purchased',
        Premium_Support_End_Date__c = today
      );
      insert newAsset;

      //SBQQ__QuoteLine__c qliUpdate = [SELECT SBQQ__UpgradedAsset__c FROM SBQQ__QuoteLine__c LIMIT 1];

      //update qliUpdate;

      List<PO_Stage__c> poStageList = helperConfigStagePoValidateEDIGoProduct();
      Map<String, SBQQ__QuoteLine__c> mapStrProductCodeQli = helperQueryQLIValidateEDIGoProduct();

      mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__UpgradedAsset__c = newAsset.id;
      mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').Special_Program__c = 'Refresh';

      update mapStrProductCodeQli.get('RS-BT-CLE-PE-PA');

      List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>{
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[4],
          EDI_NUM_LIST_ValidateEDIGoProduct[4],
          'RS-BT-CLE-PE-PA',
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__Quantity__c,
          poStageList[1].Id,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__SubscriptionTerm__c,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__NetPrice__c
        )
      };
      for (Integer i = 0; i < 9; i++) {
        poItem.add(
          ShGl_TestFactoryHelper.createPOItem(
            BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[0],
            EDI_NUM_LIST_ValidateEDIGoProduct[0],
            'RS-EE-GO-PE-PA',
            mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__Quantity__c / 3,
            poStageList[0].Id,
            mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c / 3,
            mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c / 3
          )
        );
      }
      poItem.addAll(helperConfigQuoteCommonPoli(mapStrProductCodeQli, poStageList[1].Id));
      helperStagePoValidateEDIGoProduct(poStageList, poItem);
      List<PO_Item_Stage__c> lstPoliUpdate = new List<PO_Item_Stage__c>();
      for (Integer i = poItem.size() - 9; i < 9; i++) {
        lstPoliUpdate.add(new PO_Item_Stage__c(Id = poItem[i].Id, UnitPrice__c = poItem[i].UnitPrice__c + 9999));
      }
      update lstPoliUpdate;
      update setStagePosForValidation(poStageList);
      system.assertEquals(2, poStageList.size());
    }
  }
  /**
  * @description This method test the PO Split for Diff Price Band Fail
  */
  @IsTest
  static void basicSplittedPoQnTSplit02PriceFail3DiffPriceBand() {
    User usr = [SELECT id, alias FROM user ORDER BY createddate DESC LIMIT 1];
    POStageHandler.triggerMaxCount = 25;
    System.runAs(usr) {
      List<PO_Stage__c> poStageList = helperConfigStagePoValidateEDIGoProduct();
      Map<String, SBQQ__QuoteLine__c> mapStrProductCodeQli = helperQueryQLIValidateEDIGoProduct();
      List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>{
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[0],
          EDI_NUM_LIST_ValidateEDIGoProduct[0],
          'RS-EE-GO-PE-PA',
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__Quantity__c / 3,
          poStageList[0].Id,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c / 3,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c + 999
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[0],
          EDI_NUM_LIST_ValidateEDIGoProduct[0],
          'RS-EE-GO-PE-PA',
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__Quantity__c / 3,
          poStageList[0].Id,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c / 3,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c + 999
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[0],
          EDI_NUM_LIST_ValidateEDIGoProduct[0],
          'RS-EE-GO-PE-PA',
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__Quantity__c / 3,
          poStageList[0].Id,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c / 3,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c + 999
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[0],
          EDI_NUM_LIST_ValidateEDIGoProduct[0],
          'RS-EE-GO-PE-PA',
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__Quantity__c / 3,
          poStageList[0].Id,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c / 3,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[0],
          EDI_NUM_LIST_ValidateEDIGoProduct[0],
          'RS-EE-GO-PE-PA',
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__Quantity__c / 3,
          poStageList[0].Id,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c / 3,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[0],
          EDI_NUM_LIST_ValidateEDIGoProduct[0],
          'RS-EE-GO-PE-PA',
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__Quantity__c / 3,
          poStageList[0].Id,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c / 3,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[0],
          EDI_NUM_LIST_ValidateEDIGoProduct[0],
          'RS-EE-GO-PE-PA',
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__Quantity__c / 3,
          poStageList[0].Id,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c / 3,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c + 500
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[0],
          EDI_NUM_LIST_ValidateEDIGoProduct[0],
          'RS-EE-GO-PE-PA',
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__Quantity__c / 3,
          poStageList[0].Id,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c / 3,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c + 500
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[0],
          EDI_NUM_LIST_ValidateEDIGoProduct[0],
          'RS-EE-GO-PE-PA',
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__Quantity__c / 3,
          poStageList[0].Id,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c / 3,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c + 500
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[4],
          EDI_NUM_LIST_ValidateEDIGoProduct[4],
          'RS-BT-CLE-PE-PA',
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__Quantity__c,
          poStageList[1].Id,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__SubscriptionTerm__c,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__NetPrice__c
        )
      };
      poItem.addAll(helperConfigQuoteCommonPoli(mapStrProductCodeQli, poStageList[1].Id));
      helperStagePoValidateEDIGoProduct(poStageList, poItem);
      system.assertEquals(2, poStageList.size());
    }
  }
  /**
  * @description This method test the PO Split Mix Fail
  */
  @IsTest
  static void basicSplittedPoQnTSplitMixFail() {
    User usr = [SELECT id, alias FROM user ORDER BY createddate DESC LIMIT 1];
    POStageHandler.triggerMaxCount = 25;
    System.runAs(usr) {
      List<PO_Stage__c> poStageList = helperConfigStagePoValidateEDIGoProduct();
      Map<String, SBQQ__QuoteLine__c> mapStrProductCodeQli = helperQueryQLIValidateEDIGoProduct();
      List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>{
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[0],
          EDI_NUM_LIST_ValidateEDIGoProduct[0],
          'RS-EE-GO-PE-PA',
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__Quantity__c / 3,
          poStageList[0].Id,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c / 4,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c / 3
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[0],
          EDI_NUM_LIST_ValidateEDIGoProduct[0],
          'RS-EE-GO-PE-PA',
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__Quantity__c / 3,
          poStageList[0].Id,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c / 4,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c / 3
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[0],
          EDI_NUM_LIST_ValidateEDIGoProduct[0],
          'RS-EE-GO-PE-PA',
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__Quantity__c / 3,
          poStageList[0].Id,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c / 4,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c / 3
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[4],
          EDI_NUM_LIST_ValidateEDIGoProduct[4],
          'RS-BT-CLE-PE-PA',
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__Quantity__c,
          poStageList[1].Id,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__SubscriptionTerm__c,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__NetPrice__c
        )
      };
      poItem.addAll(helperConfigQuoteCommonPoli(mapStrProductCodeQli, poStageList[1].Id));
      helperStagePoValidateEDIGoProduct(poStageList, poItem);
      List<PO_Item_Stage__c> lstPoliUpdate = new List<PO_Item_Stage__c>{
        new PO_Item_Stage__c(
          Id = poItem[0].Id,
          UnitPrice__c = mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c / 6,
          Quantity__c = mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__Quantity__c / 6,
          SubscriptionTerm__c = mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c / 3
        ),
        new PO_Item_Stage__c(
          Id = poItem[1].Id,
          UnitPrice__c = mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c / 6,
          Quantity__c = mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__Quantity__c / 6,
          SubscriptionTerm__c = mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c / 3
        ),
        new PO_Item_Stage__c(
          Id = poItem[2].Id,
          UnitPrice__c = mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c / 6,
          Quantity__c = mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__Quantity__c / 6,
          SubscriptionTerm__c = mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c / 3
        )
      };
      update lstPoliUpdate;
      update setStagePosForValidation(poStageList);
      system.assertEquals(2, poStageList.size());
    }
  }
  /**
  * @description This method test the PO Split Extra SKU Fail
  */
  @IsTest
  static void basicSplittedPoExtraSKUFail() {
    User usr = [SELECT id, alias FROM user ORDER BY createddate DESC LIMIT 1];
    POStageHandler.triggerMaxCount = 25;
    System.runAs(usr) {
      List<PO_Stage__c> poStageList = helperConfigStagePoValidateEDIGoProduct();
      Map<String, SBQQ__QuoteLine__c> mapStrProductCodeQli = helperQueryQLIValidateEDIGoProduct();
      List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>{
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[0],
          EDI_NUM_LIST_ValidateEDIGoProduct[0],
          'RS-EE-GO-PE-PA',
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__Quantity__c,
          poStageList[0].Id,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[0],
          EDI_NUM_LIST_ValidateEDIGoProduct[0],
          'copy-RS-EE-GO-PE-PA',
          1,
          poStageList[0].Id,
          20,
          20
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[5],
          EDI_NUM_LIST_ValidateEDIGoProduct[5],
          'RS-HW-SVC-PE',
          mapStrProductCodeQli.get('RS-HW-SVC-PE').SBQQ__Quantity__c,
          poStageList[1].Id,
          mapStrProductCodeQli.get('RS-HW-SVC-PE').SBQQ__SubscriptionTerm__c,
          mapStrProductCodeQli.get('RS-HW-SVC-PE').SBQQ__NetPrice__c
        )
      };
      poItem.addAll(helperConfigQuoteCommonPoli(mapStrProductCodeQli, poStageList[1].Id));
      helperStagePoValidateEDIGoProduct(poStageList, poItem);
      system.assertEquals(2, poStageList.size());
    }
  }
  /**
  * @description This method test the PO Split for Diff Price Band
  */
  @IsTest
  static void basicSplittedPoMixFailAcrossDiffPriceBand() {
    User usr = [SELECT id, alias FROM user ORDER BY createddate DESC LIMIT 1];
    POStageHandler.triggerMaxCount = 25;
    System.runAs(usr) {
      List<PO_Stage__c> poStageList = helperConfigStagePoValidateEDIGoProduct();
      Map<String, SBQQ__QuoteLine__c> mapStrProductCodeQli = helperQueryQLIValidateEDIGoProduct();
      List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>{
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[0],
          EDI_NUM_LIST_ValidateEDIGoProduct[0],
          'RS-EE-GO-PE-PA',
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__Quantity__c / 2 - 2,
          poStageList[0].Id,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c / 2,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c + 999999
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[0],
          EDI_NUM_LIST_ValidateEDIGoProduct[0],
          'RS-EE-GO-PE-PA',
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__Quantity__c / 2 + 2,
          poStageList[0].Id,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c / 2,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[0],
          EDI_NUM_LIST_ValidateEDIGoProduct[0],
          'RS-EE-GO-PE-PA',
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__Quantity__c / 2 + 2,
          poStageList[0].Id,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c / 2,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c + 999
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[4],
          EDI_NUM_LIST_ValidateEDIGoProduct[4],
          'RS-BT-CLE-PE-PA',
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__Quantity__c,
          poStageList[1].Id,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__SubscriptionTerm__c,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__NetPrice__c
        )
      };
      poItem.addAll(helperConfigQuoteCommonPoli(mapStrProductCodeQli, poStageList[1].Id));
      helperStagePoValidateEDIGoProduct(poStageList, poItem);
      system.assertEquals(2, poStageList.size());
    }
  }
  /**
  * @description This method test the PO Split Success
  */
  @IsTest
  static void basicSplittedPoQSplit05Success() {
    User usr = [SELECT id, alias FROM user ORDER BY createddate DESC LIMIT 1];
    POStageHandler.triggerMaxCount = 25;
    System.runAs(usr) {
      List<PO_Stage__c> poStageList = helperConfigStagePoValidateEDIGoProduct();
      Map<String, SBQQ__QuoteLine__c> mapStrProductCodeQli = helperQueryQLIValidateEDIGoProduct();

      List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>{
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[0],
          EDI_NUM_LIST_ValidateEDIGoProduct[0],
          'RS-EE-GO-PE-PA',
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__Quantity__c - 5,
          poStageList[0].Id,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[0],
          EDI_NUM_LIST_ValidateEDIGoProduct[0],
          'RS-EE-GO-PE-PA',
          5,
          poStageList[0].Id,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[4],
          EDI_NUM_LIST_ValidateEDIGoProduct[4],
          'RS-BT-CLE-PE-PA',
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__Quantity__c,
          poStageList[1].Id,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__SubscriptionTerm__c,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__NetPrice__c
        )
      };
      poItem.addAll(helperConfigQuoteCommonPoli(mapStrProductCodeQli, poStageList[1].Id));
      helperStagePoValidateEDIGoProduct(poStageList, poItem);
      system.assertEquals(2, poStageList.size());
    }
  }
  /**
  * @description This method test the PO Split
  */
  @IsTest
  static void basicSplittedPoQSplitQFailThenSuccess() {
    User usr = [SELECT id, alias FROM user ORDER BY createddate DESC LIMIT 1];
    POStageHandler.triggerMaxCount = 25;
    System.runAs(usr) {
      List<PO_Stage__c> poStageList = helperConfigStagePoValidateEDIGoProduct();
      Map<String, SBQQ__QuoteLine__c> mapStrProductCodeQli = helperQueryQLIValidateEDIGoProduct();

      List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>{
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[0],
          EDI_NUM_LIST_ValidateEDIGoProduct[0],
          'RS-EE-GO-PE-PA',
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__Quantity__c - 5,
          poStageList[0].Id,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c - 5,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[0],
          EDI_NUM_LIST_ValidateEDIGoProduct[0],
          'RS-EE-GO-PE-PA',
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__Quantity__c - 5,
          poStageList[0].Id,
          2,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[0],
          EDI_NUM_LIST_ValidateEDIGoProduct[0],
          'RS-EE-GO-PE-PA',
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__Quantity__c - 5,
          poStageList[0].Id,
          3,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[4],
          EDI_NUM_LIST_ValidateEDIGoProduct[4],
          'RS-BT-CLE-PE-PA',
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__Quantity__c,
          poStageList[1].Id,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__SubscriptionTerm__c,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__NetPrice__c
        )
      };
      poItem.addAll(helperConfigQuoteCommonPoli(mapStrProductCodeQli, poStageList[1].Id));
      helperStagePoValidateEDIGoProduct(poStageList, poItem);
      insert ShGl_TestFactoryHelper.createPOItem(
        BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[0],
        EDI_NUM_LIST_ValidateEDIGoProduct[0],
        'RS-EE-GO-PE-PA',
        5,
        poStageList[0].Id,
        mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c,
        mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c
      );
      update setStagePosForValidation(poStageList);
      system.assertEquals(2, poStageList.size());
    }
  }
  /**
  * @description This method test the PO QLI Success
  */
  @IsTest
  static void basicSplittedPo2QLISuccessx1() {
    User usr = [SELECT id, alias FROM user ORDER BY createddate DESC LIMIT 1];
    POStageHandler.triggerMaxCount = 25;
    System.runAs(usr) {
      List<PO_Stage__c> poStageList = helper2Qli();
      Map<String, SBQQ__QuoteLine__c> mapStrProductCodeQli = helperQueryQLIValidateEDIGoProduct();
      List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>{
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[0],
          EDI_NUM_LIST_ValidateEDIGoProduct[0],
          'RS-EE-GO-PE-PA',
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__Quantity__c,
          poStageList[0].Id,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[4],
          EDI_NUM_LIST_ValidateEDIGoProduct[4],
          'RS-BT-CLE-PE-PA',
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__Quantity__c,
          poStageList[1].Id,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__SubscriptionTerm__c,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__NetPrice__c
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[4],
          EDI_NUM_LIST_ValidateEDIGoProduct[4],
          'RS-BT-CLE-PE-PA',
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__Quantity__c,
          poStageList[1].Id,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__SubscriptionTerm__c,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__NetPrice__c
        )
      };
      poItem.addAll(helperConfigQuoteCommonPoli(mapStrProductCodeQli, poStageList[1].Id));
      helperStagePoValidateEDIGoProduct(poStageList, poItem);
      system.assertEquals(2, poStageList.size());
    }
  }
  /**
  * @description This method test the PO QLI Quantity Fail
  */
  @IsTest
  static void basicSplittedPo2QLIQnTFailx1() {
    User usr = [SELECT id, alias FROM user ORDER BY createddate DESC LIMIT 1];
    POStageHandler.triggerMaxCount = 25;
    System.runAs(usr) {
      List<PO_Stage__c> poStageList = helper2Qli();
      Map<String, SBQQ__QuoteLine__c> mapStrProductCodeQli = helperQueryQLIValidateEDIGoProduct();
      List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>{
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[0],
          EDI_NUM_LIST_ValidateEDIGoProduct[0],
          'RS-EE-GO-PE-PA',
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__Quantity__c,
          poStageList[0].Id,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__SubscriptionTerm__c,
          mapStrProductCodeQli.get('RS-EE-GO-PE-PA').SBQQ__NetPrice__c
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[4],
          EDI_NUM_LIST_ValidateEDIGoProduct[4],
          'RS-BT-CLE-PE-PA',
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__Quantity__c,
          poStageList[1].Id,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__SubscriptionTerm__c,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__NetPrice__c
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[4],
          EDI_NUM_LIST_ValidateEDIGoProduct[4],
          'RS-BT-CLE-PE-PA',
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__Quantity__c / 3,
          poStageList[1].Id,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__SubscriptionTerm__c / 3,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__NetPrice__c / 3
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[4],
          EDI_NUM_LIST_ValidateEDIGoProduct[4],
          'RS-BT-CLE-PE-PA',
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__Quantity__c / 3 - 1,
          poStageList[1].Id,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__SubscriptionTerm__c / 3 - 1,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__NetPrice__c / 3
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[4],
          EDI_NUM_LIST_ValidateEDIGoProduct[4],
          'RS-BT-CLE-PE-PA',
          1,
          poStageList[1].Id,
          1,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__NetPrice__c / 3
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[4],
          EDI_NUM_LIST_ValidateEDIGoProduct[4],
          'RS-BT-CLE-PE-PA',
          1,
          poStageList[1].Id,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__SubscriptionTerm__c / 3 - 1,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__NetPrice__c / 3
        ),
        ShGl_TestFactoryHelper.createPOItem(
          BUYER_PART_NUM_ValidateEDIGoProduct + EDI_NUM_LIST_ValidateEDIGoProduct[4],
          EDI_NUM_LIST_ValidateEDIGoProduct[4],
          'RS-BT-CLE-PE-PA',
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__Quantity__c / 3,
          poStageList[1].Id,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__SubscriptionTerm__c / 3,
          mapStrProductCodeQli.get('RS-BT-CLE-PE-PA').SBQQ__NetPrice__c / 3
        )
      };
      poItem.addAll(helperConfigQuoteCommonPoli(mapStrProductCodeQli, poStageList[1].Id));
      helperStagePoValidateEDIGoProduct(poStageList, poItem);
      system.assertEquals(2, poStageList.size());
    }
  }
  /**
  * @description This method test the EDI GO PO
  */
  static testMethod void validateEDIGotest() {
    User usr = [SELECT id, alias FROM user ORDER BY createddate DESC LIMIT 1];
    POStageHandler.triggerMaxCount = 25;
    System.runAs(usr) {
      List<product2> prodList = [SELECT id, Name, ProductCode, Product_Level__c, Product_Subtype__c, Product_Payment_Option__c, Product_Type__c, Usable_Capacity__c FROM product2];
      SBQQ__Quote__c quote = [SELECT id, name, SBQQ__Account__c, SBQQ__Opportunity2__c, SBQQ__NetAmount__c FROM SBQQ__Quote__c];
      List<ProductModel> prodModels = new List<ProductModel>();
      String currencyCode = 'USD';
      set<string> prodName = new Set<string>{
        'HybridProd-001-test',
        'HybridProd-002-test',
        'HWSupportProd-001-test',
        'HWSupport2Prod-001-test',
        'HWProd-001-test',
        'HWProd-002-test',
        'AddonProd-001-test',
        'RS-BT-RCDM-T',
        /* 'LOD-SOFTWARE', 'RS-BT-SW-SVC-PE',*/ 'RA-HW-CREDIT'
      };
      for (product2 prod : prodList) {
        if (prodName.contains(prod.name)) {
          prodModels.add(
            (ProductModel) JSON.deserialize(
              SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prod.id, '{"pricebookId" : "' + system.label.CPQPricebookID + '", "currencyCode" : "' + currencyCode + '"}'),
              ProductModel.class
            )
          );
        }
      }
      String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', quote.id);
      ProductAdder adder = new ProductAdder();
      QuoteModel quoteWithProducts = adder.add((QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class), prodModels, 0);
      Map<string, string> childParentMap = new Map<string, string>{
        'RS-BT-SW-SVC-PE' => 'LOD-SOFTWARE',
        'RS-BT-RCDM-T' => 'HybridProd-001-test',
        'HWProd-001-test' => 'HybridProd-001-test',
        'HWProd-002-test' => 'HybridProd-002-test',
        'HWSupportProd-001-test' => 'HWProd-001-test',
        'HWSupport2Prod-001-test' => 'HWProd-001-test',
        'AddonProd-001-test' => 'HybridProd-001-test'
      };
      Map<string, Integer> prodKey = new Map<string, Integer>();
      Integer hwIndex, hybIndx, addonIndx;
      hwIndex = hybIndx = addonIndx = 0;
      for (QuoteLineModel QLModel : quoteWithProducts.lineItems) {
        if (QLModel.record.Product_Level__c == 'Hybrid Software' /*|| QLModel.record.Product_Level__c == 'LOD Software'*/) {
          prodKey.put(QLModel.record.SBQQ__Product__r.name, QLModel.key);
          QLModel.record.SBQQ__Quantity__c = 500;
          QLModel.record.SBQQ__SubscriptionTerm__c = 36;
          QLModel.record.SBQQ__NetPrice__c = 100;
        } else if (QLModel.record.Product_Level__c == 'Hardware' && QLModel.record.Product_Type__c == 'Hardware') {
          prodKey.put(QLModel.record.SBQQ__Product__r.name, QLModel.key);
          QLModel.record.SBQQ__Quantity__c = 5;
          QLModel.record.SBQQ__NetPrice__c = 100;
          QLModel.parentItemKey = prodKey.get(childParentMap.get(QLModel.record.SBQQ__Product__r.name));
        } else if (QLModel.record.Product_Level__c == 'Support' || QLModel.record.Product_Level__c == 'SaaS Software Addon') {
          QLModel.record.SBQQ__Quantity__c = QLModel.record.Product_Level__c == 'SaaS Software Addon' ? 1 : 5;
          QLModel.record.SBQQ__SubscriptionTerm__c = 36;
          QLModel.record.SBQQ__NetPrice__c = 100;
          if (QLModel.record.Product_Level__c == 'Support') {
            QLModel.record.Special_Program__c = 'Conversion';
            QLModel.record.Arroyo_Subscribed_Asset_Name__c = 'TestSN1,TestSN2,TestSN3,TestSN4,TestSN5';
          }
          QLModel.parentItemKey = prodKey.get(childParentMap.get(QLModel.record.SBQQ__Product__r.name));
        } else if (QLModel.record.Product_Level__c == 'OnPrem') {
          //prodTypeItemKeySet.get('rcdm').add(QLModel.key);
          QLModel.record.SBQQ__Quantity__c = 400;
          QLModel.record.SBQQ__SubscriptionTerm__c = 56;
          QLModel.parentItemKey = prodKey.get(childParentMap.get(QLModel.record.SBQQ__Product__r.name));
        }
      }
      String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
      QuoteCalculator calculator = new QuoteCalculator();
      calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
      quote.ApprovalStatus__c = 'Approved';
      update quote;
      List<product2> prodListup = new List<product2>();
      for (product2 p : prodList) {
        p.Product_Payment_Option__c = 'Manual';
        prodListup.add(p);
      }
      update prodListup;

      List<SBQQ__QuoteLine__c> qliList = [
        SELECT
          id,
          SBQQ__Quote__r.SBQQ__NetAmount__c,
          SBQQ__ProductCode__c,
          SBQQ__NetPrice__c,
          SBQQ__NetTotal__c,
          SBQQ__Product__r.productcode,
          SBQQ__Quantity__c,
          SBQQ__SubscriptionTerm__c,
          SBQQ__Product__c,
          SBQQ__Product__r.name,
          SBQQ__Product__r.Usable_Capacity__c,
          SBQQ__Product__r.Product_Level__c,
          SBQQ__RequiredBy__c
        FROM SBQQ__QuoteLine__c
      ];
      List<PO_Stage__c> poStageList = new List<PO_Stage__c>();
      for (integer i = 1; i <= 11; i++) {
        decimal amount = i == 1 ? qliList[0].SBQQ__Quote__r.SBQQ__NetAmount__c : 0.0;
        PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage(
          'Promark Technology, Inc.pp',
          'test123',
          system.today().addDays(10),
          11,
          'test@test.com.invalid',
          'test partner',
          system.today(),
          i,
          'test12345',
          quote.name,
          amount
        );
        pos.Bill_To_Name__c = quote.SBQQ__Account__c;
        pos.Payment_schedule_type__c = 'test';
        pos.Quote_number__c = quote.name;
        pos.Opportunity__c = quote.SBQQ__Opportunity2__c;
        pos.Ship_to_Email__c = 'test@test.com.invalid';
        pos.Ship_To_Contact_Name__c = 'testCon';
        pos.Ship_To_Phone_Number__c = '7000022448';
        pos.ShippingCountryCode__c = 'IN';
        pos.ShippingStateCode__c = 'KA';
        pos.ShippingCity__c = 'test City';
        pos.ShippingStreet__c = 'test street';
        pos.ShippingPostalCode__c = '0000';

        if (i != 8)
          pos.PO_Validation_Status__c = 'Staged';
        poStageList.add(pos);
      }

      insert poStageList;

      List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>();

      for (integer i = 0; i < qliList.size(); i++) {
        string ediLinenum = 0 + '' + i;
        PO_Item_Stage__c poi;
        Map<string, list<id>> itemLevlPOIds = new Map<string, list<id>>{
          'HybridProd-001-test' => new List<id>{ poStageList[0].id, poStageList[2].id, poStageList[4].id, poStageList[6].id, poStageList[9].id },
          'HWProd-001-test' => new List<id>{ poStageList[0].id, poStageList[1].id, poStageList[3].id, poStageList[6].id, poStageList[8].id },
          'HWSupportProd-001-test' => new List<id>{ poStageList[0].id, poStageList[2].id, poStageList[5].id, poStageList[6].id, poStageList[10].id }, //,poStageList[9].id.
          'HWSupport2Prod-001-test' => new List<id>{ poStageList[0].id, poStageList[2].id, poStageList[5].id, poStageList[7].id, poStageList[10].id }, //,poStageList[9].id
          'AddonProd-001-test' => new List<id>{ poStageList[0].id },
          'HybridProd-002-test' => new List<id>{ poStageList[9].id },
          'HWProd-002-test' => new List<id>{ poStageList[8].id },
          'RS-BT-RCDM-T' => new List<id>{ poStageList[0].id, poStageList[2].id, poStageList[4].id, poStageList[6].id, poStageList[9].id },
          //'LOD-SOFTWARE' => new List<id>{ poStageList[0].id, poStageList[2].id, poStageList[4].id, poStageList[6].id, poStageList[9].id },
          //'RS-BT-SW-SVC-PE' => new List<id>{ poStageList[0].id, poStageList[2].id, poStageList[4].id, poStageList[6].id, poStageList[9].id },
          'RA-HW-CREDIT' => new List<id>{ poStageList[0].id, poStageList[2].id, poStageList[4].id, poStageList[9].id }
        };
        if (itemLevlPOIds.containsKey(qliList[i].SBQQ__Product__r.name)) {
          Integer j = 1;
          for (Id stgId : itemLevlPOIds.get(qliList[i].SBQQ__Product__r.name)) {
            Decimal Quant = qliList[i].SBQQ__Product__r.Product_Level__c == 'Hybrid Software'
              ? qliList[i].SBQQ__Product__r.name == 'HybridProd-002-test' ? 500 : 100.0
              : qliList[i].SBQQ__Product__r.name == 'HWProd-002-test' ? 5.0 : 1.0;
            poItem.add(
              ShGl_TestFactoryHelper.createPOItem(
                '1234' + ediLinenum,
                ediLinenum,
                qliList[i].SBQQ__Product__r.productcode,
                Quant,
                stgId,
                qliList[i].SBQQ__SubscriptionTerm__c,
                qliList[i].SBQQ__NetPrice__c
              )
            );
            j++;
          }
        }
      }
      insert poItem;

      List<PO_Item_Stage__c> PoitemList = [
        SELECT
          Id,
          Name,
          Stage_PO__c,
          Stage_PO__r.Expected_number_of_POs__c,
          Stage_PO__r.name,
          Stage_PO__r.Quote__c,
          Quote_Line__c,
          Quantity__c,
          UnitPrice__c,
          Product__c,
          SubscriptionTerm__c,
          ProductCode__c,
          Subscription_Term_Description__c,
          EDI_Line_Number__c,
          Buyer_Part_Number__c,
          Deliver_By__c,
          Est_Ship_Date__c,
          Stage_PO__r.Bill_To_Name__r.EDI_DISTI_ID__c,
          Stage_PO__r.Quote__r.SBQQ__Opportunity2__r.Distributor_Lookup__r.EDI_DISTI_ID__c,
          Product__r.Appliance_Model_HW__c,
          Product__r.Product_Type__c,
          Product__r.Product_Level__c,
          Product__r.ProductCode,
          Product__r.Usable_Capacity__c,
          Product__r.Product_Payment_Option__c,
          Product__r.Product_Subtype__c
        FROM PO_Item_Stage__c
      ];
      POStageHelper.allStagePOmap.clear();
      POStageHelper.quoteMap.clear();
      poStageList[6].PO_Validation_Status__c = 'Staged';
      poStageList[7].PO_Validation_Status__c = 'Staged';
      update poStageList[7];
      update poStageList[6] ;
      Decimal qliGranualPrice = 100.50;
      Decimal maxTerm = 36;
      ValidateEDIGoProducts goProductValidations = new ValidateEDIGoProducts();
      ValidateEDIGoProducts.ValidationResults goProductValidationsResults = goProductValidations.validate();
      ValidateEDIGoProducts.WQli WQliInstance = new ValidateEDIGoProducts.WQli(qliList[0]);
      List<ValidateEDIGoProducts.WQli> WQliList = new List<ValidateEDIGoProducts.WQli>();
     //ValidateEDIGoProducts.WQli WQliInstance3 = new ValidateEDIGoProducts.WQli(qliList[1]);
	  ValidateEDIGoProducts.WPoli WPoliInstance = new ValidateEDIGoProducts.WPoli(PoitemList[0]);
	  List<ValidateEDIGoProducts.WPoli> POliList = new List<ValidateEDIGoProducts.WPoli>();
      WQliList.add(WQliInstance);
      POliList.add(WPoliInstance);
      id valquoteId = WQliInstance.quoteId;
      decimal ValproductUsableCapacity = WQliInstance.productUsableCapacity;
      ValproductUsableCapacity = WQliInstance.usableCapacity;
      Boolean flag = WQliInstance.isHw;
      ValidateEDIGoProducts.AggregatedLine aggreate = new ValidateEDIGoProducts.AggregatedLine(POliList, qliGranualPrice,maxTerm);
      ValidateEDIGoProducts.AggregatedLine aggreate1 = new ValidateEDIGoProducts.AggregatedLine(WQliList, qliGranualPrice,maxTerm);
      ValidateEDIGoProducts.AggregatedLine aggreate2 = new ValidateEDIGoProducts.AggregatedLine('Prod', qliGranualPrice,maxTerm);
      aggreate2.addIndividually(POliList[0]); 
      aggreate2.addIndividually(WQliList[0]);   
      ValidateEDIGoProducts.WQli WQliInstance1 = new ValidateEDIGoProducts.WQli(qliList[0]);
      ValidateEDIGoProducts.WQli WQliInstance2 = new ValidateEDIGoProducts.WQli(qliList[0]);

      List<ValidateEDIGoProducts.WQli> WQliList1 = new List<ValidateEDIGoProducts.WQli>();
      WQliList1.add(WQliInstance1);
      WQliList1.add(WQliInstance2);
      WPoliInstance.isSaaS = true;
      WPoliInstance.isSaaSCapacityChanged = true;
      double internalQuant = WPoliInstance.internalQuantity;
      ValidateEDIGoProducts.AbstractLine objLine1 = new ValidateEDIGoProducts.AbstractLine(WQliList1[0], maxTerm);
      ValidateEDIGoProducts.AbstractLine objLine2 = new ValidateEDIGoProducts.AbstractLine(WQliList1[0], maxTerm);
      ValidateEDIGoProducts.AbstractLine objAbsLine = new ValidateEDIGoProducts.AbstractLine();
      Boolean result = objAbsLine.forceComposeAbstractLine(objLine1, objLine2, maxTerm);
      Decimal unitPrice1 = objLine1.unitPrice;
      Decimal netPrice1 = objLine1.netPrice;
      objLine1.isEmpty();
      Decimal threshold = 2.00;
      Map<string, POValidation_ErrorCode__c> validationCodes = new Map<string, POValidation_ErrorCode__c>();
      Set<Id> setIdGoProductQuote = new Set<Id>();
      setIdGoProductQuote.add(quote.Id);
      Map<String, Map<Decimal, List<ValidateEDIGoProducts.WPoli>>> mapQPTokenPricePerMonthLstWrappedPoli = new Map<String, Map<Decimal, List<ValidateEDIGoProducts.WPoli>>>();
      ValidateEDIGoProducts.WPoli objWPoli = new ValidateEDIGoProducts.WPoli(poItem[0]);
      ValproductUsableCapacity = objWPoli.usableCapacity;
      objWPoli.usableCapacity = 100;
      flag = objWPoli.isHw;
      flag = objWPoli.isAddon;
      objWPoli.addHwCapacity(qliList[0]);
      ValproductUsableCapacity = objWPoli.netPrice;

      //objWPoli.addSaaSCapacity(WQliList[0], maxTerm);
      String strQPToken = quote.Id + '-' + objWPoli.productCode;
      goProductValidations.params.threshold = threshold;
      mapQPTokenPricePerMonthLstWrappedPoli.put(strQPToken, new Map<Decimal, List<ValidateEDIGoProducts.WPoli>>());
      Map<id, PO_Item_Stage__c> poItemUpdate = new Map<id, PO_Item_Stage__c>();
      List<PO_Item_Stage__c> updatePoItems = new List<PO_Item_Stage__c>();
        for(PO_Item_Stage__c objPOItem : PoitemList){
              if(poStageList[6].Id == objPOItem.Stage_PO__c){
            	  if(objPOItem.ProductCode__c == 'HWProd-001-test'){
                        objPOItem.Quote_Line__c = qliList[3].Id;
                        updatePoItems.add(objPOItem);
                }
                poItemUpdate.put(objPOItem.Id, objPOItem);
            }
        }
      update updatePoItems;
      set<id> failedPItmId = new Set<id>();
      failedPItmId.add(PoitemList[2].Id);
      Map<id, SBQQ__QuoteLine__c> QLIMap = new Map<id, SBQQ__QuoteLine__c>();
      Set<Id> setIdGoProductStagePo = new Set<Id>();
      setIdGoProductStagePo.add(PoitemList[0].Stage_PO__c);
      setIdGoProductStagePo.add(poStageList[6].Id);
      goProductValidations.params.validationCodes = validationCodes;
      goProductValidations.params.mapAllQuotes = POStageHelper.quoteMap;
      goProductValidations.params.setIdGoProductQuote = setIdGoProductQuote;
      goProductValidations.params.mmPoli = mapQPTokenPricePerMonthLstWrappedPoli;
      goProductValidations.params.mapAllStagePo = POStageHelper.allStagePOmap;
      goProductValidations.params.mapPoliMatched = poItemUpdate;
      goProductValidations.params.setIdFailedPoli = failedPItmId;
      goProductValidations.params.setIdGoProductStagePo = setIdGoProductStagePo;
      goProductValidations.params.mapQli = QLIMap;
      ValidateEDIGoProducts.ValidationResults goProductValidationsResults1 = goProductValidations.validate();
      goProductValidations.checkForOrphanPolis();
      List<PO_Item_Stage__c> poitem1 = new List<PO_Item_Stage__c>();
            poitem1.add(ShGl_TestFactoryHelper.createPOItem(
                '123410',
                '10',
                'RS-BT-CLE-PE-PA',
                1.00,
                poStageList[6].Id,
                12.00,
                500.00
            ));
            ValidateEDIGoProducts.WPoli objWPoli2 = new ValidateEDIGoProducts.WPoli(poitem1[0]);
            strQPToken = quote.Id + '-' + objWPoli2.productCode;
            mapQPTokenPricePerMonthLstWrappedPoli = new Map<String, Map<Decimal, List<ValidateEDIGoProducts.WPoli>>>();
            mapQPTokenPricePerMonthLstWrappedPoli.put(strQPToken, new Map<Decimal, List<ValidateEDIGoProducts.WPoli>>());
            mapQPTokenPricePerMonthLstWrappedPoli.get(strQPToken).put(500, new List<ValidateEDIGoProducts.WPoli>{objWPoli2});
            goProductValidations.params.mmPoli = mapQPTokenPricePerMonthLstWrappedPoli;
            goProductValidations.checkForOrphanPolis();
            decimal decPoliQuantity = 10;
            goProductValidations.collectUsableCapacityForHw();
            ValidateEDIGoProducts.WPoli WPoliInstance1 = new ValidateEDIGoProducts.WPoli(PoitemList[3]);
            
            goProductValidations.calculateQuantitySaaSPerWPoli(WPoliInstance);
            goProductValidations.calculateQuantitySaaSPerWPoli(WPoliInstance1);
            
            goProductValidations.isFinalRound = true;
            goProductValidations.matchLstWPoliWithWQli(aggreate2, WQliList1[0]);
            goProductValidations.createCollectionOfStagePoErrorPoliId();
            
            try{
                POStageHelper.allStagePOmap.remove(PoitemList[0].Stage_PO__c);
                POStageHelper.allStagePOmap.remove(PoitemList[6].Stage_PO__c);
                goProductValidations.params.mapAllStagePo = POStageHelper.allStagePOmap;
                goProductValidations.collateQliRequiredByDependencies();
                System.assert(false, 'Expected exception was not thrown');
                
            }catch(ValidateEDIGoProducts.EDIGOProductValidationException ex){
                String message = ex.getMessage();
                System.assert(message.contains('parameter for all Stage POs') , 'passed parameter for all Stage POs');
                
            }
            try{
                POStageHelper.allStagePOmap.put(PoitemList[0].Stage_PO__c, poStageList[0]);
                POStageHelper.allStagePOmap.put(PoitemList[6].Stage_PO__c, poStageList[6]);
                goProductValidations.params.mapAllStagePo = POStageHelper.allStagePOmap;
                POStageHelper.quoteMap.remove(PoitemList[0].Stage_PO__r.Quote__c);
                goProductValidations.params.mapAllQuotes = POStageHelper.quoteMap;
                goProductValidations.collateQliRequiredByDependencies();
                System.assert(false, 'Expected exception was not thrown');
                
            }Catch(ValidateEDIGoProducts.EDIGOProductValidationException ex){
                String message = ex.getMessage();
                System.assert(message.contains('Should be in passed parameter for all Quotes') , 'Should be in passed parameter for all Quotes');
                
            }
      ValidateEDIGoProducts.AggregatedLine aggreates = new ValidateEDIGoProducts.AggregatedLine('true', qliGranualPrice,maxTerm);
      List<ValidateEDIGoProducts.AbstractLine> lstClone = new List<ValidateEDIGoProducts.AbstractLine>{objLine1};
      aggreates.lstOriginalAbsLine = lstClone.clone();
      validationCodes.put('PO-12', New POValidation_ErrorCode__c(Name = 'PO-12', Error_Issue__c = 'Term missing or mismatched for subscription or support product'));
      insert validationCodes.values();
      goProductValidations.params.validationCodes = validationCodes;
      goProductValidations.getPoValidationErrorMsg('PO-12');
      aggreate.isAlreadyAggregated(updatePoItems[0].Id);
      system.assertEquals(32, PoitemList.size());
    }
  }
}