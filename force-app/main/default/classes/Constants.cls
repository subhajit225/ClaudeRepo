/*******************************************************************************************************************
 * @description       : static variables are used in trigger/classes
 * @last modified on  : 06-19-2025
 * @last modified by  : Shrutika
 ********************************************************************************************************************/
public class Constants {
  public static final String ONDEMAND_OPPORTUNITY_TEXT = 'OnDemand Opportunity';
  public static final String ON_DEMAND_OPPORTUINITY_STAGENAME = '6 PO With Channel';
  public static final String MSP_CONSUMPTION_RENEWAL  = 'MSP Consumption Renewal';
  public static final String PRODUCT_TYPE_EDITION_UPGRADE = 'Edition Upgrade';
  public static final String PRODUCT_UPGRADE = 'Edition Upgrade';
  public static final String PROGRAM_EXPANSION = 'Expansion';
  public static final String OPP_TYPE = 'Existing Customer';
  public static final String OPP_REGISTRATION = 'Rubrik Sourced';
  public static final String OPP_STAGE_FINAL = '7 Closed Won';
  public static final String OPP_INITIAL_STAGE = '1 Discovery';
  public static final Id OPPORTUNITY_RECORDTYPEID_RENEWAL = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Renewal_Opportunity').getRecordTypeId();
  public static final String OPP_NAME_CURRENT_MONTH_YEAR = Datetime.now().format('MMMM, y');
  public static final String PROGRAM_MSP_TO_SU_V1_V2 = 'v1v2';
  public static final String CP_ACTIVITY_YES = 'Yes';
  public static final String CP_ACTIVITY_NO = 'No';
  public static final String CP_ACTIVITY_SOURCED = 'Sourced';
  public static final String CP_ACTIVITY_INFLUENCED = 'Influenced';
  public static final String RCDMT_EXT_READY_PROCESS_STATUS = 'Ready';  
  public static final String RCDMT_EXT_VERIFICATION_PROCESS_STATUS = 'Require Verification';  
  public static final String RCDMT_EXT_INITIAL_PROCESS_TYPE = 'Initial RCDM-T Processing'; 
  public static final String RCDMT_EXT_LOAD_DATA_PROCESS_TYPE = 'QLI & Order Processing';  
  public static final String RCDMT_EXT_RWD_DEAL_OPS_EXCEPTION = 'RCDM-T Manual Extension';  
  public static final String RSC_LOD_PRODUCT_LEVEL = 'LOD Software';
  public static final String RSC_HYBRID_PRODUCT_LEVEL = 'Hybrid Software';
  public static final String RSC_ONPREM_PRODUCT_LEVEL = 'OnPrem';
  public static final String RSC_FOUNDATION_PRODUCT_TYPE = 'Foundation Edition';
  public static final String RSC_BUSINESS_PRODUCT_TYPE = 'Business Edition';
  public static final String RSC_ENTERPRISE_PRODUCT_TYPE = 'Enterprise Edition';
  public static final String RCDMT_EXT_DUPLICATE_ACCOUNT_MESSAGE = 'Duplicate Account Found ,Please try with another Account'; 	
  public static final String RCDMT_EXT_END_USER_PO = 'Free RCDM-T License Extension';
  public static final String RCDMT_EXT_COMPLETED_PROCESS_STATUS = 'Completed';  
  
  //Account
  public static final Set<String> ACCOUNT_MSP_TYPES = new Set<String>{'MSP','MSP-Reseller'};

