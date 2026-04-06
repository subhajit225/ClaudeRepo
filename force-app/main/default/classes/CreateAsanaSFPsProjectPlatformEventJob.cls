/**
* @File Name : CreateAsanaSFPsProjectPlatformEventJob.cls
* @Description : publish platform even whenever ps project is created
* @Author : Yoganand Gadekar
* @Last Modified By : Yoganand Gadekar
* @Last Modified On : Sep 25, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | Sep 25, 2025 | Yoganand Gadekar  | Initial Version
**/

/*
    * @description class that implmenents queable
    */
public class CreateAsanaSFPsProjectPlatformEventJob implements Queueable {
    // Use a Set<Id> to hold the IDs passed from the trigger
    private Set<Id> parentIdsToProcess;
    
    /*
    * @description class that implmenents queable
    * @param Ids
    */
    public createAsanaSFPsProjectPlatformEventJob(Set<Id> ids) {
        this.parentIdsToProcess = ids;
    }
    
     /**@description  publish platform event when ps project is created
    * @param QueueableContext
    */
    public void execute(QueueableContext context) {
      Map<Id, Id> orderIdToProjectIdMap = new Map<Id, Id>();
        List<Salesforce_PS_Project_Created__e> asanaSFPsProjectEventList = new List<Salesforce_PS_Project_Created__e>();
        
        List<PS_Project__c> ProjectList = [Select id, Asana_Project_Id__c, Project_Manager__c,Project_Manager__r.email, Opportunity__c ,ownerId,Name,Welcome_Letter_Contact__r.Name,(select id, PS_Project__c from Orders__r)  from PS_Project__c where id IN : parentIdsToProcess];//new change
        List<Error_Logs__c> IntegrationLogs = new List<Error_Logs__c>();
        
        for(PS_Project__c psProject : ProjectList){                
                for(Order od : psProject.Orders__r){
                    orderIdToProjectIdMap.put(od.Id, psProject.Id);
                }
                              
                Salesforce_PS_Project_Created__e asanaSFPsProjectEvent = new Salesforce_PS_Project_Created__e();
                asanaSFPsProjectEvent.Project_Id__c = psProject.Id;
                asanaSFPsProjectEvent.Project_Name__c = psProject.Name;
                asanaSFPsProjectEvent.Project_Owner__c = psProject.ownerId;
                asanaSFPsProjectEvent.Welcome_Letter_Contact_Name__c = psProject.Welcome_Letter_Contact__r.Name;
                asanaSFPsProjectEvent.Asana_Project_Id__c = psProject.Asana_Project_Id__c;
                if(psProject.Project_Manager__c != null){
                   asanaSFPsProjectEvent.Project_Owner_Email__c = psProject.Project_Manager__r.email;
                }

                asanaSFPsProjectEventList.add(asanaSFPsProjectEvent);
            
        }

        Set<String> productCodeList = new Set<String>();
        List<OrderItem> orderItemList = new List<OrderItem>();
        List<Order> orderList = [select Id, OpportunityId, PS_Project__c from Order where Id IN : orderIdToProjectIdMap.keySet()];

        if(!orderList.isEmpty()){
            orderItemList = [select Id, Order.PS_Project__c, Order.OpportunityId, Product2.ProductCode, Quote_Subscription_Term__c, Quantity from OrderItem where orderId IN : orderList];
            for(OrderItem ordItm : orderItemList){
                productCodeList.add(ordItm.Product2.ProductCode);
            }
        }

        Map<String, Asana_PS_Configuration__c> skuToAsanaConfigMap = new Map<String, Asana_PS_Configuration__c>();
        for(Asana_PS_Configuration__c asanaConfig : [SELECT Id, SKU__c, Task_Label__c, Task_Type__c, Is_PS_SKU__c,Quantity_or_Subscription__c,Asana_Section_template_Id__c FROM Asana_PS_Configuration__c WHERE SKU__c IN : productCodeList]){
            if(!skuToAsanaConfigMap.containsKey(asanaConfig.SKU__c)){
                skuToAsanaConfigMap.put(asanaConfig.SKU__c, asanaConfig);
            }
        }

        Map<Id, List<ProductSummaryWrapper>> psProjectIdToProductSummaryListMap = new Map<Id, List<ProductSummaryWrapper>>();
        Map<Id, Map<String, ProductSummaryWrapper>> psProjectIdToSkuWrapperMap = new Map<Id, Map<String, ProductSummaryWrapper>>(); // added for MKT-11
        Decimal quantity;
        Decimal subscriptionTerm;
        String gId;
        
        for(OrderItem orderItm : orderItemList){
            String skuCode = orderItm.Product2.ProductCode; // added for MKT-11
            quantity = null;
            subscriptionTerm = null;
            if(skuToAsanaConfigMap.containsKey(skuCode)){ // modified for MKT-11
                Id projectId = orderIdToProjectIdMap.get(orderItm.OrderId); // added for MKT-11
                if(!psProjectIdToSkuWrapperMap.containsKey(projectId)){ // modified for MKT-11
                    psProjectIdToSkuWrapperMap.put(projectId, new Map<String, ProductSummaryWrapper>()); // modified for MKT-11
                }
                
                Asana_PS_Configuration__c config = skuToAsanaConfigMap.get(skuCode); // added for MKT-11
                String taskTypeTaskLabelName = config.Task_Type__c+' - '+ config.Task_Label__c; // modified for MKT-11
                
                If(config.Quantity_or_Subscription__c == 'Quantity'){ // modified for MKT-11
                   quantity = orderItm.Quantity;
                }
                else{
                   subscriptionTerm = orderItm.Quote_Subscription_Term__c;
                }
                
                gId = config.Asana_Section_template_Id__c; // modified for MKT-11
                Map<String, ProductSummaryWrapper> skuWrapperMap = psProjectIdToSkuWrapperMap.get(projectId);
                
                if(skuWrapperMap.containsKey(skuCode)){ // added for MKT-11
                    ProductSummaryWrapper existingWrapper = skuWrapperMap.get(skuCode);
                    if(quantity != null){
                        existingWrapper.quantity = (existingWrapper.quantity == null ? 0 : existingWrapper.quantity) + quantity;
                    }
                    if(subscriptionTerm != null){
                        existingWrapper.subscriptionTerm = (existingWrapper.subscriptionTerm == null ? 0 : existingWrapper.subscriptionTerm) + subscriptionTerm;
                    }
                } else {
                    skuWrapperMap.put(skuCode, new ProductSummaryWrapper(skuCode, taskTypeTaskLabelName, quantity, subscriptionTerm, gId));
            }            
        }
        }
        
        /* Converting the aggregated map to original list structure */
        for(Id projId : psProjectIdToSkuWrapperMap.keySet()){ // added for MKT-11
            psProjectIdToProductSummaryListMap.put(projId, new List<ProductSummaryWrapper>(psProjectIdToSkuWrapperMap.get(projId).values()));
        }
       
        for(Salesforce_PS_Project_Created__e asanaSFPsProjectEvent : asanaSFPsProjectEventList){
            if(psProjectIdToProductSummaryListMap.containsKey(asanaSFPsProjectEvent.Project_Id__c)){
                String finalJsonString = '[';
                for (Integer i = 0; i < psProjectIdToProductSummaryListMap.get(asanaSFPsProjectEvent.Project_Id__c ).size(); i++) {
                    // Serialize one wrapper at a time
                    finalJsonString += JSON.serialize(psProjectIdToProductSummaryListMap.get(asanaSFPsProjectEvent.Project_Id__c )[i]);
            
                    // Add a comma after each item except the last one
                    if (i < psProjectIdToProductSummaryListMap.get(asanaSFPsProjectEvent.Project_Id__c ).size() - 1) {
                        finalJsonString += ',';
                    }
                }
            
                finalJsonString += ']';
                asanaSFPsProjectEvent.Order_Product_Summary__c = finalJsonString;
                
            }
        }
        
        if(!asanaSFPsProjectEventList.isEmpty() && psProjectIdToProductSummaryListMap.keyset().size() > 0){
            List<Database.SaveResult> results = EventBus.publish(asanaSFPsProjectEventList);
            try{
            List<Error_Logs__c> elList = new List<Error_Logs__c>();
              for (Database.SaveResult sr : results) {
                    if (sr.isSuccess()) {
                          Error_Logs__c el = new Error_Logs__c();
                          el.Success__c = true;
                          el.Error_Type__c ='Asana Platform Event';
                          el.Type__c ='Integration';  
                          el.Error_Message__c= string.valueof(psProjectIdToProductSummaryListMap);  
                          elList.add(el);
                     }                 
                 
              }
              Database.Insert(elList,false);
            }
            catch(exception e){
              system.debug(LoggingLevel.DEBUG,e);  
            }
            
        } 
    }
    
    /*
    * @description wrapper class for building json that includes the product details
    */
    public class ProductSummaryWrapper {
        public String sku;
        public String name;
        public Decimal quantity;
        public Decimal subscriptionTerm;
        public String gid;
        
      /*
    * @description class cons
    *@param sku
    *@param name
    *@param quantity
    *@param subscriptionTerm
    *@param gid
    */
     public ProductSummaryWrapper(String sku, String name, Decimal quantity, Decimal subscriptionTerm, String gid) {
            this.sku = sku;
            this.name = name;
            this.quantity = quantity;
            this.subscriptionTerm = subscriptionTerm;
            this.gid = gid;
        }
    }
}