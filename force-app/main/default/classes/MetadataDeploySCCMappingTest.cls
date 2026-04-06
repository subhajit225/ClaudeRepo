/**MetadataDeploySCCMappingTest**/
@isTest
public class MetadataDeploySCCMappingTest{ 
    /**testUpdateCustomMetadata**/
        @isTest 
    public static void testUpdateCustomMetadata(){

            
        Test.startTest();
        Metadata.DeployCallback testcallback = new MetadataDeploySalesCompCategoryMapping();
        Metadata.DeployResult result = new Metadata.DeployResult();
        result.numberComponentErrors = 1;
        Metadata.DeployCallbackContext context = new Metadata.DeployCallbackContext();
        testcallback.handleResult(result, context);
        
        insert new Sales_Comp_Category_Mapping_Load__c(
            Name = 'CLOUDNATIVE_4',
            Label__c = 'RUBRIK GO FOUNDATION EDITION ADD-ON',
            Mapped_Sales_Comp_Category__c ='RUBRIK ENTERPRISE EDITION ADD-ON',
            Sales_Comp_Category_Mapping_Name__c = 'CLOUD NATIVE_RUBRIK_ENTERPRISE_EDITION_ADD_ON',
            Priority__c = '3'
        );
        
        List<Sales_Comp_Category_Mapping_Load__c> lstLod = new List<Sales_Comp_Category_Mapping_Load__c>();
        Sales_Comp_Category_Mapping_Load__c testUpload = new Sales_Comp_Category_Mapping_Load__c();
        insert testUpload;
        lstLod.add(testUpload);
        Assert.areEqual(1, lstLod.size());
        
        Metadata.DeployResult mockResult = new Metadata.DeployResult();
        mockResult.status = Metadata.DeployStatus.SUCCEEDED;
        
        //Metadata.DeployCallbackContext mockContext = new Metadata.DeployCallbackContext();
        
        Metadata.DeployContainer mockContainer = new Metadata.DeployContainer();
        mockContainer.addMetadata(new Metadata.CustomMetadata());
        
        //Id mockJobId = 'a6B5C0000003Z9nUAE';
        
        //MetadataDeploySalesCompCategoryMapping callback = new MetadataDeploySalesCompCategoryMapping();
        MetadataDeploySalesCompCategoryMapping.updateCustomMetadata();
        Test.stopTest();
    }
}