  // Order
  public static final String ORDER_SUB_TYPE_GC_OFFER = 'GC Offer';
 // public static final String ORDER_SUB_TYPE_GC_RENEWAL = 'GC Renewal';
  public static final String ORDER_SUB_TYPE_GC_ONDEMAND = 'GC OnDemand';
  public static final String ORDER_SUB_TYPE_GC_RENEWAL = 'GC Renewal';
  public static final String PRODUCT_SUBTYPE_AR = 'Ondemand Above Reserve';
  public static final String PRODUCT_SUBTYPE_SR = 'Ondemand Sub Reserve';
  public static final String ORDER_SPLIT_TYPE_GC_OFFER_AMENDMENT = 'GC Offer Amendment';
  public static final String PRODUCT_CODE_RSVX = 'RSVX';
  public static final String PRODUCT_FEATURE_LAMINAR = 'LAMINAR';
  public static final String PRODUCT_FEATURE_DSPM = 'DSPM CUSTOMER HOSTED UCL'; 
    public static final String ORDER_SUBTYPE_TRY_N_BUY = 'Try N Buy';
  public static final String ORDER_TYPE_POC = 'POC';
  public static final Id ORDER_RECORDTYPEID_POC_ORDER = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('POC_Order').getRecordTypeId();  
  public static final String ORDER_TYPE_REVENUE_INTERNAL = 'Revenue Internal';
  public static final string ORDER_SUB_TYPE_RENEWAL = 'Renewal';
  public static final string ORDER_SUB_TYPE_RENEWAL_EXPANSION = 'Renewal + Expansion';
  public static final String ORDER_CRSD_HOLD_CODE_RENEWAL = 'CRSD after renewal start date';
  public static final String ORDER_CRSD_HOLD_CODE = 'CRSD is in future quarter';
  public static final String ORDER_STATUS_ORDER_ACCEPTED = 'Order Accepted';

  // QLI or OI Programs
  public static final String PROGRAM_UPGRADE = 'Upgrade';
  public static final String PROGRAM_CONVERSION = 'Conversion';
  public static final String PROGRAM_REFRESH = 'Refresh';
  public static final String PROGRAM_REFRESHED = 'Refreshed';

  // OrderItem
  public static final String ORD_ITEM_REPLACEMENT_TYPE_PARTIAL = 'Partial';
  public static final List<String> ORDER_SUB_TYPES_SCALE_UTILITY = new List<String>{
    Constants.ORDER_SUB_TYPE_GC_OFFER,
    Constants.ORDER_SUB_TYPE_GC_ONDEMAND,
    Constants.ORDER_SUB_TYPE_GC_RENEWAL
  };
  public static final List<String> ORDER_SUB_TYPES_RENEWAL = new List<String>{
    Constants.ORDER_SUB_TYPE_RENEWAL,
    Constants.ORDER_SUB_TYPE_GC_RENEWAL
    //Constants.ORDER_SUB_TYPE_RENEWAL_EXPANSION
  };
  public static final List<String> SCALE_UTILITY_PRODUCT_SUBTYPES_AR_AND_SR = new List<String>{ Constants.PRODUCT_SUBTYPE_AR, Constants.PRODUCT_SUBTYPE_SR };
   public static final List<String> SCALE_UTILITY_PRODUCT_SUBTYPES_ONDEMAND = new List<String>{
    Constants.PRODUCT_SUBTYPE_ONDEMAND,
    Constants.PRODUCT_SUBTYPE_AR,
    Constants.PRODUCT_SUBTYPE_SR
  };
  public static final String ORDER_TYPE = 'Revenue';
  public static final String ORDER_DRAFT = 'Draft';
  public static final String ORDER_PENDING = 'Pending';
  public static final String ORDER_CALC = 'Completed';
  public static final String ORDER_STATUS = 'Activated';
  public static final String ORDER_CONTRACTING_METHOD = 'Single Contract';
  public static final String ORDER_SCREENING_SOURCE_EXTERNAL = 'External';
  public static final String ORDER_SCREEN_STATUS_REQUIRED = 'Required';
  public static final String ORDER_SCREEN_STATUS_NA = 'NA';
  public static final String ORDER_SCREEN_STATUS_APPROVED_BYPASSED = 'Approved Bypassed';
  public static final String ORDER_SUB_TYPE_MSP_OVERAGE = 'MSP Overage';

