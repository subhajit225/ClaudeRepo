/**
* @Author : Ashwini G
* @Date : 9th April 2020
* @Description : CS21-161 : Set the flag for r6000 series on Cluster to identify if a cluster has at least one r6000 series hardware based on the nodes tagged
* 
**/

global class UpdateR6000FlagOnClustersBatch implements Database.Batchable<sObject>, System.Schedulable{ 

    global Database.QueryLocator start(Database.BatchableContext BC){
  
        String query = 'Select Id from Cluster__c Where Archived__c = false';
        return Database.getQueryLocator(query);
    }

    global void execute(SchedulableContext SC) {
        Database.executeBatch(new UpdateR6000FlagOnClustersBatch(),100);
    }

    global void execute(Database.BatchableContext BC, List<Cluster__c> scope){

        List<Cluster__c> inScopeClusters = [Select Id,MSP_Consumption__c,(Select Id, Asset__c, Asset__r.Product2.Family, Asset__r.Product2.Description, Asset__r.Product2.Name,asset__r.Order_Service_Item__r.Order.Order_Sub_Type__c from Nodes__r where Asset__c != null and Asset__r.Product2Id != null order by Cluster__c) from Cluster__c Where Id IN :scope];
        List<Cluster__c> clustersToUpdate = new List<Cluster__c>();
        Map<Id,Cluster__c> clustersCheckToUpdateMap = new Map<Id,Cluster__c>();

        for(Cluster__c eachCluster : inScopeClusters){
            Cluster__c clusterNew = new Cluster__c();
            clusterNew.Id = eachCluster.Id;
            Integer countOfR6000NodesTagged = 0;
            Integer countOfAllNodes = 0;
            if(eachCluster.Nodes__r != null ){
                for(Node__c node : eachCluster.Nodes__r){
                    countOfAllNodes = countOfAllNodes +1;
                    if(node.asset__c != null){
                        if(node.asset__r.Order_Service_Item__c != Null){
                            if(node.asset__r.Order_Service_Item__r.Order.Order_Sub_Type__c != null && node.asset__r.Order_Service_Item__r.Order.Order_Sub_Type__c =='MSP Consumption' ){
                                if(eachCluster.MSP_Consumption__c == false){
                                    clusterNew.MSP_Consumption__c =true;
                                }
                                clustersToUpdate.add(clusterNew);
                                
                            }
                         }
                     }

                    if(node.Asset__r.Product2.Family != null){
                        if(node.Asset__r.Product2.Family.contains('R6000')){
                            countOfR6000NodesTagged = countOfR6000NodesTagged+1;
                            break;  
                        }
                    }
                    if(node.Asset__r.Product2.Description != null){
                        if(node.Asset__r.Product2.Description.contains('r6')){
                            countOfR6000NodesTagged = countOfR6000NodesTagged+1;
                            break;  
                        }
                    }
                    if(node.Asset__r.Product2.Name != null){
                        if(node.Asset__r.Product2.Name.contains('R6')){
                            countOfR6000NodesTagged = countOfR6000NodesTagged+1;
                            break;  
                        }
                    }
                }
            }
 
            if(countOfAllNodes > 0 && countOfR6000NodesTagged > 0){
                clusterNew.Contains_r6000_Product_s__c = true;
            }else{
                clusterNew.Contains_r6000_Product_s__c = false;
            }
            clustersToUpdate.add(clusterNew);

        }
        clustersCheckToUpdateMap.putall(clustersToUpdate);
        if(clustersCheckToUpdateMap.size() > 0)
        {
            List<Database.SaveResult> updateClusterResult = Database.Update(clustersCheckToUpdateMap.values(),false);
        }

    }
    
    global void finish(Database.BatchableContext BC){
    }
}