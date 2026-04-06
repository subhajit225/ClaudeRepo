public class clusterController {
    public Map<String,String> clusterMap{get;set;}
    public String payLoad{get;set;}
    public clusterController(ApexPages.StandardController sc){
        if(!Test.isRunningTest()){
            sc.addFields(new List<String>{'Capacity_Snapshot__c','Capacity_System__c','Capacity_Total__c'});
        }

        Cluster__c clust = (Cluster__c) sc.getRecord();
        clusterMap = new Map<String,String>();
        clusterMap.put('Capacity Snapshot', String.valueOf(clust.Capacity_Snapshot__c));
        clusterMap.put('Capacity System', String.valueOf(clust.Capacity_System__c));
        clusterMap.put('Capacity Total', String.valueOf(clust.Capacity_Total__c));
        payLoad = JSON.serialize(clusterMap);
    }
}