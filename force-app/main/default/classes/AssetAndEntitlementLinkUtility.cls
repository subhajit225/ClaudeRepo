//  *************************************************************************
    //  Requirements
    //  1. RWD-390 : Method to insert the values of old entitlement and new entitlement 
    //  2. RWD-385 : Identify Free HW Eligible Lines
    //
    //    Test Class : AssetAndEntitlementLinkUtility_Test
    //    Requirements developed by - Jayaraman Iyer
    //    Last Modified by - Jayaraman Iyer
    //    Last Modified - 03/25/2022
    //  *************************************************************************
    public class AssetAndEntitlementLinkUtility {

        /**
          *Method Name : insertEntLinksAndUpdateEligForFreeHW
         * Description : RWD-390 : Method to insert the values of old entitlement and new entitlement
         * Created By  : Jayaraman Iyer
         * Date : 01/13/2022
         **/
        
       
        public static void insertEntLinksAndUpdateEligForFreeHW(List<Entitlement> entNewList) {

            Map<Id, List<Entitlement>> oldOppIdVsOldEntListMap = new Map<Id, List<Entitlement>>();
            Map<Id, Id> oldConLineItemVsNewConLineItemMap = new Map<Id, Id>();
            List<String> oldcliId = new List<String>();
            
            Map<Id, Entitlement_Links__c> newEntIdVsEntLinkObjMap = new Map<Id,Entitlement_Links__c>();

            Map<Id, Entitlement> oldConLineItemVsNewEntMap = new Map<Id, Entitlement>();
            Map<Id, List<Id>> mapSCIdVsListCLIId = new Map<Id, List<Id>>(); // RWD-1375 
            Set<Id> contractLineItemIds = new Set<Id>(); // RWD-1375    
            Map<Id, Entitlement> mapCLIIdVsEntitlement = new Map<Id, Entitlement>(); // RWD-1375
            Map<Id,Entitlement> mapdupEmtitlemnt = new Map<Id,Entitlement>(); // RWD-1375
            Map<Entitlement,List<String>> mapEmtitlemnt = new Map<Entitlement,List<String>>(); // RWD-1375
            Map<Entitlement, List<Id>> mapNewEntitlementWithListOldCLI = new Map<Entitlement, List<Id>>(); // RWD-1375
            Map<String,Entitlement_Links__c> maptocheckDuplicate = new Map<String,Entitlement_Links__c>();
            List<Entitlement> lstentdup = [Select Id,OldContractLineItem__c,Product__c,ContractLineItemId,ContractLineItem.SBQQSC__QuoteLine__r.CCLI__c,ContractLineItem.SBQQSC__Product__r.SBQQSC__EntitlementConversion__c,AssetId,ContractLineItem.SBQQSC__Product__c,Product__r.SBQQSC__EntitlementConversion__c,ContractLineItem.SBQQSC__Product__r.Product_Type__c, ContractLineItem.SBQQSC__Product__r.Product_Level__c,ContractLineItem.SBQQSC__Product__r.After_Conversion_Product_Level__c 
            FROM Entitlement WHERE Id IN :entNewList];
            System.debug('entNewList -- ' + entNewList);
            System.debug('lstentdup -- ' + lstentdup);
            for(Entitlement entNewObj : entNewList) {
                if(entNewObj.OldContractLineItem__c != null /* && entNewObj.Subscription_Term__c >= 36 */) {

                    oldConLineItemVsNewConLineItemMap.put(entNewObj.OldContractLineItem__c, entNewObj.ContractLineItemId);
                    oldcliId.add(entNewObj.OldContractLineItem__c);

                    oldConLineItemVsNewEntMap.put(entNewObj.OldContractLineItem__c, entNewObj);
                }
                // RWD-1375 
                if (entNewObj.ContractLineItemId != null) { 
                    if (mapSCIdVsListCLIId.containsKey(entNewObj.ServiceContractId)) {  
                        mapSCIdVsListCLIId.get(entNewObj.ServiceContractId).add(entNewObj.ContractLineItemId);  
                    } else {    
                        mapSCIdVsListCLIId.put(entNewObj.ServiceContractId, new List<Id>{entNewObj.ContractLineItemId});    
                    }   
                    contractLineItemIds.add(entNewObj.ContractLineItemId);  
                }   
                // RWD-1375 madhura Start
               
            }
                 for(Entitlement en : lstentdup){
                     if('One per quote line'.equalsIgnoreCase(en.ContractLineItem.SBQQSC__Product__r.SBQQSC__EntitlementConversion__c)){
                     System.debug('show whats req>'+en.ContractLineItem.SBQQSC__QuoteLine__r.CCLI__c);
                    String cli = en.ContractLineItem.SBQQSC__QuoteLine__r.CCLI__c;
                    List<String> clilst = new List<String>();
                    if(String.isNotBlank(cli)){
                    clilst = cli.split(',');
                    for(String st : clilst){
                        oldcliId.add(st);
                    }
                    
                    System.debug('show oldcliId'+oldcliId);
                    
                    }
                    clilst.add(en.OldContractLineItem__c);
                     mapEmtitlemnt.put(en,clilst);
                     
                    }
                      System.debug('mapEmtitlemnt'+mapEmtitlemnt);
                }//madhura End
            System.debug('mapdupEmtitlemnt222'+mapEmtitlemnt);
            
            
            List<Entitlement> oldEntList = new List<Entitlement>();
            Map<String,Set<String>> oldConLineItemVsOldEntIdMap = new Map<String,Set<String>>();
            Map<String,String> oldCnlnVSOldEnt = new Map<String,String>();
            Set<String> strent = new Set<String>();
            if(!oldConLineItemVsNewConLineItemMap.isEmpty()) {
    /* 
                oldEntList = [SELECT Id
                                   , ContractLineItemId
                                   , Name
                                FROM Entitlement
                               WHERE ContractLineItemId IN : oldConLineItemVsNewConLineItemMap.keySet()]; */


                oldEntList = [SELECT Id
                           , ContractLineItemId
                           , ServiceContract.SBQQSC__RenewalOpportunity__c
                           , ServiceContract.SBQQSC__Opportunity__c
                           , Product__c
                           , Product__r.Product_Subtype__c
                           , AssetId
                           , Product__r.Product_Level__c
                           ,Product__r.SBQQSC__EntitlementConversion__c
                         FROM Entitlement
                         WHERE ContractLineItemId IN : oldcliId];
                                
            } else {

                oldEntList.add(new Entitlement());
            }
            System.debug('oldEntList -- ' + oldEntList);

            if(!oldEntList.isEmpty()) {

                for(Entitlement oldEntObj : oldEntList) {
                    
                    System.debug('show old ent'+oldEntObj);
                    //for multiple ent under same CLI
                    if(oldConLineItemVsOldEntIdMap.containsKey(oldEntObj.ContractLineItemId)){
                        oldConLineItemVsOldEntIdMap.get(oldEntObj.ContractLineItemId).add(oldEntObj.Id);
                        System.debug('Inside if of set'+oldConLineItemVsOldEntIdMap);
                    }else{
                        oldConLineItemVsOldEntIdMap.put(oldEntObj.ContractLineItemId, new Set<String>{oldEntObj.Id});
                        System.debug('Inside else of set'+oldConLineItemVsOldEntIdMap);
                    
                    }
                    
                    //for multiple entitlement with diff assets
                    oldCnlnVSOldEnt.put(oldEntObj.ContractLineItemId+':'+oldEntObj.AssetId,oldEntObj.Id);
                    //System.debug('oldConLineItemVsOldEntIdMap>>>>>'+oldCnlnVSOldEnt);

                    if(!oldConLineItemVsNewEntMap.isEmpty() && oldConLineItemVsNewEntMap.containsKey(oldEntObj.ContractLineItemId) && oldConLineItemVsNewEntMap.get(oldEntObj.ContractLineItemId).Subscription_Term__c >= 36) {

                        List<Entitlement> entTempList = oldOppIdVsOldEntListMap.get(oldEntObj.ServiceContract.SBQQSC__Opportunity__c);
                        if(entTempList == null) entTempList = new List<Entitlement>();

                        entTempList.add(oldEntObj);
                        oldOppIdVsOldEntListMap.put(oldEntObj.ServiceContract.SBQQSC__Opportunity__c, entTempList);
                    }
            }
        }   
            
            System.debug('oldConLineItemVsOldEntIdMap===='+oldConLineItemVsOldEntIdMap);
            System.debug('oldCnlnVSOldEnt===='+oldCnlnVSOldEnt);
            List<Entitlement_Links__c> lstEntitlementLinks = new List<Entitlement_Links__c>();
            for(Entitlement newEntObj : lstentdup) {
                if((newEntObj.ContractLineItem.SBQQSC__Product__r.Product_Type__c!= null && newEntObj.ContractLineItem.SBQQSC__Product__r.Product_Type__c == 'HW Support') && (newEntObj.ContractLineItem.SBQQSC__Product__r.Product_Level__c!= null && newEntObj.ContractLineItem.SBQQSC__Product__r.Product_Level__c == 'Support')){
                    
                String str =oldCnlnVSOldEnt.get(newEntObj.OldContractLineItem__c+':'+newEntObj.AssetId);
                
                System.debug('str'+str);
                if(String.isNotBlank(str)) {

                    String externalKey = str + ':' + newEntObj.Id;
                    System.debug('externalKey -- ' + externalKey);
                    Entitlement_Links__c entlnk = new Entitlement_Links__c();
                    entlnk.Previous_Entitlement__c = str;
                     entlnk.Renewed_Entitlement__c = newEntObj.Id;
                     entlnk.External_Key__c = externalKey;
                    if(maptocheckDuplicate.isEmpty() ||  !maptocheckDuplicate.containskey(externalKey)){
                                System.debug('Check dups1>'+maptocheckDuplicate);
                                maptocheckDuplicate.put(externalKey,entlnk);
                                lstEntitlementLinks.add(entlnk);
                                System.debug('show rec1>'+entlnk);
                                System.debug('show lst1>'+lstEntitlementLinks);
                            }
               }
            
            }
            }
            /*** RWD-1375 Starts ***/
            
            System.debug('mapEmtitlemnt'+mapEmtitlemnt);
            if (!mapEmtitlemnt.isEmpty()) {
                
                //for (Entitlement entitlement : mapNewEntitlementWithListOldCLI.keySet()) {
                for (Entitlement entitlement : mapEmtitlemnt.keySet()) {
                    System.debug('entitlementshow>>'+entitlement);
                    System.debug('show assetId'+entitlement.AssetId);
                    String assetId = entitlement.AssetId;
                    for (Id oldCLI : mapEmtitlemnt.get(entitlement)) {
                        System.debug('oldCLI>>MAD>>'+oldCLI);
                        if((entitlement.ContractLineItem.SBQQSC__Product__r.Product_Type__c!= null && entitlement.ContractLineItem.SBQQSC__Product__r.Product_Type__c != 'HW Support') && (entitlement.ContractLineItem.SBQQSC__Product__r.Product_Level__c!= null && entitlement.ContractLineItem.SBQQSC__Product__r.Product_Level__c != 'Support')){
                         System.debug('oldConLineItemVsOldEntIdMap.get(oldCLI)'+oldConLineItemVsOldEntIdMap.get(oldCLI));
                         Set<String> tempStr1 = new Set<String>();
                         if(oldConLineItemVsOldEntIdMap.get(oldCLI) != null) {
                            tempStr1 = oldConLineItemVsOldEntIdMap.get(oldCLI);
                         }
                    for(String str : tempStr1){
                    System.debug('oldCLI>>MAD>>'+str);
                            String externalKey = str + ':' + entitlement.Id;
                            System.debug('externalKey -- ' + externalKey);

                            Entitlement_Links__c entitlementLinkRecord = new Entitlement_Links__c();
                            entitlementLinkRecord.Previous_Entitlement__c = str;
                            entitlementLinkRecord.Renewed_Entitlement__c = entitlement.Id;
                            entitlementLinkRecord.External_Key__c = externalKey;
                            System.debug('maptocheckDuplicate'+maptocheckDuplicate);
                            if(maptocheckDuplicate.isEmpty() ||  !maptocheckDuplicate.containskey(externalKey)){
                                System.debug('Check dups>'+maptocheckDuplicate);
                                maptocheckDuplicate.put(externalKey,entitlementLinkRecord);
                                lstEntitlementLinks.add(entitlementLinkRecord);
                                System.debug('show rec>'+entitlementLinkRecord);
                                System.debug('show lst>'+lstEntitlementLinks);
                            }
                        }
                       }
                    }

                }
            }
            List<Entitlement_Links__c> lstEntitlementLinksToInsert = new List<Entitlement_Links__c>();
            if (!newEntIdVsEntLinkObjMap.isEmpty()) {
                lstEntitlementLinksToInsert.addAll(newEntIdVsEntLinkObjMap.values());
            }
            if (!lstEntitlementLinks.isEmpty()) {
                lstEntitlementLinksToInsert.addAll(lstEntitlementLinks);
            }
            if (!lstEntitlementLinksToInsert.isEmpty()) {
                try{
                    //Upsert Entitlement Links using external key.
                    Database.UpsertResult[] entLinksToResultList = Database.upsert(lstEntitlementLinksToInsert, Entitlement_Links__c.External_Key__c, false);

                    System.debug('entLinksToResultList====' + entLinksToResultList);
                    
                } catch (Exception dmlException) {

                    System.debug('dmlException -- ' + dmlException);
                }
            }
            /*** RWD-1375 Ends ***/

            // RWD-385 : Jayaraman Iyer: Call method to set Eligible for free HW
           /* List<Asset> assetToUpdateList = updateEligibleForFreeHW(oldOppIdVsOldEntListMap);
               
            if(!assetToUpdateList.isEmpty()) {

                try{
                  
                    AssetTriggerHelper.isUpdatedFromSystem = true;
                    update assetToUpdateList;
                    System.debug('after update assetToUpdateList====' + assetToUpdateList);

                } catch (Exception dmlException) {

                    System.debug('dmlException -- ' + dmlException);
                }
            }*/
        }

        /**
        * Method Name : updateEligibleForFreeHW
        * Description : RWD-385 : Identify Free HW Eligible Lines
        * Created By  : Jayaraman Iyer
        * Date : 01/13/2022
        * Update: 12/12/2022 - Commenting this method as the place where it is called was commented already
        **/
        
        /* 
        public static List<Asset> updateEligibleForFreeHW(Map<Id, List<Entitlement>> oldOppIdVsOldEntListMap) {

            Map<String, Asset> assetIdVsAssetObjMap = new Map<String, Asset>();

            if(!oldOppIdVsOldEntListMap.isEmpty()) {

                for(Id oppId : oldOppIdVsOldEntListMap.keySet()) {

                    List<Entitlement> oldEntList = oldOppIdVsOldEntListMap.get(oppId);

                    if(!oldEntList.isEmpty() && oldEntList != null) {

                        for(Entitlement oldEntObj : oldEntList) {

                           if(oldEntObj.Product__c != null && (oldEntObj.Product__r.Product_Subtype__c != null && String.isNotBlank(oldEntObj.Product__r.Product_Subtype__c)) && (
                                oldEntObj.Product__r.Product_Subtype__c.equalsIgnoreCase('GO') ||
                                oldEntObj.Product__r.Product_Subtype__c.equalsIgnoreCase('Saas Cloud'))
                        
                            )  {
                                    if(String.isNotBlank(oldEntObj.Product__r.Product_Level__c)){

                                        continue;
                                    } else {

                                        assetIdVsAssetObjMap.put(oldEntObj.AssetId , new Asset(Id = oldEntObj.AssetId
                                        , Eligible_for_Free_HW__c = true, Justification_for_HW_Eligibility_Overrid__c=''));
                                    }
                            }
                        }
                    }
                }
            }
            return assetIdVsAssetObjMap.values();
        }
        
        */
    }