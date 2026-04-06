trigger LinkCustomer on Node__c (after update, after insert, after delete, after undelete) {

    if(Trigger.isAfter){
        if(Trigger.isInsert){
            NodeTriggerHandler.afterInsert(Trigger.new);
        }
        if(Trigger.isUpdate){
            NodeTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
        if(Trigger.isDelete){
            NodeTriggerHandler.afterDelete(Trigger.old);
        }
        if(Trigger.isUndelete){
            NodeTriggerHandler.afterUndelete(Trigger.new);
        }
    }

    if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
    List<Node__c> nodes = trigger.new;
    List<String> assetIds = new List<String>();
    List<String> clusterIds = new List<String>();
    Map<String, String> assetToCluster = new Map<String,String>();
    
    
    
    Map<String, Asset> nodeToAsset = new Map<String,Asset>();
    for (Node__c node : nodes) {
        if (node.Asset__c != null && node.Cluster__c != null) {
            assetIds.add(node.Asset__c);
            clusterIds.add(node.Cluster__c);
            assetToCluster.put(node.Asset__c, node.Cluster__c);
        }
    }
    
    Map<String, Cluster__c> clusters = new Map<String, Cluster__c>([select Cluster__c.Id, Cluster__c.Account__c from Cluster__c
         where id in :clusterIds]);
         
    Map<String, Asset> assets = new Map<String, Asset>([select Asset.AccountId, Asset.Id from Asset
         where id in :assetIds]);
    
    List<Cluster__c> updates = new List<Cluster__c>();
    for (Asset asset : assets.values()) {
        if (asset.AccountId == null) {
            continue;
        }
        
        String clusterId = assetToCluster.get(asset.Id);
        Cluster__c cluster = clusters.get(clusterId);
        if (cluster != null) {
            if (cluster.Account__c == null) {
                cluster.Account__c = asset.AccountId;
            }
            clusters.remove(clusterId);
            updates.add(cluster);
        }
    }
    
    update(updates);
    }
}