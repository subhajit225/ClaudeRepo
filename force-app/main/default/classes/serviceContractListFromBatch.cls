/*Class to auto create R+E when Sales Opportunity is created*/
Global class serviceContractListFromBatch {
    /**count */
    public static Integer count = 1;  
    public static Set<String> extIDSFound = new Set<String>();
    public static Map<String, SBQQ__Quoteline__c> extIDSFoundMap = new Map<String, SBQQ__Quoteline__c>();
    
    //renewalContractsFromBatch created for ARY-682 calling from batch
    @AuraEnabled
    Webservice static String renewalContractsFromBatch(String str, String oppId,boolean isExecutingBatch){
        // system.debug('Contract Records:-->' + str);  
       //System.debug('Opportunity Id:-->'+oppId);
        List<Id> renewalId = new List<Id>();
        String quoteId ;
        List<contrctWrapper> contractList = new  List<contrctWrapper>();
        try{
            if(!string.isBlank(str)){
                contractList = (List<contrctWrapper>)System.JSON.deserialize(str,List<contrctWrapper>.class);
                system.debug('contractList:-->' + contractList[0]);
                CreateRenewalContext context = new CreateRenewalContext();
                context.masterContractId = contractList[0].Id;
                    
                for(contrctWrapper wrap: contractList){
                    renewalId.add(wrap.Id); 
                }
                List<Servicecontract> updatelist = new List<ServiceContract>();
                context.renewedContracts = [SELECT Id,ContractNumber, Expansion_Opportunity__c,Renew_to_Old_SKUs__c , SBQQSC__RenewalOpportunity__c, AccountId, 
                                            StartDate,EndDate,Term,OwnerId,SBQQSC__Opportunity__c,SBQQSC__Opportunity__r.OwnerId, SBQQSC__RenewalOpportunity__r.OwnerId FROM ServiceContract WHERE Id IN: renewalId];
                    
                Set<Id> userIds = new Set<id>();
                    
                SBQQ.TriggerControl.disable();
                for(ServiceContract scc : context.renewedContracts){
                    scc.Expansion_Opportunity__c = oppId;
                    //scc.SBQQSC__RenewalOpportunity__c = oppId;
                    updatelist.add(scc);
                    //Commented this line since we need to share the record with Renewal Oppty owner and not the Oppty Owner
                    /*if(scc.SBQQSC__Opportunity__c != null){
                        userIds.add(scc.SBQQSC__Opportunity__r.OwnerId);
                    }*/
                    if(scc.SBQQSC__RenewalOpportunity__c != null) {
                        userIds.add(scc.SBQQSC__RenewalOpportunity__r.OwnerId);
                    }
                    userIds.add(scc.OwnerId);
                }
                //context.renewedContracts[0].SBQQSC__RenewalOpportunity__c = oppId;
                //update context.renewedContracts[0];
                update updatelist;
                    
                if(!userIds.isEmpty()){
                    serviceContractList.customShareOpp(userIds,oppId);
                }
                    
                SBQQ.TriggerControl.enable();
                String jsonContext = JSON.serialize(context);
                System.debug('Show JSON:-->'+jsonContext);
                    
                TriggerHandler.bypass('OpportunityObjectTriggerHandler');
                //TriggerHandler.bypass('QuoteTriggerHandler');
                TriggerHandler.bypass('ServiceContractMain');
                TriggerHandler.bypass('SBQQ_QuoteLineTriggerHandler');
                // TriggerControls.disableQuoteTrigger = true;
                //TriggerControls.disableQuoteLineTrigger = true;
                    
                SBQQ__QuoteLineGroup__c qlg = new  SBQQ__QuoteLineGroup__c();
                System.debug(qlg);
                serviceContractList cn = new serviceContractList();
                System.debug(cn);  

                if(isExecutingBatch){
                  quoteId  = renewalCustomContractFromBatch(context.renewedContracts,oppId);
                }
                
                if (quoteId != null) {
                    System.debug('@rahul: inside if');
                    /*SBQQ__Quote__c newQ = new SBQQ__Quote__c(id = quoteId);
                    CallCalculateAPIBatch batchInstance  = new CallCalculateAPIBatch(new List<SBQQ__Quote__c>{newQ});
                    Database.executeBatch(batchInstance, 1);*/
                    
                    QuoteReader reader = new QuoteReader();
                    QuoteModel quote = reader.read(quoteId);
                    QuoteCalculator calculator = new QuoteCalculator();
                    calculator.calculate(quote, 'MyCallback');
                }
                // TriggerControls.disableQuoteTrigger = true;
                }
            }
            catch (DmlException ex) {
                throw new DmlException('Error Details : ' + ex.getDmlMessage(0));
            }  
            catch(AuraHandledException e ){
                System.debug('show error>>'+e.getMessage());
                throw new AuraHandledException('Error Details : '+e.getMessage());           
            }
            
            return quoteId;
        }

        //renewalCustomContractFromBatch ARY682 calling from batch AuotQuoteCreateBatch1
    @AuraEnabled
    Webservice static Id renewalCustomContractFromBatch(List<Servicecontract> renewallist, String oppId){
        for(Servicecontract sc : renewallist){
            System.debug(sc);
            //System.debug('number>>'+sc.ContractNumber);
        }
        //System.debug('renewallist'+renewallist+' & renewallist size: ' + renewallist.size());
        
        Integer addyears = renewallist[0].Term/12;
        Integer addyearsforEnd = renewallist[0].Term/12 + 1;
        //Date dfuture = System.today().addDays(365); Commented for Dynamic Term Logic
        Date dfuture = System.today();
        Date dpast = System.today().addDays(-90);
        String whereClause;
        List<Arry_Query_clause__mdt> whereclauseLst = Arry_Query_clause__mdt.getAll().values();
        
        Boolean isREQuote = false;
        System.debug(addyears);
        System.debug(addyearsforEnd);
        System.debug(dfuture);
        System.debug(dpast);
        System.debug(isREQuote);
        //Dynamic term logic - Added Contract_Renewal_Term__c
        Opportunity oppRec = [SELECT Id, Name, Opportunity_Sub_Type__c, OwnerId, ContactId, Pricebook2Id, SBQQ__QuotePricebookId__c, Contract_Renewal_Term__c FROM Opportunity WHERE Id =: oppId LIMIT 1 ];
        
        //Dynamic term logic Starts
        List<ContractLineItem> cliList = new List<ContractLineItem>();
        if (renewallist != null && !renewallist.isEmpty()) {
            cliList = [Select Id, EndDate from ContractLineItem where ServiceContractId IN : renewallist Order by EndDate DESC ];
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
        System.debug('-----'+dfuture);
        //Dynamic term logic Ends

        for(Arry_Query_clause__mdt mdt : whereclauseLst){
            whereClause = ' '+mdt.FieldName__c+' '+mdt.Operator__c+' '+mdt.Value__c+' AND '+whereClause;
            whereClause = whereClause.removeEND(' AND null');
            ////System.debug('show Clause'+whereClause);
        }
                                                                                                                                
        //System.debug('show Clause Final'+whereClause);
        
        Map<String,Schema.DisplayType> CLIFields = getcreateablefields('ContractLineItem');
        Map<String,Schema.DisplayType> QLIFields = getcreateablefields('SBQQ__QuoteLine__c');
        Map<String,Schema.DisplayType> AssetFields = getcreateablefields('Asset');
        Map<String,Schema.DisplayType> ProductFields = getcreateablefields('Product2');
        Map<Id,PricebookEntry> mapProductPbeIds = new Map<Id,PricebookEntry>();
        
        //Changed from PriceBook2Id to SBQQ__QuotePricebookId__c for SF-33382
        if(oppRec.SBQQ__QuotePricebookId__c != null){
            mapProductPbeIds= getPriceBookEntries(oppRec.SBQQ__QuotePricebookId__c);
        }
        
        Map < String, ContractLines_to_QuoteLines_field_mappin__mdt > mapCustomMetadataType = ContractLines_to_QuoteLines_field_mappin__mdt.getAll();
        System.debug(mapCustomMetadataType);
        String relationfield = '';
        String assetfids = '';
        //String entproductfields = '';
        String asstproductfields = '';
        String contractProductFields = '';
        String prodFields = '';
        
        for(String str : CLIFields.keySet()){
            relationfield = relationfield+','+ 'ContractLineItem.'+str;
            relationfield = relationfield.removeStart(',');
            ////System.debug('relationfield>'+relationfield);
        }
        
        for(String Astf : AssetFields.keySet()){
            assetfids = assetfids+','+ 'Asset.'+Astf;
            assetfids = assetfids.removeStart(',');
            ////System.debug('assetfids>'+assetfids);
        }
        
        for(String prodfld : ProductFields.keySet()){
            //entproductfields = entproductfields+','+'Product__r.'+prodfld;
            asstproductfields = asstproductfields+','+'Asset.Product2.'+prodfld;
            contractProductFields = contractProductFields+','+'ContractLineItem.SBQQSC__Product__r.'+prodfld;
            prodFields = prodFields+','+prodfld;
            //entproductfields = entproductfields.removeStart(',');
            asstproductfields = asstproductfields.removeStart(',');
            contractProductFields = contractProductFields.removeStart(',');
            prodFields = prodFields.removeStart(',');
        }
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
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
        
        ////System.debug('quote Insertion Start--> ');
        //quote.SBQQ__StartDate__c = renewallist[0].EndDate.addDays(1);// ARY-398
        //quote.SBQQ__EndDate__c = renewallist[0].EndDate.addDays(366);// ARY-398
        //quote.SBQQ__EndDate__c = quote.SBQQ__StartDate__c.addYears(1);
        //quote.EOL_New_Product_Earliest_Date__c = System.Today();
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
        quote.Auto_Generated_R_E_Quote__c = true; //ARY 682
        
        SBQQ.TriggerControl.disable();
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        insert quote;
        
        //System.debug(' Sumedha quote--> ' + quote);
        ////System.debug('Primary quote update Start--> ' + additionalPrimaryQuotes);
        
        List<SBQQ__QuoteLineGroup__c> quotelinegroupList = new List<SBQQ__QuoteLineGroup__c>();
        SBQQ__QuoteLineGroup__c qlg1 = new  SBQQ__QuoteLineGroup__c();
        qlg1.Name = System.Label.Arry_renewal_Group;
        qlg1.Is_Renewal_Group__c = true;
        qlg1.SBQQ__Description__c = 'DO NOT DELETE LINES FROM RENEWAL GROUP';
        qlg1.SBQQ__Quote__c = quote.id;
        quotelinegroupList.add(qlg1);
        
        SBQQ__QuoteLineGroup__c qlg2 = new  SBQQ__QuoteLineGroup__c();
        qlg2.Name = System.Label.Arry_expansion_group;
        qlg2.Is_Expansion_Group__c = true;
        qlg2.SBQQ__Quote__c = quote.id;
        quotelinegroupList.add(qlg2);
        insert quotelinegroupList;
        
        ////System.debug('Group insert end--> ' + quotelinegroupList);
        
        List<SBQQ__QuoteLine__c> quotelineListToinsert = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> quotelineListPar = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> quotelineListChild = new List<SBQQ__QuoteLine__c>();
        Map<String,SBQQ__QuoteLine__c> parentMapV2 = new Map<String,SBQQ__QuoteLine__c>();
        Map<String,SBQQ__QuoteLine__c> parentMap = new Map<String,SBQQ__QuoteLine__c>();
        Map<String,SBQQ__QuoteLine__c> childMap = new Map<String,SBQQ__QuoteLine__c>();
        System.debug(quotelineListToinsert);
        System.debug(quotelineListPar);
        System.debug(quotelineListChild);
        List<ContractLines_to_QuoteLines_field_mappin__mdt> fieldmapping = ContractLines_to_QuoteLines_field_mappin__mdt.getAll().values();
        Set<Id> prdIds = new Set<Id>();
        Map<String, Decimal> extIdvsQty = new Map<String, Decimal>();
        
        String Query = 'Select id,Name,Renewal_Category__c,Order_Service_Item__c,ServiceContract.SBQQSC__Quote__c,ServiceContract.SBQQSC__Quote__r.MSP_SKUs_Count__c,'+assetfids+','+contractProductFields+','+ asstproductfields+',ContractLineItemID ,'+relationfield+','+' ContractLineItem.ServiceContract.Term,ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__ProductOption__c,ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__ProductOption__r.Storage_Region_Bundle__c,ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__ProductOption__r.Product_Code_Type__c, ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__ProductOption__r.Storage_Region_Bundle_FrontEnd__c,AssetId,Asset.SBQQ__QuoteLine__r.SBQQ__PricebookEntryId__c,Asset.SBQQ__QuoteLine__r.SBQQ__SubscriptionBase__c,Asset.SBQQ__QuoteLine__r.SBQQ__ListPrice__c, Asset.SBQQSC__RequiredByLineItem__r.SBQQSC__Product__r.Product_level__c, ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__PricebookEntryId__c FROM Entitlement WHERE '+whereClause ;        
        //System.debug('Query>>>>'+Query);
        
        List<Entitlement> entLst = Database.query(Query);
        //System.debug('entLst: ' + entLst + ' & entLstSize: ' + entLst.size());
        if(entLst == null || entLst.isEmpty()){
            Delete quote;
            return null;
        }
        
        Map<String, String> combinedKeyVSAssetName = new Map<String, String>();
        Map<String, String> combinedKeyVSAssetId = new Map<String, String>();
        for(Entitlement ent : entLst){
            if((ent.ServiceContract != null && ent.ServiceContract.SBQQSC__Quote__c != null 
                && ent.ServiceContract.SBQQSC__Quote__r.MSP_SKUs_Count__c > 0 )
               || (ent.Renewal_Category__c  != null  && ent.Renewal_Category__c != 'Renew later')){
                   //System.debug('continue<< ' + ent.ServiceContract.SBQQSC__Quote__r.MSP_SKUs_Count__c);   
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
                    existingassetNames += ','+ent.Asset.Name;
                    existingassetIds += ','+ent.AssetId;
                }else if(existingassetNames == ''){
                    existingassetNames = ent.Asset.Name;
                    existingassetIds = ent.AssetId;
                }
                combinedKeyVSAssetName.put(ent.Asset.SBQQ__CombineKey__c, existingassetNames);
                combinedKeyVSAssetId.put(ent.Asset.SBQQ__CombineKey__c, existingassetIds);
            }
            if (ent.ContractLineItem.SBQQSC__RenewalProductId__c != null) {
                prdIds.add(ent.ContractLineItem.SBQQSC__RenewalProductId__c);
                //System.debug('Sumedha inside Reneeal->'+ent.ContractLineItem.SBQQSC__RenewalProductId__c+'---'+ent.ContractLineItemId);
            } 
            //System.debug('Sumedha inside prdIds->'+ent.ContractLineItem.SBQQSC__RenewalProductId__c+'---'+ent.ContractLineItemId);
        }
        
        //To query on Products with Renewal Products and store it in a Map
        List<Product2> lstRenewalProd = new List<Product2>();
        Map<Id, Product2> mapOfRenewalProdDets = new Map<Id, Product2>();
        if (!prdIds.isEmpty()) {
            String prodQuery = 'Select '+prodFields+ ' FROM Product2 where Id IN: prdIds';
            lstRenewalProd = Database.query(prodQuery);
        }
        
        if (!lstRenewalProd.isEmpty()) {
            for (Product2 prdObj : lstRenewalProd) {
                mapOfRenewalProdDets.put(prdObj.Id, prdObj);
                //System.debug('mapOfRenewalProdDets-->'+mapOfRenewalProdDets);
            }
            
        }
        
        //To break the iteration if the Entitlement has already been considered
        Set<Id> contractLines = new Set<Id>(); 
        
        for(Entitlement ent : entLst){
            ////System.debug('entitlement: ' + ent.ContractLineItem.SBQQSC__RootId__c);
            //Madhura new V2 bundle start
            if((ent.ServiceContract != null && ent.ServiceContract.SBQQSC__Quote__c != null 
                && ent.ServiceContract.SBQQSC__Quote__r.MSP_SKUs_Count__c > 0 )
               || (ent.Renewal_Category__c  != null  && ent.Renewal_Category__c != 'Renew later')){
                   //System.debug('continue<< ' + ent.ServiceContract.SBQQSC__Quote__r.MSP_SKUs_Count__c);   
                   continue;
               }
            if( ent.Asset == null && (ent.ContractLineItem.SBQQSC__RootId__c != null && ent.ContractLineItem.SBQQSC__RootId__c != '' ) ){
                if (contractLines.contains(ent.ContractLineItemId)) {
                    continue;
                }
                contractLines.add(ent.ContractLineItemId);
                //isREQuote = true;
                //System.debug('Inside v2Parent');
                if( (parentMapV2.isEmpty() ||  !parentMapV2.containsKey(ent.ContractLineItem.SBQQSC__RootId__c))){
                    Integer term;
                    if(ent.ContractLineItem.Subscription_Term__c == null){
                        term = Integer.valueOf(ent.ContractLineItem.ServiceContract.Term);
                    }else{
                        term = Integer.valueOf(ent.ContractLineItem.Subscription_Term__c);
                    }
                    //System.debug('$$term--> ' + term);
                    Date endDate = ent.ContractLineItem.Related_End_Date__c.addMonths(term);
                    System.debug(endDate);
                    SBQQ__QuoteLine__c v2Parent = createQuoteLines(ent, 'Ent', quote, quotelinegroupList, count);
                    System.debug('v2Parent New--'+v2Parent);
                    
                    //extIDSFound.add(ent.ContractLineItem.SBQQSC__RootId__c+':'+quote.id);
                    count = count+1;
                    
                    for(ContractLines_to_QuoteLines_field_mappin__mdt eachfield : fieldmapping){
                        //System.debug('$$rahul$4:eachfield--> ' + eachfield);
                        if(eachfield.Data_Type__c.equalsIgnoreCase(String.valueof(QLIFields.get(eachfield.QuoteLine_field__c))) &&
                           ent.getSObject(eachfield.Relationship__c).get(eachfield.Contractline_field__c) != null && 
                           ent.getSObject(eachfield.Relationship__c).get(eachfield.Contractline_field__c) != ''){
                               v2Parent.put(eachfield.QuoteLine_field__c,ent.getSObject(eachfield.Relationship__c).get(eachfield.Contractline_field__c));
                           }
                    }
                    
                    //Start For Twin Field
                    for(String clifield : CLIFields.keyset()){
                        //System.debug('$$rahul$4:clifield--> ' + clifield);
                        if(QLIFields.containsKey(clifield) && QLIFields.get(clifield) == CLIFields.get(clifield) && 
                           ent.getSObject('ContractLineItem').get(clifield) != null && ent.getSObject('ContractLineItem').get(clifield) != ''){
                               v2Parent.put(clifield,ent.getSObject('ContractLineItem').get(clifield));   
                               
                           }
                    }
                    
                    if (!mapOfRenewalProdDets.isEmpty()) {
                        for(String entProd : ProductFields.keyset()){
                            //for (String keyIds : mapOfRenewalProdDets.keySet()) {
                            if (mapOfRenewalProdDets.containsKey(ent.ContractLineItem.SBQQSC__RenewalProductId__c)) {
                                if(QLIFields.containsKey(entProd) && QLIFields.get(entProd) == ProductFields.get(entProd) && 
                                   mapOfRenewalProdDets.get(ent.ContractLineItem.SBQQSC__RenewalProductId__c).get(entProd) != null && mapOfRenewalProdDets.get(ent.ContractLineItem.SBQQSC__RenewalProductId__c).get(entProd) != ''){
                                       //System.debug('$$ff--> ');
                                       if(entProd == 'SBQQ__SubscriptionType__c'){
                                           v2Parent.put('SBQQ__ProductSubscriptionType__c',mapOfRenewalProdDets.get(ent.ContractLineItem.SBQQSC__RenewalProductId__c).get(entProd));
                                           v2Parent.put(entProd,mapOfRenewalProdDets.get(ent.ContractLineItem.SBQQSC__RenewalProductId__c).get(entProd));
                                           //System.debug('Sumedha $$v2Parent C--> ' + v2Parent);
                                       }else{
                                           v2Parent.put(entProd,mapOfRenewalProdDets.get(ent.ContractLineItem.SBQQSC__RenewalProductId__c).get(entProd));
                                           //System.debug('Sumedha $$v2Parent D--> ' + v2Parent);
                                       }                                       
                                   }
                                
                            }
                            // }
                        }
                    }
                    else{
                        for(String entProd : ProductFields.keyset()){
                            //System.debug('$$rahul$4:entProd--> ' + entProd);
                            if(QLIFields.containsKey(entProd) && QLIFields.get(entProd) == ProductFields.get(entProd) && 
                               ent.getSObject('Product__r').get(entProd) != null && ent.getSObject('Product__r').get(entProd) != ''){
                                   if(entProd == 'SBQQ__SubscriptionType__c'){
                                       v2Parent.put('SBQQ__ProductSubscriptionType__c',ent.getSObject('Product__r').get(entProd));
                                       v2Parent.put(entProd,ent.getSObject('Product__r').get(entProd));
                                   }else{
                                       v2Parent.put(entProd,ent.getSObject('Product__r').get(entProd));  
                                   }                                       
                               }
                        }
                    }
                    if(v2Parent.SBQQ__Product__c != null && mapProductPbeIds.containsKey(v2Parent.SBQQ__Product__c)){
                        v2Parent.SBQQ__PricebookEntryId__c = mapProductPbeIds.get(v2Parent.SBQQ__Product__c).Id;
                        v2Parent.SBQQ__ListPrice__c = mapProductPbeIds.get(v2Parent.SBQQ__Product__c).UnitPrice;
                    }
                    parentMapV2.put(ent.ContractLineItem.SBQQSC__RootId__c , v2Parent);
                    extIDSFoundMap.put(v2Parent.required_by_ext_Id__c , v2Parent);
                }
                else{
                    SBQQ__QuoteLine__c  v2Parent1 = new SBQQ__QuoteLine__c(required_by_ext_Id__c = ent.ContractLineItem.SBQQSC__RootId__c+':'+quote.id);
                    Integer term1;
                    if(ent.ContractLineItem.Subscription_Term__c == null){
                        term1 = Integer.valueOf(ent.ContractLineItem.ServiceContract.Term);
                    }else{
                        term1 = Integer.valueOf(ent.ContractLineItem.Subscription_Term__c);
                    }
                    //System.debug('$$term1--> ' + term1);
                    //Integer term1 = Integer.valueOf(ent.ContractLineItem.Subscription_Term__c);
                    Date endDate1 = ent.ContractLineItem.Related_End_Date__c.addMonths(term1);
                    //System.debug('inside v2 child'+ent.Name);
                    System.debug(endDate1);
                    
                    SBQQ__QuoteLine__c v2Child = createQuoteLines(ent, 'Ent', quote, quotelinegroupList, count);
                    v2Child.SubscribedAssetLookup__c = ent.AssetId;
                    System.debug('v2Child new ---'+v2Child);
                    
                    if(combinedKeyVSAssetName.containsKey(ent.Asset.SBQQ__CombineKey__c)){
                        v2Child.SubscribedAssetNames__c = v2Child.SubscribedAssetNames__c != null?v2Child.SubscribedAssetNames__c+','+ combinedKeyVSAssetName.get(ent.Asset.SBQQ__CombineKey__c):combinedKeyVSAssetName.get(ent.Asset.SBQQ__CombineKey__c) ;
                        v2Child.Subscribed_Asset_Name__c = v2Child.Subscribed_Asset_Name__c != null ? v2Child.Subscribed_Asset_Name__c + ',' + combinedKeyVSAssetName.get(ent.Asset.SBQQ__CombineKey__c) : combinedKeyVSAssetName.get(ent.Asset.SBQQ__CombineKey__c);
                    }
                    
                    count = count+1;
                    //extIDSFound.add(ent.ContractLineItem.SBQQSC__RootId__c+':'+quote.id);
                    for(ContractLines_to_QuoteLines_field_mappin__mdt eachfield : fieldmapping){
                        //System.debug('$$rahul$4:eachfield--> ' + eachfield);
                        if(eachfield.Data_Type__c.equalsIgnoreCase(String.valueof(QLIFields.get(eachfield.QuoteLine_field__c))) && 
                           ent.getSObject(eachfield.Relationship__c).get(eachfield.Contractline_field__c) != null && 
                           ent.getSObject(eachfield.Relationship__c).get(eachfield.Contractline_field__c) != ''){
                               v2Child.put(eachfield.QuoteLine_field__c,ent.getSObject(eachfield.Relationship__c).get(eachfield.Contractline_field__c));
                           }
                    }
                    
                    //Start For Twin Field
                    for(String clifield : CLIFields.keyset() ){
                        //System.debug('$$rahul$4:clifield--> ' + clifield);
                        if(QLIFields.containsKey(clifield) && QLIFields.get(clifield) == CLIFields.get(clifield) && ent.getSObject('ContractLineItem').get(clifield) != null && ent.getSObject('ContractLineItem').get(clifield) != ''){
                            v2Child.put(clifield,ent.getSObject('ContractLineItem').get(clifield));   
                        }
                    }
                    if (!mapOfRenewalProdDets.isEmpty()) {
                        for(String entProd : ProductFields.keyset()){
                            //for (String keyIds : mapOfRenewalProdDets.keySet()) {
                            if (mapOfRenewalProdDets.containsKey(ent.ContractLineItem.SBQQSC__RenewalProductId__c)) {
                                if(QLIFields.containsKey(entProd) && QLIFields.get(entProd) == ProductFields.get(entProd) && 
                                   mapOfRenewalProdDets.get(ent.ContractLineItem.SBQQSC__RenewalProductId__c).get(entProd) != null && mapOfRenewalProdDets.get(ent.ContractLineItem.SBQQSC__RenewalProductId__c).get(entProd) != ''){
                                       //System.debug('$$ff--> ');
                                       if(entProd == 'SBQQ__SubscriptionType__c'){
                                           v2Child.put('SBQQ__ProductSubscriptionType__c',mapOfRenewalProdDets.get(ent.ContractLineItem.SBQQSC__RenewalProductId__c).get(entProd));
                                           v2Child.put(entProd,mapOfRenewalProdDets.get(ent.ContractLineItem.SBQQSC__RenewalProductId__c).get(entProd));
                                           //System.debug('Sumedha $$v2Child C--> ' + v2Child);
                                       }else{
                                           v2Child.put(entProd,mapOfRenewalProdDets.get(ent.ContractLineItem.SBQQSC__RenewalProductId__c).get(entProd));
                                           //System.debug('Sumedha $$v2Child D--> ' + v2Child);
                                       }                                       
                                   }
                                
                            }
                            //}
                            
                        }
                        
                        
                    }
                    else {
                        for(String entProd : ProductFields.keyset()){
                            //System.debug('$$rahul$4:entProd--> ' + entProd);
                            if(QLIFields.containsKey(entProd) && QLIFields.get(entProd) == ProductFields.get(entProd) && 
                               ent.getSObject('Product__r').get(entProd) != null && ent.getSObject('Product__r').get(entProd) != ''){
                                   if(entProd == 'SBQQ__SubscriptionType__c'){
                                       v2Child.put('SBQQ__ProductSubscriptionType__c',ent.getSObject('Product__r').get(entProd));
                                       v2Child.put(entProd,ent.getSObject('Product__r').get(entProd));
                                   }else{
                                       v2Child.put(entProd,ent.getSObject('Product__r').get(entProd));  
                                   }
                               }
                        }
                    }
                    v2Child.putSObject('SBQQ__RequiredBy__r' ,v2Parent1);
                    if(v2Child.SBQQ__Product__c != null && mapProductPbeIds.containsKey(v2Child.SBQQ__Product__c)){
                        v2Child.SBQQ__PricebookEntryId__c = mapProductPbeIds.get(v2Child.SBQQ__Product__c).Id;
                        v2Child.SBQQ__ListPrice__c = mapProductPbeIds.get(v2Child.SBQQ__Product__c).UnitPrice;
                    }
                    parentMap.put(v2Child.required_by_ext_Id__c, v2Child);
                    extIDSFoundMap.put(v2Child.required_by_ext_Id__c, v2Child);
                    if (ent.ContractLineItem.SBQQSC__Product__r.License_Subtype__c != 'Add-On') {
                        extIdvsQty.put(v2Child.required_by_ext_Id__c, ent.ContractLineItem.SBQQSC__RenewalQuantity__c);
                   }
                }
            }
            //V2 bundle END
            
            if(ent.Asset != null){
                //System.debug('parentMap: ' + parentMap);
                //System.debug('RBLI: ' + ent.Asset.SBQQSC__RequiredByLineItem__c);
                //System.debug('CKey: ' + ent.Asset.SBQQ__CombineKey__c);
                //System.debug('ContainsA?: ' + parentMap.containsKey(ent.Asset.SBQQ__CombineKey__c));
                //System.debug('ContainsB?: ' + parentMapV2.containsKey(ent.Asset.SBQQSC__RequiredByLineItem__c));
                
                if((parentMap.isEmpty() || !parentMap.containsKey(ent.Asset.SBQQ__CombineKey__c + ':' + quote.Id)) || 
                   (parentMapV2.containsKey(ent.Asset.SBQQSC__RequiredByLineItem__c))){
                       //madhura for fixing v2
                       //System.debug('EntIdA: ' + ent.Id);
                       
                       SBQQ__QuoteLine__c  v2Parent= new SBQQ__QuoteLine__c();
                       if(ent.ContractLineItem.SBQQSC__Product__r.Product_level__c != null && ent.Asset.SBQQSC__RequiredByLineItem__c != null){
                           String val = String.Valueof(ent.Asset.SBQQSC__RequiredByLineItem__c);
                           //System.debug('test code palak 1 '+val+':'+quote.id);
                           v2Parent.put('required_by_ext_Id__c',val+':'+quote.id);
                       }else{
                           //System.debug('test code palak 2 '+ent.Asset.SBQQ__CombineKey__c+':'+quote.id);
                           v2Parent.put('required_by_ext_Id__c',ent.Asset.SBQQ__CombineKey__c+':'+quote.id);
                       }
                       //Parent Product QuoteLine
                       ////System.debug('PC1: ' + ent.ContractLineItem.SBQQSC__Product__r.ProductCode);
                       //System.debug('v2Parent After: ' + v2Parent);
                       //System.debug('Term: ' + ent.ContractLineItem.SBQQSC__Product__r.SBQQ__SubscriptionTerm__c);
                       
                       SBQQ__QuoteLine__c temppar  = createQuoteLines(ent, 'AssetHardware', quote, quotelinegroupList, count);
                       temppar.SBQQ__Product__c = ent.Asset.Product2Id;
                       temppar.SBQQ__Renewal__c = true;
                       temppar.SBQQ__ListPrice__c = ent.Asset.SBQQ__QuoteLine__r.SBQQ__ListPrice__c;
                       temppar.SBQQ__RenewedAsset__c = ent.AssetId;
                       temppar.SBQQ__Existing__c = true;
                        if (combinedKeyVSAssetName != null && !combinedKeyVSAssetName.isEmpty() && 
                        combinedKeyVSAssetName.containsKey(ent.Asset.SBQQ__CombineKey__c) && combinedKeyVSAssetName.get(ent.Asset.SBQQ__CombineKey__c) != null) {
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

                       //extIDSFound.add(ent.Asset.SBQQ__CombineKey__c+':'+quote.id);
                       //madhura for fixing v2
                       if(ent.ContractLineItem.SBQQSC__Product__r.Product_level__c != null && ent.Asset.SBQQSC__RequiredByLineItem__c != null){
                           String val = String.Valueof(ent.Asset.SBQQSC__RequiredByLineItem__c);
                           System.debug(val);
                           temppar.put('Arry_QL_reqby__c',ent.Asset.SBQQ__CombineKey__c+':'+quote.id);
                       }else{
                           temppar.put('required_by_ext_Id__c',ent.Asset.SBQQ__CombineKey__c+':'+quote.id);
                       }
                       
                       if(ent.ContractLineItem.SBQQSC__Product__r.Product_level__c != null && ent.Asset != null  && ent.Asset.SBQQSC__RequiredByLineItem__c != null && (ent.Asset.SBQQSC__RequiredByLineItem__r.SBQQSC__Product__r.Product_level__c == 'Hybrid Software' || ent.Asset.SBQQSC__RequiredByLineItem__r.SBQQSC__Product__r.Product_level__c == 'OnPrem')){
                           //System.debug('test code palak :'+v2Parent);
                           temppar.putSObject('SBQQ__RequiredBy__r' ,v2Parent);
                       }
                       
                       for(String assetfld : AssetFields.keyset() ){
                           //System.debug('rahul: assetfld->' + assetfld);
                           if(QLIFields.containsKey(assetfld) && QLIFields.get(assetfld) == CLIFields.get(assetfld) && 
                              ent.getSObject('Asset').get(assetfld)!= null && ent.getSObject('Asset').get(assetfld)!= ''){
                                  temppar.put(assetfld,ent.getSObject('Asset').get(assetfld));    
                              }
                       }
                       
                       for(String asstProd : ProductFields.keyset()){
                           //System.debug('rahul: asstProd->' + asstProd);
                           String prodfld = 'Product2.'+asstProd;
                           System.debug(prodfld);
                           if(QLIFields.containsKey(asstProd) && QLIFields.get(asstProd) == ProductFields.get(asstProd) && ent.getSObject('Asset').getSObject('Product2').get(asstProd) != null && ent.getSObject('Asset').getSObject('Product2').get(asstProd) != ''){
                               if(asstProd == 'SBQQ__SubscriptionType__c'){
                                   temppar.put('SBQQ__ProductSubscriptionType__c',ent.getSObject('Asset').getSObject('Product2').get(asstProd));
                                   temppar.put(asstProd,ent.getSObject('Asset').getSObject('Product2').get(asstProd));
                               }else{
                                   temppar.put(asstProd,ent.getSObject('Asset').getSObject('Product2').get(asstProd));  
                               }
                           }
                       }
                       //System.debug('temppar: ' + temppar);
                       if(temppar.SBQQ__Product__c != null && mapProductPbeIds.containsKey(temppar.SBQQ__Product__c)){
                           temppar.SBQQ__PricebookEntryId__c = mapProductPbeIds.get(temppar.SBQQ__Product__c).Id;
                           temppar.SBQQ__ListPrice__c = mapProductPbeIds.get(temppar.SBQQ__Product__c).UnitPrice;
                       }
                       parentMap.put(temppar.required_by_ext_Id__c, temppar);
                       extIDSFoundMap.put(temppar.required_by_ext_Id__c, temppar);
                        if (ent.ContractLineItem.SBQQSC__Product__r.License_Subtype__c != 'Add-On') {
                            extIdvsQty.put(temppar.required_by_ext_Id__c,temppar.SBQQ__Quantity__c);
                        }
                       count = count+1;
                       //System.debug('parentMap After: ' + parentMap);
                   }
                
                //Child QuoteLine
                /*//System.debug('childMap: ' + childMap);
//System.debug('String1: ' + (ent.Name+ent.Asset.SBQQ__CombineKey__c));
//System.debug('ContainsC?: ' + childMap.containsKey(ent.Name+ent.Asset.SBQQ__CombineKey__c));
//System.debug('CKey1: ' + ent.Asset.SBQQ__CombineKey__c);
//System.debug('ContainsD?: ' + parentMap.containsKey(ent.Asset.SBQQ__CombineKey__c));*/
                
                if(childMap.isEmpty() || (!childMap.containsKey(ent.ContractLineItemId+ ':' + quote.Id) && 
                                          parentMap.containsKey(ent.Asset.SBQQ__CombineKey__c + ':' + quote.Id))){
                                              ////System.debug('Inside Child');
                                              //System.debug('EntIdB: ' + ent.Id);
                                              Integer term;
                                              if(ent.ContractLineItem.Subscription_Term__c != null){
                                                  term = Integer.valueOf(ent.ContractLineItem.Subscription_Term__c);
                                              }else{
                                                  term = Integer.valueOf(ent.ContractLineItem.ServiceContract.Term);
                                              }
                                              
                                              Date endDate = ent.ContractLineItem.Related_End_Date__c.addMonths(term);
                                              System.debug(endDate);
                                              SBQQ__QuoteLine__c temppar = new SBQQ__QuoteLine__c();
                                              
                                              if(ent.ContractLineItem.SBQQSC__Product__r.Product_level__c != null && ent.Asset.SBQQSC__RequiredByLineItem__c != null){
                                                  String val = String.Valueof(ent.Asset.SBQQSC__RequiredByLineItem__c);
                                                  System.debug(val);
                                                  temppar.put('Arry_QL_reqby__c',ent.Asset.SBQQ__CombineKey__c+':'+quote.id);
                                              }else{
                                                  temppar.put('required_by_ext_Id__c',ent.Asset.SBQQ__CombineKey__c+':'+quote.id); 
                                              }
                                              
                                              /*if(ent.ContractLineItem.SBQQSC__Product__r != null && ent.ContractLineItem.SBQQSC__Product__r.SBQQ__SubscriptionTerm__c != null){
temppar.put('SBQQ__DefaultSubscriptionTerm__c',ent.ContractLineItem.SBQQSC__Product__r.SBQQ__SubscriptionTerm__c);
}*/
                                              
                                              SBQQ__QuoteLine__c child  = createQuoteLines(ent, 'Ent', quote, quotelinegroupList, count);
                                            child.SubscribedAssetLookup__c = ent.AssetId;
                                            System.debug('child New-->'+child);
                                              
                                              if(combinedKeyVSAssetName.containsKey(ent.Asset.SBQQ__CombineKey__c)){
                                                child.SubscribedAssetNames__c = child.SubscribedAssetNames__c != null ? child.SubscribedAssetNames__c + ',' + combinedKeyVSAssetName.get(ent.Asset.SBQQ__CombineKey__c) : combinedKeyVSAssetName.get(ent.Asset.SBQQ__CombineKey__c);
                                                child.Subscribed_Asset_Name__c = child.Subscribed_Asset_Name__c != null ? child.Subscribed_Asset_Name__c + ',' + combinedKeyVSAssetName.get(ent.Asset.SBQQ__CombineKey__c) : combinedKeyVSAssetName.get(ent.Asset.SBQQ__CombineKey__c);
                                              }
                                              
                                              //System.debug('temppar1: ' + temppar);
                                              child.putSObject('SBQQ__RequiredBy__r' ,temppar);
                                              count = count+1;
                                              
                                              for(ContractLines_to_QuoteLines_field_mappin__mdt eachfield : fieldmapping){
                                                  //System.debug('rahul: eachfield->' + eachfield);
                                                  if(eachfield.Data_Type__c.equalsIgnoreCase(String.valueof(QLIFields.get(eachfield.QuoteLine_field__c))) && ent.getSObject(eachfield.Relationship__c).get(eachfield.Contractline_field__c) != null && ent.getSObject(eachfield.Relationship__c).get(eachfield.Contractline_field__c) != ''){
                                                      child.put(eachfield.QuoteLine_field__c,ent.getSObject(eachfield.Relationship__c).get(eachfield.Contractline_field__c));
                                                  }
                                              }
                                              
                                              //Start For Twin Field
                                              for(String clifield : CLIFields.keyset() ){
                                                  //System.debug('rahul: clifield->' + clifield);
                                                  if(QLIFields.containsKey(clifield) && QLIFields.get(clifield) == CLIFields.get(clifield) && 
                                                     ent.getSObject('ContractLineItem').get(clifield) != null && ent.getSObject('ContractLineItem').get(clifield) != ''){
                                                         child.put(clifield,ent.getSObject('ContractLineItem').get(clifield));
                                                     }
                                              }
                                              if (!mapOfRenewalProdDets.isEmpty()) {
                                                  for(String entProd : ProductFields.keyset()){
                                                      //for (String keyIds : mapOfRenewalProdDets.keySet()) {
                                                      if (mapOfRenewalProdDets.containsKey(ent.ContractLineItem.SBQQSC__RenewalProductId__c)) {
                                                          if(QLIFields.containsKey(entProd) && QLIFields.get(entProd) == ProductFields.get(entProd) && 
                                                             mapOfRenewalProdDets.get(ent.ContractLineItem.SBQQSC__RenewalProductId__c).get(entProd) != null && mapOfRenewalProdDets.get(ent.ContractLineItem.SBQQSC__RenewalProductId__c).get(entProd) != ''){
                                                                 //System.debug('$$ff--> ');
                                                                 if(entProd == 'SBQQ__SubscriptionType__c'){
                                                                     child.put('SBQQ__ProductSubscriptionType__c',mapOfRenewalProdDets.get(ent.ContractLineItem.SBQQSC__RenewalProductId__c).get(entProd));
                                                                     child.put(entProd,mapOfRenewalProdDets.get(ent.ContractLineItem.SBQQSC__RenewalProductId__c).get(entProd));
                                                                     //System.debug('Sumedha $$child C--> ' + child);
                                                                 }else{
                                                                     child.put(entProd,mapOfRenewalProdDets.get(ent.ContractLineItem.SBQQSC__RenewalProductId__c).get(entProd));
                                                                     //System.debug('Sumedha $$child D--> ' + child);
                                                                 }                                       
                                                             }
                                                          
                                                      }
                                                      //}
                                                      
                                                  }
                                                  
                                                  
                                              }
                                              
                                              else{
                                                  for(String entProd : ProductFields.keyset()){
                                                      //System.debug('rahul: entProd->' + entProd);
                                                      if(QLIFields.containsKey(entProd) && QLIFields.get(entProd) == ProductFields.get(entProd) && 
                                                         ent.getSObject('Product__r').get(entProd) != null && ent.getSObject('Product__r').get(entProd) != ''){
                                                             if(entProd == 'SBQQ__SubscriptionType__c'){
                                                                 child.put('SBQQ__ProductSubscriptionType__c',ent.getSObject('Product__r').get(entProd));
                                                                 child.put(entProd,ent.getSObject('Product__r').get(entProd));
                                                             }else{
                                                                 child.put(entProd,ent.getSObject('Product__r').get(entProd));  
                                                             }
                                                         }
                                                  }
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
                                              ////System.debug('PC2: ' + ent.ProdContractLineItem.SBQQSC__Product__r.ProductCode);
                                              //System.debug('childMap After: ' + childMap);
                                              
                                          }
                //StandAlone QuoteLine
            }
        }
        
        
        if(extIDSFound != null){
            for(String keyTemp : childMap.keyset()){
                    if (!extIdvsQty.isEmpty() && childMap.get(keyTemp) != null && extIdvsQty.containsKey(childMap.get(keyTemp).required_by_ext_Id__c) && 
                        ((childMap.get(keyTemp).After_Conversion_Product_Level__c != null && childMap.get(keyTemp).After_Conversion_Product_Level__c == 'Hardware') || 
                         (childMap.get(keyTemp).Product_Level__c != null && childMap.get(keyTemp).Product_Level__c == 'Hardware'))) {
                    childMap.get(keyTemp).SBQQ__Quantity__c = extIdvsQty.get(childMap.get(keyTemp).required_by_ext_Id__c);
                    childMap.get(keyTemp).SBQQ__PriorQuantity__c = extIdvsQty.get(childMap.get(keyTemp).required_by_ext_Id__c);
                    childMap.get(keyTemp).SBQQ__Optional__c = true;
                }  
                if(childMap.get(keyTemp).SBQQ__RequiredBy__r.required_by_ext_Id__c != null){
                    //System.debug('test code 2'+childMap.get(keyTemp).SBQQ__RequiredBy__r.required_by_ext_Id__c );
                    //System.debug('test code 4'+childMap.get(keyTemp).SBQQ__RequiredBy__r.Arry_QL_reqby__c );
                    
                    if(childMap.get(keyTemp).SBQQ__RequiredBy__r.required_by_ext_Id__c != null && !extIDSFound.contains(childMap.get(keyTemp).SBQQ__RequiredBy__r.required_by_ext_Id__c)){
                        childMap.get(keyTemp).putSobject('SBQQ__RequiredBy__r',null);
                        //childMap.remove(keyTemp);
                    }
                    if(childMap.get(keyTemp).SBQQ__RequiredBy__r.Arry_QL_reqby__c != null && !extIDSFound.contains(childMap.get(keyTemp).SBQQ__RequiredBy__r.Arry_QL_reqby__c)){
                        childMap.get(keyTemp).putSobject('SBQQ__RequiredBy__r',null);
                        //childMap.remove(keyTemp);
                    }
                }
                
            }
            
            // //System.debug('test code '+qli.SBQQ__RequiredBy__r.required_by_ext_Id__c );
            
            for(String keyTemp : parentMapV2.keyset()){
                    if (!extIdvsQty.isEmpty() && parentMapV2.get(keyTemp) != null && extIdvsQty.containsKey(parentMapV2.get(keyTemp).required_by_ext_Id__c) && 
                        ((parentMapV2.get(keyTemp).After_Conversion_Product_Level__c != null && parentMapV2.get(keyTemp).After_Conversion_Product_Level__c == 'Hardware') || 
                         (parentMapV2.get(keyTemp).Product_Level__c != null && parentMapV2.get(keyTemp).Product_Level__c == 'Hardware'))) {
                    parentMapV2.get(keyTemp).SBQQ__Quantity__c = extIdvsQty.get(parentMapV2.get(keyTemp).required_by_ext_Id__c);
                     parentMapV2.get(keyTemp).SBQQ__PriorQuantity__c = extIdvsQty.get(parentMapV2.get(keyTemp).required_by_ext_Id__c);
                     parentMapV2.get(keyTemp).SBQQ__Optional__c = true;
                }
                if(parentMapV2.get(keyTemp).SBQQ__RequiredBy__r.required_by_ext_Id__c != null){
                    if(parentMapV2.get(keyTemp).SBQQ__RequiredBy__r.required_by_ext_Id__c !=null && !extIDSFound.contains(parentMapV2.get(keyTemp).SBQQ__RequiredBy__r.required_by_ext_Id__c)){
                        parentMapV2.get(keyTemp).putSobject('SBQQ__RequiredBy__r',null);
                        //parentMapV2.remove(keyTemp);
                    }
                    if(parentMapV2.get(keyTemp).SBQQ__RequiredBy__r.Arry_QL_reqby__c != null && !extIDSFound.contains(parentMapV2.get(keyTemp).SBQQ__RequiredBy__r.Arry_QL_reqby__c)){
                        parentMapV2.get(keyTemp).putSobject('SBQQ__RequiredBy__r',null);
                        //parentMapV2.remove(keyTemp);
                    }
                }
                
                
                ////System.debug('test code '+qli.SBQQ__RequiredBy__r.required_by_ext_Id__c );
            }
            
            for(String keyTemp : parentMap.keyset()){
                if (!extIdvsQty.isEmpty() && parentMap.get(keyTemp) != null && extIdvsQty.containsKey(parentMap.get(keyTemp).required_by_ext_Id__c) && 
                        ((parentMap.get(keyTemp).After_Conversion_Product_Level__c != null && parentMap.get(keyTemp).After_Conversion_Product_Level__c == 'Hardware') || 
                         (parentMap.get(keyTemp).Product_Level__c != null && parentMap.get(keyTemp).Product_Level__c == 'Hardware'))) {
                    parentMap.get(keyTemp).SBQQ__Quantity__c = extIdvsQty.get(parentMap.get(keyTemp).required_by_ext_Id__c);
                    parentMap.get(keyTemp).SBQQ__PriorQuantity__c = extIdvsQty.get(parentMap.get(keyTemp).required_by_ext_Id__c);
                    parentMap.get(keyTemp).SBQQ__Optional__c = true;
                }
                if(parentMap.get(keyTemp).SBQQ__RequiredBy__r.required_by_ext_Id__c != null){
                    if(parentMap.get(keyTemp).SBQQ__RequiredBy__r.required_by_ext_Id__c != null && !extIDSFound.contains(parentMap.get(keyTemp).SBQQ__RequiredBy__r.required_by_ext_Id__c)){
                        parentMap.get(keyTemp).putSobject('SBQQ__RequiredBy__r',null);
                        //parentMap.remove(keyTemp);
                    }
                    if(parentMap.get(keyTemp).SBQQ__RequiredBy__r.Arry_QL_reqby__c != null && !extIDSFound.contains(parentMap.get(keyTemp).SBQQ__RequiredBy__r.Arry_QL_reqby__c)){
                        parentMap.get(keyTemp).putSobject('SBQQ__RequiredBy__r',null);
                        //parentMap.remove(keyTemp);
                    }
                }
                
                
                ////System.debug('test code '+qli.SBQQ__RequiredBy__r.required_by_ext_Id__c );
            }
        }
        
        if(parentMapV2.values().size() ==0 && parentMap.values().size() == 0 && childMap.values().size() ==0){
            Delete quote;
            Return null;
        }
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
        //System.debug('SizeA:' + parentMapV2.values().SIZE());
        //System.debug('SizeB:' + parentMap.values().SIZE());
        //System.debug('SizeC:' + childMap.values().SIZE());
        //System.debug('SizeA1:' + parentMapV2.values());
        //System.debug('SizeB1:' + parentMap.values());
        //System.debug('SizeC1:' + childMap.values());
        //integer i =1/0;
        return quote.Id;
    }
    
    /** getcreateablefields*/
    public static Map<String,Schema.DisplayType> getcreateablefields(String objectName){
        String selects = '';
        System.debug(selects);
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

    /** getPriceBookEntries*/
    public static Map<Id,PriceBookEntry> getPriceBookEntries(Id PriceBookId){
        Map<Id,PriceBookEntry> mapProductIdPbeId = new Map<Id,PriceBookEntry>();
        for(PricebookEntry pbe: [SELECT Pricebook2Id, Product2Id, Product2.Productcode, IsActive, UnitPrice FROM PricebookEntry WHERE
                                 Pricebook2Id=: PriceBookId]){
                                     mapProductIdPbeId.put(pbe.Product2Id,pbe);
                                 }
        //System.debug('mapProductIdPbeId-->'+mapProductIdPbeId);
        return mapProductIdPbeId;
    }
    /**createQuoteLines */
    public static SBQQ__QuoteLine__c createQuoteLines(Entitlement ent, String source, SBQQ__Quote__c quote, List<SBQQ__QuoteLineGroup__c> quotelinegroupList, Integer count){
        SBQQ__QuoteLine__c newQuoteLine = new SBQQ__QuoteLine__c(
        SBQQ__Quote__c = quote.Id,
        SBQQ__Group__c = quotelinegroupList[0].Id,
        SBQQ__Number__c = count,
        PA_Quote_Type__c = 'Renewal+Expansion',
        SBQQ__StartDate__c = ent.ContractLineItem.Related_End_Date__c.addDays(1),
        PA_Payment_Option__c = ent.ContractLineItem.PA_Payment_Option__c,
        SBQQ__DefaultSubscriptionTerm__c = ent.ContractLineItem.SBQQSC__Product__r.SBQQ__SubscriptionTerm__c,                 
       //Storage_Region_Bundle__c = 
       //ent.ContractLineItem.Storage_Region_Bundle__c!=null ? ent.ContractLineItem.Storage_Region_Bundle__c:
        //ent.ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__ProductOption__r.Storage_Region_Bundle__c!=null?
        //ent.ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__ProductOption__r.Storage_Region_Bundle__c:
        //ent.ContractLineItem.SBQQSC__Product__r.Storage_Region_Bundle__c!=null? ent.ContractLineItem.SBQQSC__Product__r.Storage_Region_Bundle__c: '',

        //CPQ22-3699 start
        Product_Code_Type__c =
        ent.ContractLineItem.Product_Code_Type__c!=null ? ent.ContractLineItem.Product_Code_Type__c :
        ent.ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__ProductOption__r.Product_Code_Type__c!=null?
        ent.ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__ProductOption__r.Product_Code_Type__c : ''
         //CPQ22-3699 end
                           
        //Storage_Region_Bundle_FrontEnd__c =
        //ent.ContractLineItem.Storage_Region_Bundle_FrontEnd__c!=null ? ent.ContractLineItem.Storage_Region_Bundle_FrontEnd__c :
        //ent.ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__ProductOption__r.Storage_Region_Bundle_FrontEnd__c!=null?
        //ent.ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__ProductOption__r.Storage_Region_Bundle_FrontEnd__c : ''
        );
        
        if (source == 'Ent') {
            newQuoteLine.SBQQ__Description__c = ent.ContractLineItem.SBQQSC__Product__r.Description;//ent.Asset.Product2.Description,
            //newQuoteLine.required_by_ext_Id__c = ent.ContractLineItem.SBQQSC__RootId__c + ':' + quote.Id;
            newQuoteLine.required_by_ext_Id__c = ent.ContractLineItemId+ ':' + quote.Id;
            newQuoteLine.SBQQ__SubscriptionBase__c = ent.ContractLineItem.SBQQSC__Product__r.SBQQ__SubscriptionBase__c;
            newQuoteLine.SBQQ__PricebookEntryId__c = ent.ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__PricebookEntryId__c;
        }
        else if (source == 'Asset') {
            newQuoteLine.SBQQ__Description__c = ent.Asset.Product2.Description;
            //newQuoteLine.required_by_ext_Id__c = ent.Asset.SBQQ__CombineKey__c + ':' + quote.Id;
            newQuoteLine.required_by_ext_Id__c = ent.Asset.SBQQ__CombineKey__c + ':' + ent.Id+ ':' + quote.Id;
            newQuoteLine.SBQQ__SubscriptionBase__c = ent.Asset.Product2.SBQQ__SubscriptionBase__c;
            newQuoteLine.SBQQ__PricebookEntryId__c = ent.Asset.SBQQ__QuoteLine__r.SBQQ__PricebookEntryId__c;
        }
        else if (source == 'AssetHardware') {
            newQuoteLine.SBQQ__Description__c = ent.Asset.Product2.Description;
            newQuoteLine.required_by_ext_Id__c = ent.Asset.SBQQ__CombineKey__c + ':' + quote.Id;
            //newQuoteLine.required_by_ext_Id__c = ent.Asset.SBQQ__CombineKey__c + ':' + ent.Id+ ':' + quote.Id;
            newQuoteLine.SBQQ__SubscriptionBase__c = ent.Asset.Product2.SBQQ__SubscriptionBase__c;
            newQuoteLine.SBQQ__PricebookEntryId__c = ent.Asset.SBQQ__QuoteLine__r.SBQQ__PricebookEntryId__c;
            newQuoteLine.Product_Code_Type__c = '';  //CPQ22-3699
            //newQuoteLine.Storage_Region_Bundle_FrontEnd__c = '';   //CPQ22-3699
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