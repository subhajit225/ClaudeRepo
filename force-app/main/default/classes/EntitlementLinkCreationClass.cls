public class EntitlementLinkCreationClass {
    
    public EntitlementLinkCreationClass() {
        Set<String> devName = new Set<String>{ 'Old_CLI_Ids', 'New_Entitlement_Ids' };
        List<String> lstOldCliIds = new List<String>();
        List<String> lstNewEntitlementIds = new List<String>();
        
        List<Order_control__mdt> ListOldCLINewEntIds = [SELECT Id, DeveloperName, Values__c FROM Order_control__mdt WHERE DeveloperName IN :devName];
        if (!ListOldCLINewEntIds.isEmpty()) {
            for (Order_control__mdt objCLIEnt : ListOldCLINewEntIds) {
                if (objCLIEnt.DeveloperName == 'Old_CLI_Ids') {
                    lstOldCliIds = objCLIEnt.Values__c.replaceAll('\\s+', '').split(',');
                } else if (objCLIEnt.DeveloperName == 'New_Entitlement_Ids') {
                    lstNewEntitlementIds = objCLIEnt.Values__c.replaceAll('\\s+', '').split(',');
                }
            }
            createEntitlementLinks(lstOldCliIds, lstNewEntitlementIds);
        }
    }
    
    public void createEntitlementLinks(List<String> lstOldCliIds, List<String> lstNewEntitlementIds) {
        system.debug('::setOldCLIs::' + lstOldCliIds);
        system.debug('::setNewEntitlementIds::' + lstNewEntitlementIds);
        
        Set<String> setOrders = new Set<String>();
        Set<Id> setOldProducts = new Set<Id>();
        Set<Id> setNewProducts = new Set<Id>();
        Set<Id> setNewEntitlements = new Set<Id>();
        Map<String, Entitlement> mapNewEntIdToEntitlement = new Map<String, Entitlement>();
        Map<string, Id> olCLIConvProdId = new Map<String, Id>();
        List<Entitlement> lstOldEntitlement = new List<Entitlement>();
        Set<Id> setOldSplitSKuEntIds = new Set<Id>();
        Set<Id> setQuoteIds = new Set<Id>();
        String bypassSplitSKU = String.isNotBlank(Order_control__mdt.getInstance('SKU_With_Split_Renewal_Products')?.Value__c)
            ? Order_control__mdt.getInstance('SKU_With_Split_Renewal_Products').Value__c
            : null;
        Map<Id, ServiceContract> SCToUpdate = new Map<Id, ServiceContract>();
        
        String ENT_TYPE_PHONE_SUPPORT = 'Phone Support';
        Schema.SObjectType objectType = Entitlement.getSObjectType();
        List<String> entFields = new List<String>(objectType.getDescribe().fields.getMap().keySet());
        String soqlStr =
            'SELECT Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Type__c,Order_Service_Item__r.TPH_Quantity__c, ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__c, ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.Arroyo_Subscribed_Asset_Name__c, ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.SubscribedAssetNames__c,Order_Service_Item__r.Order.Is_RWD_Polaris_Quote__c,Order_Service_Item__r.Order.Type,Order_Service_Item__r.Order.Order_Status__c,ContractLineItem.SBQQSC__QuoteLine__r.SubscribedAssetNames__c,Order_Service_Item__r.SBQQ__RequiredBy__c,Order_Service_Item__r.product2.SBQQSC__EntitlementConversion__c,ContractLineItem.SBQQSC__QuoteLine__r.Arroyo_Subscribed_Asset_Name__c,Order_Service_Item__r.Previous_Contract_Line_Items__c,ContractLineItem.SBQQSC__QuoteLine__r.Subscribed_Asset_Name__c,ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.Subscribed_Asset_Name__c,asset.SerialNumber,asset.Program__c,asset.UsageEndDate,asset.serial_number__c,Order_Service_Item__r.SerialNumber__c,Order_Service_Item__r.Quantity,Order_Service_Item__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,Order_Service_Item__r.Product2Id,Order_Service_Item__r.Order.Order_Sub_Type__c,Order_Service_Item__r.SBQQ__QuoteLine__r.Disposition_Reason__c,Order_Service_Item__r.product2.Product_Level__c,Product__r.Product_Type__c, Product__r.Product_Level__c,' +
            'Product__r.Product_Subtype__c,Product__r.License_Category__c,ContractLineItem.SBQQSC__RequiredById__c, Order_Service_Item__r.Upgraded_From__c,Order_Service_Item__r.Product2.Product_Subtype__c, Order_Service_Item__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQSC__ContractLineItem__c,' +
            'Order_Service_Item__r.Order.SBQQ__Quote__c,Order_Service_Item__r.OrderId,Order_Service_Item__r.product2.ProductCode,Order_Service_Item__r.Program__c,ContractLineItem.LineItemNumber, ContractLineItem.SBQQSC__OrderProduct__r.Order.OpportunityId, ContractLineItem.SBQQSC__OrderProduct__r.Order.Opportunity.Name,Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c, Order_Service_Item__r.SBQQ__QuoteLine__c,ContractLineItem.SBQQSC__Product__r.Product_Level__c, ContractLineItem.SBQQSC__Product__r.Product_Type__c,ContractLineItem.SBQQSC__Product__r.Product_Subtype__c,ContractLineItem.SBQQSC__TerminatedDate__c,ContractLineItem.Quantity,ContractLineItem.SBQQSC__RenewalQuantity__c,ContractLineItem.SBQQSC__Quantity__c,ContractLineItem.ServiceContractId,ContractLineItem.ServiceContract.SBQQSC__RenewalQuoted__c,ContractLineItem.SBQQSC__RootId__c,Product__r.Gorefresh_Mark_SW_End_Date__c,Product__r.SBQQSC__EntitlementConversion__c,ContractLineItem.EndDate,Order_Service_Item__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__QuoteLine__r.Disposition_Reason__c,Order_Service_Item__r.product2.License_Subtype__c, Order_Service_Item__r.product2.Product_Type__c, Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c, Order_Service_Item__r.product2.Family,' +
            String.join(entFields, ',') +
            ' FROM Entitlement where Type =: ENT_TYPE_PHONE_SUPPORT  AND (Id IN : lstNewEntitlementIds OR ContractLineItemId IN : lstOldCliIds) ORDER BY Id';
        
        List<Entitlement> entListQuery = Database.query(String.escapeSingleQuotes(soqlStr));
        system.debug('::entListQuery::' + entListQuery.size());
        for (Entitlement objEntitlement : entListQuery) {
            system.debug('::objEntitlement::' + objEntitlement);
            
            if (lstNewEntitlementIds.contains(objEntitlement.Id)) {
                setOrders.add(objEntitlement.Order_Service_Item__r.OrderId);
                setQuoteIds.add(objEntitlement.Order_Service_Item__r.Order.SBQQ__Quote__c);
                mapNewEntIdToEntitlement.put(objEntitlement.Id, objEntitlement);
                setNewEntitlements.add(objEntitlement.Id);
                if (!setNewProducts.contains(objEntitlement?.Order_Service_Item__r?.product2Id))
                    setNewProducts.add(objEntitlement?.Order_Service_Item__r?.product2Id);
            }
            
            if (lstOldCliIds.contains(objEntitlement.ContractLineItemId)) {
                lstOldEntitlement.add(objEntitlement);
                setOldProducts.add(objEntitlement?.Order_Service_Item__r?.product2Id);
                
                if (bypassSplitSKU != null) {
                    if (
                        objEntitlement?.Order_Service_Item__r?.product2Id != null &&
                        bypassSplitSKU.contains(objEntitlement?.Order_Service_Item__r?.product2Id) &&
                        !setOldSplitSKuEntIds.contains(objEntitlement?.Id)
                    ) {
                        setOldSplitSKuEntIds.add(objEntitlement?.Id);
                    }
                }
            }
        }
        
        createLinkEntitlement(
            setOrders,
            setOldProducts,
            setNewProducts,
            mapNewEntIdToEntitlement,
            lstOldEntitlement,
            olCLIConvProdId,
            setNewEntitlements,
            setOldSplitSKuEntIds,
            bypassSplitSKU,
            SCToUpdate
        );
    }
    
    private void createLinkEntitlement(
        Set<String> setOrders,
        Set<Id> setOldProducts,
        Set<Id> setNewProducts,
        Map<String, Entitlement> mapNewEntIdToEntitlement,
        List<Entitlement> lstOldEntitlement,
        Map<string, Id> olCLIConvProdId,
        Set<Id> setNewEntitlements,
        Set<Id> setOldSplitSKuEntIds,
        String bypassSplitSKU,
        Map<Id, ServiceContract> SCToUpdate
    ) {
        Map<String, Polaris_SKU_Mapping_V2__c> mapProductToPolarisMappings = new Map<String, Polaris_SKU_Mapping_V2__c>();
        Map<String, Decimal> mapContractLineToQuantity = new Map<String, Decimal>(); //quantity calculation for Entitlement Links
        Map<String, Decimal> mapOldCLIToQuanity = new Map<String, Decimal>(); //quantity reduction for Old CLI
        Set<Id> setExistingEntitlement = new Set<Id>();
        Set<String> setExistingAssetIds = new Set<String>();
        Map<Id, Id> mapOldCLIToAssetId = new Map<Id, Id>(); //ARY-1068
        if (!setOldProducts.isEmpty() && !setNewProducts.isEmpty()) {
            for (Polaris_SKU_Mapping_V2__c objPolarisSKU : [
                SELECT id, Old_Product__c, Old_Product__r.ProductCode, New_Product__c, New_Product__r.ProductCode, Quantity_Ratio__c
                FROM Polaris_SKU_Mapping_V2__c
                WHERE Quantity_Ratio__c > 1 AND Old_Product__c IN :setOldProducts AND New_Product__c IN :setNewProducts
            ]) {
                mapProductToPolarisMappings.put(objPolarisSKU.Old_Product__c + '-' + objPolarisSKU.New_Product__c, objPolarisSKU);
            }
        }
        system.debug('::setNewEntitlements::' + setNewEntitlements);
        if (!setNewEntitlements.isEmpty()) {
            for (Entitlement_Links__c objEntLinks : [
                SELECT
                Id,
                Previous_Entitlement__r.AssetId,
                Renewed_Entitlement__c,
                Previous_Entitlement__r.Order_Service_Item__r.Product2Id,
                Renewed_Entitlement__r.Order_Service_Item__c,
                Renewed_Entitlement__r.ContractLineItem.SBQQSC__RenewalQuantity__c,
                Previous_Entitlement__c,
                Quantity__c,
                Renewal_Category__c
                FROM Entitlement_Links__c
                WHERE Renewed_Entitlement__c IN :setNewEntitlements OR Previous_Entitlement__c IN :setOldSplitSKuEntIds
            ]) {
                system.debug('::objEntLinks::' + objEntLinks);
                if (!setExistingEntitlement.Contains(objEntLinks.Previous_Entitlement__c)) {
                    setExistingEntitlement.add(objEntLinks.Previous_Entitlement__c);
                }
                if (
                    objEntLinks?.Previous_Entitlement__r?.AssetId != null &&
                    bypassSplitSKU.contains(objEntLinks.Previous_Entitlement__r?.Order_Service_Item__r?.Product2Id) &&
                    !setExistingAssetIds.contains(
                        objEntLinks.Previous_Entitlement__r?.Order_Service_Item__r?.Product2Id + '-' + objEntLinks.Previous_Entitlement__r.AssetId
                    )
                ) {
                    setExistingAssetIds.add(
                        objEntLinks.Previous_Entitlement__r?.Order_Service_Item__r?.Product2Id + '-' + objEntLinks.Previous_Entitlement__r.AssetId
                    );
                }
            }
        }
        List<Entitlement_Links__c> lstUpsertEntitlementLinks = new List<Entitlement_Links__c>();
        String renewalCategory = '';
        String previousratioCLIs = '';
        Map<Id, String> mapoldEntToRenewalCategory = new Map<Id, String>();
        Map<String, String> mapProgramToRenewalCategory = new Map<String, String>{
            'Conversion' => 'Converted',
                'Refresh' => 'Refreshed',
                'Renewing' => 'Renewed'
                };
                    
                    Map<Id, Entitlement> mapIdToupdateOldEntitlement = new Map<Id, Entitlement>();
        Map<Id, ContractLineItem> mapIdToUpdateOldCLI = new Map<Id, ContractLineItem>();
        Map<Id, List<Entitlement>> mapOldCLItoOldEntitlement = new Map<Id, List<Entitlement>>();
        Integer counterTPHRecord = 1;
        for (Entitlement objOldEnt : lstOldEntitlement) {
            for (Entitlement objNewEnt : mapNewEntIdToEntitlement.values()) {
                if (
                    String.isNotBlank(objNewEnt?.Order_Service_Item__r?.Previous_Contract_Line_Items__c) &&
                    setOrders.contains(objNewEnt?.Order_Service_Item__r?.OrderId)
                ) {
                    for (String previousCLI : objNewEnt?.Order_Service_Item__r?.Previous_Contract_Line_Items__c?.trim()?.split(',')) {
                        String previousCLI1 = previousCLI.trim().substring(0, 15);
                        if (previousCLI1.equals(String.valueOf(objOldEnt.ContractLineItemId).substring(0, 15))) {
                            system.debug('::objOldEnt::' + objOldEnt.Id);
                            system.debug('::objNewEnt::' + objNewEnt.Id);
                            
                            if (
                                objNewEnt?.Order_Service_Item__r?.Order?.Type == 'Revenue' &&
                                String.isBlank(objNewEnt?.Order_Service_Item__r?.Order?.Order_Sub_type__c) &&
                                String.isNotBlank(objNewEnt?.Order_Service_Item__r?.Program__c)
                            ) {
                                renewalCategory = mapProgramToRenewalCategory.containsKey(objNewEnt?.Order_Service_Item__r?.Program__c) &&
                                    mapProgramToRenewalCategory.get(objNewEnt?.Order_Service_Item__r?.Program__c) != null
                                    ? mapProgramToRenewalCategory.get(objNewEnt?.Order_Service_Item__r?.Program__c)
                                    : objNewEnt?.Order_Service_Item__r?.Program__c;
                                mapoldEntToRenewalCategory.put(objOldEnt.Id, renewalCategory);
                            } else {
                                if (String.isNotBlank(objNewEnt?.Order_Service_Item__r?.SBQQ__QuoteLine__r?.Disposition_Reason__c)) {
                                    renewalCategory = mapProgramToRenewalCategory.containsKey(
                                        objNewEnt?.Order_Service_Item__r?.SBQQ__QuoteLine__r?.Disposition_Reason__c
                                    ) && mapProgramToRenewalCategory.get(objNewEnt?.Order_Service_Item__r?.SBQQ__QuoteLine__r?.Disposition_Reason__c) != null
                                        ? mapProgramToRenewalCategory.get(objNewEnt?.Order_Service_Item__r?.SBQQ__QuoteLine__r?.Disposition_Reason__c)
                                        : objNewEnt?.Order_Service_Item__r?.SBQQ__QuoteLine__r?.Disposition_Reason__c != 'None'
                                            ? objNewEnt?.Order_Service_Item__r?.SBQQ__QuoteLine__r?.Disposition_Reason__c
                                            : renewalCategory;
                                    mapoldEntToRenewalCategory.put(objOldEnt.Id, renewalCategory);
                                }
                            }
                            if (
                                'One per unit'.equalsIgnoreCase(objNewEnt?.Order_Service_Item__r?.Product2?.SBQQSC__EntitlementConversion__c) &&
                                ('One per unit'.equalsIgnoreCase(objOldEnt?.Order_Service_Item__r?.Product2?.SBQQSC__EntitlementConversion__c) ||
                                 ('one per quote line'.equalsIgnoreCase(objOldEnt?.Order_Service_Item__r?.Product2?.SBQQSC__EntitlementConversion__c) &&
                                  objOldEnt?.Order_Service_Item__r?.Product2?.Product_Subtype__c == 'GO CNV'))
                            ) {
                                if (
                                    String.isNotBlank(objOldEnt.AssetId) &&
                                    ((String.isNotBlank(objNewEnt.AssetId) && objNewEnt.AssetId == objOldEnt.AssetId) ||
                                     (String.isNotBlank(objNewEnt?.Order_Service_Item__r?.Upgraded_From__c) &&
                                      objNewEnt.Order_Service_Item__r.Upgraded_From__c.contains(objOldEnt.Asset.SerialNumber)))
                                ) {
                                    if (!mapContractLineToQuantity.containsKey(objOldEnt?.ContractLineItemId)) {
                                        mapContractLineToQuantity.put(objOldEnt.ContractLineItemId, 1);
                                    } else {
                                        mapContractLineToQuantity.put(objOldEnt.ContractLineItemId, mapContractLineToQuantity.get(objOldEnt.ContractLineItemId) + 1);
                                        system.debug('::mapContractLineToQuantity::' + mapContractLineToQuantity);
                                    }
                                    
                                    lstUpsertEntitlementLinks.add(
                                        new Entitlement_Links__c(
                                            Renewed_Entitlement__c = objNewEnt.Id,
                                            Previous_Entitlement__c = objOldEnt.Id,
                                            Quantity__c = 1,
                                            Renewal_Category__c = renewalCategory
                                        )
                                    );
                                    setExistingEntitlement.add(objOldEnt.Id);
                                    if (objNewEnt?.Order_Service_Item__r?.Program__c != 'Refresh') {
                                        if (!setExistingAssetIds.contains(objOldEnt?.Order_Service_Item__r.Product2Id + '-' + objOldEnt.AssetId)) {
                                            mapOldCLIToQuanity.put(
                                                objOldEnt.ContractLineItemId,
                                                (objOldEnt?.ContractLineItem?.SBQQSC__RenewalQuantity__c > 0.00)
                                                ? (objOldEnt?.ContractLineItem?.SBQQSC__RenewalQuantity__c - mapContractLineToQuantity?.get(objOldEnt?.ContractLineItemId))
                                                : 0.00
                                            );
                                            if (bypassSplitSKU.contains(objOldEnt?.Order_Service_Item__r.Product2Id)) {
                                                setExistingAssetIds.add(objOldEnt?.Order_Service_Item__r.Product2Id + '-' + objOldEnt.AssetId);
                                            }
                                        }
                                        if (!mapOldCLItoOldEntitlement.containsKey(objOldEnt.ContractLineItemId)) {
                                            mapOldCLItoOldEntitlement.put(objOldEnt.ContractLineItemId, new List<Entitlement>{ objOldEnt });
                                        } else {
                                            mapOldCLItoOldEntitlement.get(objOldEnt.ContractLineItemId).add(objOldEnt);
                                        }
                                    }
                                }   else {
                                    if(String.isBlank(objOldEnt.AssetId) && (String.isBlank(objNewEnt.AssetId))){
                                        lstUpsertEntitlementLinks.add(new Entitlement_Links__c(
                                            Renewed_Entitlement__c = objNewEnt.Id, 
                                            Previous_Entitlement__c = objOldEnt.Id, 
                                            Quantity__c = 1, 
                                            Renewal_Category__c = renewalCategory));
                                        
                                    }
                                    
                                    
                                }            
                            } else if (
                                'One per unit'.equalsIgnoreCase(objNewEnt?.Order_Service_Item__r?.Product2?.SBQQSC__EntitlementConversion__c) &&
                                'One per quote line'.equalsIgnoreCase(objOldEnt?.Order_Service_Item__r?.Product2?.SBQQSC__EntitlementConversion__c)
                            ) {
                                setExistingEntitlement.add(objOldEnt.Id);
                                lstUpsertEntitlementLinks.add(
                                    new Entitlement_Links__c(
                                        Renewed_Entitlement__c = objNewEnt.Id,
                                        Previous_Entitlement__c = objOldEnt.Id,
                                        Quantity__c = objOldEnt?.Quantity__c != null ? objOldEnt?.Quantity__c : objOldEnt?.Order_Service_Item__r?.Quantity,
                                        Renewal_Category__c = renewalCategory
                                    )
                                );
                                if (!mapOldCLIToQuanity.containsKey(objOldEnt.ContractLineItemId) && objNewEnt?.Order_Service_Item__r?.Program__c != 'Refresh') {
                                    mapOldCLIToQuanity.put(objOldEnt.ContractLineItemId, 0.00);
                                    if (!mapOldCLItoOldEntitlement.containsKey(objOldEnt.ContractLineItemId)) {
                                        mapOldCLItoOldEntitlement.put(objOldEnt.ContractLineItemId, new List<Entitlement>{ objOldEnt });
                                    } else {
                                        mapOldCLItoOldEntitlement.get(objOldEnt.ContractLineItemId).add(objOldEnt);
                                    }
                                }
                            } else if (
                                'One per quote line'.equalsIgnoreCase(objNewEnt?.Order_Service_Item__r?.Product2?.SBQQSC__EntitlementConversion__c) &&
                                'One per quote line'.equalsIgnoreCase(objOldEnt?.Order_Service_Item__r?.Product2?.SBQQSC__EntitlementConversion__c) &&
                                objOldEnt?.Order_Service_Item__r?.Product2?.Product_Subtype__c != 'GO CNV'
                            ) {
                                if (!mapOldCLItoOldEntitlement.containsKey(objOldEnt.ContractLineItemId)) {
                                    mapOldCLItoOldEntitlement.put(objOldEnt.ContractLineItemId, new List<Entitlement>{ objOldEnt });
                                } else {
                                    mapOldCLItoOldEntitlement.get(objOldEnt.ContractLineItemId).add(objOldEnt);
                                }
                                
                                if (
                                    (!objNewEnt?.Order_Service_Item__r?.Order.Is_RWD_Polaris_Quote__c &&
                                     !objOldEnt?.Order_Service_Item__r?.Order.Is_RWD_Polaris_Quote__c) ||
                                    (objNewEnt?.Order_Service_Item__r?.Order.Is_RWD_Polaris_Quote__c && objOldEnt?.Order_Service_Item__r?.Order.Is_RWD_Polaris_Quote__c)
                                ) {
                                    setExistingEntitlement.add(objOldEnt.Id);
                                    lstUpsertEntitlementLinks.add(
                                        new Entitlement_Links__c(
                                            Renewed_Entitlement__c = objNewEnt.Id,
                                            Previous_Entitlement__c = objOldEnt.Id,
                                            Quantity__c = objNewEnt?.Quantity__c != null ? objNewEnt?.Quantity__c : objNewEnt?.Order_Service_Item__r?.Quantity,
                                            Renewal_Category__c = renewalCategory
                                        )
                                    );
                                    if (!mapOldCLIToQuanity.containsKey(objOldEnt.ContractLineItemId)) {
                                        mapOldCLIToQuanity.put(
                                            objOldEnt.ContractLineItemId,
                                            (objOldEnt?.ContractLineItem?.SBQQSC__RenewalQuantity__c > 0.00)
                                            ? objOldEnt?.ContractLineItem?.SBQQSC__RenewalQuantity__c - objNewEnt?.ContractLineItem?.SBQQSC__RenewalQuantity__c
                                            : 0.00
                                        );
                                    }
                                } else if (
                                    objNewEnt?.Order_Service_Item__r?.Order?.Is_RWD_Polaris_Quote__c &&
                                    !objOldEnt?.Order_Service_Item__r?.Order?.Is_RWD_Polaris_Quote__c
                                ) {
                                    previousratioCLIs = objNewEnt.Order_Service_Item__r?.Previous_Contract_Line_Items__c;
                                    Id newProdId = objNewEnt.Order_Service_Item__r?.Program__c == 'Replaced' &&
                                        previousratioCLIs != null &&
                                        olCLIConvProdId.containsKey(previousratioCLIs.trim())
                                        ? olCLIConvProdId.get(previousratioCLIs.trim())
                                        : objNewEnt?.Order_Service_Item__r?.Product2Id;
                                    if (
                                        (objNewEnt?.Order_Service_Item__r?.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c == 'Renewal+Expansion' ||
                                         objNewEnt?.Order_Service_Item__r?.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c == 'Renewal') &&
                                        mapProductToPolarisMappings.containsKey(objOldEnt?.Order_Service_Item__r?.Product2Id + '-' + newProdId)
                                    ) {
                                        Decimal ratio = (objNewEnt?.Order_Service_Item__r?.Quantity /
                                                         mapProductToPolarisMappings.get(objOldEnt?.Order_Service_Item__r?.Product2Id + '-' + newProdId).Quantity_Ratio__c);
                                        setExistingEntitlement.add(objOldEnt.Id);
                                        lstUpsertEntitlementLinks.add(
                                            new Entitlement_Links__c(
                                                Renewed_Entitlement__c = objNewEnt.Id,
                                                Previous_Entitlement__c = objOldEnt.Id,
                                                Quantity__c = ratio,
                                                Renewal_Category__c = renewalCategory
                                            )
                                        );
                                        if (!mapOldCLIToQuanity.containsKey(objOldEnt.ContractLineItemId) && objNewEnt?.Order_Service_Item__r?.Program__c != 'Refresh') {
                                            mapOldCLIToQuanity.put(
                                                objOldEnt.ContractLineItemId,
                                                objOldEnt?.ContractLineItem?.SBQQSC__RenewalQuantity__c > 0.00
                                                ? objOldEnt?.ContractLineItem?.SBQQSC__RenewalQuantity__c - ratio
                                                : 0.00
                                            );
                                        }
                                    } else {
                                        setExistingEntitlement.add(objOldEnt.Id);
                                        lstUpsertEntitlementLinks.add(
                                            new Entitlement_Links__c(
                                                Renewed_Entitlement__c = objNewEnt.Id,
                                                Previous_Entitlement__c = objOldEnt.Id,
                                                Quantity__c = objNewEnt?.Quantity__c != null ? objNewEnt?.Quantity__c : objNewEnt?.Order_Service_Item__r?.Quantity,
                                                Renewal_Category__c = renewalCategory
                                            )
                                        );
                                        if (!mapOldCLIToQuanity.containsKey(objOldEnt.ContractLineItemId) && objNewEnt?.Order_Service_Item__r?.Program__c != 'Refresh') {
                                            mapOldCLIToQuanity.put(
                                                objOldEnt.ContractLineItemId,
                                                objOldEnt?.ContractLineItem?.SBQQSC__RenewalQuantity__c > 0.00
                                                ? objOldEnt?.ContractLineItem?.SBQQSC__RenewalQuantity__c - objNewEnt?.ContractLineItem?.SBQQSC__RenewalQuantity__c
                                                : 0.00
                                            );
                                        }
                                    }
                                }
                            } else if (
                                'One per quote line'.equalsIgnoreCase(objNewEnt?.Order_Service_Item__r?.Product2?.SBQQSC__EntitlementConversion__c) &&
                                'One per unit'.equalsIgnoreCase(objOldEnt?.Order_Service_Item__r?.Product2?.SBQQSC__EntitlementConversion__c) ||
                                objOldEnt?.Order_Service_Item__r?.Product2?.Product_Subtype__c == 'GO CNV'
                            ) {
                                String subScribedAssetNumbers = '';
                                if (!mapOldCLItoOldEntitlement.containsKey(objOldEnt.ContractLineItemId)) {
                                    mapOldCLItoOldEntitlement.put(objOldEnt.ContractLineItemId, new List<Entitlement>{ objOldEnt });
                                } else {
                                    mapOldCLItoOldEntitlement.get(objOldEnt.ContractLineItemId).add(objOldEnt);
                                }
                                
                                if (String.isNotBlank(objNewEnt?.Order_Service_Item__r?.SerialNumber__c)) {
                                    subScribedAssetNumbers = objNewEnt?.Order_Service_Item__r?.SerialNumber__c;
                                } else if (String.isNotBlank(objNewEnt?.ContractLineItem?.SBQQSC__QuoteLine__r?.Arroyo_Subscribed_Asset_Name__c)) {
                                    subScribedAssetNumbers = objNewEnt?.ContractLineItem?.SBQQSC__QuoteLine__r?.Arroyo_Subscribed_Asset_Name__c;
                                } else if (String.isNotBlank(objNewEnt?.ContractLineItem?.SBQQSC__QuoteLine__r?.SubscribedAssetNames__c)) {
                                    subScribedAssetNumbers = objNewEnt?.ContractLineItem?.SBQQSC__QuoteLine__r?.SubscribedAssetNames__c;
                                } else if (objNewEnt?.ContractLineItem?.SBQQSC__QuoteLine__r?.SBQQ__RequiredBy__c != null) {
                                    if (String.isNotBlank(objNewEnt?.ContractLineItem?.SBQQSC__QuoteLine__r?.SBQQ__RequiredBy__r?.Arroyo_Subscribed_Asset_Name__c)) {
                                        subScribedAssetNumbers = objNewEnt?.ContractLineItem?.SBQQSC__QuoteLine__r?.SBQQ__RequiredBy__r?.Arroyo_Subscribed_Asset_Name__c;
                                    } else if (String.isNotBlank(objNewEnt?.ContractLineItem?.SBQQSC__QuoteLine__r?.SBQQ__RequiredBy__r?.SubscribedAssetNames__c)) {
                                        subScribedAssetNumbers = objNewEnt?.ContractLineItem?.SBQQSC__QuoteLine__r?.SBQQ__RequiredBy__r?.SubscribedAssetNames__c;
                                    }
                                }
                                system.debug('::subScribedAssetNumbers::' + subScribedAssetNumbers);
                                if (String.isNotBlank(subScribedAssetNumbers) && String.isNotBlank(objOldEnt?.AssetId)) {
                                    for (String strSubscribedAsset : subScribedAssetNumbers?.trim()?.split(',')) {
                                        if (String.isNotBlank(objOldEnt?.AssetId) && strSubscribedAsset.trim() == objOldEnt?.Asset.SerialNumber.trim()) {
                                            if (!mapContractLineToQuantity.containsKey(objOldEnt?.ContractLineItemId)) {
                                                mapContractLineToQuantity.put(objOldEnt.ContractLineItemId, 1);
                                            } else {
                                                mapContractLineToQuantity.put(objOldEnt.ContractLineItemId, mapContractLineToQuantity.get(objOldEnt.ContractLineItemId) + 1);
                                                system.debug('::mapContractLineToQuantity::' + mapContractLineToQuantity);
                                            }
                                            
                                            lstUpsertEntitlementLinks.add(
                                                new Entitlement_Links__c(
                                                    Renewed_Entitlement__c = objNewEnt.Id,
                                                    Previous_Entitlement__c = objOldEnt.Id,
                                                    Quantity__c = 1.00,
                                                    Renewal_Category__c = renewalCategory
                                                )
                                            );
                                            setExistingEntitlement.add(objOldEnt.Id);
                                            if (
                                                objNewEnt?.Order_Service_Item__r?.Program__c != 'Refresh' &&
                                                !mapContractLineToQuantity.isEmpty() &&
                                                mapContractLineToQuantity.containsKey(objOldEnt.ContractLineItemId)
                                            ) {
                                                if (!setExistingAssetIds.contains(objOldEnt?.Order_Service_Item__r.Product2Id + '-' + objOldEnt.AssetId)) {
                                                    mapOldCLIToQuanity.put(
                                                        objOldEnt.ContractLineItemId,
                                                        objOldEnt?.ContractLineItem?.SBQQSC__RenewalQuantity__c > 0.00
                                                        ? objOldEnt?.ContractLineItem?.SBQQSC__RenewalQuantity__c - mapContractLineToQuantity.get(objOldEnt.ContractLineItemId)
                                                        : 0.00
                                                    );
                                                    if (bypassSplitSKU.contains(objOldEnt?.Order_Service_Item__r.Product2Id)) {
                                                        setExistingAssetIds.add(objOldEnt?.Order_Service_Item__r.Product2Id + '-' + objOldEnt.AssetId);
                                                    }
                                                }
                                            }
                                        } //if End - AssetId
                                    } //For loop SubscribedAsset
                                } else if (
                                    (String.isBlank(subScribedAssetNumbers) && (String.isBlank(objOldEnt?.AssetId) || String.isNotBlank(objOldEnt?.AssetId))) ||
                                    (String.isNotBlank(subScribedAssetNumbers) && String.isBlank(objOldEnt?.AssetId))
                                ) {
                                    if (
                                        objNewEnt?.Order_Service_Item__r?.Product2?.Family == 'Third Party License' ||
                                        objOldEnt?.Order_Service_Item__r?.Product2?.Family == 'Third Party License' ||
                                        objNewEnt?.Order_Service_Item__r?.Product2?.Product_Type__c == '3rd Party Hardware' ||
                                        objOldEnt?.Order_Service_Item__r?.Product2?.Product_Type__c == '3rd Party Hardware'
                                    ) {
                                        if (!setExistingEntitlement.contains(objOldEnt.Id)) {
                                            if (
                                                objNewEnt?.Order_Service_Item__r?.TPH_Quantity__c != null &&
                                                counterTPHRecord <= Integer.valueOf(objNewEnt?.Order_Service_Item__r?.TPH_Quantity__c)
                                            ) {
                                                lstUpsertEntitlementLinks.add(
                                                    new Entitlement_Links__c(
                                                        Renewed_Entitlement__c = objNewEnt.Id,
                                                        Previous_Entitlement__c = objOldEnt.Id,
                                                        Quantity__c = 1,
                                                        Renewal_Category__c = renewalCategory
                                                    )
                                                );
                                                setExistingEntitlement.add(objOldEnt.Id);
                                                
                                                if (objNewEnt?.Order_Service_Item__r?.Program__c != 'Refresh') {
                                                    mapOldCLIToQuanity.put(
                                                        objOldEnt.ContractLineItemId,
                                                        objOldEnt?.ContractLineItem?.SBQQSC__RenewalQuantity__c > 0.00
                                                        ? objOldEnt?.ContractLineItem?.SBQQSC__RenewalQuantity__c -
                                                        Decimal.ValueOf(objNewEnt?.Order_Service_Item__r?.TPH_Quantity__c)
                                                        : 0.00
                                                    );
                                                }
                                                counterTPHRecord++;
                                            }
                                        }
                                    } else if (
                                        objOldEnt?.Order_Service_Item__r?.Product2?.Product_Level__c == 'Standalone Software Addon' ||
                                        objOldEnt?.Order_Service_Item__r?.Product2?.Product_Level__c == 'SaaS Software Addon' ||
                                        objOldEnt?.Order_Service_Item__r?.Product2?.License_Subtype__c == 'Add-On'
                                    ) {
                                        if (
                                            !mapContractLineToQuantity.containsKey(objOldEnt?.ContractLineItemId) &&
                                            objNewEnt?.Order_Service_Item__r?.Program__c != 'Refresh'
                                        ) {
                                            mapContractLineToQuantity.put(objOldEnt.ContractLineItemId, 0.00);
                                            lstUpsertEntitlementLinks.add(
                                                new Entitlement_Links__c(
                                                    Renewed_Entitlement__c = objNewEnt.Id,
                                                    Previous_Entitlement__c = objOldEnt.Id,
                                                    Quantity__c = objNewEnt?.Quantity__c != null ? objNewEnt?.Quantity__c : objNewEnt?.Order_Service_Item__r?.Quantity,
                                                    Renewal_Category__c = renewalCategory
                                                )
                                            );
                                            setExistingEntitlement.add(objOldEnt.Id);
                                        }
                                    } else {
                                        system.debug(':::objOldEnt?.ContractLineItemId:::' + objOldEnt?.ContractLineItemId);
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            
        }
        try{
            if (!lstUpsertEntitlementLinks.isEmpty()) {
                insert lstUpsertEntitlementLinks;
            }
        }catch (exception ex) {
            UtilityClass.logException(ex, 'EntitlementLinkCreationClass', 'createEntitlementLink', 'Entitlement Link', null);
        }
        
        
    }
    
    
}