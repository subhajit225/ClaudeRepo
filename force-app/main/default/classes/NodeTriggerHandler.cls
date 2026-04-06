/**
* @Author : Shubham
* @Created Date : 5-Aug-2022
* @Description : Handler Class for Node Trigger - LinkCustomer
*                
*                
**/
public class NodeTriggerHandler {
    
    public static void afterInsert(List<Node__c> newNodeList){
        NodeTriggerHelper.updateTotalNodeCount(newNodeList, null);
    }
    public static void afterUpdate(List<Node__c> newNodeList, Map<Id,Node__c> oldNodeMap){
        NodeTriggerHelper.updateTotalNodeCount(newNodeList, oldNodeMap);
    }
    public static void afterDelete(List<Node__c> oldNodeList){
        NodeTriggerHelper.updateTotalNodeCount(oldNodeList, null);
    }
    public static void afterUndelete(List<Node__c> newNodeList){
        NodeTriggerHelper.updateTotalNodeCount(newNodeList, null);
    }
}