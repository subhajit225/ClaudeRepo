public class UpdateClusterController {
    public Cluster__c clus{get;set;}
    public List<Cluster_registration__c> requestCluster{get;set;}
    public UpdateClusterController(ApexPages.StandardController sc){
        if(!Test.isRunningTest())
            sc.addFields(new List<String>{'Name'});
        clus = (Cluster__c)sc.getRecord();
        requestCluster = [SELECT id,Cluster__c,Cluster__r.name,Requested_Users__r.Name,Registration_Date__c, Request_Status__c,Cluster__r.account__r.Name from Cluster_registration__c where (cluster_UUID__c =: clus.Name OR Cluster_Tag__c =: clus.Name) order by createdDate desc];
    }
    
    public pagereference updateCluster(){
        List<Cluster_registration__c> requests = [SELECT Id,Cluster__c from Cluster_registration__c where (Cluster_Tag__c =:clus.Name AND cluster_UUID__c =: clus.Name) AND Cluster__c = null];
        for(Cluster_registration__c req :  requests){
            req.Cluster__c = clus.Id;
        }
        update requests;
        return null;
    }
}