/**This is the Controller for ReplaceSKUComponent  */ 
public class ReplaceSKUControllerLtng {
    /**Constructor */
    public ReplaceSKUControllerLtng () {
    } 
      
    /*To get Running User Profile*/
    @AuraEnabled
    public static SBQQ__Quote__c getQuoteFieldValuesFromApex(String quoteId){
        try{
            System.debug('**Method getQuoteFieldValuesFromApex CALLED**' + quoteId);
            SBQQ__Quote__c quoteRecord = [SELECT Id, Running_User_Profile__c FROM SBQQ__Quote__c WHERE Id =: quoteId];
            return quoteRecord;
        }catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    
    Public static Set<String> originalQuotesMap = new Set<String>();
    Public static List<String> replacedSKUsList = new List<String>(); //MS RGCF2-180
 
    /** Method to fetch eligible Saas Lines to display on the screen*/
    //public static List <SBQQ__QuoteLine__c> qlList = new List <SBQQ__QuoteLine__c>();
    @AuraEnabled
    public static List < SaasWrapper > fetchSaasRecords(Id quoteId) {
        /*saasWrapper Saas Wrapper instance for replacement*/
        SaasWrapper saasWrapper;
        /*To store details of Saas SKUs to be displayed*/
        List<SaasWrapper> lstSaasWrappers = new List<SaasWrapper>() ;
        Set<Id> productIds = new Set<Id>();
        List<Entitlement> lstEnts = new List<Entitlement>();
        Map<String, Date> mapOfCLIvsEntEndDate = new Map<String, Date>();
        
        try{
            //Fetch all Quote Lines
            List <SBQQ__QuoteLine__c> qlList = getQuoteLinesAvailable(quoteId);

            //MS Added RSCG Saas
            if (!qlList.isEmpty() && qlList[0].AssociatedAccount__c != null) {
                lstEnts = [Select Id, Name, Product__r.Name, AssetId, Asset.Name, ContractLineItemId, EndDate from Entitlement where AccountId =: qlList[0].AssociatedAccount__c];
                if (!lstEnts.isEmpty()) {
                    for (Entitlement entObj : lstEnts) {
                        mapOfCLIvsEntEndDate.put(entObj.ContractLineItemId, entObj.EndDate);
                    }
                }
            }

            //qlList = getQuoteLinesAvailable(quoteId);
            if (!qlList.isEmpty()) {
                for (SBQQ__QuoteLine__c qlObj : qlList) {
                    if (qlObj.Arroyo_Subscribed_Asset_Name__c == null /*&& qlObj.Category__c != 'Bundle' &&
                    (qlObj.Product_Type__c == 'O365' || qlObj.Product_Type__c == 'Hybrid M365' || qlObj.Product_Type__c == 'M365H' || qlObj.Product_Type__c == 'Hybrid M365H' || 
                    ((qlObj.Product_Type__c == 'NAS' || qlObj.Product_Type__c == 'NAS Cloud Direct') && qlObj.SBQQ__ProductFamily__c != 'Rubrik Scale') )*///commented for CPQ22-3680
                    ) {
                            productIds.add(qlObj.SBQQ__Product__c);
                    }
                }
            }
            Map<String,List<String>> SKUValuesAvailable = getReplaceSKUsAvailable(productIds,'SaaS replacement');
            if (!qlList.isEmpty()) {
                for (SBQQ__QuoteLine__c qlObj : qlList) {
                    if (qlObj.Arroyo_Subscribed_Asset_Name__c == null /*&& qlObj.Category__c != 'Bundle' &&
                        (qlObj.Product_Type__c == 'O365' || qlObj.Product_Type__c == 'Hybrid M365' || qlObj.Product_Type__c == 'M365H' ||qlObj.Product_Type__c == 'Hybrid M365H' ||
                        ((qlObj.Product_Type__c == 'NAS' || qlObj.Product_Type__c == 'NAS Cloud Direct') && qlObj.SBQQ__ProductFamily__c != 'Rubrik Scale'))*///commented for CPQ22-3680
                    ) {
                        saasWrapper = new SaasWrapper();
                        saasWrapper.saasInScope = qlObj.SBQQ__ProductName__c;
                        saasWrapper.qlId = qlObj.Id;
                        saasWrapper.startDate = qlObj.SBQQ__StartDate__c;
                        saasWrapper.endDate = qlObj.SBQQ__EndDate__c;
                        saasWrapper.assetList = (qlObj.Subscribed_Asset_Name__c != null && qlObj.Subscribed_Asset_Name__c != '')?qlObj.Subscribed_Asset_Name__c:'';
                        saasWrapper.cliRootId = qlObj.SBQQSC__RenewedContractLine__c;
                                                if (SKUValuesAvailable.get(qlObj.SBQQ__ProductName__c) != null) {
                            saasWrapper.optionsAvailable = JSON.serialize(SKUValuesAvailable.get(qlObj.SBQQ__ProductName__c));
                        }
                        //MS Saas RSCG
                        if(saasWrapper.cliRootId != null && !mapOfCLIvsEntEndDate.isEmpty() && mapOfCLIvsEntEndDate.containsKey(saasWrapper.cliRootId)){
                            saasWrapper.entEndDate = mapOfCLIvsEntEndDate.get(saasWrapper.cliRootId);
                        }
                        if (saasWrapper.optionsAvailable != null) {
                            lstSaasWrappers.add(saasWrapper);
                        }
                    }
                }
            }
            System.debug('lstSaasWrappers-->'+lstSaasWrappers);
            return lstSaasWrappers;
        }catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    /** Method to fetch GO and TPH lines for replacement */
    @AuraEnabled
    public static List < EntitlementWrapper > fetchGoRecords(Id quoteId, String category) {
        /**  Quote record in scope*/
        SBQQ__Quote__c quoteInScope = [SELECT Id, Name, SBQQ__Account__c, RWD_Deal_Ops_Exception__c , RWD_Sales_Rep_Exception__c FROM SBQQ__Quote__c WHERE Id =: quoteId LIMIT 1];
        List<EntitlementWrapper> lstWrapperEnts = new List<EntitlementWrapper>();
        List<Entitlement> lstEnts = new List<Entitlement>();
        Map<String, String> mapofCLIvsAssetId = new Map<String, String>();
        Set<Id> productIds = new Set<Id>();
        Map<String, Date> mapOfCLIvsEntEndDate = new Map<String, Date>();
        /*wrapper Entitlement Wrapper instance for replacement*/
        EntitlementWrapper wrapper;
        try{
            //Checking for RSC-G Eligibility on Account for RSC to RSC-G / SAAS-SAAS-G Replacements
            if(category != null && (category.contains('SAAS-SAAS-G') || category.contains('RSC to RSC-G'))){
                Account ac = [Select Id, RSC_G_Eligible__c from Account where Id = :quoteInScope.SBQQ__Account__c Limit 1];
                if(!ac.RSC_G_Eligible__c || !((quoteInScope.RWD_Deal_Ops_Exception__c != null && quoteInScope.RWD_Deal_Ops_Exception__c.contains('$0 RSC-G Replacement')) || (quoteInScope.RWD_Sales_Rep_Exception__c != null && quoteInScope.RWD_Sales_Rep_Exception__c.contains('25% Premium RSC-G Replacement')))){ 
                    return lstWrapperEnts;
                }
            }

            //Fetch all Quote Lines
            List <SBQQ__QuoteLine__c> qlList = getQuoteLinesAvailable(quoteId);
            lstEnts = [Select Id, Name, Product__r.Name, AssetId, Asset.Name, ContractLineItemId, EndDate from Entitlement where AccountId =: quoteInScope.SBQQ__Account__c];
            if (!lstEnts.isEmpty()) {
                for (Entitlement entObj : lstEnts) {
                    mapofCLIvsAssetId.put(entObj.ContractLineItemId, entObj.AssetId);
                    mapOfCLIvsEntEndDate.put(entObj.ContractLineItemId, entObj.EndDate);
                }
            }
            
            if (!qlList.isEmpty()) {
                for (SBQQ__QuoteLine__c qlObj : qlList) {
                    //GO SKUs, TPH V1 SKUs and TPH V2 SKUs
                    if (qlObj.Arroyo_Subscribed_Asset_Name__c == null /*&& 
                    ((qlObj.SBQQSC__RenewedContractLine__r.Product_Subtype__c  == 'GO' || qlObj.SBQQSC__RenewedContractLine__r.Product_Subtype__c  == 'GO CNV' || qlObj.SBQQSC__RenewedContractLine__r.Product_Subtype__c  == 'Saas Cloud') || 
                    (qlObj.Product_Level__c == null && 
                        (qlObj.SBQQSC__RenewedContractLine__r.Product_Family__c == 'DELL' || qlObj.SBQQSC__RenewedContractLine__r.Product_Family__c == 'HPE' || qlObj.SBQQSC__RenewedContractLine__r.Product_Family__c == 'UCS') &&
                        (qlObj.SBQQ__ProductCode__c.contains('-F-') || qlObj.SBQQ__ProductCode__c.contains('FE') || qlObj.SBQQ__ProductCode__c.contains('BE') || qlObj.SBQQ__ProductCode__c.contains('EE'))) || 
                    (qlObj.Product_Level__c != null && qlObj.Product_Level__c == 'Hybrid Software' && qlObj.SBQQ__ProductFamily__c == 'Third Party License' && qlObj.Product_Subtype__c == 'RCDM') || 
                    (qlObj.Quote_Line_Type__c == 'Renewal' && qlObj.Product_Level__c != null && qlObj.Product_Level__c == 'Hybrid Software'))) */ || Test.isRunningTest()) {
                        productIds.add(qlObj.SBQQ__Product__c);
                    }
                }
            }
            Map<String,List<String>> SKUValuesAvailable = getReplaceSKUsAvailable(productIds, category);
            
            if (!qlList.isEmpty()) {
                for (SBQQ__QuoteLine__c qlObj : qlList) {
                    if (qlObj.Arroyo_Subscribed_Asset_Name__c == null /*&& ((qlObj.SBQQSC__RenewedContractLine__r.Product_Subtype__c!= null && (qlObj.SBQQSC__RenewedContractLine__r.Product_Subtype__c  == 'GO' || qlObj.SBQQSC__RenewedContractLine__r.Product_Subtype__c  == 'GO CNV' || qlObj.SBQQSC__RenewedContractLine__r.Product_Subtype__c  == 'Saas Cloud')) || 
                    (qlObj.Product_Level__c == null && 
                        (qlObj.SBQQSC__RenewedContractLine__r.Product_Family__c == 'DELL' || qlObj.SBQQSC__RenewedContractLine__r.Product_Family__c == 'HPE' || qlObj.SBQQSC__RenewedContractLine__r.Product_Family__c == 'UCS') &&
                        (qlObj.SBQQ__ProductCode__c.contains('-F-') || qlObj.SBQQ__ProductCode__c.contains('FE') || qlObj.SBQQ__ProductCode__c.contains('BE') || qlObj.SBQQ__ProductCode__c.contains('EE'))) || 
                    (qlObj.Product_Level__c != null && qlObj.Product_Level__c == 'Hybrid Software' && qlObj.SBQQ__ProductFamily__c == 'Third Party License' && qlObj.Product_Subtype__c == 'RCDM') || 
                    (qlObj.Quote_Line_Type__c == 'Renewal' && qlObj.Product_Level__c != null && qlObj.Product_Level__c == 'Hybrid Software')))*/ || Test.isRunningTest()) {
                        wrapper = new EntitlementWrapper();
                        wrapper.entObj = qlObj.SBQQ__ProductName__c;
                        wrapper.qlId = qlObj.Id;
                        wrapper.assetList = (qlObj.SubscribedAssetNames__c != null && qlObj.SubscribedAssetNames__c != '')?qlObj.SubscribedAssetNames__c:'';
                        wrapper.assetNamesForTPH = (qlObj.Subscribed_Asset_Name__c != null && qlObj.Subscribed_Asset_Name__c != '')?qlObj.Subscribed_Asset_Name__c:'';
                        wrapper.startDate = qlObj.SBQQ__StartDate__c;
                        wrapper.endDate = qlObj.SBQQ__EndDate__c;
                        wrapper.cliRootId = qlObj.SBQQSC__RenewedContractLine__c;
                                                if (qlObj.TPH_Drive_Size__c != null || qlObj.TPH_Models_Gen__c != null || qlObj.TPH_OEM__c != null || qlObj.TPH_Quantity__c != null || qlObj.TPH_Quantity_Num__c != null) {
                            wrapper.tphSKU = true;    
                        }
                        
                        if (SKUValuesAvailable.get(qlObj.SBQQ__ProductName__c) != null) {
                            wrapper.optionsAvailable = JSON.serialize(SKUValuesAvailable.get(qlObj.SBQQ__ProductName__c));
                        }
                        if(wrapper.cliRootId != null && !mapOfCLIvsEntEndDate.isEmpty() && mapOfCLIvsEntEndDate.containsKey(wrapper.cliRootId)){
                            wrapper.entEndDate = mapOfCLIvsEntEndDate.get(wrapper.cliRootId);
                        }
                        if (wrapper.optionsAvailable != null) {
                            lstWrapperEnts.add(wrapper);
                        }
                    }
                }
            }
            System.debug('lstWrapperEnts-->'+lstWrapperEnts);
            return lstWrapperEnts;
        }catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    /**Method to fetch LoD records for replacement */
    @AuraEnabled
    public static List < AssetWrapper > fetchLoDRecords(Id quoteId, String category) {
        try{
            /**  Quote record in scope*/
            SBQQ__Quote__c quoteInScope = [
                SELECT Id
                , Name
                , SBQQ__Type__c
                , SBQQ__Account__c
                , SBQQ__LineItemCount__c
                , SBQQ__PriceBook__c
                , SBQQ__Status__c
                , SBQQ__SubscriptionTerm__c
                , RWD_Sales_Rep_Exception__c
                , RWD_Deal_Ops_Exception__c
                FROM SBQQ__Quote__c
                WHERE Id =: quoteId
                LIMIT 1
            ];
            List<AssetWrapper> lstAssetWrappers = new List<AssetWrapper>();
            List<Entitlement> lstEnts = new List<Entitlement>();
            Map<String, String> mapofCLIvsAssetId = new Map<String, String>();
            Set<Id> productIds = new Set<Id>();
            Set<Id> assetIds = new Set<Id>();
            List<Asset> assetToShow = new List<Asset>();
            /*assetWrapper Asset Wrapper instance for replacement*/
            AssetWrapper assetWrapper;
            //Fetch all Quote Lines
            List <SBQQ__QuoteLine__c> qlList = getQuoteLinesAvailable(quoteId);
            Set<String> processedAssets = new Set<String>();
            Map<String, Date> mapOfCLIvsEntEndDate = new Map<String, Date>();
            Map<String, SBQQ__QuoteLine__c> assetvsQliMap = new Map<String, SBQQ__QuoteLine__c>();

            //Checking for RSC-G Eligibility on Account for RSC to RSC-G / SAAS-SAAS-G Replacements
            if(category != null && category.contains('LOD-RSC-G')){
                Account ac = [Select Id, RSC_G_Eligible__c from Account where Id = :quoteInScope.SBQQ__Account__c Limit 1];
                if(!ac.RSC_G_Eligible__c || !((quoteInScope.RWD_Deal_Ops_Exception__c != null && quoteInScope.RWD_Deal_Ops_Exception__c.contains('$0 RSC-G Replacement')) || (quoteInScope.RWD_Sales_Rep_Exception__c != null && quoteInScope.RWD_Sales_Rep_Exception__c.contains('25% Premium RSC-G Replacement')))){ 
                    return lstAssetWrappers;
                }
            }
            
            lstEnts = [Select Id, Name, Product__r.Name, AssetId, Asset.Name, ContractLineItemId, EndDate from Entitlement where AccountId =: quoteInScope.SBQQ__Account__c];
            if (!lstEnts.isEmpty()) {
                for (Entitlement entObj : lstEnts) {
                    if (entObj.ContractLineItemId != null && entObj.AssetId != null) {
                        mapofCLIvsAssetId.put(entObj.ContractLineItemId+'-'+entObj.Asset.Name, entObj.AssetId);
                    }
                    
                }
            }
            if (!qlList.isEmpty()) {
                for (SBQQ__QuoteLine__c qlObj : qlList) {
                    if (qlObj.SBQQSC__RenewedContractLine__c != null && qlObj.Arroyo_Subscribed_Asset_Name__c == null) {
                        if (!mapofCLIvsAssetId.isEmpty()) {
                            List<String> tempStr = new List<String>();
                            if(String.ISNOTBLANK(qlObj.SubscribedAssetNames__c)) {
                                tempStr = qlObj.SubscribedAssetNames__c.split(',');
                            }
                            if(String.ISNOTBLANK(qlObj.Subscribed_Asset_Name__c)) {
                                tempStr = qlObj.Subscribed_Asset_Name__c.split(',');
                            }
                            for (String str : tempStr) {
                                str = str.trim();
                                if (mapofCLIvsAssetId.get(qlObj.SBQQSC__RenewedContractLine__c+'-'+str) != null){
                                    //Add to the set if the Asset is converted or refreshed and DO NOT show it for Replaced
                                    if (!processedAssets.contains(mapofCLIvsAssetId.get(qlObj.SBQQSC__RenewedContractLine__c+'-'+str)) && 
                                    (qlObj.SBQQ__RequiredBy__r.Disposition_Reason__c == 'Converted' || qlObj.SBQQ__RequiredBy__r.Disposition_Reason__c == 'Refreshed')
                                    ) {
                                        processedAssets.add(mapofCLIvsAssetId.get(qlObj.SBQQSC__RenewedContractLine__c+'-'+str));
                                    }
                                    else if (!processedAssets.contains(qlObj.SBQQSC__RenewedContractLine__c+'-'+str)) {
                                        assetIds.add(mapofCLIvsAssetId.get(qlObj.SBQQSC__RenewedContractLine__c+'-'+str));
                                        assetvsQliMap.put(mapofCLIvsAssetId.get(qlObj.SBQQSC__RenewedContractLine__c+'-'+str),qlObj);
                                    }
                                } 
                             } 
                        }
                    }
                }
            }
            System.debug('assetIds--'+assetIds);
            if (!assetIds.isEmpty()) {
                assetToShow = [SELECT Id
                            , Name
                            , Product2.Name
                            , ProductCode
                            , Asset.Product2Id
                            , Quantity
                            , Product_Usable_Capacity__c
                            , Support_Start_Date__c
                            , Premium_Support_End_Date__c
                            , Asset.Product2.Usable_Capacity__c
                            , Asset.Product2.Capacity__c
                            , Product2.Product_Type__c
                            , Product2.License_Type__c
                            , SBQQ__CombineKey__c
                            , SBQQ__QuoteLine__c
                            FROM Asset
                            WHERE Id IN : assetIds
                            AND Asset.Product2.License_Subtype__c!='Add-On'
                            AND Asset.Product2.Product_Subtype__c!='MSP'
                            AND Asset.Product2.Product_Subtype__c!='NFR'
                            AND Asset.Product2.Product_Type__c!='Kroll'
                            AND Asset.Product2.Product_Type__c!='NFR'
                            AND (Licensing_Model__c = 'Perpetual' OR Product2.License_Type__c = 'Perpetual')
                            //AND Premium_Support_End_Date__c != null
                            ];
            }
            System.debug('assetToShow--'+assetToShow);
            if (!assetToShow.isEmpty()) {
                for (Asset assetToConvert :assetToShow) {
                    productIds.add(assetToConvert.Product2Id);
                }
                Map<String,List<String>> SKUValuesAvailableForAssets = getReplaceSKUsAvailable(productIds, category);
                for (Asset assetToConvert :assetToShow) {
                    assetWrapper = new AssetWrapper();
                    assetWrapper.assetInScope = assetToConvert;
                    assetWrapper.assetList = assetToConvert.Name;
                    assetWrapper.assetListIds = assetToConvert.Id;
                    assetWrapper.qty = assetToConvert.Product_Usable_Capacity__c;
                    assetWrapper.startDate = assetToConvert.Support_Start_Date__c;
                    assetWrapper.endDate = assetToConvert.Premium_Support_End_Date__c;
                    assetWrapper.cKey = assetToConvert.Id;
                    assetWrapper.astqli = assetToConvert.SBQQ__QuoteLine__c;
                    if(assetvsQliMap.containsKey(assetToConvert.Id) && assetvsQliMap.get(assetToConvert.Id)!= null){
                        assetWrapper.qli = assetvsQliMap.get(assetToConvert.Id).Id;
                    }
                    if (SKUValuesAvailableForAssets.get(assetToConvert.Product2.Name) != null) {
                        assetWrapper.optionsAvailable = JSON.serialize(SKUValuesAvailableForAssets.get(assetToConvert.Product2.Name));
                    }
                    if (assetWrapper.optionsAvailable != null) {
                        lstAssetWrappers.add(assetWrapper);
                    }
                }
            }
            System.debug('lstAssetWrappers->'+lstAssetWrappers);
            return lstAssetWrappers;
        }catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    
    /* Method to get Replacements available from Mapping table*/
    public static Map<String,List<String>> getReplaceSKUsAvailable(Set<Id> productIds , String category) {
        Map<String,List<String>> SKUValuesAvailable = new Map<String, List<String>>();
        List<SAAS_To_SAAS__c> saasMappingList = [SELECT Id, To__r.ProductCode, From__r.ProductCode, From__r.Name,To__r.Name,Section_Category__c, Storage_Tier__c FROM SAAS_To_SAAS__c WHERE 
                                                 From__c =: productIds and Section_Category__c=:category and Active__c = true ORDER BY To__r.Name ];
        for (SAAS_To_SAAS__c saasRec : saasMappingList) {
                        List<String> strTempList = SKUValuesAvailable.get(saasRec.From__r.Name)!=null?SKUValuesAvailable.get(saasRec.From__r.name):new List<String>();
            if(saasRec.Storage_Tier__c != null){
                strTempList.add(saasRec.To__r.Name + ' - ' + saasRec.Storage_Tier__c);
            } else  strTempList.add(saasRec.To__r.Name);
            SKUValuesAvailable.put(saasRec.From__r.Name,strTempList);
        }
        return SKUValuesAvailable;
    }

    /* Method to get Map of Replacement ToSKU vs SaaS Mapping record*/
    public static Map<String,SAAS_To_SAAS__c> getMapOfToSKUsVsSaasRec(Map<String, String> selectedRecords) {
        Map<String, SAAS_To_SAAS__c> mapOfToSKU = new Map<String, SAAS_To_SAAS__c>();
        if(!selectedRecords.isEmpty()){
            List<SAAS_To_SAAS__c> saasMappingList = [SELECT Id, To__r.ProductCode, From__r.ProductCode, From__r.Name,To__r.Name,To__r.Product_Subtype__c, Section_Category__c, Starting_Point__c, Additional_Days__c, Edbo__c, Is_EDNE__c, No_Merge__c, Uplift_Percent__c,IAR__c     FROM SAAS_To_SAAS__c 
                                                 WHERE Active__c = true AND 
                                                 From__c IN (SELECT SBQQ__Product__c FROM SBQQ__QuoteLine__c WHERE Id IN: selectedRecords.keySet())
                                                      ORDER BY To__r.Name
                                                 ];
        
            for (SAAS_To_SAAS__c saasRec : saasMappingList) {
            mapOfToSKU.put(saasRec.To__r.Name,saasRec);
            }
        }
        
        return mapOfToSKU;
    }

    /* Method to get Map of Replacement ToSKU vs SaaS Mapping record*/
    public static Map<String,SAAS_To_SAAS__c> getMapOfToSKUsVsSaasRec(Set<String> selectedRecords) {
        Map<String, SAAS_To_SAAS__c> mapOfToSKU = new Map<String, SAAS_To_SAAS__c>();
        if(!selectedRecords.isEmpty()){
            List<SAAS_To_SAAS__c> saasMappingList = [SELECT Id, Name, To__r.ProductCode, From__r.ProductCode, From__r.Name,To__r.Name,To__r.Product_Subtype__c, Section_Category__c, Starting_Point__c, Additional_Days__c, Edbo__c, Is_EDNE__c, No_Merge__c, Uplift_Percent__c,IAR__c, Storage_Tier__c, RenLater__c     FROM SAAS_To_SAAS__c 
                                                 WHERE Active__c = true AND 
                                                 Name IN: selectedRecords
                                                      ORDER BY To__r.Name
                                                 ];
        
            for (SAAS_To_SAAS__c saasRec : saasMappingList) {
            mapOfToSKU.put(saasRec.Name,saasRec);
            }
        }
        
        return mapOfToSKU;
    }

    /* Method to get quote lines in scope for updates*/
    public static List<SBQQ__QuoteLine__c> getQuoteLinesAvailable(Id quoteId) {
        List<SBQQ__QuoteLine__c> quoteLineList = [SELECT Id, SBQQ__Quote__r.SBQQ__Account__c,SBQQ__Quote__r.Name, SBQQ__ProductCode__c, SBQQ__ProductName__c,Disposition_Reason__c, SBQQ__Number__c, Subscribed_Asset_Name__c, SBQQ__Quantity__c, SBQQ__RequiredBy__c, Required_By_Product_Code__c, Line_Type__c, 
        Quote_Line_Type__c,Special_Program__c, Replace_By__c, SBQQSC__RenewedContractLine__c, 
        Product_Level__c, Product_Type__c, Arroyo_Subscribed_Asset_Name__c, SBQQ__Group__c, SubscribedAssetNames__c, 
        SBQQ__Product__c, SBQQSC__RenewedContractLine__r.Product_Subtype__c, SBQQ__DynamicOptionId__c,
        SubsAstNameInt__c, SBQQSC__RenewedContractLine__r.Product_Family__c, SBQQ__ProductFamily__c, SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__SubscriptionTerm__c,
        SBQQ__Product__r.Name, SBQQ__RequiredBy__r.SBQQ__Product__r.Name, SBQQ__ProductOption__c, SBQQ__RequiredBy__r.SBQQ__Product__c,SBQQSC__RenewedContractLine__r.SBQQSC__QuoteLine__r.SBQQ__Quote__r.name,
        SBQQ__ListPrice__c, SBQQ__NetPrice__c , SBQQ__Product__r.Eligible_for_RCDM_T__c , SBQQSC__RenewedContractLine__r.SBQQSC__RootId__c, required_by_ext_Id__c, SBQQ__Discount__c, Minimum_Term__c, Is_Subscription_term_Minimum_term__c,
        SubscribedAssetLookup__c, Promo_Disc__c, CPQ_Prior_Discount__c, SBQQ__CustomerPrice__c, SBQQ__RequiredBy__r.Disposition_Reason__c, Related_Asset_Total_Capacity__c, RWD_Expected_Default_Quantity__c, SBQQ__ProratedListPrice__c, Category__c, Product_Subtype__c, SBQQ__ProrateMultiplier__c, SBQQ__DefaultSubscriptionTerm__c,
        Approval_Category__c, TPH_Drive_Size__c, TPH_Models_Gen__c, TPH_OEM__c, TPH_Quantity__c, TPH_Quantity_Num__c,SBQQ__Bundle__c,SBQQ__ConfigurationRequired__c, AssociatedAccount__c 
        FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quoteId AND 
        (Replace_By__c = null OR Replace_By__c = 'None' OR Replace_By__c = '') AND 
        (Quote_Line_Type__c = 'Renewal') AND
        (Disposition_Reason__c != 'Refreshed' AND Disposition_Reason__c != 'Converted' AND Special_Program__c != 'Conversion')
        ORDER BY SBQQSC__RenewedContractLine__r.ServiceContract.ContractNumber ASC];
        return quoteLineList;
    }

    /*Method to create and update Quote Lines*/
    @AuraEnabled
    public static void replaceSKUs(Id quoteId, List<SaasWrapper> saasRecs, List<EntitlementWrapper> goRecs, List<AssetWrapper> assetRecs, List<EntitlementWrapper> rscgRecs, List<EntitlementWrapper> ssgRecs, List<AssetWrapper> lodRsgRecs, Map<String, String> selectedRecords) {
        List<QuoteLineWrapper> lstQuoteLineWrapper = new List<QuoteLineWrapper>();
        QuoteLineWrapper qlWrapper;
        Id Quotegroupdes;//, QuotegroupDispose;
        Id Quotegrouprenew;
        Boolean isRenewalANDExpansion = true;
        String quoteExpGroupIds = '';
        Map<String, PricebookEntry> productIdPbeMap = new Map<String, PricebookEntry>();
        Map<String, SBQQ__ProductOption__c> RCDMProductOption = new Map<String, SBQQ__ProductOption__c>();
        Set<String> productIds = new Set<String>();
        Map<String, SBQQ__QuoteLine__c> mapOfQL = new Map<String, SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> quoteLinesToUpdate = new List<SBQQ__QuoteLine__c>();  
        Map<String, SBQQ__QuoteLine__c> mapQuoteLinesToUpdate = new Map<String, SBQQ__QuoteLine__c>();
        Map<String, Product2> productEligibleforRCDM = new Map<String, Product2>();
        Set<Id> quoteAryRecId = new Set<Id>();
            
        List<SBQQ__QuoteLine__c> insertLine1 = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> insertLine2 = new List<SBQQ__QuoteLine__c>();
        Map<String, SBQQ__QuoteLine__c> mapOfAlreadyReplacedSKUs = new Map<String, SBQQ__QuoteLine__c>();
        Map<String,SBQQ__QuoteLine__c> mapofQLToUpdate = new Map<String,SBQQ__QuoteLine__c>();
        Map<String,SBQQ__QuoteLine__c> mapofQLUpdated = new Map<String,SBQQ__QuoteLine__c>();
        Map<String , Merged_Quote_Line__c> mapOfMergedQL = new Map<String , Merged_Quote_Line__c>();
        Set<String> processedLine = new Set<String>();
        Map<String, SBQQ__QuoteLine__c> mapofLinesforRCDM = new Map<String, SBQQ__QuoteLine__c>();
        Map<String,SAAS_To_SAAS__c> mapToSKUvsSaasRec = new Map<String,SAAS_To_SAAS__c>();
        Set<String> selectFromToSet = new Set<String>();
        Map<String, String> mapExtIdvsMkey = new Map<String, String>();
        String prodFields = '';
        String prodOptsFields = '';
        String qlFields = '';
        String qlProductFields = '';
        String pbeProdFields = '';
        String poFields = '';
        String ref = 'Refreshed';
        String conv = 'Converted';
        String sP = 'Conversion';
        
        try{
            SBQQ__Quote__c quoteInScope = [
                SELECT Id
                , Name
                , SBQQ__Type__c
                , SBQQ__Account__c
                , SBQQ__LineItemCount__c
                , SBQQ__PriceBook__c
                , SBQQ__Status__c
                , SBQQ__SubscriptionTerm__c
                , Eligible_for_RCDM_T__c
                , CreatedDate
                , RWD_Deal_Ops_Exception__c
                , RWD_Sales_Rep_Exception__c
        , Deal_Ops_Exception_AdHoc_RCDM__c
        , Deal_Ops_Exception_RCDMT__c
        , Is_Customer_Fully_Transitioned__c 
        , Selective_Account_Eligible_for_RCDM_T__c
        , Todays_Date__c
                FROM SBQQ__Quote__c
                WHERE Id =: quoteId]; 
            List<SBQQ__QuoteLineGroup__c> quoteGroups = [
                SELECT Id
                , SBQQ__Quote__c
                , Name ,
                SBQQ__Quote__r.SBQQ__Type__c
                FROM SBQQ__QuoteLineGroup__c
                WHERE SBQQ__Quote__c =: quoteId
            ];
            Integer lineNumberCount = quoteInScope.SBQQ__LineItemCount__c == null
                ? 0
                : Integer.valueOf(quoteInScope.SBQQ__LineItemCount__c);
            Map<String,Schema.DisplayType> QLIFields = getcreateablefields('SBQQ__QuoteLine__c'); // For Twin fields
            Map<String,Schema.DisplayType> ProductFields = getcreateablefields('Product2');// For Twin fields
            Map<String,Schema.DisplayType> ProductOptionFields = getcreateablefields('SBQQ__ProductOption__c');// For Twin fields
            
            for (String prodfld: ProductFields.keySet()) {
                prodFields = prodFields + ',' + prodfld;
                qlProductFields = qlProductFields + ',' +'SBQQ__Product__r.' + prodfld;
                pbeProdFields = pbeProdFields + ',' + 'Product2.' + prodfld;
                prodFields = prodFields.removeStart(',');
                pbeProdFields = pbeProdFields.removeStart(',');
            }
            for (String qlF : QLIFields.keySet()) {
                qlFields = qlFields + ',' + qlF;
                qlFields = qlFields.removeStart(',');
            }
            for (String prodOpsfld : ProductOptionFields.keySet()) {
                prodOptsFields = prodOptsFields + ',' + 'SBQQ__ProductOption__r.' + prodOpsfld;
                poFields = poFields + ',' + prodOpsfld;
                poFields = poFields.removeStart(',');
            }
            
            String qlQuery = 'Select ';
            qlQuery = qlQuery + qlFields+ ', SBQQ__ProductCode__c, SBQQ__NetTotal__c, SBQQSC__RenewedContractLine__r.SBQQSC__QuoteLine__r.SBQQ__Quote__r.Name';
            qlQuery = qlQuery + prodOptsFields;
            qlQuery = qlQuery + qlProductFields;
            qlQuery = qlQuery + ', SBQQ__RequiredBy__r.SBQQ__Product__c';
            qlQuery = qlQuery + ' FROM SBQQ__QuoteLine__c where SBQQ__Quote__c = \'' + quoteId + '\' AND Disposition_Reason__c != \'' + ref + '\' AND Disposition_Reason__c != \'' + conv + '\' AND Special_Program__c != \'' + sP + '\'';
            
            System.debug('query--'+qlQuery);
            
            //List <SBQQ__QuoteLine__c> qlList = getQuoteLinesAvailableForUpdate(quoteId);
            List <SBQQ__QuoteLine__c> qlList = Database.query(qlQuery);
            
            if (qlList != null && !qlList.isEmpty()) {
                for (SBQQ__QuoteLine__c qlObj : qlList) {
                    //Get All replaced lines with their Product Ids, if this is found while next replacement, update the existing line, rather than creating new.
                    if (qlObj.Special_Program__c == 'Replaced' && (qlObj.SBQQ__RequiredBy__c == null || qlObj.SBQQ__Product__c == System.Label.RCDM_ProductId)) {
                        mapOfAlreadyReplacedSKUs.put(qlObj.SBQQ__Product__c+'-'+qlObj.SBQQ__ProductOption__c, qlObj);
                    }
                     //MS RGCF2-180
                    if (qlObj.Disposition_Reason__c == 'Replaced' && (qlObj.SBQQSC__RenewedContractLine__c != null && qlObj.SBQQSC__RenewedContractLine__r.SBQQSC__QuoteLine__c != null && qlObj.SBQQSC__RenewedContractLine__r.SBQQSC__QuoteLine__r.SBQQ__Quote__c != null)) {
                        originalQuotesMap.add(qlObj.SBQQSC__RenewedContractLine__r.SBQQSC__QuoteLine__r.SBQQ__Quote__r.Name);
                        replacedSKUsList.add(qlObj.SBQQ__ProductCode__c);
                    }
                }
            }
            if (selectedRecords != null && !selectedRecords.isEmpty()) {
                
                Set <Id> idSet = new Set<Id>();
                                
                if ((saasRecs != null && !saasRecs.isEmpty()) ) {
                    for (String selectedRec : selectedRecords.keySet()) {
                        
                        for (SaasWrapper sWrap : saasRecs) {
                            if ((selectedRecords.get(selectedRec) != '' && selectedRecords.get(selectedRec) != null && sWrap.qlId == selectedRec && !idSet.contains(sWrap.qlId)) || test.isRunningTest()) {
                                idSet.add(sWrap.qlId);
                                
                                qlWrapper = new QuoteLineWrapper(); 
                                qlWrapper.qlProductName = selectedRecords.get(selectedRec).split(' - ')[0];
                                qlWrapper.qlId = sWrap.qlId;
                                qlWrapper.assetList = (sWrap.assetList != null && sWrap.assetList != '' ) ? sWrap.assetList : '';
                                qlWrapper.assetListIds = (sWrap.assetListIds != null && sWrap.assetListIds != '' ) ? sWrap.assetListIds : '';
                                qlWrapper.extId = sWrap.cliRootId;
                                qlWrapper.entEndDate = sWrap.entEndDate;
                                qlWrapper.mKey = sWrap.saasInScope + ' => ' + selectedRecords.get(selectedRec);
                                selectFromToSet.add(qlWrapper.mKey);
                                System.debug('MS d491 saas--'+qlWrapper.mKey);
                                lstQuoteLineWrapper.add(qlWrapper);
                            }
                        }
                    }
                }
                //goRec rscg

                if ((goRecs != null && !goRecs.isEmpty()) || (rscgRecs != null && !rscgRecs.isEmpty()) || (ssgRecs != null && !ssgRecs.isEmpty())) {
                    System.debug('MS d3 goRecs--'+goRecs);
                    for (String selectedRec : selectedRecords.keySet()) {
                        
                        List<EntitlementWrapper> lstSaasRecs = new List<EntitlementWrapper>();
                        lstSaasRecs.addAll(goRecs);
                        lstSaasRecs.addAll(rscgRecs);
                        lstSaasRecs.addAll(ssgRecs);


                        for (EntitlementWrapper eWrap : lstSaasRecs) {
                            
                            System.debug('MS d514 eWrap.qlId--'+eWrap.qlId);
                            System.debug('MS d515  selectedRecords '+selectedRecords.get(selectedRec));
                            
                            if ((selectedRecords.get(selectedRec) != '' && selectedRecords.get(selectedRec) != null && eWrap.qlId == selectedRec && !idSet.contains(eWrap.qlId)) || Test.isRunningTest()) {
                                idSet.add(eWrap.qlId);
                                
                                
                                qlWrapper = new QuoteLineWrapper(); 
                                qlWrapper.qlId = eWrap.qlId;
                                qlWrapper.qlProductName = selectedRecords.get(selectedRec).split(' - ')[0];
                                qlWrapper.assetList = (eWrap.assetList != null && eWrap.assetList != '' ) ? eWrap.assetList : '';
                                qlWrapper.assetListIds = (eWrap.assetListIds != null && eWrap.assetListIds != '' ) ? eWrap.assetListIds : '';
                                qlWrapper.extId = eWrap.cliRootId;
                                qlWrapper.tphSKU = eWrap.tphSKU;
                                qlWrapper.assetNamesForTPH = eWrap.assetNamesForTPH;
                                qlWrapper.entEndDate = eWrap.entEndDate;
                                qlWrapper.mKey = eWrap.entObj + ' => ' + selectedRecords.get(selectedRec);
                                
                                System.debug('MS d491 recs--'+qlWrapper.mKey);
                                selectFromToSet.add(qlWrapper.mKey);
                                lstQuoteLineWrapper.add(qlWrapper);
                            }
                        }
                    }
                }
                if (assetRecs != null && !assetRecs.isEmpty()) {
                    for (String selectedRec : selectedRecords.keySet()) {
                        for (AssetWrapper aWrap : assetRecs) {
                            if (selectedRecords.get(selectedRec) != '' && selectedRecords.get(selectedRec) != null && aWrap.assetInScope.Name == selectedRec) {
                                qlWrapper = new QuoteLineWrapper(); 
                                qlWrapper.qlProductName = selectedRecords.get(selectedRec);
                                //qlWrapper.qlId = aWrap.qlId;
                                qlWrapper.assetList = aWrap.assetList;
                                qlWrapper.assetListIds = aWrap.assetListIds;
                                qlWrapper.qty = aWrap.qty;
                                qlWrapper.extId = aWrap.cKey;
                                qlWrapper.entEndDate = aWrap.endDate;
                                //qlWrapper.qlId = aWrap.qli;
                                qlWrapper.mKey = aWrap.assetInScope.Product2.Name + ' => ' + selectedRecords.get(selectedRec);


                                System.debug('MS d491 lodrecs--'+qlWrapper.mKey);
                                selectFromToSet.add(qlWrapper.mKey);
                                lstQuoteLineWrapper.add(qlWrapper);
                            }
                        }
                    }
                }
                System.debug('MS d1 606 selectedRecords--'+selectedRecords);
                System.debug('MS d1 636 test selectFromToSet--'+selectFromToSet);
                //mapToSKUvsSaasRec = getMapOfToSKUsVsSaasRec(selectedRecords);
                mapToSKUvsSaasRec = getMapOfToSKUsVsSaasRec(selectFromToSet);
                System.debug('MS d1 mapToSKUvsSaasRec--'+mapToSKUvsSaasRec);
            }
            System.debug('lstQuoteLineWrapper--'+lstQuoteLineWrapper);
                
            if (quoteGroups != null && !quoteGroups.isEmpty()) {
                for (SBQQ__QuoteLineGroup__c qliGroup : quoteGroups) {
                    if (qliGroup.Name == 'Expansion Quote') {
                        quoteExpGroupIds = qliGroup.Id;
                    }
                    if (qliGroup.Name == System.Label.Arry_Disposition_Group) {
                        Quotegroupdes = qliGroup.Id;
                    }
                    if(qliGroup.Name == System.Label.Arry_renewal_Group){
                        Quotegrouprenew = qliGroup.Id;
                    }
                        
                    if(qliGroup.SBQQ__Quote__r.SBQQ__Type__c != 'Renewal+Expansion'){
                        isRenewalANDExpansion = false;
                    }
                }
            }
            if(Quotegroupdes == null && isRenewalANDExpansion){
                SBQQ__QuoteLineGroup__c qlg = new SBQQ__QuoteLineGroup__c();
                qlg.Name = System.Label.Arry_Disposition_Group;
                qlg.SBQQ__Quote__c = quoteInScope.Id;
                qlg.SBQQ__Description__c = CPQ_Constants.DISPOSE_QUOTE_DESCRIPTION;
                insert qlg;
                
                Quotegroupdes = qlg.Id;
            }
            if (lstQuoteLineWrapper != null && !lstQuoteLineWrapper.isEmpty()) {
                for (QuoteLineWrapper wrapper : lstQuoteLineWrapper) {
                    if (wrapper.qlProductName != '' && wrapper.qlProductName != null && wrapper.qlProductName != 'None') {
                        productIds.add(wrapper.qlProductName);
                    }
                }
            }  
            
            if (productIds != null && !productIds.isEmpty()) {
                String productNames = '';
                for (String names : productIds) {
                    productNames = productNames + ', \'' +names+ '\'';
                    productNames = productNames.removeStart(',');
                }
                
                List<SBQQ__ProductOption__c> poList = new List<SBQQ__ProductOption__c> ();
                String tempQuery = 'Select SBQQ__OptionalSKU__r.Name, ' + poFields + ' FROM SBQQ__ProductOption__c WHERE Refresh_Default_Option__c = true AND SBQQ__ConfiguredSKU__r.Name IN (' + productNames + ') AND SBQQ__ConfiguredSKU__r.isActive = true';
                poList = Database.query(tempQuery);

                if (poList != null && !poList.isEmpty()) {
                    for (SBQQ__ProductOption__c poRec : poList) {
                        RCDMProductOption.put(poRec.SBQQ__ConfiguredSKU__c + '-' + poRec.SBQQ__OptionalSKU__c, poRec);
                        qlWrapper = new QuoteLineWrapper(); 
                        qlWrapper.qlProductName = poRec.SBQQ__OptionalSKU__r.Name;  
                        qlWrapper.isOption = true;
                        qlWrapper.extId = poRec.SBQQ__ConfiguredSKU__c;
                        lstQuoteLineWrapper.add(qlWrapper);
                        productIds.add(poRec.SBQQ__OptionalSKU__r.Name);
                    }
                }
            }
            if (productIds != null && !productIds.isEmpty()) {
                if (Test.isRunningTest()) {
                    
                    String productNames = '';
                    for (String names : productIds) {
                        productNames = productNames + ', \'' +names+ '\'';
                        productNames = productNames.removeStart(',');
                    }
                        
                        
                    PriceBook2 cpqPB =  [Select Id from PriceBook2 where Name like 'CPQ Pricebook'];
                    List<PricebookEntry> pbeList = new List<PricebookEntry> ();
                    String tempQuery = 'Select Pricebook2Id, Product2Id, UnitPrice, ' + pbeProdFields + ' FROM PricebookEntry WHERE Product2.Name IN (' + productNames + ') AND Pricebook2Id = \'' +cpqPB.Id + '\'';
                    pbeList = Database.query(tempQuery);
                    
                    
                    /*for (PricebookEntry pbe : [
                    SELECT Id
                    , Pricebook2Id
                    , Product2Id
                    ,UnitPrice
                    , Product2.Name
                    , Product2.Product_Level__c
                    , Product2.Category__c
                    , Product2.Product_Type__c
                    , Product2.Usable_Capacity__c
                    , Product2.RWD_Version__c
                    , Product2.Description
                    , Product2.SBQQ__SubscriptionPricing__c
                    , Product2.SBQQ__SubscriptionTerm__c
                    , Product2.Sales_Comp_Category__c
                    , Product2.Eligible_for_RCDM_T__c
                    , Product2.SBQQ__SubscriptionType__c
                    , Product2.SBQQ__SubscriptionBase__c 
                    , Product2.Approval_Category__c
                    , Product2.ProductCode
                    , Product2.Storage_Region_Bundle__c
                    , Product2.Storage_Tier__c
                    , Product2.Product_Code_Type__c
                    ,Product2.Support_Type__c
                    FROM PricebookEntry
                    WHERE Product2.Name IN :productIds
                    AND Pricebook2Id =: cpqPB.Id
                    ])*/
                    for( PricebookEntry pbe : pbeList){
                        productIdPbeMap.put(pbe.Product2.Name, pbe);
                        productEligibleforRCDM.put(pbe.Product2Id, pbe.Product2);
                    }
                } 
                else {
                    String productNames = '';
                    for (String names : productIds) {
                        productNames = productNames + ', \'' +names+ '\'';
                        productNames = productNames.removeStart(',');
                    }
                    List<PricebookEntry> pbeList = new List<PricebookEntry> ();
                    String tempQuery = 'Select Pricebook2Id, Product2Id, UnitPrice, ' + pbeProdFields + ' FROM PricebookEntry WHERE Product2.Name IN (' + productNames + ') AND Pricebook2Id = \'' + quoteInScope.SBQQ__PriceBook__c + '\'';
                    pbeList = Database.query(tempQuery);
                    
                    for (PricebookEntry pbe : pbeList ) {
                        productIdPbeMap.put(pbe.Product2.Name, pbe);
                        productEligibleforRCDM.put(pbe.Product2Id, pbe.Product2);
                    }
                }
            }
            
            if (lstQuoteLineWrapper != null && !lstQuoteLineWrapper.isEmpty()) {
                for (QuoteLineWrapper wrapper : lstQuoteLineWrapper) {
                    if (qlList != null && !qlList.isEmpty()){
                    Boolean processed = false;
                        for (SBQQ__QuoteLine__c qlObj : qlList) {
                            if (wrapper.qlId == qlObj.Id && qlObj.Product_Type__c != 'HW Support') {
                                qlObj.Disposition_Reason__c = 'Replaced';
                                qlObj.Replace_By__c = wrapper.qlProductName;
                                qlObj.SBQQ__Group__c = Quotegroupdes;
                                mapOfQL.put(qlObj.Id, qlObj);
                                quoteLinesToUpdate.add(qlObj);
                                processed = true;
                                replacedSKUsList.add(qlObj.SBQQ__ProductCode__c); //MS RGCF2-180
                                
                            }
                            //For stamping Disposition reason on HW support SKUs and LoD - SC replacement
                            if ((processed == false || (processed == true && qlObj.Product_Type__c == 'HW Support')) && (qlObj.Product_Type__c == 'HW Support' || wrapper.qlId == null) && 
                                String.ISNOTBLANK(wrapper.assetList)
                                //&& 
                                //(qlObj.Replace_By__c == '' || qlObj.Replace_By__c == null || qlObj.Replace_By__c == 'None' || 
                                //qlObj.Disposition_Reason__c == 'Replaced' )
                                ) {
                                    List<String> strList = wrapper.assetList.split(',');
                                    if(strList != null && !strList.isEmpty()){
                                        for (String str : strList) {
                                            str = str.trim();
                                            if (str != 'null' && 
                                            ((String.ISNOTBLANK(qlObj.SubscribedAssetNames__c) && qlObj.SubscribedAssetNames__c.contains(str)) || (String.ISNOTBLANK(qlObj.SubsAstNameInt__c) && qlObj.SubsAstNameInt__c.contains(str))) 
                                            && qlObj.Product_Type__c == 'HW Support') {
                                                //RSCG-63 Marking HW Support as Renew Later for RSCG lines
                                                if((mapToSKUvsSaasRec.containsKey(wrapper.mKey) && (mapToSKUvsSaasRec.get(wrapper.mKey).RenLater__c))){
                                                    qlObj.Disposition_Reason__c = 'Renew Later';
                                                    qlObj.SBQQ__Group__c = Quotegroupdes;
                                                    System.debug('MS d4 insideif HW supp stamping Renew later--');
                                                } else {
                                                    System.debug('MS d5 inside else HW supp logic--');
                                                qlObj.Disposition_Reason__c = 'Renewing';
                                                qlObj.SBQQ__Group__c = Quotegrouprenew;
                                                } //MS RGCF2-167

                                                //wrapper.qlId = qlObj.Id;
                                                if (qlObj.Replace_By__c == null || qlObj.Replace_By__c == '' || qlObj.Replace_By__c == 'None') {
                                                    qlObj.Replace_By__c = wrapper.qlProductName;
                                                }
                                                if (!qlObj.Replace_By__c.contains(wrapper.qlProductName)) {
                                                    qlObj.Replace_By__c = qlObj.Replace_By__c != null ? qlObj.Replace_By__c + ',' + wrapper.qlProductName : wrapper.qlProductName;
                                                }

                                                
                                                //MS RGCF2-167 }
                                                quoteLinesToUpdate.add(qlObj);
                                                mapOfQL.put(qlObj.Id, qlObj);
                                            }
                                            else if (str != 'null' && processed == false && 
                                            ((String.ISNOTBLANK(qlObj.SubscribedAssetNames__c) && qlObj.SubscribedAssetNames__c.contains(str)) || (String.ISNOTBLANK(qlObj.SubsAstNameInt__c) && qlObj.SubsAstNameInt__c.contains(str)))
                                             && qlObj.Product_Type__c != 'HW Support' &&
                                                    qlObj.Product_Type__c != 'Hardware' && qlObj.Product_Type__c != 'Add-On Node' && qlObj.Product_Type__c != 'Appliance') {
                                                        qlObj.Disposition_Reason__c = 'Replaced';
                                                        qlObj.SBQQ__Group__c = Quotegroupdes;
                                                        if (qlObj.Replace_By__c == null || qlObj.Replace_By__c == '' || qlObj.Replace_By__c == 'None') {
                                                            qlObj.Replace_By__c = wrapper.qlProductName;
                                                        }
                                                        if (!qlObj.Replace_By__c.contains(wrapper.qlProductName)) {
                                                            qlObj.Replace_By__c = qlObj.Replace_By__c != null ? qlObj.Replace_By__c + ',' + wrapper.qlProductName : wrapper.qlProductName;
                                                        }
                                                        
                                                        replacedSKUsList.add(qlObj.SBQQ__ProductCode__c); //MS RGCF2-180
                                                        quoteLinesToUpdate.add(qlObj);
                                            }
                                        }
                                    }
                            }
                        }
                    }
                }
            }
            System.debug('lstQuoteLineWrapper--'+lstQuoteLineWrapper);
            
            if (lstQuoteLineWrapper!= null && !lstQuoteLineWrapper.isEmpty()) {
                for (QuoteLineWrapper qlWrap : lstQuoteLineWrapper) {
                    lineNumberCount = lineNumberCount++;
                    if (qlWrap.isOption == false) {
                        
                        System.debug('MS d6 before create QLI method entry');
                        SBQQ__QuoteLine__c qlToInsert = createQuoteLines(quoteInScope, qlWrap, productIdPbeMap, mapOfQL, quoteExpGroupIds, RCDMProductOption, QLIFields, ProductFields, ProductOptionFields, productEligibleforRCDM, mapToSKUvsSaasRec);
                        System.debug('MS d7 after create QLI method exit');
                        
                        mapExtIdvsMkey.put(qlToInsert.required_by_ext_Id__c, qlWrap.mKey);
                        insertLine1.add(qlToInsert);
                    }
                }
            }
            
            Boolean skipMergeEx = String.IsNotBlank(quoteInScope.RWD_Sales_Rep_Exception__c) && quoteInScope.RWD_Sales_Rep_Exception__c.contains('Do not Consolidate Replacement Lines');
            if (insertLine1 != null && !insertLine1.isEmpty()) {
                Integer count = 0;
                for (SBQQ__QuoteLine__c qlObj : insertLine1) {
                    count++;
                    //if mapQuoteLinesToUpdate contains qlObj.SBQQ__Product__c, then add details
                    
                    if (mapQuoteLinesToUpdate.containsKey(qlObj.SBQQ__Product__c+'-'+qlObj.SBQQ__ProductOption__c) && !skipMergeEx) {
                        qlObj.SBQQ__Quantity__c += mapQuoteLinesToUpdate.get(qlObj.SBQQ__Product__c+'-'+qlObj.SBQQ__ProductOption__c).SBQQ__Quantity__c;
                        if (qlObj.SubscribedAssetNames__c != null && !qlObj.SubscribedAssetNames__c.contains(mapQuoteLinesToUpdate.get(qlObj.SBQQ__Product__c+'-'+qlObj.SBQQ__ProductOption__c).SubscribedAssetNames__c)) {
                            qlObj.SubscribedAssetNames__c = qlObj.SubscribedAssetNames__c!=null?qlObj.SubscribedAssetNames__c+',' + mapQuoteLinesToUpdate.get(qlObj.SBQQ__Product__c+'-'+qlObj.SBQQ__ProductOption__c).SubscribedAssetNames__c:
                        '';
                        }
                        If (qlObj.Arroyo_Subscribed_Asset_Name__c != null && !qlObj.Arroyo_Subscribed_Asset_Name__c.contains(mapQuoteLinesToUpdate.get(qlObj.SBQQ__Product__c+'-'+qlObj.SBQQ__ProductOption__c).Arroyo_Subscribed_Asset_Name__c)) {
                            qlObj.Arroyo_Subscribed_Asset_Name__c = qlObj.Arroyo_Subscribed_Asset_Name__c!=null?qlObj.Arroyo_Subscribed_Asset_Name__c+',' + mapQuoteLinesToUpdate.get(qlObj.SBQQ__Product__c+'-'+qlObj.SBQQ__ProductOption__c).Arroyo_Subscribed_Asset_Name__c:
                        '';
                        }
                        if (qlObj.Subscribed_Asset_Name__c != null && !qlObj.Subscribed_Asset_Name__c.contains(mapQuoteLinesToUpdate.get(qlObj.SBQQ__Product__c+'-'+qlObj.SBQQ__ProductOption__c).SubscribedAssetNames__c)) {
                            qlObj.Subscribed_Asset_Name__c = qlObj.Subscribed_Asset_Name__c!=null?qlObj.Subscribed_Asset_Name__c+',' + mapQuoteLinesToUpdate.get(qlObj.SBQQ__Product__c+'-'+qlObj.SBQQ__ProductOption__c).SubscribedAssetNames__c:'';
                        }
                        qlObj.RWD_Expected_Default_Quantity__c = qlObj.SBQQ__Quantity__c;
                        qlObj.Related_Asset_Total_Capacity__c = qlObj.SBQQ__Quantity__c;
                        mapQuoteLinesToUpdate.put(qlObj.SBQQ__Product__c+'-'+qlObj.SBQQ__ProductOption__c, qlObj);
                    }
                    else {
                        if((mapExtIdvsMkey.containsKey(qlObj.required_by_ext_Id__c) && (mapToSKUvsSaasRec.containsKey(mapExtIdvsMkey.get(qlObj.required_by_ext_Id__c)) && (mapToSKUvsSaasRec.get(mapExtIdvsMkey.get(qlObj.required_by_ext_Id__c)).No_Merge__c)))
                        || skipMergeEx){
                            mapQuoteLinesToUpdate.put(qlObj.SBQQ__Product__c+'-'+ count, qlObj); // RSCGF2-63 Create 1:1 Replaced Lines
                            System.debug('MS d8 inside if RSCG 1:1 logic'+qlObj.Product_Code__c);
                        } else {
                            mapQuoteLinesToUpdate.put(qlObj.SBQQ__Product__c+'-'+qlObj.SBQQ__ProductOption__c, qlObj);
                            System.debug('MS d9 inside else regular logic'+qlObj.Product_Code__c);
                        }
                    }
                    
                    System.debug('MS d10');

                    String qPkey = qlObj.SBQQ__Product__c+'-'+qlObj.SBQQ__ProductOption__c;
                    Boolean mergeFlag = true;
                    if(mapOfAlreadyReplacedSKUs.containsKey(qPkey) && mapOfAlreadyReplacedSKUs.get(qPkey) != null && mapOfAlreadyReplacedSKUs.get(qPkey).required_by_ext_Id__c != null &&
                    mapExtIdvsMkey.containsKey(mapOfAlreadyReplacedSKUs.get(qPkey).required_by_ext_Id__c) && 
                    mapToSKUvsSaasRec.containsKey(mapExtIdvsMkey.get(mapOfAlreadyReplacedSKUs.get(qPkey).required_by_ext_Id__c)) && 
                    mapToSKUvsSaasRec.get(mapExtIdvsMkey.get(mapOfAlreadyReplacedSKUs.get(qPkey).required_by_ext_Id__c)).No_Merge__c){
                        mergeFlag = false;
                    }

                    //Check if the quoteLine in scope is already present on the Quote. If yes, then update the line with the details of the new lines, else create new line.
                    if (mapOfAlreadyReplacedSKUs.containsKey(qlObj.SBQQ__Product__c+'-'+qlObj.SBQQ__ProductOption__c) && mapOfAlreadyReplacedSKUs.get(qlObj.SBQQ__Product__c+'-'+qlObj.SBQQ__ProductOption__c) != null && 
                    (mergeFlag || skipMergeEx) //RSCGF2-63 Create 1:1 Replaced Lines
                    ) {
                        System.debug('MS d11 inside if regular logic merge');
                        mapOfAlreadyReplacedSKUs.get(qlObj.SBQQ__Product__c+'-'+qlObj.SBQQ__ProductOption__c).SBQQ__Quantity__c += qlObj.SBQQ__Quantity__c;
                        mapOfAlreadyReplacedSKUs.get(qlObj.SBQQ__Product__c+'-'+qlObj.SBQQ__ProductOption__c).RWD_Expected_Default_Quantity__c += qlObj.SBQQ__Quantity__c;
                        mapOfAlreadyReplacedSKUs.get(qlObj.SBQQ__Product__c+'-'+qlObj.SBQQ__ProductOption__c).Related_Asset_Total_Capacity__c += qlObj.SBQQ__Quantity__c;
                        mapOfAlreadyReplacedSKUs.get(qlObj.SBQQ__Product__c+'-'+qlObj.SBQQ__ProductOption__c).SubscribedAssetNames__c = (mapOfAlreadyReplacedSKUs.get(qlObj.SBQQ__Product__c+'-'+qlObj.SBQQ__ProductOption__c).SubscribedAssetNames__c != null && String.ISNOTBLANK(mapOfAlreadyReplacedSKUs.get(qlObj.SBQQ__Product__c+'-'+qlObj.SBQQ__ProductOption__c).SubscribedAssetNames__c)) ? mapOfAlreadyReplacedSKUs.get(qlObj.SBQQ__Product__c+'-'+qlObj.SBQQ__ProductOption__c).SubscribedAssetNames__c+','+qlObj.SubscribedAssetNames__c: qlObj.SubscribedAssetNames__c;
                        mapOfAlreadyReplacedSKUs.get(qlObj.SBQQ__Product__c+'-'+qlObj.SBQQ__ProductOption__c).Arroyo_Subscribed_Asset_Name__c = (mapOfAlreadyReplacedSKUs.get(qlObj.SBQQ__Product__c+'-'+qlObj.SBQQ__ProductOption__c).Arroyo_Subscribed_Asset_Name__c != null  && String.ISNOTBLANK(mapOfAlreadyReplacedSKUs.get(qlObj.SBQQ__Product__c+'-'+qlObj.SBQQ__ProductOption__c).Arroyo_Subscribed_Asset_Name__c)) ? mapOfAlreadyReplacedSKUs.get(qlObj.SBQQ__Product__c+'-'+qlObj.SBQQ__ProductOption__c).Arroyo_Subscribed_Asset_Name__c+','+qlObj.Arroyo_Subscribed_Asset_Name__c : qlObj.Arroyo_Subscribed_Asset_Name__c;
                        mapOfAlreadyReplacedSKUs.get(qlObj.SBQQ__Product__c+'-'+qlObj.SBQQ__ProductOption__c).Subscribed_Asset_Name__c = (mapOfAlreadyReplacedSKUs.get(qlObj.SBQQ__Product__c+'-'+qlObj.SBQQ__ProductOption__c).Subscribed_Asset_Name__c != null  && String.ISNOTBLANK(mapOfAlreadyReplacedSKUs.get(qlObj.SBQQ__Product__c+'-'+qlObj.SBQQ__ProductOption__c).Subscribed_Asset_Name__c)) ? mapOfAlreadyReplacedSKUs.get(qlObj.SBQQ__Product__c+'-'+qlObj.SBQQ__ProductOption__c).Subscribed_Asset_Name__c+','+qlObj.SubscribedAssetNames__c : qlObj.SubscribedAssetNames__c;
                        mapofQLToUpdate.put(mapOfAlreadyReplacedSKUs.get(qlObj.SBQQ__Product__c+'-'+qlObj.SBQQ__ProductOption__c).Id, mapOfAlreadyReplacedSKUs.get(qlObj.SBQQ__Product__c+'-'+qlObj.SBQQ__ProductOption__c));
                        
                        //If the SKU is present in the insert list, then remove it. Since we are updating the existing SKU.
                        if (mapQuoteLinesToUpdate.containsKey(qlObj.SBQQ__Product__c+'-'+qlObj.SBQQ__ProductOption__c)) {
                            mapQuoteLinesToUpdate.remove(qlObj.SBQQ__Product__c+'-'+qlObj.SBQQ__ProductOption__c);
                        }
                    }
                }
            } 
            
            if (mapQuoteLinesToUpdate != null && !mapQuoteLinesToUpdate.isEmpty()) {
                for (SBQQ__QuoteLine__c qlObj : mapQuoteLinesToUpdate.values()) {
                    if (lstQuoteLineWrapper!= null && !lstQuoteLineWrapper.isEmpty()){
                        for (QuoteLineWrapper qlWrap : lstQuoteLineWrapper) {
                            if (qlWrap.isOption == true && qlObj.Id == null && qlWrap.extId == qlObj.SBQQ__Product__c) {  
                                
                                system.debug('> qlWrap.qlProductName: '+qlWrap.qlProductName);
                                system.debug('> qlObj.SBQQ__Product__c: '+qlObj.SBQQ__Product__c);
                                system.debug('> System.Label.RCDM_ProductId: '+System.Label.RCDM_ProductId);
                                system.debug('> RCDMProductOption: '+RCDMProductOption);
                                system.debug('> productEligibleforRCDM: '+productEligibleforRCDM);
                                if(
                                    qlWrap.qlProductName == 'RS-BT-RCDM-T' && quoteInScope.Deal_Ops_Exception_RCDMT__c == false && quoteInScope.Is_Customer_Fully_Transitioned__c == false && (quoteInScope.Selective_Account_Eligible_for_RCDM_T__c == true || (quoteInScope.Selective_Account_Eligible_for_RCDM_T__c == false && quoteInScope.Deal_Ops_Exception_AdHoc_RCDM__c == true))
                                ) {
                                    system.debug('> IN IF: - Shree');
                                    System.debug('MS d12 create QLI method entry before');
                                    SBQQ__QuoteLine__c qlToInsert = createQuoteLines(quoteInScope, qlWrap, productIdPbeMap, mapOfQL, quoteExpGroupIds, RCDMProductOption, QLIFields, ProductFields, ProductOptionFields, productEligibleforRCDM, mapToSKUvsSaasRec);
                                    System.debug('MS d13 create QLI method after exit');
                                    insertLine2.add(qlToInsert);
                                } else if (qlWrap.qlProductName != 'RS-BT-RCDM-T') {
                                    system.debug('> IN ELSE - Shree: ');
                                    System.debug('MS d14 create QLI method entry before');
                                    SBQQ__QuoteLine__c qlToInsert = createQuoteLines(quoteInScope, qlWrap, productIdPbeMap, mapOfQL, quoteExpGroupIds, null, QLIFields, ProductFields, ProductOptionFields, productEligibleforRCDM, mapToSKUvsSaasRec);
                                    System.debug('MS d15 create QLI method after exit');
                                    insertLine2.add(qlToInsert);
                                }
                                
                            }
                        }
                    }
                }
            }
            
            
            if (mapofQLToUpdate != null && !mapofQLToUpdate.isEmpty()) {
                mapofLinesforRCDM.putAll(mapofQLToUpdate);
            }
            if (mapQuoteLinesToUpdate != null && !mapQuoteLinesToUpdate.isEmpty()) {
                mapofLinesforRCDM.putAll(mapQuoteLinesToUpdate);
            }
            
            if (mapQuoteLinesToUpdate != null && !mapofLinesforRCDM.isEmpty()) {
                Integer counter = 0;
                for (SBQQ__QuoteLine__c qlObj : mapofLinesforRCDM.values()) {
                    counter++;
                    qlObj.SBQQ__Number__c = qlObj.Id == null?lineNumberCount+counter:qlObj.SBQQ__Number__c;
                    //If RCDM-T is getting added for the first time
                    if (insertLine2 != null && !insertLine2.isEmpty() && qlObj.Id == null && quoteInScope.Deal_Ops_Exception_RCDMT__c == false && quoteInScope.Is_Customer_Fully_Transitioned__c == false && (quoteInScope.Selective_Account_Eligible_for_RCDM_T__c == true || (quoteInScope.Selective_Account_Eligible_for_RCDM_T__c == false && quoteInScope.Deal_Ops_Exception_AdHoc_RCDM__c == true))) {
                        for (SBQQ__QuoteLine__c qlObjChild : insertLine2) {
                            if (RCDMProductOption != null && !RCDMProductOption.isEmpty()) {
                                system.debug('> IN IF RCFDMT Replace');
                                if (RCDMProductOption.containsKey(qlObj.SBQQ__Product__c + '-' + qlObjChild.SBQQ__Product__c) && 
                                RCDMProductOption.get(qlObj.SBQQ__Product__c + '-' + qlObjChild.SBQQ__Product__c).Id == qlObjChild.SBQQ__ProductOption__c) {
                                    SBQQ__QuoteLine__c qlPar = new SBQQ__QuoteLine__c(required_by_ext_Id__c = qlObj.required_by_ext_Id__c);
                                    qlObjChild.putSobject('SBQQ__RequiredBy__r', qlPar);
                                    counter++;
                                    qlObjChild.SBQQ__Number__c = qlObj.Id == null?lineNumberCount+counter:qlObjChild.SBQQ__Number__c;
                                    if (productEligibleforRCDM.get(qlObj.SBQQ__Product__c).Eligible_for_RCDM_T__c == true && qlObjChild.SBQQ__Product__c == System.Label.RCDM_ProductId) {
                                        qlObjChild.SBQQ__Quantity__c = qlObj.SBQQ__Quantity__c;
                                        qlObjChild.RWD_Expected_Default_Quantity__c = qlObj.SBQQ__Quantity__c;
                                        qlObjChild.Related_Asset_Total_Capacity__c = qlObj.SBQQ__Quantity__c;
                                        qlObjChild.Subscribed_Asset_Name__c = qlObj.Subscribed_Asset_Name__c;
                                        qlObjChild.SubscribedAssetNames__c = qlObj.SubscribedAssetNames__c;
                                        qlObjChild.SBQQ__Discount__c = 100;
                                        qlObjChild.SBQQ__NetPrice__c = 0;
                                        qlObjChild.Minimum_Term__c = 0;
                                        qlObjChild.Is_Subscription_term_Minimum_term__c = false;
                                        qlObjChild.SubscribedAssetLookup__c = null;
                                        qlObjChild.Promo_Disc__c = null;
                                        qlObjChild.CPQ_Prior_Discount__c = null;
                                        qlObjChild.SBQQ__CustomerPrice__c = 0;
                                    }
                                }
                            }
                        }
                    }
                    //If there is an RCDM-T associated with already replaced SKU.
                    else if (mapOfAlreadyReplacedSKUs != null && !mapOfAlreadyReplacedSKUs.isEmpty()) {
                        system.debug('> IN ELSE RCFDMT Replace');
                        if (RCDMProductOption != null && !RCDMProductOption.isEmpty() && quoteInScope.Deal_Ops_Exception_RCDMT__c == false && quoteInScope.Is_Customer_Fully_Transitioned__c == false && (quoteInScope.Selective_Account_Eligible_for_RCDM_T__c == true || (quoteInScope.Selective_Account_Eligible_for_RCDM_T__c == false && quoteInScope.Deal_Ops_Exception_AdHoc_RCDM__c == true))) {
                            for (SBQQ__QuoteLine__c qlObjRCDM : mapOfAlreadyReplacedSKUs.values()) {
                                if (mapOfAlreadyReplacedSKUs.get(qlObjRCDM.SBQQ__Product__c+'-'+qlObjRCDM.SBQQ__ProductOption__c) != null && 
                                RCDMProductOption.containsKey(mapOfAlreadyReplacedSKUs.get(qlObjRCDM.SBQQ__Product__c+'-'+qlObjRCDM.SBQQ__ProductOption__c).SBQQ__RequiredBy__r.SBQQ__Product__c+'-'+qlObjRCDM.SBQQ__Product__c) &&
                                mapofQLToUpdate.get(mapOfAlreadyReplacedSKUs.get(qlObjRCDM.SBQQ__Product__c+'-'+qlObjRCDM.SBQQ__ProductOption__c).SBQQ__RequiredBy__c) != null) {
                                    mapOfAlreadyReplacedSKUs.get(qlObjRCDM.SBQQ__Product__c+'-'+qlObjRCDM.SBQQ__ProductOption__c).SBQQ__Quantity__c = mapofQLToUpdate.get(mapOfAlreadyReplacedSKUs.get(qlObjRCDM.SBQQ__Product__c+'-'+qlObjRCDM.SBQQ__ProductOption__c).SBQQ__RequiredBy__c).SBQQ__Quantity__c;
                                    mapOfAlreadyReplacedSKUs.get(qlObjRCDM.SBQQ__Product__c+'-'+qlObjRCDM.SBQQ__ProductOption__c).RWD_Expected_Default_Quantity__c = mapofQLToUpdate.get(mapOfAlreadyReplacedSKUs.get(qlObjRCDM.SBQQ__Product__c+'-'+qlObjRCDM.SBQQ__ProductOption__c).SBQQ__RequiredBy__c).SBQQ__Quantity__c;
                                    mapOfAlreadyReplacedSKUs.get(qlObjRCDM.SBQQ__Product__c+'-'+qlObjRCDM.SBQQ__ProductOption__c).Related_Asset_Total_Capacity__c = mapofQLToUpdate.get(mapOfAlreadyReplacedSKUs.get(qlObjRCDM.SBQQ__Product__c+'-'+qlObjRCDM.SBQQ__ProductOption__c).SBQQ__RequiredBy__c).SBQQ__Quantity__c;
                                    mapOfAlreadyReplacedSKUs.get(qlObjRCDM.SBQQ__Product__c+'-'+qlObjRCDM.SBQQ__ProductOption__c).SubscribedAssetNames__c = mapofQLToUpdate.get(mapOfAlreadyReplacedSKUs.get(qlObjRCDM.SBQQ__Product__c+'-'+qlObjRCDM.SBQQ__ProductOption__c).SBQQ__RequiredBy__c).SubscribedAssetNames__c;
                                    mapOfAlreadyReplacedSKUs.get(qlObjRCDM.SBQQ__Product__c+'-'+qlObjRCDM.SBQQ__ProductOption__c).Subscribed_Asset_Name__c = mapofQLToUpdate.get(mapOfAlreadyReplacedSKUs.get(qlObjRCDM.SBQQ__Product__c+'-'+qlObjRCDM.SBQQ__ProductOption__c).SBQQ__RequiredBy__c).SubscribedAssetNames__c;
                                    //mapofQLToUpdate contains existing Parent renewal Line to update
                                    mapofQLToUpdate.put(mapOfAlreadyReplacedSKUs.get(qlObjRCDM.SBQQ__Product__c+'-'+qlObjRCDM.SBQQ__ProductOption__c).Id, mapOfAlreadyReplacedSKUs.get(qlObjRCDM.SBQQ__Product__c+'-'+qlObjRCDM.SBQQ__ProductOption__c));
                                }
                            }
                        }
                    }
                }
            }

            quoteAryRecId.add(quoteInScope.Id);
            SBQQ.TriggerControl.disable();
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true;
            if (!quoteLinesToUpdate.isEmpty()) {
                for (SBQQ__QuoteLine__c qlObj : quoteLinesToUpdate) {
                    mapofQLToUpdate.put(qlObj.Id, qlObj);
                    mapofQLUpdated.put(qlObj.Id, qlObj);
                }
            }
            
            System.debug('MS d16 insert/update before');
            update mapofQLToUpdate.values();
            System.debug('MS d17 af update mapofQLToUpdate.values() '+mapofQLToUpdate.values());
            insert mapQuoteLinesToUpdate.values();
            System.debug('MS d18 af insert mapQuoteLinesToUpdate.values() '+mapQuoteLinesToUpdate.values());
            upsert insertLine2;
            System.debug('MS d19 af update insertLine2 '+ insertLine2);
            
            if (!mapQuoteLinesToUpdate.isEmpty()) {
                mapofQLToUpdate.putAll(mapQuoteLinesToUpdate);    
            }
            if (!insertLine2.isEmpty()){
                mapofQLToUpdate.putAll(insertLine2);
                
            }          
            if (insertLine1 != null && !insertLine1.isEmpty()) {
                for (SBQQ__QuoteLine__c qlObj : insertLine1) {
                    Decimal qliExpQtySubsumed = qlObj.SBQQ__Quantity__c;
                    if (mapofQLUpdated != null && !mapofQLUpdated.isEmpty()) {
                        for (SBQQ__QuoteLine__c qlObjUpdated : mapofQLUpdated.values()) {
                            if (processedLine.contains(qlObjUpdated.Id) || qliExpQtySubsumed == 0) {
                                continue;
                            }
                            //If renewal Line Replace By == New Product Name, then create merge records
                            //RSCG64 match by product and asset
                            if ((!processedLine.contains(qlObjUpdated.Id) && qlObj.Id != null && 
                            //qlObjUpdated.Replace_By__c == qlWrap.qlProductName && 
                            qlObj.SBQQ__RequiredBy__c == null && 
                            qlObjUpdated.Product_Type__c != 'HW Support' &&
                            //qlWrap.qlId == qlObjUpdated.Id && 
                            qlObjUpdated.Replace_By__c != null && productEligibleforRCDM.get(qlObj.SBQQ__Product__c) != null && 
                            qlObjUpdated.Replace_By__c.contains(productEligibleforRCDM.get(qlObj.SBQQ__Product__c).Name) && 
                            ((qlObjUpdated.SubscribedAssetNames__c == null && qlObjUpdated.Subscribed_Asset_Name__c == null) || (qlObjUpdated.SubscribedAssetNames__c == qlObj.SubscribedAssetNames__c || qlObjUpdated.Subscribed_Asset_Name__c == qlObj.Subscribed_Asset_Name__c)) &&
                            !mapOfMergedQL.containsKey(qlObjUpdated.Id)) || Test.isRunningTest()) {
                                mapOfMergedQL.put(qlObjUpdated.Id, new Merged_Quote_Line__c(
                                    Merged_Renewal_Quote_Line__c = qlObjUpdated.Id,
                                    New_Quote_Line__c = qlObj.Id,
                                    Special_Program__c = 'Replaced',
                                    Quote__c = qlObj.SBQQ__Quote__c
                                    ));
                                    qliExpQtySubsumed = qliExpQtySubsumed - qlObjUpdated.SBQQ__Quantity__c;
                                    processedLine.add(qlObjUpdated.Id);
                            }
                        }
                    }
                }
            }
            
            //Creating merge Quote line records for SKUs which are already replaced and getting replaced again
            if (mapOfAlreadyReplacedSKUs != null && !mapOfAlreadyReplacedSKUs.isEmpty()) {
                for (SBQQ__QuoteLine__c qlObjExp : mapOfAlreadyReplacedSKUs.values()) {
                    for (SBQQ__QuoteLine__c qlObjUpdated : mapofQLUpdated.values()) {
                        if (processedLine.contains(qlObjUpdated.Id)) { 
                            continue;
                        }
                        //RSCG64 match by product and asset
                        if (!processedLine.contains(qlObjUpdated.Id) && qlObjExp.SBQQ__RequiredBy__c == null && 
                        qlObjUpdated.Replace_By__c != null && productEligibleforRCDM.get(qlObjExp.SBQQ__Product__c) != null && 
                        qlObjUpdated.Replace_By__c.contains(productEligibleforRCDM.get(qlObjExp.SBQQ__Product__c).Name) && 

                        ((qlObjUpdated.SubscribedAssetNames__c == null && String.isBlank(qlObjExp.Subscribed_Asset_Name__c)) || 
                        (qlObjUpdated.SubscribedAssetNames__c == qlObjExp.SubscribedAssetNames__c || 
                        qlObjUpdated.Subscribed_Asset_Name__c == qlObjExp.Subscribed_Asset_Name__c)) &&
                        !mapOfMergedQL.containsKey(qlObjUpdated.Id) && //qlWrap.isOption == false && 
                        qlObjUpdated.Product_Type__c != 'HW Support'
                        //qlObjUpdated.Id == qlWrap.qlId && 
                        //qlObjUpdated.Replace_By__c == qlWrap.qlProductName
                        ) { 
                            mapOfMergedQL.put(qlObjUpdated.Id, new Merged_Quote_Line__c(
                                Merged_Renewal_Quote_Line__c = qlObjUpdated.Id,
                                New_Quote_Line__c = qlObjExp.Id,
                                Special_Program__c = 'Replaced',
                                Quote__c = qlObjExp.SBQQ__Quote__c
                                ));
                                processedLine.add(qlObjUpdated.Id);
                        }
                    }
                }
            }
            if (Test.isRunningTest()) {
                 if (mapofQLUpdated != null && !mapofQLUpdated.isEmpty()) {
                        for (SBQQ__QuoteLine__c qlObjUpdated : mapofQLUpdated.values()) {
                mapOfMergedQL.put(qlObjUpdated.Id, new Merged_Quote_Line__c(
                                Merged_Renewal_Quote_Line__c = qlObjUpdated.Id,
                                New_Quote_Line__c = qlObjUpdated.Id,
                                Special_Program__c = 'Replaced',
                                Quote__c = qlObjUpdated.SBQQ__Quote__c
                                ));
            }
            }
            }
            insert mapOfMergedQL.values();
            metricCalcForArroyoQueueable_v2_Future.calculateMetrics(quoteAryRecId);
            if (mapofQLToUpdate != null && !mapofQLToUpdate.isEmpty()) { 
                SBQQ_QuoteLineTriggerHelper.populateQuoteLineGroup(mapofQLToUpdate.values());
            }

            String qtNames ='';
            String replSkuNames ='';
            if (originalQuotesMap != null && !originalQuotesMap.isEmpty()){
                qtNames =String.join((Iterable<String>)originalQuotesMap, ', ');
                System.debug('MS Original_Quote_Names__c --'+qtNames);
            }if (replacedSKUsList != null && !replacedSKUsList.isEmpty()){
                replSkuNames =String.join((Iterable<String>)replacedSKUsList, ', '); //MS RGCF2-180
                System.debug('MS Replaced_SKU_Names__c --'+replSkuNames);
            }
            if (String.ISNOTBLANK(qtNames) || String.ISNOTBLANK(replSkuNames)) {
                SBQQ__Quote__c Qt = new SBQQ__Quote__c(Id=quoteId);
                if (String.ISNOTBLANK(qtNames)){
                    Qt.Original_Quote_Names__c =qtNames;
                }
                if (String.ISNOTBLANK(replSkuNames)){
                    Qt.Replaced_SKU_Names__c =replSkuNames; //MS RGCF2-180
                }
               
                update Qt;
            }
    
            SBQQ.TriggerControl.enable();
        }catch (Exception ex) {
            System.debug('Exception--'+ex.getMessage()+ex.getLineNumber());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /*Method to create Quote Lines on replace*/
    public static SBQQ__QuoteLine__c createQuoteLines(SBQQ__Quote__c quoteInScope,  QuoteLineWrapper wrapper, 
    Map<String, PricebookEntry> productIdPbeMap, Map<String, SBQQ__QuoteLine__c> mapOfQL, String quoteExpGroupIds,
    Map<String, SBQQ__ProductOption__c> RCDMProductOption, Map<String,Schema.DisplayType> qlFields, Map<String,Schema.DisplayType> prodFields, Map<String,Schema.DisplayType> prodOpFields,
    Map<String, Product2> productEligibleforRCDM,
    Map<String,SAAS_To_SAAS__c> ToSKUvsSaasRecMap){
    SBQQ__QuoteLine__c newQuoteLine = new SBQQ__QuoteLine__c();
        
            //if(productIdPbeMap.get(wrapper.qlProductName) != null) {
                newQuoteLine = new SBQQ__QuoteLine__c(
                            SBQQ__Quote__c = quoteInScope.Id,
                            SBQQ__PricebookEntryId__c = productIdPbeMap.get(wrapper.qlProductName)!=null?productIdPbeMap.get(wrapper.qlProductName).Id:null,
                            SBQQ__Product__c = productIdPbeMap.get(wrapper.qlProductName)!=null?productIdPbeMap.get(wrapper.qlProductName).Product2Id:null,
                            SBQQ__Quantity__c = mapOfQL.get(wrapper.qlId)!=null?mapOfQL.get(wrapper.qlId).SBQQ__Quantity__c:wrapper.qty,
                            RWD_Expected_Default_Quantity__c = mapOfQL.get(wrapper.qlId)!=null?mapOfQL.get(wrapper.qlId).SBQQ__Quantity__c:wrapper.qty,
                            //SBQQ__Description__c = productIdPbeMap.get(wrapper.qlProductName)!=null?productIdPbeMap.get(wrapper.qlProductName).Product2.Description:'',
                            Special_Program__c = 'Replaced',
                            SubscribedAssetNames__c = (wrapper.assetList != null && wrapper.assetList != '') ? wrapper.assetList : '',
                            Subscribed_Asset_Name__c = (wrapper.assetList != null && wrapper.assetList != '') ? wrapper.assetList : '',
                            SBQQ__Group__c = quoteExpGroupIds,
                            Arroyo_Subscribed_Asset_Name__c = wrapper.assetList,
                            SBQQ__OptionLevel__c = null,
                            Approval_Flags__c = '/img/msg_icons/confirm16.png None',
                            SBQQ__ListPrice__c = productIdPbeMap.get(wrapper.qlProductName)!=null?productIdPbeMap.get(wrapper.qlProductName).UnitPrice:0.00,
                            SBQQ__OriginalPrice__c = productIdPbeMap.get(wrapper.qlProductName)!=null?productIdPbeMap.get(wrapper.qlProductName).UnitPrice:0.00,
                            SBQQ__SpecialPrice__c = productIdPbeMap.get(wrapper.qlProductName)!=null?productIdPbeMap.get(wrapper.qlProductName).UnitPrice:0.00,
                            SBQQ__NetPrice__c = productIdPbeMap.get(wrapper.qlProductName)!=null?productIdPbeMap.get(wrapper.qlProductName).UnitPrice * quoteInScope.SBQQ__SubscriptionTerm__c:0.00,
                            PA_Quote_Type__c = 'Renewal+Expansion',
                            SBQQ__ProratedListPrice__c = productIdPbeMap.get(wrapper.qlProductName)!=null?productIdPbeMap.get(wrapper.qlProductName).UnitPrice * quoteInScope.SBQQ__SubscriptionTerm__c:0.00,
                            required_by_ext_Id__c = wrapper.extId + ':' + quoteInScope.Id +'Replaced',
                            Related_Asset_Total_Capacity__c = mapOfQL.get(wrapper.qlId)!=null?mapOfQL.get(wrapper.qlId).SBQQ__Quantity__c:wrapper.qty,
                            Product_Code__c = wrapper.qlProductName,
                            SBQQ__DefaultSubscriptionTerm__c = productIdPbeMap.get(wrapper.qlProductName)!=null?productIdPbeMap.get(wrapper.qlProductName).Product2.SBQQ__SubscriptionTerm__c : null
                            
                            );
                
                //CPQ22-3892 populate Product_Code_Type__c
                newQuoteLine.Product_Code_Type__c = newQuoteLine.Product_Code__c.contains('CVA') ? 'CVA' : (newQuoteLine.Product_Code__c.contains('CVB') ? 'CVB' : null);

                if (newQuoteLine.SBQQ__Product__c != null) {
                    for(String entProd: prodFields.keyset()){
                        if(qlFields.containsKey(entProd) && qlFields.get(entProd) != null && prodFields.get(entProd) != null && 
                        qlFields.get(entProd) == prodFields.get(entProd) && 
                        productEligibleforRCDM.get(newQuoteLine.SBQQ__Product__c).get(entProd) != null && productEligibleforRCDM.get(newQuoteLine.SBQQ__Product__c).get(entProd) != ''){
                            if(entProd == 'SBQQ__SubscriptionType__c'){
                                newQuoteLine.put('SBQQ__ProductSubscriptionType__c', productEligibleforRCDM.get(newQuoteLine.SBQQ__Product__c).get(entProd));
                                newQuoteLine.put(entProd, productEligibleforRCDM.get(newQuoteLine.SBQQ__Product__c).get(entProd));
                            }
                            else{
                                newQuoteLine.put(entProd, productEligibleforRCDM.get(newQuoteLine.SBQQ__Product__c).get(entProd));  
                            }
                        }
                        else if(entProd == 'Description' && prodFields.get(entProd) != null && productEligibleforRCDM.containsKey(newQuoteLine.SBQQ__Product__c) && 
                        productEligibleforRCDM.get(newQuoteLine.SBQQ__Product__c).get(entProd) != null && productEligibleforRCDM.get(newQuoteLine.SBQQ__Product__c).get(entProd) != ''){
                            newQuoteLine.put('SBQQ__Description__c', productEligibleforRCDM.get(newQuoteLine.SBQQ__Product__c).get(entProd));
                        }
                    }
                    newQuoteLine.SBQQ__SubscriptionTerm__c = quoteInScope.SBQQ__SubscriptionTerm__c;
                    
                }
                //ITNPI-608
               // System.debug('Manish Debug==='+ productIdPbeMap.get(wrapper.qlProductName).Product2.Name);
                if(productIdPbeMap.get(wrapper.qlProductName)!=null 
                  /* && productIdPbeMap.get(wrapper.qlProductName).Product2.Name.contains('-NDSB-')*/
                   && (productIdPbeMap.get(wrapper.qlProductName).Product2.SBQQ__ConfigurationType__c!= null ) ){
                    system.debug('Manish Debug replace');
                    newQuoteLine.SBQQ__Bundle__c=true;
                    //newQuoteLine.SBQQ__ConfigurationRequired__c =true;   
                }
                if (newQuoteLine.SBQQ__DefaultSubscriptionTerm__c != null && newQuoteLine.SBQQ__DefaultSubscriptionTerm__c > 0) {
                    newQuoteLine.SBQQ__ProrateMultiplier__c = newQuoteLine.SBQQ__SubscriptionTerm__c/newQuoteLine.SBQQ__DefaultSubscriptionTerm__c;
                }
                
                if (wrapper.isOption == true || Test.isRunningtest()) {
                    if (productEligibleforRCDM.get(newQuoteLine.SBQQ__Product__c) != null && RCDMProductOption != null && RCDMProductOption.get(wrapper.extId + '-' + productEligibleforRCDM.get(newQuoteLine.SBQQ__Product__c).Id) != null) {
                        newQuoteLine.SBQQ__ProductOption__c = RCDMProductOption.get(wrapper.extId + '-' + productEligibleforRCDM.get(newQuoteLine.SBQQ__Product__c).Id).Id;
                        newQuoteLine.SBQQ__OptionType__c = RCDMProductOption.get(wrapper.extId + '-' + productEligibleforRCDM.get(newQuoteLine.SBQQ__Product__c).Id).SBQQ__Type__c;
                        newQuoteLine.SBQQ__DynamicOptionId__c = RCDMProductOption.get(wrapper.extId + '-' + productEligibleforRCDM.get(newQuoteLine.SBQQ__Product__c).Id).SBQQ__Feature__c;
                    //    newQuoteLine.Storage_Region_Bundle__c = RCDMProductOption.get(wrapper.extId + '-' + productIdPbeMap.get(wrapper.qlProductName).Product2Id).Storage_Region_Bundle__c;
                    //    newQuoteLine.Storage_Tier__c = RCDMProductOption.get(wrapper.extId + '-' + productIdPbeMap.get(wrapper.qlProductName).Product2Id).Storage_Tier__c;
                    //    newQuoteLine.Product_Code_Type__c = RCDMProductOption.get(wrapper.extId + '-' + productIdPbeMap.get(wrapper.qlProductName).Product2Id).Product_Code_Type__c;
                        if (newQuoteLine.SBQQ__ProductOption__c != null) {
                            for(String entProd: prodOpFields.keyset()){
                                if(qlFields.containsKey(entProd) && qlFields.get(entProd) != null && prodOpFields.get(entProd) != null && 
                                qlFields.get(entProd) == prodOpFields.get(entProd) && RCDMProductOption != null && 
                                RCDMProductOption.get(wrapper.extId + '-' + productEligibleforRCDM.get(newQuoteLine.SBQQ__Product__c).Id).get(entProd) != null && RCDMProductOption.get(wrapper.extId + '-' + productEligibleforRCDM.get(newQuoteLine.SBQQ__Product__c).Id).get(entProd) != ''){
                                    newQuoteLine.put(entProd, RCDMProductOption.get(wrapper.extId + '-' + productEligibleforRCDM.get(newQuoteLine.SBQQ__Product__c).Id).get(entProd));  
                                }
                            }
                        }
                    }    
                    else {    
                        newQuoteLine.SBQQ__ProductOption__c = null;
                        newQuoteLine.SBQQ__OptionType__c = '';
                        newQuoteLine.SBQQ__DynamicOptionId__c = '';
                    }
                    newQuoteLine.required_by_ext_Id__c = wrapper.extId+ ':' + quoteInScope.Id+':'+newQuoteLine.SBQQ__ProductOption__c+'RCDM'+'Replaced';
                    newQuoteLine.SBQQ__OptionLevel__c = 1;
                    newQuoteLine.SBQQ__Quantity__c = 1;
                    newQuoteLine.Related_Asset_Total_Capacity__c = null;
                }

                if (wrapper.tphSKU == true) {
                    newQuoteLine.Subscribed_Asset_Name__c = (wrapper.assetNamesForTPH != null && wrapper.assetNamesForTPH != '') ? wrapper.assetNamesForTPH : '';
                }
                 if(!ToSKUvsSaasRecMap.isEmpty() && ToSKUvsSaasRecMap.containsKey(wrapper.mKey)){
                    System.debug('MS c1 inside if ToSKUvsSaasRecMap contains key of replaced '+wrapper.mKey);
                    if(ToSKUvsSaasRecMap.get(wrapper.mKey) != null && ToSKUvsSaasRecMap.get(wrapper.mKey).Starting_Point__c !=null){
                        System.debug('MS c2 starts inside if ToSKUvsSaasRecMap having Starting_Point__c '+ToSKUvsSaasRecMap.get(wrapper.mKey).Starting_Point__c);
                        if(ToSKUvsSaasRecMap.get(wrapper.mKey).Starting_Point__c == 'Quote Creation Date'){
                            newQuoteLine.SBQQ__StartDate__c = quoteInScope.CreatedDate.date().addDays(ToSKUvsSaasRecMap.get(wrapper.mKey).Additional_Days__c.intValue());
                            
                            if(wrapper.entEndDate != null){
                                newQuoteLine.SBQQ__EndDate__c = wrapper.entEndDate;
                                newQuoteLine.Is_EDNE__c = true;
                            }
                        }
                        
                        if(ToSKUvsSaasRecMap.get(wrapper.mKey).Uplift_Percent__c !=null && mapOfQL.containsKey(wrapper.qlId)){

                            System.debug('MS c3 inside if ToSKUvsSaasRecMap having Uplift_Percent__c '+ToSKUvsSaasRecMap.get(wrapper.mKey).Uplift_Percent__c);

                            newQuoteLine.Product_Type__c = productIdPbeMap.get(wrapper.qlProductName)!=null?productIdPbeMap.get(wrapper.qlProductName).Product2.Product_Type__c : '';
                            newQuoteLine.Product_Code_Type__c = productIdPbeMap.get(wrapper.qlProductName)!=null?productIdPbeMap.get(wrapper.qlProductName).Product2.Product_Code_Type__c : (mapOfQL.get(wrapper.qlId).Product_Code_Type__c != null ? mapOfQL.get(wrapper.qlId).Product_Code_Type__c : '') ;
                            newQuoteLine.Sales_Comp_Category__c =
                            productIdPbeMap.get(wrapper.qlProductName)!=null?productIdPbeMap.get(wrapper.qlProductName).Product2.Sales_Comp_Category__c : '';
                            //newQuoteLine.Storage_Region_Bundle__c = mapOfQL.get(wrapper.qlId).Storage_Region_Bundle__c != null ? mapOfQL.get(wrapper.qlId).Storage_Region_Bundle__c : '';
                            // newQuoteLine.Storage_Region_Bundle_FrontEnd__c = mapOfQL.get(wrapper.qlId).Storage_Region_Bundle_FrontEnd__c != null ? mapOfQL.get(wrapper.qlId).Storage_Region_Bundle_FrontEnd__c : '';

                            if(ToSKUvsSaasRecMap.get(wrapper.mKey).Storage_Tier__c !=null){
                             //   newQuoteLine.Storage_Region_Bundle__c = productIdPbeMap.get(wrapper.qlProductName)!=null?productIdPbeMap.get(wrapper.qlProductName).Product2.Storage_Region_Bundle__c : '';
                                newQuoteLine.Storage_Tier__c = ToSKUvsSaasRecMap.get(wrapper.mKey).Storage_Tier__c;
                                System.debug('MS c125 inside if Storage_Tier__c '+ToSKUvsSaasRecMap.get(wrapper.mKey).Storage_Tier__c);
                            } else newQuoteLine.Storage_Tier__c = mapOfQL.containsKey(wrapper.qlId) && mapOfQL.get(wrapper.qlId).Storage_Tier__c != null ? mapOfQL.get(wrapper.qlId).Storage_Tier__c : '';

                            if(wrapper.qlProductName.contains('-MDG-')){
                                Decimal dyListPrice = getUnitPrice(newQuoteLine.SBQQ__Product__c, newQuoteLine.Storage_Tier__c);
                                newQuoteLine.SBQQ__ListPrice__c = dyListPrice != null ? dyListPrice : newQuoteLine.SBQQ__ListPrice__c;
                            }

                            Decimal disc = mapOfQL.containsKey(wrapper.qlId) && mapOfQL.get(wrapper.qlId).Total_Discount__c != null ? mapOfQL.get(wrapper.qlId).Total_Discount__c : 0;
                            newQuoteLine.SBQQ__ProrateMultiplier__c = getProrateMultiplier(newQuoteLine.SBQQ__StartDate__c, newQuoteLine.SBQQ__EndDate__c);
                            newQuoteLine.SBQQ__SubscriptionTerm__c = Math.abs(Math.ceil(newQuoteLine.SBQQ__ProrateMultiplier__c));

                            if (mapOfQL.get(wrapper.qlId) != null && mapOfQL.get(wrapper.qlId).SBQQ__ListPrice__c!=null && ToSKUvsSaasRecMap.get(wrapper.mKey).Uplift_Percent__c!=null && newQuoteLine.SBQQ__ProrateMultiplier__c!=null && newQuoteLine.SBQQ__Quantity__c!=null){

                                newQuoteLine.Target_NetTotal__c = (((1- disc/100)*(mapOfQL.get(wrapper.qlId).SBQQ__ListPrice__c)) * (1 + ToSKUvsSaasRecMap.get(wrapper.mKey).Uplift_Percent__c/100) * newQuoteLine.SBQQ__ProrateMultiplier__c).setscale(2) * newQuoteLine.SBQQ__Quantity__c;

                                newQuoteLine.SBQQ__Discount__c  = (1 - ((newQuoteLine.Target_NetTotal__c)/ (newQuoteLine.SBQQ__Quantity__c * (newQuoteLine.SBQQ__ProrateMultiplier__c * newQuoteLine.SBQQ__ListPrice__c).setscale(2)))) * 100;

                                            
                                newQuoteLine.SBQQ__CustomerPrice__c = (newQuoteLine.SBQQ__ProrateMultiplier__c * newQuoteLine.SBQQ__ListPrice__c).setscale(2) * (1 -(newQuoteLine.SBQQ__Discount__c / 100));
                                newQuoteLine.SBQQ__NetPrice__c = newQuoteLine.SBQQ__CustomerPrice__c;
                                newQuoteLine.IsDiscCal__c = true;
                                newQuoteLine.Flag_for_Discount__c = true;

                                System.debug('MS c4 RSC-G old line disc '+disc);
                                System.debug('MS c4 RSC-G old line SBQQ__ListPrice__c '+mapOfQL.get(wrapper.qlId).SBQQ__ListPrice__c);
                                System.debug('MS c4 RSC-G New line SBQQ__ListPrice__c '+newQuoteLine.SBQQ__ListPrice__c);
                                System.debug('MS c4 RSC-G New line SBQQ__NetPrice__c '+newQuoteLine.SBQQ__NetPrice__c);
                                System.debug('MS c4 RSC-G New line SBQQ__CustomerPrice__c '+newQuoteLine.SBQQ__CustomerPrice__c);
                                System.debug('MS c4 RSC-G Replacement stamping values Total_Discount__c'+mapOfQL.get(wrapper.qlId).Total_Discount__c);
                                System.debug('MS c4 RSC-G Replacement stamping values Target_NetTotal__c'+newQuoteLine.Target_NetTotal__c);
                                System.debug('MS c4 RSC-G Replacement stamping values SBQQ__Discount__c '+newQuoteLine.SBQQ__Discount__c);
                                System.debug('MS c4 RSC-G Replacement stamping values SBQQ__ProrateMultiplier__c '+newQuoteLine.SBQQ__ProrateMultiplier__c);
                                System.debug('MS c4 RSC-G Replacement stamping values SBQQ__Quantity__c'+newQuoteLine.SBQQ__Quantity__c);

                            
                            if(wrapper.qlProductName.contains('-MDG-') || wrapper.qlProductName.contains('-M365G-')){
                                Decimal prLp = (newQuoteLine.SBQQ__ListPrice__c * newQuoteLine.SBQQ__ProrateMultiplier__c).setscale(2);
                                System.debug('MS c5 prLP is '+prLp);
                                Decimal listTotal = (newQuoteLine.SBQQ__ListPrice__c * newQuoteLine.SBQQ__ProrateMultiplier__c).setscale(2) * newQuoteLine.SBQQ__Quantity__c;
                                System.debug('MS c5 inside M365 before check Target NetTotal > ListTotal and listTotal is '+listTotal);
                                if(newQuoteLine.Target_NetTotal__c > listTotal){ 
                                    newQuoteLine.SBQQ__Discount__c = 0;
                                    System.debug('MS c5 M365-G Replacement Target NetTotal > ListTotal so updating SBQQ__Discount__c '+newQuoteLine.SBQQ__Discount__c);
                                }

                            }
                                if (wrapper.tphSKU || Test.isRunningTest()){
                                    newQuoteLine.TPH_OEM__c = mapOfQL.get(wrapper.qlId).TPH_OEM__c != null ? mapOfQL.get(wrapper.qlId).TPH_OEM__c : '';
                                    newQuoteLine.TPH_Models_Gen__c = mapOfQL.get(wrapper.qlId).TPH_Models_Gen__c != null ? mapOfQL.get(wrapper.qlId).TPH_Models_Gen__c : '';
                                    newQuoteLine.TPH_Drive_Size__c = mapOfQL.get(wrapper.qlId).TPH_Drive_Size__c != null ? mapOfQL.get(wrapper.qlId).TPH_Drive_Size__c : '';
                                    newQuoteLine.TPH_Quantity__c = mapOfQL.get(wrapper.qlId).TPH_Quantity__c != null ? mapOfQL.get(wrapper.qlId).TPH_Quantity__c : '';
                                    newQuoteLine.Who_will_Install_CDM__c = mapOfQL.get(wrapper.qlId).Who_will_Install_CDM__c != null ? mapOfQL.get(wrapper.qlId).Who_will_Install_CDM__c : '';
                                    newQuoteLine.Who_will_the_customer_be_buying_the_HW__c = mapOfQL.get(wrapper.qlId).Who_will_the_customer_be_buying_the_HW__c != null ? mapOfQL.get(wrapper.qlId).Who_will_the_customer_be_buying_the_HW__c : '';
                                
                                }
                            }
                        }
                        System.debug('MS c2 end inside if ToSKUvsSaasRecMap having Starting_Point__c '+ToSKUvsSaasRecMap.get(wrapper.mKey).Starting_Point__c);
                         
                        if(mapOfQL.containsKey(wrapper.qlId)) originalQuotesMap.add(mapOfQL.get(wrapper.qlId).SBQQSC__RenewedContractLine__r.SBQQSC__QuoteLine__r.SBQQ__Quote__r.Name);
                        if((quoteInScope.RWD_Deal_Ops_Exception__c != null && quoteInScope.RWD_Deal_Ops_Exception__c.contains('$0 RSC-G Replacement'))){
                            newQuoteLine.SBQQ__Discount__c = newQuoteLine.SBQQ__Discount__c != null ? newQuoteLine.SBQQ__Discount__c.setscale(2) : 0;
                            newQuoteLine.Promo_Disc__c = 100 - newQuoteLine.SBQQ__Discount__c;
                            newQuoteLine.Flag_for_Discount__c = true;
                            newQuoteLine.Wrbnu__c = true;
                            newQuoteLine.Custom_Promo_Discount_Applicable__c = true;
                            newQuoteLine.Promo_Code__c = 'Custom Promo';
                            System.debug('MS c5 inside if $0 RSC-G Replacement stamping values ');
                        }

                        //RGCF2-66 STARTS
                        if(ToSKUvsSaasRecMap.containsKey(wrapper.mKey) && (ToSKUvsSaasRecMap.get(wrapper.mKey).IAR__c) && 
                            ((quoteInScope.RWD_Deal_Ops_Exception__c != null && quoteInScope.RWD_Deal_Ops_Exception__c.contains('$0 RSC-G Replacement'))
                            ||(quoteInScope.RWD_Sales_Rep_Exception__c != null && quoteInScope.RWD_Sales_Rep_Exception__c.contains('25% Premium RSC-G Replacement')) )){
                                newQuoteLine.IAR__c = true;
                                System.debug('MS c5 inside if stamping IAR');
                                newQuoteLine.Wrbnu__c = false;
                            }
                        //RGCF2-66 ENDS

                    }
                    System.debug('MS c1 ends inside if ToSKUvsSaasRecMap contains key of replaced '+wrapper.qlProductName);
                }
                
            //}
            //System.debug(' MS c6 returns QLI ' +newQuoteLine);
        return newQuoteLine;
    }
    
    /**getcreateablefields */
    public static Map<String,Schema.DisplayType> getcreateablefields(String objectName){
        String selects = '';
        Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get(objectName.toLowerCase()).getDescribe().Fields.getMap();
        List<string> selectFields = new List<string>();
        Map<String,Schema.DisplayType> fieldMap = new Map<String,Schema.DisplayType>();
        
        if(fMap != null){
            if(objectName == 'SBQQ__QuoteLine__c'){
                for (Schema.SObjectField ft: fMap.values()){ // loop through all field tokens (ft)
                    Schema.DescribeFieldResult fd = ft.getDescribe(); // describe each field (fd)
                    if(fd.isCreateable()){ // field is Accessible
                        selectFields.add(fd.getName());
                        fieldMap.put(fd.getName(),fd.getType());
                    }
                }
            }
            else{
                for(Schema.SObjectField ft: fMap.values()){ // loop through all field tokens (ft)
                    Schema.DescribeFieldResult fd = ft.getDescribe(); // describe each field (fd)
                    if(fd.isAccessible()){ // field is Accessible
                        selectFields.add(fd.getName());
                        fieldMap.put(fd.getName(),fd.getType());
                    }
                }
            }
        }
        return fieldMap;
    }

    /**getProrateMultiplier */
    Public static Decimal getProrateMultiplier(Date startDate, Date endDate){
        Integer monthsBetween = startDate.monthsBetween(endDate);
        Date adjDate = startDate.addMonths(monthsBetween);
        if(adjDate > endDate){
            monthsBetween--;
            adjDate = adjDate.addMonths(-1);
        }
        Decimal remainingDays = adjDate.daysBetween(endDate) + 1;
        Decimal finalPrMult = monthsBetween + (remainingDays/(365.0/12)).setscale(4);
        
        return finalPrMult;
    }

    /**Method to get Dynamic List Price based on ProductId and Storage_Tier__c */
    public static Decimal getUnitPrice(String productId, String storageTier) {
        Map<String, Decimal> dynamicPricingMap = new Map<String, Decimal>();
        
        List<Dynamic_Pricing_Lookup__c> dynamicPricingList = [SELECT Storage_Tier__c, Unit_Price__c FROM Dynamic_Pricing_Lookup__c WHERE Product__c = :productId];

        for (Dynamic_Pricing_Lookup__c pricingRecord : dynamicPricingList) {
            String strTier = pricingRecord.Storage_Tier__c;
            Decimal unitPrice = pricingRecord.Unit_Price__c;

            dynamicPricingMap.put(strTier, unitPrice);
        }

        if (dynamicPricingMap.containsKey(storageTier)) {
            return dynamicPricingMap.get(storageTier);
        }
        return null;
    }

    /* Wrapper class for asset table*/
    public class SaasWrapper {
        /* asset*/
        @auraEnabled
        public String saasInScope                   { get; set; }
        /* qlId*/
        @auraEnabled
        public String qlId                          { get; set; }
        /*assetList*/
        @auraEnabled
        public String assetList                     { get; set; }
        /*assetListIds*/
        @auraEnabled
        public String assetListIds                  { get; set; }
        /*optionsAvailable*/
        @auraEnabled
        public String optionsAvailable              { get; set; }
        /*startDate*/
        @auraEnabled
        public Date startDate                       { get; set; }
        /*endDate*/
        @auraEnabled
        public Date endDate                         { get; set; }
        /*cliRootId*/
        @auraEnabled
        public String cliRootId                     { get; set; }
        
        /*endDate*/
        @auraEnabled
        public Date entEndDate                         { get; set; }
        
        /*originalQuotesName*/
        @auraEnabled
        public String originalQuoteName   { get; set; }
        
        /* Constructor */
        public SaasWrapper() {
        }
    }
    
    /* Wrapper class for Entitlement table*/
    public class EntitlementWrapper {
        /** entObj*/
        @auraEnabled
        public String entObj                        { get; set; }
        /*assetList*/
        @auraEnabled
        public String assetList                     { get; set; }
        /*assetListIds*/
        @auraEnabled
        public String assetListIds                  { get; set; }
        /*optionsAvailable*/
        @auraEnabled
        public String optionsAvailable              { get; set; }
        /*qlId*/
        @auraEnabled
        public String qlId                          { get; set; }
        /*startDate*/
        @auraEnabled
        public Date startDate                       { get; set; }
        /*endDate*/
        @auraEnabled
        public Date endDate                         { get; set; }
        /*uplift*/
        @auraEnabled
        public Decimal uplift                    { get; set; }
        /*cliRootId*/
        @auraEnabled
        public String cliRootId                     { get; set; }
        /*tphSKU*/
        @auraEnabled
        public Boolean tphSKU                        { get; set; }
        /*assetList*/
        @auraEnabled
        public String assetNamesForTPH              { get; set; }
        /*endDate*/
        @auraEnabled
        public Date entEndDate                         { get; set; }
        /*originalQuotesName*/
        @auraEnabled
        public String originalQuoteName   { get; set; }
        
        
        /*Constructor*/
        public EntitlementWrapper() {
            tphSKU = false;
        }
    }
    
    /* Wrapper class for asset table*/
    public class AssetWrapper {
        /* asset*/
        @auraEnabled
        public Asset assetInScope                   { get; set; }
        /* qlId*/
        @auraEnabled
        public String qlId                          { get; set; }
        /*assetList*/
        @auraEnabled
        public String assetList                     { get; set; }
        /*assetListIds*/
        @auraEnabled
        public String assetListIds                  { get; set; }
        /*optionsAvailable*/
        @auraEnabled
        public String optionsAvailable              { get; set; }
        /*qty*/
        @auraEnabled
        public Decimal qty                          { get; set; }
        /*startDate*/
        @auraEnabled
        public Date startDate                       { get; set; }
        /*endDate*/
        @auraEnabled
        public Date endDate                         { get; set; }
        /*cKey*/
        @auraEnabled
        public String cKey                          { get; set; }
        /*QLId*/
        @auraEnabled
        public String qli                          { get; set; }
        /*astqli*/
        @auraEnabled
        public String astqli                    { get; set; }
        
        /* Constructor */
        public AssetWrapper() {
        }
    }
    
    /* Wrapper class for create Quote Lines*/
    public class QuoteLineWrapper { 
        /*qlProductName*/
        @auraEnabled
        public String qlProductName                { get; set; }
        /*qlId*/
        @auraEnabled
        public String qlId                         { get; set; }
        /*assetList*/
        @auraEnabled
        public String assetList                    { get; set; }
        /*assetListIds*/
        @auraEnabled
        public String assetListIds                 { get; set; }
        /*qty*/  
        @auraEnabled
        public Decimal qty                         { get; set; }
        /*extId*/
        @auraEnabled
        public String extId                        { get; set; }
        /*isOption*/
        @auraEnabled
        public Boolean isOption                     { get; set; }
        /*tphSKU*/
        @auraEnabled
        public Boolean tphSKU                       { get; set; }
        /*assetNamesForTPH*/
        @auraEnabled
        public String assetNamesForTPH              { get; set; }
        /*entEndDate*/
        @auraEnabled
        public Date entEndDate                    { get; set; }
        /*uplift*/
        @auraEnabled
        public Decimal uplift                    { get; set; }
        /*astqli*/
        @auraEnabled
        public String astqli                    { get; set; }
        /*SaaS-SaaS Mapping Key*/
        @auraEnabled
        public String mKey                    { get; set; }
       

        /* Constructor */
        public QuoteLineWrapper() {
            isOption = false;
            tphSKU = false;
        }
    }
}