  public static final String CLOSED_LOST_STAGE = '7 Closed Lost';
  public static final String CLOSED_ADMIN_STAGE = '7 Closed Admin';
  public static final String QUOTE_UPDATED_SUCCESS_STATUS = 'Quote Update Completed';
  public static final String QUOTE_UPDATED_SUCCESS_MESSAGE = 'Quote Update Successfully';
  public static final String QUOTE_UPDATED_FAILED_STATUS = 'Quote Update Failed';
  public static final String QUOTE_UPDATED_FAILED_MESSAGE = 'Quote Not Approved';
  public static final String QUOTE_UPDATED_NOTREQUIRED_STATUS = 'Quote Update Not Required';
  public static final String QUOTE_UPDATED_NOTREQUIRED_MESSAGE = 'Quote is already Approved and Primary.';
  public static final String OPPORTUNITY_FOR_UNCALCULATEONQUOTE_STATUS = 'Opportunity Update Failed';
  public static final String OPPORTUNITY_SUCCESS_STATUS = 'Opportunity Update Completed';
  public static final String OPPORTUNITY_SUCCESS_MESSAGE = 'Opportunity updated to Stage 6';
  public static final set<String> VALID_OPPTY_STAGES = new Set<String>{ 
    Constants.ON_DEMAND_OPPORTUINITY_STAGENAME,
    Constants.OPP_STAGE_FINAL,
    Constants.CLOSED_LOST_STAGE,
    CLOSED_ADMIN_STAGE
   };
  

  //Entitlement Links
    public static final String ENT_LINK_TYPE_PARTIAL_CNV_ONPREM = 'Partial CNV-ONPREM';
    public static final String ENT_LINK_TYPE_CNV_ONPREM = 'CNV-ONPREM';
    public static final String ENT_LINK_TYPE_SPLIT_UPGRADE = 'Split-Upgrade';
    public static final String ENT_LINK_TYPE_SPLIT_CONVERSION = 'Split-Conversion';
    public static final String ENT_LINK_TYPE_SPLIT_RENEWAL = 'Split-Renewal';
    public static final String ENT_LINK_TYPE_SPLIT_SURVIVING = 'Split-Surviving';
    public static final Set<String> ENT_LINK_SPLIT_REPLACEMENT_TYPES  = new Set<String>{
      ENT_LINK_TYPE_SPLIT_UPGRADE,
      ENT_LINK_TYPE_SPLIT_CONVERSION,
      ENT_LINK_TYPE_SPLIT_RENEWAL,
      ENT_LINK_TYPE_SPLIT_SURVIVING
    };

  public static final Set<String> ENT_LINK_TYPES = new Set<String>();
  static {
    ENT_LINK_TYPES.addAll(ENT_LINK_SPLIT_REPLACEMENT_TYPES);
      ENT_LINK_TYPES.add(PROGRAM_REFRESH);
  }

  // Product/SKUs
  public static final String PRODUCT_TYPE_RCDM = 'RCDM';
  public static final String PRODUCT_TYPE_RCDM_SUPPORT = 'RCDM Support';
  public static final String PRODUCT_TYPE_TRAINING = 'Training';
  public static final String PRODUCT_TYPE_CONSUMPTION = 'Consumption';
  public static final String PRODUCT_SUBTYPE_ONDEMAND = 'On Demand';
  public static final String LICENSE_CATEGORY = 'SaaS';
  public static final String PROD_SUB_TYPE_SCALE_MSP = 'Scale MSP';
  public static final String PROD_LICENSE_CATEGORY_SAAS = 'SaaS';
  public static final String PROD_BUNDLE_FEATURES_M365H = 'M365H';
  public static final List<String> SCALE_UTILITY_PRODUCT_SUBTYPES = new List<String>{ Constants.PRODUCT_SUBTYPE_ONDEMAND, Constants.PROD_SUB_TYPE_SCALE_MSP };
  public static final List<String> INVALIDATE_ACCESSORIES = new List<String>{ 'RCA-SFP-TSR-01', 'RCA-SFP28-TSR-01', 'RCA-F3M-CBL-01' }; 
  public static final String PROD_ENTCON_ONE_PER_UNIT = 'One per unit';
  public static final String PROD_ENTCON_ONE_PER_QUOTELINE = 'One per quote line';
  public static final String PROD_SUBTYPE_GO_CNV = 'GO CNV';
  public static final set<string> THIRD_PARTY_HARDWARE = new Set<string>{ 'DELL', 'UCS', 'HPE' };
  public static final String PROD_FAMILY_RUBRIK_SCALE = 'Rubrik Scale';
  public static final String PROD_FAMILY_THIRD_PARTY_LICENSE = 'Third Party License';
  public static final String PROD_PRODUCT_TYPE_THIRD_PARTY_HARDWARE = '3rd Party Hardware';
  public static final String PROD_MSP_STD_ACTUAL_MSP_ACTUAL_OVERAGE  = 'MSP Actual & Overage';
  public static final String PROD_PRODUCT_TYPE_MSP = 'MSP';
  public static final String PROD_CATEGORY_PROFESSIONAL_SERVICES = 'Professional Services';
  public static final String PRODUCT_FAMILY_R6000 = 'R6000';
  public static final String PRODUCT_FAMILY_R7000 = 'R7000';
  public static final Set<String> DUMMY_PRODUCTS = new Set<String>{ 'One-Time-Special' };
  public static final String SKU_TYPE_HARDWARE = 'Hardware';
  public static final String SKU_TYPE_HW_SUPPORT = 'HW Support';
  public static final String SKU_TYPE_LICENSE = 'License'; 
  public static final string SKU_TYPE_DELTA_UG = 'deltaUG';
  public static final string SKU_TYPE_NON_HARDWARE = 'Non-Hardware';
  public static final String PRODUCT_REP_CATEGORY = 'Enterprise Data Protection - Scale';
      
