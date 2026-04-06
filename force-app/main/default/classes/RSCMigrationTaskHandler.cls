/** 
* @Author      : Raveesh Layal
* @CreatedDate : 5th October 2023
* @Description : Updates the repective RSC Migration Task records and related records.
* @TstClass    : RSCMigrationTaskHandlerTest
* @Jira		   : CS21-1939 

* -------------------------- @History --------------------------------------------------------------------------------------------
* Story Number       Modified By              Date           Description
* CS21-1939        		           
* --------------------------------------------------------------------------------------------------------------------------------
*/

public class RSCMigrationTaskHandler{ 
    /**
* @description method to update Cluster Id in the task record as per UUID
* @param  rscTasks- List of new Trigger.new.
* @param  oldMap - Map of Trigger.old 
* @return void
*/
    public static void updateClusterId(List<RSC_Migration_Tasks__c> rscTasks, Map<Id,RSC_Migration_Tasks__c >oldMap)
    {
        set<string> uuidSet=new set<string>();
        map<String,id> uuidToClusterId=new  map<String,id>();
        for(RSC_Migration_Tasks__c rmt:rscTasks)
        {
            if(rmt.cluster_UUID__c!=null && (Trigger.isInsert || (Trigger.isUpdate && oldmap.get(rmt.id).cluster_UUID__c!=rmt.cluster_UUID__c)))
            {
                uuidSet.add(rmt.cluster_UUID__c);    
            }
            
        }
        if(uuidSet.size()>0)
        {
            list<Cluster__c> clusterList=[select id,uuid__c from Cluster__c where uuid__c in:uuidSet];
            for(Cluster__c rc:clusterList)
            {
                if(!uuidToClusterId.containsKey(rc.uuid__c))
                {
                    uuidToClusterId.put(rc.uuid__c,rc.id);
                }
                
            }
            for(RSC_Migration_Tasks__c rm:rscTasks)
            {
                if(uuidToClusterId.containsKey(rm.cluster_UUID__c))
                {
                    rm.Cluster__c=uuidToClusterId.get(rm.cluster_UUID__c);
                }
                
            } 
        }
        
        
    }
    /**
* @description method to count and update the number of completed tasks.
* @param  rscTasks- List of new Trigger.new.
* @param  oldMap - Map of Trigger.old 
* @return void
*/
    public static void updateTotalCountOnCluster(List<RSC_Migration_Tasks__c> rscTasks, Map<Id,RSC_Migration_Tasks__c >oldMap){
        Map<Id,Id>clusterToaccId=new Map<Id,Id>(); 
        Map<Id,Integer>clusterIdToTotalTasks=new Map<Id,Integer>();
        Map<Id,Integer>clusterIdToCompletedTasks=new Map<Id,Integer>();
        Map<id,Integer>ClusterIdToInprogressTasks=new Map<id,Integer>();
        Map<Id,Integer>accIdToTotalTasks=new Map<Id,Integer>();
        Map<Id,Integer>accIdToCompletedTasks=new Map<Id,Integer>();
        Map<id,Integer>accIdToInprogressTasks=new Map<id,Integer>();
        Map<Id,Id>clusterIdToAcc=new Map<Id,Id>();
        Set<Cluster__c>clustersToBeUpdated=new Set<Cluster__c>(); 
        Set<Account>accsToBeUpdated=new Set<Account>(); 
        if(Trigger.isInsert || Trigger.IsUndelete || Trigger.isUpdate){
            for(RSC_Migration_Tasks__c rmt:rscTasks){
                if(rmt.Cluster__c!=null && (Trigger.isInsert || Trigger.IsUndelete || (Trigger.isUpdate && ((rmt.Cluster__c!=oldMap.get(rmt.Id).Cluster__c ) || (rmt.Task_Migration_Status__c!= oldMap.get(rmt.id).Task_Migration_Status__c ))))){
                    clusterToaccId.put(rmt.Cluster__c,rmt.Account_Id__c);
                    
                    If((Trigger.isUpdate && (rmt.Cluster__c!=oldMap.get(rmt.Id).Cluster__c ))){
                        clusterToaccId.put(oldMap.get(rmt.Id).Cluster__c,oldMap.get(rmt.Id).Account_Id__c);
                    }
                }
            }
        }
        if(Trigger.isDelete){
            for(Id rmtId:oldMap.keySet()){
                if(oldMap.get(rmtId).Account_Id__c!=null){
                    clusterToaccId.put(oldMap.get(rmtId).Cluster__c,oldMap.get(rmtId).Account_Id__c);
                    
                }
            }        
        }
        if(clusterToaccId.size()>0){
            List<RSC_Migration_Tasks__c>migrationTasks=[SELECT ID,Task_Migration_Status__c,Cluster__c,Cluster__r.name,Account_Id__c FROM RSC_Migration_Tasks__c where Account_Id__c IN: clusterToaccId.values() ];
            if(migrationTasks.size()>0){
                for(RSC_Migration_Tasks__c clust:migrationTasks){
                    clusterIdToAcc.put(clust.Cluster__c,clust.Account_Id__c);
                    if(clusterIdToTotalTasks.containsKey(clust.Cluster__c)){
                        clusterIdToTotalTasks.put(clust.Cluster__c,clusterIdToTotalTasks.get(clust.Cluster__c)+1);
                    }
                    else{
                        clusterIdToTotalTasks.put(clust.Cluster__c, 1);
                    }
                    if(accIdToTotalTasks.containsKey(clust.Account_Id__c)){
                        accIdToTotalTasks.put(clust.Account_Id__c,accIdToTotalTasks.get(clust.Account_Id__c)+1);
                    }
                    else{
                        accIdToTotalTasks.put(clust.Account_Id__c, 1);
                    }
                    if(clust.Task_Migration_Status__c!=null && clust.Task_Migration_Status__c=='MIGRATED'){
                        if(clusterIdToCompletedTasks.containsKey(clust.Cluster__c)){
                            clusterIdToCompletedTasks.put(clust.Cluster__c,clusterIdToCompletedTasks.get(clust.Cluster__c)+1);
                        }
                        else{
                            clusterIdToCompletedTasks.put(clust.Cluster__c, 1);
                        }
                        if(accIdToCompletedTasks.containsKey(clust.Account_Id__c)){
                            accIdToCompletedTasks.put(clust.Account_Id__c,accIdToCompletedTasks.get(clust.Account_Id__c)+1);
                        }
                        else{
                            accIdToCompletedTasks.put(clust.Account_Id__c, 1);
                        }
                    } 
                    if(clust.Task_Migration_Status__c!=null && clust.Task_Migration_Status__c=='IN_PROGRESS')
                    {
                        if(ClusterIdToInprogressTasks.containsKey(clust.Cluster__c)){
                            ClusterIdToInprogressTasks.put(clust.Cluster__c,ClusterIdToInprogressTasks.get(clust.Cluster__c)+1);
                        }
                        else{
                            ClusterIdToInprogressTasks.put(clust.Cluster__c, 1);
                        }
                        if(accIdToInprogressTasks.containsKey(clust.Account_Id__c)){
                            accIdToInprogressTasks.put(clust.Account_Id__c,accIdToInprogressTasks.get(clust.Account_Id__c)+1);
                        }
                        else{
                            accIdToInprogressTasks.put(clust.Account_Id__c, 1);
                        } 
                    }
                }   
            }
            else{
                if(clusterToaccId.keySet().size()>0){
                    for(Id clusterId: clusterToaccId.keySet()){
                        
                        
                        Cluster__c csr=new Cluster__c(Id=clusterId);
                        csr.Total_RSC_Migration_Tasks__c=0;
                        csr.RSC_Migrations_Tasks_Completed__c=0;
                        csr.RSC_Migration_Tasks_Inprogress__c=0;
                        clustersToBeUpdated.add(csr);
                        
                        Account acc=new Account(Id=clusterToaccId.get(clusterId));
                        acc.Total_RSC_Migration_Tasks__c=0;
                        acc.RSC_Migrations_Tasks_Completed__c=0;
                        acc.RSC_Migration_Tasks_Inprogress__c=0;
                        accsToBeUpdated.add(acc);  
                        
                        
                    }
                    
                }
            }
        }
        if(clusterToaccId.size()>0){
            for(Id clusterIdfromContext: clusterToaccId.keySet()){
                if(!clusterIdToAcc.containsKey(clusterIdfromContext)){
                    Cluster__c csr=new Cluster__c(Id=clusterIdfromContext);
                    csr.Total_RSC_Migration_Tasks__c=0;
                    csr.RSC_Migrations_Tasks_Completed__c=0;
                    csr.RSC_Migration_Tasks_Inprogress__c=0;
                    clustersToBeUpdated.add(csr);  
                }
                if( clusterIdToAcc!=null && !clusterIdToAcc.values().contains(clusterToaccId.get(clusterIdfromContext))){
                    Account acc=new Account(Id=clusterToaccId.get(clusterIdfromContext));
                    acc.Total_RSC_Migration_Tasks__c=0;
                    acc.RSC_Migrations_Tasks_Completed__c=0;
                    acc.RSC_Migration_Tasks_Inprogress__c=0;
                    accsToBeUpdated.add(acc);
                }
                
            }
        }
        
        if(clusterIdToTotalTasks.size()>0){
            
            for(Id clusterId:clusterIdToTotalTasks.keySet()){
                if(clusterToaccId.containsKey(clusterId)){
                    Cluster__c csr=new Cluster__c(Id=clusterId);
                    csr.Total_RSC_Migration_Tasks__c=clusterIdToTotalTasks.get(clusterId)!=null?clusterIdToTotalTasks.get(clusterId):0;
                    csr.RSC_Migrations_Tasks_Completed__c=clusterIdToCompletedTasks.get(clusterId)!=null?clusterIdToCompletedTasks.get(clusterId):0;
                    csr.RSC_Migration_Tasks_Inprogress__c=ClusterIdToInprogressTasks.get(clusterId)!=null?ClusterIdToInprogressTasks.get(clusterId):0;
                    clustersToBeUpdated.add(csr);
                    
                    
                    Account acc=new Account(Id=clusterIdToAcc.get(clusterId));
                    acc.Total_RSC_Migration_Tasks__c=accIdToTotalTasks.get(clusterIdToAcc.get(clusterId))!=null?accIdToTotalTasks.get(clusterIdToAcc.get(clusterId)):0;
                    acc.RSC_Migrations_Tasks_Completed__c=accIdToCompletedTasks.get(clusterIdToAcc.get(clusterId))!=null?accIdToCompletedTasks.get(clusterIdToAcc.get(clusterId)):0;
                    acc.RSC_Migration_Tasks_Inprogress__c=accIdToInprogressTasks.get(clusterIdToAcc.get(clusterId))!=null?accIdToInprogressTasks.get(clusterIdToAcc.get(clusterId)):0;
                    accsToBeUpdated.add(acc);
                }
            }
            
            if(clustersToBeUpdated.size()>0){
                Database.update(new List<Cluster__c>(clustersToBeUpdated),false);
                Database.update(new List<Account>(accsToBeUpdated),false);
            }
        }
        
        
    }
    
}