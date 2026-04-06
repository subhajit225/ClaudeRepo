global class Entititlement_isRenewal_Update_Batch implements Database.Batchable<sObject>, Database.stateful{
    public Set<Opportunity> processedEntitlements = new Set<Opportunity>();
    global Database.QueryLocator start(Database.BatchableContext BC){ //and OpportunityId = \'006S0000009yFdQ\' ,Order_Service_Item__r.Product2Id
     //FOR TEST PURPOSE ONLY
        /*string entl='02i4000000PfrO3';
        string whereClause = ' AssetId = \'' + entl + '\' ';
        String query = 'select id , Product__c,AssetId, EndDate,StartDate, AccountID,Renewable__c  from Entitlement where '+whereClause + (Test.isRunningTest()?' LIMIT 20':'');
        return Database.getQueryLocator(query);
       */
        //FOR ACCOUNT
      /* string acc='0014000001mfbK4';
        string whereClause = ' AccountId = \'' + acc + '\' ';
        String query = 'select id , Product__c,AssetId,Startdate, EndDate,Renewable__c,AccountId  from Entitlement where '+whereClause + (Test.isRunningTest()?' LIMIT 20':'');
        return Database.getQueryLocator(query);
       */
       String query = 'select id , Product__c,AssetId,StartDate, AccountID, EndDate,Renewable__c  from Entitlement '+ (Test.isRunningTest()?' LIMIT 20':'');
       return Database.getQueryLocator(query);
    }
    // Execute Metjod to perform Logic on Batch
    global void execute(Database.BatchableContext BC, List<Entitlement> scope){
        List<Entitlement> entitlementsToBeUpdated = new List<Entitlement>();
        Map<Id,Entitlement> mapEntitlementsRenewed = new Map<ID,Entitlement>();
        Map<Id,Set<Id>> mapAssetProductonEntitlement = new Map<Id,Set<Id>>();
        Map<Id,Set<Id>> mapProductEntitlement = new Map<Id,Set<Id>>();
        Map<Id,Set<String>> mapAssetProductCodeonEntitlement = new Map<Id,Set<String>>();
        Map<Id,Set<Entitlement>> mapAccountEntitlement_RBKEDGE = new Map<Id,Set<Entitlement>>();
        Map<Id,Set<Entitlement>> mapAccountEntitlement_RBKARCDM = new Map<Id,Set<Entitlement>>();
        Map<Id,Set<Id>> mapAssetEntitlements = new Map<Id,Set<Id>>();
        Map<Id,Set<Id>> mapProductEntitlementSet = new Map<Id,Set<Id>>();
        // My preference for aggregating related record Ids is to use a Set<Id>
        Set<Id> assetIds = new Set<Id>();
        Set<Id> AccountIds = new Set<Id>();
        List<Entitlement> entlToUpdate = new List<Entitlement>();

        for(Entitlement entl :Scope){
            if(entl.AssetId != null)
            assetIds.add(entl.AssetId);
        }

        for(Entitlement entl :Scope){
            if(entl.AssetId == null && Entl.AccountID != null)
            accountIds.add(entl.AccountID);
        }

        Set<Id> productIdSet = new Set<Id>();
        Set<Id> nonAssetEntilementIdSet = new Set<Id>();
        Set<String> productCodeSet = new Set<String>();
        Set<String> productCodeSetNonAsset = new Set<String>();
        Set<Entitlement> EntitlementSet = new Set<Entitlement>();
        Set<Id> EntitlementIdSet = new Set<id>();
        for(Asset asset : [Select id, name ,(select id,name ,AssetId,StartDate, EndDate, Product__C, Product__r.ProductCode from Entitlements) from Asset where id IN: AssetIds]){
            for(Entitlement entl : asset.entitlements){
                if(entl.assetId != null && entl.Product__r.ProductCode != null){
                    if(string.ValueOf(entl.Product__r.ProductCode).startsWith('RBK-SVC')){
                        System.debug('in RBK_SVC ==='+entl.Product__r.ProductCode);
                        productCodeSet.add('RBK-SVC%');
                    }
                    else if(string.ValueOf(entl.Product__r.ProductCode).startsWith('RBK-NRD') ){
                        System.debug('in RBK_nrd ==='+entl.Product__r.ProductCode);
                        productCodeSet.add('RBK-NRD%');
                    }
                    else{
                        System.debug('inentl.product__c ==='+entl.product__c);
                        productIdSet.add(entl.product__c);
                    }
                EntitlementSet.add(entl);
                }
            }
            productIdSet.remove(null);
            mapAssetProductonEntitlement.put(Asset.Id,productIdSet);
            mapAssetProductCodeonEntitlement.put(Asset.Id,productCodeSet);
        }
        for(Account acc : [Select id, name ,(select id,name ,AssetId,StartDate, EndDate, Product__C, Product__r.ProductCode from Entitlements order by EndDate asc) from Account where id IN: AccountIds]){
            Set<Entitlement> RBKCLOUTEntlIdSet = new Set<Entitlement>();
            Set<Entitlement> RBKRCDMEntlIdSet = new Set<Entitlement>();
            for(Entitlement entl : acc.entitlements){
                if(entl.assetId == null && entl.product__c != null){
                   String strProdCode = entl.Product__r.ProductCode.substring(0,entl.Product__r.ProductCode.lastIndexOf('-'));
                    system.debug('strprod =='+strProdCode);
                    productCodeSetNonAsset.add(strProdCode);
                    if(strProdCode == 'RBK-EDGE-10'){
                        System.debug('in RBK-EDGE-10 ==='+entl.Product__r.ProductCode);
                        productCodeSetNonAsset.add(strProdCode);
                        RBKCLOUTEntlIdSet.add(entl);
                    }
                    else if( strProdCode =='RBK-RCDM-AWS' ){
                        System.debug('in RBK-RCDM-AW ==='+entl.Product__r.ProductCode);
                        productCodeSetNonAsset.add(strProdCode);
                        RBKRCDMEntlIdSet.add(entl);
                    }
                    else{
                        System.debug('inentl.product__c ==='+entl.product__c);
                        nonAssetEntilementIdSet.add(entl.id);
                    }
                }
            }
            system.debug('RBKCLOUTEntlIdSet =='+RBKCLOUTEntlIdSet);
            system.debug('RBKRCDMEntlIdSet =='+RBKRCDMEntlIdSet);
            if(RBKCLOUTEntlIdSet.size()>0)
            mapAccountEntitlement_RBKEDGE.put(acc.Id, RBKCLOUTEntlIdSet);
            if(RBKRCDMEntlIdSet.size()>0)
            mapAccountEntitlement_RBKARCDM.put(acc.Id,RBKRCDMEntlIdSet);
        }
        System.debug('assetIds ==='+assetIds);
        System.debug('productIdSet ==='+productIdSet);
        System.debug('productCodeSet ==='+productCodeSet);
        System.debug('nonAssetEntilementIdSet ==='+nonAssetEntilementIdSet);
        System.debug('productCodeSetNonAsset ==='+productCodeSetNonAsset);

        Map<id,Boolean> mapAssetEntlStatus = new Map<Id,Boolean>();
       for(Product2 prod : [Select id, name ,(select id,name , EndDate from Entitlements__r) from Product2 where id IN: productIdSet]){
            for(Entitlement entl : prod.entitlements__r){
                EntitlementIdSet.add(entl.Id);
            }
            mapProductEntitlement.put(prod.Id,EntitlementIdSet);
        }
        System.debug('AssetIds ==='+AssetIds);
        List<Product2>  prodList = [Select id, name ,(select id,name , EndDate from Entitlements__r Where AssetID IN :AssetIds order by EndDate Desc LIMIT 1) from Product2 where id IN: ProductIdSet];
        for(Id asset : AssetIds){
            for(Product2  prod : prodList){
                if(!(prod.Entitlements__r.isEmpty()) && prod.Entitlements__r != null){
                    system.debug('prod.Entitlements__r=='+prod.Entitlements__r);
                    mapAssetEntlStatus.put(prod.Entitlements__r[0].Id,true);
                }
            }
        }

        /*for(Id asset : AssetIds){
            for(Product2  prod : [Select id, name ,(select id,name , EndDate from Entitlements__r Where AssetID=:asset order by EndDate Desc LIMIT 1) from Product2 where ProductCode LIKE : ProductCodeSet]){
                if(!(prod.Entitlements__r.isEmpty()) && prod.Entitlements__r != null){
                    system.debug('prod.Entitlements__r=='+prod.Entitlements__r);
                    mapAssetEntlStatus.put(prod.Entitlements__r[0].Id,true);
                }
            }
             }
            for(Entitlement  entl : [Select id, name ,Enddate,Product__r.ProductCode from Entitlement Where AssetID=:Asset and Product__r.ProductCode LIKE : ProductCodeSet order by EndDate Desc LIMIT 1 ]){
                //if(!(prod.Entitlements__r.isEmpty()) && prod.Entitlements__r != null){
                    system.debug('entl=='+entl);
                    mapAssetEntlStatus.put(entl.Id,true);
                //}
            }*/

        //for(String prod :ProductCodeSet){
              for(Asset  asset : [select id, name, (Select id, name ,Enddate,Product__r.ProductCode from Entitlements where (Product__r.ProductCode LIKE 'RBK-NRD%' OR Product__r.ProductCode LIKE 'RBK-SVC%' ) order by EndDate Desc LIMIT 1) from Asset Where Id=:AssetIds ]){
                if(!(asset.Entitlements.isEmpty()) && asset.Entitlements != null){
                    system.debug('entl=='+asset.Entitlements[0]);
                    mapAssetEntlStatus.put(asset.Entitlements[0].Id,true);
                }
              }
            //}
        /*for(String prod :productCodeSetNonAsset){
              for(Asset  asset : [select id, name, (Select id, name ,Enddate,Product__r.ProductCode from Entitlements where Product__r.ProductCode LIKE: prod order by EndDate Desc LIMIT 1) from Asset Where Id=:AssetIds ]){ 
                if(!(asset.Entitlements.isEmpty()) && asset.Entitlements != null){
                    system.debug('entl=='+asset.Entitlements[0]);
                    mapAssetEntlStatus.put(asset.Entitlements[0].Id,true);
                }
              }
        }*/
        system.debug('mapAccountEntitlement_RBKEDGE =='+mapAccountEntitlement_RBKEDGE);
        for(Id accId : mapAccountEntitlement_RBKEDGE.keySet()){
                Id finalUpdateId = null;
                Date compareDate = null;
                for(Entitlement entl : mapAccountEntitlement_RBKEDGE.get(accId)){
                    if(entl.EndDate != null && compareDate == null){
                        compareDate = entl.EndDate;
                        system.debug('entl.Id 111=='+entl);
                        finalUpdateId = entl.Id;
                    }else if(entl.StartDate == compareDate.addDays(1) ){
                        compareDate = entl.EndDate;
                        system.debug('entl.Id 222=='+entl);
                        finalUpdateId = entl.Id;
                    }else{
                        compareDate = entl.EndDate;
                        mapAssetEntlStatus.put(entl.id,true);
                    }
                    system.debug('finalUpdateId=='+finalUpdateId);
                }
                system.debug('mapAssetEntlStatus before 111=='+mapAssetEntlStatus);
                if(finalUpdateId != null)
                mapAssetEntlStatus.put(finalUpdateId,true);
                system.debug('mapAssetEntlStatus after 111=='+mapAssetEntlStatus);
            }
        system.debug('mapAccountEntitlement_RBKARCDM =='+mapAccountEntitlement_RBKARCDM);
        for(Id accId : mapAccountEntitlement_RBKARCDM.keySet()){
                Id finalUpdateId = null;
                Date compareDate = null;
                for(Entitlement entl : mapAccountEntitlement_RBKARCDM.get(accId)){
                    if(entl.EndDate != null && compareDate == null){
                        compareDate = entl.EndDate;
                        system.debug('entl.Id 333=='+entl.Id);
                        finalUpdateId = entl.Id;
                    }else if(entl.StartDate == compareDate.addDays(1) ){
                        compareDate = entl.EndDate;
                        system.debug('entl.Id 444=='+entl.Id);
                        finalUpdateId = entl.Id;
                    }else{
                        compareDate = entl.EndDate;
                        mapAssetEntlStatus.put(entl.id,true);
                    }system.debug('finalUpdateId=='+finalUpdateId);
                }
                system.debug('mapAssetEntlStatus before 222=='+mapAssetEntlStatus);
                if(finalUpdateId != null)
                mapAssetEntlStatus.put(finalUpdateId,true);
                system.debug('mapAssetEntlStatus after 222=='+mapAssetEntlStatus);
            }
        system.debug('mapAssetEntlStatus=='+mapAssetEntlStatus);
        system.debug('Scope=='+Scope);
        /*for(Entitlement etl : scope){
          system.debug('nonAssetEntilementIdSet=='+nonAssetEntilementIdSet);
          system.debug('etl=='+etl);
          system.debug('nonAssetEntilementIdSet.contains(etl.id)=='+nonAssetEntilementIdSet.contains(etl.id));
          if(etl.AssetId == null && nonAssetEntilementIdSet.contains(etl.id)){
              etl.renewable__c = TRUE;
          }
          else
          etl.renewable__c = mapAssetEntlStatus.get(etl.id) != null ? mapAssetEntlStatus.get(etl.id):false;
          entitlementsToBeUpdated.add(etl);
        }
        system.debug('entitlementsToBeUpdated=='+entitlementsToBeUpdated);
        Database.update(entitlementsToBeUpdated,false);*/
      }
      global void finish(Database.BatchableContext processOpptys) {
        try{
            PS_OverdureEmailServiceBatch b = new PS_OverdureEmailServiceBatch();
            Database.executeBatch(b,75);
        }catch(Exception e){
            system.debug('@@ Exception occured PS_OverdureEmailServiceBatch '+e.getMessage());
        }
        /*try{
            PC_DealRegExpiryUpdateBatch bt = new PC_DealRegExpiryUpdateBatch();
            Database.executeBatch(bt,1);
        }catch(Exception e){
            system.debug('@@ Exception occured PC_DealRegExpiryUpdateBatch '+e.getMessage());
        }
        try{
            PC_MDFSubmitClaimRemainderBatch claimReminder = new PC_MDFSubmitClaimRemainderBatch();
            Database.executeBatch(claimReminder);
        }catch(Exception e){
            system.debug('@@ Exception occured PC_MDFSubmitClaimRemainderBatch '+e.getMessage());
        }
        try{
            PC_ContractExpiryBatch contractexpbatch = new PC_ContractExpiryBatch();
            Database.executeBatch(contractexpbatch,100);
        }catch(Exception e){
            system.debug('@@ Exception occured PC_ContractExpiryBatch '+e.getMessage());
        }*/
        try{
            LeadUnMQLBatchController unMQLbatch = new LeadUnMQLBatchController();
            Database.executeBatch(unMQLbatch,100);
        }catch(Exception e){
            system.debug('@@ Exception occured LeadUnMQLBatchController '+e.getMessage());
        }
        try{
            PC_MassConverLeadBatch massleadconvbatch = new PC_MassConverLeadBatch();
            Database.executeBatch(massleadconvbatch,100);
        }catch(Exception e){
            system.debug('@@ Exception occured PC_MassConverLeadBatch '+e.getMessage());
        }
        /*try{
            PC_ReCalculate_FileSharingBatch filesharebatch = new PC_ReCalculate_FileSharingBatch();
            Database.executeBatch(filesharebatch,200);
        }catch(Exception e){
            system.debug('@@ Exception occured PC_ReCalculate_FileSharingBatch '+e.getMessage());
        }*/
        try{
            updateProductTypeOLIBatch ptypebatch = new updateProductTypeOLIBatch();
            Database.executeBatch(ptypebatch,100);
        }catch(Exception e){
            system.debug('@@ Exception occured updateProductTypeOLIBatch '+e.getMessage());
        }
        /*try{
            Database.executeBatch(new MIPSyncBatch(null), 1);
        }catch(Exception e){
            system.debug('@@ Exception occured MIPSyncBatch'+ e.getMessage());
        } */
      }
}