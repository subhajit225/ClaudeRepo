/**
* @File Name : EntitlementMissingScriptClass.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : October 21, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 21, 2024 |   | Initial Version
**/

public class EntitlementMissingScriptClass {
    @AuraEnabled
    public static List<EntitlementWrapper> getDebugSet(String UIstartDate, String UIendDate) {
        
        System.debug('UIstartDate::'+UIstartDate);
        System.debug('UIendDate::'+UIendDate);
        
        List<EntitlementWrapper> missingEntitlements = new List<EntitlementWrapper>();
        List<DebugLogWrapper> debugLogsList = new List<DebugLogWrapper>();
        List<DebugLogWrapper> missingoldCLIQLIdsList = new List<DebugLogWrapper>();
        List<DebugLogWrapper> missingSNQLIsList = new List<DebugLogWrapper>();
        List<DebugLogWrapper> quantityAndHwCapacityNewSalesList = new List<DebugLogWrapper>();
        List<DebugLogWrapper> missingLinkBetweenSwAndHwsList = new List<DebugLogWrapper>();
        List<DebugLogWrapper> mismatchSNQuantQLIsList = new List<DebugLogWrapper>();
        List<DebugLogWrapper> mismatchCLIAssetQLIdsList = new List<DebugLogWrapper>();
        List<DebugLogWrapper> mismatchSNQuantQLIValidateOnlYList = new List<DebugLogWrapper>();
        List<DebugLogWrapper> missingoldCLIOrdersList = new List<DebugLogWrapper>();
        List<DebugLogWrapper> newSalemismatchSNQuantEntIdsList = new List<DebugLogWrapper>();
        Map<Id, DebugLogWrapper> missingLinkedAssetEntIdMap = new Map<Id, DebugLogWrapper>();
        List<DebugLogWrapper> orderCLIQLIMismatchList = new List<DebugLogWrapper>();
        List<DebugLogWrapper> oneTimeCorrectionList = new List<DebugLogWrapper>();
        /* This script doesn't discard license sku associated with addon node
        * Scale needs to be manually reviewed as they don't have old CLI nor asset Id ex: 5508Y000006E36HQAS
        * v2 to v2 renewed addons will have to be eliminated manually
        */
        set<id> AllmissingLinksEntId = new set<id>(); // Overall missing/ partial entitlement links
        set<id> missingLinksQuantitymismatchId = new set<id>();
        set<id> quantityAndHwCapacityNewSale = new set<id>();
        
        //QLI
        set<id> missingSNQLI = new set<id>(); // Missing SN on the renewal/conversion QLI
        set<id> mismatchSNQuantQLI= new set<id>(); // SN and Quant mismatch on quote
        set<id>mismatchSNQuantQLIValidateOnlY = new set<id>(); // Ent links are created but quant != SN on QLI
        set<id> MismatchCLIAssetQLId = new set<id>(); // When assets on QLI is not present on the old CLI
        set<id> MissingoldCLIQLId = new set<id>(); // old CLI is missing on the QLI
        //Order
        set<id> missingSNonOI = new set<id>();
        set<id> MissingLinksOnOrdEntId = new set<id>(); // has old cli and asset
        set<id> MissingLinksOIAddon = new set<id>();// Ent links for addon
        set<id> MissingLinksOIScale = new set<id>();
        set<id> MissingoldCLIOrder = new set<id>(); // conversion , when old CLI is not copied from QLI
        set<id> UsableCapacityNotKnown = new set<id>(); // Usable capacity is missing on the asset
        Map<id,id> MissingLinkedAssetEntId = new Map<id,id>(); // Missing linked assetIds
        set<id> OrderCLIQLIMismatch = new set<id>(); // Single orders CLId != QLI CLId
        set<id> OIValidateOnly = new set<id>(); // records cnv without CLI,SN (sakura)
        Set<Id> AllLicencequoteline= new Set<Id>();
        
        Map<id,string>  NewSalemismatchSNQuantEntId = new Map<id,string> ();
        Map<string,integer> errMsgCountMap = new Map<string,integer>();
        
        //Local Usage
        Map<string,set<string>> oldCLIAssetNameMap = new Map<string,set<string>>();
        List<id> OrdItmOldCLIRecheck = new List<id>();
        set<id> discardEnt = new set<id> {}; // include entIds for known records
        set<id> IncludeOnlyEnt = new set<id> {}; // for testing
        set<id> missingLinkBetweenSwAndHw = new Set<Id>();
        
        // RV
        set<id> AllAboveENTs = new set<id>();
        set<id> NewTotalEntmissinglink = new set<id>();
        
        Set<String> excludeQLIIds = getQliIdsToBeExcludedFromReport();
        String entitlementQuery = 'select id,Name, Order_Service_Item__r.Product2.ProductCode, Product__r.name,Order_Quantity__c,Quantity__c,Order_Service_Item__r.Previous_Contract_Line_Items__c,Order_Service_Item__r.SerialNumber__c,Order_Service_Item__r.SBQQ__QuoteLine__c,Order_Service_Item__r.SBQQ__QuoteLine__r.Arroyo_Subsumed_Old_Contract_Line_Items__c,Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__Quantity__c,Order_Service_Item__r.Program__c,Order_Service_Item__r.SBQQ__QuoteLine__r.Subscribed_Asset_Name__c,Order_Service_Item__r.SBQQ__QuoteLine__r.Arroyo_Subscribed_Asset_Name__c,Order_Service_Item__r.order.Order_Sub_Type__c,Product__r.Product_Level__c,Product__r.Product_Type__c,Product__r.Product_Subtype__c,Product__r.License_Category__c,'
                               +' Order_Service_Item__r.order.SD_Status__c,Order_Service_Item__r.order.ProcessType__c,Order_Service_Item__r.product2.Family,Assetid,ContractLineItemId,Asset.name,Product__r.Family,CreatedDate,Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQSC__RenewedContractLine__c,Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c,Order_Service_Item__r.order.Type,'
                               +' ContractLineItem.Product_Category__c, Order_Service_Item__r.product2.Product_Type__c,Order_Service_Item__r.Product2.Product_Subtype__c, Order_Service_Item__r.SBQQ__RequiredBy__r.product2.Product_Type__c,Order_Service_Item__r.SBQQ__RequiredBy__r.product2.Item_Type__c,Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Product_Type__c,Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Item_Type__c,'
                               +' Order_Service_Item__r.SBQQ__QuoteLine__r.SubscribedAssetNames__c, '
                               +' (select id from Entitlement_Links1__r),'
                               +' (select id,Asset__r.Product2.Usable_Capacity__c from Scale_Entitlements__r)'
                               +' FROM entitlement'
                               +' WHERE '+ getDatesFilter(UIstartDate, UIEndDate)
            				   +' Failure_Category__c = null AND Order_Service_Item__r.Order.Order_Status__c != \'Rejected\' AND Order_Service_Item__r.order.Is_RWD_Polaris_Quote__c = true and (Order_Service_Item__r.order.Order_Sub_Type__c =\'Renewal\' or Order_Service_Item__r.Program__c = \'Conversion\' or Order_Service_Item__r.Program__c =\'Replaced\') and Order_Service_Item__r.product2.name != \'RS-BT-RCDM-T\' and Type =\'Phone Support\''    
                               +' and (NOT id IN: discardEnt) and Order_Service_Item__r.SBQQ__QuoteLine__c NOT IN :excludeQLIIds  order by createddate desc';
        System.debug('entitlementQuery::'+entitlementQuery);
        for(Entitlement ent : Database.query(entitlementQuery))
        {// and id IN:IncludeOnlyEnt CreatedDate >= 2023-05-19T20:00:34.000+0000    or  Order_Service_Item__r.Program__c = 'Refresh'  and createddate>= yesterday 
            Boolean isAddon = ((ent.Order_Service_Item__r.SBQQ__RequiredBy__r.product2.Product_Type__c == 'Add-On Node' && ent.Order_Service_Item__r.SBQQ__RequiredBy__r.product2.Item_Type__c =='Non-inventory Item')||
                               (ent.Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Product_Type__c == 'Add-On Node' && ent.Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Item_Type__c =='Non-inventory Item'));
            
            Boolean isHwSupport = (ent.Product__r.Product_Level__c =='Support' && ent.Product__r.Product_Type__c == 'HW Support'	);																																																																																			
            if(ent.Entitlement_Links1__r.isEmpty())
            {
                if(isAddon){
                    if(ent.Order_Service_Item__r.SBQQ__QuoteLine__r.Arroyo_Subsumed_Old_Contract_Line_Items__c == null ){
                        MissingoldCLIQLId.add(ent.Order_Service_Item__r.SBQQ__QuoteLine__c);
                        DebugLogWrapper dlw = buildWrapper(ent, null);
                        if(dlw != null){
                        	missingoldCLIQLIdsList.add(dlw);    
                        }
                        // RV
                        AllAboveENTs.add(ent.Id);
                    }
                    else{
                        MissingLinksOIAddon.add(ent.id);
                        DebugLogWrapper dlw = buildWrapper(ent, null);
                        if(dlw != null){
                        	oneTimeCorrectionList.add(dlw);    
                        }
                        // RV
                        AllAboveENTs.add(ent.Id);
                    }
                    continue;
                }
                if(ent.Product__r.Family == 'Rubrik Scale'){
                    if(ent.Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQSC__RenewedContractLine__c == null &&
                       ent.Order_Service_Item__r.SBQQ__QuoteLine__r.Arroyo_Subsumed_Old_Contract_Line_Items__c == null){
                           MissingoldCLIQLId.add(ent.Order_Service_Item__r.SBQQ__QuoteLine__c);
                           DebugLogWrapper dlw = buildWrapper(ent, null);
                           if(dlw != null){
                               missingoldCLIQLIdsList.add(dlw);    
                           }
                           // RV
                           AllAboveENTs.add(ent.Id);
                       }
                    else{
                           MissingLinksOIScale.add(ent.id);
                           DebugLogWrapper dlw = buildWrapper(ent, null);
                           if(dlw != null){
                               oneTimeCorrectionList.add(dlw);    
                           }
                           // RV
                           AllAboveENTs.add(ent.Id);
                       }
                    continue;
                }
                if(ent.Order_Service_Item__r.SBQQ__QuoteLine__r.Arroyo_Subsumed_Old_Contract_Line_Items__c != null){
                    AllmissingLinksEntId.add(ent.id);
                }
                if((ent.Order_Service_Item__r.Previous_Contract_Line_Items__c == null || ent.Order_Service_Item__r.SBQQ__QuoteLine__r.Arroyo_Subsumed_Old_Contract_Line_Items__c == null) && ent.CreatedDate >= DateTime.newInstance(2022,11,21)){
                    if(ent.Order_Service_Item__r.SBQQ__QuoteLine__r.Arroyo_Subsumed_Old_Contract_Line_Items__c == null && (ent.Order_Service_Item__r.order.Order_Sub_Type__c =='Renewal' || ent.Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c =='Renewal+Expansion') ){
                        MissingoldCLIQLId.add(ent.Order_Service_Item__r.SBQQ__QuoteLine__c);
                        DebugLogWrapper dlw = buildWrapper(ent, null);
                        if(dlw != null){
                            missingoldCLIQLIdsList.add(dlw);    
                        }
                        // RV
                        AllAboveENTs.add(ent.Id);
                    }
                    else if( ent.AssetId != null && ent.Order_Service_Item__r.Program__c == 'Conversion' && ent.Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c != 'Renewal+Expansion'){
                        if(ent.Order_Service_Item__r.order.Type != 'Revenue' && !isAddon){
                            OIValidateOnly.add(ent.Order_Service_Item__c);
                            DebugLogWrapper dlw = buildWrapper(ent, null);
                            if(dlw != null){
                                oneTimeCorrectionList.add(dlw);    
                            }
                            // RV
                            AllAboveENTs.add(ent.Id);
                            continue;
                        }
                    }
                    else if(isAddon== false && ent.Order_Service_Item__r.Program__c == 'Conversion' && ent.Order_Service_Item__r.SBQQ__QuoteLine__r.Arroyo_Subscribed_Asset_Name__c == null){
                        missingSNQLI.add(ent.Order_Service_Item__r.SBQQ__QuoteLine__c);
                        DebugLogWrapper dlw = buildWrapper(ent, null);
                        if(dlw != null){
                            missingSNQLIsList.add(dlw);    
                        }
                        // RV
                        AllAboveENTs.add(ent.Id);
                    }
                    else if(ent.Order_Service_Item__r.Previous_Contract_Line_Items__c == null ){ 
                        
                        MissingoldCLIOrder.add(ent.id);
                        DebugLogWrapper dlw = buildWrapper(ent, null);
                        if(dlw != null){
                            missingoldCLIOrdersList.add(dlw);    
                        }
                        // RV
                        AllAboveENTs.add(ent.Id);
                    }
                }
                if((ent.Product__r.Product_Level__c =='Support' && ent.Product__r.Product_Type__c == 'HW Support')
                   	||(ent.Product__r.Product_Level__c == 'Hybrid Software' || (ent.Product__r.Product_Level__c == 'OnPrem' 
                    &&(ent.Product__r.Product_Type__c =='Foundation Edition' || ent.Product__r.Product_Type__c =='Business Edition' 
                       || ent.Product__r.Product_Type__c =='Enterprise Edition' )
                    && ent.Product__r.Product_Subtype__c == null) ||  ent.Product__r.Product_Level__c == 'LOD Software') 
                   	&& ent.Product__r.Product_Subtype__c != 'RCDM')
                {
                    if(isAddon== false && ent.Order_Service_Item__r.Program__c != 'Refresh'  && ent.Product__r.Family != 'Rubrik Scale' 
                       && ((ent.Order_Service_Item__r.SBQQ__QuoteLine__r.Subscribed_Asset_Name__c == null && ent.Order_Service_Item__r.order.Order_Sub_Type__c =='Renewal' &&  ent.Order_Service_Item__r.Program__c != 'Conversion') ||(ent.Order_Service_Item__r.SBQQ__QuoteLine__r.Arroyo_Subscribed_Asset_Name__c == null &&
                                       ent.Order_Service_Item__r.SBQQ__QuoteLine__r.Subscribed_Asset_Name__c == null)))
                    { //  missing SN
                        
                        missingSNQLI.add(ent.Order_Service_Item__r.SBQQ__QuoteLine__c);
                        DebugLogWrapper dlw = buildWrapper(ent, null);
                        if(dlw != null){
                            missingSNQLIsList.add(dlw);    
                        }
                        // RV
                        AllAboveENTs.add(ent.Id);
                    }
                    else{ // asset and quantity mismatch
                        if((!(ent.Product__r.Product_Subtype__c == 'Scale MSP' && ent.Product__r.License_Category__c == null)) && (ent.Product__r.Product_Level__c == 'Hybrid Software' || (ent.Product__r.Product_Level__c == 'OnPrem' && (ent.Product__r.Product_Type__c =='Foundation Edition' || ent.Product__r.Product_Type__c =='Business Edition' || ent.Product__r.Product_Type__c =='Enterprise Edition' )
                        			&& ent.Product__r.Product_Subtype__c == null) ||  ent.Product__r.Product_Level__c == 'LOD Software') && ent.Product__r.Product_Subtype__c != 'RCDM' && ent.Product__r.Product_Subtype__c != 'Virtual'   &&  ent.Product__r.Family != 'Rubrik Scale')
                        {
                            
                            if(!ent.Scale_Entitlements__r.isEmpty()){ // Linked assets
                                Decimal Capacity = 0.0;
                                for(Scale_Entitlement__c scEnt : ent.Scale_Entitlements__r){
                                    if(scEnt.Asset__r?.Product2?.Usable_Capacity__c  != null){
                                        Capacity+= scEnt.Asset__r.Product2.Usable_Capacity__c;
                                    }
                                    else{
                                        UsableCapacityNotKnown.add(scEnt.id);
                                    }
                                }
                                if(ent.Order_Quantity__c != Capacity){
                                    mismatchSNQuantQLI.add(ent.Order_Service_Item__r.SBQQ__QuoteLine__c);
                                    DebugLogWrapper dlw = buildWrapper(ent, null);
                                    if(dlw != null){
                                        mismatchSNQuantQLIsList.add(dlw);    
                                    }
                                    // RV
                                    AllAboveENTs.add(ent.Id);
                                }
                            }
                            else if(ent.Order_Service_Item__r.product2.Family != 'Third Party License' && 
                                    ent.Order_Service_Item__r.product2.Product_Type__c != 'RZTDP' &&
                                    (ent.ContractLineItem.Product_Category__c != 'Virtual-Addon'&&
                                     ent.ContractLineItem.Product_Category__c != 'Virtual Addon') &&
                                    ent.Order_Service_Item__r.product2.Product_Subtype__c != 'FEDRAMP'
                                    && !ent.Order_Service_Item__r.Product2.ProductCode.contains('RSCP'))
                            {
                                MissingLinkedAssetEntId.put(ent.Order_Service_Item__r.SBQQ__QuoteLine__c,ent.id);
                                DebugLogWrapper dlw = buildWrapper(ent, null);
                                if(dlw != null){
                                    missingLinkedAssetEntIdMap.put(ent.Order_Service_Item__r.SBQQ__QuoteLine__c, dlw);    
                                }
                                // RV
                                AllAboveENTs.add(ent.Id);
                            }
                        }
                        else if(ent.Product__r.Product_Level__c =='Support' && ent.Product__r.Product_Type__c == 'HW Support')
                        {
                            if(isAddon== false && (ent.Order_Service_Item__r.Program__c == 'Conversion' && ent.Order_Service_Item__r.SBQQ__QuoteLine__r.Arroyo_Subscribed_Asset_Name__c == null && ent.Order_Service_Item__r.SBQQ__QuoteLine__r.Subscribed_Asset_Name__c  == null)||
                               (ent.Order_Service_Item__r.Program__c != 'Conversion' && ent.Order_Service_Item__r.SBQQ__QuoteLine__r.Subscribed_Asset_Name__c  == null))
                            {
                                missingSNQLI.add(ent.Order_Service_Item__r.SBQQ__QuoteLine__c);
                                DebugLogWrapper dlw = buildWrapper(ent, null);
                                if(dlw != null){
                                    missingSNQLIsList.add(dlw);    
                                }
                                // RV
                                AllAboveENTs.add(ent.Id);
                            }else if(ent.Order_Service_Item__r.SerialNumber__c == null){
                                missingSNonOI.add(ent.Order_Service_Item__c);
                            }else if(ent.Order_Quantity__c != ent.Order_Service_Item__r.SerialNumber__c.split(',').size()){
                                mismatchSNQuantQLI.add(ent.Order_Service_Item__r.SBQQ__QuoteLine__c);
                                DebugLogWrapper dlw = buildWrapper(ent, null);
                                if(dlw != null){
                                    mismatchSNQuantQLIsList.add(dlw);    
                                }
                                // RV
                                AllAboveENTs.add(ent.Id);
                            }else if(ent.Order_Service_Item__r.Previous_Contract_Line_Items__c != null &&
                                     ent.Order_Service_Item__r.SerialNumber__c != null)
                            {
                                MissingLinksOnOrdEntId.add(ent.id);
                                OrdItmOldCLIRecheck.add(ent.Order_Service_Item__c);
                                if(ent.Order_Service_Item__r.Previous_Contract_Line_Items__c != null){
                                    for(string oldCLI : ent.Order_Service_Item__r.Previous_Contract_Line_Items__c.split(',')){
                                        oldCLIAssetNameMap.put(oldCLI.trim(),new set<string>());
                                    }
                                }
                            }
                        }
                    }
                }
                else if(ent.Order_Service_Item__r.Previous_Contract_Line_Items__c != null)
                {
                    MissingLinksOnOrdEntId.add(ent.id);
                    OrdItmOldCLIRecheck.add(ent.Order_Service_Item__c);
                    if(ent.Order_Service_Item__r.Previous_Contract_Line_Items__c != null){
                        for(string oldCLI : ent.Order_Service_Item__r.Previous_Contract_Line_Items__c.split(',')){
                            oldCLIAssetNameMap.put(oldCLI.trim(),new set<string>());
                        }
                    }
                }
            }
            else if((!(ent.Product__r.Product_Subtype__c == 'Scale MSP' && ent.Product__r.License_Category__c == null)) && // Where  ent links are created but may miss by quantity factor
                     ent.Order_Service_Item__r.product2.Family != 'Third Party License' &&
                     (ent.Product__r.Product_Level__c == 'Hybrid Software' || (ent.Product__r.Product_Level__c == 'OnPrem' && (ent.Product__r.Product_Type__c =='Foundation Edition' || ent.Product__r.Product_Type__c =='Business Edition' || ent.Product__r.Product_Type__c =='Enterprise Edition' )
                      && ent.Product__r.Product_Subtype__c == null) ||  ent.Product__r.Product_Level__c == 'LOD Software') && ent.Product__r.Product_Subtype__c != 'RCDM' && ent.Product__r.Product_Subtype__c != 'Virtual'   &&  ent.Product__r.Family != 'Rubrik Scale' )
            { // Mismatch in quantity for license sku
                if(!ent.Scale_Entitlements__r.isEmpty())
                {
                    Decimal Capacity = 0.0;
                    for(Scale_Entitlement__c scEnt : ent.Scale_Entitlements__r)
                    {
                        if(scEnt.Asset__r?.Product2?.Usable_Capacity__c  != null)
                        {
                            Capacity+= scEnt.Asset__r.Product2.Usable_Capacity__c;
                        }
                        else{
                            UsableCapacityNotKnown.add(scEnt.id);
                        }
                    }
                    if(ent.Order_Quantity__c != Capacity &&
                       ent.Order_Service_Item__r.SBQQ__QuoteLine__r.Arroyo_Subsumed_Old_Contract_Line_Items__c != null)
                    {
                        //if(ent.Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__Quantity__c != Capacity){
                        mismatchSNQuantQLI.add(ent.Order_Service_Item__r.SBQQ__QuoteLine__c);
                        DebugLogWrapper dlw = buildWrapper(ent, null);
                        if(dlw != null){
                            mismatchSNQuantQLIsList.add(dlw);    
                        }
                        AllmissingLinksEntId.add(ent.id);
                        missingLinksQuantitymismatchId.add(ent.id);
                        // RV
                        AllAboveENTs.add(ent.Id);
                        //}
                        
                    }
                }
                else if(!isAddon)
                {
                    if(ent.ContractLineItem.Product_Category__c != 'Virtual-Addon' && ent.ContractLineItem.Product_Category__c != 'Virtual Addon')
                    {
                        mismatchSNQuantQLIValidateOnlY.add(ent.Order_Service_Item__r.SBQQ__QuoteLine__c);
                        DebugLogWrapper dlw = buildWrapper(ent, null);
                        if(dlw != null){
                            mismatchSNQuantQLIValidateOnlYList.add(dlw);    
                        }
                        // RV
                        AllAboveENTs.add(ent.Id);
                    }
                }
            }
            else if(isHwSupport && !ent.Entitlement_Links1__r.isEmpty() && ent?.Order_Service_Item__r?.SerialNumber__c != null && ent?.Order_Quantity__c != null && ent?.Order_Quantity__c != ent?.Order_Service_Item__r?.SerialNumber__c.split(',').size())
            {
              	mismatchSNQuantQLI.add(ent.Order_Service_Item__r.SBQQ__QuoteLine__c);
                DebugLogWrapper dlw = buildWrapper(ent, null);
                if(dlw != null){
                    mismatchSNQuantQLIsList.add(dlw);    
                }
            }
        }
        Set<String> oldCLIAssetNamesList = oldCLIAssetNameMap.keyset();
        entitlementQuery = 'SELECT id,ContractLineItemId,Order_Service_Item__r.Product2.Product_Subtype__c,ContractLineItem.Product_Category__c, Asset.name FROM Entitlement'
            				+ ' WHERE '+ getDatesFilter(UIstartDate, UIEndDate) +' Failure_Category__c = null AND ContractLineItemId IN :oldCLIAssetNamesList and Assetid != null and Order_Service_Item__r.SBQQ__QuoteLine__c NOT IN :excludeQLIIds order by createddate desc';
        System.debug('entitlementQuery::2'+entitlementQuery);
        for(Entitlement ent : Database.query(entitlementQuery))
        {
            if(!String.isBlank(ent?.ContractLineItemId) && oldCLIAssetNameMap.containsKey(ent?.ContractLineItemId) 
               && ent?.Asset != null && String.isNotBlank(ent?.Asset?.name))
            {
                oldCLIAssetNameMap?.get(ent?.ContractLineItemId).add(ent?.Asset?.name);
            }
            
        }
        //DebugList.add('oldCLIAssetNameMap'+JSON.serialize(oldCLIAssetNameMap));
        for(orderItem OI : [select id,order.Total_no_of_orders__c,Previous_Contract_Line_Items__c,SerialNumber__c,SBQQ__QuoteLine__c,SBQQ__QuoteLine__r.Arroyo_Subsumed_Old_Contract_Line_Items__c, SBQQ__QuoteLine__r.Subscribed_Asset_Name__c,
                            SBQQ__QuoteLine__r.SubscribedAssetNames__c,
                            SBQQ__QuoteLine__r.Arroyo_Subscribed_Asset_Name__c,
                            (select id from entitlements__r)   from orderItem where id IN: OrdItmOldCLIRecheck order by createddate desc])
        {
            if(OI.SerialNumber__c != null)
            {
                set<string> SNSet = new set<string>();
                SNSet.addall(OI.SerialNumber__c.split(','));
                if(OI.order.Total_no_of_orders__c == 1 && OI.Previous_Contract_Line_Items__c!= null && OI.SBQQ__QuoteLine__r.Arroyo_Subsumed_Old_Contract_Line_Items__c != null && OI.Previous_Contract_Line_Items__c.deleteWhitespace() != OI.SBQQ__QuoteLine__r.Arroyo_Subsumed_Old_Contract_Line_Items__c.deleteWhitespace())
                {
                    OrderCLIQLIMismatch.add(OI.id);
                    SBQQ__QuoteLine__c qli = new SBQQ__QuoteLine__c();
                    qli.Id = OI.SBQQ__QuoteLine__c;
                    qli.SubscribedAssetNames__c = OI.SBQQ__QuoteLine__r.SubscribedAssetNames__c;
                    qli.Subscribed_Asset_Name__c = OI.SBQQ__QuoteLine__r.Subscribed_Asset_Name__c;
                    qli.Arroyo_Subscribed_Asset_Name__c = OI.SBQQ__QuoteLine__r.Arroyo_Subscribed_Asset_Name__c;
                    qli.Arroyo_Subsumed_Old_Contract_Line_Items__c = OI.SBQQ__QuoteLine__r.Arroyo_Subsumed_Old_Contract_Line_Items__c;
                    DebugLogWrapper dlw = buildWrapper(null, qli);
                    if(dlw != null){
                        orderCLIQLIMismatchList.add(dlw);    
                    }
                    
                    // RV
                    if(!OI.entitlements__r.isEmpty())
                    {
                        for(entitlement ent : OI.entitlements__r)
                        {
                            AllAboveENTs.add(ent.Id);
                        }
                    }
                }
                else {
                    set<string> SNSetClone = new set<String>(SNSet); 
                    for(string SN : SNSetClone)
                    {
                        for(string oldCLI : OI.Previous_Contract_Line_Items__c.split(','))
                        {
                            if(oldCLIAssetNameMap.get(oldCLI.trim())!= null && oldCLIAssetNameMap.get(oldCLI.trim()).contains(SN.trim()))
                            {
                                SNSet.remove(SN);
                                continue;
                            }
                        }
                    }
                    if(!SNSet.isEmpty())
                    {
                        MismatchCLIAssetQLId.add(OI.SBQQ__QuoteLine__c);
                        SBQQ__QuoteLine__c qli = new SBQQ__QuoteLine__c();
                        qli.Id = OI.SBQQ__QuoteLine__c;
                        qli.SubscribedAssetNames__c = OI.SBQQ__QuoteLine__r.SubscribedAssetNames__c;
                        qli.Subscribed_Asset_Name__c = OI.SBQQ__QuoteLine__r.Subscribed_Asset_Name__c;
                        qli.Arroyo_Subscribed_Asset_Name__c = OI.SBQQ__QuoteLine__r.Arroyo_Subscribed_Asset_Name__c;
                        qli.Arroyo_Subsumed_Old_Contract_Line_Items__c = OI.SBQQ__QuoteLine__r.Arroyo_Subsumed_Old_Contract_Line_Items__c;
                        DebugLogWrapper dlw = buildWrapper(null, qli);
                        if(dlw != null){
                        	mismatchCLIAssetQLIdsList.add(dlw);    
                        }
                        if(!OI.entitlements__r.isEmpty())
                        {
                            for(entitlement ent : OI.entitlements__r)
                            {
                                MissingLinksOnOrdEntId.remove(ent.id);
                                // RV
                                AllAboveENTs.add(ent.Id);
                            }
                        }
                        
                    }
                }
            }
        }
        entitlementQuery = 'select id,ContractLineItem.Product_Category__c,Order_Service_Item__r.Product2.Product_Subtype__c, Order_Service_Item__r.product2.Product_Type__c, Product__r.name,Quantity__c,Order_Quantity__c,Order_Service_Item__r.Previous_Contract_Line_Items__c,Order_Service_Item__r.SBQQ__QuoteLine__c,Order_Service_Item__r.SBQQ__QuoteLine__r.Arroyo_Subsumed_Old_Contract_Line_Items__c,Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__Quantity__c,Order_Service_Item__r.Program__c,Order_Service_Item__r.SBQQ__QuoteLine__r.Subscribed_Asset_Name__c,Order_Service_Item__r.SBQQ__QuoteLine__r.Arroyo_Subscribed_Asset_Name__c,Order_Service_Item__r.order.Order_Sub_Type__c,Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c,Product__r.Product_Level__c,Product__r.Product_Type__c,Product__r.Product_Subtype__c,Product__r.License_Category__c,'
                               +' Order_Service_Item__r.order.SD_Status__c,Order_Service_Item__r.Product2.ProductCode, Order_Service_Item__r.order.ProcessType__c,Order_Service_Item__r.product2.Family,'
                               +' Order_Service_Item__r.SBQQ__QuoteLine__r.SubscribedAssetNames__c,'
                               +' (select id from Entitlement_Links1__r),'         
                               +' (select id,Asset__r.Product2.Usable_Capacity__c from Scale_Entitlements__r)'
                               +' FROM Entitlement ';
        String whereConditions = ' WHERE '+ getDatesFilter(UIstartDate, UIEndDate) +' Failure_Category__c = null AND Order_Service_Item__r.SBQQ__QuoteLine__c NOT IN :excludeQLIIds and Order_Service_Item__r.Order.Order_Status__c != \'Rejected\' AND (Product__r.Product_Level__c = \'Hybrid Software\' or (Product__r.Product_Level__c = \'OnPrem\' and (Product__r.Product_Type__c =\'Foundation Edition\' or Product__r.Product_Type__c =\'Business Edition\' or Product__r.Product_Type__c =\'Enterprise Edition\' )'
                               + ' and Product__r.Product_Subtype__c = null) or Product__r.Product_Level__c = \'LOD Software\') and Product__r.Product_Subtype__c != \'RCDM\' and Product__r.Product_Subtype__c != \'Virtual\'   and Product__r.Family != \'Rubrik Scale\' and Order_Service_Item__r.order.Is_RWD_Polaris_Quote__c = true and '
                               + ' Order_Service_Item__r.order.Order_Sub_Type__c !=\'Renewal\' and Order_Service_Item__r.Program__c != \'Conversion\' and Product__r.Family != \'Rubrik Scale\' and '
                               + ' Type =\'Phone Support\'  and Order_Service_Item__r.product2.Family != \'Third Party License\' and '
                               + ' (Order_Service_Item__r.Order.ProcessType__c != \'Aspen\' or'
                               + ' (Order_Service_Item__r.order.ProcessType__c =\'Aspen\' and Order_Service_Item__r.order.SD_Status__c =\'Success\')) and'
                               + ' (NOT(Product__r.Product_Subtype__c = \'Scale MSP\' and Product__r.License_Category__c = null)) and'
                               + ' (NOT id IN: discardEnt) order by createddate desc';
        if(Test.isRunningTest()){
        	whereConditions = '';	    
        }
        for(Entitlement ent : Database.query(entitlementQuery+whereConditions))
        {// and id IN:IncludeOnlyEnt and CreatedDate >= 2023-05-19T20:00:34.000+0000    or  Order_Service_Item__r.Program__c = 'Refresh' and createddate>= yesterday
            
            if(!ent.Scale_Entitlements__r.isEmpty())
            {
                
                Decimal Capacity = 0.0;
                for(Scale_Entitlement__c scEnt : ent.Scale_Entitlements__r)
                {
                    
                    if(scEnt.Asset__r?.Product2?.Usable_Capacity__c  != null){
                        Capacity+= scEnt.Asset__r.Product2.Usable_Capacity__c;
                    }
                    else{
                        UsableCapacityNotKnown.add(scEnt.id);
                    }
                }
                if(ent.Order_Quantity__c != Capacity)
                {
                    
                    NewSalemismatchSNQuantEntId.put(ent.id,'AssetCapacity'+Capacity+':: OrderQty::'+ent.Order_Quantity__c);
                    DebugLogWrapper dlw = buildWrapper(ent, null);
                    if(dlw != null){
                        newSalemismatchSNQuantEntIdsList.add(dlw);    
                    }
                    // RV
                    AllAboveENTs.add(ent.Id);
                }
            }
            else {
                if(ent.Order_Service_Item__r.product2.Product_Type__c != 'RZTDP' && (ent.ContractLineItem.Product_Category__c != 'Virtual-Addon' && ent.ContractLineItem.Product_Category__c != 'Virtual Addon') &&
                   ent.Order_Service_Item__r.Product2.Product_Subtype__c != 'FEDRAMP' &&
                   !ent.Order_Service_Item__r.Product2.ProductCode.contains('RSCP'))
                {
                    MissingLinkedAssetEntId.put(ent.Order_Service_Item__r.SBQQ__QuoteLine__c,ent.id);
                    DebugLogWrapper dlw = buildWrapper(ent, null);
                    if(dlw != null){
                        missingLinkedAssetEntIdMap.put(ent.Order_Service_Item__r.SBQQ__QuoteLine__c, dlw);    
                    }
                    AllLicencequoteline.add(ent.Order_Service_Item__r.SBQQ__QuoteLine__c);
                    
                    // RV
                    AllAboveENTs.add(ent.Id);
                }
            }
        }
        for(SBQQ__QuoteLine__c qli  : [Select Id,SBQQ__Quantity__c, SubscribedAssetNames__c, Subscribed_Asset_Name__c, Arroyo_Subscribed_Asset_Name__c,
                                       Arroyo_Subsumed_Old_Contract_Line_Items__c,
                                       (select id,SBQQ__Product__r.Usable_Capacity__c,SBQQ__Quantity__c from SBQQ__Quote_Lines__r where (SBQQ__Product__r.Product_Level__c = 'Hardware' AND
                                                                                                                                                                     SBQQ__Product__r.Product_Type__c = 'Hardware') OR
                                                                    (SBQQ__Product__r.Product_Type__c = 'Add-On Node'  AND
                                                                     SBQQ__Product__r.Item_Type__c = 'Non-inventory Item'))
                                       from SBQQ__QuoteLine__c where Id IN : AllLicencequoteline order by createddate desc])
        {
            if(qli.SBQQ__Quote_Lines__r.isEmpty()){
                if(missingLinkedAssetEntId.containskey(qli.Id))
                    missingLinkedAssetEntId.remove(qli.Id);
                if(missingLinkedAssetEntIdMap.containskey(qli.Id))
                    missingLinkedAssetEntIdMap.remove(qli.Id);
                    
                missingLinkBetweenSwAndHw.add(qli.Id);
                DebugLogWrapper dlw = buildWrapper(null, qli);
                if(dlw != null){
                    missingLinkBetweenSwAndHwsList.add(dlw);    
                }
            }
            else{
                Decimal qty = 0.0;
                for(SBQQ__QuoteLine__c qliInner : qli.SBQQ__Quote_Lines__r){
                    qty += (qliInner.SBQQ__Quantity__c * qliInner.SBQQ__Product__r.Usable_Capacity__c);
                }
                if(qty!= qli.SBQQ__Quantity__c){
                    if(missingLinkedAssetEntId.containskey(qli.Id))
                        missingLinkedAssetEntId.remove(qli.Id);
                    if(missingLinkedAssetEntIdMap.containskey(qli.Id))
                    	missingLinkedAssetEntIdMap.remove(qli.Id);
                    quantityAndHwCapacityNewSale.add(qli.Id);
                    DebugLogWrapper dlw = buildWrapper(null, qli);
                    if(dlw != null){
                        quantityAndHwCapacityNewSalesList.add(dlw);    
                    }
                }
            }
        }
        
        Set<Id> MissingLinkedAssetEntIdSet = new Set<Id>(MissingLinkedAssetEntId.values());
        // Duplicate of quant and SN mismatch DebugList.add('missingLinksQuantitymismatchId Size-'+missingLinksQuantitymismatchId.size()+'->\n'+JSON.serialize(missingLinksQuantitymismatchId));
        
        // For size
        
        if(!missingLinkBetweenSwAndHw.isEmpty())
            errMsgCountMap.put('missingLinkBetweenSwAndHw Size-',missingLinkBetweenSwAndHw.size());
        
        
        if(!quantityAndHwCapacityNewSale.isEmpty())
            errMsgCountMap.put('quantityAndHwCapacityNewSale Size-',quantityAndHwCapacityNewSale.size());
        
        
        if(!MissingoldCLIQLId.isEmpty())
            errMsgCountMap.put('MissingoldCLIQLId Size-',MissingoldCLIQLId.size());
        if(!missingSNQLI.isEmpty())
            errMsgCountMap.put('missingSNQLI Size-',missingSNQLI.size());
        if(!mismatchSNQuantQLI.isEmpty())
            errMsgCountMap.put('mismatchSNQuantQLI Size-',mismatchSNQuantQLI.size());
        if(!MissingoldCLIOrder.isEmpty())
            errMsgCountMap.put('MissingoldCLIOrder Size-',MissingoldCLIOrder.size());
        if(!MismatchCLIAssetQLId.isEmpty())
            errMsgCountMap.put('MismatchCLIAssetQLId Size-',MismatchCLIAssetQLId.size());
        if(!MissingLinkedAssetEntIdSet.isEmpty())
            errMsgCountMap.put('MissingLinkedAssetEntIdSet Size-',MissingLinkedAssetEntIdSet.size()); 
        if(!UsableCapacityNotKnown.isEmpty())
            errMsgCountMap.put('UsableCapacityNotKnown Size-',UsableCapacityNotKnown.size());
        if(!MissingLinksOnOrdEntId.isEmpty())
            errMsgCountMap.put('MissingEntLinkEntId Size-',MissingLinksOnOrdEntId.size());
        if(!MissingLinksOIAddon.isEmpty())
            errMsgCountMap.put('MissingLinksOIAddon Size-',MissingLinksOIAddon.size());
        if(!MissingLinksOIScale.isEmpty())
            errMsgCountMap.put('MissingLinksOIScale Size-',MissingLinksOIScale.size());
        if(!NewSalemismatchSNQuantEntId.isEmpty())
            errMsgCountMap.put('NewSalemismatchSNQuantEntId Size-',NewSalemismatchSNQuantEntId.size());
        if(!mismatchSNQuantQLIValidateOnlY.isEmpty())
            errMsgCountMap.put('mismatchSNQuantQLIValidateOnlY Size-',mismatchSNQuantQLIValidateOnlY.size()); // Just for checking , check for ent links
        if(!OrderCLIQLIMismatch.isEmpty())
            errMsgCountMap.put('OrderCLIQLIMismatch Saize-',OrderCLIQLIMismatch.size());
        if(!OIValidateOnly.isEmpty())
            errMsgCountMap.put('OIValidateOnly Size-',OIValidateOnly.size());
        if(!AllmissingLinksEntId.isEmpty())
            errMsgCountMap.put('TotalEntmissinglink Size-',AllmissingLinksEntId.size());
        //errMsgCountMap.put('missingLinksQuantitymismatchId Size-',missingLinksQuantitymismatchId.size());
       
        for(Id i:AllmissingLinksEntId) {
            if(!AllAboveENTs.contains(i)) {
                NewTotalEntmissinglink.add(i);
            }
        }
        
        missingEntitlements = buildEntitlementWrapper('Missing Old CLI', missingoldCLIQLIdsList, missingEntitlements);
        missingEntitlements = buildEntitlementWrapper('Missing SN ', missingSNQLIsList, missingEntitlements);
        missingEntitlements = buildEntitlementWrapper('Quantity and HW Capacity(new Sale) ', quantityAndHwCapacityNewSalesList, missingEntitlements);
        missingEntitlements = buildEntitlementWrapper('Missing Link between SW and HW (NEW) ', missingLinkBetweenSwAndHwsList, missingEntitlements);
        missingEntitlements = buildEntitlementWrapper('Quantity and SN Mismatch (Renewals) ', mismatchSNQuantQLIsList, missingEntitlements);
        missingEntitlements = buildEntitlementWrapper('CLI and asset mismatch on the QLI ', mismatchCLIAssetQLIdsList, missingEntitlements);
        missingEntitlements = buildEntitlementWrapper('General quote validation ', mismatchSNQuantQLIValidateOnlYList, missingEntitlements);
        missingEntitlements = buildEntitlementWrapper('Missing old CLI on order ', missingoldCLIOrdersList, missingEntitlements);
        missingEntitlements = buildEntitlementWrapper('Quantity and SN Mismatch(new Sale) ', newSalemismatchSNQuantEntIdsList, missingEntitlements);
        missingEntitlements = buildEntitlementWrapper('Missing linked assets  ', missingLinkedAssetEntIdMap.values(), missingEntitlements);
        missingEntitlements = buildEntitlementWrapper('Order CLI QLI Mismatch  ', orderCLIQLIMismatchList, missingEntitlements);
        missingEntitlements = buildEntitlementWrapper('One time correction  ', oneTimeCorrectionList, missingEntitlements);
        
        System.debug('missingoldCLIQLId Size-'+missingoldCLIQLId.size());
        System.debug('missingSNQLI Size-'+missingSNQLI.size());
        System.debug('quantityAndHwCapacityNewSale Size-'+quantityAndHwCapacityNewSale.size());
        System.debug('missingLinkBetweenSwAndHw Size-'+missingLinkBetweenSwAndHw.size());
        System.debug('mismatchSNQuantQLI Size-'+mismatchSNQuantQLI.size());
        System.debug('mismatchCLIAssetQLId Size-'+mismatchCLIAssetQLId.size());
        System.debug('mismatchSNQuantQLIValidateOnlY Size-'+mismatchSNQuantQLIValidateOnlY.size());
		System.debug('MissingoldCLIOrder Size-'+MissingoldCLIOrder.size());
        System.debug('NewSalemismatchSNQuantEntId Size-'+NewSalemismatchSNQuantEntId.size());
        System.debug('MissingLinkedAssetEntId Size-'+MissingLinkedAssetEntId.size() + ' MissingLinkedAssetEntIdSet size - '+MissingLinkedAssetEntIdSet.size());
        System.debug('OrderCLIQLIMismatch Size-'+OrderCLIQLIMismatch.size());
        System.debug('OIValidateOnly Size-'+OIValidateOnly+' MissingLinksOIAddon Size-'+MissingLinksOIAddon+' MissingLinksOIScale Size-'+MissingLinksOIScale);
        
        return missingEntitlements;
    }
    private static String getDatesFilter(String startDate, String endDate){
    	String dateFilter = ' Id != null AND ';
        if(startDate != null && endDate != null){
        	dateFilter += ' StartDate >='+ startDate+' AND EndDate <= '+ endDate +' AND ';	    
        }
        else if(startDate != null){
        	dateFilter += ' StartDate >='+ startDate +' AND ';    
        }
        else if(endDate != null){
        	dateFilter +=  ' EndDate <='+ endDate +' AND ';  
        }
        return dateFilter;
    }
    private static Set<String> getQliIdsToBeExcludedFromReport(){
        Set<String> excludeQLIIds = new Set<String>{}; // This set can be used to exclude QLIs from the script records.
        List<Order_control__mdt> orderControlsList = [SELECT Values__c FROM Order_control__mdt WHERE DeveloperName = 'Entitlement_Report_Exception_List' LIMIT 1];
        if(!orderControlsList.isEmpty()){
            String excludedIds = orderControlsList[0].Values__c;
            if(String.isNotBlank(excludedIds)){
                for(String qliId : excludedIds.replaceAll('\\s+','').split(',')){
                    excludeQLIIds.add(qliId.trim());    
                }    
            }    
        }
        return excludeQLIIds;
    }
    private static List<EntitlementWrapper> buildEntitlementWrapper(String listName, List<DebugLogWrapper> debugsList, List<EntitlementWrapper> entitlementsList) {
    	EntitlementWrapper entWrap = new EntitlementWrapper();
        entWrap.info = listName;
        Set<Id> qliIds = new Set<Id>();
        String qliIdsString = '';
        List<DebugLogWrapper> qliLogsList = new List<DebugLogWrapper>();
        for(DebugLogWrapper dlw : debugsList){
            if(!qliIds.contains(dlw.qliId)){
            	qliLogsList.add(dlw);
                qliIdsString += dlw.qliId+',';
            } 
            qliIds.add(dlw.qliId);
        }
        entWrap.recordCount = qliLogsList.size();
        entWrap.qliDetails = qliLogsList;
        entWrap.qliIds = qliIdsString.removeEnd(',');
        entitlementsList.add(entWrap);
        return entitlementsList;
    }
    private static DebugLogWrapper buildWrapper(Entitlement ent, SBQQ__QuoteLine__c qli) {
        
        /*String subscribedAssetNames1;
        String subscribedAssetNames2;
        String subscribedAssetNames3;
        String subscribedAssetNames4;*/
        DebugLogWrapper missingEntitlementWrapper = new DebugLogWrapper();
        if(ent != null){
            if(ent.Order_Service_Item__c != null && ent.Order_Service_Item__r.SBQQ__QuoteLine__c != null){
            	missingEntitlementWrapper.qliId = ent.Order_Service_Item__r.SBQQ__QuoteLine__c;    
            }
            /*subscribedAssetNames1 = ent.Order_Service_Item__r.SBQQ__QuoteLine__r.SubscribedAssetNames__c; 
            subscribedAssetNames2 = ent.Order_Service_Item__r.SBQQ__QuoteLine__r.Subscribed_Asset_Name__c;
            subscribedAssetNames3 = ent.Order_Service_Item__r.SBQQ__QuoteLine__r.Arroyo_Subscribed_Asset_Name__c;
            subscribedAssetNames4 = ent.Order_Service_Item__r.SBQQ__QuoteLine__r.Arroyo_Subsumed_Old_Contract_Line_Items__c;*/
        }
        else if(qli != null){
            missingEntitlementWrapper.qliId = qli.Id;
        	/*subscribedAssetNames1 = qli.SubscribedAssetNames__c; 
            subscribedAssetNames2 = qli.Subscribed_Asset_Name__c;
            subscribedAssetNames3 = qli.Arroyo_Subscribed_Asset_Name__c;  
            subscribedAssetNames4 = qli.Arroyo_Subsumed_Old_Contract_Line_Items__c;*/
        }
        if(missingEntitlementWrapper.qliId == null){
        	return null;    
        }
        /*List<String> assetNamesList = String.isNotBlank(subscribedAssetNames1)
            ?subscribedAssetNames1.split(',')
            : new List<String>();
        List<String> subAssetNamesList = String.isNotBlank(subscribedAssetNames2)
            ?subscribedAssetNames2.split(',')
            : new List<String>();
        List<String> refreshedAssetList = String.isNotBlank(subscribedAssetNames3)
            ?subscribedAssetNames3.split(',')
            : new List<String>();
        List<String> subsummedList = String.isNotBlank(subscribedAssetNames4)
            ?subscribedAssetNames4.split(',')
            : new List<String>();
        
        missingEntitlementWrapper.assetNames = removeDuplicates(assetNamesList, subAssetNamesList, refreshedAssetList);
        missingEntitlementWrapper.subsumedItems = removeDuplicates(subsummedList, null, null);*/
        return missingEntitlementWrapper;
    }
    /*private static List<String> removeDuplicates(List<String> assetNamesList, List<String> subAssetNames, List<String> subsumedItems){
        set<String> uniqueValueSet = new set<String>();
        for(String assetName : assetNamesList){
            assetName = assetName.trim();
            uniqueValueSet.add(assetName); 
        } 
        if(subAssetNames != null){
            for(String assetName : subAssetNames){
                assetName = assetName.trim();
                uniqueValueSet.add(assetName); 
            }    
        }
        if(subsumedItems != null){
            for(String subItem : subsumedItems){
                subItem = subItem.trim();
                uniqueValueSet.add(subItem); 
            }    
        }
        return new List<String>(uniqueValueSet);
    }*/
    public class EntitlementWrapper{
        @AuraEnabled
        public String info;
        @AuraEnabled
        public Integer recordCount;
        @AuraEnabled
        public List<DebugLogWrapper> qliDetails;
        @AuraEnabled
        public String qliIds;
    }
    public class DebugLogWrapper {
        @AuraEnabled
        public String qliId;
        /*@AuraEnabled
        public List<String> assetNames;
        @AuraEnabled
        public List<String> subsumedItems;*/
        
    }
}