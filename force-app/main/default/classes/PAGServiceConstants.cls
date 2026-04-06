/***********************************************************************************************************
@Description : Constant class for PAG/PQL api service
@Developer : Rubrik Dev
@Test Class : PAGServiceTest 
@Modification Logs
@Modified By             Date            Description
@Rubrik Dev              2/17/2025       SAL25-819 Implement Opportunity Creation Process
************************************************************************************************************/
public with sharing class PAGServiceConstants {
    
    public static final String MSG_INVALID_INPUT_PARAMETERS = '';
    public static final String MSG_INVALID_INPUT_PARAMETERS_CODE = '400';
    public static final String MSG_SUCCESSFULL_UPSERT_DATA = 'Success';
    public static final String MSG_SUCCESSFULL_UPSERT_DATA_CODE = '200';
    public static final String MSG_INVALID_REQUEST = '';
    public static final String MSG_INVALID_REQUEST_CODE = '400';
    public static final String MSG_NOT_MODIFIED_REQUEST = '';
    public static final String MSG_NOT_MODIFIED_REQUEST_CODE = '304';
    public static final String MSG_UNHANDLED_EXCEPTION_CODE = '500';
    public static final String MSG_SEND_TRIALORPAG_ID = 'SendEitherTrialOrPAGID : Please send either of Trial ID or PAG ID';
    //SAL25-818 Error message if External and PQL Id are present in the PQL request.
    public static final String MSG_SEND_EXTERNALORPQL_ID = 'SendEitherExternalOrPQLID  : Please send either a PQL External Id or PQL ID.';
    public static final String MSG_SEND_ACCOUNT_ID_CAN_NOT_BE_BLANK = 'Account__c can not be balnk';
    public static final String MSG_SEND_PAGID_WITH_ENTITLEMENT = 'MissingPAGIDOnEntitlement : Please send PAG ID with Entitlement Data';

    public static final String OPPORTUNITY_SALES_RECORD_TYPE = 'Sales_Opportunity';
    public static final String OPPORTUNITY_LEADSOURCE_PAG = 'Product Assisted Growth (PAG)';
    public static final String OPPORTUNITY_LEADSOURCE_PQL = 'Product Qualified Lead (PQL)';// SAL25-819
    public static final String OPPORTUNITY_STAGE_NURTURE = '0 Nurture';
    public static final String OPPORTUNITY_TYPE_EXISTING_CUST = 'Existing Customer';
    public static final String OPPORTUNITY_SUBTYPE_REGULAR = 'Regular';
    public static final Integer OPPORTUNITY_AMOUNT_ZERO = 0;
    
    public static final String PRODUCT_ASSISTED_GROWTH_TRIAL = 'Product Assisted Growth Trial';
    public static final String PRODUCT_QUALIFIED_LEAD = 'Product Qualified Lead';//SAL25-819
    public static final Integer PAG_END_DATE_BUFFER = 90;
    public static final Integer PQL_END_DATE_BUFFER = 180; //SAL25-819
    public static final String PQL = 'PQL'; //SAL25-819
    public static final String PAG = 'PAG'; //SAL25-819
    public static final String ENTITLEMENT_TYPE = 'Evaluation';
    public static final String ENTITLEMENT_SUBTYPE = 'PAG';
    
    

}