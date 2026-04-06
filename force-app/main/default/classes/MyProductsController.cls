/**
 * @Author        :  
 * @description   :  
 * @TstClass      : MyProductsControllerTest
 * -------------------------------------------------------------- @History -------------------------------------------------------------------------
 * Story Number       Modified By              Date           Description
 * CS21-869          Vijay Kumar K R        Oct 17, 2022      Add cluster version and other metadata on the Cluster tab
 * CS21-45           Vijay Kumar K R        May 06, 2025      Add ability to select multiple clusters and bulk update proactive contact
 * -------------------------------------------------------------------------------------------------------------------------------------------------
 */
public with sharing class MyProductsController{

    public static list<Entitlement> cloutList;
    public static list<Entitlement> clonList;
    public static list<Entitlement> clclList;
    public static User userRecord;

    public static map<Id, ProductWrapper> mapclustrId_To_ProductWrapper;

    public static list<Entitlement> edgeList;

    public static List<String> edgeFamilies;
    public static List<String> cloutFamilies;
    public static List<String> clonFamilies;
    public static List<String> cdmFamilies;

    /**
    * @description Method to fetch polaris contact name and email details to be displayed in MyProduct Page - CS21-759
    * @return String
    */
    @AuraEnabled
    public static string getPolarisDataProtectionDetails() {
        String polarisContactInformation = '';
        Set<String> contacts = new Set<String>();
        userRecord = [SELECT Id, AccountId FROM User WHERE Id = :Userinfo.getUserId()];

        for (Order eachOrder : [SELECT Id, Polaris_Contact__r.Name, Polaris_Contact_Email__c
                                FROM Order WHERE AccountId = :userRecord.AccountId
                                AND Polaris_Contact__c != null
                                AND Polaris_Contact_Email__c != null
                                ORDER BY Createddate DESC])
        {
            if (contacts.add(eachOrder.Polaris_Contact_Email__c.toLowerCase())) {
                polarisContactInformation +=  eachOrder.Polaris_Contact__r.Name;
                polarisContactInformation +=  ' (' + eachOrder.Polaris_Contact_Email__c.toLowerCase() + '), ';
            }
        }

        polarisContactInformation = String.isNotBlank(polarisContactInformation) ? polarisContactInformation.substringBeforeLast(', ') : '';
        return polarisContactInformation;
    }
    /**
    * @description Method to get CloudAssets
    * @return cloudAssetsWrapper
    */
    @AuraEnabled
    public static cloudAssetsWrapper getCloudAssets(){
        userRecord = [SELECT id,AccountId from User where id =: Userinfo.getUserId()];
        cloutFamilies = System.label.cloutFamilies.split(';');
        clonFamilies = System.label.clonFamilies.split(';');
        cdmFamilies = System.label.cdmFamilies.split(';');

        cloutList = getClout();
        clonList = getClon();
        clclList = getClCL();

        cloudAssetsWrapper tempVar = new cloudAssetsWrapper(cloutList,clonList,clclList);
        return tempVar;
    }

    /**
    * @description Method to get Clout Clusters
    * @return List<Entitlement>
    */
    public static List<Entitlement> getClout() {
        if (cloutList == null){
            cloutList = [Select Name,StartDate,EndDate,Product__r.ProductCode, Asset.Name,Product__r.Family, Product__r.Name, Terminated_Date__c
                         from Entitlement where Product__r.Family=:cloutFamilies AND AccountId =: userRecord.AccountId];
        } 
        if (cloutList.isEmpty()) {
            return null;
        }

        return cloutList;
    }

    /**
    * @description Method to get Clon Clusters
    * @return List<Entitlement>
    */
    public static List<Entitlement> getClon() {
        if (clonList == null){
            clonList = [Select Name,StartDate,EndDate,Product__r.ProductCode,Asset.Name,Product__r.Family, Product__r.Name, Terminated_Date__c
                        from Entitlement where Product__r.Family=:clonFamilies AND AccountId =: userRecord.AccountId];
        }
        if (clonList.isEmpty()) {
            return null;
        }

        return clonList;
    }

    /**
    * @description Method to get Cloud Clusters
    * @return List<Entitlement>
    */
    public static List<Entitlement> getClCL() {
        if (clclList == null){
            /*clclList = [Select Name,StartDate,EndDate,Product__r.ProductCode,Asset.Name,Product__r.Family, Product__r.Name
                        from Entitlement where Product__r.Family=:cdmFamilies AND AccountId =: userRecord.AccountId];*/

            //CS21-530 : Replaced Product Family condition with Bundle features
            clclList = [SELECT Name, StartDate, EndDate, Product__r.ProductCode, Asset.Name, Product__r.Family, Product__r.Name, Terminated_Date__c,
                            Product__r.Description, Order_Quantity__c
                        FROM Entitlement
                        WHERE Product__r.Bundle_Features__c INCLUDES ('Cloud Cluster')
                        AND AccountId =: userRecord.AccountId];
        }
        if (clclList.isEmpty()) {
            return null;
        }

        return clclList;
    }
     /**
    * @description cloudAssetsWrapper to store cloutList,clonList, clclList 
    * @return NA
    */
    public with sharing class cloudAssetsWrapper{
        @AuraEnabled public list<Entitlement> cloutList;
        @AuraEnabled public list<Entitlement> clonList;
        @AuraEnabled public list<Entitlement> clclList;
         /**
        * @description cloudAssetsWrapper to assign cloutList,clonList, clclList 
        * @return void
        */
        public cloudAssetsWrapper(list<Entitlement> cloutList, list<Entitlement> clonList, list<Entitlement> clclList){
            this.cloutList = cloutList;
            this.clonList = clonList;
            this.clclList = clclList;
        }
    }
    /**
    * @description Method to get Clusters
    * @return List<ProductWrapper>
    */
	@AuraEnabled
    public static List<ProductWrapper> clusters(){
        mapclustrId_To_ProductWrapper = new map<Id, ProductWrapper>();
        set<Id> clusterEdgeIDs = new set<Id>();

        integer limitValues = test.isrunningtest() ? 1 : 50000;

        for (Node__c node : [Select cluster__c from Node__c where Model__c='Edge' limit :limitValues]) {
            clusterEdgeIDs.add(node.cluster__c);
        }

        for (Cluster__c clstr : [Select  Account__c, archived__c, description__c, software_version__c,tag__c, uuid__c, Name, is_callhome_on__c, storage_usage__c, objects_protected__c, 
                                        snapshot_count__c, CDM_End_of_Support_Status__c,
                                 (select asset__c, asset__r.Name, bios_version__c,board_serial__c,chassis__c,chassis__r.Name,cluster__c,Id,ipmi_mac_address__c,
                                  mac_address_0__c,mac_address_1__c,manufactured_date__c,Name,OwnerId,serial_number__c,
                                  asset__r.Support_Start_Date__c, asset__r.Support_End_Date__c, asset__r.Premium_Support_End_Date__c, asset__r.Product2.ProductCode,
                                  software_version__c from  Nodes__r  where Model__c!='Edge'
                                 )
                                 from  Cluster__c where ID != :clusterEdgeIDs
                                 and Account__c!=null and archived__c = false
                                ]) {

                                    mapclustrId_To_ProductWrapper.put(clstr.Id, new ProductWrapper(clstr, clstr.Nodes__r));
                                }

        return mapclustrId_To_ProductWrapper.values();
    }
     /**
    * @description Method to get MosaicClusters
    * @return List<ProductWrapper>
    */
    @AuraEnabled
    public static List<ProductWrapper> MosaicClusters(){
        map<Id, ProductWrapper> mapclustrId_To_ProductWrappers = new map<Id, ProductWrapper>();

        integer limitValues = test.isrunningtest() ? 1 : 50000;

        for (Cluster__c clstr : [Select  Account__c, archived__c, description__c, software_version__c,tag__c, uuid__c, Name,is_callhome_on__c,CreatedDate,
                                 (select asset__c, asset__r.Name, bios_version__c,board_serial__c,chassis__c,chassis__r.Name,cluster__c,Id,ipmi_mac_address__c,
                                  mac_address_0__c,mac_address_1__c,manufactured_date__c,Name,OwnerId,serial_number__c,CreatedDate,
                                  asset__r.Support_Start_Date__c, asset__r.Support_End_Date__c, asset__r.Premium_Support_End_Date__c, asset__r.Product2.ProductCode,
                                  software_version__c from  Nodes__r  where Model__c!='Edge'
                                 )
                                 from  Cluster__c where Account__c!=null and archived__c = false AND tag__c = 'Datos'
                                ]) {

                                    mapclustrId_To_ProductWrappers.put(clstr.Id, new ProductWrapper(clstr, clstr.Nodes__r));
                                }

        return mapclustrId_To_ProductWrappers.values();
    }
     /**
    * @description ProductWrapper to store Cluster__c and Node__c
    * @return NA
    */
    public class ProductWrapper{
        @AuraEnabled public Cluster__c clustr;
        @AuraEnabled public list<Node__c> nodes;
         /**
        * @description ProductWrapper to assign Cluster__c and Node__c
        * @return void
        */
        public ProductWrapper(Cluster__c pclustr, list<Node__c> pnodes) {
            this.clustr = pclustr;
            this.nodes = pnodes;
        }
    }

    /**
    * @description Method to get EdgeNodes
    * @return List<Entitlement>
    */
    @AuraEnabled
    public static List<Entitlement> EdgeNodes(){
        edgeFamilies = System.label.EdgeFamilies.split(';');
        userRecord = [SELECT id,AccountId from User where id =: Userinfo.getUserId()];

        if (edgeList == null){
            edgeList = [Select Name,StartDate,EndDate,Product__r.ProductCode,Asset.Name,Product__r.Family, Product__r.Name, Terminated_Date__c
                        from Entitlement where Product__r.Family=:edgeFamilies  AND AccountId =: userRecord.AccountId];
        } 
        if (edgeList.isEmpty()){
            return null;
        }

        return edgeList;
    }
    
    /**
    * @description Method to get Dark Nodes
    * @return List<Node__c>
    */
    @AuraEnabled
    public static List<Node__c> darkNodes() {
        return ([SELECT asset__c, asset__r.Name, bios_version__c,board_serial__c,chassis__c,chassis__r.Name,cluster__c,Id,
                        ipmi_mac_address__c, mac_address_0__c,mac_address_1__c,manufactured_date__c,Name,OwnerId,serial_number__c,
                        asset__r.Support_Start_Date__c, asset__r.Support_End_Date__c, asset__r.Premium_Support_End_Date__c,
                        asset__r.Product2.ProductCode, software_version__c
                FROM Node__c
                WHERE Model__c != 'Edge'
                AND cluster__c = null
                AND asset__r.Status != 'Decommissioned']);   //CS21-861 : Archive decommissioned assets in Salesforce so they
                                                            //are not visible on the Support Portal
    }
     /**
    * @description Method to get getInstallWrapper
    * @return  List<InstallBaseDownloadController.InstallBaseWrapper>
    */
    @AuraEnabled
    public static List<InstallBaseDownloadController.InstallBaseWrapper> getInstallWrapper(){
        return new InstallBaseDownloadController().getibWrapperObj();
    }

    /**
    * @description CS21-46
    * @param proContactId
    * @param accId
    * @param clusterIds
    * @param uncheckedclusterIds
    * @param isUpdateAllClusters
    */
    @AuraEnabled
    public static void bulkUpdateProactiveContactOnClusters(String proContactId, String accId, List<Id> clusterIds, List<Id> uncheckedclusterIds, Boolean isUpdateAllClusters) {
        ProactiveClusterController.updateProactiveContactOnClusters(proContactId, accId, clusterIds, uncheckedclusterIds, isUpdateAllClusters);
    }

    /**
     * @description Fetches RSC Instance data and table configuration by delegating 
     * to the RSCInstanceService.
     * @return RSCInstanceService.TableWrapper — The unified data and metadata wrapper.
     */
    @AuraEnabled
    public static RSCInstanceService.TableWrapper getRSCInstances() {
        return RSCInstanceService.getRSCInstances();
    }

}