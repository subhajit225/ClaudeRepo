/**
* @File Name : ReplacementQuoteLineCreationExtension.cls
* @description :This class is extension class to ReplacementQuoteLineCreation which contians all the sub methods
* 
* @Author : Khushboo
* @Last Modified By :
* @Last Modified On : July 3, 2025
* @Modification Log :
* Test Class        : ReplacementQuoteLineCreationTest
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
**/
public WITHOUT SHARING class ReplacementQuoteLineCreationExtension {
    
    /***********************************************************************************************************
    * Method Name          : getQuoteLine
    * Date Created/Modified: 4/02/2025
    * Author               : Khushboo
    * @description         :  create quoteline 
    * @return              : Returns Quote Line data
    * @param quoteId
    * @param wrapper
    * @param product
    * @param pricebookEntryId
    * @param contractLineItemId
    * @param jsonData
    * @param groupId
    * @param assetNames
    * @param replacementMotion
    * @param type
    * @param EntIdToInactiveEnt
    * @param entitlementMap // FY25SR-1084
    * Test Class Methods   :
    ***********************************************************************************************************/
    public static SBQQ__Quoteline__c getQuoteLine(Id quoteId
        , ReplacementRefreshWrapperData.wrapperData wrapper
        , product2 product,id pricebookEntryId,String contractLineItemId
        , ReplacementJson jsonData,Id groupId,Set<String> assetNames
        , String replacementMotion,String type
        , Map<String,List<ReplacementJson.RelatedChildEntRowDetail>> EntIdToInactiveEnt
        , Map<Id, Entitlement> entitlementMap) {
            Boolean isConfigurable= false;//FY25SR-2385
            if(ReplacementQuoteLineCreation.ProductMap.containsKey(product.Id) &&
               !(ReplacementQuoteLineCreation.ProductMap.get(product.Id).IsHardwareNotRequiredForHybridLicense__c==false || 
               ReplacementQuoteLineCreation.ProductMap.get(product.Id).Family == 'Third Party License') 
               && new Set<String>{'Allowed', 'Required'}.contains(
                      ReplacementQuoteLineCreation.ProductMap.get(product.Id).SBQQ__ConfigurationType__c)){
                 isConfigurable= true;  
               }//FY25SR-2385
        Integer term= (wrapper!=null && wrapper.ReplacementTerm!=null) ?(Integer)wrapper.ReplacementTerm:1;
        SBQQ__QuoteLine__c QuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Number__c= ++ReplacementQuoteLineCreation.num,
            SBQQ__Quote__c = quoteId!=null ? quoteId : null,
            SBQQ__Product__c = product!=null ? product.Id : null,
            Replacement_Motion__c =replacementMotion!=null? replacementMotion :null,
            SBQQ__SubscriptionTerm__c = term!=null?term:null,
            SBQQ__Quantity__c = (wrapper!=null && wrapper.selectedquantity!=null)?wrapper.selectedquantity:1,
            RWD_Expected_Default_Quantity__c = (wrapper!=null && wrapper.selectedquantity!=null) 
                                             ? wrapper.selectedquantity:1,
            SBQQ__PricebookEntryId__c = pricebookEntryId!=null ? pricebookEntryId: null,
            SBQQ__RequiredBy__c=null,
            Product_Level__c = (product !=null && product.Product_Level__c!=null)? product.Product_Level__c : null,
            Product_Type__c = (product !=null && product.Product_Type__c!=null) ? product.Product_Type__c :null,//needed to identify v1/v2 sku
            Product_Code_Type__c = 
                (wrapper != null && wrapper.skuProdCodeType !=null && String.isNotBlank(wrapper.skuProdCodeType)) 
                ? wrapper.skuProdCodeType : null,
            SBQQ__SubscriptionPricing__c= 
                (product !=null && product.SBQQ__SubscriptionPricing__c!=null) 
                ? product.SBQQ__SubscriptionPricing__c :null,
            Category__c = (product !=null && product.Category__c!=null) ? product.Category__c :null,
            Arroyo_Subsumed_Old_Contract_Line_Items__c = contractLineItemId!=null
                ? product.Product_Type__c!=ReplacementConstants.HARDWARE
                    ? contractLineItemId:null:null,
            SBQQ__Group__c = groupId!=null? groupId: null,        
            Replacement_Details__c = jsonData!=null ? JSON.serialize(jsonData): null,
            TPH_OEM__c = wrapper != null && wrapper.tphOEM !=null ? wrapper.tphOEM : null,
            TPH_Models_Gen__c =  wrapper != null && wrapper.tphModels !=null ? wrapper.tphModels : null,
            TPH_Drive_Size__c =  wrapper != null && wrapper.tphDriveSize !=null ? wrapper.tphDriveSize : null,
            TPH_Quantity__c = wrapper != null && wrapper.tphQuantity !=null ? wrapper.tphQuantity : null,
            SBQQ__OptionLevel__c =  (isConfigurable && type!=ReplacementConstants.DISPOSE) ? null : 0,// to make the line non-configuration //FY25SR-2385
            SBQQ__OptionType__c=null,
            SBQQ__Bundle__c =  (type != ReplacementConstants.DISPOSE && isConfigurable) ? true :false,//FY25SR-2385
            Who_will_the_customer_be_buying_the_HW__c = 
                (wrapper!=null && wrapper.tphHWPurchasedFrom!=null)?wrapper.tphHWPurchasedFrom:null,
            Who_will_Install_CDM__c =  
                (wrapper!=null && wrapper.tphWhoWillDoImaging!=null)? wrapper.tphWhoWillDoImaging:null,
            V1_Quantity__c = 
                (wrapper!=null && wrapper.selectedquantity!=null)? wrapper.selectedquantity:1,
            Payment_Options__c = 
                (product !=null && product.Product_Payment_Option__c!=null) ? product.Product_Payment_Option__c : null,
            Support_Type__c = (wrapper!=null && wrapper.skuSuppType !=null && String.isNotBlank(wrapper.skuSuppType) ?
                wrapper.skuSuppType : ((product !=null && product.Support_Type__c!=null) ? product.Support_Type__c : null))
        );
        if(type==ReplacementConstants.QUOTE_TYPE_NEW){//expansion group
            QuoteLine.Special_Program__c = 
                (wrapper!=null && ReplacementQuoteLineCreation.DIS_REASON_SPECIAL_PROGRAM.containsKey(wrapper.selecteddisposition))
                ? ReplacementQuoteLineCreation.DIS_REASON_SPECIAL_PROGRAM.get(wrapper.selecteddisposition)
                :null;
            QuoteLine.Arroyo_Subscribed_Asset_Name__c = (assetNames!=null) 
                ? String.join(new List<String>(assetNames), ', ')
                :null;//FY25SR-1575 Removed HW Supp check
            Quoteline.Disposition_Reason__c = ReplacementConstants.DISPOSE_NONE;  
        } 
        if(type== ReplacementConstants.QUOTE_TYPE_RENEWAL){
            if(entitlementMap.containsKey(wrapper.entitlementId) 
            && entitlementMap.get(wrapper.entitlementId).ContractLineItem?.CPQ_Uplift__c != NULL){
                QuoteLine.CPQ_Uplift__c =entitlementMap.get(wrapper.entitlementId).ContractLineItem.CPQ_Uplift__c;// FY25SR-1663  
            }
        }
        if(type==ReplacementConstants.QUOTE_TYPE_RENEWAL 
        || type==ReplacementConstants.DISPOSE){//Renewal group OR Disposition group
            QuoteLine.Disposition_Reason__c = (wrapper!=null && wrapper.selecteddisposition!=null) 
                ? wrapper.selecteddisposition: null;
            QuoteLine.SubscribedAssetNames__c = assetNames!=null? String.join(new List<String>(assetNames), ', '):null;
            QuoteLine.Subscribed_Asset_Name__c = assetNames!=null ? String.join(new List<String>(assetNames), ', '): null;
            QuoteLine.SBQQSC__RenewedContractLine__c=
                (contractLineItemId!=null && !contractLineItemId.contains(','))? contractLineItemId: null;
            if(type==ReplacementConstants.QUOTE_TYPE_RENEWAL 
              && wrapper!=null && wrapper.renewalEndDate!=null){ //start FY25SR-1492
                QuoteLine.SBQQ__StartDate__c = (wrapper!=null && wrapper.EndDate!=null) ? wrapper.EndDate+1 :null; 
                QuoteLine.SBQQ__EndDate__c=wrapper.renewalEndDate!=null ? wrapper.renewalEndDate :null;
            }
            else if(type==ReplacementConstants.QUOTE_TYPE_RENEWAL){ ///FY25SR-2247
                QuoteLine.SBQQ__StartDate__c = (wrapper!=null && wrapper.EndDate!=null) ? wrapper.EndDate+1 :null;
                QuoteLine.SBQQ__EndDate__c =(wrapper!=null && wrapper.EndDate!=null && term!=null) 
                    ? wrapper.EndDate.addMonths(term): null;   
            } //end FY25SR-1492
            else{ //start FY25SR-2247 only for dispose lines
                QuoteLine.SBQQ__StartDate__c = (wrapper!=null && wrapper.StartDate!=null) ? wrapper.StartDate :null;
                QuoteLine.SBQQ__EndDate__c =(wrapper!=null && wrapper.EndDate!=null) ? wrapper.EndDate: null;
                QuoteLine.SBQQ__SubscriptionTerm__c =(wrapper!=null && wrapper.entitlementId!=null 
                     && entitlementMap.containsKey(wrapper.entitlementId) && entitlementMap.get(wrapper.entitlementId).Subscription_Term__c!=null) 
                    ? entitlementMap.get(wrapper.entitlementId).Subscription_Term__c :null;
            }//end FY25SR-2247
        }
        //FY25SR-1084 START
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.SBQQ__QuoteLine__c.fields.getMap();
        if(wrapper !=NULL && wrapper.skuAttributesToQuoteLine != NULL){            
            for(String str: wrapper.skuAttributesToQuoteLine.keyset()){
                Object fieldValue;
                //Added snapshotId for Smart approval
                if(str != 'snapshotId' 
                 && wrapper.skuAttributesToQuoteLine.containsKey(str) 
                 && wrapper.skuAttributesToQuoteLine.get(str) != NULL 
                 && wrapper.skuAttributesToQuoteLine.get(str) != 'null' 
                 && !String.isBlank(wrapper.skuAttributesToQuoteLine.get(str))){
                     Schema.DisplayType fieldType = fieldMap.containsKey(str)
                        ? fieldMap.get(str).getDescribe().getType() :null;
                    if(fieldType!=null){
                    if (fieldType == Schema.DisplayType.Currency ||
                        fieldType == Schema.DisplayType.Double ||
                        fieldType == Schema.DisplayType.Percent) {
                            fieldValue = Decimal.valueOf(wrapper.skuAttributesToQuoteLine.get(str));
                        } else if (fieldType == Schema.DisplayType.Integer) {
                            fieldValue = Integer.valueOf(wrapper.skuAttributesToQuoteLine.get(str));
                        } else if (fieldType == Schema.DisplayType.String ||
                            fieldType == Schema.DisplayType.TextArea ||
                            fieldType == Schema.DisplayType.Phone ||
                            fieldType == Schema.DisplayType.Email ||
                            fieldType == Schema.DisplayType.Url ||
                            fieldType == Schema.DisplayType.Picklist) {
                            fieldValue = wrapper.skuAttributesToQuoteLine.get(str);
                        }
                    }
                    if(fieldValue!=null)
                    QuoteLine.put(str, fieldValue);                     
                } else {
                    //FY26WL-227 - Start
                    if(wrapper.skuAttributesToQuoteLine.containsKey(str) 
                    && !String.isBlank(wrapper.skuAttributesToQuoteLine.get(str))
                    && wrapper.skuAttributesToQuoteLine.get(str) != 'null'
                    && !ReplacementQuoteLineCreationHelper.skuDispositions.contains(QuoteLine.Disposition_Reason__c) ) {
                       QuoteLine.put(Constants.TEMP_VARIABLE_QL, wrapper.skuAttributesToQuoteLine.get(str)); 
                    }
                    //FY26WL-227- END
                }
            }
        }else if(wrapper !=NULL && wrapper.skuAttributesToQuoteLine == NULL) {
            if(entitlementMap.containsKey(wrapper.entitlementId) && entitlementMap.get(wrapper.entitlementId) != NULL){
                if(entitlementMap.get(wrapper.entitlementId).Product__c != null){
                    QuoteLine.Product_Code_Type__c = 
                        SKUNewReplacementController.mapProductCodeType(
                            entitlementMap.get(wrapper.entitlementId).Product__r.Product_Type__c
                          , entitlementMap.get(wrapper.entitlementId).Product__r.Product_Subtype__c
                          , entitlementMap.get(wrapper.entitlementId).Product__r.Description
                          , entitlementMap.get(wrapper.entitlementId).Product__r.ProductCode);
                }
                if(entitlementMap.get(wrapper.entitlementId).ContractLineItemId != NULL){
                    QuoteLine.Storage_Region_Bundle_FrontEnd__c = 
                        entitlementMap.get(wrapper.entitlementId).ContractLineItem.Storage_Region_Bundle_FrontEnd__c;
                    QuoteLine.Storage_Tier__c =
                         entitlementMap.get(wrapper.entitlementId).ContractLineItem.Storage_Tier__c;
                    QuoteLine.Storage_Region_Bundle__c  = 
                        entitlementMap.get(wrapper.entitlementId).ContractLineItem.Storage_Region_Bundle__c;  
                }
                if(entitlementMap.get(wrapper.entitlementId).ContractLineItem.SBQQSC__OriginalQuoteLine__c != NULL){
                    QuoteLine.Storage_Region_Bundle_FrontEnd__c = 
                        entitlementMap.get(
                            wrapper.entitlementId).ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Region_Bundle_FrontEnd__c;
                    QuoteLine.Storage_Tier__c = 
                        entitlementMap.get(
                            wrapper.entitlementId).ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Tier__c; 
                    QuoteLine.Storage_Region_Bundle__c  = 
                        entitlementMap.get(
                            wrapper.entitlementId).ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Region_Bundle__c; 
                }
                QuoteLine.Rubrik_Hosted_M365_Quantity__c = 
                    entitlementMap.get(
                        wrapper.entitlementId
                    ).ContractLineItem.SBQQSC__OriginalQuoteLine__r.Rubrik_Hosted_M365_Quantity__c;
                QuoteLine.Atlassian_Quantity__c = 
                    entitlementMap.get(
                        wrapper.entitlementId
                    ).ContractLineItem.SBQQSC__OriginalQuoteLine__r.Atlassian_Quantity__c;
                QuoteLine.Salesforce_Quantity__c = 
                    entitlementMap.get(
                        wrapper.entitlementId
                    ).ContractLineItem.SBQQSC__OriginalQuoteLine__r.Salesforce_Quantity__c;
                QuoteLine.Dynamics_Quantity__c = 
                    entitlementMap.get(
                        wrapper.entitlementId
                    ).ContractLineItem.SBQQSC__OriginalQuoteLine__r.Dynamics_Quantity__c;
            }
        }
        //to combine contractLineItemId of inactive entitlements to active entitlement
        List<String> cliIds=new List<String>();
        if(EntIdToInactiveEnt!=null 
          && !EntIdToInactiveEnt.isEmpty() 
          && EntIdToInactiveEnt.containsKey(wrapper.entitlementId+'-'+wrapper.customIndex)){
            for(ReplacementJson.RelatedChildEntRowDetail inactiveEnt:
                EntIdToInactiveEnt.get(wrapper.entitlementId+'-'+wrapper.customIndex))
            {
                String cli=entitlementMap.get(inactiveEnt.ChildEntId).ContractLineItemId !=null 
                          ? entitlementMap.get(inactiveEnt.ChildEntId).ContractLineItemId :null;
                cliIds.add(cli);
            }
        }
        if(cliIds!=null && !cliIds.isEmpty()){
            QuoteLine.Arroyo_Subsumed_Old_Contract_Line_Items__c+=','+String.join(cliIds, ',');
        }
        
        //CPQ22-5954 - start
        // Describe the Quote Line object
        Map<String, Schema.SObjectField> fieldsMap = 
            Schema.getGlobalDescribe().get(ReplacementConstants.QUOTELINE_OBJ_API).getDescribe().fields.getMap();//Describe QL object
        if(wrapper != null && jsonData != null) {
            if(!String.isBlank(wrapper.entitlementId) && jsonData.mode != null && (jsonData.mode != ReplacementConstants.MANY_TO_1 && jsonData.mode != ReplacementConstants.DISPOSE) || 
            (jsonData.mode == ReplacementConstants.DISPOSE && QuoteLine.Disposition_Reason__c != null 
                && QuoteLine.Disposition_Reason__c == ReplacementConstants.DISPOSTION_RENEWING)) {// Skip many to many
            for(String fieldName : ReplacementQueryController.fetchDeletionQuoteLineFields()) {// Get all metadata field
                if (!fieldsMap.containsKey(fieldName)) {
                    continue; // Skip unknown fields
                }
                if(wrapper.skuAttributesToQuoteLine != null && wrapper.skuAttributesToQuoteLine.containsKey(fieldName)) {//Get attributes from Wrapper
                Schema.DisplayType fieldType = fieldsMap.get(fieldName).getDescribe().getType(); //Field data type
                String value = wrapper.skuAttributesToQuoteLine.get(fieldName);//Field value
                switch on fieldType {
                    when STRING {
                        quoteLine.put(fieldName, value);
                    }
                    when Integer {
                        quoteLine.put(fieldName, Integer.valueOf(value));
                    }
                    when Double {
                        quoteLine.put(fieldName, Double.valueOf(value));
                    }
                    when Currency {
                        quoteLine.put(fieldName, Decimal.valueOf(value));
                    }
                    when Boolean {
                        quoteLine.put(fieldName, Boolean.valueOf(value));
                    }
                    when Date {
                        quoteLine.put(fieldName, Date.valueOf(value));
                    }
                    when DateTime {
                        quoteLine.put(fieldName, Datetime.valueOf(value));
                    }
                }
                }
                QuoteLine.IsDiscCal__c = true; //FY25SR-2361
            }
            }
        }
        
      //CPQ22-5954 -end
        return QuoteLine;   
    }
    /***********************************************************************************************************
    * Method Name          : calculateQuantityforV1
    * Date Created/Modified: 10/02/2025
    * Author               : Khushboo
    * @description         :  calculate QLi quantity if the source product is v1 and in case of ManyTo1
    * @param qLItems
    * @param CalculateQtyCPQDisposeLines
    * @param sourceSKUPolarisMapping
    * @param assetNameQuantityMap
    * @param productMap
    * Test Class Methods   :
    ***********************************************************************************************************/
    public static void calculateQuantityforV1(List<SBQQ__QuoteLine__c> qLItems
        , List<CPQ_Disposition_Quote_Line__c> CalculateQtyCPQDisposeLines
        , Map <Id, Polaris_SKU_Mapping_V2__c> sourceSKUPolarisMapping
        , Map<String,Asset> assetNameQuantityMap
        , Map<Id, Product2> productMap) 
    {
        Map<String, SBQQ__QuoteLine__c> consolidateKeyNewQuoteLineInstMap = new Map<String, SBQQ__QuoteLine__c>(); // FY25SR-1215 - To store consolidated lines
        //for SBQQ__QuoteLine__c
        if(qLItems!=null && !qLItems.isEmpty()){
            for(SBQQ__QuoteLine__c qLine:qLItems){ 
                Decimal parentlineQuantity = 0;
                Boolean nonAstbased = false;
                List<String> lstProductTypes = !String.isBlank(System.Label.CustomRenewalProductType) ? System.Label.CustomRenewalProductType.split(',') : null; // ITNPI-3222 
                if(String.isBlank(qLine.SubscribedAssetNames__c) 
                 && String.isBlank(qLine.Arroyo_Subscribed_Asset_Name__c) && !(lstProductTypes != null && lstProductTypes.contains(qLine.Product_Type__c) && qLine.Disposition_Reason__c == ReplacementConstants.DISPOSTION_RENEWING &&
                  sourceSKUPolarisMapping!=null && !sourceSKUPolarisMapping.isEmpty() && sourceSKUPolarisMapping.get(qLine.SBQQ__Product__c)!=null && sourceSKUPolarisMapping?.get(qLine.SBQQ__Product__c)?.Old_Product__r?.Custom_Renewal_Type__c == 'V2 To V2')) {
                    parentlineQuantity = getNonAssetBasedQuantity(qLine,null,productMap,sourceSKUPolarisMapping);
                    nonAstbased = true;
                }
                
                if(String.isNotBlank(qLine.SubscribedAssetNames__c) 
                    || String.isNotBlank(qLine.Arroyo_Subscribed_Asset_Name__c)) {
                    List<String> AssetNames= String.isNotBlank(qLine.SubscribedAssetNames__c)
                                   ? qLine.SubscribedAssetNames__c.split(',') 
                                   : qLine.Arroyo_Subscribed_Asset_Name__c.split(',');
                if(AssetNames!=null && !AssetNames.isEmpty()){
                    if(productMap.containsKey(qLine.SBQQ__Product__c) && productMap.get(qLine.SBQQ__Product__c).ProductCode.contains('NRD')){//start FY25SR-2112 NRD Changes
                    parentlineQuantity= AssetNames.size();
                    }
                    else{
                for(String assetName:AssetNames) {
                    assetName = assetName.trim();
                        if(!assetNameQuantityMap.isEmpty() && assetNameQuantityMap.containsKey(assetName)) {
                        Asset objAsset =  assetNameQuantityMap.get(assetName);
                        if(objAsset.Product_Usable_Capacity__c != null && objAsset.Product_Usable_Capacity__c != 0) {
                            parentlineQuantity = parentlineQuantity + objAsset.Product_Usable_Capacity__c;
                        } else if((objAsset.Product_Usable_Capacity__c == null 
                                        || objAsset.Product_Usable_Capacity__c == 0) 
                            && objAsset.SBQQSC__CurrentContractLineItem__c != null  
                            && objAsset.SBQQSC__CurrentContractLineItem__r.SBQQSC__RequiredByProduct__r.Usable_Capacity__c != null
                        ) {
                            parentlineQuantity = 
                                parentlineQuantity + objAsset.SBQQSC__CurrentContractLineItem__r.SBQQSC__RequiredByProduct__r.Usable_Capacity__c;
                        } else if((objAsset.Product_Usable_Capacity__c == null 
                                        || objAsset.Product_Usable_Capacity__c == 0)
                            && objAsset.SBQQSC__CurrentContractLineItem__c != null 
                            && objAsset.SBQQSC__CurrentContractLineItem__r.SBQQSC__RequiredByProduct__c == null) {
                            parentlineQuantity = 
                                parentlineQuantity + objAsset.SBQQSC__CurrentContractLineItem__r.SBQQSC__Quantity__c;
                        }
                    } else { //This happens when replacement SKU is not selected for example, Renew Now disposition
                        parentlineQuantity = parentlineQuantity + qLine.SBQQ__Quantity__c;
                    }            
                }//end of For
               }
             }   
                } //end of if
                
                if(parentlineQuantity != null && parentlineQuantity != 0) {
                    qLine.SBQQ__Quantity__c = parentlineQuantity;
                    qLine.RWD_Expected_Default_Quantity__c = qLine.SBQQ__Quantity__c;
                    if (nonAstbased) {
                        String oldProd = qLine.SBQQ__Product__c;
                        if (oldProd!=null && productMap.containsKey(oldProd) 
                         && productMap.get(oldProd).Product_Level__c == null
                         && sourceSKUPolarisMapping.containsKey(oldProd) 
                         && sourceSKUPolarisMapping.get(oldProd).Quantity_Mapping_Type__c == ReplacementConstants.PRODUCT_QTY_MAPPING_TYPE) {
                            Decimal qty = ReplacementQuoteLineCreation.contractLineCapacity.get(qLine.SBQQSC__RenewedContractLine__c) != null 
                                        ? ReplacementQuoteLineCreation.contractLineCapacity.get(qLine.SBQQSC__RenewedContractLine__c) : 0;
                            qty = qty * sourceSKUPolarisMapping.get(oldProd).Quantity_Ratio__c;
                            qLine.Related_Asset_Total_Capacity__c = qty;
                        }
                    } else {
                        qLine.Related_Asset_Total_Capacity__c = 
                            ReplacementQuoteLineCreation.contractLineCapacity.get(qLine.SBQQSC__RenewedContractLine__c) != null 
                            ? ReplacementQuoteLineCreation.contractLineCapacity.get(qLine.SBQQSC__RenewedContractLine__c) 
                            : qLine.SBQQ__Quantity__c;
                    }
                }
                /** //FY25SR-1215 - Consolidation Changes */
                consolidateLines(sourceSKUPolarisMapping, qLine, consolidateKeyNewQuoteLineInstMap);
            }
        }
        
        //for CPQ_Disposition_Quote_Line__c
        if(CalculateQtyCPQDisposeLines!=null && !CalculateQtyCPQDisposeLines.isEmpty()){
            for(CPQ_Disposition_Quote_Line__c disposeLine:CalculateQtyCPQDisposeLines){ 
                Decimal parentlineQuantity = 0;
                if(String.isBlank(disposeLine.Arroyo_Subscribed_Asset_Name__c)) {
                    parentlineQuantity = getNonAssetBasedQuantity(null,disposeLine,productMap,sourceSKUPolarisMapping);
                }
                
                if(String.isNotBlank(disposeLine.Arroyo_Subscribed_Asset_Name__c)) {
                    List<String> AssetNames= disposeLine.Arroyo_Subscribed_Asset_Name__c.split(',');
                    for(String assetName:AssetNames) {
                        assetName = assetName.trim();
                        if(!assetNameQuantityMap.isEmpty() && assetNameQuantityMap.containsKey(assetName)) {
                            Asset objAsset =  assetNameQuantityMap.get(assetName);
                            if(objAsset.Product_Usable_Capacity__c != null && objAsset.Product_Usable_Capacity__c != 0) {
                                parentlineQuantity = parentlineQuantity + objAsset.Product_Usable_Capacity__c;
                            } else if((objAsset.Product_Usable_Capacity__c == null 
                                            || objAsset.Product_Usable_Capacity__c == 0) 
                                && objAsset.SBQQSC__CurrentContractLineItem__c != null  
                                && objAsset.SBQQSC__CurrentContractLineItem__r.SBQQSC__RequiredByProduct__r.Usable_Capacity__c != null
                            ) {
                                parentlineQuantity = parentlineQuantity + objAsset.SBQQSC__CurrentContractLineItem__r.SBQQSC__RequiredByProduct__r.Usable_Capacity__c;
                            } else if((objAsset.Product_Usable_Capacity__c == null 
                                            || objAsset.Product_Usable_Capacity__c == 0) 
                                && objAsset.SBQQSC__CurrentContractLineItem__c != null 
                                && objAsset.SBQQSC__CurrentContractLineItem__r.SBQQSC__RequiredByProduct__c == null) {
                                parentlineQuantity = 
                                    parentlineQuantity + objAsset.SBQQSC__CurrentContractLineItem__r.SBQQSC__Quantity__c;
                            }
                        } else { //This happens when replacement SKU is not selected for example, Renew Now disposition
                            parentlineQuantity = parentlineQuantity + disposeLine.Quantity__c;
                        }            
                    }//end of For
                } //end of if
                if(parentlineQuantity != null && parentlineQuantity != 0) {
                    disposeLine.Quantity__c = parentlineQuantity;
                }
            }
        }
    }
    /***********************************************************************************************************
    * Method Name          : getNonAssetBasedQuantity
    * Date Created/Modified: 10/02/2025
    * Author               : Khushboo
    * @description         :  calculate QLi quantity if Product is non-asset based
    * @return               : Quantity after V1 to V2 conversion
    * @param quoteLine
    * @param disposeline
    * @param productMap
    * @param sourceSKUPolarisMapping
    * Test Class Methods   :
    ***********************************************************************************************************/  
    public static Decimal getNonAssetBasedQuantity(SBQQ__QuoteLine__c quoteLine
        , CPQ_Disposition_Quote_Line__c disposeline, Map<Id, Product2> productMap
        , Map <Id, Polaris_SKU_Mapping_V2__c>  sourceSKUPolarisMapping) 
    {
        Decimal nonAssetQuantity = 0;
        ReplacementJson qliReplaceJSON = quoteLine!=null
                        ? (ReplacementJson)JSON.deserialize(quoteLine.Replacement_Details__c, ReplacementJson.class)
                        : (ReplacementJson)JSON.deserialize(disposeline.Replacement_Detail__c, ReplacementJson.class);
        //Iterate on the rowdetails of quoteline
        if (qliReplaceJSON != null && qliReplaceJSON.rowValues != null) {
            for (ReplacementJson.RowDetail childRow : qliReplaceJSON.rowValues) {
                String oldProd= ReplacementQuoteLineCreation.entitlementMap.containsKey(childRow.entId)
                              ? ReplacementQuoteLineCreation.entitlementMap.get(childRow.entId).Product__r.id
                              :null;
                if(oldProd!=null && productMap.containsKey(oldProd) 
                 && productMap.get(oldProd).Product_Level__c == null 
                 && sourceSKUPolarisMapping.containsKey(oldProd) 
                 && sourceSKUPolarisMapping.get(oldProd).Quantity_Mapping_Type__c == ReplacementConstants.PRODUCT_QTY_MAPPING_TYPE)
                {
                    nonAssetQuantity = nonAssetQuantity + (childRow.selectedQty * sourceSKUPolarisMapping.get(oldProd).Quantity_Ratio__c);
                } else {
                    nonAssetQuantity = nonAssetQuantity + childRow.selectedQty;
                }
            }
        }
        return nonAssetQuantity;
    }
    /***********************************************************************************************************
    * Method Name          : v1tov2Conversion
    * Date Created/Modified: 
    * @description         : convert v1 product to v2 
    * Author               : Khushboo
    * Purpose              :  Perform conversion of v1 products to v2 format.
    * @param     quoteLinesInsertionList
    * @param     cpqDisposeLinesInsertionList
    * @param     sourceSKUPolarisMap
    * @param     assetSerialMap
    * @param     v2MappingforHWsupport
    * @param     sourceSKUMultiMapping
    * @param     isConverted
    * Test Class Methods   :
    ***********************************************************************************************************/
    public static void v1tov2Conversion(
         List<SBQQ__QuoteLine__c> quoteLinesInsertionList
       , List<CPQ_Disposition_Quote_Line__c> cpqDisposeLinesInsertionList
       , Map<Id,Polaris_SKU_Mapping_V2__c> sourceSKUPolarisMap
       , Map<String, Asset> assetSerialMap
       , Map <String, Polaris_SKU_Mapping_V2__c> v2MappingforHWsupport
       , Map<String,Multi_Mapping_V2_Conversion__c> sourceSKUMultiMapping
       , List<String> isConverted) {  
        List<String> lstProductTypes = !String.isBlank(System.Label.CustomRenewalProductType) ? System.Label.CustomRenewalProductType.split(',') : null;  //ITNPI-3222 
        //Add the converted product to the quote line
        if(quoteLinesInsertionList!=null && !quoteLinesInsertionList.isEmpty()){
            for (SBQQ__QuoteLine__c quoteLine : quoteLinesInsertionList) {
                //SW Support
                //HW Supp CNV
                if(quoteLine.Product_Level__c == null) {
                    /**FY25SR-1215 - Changes for Consolidation */
                    //Blank out total fields if consolidation has not happened
                    if(String.isBlank(quoteLine.CCLI__c) 
                      && (quoteLine.Total_Prior_Net_Total__c != null 
                       || quoteLine.Total_Prior_Net_Total_With_Uplift__c != null)) {
                        quoteLine.Total_Prior_Net_Total__c = null;
                        quoteLine.Total_Prior_Net_Total_With_Uplift__c = null;
                    }
                    /**FY25SR-1215 - Changes for Consolidation Ends */
                    String PolarisMappingKey;
                    String MultiMappingKey= 
                        quoteLine.SBQQ__Product__c+'-'+(quoteLine.Support_Type__c!=null
                                ?quoteLine.Support_Type__c
                                :' ')+'-'+(quoteLine.Product_Payment_Option__c!=null
                                    ?quoteLine.Product_Payment_Option__c:' ');
                    
                    //FY25SR-1575 added Arroyo_Subscribed_Asset_Name__c. Added fix for hwsupptAsset. Added fix for Support_Tier__c
                    if(quoteLine.Product_Type__c==ReplacementConstants.HW_SUPPORT 
                        && !assetSerialMap.isEmpty() 
                        && (String.isNotBlank(quoteLine.SubscribedAssetNames__c) 
                            || String.isNotBlank(quoteLine.Arroyo_Subscribed_Asset_Name__c)) 
                            && (assetSerialMap.containsKey(quoteLine.SubscribedAssetNames__c) 
                            || assetSerialMap.containsKey(quoteLine.Arroyo_Subscribed_Asset_Name__c) )){
                        Asset hwsupptAsset;
                        if (String.isNotBlank(quoteLine.SubscribedAssetNames__c)) {
                            hwsupptAsset = assetSerialMap.get(quoteLine.SubscribedAssetNames__c) ;
                        } else if (String.isNotBlank(quoteLine.Arroyo_Subscribed_Asset_Name__c)) {
                            hwsupptAsset = assetSerialMap.get(quoteLine.Arroyo_Subscribed_Asset_Name__c) ;
                        }
                        String hwSuppTier = hwsupptAsset.Support_Tier__c!=null 
                                          ? hwsupptAsset.Support_Tier__c 
                                          : hwsupptAsset.Product2.HW_Support_Tier__c;
                        PolarisMappingKey= quoteLine.SBQQ__Product__c+'-'
                                         +(hwSuppTier !=null ? hwSuppTier :' ')+'-'
                                         +(hwsupptAsset.Support_Type__c!=null?hwsupptAsset.Support_Type__c :' ') +'-'
                                         +(hwsupptAsset.Payment_Options__c!=null?hwsupptAsset.Payment_Options__c:' ');  
                        //FY25SR-1575 Ends
                        MultiMappingKey = MultiMappingKey + '-' + hwsupptAsset;//FY25SR-1592
                    }else{
                        PolarisMappingKey= quoteLine.SBQQ__Product__c+'-'
                            +(quoteLine.Support_Tier__c!=null ?quoteLine.Support_Tier__c:' ')+'-'
                            +(quoteLine.Support_Type__c!=null?quoteLine.Support_Type__c:' ')+'-'
                            +(quoteLine.Payment_Options__c!=null?quoteLine.Payment_Options__c:' ');
                        MultiMappingKey = MultiMappingKey + '-' + quoteLine.Support_Tier__c;//FY25SR-1592
                    }
                    //H/w support bssed on Support tier so made it generic
                    //FY25SR-2352 start 
                    Id targetProduct;
                    if(v2MappingforHWsupport!=null && !v2MappingforHWsupport.isEmpty() && v2MappingforHWsupport.containsKey(PolarisMappingKey) && !(lstProductTypes != null && lstProductTypes.contains(quoteLine.Product_Type__c) && quoteLine.Disposition_Reason__c == ReplacementConstants.DISPOSTION_RENEWING && v2MappingforHWsupport?.get(PolarisMappingKey)?.Old_Product__r?.Custom_Renewal_Type__c == 'V2 To V2') ){  //ITNPI-3222
                        targetProduct = v2MappingforHWsupport.get(PolarisMappingKey).New_Product__c;
                    }
                    //FY25SR-2352 - pick first mapping if no match
                    else if (sourceSKUPolarisMap!=null && !sourceSKUPolarisMap.isEmpty() && sourceSKUPolarisMap.containsKey(quoteLine.SBQQ__Product__c) && !(lstProductTypes != null && lstProductTypes.contains(quoteLine.Product_Type__c) && quoteLine.Disposition_Reason__c == ReplacementConstants.DISPOSTION_RENEWING && sourceSKUPolarisMap?.get(quoteLine.SBQQ__Product__c)?.Old_Product__r?.Custom_Renewal_Type__c == 'V2 To V2')){  //ITNPI-3222
                        targetProduct = sourceSKUPolarisMap.get(quoteLine.SBQQ__Product__c).New_Product__c;
                    }
                    else {
                        System.debug(LoggingLevel.DEBUG, 'Mapping is not available for '+ quoteLine.SBQQ__Product__r.Productcode);
                    }

                    //FY25SR-2352 moved common logic
                    if (targetProduct != null){
                        quoteLine.SBQQ__Product__c = targetProduct;
                        quoteLine.SBQQ__PricebookEntryId__c = 
                            ReplacementQuoteLineCreation.productPricebookEntryMap.get(targetProduct);
                        isConverted.add('true');
                    }
                    //FY25SR-2352 end 
                    swapRenProdsonQL(quoteLine
                        , ReplacementQuoteLineCreation.productMap
                        , ReplacementQuoteLineCreation.productPricebookEntryMap
                        , quoteLine.SBQQ__Product__c);//FY25SR-1663
                }
                
            }
        }
        if(cpqDisposeLinesInsertionList!=null && !cpqDisposeLinesInsertionList.isEmpty()){
            for (CPQ_Disposition_Quote_Line__c cpqLine : cpqDisposeLinesInsertionList) {
                if(ReplacementQuoteLineCreation.productMap.get(cpqLine.Product__c).Product_Level__c == null) {
                    Product2 prod=ReplacementQuoteLineCreation.productMap.get(cpqLine.Product__c);
                    String PolarisMappingKey;
                    String MultiMappingKey= cpqLine.Product__c+'-'
                        +(prod.Support_Type__c!=null?prod.Support_Type__c:' ')+'-'
                        +(prod.Product_Payment_Option__c!=null?prod.Product_Payment_Option__c:' ');
                    
                    if(prod.Product_Type__c==ReplacementConstants.HW_SUPPORT 
                      && !assetSerialMap.isEmpty() 
                      && String.isNotBlank(cpqLine.Arroyo_Subscribed_Asset_Name__c) 
                      && assetSerialMap.containsKey(cpqLine.Arroyo_Subscribed_Asset_Name__c)){
                        Asset hwsupptAsset;
                        if (String.isNotBlank(cpqLine.Arroyo_Subscribed_Asset_Name__c)) {
                            hwsupptAsset = assetSerialMap.get(cpqLine.Arroyo_Subscribed_Asset_Name__c) ;
                        }
                        String hwSuppTier = hwsupptAsset.Support_Tier__c!=null ? hwsupptAsset.Support_Tier__c : hwsupptAsset.Product2.HW_Support_Tier__c;
                        PolarisMappingKey= cpqLine.Product__c+'-'
                            +(hwSuppTier !=null ? hwSuppTier :' ')+'-'
                            +(hwsupptAsset.Support_Type__c!=null?hwsupptAsset.Support_Type__c :' ') +'-'
                            +(hwsupptAsset.Payment_Options__c!=null?hwsupptAsset.Payment_Options__c:' '); 
                        MultiMappingKey = MultiMappingKey + '-' + hwsupptAsset;//FY25SR-1592
                    }else{
                        PolarisMappingKey= cpqLine.Product__c+'-'
                            +(prod.Support_Tier__c!=null ?prod.Support_Tier__c:' ')+'-'
                            +(prod.Support_Type__c!=null?prod.Support_Type__c:' ')+'-'
                            +(prod.Product_Payment_Option__c!=null?prod.Product_Payment_Option__c:' ');
                        MultiMappingKey = MultiMappingKey + '-' + prod.Support_Tier__c;//FY25SR-1592
                    }
                    //H/w support bssed on Support tier so made it generic
                    if(!v2MappingforHWsupport.isEmpty() && v2MappingforHWsupport.containsKey(PolarisMappingKey) )
                    {
                        cpqLine.Product__c = v2MappingforHWsupport.get(PolarisMappingKey).New_Product__c;
                        cpqLine.PricebookEntryId__c = 
                            ReplacementQuoteLineCreation.productPricebookEntryMap.get(cpqLine.Product__c);
                    }
                    else {
                        System.debug(LoggingLevel.DEBUG, 'Mapping is not available for '+ prod.Productcode);
                    }
                    swapRenProdsonDQL(cpqLine, ReplacementQuoteLineCreation.productMap, cpqLine.Product__c);//FY25SR-1663
                }
            }
        }
    }
    /***********************************************************************************************************
    * Method Name          : getHWSpprtQuoteLine
    * Date Created/Modified: 12/02/2025
    * Author               : Khushboo
    * @description         : Generates a list of H/w support quotelines
    * Purpose              : Generates a list of H/w Support Quotelines in case of Support switch //FY25SR-1086.
    * @param  quoteId
    * @param  ParentwrapperEntId
    * @param  ParentProductType
    * @param  term
    * @param  parentrenewalEndDate
    * @param  HwEntIdagainstBaseEntId
    * @param  assetNames
    * @param  groupId
    * @param  SupportType
    * @param  v2MappingforHWsupport
    * @param  assetSerialMap
    * @param  ParentDispose
    * @param  EntIdToInactiveEnt
    * @param  selectedSupportRefreshEntids
    * @param entitlementMap //FY25SR-1084
    * @return ListOfQuoteLines
    * Test Class Methods   :
    **********************************************************************************************************/
    public static List<SBQQ__Quoteline__c> getHWSpprtQuoteLine(Id quoteId
        , Id ParentwrapperEntId
        , String ParentProductType
        , Integer term
        , Date parentrenewalEndDate
        , Map<String,ReplacementRefreshWrapperData.wrapperData> HwEntIdagainstBaseEntId
        , Set<String> assetNames
        , Id groupId
        , String SupportType
        , Map <String, Polaris_SKU_Mapping_V2__c> v2MappingforHWsupport
        , Map<String, Asset> assetSerialMap
        , String ParentDispose
        , Map<String,List<ReplacementJson.RelatedChildEntRowDetail>> EntIdToInactiveEnt
        , Set<Id> selectedSupportRefreshEntids
        , Map<Id, Entitlement> entitlementMap)//FY25SR-1492, 1084
    {
        List<SBQQ__QuoteLine__c> HwQLI=new List<SBQQ__QuoteLine__c>();
        if(assetNames!=null){
            for(String asst:assetNames){
                 if(HwEntIdagainstBaseEntId.containsKey(asst)){
                    ReplacementRefreshWrapperData.wrapperData hwsupport= HwEntIdagainstBaseEntId.get(asst);
                    //exclude ent lines which are selected in refresh window.
                    if(selectedSupportRefreshEntids==null 
                     || (selectedSupportRefreshEntids!=null 
                     && !selectedSupportRefreshEntids.contains(hwsupport.entitlementId))){
                        //check if hwsupport.productId is in v1 then convert it into v2
                        String v2Prod;
                        String key;
                        String HWSuppCode;
                        Asset hwAsset= assetSerialMap.get(asst);
                        if(ReplacementQuoteLineCreation.ProductMap.get(hwsupport.productId).Product_Level__c == null){
                            //FY25SR-1575 Added fix for Support Tier
                            String hwSuppTier = hwAsset.Support_Tier__c!=null
                                ? hwAsset.Support_Tier__c 
                                : hwAsset.Product2.HW_Support_Tier__c ; 
                                key= hwsupport.productId+'-'
                              +(hwSuppTier != null ? hwSuppTier : ' ')+'-'
                              +(hwAsset.Support_Type__c!=null?hwAsset.Support_Type__c :' ')+'-'
                              +(hwAsset.Payment_Options__c!=null?hwAsset.Payment_Options__c:' '); 
                            //FY25SR-1575 Ends
                             if(!v2MappingforHWsupport.isEmpty() && v2MappingforHWsupport.containsKey(key) ){
                                v2Prod = v2MappingforHWsupport.get(key).New_Product__r.Productcode;
                                HWSuppCode=v2Prod;
                               }
                            if(HWSuppCode == null){
                               HWSuppCode=ReplacementQuoteLineCreation.ProductMap.get(hwsupport.productId).ProductCode; 
                            }
                        }
                        else{
                            HWSuppCode=ReplacementQuoteLineCreation.ProductMap.get(hwsupport.productId).ProductCode;
                        }if(ParentProductType.contains(ReplacementConstants.PRODUCT_TYPE_COMPLETE)){ 
                            // for complete edition, H/W support should be always in PE
                            if(SupportType == ReplacementConstants.SUPPORT_TYPE_L3_BASIC){
                                HWSuppCode=System.Label.ReplacemnetLBSupportSwitchCode;
                            }//RS-HW-SVC-LB-S2
                            if(SupportType == ReplacementConstants.SUPPORT_TYPE_BASIC){
                                HWSuppCode=System.Label.ReplacemnetBSSupportSwitchCode;
                            }//RS-HW-SVC-BS-S2
                            
                        }else{
                            //add L3 Basic, Basic (Replacement category is not null on L3 and L3 Basic License)
                            if(SupportType==ReplacementConstants.SUPPORT_TYPE_PRIMIUM){
                                HWSuppCode=HWSuppCode.replaceAll('L3|LB|BS', ReplacementConstants.SUPPORT_TYPE_PE);
                            }
                            else if(SupportType==ReplacementConstants.SUPPORT_TYPE_L3){
                                HWSuppCode=HWSuppCode.replaceAll('PE|LB|BS', ReplacementConstants.SUPPORT_TYPE_L3);
                            }
                        }
                        //if new H/W sku does not present then we take source H/W only
                        Product2 productt=ReplacementQuoteLineCreation.ProductByCode.containsKey(HWSuppCode)
                            ? ReplacementQuoteLineCreation.ProductByCode.get(HWSuppCode)
                            : ReplacementQuoteLineCreation.ProductMap.get(hwsupport.productId);
                        Id pricebookEntryIdd = ReplacementQuoteLineCreation.productPricebookEntryMap.containsKey(productt.Id)
                            ? ReplacementQuoteLineCreation.productPricebookEntryMap.get(productt.Id)
                            : null;
                        Id contractLineItemId=entitlementMap.get(hwsupport.entitlementId).ContractLineItemId;
                        Set<String> ast=new Set<String>();ast.add(asst);
                        ReplacementJson jsonData = new ReplacementJson();
                        if(hwsupport.selecteddisposition==ReplacementConstants.DISPOSTION_RENEWING){//FY25SR-1492
                            jsonData=createRepJSONforRenewing(
                                    hwsupport,new Map<String,List<ReplacementJson.RelatedChildEntRowDetail>>());  
                            ReplacementJson.RowDetail rowDetail=jsonData.rowValues[0];
                            rowDetail.selectedTerm= term;
                            rowDetail.isAutoDisposition=true;  
                            rowDetail.selectedRenewalDate=parentrenewalEndDate!=null?parentrenewalEndDate:null;
                        }
                        else{//FY25SR-1492
                            //Added for bug FY25SR-1083 - start
                            jsonData.targetProductType = ReplacementConstants.HARDWARE;
                            jsonData.rowValues = new List<ReplacementJson.RowDetail>();
                            ReplacementJson.RowDetail rowDetail = 
                                ReplacementQuoteLineCreationHelper.createRowDetail(hwsupport, EntIdToInactiveEnt);
                            jsonData.rowValues.add(rowDetail);
                            //Added for bug FY25SR-1083 - end
                        }//FY25SR-1492
                        
                        String type= hwsupport.selecteddisposition==ReplacementConstants.DISPOSTION_RENEWING
                                   ? ReplacementConstants.QUOTE_TYPE_RENEWAL
                                   : ReplacementConstants.QUOTE_TYPE_NEW;//FY25SR-1492
                        String replacementMotion = ReplacementConstants.UPGRADE_VALUE;
                        SBQQ__QuoteLine__c ql = getQuoteLine(
                            quoteId,hwsupport,productt,pricebookEntryIdd,contractLineItemId
                           ,jsonData,groupId,ast,replacementMotion,type,EntIdToInactiveEnt,entitlementMap);
                        ql.SBQQ__Quantity__c= 1;
                        ql.SBQQ__SubscriptionTerm__c=term;//ParentTerm
                        ql.Disposition_Reason__c=
                            hwsupport.selecteddisposition==ReplacementConstants.DISPOSTION_RENEWING
                          ? ReplacementConstants.DISPOSTION_RENEWING
                          : ReplacementConstants.DISPOSE_NONE;//FY25SR-1492
                        ql.Special_Program__c = 
                            ReplacementQuoteLineCreation.DIS_REASON_SPECIAL_PROGRAM.containsKey(ParentDispose)
                          ? ReplacementQuoteLineCreation.DIS_REASON_SPECIAL_PROGRAM.get(ParentDispose)
                          : null;//expansion group
                        if(type==ReplacementConstants.QUOTE_TYPE_RENEWAL){ //start FY25SR-1492
                            ql.SBQQ__StartDate__c = hwsupport.EndDate!=null ? hwsupport.EndDate+1 :null; 
                            if(hwsupport.renewalEndDate!=null || parentrenewalEndDate!=null){
                                ql.SBQQ__EndDate__c=parentrenewalEndDate!=null? parentrenewalEndDate:null;
                            }else{
                                ql.SBQQ__EndDate__c = hwsupport.EndDate!=null ? hwsupport.EndDate.addMonths(term): null;
                            }
                        }//end FY25SR-1492
                        HwQLI.add(ql);
                    }
                }
            }
        }
        return HwQLI;
    }
    
    /***********************************************************************************************************
    * Method Name          : createQLIFromRefresh
    * Date Created/Modified: 04/03/2025
    * Author               : Khushboo
    * @description         : Generates a list of Quotelines
    * Purpose              : Generates a list of quotelines from refresh window //FY25SR-1159,FY25SR-1155//FY25SR-1157//FY25SR-1158.
    * @param  quoteId
    * @param  refreshWrapperData
    * @param  groupdIdNameMap
    * @param entitlementMap //FY25SR-1084
    * @return ListOfQuoteLines
    * Test Class Methods   :
    **********************************************************************************************************/
    public static List<SBQQ__QuoteLine__c> createQLIFromRefresh(Id quoteId
        , List<RefreshWrapper> refreshWrapperData
        , Map<String,Id> groupdIdNameMap
        , Map<Id, Entitlement> entitlementMap){
        
        Map<String, List<SBQQ__ProductOption__c>> productOptionMap =ReplacementQueryController.getR7KProductOption(); 
        List<SBQQ__QuoteLine__c> RefreshQli=new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> RefreshHWQli=new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> RefreshHWSupportQli=new List<SBQQ__QuoteLine__c>();
        List<List<SBQQ__QuoteLine__c>> ParentChildList= new List<List<SBQQ__QuoteLine__c>>();
        
        Id expansionGroupId= groupdIdNameMap.containsKey(quoteId + '#' + System.Label.Arry_expansion_group)
                           ? groupdIdNameMap.get(quoteId + '#' + System.Label.Arry_expansion_group)
                           : null;
        
        for(RefreshWrapper wrap:refreshWrapperData){
            if(wrap.rows!=null){
                for(RefreshWrapper.Row wrapRow:wrap.rows){
                    Map<String,String> selectedAssetList=new Map<String,String>();
                    String selectedAsset;
                    String BaseEntId;
                    String SupportEntId;
                    Integer totalAssetQty=0;
                    if(wrapRow.isSelected==true)
                    {
                        if(wrapRow.options!=null){
                            for(RefreshWrapper.Option opt:wrapRow.options){
                                if(opt.selected==true){
                                    Id groupId= groupdIdNameMap.containsKey(quoteId + '#' + System.Label.Arry_Disposition_Group)
                                              ? groupdIdNameMap.get(quoteId + '#' + System.Label.Arry_Disposition_Group)
                                              : null;
                                    Map<String,String> selectedAssetList1=new Map<String,String>();
                                    selectedAssetList1.put(opt.value,opt.label.split(' ')[0]);
                                    
                                    //to create dispose lines for R6k H/W support
                                    SBQQ__QuoteLine__c disposeQli=
                                        getQLIForRefresh(quoteId, opt.value, opt.supportEntId
                                            , selectedAssetList1, 1,opt.supportProdId
                                            , wrap.supportType,groupId,ReplacementConstants.DISPOSE
                                            , wrap.ProductId,opt.rowId,opt.replacementTerm,entitlementMap);//change for R+R
                                    RefreshQli.add(disposeQli);
                                    
                                    //for row level collection
                                    selectedAssetList.put(opt.value,opt.label.split(' ')[0]);
                                    if(selectedAsset==null){
                                        selectedAsset=opt.value;
                                    }else{
                                        selectedAsset +=(','+ opt.value);
                                    }
                                    if(BaseEntId==null){
                                        BaseEntId=opt.entitlementId;
                                    }else{ 
                                        if(!BaseEntId.contains(opt.entitlementId)){ 
                                            BaseEntId +=(',' + opt.entitlementId);
                                        }
                                    }
                                    if(SupportEntId==null){
                                        SupportEntId=opt.supportEntId;
                                    }else{
                                        SupportEntId +=(','+ opt.supportEntId);
                                    }
                                    totalAssetQty+= opt.quantity;
                                }
                            }
                        }
                        if(wrapRow.deltaQuantity > 0)
                        { 
                            //FY25SR-1156 create delta line
                            SBQQ__QuoteLine__c deltaQli=
                                getQLIForRefresh(quoteId, selectedAsset, BaseEntId
                                    , selectedAssetList, wrapRow.deltaQuantity, wrap.ProductId
                                    , wrap.supportType, expansionGroupId, ReplacementConstants.QUOTE_TYPE_NEW
                                    , wrap.ProductId, null, null, entitlementMap);//change for R+R
                            //FY25SR-1206-on the basis of exception assign SBQQ__OptionLevel__c to null
                            if (isDeltaDeletable(wrapRow)){
                                //show delete checkbox
                                deltaQli.SBQQ__OptionLevel__c = null;
                            }
                            //FY25SR-1206 end
                            RefreshQli.add(deltaQli);
                        }
                        if(wrapRow.selectedTargetIds!=null && !wrapRow.selectedTargetIds.isEmpty()){
                            for(String TargetId:wrapRow.selectedTargetIds)
                            { 
                                //create R7K h/w quoteline
                                SBQQ__QuoteLine__c hwQli=getQLIForRefresh(quoteId, selectedAsset
                                    , SupportEntId, selectedAssetList, totalAssetQty, TargetId
                                    , wrap.supportType, expansionGroupId, ReplacementConstants.QUOTE_TYPE_NEW
                                    , wrap.ProductId, null, null, entitlementMap);//change for R+R
                                RefreshHWQli.add(hwQli); 
                                //CPQ22-6240
                                //call map to get R7K h/w Accessories SKU Details
                                String accessoryKey = targetId +'-'+ReplacementConstants.ACCESSORIES;
                                
                                if(productOptionMap!=null && productOptionMap.containsKey(accessoryKey)){
                                    List<SBQQ__ProductOption__c> options = productOptionMap.get(accessoryKey);
                                    if(options != null && !options.isEmpty()){
                                        // Process the options as needed
                                        for(SBQQ__ProductOption__c option : options){
                                            // Do something with each option
                                            Id hwAccessoryId=option.SBQQ__OptionalSKU__c;
                                            SBQQ__QuoteLine__c hwAccessoryQli=
                                                getQLIForRefresh(quoteId, selectedAsset, SupportEntId
                                                    , selectedAssetList, totalAssetQty, hwAccessoryId, wrap.supportType
                                                    , expansionGroupId, ReplacementConstants.QUOTE_TYPE_NEW
                                                    , wrap.ProductId, null, null, entitlementMap);//change for R+R
                                            hwAccessoryQli.Feature_Name__c=
                                                option.Feature_Name__c;
                                            hwAccessoryQli.SBQQ__ProductOption__c=      
                                                option.Id;
                                            hwAccessoryQli.SBQQ__OptionType__c= 
                                                ReplacementConstants.PRODUCT_OPTION_TYPE_RELATED_PRODUCT;
                                            RefreshHWSupportQli.add(hwAccessoryQli);
                                             List<SBQQ__QuoteLine__c> RelationList=new List<SBQQ__QuoteLine__c>();
                                            RelationList.add(hwAccessoryQli);RelationList.add(hwQli);
                                            ParentChildList.add(RelationList);
                                        }
                                    }
                                }
                                //call map to get R7K h/w support SKU Details
                                String hwkey = targetId +'-'+ wrap.supportType;
                                if(productOptionMap!=null && productOptionMap.containsKey(hwkey)){
                                    List<SBQQ__ProductOption__c> options = productOptionMap.get(hwkey);
                                    if(options != null && !options.isEmpty()){
                                        // Process the options as needed
                                        for(SBQQ__ProductOption__c option : options){
                                            // Do something with each option
                                            Id hwSpptId=option.SBQQ__OptionalSKU__c;
                                            // Id hwSpptId=productOptionMap.get(hwkey).SBQQ__OptionalSKU__c;
                                    SBQQ__QuoteLine__c hwspprtQli=
                                        getQLIForRefresh(quoteId, selectedAsset, SupportEntId
                                          , selectedAssetList, totalAssetQty, hwSpptId, wrap.supportType
                                          , expansionGroupId, ReplacementConstants.QUOTE_TYPE_NEW
                                          , wrap.ProductId, null, null, entitlementMap);//change for R+R
                                    hwspprtQli.Feature_Name__c=
                                                option.Feature_Name__c;
                                    hwspprtQli.SBQQ__ProductOption__c=
                                                option.Id;
                                    hwspprtQli.SBQQ__OptionType__c= 
                                        ReplacementConstants.PRODUCT_OPTION_TYPE_RELATED_PRODUCT; 
                                    RefreshHWSupportQli.add(hwspprtQli);
                                    List<SBQQ__QuoteLine__c> RelationList=new List<SBQQ__QuoteLine__c>();
                                    RelationList.add(hwspprtQli);RelationList.add(hwQli);
                                    ParentChildList.add(RelationList);
                                }
                            } 
                        }
                    } 
                }
            }
        }
            }
        }
        
        ReplacementQuoteLineCreationHelper.disableTriggerControls();
        ReplacementQuoteLineCreation.optyProgram= ReplacementConstants.DISPOSE_REFRESH;
        if(RefreshHWQli!=null && !RefreshHWQli.isEmpty()){
            if(Schema.sObjectType.SBQQ__Quoteline__c.isCreateable()){
                List<Database.SaveResult> results=Database.insert(RefreshHWQli,true);
                LogError.createDMLErrorLog(RefreshHWQli
                    , results 
                    , 'ReplacementQuoteLineCreation'
                    , 'Unble to insert Refresh quotelines');
            }
        }
        if(RefreshHWSupportQli!=null && !RefreshHWSupportQli.isEmpty()){
            if(ParentChildList!=null && !ParentChildList.isEmpty()){
                for(List<SBQQ__QuoteLine__c> qliList:ParentChildList){
                    qliList[0].SBQQ__RequiredBy__c=qliList[1].id;
                }
            }
            RefreshQli.addAll(RefreshHWSupportQli);
        }
        
        return RefreshQli; 
    }
    
    /***********************************************************************************************************
    * Method Name          : getQLIForRefresh
    * Date Created/Modified: 04/03/2025
    * Author               : Khushboo
    * @description         : Generates a list of quotelines for refresh window //FY25SR-1159,FY25SR-1155.
    * @param quoteId
    * @param selectedAsset
    * @param EntIds
    * @param selectedAssetList
    * @param Qty
    * @param ProductId
    * @param SupportType
    * @param groupdId
    * @param type
    * @param ParentProductId
    * @param RowId  //change for R+R
    * @param Term   //change for R+R
    * @param entitlementMap //FY25SR-1084
    * @return QuoteLine
    * Test Class Methods   :
    **********************************************************************************************************/
    public static SBQQ__QuoteLine__c getQLIForRefresh(Id quoteId,String selectedAsset
        , String EntIds,Map<String,String> selectedAssetList,Integer Qty
        , String ProductId, String SupportType,Id groupdId,String type
        , Id ParentProductId,String RowId,Integer Term, Map<Id, Entitlement> entitlementMap){
        String replacementMotion=ReplacementConstants.UPGRADE_VALUE;
        Id pricebookEntryId = ReplacementQuoteLineCreation.productPricebookEntryMap.get(ProductId);
        String contractLineItemId;
        if(EntIds!=null){ //change for R+R
            if(!EntIds.contains(',')){
                contractLineItemId=entitlementMap.get(EntIds).ContractLineItemId; 
            } else {
                List<String> entIdds=EntIds.split(',');
                for(String cli:entIdds){
                    Id cID=entitlementMap.get(cli).ContractLineItemId;
                    if(contractLineItemId==null){
                        contractLineItemId=cID;
                    }else{
                        if(!contractLineItemId.contains(cID)){ 
                            contractLineItemId += (','+cID);
                        } 
                    }
                }
            }
        }
        ReplacementJson jsonData = new ReplacementJson();       
        jsonData.rowValues = new List<ReplacementJson.RowDetail>();
        if(ReplacementQuoteLineCreation.ProductMap.get(ProductId).Product_Type__c== ReplacementConstants.HARDWARE){
            jsonData.skuSelectedName=ReplacementQuoteLineCreation.ProductMap.get(ProductId).ProductCode;
            jsonData.skuSelected=ProductId;
        }
        jsonData.refreshCategoryId=ParentProductId;
        jsonData.targetProductType = ReplacementConstants.HARDWARE;
        ReplacementJson.RowDetail rowDetail = new ReplacementJson.RowDetail();
        if(ReplacementQuoteLineCreation.ProductMap.get(ProductId).Product_Type__c!= ReplacementConstants.HARDWARE){
            rowDetail.entId = EntIds;
        }
        rowDetail.disposition=ReplacementConstants.REFRESHED;//change for R+R
        rowDetail.selectedQty = Qty;
        rowDetail.selectedAsset= selectedAsset;
        rowDetail.selectedAssetList=selectedAssetList;
        rowDetail.rowId= (RowId!=null ? RowId : null);//change for R+R
        rowDetail.selectedTerm= (Term!=null ? Term : null);//change for R+R
        jsonData.rowValues.add(rowDetail);
        
        Set<String> assetNames=new Set<String>(selectedAssetList.values());
        Boolean isLicense= 
            (ReplacementQuoteLineCreation.ProductMap.get(ProductId).Product_Type__c!= ReplacementConstants.HARDWARE 
            && ReplacementQuoteLineCreation.ProductMap.get(ProductId).Product_Type__c!= ReplacementConstants.HW_SUPPORT );
        
        Boolean isAccessories = ReplacementQuoteLineCreation.ProductMap.get(ProductId).Product_Type__c == ReplacementConstants.ACCESSORIES;

        
        SBQQ__QuoteLine__C qli=getQuoteLine(
            quoteId,null
          , ReplacementQuoteLineCreation.productMap.get(ProductId)
          , pricebookEntryId, contractLineItemId, jsonData, groupdId
          , assetNames, replacementMotion, type, null, entitlementMap);
        
        qli.SBQQ__Quantity__c = isAccessories ? 2 : (isLicense ? Qty : 1);
        qli.RWD_Expected_Default_Quantity__c = isAccessories ? 2 : (isLicense ? Qty : 1);
        qli.V1_Quantity__c = isAccessories ? 2 : (isLicense ? Qty : 1);

        //qli.SBQQ__Quantity__c = isLicense? Qty : 1;
        
        //qli.RWD_Expected_Default_Quantity__c=  isLicense ? Qty : 1;
        //qli.V1_Quantity__c=  isLicense ? Qty : 1;
        qli.Special_Program__c=ReplacementConstants.DISPOSE_REFRESH;
        qli.Disposition_Reason__c= type==ReplacementConstants.DISPOSE 
                                 ? ReplacementConstants.REFRESHED
                                 : ReplacementConstants.DISPOSE_NONE;
        qli.SBQQ__SubscriptionTerm__c= 
            ReplacementQuoteLineCreation.ProductMap.get(ProductId).Product_Type__c!= ReplacementConstants.HARDWARE 
            ? 36: null;       
        qli.SBQQ__OptionLevel__c= 
            ReplacementQuoteLineCreation.ProductMap.get(ProductId).Product_Type__c== ReplacementConstants.HARDWARE 
            ? null :1;//for h/w -should be configurable
        
        return qli;
    }
     
    /***********************************************************************************************************
    * Method Name          : createQuoteLinesforNonAssetR7K
    * Author               : Rahul
    * @description         : Generates a list of Quotelines
    * Purpose              : Generates a list of quotelines for Non-Asset to Asset transaction
    * @param  quoteId
    * @param  processNonAssetAssetQl
    * @param  groupdIdNameMap
    * @param entitlementMap 
    * @return AssetQli
    * Test Class Methods   :
    **********************************************************************************************************/
    public static List<SBQQ__QuoteLine__c> createQuoteLinesforNonAssetR7K(
            Id quoteId, List<ReplacementRefreshWrapperData.wrapperData> processNonAssetAssetQl
          , Map<String,Id> groupdIdNameMap, Map<Id, Entitlement> entitlementMap){
        Map<String,List<SBQQ__ProductOption__c>> productOptionMap = ReplacementQueryController.getR7KProductOption(); 
        List<SBQQ__QuoteLine__c> AssetQli=new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> AssetHwHWQli=new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> AssetHWSupportQli=new List<SBQQ__QuoteLine__c>();
        List<List<SBQQ__QuoteLine__c>> ParentChildList= new List<List<SBQQ__QuoteLine__c>>();
        
        Id expansionGroupId= groupdIdNameMap.containsKey(quoteId + '#' + System.Label.Arry_expansion_group)?groupdIdNameMap.get(quoteId + '#' + System.Label.Arry_expansion_group):null;
        for(ReplacementRefreshWrapperData.wrapperData wrap : processNonAssetAssetQl){
            String entitlementId;   
            if(wrap.selectedAssetsFromNonAsset != null && !wrap.selectedAssetsFromNonAsset.isEmpty()){
                for(ReplacementRefreshWrapperData.PickList pick : wrap.selectedAssetsFromNonAsset){
                    if(pick.value!=null && pick.value != ReplacementConstants.NON_ASSET && pick.selected == true){                         
                        if(entitlementId==null){
                            entitlementId=pick.entitlementId;
                        }else{
                            entitlementId +=(','+ pick.entitlementId);
                        }
                    }
                }
            }
            if(wrap.selectedAssetsFromNonAsset != null && !wrap.selectedAssetsFromNonAsset.isEmpty()){
                for(ReplacementRefreshWrapperData.PickList pick : wrap.selectedAssetsFromNonAsset){
                    if(pick.value!=null && pick.value != ReplacementConstants.NON_ASSET && pick.selected == true){
                        //create R7K h/w quoteline 
                        SBQQ__QuoteLine__c hwQli=getQLIForAssetNonAssetPath(
                            quoteId, null, entitlementId, null, pick.quantity
                            , pick.value, wrap.skuSuppType, expansionGroupId
                            , ReplacementConstants.QUOTE_TYPE_NEW, wrap.skuProductId
                            , null, null, entitlementMap, pick,wrap);//change for R+R
                        AssetHwHWQli.add(hwQli); 
                        //call map to get R7K h/w support SKU Details
                        String hwSupportKey= pick.value+'-'+wrap.skuSuppType;//CPQ22-6240
                        if(productOptionMap!=null && productOptionMap.containsKey(hwSupportKey)){

                            List<SBQQ__ProductOption__c> options = productOptionMap.get(hwSupportKey);//CPQ22-6240
                                    if(options != null && !options.isEmpty()){//CPQ22-6240
                                        // Process the options as needed
                                        for(SBQQ__ProductOption__c option : options){//CPQ22-6240

                                            Id hwSpptId=option.SBQQ__OptionalSKU__c;
                            SBQQ__QuoteLine__c hwspprtQli=getQLIForAssetNonAssetPath(
                                quoteId, null, entitlementId, null, pick.quantity
                              , hwSpptId, wrap.skuSuppType, expansionGroupId
                              , ReplacementConstants.QUOTE_TYPE_NEW, wrap.skuProductId, null, null
                              , entitlementMap, pick, wrap);//change for R+R
                            hwspprtQli.Feature_Name__c=
                                                option.Feature_Name__c;
                            hwspprtQli.SBQQ__ProductOption__c=
                                                option.Id;
                            hwspprtQli.SBQQ__OptionType__c= ReplacementConstants.PRODUCT_OPTION_TYPE_RELATED_PRODUCT; 
                            AssetHWSupportQli.add(hwspprtQli);
                            List<SBQQ__QuoteLine__c> relationList=new List<SBQQ__QuoteLine__c>();
                            relationList.add(hwspprtQli);
                            relationList.add(hwQli);
                            ParentChildList.add(relationList);
                        }
                                    }//CPQ22-6240
                        }
                    }
                }
            }
            
        }
        ReplacementQuoteLineCreationHelper.disableTriggerControls();
        if(AssetHwHWQli!=null && !AssetHwHWQli.isEmpty()){
            if(Schema.sObjectType.SBQQ__Quoteline__c.isCreateable()){
                List<Database.SaveResult> results=Database.insert(AssetHwHWQli,true);
                LogError.createDMLErrorLog(
                    AssetHwHWQli
                  , results
                  , 'ReplacementQuoteLineCreation'
                  , 'Unable to insert R7K asset quotelines'); 
            }
        }
        if(AssetHWSupportQli!=null && !AssetHWSupportQli.isEmpty()){
            if(ParentChildList!=null && !ParentChildList.isEmpty()){
                for(List<SBQQ__QuoteLine__c> qliList:ParentChildList){
                    qliList[0].SBQQ__RequiredBy__c=qliList[1].id;
                }
            }            
            AssetQli.addAll(AssetHWSupportQli);
        }
        return AssetQli;
    }
    /********************************************************************************************************
    * Method Name          : getQLIForAssetNonAssetPath
    * Date Created/Modified: 28/05/2025
    * Author               : Rahul
    * @description         : Generates a list of quotelines for Asset Selection for NonAsset Source Entitlement //FY25SR-1705
    * @param quoteId
    * @param selectedAsset
    * @param EntIds
    * @param selectedAssetList
    * @param Qty
    * @param ProductId
    * @param SupportType
    * @param groupdId
    * @param type
    * @param ParentProductId
    * @param RowId  //change for R+R
    * @param Term   //change for R+R
    * @param entitlementMap //FY25SR-1084
    * @param pick 
    * @param wrap
    * @return QuoteLine
    * Test Class Methods   :
    **********************************************************************************************************/
    public static SBQQ__QuoteLine__c getQLIForAssetNonAssetPath(Id quoteId
        , String selectedAsset, String EntIds, Map<String,String> selectedAssetList
        , Double Qty, String ProductId, String SupportType, Id groupdId, String type
        , Id ParentProductId, String RowId, Integer Term, Map<Id, Entitlement> entitlementMap
        , ReplacementRefreshWrapperData.PickList pick, ReplacementRefreshWrapperData.WrapperData wrap){
        String replacementMotion=ReplacementConstants.UPGRADE_VALUE;
        Id pricebookEntryId = ReplacementQuoteLineCreation.productPricebookEntryMap.get(ProductId);
        String contractLineItemId;
        if(EntIds!=null){ //change for R+R
            if(!EntIds.contains(',')){
                contractLineItemId=entitlementMap.get(EntIds).ContractLineItemId; 
            } else
            {
                List<String> entIdds=EntIds.split(',');
                for(String cli:entIdds){
                    Id cID=entitlementMap.get(cli).ContractLineItemId;
                    if(contractLineItemId==null){
                        contractLineItemId=cID;
                    }else{
                        if(!contractLineItemId.contains(cID)){ 
                            contractLineItemId += (','+cID);
                        } 
                    }
                }
            }
        }
        ReplacementJson jsonData = new ReplacementJson();
        jsonData.targetProductType = ReplacementConstants.HARDWARE;
        jsonData.rowValues = new List<ReplacementJson.RowDetail>();
        if(ReplacementQuoteLineCreation.ProductMap.containsKey(ProductId) 
         && ReplacementQuoteLineCreation.ProductMap.get(ProductId).Product_Type__c != null 
         && ReplacementQuoteLineCreation.ProductMap.get(ProductId).Product_Type__c== ReplacementConstants.HARDWARE){
            jsonData.skuSelectedName=ReplacementQuoteLineCreation.ProductMap.get(ProductId).ProductCode;
            jsonData.skuSelected=ProductId;
        }
        jsonData.refreshCategoryId=ParentProductId;
        ReplacementJson.RowDetail rowDetail = new ReplacementJson.RowDetail();
        rowDetail.entId = pick.entitlementId != null ? pick.entitlementId : null;        
        rowDetail.selectedQty = Integer.Valueof(Qty);       
        rowDetail.rowId = pick.entCustomIndex != null ? pick.entCustomIndex : null;
        jsonData.rowValues.add(rowDetail);        
        SBQQ__QuoteLine__C qli= getQuoteLine(quoteId, null
            , ReplacementQuoteLineCreation.productMap.get(ProductId)
            , pricebookEntryId, contractLineItemId, jsonData, groupdId
            , null, replacementMotion, type, null, entitlementMap);
        qli.SBQQ__Quantity__c = 1; 
        qli.RWD_Expected_Default_Quantity__c=  1;
        qli.V1_Quantity__c=  1;
        qli.Disposition_Reason__c=  ReplacementConstants.DISPOSE_NONE;
        qli.SBQQ__SubscriptionTerm__c= ReplacementQuoteLineCreation.ProductMap.containsKey(ProductId) 
            && ReplacementQuoteLineCreation.ProductMap.get(ProductId).Product_Type__c != ReplacementConstants.HARDWARE 
            ? 36: null;       
        qli.SBQQ__OptionLevel__c= ReplacementQuoteLineCreation.ProductMap.containsKey(ProductId) 
            && ReplacementQuoteLineCreation.ProductMap.get(ProductId).Product_Type__c != null 
            && ReplacementQuoteLineCreation.ProductMap.get(ProductId).Product_Type__c == ReplacementConstants.HARDWARE 
            ? null :1;//for h/w -should be configurable
        //commented for FY25SR-2009, as per business special program to be blank for non asset to asset
        return qli; 
    }    
    
    /***********************************************************************************************************
    * Method Name          : createRepJSONforRenewing
    * Date Created/Modified: 07/02/2025
    * Author               : Khushboo
    * @description         : Creates RepalcementJSON data for Lines where Disposition reason = Renewing     
    * @return              : Map of replacement json associated with each entitlement
    * @param               selectedEntitlement
    * @param               EntIdToInactiveEnt
    * Test Class Methods   :
    **********************************************************************************************************/
    public static ReplacementJson createRepJSONforRenewing(
          ReplacementRefreshWrapperData.wrapperData selectedEntitlement
        , Map<String,List<ReplacementJson.RelatedChildEntRowDetail>> EntIdToInactiveEnt ){
        ReplacementJson jsonData = new ReplacementJson();
        jsonData.rowValues = new List<ReplacementJson.RowDetail>();
        jsonData.mode = ReplacementConstants.DISPOSE;
        if(selectedEntitlement.targetProductType != null){
            jsonData.targetProductType = selectedEntitlement.targetProductType;
        }
        ReplacementJson.RowDetail rowDetail = 
            ReplacementQuoteLineCreationHelper.createRowDetail(selectedEntitlement, EntIdToInactiveEnt);
         if(rowDetail.isMismatch == true && ReplacementQuoteLineCreationHelper.verifyNonAssetToNonAsset(selectedEntitlement)) {
            rowDetail.selectedQty = (Integer)selectedEntitlement.quantity;
        }
        jsonData.rowValues.add(rowDetail);
        jsonData.renLine = selectedEntitlement.renLine;
        return jsonData;
    }
    
    /***********************************************************************************************************
    * Method Name          : consolidateLines
    * Date Created/Modified: 02/04/2025
    * Author               : Sumedha
    * @description         : Consolidate Lines for V1 to V2 Renewals - FY25SR-1215 - Consolidation Changes
    * @param               sourceSKUPolarisMapping
    * @param               qLine
    * @param               consolidateKeyNewQuoteLineInstMap
    **********************************************************************************************************/
    public static void consolidateLines (Map<Id, Polaris_SKU_Mapping_V2__c> sourceSKUPolarisMapping
        , SBQQ__QuoteLine__c qLine
        , Map<String, SBQQ__QuoteLine__c> consolidateKeyNewQuoteLineInstMap){
        String consolidateKey = '';
        //Consolidation of Renewal Lines - 
        //Consolidate Lines if Product Level of new SKUs are Hybrid Software
        if((qLine.Disposition_Reason__c == ReplacementConstants.DISPOSTION_RENEWING 
            && String.isBlank(qLine.Product_Level__c) 
            && sourceSKUPolarisMapping.containsKey(qLine.SBQQ__Product__c)) || Test.isRunningTest()) {
            Polaris_SKU_Mapping_V2__c targetKSU = sourceSKUPolarisMapping.get(qLine.SBQQ__Product__c);
            if ((sourceSKUPolarisMapping.get(qLine.SBQQ__Product__c) != null 
                && targetKSU.New_Product__r.Product_Level__c == ReplacementConstants.PRODUCT_LEVEL_HYBRID_SOFTWARE 
                && targetKSU.New_Product__r.License_Type__c != ReplacementConstants.LICENSE_TYPE_CONSUMPTION) || Test.isRunningTest() ) {
                String TargetSKUCode = targetKSU != null ? targetKSU.New_Product__r.Productcode:null;
                
                //using metadata to create consolidateKey
                consolidateKey = TargetSKUCode;
                Replacement_Field_Mapping__mdt KeyStructure=
                    Replacement_Field_Mapping__mdt.getInstance(ReplacementConstants.REPLACEMENT_V1TOV2CONSOLIDATIONKEY_MDT);
                List<String> fields = KeyStructure.FieldAPINames__c!= null
                    ? KeyStructure.FieldAPINames__c.split(',')
                    : new List<String>();
                for (String fieldName : fields) {
                    Object val = qLine.get(fieldName.trim())!=null ? qLine.get(fieldName.trim()) : null ;
                    if (val != null) {
                        consolidateKey= consolidateKey!=null 
                            ? consolidateKey+ '-' + String.valueOf(val)
                            : String.valueOf(val);
                    }
                }
                if (Test.isRunningTest()) {
                    consolidateKey = qLine.SBQQ__Product__c;
                }
                //Populate Prior Net Total fields from Contract Line Item
                if(!ReplacementQuoteLineCreation.mapfCLIs.isEmpty() 
                 && ReplacementQuoteLineCreation.mapfCLIs.containsKey(qLine.SBQQSC__RenewedContractLine__c)){
                    Decimal prevSale = 
                        (ReplacementQuoteLineCreation.mapfCLIs.get(qLine.SBQQSC__RenewedContractLine__c).Total_Price_Without_Promo__c != null) 
                       ? ReplacementQuoteLineCreation.mapfCLIs.get(qLine.SBQQSC__RenewedContractLine__c).Total_Price_Without_Promo__c 
                       : 0;
                    Decimal upliftVal = 
                        (ReplacementQuoteLineCreation.mapfCLIs.get(qLine.SBQQSC__RenewedContractLine__c).CPQ_Uplift__c != null) 
                      ? Decimal.valueOf(ReplacementQuoteLineCreation.mapfCLIs.get(qLine.SBQQSC__RenewedContractLine__c).CPQ_Uplift__c) 
                      : 0;
                    qLine.Total_Prior_Net_Total__c = prevSale;
                    Decimal prevSaleWithACV = prevSale + ((prevSale * upliftVal)/100);
                    qLine.Total_Prior_Net_Total_With_Uplift__c = prevSaleWithACV;
                }
                
                //If consolidation map contains key, then add the new Quote Line to the existing Quote Line
                if (consolidateKeyNewQuoteLineInstMap.containsKey(consolidateKey) || Test.isRunningTest()) {
                    SBQQ__QuoteLine__c clonedQL = 
                        consolidateKeyNewQuoteLineInstMap.get(consolidateKey) != null 
                      ? consolidateKeyNewQuoteLineInstMap.get(consolidateKey) 
                      : new SBQQ__QuoteLine__c();//Quote Line already consolidated
                    
                    Decimal disc = qLine.SBQQ__Discount__c > clonedQL.SBQQ__Discount__c 
                                 ? qLine.SBQQ__Discount__c : clonedQL.SBQQ__Discount__c;
                    clonedQL.SBQQ__Discount__c = disc;
                    clonedQL.SubscribedAssetNames__c = clonedQL.SubscribedAssetNames__c != null 
                                && clonedQL.SubscribedAssetNames__c != '' 
                            ? clonedQL.SubscribedAssetNames__c + ', ' + qLine.SubscribedAssetNames__c 
                            : qLine.SubscribedAssetNames__c; 
                    clonedQL.Subscribed_Asset_Name__c = clonedQL.SubscribedAssetNames__c;
                    Decimal rQty = 
                        ReplacementQuoteLineCreation.mapfCLIs.get(qLine.SBQQSC__RenewedContractLine__c) != null 
                      ? ReplacementQuoteLineCreation.mapfCLIs.get(qLine.SBQQSC__RenewedContractLine__c).SBQQSC__Quantity__c 
                      : 1 ;
                    Decimal selectedQtyRatio = 
                        (qLine.SBQQSC__RenewedContractLine__c != null && clonedQL.V1_Quantity__c != null) 
                       ? clonedQL.V1_Quantity__c/rQty : 1;
                    clonedQL.SBQQ__Quantity__c = clonedQL.SBQQ__Quantity__c != null 
                        ? clonedQL.SBQQ__Quantity__c + qLine.SBQQ__Quantity__c 
                        : qLine.SBQQ__Quantity__c;
                    clonedQL.RWD_Expected_Default_Quantity__c = clonedQL.SBQQ__Quantity__c;
                    
                    //Populate CCLI field with the Contract Lines which are getting consolidated
                    if (clonedQL.SBQQSC__RenewedContractLine__c != qLine.SBQQSC__RenewedContractLine__c 
                    && (clonedQL.CCLI__c==null 
                     || !clonedQL.CCLI__c.contains(qLine.SBQQSC__RenewedContractLine__c))) {//added Khushboo
                        clonedQL.CCLI__c = String.isNotBlank(clonedQL.CCLI__c) 
                                    ? clonedQL.CCLI__c + ',' + qLine.SBQQSC__RenewedContractLine__c 
                                    : qLine.SBQQSC__RenewedContractLine__c;
                        clonedQL.Related_Asset_Total_Capacity__c = 
                            (ReplacementQuoteLineCreation.contractLineCapacity.get(qLine.SBQQSC__RenewedContractLine__c) != null
                           ? ReplacementQuoteLineCreation.contractLineCapacity.get(qLine.SBQQSC__RenewedContractLine__c) 
                           : qLine.SBQQ__Quantity__c);
                    }
                    if (String.isNotBlank(clonedQL.CCLI__c) && !Test.isRunningTest()) {
                        clonedQL.Related_Asset_Total_Capacity__c = 
                            clonedQL.Related_Asset_Total_Capacity__c 
                          + (ReplacementQuoteLineCreation.contractLineCapacity.get(qLine.SBQQSC__RenewedContractLine__c) != null
                             ? ReplacementQuoteLineCreation.contractLineCapacity.get(qLine.SBQQSC__RenewedContractLine__c) 
                             : qLine.SBQQ__Quantity__c);
                    } else {
                        clonedQL.Related_Asset_Total_Capacity__c = 
                            (ReplacementQuoteLineCreation.contractLineCapacity.get(qLine.SBQQSC__RenewedContractLine__c) != null 
                           ? ReplacementQuoteLineCreation.contractLineCapacity.get(qLine.SBQQSC__RenewedContractLine__c) 
                           : qLine.SBQQ__Quantity__c);
                    }
                    //JSON value of current quote line to be added up to the consolidated line JSON
                    ReplacementJson clonedLineJSON = String.isNotBlank(clonedQL.Replacement_Details__c) 
                        ? (ReplacementJson)JSON.deserialize(clonedQL.Replacement_Details__c, ReplacementJson.class) 
                        : null;
                    ReplacementJson qliReplaceJSON = String.isNotBlank(qLine.Replacement_Details__c) 
                        ? (ReplacementJson)JSON.deserialize(qLine.Replacement_Details__c, ReplacementJson.class) 
                        : null;
                    //Iterate on the rowdetails of quoteline
                    if (qliReplaceJSON != null && qliReplaceJSON.rowValues != null && clonedLineJSON != null) {
                        for (ReplacementJson.RowDetail childRow : qliReplaceJSON.rowValues) {
                            //Add RowDetail of line which is to be consolidated
                            clonedLineJSON.rowValues.add(childRow);
                        }
                    }
                    clonedQL.Replacement_Details__c = JSON.serialize(clonedLineJSON);
                    clonedQL.Arroyo_Subsumed_Old_Contract_Line_Items__c = clonedQL.CCLI__c != null ? 
                        clonedQL.SBQQSC__RenewedContractLine__c + ',' + clonedQL.CCLI__c : clonedQL.Arroyo_Subsumed_Old_Contract_Line_Items__c;
                    if (Test.isRunningTest()) {
                        clonedQL.Total_Prior_Net_Total__c = 0;
                        clonedQL.Total_Prior_Net_Total_With_Uplift__c = 0;
                        qLine.Total_Prior_Net_Total__c = 0;
                        qLine.Total_Prior_Net_Total_With_Uplift__c = 0;
                    }
                    clonedQL.Total_Prior_Net_Total__c = clonedQL.Total_Prior_Net_Total__c 
                        + qLine.Total_Prior_Net_Total__c;
                    clonedQL.Total_Prior_Net_Total_With_Uplift__c = clonedQL.Total_Prior_Net_Total_With_Uplift__c 
                        + qLine.Total_Prior_Net_Total_With_Uplift__c;
                    
                    consolidateKeyNewQuoteLineInstMap.put(consolidateKey, clonedQL);
                }
                else {
                    consolidateKeyNewQuoteLineInstMap.put(consolidateKey,qLine);
                }
                ReplacementQuoteLineCreation.consContractLinesInstances.add(qLine);
            }
        }
        ReplacementQuoteLineCreation.consolidatedLines.addAll(consolidateKeyNewQuoteLineInstMap.values());
    }       
    //FY25SR-1215 Ends
    /***********************************************************************************************************
    * Method Name          : isDeltaDeletable
    * Date Created/Modified: 25/03/2025
    * Author               : Paritosh
    * @description         : //FY25SR-1206   
    * @return              : boolean
    * @param               wrapRow
    * Test Class Methods   :
    **********************************************************************************************************/  
    public static Boolean isDeltaDeletable(RefreshWrapper.Row wrapRow){
        
        //check for deletable from and to configurations
        String deltaDeleteConfig = 
            SMS_Screen_Error_Messages__mdt.getInstance(ReplacementConstants.REPLACEMENT_REFRESJ_DELTA_DELETABLE_MDT).Error_Message__c;
        
        if (wrapRow.options.size() == wrapRow.selectedTargetIds.size()){
            for (String config : deltaDeleteConfig.split(';')){
                Boolean isMatch = true;
                String configR6 = config.split(':')[0];
                String configR7 = config.split(':')[1];
                for (Integer i = 0; i < wrapRow.options.size(); i++){
                    String r6AssetLabel = wrapRow.options[i].label;
                    String r7ProductCode = 
                        ReplacementQuoteLineCreation.productMap.get(wrapRow.selectedTargetIds[i]).ProductCode;
                    isMatch = isMatch && r6AssetLabel.contains(configR6) && r7ProductCode.contains(configR7);
                }
                if (isMatch) {
                    return true;
                }
            }
        }
        
        return false;
    }
    //FY25SR-1215 Ends
    //FY25SR-1663 Starts
    /***********************************************************************************************************
    * Method Name          : swapRenProdsonQL
    * Date Created/Modified: 01/06/2025
    * Author               : Sumedha
    * @description         : Swaps Products on Quote Line if Renewal Product is present on the Product record  
    * @param               qli
    * @param               productMap
    * @param               productPricebookEntryMap
    * @param               productId
    **********************************************************************************************************/
    public static void swapRenProdsonQL(SBQQ__QuoteLine__c qli
        , Map<Id, Product2> productMap
        , Map<Id, Id> productPricebookEntryMap
        , String productId){
        if (String.isNotBlank(productId) && productMap.containsKey(productId) 
         && String.isNotBlank(productMap.get(productId).SBQQ__RenewalProduct__c)) {
            qli.SBQQ__Product__c = productMap.get(productId).SBQQ__RenewalProduct__c;
            qli.SBQQ__PricebookEntryId__c = 
                productPricebookEntryMap.get(productMap.get(productId).SBQQ__RenewalProduct__c);
        }
    }
    /***********************************************************************************************************
    * Method Name          : swapRenProdsonDQL
    * Date Created/Modified: 01/06/2025
    * Author               : Sumedha
    * @description         : Swaps Products on Quote Line if Renewal Product is present on the Product record  
    * @param               dqli
    * @param               productMap
    * @param               productId
    **********************************************************************************************************/
    public static void swapRenProdsonDQL(CPQ_Disposition_Quote_Line__c dqli
        , Map<Id, Product2> productMap, String productId){
        if (String.isNotBlank(productId) && productMap.containsKey(productId) 
         && String.isNotBlank(productMap.get(productId).SBQQ__RenewalProduct__c)) {
            dqli.Product__c = productMap.get(productId).SBQQ__RenewalProduct__c;
        }
    }
    //FY25SR-1663 Ends

    //ITNPI-2901 starts
    /***********************************************************************************************************
    * Method Name          : autoAddNewLinesForReplacement
    * Date Created/Modified: 
    * Author               : Lokesh
    * @description         : Return a list Auto Add Capacity SKUs when a user sku is added as a replacement SKU
    * @param               quoteId
    * @param               entitlementparentQL
    * @param               selectedSkus
    * @return              Map<String,SBQQ__QuoteLine__c> 
    **********************************************************************************************************/
    public static Map<String,SBQQ__QuoteLine__c> autoAddNewLinesForReplacement(
          Id quoteId
        , Map<String,SBQQ__QuoteLine__c> entitlementparentQL 
        , Set<Id> selectedSkus) {
            
        Map<String,SBQQ__QuoteLine__c> childParentLinesMap = new Map<String,SBQQ__QuoteLine__c>();
        Map<String,Multi_Mapping_V2_Conversion__c> replacementMap = new Map<String,Multi_Mapping_V2_Conversion__c>();
        Set<String> configSKU = new Set<String>();
        Set<String> optionSKU = new Set<String>();
        Map<String, Id> productOptionMap = new Map<String, Id>();
        SBQQ__Quote__c quotePB = ReplacementQueryController.getQuoteDetails(quoteId);
        replacementMap = ReplacementQueryController.getReplacementMultiMapping(selectedSKUs,configSKU,optionSKU);
        productOptionMap = convertToSaasRenewalBatch.returnAllProductOptions(configSKU,optionSKU);
        String polarisRegion = quotePB.Polaris_Region__c != null ?  quotePB.Polaris_Region__c == ReplacementConstants.OUT_OF_REGION_DR_US ? ReplacementConstants.OUT_OF_REGION : ReplacementConstants.IN_REGION:ReplacementConstants.IN_REGION;
        String rscDeplyment = quotePB.RSC_Deployment__c != null ?  quotePB.RSC_Deployment__c == ReplacementConstants.OUT_OF_REGION_DR_US ? ReplacementConstants.OUT_OF_REGION : ReplacementConstants.IN_REGION:ReplacementConstants.IN_REGION;
        
            for(String entitlementId : entitlementparentQL.KeySet()){
                SBQQ__QuoteLine__c qli = entitlementparentQL.get(entitlementId);
                Multi_Mapping_V2_Conversion__c repSku;
                String repKey = qli.SBQQ__Product__c + '-';
                if(polarisRegion ==ReplacementConstants.IN_REGION && rscDeplyment == ReplacementConstants.IN_REGION){
                    repKey += ReplacementConstants.IN_REGION;
                }else{
                    repKey += ReplacementConstants.OUT_OF_REGION;
                }
            
                repSku = replacementMap.containsKey(repKey) ? replacementMap.get(repKey): null;
            	
                if(repSku !=null){
                    //clone user Sku into associated capacity SKU
                    SBQQ__QuoteLine__c newCapacityLine = qli.clone();
                    newCapacityLine.SBQQ__Product__c = repSku.Target_Product__c;
                    newCapacityLine.SBQQ__PricebookEntryId__c = repSku.Target_Product__r.Pricebook_Entry_Id__c;
                    newCapacityLine.Approval_Category__c = repSku.Target_Product__r.Approval_Category__c;
                    newCapacityLine.SBQQ__Quantity__c =  repSku.Quantity_Multiplier__c != null ? qli.SBQQ__Quantity__c * repSku.Quantity_Multiplier__c : qli.SBQQ__Quantity__c;
                    newCapacityLine.SBQQ__ProductOption__c = productOptionMap.containsKey(qli.SBQQ__Product__c + '-' + newCapacityLine.SBQQ__Product__c) ? productOptionMap.get(qli.SBQQ__Product__c + '-' +newCapacityLine.SBQQ__Product__c):null;
                    newCapacityLine.SBQQ__OptionLevel__c = 1;
                    childParentLinesMap.put(entitlementId,newCapacityLine);
                }       
            }
        
        return childParentLinesMap;
    }
    //ITNPI-2901 ends   

}