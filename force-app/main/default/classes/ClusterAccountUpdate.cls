public with sharing class ClusterAccountUpdate implements Database.Batchable<SObject>, Schedulable{
    public void execute(SchedulableContext sc){
        ClusterAccountUpdate ob = new ClusterAccountUpdate();
        Database.executeBatch(ob, 100);
    }

    public Database.Querylocator start(Database.BatchableContext BC){
        return Database.getQueryLocator('Select Id, Account__c, (Select Id, Asset__c, Asset__r.AccountId from Nodes__r where Asset__c != null) from Cluster__c where archived__c = false');
    }

    public void execute(Database.BatchableContext BC,List<Cluster__c> scope){
        List<Cluster__c> clustersToUpdate = new List<Cluster__c>();
        for(Cluster__c cluster: scope){
            if(cluster.Nodes__r.size()==0){
                continue;
            }
            
            Id accountId = null;
            for(Node__c node: cluster.Nodes__r){
                if(accountId == null){
                    accountId = node.Asset__r.AccountId;
                }
                else if(accountId != node.Asset__r.AccountId){
                    accountId = null;
                    break;
                }
            }

            if(accountId == null){
                continue;
            }

            if(cluster.Account__c != accountId){
                clustersToUpdate.add(new Cluster__c(Id = cluster.Id, Account__c = accountId));
            }
        }

        if(clustersToUpdate.size()>0){
            update clustersToUpdate;
        }
    }

    public void finish(Database.BatchableContext BC){
    }


}