  // Quote
  public static final String AMENDMENT_QUOTE = 'Amendment';
  public static final String MANUAL_FULFILL_Quote_RSCP_CONVERSION = '$0 RSC-RSC-P Conversion';
  public static final String MANUAL_FULFILL_Quote_GO_RSCP_CONVERSION = '$0 GO-RSCP Conversion';
  public static final String PRODUCT_CODE_PREFIX_RSCP = 'RSCP-'; // PRDOPS-544
  public static final String POLARIS_FULFILLMENT_STATUS_NOT_NEEDED = 'Not Needed'; // PRDOPS-544

  // Contract
  public static final String CONTRACT_ORDER_BATCH_QUERY = 'ContractOrderBatchQuery';

  // Scale Utility Related objects
  public static final String PROCESS_FLAG_DO_NOT_PROCESS = 'Do not Process';
  public static final String PROCESS_FLAG_REPROCESS = 'Reprocess';
  public static final String PROCESS_FLAG_CEATE_OVERAGE_ORDER = 'Create Overage Order';
  public static final String PROCESS_FLAG_ORDER_CREATED = 'Order Created';
  public static final String PROCESS_FLAG_STALE = 'Stale';
  public static final String PROCESS_FLAG_LATE_REQUEST = 'Late Request';
  public static final String SYNC_READY = 'Sync Ready';
  public static final String SYNC_SUCCESS = 'Sync Success';
  public static final String SCALE_UTILITY_OVERAGE_BATCH_QUERY = 'ScaleUtilityOverageBatchQuery';
  public static final String SCALE_UTILITY_OVERAGE_BATCH_OI_QUERY = 'ScaleUtilityOverageOIQuery';
  public static final String SCALE_UTILITY_OVERAGE_SC_QUERY = 'ScaleUtilityOverageSCQuery'; 
  public static final String SCALE_UTILITY_LATE_REQUEST_MESSAGE = 'Process flag is marked Create order in the end of the month at TimeStamp so this is set to Late Request';
  public static final List<String> PROCESS_FLAGS_TO_REPROCESS = new List<String>{ PROCESS_FLAG_DO_NOT_PROCESS, PROCESS_FLAG_REPROCESS, PROCESS_FLAG_STALE };

  // Date
  public static final Integer CURRENT_YEAR = Date.Today().Year();
  public static final Integer CURRENT_MONTH = Date.Today().Month();
  public static final Integer LAST_MONTH = Date.Today().addMonths(-1).month();
  
