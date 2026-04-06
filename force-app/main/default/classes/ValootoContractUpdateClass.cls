/*
 This batch converts the non-CPQ Service Contracts to CPQ Service Contracts
 Assumption : Service Contracts are not amended or renewed.
*/
global class ValootoContractUpdateClass implements Database.Batchable<sObject>{
    Exception[] errors = new Exception[0];   
    public set<Id> scIds = new set<Id>();
    public set<Id> cliIds = new set<Id>();
    public set<Id> prodId = new set<Id>();
    public boolean exceptionVariable = false;
    public List<PriceBookEntry> pbeList = new List<PriceBookEntry>();
    public List<ContractLineItem> cliList = new List<ContractLineItem>();
    public List<ContractLineItem> dummySCLine = new List<ContractLineItem>();
    public List<ContractLineItem> updateCLI = new List<ContractLineItem>();
    public List<ContractLineItem> deleteCLI = new List<ContractLineItem>();
    public List<ServiceContract> updateSc = new List<ServiceContract>();
    public List<Entitlement> entitlementList = new List<Entitlement>();
    public List<Entitlement> entitlementToBeUpdated = new List<Entitlement>();
    public List<Pricebook2> CPQPriceBook = new List<Pricebook2>();
	public Id dummyId;
    
    public Map<Id, Id> entitlementAndCli = new Map<Id, Id>();         //One CLI will have only once entitlement?
    public Map<Id, Id> productAndPriceEntry = new Map<Id, Id>();
    public Map<Id, ContractLineItem> oldCLIAndNewCLI = new Map<Id, ContractLineItem>();
    
    public Id cpqPricebookId;
    public static final String PRICEBOOKNAME = 'CPQ Pricebook';
    
    global Database.querylocator start(Database.BatchableContext BC){
        //Query Service COntract
        String query = 'SELECT Id, Pricebook2Id'
                     + ' FROM ServiceContract '
                     + ' WHERE Convert_Valooto_To_CPQ__c = TRUE '
                     + ' AND Pricebook2.Name != \'' + PRICEBOOKNAME + '\'';
        system.debug('Vaishali Batch Query'+query);
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<ServiceContract> scope){ 
        Savepoint spCLIInsert = Database.setSavepoint();
		Id serviceContractId;
        //Get CPQ Pricebook Id
        CPQPriceBook = [SELECT Id 
                          FROM Pricebook2
                         WHERE Name = :PRICEBOOKNAME
                         ];
        system.debug('Vaishali CPQPriceBook'+CPQPriceBook);
        
		dummyId = [SELECT Id
                     FROM ServiceContract 
                    WHERE Name =: 'Dummy Service Contract DO NOT DELETE'
					][0].Id;
		
        //Get service contract Ids
        system.debug('Vaishali Service contractscope'+scope);
        for (ServiceContract sc : scope){
            scIds.add(sc.Id);           
        }
        system.debug('Vaishali scIds'+scIds);
        
        //Contract Line Item of the service contract
        cliList = [SELECT Id
                        , ServiceContractId
                        , SBQQSC__Account__c
                        , Quantity
                        , UnitPrice
                        , SBQQSC__Product__c
                        , PricebookEntryId
                        , StartDate
                        , EndDate
                        , SBQQSC__OrderProduct__c
                        , SBQQSC__ListPrice__c
                        , Discount
                        , SBQQSC__Discount__c
                        , SBQQSC__RootId__c
                        , RootContractLineItemId
                        , SBQQSC__RenewalProductId__c
                        , SBQQSC__Number__c 
                        , (SELECT Id
                                , ContractLineItemId    
                                , ServiceContractId 
                             FROM Entitlements
                            )
                        , (SELECT Id
                                , SBQQSC__CurrentContractLineItem__c
                                , SBQQSC__RequiredByLineItem__c 
                             FROM SBQQSC__CoveredAssets__r 
                            )
                     FROM ContractLineItem 
                    WHERE ServiceContractId 
                       in :scIds];  
        system.debug('Vaishali cliList'+cliList);
        //Add CLI id in set, product in set Id
        for(ContractLineItem cliInstance : cliList) {
            cliIds.add(cliInstance.id);
            prodId.add(cliInstance.SBQQSC__Product__c);
            deleteCLI.add(cliInstance);
        }
        system.debug('Vaishali cliIds'+cliIds);
        system.debug('prodId'+prodId);
        system.debug('Vaishali deleteCLI'+deleteCLI);
        
        //Query Pricebookentry of products attached to CLI
        pbeList = [SELECT Id
                        , UnitPrice
                        , Pricebook2Id
                        , Product2Id
                     FROM PricebookEntry
                    WHERE Pricebook2.Name = 'CPQ Pricebook'
                      AND Product2Id IN :prodId 
                    ];
        system.debug('Vaishali pbeList'+pbeList);
        
        for(PricebookEntry pbeInstance : pbeList) {
            productAndPriceEntry.put(pbeInstance.product2Id, pbeInstance.Id);    
        }
        system.debug('Vaishali productAndPriceEntry'+productAndPriceEntry);
        
        Map<Id, List<ContractLineItem>> scIdAndNewCLI = new Map<Id, List<ContractLineItem>>();
        List<ContractLineItem> newCLIList = new List<ContractLineItem>();
        Map<String, List<WrapperForValootoBatch.CLIWrapper>> clusterAndWrapperMap = 
            new Map<String, List<WrapperForValootoBatch.CLIWrapper>>();
        WrapperForValootoBatch.CLIWrapper wrapIns = new WrapperForValootoBatch.CLIWrapper();
        List<WrapperForValootoBatch.CLIWrapper> listOfWrapper= new List<WrapperForValootoBatch.CLIWrapper>();
        Map<Id, List<Entitlement>> clonedCLIandEntitlement = new Map<Id, List<Entitlement>>();
        Map<Id, List<Asset>> clonedCLIandAsset = new Map<Id, List<Asset>>();
        List<Entitlement> entitlementListToUpdate = new List<Entitlement>();
        List<Asset> assetListToUpdate = new List<Asset>();
        wrapIns.cliAndEntitlement = new Map<Id, List<Entitlement>>();
		wrapIns.cliAndClonedCLI = new Map<Id, ContractLineItem>();
        wrapIns.cliAndAsset = new Map<Id, List<Asset>>();
        //Clone CLI to Dummy Service Contract
        List<String> fields = new List<String>();
        fields.addAll(ContractLineItem.getsObjectType().getDescribe().fields.getMap().keySet());
        for(ContractLineItem cliInstance : cliList) {
            Id cId = cliInstance.Id;
            system.debug('Vaishali'+cliInstance.Id);
            String soql = 'SELECT ' + String.escapeSingleQuotes(String.join(fields, ',')) + ' FROM ContractLineItem WHERE Id =: cId';
            ContractLineItem newCLI = Database.query(soql).deepclone(false,false,false);
            newCLI.serviceContractId = dummyId;
            newCLI.PricebookEntryId = productAndPriceEntry.get(newCLI.SBQQSC__Product__c);

            try {
                system.debug('inside try of CLI');
                insert newCLI;
            } Catch(DMLException e) {
                system.debug('inside catch of CLI');
				Database.rollback(spCLIInsert);
				errors.add(e);
                exceptionVariable = true;
                system.debug('Vaishali exceptionVariable'+exceptionVariable);
				
            }           
            if(exceptionVariable == false) {
                system.debug('Vaishali CLI Id'+newCLI.Id);
                
                wrapIns.cliAndClonedCLI.put(cId, newCLI);
            
                //Creating Map of Original Service Contract and new CLI List 
                if(scIdAndNewCLI.containsKey(cliInstance.serviceCOntractId)) {
                    
                    system.debug('Vaishali Inside first If of scIdAndNewCLI Map ');
                    newCLIList = scIdAndNewCLI.get(cliInstance.serviceCOntractId);
                    newCLIList.add(newCLI);
                    scIdAndNewCLI.put(cliInstance.serviceContractId, newCLIList);
                }else {
                    system.debug('Vaishali Inside else If of scIdAndNewCLI Map ');
                    system.debug('Vaishali newCLI'+newCLI);
                    system.debug('Vaishali newCLIList'+newCLIList);
                    system.debug('Vaishali scIdAndNewCLI'+scIdAndNewCLI);
                    newCLIList.add(newCLI);
                    scIdAndNewCLI.put(cliInstance.serviceContractId, newCLIList);
                }
                system.debug('Vaishali scIdAndNewCLI'+scIdAndNewCLI);
                 
                 //Creating Map of CLI and List of Entitlement associated with it.           
                for(Entitlement entInstance : cliInstance.Entitlements) {
                    List<Entitlement> entList = new List<Entitlement>();
                    
                    //if Map for CLI already exists 
                    if(wrapIns.cliAndEntitlement.containsKey(entInstance.ContractLineItemId)) {
                        system.debug('inside first if of entitlement map');
                        entList = wrapIns.cliAndEntitlement.get(entInstance.ContractLineItemId);
                        entList.add(entInstance);
                        wrapIns.cliAndEntitlement.put(entInstance.ContractLineItemId, entList);
                        
                    }else { //if Map for CLI is new
                        system.debug('inside first else of entitlement map');
                        entList.add(entInstance);
                        wrapIns.cliAndEntitlement.put(entInstance.ContractLineItemId, entList);
                    }
                    
                    system.debug('Vaishali wrapIns.cliAndEntitlement'+wrapIns.cliAndEntitlement);
                }
                
                //Creating Map of CLI and List of Assets associated with it
                for(Asset assetIns : cliInstance.SBQQSC__CoveredAssets__r ) {
                    List<Asset> assetList = new List<Asset>();
                    
                    if(wrapIns.cliAndAsset.containsKey(assetIns.SBQQSC__CurrentContractLineItem__c)) {
                        system.debug('inside first if of asset map');
                        assetList = wrapIns.cliAndAsset.get(assetIns.SBQQSC__CurrentContractLineItem__c);
                        assetList.add(assetIns);
                        wrapIns.cliAndAsset.put(assetIns.SBQQSC__CurrentContractLineItem__c, assetList);
                        
                    }else { //if Map for CLI is new
                        system.debug('inside first else of assetmap');
                        assetList.add(assetIns);
                        wrapIns.cliAndAsset.put(assetIns.SBQQSC__CurrentContractLineItem__c, assetList );
                    }
                    system.debug('Vaishali Map of Assets'+wrapIns.cliAndAsset);
                }
                
                listOfWrapper.add(wrapIns);
                if(clusterAndWrapperMap.containsKey(cliInstance.ServiceContractId)) {
                    system.debug('Vaishali Inside first if of Map');
                    clusterAndWrapperMap.put(cliInstance.ServiceContractId, listOfWrapper);  
                } else {
                    List<WrapperForValootoBatch.CLIWrapper> wrapper = new List<WrapperForValootoBatch.CLIWrapper>();
                    system.debug('Vaishali Inside first else of Map');
                    wrapper.add(wrapIns);
                    clusterAndWrapperMap.put(cliInstance.ServiceContractId, wrapper);
                } 
                system.debug('Vaishali listOfWrapper'+listOfWrapper);
                
                system.debug('Vaishali clusterAndWrapperMap'+clusterAndWrapperMap);   
                system.debug('Vaishali clusterAndWrapperMap.keySet()'+clusterAndWrapperMap.keySet());
                system.debug('Vaishali clusterAndWrapperMap.values()'+clusterAndWrapperMap.values());
            }
        } 
        
        List<List<WrapperForValootoBatch.CLIWrapper>> wrapList = new List<List<WrapperForValootoBatch.CLIWrapper>>();
        wrapList  = clusterAndWrapperMap.values();
        if(wrapList.size() != 0 && exceptionVariable == false) {
            for(List<WrapperForValootoBatch.CLIWrapper> wrap1 : wrapList ) {
            system.debug('Inside first for');
                List<Entitlement> entListToUpdate = new List<Entitlement>();
                List<Asset> assetToUpdate = new List<Asset>();
                for(WrapperForValootoBatch.CLIWrapper wrap2 : wrap1) {
                system.debug('Inside second for');
                    Map<Id, ContractLineItem> cliMap = new Map<Id, ContractLineItem>();
                    cliMap = wrap2.cliAndClonedCLI;
                    List<List<Entitlement>> entMap = new List<List<Entitlement>>();
                    entMap = wrap2.cliAndEntitlement.values();
                    List<List<Asset>> assetMap = new List<List<Asset>>();
                    assetMap = wrap2.cliAndAsset.values();
                    for(List<Entitlement> entListFromMap: entMap ) {
                        for(Entitlement entInstance : entListFromMap) {
                            system.debug('Inside for of List of entitlement from Wrapper');
                            if(cliMap.containsKey(entInstance.ContractLineItemId)) {
                                system.debug('Inside if of entitlement update wrapper');
                                ContractLineItem cliNew = cliMap.get(entInstance.ContractLineItemId);
                                entInstance.ContractLineItemId = cliNew.Id;
                                entListToUpdate.add(entInstance);
                                system.debug('Vaishali Update Original Entitlement'+ entListToUpdate);
                                List<Entitlement> entListForMap = new List<Entitlement>();
                                if(clonedCLIandEntitlement.containsKey(cliNew.Id)) {
                                    system.debug('Inside entitlement if of map creation'+clonedCLIandEntitlement);
                                    entListForMap = clonedCLIandEntitlement.get(cliNew.Id);
                                    entListForMap.add(entInstance);
                                    clonedCLIandEntitlement.put(cliNew.Id, entListForMap);
                                }else {
                                    system.debug('Inside entitlement else of map creation '+clonedCLIandEntitlement);
                                    system.debug('Vaishali entListForMap '+entListForMap);
                                    
                                    entListForMap.add(entInstance);
                                    clonedCLIandEntitlement.put(cliNew.Id, entListForMap);
                                }
                            }
                            
                        }
                    }
                    system.debug('Vaishali Update Original Entitlement'+ entListToUpdate);
                    try {
                        system.debug('Vaishali Inside try of updating entitlement' );
                        update entListToUpdate;
                    }
                    Catch(Exception e) {
                        system.debug('Vaishali Inside catch of updating entitlement' +e.getMessage());
						Database.rollback(spCLIInsert);
						errors.add(e);
						exceptionVariable = true;
                        
                    }
                    
                    //Asset Update
                    for(List<Asset> assetListFromMap: assetMap ) {
                        for(Asset assetInstance : assetListFromMap) {
                            system.debug('Inside for of List of Asset from Wrapper');
                            if(cliMap.containsKey(assetInstance.SBQQSC__CurrentContractLineItem__c)) {
                                system.debug('Inside if of entitlement update wrapper');
                                ContractLineItem cliNew = cliMap.get(assetInstance.SBQQSC__CurrentContractLineItem__c);
                                if(assetInstance.SBQQSC__CurrentContractLineItem__c != null) {
                                    assetInstance.SBQQSC__CurrentContractLineItem__c = cliNew.Id;
                                }
                                /*if(asset.SBQQSC__RequiredByLineItem__c != null) {
                                    assetInstance.SBQQSC__RequiredByLineItem__c = cliNew.Id;
                                }*/
                                assetToUpdate.add(assetInstance);
                                system.debug('Vaishali Update Original Asset'+ assetToUpdate);
                                List<Asset> assetListForMap = new List<Asset>();
                                if(clonedCLIandAsset.containsKey(cliNew.Id)) {
                                    system.debug('Inside asset if of map creation'+clonedCLIandAsset);
                                    assetListForMap = clonedCLIandAsset.get(cliNew.Id);
                                    assetListForMap.add(assetInstance);
                                    clonedCLIandAsset.put(cliNew.Id, assetListForMap);
                                }else {
                                    system.debug('Inside asset else of map creation '+clonedCLIandAsset);
                                    system.debug('Vaishali assetListForMap '+assetListForMap);
                                    
                                    assetListForMap.add(assetInstance);
                                    clonedCLIandAsset.put(cliNew.Id, assetListForMap);
                                }
                            }
                            
                        }
                    }
                    try {
                        system.debug('Vaishali Inside try of updating asset' );
                        update assetToUpdate;
                    }
                    Catch(Exception e) {
                        system.debug('Vaishali Inside catch of updating asset' +e.getMessage());
						Database.rollback(spCLIInsert);
						errors.add(e);
						exceptionVariable = true;
                        
                    }
                    
                }
            }
        }
        
        //delete original CLI from Original Contract
        if(exceptionVariable == false) {
            try {
                system.debug('Vaishali Inside try of deleting CLI'+deleteCLI);
                delete deleteCLI;
            }
            Catch(Exception e) {
                system.debug('Vaishali Inside catch of deleting CLI'+e.getMessage());
				Database.rollback(spCLIInsert);
				errors.add(e);
				exceptionVariable = true;				
                
            } 
        }
        
        //Update Original SC with CPQ Pricebook
        if(exceptionVariable == false) {
            List<ServiceContract> scToUpdate = new List<ServiceContract>();
            for (ServiceContract sc : scope) {
                system.debug('Vaishali Inside the for of updating SC Pricebook');
                sc.Pricebook2Id = CPQPriceBook[0].Id;
                scToUpdate.add(sc);
            }
            try {
                system.debug('Inside try of updating the SC'+scToUpdate);
                update scToUpdate;
            }
            Catch(Exception e) {
                system.debug('Inside catch of updating the SC'+e.getMessage());
				Database.rollback(spCLIInsert);
				errors.add(e);
				exceptionVariable = true;
                
            }
        }
         
        if(exceptionVariable == false) {
             //Iterate over scIdAndNewCLI to clone new CLI to Original SC
             List<ContractLineItem> cliToUpdateOriginal = new List<ContractLineItem>();
             for(ServiceContract sc : scope) {
                 if(scIdAndNewCLI.containsKey(sc.Id)) {
                    List<ContractLineItem> cliList = scIdAndNewCLI.get(sc.Id);
                    for(ContractLineItem cliInstance: cliList) {
                        Id cId = cliInstance.Id;
                        system.debug('Vaishali'+cliInstance.Id);
                        String soql = 'SELECT ' + String.escapeSingleQuotes(String.join(fields, ',')) + ' FROM ContractLineItem WHERE Id =: cId';
                        ContractLineItem newCLI = Database.query(soql).deepclone(false,false,false);
                        newCLI.serviceContractId = sc.Id;
                        system.debug('CLI on original SC'+newCLI);
                        insert newCLI;
                        
                        if(clonedCLIandEntitlement.containsKey(cliInstance.Id)) {
                            List<Entitlement> entList = clonedCLIandEntitlement.get(cliInstance.Id);    
                            for(Entitlement entListInstance : entList) {
                                entListInstance.ContractLineItemId = newCLI.Id;
                                entitlementListToUpdate.add(entListInstance);
                                system.debug('inside updating the entitlement again'+entitlementListToUpdate);
                           }   
                           
                        }
                        if(clonedCLIandAsset.containsKey(cliInstance.Id)) {
                            List<Asset> assetList = clonedCLIandAsset.get(cliInstance.Id);    
                            for(Asset assetListInstance : assetList) {
                                if(assetListInstance.SBQQSC__CurrentContractLineItem__c != null) {
                                    assetListInstance.SBQQSC__CurrentContractLineItem__c = newCLI.Id;
                                }
                                /*if(asset.SBQQSC__RequiredByLineItem__c != null) {
                                    assetListInstance.SBQQSC__RequiredByLineItem__c = newCLI.Id;
                                }*/
                                assetListToUpdate.add(assetListInstance);
                                system.debug('inside updating the asset again'+assetListToUpdate);
                           }   
                           
                        }
                        
                    }
                 }         
             }
             
             try {
                if(entitlementListToUpdate.size() != 0 )  {update entitlementListToUpdate;}
                if(assetListToUpdate.size() != 0 ) {update assetListToUpdate;}
            }
            Catch(Exception e) {
                
				Database.rollback(spCLIInsert);
				errors.add(e);
				exceptionVariable = true;
                
            }
        }
         //Delete the CLI from Dummy Contract
        
        if(exceptionVariable == false) {
            List<ContractLineItem> dummyContractCLIToDelete = new List <ContractLineItem>();
            dummyContractCLIToDelete = [SELECT Id
                                          FROM ContractLineItem 
                                         WHERE ServiceContract.Name =: 'Dummy Service Contract DO NOT DELETE'
                                         ];
            try{
                delete dummyContractCLIToDelete;
            }Catch(Exception e){
				Database.rollback(spCLIInsert);
				errors.add(e);
				exceptionVariable = true;               
                
            }
        }
		if(exceptionVariable == true) {
            String ErrorMessage;
            for(Exception errIns: errors) {
                ErrorMessage = ErrorMessage+errIns;
            }
            Batch_Error_Log__c logInstance = new Batch_Error_Log__c();
            logInstance.Failure_Job_ID__c = BC.getJobId(); 
            logInstance.Failure_Message__c = ErrorMessage; 
            logInstance.Object_ID__c = serviceContractId;
            system.debug('Inside catch batch error log'+logInstance);
            insert logInstance; 
            system.debug('Inside catch batch error log'+logInstance.id);
            
            system.debug('Vaishali exceptionVariable'+exceptionVariable);
            
        }
    }
    global void finish(Database.BatchableContext BC){
   
        
    }
}