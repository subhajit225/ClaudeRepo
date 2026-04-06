global class AssetSWVersionUpdate implements Database.Batchable<sObject>, Schedulable {

	String query;

	global AssetSWVersionUpdate() {
		this.query = 'SELECT Id, (SELECT Id, software_version__c FROM Nodes__r) FROM Asset';
	}

    global void execute(SchedulableContext sc) {
        AssetSWVersionUpdate b = new AssetSWVersionUpdate();
        Database.executeBatch(b, 100);
    }

	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Asset> assets = (List<Asset>)scope;
        updateAssetSWVersion(assets);
	}

    public static void updateAssetSWVersion(List<Asset> assets) {
        List<Asset> toUpdate = new List<Asset>();

        for(Asset asset : assets) {
            Set<String> sVersions = new Set<String>();
            for(Node__c node : asset.Nodes__r) {
                sVersions.add(node.software_version__c);
            }
            if(sVersions.size() == 1 && !sVersions.contains(null)) {
                toUpdate.add(
                    new Asset(Id = asset.Id, SW_Version__c = (new List<String>(sVersions)).get(0))
                );
            }
        }

        if(!toUpdate.isEmpty()) {
            Database.update(toUpdate, false);
        }
    }

	global void finish(Database.BatchableContext BC) {

	}

}