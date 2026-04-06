/**************************************************************************************************
 * @description       : Depreciated RMAOrderHandlerExtnClass  class as PRDOPS26-287
 * @last modified on  : 11-03-2025
 * @last modified by  : Prashant Kumar
 ******************************************************************************/
public class RMAOrderHandlerExtnClass { 
   /* public Case caseRecord{get;set;}
    public list<Account> accList;
    public boolean copyAddress{get;Set;}
    Public RMA_Order__c RMAOrder{get ;Set;}
    public Id selectedAssetId{get;set;}
    public Boolean isValidSupport{get;set;}
    public Id selectedNodeId{get;set;}
    public String[] selectedNodeList{get;set;}
    public String[] selectedDriveList{get;set;}
    public String[] selectedSSDDriveList{get;set;}
    public String[] selectedChassisList{get;set;}
    public String[] selectedMemoryList{get;set;}
    public String[] selectedPowerSupplyList{get;set;}
    public String[] selectedApplianceList{get;set;}
    public String[] selectedCMOSBatteryList{get;set;}
    
    public Boolean boolNodeQuantity{get;set;}
    public Boolean boolDriveQuantity{get;set;}
    public Boolean boolSSDDriveQuantity{get;set;}
    public Boolean boolChassisQuantity{get;set;}
    public Boolean boolMemoryQuantity{get;set;}
    public Boolean boolPSupplyQuantity{get;set;}
    public Boolean boolApplianceQuantity{get;set;}
    public Boolean boolCMOSBatteryQuantity{get;set;}
    
    public Boolean boolNodeSerialnumber{get;set;}
    public Boolean boolDriveSerialnumber{get;set;}
    public Boolean boolSSDDriveSerialnumber{get;set;}
    public Boolean boolChassisSerialnumber{get;set;}
    public Boolean boolMemorySerialnumber{get;set;}
    public Boolean boolPSupplySerialnumber{get;set;}
    public Boolean boolApplianceSerialnumber{get;set;}
    public Boolean boolCMOSBatterySerialnumber{get;set;}
    
    public List<SelectOption> listDarkSite{get;set;}
    public String rmaOrderName{get;set;}
    public String rmaOrderID{get;set;}
    public Boolean isApplianceSelected{get;set;}
    public Boolean boolDoHaveClusterID{get;set;}
    public List<SelectOption> listOfComponents{get;set;}
    public List<String> listOfSelectedComponents{get;set;}
    Public List< SelectOption > shippingAddressesOptions{get;set;}
    public String jsonMapFailureReasons{get;set;}
    public Map<String,String> mapFailureReasons;
    public String jsonMapFailureReasonsSelection{get;set;}
    public String jsonMapFailureOtherReasonsSelection{get;set;}
    public Map<String,String> mapFailureReasonsSelection;
    public Map<String,String> mapFailureOtherReasonsSelection;
    public Map<String,Boolean> assetWithSmartHandEntitlementBool {get;set;}
    public Map<ID,Boolean> assetWithEntitlements {get;set;}
    public String jsonMapSmartHandAsset {get;set;}
    
    public boolean isSSDSelected {get;set;}
    
    
    public Boolean smartHandQualified {get; set;}
    public Boolean smartHandRequested {get; set;}
    public Boolean smartHandAvailable {get;set;}
    
    public Id selectedDriveId{get;set;}
    public Id selectedMemoryId{get;set;}
    public Id selectedPowerSupplyId{get;set;}
    //public Id selectedNicId{get;set;}
    
    public List<SelectOption> assetOptionsList{get;set;}
    public List<SelectOption> nodeOptionsList{get;set;}
    public List<SelectOption> driveOptionsList{get;set;}
    public List<SelectOption> sSDDriveOptionsList{get;set;}
    public List<SelectOption> powerSupplyOptionsList{get;set;}
    public List<SelectOption> chassisOptionsList{get;set;}
    public List<SelectOption> applianceOptionsList{get;set;}
    public List<SelectOption> memoryOptionsList{get;set;}
    public List<SelectOption> CMOSBatteryOptionsList{get;set;}
    
    public PaginatedSelectList clusterIDOptionsList{get;set;}
    public list<Asset> assetList;               // List to hold instances to be inserted
    public List<String> countries{get;set;}
    public string  flag{get;set;}
    public string timezoneDate{get;set;}*/
    //Logic updated for PRDOPS21_278
    public RMAOrderHandlerExtnClass(ApexPages.StandardController controller){
        /*try{
            caseRecord =[select id,CaseNumber, AccountID,Account.ShippingStreet,Account.Name,Account.ShippingCity,Account.ShippingCountry,Account.ShippingPostalCode,Account.ShippingState from case where id=:ApexPages.currentPage().getParameters().get('id')];
            mapFailureReasons = new map<string, string>();
            for(RMA_Failure_List__c failure : RMA_Failure_List__c.getAll().values()){
                mapFailureReasons.put(failure.name, failure.Failure_Type__c);
            }
            jsonMapFailureReasons=JSON.serialize(mapFailureReasons); 
            jsonMapFailureReasonsSelection=''; 
            jsonMapFailureOtherReasonsSelection='';
            listOfComponents = new List<SelectOption>();
            smartHandRequested = false;
            smartHandQualified = false;
            smartHandAvailable = false;
            
            listOfComponents.add(new SelectOption('Appliance','Appliance'));
            listOfComponents.add(new SelectOption('Chassis','Chassis'));
            listOfComponents.add(new SelectOption('HDD','HDD'));
            listOfComponents.add(new SelectOption('SSD','SSD'));
            listOfComponents.add(new SelectOption('Memory','Memory'));
            //listOfComponents.add(new SelectOption('NIC','NIC'));
            listOfComponents.add(new SelectOption('Node','Node'));
            listOfComponents.add(new SelectOption('PSU','PSU'));
            listOfComponents.add(new SelectOption('CMOS Battery','CMOS Battery'));
            system.debug('case 1--'+caseRecord);
            
            listDarkSite =new List<SelectOption>();
            //listDarkSite.add(new SelectOption('--None--','--None--'));
            listDarkSite.add(new SelectOption('Yes','Yes'));
            listDarkSite.add(new SelectOption('No','No'));
            RMAOrder= new RMA_Order__c(); 
            RMAOrder.Cluster_Id__c = ''; 
            RMAOrder.Ship_To_Name__C = caseRecord.AccountID; 
            isValidSupport= false;
            copyAddress= False;           
            assetOptionsList = new List<SelectOption>();
            assetOptionsList.add(new SelectOption('','--None--'));
            nodeOptionsList = new List<SelectOption>();
            nodeOptionsList.add(new SelectOption('','--None--'));
            selectedNodeList = new List<string>();
            selectedDriveList = new List<string>();
            selectedChassisList = new List<string>();
            selectedMemoryList = new List<string>();
            selectedPowerSupplyList = new List<string>();
            selectedApplianceList = new List<string>();
            selectedCMOSBatteryList = new List<string>();
            applianceOptionsList = new List<SelectOption>();
            applianceOptionsList.add(new SelectOption('','--None--'));
            cmosBatteryOptionsList = new List<SelectOption>();
            cmosBatteryOptionsList.add(new SelectOption('','--None--'));
            
            driveOptionsList = new List<SelectOption>();
            sSDDriveOptionsList = new List<SelectOption>();
            driveOptionsList.add(new SelectOption('','--None--'));
            sSDDriveOptionsList.add(new SelectOption('','--None--'));
            powerSupplyOptionsList = new List<SelectOption>();
            powerSupplyOptionsList.add(new SelectOption('','--None--'));
            chassisOptionsList = new List<SelectOption>();
            chassisOptionsList.add(new SelectOption('','--None--'));
            memoryOptionsList = new List<SelectOption>();
            memoryOptionsList.add(new SelectOption('','--None--'));
            
            
            boolNodeQuantity=false;
            boolDriveQuantity=false;
            boolSSDDriveQuantity=false;
            boolChassisQuantity=false;
            boolApplianceQuantity =false;
            boolPSupplyQuantity=false;
            boolMemoryQuantity=false;
            boolCMOSBatteryQuantity=false;
            
            boolNodeSerialnumber=false;
            boolDriveSerialnumber=false;
            boolSSDDriveSerialnumber=false;
            boolChassisSerialnumber=false;
            boolMemorySerialnumber=false;
            boolPSupplySerialnumber=false;
            boolApplianceSerialnumber=false;
            boolCMOSBatterySerialnumber =false;

            assetWithSmartHandEntitlementBool = new Map<String,Boolean>();
            getAssetWithSmartHandEntitlementMap(assetWithSmartHandEntitlementBool);
            
            listOfSelectedComponents = new List<String>();
            //, (Select id, Product__r.Name from Entitlements where Product__r.Name Like '%SmartHand%')
            if(caseRecord <> null && caseRecord.AccountId != null){
                accList=[select id, name, (Select id, SerialNumber ,name, Product2.Name from Assets),(select id,name, archived__c from Clusters__r where archived__c=false) from Account where id=:caseRecord.AccountID LIMIt 1];
            }
            if(!accList.isEmpty()){
                
                clusterIDOptionsList = new PaginatedSelectList();
                
                
                clusterIDOptionsList.add(new SelectOption('--None--','--None--'));
                for(Cluster__c cluster: accList[0].clusters__r){
                    if(cluster != null) {
                        clusterIDOptionsList.add(new SelectOption(cluster.Id,cluster.Name));
                    }
                    
                }
                clusterIDOptionsList.add(new SelectOption('Other','Other'));
                
                system.debug('Account--'+acclist[0]);
                
                // if(accList[0].Entitlements.size()>0){
                //     smartHandAvailable= true;
                //     smartHandRequested = true;
                // }
                getAssetWithSmartHandEntitlementMap(assetWithSmartHandEntitlementBool);
                jsonMapSmartHandAsset = JSON.serialize(assetWithSmartHandEntitlementBool);
                    
            }
        }
        catch(Exception ex){
            system.debug(ex);
        }*/
    }
    /*List<Asset> currentAsset;
    public void getAssetWithSmartHandEntitlementMap(Map<String, Boolean> assetWithSmartHandEntitlementBool) {
        Set<Id>ParentAssetIDs = New Set<ID>();
        Map<Id,Asset> ParentAssetMap = new Map<Id,Asset>();
        // List<Asset> assetList =[Select id, name, Serial_Number__c,
        //                             (Select Id, name , Product__c,Product__r.Name 
        //                                 from Entitlements where Product__r.Name LIKE '%SmartHand%' AND status = 'Active') 
                                    
        //                             from Asset where AccountId =: caseRecord.AccountId
        //                         ];
        List<String> eligibleProductList = new List<String>{ 'RBK-SVC-CEM', 'RBK-SVC-ASE', 'RBK-SVC-PROACTIVE', 'RBK-SVC-ENTERPRISE' };
        List<Asset> assetList = [select Id,SerialNumber,serial_number__c,ParentId, Premium_Support_End_Date__c, Account.Global_2000__c, Account.Type,
                                        Account.Sum_of_Opportunities__c,Account.Smart_Hands_Qualified__c,Account.Segment_Class__c,
                                        (Select Id,Name,Serial_Number__c,Asset__r.serial_number__c from Nodes__r),
                                        (Select Id,Name,Serial_Number__c,node__r.Name, node__r.Asset__r.serial_number__c from Drives__r),
                                        (Select Id,Name,Serial_Number__c,Asset__r.Name, Asset__r.serial_number__c from chassis__r), 
                                        (Select Id,Name,Serial_Number__c, Asset__r.serial_number__c from Power_Supplies__r), 
                                        (Select Id,Name,Serial_Number__c,Node__r.Name, node__r.Asset__r.serial_number__c from Nics__r),
                                        (Select Id,Name,Serial_Number__c,Node__r.Name, node__r.Asset__r.serial_number__c from Memory__r),
                                        (Select Id, name , Product__c,Product__r.Name 
                                        from Entitlements where status = 'Active')  
                                    from Asset where AccountId =: caseRecord.AccountId];
        
        // Added for PRDOPS21-203 to handle parent check
        Map<ID,Boolean> assetWithEntitlements = new Map<ID,Boolean>();
        if(!assetList.isEmpty()){
            for(Asset assetData: assetList){
                if(assetData.ParentId != NULL){
                    ParentAssetIDs.add(assetData.ParentId);
                }
                else{
                    if(!assetData.Entitlements.isEmpty()){
                        for(Entitlement EntitleData: assetData.Entitlements){
                      // new products added
                            if(EntitleData.Product__r.Name=='RBK-SVC-CEM'||EntitleData.Product__r.Name=='RBK-SVC-ASE'||EntitleData.Product__r.Name=='RBK-SVC-PROACTIVE'||EntitleData.Product__r.Name=='RBK-SVC-ENTERPRISE' || EntitleData.Product__r.Name=='RBK-SVC-PROACTIVE-PA' || EntitleData.Product__r.Name=='RBK-SVC-PROACTIVE-ADDON-PA'|| EntitleData.Product__r.Name=='RBK-SVC-PROACTIVE-ADDON'||EntitleData.Product__r.Name=='RBK-SVC-CEM-ADDON'||EntitleData.Product__r.Name=='RBK-SVC-CEM-PA'||EntitleData.Product__r.Name=='RBK-SVC-CEM-ADDON-PA'||EntitleData.Product__r.Name=='RBK-SVC-PROACTIVE-ADDON'||EntitleData.Product__r.Name=='RBK-SVC-PROACTIVE-ADDON-PA'||EntitleData.Product__r.Name=='RBK-SVC-PROACTIVE-PA'){
                                if(assetWithEntitlements.containsKey(assetData.ID) && assetWithEntitlements.get(assetData.ID) == False){
                                    assetWithEntitlements.remove(assetData.ID);
                                    assetWithEntitlements.put(assetData.Id,true);
                                    break;
                                }
                                else{
                                    assetWithEntitlements.put(assetData.Id,true);
                                    break;
                                }
                            }
                            else {
                                assetWithEntitlements.put(assetData.Id,false);
                                        
                            }
                        }
                    }
                }
            }
        }
        system.debug('PARENT ID SET'+ ParentAssetIDs);
        if(ParentAssetIDs.size() > 0){
                for(Asset ParentAsset : [select Id,SerialNumber,serial_number__c,ParentId, Premium_Support_End_Date__c, Account.Global_2000__c, Account.Type,
                                            Account.Sum_of_Opportunities__c,Account.Smart_Hands_Qualified__c,Account.Segment_Class__c,
                                            (Select Id,Name,Serial_Number__c,Asset__r.serial_number__c from Nodes__r),
                                            (Select Id,Name,Serial_Number__c,node__r.Name, node__r.Asset__r.serial_number__c from Drives__r),
                                            (Select Id,Name,Serial_Number__c,Asset__r.Name, Asset__r.serial_number__c from chassis__r), 
                                            (Select Id,Name,Serial_Number__c, Asset__r.serial_number__c from Power_Supplies__r), 
                                            (Select Id,Name,Serial_Number__c,Node__r.Name, node__r.Asset__r.serial_number__c from Nics__r),
                                            (Select Id,Name,Serial_Number__c,Node__r.Name, node__r.Asset__r.serial_number__c from Memory__r),
                                            (Select Id, name , Product__c,Product__r.Name 
                                            from Entitlements where status = 'Active')  
                                            from Asset where Id  IN: ParentAssetIDs]){
                                                ParentAssetMap.put(ParentAsset.Id,ParentAsset);
            }
        }
        Map<ID,Boolean> parentassetWithEntitlements = new Map<ID,Boolean>();
        if(!ParentAssetMap.isEmpty()){
            for(Asset ParentAsset:ParentAssetMap.Values()){
                    if(!ParentAsset.Entitlements.isEmpty()){
                            for(Entitlement parenrEntitleData: ParentAsset.Entitlements){
                                  if(parenrEntitleData.Product__r.Name=='RBK-SVC-CEM'||parenrEntitleData.Product__r.Name=='RBK-SVC-ASE'||parenrEntitleData.Product__r.Name=='RBK-SVC-PROACTIVE'||parenrEntitleData.Product__r.Name=='RBK-SVC-ENTERPRISE'|| parenrEntitleData.Product__r.Name=='RBK-SVC-PROACTIVE-PA'|| parenrEntitleData.Product__r.Name=='RBK-SVC-PROACTIVE-ADDON-PA'|| parenrEntitleData.Product__r.Name=='RBK-SVC-PROACTIVE-ADDON'||parenrEntitleData.Product__r.Name=='RBK-SVC-CEM-ADDON'||parenrEntitleData.Product__r.Name=='RBK-SVC-CEM-PA'||parenrEntitleData.Product__r.Name=='RBK-SVC-CEM-ADDON-PA'||parenrEntitleData.Product__r.Name=='RBK-SVC-PROACTIVE-ADDON'||parenrEntitleData.Product__r.Name=='RBK-SVC-PROACTIVE-ADDON-PA'||parenrEntitleData.Product__r.Name=='RBK-SVC-PROACTIVE-PA')
                                    {
                                        if(parentassetWithEntitlements.containsKey(ParentAsset.ID) && parentassetWithEntitlements.get(ParentAsset.ID) == False)
                                        {
                                            parentassetWithEntitlements.remove(ParentAsset.ID);
                                            parentassetWithEntitlements.put(ParentAsset.Id,true);
                                            break;
                                        }
                                        else
                                        {
                                            parentassetWithEntitlements.put(ParentAsset.Id,true);
                                            break;
                                        }
                                    }
                                    else
                                    {
                                        parentassetWithEntitlements.put(ParentAsset.Id,false);
                                        
                                    }
                            }
                        
                    }
                
            }
        }
        

        if(!assetList.isEmpty()) {
            for(Asset assetRecord : assetList) {
                if(assetRecord.ParentId != NULL && ParentAssetMap.containsKey(assetRecord.ParentId)){
                    Asset ParentAssetInfo = ParentAssetMap.get(assetRecord.ParentId);
                    if((!ParentAssetInfo.Entitlements.isEmpty() && ( (ParentAssetInfo.Account.Global_2000__c ==true && ParentAssetInfo.Account.Type=='Customer') || (ParentAssetInfo.Account.Sum_of_Opportunities__c >= 1000000)|| (parentassetWithEntitlements.get(assetRecord.ParentId)!= false))) || (ParentAssetInfo.Account.Smart_Hands_Qualified__c ==true ) ||(ParentAssetInfo.Account.Segment_Class__c == 'Enterprise') ) {
                            assetWithSmartHandEntitlementBool.put(assetRecord.Serial_Number__c, true);
                            for(Node__c nodeRec: assetRecord.Nodes__r) {
                                assetWithSmartHandEntitlementBool.put(nodeRec.Serial_Number__c, true);
                            }
                            for(Drive__c driveRec: assetRecord.Drives__r) {
                                assetWithSmartHandEntitlementBool.put(driveRec.Serial_Number__c, true);
                            }
                            for(Chassis__c chassisRec: assetRecord.Chassis__r) {
                                assetWithSmartHandEntitlementBool.put(chassisRec.Serial_Number__c, true);
                            }
                            for(Power_Supply__c PSURec: assetRecord.Power_Supplies__r) {
                                assetWithSmartHandEntitlementBool.put(PSURec.Serial_Number__c, true);
                            }
                            for(Nic__c nicRec: assetRecord.Nics__r) {
                                assetWithSmartHandEntitlementBool.put(nicRec.Serial_Number__c, true);
                            }
                            for(Memory__c memoryRec: assetRecord.Memory__r) {
                                assetWithSmartHandEntitlementBool.put(memoryRec.Serial_Number__c, true);
                            }
                        
                    }
                }
                else{
                    //SF-6779- added by Varsha as criteria for smart hand service is changed
                    if((!assetRecord.Entitlements.isEmpty() && ( (assetRecord.Account.Global_2000__c ==true && assetRecord.Account.Type=='Customer') || (assetRecord.Account.Sum_of_Opportunities__c >= 1000000)|| (assetWithEntitlements.get(assetRecord.ID)!= false))) || (assetRecord.Account.Smart_Hands_Qualified__c ==true ) || (assetRecord.Account.Segment_Class__c == 'Enterprise')) {
                            assetWithSmartHandEntitlementBool.put(assetRecord.Serial_Number__c, true);
                            for(Node__c nodeRec: assetRecord.Nodes__r) {
                                assetWithSmartHandEntitlementBool.put(nodeRec.Serial_Number__c, true);
                            }
                            for(Drive__c driveRec: assetRecord.Drives__r) {
                                assetWithSmartHandEntitlementBool.put(driveRec.Serial_Number__c, true);
                            }
                            for(Chassis__c chassisRec: assetRecord.Chassis__r) {
                                assetWithSmartHandEntitlementBool.put(chassisRec.Serial_Number__c, true);
                            }
                            for(Power_Supply__c PSURec: assetRecord.Power_Supplies__r) {
                                assetWithSmartHandEntitlementBool.put(PSURec.Serial_Number__c, true);
                            }
                            for(Nic__c nicRec: assetRecord.Nics__r) {
                                assetWithSmartHandEntitlementBool.put(nicRec.Serial_Number__c, true);
                            }
                            for(Memory__c memoryRec: assetRecord.Memory__r) {
                                assetWithSmartHandEntitlementBool.put(memoryRec.Serial_Number__c, true);
                            }

                    }
                    else {
                        //assetWithSmartHandEntitlementBool.put(assetRecord.Serial_Number__c, false);
                    }
                }
            }
        }
        System.debug('@@@SmartHand@@@ assetWithSmartHandEntitlementBool@@@-'+assetWithSmartHandEntitlementBool);
        System.debug('@@@SmartHand@@@ assetWithSmartHandEntitlementBool@@@SIZE-'+assetWithSmartHandEntitlementBool.size());
    
    }
    public void  fetchAssetConfigs(){
        system.debug('in Fetch Asset method');
        System.debug('selectedDriveList-onchange-'+selectedDriveList);
        List<Asset> currentAsset;
        if(boolSSDDriveQuantity) {
                currentAsset = [select Id,SerialNumber,serial_number__c, Premium_Support_End_Date__c,
                                        (Select Id,Name,Serial_Number__c,Asset__r.serial_number__c from Nodes__r),
                                         (Select Id,Name,Serial_Number__c,node__r.Name, node__r.Asset__r.serial_number__c from Drives__r),
                                         (Select Id,Name,Serial_Number__c,Asset__r.Name, Asset__r.serial_number__c from chassis__r), 
                                         (Select Id,Name,Serial_Number__c, Asset__r.serial_number__c from Power_Supplies__r), 
                                         (Select Id,Name,Serial_Number__c,Node__r.Name, node__r.Asset__r.serial_number__c from Nics__r),
                                         (Select Id,Name,Serial_Number__c,Node__r.Name, node__r.Asset__r.serial_number__c from Memory__r) 
                                     from Asset where AccountId=: AcclIst[0].id AND (Product2.Family = 'R6000' OR Product2.Family = 'E1000')];
                                     
        }
        else {
               currentAsset = [select Id,SerialNumber,serial_number__c, Premium_Support_End_Date__c,
                                        (Select Id,Name,Serial_Number__c,Asset__r.serial_number__c from Nodes__r),
                                         (Select Id,Name,Serial_Number__c,node__r.Name, node__r.Asset__r.serial_number__c from Drives__r),
                                         (Select Id,Name,Serial_Number__c,Asset__r.Name, Asset__r.serial_number__c from chassis__r), 
                                         (Select Id,Name,Serial_Number__c, Asset__r.serial_number__c from Power_Supplies__r), 
                                         (Select Id,Name,Serial_Number__c,Node__r.Name, node__r.Asset__r.serial_number__c from Nics__r),
                                         (Select Id,Name,Serial_Number__c,Node__r.Name, node__r.Asset__r.serial_number__c from Memory__r) 
                                     from Asset where AccountId=: AcclIst[0].id];
        }
            
         
       
        applianceOptionsList = new List<SelectOption>();
        for(Asset asset : currentAsset){
            if(asset != null && asset.serial_number__c != null)
            applianceOptionsList.add(new SelectOption(asset.serial_number__c,asset.serial_number__c));
        }
        system.debug('SelectOption=='+applianceOptionsList);
        
        nodeOptionsList = new List<SelectOption>();
        for(Asset asset : currentAsset){
            for(Node__c nodeRec : asset.Nodes__r){
                nodeOptionsList.add(new SelectOption(NodeRec.serial_number__c,nodeRec.serial_number__c));
                // //#smarthands
                 if(nodeRec.Asset__c != null) {
                     if(assetWithSmartHandEntitlementBool.containsKey(nodeRec.Asset__r.serial_number__c)) {
                         assetWithSmartHandEntitlementBool.put(nodeRec.Serial_Number__c, true);
                     }
                 }
                
            }
        }
    }
    
    public Void  fetchSelectedComponent(){
        system.debug('RMAOrder.Cluster_Id__c =='+RMAOrder.Cluster_Id__c);
        applianceOptionsList =new List<SelectOption>();
        applianceOptionsList.add(new SelectOption('','--None--'));
        nodeOptionsList =new List<SelectOption>();
        nodeOptionsList.add(new SelectOption('','--None--'));
        
        if((RMAOrder.Cluster_Id__c != '' && RMAOrder.Cluster_Id__c != null)){
            List<Cluster__c> listClustersWithNodes;
            List<Node__c> listNodesWithAsset;
            if(boolSSDDriveQuantity) {
                listClustersWithNodes =[select id,name, (select id,name,serial_number__c, Asset__r.serial_number__c from Nodes__r where (Asset__r.Product2.Family = 'R6000' OR Asset__r.Product2.Family = 'E1000')) from Cluster__C where Id=:RMAOrder.Cluster_Id__c Limit 1];
                RMAOrder.Cluster__c = listClustersWithNodes[0].name;
                listNodesWithAsset = [Select id, asset__c, asset__r.name, Asset__r.serial_number__c,serial_number__c, cluster__c from Node__C where  cluster__c=:RMAOrder.Cluster_Id__c AND (Asset__r.Product2.Family = 'R6000' OR Asset__r.Product2.Family = 'E1000')];
            }
            else {
                listClustersWithNodes =[select id,name, (select id,name,serial_number__c, Asset__r.serial_number__c from Nodes__r) from Cluster__C where Id=:RMAOrder.Cluster_Id__c Limit 1];
                RMAOrder.Cluster__c = listClustersWithNodes[0].name;
                listNodesWithAsset = [Select id, asset__c, asset__r.name, Asset__r.serial_number__c,serial_number__c, cluster__c from Node__C where  cluster__c=:RMAOrder.Cluster_Id__c];
            }
            Set<String> uniqueAssets = new Set<String>();
            for(Node__c nodeRec : listNodesWithAsset){
                //nodeOptionsList.add(new SelectOption(NodeRec.id,nodeRec.serial_number__c));
                if(NodeRec.asset__r.serial_number__c != null) {
                    uniqueAssets.add(NodeRec.asset__r.serial_number__c);
                    // //#smarthands
                    // if(NodeRec.asset__r.serial_number__c != null) {
                    //     if(assetWithSmartHandEntitlementBool.containsKey(nodeRec.Asset__r.serial_number__c)) {
                    //         assetWithSmartHandEntitlementBool.put(nodeRec.Serial_Number__c, true);
                    //     }
                    // }
                }
                    
            }
            system.debug('listNodesWithAsset =='+listNodesWithAsset);
            applianceOptionsList = new List<SelectOption>();
            for(String assetRec : uniqueAssets){
                applianceOptionsList.add(new SelectOption(assetRec,assetRec));
            }
            if(applianceOptionsList.size()==0)
                applianceOptionsList.add(new SelectOption('Other','No Asset Found'));
            system.debug('applianceOptionsList =='+applianceOptionsList);
            nodeOptionsList = new List<SelectOption>();
            if(!listClustersWithNodes.isEmpty()){
                for(Node__c nodeRec : listClustersWithNodes[0].Nodes__r){
                    nodeOptionsList.add(new SelectOption(NodeRec.serial_number__c,nodeRec.serial_number__c));
                    // //#smarthands
                    // System.debug('NodeRec.asset__r.SerialNumber =='+NodeRec.asset__r.serial_number__c) ;
                    // if(NodeRec.asset__r.serial_number__c != null) {
                    //     if(assetWithSmartHandEntitlementBool.containsKey(nodeRec.Asset__r.serial_number__c)) {
                    //         System.debug('assey keybool==');
                    //         assetWithSmartHandEntitlementBool.put(nodeRec.Serial_Number__c, true);
                    //     }
                    // }
                }
                System.debug('assetWithSmartHandEntitlementBool=='+assetWithSmartHandEntitlementBool);
            }
            if(nodeOptionsList.size()==0)
                nodeOptionsList.add(new SelectOption('Other','No Node Found'));
            
        }
        
    }
    public Void  fetchAssetorNodeComponents(){
        system.debug('selectedApplianceList =='+selectedApplianceList);
        chassisOptionsList =new List<SelectOption>();
        chassisOptionsList.add(new SelectOption('','--None--'));
        driveOptionsList =new List<SelectOption>();
        driveOptionsList.add(new SelectOption('','--None--'));
        sSDDriveOptionsList =new List<SelectOption>();
        sSDDriveOptionsList.add(new SelectOption('','--None--'));
        
        memoryOptionsList =new List<SelectOption>();
        memoryOptionsList.add(new SelectOption('','--None--'));
        powerSupplyOptionsList=new List<SelectOption>();
        powerSupplyOptionsList.add(new SelectOption('','--None--'));
        cmosBatteryOptionsList=new List<SelectOption>();
        cmosBatteryOptionsList.add(new SelectOption('','--None--'));

        if((selectedApplianceList.size() != null && selectedApplianceList.size() >0)){
            List<Asset> listcomponentsWithAsset =[select id,name, (select id,name,serial_number__c,Asset__r.Name, Asset__r.serial_number__c from Power_Supplies__r), (select id,name,serial_number__c,Asset__r.Name, Asset__r.serial_number__c from Chassis__r) from Asset where Serial_Number__C IN: selectedApplianceList];
            chassisOptionsList = new List<SelectOption>();
            for(Asset asst : listcomponentsWithAsset) {
                for(Chassis__c chassisRec : asst.chassis__r){
                    chassisOptionsList.add(new SelectOption(chassisRec.serial_number__c, chassisRec.serial_number__c+' - ('+chassisRec.Asset__r.Name+')'));
                    // //#smarthands
                    // if(chassisRec.asset__r.serial_number__c != null) {
                    //     if(assetWithSmartHandEntitlementBool.containsKey(chassisRec.Asset__r.serial_number__c)) {
                    //         assetWithSmartHandEntitlementBool.put(chassisRec.serial_number__c, true);
                    //     }
                    // }
                }
            }
            if(chassisOptionsList.size()==0)
                chassisOptionsList.add(new SelectOption('Other','No Chassis found'));
            
            powerSupplyOptionsList = new List<SelectOption>();
            for(Asset asst : listcomponentsWithAsset) {
                for(Power_Supply__c psupplyRec : asst.Power_supplies__r){
                    powerSupplyOptionsList.add(new SelectOption(psupplyRec.serial_number__c,psupplyRec.serial_number__c+' - ('+psupplyRec.Asset__r.Name+')'));
                    // //#smarthands
                    // if(psupplyRec.asset__r.serial_number__c != null) {
                    //     if(assetWithSmartHandEntitlementBool.containsKey(psupplyRec.Asset__r.serial_number__c)) {
                    //         assetWithSmartHandEntitlementBool.put(psupplyRec.serial_number__c, true);
                    //     }
                    // }
                }
            }
            if(powerSupplyOptionsList.size()==0)
                powerSupplyOptionsList.add(new SelectOption('Other','No PSU found'));
        }
        if(selectedNodeList.size() != null && selectedNodeList.size() >0){ 
            List<Node__c> listComponentsWithNode =[select id,name,cluster__c,serial_number__c, 
                                                    (select id,name ,Node__r.name,serial_number__c, Node__r.Asset__r.serial_number__c, Type__c from HDDS__r),
                                                    (select id,name,Node__r.name,serial_number__c, Node__r.Asset__r.serial_number__c from Nics__R),
                                                    (select id,name,Node__r.name,serial_number__c, Node__r.Asset__r.serial_number__c from Memory__R) 
                                                    from Node__c where Serial_Number__C IN:selectedNodeList];
            
            driveOptionsList = new List<SelectOption>();
            sSDDriveOptionsList = new List<SelectOption>();
            if(!listComponentsWithNode.isEmpty()){
                for(Node__c node : listComponentsWithNode) {
                    for(Drive__c driveRec : node.HDDs__r){
                        if(driveRec.Type__c == 'HDD') {
                            driveOptionsList.add(new SelectOption(driveRec.serial_number__c,driveRec.serial_number__c +' - ('+driveRec.Node__r.name+')'));
                        }
                        if(driveRec.Type__c == 'SSD') {
                            ssdDriveOptionsList.add(new SelectOption(driveRec.serial_number__c,driveRec.serial_number__c +' - ('+driveRec.Node__r.name+')'));
                        }
                        // //#smarthands
                        // if(driveRec.Node__r.Asset__r.serial_number__c != null) {
                        //     if(assetWithSmartHandEntitlementBool.containsKey(driveRec.Node__r.Asset__r.serial_number__c)) {
                        //         assetWithSmartHandEntitlementBool.put(driveRec.serial_number__c, true);
                        //     }
                        // }
                    }
                    
                }
            }
            if(driveOptionsList.size()==0) {
                driveOptionsList.add(new SelectOption('Other','No Drive Found'));
            }
            if(ssdDriveOptionsList.size()==0) {
                ssdDriveOptionsList.add(new SelectOption('Other','No Drive Found'));
            }
            
            memoryOptionsList = new List<SelectOption>();
            if(!listComponentsWithNode.isEmpty()){
                for(Node__c node : listComponentsWithNode) {    
                    for(Memory__C memRec : node.Memory__r){
                        memoryOptionsList.add(new SelectOption(memRec.serial_number__c,memRec.serial_number__c+' - ('+memRec.Node__r.Name+')'));
                        // //#smarthands
                        // if(memRec.Node__r.Asset__r.serial_number__c != null) {
                        //     if(assetWithSmartHandEntitlementBool.containsKey(memRec.Node__r.Asset__r.serial_number__c)) {
                        //         assetWithSmartHandEntitlementBool.put(memRec.serial_number__c, true);
                        //     }
                        // }
                    }
                }
            }
            if(memoryOptionsList.size()==0)
                memoryOptionsList.add(new SelectOption('Other','No Memory Found'));
            
            system.debug('memoryOptionsList=='+memoryOptionsList);

            cmosBatteryOptionsList = new List<SelectOption>();
            cmosBatteryOptionsList.add(new SelectOption('CMOS Battery','CMOS Battery'));
            
            system.debug('cmosBatteryOptionsList=='+cmosBatteryOptionsList);
        }
    }
    
    public PageReference setAddress(){
        if(copyAddress == true){
            copyAddress =true; 
            RMAOrder.Shipping_Street__c = CaseRecord.Account.ShippingStreet;
            RMAOrder.Shipping_City__c = CaseRecord.Account.ShippingCity;
            RMAOrder.ShippingState__c = CaseRecord.Account.ShippingState;
            
            RMAOrder.Shipping_Zip_Postal_Code__c = CaseRecord.Account.ShippingPostalCode;
            RMAOrder.ShippingCountry__c = CaseRecord.Account.ShippingCountry;
            system.debug('RMAOrder.ShippingCountry__c '+RMAOrder.ShippingCountry__c);
            if(RMAOrder.ShippingCountry__c == 'USA' || RMAOrder.ShippingCountry__c =='US'){
                RMAOrder.ShippingCountry__c ='United States';
            }
        }else{
            copyAddress =false; 
            RMAOrder.Shipping_Street__c = '';
            RMAOrder.Shipping_City__c = '';
            RMAOrder.ShippingState__c = '';
            RMAOrder.Shipping_Zip_Postal_Code__c = '';
            RMAOrder.ShippingCountry__c = '';
        } 
        return null;
        
    }
    
    public void makeComponentInputSeletion(){
        system.debug('listSelectedComponents=='+listOfSelectedComponents);
        System.debug('selectedDriveList-onchange-'+selectedDriveList);
        Set<String> compSet = new Set<String>();
        RMAOrder.Cluster_ID__c='';
        
        selectedNodeList = new List<string>();
        selectedDriveList = new List<string>();
        selectedSSDDriveList = new List<string>();
        selectedChassisList = new List<string>();
        selectedMemoryList = new List<string>();
        selectedPowerSupplyList = new List<string>();
        selectedApplianceList = new List<string>();
        selectedCMOSBatteryList = new List<string>();
        
        RMAOrder.Node_Quantity__c = null;
        RMAOrder.Drive_Quantity__c = null;
        RMAOrder.SSD_Quantity__c = null;
        RMAOrder.Memory_Quantity__c = null;
        RMAOrder.Chasis_Quantity__c = null;
        RMAOrder.Power_Supply_Quantity__c = null;
        RMAOrder.Appliance_Quantity__c  = null;
        RMAOrder.CMOS_Battery_Quantity__c  = null;
        
        System.debug('selectedDriveList-onchange 2-'+selectedDriveList);
        boolNodeSerialnumber =false;
        boolApplianceSerialnumber = false;
        boolDriveSerialnumber = false;
        boolSSDDriveSerialnumber = false;
        boolChassisSerialnumber = false;
        boolPSupplySerialnumber = false;
        boolMemorySerialnumber = false;
        boolCMOSBatterySerialnumber = false;
        
        if(listOfSelectedComponents != null || !listOfSelectedComponents.isEmpty()) {
            compSet.addAll(listOfSelectedComponents);
        }
        
        boolApplianceQuantity= false;
        for(String comp : compSet){
            if(compSet.contains('Appliance')){
                boolNodeQuantity = false;
                boolDriveQuantity = false;
                boolSSDDriveQuantity = false;
                boolChassisQuantity = false;
                boolPSupplyQuantity = false;
                //boolNICQuantity = false;
                boolMemoryQuantity = false;
                boolCMOSBatteryQuantity = false;
                boolApplianceQuantity = compSet.contains('Appliance')? true: false;
            }
            else{
                boolNodeQuantity = compSet.contains('Node')? true: false;
                boolSSDDriveQuantity = compSet.contains('SSD')? true: false;
                isSSDSelected = compSet.contains('SSD') && compset.size()>=2? true: false;
                boolDriveQuantity = compSet.contains('HDD')? true: false;
                boolChassisQuantity = compSet.contains('Chassis')? true: false;
                boolPSupplyQuantity = compSet.contains('PSU')? true: false;
                //boolNICQuantity = compSet.contains('NIC')? true: false;
                boolMemoryQuantity = compSet.contains('Memory')? true: false;
                boolCMOSBatteryQuantity = compSet.contains('CMOS Battery')? true: false;
            }
        }
        
    }
    
    public void makeComponentSeletion(){
        system.debug('listSelectedComponents=='+listOfSelectedComponents);
        Set<String> compSet = new Set<String>();
        if(listOfSelectedComponents != null || !listOfSelectedComponents.isEmpty())
            compSet.addAll(listOfSelectedComponents);
        for(String comp : compSet){
            system.debug('comp=='+comp);
            if(compSet.contains('Node') || compSet.contains('SSD') || compSet.contains('HDD') || compSet.contains('NIC') || compSet.contains('Memory') || compSet.contains('CMOS Battery'))
                boolNodeSerialnumber =true;
            if(compSet.contains('Appliance') || compSet.contains('Chassis') || compSet.contains('PSU'))
                boolApplianceSerialnumber = true;
            
        }
        system.debug('boolApplianceSerialnumber=='+boolApplianceSerialnumber);
        system.debug('boolNodeSerialnumber=='+boolNodeSerialnumber);
        if(RMAOrder.Cluster_ID__c != 'Other' && RMAOrder.Cluster_ID__c != '--None--' ){
            
            fetchSelectedComponent();
            
        }
        else{
            fetchAssetConfigs();
        }
    }
    
    
    public void makeAssetSeletion(){
        system.debug('listSelectedComponents=='+listOfSelectedComponents);
        Set<String> compSet = new Set<String>();
        if(listOfSelectedComponents != null || !listOfSelectedComponents.isEmpty())
            compSet.addAll(listOfSelectedComponents);
        for(String comp : compSet){
            system.debug('comp=='+comp);
            if(compSet.contains('Node') || compSet.contains('HDD') || compSet.contains('SSD') || compSet.contains('NIC') || compSet.contains('Memory') || compSet.contains('CMOS Battery')){
                boolNodeSerialnumber =true;
                boolDriveSerialnumber = compSet.contains('HDD')? true: false;
                boolSSDDriveSerialnumber = compSet.contains('SSD')? true: false;
                boolMemorySerialnumber = compSet.contains('Memory')? true: false;
                boolCMOSBatterySerialnumber = compSet.contains('CMOS Battery')? true: false;
            }
            if(compSet.contains('Appliance') || compSet.contains('Chassis') || compSet.contains('PSU')){
                boolApplianceSerialnumber = true;
                boolChassisSerialnumber = compSet.contains('Chassis')? true: false;
                boolPSupplySerialnumber = compSet.contains('PSU')? true: false;
            }
            
            
        }
        system.debug('boolApplianceSerialnumber=='+boolApplianceSerialnumber);
        system.debug('boolPSupplySerialnumber=='+boolPSupplySerialnumber);
        system.debug('boolChassisSerialnumber=='+boolChassisSerialnumber);
        system.debug('boolDriveSerialnumber=='+boolDriveSerialnumber);
        system.debug('boolSSDDriveSerialnumber=='+boolSSDDriveSerialnumber);
        system.debug('boolMemorySerialnumber=='+boolMemorySerialnumber);
        system.debug('boolNodeSerialnumber=='+boolNodeSerialnumber);
        system.debug('boolCMOSBatterySerialnumber=='+boolCMOSBatterySerialnumber);
        
        fetchAssetorNodeComponents();
    }
    
    public void showClusterField(){
        system.debug('boolDoHaveClusterID =='+boolDoHaveClusterID);
    }
    
    public PageReference saveRMA(){
        try{
            system.Debug('RMA Request'+RMAOrder);
            jsonMapFailureReasonsSelection = Apexpages.currentPage().getParameters().get('jsonMapFailureReasonsSelection');
            jsonMapFailureOtherReasonsSelection = Apexpages.currentPage().getParameters().get('jsonMapFailureOtherReasonsSelection');
            system.Debug('RMA Request jsonMapFailureReasonsSelection'+jsonMapFailureReasonsSelection);
            system.Debug('RMA Request jsonMapFailureReasonsSelection'+jsonMapFailureOtherReasonsSelection);
            system.Debug('RMA Request jsonMapFailureReasonsSelection'+String.isNotBlank(jsonMapFailureReasonsSelection));
            system.Debug('RMA Request jsonMapFailureReasonsSelection'+String.isNotBlank(jsonMapFailureOtherReasonsSelection));
            system.Debug('RMA Request jsonMapFailureReasonsSelection'+jsonMapFailureReasonsSelection.length());
            system.Debug('RMA Request jsonMapFailureReasonsSelection'+jsonMapFailureOtherReasonsSelection.length());
            mapFailureReasonsSelection = new Map<String,String>();
            if (String.isNotBlank(jsonMapFailureReasonsSelection)) {
                mapFailureReasonsSelection = (Map<String,String>) JSON.deserialize(jsonMapFailureReasonsSelection, Map<String,String>.class);
            }
            system.Debug('RMA Request mapFailureReasonsSelection'+mapFailureReasonsSelection);
            
            mapFailureOtherReasonsSelection = new Map<String,String>();
            if (String.isNotBlank(jsonMapFailureOtherReasonsSelection)) {
                mapFailureOtherReasonsSelection = (Map<String,String>) JSON.deserialize(jsonMapFailureOtherReasonsSelection, Map<String,String>.class);
            }
            system.Debug('RMA Request mapFailureReasonsSelection'+mapFailureOtherReasonsSelection);
            
            system.Debug('RMA Request SelectedAssetId'+selectedApplianceList);
            if(selectedApplianceList <> Null && selectedApplianceList.size()>0)
                RMAOrder.Appliance__c = String.join(selectedApplianceList,';');
            
            
            
            RMAOrder.Parent_Case__c = caseRecord.Id;
            RMAOrder.Node__c = String.join(SelectedNodeList, ',');
            RMAOrder.Drive__c = String.join(SelectedDriveList, ',');
            RMAOrder.SSD__c = String.join(selectedSSDDriveList, ',');
            RMAOrder.Memory__c = String.join(selectedMemoryList, ',');
            RMAOrder.Chassis__c = String.join(selectedChassisList, ',');
            RMAOrder.Power_Supply__c = String.join(SelectedPowersupplyList, ',');
            RMAOrder.CMOS_Battery__c = String.join(selectedCMOSBatteryList, ',');
            system.debug('copyAdress=='+ copyAddress);
            system.debug('CaseRecord=='+ CaseRecord);
            
            // Adding Logic
            Set<String> relatedAssetSN = new Set<String>();
            Set<string> allAppliances = new Set<string> ();
            //Added for SF-7053
            Set<ID> ParentAssetToQuery = New Set<ID>();
            Map<Id,String>ParentSerialNumber =New Map<Id,String>();
            map<ID,Asset> selectedAssetMap = New map<ID,Asset>();
            for(String sn : selectedApplianceList){
                relatedAssetSN.add(sn);
            }
            system.debug('selectedNodeList =='+selectedNodeList+'==size=='+selectedNodeList.size());
            for(Node__c nodeSN : [select id,Serial_Number__c,Asset__c,Asset__r.Serial_Number__c from Node__c where Serial_Number__c IN: selectedNodeList]){
                relatedAssetSN.add(nodeSN.Asset__r.Serial_Number__c);
            }
            system.debug('relatedAssetSN =='+relatedAssetSN+'==size=='+relatedAssetSN.size());
            
            RMAOrder.Valid_Support__c = false;
            RMAOrder.Send_Smart_Hands_Service__c = smartHandRequested;
            RMAOrder.Entitled_for_Smart_Hands_Service__c = smartHandQualified;
            
            if(RMAOrder.Send_Smart_Hands_Service__c == false) {
                RMAOrder.Date_of_Smart_Hands_Arrival__c = null;
                RMAOrder.Time_of_Smart_Hands_Tech_Arrival__c = null;
            }
            isValidSupport = false;
            for(Asset asstRecord : [select id,serial_Number__c,ParentId,Product2.category__C, (select id, Status,Product__r.productCode,Product__r.category__C from Entitlements where Product__r.Category__C='Support' OR Product__r.Category__C='Hardware' OR Product__r.License_Subtype__c ='ELA' OR Product__r.License_Type__c ='Consumption' OR Product__r.ProductCode like '%PRO%' OR  Product__r.ProductCode like '%HYB%' OR Product__r.ProductCode like '%SUB%' OR  Product__r.ProductCode like '%PROMO%') from Asset where serial_Number__c IN:relatedAssetSN]){
                selectedAssetMap.put(asstRecord.Id,asstRecord);
                system.debug('test=='+asstRecord.Entitlements);
                system.debug('asstRecord.Entitlements =='+asstRecord.Entitlements);
                if(asstRecord.ParentId != NULL){   
                    ParentAssetToQuery.add(asstRecord.ParentId);
                }
                else{
                    for(Entitlement entl : asstRecord.Entitlements){
                        if(entl.Status != null && entl.status == 'Active'){
                            RMAOrder.Valid_Support__c = true;
                            isValidSupport = true;
                        }
                        if(entl.Product__r.productCode.contains('-NRD-')){
                            RMAOrder.NRD_Policy__c = true;
                        }
                    }
                }
                if(asstRecord.Entitlements.size()<=0){
                    RMAOrder.Valid_Support__c = false;
                    isValidSupport = false;
                }
                system.debug(' in if  isValidSupport =='+isValidSupport);
            }
            if(ParentAssetToQuery.size() >0 ){
                for(Asset parentasstRecord : [select id,serial_Number__c,ParentId,Product2.category__C, (select id, Status,Product__r.productCode,Product__r.category__C from Entitlements where Product__r.Category__C='Support' OR Product__r.Category__C='Hardware' OR Product__r.License_Subtype__c ='ELA' OR Product__r.License_Type__c ='Consumption' OR Product__r.ProductCode like '%PRO%' OR  Product__r.ProductCode like '%HYB%' OR Product__r.ProductCode like '%SUB%' OR  Product__r.ProductCode like '%PROMO%') from Asset where Id IN:ParentAssetToQuery]){
                    ParentSerialNumber.put(parentasstRecord.id,parentasstRecord.serial_Number__c);
                    for(Entitlement parententl : parentasstRecord.Entitlements){
                        if(parententl.Status != null && parententl.status == 'Active'){
                            RMAOrder.Valid_Support__c = true;
                            isValidSupport = true;
                        }        
                        if(parententl.Product__r.productCode.contains('-NRD-')){
                            RMAOrder.NRD_Policy__c = true;
                         }
                    }
                    if(parentasstRecord.Entitlements.size()<=0){
                         RMAOrder.Valid_Support__c = false;
                         isValidSupport = false;
                    }
               }
            }
            
            if(SelectedDriveList.size()>0){
                for(Asset asstRecord : [select id,serial_Number__c,Product2.category__C, (select id, Status,Product__r.productCode,Product__r.category__C from Entitlements where Product__r.Category__C='Non-Returnable Disk Service') from Asset where serial_Number__c IN:relatedAssetSN]){
                    system.debug('test=='+asstRecord.Entitlements);
                    system.debug('asstRecord.Entitlements =='+asstRecord.Entitlements);
                    for(Entitlement entl : asstRecord.Entitlements){
                        if(entl.Product__r.productCode.contains('-NRD-')){
                            RMAOrder.NRD_Policy__c = true;
                        }
                    }
                    system.debug(' in if  isValidSupport =='+isValidSupport);
                }
            }
            if(relatedAssetSN.isEmpty()){
                RMAOrder.Valid_Support__c = false;
                isValidSupport = false;
            }
            else{
                // Logic to update Asset on RMA Form
                system.debug('relatedAssetSN =='+relatedAssetSN);
                string assets ='';
                if(!selectedAssetMap.isEmpty()){
                    for(Asset AllSelectedAsset : selectedAssetMap.values()){
                        if(AllSelectedAsset.ParentId != NULL && ParentSerialNumber.containsKey(AllSelectedAsset.ParentId)){
                        assets +=ParentSerialNumber.get(AllSelectedAsset.ParentId) +',';    
                        }
                        else{
                        assets +=AllSelectedAsset.serial_Number__c +',';
                        }
                    }
                }
                if(assets.contains(',')){
                    assets = assets.removeEnd(',');
                }
                if(String.isNotBlank(assets)){
                    allAppliances= New set<String>(assets.split(','));
                }
                system.debug('assets =='+assets);
                RMAOrder.Appliance__c = assets;
                RMAOrder.Assets__c = assets;
            }
            
            if(RMAOrder.Valid_Support__c == false){
                RMAOrder.Status__c ='Submitted';
                isValidSupport = false;
            }
            else{
                RMAOrder.Status__c ='Submitted';
                isValidSupport = true;
            }
            
            
            
            PageReference pageRef;
            RMA_Order__c newRMA;
            system.debug('isValidSupport =='+isValidSupport);
            system.debug('isValidSupport =='+smartHandRequested);
            system.debug('isValidSupport =='+smartHandQualified);
            system.debug('RMAOrder.Send_Smart_Hands_Service__c =='+RMAOrder.Send_Smart_Hands_Service__c);
            system.debug('String.isBlank(RMAOrder.Comment_if_any__c) =='+String.isBlank(RMAOrder.Comment_if_any__c));
            system.debug('smart hand 1 =='+(smartHandRequested ==true && smartHandQualified ==false && (!String.isBlank(RMAOrder.Comment_if_any__c))));
            system.debug('smart hand 2 =='+(smartHandRequested ==true && smartHandQualified ==true));
            system.debug('smart hand 3 =='+((smartHandRequested ==true && smartHandQualified ==false && (!String.isBlank(RMAOrder.Comment_if_any__c)))|| (smartHandRequested ==true && smartHandQualified ==true)));
            
            if((isValidSupport && smartHandRequested ==false) || (!isValidSupport && !String.isBlank(RMAOrder.Comment_if_any__c) ) ||
                 ( isValidSupport && (smartHandRequested ==true && smartHandQualified ==false && (!String.isBlank(RMAOrder.Comment_if_any__c)))||
                 (isValidSupport && smartHandRequested ==true && smartHandQualified ==true))){
                system.debug('RMAOrder.Valid_Support__c=='+RMAOrder.Valid_Support__c);
                system.debug('isValidSupport =='+isValidSupport);
                system.debug('RMAOrder =='+RMAOrder);
                insert RMAOrder;
                
                newRMA =[SELECT Id, Name, Parent_Case__c,Parent_Case__r.Id, Status__c, Drive__c, Node__c, Memory__c,Memory_Quantity__c,Chassis__C, Power_Supply__c, NIC__c,SSD__c, Type__c, Shipping_Street__c, Shipping_City__c, ShippingState__c, Shipping_Zip_Postal_Code__c, ShippingCountry__c, CopyAdrressfromAccount__c, Node_Quantity__c, SSD_Quantity__c,Drive_Quantity__c, Chasis_Quantity__c, Power_Supply_Quantity__c, NIC_Quantity__c, Appliance_Quantity__c, Cluster_ID__c, Appliance__c FROM RMA_Order__c where id=:RMAOrder.ID];
                rmaOrderID = newRMA.Id;
                /* Create Failure Records */
               /* if(SelectedNodeList.size()> 0 && RMAOrder.Node_Quantity__c >0){
                    createAssetFailure(allAppliances, SelectedNodeList, 'Node__C');
                }
                if(SelectedDriveList.size()> 0 && RMAOrder.Drive_Quantity__c > 0){
                    createAssetFailure(allAppliances, SelectedDriveList, 'Drive__c');
                }
                if(newRMA.Drive__c=='Other'){
                    List<string> drivenodeSrNumbers = New List<String>();
                     if(!String.isBlank(newRMA.Node__c)){
                                if(newRMA.Node__c.contains(',')){
                                    drivenodeSrNumbers = newRMA.Node__c.split(',');
                                }
                                else{
                                    drivenodeSrNumbers.add(newRMA.Node__c);
                                }
                    }
                    
                    createOtherFailure(allAppliances,drivenodeSrNumbers,'Drive');
                }
                
                if(SelectedSSDDriveList.size()> 0 && RMAOrder.SSD_Quantity__c > 0){
                    createAssetFailure(allAppliances, SelectedSSDDriveList, 'Drive__c');
                }
                if(newRMA.SSD__c=='Other'){
                    List<string> ssdNodeSrNumbers = New List<String>();
                     if(!String.isBlank(newRMA.Node__c)){
                                if(newRMA.Node__c.contains(',')){
                                    ssdNodeSrNumbers = newRMA.Node__c.split(',');
                                }
                                else{
                                    ssdNodeSrNumbers.add(newRMA.Node__c);
                                }
                    }
                    
                    createOtherFailure(allAppliances,ssdNodeSrNumbers,'SSD');
                }
                if(selectedMemoryList.size()> 0 && RMAOrder.Memory_Quantity__c >0){
                    createAssetFailure(allAppliances, selectedMemoryList, 'Memory__c');
                }
                if(newRMA.Memory__c=='Other'){
                    List<string> memnodeSrNumbers = New List<String>();
                     if(!String.isBlank(newRMA.Node__c)){
                                if(newRMA.Node__c.contains(',')){
                                    memnodeSrNumbers = newRMA.Node__c.split(',');
                                }
                                else{
                                    memnodeSrNumbers.add(newRMA.Node__c);
                                }
                    }
                    
                    createOtherFailure(allAppliances,memnodeSrNumbers,'Memory');
                }
                
                if(selectedChassisList.size()> 0 && RMAOrder.Chasis_Quantity__c > 0){
                    createAssetFailure(allAppliances, selectedChassisList, 'Chassis__C');
                }
                if(newRMA.Chassis__C=='Other'){
                    List<string> chassisAssetSrNumbers = New List<String>();
                    if(!String.isBlank(newRMA.Appliance__c)){
                        if(newRMA.Appliance__c.contains(',')){
                            chassisAssetSrNumbers = newRMA.Appliance__c.split(',');
                        }
                        else{
                            chassisAssetSrNumbers.add(newRMA.Appliance__c);
                        }

                    }
                    
                    createOtherFailure(allAppliances,chassisAssetSrNumbers,'Chassis');
                }

                if(SelectedPowersupplyList.size()> 0 && RMAOrder.Power_Supply_Quantity__c >0){
                    createAssetFailure(allAppliances, SelectedPowersupplyList, 'Power_Supply__c');
                }
                 if(newRMA.Power_Supply__c=='Other'){
                    List<string> PsuAssetSrNumbers = New List<String>();
                    if(!String.isBlank(newRMA.Appliance__c)){
                        if(newRMA.Appliance__c.contains(',')){
                            PsuAssetSrNumbers = newRMA.Appliance__c.split(',');
                        }
                        else{
                            PsuAssetSrNumbers.add(newRMA.Appliance__c);
                        }

                    }
                    
                    createOtherFailure(allAppliances,PsuAssetSrNumbers,'PSU');
                }
                if(selectedCMOSBatteryList.size()> 0 && RMAOrder.CMOS_Battery_Quantity__c >0){
                    createAssetFailure(allAppliances, selectedCMOSBatteryList, 'CMOS_Battery__c');
                }
                if(selectedApplianceList.size()> 0 && RMAOrder.Appliance_Quantity__c >0){
                    createAssetFailure(allAppliances, selectedApplianceList, 'Asset');
                }
                
                pageRef = new PageReference('/apex/RMA_Order_Form?id='+newRMA.Parent_Case__r.Id);
                
                pageRef.getParameters().put('RMAId', newRMA.Id);
                pageRef.getParameters().put('RMAName', newRMA.Name);
                pageRef.getParameters().put('msg','success');
                pageRef.setredirect(true);
            }
            else{
                system.debug('in else');
                pageRef = new PageReference('/apex/RMA_Order_Form?id='+caseRecord.ID);
                pageRef.getParameters().put('msg','pending');
                //pageref =null;
            }
            system.debug('isValidSupport =='+isValidSupport);
            return pageRef;
        }
        catch(Exception ex){
            system.Debug('Exception Occured in Method== saveRMA == class== RMAOrderHandlerExtnClass'+ex);
            return null;
        }
        
    }
    Public void createAssetFailure(Set<String> assetSerialNumber, List<String> compSerialNumber, string Type){
        String serialNumber =new List<String> ( assetSerialNumber )[0];
        ID relatedAssetId = [select id , serial_number__c from Asset where SerialNumber=:serialNumber].id;
        System.debug('rmaOrderID==='+rmaOrderID);
        List<Failure__c> listFailure = new List<Failure__c>();

        if(type != 'CMOS_Battery__c') {
            String idInClause = '(\'';
            for (String sr : compSerialNumber){
                idInClause += String.escapeSingleQuotes(sr) + '\',\'';
            }
            idInClause  = idInClause.substring(0,idInClause.length()-2);
            idInClause += ')';
            system.debug('compSerialNumber==='+idInClause);
            system.debug('mapFailureReasonsSelection==='+mapFailureReasonsSelection);
            String queryStr ='select id, serial_number__c,name from ' + String.escapeSingleQuotes(type) + ' where serial_number__c in ' + idInClause;
            List<sobject> records= Database.query(queryStr);
            
            if(type == 'Node__c'){
                for(sobject node : records){
                    Failure__c failure = new Failure__c(Asset__c = relatedAssetId !=null? relatedAssetId:null, Date_of_Failure__c =system.today());
                    failure.node__c = node.id;
                    failure.Component_Type__c ='Node';
                    String sNumber = (string)node.get('serial_number__c');
                    if(!Test.isRunningTest()){
                    failure.Failure_Reason__c = mapFailureReasonsSelection.get(sNumber);
                    failure.Failure_Reason_Other__c = mapFailureOtherReasonsSelection.get(sNumber);
                    }
                  
                    failure.RMA_Request__c = rmaOrderID;
                    failure.serial_Number_Reported__c = sNumber;
                    failure.Product_Code__C = getProductCode(sNumber, 'Node');
                    system.debug('failure inserted --'+failure);
                    listFailure.add(failure) ;
                }
            }
            if(type == 'Memory__c'){
                for(sobject mem : records){
                    Failure__c failure = new Failure__c(Asset__c = relatedAssetId !=null? relatedAssetId:null, Date_of_Failure__c =system.today());
                    failure.Memory__c = mem.id;
                    failure.Component_Type__c ='Memory';
                    String sNumber = (string)mem.get('serial_number__c');
                    if(!Test.isRunningTest()){
                    failure.Failure_Reason__c = mapFailureReasonsSelection.get(sNumber);
                    failure.Failure_Reason_Other__c = mapFailureOtherReasonsSelection.get(sNumber);
                    }
                    failure.RMA_Request__c = rmaOrderID;
                    failure.Product_Code__C = getProductCode(sNumber, 'Memory');
                    system.debug('failure inserted --'+failure);
                    listFailure.add(failure) ;
                }
            }
            if(type == 'Drive__c'){
                for(sobject drive : records){
                    Failure__c failure = new Failure__c(Asset__c = relatedAssetId !=null? relatedAssetId:null, Date_of_Failure__c =system.today());
                    failure.Drive__c = Drive.id;
                    failure.Component_Type__c ='Drive';
                    String sNumber = (string)drive.get('serial_number__c');
                    if(!Test.isRunningTest()){
                    failure.Failure_Reason__c = mapFailureReasonsSelection.get(sNumber);
                    failure.Failure_Reason_Other__c = mapFailureOtherReasonsSelection.get(sNumber);
                    }
                    failure.RMA_Request__c = rmaOrderID;
                    failure.Product_Code__C = getProductCode(sNumber, 'Drive');
                    system.debug('failure inserted --'+failure);
                    listFailure.add(failure) ;
                }
            }
            if(type == 'SSD__c'){
                for(sobject drive : records){
                    Failure__c failure = new Failure__c(Asset__c = relatedAssetId !=null? relatedAssetId:null, Date_of_Failure__c =system.today());
                    failure.Drive__c = Drive.id;
                    failure.Component_Type__c ='Drive';
                    String sNumber = (string)drive.get('serial_number__c');
                    if(!Test.isRunningTest()){
                    failure.Failure_Reason__c = mapFailureReasonsSelection.get(sNumber);
                    failure.Failure_Reason_Other__c = mapFailureOtherReasonsSelection.get(sNumber);
                    }
                    failure.RMA_Request__c = rmaOrderID;
                    failure.Product_Code__C = getProductCode(sNumber, 'SSD');
                    system.debug('failure inserted --'+failure);
                    listFailure.add(failure) ;
                }
            }
            if(type == 'Power_supply__c'){
                for(sobject psupply : records){
                    Failure__c failure = new Failure__c(Asset__c = relatedAssetId !=null? relatedAssetId:null, Date_of_Failure__c =system.today());
                    failure.Power_supply__c = psupply.id;
                    failure.Component_Type__c ='Power Supply';
                    String sNumber = (string)psupply.get('serial_number__c');
                    if(!Test.isRunningTest()){
                    failure.Failure_Reason__c = mapFailureReasonsSelection.get(sNumber);
                    failure.Failure_Reason_Other__c = mapFailureOtherReasonsSelection.get(sNumber);
                    }
                    failure.RMA_Request__c = rmaOrderID;
                    failure.Product_Code__C = getProductCode(sNumber, 'Power Supply');
                    system.debug('failure inserted --'+failure);
                    listFailure.add(failure) ;
                }
            }
            if(type == 'Chassis__c'){
                for(sobject chassis : records){
                    Failure__c failure = new Failure__c(Asset__c = relatedAssetId !=null? relatedAssetId:null, Date_of_Failure__c =system.today());
                    failure.Chassis__c = Chassis.id;
                    failure.Component_Type__c ='Chassis';
                    String sNumber = (string)chassis.get('serial_number__c');
                    if(!Test.isRunningTest()){
                    failure.Failure_Reason__c = mapFailureReasonsSelection.get(sNumber);
                    failure.Failure_Reason_Other__c = mapFailureOtherReasonsSelection.get(sNumber);
                    }
                    failure.RMA_Request__c = rmaOrderID;
                    failure.Product_Code__C = getProductCode(sNumber, 'Chassis');
                    system.debug('failure inserted --'+failure);
                    listFailure.add(failure) ;
                }
            }
            if(type == 'Asset'){
                for(sobject asset : records){
                    Failure__c failure = new Failure__c(Asset__c = relatedAssetId !=null? relatedAssetId:null, Date_of_Failure__c =system.today());
                    failure.Component_Type__c ='Appliance';
                    String sNumber = (string)asset.get('serial_number__c');
                    if(!Test.isRunningTest()){
                    failure.Failure_Reason__c = mapFailureReasonsSelection.get(sNumber);
                    failure.Failure_Reason_Other__c = mapFailureOtherReasonsSelection.get(sNumber);
                    }
                    failure.RMA_Request__c = rmaOrderID;
                    failure.Product_Code__C = getProductCode(sNumber, 'Asset');
                    system.debug('failure inserted --'+failure);
                    listFailure.add(failure) ;
                }
            }
        }
        else if(type =='CMOS_Battery__c') {
            if(type == 'CMOS_Battery__c'){
                for(Integer i=0; i< RMAOrder.CMOS_Battery_Quantity__c; i++){
                    Failure__c failure = new Failure__c(Asset__c = relatedAssetId !=null? relatedAssetId:null, Date_of_Failure__c =system.today());
                    failure.Component_Type__c ='CMOS Battery';
                    String sNumber = 'CMOS Battery';
                    failure.Failure_Reason__c = 'Other';
                    failure.Failure_Reason_Other__c = 'Other';
                    failure.RMA_Request__c = rmaOrderID;
                    failure.Product_Code__C = Label.CMOS_Battery_Product;
                    system.debug('failure inserted --'+failure);
                    listFailure.add(failure) ;
                }
            }
        }

        if(!listFailure.isEmpty()){
            system.debug('listFailure ==='+listFailure);
            insert listFailure;
        }
    }
    
    public string getProductCode(String CompSNumber, string compType){
        
        if(compType == 'Power Supply'){
             Power_Supply__c dr;
             if(!Test.isRunningTest()){
             dr = [select id,Serial_Number__c,Asset__r.Product2.ProductCode,Asset__r.Product2.Id,Asset__r.Product2.Family,Asset__r.Product2.Product_NIC_Type__c,Asset__r.Product2.Appliance_Model__c from Power_Supply__c where Serial_Number__c =: CompSNumber Limit 1];
             }
            else{
             dr = [select id,Serial_Number__c,Asset__r.Product2.ProductCode,Asset__r.Product2.Id,Asset__r.Product2.Family,Asset__r.Product2.Product_NIC_Type__c,Asset__r.Product2.Appliance_Model__c from Power_Supply__c Limit 1];
             }
             
            String relatedProdFamily = dr.Asset__r.Product2.Family != null? dr.Asset__r.Product2.Family : '';
            relatedProdFamily=relatedProdFamily.toUppercase();
            String  relatedNicType = dr.Asset__r.Product2.Product_NIC_Type__c != null ? dr.Asset__r.Product2.Product_NIC_Type__c : '';
            String  relatedApplianceModel = dr.Asset__r.Product2.Appliance_Model__c != null ?dr.Asset__r.Product2.Appliance_Model__c:'';
            
            String  relatedProdCode = dr.Asset__r.Product2.ProductCode;
           /* <--START--> SF-91  Added Logic for new Mapping Helper method*/
          /*  Spares_Mapping__c mapping = RMASparePartsMappingHelper.returnSparePartCode(relatedProdFamily, relatedNicType,  relatedApplianceModel); 
            if(mapping != null){
                return mapping.PSU__c;
            }
            else
                return null;
            /* < END ---- SF-91> */
       /* }
        else if(compType == 'Drive' || compType == 'SSD'){
             Drive__C dr;
             if(!Test.isRunningTest()){
             dr = [select id,Serial_Number__c,node__r.Asset__r.Product2.ProductCode,node__r.Asset__r.Product2.Id,node__r.Asset__r.Product2.Family ,node__r.Asset__r.Product2.Product_NIC_Type__c,node__r.Asset__r.Product2.Appliance_Model__c, Type__c from Drive__c where Serial_Number__c =:compSNumber];
             }
            else{
             dr =  [select id,Serial_Number__c,node__r.Asset__r.Product2.ProductCode,node__r.Asset__r.Product2.Id,node__r.Asset__r.Product2.Family ,node__r.Asset__r.Product2.Product_NIC_Type__c,node__r.Asset__r.Product2.Appliance_Model__c, Type__c from Drive__c LIMIT 1];
             }
            String relatedProdFamily = dr.node__r.Asset__r.Product2.Family != null? dr.node__r.Asset__r.Product2.Family : '';
            relatedProdFamily=relatedProdFamily.toUppercase();
            String  relatedNicType = dr.node__r.Asset__r.Product2.Product_NIC_Type__c != null ? dr.node__r.Asset__r.Product2.Product_NIC_Type__c : '';
            String  relatedApplianceModel = dr.node__r.Asset__r.Product2.Appliance_Model__c != null ?dr.node__r.Asset__r.Product2.Appliance_Model__c:'';
            String relatedProdCode = dr.node__r.Asset__r.Product2.ProductCode;
            /* <--START--> SF-91  Added Logic for new Mapping Helper method*/
          /*  Spares_Mapping__c mapping = RMASparePartsMappingHelper.returnSparePartCode(relatedProdFamily, relatedNicType,  relatedApplianceModel); 
            if(mapping != null && compType == 'Drive'){
                return mapping.HDD__c;
            }
            else if(mapping != null && compType == 'SSD'){
                return mapping.SSD__c;
            }
            else
                return null;
            /* < END ---- SF-91> */
      /*  }
        else if(compType == 'Memory'){
             Memory__c dr;
             if(!Test.isRunningTest()){
             dr = [select id,Serial_Number__c,node__r.Asset__r.Product2.ProductCode,node__r.Asset__r.Product2.Id,node__r.Asset__r.Product2.Family,node__r.Asset__r.Product2.Product_NIC_Type__c,node__r.Asset__r.Product2.Appliance_Model__c from Memory__c where Serial_Number__c =:compSnumber];
             }
            else{
             dr =[select id,Serial_Number__c,node__r.Asset__r.Product2.ProductCode,node__r.Asset__r.Product2.Id,node__r.Asset__r.Product2.Family,node__r.Asset__r.Product2.Product_NIC_Type__c,node__r.Asset__r.Product2.Appliance_Model__c from Memory__c LIMIT 1];
             }
            String relatedProdFamily = dr.node__r.Asset__r.Product2.Family != null? dr.node__r.Asset__r.Product2.Family : '';
            relatedProdFamily=relatedProdFamily.toUppercase();
            String  relatedNicType = dr.node__r.Asset__r.Product2.Product_NIC_Type__c != null ? dr.node__r.Asset__r.Product2.Product_NIC_Type__c : '';
            String  relatedApplianceModel = dr.node__r.Asset__r.Product2.Appliance_Model__c != null ?dr.node__r.Asset__r.Product2.Appliance_Model__c:'';
            
            String relatedProdCode = dr.node__r.Asset__r.Product2.ProductCode;
            /* <--START--> SF-91  Added Logic for new Mapping Helper method*/
           /* Spares_Mapping__c mapping = RMASparePartsMappingHelper.returnSparePartCode(relatedProdFamily, relatedNicType,  relatedApplianceModel); 
            if(mapping != null){
                return mapping.Memory__c;
            }
            else
                return null;
            /* < END ---- SF-91> */
            
