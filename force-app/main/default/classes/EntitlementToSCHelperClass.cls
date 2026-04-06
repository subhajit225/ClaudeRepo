public class EntitlementToSCHelperClass{
    private static Pricebook2 stdPriceBook;
    public static Pricebook2 getStdPriceBook () {
    if (stdPriceBook == null) 
        stdPriceBook    = [select id, name from Pricebook2 where isStandard = true limit 1];
        return stdPriceBook;    
    }
    private static map<String,Id> mapProdCodevsID= new Map<String, Id>();
    public static void getProductId() {
    
        for(product2 prod: [select id, productCode from Product2 LIMIT 50000]){
            mapProdCodevsID.put(prod.productCode, prod.Id);
        }
           //return 'true';
    }
    private static map<Id,Decimal> mapOrderProductwithEntlCount= new Map<Id,Decimal>();
    public static void getOrderProductEntitlementCount(List<Id> orderItemIds) {
    
        for(OrderItem oi: [select id, (select id, name from Entitlements__r) from OrderItem  where ID IN:orderItemIds LIMIT 50000]){
            mapOrderProductwithEntlCount.put(oi.Id, oi.Entitlements__r.size());
        }
           //return 'true';
        system.debug('mapOrderProductwithEntlCount=='+mapOrderProductwithEntlCount);
    }
    //EntitlementToSCHelperClass.
    public static void createSCandSCLI(Map<Entitlement, Set<Entitlement>> mapEntitlements,string timestamp){
        
        getProductId();
        getStdPriceBook();
        String relatedAccountId ='';
        List<Id> relatedOrderProducts =new List<Id>();
        //List<Entitlement> processedEntList = new List<Entitlement>();
        //processedEntList.addAll(mapEntitlements.values());
        for(Entitlement entParent : mapEntitlements.keySet()){
            for(Entitlement ent : mapEntitlements.get(entParent)){
                relatedOrderProducts.add(ent.Order_Service_Item__c);
            }
        }
        system.debug('relatedOrderProducts--'+relatedOrderProducts);
        getOrderProductEntitlementCount(relatedOrderProducts);
        List<ServiceContract> contractToBeCreated = new List<ServiceContract>();
        Map<Id, ServiceContract> entlIdToContract = new Map<Id, ServiceContract>();
        //Map<Entitlement, ServiceContract> mapSCtoEntl = new Map<Entitlement, ServiceContract>();
        for(Entitlement entl : mapEntitlements.KeySet() ){
            ServiceContract con = New ServiceContract();
            con.AccountId = entl.AccountId;
            relatedAccountId=entl.AccountId;
            con.Name = entl.Account.Name+ '- Contract';
            con.startDate =entl.StartDate;
            con.EndDate = entl.EndDate;
            con.SBQQSC__RenewalOpportunityRecordTypeId__c = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId();
            
            if(entl.order_service_item__c != null){
                if(entl.order_service_item__r.order.Type == 'POC'){
                    con.SBQQSC__Opportunity__c = entl.order_service_item__r.order.POC_Opportunity__c;
                    con.Name = entl.order_service_item__r.Order.POC_Opportunity__r.Name+'- Contract';
                }
                else {
                    con.SBQQSC__Opportunity__c = entl.order_service_item__r.order.OpportunityId;
                    con.Name = entl.order_service_item__r.order.Opportunity.Name+'- Contract';
                }
                
                con.SBQQSC__Order__c = entl.order_service_item__r.orderId;
            }
            con.OwnerId = entl.Account.OwnerId;
            if(entl.startDate != null && entl.endDate != null){
            con.Term  =  entl.startDate.monthsBetween(entl.endDate);
            con.SBQQSC__RenewalTerm__c = entl.startDate.monthsBetween(entl.endDate);
            }
            //contract.SBQQ__RenewalTerm__c = entl.
            //con.Status = 'Draft';
            if(entl.order_service_item__c != null){
                con.Pricebook2Id = entl.order_service_item__r.order.PriceBook2Id;
            }
            else{
                con.Pricebook2Id = stdPriceBook.id;
            }
            //mapSCtoEntl.put(entl, con);
            entlIdToContract.put(entl.Id, con);
            system.debug('entlIdToContract =='+entlIdToContract);
            
        } 
        
        System.Savepoint sp = Database.setSavepoint();
        try{
        system.debug('size entlIdToContract =='+entlIdToContract.size()+'==entlIdToContract=='+entlIdToContract.values());
        insert entlIdToContract.values();   //mapSCtoEntl.values(); //

    }catch(Exception ex){
        system.debug('Excpetion in createSCandSCLI Method'+ex);
        createErrorRecord(ex.getMessage(),'Service Contract','Entitlement_To_ServiceContract_Batch', ex.getTypeName(), ex.getLineNumber(),relatedAccountId,null,timestamp,'');
                
    }
    Map<Id, Id> mapProductToPriceBookEntryID = new Map<Id,Id>();
    for(PriceBookEntry pbe : [select id, Product2ID, Pricebook2Id from PricebookEntry where Pricebook2.Name='Standard Price Book' Limit 50000]){
        mapProductToPriceBookEntryID.put(pbe.Product2ID,pbe.Id);
    }
    List<ContractLineItem> CLIList  = new List<ContractLineItem>();
    Map<Entitlement, ContractLineItem> mapCLItoEntl = new Map<Entitlement, ContractLineItem>();
    Map<Id, ContractLineItem> mapCLItoEntlID = new Map<Id, ContractLineItem>();
    List<ID> ErrorEntitlementIdList = new List<Id>(); 
    try{

        List<PricebookEntry> pricebookEntryList = new List<PricebookEntry>();
        for(Entitlement entl : mapEntitlements.KeySet() ){                
            for(Entitlement ent : mapEntitlements.get(entl)){
                if(ent.Order_Service_Item__c == null && ent.Product__c != null && !mapProductToPriceBookEntryID.containsKey(ent.Product__c)){
                    PricebookEntry newPBE = new PricebookEntry(Pricebook2Id = stdPriceBook.Id, Product2Id = ent.Product__c, UnitPrice = 0, IsActive = true); 
                    pricebookEntryList.add(newPBE);
                }
            }
        }
        if(!pricebookEntryList.isEmpty()){
            insert pricebookEntryList;
            for(PriceBookEntry pbe: pricebookEntryList){
                mapProductToPriceBookEntryID.put(pbe.Product2ID,pbe.Id);
            }
        }

        for(Entitlement entl : mapEntitlements.KeySet() ){
        system.debug('mapEntitlements.KeySet() 222=='+mapEntitlements.get(entl).size());
            
            for(Entitlement ent : mapEntitlements.get(entl)){
                ContractLineItem CLI = new ContractLineItem();
                CLI.ServiceContractID = entlIdToContract.get(entl.ID).Id;
                CLI.StartDate = ent.StartDate;
                CLI.EndDate = ent.EndDate;
                Decimal durationinYrs = 1.00;
                if(entl.startDate != null && entl.endDate != null){
                    durationinYrs = entl.startDate.monthsBetween(entl.endDate)/12.00;
                }
                
                CLI.AssetID = ent.AssetID;
                CLI.SBQQSC__RequiredById__c = ent.AssetId;
                CLI.SBQQSC__Product__c = ent.Product__c;
                CLI.SBQQSC__RequiredByProduct__c = ent.base_product__c != null? mapProdCodevsID.get(ent.base_product__c): null;
                CLI.Product_Option_Percent_of_Total__c =16.0;
                if(ent.Order_Service_Item__c != null){
                    CLI.SBQQSC__OrderProduct__c = ent.Order_Service_Item__c;
                }
                if(ent.Order_Service_Item__c != null){
                    CLI.PriceBookEntryId = ent.Order_Service_Item__r.PriceBookEntryId;
                }else if(ent.Product__c != null){
                    CLI.pricebookEntryId = mapProductToPriceBookEntryID.get(ent.Product__c);
                }
                CLI.SBQQSC__Account__c = ent.AccountId != null? ent.AccountId: null;
                //CLI.UnitPrice = ent.Order_Service_Item__c != null? ent.Order_Service_Item__r.UnitPrice: ent.Order_Quantity__c != null && ent.Calculated_List_Price__c != null ? ent.Calculated_List_Price__c/ ent.Order_Quantity__c : ent.Calculated_List_Price__c != null ? ent.Calculated_List_Price__c :0.0 ;
                //CLI.Status = ent.Status;
                //CLI.Quantity = ent.Order_Service_Item__c != null? ent.Order_Service_Item__r.Quantity: 1.00;
                CLI.Quantity = mapOrderProductwithEntlCount.get(ent.Order_Service_Item__c)!=null?ent.Order_Quantity__c/mapOrderProductwithEntlCount.get(ent.Order_Service_Item__c):1.00;
                
                Decimal Price = ent.Order_Service_Item__c != null && ent.Order_Service_Item__r.Actual_Sales_Price__c != null && ent.Order_Service_Item__r.Actual_Sales_Price__c != 0? ent.Order_Service_Item__r.Actual_Sales_Price__c: ent.PB_List_Price__c;
                system.debug('Price 11 =='+Price);
                system.debug('durationinYrs =='+durationinYrs);
                
                if(ent.Product__r.ProductCode.endsWith('-MO')){
                    Price= Price!=null?Price*12.00:0.00;
                    CLI.Quantity= CLI.Quantity/12.00;
                    CLI.UnitPrice = Price;
                    CLI.SBQQSC__ListPrice__c = CLI.UnitPrice;
                }
                else{
                    CLI.UnitPrice = Price== null || durationinYrs ==0 ? 0.00:(Price /durationinYrs);
                    CLI.SBQQSC__ListPrice__c = CLI.UnitPrice;
                }
                if(ent.Base_Product__c == null && !ent.Product__r.ProductCode.endsWith('-MO')){
                        CLI.SBQQSC__RenewalQuantity__c = CLI.Quantity;
                }
                else
                    CLI.SBQQSC__RenewalQuantity__c = 1.0;

                if(!ent.Product__r.ProductCode.endsWith('-MO'))
                    CLI.Quantity = durationinYrs;
                
                if(ent.Base_Product__c == null)
                    CLI.Quantity = CLI.SBQQSC__RenewalQuantity__c*durationinYrs;
                system.debug('Price 222 =='+Price);
                       
                decimal discount = ent.Order_Service_Item__r.Actual_Sales_Price__c !=null && ent.Order_Service_Item__r.Actual_Sales_Price__c !=0? 100*((ent.Order_Service_Item__r.Actual_Sales_Price__c - ent.Order_Service_Item__r.Sales_Price__c)/ent.Order_Service_Item__r.Actual_Sales_Price__c):Decimal.ValueOf(System.Label.Discount);
                CLI.Discount =discount;
                CLI.SBQQSC__Number__c =1;
                CLIList.add(CLI); 
                system.debug('ent=='+ent+'--cli--'+cli);
                mapCLItoEntl.put(ent,cli);
                mapCLItoEntlID.put(ent.Id,cli);
                system.debug('mapCLItoEntl =='+mapCLItoEntl);
                system.debug('mapCLItoEntlID =='+mapCLItoEntlID);
            }
            }
            
                    system.debug('size CLIList =='+CLIList.size()+'==CliList=='+CLIList);
                    
                    //insert  CLIList ;//mapCLItoEntl.values();
                    Database.SaveResult[] srList = Database.insert(CLIList, false);
                    // Iterate through each returned result
                    for(Integer i=0;i<srList.size();i++){
                        
                        if (!srList.get(i).isSuccess()){
                            // DML operation failed
                            Database.rollback(sp);
                            Database.Error error = srList.get(i).getErrors().get(0);
                            String failedDML = error.getMessage();
                            CLIList.get(i);//failed record from the list
                            system.debug('Failed ID'+CLIList.get(i).pricebookEntryId);
                            ErrorEntitlementIdList.add(CLIList.get(i).pricebookEntryId);
                            system.debug('ErrorEntitlementIdListD'+ErrorEntitlementIdList);
                            string stringerr=createErrorRecord(error.getMessage(),'Contract Line Item','Entitlement_To_ServiceContract_Batch', error.getMessage(), i,relatedAccountId,CLIList.get(i).SBQQSC__Product__c,timestamp,CLIList.get(i).pricebookEntryId);
                            system.debug('test---'+stringerr);
                         }
                        
                    }
                    List<Entitlement> entlIst = new List<Entitlement>();
                    if(ErrorEntitlementIdList.isEmpty()){
                    for(Entitlement ent : [select id,ContractLineItemID,isSCCreated__C,ServiceCOntractID from Entitlement where Id IN: mapCLItoEntlID.KeySet()]){
                        
                        ent.ContractLineItemID= mapCLItoEntlID.get(ent.Id).Id;
                        system.debug('test--'+mapCLItoEntlID);
                        ent.ServiceCOntractID= mapCLItoEntlID.get(ent.id).ServiceContractID !=null?mapCLItoEntlID.get(ent.id).ServiceContractID:null;
                        ent.isSCCreated__C = true;
                        entlIst.add(ent);
                    }
                    update entlIst;
                    }
                    
                    
                }catch(Exception ex){
                    system.debug('Excpetion in createSCandSCLI Method'+ex);
                    createErrorRecord(ex.getMessage(),'Contract Line Item','Entitlement_To_ServiceContract_Batch', ex.getTypeName(), ex.getLineNumber(),relatedAccountId,'',timestamp,'');
                    
                }
    
    }
    public static string createErrorRecord(string exceptionMessage, String objectType, String component,String type,Integer linenumber, String recId, String prodCode,string timestamp,String pbeId){
        try{
        Batch_Log__c newErrorRecord = new Batch_Log__c();
        newErrorRecord.Description__c = exceptionMessage;
        newErrorRecord.Source_Component__c =component;
        newErrorRecord.Related_Object__c = objectType;
        newErrorRecord.Exception_Type__c = type;
        newErrorRecord.Line_Number__C =linenumber;
        newErrorRecord.Related_Record_ID__c  = recId;
        system.debug('timestamp--'+timestamp);
        newErrorRecord.Batch_TimeStamp__c = timeStamp;
        newErrorRecord.Related_Product__c = prodCode;
        newErrorRecord.Failed_PriceBookEntry__c =PBEid;
        system.debug(newErrorRecord);
        Database.insert(newErrorRecord,false);
        return newErrorRecord.id;
        }
        catch(Exception exp){
            system.debug('Excpetion in error log Method'+exp);
            return null;
        }
        
    }

}