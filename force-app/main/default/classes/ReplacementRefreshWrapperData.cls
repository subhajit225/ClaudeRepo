/***********************************************************************************************************
 * Class Name           : ReplacementRefreshWrapperData
 * Date Created/Modified: 28/03/2024
 * Author               : Shivani
 * @description         : This Wrapper class is used by all the components and apex in Replacement Framework.
 * Test Class           :
 * Dependant Components : newReplacementLWC,ReplacementRefreshUtility
 /**********************************************************************************************************/

 public class ReplacementRefreshWrapperData {
  /***********************************************************************************************************
    * Wrapper Class Name   : WrapperData
    * Date Created/Modified: 28/03/2024
    * Author               : Shivani/Rahul
    * @description         : All the entitlements are constructed as list in the form of below wrapper class.
    * Test Class Methods   :
    /**********************************************************************************************************/

  public class WrapperData {
        /**
        * @description wrapBaseLicense stores the Wrapper instance of RSC Lines and AddOns
        */
        @AuraEnabled
        public List<ReplacementRefreshWrapperData.WrapperData> wrapBaseLicense {get; set;}
        /** 
        * @description wrapHWSupportLines stores the Wrapper instance of HW Support Lines
        */
        @AuraEnabled       
        public List<ReplacementRefreshWrapperData.WrapperData> wrapHWSupportLines {get; set;}
        /**
         * @description wrapInactiveEnt stores the Wrapper instance of Inactive Lines associated with wrapBaseLicense, 
         * wrapHWSupportLines and wrapUpgradeEnt
         */
        @AuraEnabled
        public List<ReplacementRefreshWrapperData.WrapperData> wrapInactiveEnt {get; set;}
        /**
         * @description wrapUpgradeEnt stores the Wrapper instance of Upgrade Lines associated with Base Products
         */
        @AuraEnabled
        public List<ReplacementRefreshWrapperData.WrapperData> wrapUpgradeEnt {get; set;}
        /**
         * @description mapAssetEntitlements stores the Wrapper instance of RSCs along with the delta RSC 
         * which is added during HW Expansion in Refresh
         */
        @AuraEnabled
        // public Map<String, List<ReplacementRefreshWrapperData.WrapperData>> mapAssetEntitlements{get; set;}
        // public List<ReplacementRefreshWrapperData.futureDataValues> mapAssetEntitlements{get; set;}
        public ReplacementRefreshWrapperData.futureDataValues mapAssetEntitlements{get; set;}
        /**
         * @description Stores true in case of V1 Product
         */
        @AuraEnabled
        public Boolean v1Product { get; set; } //FY25SR-2232
        /**
         * @description consumedquantity Qty consumed on the Line
         */
        @AuraEnabled
        public Double consumedquantity { get; set; }
        /**
         * @description entitlement Name - Stores the name of the Entitlement in scope
         */
        @AuraEnabled
        public String entitlementName { get; set; }
        /**
         * @description entitlementOrderNumber - Stores the name of the Order Number associated with Entitlements
         */
        @AuraEnabled
        public String entitlementOrderNumber { get; set; }
        /**
         * @description entitlementId - Entitlement Id of the Entitlements in the Wrapper
         */
        @AuraEnabled
        public String entitlementId { get; set; }
        /**
         * @description productId - Product Id of the Product on the Entitlement
         */
        @AuraEnabled
        public String productId {get; set; }
        /**
         * @description oldProductEdition - Edition of the Product on the Entitlement
         */
        @AuraEnabled
        public String oldProductEdition { get; set; } // CAn be removed
        /**
         * @description StartDate - Start Date on the Entitlement
         */
        @AuraEnabled
        public Date StartDate { get; set; }
        /**
         * @description EndDate - End Date on the Entitlement
         */
        @AuraEnabled
        public Date EndDate { get; set; }
        /**
         * @description assetsAvailable - List of Assets available for each of the Entitlement. 
         * This will be populated when the Entitlements are split, to hold the rest of the Assets 
         * which are available for the Entitlement
         */
        @AuraEnabled
        public List<pickList> assetsAvailable { get; set; }
        /**
         * @description quantityAssetType - True if the Qty has to be based on Assets
         */
        @AuraEnabled
        public Boolean quantityAssetType { get; set; }
        /**
         * @description SrprodLicSubCategoryVal - License Sub Category of Source Product
         */
        @AuraEnabled
        public String SrprodLicSubCategoryVal { get; set; }
        /**
         * @description quantity - If TPH Quantity is present, then TPH Quantity of Quote Line, 
         * else Quantity of Contract Line - This holds Original Qty of the line and is not changed.
         */
        @AuraEnabled
        public Double quantity { get; set; }
        /**
         * @description selectedquantity - If TPH Quantity is present, then TPH Quantity of Quote Line,
         *  else Quantity of Contract Line - This holds the Qty selected by the User.
         */
        @AuraEnabled
        public Double selectedquantity { get; set; }
        /**
         * @description ReplacementTerm - This is the Term of Entitlement from Today to End Date of the Line. 
         * By default this will be 12 or greater term. This can be changed by the User.
         */
        @AuraEnabled
        public Double ReplacementTerm { get; set; }
        /**
         * @description RemainingTerm - This is the Term of Entitlement from Today to End Date of the Line. 
         * This will not be changed and will always have the Remaining Term of the Entitlement.
         */
        @AuraEnabled
        public Double RemainingTerm {get; set;}
        /**
         * @description selecteddisposition - The disposition reason selected for the Entitlement
         */
        @AuraEnabled
        public String selecteddisposition { get; set; }
        /**
         * @description disableDisposition - Disables Disposition reason selection
         */
        @AuraEnabled
        public Boolean disableDisposition { get; set; }
        /**
         * @description prodRepCategory - Stores the Replacement Category of the Product on the Entitlement
         */
        @AuraEnabled
        public string SrprodRepCategory { get; set; }
        /**
         * @description customIndex - Stores the index of the Entitlement
         */
        @AuraEnabled
        public String customIndex { get; set; }
        /**
         * @description errors - Stores any Errors occured in the process. Used for Validations too.
         */
        @AuraEnabled
        public String errors { get; set; }
        /**
         * @description rowSelected - True for the Entitlement which is selected by the User.
        */
        @AuraEnabled
        public Boolean rowSelected { get; set; }
        /**
         * @description showAdd - Determines if Add button has to shown for the Entitlement or not.
        */
        @AuraEnabled
        public Boolean showAdd { get; set; }
        /**
         * @description serviceContractId - Id of Service Contract associated with the Entitlement
        */
        @AuraEnabled
        public String serviceContractId { get; set; }
        /**
         * @description serviceContractName - Name of Service Contract associated with the Entitlement
        */
        @AuraEnabled
        public String serviceContractName { get; set; }
        /**
         * @description serviceContractNumber - Number of Service Contract associated with the Entitlement
        */
        @AuraEnabled
        public String serviceContractNumber { get; set; }
        /** 
         * @description RootId - Root Id associated with the Entitlement
        */
        @AuraEnabled
        public String rootId { get; set; }
        /**
         * @description showSelectCheckBox - If true, shows the checkbox on the UI against the line
        */
        @AuraEnabled
        public Boolean showSelectCheckBox { get; set; }
        /**
         * @description skuProductId - Product Id of the SKU selected for Replacement
        */
        @AuraEnabled
        public String skuProductId { get; set; }
        /**
         * @description skuProdName - Product Name of the SKU selected for Replacement
        */
        @AuraEnabled
        public String skuProdName { get; set; }
        /**
         * @description skuProdRepCategory - Replacement Category of the SKU selected for Replacement
        */
        @AuraEnabled
        public String skuProdRepCategory { get; set; }
        /**
         * @description skuProdLicenseSubCategory - License Sub Category of SKU selected for Replacement
        */
        @AuraEnabled
        public String skuProdLicenseSubCategory { get; set; }
        /**
         * @description skuStorBackBundleValue - To be determined in upcoming sprints
        */
        @AuraEnabled
        public String skuStorBackBundleValue {get; set;}
        /**
         * @description skuStorFrontBundleValue - To be determined in upcoming sprints
        */
        @AuraEnabled
        public String skuStorFrontBundleValue {get; set;}
        /**
         * @description skuStorTierValue - To be determined in upcoming sprints
        */
        @AuraEnabled
        public String skuStorTierValue {get; set;} 
        /**
         * @description skuProdCodeType - Product Code Type of SKU selected for Replacement
        */
        @AuraEnabled
        public String skuProdCodeType {get; set;} 

        /**
         * @description oldSKUwrapBundleVal - To be determined in upcoming sprints
        */
        @AuraEnabled
        public String oldSKUwrapBundleVal {get; set;}
        /**
         * @description oldSKUwrapBundleBackVal - To be determined in upcoming sprints
        */
        @AuraEnabled 
        public String oldSKUwrapBundleBackVal {get; set;}
        /**
         * @description oldSKUwrapProductType - To be determined in upcoming sprints
        */
        @AuraEnabled
        public String oldSKUwrapProductType {get; set;}
        /**
         * @description oldSKUwrapTierVal - To be determined in upcoming sprints
        */
        @AuraEnabled
        public String oldSKUwrapTierVal {get; set;}
        /**
         * @description partialReplacement - True if all Assets are not replaced. Partial Assets are renewed or disposed.
        */
        @AuraEnabled
        public Boolean partialReplacement { get; set; }
        /**
         * @description tphTypeEntitlement - Holds tphTypeEntitlement  value if present
        */
        @AuraEnabled
        public Boolean tphTypeEntitlement { get; set; }  //FY25SR-1557
      	/**
         * @description tphQuantity - Holds TPH Quantity value if present
        */
        @AuraEnabled
        public String tphQuantity { get; set; }  //FY25SR-1557
        /**
         * @description tphOEM - Holds TPH OEM value if present
        */
        @AuraEnabled
        public String tphOEM { get; set; }  //FY25SR-1557
        /**
         * @description tphModels - Holds TPH Model value if present
        */
        @AuraEnabled
        public String tphModels { get; set; }  //FY25SR-1557
        /**
         * @description tphDriveSize - Holds TPH Drive Size value if present
        */
        @AuraEnabled
        public String tphDriveSize { get; set; }  //FY25SR-1557
        /**
         * @description serviceContractName - Name of Service Contract associated with the Entitlement
        */
        //tphHWPurchasedFrom - Holds HW Purchased From value if present, for TPH
        @AuraEnabled
        public String tphHWPurchasedFrom { get; set; }
        /**
         * @description tphWhoWillDoImaging - Holds Who will do the Imaging value if present, for TPH
        */
        @AuraEnabled
        public String tphWhoWillDoImaging { get; set; }
        /**
         * @description isModified - True if the Entitlement is changed from UI.
        */
        @AuraEnabled
        public Boolean isModified {get;set;}
        /**
         * @description baseProdIds - Populated with Entitlement Id on Upgrade Wrap instance. 
         * Holds Entitlement Ids of the Lines for which the wrap is an Upgrade
        */
        @AuraEnabled
        public String baseProdIds {get;set;} 
        /**
         * @description skuSuppType - Support Type of the SKU selected for Replacement
        */
        @AuraEnabled
        public String skuSuppType { get; set; }
        /**
         * @description srPaymentType of the Entitlement
        */
        @AuraEnabled
        public String srPaymentType { get; set; }
        /**
         * @description srRenewedProduct of the Entitlement
        */
        @AuraEnabled
        public String srRenewedProduct { get; set; }
        /**
         * @description srCustomRenewedProduct of the Entitlement
        */
        @AuraEnabled
        public String srCustomRenewedProduct { get; set; }
        /**
         * @description srSuppType - Product Id of the Entitlement
        */
        @AuraEnabled
        public String srSuppType { get; set; }
        /**
         * @description srProdType - Product type
        */
        @AuraEnabled
        public String srProdType { get; set; }
        /**
         * @description autoDisposition - List of Disposition Reasons which is selected automatically
        */
        @AuraEnabled
        public List<pickList> autoDisposition { get; set; }
        /**
         * @description manualDisposition - List of Disposition Reasons which can be selected by the User
        */
        @AuraEnabled
        public List<pickList> manualDisposition { get; set; }
        /**
         * @description renLine - True if the Line is already created from Service Contract - Used for Renewal Quotes
        */
        @AuraEnabled
        public Boolean renLine { get; set; }
        /**
         * @description renewalEndDate - Renewal End Date for Renewing Lines
        */
        @AuraEnabled
        public Date renewalEndDate { get; set; }
          /**
             * @description originalQuoteLineIdForEnt 
          */
          @AuraEnabled
          public String originalQuoteLineIdForEnt { get; set; }
          /**
            * @description skuAttributesToQuoteLine 
          */
          @AuraEnabled
          public Map<String, String> skuAttributesToQuoteLine { get; set; }
        /**
         * @description keyIdentifier - Added to store Asset List, used for Replace + Refresh scenario - Future transaction 
        */
        @AuraEnabled
        public String keyIdentifier { get; set; }
        /**
        * @description srcLicModel - Stores License Model of the CLI.
        */
        @AuraEnabled
        public String srcLicModel { get; set; }
        /**
        * @description anyToAnyFlag - Stores Boolean for AnytoAny check
        */
        @AuraEnabled
        public Boolean anyToAnyFlag { get; set; }
        /**
        * @description path 
        */
        @AuraEnabled
        public String targetProductType { get; set; }// FY25SR-1705
        /**
        * @description selectedAssetsFromNonAsset
        */
        @AuraEnabled
        public List<ReplacementRefreshWrapperData.PickList> selectedAssetsFromNonAsset { get; set; } // FY25SR-1705
        /**
        * @description doNotConsolidateEnt
        */
        @AuraEnabled
        public Boolean doNotConsolidateEnt { get; set; } // FY25SR-1705 ,  //FY25SR-1124
        /**
         * @description 
        */
        @AuraEnabled
        public List<ReplacementRefreshWrapperData.PickList> exceptionMessages { get; set; } // FY25SR-1124
        /**
         * @description textToShow - To show the help text on Upgrade SKUs
        */
        @AuraEnabled
        public String textToShow { get; set; } // FY25SR-1580
       
        /**
         * @description misMatchQTY
        */
        @AuraEnabled
        public Boolean misMatchQTY { get; set; } // FY25SR-2071
       
        /**
         * @description disableSKU
        */
        @AuraEnabled
        public Boolean disableSKU { get; set; } // FY25SR-2388
       
    }
  
  /***********************************************************************************************************
  * Wrapper Class Name   : PickList
  * Date Created/Modified: 28/03/2024
  * Author               : Shivani/Rahul/Vartika
  * @description         : Used as a input class for WrapperData class to create picklist values.
  * Test Class Methods   :
  /**********************************************************************************************************/
  public class PickList {
    /**
    * @description value - Value of Picklist
    */
    @AuraEnabled
    public String value { get; set; }
    /**
    * @description label - Label of Picklist
    */
    @AuraEnabled
    public String label { get; set; }
    /**
    * @description entitlementId - EntitlementId on which Assets has to be shown
    */
    @AuraEnabled
    public String entitlementId { get; set; }
    /**
    * @description entitlementName - EntitlementName on which Assets has to be shown
    */
    @AuraEnabled
    public String entitlementName { get; set; }
    /**
    * @description quantity - Product Usable capacity of the Assets
    */
    @AuraEnabled
    public Double quantity { get; set; }
    /**
    * @description selected - True if the Assets are selected
    */
    @AuraEnabled
    public Boolean selected { get; set; }
    /**
    * @description valueProcessed - true if values are evaluated on the UI. Displays the rest of the Assets.
    */
    @AuraEnabled
    public Boolean valueProcessed { get; set; }
    /**
    * @description entCustomIndex
    */
    @AuraEnabled
    public String entCustomIndex { get; set; } // FY25SR-1705 
     /**
    * @description disabled
    */
    @AuraEnabled
    public Boolean disabled { get; set; } // FY25SR-1124
    /**
    * @description isVisible
    */
    @AuraEnabled
    public Boolean isVisible { get; set; } // FY25SR-1124
  }
  /***********************************************************************************************************
  * Method Name          : createpicKlistValues
  * Date Created/Modified: 28/03/2024
  * Author               : Shivani/Rahul
  * @description         : This method dynamically creates ReplacementWrapperData.pickList values related to entitlements by taking
  *                        Value, Label, entitlementId, entitlementName, quantity, selected,
  *                        valueProcessed as input parameters.
  * @return              : return
  * @param value
  * @param label
  * @param entitlementId
  * @param entitlementName
  * @param quantity
  * @param selected
  * @param valueProcessed
  * @param disabled
  * @param isVisible
  * Test Class Methods   :
  /**********************************************************************************************************/
  public static pickList createpicKlistValues(
    String value,
    String label,
    String entitlementId,
    String entitlementName,
    Double quantity,
    Boolean selected,
    Boolean valueProcessed,
    Boolean disabled,
    Boolean isVisible
  ) {
    pickList objpickList = new pickList();
    objpickList.value = value;
    objpickList.label = label;
    objpickList.entitlementId = entitlementId;
    objpickList.entitlementName = entitlementName;
    objpickList.selected = valueProcessed;
    objpickList.valueProcessed = selected;
    objpickList.quantity = quantity;
    objpickList.disabled = disabled;
    objpickList.isVisible = isVisible;
    return objpickList;
  }
/***********************************************************************************************************
    * Wrapper Class Name   : FutureDataValues
    * Date Created/Modified: 28/03/2024
    * Author               : Shivani/Rahul
    * @description         : All the entitlements are constructed as list in the form of below wrapper class.
    * Test Class Methods   :
 /**********************************************************************************************************/
  public class FutureDataValues{
    /**
    * @description futureKey 
    */
    @AuraEnabled public string futureKey{get;set;}
    /**
    * @description futureValues 
    */
    @AuraEnabled public List<ReplacementRefreshWrapperData.WrapperData> futureValues{get;set;}
  }
}