        /*}
        else if(compType == 'Chassis'){
             Chassis__c dr;
             if(!Test.isRunningTest()){
             dr =[select id,Serial_Number__c,Asset__r.Product2.ProductCode,Asset__r.Product2.Id,Asset__r.Product2.Family,Asset__r.Product2.Product_NIC_Type__c,Asset__r.Product2.Appliance_Model__c from Chassis__c where Serial_Number__c =:compSNumber];
                }
            else{
             dr =[select id,Serial_Number__c,Asset__r.Product2.ProductCode,Asset__r.Product2.Id,Asset__r.Product2.Family,Asset__r.Product2.Product_NIC_Type__c,Asset__r.Product2.Appliance_Model__c from Chassis__c LIMIT 1];
             } 
            String relatedProdFamily = dr.Asset__r.Product2.Family != null? dr.Asset__r.Product2.Family : '';
            relatedProdFamily=relatedProdFamily.toUppercase();
            String  relatedNicType = dr.Asset__r.Product2.Product_NIC_Type__c != null ? dr.Asset__r.Product2.Product_NIC_Type__c : '';
            String  relatedApplianceModel = dr.Asset__r.Product2.Appliance_Model__c != null ?dr.Asset__r.Product2.Appliance_Model__c:'';
            
            String  relatedProdCode = dr.Asset__r.Product2.ProductCode;
            /* <--START--> SF-91  Added Logic for new Mapping Helper method*/
          /*  Spares_Mapping__c mapping = RMASparePartsMappingHelper.returnSparePartCode(relatedProdFamily, relatedNicType,  relatedApplianceModel); 
            if(mapping != null){
                return mapping.Chassis__c;
            }
            else
                return null;
            /* < END ---- SF-91> */
        /*}
        else if(compType == 'Node'){
            Node__c dr;
             if(!Test.isRunningTest()){
             dr =[select id,Serial_Number__c,Asset__r.Product2.ProductCode,Asset__r.Product2.Id,Asset__r.Product2.Family ,Asset__r.Product2.Product_NIC_Type__c,Asset__r.Product2.Appliance_Model__c from Node__c where Serial_Number__c =:compSNumber];
            }
            else{
             dr =[select id,Serial_Number__c,Asset__r.Product2.ProductCode,Asset__r.Product2.Id,Asset__r.Product2.Family ,Asset__r.Product2.Product_NIC_Type__c,Asset__r.Product2.Appliance_Model__c from Node__c LIMIT 1];
             }
            String relatedProdFamily = dr.Asset__r.Product2.Family != null? dr.Asset__r.Product2.Family : '';
            relatedProdFamily=relatedProdFamily.toUppercase();
            String  relatedNicType = dr.Asset__r.Product2.Product_NIC_Type__c != null ? dr.Asset__r.Product2.Product_NIC_Type__c : '';
            String  relatedApplianceModel = dr.Asset__r.Product2.Appliance_Model__c != null ?dr.Asset__r.Product2.Appliance_Model__c:'';
            
            String  relatedProdCode = dr.Asset__r.Product2.ProductCode;
            /* <--START--> SF-91  Added Logic for new Mapping Helper method*/
          /*  Spares_Mapping__c mapping = RMASparePartsMappingHelper.returnSparePartCode(relatedProdFamily, relatedNicType,  relatedApplianceModel); 
            if(mapping != null){
                return mapping.Node__c;
            }
            else
                return null;
            /* < END ---- SF-91> */
     /*   }
        else if(compType == 'Asset'){
            Asset dr =[select id,Serial_Number__c,Product2.ProductCode from Asset where Serial_Number__c =:compSNumber];
            return dr.Product2.ProductCode;
        }
        return null;
    }
    //Added for PRDOPS21-278
    Public void createOtherFailure(Set<String> assetSerialNumber, List<String> NodeSerialno, string Type){
        String serialNumber =new List<String> ( assetSerialNumber )[0];
        String NodeserialNumber =new List<String> (NodeSerialno)[0];
        ID relatedAssetId = [select id , serial_number__c from Asset where SerialNumber=:serialNumber].id;
       
        List<Failure__c> listOtherFailure = new List<Failure__c>();
       
                Failure__c failure = new Failure__c(Asset__c = relatedAssetId !=null? relatedAssetId:null, Date_of_Failure__c =system.today());
                failure.Failure_Reason__c = 'Other';
                failure.Failure_Reason_Other__c = 'Other';
                failure.RMA_Request__c = rmaOrderID;
                // failure.serial_Number_Reported__c = 'Other';
                if(type == 'Memory'){
                    failure.Product_Code__C = getOtherProductCode(NodeserialNumber, 'Memory');
                    system.debug('failure inserted --'+failure);
                    failure.Component_Type__c ='Memory';
                }
                if(type == 'Drive'){
                    failure.Component_Type__c ='Drive';
                    failure.Product_Code__C = getOtherProductCode(NodeserialNumber, 'Drive');
                 }
                 if(type == 'SSD'){
                     failure.Component_Type__c ='Drive';
                     failure.Product_Code__C = getOtherProductCode(NodeserialNumber, 'SSD');
                  }
                  if(type == 'Chassis'){
                    failure.Component_Type__c ='Chassis';
                    failure.Product_Code__C = getOtherProductCode(NodeserialNumber, 'Chassis');
                 }
                 if(type == 'PSU'){
                    failure.Component_Type__c ='Power Supply';
                    failure.Product_Code__C = getOtherProductCode(NodeserialNumber, 'PSU');
                 }
                
                listOtherFailure.add(failure) ;
           
           
        if(!listOtherFailure.isEmpty()){
         insert listOtherFailure;
        }
    }
    public string getOtherProductCode(string NodeNumber,string Type)
    {
         Node__c nodeData;
        String relatedProdFamily;
        String  relatedNicType;
        String  relatedApplianceModel;
        String  relatedProdCode;

        if(Type == 'Memory' || Type == 'Drive' ||Type == 'SSD' ){ 
        Set<ID> assetParentID = New set<Id>();
        if(!Test.isRunningTest()){
         nodeData=  [select Id,Serial_Number__c,asset__r.ParentId,Asset__r.Product2.ProductCode,Asset__r.Product2.Id,Asset__r.Product2.Family,Asset__r.Product2.Product_NIC_Type__c,Asset__r.Product2.Appliance_Model__c, cpu_model__c from Node__c where Serial_Number__c =: NodeNumber];
         }
        else{
         nodeData=  [select Id,Serial_Number__c,asset__r.ParentId,Asset__r.Product2.ProductCode,Asset__r.Product2.Id,Asset__r.Product2.Family,Asset__r.Product2.Product_NIC_Type__c,Asset__r.Product2.Appliance_Model__c, cpu_model__c from Node__c LIMIT 1];
         }
        
        if(nodeData.asset__r.ParentId !=Null){
           Asset parentAssetData = [select Id,Serial_Number__c,ParentId,Product2.ProductCode,Product2.Id,Product2.Family,Product2.Product_NIC_Type__c,Product2.Appliance_Model__c from Asset where id =: nodeData.asset__r.ParentId];
           relatedProdFamily=parentAssetData .Product2.Family;
           relatedProdFamily=relatedProdFamily.toUppercase();
           relatedNicType = parentAssetData.Product2.Product_NIC_Type__c != null ? parentAssetData.Product2.Product_NIC_Type__c : '';
           relatedApplianceModel = parentAssetData.Product2.Appliance_Model__c != null ?parentAssetData.Product2.Appliance_Model__c:'';
           relatedProdCode =parentAssetData.Product2.ProductCode;
        }
        else{
        relatedProdFamily=nodeData.Asset__r.Product2.Family;
        relatedProdFamily=relatedProdFamily.toUppercase();
        relatedNicType = nodeData.Asset__r.Product2.Product_NIC_Type__c != null ? nodeData.Asset__r.Product2.Product_NIC_Type__c : '';
        relatedApplianceModel = nodeData.Asset__r.Product2.Appliance_Model__c != null ?nodeData.Asset__r.Product2.Appliance_Model__c:'';
        relatedProdCode =nodeData.Asset__r.Product2.ProductCode;
        }
        Spares_Mapping__c mapping = RMASparePartsMappingHelper.returnSparePartCode(relatedProdFamily, relatedNicType,  relatedApplianceModel); 
        if(mapping != null){
            if(Type =='Memory'){
                return mapping.Memory__c;
            }
            else if(Type == 'Drive' || Type == 'SSD'){
                if(Type == 'Drive'){
                    return mapping.HDD__c;
                }
                else if(Type == 'SSD'){
                    return mapping.SSD__c;
                }
                else{
                    return null;
                }
            }
        }
    }
        if(Type == 'PSU' || Type == 'Chassis'){
                Asset assetData;
                 if(!Test.isRunningTest()){
                 assetData=[select id,serial_number__c,Product2.Id,product2.Family,product2.Product_NIC_Type__c, product2.Appliance_Model__c,product2.ProductCode from Asset where  Serial_Number__c =: NodeNumber];
                }
                else{
                assetData=[select id,serial_number__c,Product2.Id,product2.Family,product2.Product_NIC_Type__c, product2.Appliance_Model__c,product2.ProductCode from Asset limit 1];
                 }
                relatedProdFamily=assetData.Product2.Family;
                relatedProdFamily=relatedProdFamily.toUppercase();
                relatedNicType = assetData.Product2.Product_NIC_Type__c != null ? assetData.Product2.Product_NIC_Type__c : '';
                relatedApplianceModel = assetData.Product2.Appliance_Model__c != null ?assetData.Product2.Appliance_Model__c:'';
                relatedProdCode =assetData.Product2.ProductCode;
                Spares_Mapping__c Spmapping = RMASparePartsMappingHelper.returnSparePartCode(relatedProdFamily, relatedNicType,  relatedApplianceModel); 
                if(Spmapping != null){
                    if(Type =='chassis'){
                        return Spmapping.Chassis__c;
                    }
                    else if(Type == 'PSU'){
                        return Spmapping.PSU__c;
                    }
                }
            }
        return null;
    }
        
    
    
    public List<SelectOption> getClusterOptions1(){
        List<SelectOption> retVal = new List<SelectOption>();
        retVal.add(new SelectOption('--None--','--None--'));
        
        for(integer i = 0; i<999;++i){
            if(accList[0].clusters__r[i] != null){
                cluster__c cluster = accList[0].clusters__r[i];
                retVal.add(new SelectOption(cluster.Id,cluster.Name));
            }
        }
        return retVal;
    }
    public List<SelectOption> getClusterOptions2(){
        List<SelectOption> retVal = new List<SelectOption>();
        for(integer i = 999; i<1999;++i){
            if(accList[0].clusters__r[i] != null){
                cluster__c cluster = accList[0].clusters__r[i];
                retVal.add(new SelectOption(cluster.Id,cluster.Name));
            }
        }
        return retVal;
    }
    public List<SelectOption> getClusterOptions3(){
        List<SelectOption> retVal = new List<SelectOption>();
        for(integer i = 1999; i<2999;++i){
            if(accList[0].clusters__r[i] != null){
                cluster__c cluster = accList[0].clusters__r[i];
                retVal.add(new SelectOption(cluster.Id,cluster.Name));
            }
        } 
        return retVal;
    }
    public List<SelectOption> getClusterOptions4(){
        List<SelectOption> retVal = new List<SelectOption>();
        for(integer i = 2999; i<3999;++i){
            if(accList[0].clusters__r[i] != null){
                cluster__c cluster = accList[0].clusters__r[i];
                retVal.add(new SelectOption(cluster.Id,cluster.Name));
            }
        } 
        return retVal;
    }
    public List<SelectOption> getClusterOptionOther(){
        List<SelectOption> retVal = new List<SelectOption>();
        retVal.add(new SelectOption('Other','Other'));
        return retVal;
    }
    
    public  void CompareCountries()
    { 
    
    
    flag='';
      smartHandRequested = false;
      string selectedcountrystr;
      RMAOrder.Send_Smart_Hands_Service__c = smartHandRequested;
     if(RMAOrder.Send_Smart_Hands_Service__c == false) {
                RMAOrder.Date_of_Smart_Hands_Arrival__c = null;
                RMAOrder.Time_of_Smart_Hands_Tech_Arrival__c = null;
            }
     if(!Test.isRunningTest()){
     selectedcountrystr = Apexpages.currentPage().getParameters().get('selectedcountry');
     }
    else{
     selectedcountrystr ='India';
    }
     
     List<CountryWithTimezone__c> CountryAndTimezone = CountryWithTimezone__c.getall().values();
     //List<String> countries = System.Label.countryValue.split(',');
     string ShippingcountryTZ;
        if(CountryAndTimezone.size()>0){
            for(CountryWithTimezone__c ct :CountryAndTimezone){
                if(selectedcountrystr.equals(ct.name)){
                    flag='true'; 
                    ShippingcountryTZ=ct.Timezone__c.trim();
                    dateTime todaysDate = system.now();
                    system.debug('todaysDate'+todaysDate);
                    timezoneDate=todaysDate.format('yyyy-MM-dd',ShippingcountryTZ);
                    system.debug('timezoneDate'+timezoneDate);
                    break;
                    }
                     else
                    {
                            flag='false'; 
                    }
                 }
             }
    
    for(String chasis : selectedChassisList) {
        if(assetWithSmartHandEntitlementBool.containsKey(chasis)) {
            smartHandQualified = true;           
            return;
        }
        
    }
    for(String memory : selectedMemoryList) {
        if(assetWithSmartHandEntitlementBool.containsKey(memory)) {
            smartHandQualified = true;
            return;
        }
        
    }
    for(String psu : selectedPowerSupplyList) {
        if(assetWithSmartHandEntitlementBool.containsKey(psu)) {
            smartHandQualified = true;
            return;
        }
        
    }
    for(String asset : selectedApplianceList) {
        if(assetWithSmartHandEntitlementBool.containsKey(asset)) {
            smartHandQualified = true;
            return;
        }
        
    }
    for(String cmos : selectedCMOSBatteryList) {
        if(assetWithSmartHandEntitlementBool.containsKey(cmos)) {
            smartHandQualified = true;
            return;
        }
        
    }
     for(String driveList : selectedDriveList) {
        if(assetWithSmartHandEntitlementBool.containsKey(driveList)) {
            smartHandQualified = true;
            return;
        }
        
    }
    
    for(String node : selectedNodeList) {
        if(assetWithSmartHandEntitlementBool.containsKey(node)) {
            smartHandQualified = true;
            return;
        }
        
    }
    
    
  
    }
    public void setsmartHandDate()
    {
      string smartHandArrDate;
      RMAOrder.Send_Smart_Hands_Service__c = smartHandRequested;
     date smartHandDateVal;
     if(!Test.isRunningTest()){
     smartHandArrDate = Apexpages.currentPage().getParameters().get('dateValue');
     }
    else{
     smartHandArrDate =system.Today().format();
     }
     system.debug('smartHandArrDate'+smartHandArrDate);
     smartHandDateVal = Date.parse(smartHandArrDate);
     system.debug('smartHandDateVal'+smartHandDateVal);
     system.debug('stored Date Value'+smartHandDateVal);
     if(RMAOrder.Send_Smart_Hands_Service__c == true) {
       RMAOrder.Date_of_Smart_Hands_Arrival__c = smartHandDateVal;
                
            }
    }
    
    
    public static Integer getCounter() {
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        return i;
    }  */                 
}