  // Entitlement And entitlement links
  public static final String ENT_RENEWAL_CATEGORY_RENEWED = 'Renewed';
  public static final String ENT_INACTIVE_USED = 'inactiveUsedEnt';
  public static final String ENT_INACTIVE_LEFT = 'inactiveLeftEnt';
  public static final String ENT_INACTIVE = 'InactiveEnt';
  public static final String ENT_STATUS_EXPIRED = 'Expired';
  public static final String ENT_TRANS_TYPE_REPLACEMENT_FRAMEWORK = 'Replacement Framework';
  public static final String ENT_TYPE_PHONE_SUPPORT = 'Phone Support';
  public static final String ENT_RENEWAL_CATEGORY_REFRESHED = 'Refreshed';
  public static final String ENT_TYPE_PMC = 'PMC';
  public static final String ENT_TYPE_EVALUATION = 'Evaluation';
  public static final String ENT_TYPE_MANUFACTURING_ENTITLEMENT = 'Manufacturing Entitlement';
  public static final String ENT_SUBTYPE_RUBRIK_SUPPORT = 'Rubrik Support';  
  public static final Decimal DEFAULT_SU_ENTITLEMENT_LINK_QUANTITY = 1;
  public static final Id ENT_RECORDTYPEID_MANUFACTURING = Schema.SObjectType.Entitlement.getRecordTypeInfosByDeveloperName().get('Manufacturing_Entitlement').getRecordTypeId();  
  public static final Id ENT_RECORDTYPEID_SUPPORT = Schema.SObjectType.Entitlement.getRecordTypeInfosByDeveloperName().get('Support').getRecordTypeId();  
  public static final Map<String, String> mapProgramToRenewalCategory = new Map<String, String>{
    'Conversion' => 'Converted', 
        'Refresh' => 'Refreshed', 
        'Renewing' => 'Renewed', 
        'Renewal' => 'Renewed', 
        'Upgrade' => 'Upgraded' 
        };  
  public static final String UPGRADED_STATUS = 'Upgraded';
  public static final String CONVERTED_STATUS = 'Converted';    

  public static final String ENT_STATUS_ACTIVE = 'Active';

  // General Strings
  public static final String ACCOUNT_OBJECT_NAME = 'Account';
  public static final String ORDER_OBJECT_NAME = 'Order';
  // Rebate type
  public static final String REBATE_DEAL_TYPE_GC_OFFER = 'GC Offer';
  // SnowFlake Feed
  public static final String SNOWFLAKE_ORIGIN_SFDC = 'SFDC';
  public static final String SNOWFLAKE_TYPE_CNP = 'CNP';
  public static final String SNOWFLAKE_CLUSTERNAME = 'ClusterUUID';
  public static final String SNOWFLAKE_CLUSTERUSAGE = 'ClusterUsage';

  public static final String SNOWFLAKE_Global_Commit = 'Global_Commit_ID__c';
  public static final String SNOWFLAKE_AccountID = 'Account_ID__c';
  public static final String SNOWFLAKE_Original_Order = 'Original_Order__c';
  public static final String SNOWFLAKE_RECORDID = 'recordId';
  public static final String PRODUCT_FIELD_BUNDLETYPE = 'BundleType';
  public static final String SNOWFLAKE_TYPE_M365H = 'M365H';
  public static final String PRODUCT_TYPE_NAS_CLOUD_DIRECT = 'NAS Cloud Direct';
  public static final String PRODUCT_SUB_TYPE_BE_ADDON = 'BE Addons';
  public static final String PRODUCT_TYPE_IGNEOUS_LEGACY = 'Igneous-Legacy';
  public static final String NAS_DATA_SECURITY = 'NAS Data Security';
  public static final String UCL_DATA_SECURITY = 'UCL Data Security';
  // Shipment Detail
  public static final Id overViewRecordTypeId = Schema.SObjectType.ShipmentDetail__c.getRecordTypeInfosByName()
    .get('Overview').getRecordTypeId(); 
    
    //CCR 
    public static final String CUSTOMER_RETURN = 'Customer Returns / Refunds';
    public static final String NON_PAYMENT = 'Non-Payment';
    public static final String BOOKING_POLICY = 'Change in Booking Policy / De-Risk Decision';
    public static final String INCORRECT_ORDER = 'Incorrect Order/Mis-quote';
    public static final String UNPAID_REPLACEMENT_DEBOOK = 'Unpaid Replacement Debooking';
    public static final String PARTNER_REFERRAL_FEE = 'Partner Referral Fee';

