public class UpdateCustomMetadata implements Queueable {
    Public string LastModifiedDate;
    public UpdateCustomMetadata(string LastModifiedDate){
      this.LastModifiedDate = LastModifiedDate;
    }
    public void execute(QueueableContext context) {
        Metadata.CustomMetadata customMetadata =  new Metadata.CustomMetadata();
        customMetadata.fullName = 'Territory_Management_Setup__mdt.Con_OTA_LMDT';
        customMetadata.Label = 'Con OTA LMDT';
        Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
        customField.field = 'Field_Value__c';
        customField.value = LastModifiedDate;
        customMetadata.values.add(customField);
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        mdContainer.addMetadata(customMetadata);
        PostMetaDataUpdateCallback callback = new PostMetaDataUpdateCallback();
        Id jobId = Test.isRunningTest() ? '01q1k000001fR4C' : Metadata.Operations.enqueueDeployment(mdContainer, callback);      
    }
}