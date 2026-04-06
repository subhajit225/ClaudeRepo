trigger AssetEventHandler on AssetEvent__e (after insert) {
    /*public static final String conversionVal = 'One per unit';
    public static final String errorType = 'GoRefresh CLI Update';
    public static final String type = 'SFDC';
    If(trigger.isAfter){   
        Set<Id> DeadAssetIds = new Set<Id>();
        List<ContractLineItem> listOfConLinItem = new List<ContractLineItem>();
        List<ContractLineItem> listToUpdateCLI = new List<ContractLineItem>();
        Set<Id> contIds = new Set<Id>();
        
        for(AssetEvent__e event : Trigger.new){
            if(event.Action__c == 'REFRESH'){
                DeadAssetIds.add(event.Asset_Id__c);
            }
        }
        if(!DeadAssetIds.isEmpty()){
            for(Entitlement ent: [SELECT id,ContractLineItemId FROM Entitlement WHERE AssetId IN :DeadAssetIds]){
                contIds.add(ent.ContractLineItemId);
            }
        }
        if(!contIds.isEmpty()){
            listOfConLinItem = [SELECT Id,Quantity,SBQQSC__RootId__c,SBQQSC__Quantity__c,SBQQSC__RenewalQuantity__c,
                                SBQQSC__Product__r.SBQQSC__EntitlementConversion__c,SBQQSC__TerminatedDate__c,
                                (SELECT Id,AssetId,Asset.UsageEndDate FROM Entitlements where AssetId IN :DeadAssetIds) FROM ContractLineItem WHERE Id IN:contIds];
        }
        for(ContractLineItem  eachLine: listOfConLinItem){
            List<Entitlement> entWithValidAsset = new List<Entitlement>();
            List<Entitlement> entWithEndDate = new List<Entitlement>();
            for(Entitlement eachEnt: eachLine.Entitlements){
                if(eachEnt.AssetId != null && eachEnt.Asset.UsageEndDate == null){
                    entWithValidAsset.add(eachEnt);
                }
                else{
                    entWithEndDate.add(eachEnt);
                }
            }
            if((eachLine.SBQQSC__Product__r.SBQQSC__EntitlementConversion__c != conversionVal || eachLine.Quantity == 1) && (!entWithEndDate.isEmpty())){
                eachLine.SBQQSC__TerminatedDate__c = entWithEndDate[0].asset.UsageEndDate;
            }
            else{
                if(eachLine.Entitlements.size() > 0){
                    if(eachLine.Quantity <= eachLine.Entitlements.size()){
                        eachLine.Quantity = 1;
                        eachLine.SBQQSC__RenewalQuantity__c = 1;
                        eachLine.SBQQSC__Quantity__c = 1;
                        if(!entWithEndDate.isEmpty()){
                            eachLine.SBQQSC__TerminatedDate__c = entWithEndDate[0].asset.UsageEndDate;
                        } 
                    }
                    else if(eachLine.Quantity > eachLine.Entitlements.size()){
                        Decimal tempVal = eachLine.Quantity - eachLine.Entitlements.size();
                        eachLine.Quantity = tempVal;
                        eachLine.SBQQSC__RenewalQuantity__c = tempVal;
                        eachLine.SBQQSC__Quantity__c = tempVal;
                    }
                    
                }
            }
            if(!entWithValidAsset.isEmpty() && DeadAssetIds.contains(eachLine.SBQQSC__RootId__c)){
                eachLine.SBQQSC__RootId__c = entWithValidAsset[0].AssetId;
            }
            listToUpdateCLI.add(eachLine);
            entWithValidAsset.clear();
            entWithEndDate.clear();
        }
        if(!listToUpdateCLI.isEmpty()){
            try{
                SBQQ.TriggerControl.disable();
                Update listToUpdateCLI;
                SBQQ.TriggerControl.enable();
            }
            Catch(Exception ex){
                Error_Logs__c errLog = new Error_Logs__c(Error_Type__c = errorType,error_Message__c = ex.getMessage() + '\r\n' + ex.getStackTraceString(),Type__c = type);
                if((String.valueOf(DeadAssetIds)).length() > 250){
                    errLog.Object__c = (String.valueOf(DeadAssetIds)).substring(0, 250); 
                }else{
                    errLog.Object__c = (String.valueOf(DeadAssetIds));
                }
                insert errLog;
            }
        }
    } */
}