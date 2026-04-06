/**
* @Author : Shubham
* @Created Date : 5-Aug-2022
* @Description : Helper Class for Node Trigger - LinkCustomer
*                
*                
**/

public class NodeTriggerHelper {
    
    // CS21-1167 - Calculating and updating Total Node Count on Cluster object
    public static void updateTotalNodeCount(List<Node__c> nodeList, Map<Id,Node__c> oldNodeMap){

        List<Cluster__c> updateClusterList = new List<Cluster__c>();
        Set<Id> clusterIdSet = new Set<Id>();

        if(oldNodeMap == null){
            for(Node__c objNode : nodeList) {
                if(objNode.cluster__c != null){
                    clusterIdSet.add(objNode.cluster__c);
                }
            }
        }else{
            for(Node__c node : nodeList){
                Node__c oldNode = oldNodeMap.get(node.Id);
                if(oldNode != null && node.cluster__c != oldNode.cluster__c){
                    if(oldNode.cluster__c != null) 
                        clusterIdSet.add(oldNode.cluster__c);
                    if(node.cluster__c != null) 
                        clusterIdSet.add(node.cluster__c);
                }
            }    
        }

        clusterIdSet.remove(null);

        if(!clusterIdSet.isEmpty()){
            for (AggregateResult agr : [SELECT cluster__c, Count(Id) TotalNodeCount
                                    FROM Node__c
                                    WHERE cluster__c IN :clusterIdSet
                                    GROUP BY cluster__c]) {
                Id clusterId = (Id) agr.get('cluster__c');
                Cluster__c objCluster = new Cluster__c(Id = clusterId);
                objCluster.Total_Node_Count__c = (Integer) agr.get('TotalNodeCount');
                updateClusterList.add(objCluster);
                if(clusterIdSet.contains(clusterId)){
                    clusterIdSet.remove(clusterId);    
                }
            }
            for(Id clusterId : clusterIdSet){
                updateClusterList.add(new Cluster__c(id = clusterId, Total_Node_Count__c = 0));
            }
        }
        
        if(!updateClusterList.isEmpty()){
            update updateClusterList;
        }
    }
}