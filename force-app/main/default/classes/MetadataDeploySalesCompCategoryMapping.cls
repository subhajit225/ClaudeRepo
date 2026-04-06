/*MetadataDeploySalesCompCategoryMapping.updateCustomMetadata();*/
public without sharing class MetadataDeploySalesCompCategoryMapping implements Metadata.DeployCallback {
    /** listField*/
    public List<FieldWrapper> listField {get;set;}
    /** FieldWrapper*/
    public class FieldWrapper
    {
        /** fieldName*/
        public String fieldName {get; set;}
        /** fieldAPIName*/
        public String fieldAPIName {get; set;}
    }

                                    
    /** updateCustomMetadata*/
    public static String updateCustomMetadata()
    {
        List<Sales_Comp_Category_Mapping__mdt> sccmRec = getMetaDataRecords();
        System.Debug('sccmRec:-> ' + sccmRec);
        
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        System.Debug('mdContainer:-> ' + mdContainer);
        
        List<Sales_Comp_Category_Mapping_Load__c> uploadList = [SELECT Id, Name, Mapped_Sales_Comp_Category__c, Priority__c, Label__c,  
                                                                Sales_Comp_Category_Mapping_Name__c FROM Sales_Comp_Category_Mapping_Load__c 
                                                                WHERE CreatedDate = TODAY LIMIT 25000];
        System.Debug('uploadList:-> ' + uploadList + ' & uploadList Size: ' + uploadList.size());
        
        for(Sales_Comp_Category_Mapping_Load__c upload: uploadList){
            
            Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
            customMetadata.fullName = 'Sales_Comp_Category_Mapping.'+ upload.Name;//Unique Name
            customMetadata.label = upload.Label__c;
            system.debug('upload.Id:-> '+ upload.Id);
            system.debug('customMetadata.fullName:-> '+ customMetadata.fullName);
            
            Metadata.CustomMetadataValue customField1 = new Metadata.CustomMetadataValue();
            customField1.field = 'Sales_Comp_Category_Mapping_Name__c';
            customField1.value = upload.Sales_Comp_Category_Mapping_Name__c;
            customMetadata.values.add(customField1);
            
            Metadata.CustomMetadataValue customField2 = new Metadata.CustomMetadataValue();
            customField2.field = 'Mapped_Sales_Comp_Category__c';
            customField2.value = upload.Mapped_Sales_Comp_Category__c;
            customMetadata.values.add(customField2);
            
            Metadata.CustomMetadataValue customField3 = new Metadata.CustomMetadataValue(); 
            customField3.field = 'Priority__c';
            customField3.value = upload.Priority__c;
            customMetadata.values.add(customField3);
            
            mdContainer.addMetadata(customMetadata);
        }
                                                                
        System.Debug('mdContainer Final:-> ' + mdContainer);
        
        MetadataDeploySalesCompCategoryMapping callback = new MetadataDeploySalesCompCategoryMapping();
        
        if (!Test.isRunningTest()) { 
            Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
            System.Debug('Job ID is :-> ' + jobId);
        
        }
        return 'Success';
    }
    /**getMetaDataRecords */
    public static List<Sales_Comp_Category_Mapping__mdt> getMetaDataRecords()
    {
        List<Sales_Comp_Category_Mapping__mdt> metadataSCCMRec = [SELECT Id, DeveloperName, Label, Mapped_Sales_Comp_Category__c, Priority__c 
                                                                  FROM Sales_Comp_Category_Mapping__mdt LIMIT 25000];
        System.Debug('metadataSCCMRec :-> ' + metadataSCCMRec);
        return metadataSCCMRec;
    }
    
    /** handleResult*/
    public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
        if(result.status == Metadata.DeployStatus.SUCCEEDED)
        {
            System.debug('Success :==> '+ result);
        }else{
            System.debug('Failure :==> '+ result);
        }
    }
}