public with sharing class AssetDatesUpdateFromParent_Batch implements Database.Batchable<SObject>, Schedulable {
    public void execute(SchedulableContext sc){
        AssetDatesUpdateFromParent_Batch ob = new AssetDatesUpdateFromParent_Batch();
        Database.executeBatch(ob, 100);
    }

    public Database.Querylocator start(Database.BatchableContext BC){
        return Database.getQueryLocator('Select Id, Support_Start_Date__c, Premium_Support_End_Date__c, Parent.Support_Start_Date__c, Parent.Premium_Support_End_Date__c from Asset where ParentId != null and Product2.Name like \'X-%\'');
    }

    public void execute(Database.BatchableContext BC,List<Asset> scope){
        List<Asset> assetsToUpdate = new List<Asset>();
        for(Asset ast: scope){
            if((ast.Parent.Support_Start_Date__c != null && ast.Support_Start_Date__c != ast.Parent.Support_Start_Date__c) ||
             (ast.Parent.Premium_Support_End_Date__c != null && ast.Premium_Support_End_Date__c != ast.Parent.Premium_Support_End_Date__c)){
                assetsToUpdate.add(new Asset(Id = ast.Id, Support_Start_Date__c = ast.Parent.Support_Start_Date__c, Premium_Support_End_Date__c = ast.Parent.Premium_Support_End_Date__c));
            }
        }

        if(assetsToUpdate.size()>0){
            AssetTriggerHelper.allowSupportStartDateUpdate(true);
            update assetsToUpdate;
            AssetTriggerHelper.allowSupportStartDateUpdate(false);
        }
    }

    public void finish(Database.BatchableContext BC){
    }

}