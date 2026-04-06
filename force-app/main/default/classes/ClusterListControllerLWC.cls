/*
* Class Name :- ClusterListControllerLWC
* Author :- Ashish Thakur - Grazitti
* Created-Date :- 23-03-2022
* Description : This Controller is Cluster list Controller for lGT_ClusterListLWC Component


* -------------------------- @History --------------------------------------------------------------------------------------------
* Story Number       Modified By              Date           Description
* CS21-1939        	Raveesh Layal	         10-06-2023     Added fields to showcase on Case page.
* --------------------------------------------------------------------------------------------------------------------------------
*/


public with sharing class ClusterListControllerLWC {
    
       
     @AuraEnabled(cacheable=true)
     public static List<ClusterWrapper> getClusterListLWC(String caseId, Boolean showLess){
        Case caseRecord = [SELECT Id,AccountId FROM Case WHERE id =: caseId];
        List<Cluster__c> accountRelatedClusterList = new List<Cluster__c>();
        if(showLess == true){
            accountRelatedClusterList = [SELECT Id, Name, tag__c, software_version__c, archived__c,account__r.Total_RSC_Migration_Tasks__c, account__r.RSC_Migrations_Tasks_Completed__c,account__r.RSC_Migration_Tasks_Inprogress__c,Overall_Cluster_Migration__c, account__r.Overall_Cluster_Migration__c,RSC_Migrations_Tasks_Completed__c,Total_RSC_Migration_Tasks__c,RSC_Migration_Tasks_Inprogress__c  FROM Cluster__c WHERE account__c =: caseRecord.AccountId AND archived__c = false Order By LastModifiedDate desc LIMIT 5];
        }
        else{
              accountRelatedClusterList = [SELECT Id, Name, tag__c, software_version__c, archived__c,account__r.Total_RSC_Migration_Tasks__c, account__r.RSC_Migrations_Tasks_Completed__c,account__r.RSC_Migration_Tasks_Inprogress__c,Overall_Cluster_Migration__c, account__r.Overall_Cluster_Migration__c,RSC_Migrations_Tasks_Completed__c,Total_RSC_Migration_Tasks__c,RSC_Migration_Tasks_Inprogress__c  FROM Cluster__c WHERE account__c =: caseRecord.AccountId AND archived__c = false Order By LastModifiedDate desc];
        }
        if(accountRelatedClusterList != null && !accountRelatedClusterList.isEmpty()){
        return testcalculate(caseRecord.AccountId,showLess,accountRelatedClusterList);
        }
        else{
            return new List<ClusterWrapper>();
        }

    }
    
    public static list<ClusterWrapper> testcalculate(String accountId,Boolean showLess,list<cluster__c>clusterData){
        list<ClusterWrapper> wrapper=new list<ClusterWrapper>();
   
        map<id,Decimal> clusterIdToNoOfSLAsMigrated=new map<id,Decimal>();
        map<id,Decimal> clusterIdToNoOfSLAsWithObjects=new map<id,Decimal>();
        
        map<id,Decimal> accountIdToNoOfSLAsMigrated=new map<id,Decimal>();
        map<id,Decimal> accountIdToNoOfSLAsWithObjects=new map<id,Decimal>();
       
        list<RSC_Migration_Tasks__c> rscTask=[select id,No_of_SLAs_migrated__c,No_of_SLAs_with_objects__c,Cluster__c,Cluster__r.account__c from RSC_Migration_Tasks__c where Cluster__r.account__c=:accountId];
        for(RSC_Migration_Tasks__c rsc:rscTask)
        {
            //Map of Cluster Id TO No of SLAMigrated
            if(clusterIdToNoOfSLAsMigrated.containskey(rsc.Cluster__c)){
             
               clusterIdToNoOfSLAsMigrated.put(rsc.Cluster__c,clusterIdToNoOfSLAsMigrated.get(rsc.Cluster__c)+(rsc.No_of_SLAs_migrated__c!=null ? rsc.No_of_SLAs_migrated__c:0)); 
               
            }
            else{
               clusterIdToNoOfSLAsMigrated.put(rsc.Cluster__c,rsc.No_of_SLAs_migrated__c!=null?rsc.No_of_SLAs_migrated__c:0); 

            }
            
            if(clusterIdToNoOfSLAsWithObjects.containskey(rsc.Cluster__c))
            {
             clusterIdToNoOfSLAsWithObjects.put(rsc.Cluster__c,clusterIdToNoOfSLAsWithObjects.get(rsc.Cluster__c)+(rsc.No_of_SLAs_with_objects__c!=null ? rsc.No_of_SLAs_with_objects__c:0)); 
               
            }else{
               clusterIdToNoOfSLAsWithObjects.put(rsc.Cluster__c,rsc.No_of_SLAs_with_objects__c!=null?rsc.No_of_SLAs_with_objects__c:0); 
            }
            
            if(accountIdToNoOfSLAsMigrated.containskey(rsc.Cluster__r.account__c )){
               accountIdToNoOfSLAsMigrated.put(rsc.Cluster__r.account__c ,accountIdToNoOfSLAsMigrated.get(rsc.Cluster__r.account__c )+(rsc.No_of_SLAs_migrated__c!=null ? rsc.No_of_SLAs_migrated__c:0)); 
               
            }
            else{
               accountIdToNoOfSLAsMigrated.put(rsc.Cluster__r.account__c ,rsc.No_of_SLAs_migrated__c!=null?rsc.No_of_SLAs_migrated__c:0); 
             
            }
            if(accountIdToNoOfSLAsWithObjects.containskey(rsc.Cluster__r.account__c ))
            {
             accountIdToNoOfSLAsWithObjects.put(rsc.Cluster__r.account__c ,accountIdToNoOfSLAsWithObjects.get(rsc.Cluster__r.account__c )+(rsc.No_of_SLAs_with_objects__c!=null ? rsc.No_of_SLAs_with_objects__c:0)); 
               
            }else{
               accountIdToNoOfSLAsWithObjects.put(rsc.Cluster__r.account__c ,rsc.No_of_SLAs_with_objects__c!=null?rsc.No_of_SLAs_with_objects__c:0); 
            }
          
        }
       
         wrapper.add(new ClusterWrapper(clusterIdToNoOfSLAsMigrated,clusterIdToNoOfSLAsWithObjects,accountIdToNoOfSLAsMigrated,accountIdToNoOfSLAsWithObjects,clusterData));
            return wrapper;
    }
    Public class ClusterWrapper{
        @AuraEnabled Public  map<id,Decimal> clusterIdToNoOfSLAsMigrated { get; set; }
        @AuraEnabled Public  map<id,Decimal> clusterIdToNoOfSLAsWithObjects { get; set; }
        
        @AuraEnabled Public  map<id,Decimal> accountIdToNoOfSLAsMigrated { get; set; }
        @AuraEnabled Public  map<id,Decimal> accountIdToNoOfSLAsWithObjects { get; set; }
        @AuraEnabled public  List<Cluster__c> clusterList{get;set;}
        
         public ClusterWrapper(map<id,Decimal> clusterIdToNoOfSLAsMigrated,map<id,Decimal> clusterIdToNoOfSLAsWithObjects,map<id,Decimal> accountIdToNoOfSLAsMigrated,map<id,Decimal> accountIdToNoOfSLAsWithObjects,list<cluster__c> clusterList){
             this.clusterIdToNoOfSLAsMigrated=clusterIdToNoOfSLAsMigrated;
             this.clusterIdToNoOfSLAsWithObjects=clusterIdToNoOfSLAsWithObjects;
             this.accountIdToNoOfSLAsMigrated=accountIdToNoOfSLAsMigrated;
             this.accountIdToNoOfSLAsWithObjects=accountIdToNoOfSLAsWithObjects;
             this.clusterList=clusterList;
         }
    }
    
}