    public static final List<String> CCR_TYPES = new List<String>{Constants.CUSTOMER_RETURN, Constants.NON_PAYMENT, Constants.BOOKING_POLICY, Constants.INCORRECT_ORDER, Constants.UNPAID_REPLACEMENT_DEBOOK};
    public static final List<String> CCR_TYPESWITHOUTREFUND = new List<String>{Constants.NON_PAYMENT, Constants.BOOKING_POLICY, Constants.INCORRECT_ORDER, Constants.UNPAID_REPLACEMENT_DEBOOK};
    
    
  //Asset
  public static final String ASSET_STATUS_DECOMMISSIONED = 'Decommissioned';
  
  //Replacement Programs
  public static final List<String> REPLACEMENT_PROGRAMS = new List<String>{ PROGRAM_CONVERSION, PROGRAM_UPGRADE };
  public static final String ORDER_TYPE_REVENUE = 'Revenue';
  //Scale Entitlements
  public static final String SCALE_ENT_RENEWAL_CATEGORY_REFRESHED = 'Refreshed';
  public static final String SCALE_ENT_TYPE_REFRESHED_DELTA_LICENSE	= 'Refreshed Delta License';	
  public static final String SCALE_ENT_TYPE_REFRESHED_BASE_LICENSE	= 'Refreshed Base License';	

  //Order Type & Subtype

  public static final String ORDER_TYPE_REPLACEMENT = 'Replacement';
  public static final String ORDER_TYPE_RENEWAL = 'Renewal';
  public static final String ORDER_SUBTYPE_RENEWAL = 'Renewal';
  
  //Order -> SC Or Entitlement Stages
  public static final String SC_ENT_STAGE_CREATE_CUSTOM_ENT = 'Create Custom Entitlement';
  public static final String SC_ENT_STAGE_CUSTOM_ENT_CREATED = 'Custom Entitlement Created';
  public static final String SC_ENT_STAGE_CUSTOM_ENT_CREATION_FAILED = 'Custom Entitlement Creation Failed';
  
  public static final String SC_ENT_STAGE_CREATE_MANUFACTURING_ENT = 'Create Manufacturing Entitlement';
  public static final String SC_ENT_STAGE_MANUFACTURING_ENT_CREATED = 'Manufacturing Entitlement Created';
  public static final String SC_ENT_STAGE_MANUFACTURING_ENT_CREATION_FAILED = 'Manufacturing Entitlement Creation Failed';

  public static final String SC_ENT_STAGE_CREATE_POC_ENT = 'Create POC Entitlement';
  public static final String SC_ENT_STAGE_POC_ENT_CREATED = 'POC Entitlement Created';
  public static final String SC_ENT_STAGE_POC_ENT_CREATION_FAILED = 'POC Entitlement Creation Failed';
  
  public static final String SC_ENT_STAGE_EXTEND_POC_ENT = 'Extend POC Entitlement End Date';
  public static final String SC_ENT_STAGE_POC_EXTENDED = 'POC Extended';
  public static final String SC_ENT_STAGE_POC_EXTENSION_FAILED = 'POC Extension Failed';
  
  //Stages for Existing Contract Orders Batch  
  public static final String SC_ENT_STAGE_CREATE_SERVICE_CONTRACT = 'Create Service Contract';
  public static final String SC_ENT_STAGE_SC_CREATION_SUCCESSFUL = 'SC Creation Successful';
  public static final String SC_ENT_STAGE_SC_CREATION_FAILED = 'SC Creation Failed';  
  
  // ContractOrders Batch
  
    public static final List<String> CUSTOM_ENTITLEMENT_CREATION_STAGES = new List<String>{
        SC_ENT_STAGE_CREATE_CUSTOM_ENT,
        SC_ENT_STAGE_CUSTOM_ENT_CREATION_FAILED,
        SC_ENT_STAGE_CREATE_MANUFACTURING_ENT,
        SC_ENT_STAGE_MANUFACTURING_ENT_CREATION_FAILED,
        SC_ENT_STAGE_CREATE_POC_ENT,
        SC_ENT_STAGE_POC_ENT_CREATION_FAILED
    };
    
  public static final List<String> POC_EXTENSION_STAGES = new List<String>{ SC_ENT_STAGE_EXTEND_POC_ENT, SC_ENT_STAGE_POC_EXTENSION_FAILED };
    
