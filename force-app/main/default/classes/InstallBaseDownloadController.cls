/*
* @Author :        Shiva Sharma
* @Description : Controller for the vf page InstallBaseDownloadList
* @Updates :      Ashwini G : 24th Sept 2019 : CS- 274 : Added a new column for the install base download list
*/

public with sharing class InstallBaseDownloadController {
    
    
    Public List<InstallBaseWrapper> WrapperList {get;set;}
    
    public InstallBaseDownloadController() {
        
    }
    
    Public List<InstallBaseWrapper> getibWrapperObj(){
        /*List<Node__c> nodes = [select asset__c, asset__r.Name, bios_version__c,board_serial__c,chassis__c,chassis__r.Name,chassis__r.serial_number__c,cluster__r.uuid__c, cluster__c,Id,ipmi_mac_address__c,
mac_address_0__c,mac_address_1__c,manufactured_date__c,Name,OwnerId,serial_number__c,
asset__r.Support_Start_Date__c, asset__r.Support_End_Date__c, asset__r.Premium_Support_End_Date__c, asset__r.Product2.ProductCode,
software_version__c,
asset__r.Parent.Name               //CS-274 : Added a column for Asset's parent 
from  Node__c  where Model__c!='Edge' ];*/
        
        List<Cluster__c> clusters = [SELECT Id, Name, uuid__c, (Select Id, Name, asset__r.Parent.Name, asset__c, asset__r.Name, serial_number__c, chassis__r.serial_number__c, asset__r.Support_Start_Date__c, asset__r.Support_End_Date__c, asset__r.Premium_Support_End_Date__c, software_version__c from Nodes__r where Model__c!='Edge') FROM Cluster__c];
        
        List<Entitlement> cloutList = [Select Name,StartDate,EndDate,Terminated_Date__c,Product__r.ProductCode,
                                       Product__r.Family, Product__r.Name, Asset.Name
                                       from Entitlement where Product__r.Family='RBK-CLOUT'
                                      ];
        
        List<Entitlement> clonList = [Select Name,StartDate,EndDate,Terminated_Date__c,Product__r.ProductCode,
                                      Product__r.Family, Product__r.Name, Asset.Name
                                      from Entitlement where Product__r.Family='RBK-CLON'
                                     ];                                
        
        List<Entitlement> clclList = [Select Name,StartDate,EndDate,Terminated_Date__c,Product__r.ProductCode,
                                      Product__r.Family, Product__r.Name, Asset.Name
                                      from Entitlement where Product__r.Family='RBK-RCDM'
                                     ];                                
        
        
        WrapperList = New List<InstallBaseWrapper>();
        /*for(Node__c n : nodes){
WrapperList.add(New InstallBaseWrapper('Node', n.Name, n.cluster__r.uuid__c, n.asset__r.Support_Start_Date__c, n.asset__r.Premium_Support_End_Date__c, n.serial_number__c, n.asset__r.Name, n.chassis__r.serial_number__c, n.asset__r.Parent.Name)); 
}*/
        for(Cluster__c c : clusters){
            if(!c.Nodes__r.isEmpty()){
                for(Node__c n : c.Nodes__r){
                    WrapperList.add(New InstallBaseWrapper('Node', n.Name, c.uuid__c, n.asset__r.Support_Start_Date__c, n.asset__r.Premium_Support_End_Date__c,null, n.serial_number__c, n.asset__r.Name, n.chassis__r.serial_number__c, n.asset__r.Parent.Name));
                }
            } 
        }
        for(Entitlement e : cloutList){
            WrapperList.add(New InstallBaseWrapper('Cloud Out', e.Name, e.Asset.Name, e.StartDate, e.EndDate, e.Terminated_Date__c, null, null,null,null));           
        }
        for(Entitlement e : clonList){
            WrapperList.add(New InstallBaseWrapper('Cloud On', e.Name, e.Asset.Name, e.StartDate, e.EndDate, e.Terminated_Date__c, null, null,null,null));           
        }          
        for(Entitlement e : clclList){
            WrapperList.add(New InstallBaseWrapper('Cloud Cluster', e.Name, e.Asset.Name, e.StartDate, e.EndDate, e.Terminated_Date__c, null, null,null,null));           
        }   
        
        return WrapperList;
    } 
    
    Public Class InstallBaseWrapper{
        
        @AuraEnabled public string ibtype {get; set;}
        @AuraEnabled public string ibname {get; set;}
        @AuraEnabled public string uuid {get; set;}
        @AuraEnabled public date startdate {get; set;}
        @AuraEnabled public date enddate {get; set;}
        /*
        @description Termination Date Field
        */
        @AuraEnabled public date termdate {get; set;}
        @AuraEnabled  public string serial {get; set;}
        @AuraEnabled public string assetnum {get; set;}
        @AuraEnabled  public string chassiSerialNumber {get; set;}
        @AuraEnabled  public string parentassetname {get; set;}
        /*
            @description Initializes an InstallBaseWrapper with asset, lifecycle, and identification details.
            @param ibtype Install base type (e.g., hardware, software).
            @param ibname Install base name or asset title.
            @param uuid Unique identifier for the install base record.
            @param startdate Contract or coverage start date.
            @param enddate Contract or coverage end date.
            @param termdate Termination or decommission date, if applicable.
            @param serial Manufacturer serial number.
            @param assetnum Internal asset number or CMDB reference.
            @param chassiSerialNumber Chassis or frame serial identifier.
            @param parentassetname Parent asset name for hierarchy linking.
*/
        public InstallBaseWrapper( string ibtype, string ibname, string uuid, date startdate, date enddate, date termdate, string serial, string assetnum, string chassiSerialNumber, string parentassetname)
        {
            this.ibtype = ibtype;
            this.ibname = ibname;
            this.uuid = uuid;
            this.startdate = startdate;
            this.enddate = enddate;
            this.termdate = termdate;
            this.serial = serial;
            this.assetnum  = assetnum;
            this.chassiSerialNumber = chassiSerialNumber;
            this.parentassetname = parentassetname;
        }
    }
}