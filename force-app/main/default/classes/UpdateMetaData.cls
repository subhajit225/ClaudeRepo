public class UpdateMetaData implements Metadata.DeployCallback,Database.Batchable<sObject>,Schedulable  {
    public void handleResult(Metadata.DeployResult result,Metadata.DeployCallbackContext context) {
    }  
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new UpdateMetaData());
    }
    
    public Database.QueryLocator  start(Database.BatchableContext bc) {
        return Database.getQueryLocator('select id ,Name,DomainAPI__c,Action__c  from DomainsUpdate__c');
    }
    public void execute(Database.BatchableContext bc, List<Sobject> records){
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        for(DomainsUpdate__c dm : (List<DomainsUpdate__c>)records){
            Metadata.CustomMetadata customMetadata =  new Metadata.CustomMetadata();
            customMetadata.fullName = 'Ignored_Domain.'+dm.DomainAPI__c;
            customMetadata.label = dm.Name;
            
            Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
            customField.field = 'isIgnored__c';
            customField.value = dm.Action__c == 'ADD' ? true : false;
            
            customMetadata.values.add(customField);
            mdContainer.addMetadata(customMetadata);
        }
        UpdateMetaData callback = new UpdateMetaData();
        
        // Enqueue custom metadata deployment
        // jobId is the deployment ID
        if(!Test.isRunningTest())Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
    }    
    public void finish(Database.BatchableContext bc){
        delete [SELECT id ,Name,DomainAPI__c,Action__c  from DomainsUpdate__c];
    }    
    
}