    public static final List<String> CONTRACT_ORDERS_ENT_STAGES = new List<String>();
    static {
      CONTRACT_ORDERS_ENT_STAGES.addAll(CUSTOM_ENTITLEMENT_CREATION_STAGES);
      CONTRACT_ORDERS_ENT_STAGES.addAll(POC_EXTENSION_STAGES);
    }

  public static final List<String> CONTRACT_ORDERS_SC_STAGES = new List<String>{ SC_ENT_STAGE_CREATE_SERVICE_CONTRACT, SC_ENT_STAGE_SC_CREATION_FAILED };

  public static final String CONTRACT_ORDERS_BASE_QUERY = 'SELECT Id, Scale_Utility_SKUs_Count__c, Order_sub_Type__c, OrderNumber, Is_RWD_Polaris_Quote__c, SBQQ__Quote__c, SC_or_Entitlement_Stage__c FROM Order';
  public static final String CONTRACT_ORDERS_OLD_FILTERS = ' WHERE Order_Status__c = \'Shipped\' ' +
                            'AND SBQQ__Contracted__c = false ' +
                            'AND (Welcome_letter_sent_for_the_first_time__c = true ' +
                            'OR WelcomeEmailSentforSoftwareProducts__c = true) ' +
                            'AND Type = \'Revenue\' ' +
                            'AND Order_Sub_Type__c != \'MSP Overage\' ' +
                            'AND SBQQ__Quote__c != null ' +
                            'AND Order_Sub_Type__c != \'GC OnDemand\' ' +
                            'AND Status = \'Activated\' ' +
                            'AND OrderNumber NOT IN :byPassOrderNum';
                           
  public static final String CONTRACT_ORDERS_NEW_FILTERS = ' WHERE SC_or_Entitlement_Stage__c INCLUDES (\'' + String.join(CONTRACT_ORDERS_SC_STAGES, '\',\'') + '\')';
  public static final String CONTRACT_ORDERS_FINISH_FILTERS = ' WHERE SC_or_Entitlement_Stage__c INCLUDES (\'' + String.join(CONTRACT_ORDERS_ENT_STAGES, '\',\'') + '\')';
  //FY25SR-1207
  public static Boolean IS_FIPS_ASSET_REFRESHED = false;
  public static final String FIPS_ASSET_REFRESHED = 'FipsAssetRefreshed';
  public static final String FIPS = 'FIPS';
  
  //ContractOrders Error Logging
  public static final String ENTITLEMENT_MANAGER_CLASS  = 'ReplacementEntSplitManager';
  public static final String ERROR_ORIGINAL_ENT_NOT_FOUND = 'Original Entitlement Record Not Found';
  public static final String ERROR_TERMINATE_DATE_NOT_FOUND = 'Terminate Date Not found based on Replacement Framework Policy';
  public static final String ERROR_TARGET_PRODUCT_TYPE_MISSING = 'TargetProductType not found from QLI JSON';
  public static final String ERROR_SURVIVING_ENTITLEMENT_MISSING = 'Surviving Entitlement Not found';
  public static final String ERROR_INVALID_ENT_DETAILS_WRAPPER = 'Invalid entitlement details wrapper provided.';
  public static final String ERROR_ORDER_ACCEPTED_SHIP_DATES_MISSING = 'Order Accepted Timestamp or Actual Order Ship Date is missing on the Order linked to the Replacement Entitlement.';
  public static final String ERROR_REPLACEMENT_ENT_NOT_FOUND = 'New Replaced Entitlement is unavailable.';
  public static final String ERROR_OI_EXTENSION_NOT_FOUND = 'Order Item Extension details are unavailable.';  

  //Entitlement Split Key 

  public static final String ENT_KEY_ORIGINAL = 'Original';
  public static final String ENT_KEY_SURVIVING_NEW = 'SurvivingNew';
  public static final String ENT_KEY_SURVIVING_OLD = 'SurvivingOld';
  public static final String ENT_KEY_REPLACED_OR_RENEWED_NEW  = 'ReplacedOrRenewedNew';
  public static final String ENT_KEY_REPLACED_OR_RENEWED_OLD  = 'ReplacedOrRenewedOld';
  public static final String STATUS_APPROVED = 'Approved';//CPQ22-6097
  public static final String STATUS_IN_REVIEW = 'In Review';//CPQ22-6097

