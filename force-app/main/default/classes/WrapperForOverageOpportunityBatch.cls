public Class WrapperForOverageOpportunityBatch {

    public class AccountProductWrapper {
        public Id ownerId {get; set;}
        public Id clusterId {get; set;}
        public String poNumber {get; set;}
        public List<String> prodIdAndPbId {get;set;}
        public Decimal productQuantity {get;set;}  //AshwiniG : MSP1.1PostGoLive Changed to Decimal
        public Id distiAcc {get; set;}    
        public Id entitlementId {get; set;}   //AshwiniG : SW Only
        public DateTime orderCreatedDate {get;set;}  //AshwiniG : MSP1.1PostGoLive
        public String orderShipToName {get;set;}
        public String orderShipToContactName {get;set;}  
        public String orderShiptoEmail {get;set;}
        public String orderShipToPhoneNumber {get;set;}
        public String orderShippingCarrier {get;set;}
        public String orderServiceLevel {get;set;}
        public String orderShippingAccountNumber {get;set;}
        public String orderShippingCountry  {get;set;}
        public String orderShippingStreet {get;set;}
        public String orderShippingCity {get;set;}
        public String orderShippingState {get;set;}
        public String orderShippingPostalCode {get;set;}
        public String orderBillToName {get;set;}
        public String orderOpportunityInitialContactsName {get;set;}
        public String orderOpportunityAllianceHWPartner {get;set;}
        public String orderOpportunityAllianceSourceTypeHW {get;set;}
        public String orderOpportunityAlliancePartnerName {get;set;}
        public String orderOpportunityAllianceSourceTypeSW {get;set;}
        public String orderOpportunityCloudType {get;set;}
        public String orderOpportunityInstallationAssignedTo {get;set;}
        public String orderOpportunityPartnerLevelOfInvolvement {get;set;}
        public Boolean orderOpportunityHasPolarisProduct {get;set;}
        public String orderOpportunityPolarisRegion {get;set;}
        public String orderOpportunityPolarisPortalContact {get;set;}
        public String orderOpportunityKeyFeatureNeeds {get;set;}
        public String orderOpportunityLostToWonAgainst {get;set;}
        public String orderOpportunityPartnerLookup {get;set;}
        public String orderOpportunityPrimaryCompetitor {get;set;}
        public String orderOpportunityWinLossComments {get;set;}
    }
}