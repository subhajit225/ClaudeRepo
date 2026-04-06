global class Account_ClusterCapacityBatch implements Database.Batchable<sObject> , Database.stateful{
    public Map<Id,Decimal> mapAccountwithValues = new Map<Id,Decimal>();
     global Database.QueryLocator start(Database.BatchableContext BC){

    string accid='0014000001YwlNxAAJ';
    string whereClause = ' id = \'' + accid + '\' ';
    string query= 'Select id,name from Account where'+whereClause;
    //string query= 'Select id,name from Account';
      return Database.getQueryLocator(query);
   }

   global void execute(Database.BatchableContext BC, List<Account> scope){
         Map<Id,List<Cluster__c>> mapAccountwithClusters = new Map<Id,List<Cluster__c>>();
         Map<Id,Decimal> mapAccountwithClustersCapacity = new Map<Id,Decimal>();
         Map<Id,Decimal> mapClusterwithClustersUsage = new Map<Id,Decimal>();
         Map<Id,Decimal> mapAccountwithClustersUsage = new Map<Id,Decimal>();
         Map<Id,Decimal> mapAssetwithClustersCapacity = new Map<Id,Decimal>();
         Map<Id,Decimal> mapClusterwithClustersCapacity = new Map<Id,Decimal>();
         Map<Id,Decimal> mapAccountCapacityPercentage = new Map<Id,Decimal>();
         Map<Id,Decimal> mapClusterWithCapacityPercentage = new Map<Id,Decimal>();
         Map<Id,Decimal> mapClusterWithValues = new Map<Id,Decimal>();
         Map<Id,String> mapClusterWithAccOwnerValues = new Map<Id,String>();
         Map<Id,String> mapAccwithAccountSEEmail = new Map<Id,String>();
         Map<Id,String> mapClusterwithAccountSEEmail = new Map<Id,String>();
         Map<Id,Integer> mapAssetwithNodeCount = new Map<Id,Integer>();
         Map<Id,Decimal> mapNodeLicencedCapacity = new Map<Id,Decimal>();

         List<Id> clusterList = new List<Id>();
         List<Id> accIdList = new List<Id>();
         for(Account acc: scope){
         accIdList.add(acc.Id);
         }
         system.debug('accIdList =='+accIdList+'==size--'+accIdList.size());
         List<Account> accList =[Select id,Owner.Email,(select Id,name , account__c, storage_usage__c,consumption_percentage__c, archived__c, Account_Owner_s_Email__c from Clusters__r where archived__c= false  and storage_usage__c >0 ) from Account where Id IN: accIdList];
         for (AccountTeamMember atm : [Select UserId, TeamMemberRole,User.Email, Id, AccountId From AccountTeamMember where AccountID in :accIdList and TeamMemberRole = 'Sales Engineer' ]){
            if (atm.User.Email != null){
                mapAccwithAccountSEEmail.put(atm.AccountId,atm.User.Email);
            }
        }
        system.debug('mapAccountwithClustersUsage  '+mapAccountwithClustersUsage);
        for(Asset Asst : [select id,Name ,(select id,Name from Nodes__r) from Asset where AccountID IN: accIdList]){
           mapAssetwithNodeCount.put(Asst.Id, Asst.Nodes__r.Size());
        }
        system.debug('mapAssetwithNodeCount  '+mapAssetwithNodeCount);
         for(Account acc: accList){
             mapAccountwithClusters.put(acc.id,acc.Clusters__r);
             for(Cluster__c cluster : acc.Clusters__r){
                 clusterList.add(cluster.id);
                 if(cluster.storage_usage__c != null)
                 mapClusterwithClustersUsage.put(cluster.id,cluster.storage_usage__c);
                 mapClusterWithAccOwnerValues.put(cluster.id,acc.Owner.Email);
                 mapClusterwithAccountSEEmail.put(cluster.id,mapAccwithAccountSEEmail.get(acc.Id));
             }


         }
         system.debug('mapClusterwithClustersUsage  '+mapClusterwithClustersUsage);

        /*for(Cluster__c Cluster :[Select id,name ,(Select id, Asset__c,Asset__r.Licensed_Capacity__c from Nodes__r) from cluster__c where ID IN:clusterList]){
             Set<Id> setUniqueAssets = new Set<Id>();
             for(Node__c node : Cluster.nodes__r){
                 mapAssetwithClustersCapacity.put(node.Asset__C,node.Asset__r.Licensed_Capacity__c);
                 setUniqueAssets.add(node.Asset__C);
             }
             system.debug('setUniqueAssets value ==='+setUniqueAssets+'setUniqueAssets size()'+setUniqueAssets.size());
             Decimal licenseCapacity =0.0;
             for(Id assetId :setUniqueAssets){
                 if(mapAssetwithClustersCapacity.containsKey(assetId)){
                   if(mapAssetwithClustersCapacity.get(assetId) != null)
                   licenseCapacity =  licenseCapacity +mapAssetwithClustersCapacity.get(assetId);
                 }
             }
             mapClusterwithClustersCapacity.put(Cluster.id,licenseCapacity) ;
         }*/
         for(Cluster__c Cluster :[Select id,name ,(Select id, Asset__c,Asset__r.Licensed_Capacity__c from Nodes__r) from cluster__c where ID IN:clusterList]){
              Decimal totalNodeCapacity =0.0;
              for(Node__c node : Cluster.nodes__r){
                 if(node.Asset__r.Licensed_Capacity__c != null && node.Asset__r.Licensed_Capacity__c != 0 && mapAssetwithNodeCount.get(node.Asset__c)  !=0 ){
                 system.debug('node Asset Capacity--'+node.Asset__r.Licensed_Capacity__c);
                 system.debug('mapAssetwithNodeCount.get(node.Asset__c) ==='+mapAssetwithNodeCount.get(node.Asset__c));
                 
                 totalNodeCapacity+= node.Asset__r.Licensed_Capacity__c/mapAssetwithNodeCount.get(node.Asset__c);
                 
                 }
                  //mapNodeLicencedCapacity.put(node.Asset__C,node.Asset__r.Licensed_Capacity__c);
                  //setUniqueAssets.add(node.Asset__C);
              }
              mapNodeLicencedCapacity.put(Cluster.Id,totalNodeCapacity);
              
          }
          system.debug('mapNodeLicencedCapacity value ==='+mapNodeLicencedCapacity+'mapNodeLicencedCapacity size()'+mapNodeLicencedCapacity.size());
         system.debug('mapAssetwithClustersCapacity value ==='+mapAssetwithClustersCapacity+'mapAssetwithClustersCapacity size()'+mapAssetwithClustersCapacity.size());
         system.debug('mapClusterwithClustersCapacity value ==='+mapClusterwithClustersCapacity+'mapClusterwithClustersCapacity size()'+mapClusterwithClustersCapacity.size());


        /*for(Id cluster :mapClusterwithClustersUsage.keySet() ){
             Decimal Percentage =0.0;
             if(mapClusterwithClustersUsage.containsKey(cluster)){
                 if(mapClusterwithClustersUsage.get(cluster) != null && mapClusterwithClustersUsage.get(cluster) != 0 && mapClusterwithClustersCapacity.get(cluster) != 0)
                 System.debug('mapClusterwithClustersUsage.get(cluster) --'+mapClusterwithClustersUsage.get(cluster));
                 System.debug('mapClusterwithClustersCapacity.get(cluster).get(cluster) --'+mapClusterwithClustersCapacity.get(cluster));
                 if(mapClusterwithClustersCapacity.get(cluster) != 0.0)
                 Percentage = 100*(mapClusterwithClustersUsage.get(cluster)/mapClusterwithClustersCapacity.get(cluster));
                 else
                 Percentage = 0.0;
             }
             mapClusterWithCapacityPercentage.put(cluster,Percentage);
         }*/

         for(Id cluster :mapClusterwithClustersUsage.keySet() ){
              Decimal Percentage =0.0;
              if(mapClusterwithClustersUsage.containsKey(cluster)){
                  if(mapClusterwithClustersUsage.get(cluster) != null && mapClusterwithClustersUsage.get(cluster) != 0 && mapClusterwithClustersCapacity.get(cluster) != 0)
                  System.debug('mapClusterwithClustersUsage.get(cluster) --'+mapClusterwithClustersUsage.get(cluster));
                  System.debug('mapNodeLicencedCapacity.get(cluster).get(cluster) --'+mapNodeLicencedCapacity.get(cluster));
                  if(mapNodeLicencedCapacity.get(cluster) != 0)
                  Percentage = 100*(mapClusterwithClustersUsage.get(cluster)/mapNodeLicencedCapacity.get(cluster));
                  else
                  Percentage = 0.0;
              }
              mapClusterWithCapacityPercentage.put(cluster,Percentage);
          }
         System.debug('mapClusterWithCapacityPercentage --'+mapClusterWithCapacityPercentage);

           /*for(Account acc :accList){
               if(acc.Consumption_Percentage__c != mapAccountCapacityPercentage.get(acc.Id)){
                   mapAccountwithValues.put(acc.Id,mapAccountCapacityPercentage.get(acc.Id));
               }
           }*/

           for(Account acc :accList){
             for(Cluster__c cls : acc.Clusters__r){
                 if(cls.Consumption_Percentage__c != mapClusterWithCapacityPercentage.get(cls.Id)){
                   mapClusterWithValues.put(cls.Id,mapClusterWithCapacityPercentage.get(cls.Id));
               }
             }
          }
        System.debug('mapClusterWithValues --'+mapClusterWithValues);
           List<Cluster__c> clusterUpdateList = new List<Cluster__c>();

           for(Id clsId : mapClusterWithValues.KeySet()){
             clusterUpdateList.add( new Cluster__c(Id=clsId,Consumption_Percentage__c=mapClusterWithValues.get(clsID), Account_Owner_s_Email__c = mapClusterWithAccOwnerValues.get(clsId), Account_SE__c=mapClusterwithAccountSEEmail.get(clsId)));
           }

           System.debug('clusterUpdateList --'+clusterUpdateList);
           if(!clusterUpdateList.isempty())
           Database.Update(clusterUpdateList);
         system.debug('mapAccountwithClustersCapacity value ==='+mapAccountwithClustersCapacity+'mapClusterwithClustersCapacity size()'+mapClusterwithClustersCapacity.size());
         system.debug('mapAccountwithValues value ==='+mapAccountwithValues+'mapAccountwithValues size()'+mapAccountwithValues.size());
    }

   global void finish(Database.BatchableContext BC){

       System.debug('Compeleted');
       System.debug('mapAccountwithValues=='+mapAccountwithValues);

   }


}