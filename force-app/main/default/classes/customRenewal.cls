/***********************************************************************************************************
* Method Name          : customRenewal
* Date Created/Modified: 28/03/2024
* @description         : Controller class to create Quote and Quote Lines for Renewal + Expansion quotes
* Test Class           :
/**********************************************************************************************************/
Global without sharing class customRenewal{

    /**count */ 
    public static Integer count = 1;
    public static Set<String> extIDSFound = new Set<String>();
    public static Map<String, SBQQ__Quoteline__c> extIDSFoundMap = new Map<String, SBQQ__Quoteline__c>();
   
   /***********************************************************************************************************
    * Method Name          : renewalCustomContract
    * Date Created/Modified: 28/03/2024
    * @description         : Controller class to create Quote and Quote Lines for Renewal + Expansion quotes
    * @return              : Id
    * @param renewallist
    * @param oppId
    * Test Class           :
    /**********************************************************************************************************/
    @AuraEnabled
    Webservice static Id renewalCustomContract(List<Servicecontract> renewallist, String oppId){
        for(Servicecontract sc : renewallist){
            System.debug(LoggingLevel.DEBUG,'number>>'+sc.ContractNumber);
        }
        Integer addyears = renewallist[0].Term / 12;
        Integer addyearsforEnd = renewallist[0].Term / 12 + 1;
        Date dpast = System.today().addDays(-90);
        String whereClause;
        List<Arry_Query_clause__mdt> whereclauseLst = Arry_Query_clause__mdt.getAll().values();
        Date dfuture = System.today();        
        Boolean isREQuote = false;
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        try{
                    //Dynamic term logic - Added Contract_Renewal_Term__c
                    Opportunity oppRec = [SELECT Id, Name, Opportunity_Sub_Type__c, OwnerId, ContactId, Pricebook2Id, 
                                            SBQQ__QuotePricebookId__c, Contract_Renewal_Term__c FROM Opportunity 
                                        WHERE Id =: oppId LIMIT 1];

                    //Dynamic term logic Starts
                    List<ContractLineItem> cliList = new List<ContractLineItem>();
                    if (renewallist != null && !renewallist.isEmpty()) {
                        cliList = [Select Id, EndDate from ContractLineItem where ServiceContractId IN : renewallist
                                        AND (NOT SBQQSC__ProductName__c LIKE '%RZTDP%') //Excluding RZTDP SKUs as part of CPQ22-4352
                                    Order by EndDate DESC ];
                    }
                    Date maxCLIEndDate;
                    if (cliList != null && !cliList.isEmpty()) {
                        for (ContractLineItem cliObj : cliList) {
                            if (cliObj.EndDate != null) {    
                                maxCLIEndDate = cliObj.EndDate;
                                break;
                            }
                        }
                    }
                    
                    if (oppRec.Contract_Renewal_Term__c != null) {
                        dfuture = System.today().addMonths(Integer.valueOf(oppRec.Contract_Renewal_Term__c));
                    }
                    else {
                        dfuture = maxCLIEndDate;
                    }
                    //dfuture = System.today().addDays(Integer.valueOf(System.Label.Renewal_Contract_Term));
                    //Dynamic term logic Ends

                    for(Arry_Query_clause__mdt mdt: whereclauseLst){
                        whereClause = ' ' + mdt.FieldName__c + ' ' + mdt.Operator__c + ' ' + mdt.Value__c + ' AND ' + whereClause;
                        whereClause = whereClause.removeEND(' AND null');
                        //System.debug('show Clause: ' + whereClause);
                    }
                    //System.debug('show Clause Final: ' + whereClause);
                    
                    Map<String, Schema.DisplayType> CLIFields = getcreateablefields('ContractLineItem');
                    Map<String, Schema.DisplayType> QLIFields = getcreateablefields('SBQQ__QuoteLine__c');
                    Map<String, Schema.DisplayType> AssetFields = getcreateablefields('Asset');
                    Map<String, Schema.DisplayType> ProductFields = getcreateablefields('Product2');
                    
                    Map<String, ContractLines_to_QuoteLines_field_mappin__mdt> mapCustomMetadataType = ContractLines_to_QuoteLines_field_mappin__mdt.getAll();
                    String relationfield = '';
                    String assetfids = '';
                    //String entproductfields = '';
                    String asstproductfields = '';
                    String contractProductFields = '';
                    String prodFields = '';
                    
                    List<SBQQ__QuoteLine__c> quotelineListToinsert = new List<SBQQ__QuoteLine__c>();
                    List<SBQQ__QuoteLine__c> quotelineListPar = new List<SBQQ__QuoteLine__c>();
                    List<SBQQ__QuoteLine__c> quotelineListChild = new List<SBQQ__QuoteLine__c>();
                    List<ContractLines_to_QuoteLines_field_mappin__mdt> fieldmapping = ContractLines_to_QuoteLines_field_mappin__mdt.getAll().values();
                    
                    Map<String, SBQQ__QuoteLine__c> parentMapV2 = new Map<String, SBQQ__QuoteLine__c>();
                    Map<String, SBQQ__QuoteLine__c> parentMap = new Map<String, SBQQ__QuoteLine__c>();
                    Map<String, SBQQ__QuoteLine__c> childMap = new Map<String, SBQQ__QuoteLine__c>();
                    Map<Id, PricebookEntry> mapProductPbeIds = new Map<Id, PricebookEntry>();
                    Map<String, Decimal> extIdvsQty = new Map<String, Decimal>();
                    
                    Set<Id> prdIds = new Set<Id>();
                    
                    for(String str: CLIFields.keySet()){
                        relationfield = relationfield + ',' + 'ContractLineItem.' + str;
                        relationfield = relationfield.removeStart(',');
                        //System.debug('relationfield>'+relationfield);
                    }
                    
                    for(String Astf: AssetFields.keySet()){
                        assetfids = assetfids + ',' + 'Asset.' + Astf;
                        assetfids = assetfids.removeStart(',');
                        //System.debug('assetfids>'+assetfids);
                    }
                    
                    for(String prodfld: ProductFields.keySet()){
                        //entproductfields = entproductfields+','+'Product__r.'+prodfld;
                        asstproductfields = asstproductfields + ',' + 'Asset.Product2.' + prodfld;
                        contractProductFields = contractProductFields + ',' + 'ContractLineItem.SBQQSC__Product__r.' + prodfld;
                        prodFields = prodFields + ',' + prodfld;
                        //entproductfields = entproductfields.removeStart(',');
                        asstproductfields = asstproductfields.removeStart(',');
                        contractProductFields = contractProductFields.removeStart(',');
                        prodFields = prodFields.removeStart(',');
                    }
                
                    quote.SBQQ__Opportunity2__c = oppId;
                    quote.SBQQ__Account__c = renewallist[0].AccountId;
                    quote.Amended_Renewed_Service_Contract__c = renewallist[0].Id;
                    quote.SBQQ__QuoteTemplateId__c = SYSTEM.LABEL.Renewal_Expansion_Quote_Template_Id;
                    
                    //Arroyo 2.0 ARY-684 CR #20- Start
                    //quote.recordTypeId = system.label.RE_Quote; //'a6T8C0000004tMsUAI';//QuoteRecoTypeDatas.get('RE_Quote').getRecordTypeId();
                    //Arroyo 2.0 ARY-684 CR #20- End
                    
                    if(renewallist[0].Renew_to_Old_SKUs__c){
                        quote.SBQQ__QuoteProcessId__c = label.QuoteProcessId;
                    }else{
                        quote.SBQQ__QuoteProcessId__c = label.PolarisProcessId;
                    }
                    
                    quote.SBQQ__SubscriptionTerm__c = 36; // ARY-398
                    quote.SBQQ__LineItemsGrouped__c = true;
                    //quote.SBQQ__Primary__c = true;
                    quote.SBQQ__Type__c = 'Renewal+Expansion';
                    quote.SBQQ__OrderByQuoteLineGroup__c = false;
                    quote.SBQQ__OrderBy__c='Line_Type_Order__c';
                    quote.OpportunitySubType__c = oppRec.Opportunity_Sub_Type__c;
                    quote.SBQQ__PriceBook__c = oppRec.Pricebook2Id;
                    quote.SBQQ__PrimaryContact__c = oppRec.ContactId;
                    quote.SBQQ__SalesRep__c = oppRec.OwnerId;
                    quote.Update_Expires_On__c = true; // ARY-507 : to set Expiration date always to future date 
                    
                    String Query = 'SELECT Id, Name, Renewal_Category__c, Order_Service_Item__c, ServiceContract.SBQQSC__Quote__c,ServiceContract.SBQQSC__Quote__r.MSP_SKUs_Count__c,' + assetfids + ',' + contractProductFields + ',' + asstproductfields + ',ContractLineItemID ,' + relationfield + ',' + ' ContractLineItem.ServiceContract.Term, ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__ProductOption__c, ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__ProductOption__r.Storage_Region_Bundle__c, ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__ProductOption__r.Product_Code_Type__c, ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__ProductOption__r.Storage_Region_Bundle_FrontEnd__c, AssetId,Asset.SBQQ__QuoteLine__r.SBQQ__PricebookEntryId__c, Asset.SBQQ__QuoteLine__r.SBQQ__SubscriptionBase__c, Asset.SBQQ__QuoteLine__r.SBQQ__ListPrice__c, Asset.SBQQSC__RequiredByLineItem__r.SBQQSC__Product__r.Product_level__c, ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__PricebookEntryId__c, ServiceContract.SBQQSC__RenewalTerm__c FROM Entitlement WHERE ' + whereClause;
                    //System.debug('Query: ' + Query);
                    
                    List<Entitlement> entLst = Database.query(Query.trim());
                    Date maxEnddate;
                    Integer renewalTerm = 12;
                    
                    if(entLst == null || entLst.isEmpty()){
                        if (quote.Id != null) {
                            Delete quote;
                            return null;
                        }
                    }
                    
                    //Changed from PriceBook2Id to SBQQ__QuotePricebookId__c for SF-33382
                    if(oppRec.SBQQ__QuotePricebookId__c != null){
                        mapProductPbeIds= getPriceBookEntries(oppRec.SBQQ__QuotePricebookId__c);
                    }
                    
                    Map<String, String> combinedKeyVSAssetName = new Map<String, String>();
                    Map<String, String> combinedKeyVSAssetId = new Map<String, String>();
                    
                    for(Entitlement ent: entLst){
                        if((ent.ServiceContract != null && ent.ServiceContract.SBQQSC__Quote__c != null 
                            && ent.ServiceContract.SBQQSC__Quote__r.MSP_SKUs_Count__c > 0)
                        || (ent.Renewal_Category__c  != null  && ent.Renewal_Category__c != 'Renew later')){
                            //System.debug('continueA: ' + ent.Renewal_Category__c);   
                            continue;
                        }
                        
                        if(ent.Asset != null && ent.Asset.SBQQ__CombineKey__c != null){
                            String existingassetNames = '';
                            String existingassetIds = '';
                            if(combinedKeyVSAssetName.containsKey(ent.Asset.SBQQ__CombineKey__c)){
                                existingassetNames = combinedKeyVSAssetName.get(ent.Asset.SBQQ__CombineKey__c);
                                existingassetIds = combinedKeyVSAssetId.get(ent.Asset.SBQQ__CombineKey__c);
                            }
                            if(existingassetNames != '' && !existingassetNames.contains(ent.Asset.Name)){
                                existingassetNames += ',' + ent.Asset.Name;
                                existingassetIds += ',' + ent.AssetId;
                            }else if(existingassetNames == ''){
                                existingassetNames = ent.Asset.Name;
                                existingassetIds = ent.AssetId;
                            }
                            combinedKeyVSAssetName.put(ent.Asset.SBQQ__CombineKey__c, existingassetNames);
                            combinedKeyVSAssetId.put(ent.Asset.SBQQ__CombineKey__c, existingassetIds);
                        }
                        if(ent.ContractLineItem.SBQQSC__RenewalProductId__c != null) {
                            prdIds.add(ent.ContractLineItem.SBQQSC__RenewalProductId__c);
                        }
                        //CPQ22-3347 - Start Modified logic to include max end date calculation based on csat end date
                        if(ent.ContractLineItem.enddate != null){

                            /*Date tempEndDate;

                            if(ent.ContractLineItem.New_Extended_End_Date__c != null && ent.ContractLineItem.New_Extended_End_Date__c > ent.ContractLineItem.enddate){
                                //tempEndDate = ent.ContractLineItem.New_Extended_End_Date__c;
                                tempEndDate = ent.ContractLineItem.enddate;
                            }else{
                                tempEndDate = ent.ContractLineItem.enddate;
                            }*/

                            if(maxEnddate == null){
                                maxEnddate = ent.ContractLineItem.enddate;
                            } else if(maxEnddate < ent.ContractLineItem.enddate){
                                maxEnddate = ent.ContractLineItem.enddate;
                            }
                        }
                        //CPQ22-3347 - End
                        
                        if(quote.Amended_Renewed_Service_Contract__c == ent.ServiceContractId){
                            renewalTerm = Integer.valueOf(ent.ServiceContract.SBQQSC__RenewalTerm__c);
                        }
                    }
                    
                    if(maxEndDate != null && renewalTerm != null){
                        quote.Co_Term_Date__c = maxEndDate.addMonths(renewalTerm);
                    }
                    //quote.Co_Term_Date__c = maxEndDate.addMonths(renewalTerm);
                    
                    SBQQ.TriggerControl.disable();
                    insert quote;
                    
                    //System.debug('Sumedha Primary quote update Start--> ' + quote);
                    
                    List<SBQQ__QuoteLineGroup__c> quotelinegroupList = new List<SBQQ__QuoteLineGroup__c>();
                    SBQQ__QuoteLineGroup__c qlg1 = new SBQQ__QuoteLineGroup__c();
                    qlg1.Name = System.Label.Arry_renewal_Group;
                    qlg1.Is_Renewal_Group__c = true;
                    qlg1.SBQQ__Description__c = 'DO NOT DELETE LINES FROM RENEWAL GROUP';
                    qlg1.SBQQ__Quote__c = quote.Id;
                    quotelinegroupList.add(qlg1);
                    
                    SBQQ__QuoteLineGroup__c qlg2 = new SBQQ__QuoteLineGroup__c();
                    qlg2.Name = System.Label.Arry_expansion_group;
                    qlg2.Is_Expansion_Group__c = true;
                    qlg2.SBQQ__Quote__c = quote.Id;
                    quotelinegroupList.add(qlg2);
                    insert quotelinegroupList;
                    
                    //To query on Products with Renewal Products and store it in a Map
                    List<Product2> lstRenewalProd = new List<Product2>();
                    Map<Id, Product2> mapOfRenewalProdDets = new Map<Id, Product2>();
                    if(!prdIds.isEmpty()){
                        String prodQuery = 'Select ' + prodFields + ' FROM Product2 where Id IN: prdIds';
                        lstRenewalProd = Database.query(prodQuery);
                    }
                    
                    if(!lstRenewalProd.isEmpty()){
                        for (Product2 prdObj : lstRenewalProd) {
                            mapOfRenewalProdDets.put(prdObj.Id, prdObj);
                        }
                    }
                    
                    //To break the iteration if the Entitlement has already been considered
                    Set<Id> contractLines = new Set<Id>(); 
                    
                    for(Entitlement ent: entLst){
                        //Madhura new V2 bundle start
                        if((ent.ServiceContract != null && ent.ServiceContract.SBQQSC__Quote__c != null 
                            && ent.ServiceContract.SBQQSC__Quote__r.MSP_SKUs_Count__c > 0)
                        || (ent.Renewal_Category__c  != null  && ent.Renewal_Category__c != 'Renew later')){
                            //System.debug('continueB<< ' + ent.Renewal_Category__c);   
                            continue; //Entitlements having Renewal_Category__c populated will be removed from consideration of below logic
                        }
                        if(ent.Asset == null && (ent.ContractLineItem.SBQQSC__RootId__c != null && 
                                                        ent.ContractLineItem.SBQQSC__RootId__c != '')){
                            if(contractLines.contains(ent.ContractLineItemId)){
                                continue;
                            }
                            contractLines.add(ent.ContractLineItemId);
                            //isREQuote = true;
                            if( 
                                (parentMapV2.isEmpty() || !parentMapV2.containsKey(ent.ContractLineItem.SBQQSC__RootId__c)) 
                                && ent.ContractLineItem.SBQQSC__RequiredById__c == null // Added for CPQ22-4489
                            ){
                                Integer term;
                                if(ent.ContractLineItem.Subscription_Term__c == null){
                                    term = Integer.valueOf(ent.ContractLineItem.ServiceContract.Term);
                                }else{
                                    term = Integer.valueOf(ent.ContractLineItem.Subscription_Term__c);
                                }
                                Date endDate = ent.ContractLineItem.Related_End_Date__c.addMonths(term);
                                //System.debug('RenGrpId: ' + quotelinegroupList[0].Id );
                                
                                SBQQ__QuoteLine__c v2Parent = createQuoteLines(ent, 'Ent', quote, quotelinegroupList, count);
                                
                                //extIDSFound.add(ent.ContractLineItem.SBQQSC__RootId__c+':'+quote.id);
                                //System.debug('extIDSFound A: ' + extIDSFound);
                                
                                count = count+1;
                                
                                for(ContractLines_to_QuoteLines_field_mappin__mdt eachfield: fieldmapping){
                                    if(eachfield.Data_Type__c.equalsIgnoreCase(String.valueof(QLIFields.get(eachfield.QuoteLine_field__c))) &&
                                    ent.getSObject(eachfield.Relationship__c).get(eachfield.Contractline_field__c) != null && 
                                    ent.getSObject(eachfield.Relationship__c).get(eachfield.Contractline_field__c) != ''){
                                        v2Parent.put(eachfield.QuoteLine_field__c, 
                                                                ent.getSObject(eachfield.Relationship__c).get(eachfield.Contractline_field__c));
                                    }
                                }
                                
                                //Start For Twin Field
                                for(String clifield: CLIFields.keyset()){
                                    if(QLIFields.containsKey(clifield) && QLIFields.get(clifield) == CLIFields.get(clifield) && 
                                    ent.getSObject('ContractLineItem').get(clifield) != null && 
                                                    ent.getSObject('ContractLineItem').get(clifield) != ''){
                                        v2Parent.put(clifield,ent.getSObject('ContractLineItem').get(clifield));   
                                        //System.debug('$$v2Parent B--> ' + v2Parent);
                                    }
                                }
                                
                                if(!mapOfRenewalProdDets.isEmpty()){
                                    for(String entProd : ProductFields.keyset()){
                                        //for (String keyIds : mapOfRenewalProdDets.keySet()) {
                                        if(mapOfRenewalProdDets.containsKey(ent.ContractLineItem.SBQQSC__RenewalProductId__c)) {
                                            if(QLIFields.containsKey(entProd) && 
                                                        QLIFields.get(entProd) == ProductFields.get(entProd) && 
                                            mapOfRenewalProdDets.get(ent.ContractLineItem.SBQQSC__RenewalProductId__c).get(entProd) != null 
                                            && mapOfRenewalProdDets.get(ent.ContractLineItem.SBQQSC__RenewalProductId__c).get(entProd) != ''){
                                                //System.debug('$$ff--> ');
                                                if(entProd == 'SBQQ__SubscriptionType__c'){
                                                    v2Parent.put('SBQQ__ProductSubscriptionType__c', 
                                                                    mapOfRenewalProdDets.get(ent.ContractLineItem.SBQQSC__RenewalProductId__c).get(entProd));
                                                    v2Parent.put(entProd, 
                                                                    mapOfRenewalProdDets.get(ent.ContractLineItem.SBQQSC__RenewalProductId__c).get(entProd));
                                                }else{
                                                    v2Parent.put(entProd, 
                                                                    mapOfRenewalProdDets.get(ent.ContractLineItem.SBQQSC__RenewalProductId__c).get(entProd));
                                                }                                       
                                            }
                                        }
                                    }
                                }
                                else{
                                    system.debug(LoggingLevel.DEBUG, 'Empty block 1');
                                    /***Below logic has been commented as a part of story FY25SR-2251 as this block would never be called***/
                                    /*
                                    for(String entProd: ProductFields.keyset()){
                                        //System.debug('$$rahul$4:entProd C--> ' + entProd);
                                        if(QLIFields.containsKey(entProd) && QLIFields.get(entProd) == ProductFields.get(entProd) && 
                                        ent.getSObject('Product__r').get(entProd) != null && ent.getSObject('Product__r').get(entProd) != ''){
                                            if(entProd == 'SBQQ__SubscriptionType__c'){
                                                v2Parent.put('SBQQ__ProductSubscriptionType__c', ent.getSObject('Product__r').get(entProd));
                                                v2Parent.put(entProd,ent.getSObject('Product__r').get(entProd));
                                            }else{
                                                v2Parent.put(entProd,ent.getSObject('Product__r').get(entProd));
                                            }                                       
                                        }
                                    }*/
                                }
                                if(v2Parent.SBQQ__Product__c != null && mapProductPbeIds.containsKey(v2Parent.SBQQ__Product__c)){
                                    v2Parent.SBQQ__PricebookEntryId__c = mapProductPbeIds.get(v2Parent.SBQQ__Product__c).Id;
                                    v2Parent.SBQQ__ListPrice__c = mapProductPbeIds.get(v2Parent.SBQQ__Product__c).UnitPrice;
                                    //System.debug('$$v2Parent E--> ' + v2Parent);
                                }
                                parentMapV2.put(ent.ContractLineItem.SBQQSC__RootId__c , v2Parent);
                                extIDSFoundMap.put(v2Parent.required_by_ext_Id__c , v2Parent);
                                //System.debug('IF parentMapV2: ' + parentMapV2);
                            }
                            else{
                                //System.debug('Else v2Parent: ' + ent.Id + ' , RootIdB: ' + ent.ContractLineItem.SBQQSC__RootId__c);
                                SBQQ__QuoteLine__c v2Parent1 = new SBQQ__QuoteLine__c(required_by_ext_Id__c = ent.ContractLineItem.SBQQSC__RootId__c + ':' + quote.Id);
                                Date startDate1 = ent.ContractLineItem.Related_End_Date__c.addDays(1);
                                Integer term1;
                                if(ent.ContractLineItem.Subscription_Term__c == null){
                                    term1 = Integer.valueOf(ent.ContractLineItem.ServiceContract.Term);
                                }else{
                                    term1 = Integer.valueOf(ent.ContractLineItem.Subscription_Term__c);
                                }
                                //Integer term1 = Integer.valueOf(ent.ContractLineItem.Subscription_Term__c);
                                Date endDate1 = ent.ContractLineItem.Related_End_Date__c.addMonths(term1);
                                //System.debug('inside v2 child' + ent.Name);
                                
                                SBQQ__QuoteLine__c v2Child = createQuoteLines(ent, 'Ent', quote, quotelinegroupList, count);
                                v2Child.SubscribedAssetLookup__c = ent.AssetId;
                                
                                
                                if(combinedKeyVSAssetName.containsKey(ent.Asset.SBQQ__CombineKey__c)){
                                    v2Child.SubscribedAssetNames__c = v2Child.SubscribedAssetNames__c != null?v2Child.SubscribedAssetNames__c+','+ combinedKeyVSAssetName.get(ent.Asset.SBQQ__CombineKey__c):combinedKeyVSAssetName.get(ent.Asset.SBQQ__CombineKey__c) ;
                                    v2Child.Subscribed_Asset_Name__c = v2Child.Subscribed_Asset_Name__c != null ? v2Child.Subscribed_Asset_Name__c + ',' + combinedKeyVSAssetName.get(ent.Asset.SBQQ__CombineKey__c) : combinedKeyVSAssetName.get(ent.Asset.SBQQ__CombineKey__c);
                                }
                            
                                count = count + 1;
                                //extIDSFound.add(ent.ContractLineItem.SBQQSC__RootId__c + ':' + quote.id);
                                //System.debug('extIDSFound B: ' + extIDSFound);
                                
                                for(ContractLines_to_QuoteLines_field_mappin__mdt eachfield: fieldmapping){
                                    //System.debug('$$rahul$4:eachfield--> ' + eachfield);
                                    if(eachfield.Data_Type__c.equalsIgnoreCase(String.valueof(QLIFields.get(eachfield.QuoteLine_field__c))) && 
                                    ent.getSObject(eachfield.Relationship__c).get(eachfield.Contractline_field__c) != null && 
                                    ent.getSObject(eachfield.Relationship__c).get(eachfield.Contractline_field__c) != ''){
                                        v2Child.put(eachfield.QuoteLine_field__c, 
                                                    ent.getSObject(eachfield.Relationship__c).get(eachfield.Contractline_field__c));
                                    }
                                }
                                
                                //Start For Twin Field
                                for(String clifield: CLIFields.keyset()){
                                    if(QLIFields.containsKey(clifield) && QLIFields.get(clifield) == CLIFields.get(clifield) 
                                    && ent.getSObject('ContractLineItem').get(clifield) != null && ent.getSObject('ContractLineItem').get(clifield) != ''){
                                        v2Child.put(clifield,ent.getSObject('ContractLineItem').get(clifield));   
                                    }
                                }
                                if (!mapOfRenewalProdDets.isEmpty()) {
                                    for(String entProd: ProductFields.keyset()){
                                        //for(String keyIds : mapOfRenewalProdDets.keySet()){
                                        if(mapOfRenewalProdDets.containsKey(ent.ContractLineItem.SBQQSC__RenewalProductId__c)){
                                            if(QLIFields.containsKey(entProd) && 
                                                        QLIFields.get(entProd) == ProductFields.get(entProd) && 
                                            mapOfRenewalProdDets.get(ent.ContractLineItem.SBQQSC__RenewalProductId__c).get(entProd) != null 
                                            && mapOfRenewalProdDets.get(ent.ContractLineItem.SBQQSC__RenewalProductId__c).get(entProd) != ''){
                                                //System.debug('$$ff--> ');
                                                if(entProd == 'SBQQ__SubscriptionType__c'){
                                                    v2Child.put('SBQQ__ProductSubscriptionType__c', 
                                                                mapOfRenewalProdDets.get(ent.ContractLineItem.SBQQSC__RenewalProductId__c).get(entProd));
                                                    v2Child.put(entProd, 
                                                                mapOfRenewalProdDets.get(ent.ContractLineItem.SBQQSC__RenewalProductId__c).get(entProd));
                                                    //System.debug('Sumedha $$v2Child C--> ' + v2Child);
                                                }else{
                                                    v2Child.put(entProd, 
                                                                mapOfRenewalProdDets.get(ent.ContractLineItem.SBQQSC__RenewalProductId__c).get(entProd));
                                                    //System.debug('Sumedha $$v2Child D--> ' + v2Child);
                                                }                                       
                                            }
                                        }
                                    }
                                }
                                else {
                                    system.debug(LoggingLevel.DEBUG, 'Empty block 2');
                                    /***Below logic has been commented as a part of story FY25SR-2251 as this block would never be called***/
                                    /*
                                    for(String entProd: ProductFields.keyset()){
                                        if(QLIFields.containsKey(entProd) && QLIFields.get(entProd) == ProductFields.get(entProd) && 
                                        ent.getSObject('Product__r').get(entProd) != null && ent.getSObject('Product__r').get(entProd) != ''){
                                            if(entProd == 'SBQQ__SubscriptionType__c'){
                                                v2Child.put('SBQQ__ProductSubscriptionType__c', ent.getSObject('Product__r').get(entProd));
                                                v2Child.put(entProd, ent.getSObject('Product__r').get(entProd));
                                            }else{
                                                v2Child.put(entProd, ent.getSObject('Product__r').get(entProd));  
                                            }
                                        }
                                    }*/
                                }
                                if(v2Child.SBQQ__Product__c != null && mapProductPbeIds.containsKey(v2Child.SBQQ__Product__c)){
                                    v2Child.SBQQ__PricebookEntryId__c = mapProductPbeIds.get(v2Child.SBQQ__Product__c).Id;
                                    v2Child.SBQQ__ListPrice__c = mapProductPbeIds.get(v2Child.SBQQ__Product__c).UnitPrice;
                                }
                                v2Child.putSObject('SBQQ__RequiredBy__r', v2Parent1);
                                parentMap.put(v2Child.required_by_ext_Id__c, v2Child);
                                extIDSFoundMap.put(v2Child.required_by_ext_Id__c, v2Child);
                                if (ent.ContractLineItem.SBQQSC__Product__r.License_Subtype__c != 'Add-On') {
                                    extIdvsQty.put(v2Child.required_by_ext_Id__c, ent.ContractLineItem.SBQQSC__RenewalQuantity__c);
                                }
                            }
                        }
                        //V2 bundle END
                        
                        if(ent.Asset != null){
                            if((parentMap.isEmpty() || !parentMap.containsKey(ent.Asset.SBQQ__CombineKey__c + ':' + quote.Id)) || 
                            (parentMapV2.containsKey(ent.Asset.SBQQSC__RequiredByLineItem__c))){
                                //madhura for fixing v2
                                SBQQ__QuoteLine__c v2Parent= new SBQQ__QuoteLine__c();
                                if(ent.ContractLineItem.SBQQSC__Product__r.Product_level__c != null && ent.Asset.SBQQSC__RequiredByLineItem__c != null){
                                    String val = String.Valueof(ent.Asset.SBQQSC__RequiredByLineItem__c);
                                    v2Parent.put('required_by_ext_Id__c', val + ':' + quote.Id);
                                }else{
                                    v2Parent.put('required_by_ext_Id__c',ent.Asset.SBQQ__CombineKey__c + ':' + quote.Id);
                                }
                                //Parent Product QuoteLine
                                
                                if(ent.Asset.Product2.SBQQ__SubscriptionPricing__c != 'Fixed Price' ) {  //CPQ22-4194
                                
                                SBQQ__QuoteLine__c temppar  = createQuoteLines(ent, 'AssetHardware', quote, quotelinegroupList, count);
                                temppar.SBQQ__Product__c = ent.Asset.Product2Id;
                                temppar.SBQQ__Renewal__c = true;
                                temppar.SBQQ__ListPrice__c = ent.Asset.SBQQ__QuoteLine__r.SBQQ__ListPrice__c;
                                temppar.SBQQ__RenewedAsset__c = ent.AssetId;
                                temppar.SBQQ__Existing__c = true;
                                if (combinedKeyVSAssetName != null && !combinedKeyVSAssetName.isEmpty() && 
                                        combinedKeyVSAssetName.containsKey(ent.Asset.SBQQ__CombineKey__c) && 
                                            combinedKeyVSAssetName.get(ent.Asset.SBQQ__CombineKey__c) != null) {
                                        List<String> splitStr = combinedKeyVSAssetName.get(ent.Asset.SBQQ__CombineKey__c).split(',');
                                        if (splitStr != null && !splitStr.isEmpty()) {
                                            temppar.SBQQ__Quantity__c  = splitStr.size();
                                            temppar.SBQQ__PriorQuantity__c = splitStr.size();
                                        }
                                    }
                                    else {
                                        temppar.SBQQ__Quantity__c = ent.ContractLineItem.SBQQSC__RenewalQuantity__c;
                                        temppar.SBQQ__PriorQuantity__c = ent.ContractLineItem.SBQQSC__RenewalQuantity__c;
                                    }
                                //extIDSFound.add(ent.Asset.SBQQ__CombineKey__c + ':' + quote.Id);
                                //System.debug('extIDSFound C: ' + extIDSFound);
                                //madhura for fixing v2
                                if(ent.ContractLineItem.SBQQSC__Product__r.Product_level__c != null && ent.Asset.SBQQSC__RequiredByLineItem__c != null){
                                    String val = String.Valueof(ent.Asset.SBQQSC__RequiredByLineItem__c);
                                    temppar.put('Arry_QL_reqby__c', ent.Asset.SBQQ__CombineKey__c + ':' + quote.Id);//val
                                }else{
                                    //System.debug('RootIdD: ' + ent.Asset.SBQQ__CombineKey__c);
                                    temppar.put('required_by_ext_Id__c', ent.Asset.SBQQ__CombineKey__c + ':' + quote.Id);
                                }
                                
                                if(ent.ContractLineItem.SBQQSC__Product__r.Product_level__c != null && ent.Asset != null 
                                && ent.Asset.SBQQSC__RequiredByLineItem__c != null && (ent.Asset.SBQQSC__RequiredByLineItem__r.SBQQSC__Product__r.Product_level__c == 'Hybrid Software' || ent.Asset.SBQQSC__RequiredByLineItem__r.SBQQSC__Product__r.Product_level__c == 'OnPrem')){
                                        //System.debug('test code palak :' + v2Parent);
                                        temppar.putSObject('SBQQ__RequiredBy__r', v2Parent);
                                    }
                                
                                for(String assetfld : AssetFields.keyset() ){
                                    if(QLIFields.containsKey(assetfld) && QLIFields.get(assetfld) == CLIFields.get(assetfld) && 
                                        ent.getSObject('Asset').get(assetfld)!= null && ent.getSObject('Asset').get(assetfld)!= ''){
                                            temppar.put(assetfld, ent.getSObject('Asset').get(assetfld));    
                                        }
                                }
                                
                                for(String asstProd: ProductFields.keyset()){
                                    String prodfld = 'Product2.' + asstProd;
                                    if(QLIFields.containsKey(asstProd) && QLIFields.get(asstProd) == ProductFields.get(asstProd) 
                                        && ent.getSObject('Asset').getSObject('Product2').get(asstProd) != null 
                                        && ent.getSObject('Asset').getSObject('Product2').get(asstProd) != ''){
                                            if(asstProd == 'SBQQ__SubscriptionType__c'){
                                                temppar.put('SBQQ__ProductSubscriptionType__c', ent.getSObject('Asset').getSObject('Product2').get(asstProd));
                                                temppar.put(asstProd, ent.getSObject('Asset').getSObject('Product2').get(asstProd));
                                            }else{
                                                temppar.put(asstProd, ent.getSObject('Asset').getSObject('Product2').get(asstProd));  
                                            }
                                        }
                                }
                                
                                if(temppar.SBQQ__Product__c != null && mapProductPbeIds.containsKey(temppar.SBQQ__Product__c)){
                                    temppar.SBQQ__PricebookEntryId__c = mapProductPbeIds.get(temppar.SBQQ__Product__c).Id;
                                    temppar.SBQQ__ListPrice__c = mapProductPbeIds.get(temppar.SBQQ__Product__c).UnitPrice;
                                }
                                parentMap.put(temppar.required_by_ext_Id__c, temppar);
                                extIDSFoundMap.put(temppar.required_by_ext_Id__c, temppar);
                                    
                                    if (ent.ContractLineItem.SBQQSC__Product__r.License_Subtype__c != 'Add-On') {
                                        extIdvsQty.put(temppar.required_by_ext_Id__c,temppar.SBQQ__Quantity__c);
                                    }
                                count = count + 1;
                            }
                            }
                            //Child QuoteLine
                            
                            if(childMap.isEmpty() || (!childMap.containsKey(ent.ContractLineItemId+ ':' + quote.Id) && 
                            parentMap.containsKey(ent.Asset.SBQQ__CombineKey__c + ':' + quote.Id))){
                                                        Date startDate = ent.ContractLineItem.Related_End_Date__c.addDays(1);
                                                        Integer term;
                                                        if(ent.ContractLineItem.Subscription_Term__c != null){
                                                            term = Integer.valueOf(ent.ContractLineItem.Subscription_Term__c);
                                                        }else{
                                                            term = Integer.valueOf(ent.ContractLineItem.ServiceContract.Term);
                                                        }
                                                        Date endDate = ent.ContractLineItem.Related_End_Date__c.addMonths(term);
                                                        SBQQ__QuoteLine__c temppar = new SBQQ__QuoteLine__c();
                                                        
                                                        if(ent.ContractLineItem.SBQQSC__Product__r.Product_level__c != null 
                                                            && ent.Asset.SBQQSC__RequiredByLineItem__c != null){
                                                                //System.debug('Arry_QL_reqby__c: ');
                                                                String val = String.Valueof(ent.Asset.SBQQSC__RequiredByLineItem__c);
                                                                temppar.put('required_by_ext_Id__c',ent.Asset.SBQQ__CombineKey__c+':'+quote.id);//val
                                                                //System.debug('quote.id'+quote.id);
                                                            }else{
                                                                //System.debug('RootIdE: ' + ent.Asset.SBQQ__CombineKey__c);
                                                                temppar.put('required_by_ext_Id__c',ent.Asset.SBQQ__CombineKey__c + ':' + quote.id); 
                                                            }
                                                        
                                                        /*if(ent.ContractLineItem.SBQQSC__Product__r != null && ent.ContractLineItem.SBQQSC__Product__r.SBQQ__SubscriptionTerm__c != null){
            temppar.put('SBQQ__DefaultSubscriptionTerm__c',ent.ContractLineItem.SBQQSC__Product__r.SBQQ__SubscriptionTerm__c);
            }*/
                                                        
                                                        SBQQ__QuoteLine__c child  = createQuoteLines(ent, 'Ent', quote, quotelinegroupList, count);
                                                        child.SubscribedAssetLookup__c = ent.AssetId;
                                                        
                                                        if(combinedKeyVSAssetName.containsKey(ent.Asset.SBQQ__CombineKey__c)){
                                                            child.SubscribedAssetNames__c = child.SubscribedAssetNames__c != null ? child.SubscribedAssetNames__c + ',' + combinedKeyVSAssetName.get(ent.Asset.SBQQ__CombineKey__c) : combinedKeyVSAssetName.get(ent.Asset.SBQQ__CombineKey__c);
                                                            child.Subscribed_Asset_Name__c = child.Subscribed_Asset_Name__c != null ? child.Subscribed_Asset_Name__c + ',' + combinedKeyVSAssetName.get(ent.Asset.SBQQ__CombineKey__c) : combinedKeyVSAssetName.get(ent.Asset.SBQQ__CombineKey__c);
                                                        }
                                                            
                                                        //System.debug('temppar1: ' + temppar);
                                                        child.putSObject('SBQQ__RequiredBy__r', temppar);
                                                        count = count + 1;
                                                        ////System.debug('ObjrecChildA: ' + child);
                                                        
                                                        for(ContractLines_to_QuoteLines_field_mappin__mdt eachfield: fieldmapping){
                                                            //System.debug('rahul: eachfield->' + eachfield);
                                                            if(eachfield.Data_Type__c.equalsIgnoreCase(String.valueof(QLIFields.get(eachfield.QuoteLine_field__c))) 
                                                                && ent.getSObject(eachfield.Relationship__c).get(eachfield.Contractline_field__c) != null && 
                                                                ent.getSObject(eachfield.Relationship__c).get(eachfield.Contractline_field__c) != ''){
                                                                    //System.debug('Enter for Child A');   
                                                                    child.put(eachfield.QuoteLine_field__c, 
                                                                            ent.getSObject(eachfield.Relationship__c).get(eachfield.Contractline_field__c));
                                                                }
                                                        }
                                                        
                                                        //Start For Twin Field
                                                        for(String clifield: CLIFields.keyset() ){
                                                            if(QLIFields.containsKey(clifield) && QLIFields.get(clifield) == CLIFields.get(clifield) && 
                                                                ent.getSObject('ContractLineItem').get(clifield) != null 
                                                                && ent.getSObject('ContractLineItem').get(clifield) != ''){
                                                                    //System.debug('Enter for Child B'); 
                                                                    child.put(clifield, ent.getSObject('ContractLineItem').get(clifield));
                                                                }
                                                        }
                                                        if(!mapOfRenewalProdDets.isEmpty()){
                                                            for(String entProd: ProductFields.keyset()){
                                                                //for (String keyIds : mapOfRenewalProdDets.keySet()) {
                                                                if(mapOfRenewalProdDets.containsKey(ent.ContractLineItem.SBQQSC__RenewalProductId__c)){
                                                                    if(QLIFields.containsKey(entProd) && QLIFields.get(entProd) == ProductFields.get(entProd) && 
                                                                        mapOfRenewalProdDets.get(ent.ContractLineItem.SBQQSC__RenewalProductId__c).get(entProd) != null 
                                                                        && mapOfRenewalProdDets.get(ent.ContractLineItem.SBQQSC__RenewalProductId__c).get(entProd) != ''){
                                                                            //System.debug('$$ff--> ');
                                                                            if(entProd == 'SBQQ__SubscriptionType__c'){
                                                                                child.put('SBQQ__ProductSubscriptionType__c',
                                                                                        mapOfRenewalProdDets.get(ent.ContractLineItem.SBQQSC__RenewalProductId__c).get(entProd));
                                                                                child.put(entProd, 
                                                                                        mapOfRenewalProdDets.get(ent.ContractLineItem.SBQQSC__RenewalProductId__c).get(entProd));
                                                                                //System.debug('Sumedha $$child C--> ' + child);
                                                                            }else{
                                                                                child.put(entProd, 
                                                                                        mapOfRenewalProdDets.get(ent.ContractLineItem.SBQQSC__RenewalProductId__c).get(entProd));
                                                                                //System.debug('Sumedha $$child D--> ' + child);
                                                                            }                                       
                                                                        }
                                                                }
                                                                //}
                                                            }
                                                        }
                                                        else{
                                                            system.debug(LoggingLevel.DEBUG, 'Empty block 3');
                                                            /***Below logic has been commented as a part of story FY25SR-2251 as this block would never be called***/
                                                            /*
                                                            for(String entProd: ProductFields.keyset()){
                                                                if(QLIFields.containsKey(entProd) && QLIFields.get(entProd) == ProductFields.get(entProd) && 
                                                                    ent.getSObject('Product__r').get(entProd) != null 
                                                                    && ent.getSObject('Product__r').get(entProd) != ''){
                                                                        if(entProd == 'SBQQ__SubscriptionType__c'){
                                                                            child.put('SBQQ__ProductSubscriptionType__c', 
                                                                                    ent.getSObject('Product__r').get(entProd));
                                                                            child.put(entProd, 
                                                                                    ent.getSObject('Product__r').get(entProd));
                                                                        }else{
                                                                            child.put(entProd, 
                                                                                    ent.getSObject('Product__r').get(entProd));  
                                                                        }
                                                                    }
                                                            }*/
                                                        }
                                                        
                                                        //End For Twin field
                                                        //System.debug('child1: ' + child);
                                                        if(child.SBQQ__Product__c != null && mapProductPbeIds.containsKey(child.SBQQ__Product__c)){
                                                            child.SBQQ__PricebookEntryId__c = mapProductPbeIds.get(child.SBQQ__Product__c).Id;
                                                            child.SBQQ__ListPrice__c = mapProductPbeIds.get(child.SBQQ__Product__c).UnitPrice;
                                                        }
                                                        childMap.put(child.required_by_ext_Id__c, child);
                                                        extIDSFoundMap.put(child.required_by_ext_Id__c, child);
                                                        if (ent.ContractLineItem.SBQQSC__Product__r.License_Subtype__c != 'Add-On') {
                                                            extIdvsQty.put(child.required_by_ext_Id__c, ent.ContractLineItem.SBQQSC__RenewalQuantity__c);
                                                        }
                                                        
                                                        //System.debug('PC2: ' + ent.ContractLineItem.SBQQSC__Product__r.ProductCode);
                                                        //System.debug('childMap After: ' + childMap);
                                                    }
                            //StandAlone QuoteLine
                        }
                    }
                    //System.debug('extIDSFound D: ' + extIDSFound);
                    //System.debug('childMap D: ' + childMap + ' & childMapSize: ' + childMap.size());
                    
                    if(extIDSFound != null){
                        //System.debug('childMap.keyset(): ' + childMap.keyset());
                        for(String keyTemp : childMap.keyset()){
                            if (!extIdvsQty.isEmpty() && childMap.get(keyTemp) != null && extIdvsQty.containsKey(childMap.get(keyTemp).required_by_ext_Id__c) && 
                                ((childMap.get(keyTemp).After_Conversion_Product_Level__c != null && childMap.get(keyTemp).After_Conversion_Product_Level__c == 'Hardware') || 
                                (childMap.get(keyTemp).Product_Level__c != null && childMap.get(keyTemp).Product_Level__c == 'Hardware'))) {
                                    childMap.get(keyTemp).SBQQ__Quantity__c = extIdvsQty.get(childMap.get(keyTemp).required_by_ext_Id__c);
                                    childMap.get(keyTemp).SBQQ__PriorQuantity__c = extIdvsQty.get(childMap.get(keyTemp).required_by_ext_Id__c);
                                    childMap.get(keyTemp).SBQQ__Optional__c = true;
                                }   
                            //System.debug('NullA??: ' + childMap.get(keyTemp));
                            //if(childMap.get(keyTemp).SBQQ__RequiredBy__c != null){
                            if(childMap.get(keyTemp).SBQQ__RequiredBy__r.required_by_ext_Id__c != null){
                                //System.debug('test code 2 ' + childMap.get(keyTemp).SBQQ__RequiredBy__r.required_by_ext_Id__c );
                                //System.debug('test code 4 ' + childMap.get(keyTemp).SBQQ__RequiredBy__r.Arry_QL_reqby__c );
                                
                                if(childMap.get(keyTemp).SBQQ__RequiredBy__r.required_by_ext_Id__c != null
                                && !extIDSFound.contains(childMap.get(keyTemp).SBQQ__RequiredBy__r.required_by_ext_Id__c)){
                                    childMap.get(keyTemp).putSobject('SBQQ__RequiredBy__r',null);
                                    //System.debug('childMap A: ' + childMap);
                                    //childMap.remove(keyTemp);
                                }
                                if(childMap.get(keyTemp).SBQQ__RequiredBy__r.Arry_QL_reqby__c != null 
                                && !extIDSFound.contains(childMap.get(keyTemp).SBQQ__RequiredBy__r.Arry_QL_reqby__c)){
                                    childMap.get(keyTemp).putSobject('SBQQ__RequiredBy__r',null);
                                    //System.debug('childMap A: ' + childMap);
                                    //childMap.remove(keyTemp);
                                }
                            }
                        }
                        //System.debug('test code '+qli.SBQQ__RequiredBy__r.required_by_ext_Id__c );
                        //System.debug('parentMapV2.keyset(): ' + parentMapV2.keyset());
                        for(String keyTemp: parentMapV2.keyset()){
                            if (!extIdvsQty.isEmpty() && parentMapV2.get(keyTemp) != null && extIdvsQty.containsKey(parentMapV2.get(keyTemp).required_by_ext_Id__c) && 
                                ((parentMapV2.get(keyTemp).After_Conversion_Product_Level__c != null && parentMapV2.get(keyTemp).After_Conversion_Product_Level__c == 'Hardware') || 
                                (parentMapV2.get(keyTemp).Product_Level__c != null && parentMapV2.get(keyTemp).Product_Level__c == 'Hardware'))) {
                                    parentMapV2.get(keyTemp).SBQQ__Quantity__c = extIdvsQty.get(parentMapV2.get(keyTemp).required_by_ext_Id__c);
                                    parentMapV2.get(keyTemp).SBQQ__PriorQuantity__c = extIdvsQty.get(parentMapV2.get(keyTemp).required_by_ext_Id__c);
                                    parentMapV2.get(keyTemp).SBQQ__Optional__c = true;
                                }
                            //System.debug('NullB??: ' + parentMapV2.get(keyTemp));
                            //if(parentMapV2.get(keyTemp).SBQQ__RequiredBy__c != null){
                            if(parentMapV2.get(keyTemp).SBQQ__RequiredBy__r.required_by_ext_Id__c != null){
                                if(parentMapV2.get(keyTemp).SBQQ__RequiredBy__r.required_by_ext_Id__c !=null 
                                && !extIDSFound.contains(parentMapV2.get(keyTemp).SBQQ__RequiredBy__r.required_by_ext_Id__c)){
                                    parentMapV2.get(keyTemp).putSobject('SBQQ__RequiredBy__r', null);
                                    //System.debug('parentMapV2 A: ' + parentMapV2);
                                    //parentMapV2.remove(keyTemp);
                                }
                                if(parentMapV2.get(keyTemp).SBQQ__RequiredBy__r.Arry_QL_reqby__c != null 
                                && !extIDSFound.contains(parentMapV2.get(keyTemp).SBQQ__RequiredBy__r.Arry_QL_reqby__c)){
                                    parentMapV2.get(keyTemp).putSobject('SBQQ__RequiredBy__r',null);
                                    //System.debug('parentMapV2 B: ' + parentMapV2);
                                    //parentMapV2.remove(keyTemp);
                                }
                            }
                            ////System.debug('test code '+qli.SBQQ__RequiredBy__r.required_by_ext_Id__c );
                        }
                        
                        //System.debug('parentMap.keyset(): ' + parentMap.keyset());
                        for(String keyTemp : parentMap.keyset()){
                            if (!extIdvsQty.isEmpty() && parentMap.get(keyTemp) != null && extIdvsQty.containsKey(parentMap.get(keyTemp).required_by_ext_Id__c) && 
                                ((parentMap.get(keyTemp).After_Conversion_Product_Level__c != null && parentMap.get(keyTemp).After_Conversion_Product_Level__c == 'Hardware') || 
                                (parentMap.get(keyTemp).Product_Level__c != null && parentMap.get(keyTemp).Product_Level__c == 'Hardware'))) {
                                    parentMap.get(keyTemp).SBQQ__Quantity__c = extIdvsQty.get(parentMap.get(keyTemp).required_by_ext_Id__c);
                                    parentMap.get(keyTemp).SBQQ__PriorQuantity__c = extIdvsQty.get(parentMap.get(keyTemp).required_by_ext_Id__c);
                                    parentMap.get(keyTemp).SBQQ__Optional__c = true;
                                }
                            //System.debug('NullC??: ' + parentMapV2.get(keyTemp));
                            //if(parentMap.get(keyTemp).SBQQ__RequiredBy__c != null){
                            if(parentMap.get(keyTemp).SBQQ__RequiredBy__r.required_by_ext_Id__c != null){
                                if(parentMap.get(keyTemp).SBQQ__RequiredBy__r.required_by_ext_Id__c != null 
                                && !extIDSFound.contains(parentMap.get(keyTemp).SBQQ__RequiredBy__r.required_by_ext_Id__c)){
                                    parentMap.get(keyTemp).putSobject('SBQQ__RequiredBy__r',null);
                                    //System.debug('parentMap A: ' + parentMap); 
                                    //parentMap.remove(keyTemp);
                                }
                                if(parentMap.get(keyTemp).SBQQ__RequiredBy__r.Arry_QL_reqby__c != null 
                                && !extIDSFound.contains(parentMap.get(keyTemp).SBQQ__RequiredBy__r.Arry_QL_reqby__c)){
                                    parentMap.get(keyTemp).putSobject('SBQQ__RequiredBy__r',null);
                                    //System.debug('parentMap B: ' + parentMap);
                                    //parentMap.remove(keyTemp);
                                }
                            }
                            //System.debug('test code '+qli.SBQQ__RequiredBy__r.required_by_ext_Id__c );
                        }
                    }
                    
                    if(parentMapV2.values().size() ==0 && parentMap.values().size() == 0 && 
                                            childMap.values().size() ==0){
                        //System.debug('Enter to delete Quote:' + quote);
                        Delete quote;
                        Return null;
                    }
                    
                    //System.debug('SizeC1:' + childMap.values());
                    //System.debug('SizeA:' + parentMapV2.values().size());
                    //System.debug('SizeB:' + parentMap.values().size());
                    //System.debug('SizeC:' + childMap.values().size());
                        insert parentMapV2.values();
                        for (String key : parentMap.keySet()) {
                            SBQQ__QuoteLine__c qlObj = parentMap.get(key);
                            if (qlObj.Id != null) {
                                parentMap.remove(key);
                            }
                        }
                        insert parentMap.values();

                        for (String key : childMap.keySet()) {
                            SBQQ__QuoteLine__c qlObj = childMap.get(key);
                            if (qlObj.Id != null) {
                                childMap.remove(key);
                            }
                        }
                        insert childMap.values();
        }
        catch (Exception e){
            if(quote != null){
                //System.debug('Enter to delete Quote:' + quote);
                Delete quote;
                //System.debug('Exception--->'+e.getMessage());
                Return e.getMessage();
                //Return null;
            }
        }
        //System.debug('quote.Id--->'+quote.Id);
        //integer i =1/0;
        return quote.Id;
    }

    /***********************************************************************************************************
    * Method Name          : allFields
    * @description         : Gets the records by querying all fields
    * @return              : Query to run
    * @param ObjectName
    /**********************************************************************************************************/
    public static String allFields(String ObjectName){
        List<String> fields = new List<String>(Schema.getGlobalDescribe().get(ObjectName).getDescribe().fields.getMap().keySet());
        String query  = 'SELECT ' + String.join(fields, ',') + ' FROM ' + ObjectName;
        return query;
    }
    
    /***********************************************************************************************************
    * Method Name          : getcreateablefields
    * @description         : Gets the list of fields which are not Read Only
    * @return              : List of Fields
    * @param objectName
    /**********************************************************************************************************/
    public static Map<String,Schema.DisplayType> getcreateablefields(String objectName){
        String selects = '';
        Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get(objectName.toLowerCase()).getDescribe().Fields.getMap();
        List<string> selectFields = new List<string>();
        Map<String,Schema.DisplayType> fieldMap = new Map<String,Schema.DisplayType>();
        //System.debug(objectName + ' fMap--> ' + fMap);
        
        if(fMap != null){
            if(objectName == 'SBQQ__QuoteLine__c'){
                for (Schema.SObjectField ft: fMap.values()){ // loop through all field tokens (ft)
                    Schema.DescribeFieldResult fd = ft.getDescribe(); // describe each field (fd)
                    //System.debug('fd>>'+fd.getName()+' isCreateable>>'+fd.isCreateable());
                    if(fd.isCreateable()){ // field is Accessible
                        selectFields.add(fd.getName());
                        fieldMap.put(fd.getName(),fd.getType());
                    }
                }
            }
            else{
                for(Schema.SObjectField ft: fMap.values()){ // loop through all field tokens (ft)
                    Schema.DescribeFieldResult fd = ft.getDescribe(); // describe each field (fd)
                    //System.debug('fd: ' + fd.getName() + ' isCreateable: ' + fd.isCreateable());
                    if(fd.isAccessible()){ // field is Accessible
                        selectFields.add(fd.getName());
                        fieldMap.put(fd.getName(),fd.getType());
                    }
                }
            }
        }
        //System.debug('CLifieldMap>>'+fieldMap);
        return fieldMap;
    }
    
    /***********************************************************************************************************
    * Method Name          : getPriceBookEntries
    * @description         : Get PriceBookEntries of Products
    * @return              : Map of PBEs
    * @param PriceBookId
    /**********************************************************************************************************/
    public static Map<Id,PriceBookEntry> getPriceBookEntries(Id PriceBookId){
        Map<Id,PriceBookEntry> mapProductIdPbeId = new Map<Id,PriceBookEntry>();
        for(PricebookEntry pbe: [SELECT Pricebook2Id, Product2Id, Product2.Productcode, IsActive, UnitPrice FROM PricebookEntry WHERE
                                 Pricebook2Id=: PriceBookId]){
                                     mapProductIdPbeId.put(pbe.Product2Id,pbe);
                                 }
        return mapProductIdPbeId;
    }
    
    /***********************************************************************************************************
    * Method Name          : createQuoteLines
    * @description         : Creates Quote Lines
    * @return              : Quote Line record created
    * @param ent
    * @param source
    * @param quote
    * @param quotelinegroupList
    * @param count
    /**********************************************************************************************************/
    public static SBQQ__QuoteLine__c createQuoteLines(Entitlement ent, String source, SBQQ__Quote__c quote, List<SBQQ__QuoteLineGroup__c> quotelinegroupList, Integer count){
        SBQQ__QuoteLine__c newQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Group__c = quotelinegroupList[0].Id,
            SBQQ__Number__c = count,
            PA_Quote_Type__c = 'Renewal+Expansion',
            SBQQ__StartDate__c = ent.ContractLineItem.Related_End_Date__c.addDays(1),
            PA_Payment_Option__c = ent.ContractLineItem.PA_Payment_Option__c,
            SBQQ__DefaultSubscriptionTerm__c = ent.ContractLineItem.SBQQSC__Product__r.SBQQ__SubscriptionTerm__c,                 
            /* commented as part of ITNPI-2852
           // Storage_Region_Bundle__c = 
            //ent.ContractLineItem.Storage_Region_Bundle__c!=null ? ent.ContractLineItem.Storage_Region_Bundle__c:
            //ent.ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__ProductOption__r.Storage_Region_Bundle__c!=null?
            //ent.ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__ProductOption__r.Storage_Region_Bundle__c:
            //ent.ContractLineItem.SBQQSC__Product__r.Storage_Region_Bundle__c!=null? ent.ContractLineItem.SBQQSC__Product__r.Storage_Region_Bundle__c: '',
            */
            //CPQ22-3699 Start
            Product_Code_Type__c =
            ent.ContractLineItem.Product_Code_Type__c!=null ? ent.ContractLineItem.Product_Code_Type__c :
            ent.ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__ProductOption__r.Product_Code_Type__c!=null?
            ent.ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__ProductOption__r.Product_Code_Type__c : '');
            //CPQ22-3699 End
            
            /* commented as part of ITNPI-2852
            //Storage_Region_Bundle_FrontEnd__c =
            //ent.ContractLineItem.Storage_Region_Bundle_FrontEnd__c!=null ? ent.ContractLineItem.Storage_Region_Bundle_FrontEnd__c :
            //ent.ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__ProductOption__r.Storage_Region_Bundle_FrontEnd__c!=null?
            //ent.ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__ProductOption__r.Storage_Region_Bundle_FrontEnd__c : '');
            */
        if (source == 'Ent') {
            newQuoteLine.SBQQ__Description__c = ent.ContractLineItem.SBQQSC__Product__r.Description;//ent.Asset.Product2.Description,
            //newQuoteLine.required_by_ext_Id__c = ent.ContractLineItem.SBQQSC__RootId__c + ':' + quote.Id;
            newQuoteLine.required_by_ext_Id__c = ent.ContractLineItemId+ ':' + quote.Id;
            newQuoteLine.SBQQ__SubscriptionBase__c = ent.ContractLineItem.SBQQSC__Product__r.SBQQ__SubscriptionBase__c;
            newQuoteLine.SBQQ__PricebookEntryId__c = ent.ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__PricebookEntryId__c;
        }
        /***Below logic has been commented as a part of story FY25SR-2251 as this block would never be called***/
        /*else if (source == 'Asset') {
            newQuoteLine.SBQQ__Description__c = ent.Asset.Product2.Description;
            //newQuoteLine.required_by_ext_Id__c = ent.Asset.SBQQ__CombineKey__c + ':' + quote.Id;
            newQuoteLine.required_by_ext_Id__c = ent.Asset.SBQQ__CombineKey__c + ':' + ent.Id+ ':' + quote.Id;
            newQuoteLine.SBQQ__SubscriptionBase__c = ent.Asset.Product2.SBQQ__SubscriptionBase__c;
            newQuoteLine.SBQQ__PricebookEntryId__c = ent.Asset.SBQQ__QuoteLine__r.SBQQ__PricebookEntryId__c;
        }*/
        else if (source == 'AssetHardware') {
            newQuoteLine.SBQQ__Description__c = ent.Asset.Product2.Description;
            newQuoteLine.required_by_ext_Id__c = ent.Asset.SBQQ__CombineKey__c + ':' + quote.Id;
            //newQuoteLine.required_by_ext_Id__c = ent.Asset.SBQQ__CombineKey__c + ':' + ent.Id+ ':' + quote.Id;
            newQuoteLine.SBQQ__SubscriptionBase__c = ent.Asset.Product2.SBQQ__SubscriptionBase__c;
            newQuoteLine.SBQQ__PricebookEntryId__c = ent.Asset.SBQQ__QuoteLine__r.SBQQ__PricebookEntryId__c;
            newQuoteLine.Product_Code_Type__c = ''; //CPQ22-3699
            //newQuoteLine.Storage_Region_Bundle_FrontEnd__c = '';  //CPQ22-3699
        }
        if(!extIDSFound.contains(newQuoteLine.required_by_ext_Id__c)){
            extIDSFoundMap.put(newQuoteLine.required_by_ext_Id__c,newQuoteLine);
            extIDSFound.add(newQuoteLine.required_by_ext_Id__c);
            return newQuoteLine; 
        }
            
        else{
            return extIDSFoundMap.get(newQuoteLine.required_by_ext_Id__c);
        }
    }
}