  //RSC Instance
  public static final String OPP_MSP_DEAL_TYPE_DEDICATED_DEAL = 'Dedicated Deal';
  public static final String OPP_MSP_DEAL_TYPE_SHARED_SERVICES = 'Shared Services';
  public static final String RSCINSTANCE_ACCOUNT_RELATIONSHIP_PRIMARY = 'Primary';
  public static final String RSCINSTANCE_ACCOUNT_RELATIONSHIP_CHILD = 'Child';
  public static final String RSCINSTANCE_ACCOUNT_TYPE_POC = 'POC';
  public static final String RSCINSTANCE_ACCOUNT_TYPE_PROD = 'Revenue';
  public static final String RSCINSTANCE_STATUS_PENDING_CREATION = 'PENDING_CREATION';
  public static final String RSCINSTANCE_STATUS_ACTIVE = 'ACTIVE';
  public static final String RSCINSTANCE_STATUS_DELETED = 'DELETED';
  public static final String RSCINSTANCE_STATUS_MARKED_FOR_DELETION = 'MARKED_FOR_DELETION';
  public static final String RSCINSTANCE_CONTRACT_TYPE_DEDICATED = 'Dedicated';
  public static final String RSCINSTANCE_CONTRACT_TYPE_SHARED = 'Shared';
  public static final List<String> RSCINSTANCE_DELETED_STATUS_LIST = new List<String>{ Constants.RSCINSTANCE_STATUS_DELETED, Constants.RSCINSTANCE_STATUS_MARKED_FOR_DELETION };
  
  //Disposition Reason
  public static final String RENEWING = 'Renewing';
  // Product Edition
  public static final String COMPLETE_UPGRADE_EDITION    = 'Complete Cyber Resilience Upgrade';//ITNPI-3211
  // Product Types for Cluster Order Type  
  public static final List<String> IDENTITY_EDGE_PRODUCT_TYPES = new List<String>{
    'Identity Cyber recovery',
    'Identity Cyber posture',
    'EDGE',
    'Rubrik Spark',
    'M365 CCR'
  };//ITNPI-3211
    public static final String CONTRACT_IN_NEGOTIATION = 'Contract In Negotiation';
    //Smart Approval
    public static final String SMART_APPROVED = 'Smart Approved';
    public static final String SMART_IN_REVIEW = 'In Review of auto approval';
    public static final String STATUS_REQUESTED = 'Requested';
    public static final String STRING_TIER = 'Tier:';
    public static final String SMART_APPROVAL_EMAIL = 'Smart_Approval';
    public static final String STATUS_ASSIGNED = 'Assigned';
    public static final String STATUS_SMART_APPROVED = 'Smart Approved';
    public static final String RT_APPROVED_QUOTE = 'Approved_Quote';
    //Operations
    public static final String EQUALS_OPERATOR = 'equals';
    public static final String NOT_EQUALS_OPERATOR = 'not equals';
    public static final String LESS_THAN_OPERATOR = 'less than';
    public static final String LESS_OR_EQUALS_OPERATOR = 'less or equals';
    public static final String GREATER_THAN_OPERATOR = 'greater than';
    public static final String GREATER_OR_QUALS_OPERATOR = 'greater or equals';
    public static final String STARTS_WITH_OPERATOR = 'starts with';
    public static final String ENDS_WITH_OPERATOR = 'ends with';
    public static final String CONTAINS_OPERATOR = 'contains';
    public static final String DOES_NOT_CONTAIN_OPERATOR = 'does not contain';
    public static final String INCLUDES_OPERATOR = 'includes';
    public static final String QL_RWD_APPROVAL_TIER = 'RWD_approval_Tier__c';
    public static final String APPROVAL_SNAPSHOT_CHILD_OBJ= 'Approval_Snapshots__r';
    public static final String QUOTELINE_FIELDAPI = 'Quote_Line__c';
    public static final String PARAMETERNAME_SNAP = 'snapshotId';
    public static final String TEMP_VARIABLE_QL = 'Approval_temp_field__c';
}