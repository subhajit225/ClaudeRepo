/******************************************************************************
* @description       : This Class has all the default values
* @author            : Ankit Gupta
* @last modified on  : 02-26-2026
* @last modified by  : Harshit Garg
* Modifications Log
* Ver   Date          Author           Modification
* 1.0   11-10-2025    Ankit Gupta      Initial Version
******************************************************************************/
public with sharing class TestDataFactoryDefaults {

  public static final Id pricebookId = Test.getStandardPricebookId();

  /**
   * @description This method generate any type of SObjects with common and indexed fields
   * @param count
   * @param sObjectType
   * @param commonFields
   * @param indexedFields
   * @return List<SObject>
   */
  public static List<SObject> generateSObjects(
      Integer count,
      String sObjectType,
      Map<String, Object> commonFields,
      Map<String, List<Object>> indexedFields
  ) {
      List<SObject> sObjectList = new List<SObject>();
      Map<String, Object> defaultFields = getDefaultFields(sObjectType);

      if (commonFields != null && !commonFields.isEmpty()) {
          defaultFields.putAll(commonFields);
      }

      for (Integer i = 0; i < count; i++) {
          SObject record = (SObject) Type.forName('Schema.' + sObjectType).newInstance();
          // Add common fields (same for all)
          if (defaultFields != null) {
              for (String fieldName : defaultFields.keySet()) {
                  record.put(fieldName, defaultFields.get(fieldName));
              }
          }
          // Add indexed fields (unique per record)
          if (indexedFields != null) {
              for (String fieldName : indexedFields.keySet()) {
                  List<Object> fieldValues = indexedFields.get(fieldName);
                  if (fieldValues != null && i < fieldValues.size()) {
                      record.put(fieldName, fieldValues[i]);
                  }
              }
          }

          // Add to the list
          sObjectList.add(record);
      }

      return sObjectList;
  }


  // User Common Fields
  public static final Map<String, Object> mapUserCommonFields = new Map<String, Object>{
      'EmailEncodingKey' => 'UTF-8',
      'LanguageLocaleKey' => 'en_US',
      'LocaleSidKey' => 'en_US',
      'TimeZoneSidKey' => 'America/Los_Angeles'
  };

  // Account Common Fields
  public static final Map<String, Object> mapAccountCommonFields = new Map<String, Object>{
      'Name' => 'Test Account'
  };

  // Contact Common Fields
  public static final Map<String, Object> mapContactCommonFields = new Map<String, Object>{
      'FirstName' => 'John',
      'LastName' => 'Doe',
      'Email' => 'john.doe@test.com.sandbox'
  };

  // Opportunity Common Fields
  public static final Map<String, Object> mapOpportunityCommonFields = new Map<String, Object>{
      'StageName' => '1 Discovery',
      'CloseDate' => System.Today().addDays(30),
      'Name' => 'Test Opportunity',
      'Pricebook2Id' => pricebookId
  };

  // Deal Registration Common Fields
  public static final Map<String, Object> mapDealRegistrationCommonFields = new Map<String, Object>{
      'FirstName__c' => 'Test',
      'LastName__c' => 'Lead',
      'Phone__c' => '123456789',
      'Company__c' => 'REdSky',
      'Email__c' => 'Test@redsky.com.sandbox',
      'Title__c' => 'Sr.Dev',
      'Purchase_Timeframe__c' => 'N/A',
      'Street__c' => 'Street',
      'StateCode__c' => 'AK',
      'PostalCode__c' => '421302',
      'City__c' => 'City',
      'Country__c' => 'United States',
      'Partner__c' => 'Rubrik',
      'Partner_Rep__c' => 'Rep Name',
      'Partner_Rep_Phone_Number__c' => '1234567890',
      'Partner_Rep_Email_Address__c' => 'partner@redsky.com.sandbox',
      'Secondary_Email_for_Deal_Reg__c' => 'partner@redsky.com.sandbox'
  };

  // Partner Page Configuration Common Fields
  public static final Map<String, Object> mapPartnerPageConfigCommonFields = new Map<String, Object>{
      'Name' => 'Menu config',
      'Page_Name__c' => 'Home'
  };

  // Partner Fund Request Common Fields
  public static final Map<String, Object> mapPartnerFundRequestCommonFields = new Map<String, Object>{
      'Title' => 'Test PFR',
      'Requested_Amount__c' => 100,
      'RequestedAmount' => 100
  };

  // Partner Fund Claim Common Fields
  public static final Map<String, Object> mapPartnerFundClaimCommonFields = new Map<String, Object>{
      'Title' => 'Test',
      'Amount' => 100,
      'Description' => 'Test'
  };

  // Incentives Common Fields
  public static final Map<String, Object> mapIncentivesCommonFields = new Map<String, Object>{
      'Name' => 'Test Incentive'
  };

  // Territory2 Common Fields
  public static final Map<String, Object> mapTerritory2CommonFields = new Map<String, Object>{
      'Name' => 'CDM-'
  };

  // Lead Common Fields
  public static final Map<String, Object> mapLeadCommonFields = new Map<String, Object>{
      'FirstName' => 'Test',
      'LastName' => 'Lead',
      'Phone' => '123456789',
      'Company' => 'REdSky',
      'Email' => 'Test@redsky.com.sandbox',
      'Title' => 'Sr.Dev',
      'LeadSource' => 'E-mail'
  };

  // Patch Manager Common Fields
  public static final Map<String, Object> mapPatchManagerCommonFields = new Map<String, Object>{
      'CountryGlobal__c' => 'United States',
      'City__c' => 'City',
      'State__c' => 'AK',
      'StateGlobal__c' => 'AK',
      'Zip_code__c' => '421302'
  };

  // Partner Fund Allocation Common Fields
  public static final Map<String, Object> mapPartnerFundAllocationCommonFields = new Map<String, Object>{
      'Title' => 'Test Fund Allocation',
      'Amount' => 1000
  };

  // Content Version Common Fields
  public static final Map<String, Object> mapContentVersionCommonFields = new Map<String, Object>{
      'Title' => 'Test Content',
      'VersionData' => Blob.valueOf('Test Content'),
      'IsMajorVersion' => true
  };

  // Content Document Link Common Fields
  public static final Map<String, Object> mapContentDocumentLinkCommonFields = new Map<String, Object>{
      'ShareType' => 'V',
      'Visibility' => 'AllUsers'
  };

  // Case Common Fields
  public static final Map<String, Object> mapCaseCommonFields = new Map<String, Object>{
      'Status' => 'New',
      'Origin' => 'Partner Portal',
      'Priority' => 'Medium',
      'Type' => 'Software'
  };

  // MIP Contract Common Fields
  public static final Map<String, Object> mapMIPContractCommonFields = new Map<String, Object>{
      'Start_Date__c' => System.today(),
      'End_Date__c' => System.today()
  };

  // Partner Marketing Budget Common Fields
  public static final Map<String, Object> mapPartnerMarketingBudgetCommonFields = new Map<String, Object>{
      'Title' => 'test',
      'StartDate' => System.today(),
      'EndDate' => System.today()+1,
      'IsIgnoreValidation' => true,
      'Amount' => 1000
  };

  // Partner Registration Request Common Fields
  public static final Map<String, Object> mapPartnerRegistrationRequestCommonFields = new Map<String, Object>{
      'First_Name__c' => 'Test Firstname',
      'Last_Name__c' => 'Test Lastname',
      'Email__c' => 'abc@gmail.com.sandbox',
      'Company_Name__c' => 'TestCompany'
  };
  
  // Partner Onboarding Request Common Fields
  public static final Map<String, Object> mapPartnerOnboardingRequestCommonFields = new Map<String, Object>{
      'Address_1__c' => 'test address',
      'Address_2__c' => 'test address2',
      'Partner_Onboarding_Status__c' => 'Pending',
      'First_Name__c' => 'Test',
	  'Last_Name__c' => 'User',
	  'Title__c' => 'Administrator',
	  'Phone__c' => '555-0000',
	  'Country__c' => 'United States', 
      'City__c' => 'Test City',
	  'Postal_Code__c' => '12345'
  };
  
  
  //Marketing

  // OpportunitySplitMapping__c Common Fields
  public static final Map<String, Object> mapOpportunitySplitMappingCommonFields = new Map<String, Object>{
      'Skip_Update_if_child_has_value__c' => false
  };

  // Order Common Fields
  public static final Map<String, Object> mapOrderCommonFields = new Map<String, Object>{
      'Status' => 'Draft',
      'EffectiveDate' => Date.today(),
      'Polaris_Fulfillment_Status__c' => 'Completed',
      'Pricebook2Id' => pricebookId
  };

  // OpportunityLineItem Common Fields
  public static final Map<String, Object> mapOpportunityLineItemCommonFields = new Map<String, Object>{
      'TotalPrice' => 2000,
      'Quantity' => 2,
      'Description' => 'Test'
  };

  // PriceBook2 Common Fields
  public static final Map<String, Object> mapPriceBook2CommonFields = new Map<String, Object>{
      'Name' => 'V68_2017_08_09_12_26_43'
  };

  // SBQQ__Quote__c Common Fields
  public static final Map<String, Object> mapSBQQQuoteCommonFields = new Map<String, Object>{
      'SBQQ__PriceBook__c' => pricebookId,
      'SBQQ__Primary__c' => true,
      'SBQQ__SubscriptionTerm__c' => 12,
      'SBQQ__StartDate__c' => Date.Today()
  };

  // ServiceContract Common Fields
  public static final Map<String, Object> mapServiceContractCommonFields = new Map<String, Object>{
      'Name' => 'Test Contract',
      'StartDate' => System.today(),
      'Pricebook2Id' => pricebookId
  };

  // CCR__c Common Fields
  public static final Map<String, Object> mapCCRCommonFields = new Map<String, Object>{
      'Comment__c' => 'test',
      'Amount__c' => 100.00
  };

  // PriceBookEntry Common Fields
  public static final Map<String, Object> mapPriceBookEntryCommonFields = new Map<String, Object>{
      'Pricebook2Id' => pricebookId,
      'IsActive' => true,
      'UnitPrice' => 100.0
  };

  // Product2 Common Fields
  public static final Map<String, Object> mapProduct2CommonFields = new Map<String, Object>{
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

  // ObjectTerritory2Association Common Fields
  public static final Map<String, Object> mapObjectTerritory2AssociationCommonFields = new Map<String, Object>{
      'AssociationCause' => 'Territory2Manual'
  };

  // ContractLineItem Common Fields
  public static final Map<String, Object> mapContractLineItemCommonFields = new Map<String, Object>{
      'Quantity' => 1,
      'UnitPrice' => 100
  };

  // Asset Common Fields
  public static final Map<String, Object> mapAssetCommonFields = new Map<String, Object>{
      'Name' => 'SN12345',
      'SerialNumber' => 'SN12345',
      'Serial_Number__c' => 'SN12345',
      'SW_Version__c' => '0.1'
  };

  // Campaign Common Fields
  public static final Map<String, Object> mapCampaignCommonFields = new Map<String, Object>{
      'Name' => 'Test Campaign',
      'IsActive' => true,
      'StartDate' => System.today(),
      'EndDate' => System.today().addDays(30),
      'Campaign_Sales_Theatre__c' => 'AMER',
      'Campaign_Sales_Area__c' => 'AMER',
      'Executed_By__c' => 'Partner Marketing',
      'Alliance_Partner__c' => 'None',
      'Campaign_Sales_Region__c' => 'AMER',
      'Campaign_Theme__c' => 'Security',
      'GTM_Play__c' => 'General Security'
  };

  /**
   * @description This method is used to get the default field mappings for partner-related sObjects
   * @param sObjectType
   * @return Map<String, Object>
   */
  public static Map<String, Object> getDefaultFields(String sObjectType) {
      if (String.isBlank(sObjectType)) {
          return new Map<String, Object>();
      }

      switch on sObjectType.toLowerCase() {
          //Partner
          when 'user'                                 { return mapUserCommonFields; }
          when 'account'                              { return mapAccountCommonFields; }
          when 'contact'                              { return mapContactCommonFields; }
          when 'opportunity'                          { return mapOpportunityCommonFields; }
          when 'deal_registration__c'                 { return mapDealRegistrationCommonFields; }
          when 'partner_page_configuration__c'        { return mapPartnerPageConfigCommonFields; }
          when 'patchmanager__c'                      { return mapPatchManagerCommonFields; }
          when 'incentives__c'                        { return mapIncentivesCommonFields; }
          when 'lead'                                 { return mapLeadCommonFields; }
          when 'partnerfundrequest'                   { return mapPartnerFundRequestCommonFields; }
          when 'territory2'                           { return mapTerritory2CommonFields; }
          when 'mip_contract__c'                      { return mapMIPContractCommonFields; }
          when 'partnermarketingbudget'               { return mapPartnerMarketingBudgetCommonFields; }
          when 'partnerfundallocation'                { return mapPartnerFundAllocationCommonFields; }
          when 'partner_registration_request__c'      { return mapPartnerRegistrationRequestCommonFields; }
          when 'case'                                 { return mapCaseCommonFields; }
          when 'contentversion'                       { return mapContentVersionCommonFields; }
		  when 'partner_onboarding_request__c'        { return mapPartnerOnboardingRequestCommonFields; }
          when 'contentdocumentlink'                  { return mapContentDocumentLinkCommonFields; }
          when 'campaign'                             { return mapCampaignCommonFields; }
          when 'partnerfundclaim'                     { return mapPartnerFundClaimCommonFields; }

          //Marketing
          when 'opportunitysplitmapping__c'           { return mapOpportunitySplitMappingCommonFields; }
          when 'order'                                { return mapOrderCommonFields; }
          when 'opportunitylineitem'                  { return mapOpportunityLineItemCommonFields; }
          when 'pricebook2'                           { return mapPriceBook2CommonFields; }
          when 'sbqq__quote__c'                       { return mapSBQQQuoteCommonFields; }
          when 'servicecontract'                      { return mapServiceContractCommonFields; } 
          when 'ccr__c'                               { return mapCCRCommonFields; }
          when 'pricebookentry'                       { return mapPriceBookEntryCommonFields; }
          when 'product2'                             { return mapProduct2CommonFields; }
          when 'objectterritory2association'          { return mapObjectTerritory2AssociationCommonFields; }
          when 'contractlineitem'                     { return mapContractLineItemCommonFields; }
          when 'asset'                                { return mapAssetCommonFields; }
          when else                                   { return new Map<String, Object>(); }
      }
  }
}