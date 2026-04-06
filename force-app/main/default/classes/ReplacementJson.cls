/***********************************************************************************************************
 * Class Name           : ReplacementJson
 * Date Created/Modified: 28/03/2024
 * Author               : Ankita Varma
 * Purpose              : This Wrapper class is used by all the components and apex in Replacement Framework.
 * Test Class           :
 * Dependant Components : newReplacementLWC, NewReplacementController
 * @description This Wrapper class is used by all the components and apex in Replacement Framework.
 **/
public class ReplacementJson {
    
    /**
    * @description mode - mode 
    */
    @AuraEnabled public String mode;
    /**
    * @description skuSelected
    */
    @AuraEnabled public String skuSelected;//Yes
    /**
    * @description skuSelectedName
    */
    @AuraEnabled public String skuSelectedName;//Technical easy
    /**
    * @description skuStorageBundleVal
    */
    //@AuraEnabled public String skuStorageBundleVal;//Rahul made changes for Prod replacement
    /**
    * @description skuStorageTierVal
    */
    @AuraEnabled public String skuStorageTierVal;//Issue with Storage Tier getting overriden to unlimited, hence added  //FY25SR-1084
    /**
    * @description skuAttlasianVal
    */
    //@AuraEnabled public String skuAttlasianVal;
    /**
    * @description skuM365HVal
    */
    // @AuraEnabled public String skuM365HVal;
    /**
    * @description skuSFDCVal
    */
    // @AuraEnabled public String skuSFDCVal;
    /**
    * @description seamlessCutover
    */
    // @AuraEnabled public String seamlessCutover;//Yes
    /**
    * @description renLine
    */
    @AuraEnabled public Boolean renLine;//True if the line is created from a Service Contract. Used for Renewal Quote Types
    /**
    * @description lodToSaas
    */
    @AuraEnabled public Boolean lodToSaas;//True if the line is updated after LOD to SAAS conversion. Used to disable the line on SMS screen 
    /**
    * @description refreshCategoryId
    */
    @AuraEnabled public String refreshCategoryId ; //Added for Refresh Category product Id Indentifier 
    /**
    * @description skuSuppType
    */
   // @AuraEnabled public String skuSuppType; //Added for bug FY25SR-1083
    /**
    * @description skuProdCodeType
    */
   // @AuraEnabled public String skuProdCodeType;//Added for FY25SR-1084
    /**
    * @description dynamicFieldValues - values gets populated on runtime
    */
    @AuraEnabled public Map<String, String> dynamicFieldValues;//Added for FY25SR-1084 
    /**
    * @description targetProductType
    */
    @AuraEnabled public String targetProductType;//Added for FY25SR-1084
    /**
    * @description rowValues
    */
    @AuraEnabled public List<RowDetail> rowValues;
    /**
     * @description : subClass RowDetails
     */
    public class RowDetail {
        /**
         * @description : rowId
         */
        @AuraEnabled public String rowId;//Yes
        /**
         * @description : entId
         */
        @AuraEnabled public String entId;//Yes
        /**
        * @description upgradeLines
        */
        @AuraEnabled public List<RelatedChildEntRowDetail> upgradeLines;  
        /**
        * @description inactiveLines
        */        
        @AuraEnabled public List<RelatedChildEntRowDetail> inactiveLines;    
        /**
        * @description selectedTerm
        */
        @AuraEnabled public Integer selectedTerm; //Need to populate it on Page again - Here it will handle all partial cases      
        /**
        * @description selectedQty
        */
        @AuraEnabled public Integer selectedQty;//Yes
        /**
        * @description anyToAnyFlag
        */
      //  @AuraEnabled public Boolean anyToAnyFlag;//Yes // FY25SR-1577
        /**
        * @description selectedAsset
        */
        @AuraEnabled public String selectedAsset;//Yes
        /**
        * @description selectedAssetList
        */
        @AuraEnabled public Map<String,String> selectedAssetList;
        /**
        * @description disposition
        */
        @AuraEnabled public String disposition;//Technical easy
        /**
        * @description selectedRenewalDate
        */
        @AuraEnabled public Date selectedRenewalDate; // Added as part of FY25SR-1492 for the user selected Renewal end date
        /**
        * @description isAutoDisposition
        */
        @AuraEnabled public Boolean isAutoDisposition;
        /**
        * @description do not consolidate
        */
       // @AuraEnabled public Boolean dnc;
        /**
         * @description Mismatch QTY non asset to non asset
        */
        @AuraEnabled public Boolean isMismatch;
          
    }
    /**
     * @description : subClass RelatedChildEntRowDetail
     */
    public class RelatedChildEntRowDetail{
        /**
        * @description childEntId
        */
        @AuraEnabled public String childEntId;
        /**
        * @description childQnty
        */
        @AuraEnabled public Integer childQnty;
        /**
        * @description childrowId
        */
        @AuraEnabled public String childrowId;
    
    }
}