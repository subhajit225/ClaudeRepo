/**
 * @author Paritosh
 * @Date Created/Modified 04/03/2025
 * @description This Wrapper class used in Refresh Framework.
 */
public class RefreshWrapper {

    /** @description base licence product id */
    @AuraEnabled
    public string productId { get; set; }

    /** @description base licence product code */
    @AuraEnabled
 
    public string productCode { get; set; }

    /** @description base licence suport type */
    @AuraEnabled
    public string supportType { get; set; }

    /** @description refresh page row data */
    @AuraEnabled
    public List<Row> rows { get; set; }
    
    /** @description row wrapper class*/
    public class Row
    {
        /** @description row selected */
        @AuraEnabled
        public Boolean isSelected { get; set; }

        /** @description row modified */
        @AuraEnabled
        public Boolean isModified { get; set; }

        /** @description quantity for delta licence */
        @AuraEnabled
        public Integer deltaQuantity { get; set; }

        /** @description row previous selected asset Ids */
        @AuraEnabled
        public List<String> previousAssetIds{ get; set; }

        /** @description current selected asset Ids */
        @AuraEnabled
        public List<String> selectedAssetIds { get; set; }

        /** @description current selected asset data*/
        @AuraEnabled
        public List<Option> options { get; set; }

        /** @description selected target product Ids */
        @AuraEnabled
        public List<String> selectedTargetIds { get; set; }
    }
    
    /** @description asset option wrapper */
    public class Option
    {
        /** @description base licence entitlement Ids */
        @AuraEnabled
        public string entitlementId { get; set; }

        /** @description HW support entitlement Id */
        @AuraEnabled
        public string supportEntId { get; set; }

        /** @description HW support product Id */
        @AuraEnabled
        public string supportProdId { get; set; }

        /** @description HW support row Id (replacement page)*/
        @AuraEnabled
        public string rowId{ get; set; }
        
        /** @description HW support term (replacement page)*/
        @AuraEnabled
        public Integer replacementTerm{ get; set; }

        /** @description Asset label */
        @AuraEnabled
        public string label { get; set; }

        /** @description Asset capacity */
        @AuraEnabled
        public Integer quantity { get; set; }

        /** @description Asset selected */
        @AuraEnabled
        public boolean selected { get; set; }

        /** @description Asset Id */
        @AuraEnabled
        public string value { get; set; }
    }

}