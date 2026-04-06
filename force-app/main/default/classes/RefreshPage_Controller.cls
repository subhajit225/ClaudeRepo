/**
 * @author Paritosh
 * @Date Created/Modified: 11/03/25
 * @description Controller for LWC component RefreshPage of SMS UI
 */
public with sharing class RefreshPage_Controller {

    /** @description query metadata clause **/ 
    @testVisible
    static String REPLACEMENT_REFRESH_ELIGIBLE_SKU_QUERY_MDT = ReplacementConstants.REPLACEMENT_REFRESH_ELIGIBLE_SKU_QUERY_MDT;

    /**
     * @description Get get list of source and target eligible products
     * @return source and target eligible products
     */
    @AuraEnabled
    public static List<Product2> getEligibleProducts(){
        try {
            List<Product2> eligibleProducts = new List<Product2>();
            String whereClause;

            Replacement_Field_Mapping__mdt whereClauseMetadata =
                Replacement_Field_Mapping__mdt.getInstance(REPLACEMENT_REFRESH_ELIGIBLE_SKU_QUERY_MDT);
            if (whereClauseMetadata != null){
                whereClause = whereClauseMetadata.First_Filter_Criteria__c;
            }

            String query ='SELECT Id, ProductCode,Product_Type__c, Category__c, Usable_Capacity__c, '
             + 'RWD_Version__c, RWD_Hardware_Family__c, Refresh_Eligibility__c, Product_NIC_Type__c, Family  ';
            query += 'FROM Product2 ';
            query += ' WHERE '+ whereClause;
            query += ' ORDER BY Usable_Capacity__c, ProductCode ';

            eligibleProducts = Database.query(query.trim());

            return eligibleProducts;

        } catch (Exception e) {
            LogError.logCustomError('RefreshPage_Controller', e.getMessage(), e.getStackTraceString(), 'getEligibleProducts');
            throw ReplacementQuoteLineCreationHelper.handleException(e);
        }
    }
}