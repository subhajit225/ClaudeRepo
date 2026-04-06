/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 11-05-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public  without sharing class POCRequestTriggerHelper {
    public static final String APPLIANCE_PREM_SUPPORT_PRODUCT_CODE = 'RBK-SVC-PREM-APPLIANCE';
    public static final String RUBRIK_APPLIANCE_RSCG_PRODUCT_CODE = 'RS-BT-FE-RSCG-PE-PP';
    public static final String RUBRIK_APPLIANCE_PRODUCT_CODE = 'RS-BT-FE-PE-PP';
    public static final String RCV_ARCHIVE_PRODUCT_CODE = 'RS-BT-CVA-PE-PP';
    public static final String RCV_BACKUP_PRODUCT_CODE = 'RS-BT-CVB-PE-PP';
    public static final String POCPHASESTATUS = 'In Progress';
    @testVisible
    private static final String POC_APPROVAL_EXCEPTION_MESSAGE = 'Operation not permitted. Please contact your manager for assistance.';
    private static Map<String, String> productCodeToOption = new Map<String, String>();
    private static Map<String, String> productCodeToRequiredBy = new Map<String, String>();
    public static string pocType;
    public static Set<Id> runTriggerOnce = new Set<Id>();
    public static Set<String> allSkusRecord = new Set<String>();
    public static Order_control__mdt checkRSCPostCall = Order_control__mdt.getInstance('Enable_Polaris_Fulfilment_SFPost');
// MKT23-496 //
    /**
     * @description Synchronizes POC (Proof of Concept) lines by mapping product categories to SKUs.
     * This Extracts product categories from the POC records.
     * Fetches  corresponding SKUs and mappings from the Product Picker metadata.
     * @param newPOCMap A map of POC records where the key is the POC Id and the value is the POC record.This map contains newly created or updated POC records.
     */
    public static void syncPOCLines(Map<Id, POC__c> newPOCMap) {
        Map<Id, Set<String>> pocIdToCategories = new Map<Id, Set<String>>();
        Set<String> allCategories = new Set<String>();
                for(Id pocId : newPOCMap.keySet()) {
            POC__c poc = newPOCMap.get(pocId);
            pocType = poc.POC_Type__c;
            //get the product categories
            if(poc.Product_Categories__c != null){
                List<String> categories = poc.Product_Categories__c.split(';');
                pocIdToCategories.put(poc.Id, new Set<String>(categories));
                allCategories.addAll(categories);
            }
        }

        if(!pocIdToCategories.isEmpty()){
            Map<String, String> criteriaToSKUs = new Map<String, String>();
            Map<String, Id> skuToId = new Map<String, Id>();
            for(POC_Product_Picker_Matrix__mdt matrix: [SELECT MasterLabel, Criteria__c, Sub_criteria__c, Product_SKU__c, POC_Option__c, Required_By__c, OPTY_POC_Product_Picker_Type__r.Custom_Master_Label__c, Polaris_Platform__c
                                                        FROM POC_Product_Picker_Matrix__mdt
                                                        WHERE OPTY_POC_Product_Picker_Type__r.Custom_Master_Label__c IN :allCategories]) {
                                                            String key = matrix.Polaris_Platform__c+'$$'+matrix.OPTY_POC_Product_Picker_Type__r.Custom_Master_Label__c;
                                                            if(matrix.Criteria__c != null) 
                                                                key = (key+'=='+matrix.Criteria__c.toLowerCase());
                                                            if(matrix.Sub_criteria__c != null) 
                                                                key = (key+'::'+matrix.Sub_criteria__c.toLowerCase());
                                                            criteriaToSKUs.put(key, matrix.Product_SKU__c);
                                                            //updated for MKT26-410
                                                            if( matrix.OPTY_POC_Product_Picker_Type__r.Custom_Master_Label__c == 'Rubrik Cloud Vault' || matrix.OPTY_POC_Product_Picker_Type__r.Custom_Master_Label__c == 'Rubrik Cloud Vault - Government' || matrix.OPTY_POC_Product_Picker_Type__r.Custom_Master_Label__c == 'SaaS (Jira Cloud, Salesforce)' || matrix.OPTY_POC_Product_Picker_Type__r.Custom_Master_Label__c == 'RSC Enterprise and Proactive Editions' || matrix.OPTY_POC_Product_Picker_Type__r.Custom_Master_Label__c == 'RSC-G Enterprise and Proactive Editions' || matrix.OPTY_POC_Product_Picker_Type__r.Custom_Master_Label__c == 'RSC-Private') {
                                                                criteriaToSKUs.put(matrix.Polaris_Platform__c+'$$'+matrix.Masterlabel, matrix.Product_SKU__c);
                                                            }
                                                            
                                                            for(String code : matrix.Product_SKU__c.split(';')) {
                                                                skuToId.put(code, null);
                                                                if(matrix.Required_By__c != null && code != matrix.Required_By__c ){
                                                                    if(productCodeToRequiredBy.containsKey(code))
                                                                        productCodeToRequiredBy.put(code, productCodeToRequiredBy.get(code) + ';' + matrix.Required_By__c);
                                                                    else 
                                                                        productCodeToRequiredBy.put(code, matrix.Required_By__c);
                                                                }
                                                            }
                                                            if(matrix.POC_Option__c != null){
                                                                List<String> prodCodeAndOption = matrix.POC_Option__c.split('=>');
                                                                productCodeToOption.put(prodCodeAndOption[0], prodCodeAndOption[1]);
                                                            }
                                                        }
            //add SAP Hana/Kubernetes protection SKUs
            for(POC_Product_Picker_Matrix__mdt matrix: [SELECT Product_SKU__c, MasterLabel, Polaris_Platform__c
                                                        FROM POC_Product_Picker_Matrix__mdt
                                                        WHERE MasterLabel = 'Kubernetes'
                                                        OR MasterLabel = 'SAP_HANA']) {
                                                            criteriaToSKUs.put(matrix.Polaris_Platform__c+'$$'+matrix.MasterLabel, matrix.Product_SKU__c);
                                                            for(String code : matrix.Product_SKU__c.split(';'))
                                                                skuToId.put(code, null);
                                                        }
            skuToId.put(RUBRIK_APPLIANCE_RSCG_PRODUCT_CODE, null);                                  
            Set<String> allSKUs = skuToId.keySet();
            for(Product2 prod : [SELECT Id, ProductCode FROM Product2 WHERE productCode IN :allSKUs AND IsActive= true]){
                skuToId.put(prod.ProductCode, prod.Id);
            }
            // get default Product to Add//
            /*set<String> defaultProductCode = new set<String>();
            String defaultskuToId = '';
            defaultProductCode.add('RS-BT-RCDM-T');
            List<Product2> prodDefault = [SELECT Id, ProductCode FROM Product2 WHERE productCode IN :defaultProductCode AND IsActive= true];
           if(prodDefault.size()>0) 
               defaultskuToId=prodDefault[0].Id;
               */
           
            List<POC_Line__c> linesToInsert = new List<POC_Line__c>();
            Boolean isNASAndRCVCloudSelected = false;
            Boolean isUCLWithRCV = false;
            Boolean isArchiveSelected = false;
            Boolean isBackupSelected = false;
            
            if(allCategories.contains('NAS Cloud Direct') && ((!allCategories.contains('Rubrik Cloud Vault') && !allCategories.contains('UCL (Cloud Cluster, Cloud Native & Entra ID)') ) ||  allCategories.size() == 1 )){
                isNASAndRCVCloudSelected = true;
            }
            if(allCategories.contains('UCL (Cloud Cluster, Cloud Native & Entra ID)') && (!allCategories.contains('Rubrik Cloud Vault') ||  allCategories.size() == 1 )){
                isUCLWithRCV = true;
            }
            
            for(Id pocId : pocIdToCategories.keySet()){
                String platform = newPOCMap.get( pocId ).Polaris_Platfrom__c;
                Set<String> productCategories = pocIdToCategories.get(pocId);
                for(String category : pocIdToCategories.get(pocId)){
                    if('Edge' == category
                       //|| 'Polaris GPS and Radar' == category
                       //|| 'Polaris Sonar' == category
                        || 'Polaris Cloud Native Protection' == category
                        || 'RSC Enterprise Edition' == category
                        || 'Ransomware Monitoring & Investigation' == category
                        || 'Sensitive Data Monitoring & Remediation' == category
                        || 'Orchestrated Application Recovery' == category
                       	|| 'RSC 3rd Party S/W With Enterprise Ed.' == category
                        /*|| 'RSC-Private with Enterprise Edition' == category*/ //Commented for MKT26-93
                        || 'SAP HANA for Cloud Cluster' == category
                       	|| 'RSC Proactive Edition' == category
                        || 'Laminar' == category
                        || 'Data Security Posture Management' == category
                        || 'RSC-G Enterprise Edition' == category
                        || 'RSC-G Proactive Edition' == category
                        || 'RSC-G Third Party Software with Enterprise Edition' == category

                       //|| 'Polaris AppFlows' == category
                      ) {
                          //directly add the SKUS
                          
                          linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$'+category), skuToId, pocId, 1, category));
                      } 
                    else if( 'NAS Cloud Direct' == category){
                        linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$'+'NAS Cloud Direct'+'=='+newPOCMap.get(pocId).NCD_Editions__c.toLowerCase()), skuToId, pocId,Integer.valueOf(newPOCMap.get(pocId).Number_Of_NCD_FETB__c), category));
                        
                        isArchiveSelected = ('Yes' == newPOCMap.get(pocId).RCV_Archive_Tier__c && !isArchiveSelected);
                        isBackupSelected = ('Yes' == newPOCMap.get(pocId).RCV_Backup_Tier__c && !isBackupSelected);
                        
                        if(('Yes' == newPOCMap.get(pocId).RCV_Archive_Tier__c ) && newPOCMap.get(pocId).NCD_Editions__c != 'Business Edition Customer Hosted (Ransomware Monitoring)' && ( isNASAndRCVCloudSelected || isArchiveSelected)){
                            if(newPOCMap.get(pocId).Data_Redundancy_Archive_NAS__c == 'Single Zone (LRS)'){
                                linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$'+category+'==archive'), skuToId, pocId, Integer.valueOf(newPOCMap.get(pocId).Archive_TB__c), category));
                            }
                            if(newPOCMap.get(pocId).Data_Redundancy_Archive_NAS__c == 'Multi Zone (ZRS)'){
                                linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$'+category+'==multi zone'), skuToId, pocId, Integer.valueOf(newPOCMap.get(pocId).Archive_TB__c), category));
                            }
                        }
                        if(('Yes' == newPOCMap.get(pocId).RCV_Backup_Tier__c) && newPOCMap.get(pocId).NCD_Editions__c != 'Business Edition Customer Hosted (Ransomware Monitoring)' && ( isNASAndRCVCloudSelected  || isBackupSelected )){
                            if(newPOCMap.get(pocId).Data_Redundancy_Backup_NAS__c == 'Single Zone (LRS)'){
                                linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$'+category+'==backup'), skuToId, pocId, Integer.valueOf(newPOCMap.get(pocId).Backup_TB__c), category));
                            }
                            if(newPOCMap.get(pocId).Data_Redundancy_Backup_NAS__c == 'Multi Zone (ZRS)'){
                                linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$'+category+'==multiple zone'), skuToId, pocId, Integer.valueOf(newPOCMap.get(pocId).Backup_TB__c), category));
                            }
                            if(newPOCMap.get(pocId).Data_Redundancy_Backup_NAS__c == 'Multi Region (GRS)'){
                                linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$'+category+'==multi region'), skuToId, pocId, Integer.valueOf(newPOCMap.get(pocId).Backup_TB__c), category));
                            }
                        }
                    }
                    else if('Rubrik Cloud Vault' == category || 'Rubrik Cloud Vault - Government' == category ) {
                        if('Rubrik Cloud Vault - Government' == category ){
                            if(!isArchiveSelected && 'Yes' == newPOCMap.get(pocId).RCV_Archive_Tier__c && 'Single Zone (LRS)' == newPOCMap.get(pocId).Data_Redundancy_Archive__c){
                            linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$'+'Rubrik Cloud Vault - Government Archive'), skuToId, pocId, Integer.valueOf(newPOCMap.get(pocId).Archive_TB__c), category));
                        }
                            if(!isArchiveSelected && 'Yes' == newPOCMap.get(pocId).RCV_Backup_Tier__c && 'Single Zone (LRS)' == newPOCMap.get(pocId).Data_Redundancy_Backup__c){
                            linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$'+'Rubrik Cloud Vault - Government Backup'), skuToId, pocId, Integer.valueOf(newPOCMap.get(pocId).Backup_TB__c), category));
                        }
                            if(!isArchiveSelected && 'Yes' == newPOCMap.get(pocId).RCV_Backup_Tier__c && 'Multi Region (GRS)' == newPOCMap.get(pocId).Data_Redundancy_Backup__c){
                                linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$'+'Rubrik Cloud Vault -Government MultiReg'), skuToId, pocId, Integer.valueOf(newPOCMap.get(pocId).Backup_TB__c), category));
                            }
                            if(!isArchiveSelected && 'Yes' == newPOCMap.get(pocId).RCV_Backup_Tier__c && 'Multi Zone (ZRS)' == newPOCMap.get(pocId).Data_Redundancy_Backup__c){
                                linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$'+'Rubrik Cloud Vault -Government MultiZone'), skuToId, pocId, Integer.valueOf(newPOCMap.get(pocId).Backup_TB__c), category));
                        }

                        }
                        if('Rubrik Cloud Vault' == category){
                        if(!isArchiveSelected && 'Yes' == newPOCMap.get(pocId).RCV_Archive_Tier__c && 'Multi Zone (ZRS)' == newPOCMap.get(pocId).Data_Redundancy_Archive__c){
                            linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$'+'Multi Zone Archive'), skuToId, pocId, Integer.valueOf(newPOCMap.get(pocId).Archive_TB__c), category));
                        }
                        if(!isBackupSelected && 'Yes' == newPOCMap.get(pocId).RCV_Backup_Tier__c && 'Multi Zone (ZRS)' == newPOCMap.get(pocId).Data_Redundancy_Backup__c){
                            linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$'+'Multi Zone Backup'), skuToId, pocId, Integer.valueOf(newPOCMap.get(pocId).Backup_TB__c), category));
                        }
                        if( !isBackupSelected  && 'Yes' == newPOCMap.get(pocId).RCV_Backup_Tier__c && 'Multi Region (GRS)' == newPOCMap.get(pocId).Data_Redundancy_Backup__c){
                            linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$'+'Multi Region Backup'), skuToId, pocId, Integer.valueOf(newPOCMap.get(pocId).Backup_TB__c), category));
                        }
                        if( !isArchiveSelected  && 'Yes' == newPOCMap.get(pocId).RCV_Archive_Tier__c && 'Single Zone (LRS)' == newPOCMap.get(pocId).Data_Redundancy_Archive__c){
                            linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$'+category+' Archive'), skuToId, pocId, Integer.valueOf(newPOCMap.get(pocId).Archive_TB__c), category));
                        }
                        if( !isBackupSelected  &&'Yes' == newPOCMap.get(pocId).RCV_Backup_Tier__c && 'Single Zone (LRS)' == newPOCMap.get(pocId).Data_Redundancy_Backup__c){
                            linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$'+category+' Backup'), skuToId, pocId, Integer.valueOf(newPOCMap.get(pocId).Backup_TB__c), category));
                        }
					}
                        if(!isArchiveSelected && 'Yes' == newPOCMap.get(pocId).RCV_Archive_Tier__c && newPOCMap.get(pocId).Data_Redundancy_Archive__c != null){
                            isArchiveSelected = true;
                        }
                        if(!isBackupSelected && 'Yes' == newPOCMap.get(pocId).RCV_Backup_Tier__c && newPOCMap.get(pocId).Data_Redundancy_Backup__c != null){
                            isBackupSelected = true;
                        }
                    }  else if('SaaS (Jira Cloud, Salesforce, Dynamics)' == category){
                        if('Yes' == newPOCMap.get(pocId).Salesforce__c || 'Yes' == newPOCMap.get(pocId).Jira_Cloud__c || 'Yes' == newPOCMap.get(pocId).Dynamics__c){
                            Integer salesforceNumbers = 'Yes' == newPOCMap.get(pocId).Salesforce__c ? Integer.valueOf(Math.ceil(newPOCMap.get(pocId).Number_of_Users_Salesforce__c)) : 0;
                            Integer jiraNumbers = 'Yes' == newPOCMap.get(pocId).Jira_Cloud__c ? Integer.valueOf(Math.ceil(newPOCMap.get(pocId).Number_of_Users_Atlassian__c)) : 0;
                            Integer dynamicNumbers = 'Yes' == newPOCMap.get(pocId).Dynamics__c ? Integer.valueOf(Math.ceil(newPOCMap.get(pocId).Number_of_Users_Dynamics__c)) : 0;
                            Integer sumOfSaasUsers = salesforceNumbers + jiraNumbers + dynamicNumbers;
                            linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$SaaS (Jira Cloud, Salesforce, Dynamics)'+'==saas'), skuToId, pocId, sumOfSaasUsers, category));
                        }
                        // if('Yes' == newPOCMap.get(pocId).Salesforce__c && newPOCMap.get(pocId).Hosting_Environment_Salesforce__c == 'Rubrik Hosted Foundation Edition plus DevOps Add-on'){
                        //     linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$Rubrik Hosted Foundation & DevOps'), skuToId, pocId, Integer.valueOf(Math.ceil(newPOCMap.get(pocId).Number_of_Users_Salesforce__c)), category));
                        // }	
                        // if('Yes' == newPOCMap.get(pocId).Salesforce__c && newPOCMap.get(pocId).Hosting_Environment_Salesforce__c == 'Rubrik Hosted Foundation Edition'){
                        //     linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$Salesforce'), skuToId, pocId, Integer.valueOf(Math.ceil(newPOCMap.get(pocId).Number_of_Users_Salesforce__c)), category));
                        // }	
                        // if('Yes' == newPOCMap.get(pocId).Jira_Cloud__c){
                        //     linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$Jira Cloud'), skuToId, pocId, Integer.valueOf(Math.ceil(newPOCMap.get(pocId).Number_of_Users_Atlassian__c)), category));
                        // }
                    }  
                    else if('M365 and Entra ID' == category){
                        if((newPOCMap.get(pocId).M365_Hosting_environment__c == 'Rubrik Hosted Enterprise Edition') || (newPOCMap.get(pocId).POC_Type__c != 'Web Try and Buy' && newPOCMap.get(pocId).M365_Hosting_environment__c == 'Rubrik Hosted EE, DSPM, Identity Recovery & Resilience')){
                            linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$M365 and Entra ID'+'=='+newPOCMap.get(pocId).M365_Hosting_environment__c.toLowerCase()), skuToId, pocId, Integer.valueOf(Math.ceil(newPOCMap.get(pocId).Number_of_Users__c)), category));
                        }else{
                            linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$M365 and Entra ID'+'=='+newPOCMap.get(pocId).M365_Hosting_environment__c.toLowerCase()), skuToId, pocId, Integer.valueOf(Math.ceil(newPOCMap.get(pocId).Number_of_Users__c/10)), category));
                        }
                        linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$M365 and Entra ID'+'=='+'rubrik hosted enterprise edt per gb'), skuToId, pocId, Integer.valueOf(Math.ceil(newPOCMap.get(pocId).Number_of_Users__c)*20), category));
                    }
                    else if('Atlassian Jira Cloud' == category){
                        linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$'+category+'=='+newPOCMap.get(pocId).Hosting_Environment__c.toLowerCase()), skuToId, pocId, Integer.valueOf(Math.ceil(newPOCMap.get(pocId).Number_of_Users_Atlassian__c)), category));
                    }
                    else if('M365' == category){
                        linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$M365'+'=='+newPOCMap.get(pocId).M365_Hosting_Environment_RSCG__c.toLowerCase()), skuToId, pocId, Integer.valueOf(Math.ceil(newPOCMap.get(pocId).Number_of_Users_RSCG__c)), category));
                        linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$M365'+'=='+'rubrik hosted m365 per gb'), skuToId, pocId, Integer.valueOf(Math.ceil(newPOCMap.get(pocId).Number_of_Users_RSCG__c)*20), category));
                    }
                    else if('UCL (Cloud Cluster, Cloud Native & Entra ID)' == category){
                        //linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$UCL (Cloud Cluster, Cloud Native & Entra ID)'+'=='+newPOCMap.get(pocId).Cloud_Cluster_Location__c.toLowerCase()), skuToId, pocId, 1, category));
                        if(!productCategories.contains('Edge') && !productCategories.contains('Rubrik Appliance')){
                            linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$'+category+'=='+category.toLowerCase()), skuToId, pocId,1, category));
                        }
                        linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$UCL (Cloud Cluster, Cloud Native & Entra ID)'+'=='+newPOCMap.get(pocId).UCL_Edition__c.toLowerCase()), skuToId, pocId, 1, category));
                        if(('Yes' == newPOCMap.get(pocId).RCV_Backup_Tier__c) && newPOCMap.get(pocId).UCL_Edition__c == 'UCL with Rubrik-hosted Enterprise Edition (With RCV Backup tier)' && isUCLWithRCV && !isNASAndRCVCloudSelected ){
                            if(newPOCMap.get(pocId).Data_Redundancy_Backup_UCL__c == 'Single Zone (LRS)'){
                                linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$'+category+'==backup'), skuToId, pocId, Integer.valueOf(newPOCMap.get(pocId).Backup_TB__c), category));
                            }
                            if(newPOCMap.get(pocId).Data_Redundancy_Backup_UCL__c == 'Multi Zone (ZRS)'){
                                linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$'+category+'==multi zone'), skuToId, pocId, Integer.valueOf(newPOCMap.get(pocId).Backup_TB__c), category));
                            }
                            if(newPOCMap.get(pocId).Data_Redundancy_Backup_UCL__c == 'Multi Region (GRS)'){
                                linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$'+category+'==multi region'), skuToId, pocId, Integer.valueOf(newPOCMap.get(pocId).Backup_TB__c), category));
                            }
                        }
                    }
                    else if('UCL(Cloud Cluster & Cloud Native)' == category){
                        //linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$UCL (Cloud Cluster, Cloud Native & Entra ID)'+'=='+newPOCMap.get(pocId).Cloud_Cluster_Location__c.toLowerCase()), skuToId, pocId, 1, category));
                        linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$UCL(Cloud Cluster & Cloud Native)'+'=='+newPOCMap.get(pocId).UCL_Edition__c.toLowerCase()), skuToId, pocId,1, category));
                    }
                    else if('SaaS (Salesforce)' == category){
                        if(newPOCMap.get(pocId).Salesforce_plus_DevOps_Add_on__c == 'Yes'){
                            linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$'+category), skuToId, pocId,Integer.valueOf(newPOCMap.get(pocId).Number_of_Users_Saas__c), category));
                        }
                    }
                    //commenting the below elis as part of MKT26-1427
                    /*else if('Identity Cyber Recovery for Okta' == category){
                        if(newPOCMap.get(pocId).Identity_Cyber_Recovery_for_Okta__c == 'Yes'){
                            linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$'+category), skuToId, pocId,Integer.valueOf(newPOCMap.get(pocId).How_many_users_are_there_in_the_Okta_IdP__c), category));
                        }
                    }*/
                    else if('Rubrik Appliance' == category){
                        List<RubrikApplianceProduct> raProducts = new List<RubrikApplianceProduct>();
                        List<RubrikApplianceAccessory> raAccesories = new List<RubrikApplianceAccessory>();
                        
                        if(newPOCMap.get(pocId).Rubrik_Appliance_Products__c != null){
                            raProducts = (List<RubrikApplianceProduct>)JSON.deserialize(newPOCMap.get(pocId).Rubrik_Appliance_Products__c,List<RubrikApplianceProduct>.class);
                            if(raProducts!=null){
                                //find the sku for every product
                                for(RubrikApplianceProduct product : raProducts){
                                    String key = newPOCMap.get(pocId).Polaris_Platfrom__c+'$$Rubrik Appliance=='+product.switchType.toLowerCase()+'::'+product.productName.toLowerCase();
                                    String sku = criteriaToSKUs.get(key);
                                    if(product.switchType == 'r7420S' && !allCategories.contains('Edge')){
                                        linesToInsert.addAll(createPOCLines(RUBRIK_APPLIANCE_PRODUCT_CODE, skuToId, pocId, product.quantity, category));
                                    }
                                    if(pocType == 'Standard POC : RSC-G'){
                                        sku = sku.contains(';'+RUBRIK_APPLIANCE_PRODUCT_CODE) ? sku.replace(';'+RUBRIK_APPLIANCE_PRODUCT_CODE,'') : sku;
                                        sku = sku +';'+RUBRIK_APPLIANCE_RSCG_PRODUCT_CODE;
                                    }
                                    if(sku != null)
                                        linesToInsert.addAll(createPOCLines(sku, skuToId, pocId, product.quantity, category));
                                }
                            }
                        }
                        
                        
                        if(newPOCMap.get(pocId).Rubrik_Appliance_Accessories__c != null){
                            raAccesories = (List<RubrikApplianceAccessory>)JSON.deserialize(newPOCMap.get(pocId).Rubrik_Appliance_Accessories__c,List<RubrikApplianceAccessory>.class);
                            if(raAccesories!=null){
                                for(RubrikApplianceAccessory accessory : raAccesories){
                                    if(accessory.accessoryName != null){
                                        String sku = criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$Rubrik Appliance=='+accessory.accessoryName.toLowerCase());
                                        if(pocType == 'Standard POC : RSC-G'){
                                            sku = sku.contains(';'+RUBRIK_APPLIANCE_PRODUCT_CODE) ? sku.replace(';'+RUBRIK_APPLIANCE_PRODUCT_CODE,'') : sku;
                                        }
                                        if(sku != null){
                                            linesToInsert.addAll(createPOCLines(sku, skuToId, pocId, accessory.quantity, category));
                                    }
                                            
                                    }
                                }
                            }
                        }
                    }
                    else if ('Identity Recovery and Resilience - AD, Entra ID, Okta' == category){
                        if('Yes' == newPOCMap.get(pocId).Add_Identity_Resilience__c){
                            linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$'+category+'==identity resilience'), skuToId, pocId,Integer.valueOf(newPOCMap.get(pocId).How_many_identity_users_are_there__c), category));
                        }
                        if('Yes' == newPOCMap.get(pocId).Add_Identity_Recovery__c){
                            linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$'+category+'==identity recovery'), skuToId, pocId,Integer.valueOf(newPOCMap.get(pocId).How_many_Identity_UsersAreThere__c), category));
                        }
                        //below if block is added for MKT26-1427
                        if('Yes' == newPOCMap.get(pocId).Identity_Cyber_Recovery_for_Okta__c){
                            linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$'+category+'==identity cyber recovery for okta'), skuToId, pocId,Integer.valueOf(newPOCMap.get(pocId).How_many_users_are_there_in_the_Okta_IdP__c), category));
                        }
                    }
                    else if ('Identity Recovery' == category){
                        linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$'+category), skuToId, pocId,Integer.valueOf(newPOCMap.get(pocId).How_many_identity_users_areThere__c), category));
                    }
                    else if ('Cloud Unstructured (S3, Azure Blob, and Cloud Files)' == category){
                        linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$'+category), skuToId, pocId,Integer.valueOf(newPOCMap.get(pocId).How_much_FETB_do_you_need__c), category));
                    }
      				else if ('Codebase Recovery' == category){ //Added for MKT26-490
                        linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$'+category), skuToId, pocId,Integer.valueOf(newPOCMap.get(pocId).Number_of_repositories_to_back_up_1_500__c), category));
                    }
                    else if ('RSC Enterprise and Proactive Editions' == category){ //Added for MKT26-410
                        if( newPOCMap.get(pocId).RSC_Enterprise_Edition__c == 'Yes' ) {
                            linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$'+category + ' EE'), skuToId, pocId,1, category));
                        }
                        if( newPOCMap.get(pocId).RSC_Proactive_Edition__c == 'Yes' ) {
                            linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$'+category + ' PE'), skuToId, pocId,1, category));
                        }
                    }
                    else if ('RSC-G Enterprise and Proactive Editions' == category){ //Added for MKT26-410
                        if( newPOCMap.get(pocId).RSC_G_Enterprise_Edition__c == 'Yes' ) {
                            linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$'+ 'RSCG Enterprise and ProactiveEditions EE'), skuToId, pocId,1, category));
                        }
                        if( newPOCMap.get(pocId).RSC_G_Proactive_Edition__c == 'Yes' ) {
                            linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$'+ 'RSCG Enterprise and ProactiveEditions PE'), skuToId, pocId,1, category));
                        }
                    }
      				else if ('RSC-Private' == category){ //Added for MKT26-93
                        linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$'+ newPOCMap.get(pocId).RSC_Private_Edition__c), skuToId, pocId,1, category));
      				}
      				else if( 'Annapurna' == category) { //Added for MKT26-405
                        linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+ '$$' + category), skuToId, pocId, 100, null));  
      				}
                    
                    else if('M365 and Google Workspace' == category){ // Added for MKT26-1556
                        if(newPOCMap.get(pocId).M365_Option__c == 'Yes'){
                                linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$M365 and Google Workspace'+'=='+newPOCMap.get(pocId).M365_Hosting_environment__c.toLowerCase()), skuToId, pocId, Integer.valueOf(Math.ceil(newPOCMap.get(pocId).Number_of_Users__c)), category));
                            linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$M365 and Google Workspace'+'=='+'rubrik hosted enterprise edt per gb'), skuToId, pocId, Integer.valueOf(Math.ceil(newPOCMap.get(pocId).Number_of_Users__c)*20), category));
                        }
                        if(newPOCMap.get(pocId).Google_Workspace__c == 'Yes'){
                            if(newPOCMap.get(pocId).Google_Workspace_Hosting_Environment__c == 'Rubrik Hosted Foundation Edition'){
                                linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$M365 and Google Workspace'+'==gspace '+newPOCMap.get(pocId).Google_Workspace_Hosting_Environment__c.toLowerCase() + ' sku1'), skuToId, pocId, Integer.valueOf(Math.ceil(newPOCMap.get(pocId).Number_of_Users_Google_Workspace__c)), category));
                                linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$M365 and Google Workspace'+'==gspace '+newPOCMap.get(pocId).Google_Workspace_Hosting_Environment__c.toLowerCase() + ' sku2'), skuToId, pocId, Integer.valueOf(Math.ceil(newPOCMap.get(pocId).Number_of_Users_Google_Workspace__c)*20), category));
                            }
                        }   
                    }
      
      //added for MKT-38
                    else if('Rubrik Agent Cloud' == category){
                        linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$'+category + '==rubrik agent cloud sku 1'), skuToId, pocId, 1, null));
                        linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$'+category + '==rubrik agent cloud sku 2'), skuToId, pocId, 1, null));
                    }
                        
                }
                if(newPOCMap.get(pocId).SAP_Hana__c){
                    linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$SAP_HANA'), skuToId, pocId, 1, null));    
                }
                if(newPOCMap.get(pocId).Kubernetes__c){
                    linesToInsert.addAll(createPOCLines(criteriaToSKUs.get(newPOCMap.get(pocId).Polaris_Platfrom__c+'$$Kubernetes'), skuToId, pocId, 1, null));    
                }

             // Add Default Product //
            /* if((defaultskuToId !=null || defaultskuToId !='')&& newPOCMap.get(pocId).POC_Type__c !='Web Try and Buy') {
                POC_Line__c lineItemDefault = new POC_Line__c();
                lineItemDefault.POC_Request__c = pocId;
                lineItemDefault.Product__c =  defaultskuToId;
                lineItemDefault.Quantity__c = 1;
                linesToInsert.add(lineItemDefault); 
             }*/
                
 

            }
            
            
            if(!linesToInsert.isEmpty()){
                insert linesToInsert;
            }
        }
    }
    private static List<POC_Line__c> createPOCLines(String sku, Map<String, Id> skuToId, Id pocId, Integer quantity, String pocProductType) {
        List<POC_Line__c> linesToInsert = new List<POC_Line__c>();

        Set<String> allSkus = new Set<String>();
        if(sku != null){
            allSkus = new Set<String>(sku.split(';'));
        }

        for(String code : allSkus){
            if(!allSkusRecord.contains(code)){
                allSkusRecord.add(code);
            POC_Line__c lineItem = new POC_Line__c();
            lineItem.POC_Request__c = pocId;
            lineItem.Product__c =  skuToId.get(code);
            lineItem.Quantity__c = (pocProductType == 'Rubrik Cloud Vault' && code == 'RBK-POLARIS-GPS') ? 1 : (((pocProductType == 'Rubrik Appliance' || pocProductType == 'UCL(Cloud Cluster & Cloud Native)') && code == RUBRIK_APPLIANCE_RSCG_PRODUCT_CODE) ? 1 : quantity);
            lineItem.POC_Option__c = productCodeToOption.get(code);
            //get the required by in the current bundle
            if(productCodeToRequiredBy.containsKey(code))
                for(String requiredByCode : productCodeToRequiredBy.get(code).split(';'))
                    if(allSkus.contains(requiredByCode))
                        lineItem.Required_By__c = requiredByCode;
            linesToInsert.add(lineItem);
        }
        }
        return linesToInsert;
    }
    /**
     * @description Updates the "Most Recent POC Request" field on related Opportunity records
     *
     * @param newPOCs The list of newly inserted or updated POC__c records.
    */
        public static void updateMostRecentPOCOnOppty(List<POC__c> newPOCs){
        Map<Id, Opportunity> oppMap = new Map<ID, Opportunity>();
        for(POC__c newPoc: newPOCs){
            if(newPoc.Opportunity__c != null){
                oppMap.put(newPoc.Opportunity__c, new Opportunity(ID = newPoc.Opportunity__c, Most_Recent_POC_Request__c = newPoc.id));
            }
        }
        if(!oppMap.isEmpty()){
            update oppMap.values();
        }
    }
    class RubrikApplianceProduct{
        String productName{get;set;}
        String switchType{get;set;}
        Integer Quantity{get;set;}
    }
    class RubrikApplianceAccessory{
        String accessoryName{get;set;}
        Integer Quantity{get;set;}
    }
    /**
     * @description Creates Order Detail records based on changes to POC__c records.
     *
     * @param newPOCs The list of newly inserted or updated POC__c records.
     * @param oldPOCMap A map of the old versions of POC__c records (keyed by Id).
     *                  This is used to detect field changes on update. Can be null for insert-only logic.
    */
    public static void createOrderDetails(List<POC__c> newPOCs, Map<Id,POC__c> oldPOCMap){
        List<Order> orderList = new List<Order>();
        Map<Id, POC__c> createOrderPOCIdToPOC = new Map<Id, POC__c>();
        for(POC__c newPOC : newPOCs){
            if( !runTriggerOnce.contains(newPOC.Id)
                && newPoc.POC_Type__c != 'Virtual Lab' && newPoc.Opportunity__c != null
                && newPoc.Approval_Status__c == 'Approved' && newPoc.Approval_Status__c != oldPOCMap.get(newPOC.Id).Approval_Status__c
            ){
                //create orders here
                createOrderPOCIdToPOC.put(newPOC.Id, newPOC);
                runTriggerOnce.add(newPOC.Id);
            }
        }
        if(!createOrderPOCIdToPOC.isEmpty()){
            Map<Id, Order> pocIdToOrder = generateOrders(createOrderPOCIdToPOC.values());
            if(!pocIdToOrder.isEmpty()){
                OrderItemTriggerHelper.insertTransaction = true;
                insert pocIdToOrder.values();
                //create order lines
                List<OrderItem> orderItems = generateOrderItems(pocIdToOrder, createOrderPOCIdToPOC);
                if(!orderItems.isEmpty()){
                    insert orderItems;
                    //Update the Required by and POC Option
                    Map<String, Id> productCodeToOIId = new Map<String, Id>();
                    Map<Id, OrderItem> idToOrderItem = new Map<Id, OrderItem>(
                        [SELECT Id, Product_Code_Formula__c, POC_Line_Item__r.Required_By__c FROM OrderItem WHERE Id IN :orderItems]
                    );
                    for(OrderItem item : idToOrderItem.values()){
                        productCodeToOIId.put(item.Product_Code_Formula__c, item.Id);
                    }
                    for(OrderItem item : orderItems){
                        String requiredCode = idToOrderItem.get(item.Id).POC_Line_Item__r.Required_By__c;
                        if(requiredCode != null){
                            item.SBQQ__RequiredBy__c = productCodeToOIId.get(requiredCode);
                        }
                    }
                    update orderItems;
                }
                    
            }
        }
    }

    private static Map<Id,Order> generateOrders(List<POC__c> pocs){
        Map<Id, Order> pocIdToOrder = new Map<Id, Order>();
        Id orderRecordId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order').getRecordTypeId();
        Set<Id> opptyIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        Set<Id> contactRSCGIds = new Set<Id>();
        for(POC__c poc : pocs){
            if(poc.Opportunity__c != null)
                opptyIds.add(poc.Opportunity__c);
            if(poc.Polaris_Contact__c != null)
                contactIds.add(poc.Polaris_Contact__c);
            if(poc.RSC_G_Contact__c != null)
                contactRSCGIds.add(poc.RSC_G_Contact__c);
        }
        Map<Id, Opportunity> opptyIdToOppty; Map<Id, Contact> contactIdToContact;
        if(!opptyIds.isEmpty()){
            opptyIdToOppty = new Map<Id, Opportunity>([SELECT Id, AccountId, Pricebook2Id,
                                                        Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingPostalCode, Account.BillingCountry
                                                        FROM Opportunity WHERE Id IN :opptyIds]);
        }
        if(!contactIds.isEmpty() || !contactRSCGIds.isEmpty()){
            contactIdToContact = new Map<Id, Contact>([SELECT id, Email, Phone, Name, MailingCountry, MailingCity, MailingStreet, MailingPostalCode, MailingStateCode, MailingState
                                                        FROM Contact WHERE Id IN :contactIds OR Id IN :contactRSCGIds]);
        }
        for(POC__c poc : pocs){
            Order ord = new Order();
            ord.RecordTypeId = orderRecordId;
            ord.POC_Opportunity__c = poc.Opportunity__c;
            ord.EffectiveDate = System.today();
            ord.Status = 'Draft';
            ord.Order_Status__c = 'Pending';
            ord.POC_Request__c = poc.Id;
            ord.Type = 'POC';
            ord.Order_Sub_Type__c = poc.POC_Type__c == 'Web Try and Buy'?'Try N Buy':'POC';
            ord.Is_RWD_Polaris_Quote__c = true;
            String country;
            if('Standard POC : RSC-G' == poc.POC_Type__c){
                ord.RSC_G_Contact__c = poc.RSC_G_Contact__c;
                ord.RSC_G_Contact_Email__c = contactIdToContact.get(poc.RSC_G_Contact__c).Email;
                ord.RSC_G_Contact_Phone__c = contactIdToContact.get(poc.RSC_G_Contact__c).Phone;
            }
            //MKT23-332 - copy shipping address from Account if POC is web try and buy
            if('Web Try and Buy' == poc.POC_Type__c){
                if(opptyIdToOppty.get(poc.Opportunity__c) != null && opptyIdToOppty.get(poc.Opportunity__c).Account.BillingCountry != null) {
                    country = opptyIdToOppty.get(poc.Opportunity__c).Account.BillingCountry;
                    ord.ShippingStreet = opptyIdToOppty.get(poc.Opportunity__c).Account.BillingStreet;
                    ord.ShippingCity = opptyIdToOppty.get(poc.Opportunity__c).Account.BillingCity;
                    ord.ShippingPostalCode = opptyIdToOppty.get(poc.Opportunity__c).Account.BillingPostalCode;
                    ord.ShippingState = opptyIdToOppty.get(poc.Opportunity__c).Account.BillingState; 
                }
                else {
                    country = contactIdToContact.get(poc.Polaris_Contact__c).MailingCountry;
                    ord.ShippingStreet = contactIdToContact.get(poc.Polaris_Contact__c).MailingStreet;
                    ord.ShippingCity = contactIdToContact.get(poc.Polaris_Contact__c).MailingCity;
                    ord.ShippingPostalCode = contactIdToContact.get(poc.Polaris_Contact__c).MailingPostalCode;
                    ord.ShippingState = contactIdToContact.get(poc.Polaris_Contact__c).MailingState;
                }
                ord.ShipToContactName__c = contactIdToContact.get(poc.Polaris_Contact__c).Name;
            }
            else {
                ord.ShipToContactName__c = poc.Shipping_Contact__c;
                ord.ShippingCity = poc.Shipping_City__c;
                ord.ShippingStreet = poc.Shipping_Street__c;
                ord.ShippingPostalCode = poc.Shipping_Zip_Postal_Code__c;
                country = poc.Ship_To_Country__c;
                if(String.isNotBlank(poc.Shipping_State__c)
                        && poc.Shipping_State__c.length() > 0) {
                    ord.ShippingStateCode = poc.Shipping_State__c;
                }
                else {
                    ord.ShippingState = poc.Shipping_State__c;
                }
            }
            ord.Ship_To_Phone_Number__c = poc.Shipping_Contact_Phone__c;
            ord.Ship_to_Email__c = poc.Shipping_Contact_Email__c;
            if(country != null) {
                Map<String, String> countryNameISOCodeMap = getCountryNameISOCodeMap();
                ord.ShippingCountryCode = countryNameISOCodeMap.get(country);
            }
            ord.Additional_Shipping_Comments__c = poc.POC_Shipping_Information_Comments__c;
            //Other Product Comments
            ord.Other_Product_Comments__c = poc.Other_Accessories__c;
            ord.Polaris_Region__c = poc.Polaris_Region__c;
            ord.Polaris_Contact__c = poc.Polaris_Contact__c;
            if(poc.Polaris_Contact__c != null){
                ord.Polaris_Contact_Email__c = contactIdToContact.get(poc.Polaris_Contact__c).Email;
            }
            if(poc.Opportunity__c != null){
                Opportunity oppty = opptyIdToOppty.get(poc.Opportunity__c);
                ord.AccountId = oppty.AccountId;
                ord.Pricebook2Id = oppty.pricebook2Id;
            }
            pocIdToOrder.put(poc.Id, ord);
        }
        return pocIdToOrder;
    }
    private static List<OrderItem> generateOrderItems(Map<Id,Order> pocIdToOrder, Map<Id, POC__c> pocIdToPOC){
        //query the poc lines
        Set<Id> pocIds = pocIdToOrder.keyset();
        Map<Id, List<OrderItem>> orderIdToSubSupitems = new Map<Id, List<OrderItem>>();
        Map<Id, Id> orderIdToApplianceId = new Map<Id, Id>();
        List<OrderItem> items = new List<OrderItem>();
        Set<Id> productIds = new Set<Id>();
        Set<Id> priceBook2Ids = new Set<Id>();
        for(POC_Line__c pocLine : [SELECT Id, Product__c, POC_Option__c, Required_By__c, Quantity__c, POC_Request__c, Product__r.Name, Product__r.ProductCode, Product__r.License_Type__c
                FROM POC_Line__c 
                WHERE POC_Request__c IN :pocIds]){
            OrderItem item = new OrderItem();
            item.OrderId = pocIdToOrder.get(pocLine.POC_Request__c).Id;
            productIds.add(pocLine.Product__c);
            priceBook2Ids.add(pocIdToOrder.get(pocLine.POC_Request__c).Pricebook2Id);
            item.PriceBookEntryId = pocLine.Product__c;
            item.UnitPrice = 0;
            item.Description = pocLine.Product__r.Name;
            item.Quantity = pocLine.Quantity__c;
            //for web try and buy, populate the following
            if('Web Try and Buy' == pocIdToPOC.get(pocLine.POC_Request__c).POC_Type__c) {
                item.Support_Start_Date__c = pocIdToPOC.get(pocLine.POC_Request__c).Planned_Installation_Date__c;
                item.Support_End_Date__c = pocIdToPOC.get(pocLine.POC_Request__c).Original_End_Date__c;
            }
            if('Ransomware Recovery Software' == pocIdToPOC.get(pocLine.POC_Request__c).POC_Type__c) { 
                item.Support_Start_Date__c = pocIdToPOC.get(pocLine.POC_Request__c).Planned_Installation_Date__c; 
                item.Support_End_Date__c = pocIdToPOC.get(pocLine.POC_Request__c).Original_End_Date__c.addDays(7);
            }
            item.POC_Option__c = pocLine.POC_Option__c;
            if('Standard POC : RSC-G' == pocIdToPOC.get(pocLine.POC_Request__c).POC_Type__c){
                item.User_license_count__c = pocIdToPOC.get(pocLine.POC_Request__c).Number_of_Users_RSCG__c;
            }else{
                item.User_license_count__c = pocIdToPOC.get(pocLine.POC_Request__c).Number_of_Users__c;
            }
            if(pocIdToPOC.get(pocLine.POC_Request__c).Product_Categories__c.contains('Rubrik Cloud Vault') || pocIdToPOC.get(pocLine.POC_Request__c).Product_Categories__c.contains('NAS Cloud Direct') || pocIdToPOC.get(pocLine.POC_Request__c).Product_Categories__c.contains('UCL (Cloud Cluster, Cloud Native & Entra ID)')){
                if(pocIdToPOC.get(pocLine.POC_Request__c).RCV_Archive_Tier__c == 'Yes' && RCV_ARCHIVE_PRODUCT_CODE == pocLine.Product__r.ProductCode && pocIdToPOC.get(pocLine.POC_Request__c).Storage_Region_Bundle_RCV_Archive__c != null){
                    String storageRegionValue = pocIdToPOC.get(pocLine.POC_Request__c).Storage_Region_Bundle_RCV_Archive__c; 
                    item.Storage_Region_Bundle__c = storageRegionValue.contains('Standard - Zone 1') ? 'Standard - Zone 1' : (storageRegionValue.contains('Standard - Zone 2') ? 'Standard - Zone 2' : '');
                }else if(pocIdToPOC.get(pocLine.POC_Request__c).RCV_Backup_Tier__c == 'Yes' && RCV_BACKUP_PRODUCT_CODE == pocLine.Product__r.ProductCode && pocIdToPOC.get(pocLine.POC_Request__c).Storage_Region_Bundle_RCV_Backup__c != null){
                    String storageRegionValue = pocIdToPOC.get(pocLine.POC_Request__c).Storage_Region_Bundle_RCV_Backup__c; 
                    item.Storage_Region_Bundle__c = storageRegionValue.contains('Standard - Zone 1') ? 'Standard - Zone 1' : (storageRegionValue.contains('Standard - Zone 2') ? 'Standard - Zone 2' : '');
                }
            }
            item.POC_Line_Item__c = pocLine.Id;
            items.add(item);
        }
        if(!orderIdToSubSupitems.isEmpty()){
            for(Id orderId : orderIdToSubSupitems.keySet()){
                for(OrderItem item : orderIdToSubSupitems.get(orderId)){
                    item.SBQQ__RequiredBy__c = orderIdToApplianceId.get(orderId);
                }
            }
        }
        Map<Id, Id> mapPricebookEntry = new Map<Id, Id>();
        for(PriceBookEntry entry : [SELECT Id, Product2Id FROM PricebookEntry
            WHERE Product2Id IN :productIds AND Pricebook2Id IN :pricebook2Ids
        ]){
            mapPricebookEntry.put(entry.Product2Id, entry.Id);
        }
        for(OrderItem item : items){
            item.PriceBookEntryId = mapPricebookEntry.containsKey(item.PriceBookEntryId) ? mapPricebookEntry.get(item.PriceBookEntryId): null;
        }
        
        return items;
    }
    /**
     * @description Updates the End Dates on related Order and Asset records based on changes 
     * to POC__c records.
     *
     * @param newPocMap A map of the updated POC__c records, keyed by their Ids.
     * @param oldPocMap A map of the previous versions of those POC__c records, 
     *                  used for comparison to detect changes.
    */
    public static void updateOrderAndAssetEndDates(Map<ID, POC__c> newPocMap, Map<ID, POC__c> oldPocMap){
        ShGl_DisableBusinessLogic__c businessLogicToggle = ShGl_DisableBusinessLogic__c.getInstance();
        list<POC__c> pocList = new list<POC__c>();
        for(POC__c pocRec: newPocMap.values()){
            if(pocRec.POC_Type__c == 'Web Try and Buy' && pocRec.New_Expected_End_Date__c != oldPocMap.get(pocRec.id).New_Expected_End_Date__c) //MKT26-892
                pocList.add(pocRec);
            if(pocRec.POC_Type__c != 'Web Try and Buy' && pocRec.Approval_Status__c != oldPocMap.get(pocRec.id).Approval_Status__c && pocRec.Approval_Status__c == 'Extension Approved')
                pocList.add(pocRec);
        }
        
        List<Asset> assetListToUpdate= new List<Asset>();
        Map<Id, Entitlement> entitlementListToUpdate= new Map<Id, Entitlement>();
        List<Order> orderToUpdate = new List<Order>();
        List<OrderItem> orderItemsToUpdate = new List<OrderItem>();
        for(Order ord : [SELECT Id,SC_or_Entitlement_Stage__c, POC_Request__r.New_Expected_End_Date__c,RSC_G_Enabled__c,
                            (SELECT Id FROM OrderItems WHERE Support_End_Date__c != null)
                        FROM Order WHERE POC_Request__c IN :pocList]){
            ord.Support_End_Date__c = ord.POC_Request__r.New_Expected_End_Date__c;
            ord.Polaris_Fulfillment_Status__c = 'Not Started';
            //Added for PRDOPS26-1057
            if(!ord.RSC_G_Enabled__c && String.isNotBlank(checkRSCPostCall.Value__c) && Boolean.valueOf(checkRSCPostCall.Value__c)){
            	ord.Polaris_Fulfillment_Status__c = 'Provisioning Requested';
            }
            if(!businessLogicToggle.Follow_Existing_EntCreate_Process__c){
                String existingVal = ord.SC_or_Entitlement_Stage__c;
                if(existingVal == null || !existingVal.contains('Extend POC Entitlement End Date')){
                    if(String.isEmpty(existingVal)){
                        ord.SC_or_Entitlement_Stage__c = 'Extend POC Entitlement End Date';
                    }
                    else{
                        ord.SC_or_Entitlement_Stage__c =  existingVal + ';' + 'Extend POC Entitlement End Date';
                    }
                }
            }
            orderToUpdate.add(ord);
            for(OrderItem item : ord.OrderItems){
                item.Support_End_Date__c = ord.POC_Request__r.New_Expected_End_Date__c;
                orderItemsToUpdate.add(item);
            }
        }
        //Update the enddate on order line entitlements
        if(businessLogicToggle.Follow_Existing_EntCreate_Process__c){
            for(Entitlement ent : [SELECT Id, Order_Service_Item__r.Order.POC_Request__r.New_Expected_End_Date__c 
                                        FROM Entitlement WHERE Order_Service_Item__c IN :orderItemsToUpdate]){
                    ent.endDate = ent.Order_Service_Item__r.Order.POC_Request__r.New_Expected_End_Date__c;
                    entitlementListToUpdate.put(ent.Id, ent);
            } 
        }
        for(asset assetRec : [SELECT id, POC_Request__r.New_Expected_End_Date__c
                                FROM Asset 
                                WHERE POC_Request__c IN: pocList]){
            assetListToUpdate.add(new asset(id=assetRec.Id, Premium_Support_End_Date__c =assetRec.POC_Request__r.New_Expected_End_Date__c));
        }
        if (!assetListToUpdate.isEmpty())
            update assetListToUpdate;
        if (!entitlementListToUpdate.isEmpty() && businessLogicToggle.Follow_Existing_EntCreate_Process__c)
            update entitlementListToUpdate.values();
        if(!orderToUpdate.isEmpty()){
            OrderHandler.IsInsertTransaction = true;
            OrderItemTriggerHelper.insertTransaction = true;
            update orderToUpdate;
        }
        if(!orderItemsToUpdate.isEmpty()){
            OrderHandler.IsInsertTransaction = true;
            OrderItemTriggerHelper.insertTransaction = true;
            update orderItemsToUpdate;
        }    
    }
    private static Map<String, String> getCountryNameISOCodeMap() {
        Map<String,String> maplabelVal=new Map<String,String>();
        Schema.sObjectType objType = Contact.getSObjectType();
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
        List<Schema.PicklistEntry> values = fieldMap.get('MailingCountryCode').getDescribe().getPickListValues();
        for (Schema.PicklistEntry a : values){
           maplabelVal.put(a.getLabel(), a.getValue());
        }
        return maplabelVal;
    }
    /**
     * @description Automatically approves POC__c records of type "Virtual Lab".
     * This method updates each qualifying POC__c record by setting its 
     * Approval_Status__c to "Approved", aligning the Most Recent, Original, 
     * and New Expected End Dates, and assigning the current user as the POC submitter.
     *
     * @param newPOCs The list of new or updated POC__c records to evaluate and update.
    */
    
    public static void approveVirtualLabPOCs(List<POC__c> newPOCs){
        for(POC__c poc : newPOCs){
            if('Virtual Lab' == poc.POC_Type__c) {
                poc.Approval_Status__c = 'Approved';
                poc.Most_Recent_End_Date__c = poc.Original_End_Date__c = poc.New_Expected_End_Date__c;
                poc.POC_Submitter__c = UserInfo.getUserId();
            }
        }
    }
    /**
     * @description Adds "Virtual Lab" to the POC_Products__c field on associated Opportunity records
     * for all POC__c records of type "Virtual Lab". This ensures that Opportunities reflect
     * the presence of a Virtual Lab POC in their product listing.
     *
     * The method checks each POC__c record in the provided list and identifies the associated
     * Opportunity. If "Virtual Lab" is not already present in the Opportunity's POC_Products__c field,
     * it appends it. This method avoids duplicates and performs a bulk update for efficiency.
     *
     * @param newPOCs The list of new or updated POC__c records to evaluate. Only those with
     *                POC_Type__c equal to "Virtual Lab" will be processed.
    */
    public static void addVirtualLabPOCProduct(List<POC__c> newPOCs){
        Set<Id> pocIds = new Set<Id>();
        Set<Id> oldOpptyIds = new Set<Id>();

        for(POC__c poc : newPOCs){
            if('Virtual Lab' == poc.POC_Type__c){
                pocIds.add(poc.Id);
            }
        }

        if(!pocIds.isEmpty()){
            Map<Id, Opportunity> opptyToUpdate = new Map<Id, Opportunity>();
            for(POC__c poc : [SELECT Id, Opportunity__c, Opportunity__r.POC_Products__c, Product_Categories__c, Cloud_Cluster_Location__c
                                FROM POC__c 
                                WHERE Id IN :pocIds]){
                Opportunity oppty = opptyToUpdate.containsKey(poc.Opportunity__c) ? opptyToUpdate.get(poc.Opportunity__c) :new Opportunity(Id = poc.Opportunity__c,POC_Products__c=poc.Opportunity__r.POC_Products__c);
                if(oppty.POC_Products__c == null) 
                    oppty.POC_Products__c = '';
                if(!oppty.POC_Products__c.contains('Virtual Lab')){
                    oppty.POC_Products__c = oppty.POC_Products__c+';'+'Virtual Lab';
                    opptyToUpdate.put(oppty.Id, oppty);
                }
            }
            if(!opptyToUpdate.isEmpty())
                update opptyToUpdate.values();
        }
    }
    /**
     * @description Updates the POC_Products__c field on related Opportunity records when a POC__c record’s
     * Opportunity reference changes. It ensures the Opportunity reflects all shipped POC product categories,
     * including any relevant Cloud Cluster locations and the presence of Virtual Lab POCs.
     *
     * @param newPOCs The list of newly inserted or updated POC__c records.
     * @param oldPOCMap A map of the original versions of the updated POC__c records, keyed by Id.
     *                  This is used to detect changes in the Opportunity reference.
     */

    public static void updateOpptyPOCProducts(List<POC__c> newPOCs, Map<Id, POC__c> oldPOCMap){
        Set<Id> opptyIds = new Set<Id>();
        for(POC__c poc : newPOCs){
            if(poc.Opportunity__c != oldPOCMap.get(poc.Id).Opportunity__c){
                opptyIds.add(oldPOCMap.get(poc.Id).Opportunity__c);
                opptyIds.add(poc.Opportunity__c);
            }
        }
        Map<Id, Opportunity> opptyToUpdate = new Map<Id, Opportunity>();
        for(Opportunity loopOpp : [SELECT Id,
                            (SELECT Id, POC_Request__r.Opportunity__c, POC_Request__r.Product_Categories__c, POC_Request__r.Cloud_Cluster_Location__c, Order_Status__c FROM Orders__r) 
                                FROM Opportunity
                                WHERE Id IN :opptyIds]) {
            Opportunity oppty = opptyToUpdate.containsKey(loopOpp.Id) ? 
                            opptyToUpdate.get(loopOpp.Id): new Opportunity(Id = loopOpp.Id, POC_Products__c='');
            for(Order ar : loopOpp.Orders__r){
                if('Shipped' == ar.Order_Status__c)
                    for(String category : ar.POC_Request__r.Product_Categories__c.split(';')){
                        if('UCL (Cloud Cluster, Cloud Native & Entra ID)' == category)
                            category = category+' - '+ar.POC_Request__r.Cloud_Cluster_Location__c;
                        if(!oppty.POC_Products__c.contains(category)){
                            oppty.POC_Products__c = oppty.POC_Products__c == ''?category : (oppty.POC_Products__c+';'+category);
                        }
                    }
            }
            opptyToUpdate.put(oppty.Id, oppty);
        }
        //update Virtual Labs
        for(POC__c poc : [SELECT Id, Opportunity__c FROM POC__c 
                            WHERE Opportunity__c IN :opptyIds 
                            AND POC_Type__c = 'Virtual Lab']) {
            Opportunity oppty = opptyToUpdate.get(poc.Opportunity__c);
            if(!oppty.POC_Products__c.contains('Virtual Lab'))
                oppty.POC_Products__c = oppty.POC_Products__c==''? 'Virtual Lab' : oppty.POC_Products__c+';Virtual Lab';       
        }
        if(!opptyToUpdate.isEmpty()){
            update opptyToUpdate.values();
        }
    }
    /**
     * @description Handles logic during the before update trigger context for POC__c records.
     * This method performs validations and field updates based on changes in key fields.
     *
     * @param newPocMap A map of the updated POC__c records, keyed by Id.
     * @param oldPocMap A map of the original versions of the POC__c records before update, keyed by Id.
    */
    public static void onBeforeUpdate(Map<ID, POC__c> newPocMap, Map<ID, POC__c> oldPocMap) {
        for(POC__c newPOC : newPOCMap.values()){
            POC__c oldPOC = oldPOCMap.get(newPOC.Id);
            if(oldPoc.Most_Recent_End_Date__c != newPoc.Most_Recent_End_Date__c ) {
                newPoc.Extension_Date_Changed__c = true;
            }
            if(( newPOC.POC_Type__c == 'Standard POC' || newPOC.POC_Type__c == 'Standard POC : RSC-G' || newPOC.POC_Type__c == 'CSAT Loaner') && newPOC.Approval_Status__c != oldPOC.Approval_Status__c && newPOC.Approval_Status__c == 'Approved' && newPOC.OwnerId == UserInfo.getUserId()) {
                newPOC.Approval_Status__c.addError(POC_APPROVAL_EXCEPTION_MESSAGE);
            }
            if(oldPoc.Approval_Status__c != newPoc.Approval_Status__c && newPoc.Approval_Status__c == 'Return Completed') {
                newPoc.POC_Return_Date__c = Datetime.now();
            }
            if(oldPoc.Approval_Status__c != newPoc.Approval_Status__c && newPoc.Approval_Status__c == 'Pending') {
                newPoc.POC_Submitter__c = UserInfo.getUserId();
            }
            if(oldPoc.Approval_Status__c != newPoc.Approval_Status__c && newPoc.Approval_Status__c == 'Extension Approved') {
                newPoc.Number_of_Expiry_Notifications_Sent__c = 0;
            }
        }
    }
    
    /**
     * @description Updates the POC_Phase__c field on Opportunity records based on the approval status change of related POC__c records.
     * 
     * @param newPOCs List of new or updated POC__c records in the current context.
     * @param oldPOCMap Map of old POC__c records (prior values), keyed by their IDs.
    */
    
     public static void updatePOCPhaseonOpportuntiy(List<POC__c> newPOCs, Map<Id, POC__c> oldPOCMap){
        List<Opportunity> OppListUpdate = new List<Opportunity>();
        set<String> OppId = new set<String>();
        map<String,Opportunity> oppMapData= new map<String,Opportunity>();
        for(POC__c poc : newPOCs){
            OppId.add(poc.Opportunity__c);
        }
        List<Opportunity> OppDetails = [Select id,POC_Phase__c from Opportunity where id IN :OppId];
        if(OppDetails.size()>0) {
            for(Opportunity opp:OppDetails){
                if(opp.POC_Phase__c == null || opp.POC_Phase__c == 'No POC' || opp.POC_Phase__c=='Planned POC')
                    oppMapData.put(opp.id,opp); 
            }
        }
        for(POC__c poc : newPOCs){
            if(poc.Approval_Status__c != oldPOCMap.get(poc.Id).Approval_Status__c 
               && poc.Approval_Status__c =='Approved'
               && poc.Opportunity__c != null
              ){
                  if(oppMapData.containskey(poc.Opportunity__c))
                      OppListUpdate.add(new Opportunity(Id = poc.Opportunity__c, POC_Phase__c=POCPHASESTATUS));
              }
        }
        if(OppListUpdate.size()>0) {   
            update OppListUpdate;
        }
    }
}