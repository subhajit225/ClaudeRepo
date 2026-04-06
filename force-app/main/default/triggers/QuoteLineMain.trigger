trigger QuoteLineMain on SBQQ__QuoteLine__c (before insert,before update) {
    List<SBQQ__QuoteLine__C> qLineList = new List<SBQQ__QuoteLine__C>();
    Map<String, String> mapIDvsSnumber = new Map<String,String>();
    Set<String> assetIds = new Set<String>();
    //QLineList =  AND ];
    for(SBQQ__QuoteLine__C QL: [select id, SBQQ__SubscribedAssetIds__c, SubscribedAssetNames__C from SBQQ__QuoteLine__C where ID IN: Trigger.New]){
        IF(String.isNotBlank(QL.SBQQ__SubscribedAssetIds__c)){
            for(String asstId: QL.SBQQ__SubscribedAssetIds__c.split(',') ){
               asstId = asstId.trim();
                assetIds.add(asstId); 
            }
            
       }
    }
    System.debug('AssetIds=='+AssetIds);
    for(Asset asset : [select id, name from Asset id where id In: assetIds]){
        mapIDvsSnumber.put(asset.id, asset.Name);
    }
    System.debug('mapIDvsSnumber=='+mapIDvsSnumber);
    for(SBQQ__QuoteLine__C QL : Trigger.new){
        //Update ProductCode Text field value
        QL.Product_Code__c = QL.SBQQ__PackageProductCode__c;
        String names = '';
        if(String.isNotBlank(QL.SBQQ__SubscribedAssetIds__c) ){
        for(String assetId : QL.SBQQ__SubscribedAssetIds__c.split(',')){
            assetId = assetId.trim();
            ID assettNewId = assetId;
           System.debug('mapIDvsSnumber id=='+mapIDvsSnumber.get(assettNewId));
            
            names += mapIDvsSnumber.get(assettNewId)+',';
        }
        QL.SubscribedAssetNames__c =names.removeEnd(',');
        }
    }
}