public with sharing class ProductsController {
    
     public static Integer edgeListSize {get; set;}
     public static list<string> edgeFamilies {get; set;}
     public static list<string> cloutFamilies {get; set;}
     public static list<string> clonFamilies {get; set;}
     public static list<string> cdmFamilies {get; set;}
     public static boolean isTest {get; set;}
 
    /*Edge Pagination */
    private integer totalEdgeRecs = 0;
    private integer OffsetSize = 0;
    private integer LimitSize= 10;
     
     public ProductsController()
      {
        totalEdgeRecs = edgeListSize;
        edgeFamilies = System.label.EdgeFamilies.split(';');        
        cloutFamilies = System.label.cloutFamilies.split(';');
        clonFamilies = System.label.clonFamilies.split(';');
        cdmFamilies = System.label.cdmFamilies.split(';');
      }
     
    
     //Clusters
      private map<Id, ProductWrapper> mapclustrId_To_ProductWrapper {
        get {
            if (mapclustrId_To_ProductWrapper == null) {
                mapclustrId_To_ProductWrapper = new map<Id, ProductWrapper>{};
                set<Id> clusterEdgeIDs = new set<Id>();
                
                integer limitValues = test.isrunningtest() ? 1 : 50000;

                
                for (Node__c node : [Select cluster__c from Node__c where Model__c='Edge' limit :limitValues]) 
                {
                  clusterEdgeIDs.add(node.cluster__c);
                  system.debug('### clusterEdgeIDs ' + clusterEdgeIDs);
                }  
                

                for (Cluster__c clstr : [Select  Account__c, archived__c, description__c, software_version__c,
                                                
                                                tag__c, uuid__c, Name,
                                            (select asset__c, asset__r.Name, bios_version__c,board_serial__c,chassis__c,chassis__r.Name,cluster__c,Id,ipmi_mac_address__c,
                                            mac_address_0__c,mac_address_1__c,manufactured_date__c,Name,OwnerId,serial_number__c,
                                            asset__r.Support_Start_Date__c, asset__r.Support_End_Date__c, asset__r.Premium_Support_End_Date__c, asset__r.Product2.ProductCode,
                                            software_version__c from  Nodes__r  where Model__c!='Edge'
                                             )
                                            from  Cluster__c where ID != :clusterEdgeIDs
                                            and Account__c!=null
                                            ]) {

                    mapclustrId_To_ProductWrapper.put(clstr.Id, new ProductWrapper(clstr, clstr.Nodes__r));
                }

            }

            return mapclustrId_To_ProductWrapper;
        }
        private set;
    }
    
    //Dark Sites
        public static list<Node__c> nodeList;  
            public List<Node__c> getDarkNodes() {
                if (nodeList == null)
                    nodeList = [Select asset__c, asset__r.Name, bios_version__c,board_serial__c,chassis__c,chassis__r.Name,cluster__c,Id,ipmi_mac_address__c,
                                            mac_address_0__c,mac_address_1__c,manufactured_date__c,Name,OwnerId,serial_number__c,asset__r.Support_Start_Date__c, 
                                            asset__r.Support_End_Date__c, asset__r.Premium_Support_End_Date__c, asset__r.Product2.ProductCode,
                                            software_version__c from Node__c where Model__c!='Edge'
                                            and cluster__c=null
                                            ];
                if (nodeList.isEmpty()) {
                    return null;
                }
                

                return nodeList;
           }    

        //Cloud Out
        public static list<Entitlement> cloutList;  
            public List<Entitlement> getClout() {
                if (cloutList == null)
                    cloutList = [Select Name,StartDate,EndDate,Product__r.ProductCode, Asset.Name,
                                 Product__r.Family, Product__r.Name
                                 //from Entitlement where Product__r.Family=:'RBK-CLOUT'
                                 from Entitlement where Product__r.Family=:cloutFamilies

                                            ];
                if (cloutList.isEmpty()) {
                    return null;
                }

                return cloutList;
           }  
 
 
   
         //Cloud On
        public static list<Entitlement> clonList;  
            public List<Entitlement> getClon() {
                if (clonList == null)
                    clonList = [Select Name,StartDate,EndDate,Product__r.ProductCode,Asset.Name,
                                 Product__r.Family, Product__r.Name
                                 //from Entitlement where Product__r.Family='RBK-CLON'
                                 from Entitlement where Product__r.Family=:clonFamilies


                                            ];
                if (clonList.isEmpty()) {
                    return null;
                }

                return clonList;
           }  
   
   
       //Cloud Clusters
        public static list<Entitlement> clclList;  
            public List<Entitlement> getClCL() {
                if (clclList == null)
                    clclList = [Select Name,StartDate,EndDate,Product__r.ProductCode,Asset.Name,
                                 Product__r.Family, Product__r.Name
                                 //from Entitlement where Product__r.Family='RBK-RCDM'
                                 from Entitlement where Product__r.Family=:cdmFamilies
                                            ];
                if (clclList.isEmpty()) {
                    return null;
                }

                return clclList;
           } 
    
    
      //Edge
        public static list<Entitlement> edgeList;  
            public List<Entitlement> getEdgeNodes() {
                if (edgeList == null)
                    edgeList = [Select Name,StartDate,EndDate,Product__r.ProductCode,Asset.Name,
                                 Product__r.Family, Product__r.Name
                                 //from Entitlement where Product__r.Family='RBK-EDGE'
                                 from Entitlement where Product__r.Family=:edgeFamilies
                                 ];
                if (edgeList.isEmpty()) {
                    return null;
                }

                return edgeList;
           } 
    
    public list<ProductWrapper> getClusters() {
        return mapclustrId_To_ProductWrapper.values();
    }
    
    public integer getedgeSize() {
        edgeListSize = 0;
        if(edgeList.size()!=0 && edgeList!=null ) edgeListSize = edgeList.size();
        return edgeList.size();
    }



/*****************************************************************************************************************************************
                                                Wrapper classes
 *****************************************************************************************************************************************/    

    public class ProductWrapper {
        public Cluster__c clustr       {get;set;}
        public list<Node__c> nodes   {get;set;}

        public ProductWrapper(Cluster__c pclustr, list<Node__c> pnodes) {
            this.clustr = pclustr;
            this.nodes = pnodes;
  
        }
        
        
    }


}