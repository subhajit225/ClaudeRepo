public class SplitPOValidation {
    public SplitPOValidation() {}
    static List<EDI_Pricing_Difference_Threshold__mdt> thresholdData;
    public static List<PO_Stage_Errors__c> errcodes = new List<PO_Stage_Errors__c>();
    public static Boolean onlyValidate = false;
    public static Boolean isSplitCaseValidation = false;
    static Decimal threshold = 0.00;
    public static Boolean hasRcdmtIntErr = false; 
    static{
        List<EDI_Pricing_Difference_Threshold__mdt> thresholdData = [SELECT Id,DeveloperName,Threshold_Value__c
                                                                     FROM EDI_Pricing_Difference_Threshold__mdt
                                                                     LIMIT 1];
        if(thresholdData.isEmpty() == false && thresholdData[0].Threshold_Value__c != null){
            SplitPOValidation.threshold = thresholdData[0].Threshold_Value__c;
        }
    }

    public static void validateSplittedLines(List<PO_Stage__c> poList,Map<Id, PO_Stage__c> oldMap, Map<id,opportunity> oppMap){
        Set<Id> poIdsToProcess = new Set<Id>();
        Map<id,PO_Stage__c> quoteIdMap = new MAp<ID,PO_Stage__c>();
        Map<id,Integer> mapQuoteIdTotalPOStaged = new Map<id,integer>();
        Map<id,Decimal> mapQuotePOAmount = new Map<id,Decimal>();
        Map<id,PO_Stage__c> stageMap = new Map<id,PO_Stage__c> ();
        Map<Id,Set<Id>> stagePOrBundleParentMap = new Map<Id,Set<Id>>();
        Map<Id,Id> quoteLineRequiredBy= new Map<Id,Id>();
        Map<Id,Id> bundleParentStagePOMap = new Map<Id,Id>();
        Map<Id,SBQQ__QuoteLine__c> qliMap= new Map<Id,SBQQ__QuoteLine__c>();
        Set<id> validPOIds = new Set<id>();
        List<PO_Item_Stage__c> poItemsToUpdate = new List<PO_Item_Stage__c>();
        set<Id> processedPOItem = new set<Id>();
        Map<id, List<PO_Item_Stage__c>> mapOfRenwLinetoSwap = new Map<id, List<PO_Item_Stage__c>>();
        for(PO_Stage__c poStage : poList){
            if(onlyValidate ||(poStage.PO_Validation_Status__c == 'Staged' && oppMap != null 
                && oppMap.get(poStage.Opportunity__c) != null 
                && oppMap.get(poStage.Opportunity__c).Sell_to_Partner__c == null
                && poStage.Quote_number__c!=null)){

                validPOIds.add(poStage.id);
            }         
               
        }

        if(validPOIds != null && validPOIds.size()>0)
            stageMap = new Map<id,PO_Stage__c>([select id,PO_Validation_Status__c from PO_Stage__c where id in: validPOIds]);
            
        for(PO_Stage__c poStage : poList){
            PO_Stage__c oldPOStage = oldMap.get(poStage.Id);    
            if((poStage.Quote__c!=null 
                && oldPOStage.PO_Validation_Status__c != poStage.PO_Validation_Status__c && poStage.PO_Validation_Status__c == 'Staged' 
                && stageMap.get(poStage.id)!= null &&  stageMap.get(poStage.id).PO_Validation_Status__c== 'Staged')|| onlyValidate){
                poIdsToProcess.add(poStage.Id);
                if(quoteIdMap.containsKey(poStage.Quote__c)){
                    decimal POnum= quoteIdMap.get(poStage.Quote__c).Expected_number_of_POs__c;
                    isSplitCaseValidation = POnum >1?true:false;
                    if(POnum<=poStage.Expected_number_of_POs__c)
                        quoteIdMap.put(poStage.Quote__c,poStage);
                }else{
                    isSplitCaseValidation = poStage.Expected_number_of_POs__c >1?true:false;
                    quoteIdMap.put(poStage.Quote__c,poStage);
                }
            }
        }

        //Query All quotes with related PO Stage & line items.
        // From related PO Staged validate if no. of PO expected and recieved are same
        
        Map<id,SBQQ__Quote__c> quoteMap = new Map<id,SBQQ__Quote__c>();
        if(quoteIdMap != null && quoteIdMap.size()>0){
            String quoteQuery = 'select id,SBQQ__NetAmount__c,SBQQ__Primary__c,SBQQ__Status__c,SBQQ__Opportunity2__r.StageName,SBQQ__Account__r.Name,(select id, TotalAmount__c ,Account_Name__c,Name from Stage_PO__r where PO_Validation_Status__c=\'Staged\'';
            quoteQuery += onlyValidate?' OR PO_Internal_Validation_Status__c = \'Internal Failure\'':'';
            quoteQuery +='),(select Id,SBQQ__Group__r.Name,Special_Program__c,SBQQ__Product__r.Product_Type__c,Line_Type__c,SBQQ__Quote__c, SBQQ__NetTotal__c,SBQQ__NetPrice__c,SBQQ__ProductCode__c, SBQQ__Quantity__c, SBQQ__ListPrice__c, SBQQ__SubscriptionTerm__c, SBQQ__Product__r.Product_Subtype__c,SBQQ__Product__r.SBQQ__ExcludeFromOpportunity__c,SBQQ__Product__r.Appliance_Model_HW__c,SBQQ__Product__r.SBQQ__Optional__c,SBQQ__RenewedAsset__c,SBQQ__Quote__r.SBQQ__Type__c,Name,SBQQ__RequiredBy__c,SBQQ__RequiredBy__r.Name,SBQQ__RequiredBy__r.SBQQ__Existing__c,SBQQ__Bundle__c,SBQQ__Existing__c,SBQQ__UpgradedAsset__c,SBQQ__Quote__r.SBQQ__Opportunity2__r.Distributor_Lookup__r.EDI_DISTI_ID__c,SBQQ__Renewal__c,SBQQ__EffectiveQuantity__c from SBQQ__LineItems__r where SBQQ__Group__r.Name != \'Disposition Quote\' order by SBQQ__RequiredBy__c,SBQQ__Quantity__c DESC NULLS FIRST ) from SBQQ__Quote__c ';
            quoteQuery += ' where id in (\''+String.join(new List<Id>(quoteIdMap.keyset()),'\',\'')+'\')';
            quoteMap = new Map<id,SBQQ__Quote__c>((List<SBQQ__Quote__c>)Database.query(quoteQuery));
        }

        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
        set<id> stagedQuoteids = new set<id>();
        for(id quoteID: quoteIdMap.keyset()){
            Integer poStagedOnQuote = quoteMap.get(quoteID) != null && quoteMap.get(quoteID).getSObjects('Stage_PO__r') != null?quoteMap.get(quoteID).getSObjects('Stage_PO__r').size():0;
            Decimal expectedNumberOFPO= quoteIdMap.get(quoteID) != null ?quoteIdMap.get(quoteID).Expected_number_of_POs__c:0;
            
            if(poStagedOnQuote == expectedNumberOFPO && expectedNumberOFPO >=1 && poStagedOnQuote != 0){
                stagedQuoteids.add(quoteID);
                mapQuoteIdTotalPOStaged.put(quoteID,poStagedOnQuote);
                if(quoteMap.get(quoteID).getSObjects('SBQQ__LineItems__r') != null){
                    quoteLines.addAll((List<SBQQ__QuoteLine__c>)quoteMap.get(quoteID).getSObjects('SBQQ__LineItems__r'));
                }
                for(PO_Stage__c pos: quoteMap.get(quoteID).getSObjects('Stage_PO__r')){
                    Decimal tempPOAmount = mapQuotePOAmount.containsKey(quoteID) ? mapQuotePOAmount.get(quoteID):0;
                    Decimal totalAmt =pos.TotalAmount__c!= null? tempPOAmount+ pos.TotalAmount__c:tempPOAmount;
                    mapQuotePOAmount.put(quoteID,totalAmt);
                }
            }
        }
         
        if(!(stagedQuoteids.size()>0))
            return;
         
         Map<string,POValidation_ErrorCode__c> validationCodes = POValidation_ErrorCode__c.getAll();
         Set<String> goProducts = new Set<String>();
         for(Product2 prod: [Select Id, Product_Subtype__c, ProductCode from Product2 where  Product_Payment_Option__c='Annual']){
            goProducts.add(prod.ProductCode);
         }
         //CreateMap key=QuoteIDProductcode value= list of stage items
         Set<String> dummyProds = Constants.DUMMY_PRODUCTS;
         Map<String,List<PO_Item_Stage__c>> mapProdCodeQuoteStageItems = new Map<String,List<PO_Item_Stage__c>>();
         Map<String,Map<String,Set<String>>> consultTravelMap = new Map<String,Map<String,Set<String>>>();
         List<PO_Item_Stage__c> allStageLines = new List<PO_Item_Stage__c>();
         Map<id,PO_Item_Stage__c> allStageLinesMap = new Map<id,PO_Item_Stage__c>();
         Map<String,String> mapPODistiName = new Map<String,String>();
         //Collect set of Quote ids
         Set<id> quoteIDs = new Set<id>();
         Map<Id, Decimal> netPriceMap = new Map<Id, Decimal>();
         String lineItemQuery = 'select Id,Type__c, Name, Stage_PO__c,Stage_PO__r.Expected_number_of_POs__c,Stage_PO__r.name,Stage_PO__r.Quote__c ,Quantity__c, UnitPrice__c, Product__c,SubscriptionTerm__c, ProductCode__c, Subscription_Term_Description__c,EDI_Line_Number__c, Buyer_Part_Number__c, Deliver_By__c, Est_Ship_Date__c, Stage_PO__r.Bill_To_Name__c, Stage_PO__r.Quote__r.SBQQ__Opportunity2__r.Distributor_Lookup__r.EDI_DISTI_ID__c,Quote_Line__c from PO_Item_Stage__c';//PRDOPS23-414 - PO-100 error for PA SKUs - added Quote_Line__c column in the query.	
         lineItemQuery += ' where ProductCode__c NOT IN :dummyProds and Stage_PO__r.Quote__c in (\''+String.join(new List<Id>(stagedQuoteids),'\',\'')+'\') and (Stage_PO__r.PO_Validation_Status__c=\'Staged\'';
         lineItemQuery  += onlyValidate?' OR Stage_PO__r.PO_Internal_Validation_Status__c = \'Internal Failure\')':')';
         lineItemQuery += ' order by Quantity__c desc ';
         List<PO_Item_Stage__c> lstOfStagePos = Database.query(lineItemQuery);
         for(PO_Item_Stage__c si: lstOfStagePos) {
                decimal tempUnitPrice=roundUpCustom(si.UnitPrice__c);
                /*if(goProducts.contains(si.ProductCode__c)){
                    netPriceMap.put(si.Id, tempUnitPrice*si.Quantity__c);
                }else
                    netPriceMap.put(si.Id, si.UnitPrice__c*si.Quantity__c);*/
                netPriceMap.put(si.Id, si.UnitPrice__c*si.Quantity__c);
                /*if(onlyValidate && si.Stage_PO__r.Expected_number_of_POs__c == 1){
                netPriceMap.put(si.Id, si.UnitPrice__c);
                }*/
                
                if(si.Stage_PO__r.Quote__c != null){
                    if(!mapPODistiName.containsKey(si.Stage_PO__r.Quote__c)){
                        mapPODistiName.put(si.Stage_PO__r.Quote__c,si.Stage_PO__r.Bill_To_Name__c);
                    }
                    //allStageLines.add(si);
                    allStageLinesMap.put(si.id,si);
                    quoteIDs.add(si.Stage_PO__r.Quote__c);
                    if((si.ProductCode__c == 'RBK-CONSULT' || si.ProductCode__c =='RBK-TRAVEL-EXPENSES')){
                        if(consultTravelMap.containsKey(si.Stage_PO__r.Quote__c)){
                            if(consultTravelMap.get(si.Stage_PO__r.Quote__c).containsKey(si.Stage_PO__c)){
                                consultTravelMap.get(si.Stage_PO__r.Quote__c).get(si.Stage_PO__c).add(si.ProductCode__c);
                            }
                            else{
                                consultTravelMap.get(si.Stage_PO__r.Quote__c).put(si.Stage_PO__c,new Set<String>{si.ProductCode__c});
                            }
                        }
                        else{
                            consultTravelMap.put(si.Stage_PO__r.Quote__c, new Map<String,Set<String>>{si.Stage_PO__c => new Set<String>{si.ProductCode__c}});
                        }
                    }
                    if(mapProdCodeQuoteStageItems.containsKey(si.ProductCode__c+si.Stage_PO__r.Quote__c))
                        mapProdCodeQuoteStageItems.get(si.ProductCode__c+si.Stage_PO__r.Quote__c).add(si);
                    else {
                            List<PO_Item_Stage__c> tempList = new list<PO_Item_Stage__c>();
                            tempList.add(si);
                            mapProdCodeQuoteStageItems.put(si.ProductCode__c+si.Stage_PO__r.Quote__c,tempList);
                    }
                }
                
            }
        
        Map<string,wrapProductCode> wrapMAp = new Map<string,wrapProductCode>();
        //Query all quote line items.
        Set<id> passedPOStageIds = new Set<ID>();
        Map<id,set<id>> QuoteExtValidPOMAp = new Map<id,set<id>>();
        Map<id,set<string>> unmatchedQuotes = new Map<id,set<string>>();
        
        //Logic for ALL ConsultSKU and travelSKU in one quote
        Map<id,Set<id>> quoteIdPOStageIDMap = new map<id,Set<id>>();
        Map<String,Map<String,String>> mapEDIBuyersPartData = new Map<String,Map<String,String>>();
        Map<Id,SBQQ__QuoteLine__c> quoteLineToCreditSKU = new Map<Id,SBQQ__QuoteLine__c>(); 
        for(SBQQ__QuoteLine__c qli: quoteLines){    
            if(/*qli.SBQQ__Quote__r.SBQQ__Opportunity2__r.Distributor_Lookup__r.EDI_DISTI_ID__c == 'ARROW' &&*/ qli.SBQQ__ProductCode__c.equalsIgnoreCase('RBK-REF-HW-CREDIT') && qli.SBQQ__RequiredBy__c != null && !quoteLineToCreditSKU.containsKey(qli.SBQQ__RequiredBy__c)){    
                quoteLineToCreditSKU.put(qli.SBQQ__RequiredBy__c,qli);  
            }   
        }   
        Map<String, Decimal> goRefreshAmt = new Map<String, Decimal>();
        for(SBQQ__QuoteLine__c qli: quoteLines){
            quoteLineRequiredBy.put(qli.Id,qli.SBQQ__RequiredBy__c);
            qliMap.put(qli.Id,qli);
            Decimal TotalPrice=0;
            Decimal TotalQuant=0;
            Decimal totalTerm =0;
            List<PO_Item_Stage__c> matchProbSI = new List<PO_Item_Stage__c>();
            boolean completeMatch = false;
            string mapKey=qli.SBQQ__ProductCode__c+''+qli.SBQQ__Quote__c;
            Decimal rubrikGoPricePerYearPerUnit=0;
            Decimal rubrikGoTermFactor =0;
            String poDistiName = '';
            String checkDistributorForStagePO = '';

            String lineType = '';
            if((qli.Special_Program__c == 'Conversion' && qli.SBQQ__Existing__c)  || (qli.SBQQ__Quote__r.SBQQ__Type__c == 'Renewal+Expansion' && qli.Line_Type__c == 'Renewal' && qli.SBQQ__Existing__c) /*&& qli.SBQQ__Product__r.Product_Type__c == 'Hardware' && qli.SBQQ__Product__r.Appliance_Model_HW__c != null*/){
                continue;
            }
            if(qli.SBQQ__Group__r.Name != null && qli.SBQQ__Group__r.Name != 'Disposition Quote'){
                lineType = qli.SBQQ__Group__r.Name == 'Renewal Quote' ? 'Renewal' : 'New';
            }
            if(mapPODistiName.containsKey(qli.SBQQ__Quote__c)){
                poDistiName = mapPODistiName.get(qli.SBQQ__Quote__c);
                if(poDistiName!=null && OrderinsertHelper.getDistributorMetadata(poDistiName)!=null)
                checkDistributorForStagePO = OrderinsertHelper.getDistributorMetadata(poDistiName).Po_Disti_Type__c;
            }

            if(goProducts.contains(qli.SBQQ__ProductCode__c) && (checkDistributorForStagePO!=null && checkDistributorForStagePO == 'INGRAM')/*qli.SBQQ__Quote__r.SBQQ__Opportunity2__r.Distributor_Lookup__r.EDI_DISTI_ID__c != 'ARROW'*/){
                //Decimal tempPrice = !isSplitCaseValidation?qli.SBQQ__NetPrice__c: qli.SBQQ__NetTotal__c;
                Decimal tempPrice = qli.SBQQ__NetTotal__c; 
                rubrikGoPricePerYearPerUnit = calculateRubrikGoUnitPrice(qli.SBQQ__SubscriptionTerm__c,qli.SBQQ__Quantity__c,tempPrice );
                rubrikGoTermFactor = qli.SBQQ__SubscriptionTerm__c != null?(qli.SBQQ__SubscriptionTerm__c/12):0;
                rubrikGoTermFactor=rubrikGoTermFactor.round(System.RoundingMode.CEILING);
                
                
            }
            
            mapEDIBuyersPartData.put(qli.Id,new Map<String,String>{'EDLN'=>''});

            if(mapProdCodeQuoteStageItems.containsKey(mapKey) && mapProdCodeQuoteStageItems.get(mapKey) != null && !mapProdCodeQuoteStageItems.get(mapKey).isEmpty() ){
                Decimal PrevMatchedQuant;
                List<PO_Item_Stage__c> piItemordbyBestMatch;
                piItemordbyBestMatch = findBestMatch(mapProdCodeQuoteStageItems.get(mapKey), bundleParentStagePOMap, qli) != null ?  findBestMatch(mapProdCodeQuoteStageItems.get(mapKey), bundleParentStagePOMap, qli) : new List<PO_Item_Stage__c>();
                for(PO_Item_Stage__c si: mapProdCodeQuoteStageItems.get(mapKey)){
                    if(!piItemordbyBestMatch.contains(si)){
                        piItemordbyBestMatch.add(si);
                    }
                }
                for(PO_Item_Stage__c si: piItemordbyBestMatch){
                    String distributorForStagePO ='';
                    String billtoname = si?.Stage_PO__r?.Bill_To_Name__c; 
                    if(billtoname!=null && OrderinsertHelper.getDistributorMetadata(billtoname)!=null)
                       distributorForStagePO  = OrderinsertHelper.getDistributorMetadata(billtoname).Po_Disti_Type__c;


                    Decimal netPrice = netPriceMap.get(si.Id);
                    //Start : Logic for ALL ConsultSKU and travelSKU in one quote
                    if(qli.SBQQ__ProductCode__c == 'RBK-CONSULT' || qli.SBQQ__ProductCode__c =='RBK-TRAVEL-EXPENSES'){
                        if(quoteIdPOStageIDMap != null && quoteIdPOStageIDMap.containsKey(qli.SBQQ__Quote__c))
                            quoteIdPOStageIDMap.get(qli.SBQQ__Quote__c).add(si.Stage_PO__c);
                        else{
                            Set<id> tempSet = new set<id>();
                            tempset.add(si.Stage_PO__c);
                            quoteIdPOStageIDMap.put(qli.SBQQ__Quote__c,tempset);
                        }
                    }
                    //END : Logic for ALL ConsultSKU and travelSKU in one quote
                    
                    //Decimal priceFactor = si.UnitPrice__c != null && si.UnitPrice__c != 0? qli.SBQQ__NetTotal__c /si.UnitPrice__c: 0;
                    //Decimal tempPrice = !isSplitCaseValidation?qli.SBQQ__NetPrice__c: qli.SBQQ__NetTotal__c;
                    Decimal tempPrice = qli.SBQQ__NetTotal__c;
                    Decimal priceFactor = netPrice != null && netPrice != 0? tempPrice /netPrice: 0;
                    Decimal adjustedAmt;    
                    if(/*qli.SBQQ__Quote__r.SBQQ__Opportunity2__r.Distributor_Lookup__r.EDI_DISTI_ID__c == 'ARROW' &&*/  qli.Special_Program__c == 'Refresh' && qli.SBQQ__UpgradedAsset__c != null && quoteLineToCreditSKU.containsKey(qli.Id)){   
                        //Decimal tepTotal = !isSplitCaseValidation?quoteLineToCreditSKU.get(qli.Id).SBQQ__NetPrice__c: quoteLineToCreditSKU.get(qli.Id).SBQQ__NetTotal__c;   
                        Decimal tepTotal = quoteLineToCreditSKU.get(qli.Id).SBQQ__NetTotal__c;
                        adjustedAmt = (tempPrice + tepTotal);
                        goRefreshAmt.put(qli.Id, adjustedAmt);  
                        priceFactor = 0;  
                    }   
                    if((adjustedAmt != null && SplitPOValidation.isTolerableDifference(netPrice,adjustedAmt)) || /*qli.SBQQ__Quote__r.SBQQ__Opportunity2__r.Distributor_Lookup__r.EDI_DISTI_ID__c == 'ARROW' &&*/ qli.SBQQ__ProductCode__c.equalsIgnoreCase('RBK-REF-HW-CREDIT')){   
                        priceFactor = 1;    
                        //goRefreshAmt.put(qli.Id, adjustedAmt);  
                    }
                    

                   
                    if(goProducts.contains(qli.SBQQ__ProductCode__c) && (distributorForStagePO!=null && distributorForStagePO == 'INGRAM')/*qli.SBQQ__Quote__r.SBQQ__Opportunity2__r.Distributor_Lookup__r.EDI_DISTI_ID__c != 'ARROW'*/){
                        
                        if(si.SubscriptionTerm__c==12){
                            //Decimal siTotPricePerQuant = si.Quantity__c != null && si.Quantity__c  != 0 && si.UnitPrice__c != null? (si.UnitPrice__c).round(System.RoundingMode.CEILING):0 ;
                            Decimal siTotPricePerQuant = si.Quantity__c != null && si.Quantity__c  != 0 && netPrice != null? (netPrice).round(System.RoundingMode.CEILING):0 ;
                            
                            if(!SplitPOValidation.isTolerableDifference(siTotPricePerQuant,(rubrikGoPricePerYearPerUnit*si.Quantity__c))){
                                 Continue;   
                            }
                            PrevMatchedQuant = PrevMatchedQuant == null ? si.Quantity__c :PrevMatchedQuant;
                            Decimal addPrvMatchedQuant = PrevMatchedQuant != si.Quantity__c ?PrevMatchedQuant+si.Quantity__c : PrevMatchedQuant;
                            if(addPrvMatchedQuant <= qli.SBQQ__Quantity__c ){
                                //TotalPrice = si.UnitPrice__c!=null? TotalPrice + si.UnitPrice__c:TotalPrice;
                                //Decimal tempTotPrice = netPrice;
                                Decimal tempTotPrice = si.UnitPrice__c != null && si.Quantity__c != null ? si.UnitPrice__c *si.Quantity__c : 0;
                                TotalPrice = tempTotPrice!=null? TotalPrice + tempTotPrice: TotalPrice;
                                TotalQuant = si.Quantity__c != null? TotalQuant + si.Quantity__c: TotalQuant;
                                totalTerm =  si.SubscriptionTerm__c != null?totalTerm+si.SubscriptionTerm__c:totalTerm;
                                
                                String EDIline = si.EDI_Line_Number__c != null? si.EDI_Line_Number__c+'*'+si.Stage_PO__c: '';
                                String buyerPartNum = si.Buyer_part_Number__c != null? si.Buyer_part_Number__c+'*'+si.Stage_PO__c:'';
                                
                                if((mapEDIBuyersPartData.get(qli.Id).get('EDLN') != null && !mapEDIBuyersPartData.get(qli.Id).get('EDLN').contains(EDIline)) ||mapEDIBuyersPartData.get(qli.Id).get('EDLN') ==''){
                                        
                                        String EDLNNum = mapEDIBuyersPartData.get(qli.Id).get('EDLN')!=''?mapEDIBuyersPartData.get(qli.Id).get('EDLN')+';'+EDIline:EDIline;
                                        mapEDIBuyersPartData.get(qli.Id).put('EDLN',EDLNNum);
                                        if(!processedPOItem.contains(si.Id)){
                                            processedPOItem.add(si.Id);
                                            poItemsToUpdate.add(new PO_Item_Stage__c(Id=si.Id, Type__c = lineType, Quote_Line__c = qli.Id,Stage_Po__c = si.Stage_Po__c,Name=si.Name ));
                                        }
                                        if(qli.SBQQ__Bundle__c){
                                            bundleParentStagePOMap.put(qli.Id,si.Stage_PO__c);
                                            if(!stagePOrBundleParentMap.containsKey(si.Stage_PO__c)){
                                                stagePOrBundleParentMap.put(si.Stage_PO__c,new Set<Id>{qli.Id});
                                            }
                                            else{
                                                stagePOrBundleParentMap.get(si.Stage_PO__c).add(qli.Id);
                                            }
                                        }
                                }                               
                                
                                matchProbSI.add(si);
                            }

                            
                        }else{

                                if(si.SubscriptionTerm__c<12){
                                PrevMatchedQuant = PrevMatchedQuant == null ? si.Quantity__c :PrevMatchedQuant;
                                Decimal addPrvMatchedQuant = PrevMatchedQuant != si.Quantity__c ?PrevMatchedQuant+si.Quantity__c : PrevMatchedQuant;
                                
                                decimal pricePerMonth= (rubrikGoPricePerYearPerUnit/12);/*.round(System.RoundingMode.CEILING);*/

                                decimal totExpPrice = (pricePerMonth*si.SubscriptionTerm__c*si.quantity__c);/*.round(System.RoundingMode.CEILING);*/

                                //Decimal siTotPricePerQuant = si.UnitPrice__c != null? (si.UnitPrice__c).round(System.RoundingMode.CEILING):0 ;
                                Decimal siTotPricePerQuant = netPrice != null? (netPrice)/*.round(System.RoundingMode.CEILING)*/:0 ;
                                
                                
                                if(!SplitPOValidation.isTolerableDifference(totExpPrice ,siTotPricePerQuant))
                                    Continue;
                                if(addPrvMatchedQuant <= qli.SBQQ__Quantity__c){
                                    //TotalPrice = si.UnitPrice__c!=null? TotalPrice + si.UnitPrice__c:TotalPrice;
                                    Decimal tempTotPrice = si.UnitPrice__c != null && si.Quantity__c != null ? si.UnitPrice__c *si.Quantity__c : 0;
                                    TotalPrice = tempTotPrice!=null? TotalPrice + tempTotPrice:TotalPrice;
                                    TotalQuant = si.Quantity__c != null? TotalQuant + si.Quantity__c: TotalQuant;
                                    totalTerm =  si.SubscriptionTerm__c != null?totalTerm+si.SubscriptionTerm__c:totalTerm;
                                    String EDIline = si.EDI_Line_Number__c != null? si.EDI_Line_Number__c+'*'+si.Stage_PO__c: '';
                                    String buyerPartNum = si.Buyer_part_Number__c != null? si.Buyer_part_Number__c+'*'+si.Stage_PO__c:'';
                                
                                    if((mapEDIBuyersPartData.get(qli.Id).get('EDLN') != null && !mapEDIBuyersPartData.get(qli.Id).get('EDLN').contains(EDIline))|| mapEDIBuyersPartData.get(qli.Id).get('EDLN')==''){                                        String EDLNNum = mapEDIBuyersPartData.get(qli.Id).get('EDLN')!=''?mapEDIBuyersPartData.get(qli.Id).get('EDLN')+';'+EDIline:EDIline;
                                        mapEDIBuyersPartData.get(qli.Id).put('EDLN',EDLNNum);
                                        if(!processedPOItem.contains(si.Id)){
                                          processedPOItem.add(si.Id);
                                          poItemsToUpdate.add(new PO_Item_Stage__c(Id=si.Id, type__c = lineType, Quote_Line__c = qli.Id,Stage_Po__c = si.Stage_Po__c,Name=si.Name));
                                        }
                                        if(qli.SBQQ__Bundle__c){
                                            bundleParentStagePOMap.put(qli.Id,si.Stage_PO__c);
                                            if(!stagePOrBundleParentMap.containsKey(si.Stage_PO__c)){
                                                stagePOrBundleParentMap.put(si.Stage_PO__c,new Set<Id>{qli.Id});
                                            }
                                            else{
                                                stagePOrBundleParentMap.get(si.Stage_PO__c).add(qli.Id);
                                            }
                                        }
                                    }
                                    matchProbSI.add(si);
                                }

                            
                           }
                        }
                    }
                     else if((priceFactor>0 &&   qli.SBQQ__Quantity__c >= (TotalQuant+si.Quantity__c) &&    (qli.SBQQ__NetTotal__c+(SplitPOValidation.threshold *qli.SBQQ__Quantity__c))   >=(netPrice+totalprice) && SplitPOValidation.isTolerableDifference(qli.SBQQ__NetPrice__c,si.unitprice__c) ) // commented to resolve PRDOPS22-489 , && priceFactor<= qli.SBQQ__Quantity__c
                         ||  (qli.SBQQ__NetTotal__c ==0 && netPrice==0 && (qli.SBQQ__Quantity__c >= (TotalQuant+si.Quantity__c)|| qli.SBQQ__Quantity__c == si.Quantity__c) && qli.SBQQ__NetTotal__c>=(netPrice+totalprice) && SplitPOValidation.isTolerableDifference(qli.SBQQ__NetPrice__c,si.unitprice__c) )
                         || (priceFactor == 1 && (si.Quantity__c == qli.SBQQ__Quantity__c) && si.SubscriptionTerm__c == qli.SBQQ__SubscriptionTerm__c)){
                      //||  (qli.SBQQ__NetTotal__c ==0 && netPrice==0)
                        
                        
                        if(priceFactor == 1 && (si.Quantity__c == qli.SBQQ__Quantity__c) && si.SubscriptionTerm__c == qli.SBQQ__SubscriptionTerm__c){
                                String EDIline = si.EDI_Line_Number__c != null? si.EDI_Line_Number__c+'*'+si.Stage_PO__c: '';
                                if((mapEDIBuyersPartData.get(qli.Id).get('EDLN') != null && !mapEDIBuyersPartData.get(qli.Id).get('EDLN').contains(EDIline)|| mapEDIBuyersPartData.get(qli.Id).get('EDLN')=='')) {            
                                    mapEDIBuyersPartData.get(qli.Id).put('EDLN',EDIline);
                                    if(!processedPOItem.contains(si.Id)){
                                        processedPOItem.add(si.Id);
                                        poItemsToUpdate.add(new PO_Item_Stage__c(Id=si.Id, type__c= lineType, Quote_Line__c = qli.Id,Stage_Po__c = si.Stage_Po__c,Name=si.Name));
                                    }
                                    if(qli.SBQQ__Bundle__c){
                                        bundleParentStagePOMap.put(qli.Id,si.Stage_PO__c);
                                        if(!stagePOrBundleParentMap.containsKey(si.Stage_PO__c)){
                                            stagePOrBundleParentMap.put(si.Stage_PO__c,new Set<Id>{qli.Id});
                                        }
                                        else{
                                            stagePOrBundleParentMap.get(si.Stage_PO__c).add(qli.Id);
                                        }
                                    }
                                }
                                String buyerPartNum = si.Buyer_part_Number__c != null? si.Buyer_part_Number__c+'*'+si.Stage_PO__c:'';                         
                                Integer MatchIndex = mapProdCodeQuoteStageItems.get(mapKey).IndexOF(si);
                                if(MatchIndex !=-1)
                                    mapProdCodeQuoteStageItems.get(mapKey).remove(MatchIndex);
                               
                                //MatchIndex = allStageLines.IndexOF(si);
                                //if(MatchIndex !=-1)
                                    //allStageLines.remove(MatchIndex);
                                allStageLinesMap.remove(si.id);
                                completeMatch = true;
                                passedPOStageIds.add(si.Stage_PO__c);
                                if(QuoteExtValidPOMAp.containsKey(qli.SBQQ__Quote__c)){
                                    QuoteExtValidPOMAp.get(qli.SBQQ__Quote__c).add(si.Stage_PO__c);
                                }else{
                                    Set<id> tempSet = new set<id>();
                                    tempSet.add(si.Stage_PO__c);
                                    QuoteExtValidPOMAp.put(qli.SBQQ__Quote__c,tempSet);
                                }
                                break;
                        }
                        //TotalPrice = si.UnitPrice__c!=null? TotalPrice + si.UnitPrice__c:TotalPrice;
                       
                        TotalPrice = netPrice!=null? TotalPrice + netPrice:TotalPrice;
                        //Condition added as part of defect fix.
                        if(qli.SBQQ__Quantity__c == si.Quantity__c && netPrice==0 ){
                            TotalQuant = si.Quantity__c ;
                            mapEDIBuyersPartData.get(qli.Id).put('EDLN','');
                            matchProbSI.clear();
                        }else
                            TotalQuant = si.Quantity__c != null? TotalQuant + si.Quantity__c: TotalQuant;
                        totalTerm =  si.SubscriptionTerm__c != null?totalTerm+si.SubscriptionTerm__c:totalTerm;
                        String EDIline = si.EDI_Line_Number__c != null? si.EDI_Line_Number__c+'*'+si.Stage_PO__c: '';
                        String buyerPartNum = si.Buyer_part_Number__c != null? si.Buyer_part_Number__c+'*'+si.Stage_PO__c:'';

                        if((mapEDIBuyersPartData.get(qli.Id).get('EDLN') != null && !mapEDIBuyersPartData.get(qli.Id).get('EDLN').contains(EDIline))|| mapEDIBuyersPartData.get(qli.Id).get('EDLN')==''){                            
                            String EDLNNum = mapEDIBuyersPartData.get(qli.Id).get('EDLN') != null &&mapEDIBuyersPartData.get(qli.Id).get('EDLN')!=''?mapEDIBuyersPartData.get(qli.Id).get('EDLN')+';'+EDIline:EDIline;
                            mapEDIBuyersPartData.get(qli.Id).put('EDLN',EDLNNum);
                            if(!processedPOItem.contains(si.Id)){
                             processedPOItem.add(si.Id);
                             poItemsToUpdate.add(new PO_Item_Stage__c(Id=si.Id, type__c = lineType,Quote_Line__c = qli.Id,Stage_Po__c = si.Stage_Po__c ,Name=si.Name));
                            }
                            if(qli.SBQQ__Bundle__c){
                                bundleParentStagePOMap.put(qli.Id,si.Stage_PO__c);
                                if(!stagePOrBundleParentMap.containsKey(si.Stage_PO__c)){
                                    stagePOrBundleParentMap.put(si.Stage_PO__c,new Set<Id>{qli.Id});
                                }
                                else{
                                    stagePOrBundleParentMap.get(si.Stage_PO__c).add(qli.Id);
                                }
                            }
                        }
                        
                        matchProbSI.add(si);
                    }
                   
                    Decimal termMatchValue =0;
                    Decimal totalRubrikGoQuoteTerm = 0;
                    boolean termMatched=false;
                    if(goProducts.contains(qli.SBQQ__ProductCode__c) && (distributorForStagePO!=null && distributorForStagePO == 'INGRAM')/*qli.SBQQ__Quote__r.SBQQ__Opportunity2__r.Distributor_Lookup__r.EDI_DISTI_ID__c != 'ARROW'*/){
                        
                        Integer matchedSISize = matchProbSI.size();
                        // && rubrikGoTermFactor != matchedSISize
                        if(rubrikGoTermFactor>1){
                            integer temp= matchedSISize/Integer.valueOF(rubrikGoTermFactor);
                            if(temp != 0){
                                totalRubrikGoQuoteTerm = totalTerm/temp;
                                if(totalRubrikGoQuoteTerm == qli.SBQQ__SubscriptionTerm__c){
                                    termMatched = true;
                                    //totalPrice = totalPrice.round(System.RoundingMode.CEILING);
                                    
                                }
                            }
                                
                        }else IF(rubrikGoTermFactor==1){
                            termMatchValue = qli.SBQQ__SubscriptionTerm__c!= null?qli.SBQQ__SubscriptionTerm__c:0;
                            
                        }
                        
                       }else{
                        //Multiply size of matched list with line item subscription term.
                        Integer matchedSISize = matchProbSI.size();
                        termMatchValue = qli.SBQQ__SubscriptionTerm__c!= null? qli.SBQQ__SubscriptionTerm__c*matchedSISize:termMatchValue;
                    }
                    
                    
                    Decimal quantMatchValue =0;
                    if(goProducts.contains(qli.SBQQ__ProductCode__c) && (distributorForStagePO!=null && distributorForStagePO == 'INGRAM')/*qli.SBQQ__Quote__r.SBQQ__Opportunity2__r.Distributor_Lookup__r.EDI_DISTI_ID__c != 'ARROW'*/)
                        quantMatchValue = qli.SBQQ__Quantity__c != null? qli.SBQQ__Quantity__c*rubrikGoTermFactor:quantMatchValue;
                    else{
                        quantMatchValue = quantMatchValue!= null? qli.SBQQ__Quantity__c:quantMatchValue;
                    }
                    
                    decimal priceMatchValue =0;
                    Decimal TempNetUnitPrice = qli.SBQQ__NetTotal__c != null && qli.SBQQ__Quantity__c != null && qli.SBQQ__Quantity__c != 0? (qli.SBQQ__NetTotal__c/qli.SBQQ__Quantity__c).setscale(2) : 0;
                    priceMatchValue = qli.SBQQ__Quantity__c != null? (TempNetUnitPrice * qli.SBQQ__Quantity__c).setscale(2)  : 0;
                    if(goProducts.contains(qli.SBQQ__ProductCode__c) && (distributorForStagePO!=null && distributorForStagePO == 'INGRAM')/*qli.SBQQ__Quote__r.SBQQ__Opportunity2__r.Distributor_Lookup__r.EDI_DISTI_ID__c != 'ARROW'*/){
                         if(totalQuant == quantMatchValue){
                            
                            /*Decimal priceMatchValueTemp = priceMatchValue !=totalPrice  ? priceMatchValue.round(System.RoundingMode.Floor):priceMatchValue;
                            Decimal totalPriceTemp = priceMatchValue !=totalPrice  ? totalPrice.round(System.RoundingMode.Floor):totalPrice;
                         
                            Decimal priceMatchValueTemp1 = priceMatchValueTemp !=totalPriceTemp  ? priceMatchValue.round(System.RoundingMode.Floor):priceMatchValueTemp;
                            Decimal totalPriceTemp1 = priceMatchValueTemp !=totalPriceTemp  ? totalPrice.round(System.RoundingMode.CEILING):totalPriceTemp;
                            
                            priceMatchValue = priceMatchValueTemp1 !=totalPriceTemp1  ? priceMatchValue.round(System.RoundingMode.CEILING):priceMatchValueTemp1;
                            totalPrice = priceMatchValueTemp1 !=totalPriceTemp1  ? totalPrice.round(System.RoundingMode.Floor):totalPriceTemp1;*/
                         }
                        
                        
                    }
                    // To Handle scenarios like 100/3
                    
                    /*Decimal TempNetUnitPrice = qli.SBQQ__NetTotal__c != null && qli.SBQQ__Quantity__c != null && qli.SBQQ__Quantity__c != 0? (qli.SBQQ__NetTotal__c/qli.SBQQ__Quantity__c).setscale(2) : 0;
                    System.debug('test code TempNetUnitPrice '+TempNetUnitPrice);
                    priceMatchValue = qli.SBQQ__Quantity__c != null? (TempNetUnitPrice * qli.SBQQ__Quantity__c).setscale(2) : 0;*/
                  
                    
                    //totalPrice == qli.SBQQ__NetTotal__c
                    if(((/*!qli.Is_Refresh__c &&*/ SplitPOValidation.isTolerableDifference(totalPrice,priceMatchValue))) && totalQuant == quantMatchValue && ((totalTerm == termMatchValue)|| termMatched) ){
                        
                        for(PO_Item_Stage__c tempSI: matchProbSI){
                             passedPOStageIds.add(tempSI.Stage_PO__c);
                             if(QuoteExtValidPOMAp.containsKey(qli.SBQQ__Quote__c)){
                                    QuoteExtValidPOMAp.get(qli.SBQQ__Quote__c).add(tempSI.Stage_PO__c);
                             }else{
                                    Set<id> tempSet = new set<id>();
                                    tempSet.add(tempSI.Stage_PO__c);
                                    QuoteExtValidPOMAp.put(qli.SBQQ__Quote__c,tempSet);
                             }
                             Integer MatchIndex = mapProdCodeQuoteStageItems.get(mapKey).IndexOF(tempSI);
                             if(MatchIndex !=-1)
                                mapProdCodeQuoteStageItems.get(mapKey).remove(MatchIndex);
                             /*MatchIndex = allStageLines.IndexOF(tempSI);
                             if(MatchIndex !=-1)
                                allStageLines.remove(MatchIndex);*/
                             allStageLinesMap.remove(tempSI.id);
                        }
                        completeMatch = true;
                        
                        break;
                    }
                }
            }else{
                /*added by rahul for sf-5589=>PRDOPS21-44*/
                if((qli.SBQQ__RenewedAsset__c  != null  && qli.SBQQ__Quote__r.SBQQ__Type__c  == 'Renewal')||(qli.SBQQ__Quote__r.SBQQ__Type__c  == 'Amendment' && qli.SBQQ__Existing__c)){}
                //Logic to check if there is any extra line on quote
                else if( (!qli.SBQQ__Product__r.SBQQ__ExcludeFromOpportunity__c && !qli.SBQQ__Product__r.SBQQ__Optional__c) 
                    && !qli.SBQQ__ProductCode__c.contains('HW-CREDIT')){ //PRDOPS23-66
                    if(!qli.SBQQ__Renewal__c || qli.SBQQ__EffectiveQuantity__c != 0 || !qli.SBQQ__Existing__c){ //PRDOPS23-848
                        if(unmatchedQuotes.containsKey(qli.SBQQ__Quote__c))    
                            unmatchedQuotes.get(qli.SBQQ__Quote__c).add(qli.SBQQ__ProductCode__c);
                        else {
                            Set<string> tempset = new set<string>();
                            tempset.Add(qli.SBQQ__ProductCode__c);
                            unmatchedQuotes.put(qli.SBQQ__Quote__c,tempset);
                        }
                    }
                }
            }
            
            
            /*if(!completeMatch && /*qli.SBQQ__Quote__r.SBQQ__Opportunity2__r.Distributor_Lookup__r.EDI_DISTI_ID__c == 'ARROW' &&*//* qli.SBQQ__ProductCode__c != null && qli.SBQQ__ProductCode__c.equalsIgnoreCase('RBK-REF-HW-CREDIT')){
                QuoteExtValidPOMAp.remove(qli.SBQQ__Quote__c);
                for(PO_Stage__c poi: quoteMap.get(qli.SBQQ__Quote__c).getSObjects('Stage_PO__r')){
                   
                    PO_Stage__c ps=   new PO_Stage__c(Id = poi.id, PO_Validation_Status__c = 'Failure');
                    stageUpdates.put(poi.id,ps);
                    string tempMes = validationCodes.get('PO-09') != null? validationCodes.get('PO-09').Error_Issue__c : system.label.Generic_Validation_Error_Mgs;
                    String errorMess = tempMes +' : '+qli.SBQQ__ProductCode__c;
                    errcodes.add(new PO_Stage_Errors__c(Name ='PO-09', Error_Code__c ='PO-09', 
                                                            Error_Message__c=errorMess, 
                                                            PO_Stage_Id__c = poi.id,
                                                            PO_Stage_Id__r = poi,
                                                            Error_Type__c = 'External'
                                                        ));
                }
            }
            else*/
            if((qli.SBQQ__RenewedAsset__c  != null  && qli.SBQQ__Quote__r.SBQQ__Type__c  == 'Renewal')||(qli.SBQQ__Quote__r.SBQQ__Type__c  == 'Amendment' && qli.SBQQ__Existing__c)){} //PRDOPS22-251
            else if(!completeMatch && !qli.SBQQ__Product__r.SBQQ__ExcludeFromOpportunity__c && !qli.SBQQ__Product__r.SBQQ__Optional__c){
                if(!qli.SBQQ__Renewal__c || qli.SBQQ__EffectiveQuantity__c != 0 || !qli.SBQQ__Existing__c){ //PRDOPS23-848 
                 if(wrapMAp.containsKey(mapKey)){
                    Decimal subTerm = qli.SBQQ__SubscriptionTerm__c != null?qli.SBQQ__SubscriptionTerm__c:0;
                    wrapMAp.get(mapKey).subscriptionTerm =wrapMAp.get(mapKey).subscriptionTerm+subTerm;
                    wrapMAp.get(mapKey).quantity = wrapMAp.get(mapKey).quantity+qli.SBQQ__Quantity__c;
                    //Decimal priceTemp = !isSplitCaseValidation?qli.SBQQ__NetPrice__c: qli.SBQQ__NetTotal__c;
                    Decimal priceTemp = qli.SBQQ__NetTotal__c;
                    priceTemp = goRefreshAmt.containsKey(qli.Id)?goRefreshAmt.get(qli.Id):priceTemp;
                    wrapMAp.get(mapKey).totalprice = wrapMAp.get(mapKey).totalprice+ priceTemp ;
                 
                 }else{
                    Decimal subTerm = qli.SBQQ__SubscriptionTerm__c != null?qli.SBQQ__SubscriptionTerm__c:0;
                    //Decimal priceTemp = onlyValidate && !isSplitCaseValidation?qli.SBQQ__NetPrice__c: qli.SBQQ__NetTotal__c;
                     Decimal priceTemp = qli.SBQQ__NetTotal__c;
                    priceTemp = goRefreshAmt.containsKey(qli.Id)?goRefreshAmt.get(qli.Id):priceTemp;
                    wrapProductCode wrapinst= new wrapProductCode(subTerm,qli.SBQQ__Quantity__c,priceTemp,qli.SBQQ__ProductCode__c,qli.SBQQ__Quote__c);
                    wrapMAp.put(mapKey,wrapinst);
                 }
                 mapEDIBuyersPartData.get(qli.Id).put('EDLN','');
                } 
            }
              
            
        }
       
        

        
        allStageLines.clear();
        allStageLines.addAll(allStageLinesMap.values());

        Set<String> setHandledProducts = new Set<String>();
        
        for(PO_Item_Stage__c si: allStageLines){
            string key=si.ProductCode__c+''+si.Stage_PO__r.Quote__c;
            Decimal totalTerm=0;
            Decimal totalQuant=0;
            Decimal totalPrice=0;
           
            boolean errorRecorded = false;
             if(QuoteExtValidPOMAp.containskey(si.Stage_PO__r.Quote__c))
                     QuoteExtValidPOMAp.get(si.Stage_PO__r.Quote__c).remove(si.Stage_PO__c);
            passedPOStageIds.remove(si.Stage_PO__c);
                
               
            
            if(!mapProdCodeQuoteStageItems.containsKey(key)){
                    errorRecorded = true;
                    errcodes.add(new PO_Stage_Errors__c(Name ='PO-09', Error_Code__c ='PO-09', 
                                                            Error_Message__c=validationCodes.get('PO-09') != null? validationCodes.get('PO-09').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                                                            PO_Stage_Id__c = si.Stage_PO__c,
                                                            PO_Stage_Item_Id__c = si.Id,
                                                            PO_Stage_Id__r = si.Stage_PO__r,
                                                            PO_Stage_Item_Id__r = si,
                                                            Error_Type__c = 'External'
                                                        ));
                          
                 
            }else{
                Map<string,List<decimal>> termMap = new Map<string,List<decimal>>();
                for(PO_Item_Stage__c poi: mapProdCodeQuoteStageItems.get(key)){
                    Decimal netPrice = netPriceMap.get(poi.Id);
                    if(termMap.containsKey(key)){
                       termMap.get(key).add(poi.SubscriptionTerm__c);
                    }else{
                           List<decimal> templist = new List<Decimal>();
                           decimal termtemp = poi.SubscriptionTerm__c != null?poi.SubscriptionTerm__c:0;
                           templist.add(termtemp);
                           termMap.put(key,templist);
                       
                    }
                    totalTerm = poi.SubscriptionTerm__c != null?totalTerm+poi.SubscriptionTerm__c:totalTerm;
                    totalQuant= poi.Quantity__c != null?totalQuant+poi.Quantity__c:totalQuant;
                    //TotalPrice = poi.UnitPrice__c != null?TotalPrice + poi.UnitPrice__c:TotalPrice;
                    TotalPrice = netPrice != null?TotalPrice + netPrice:TotalPrice;
                }
                wrapProductCode wrapInst= wrapMAp.get(key);
                
                if(wrapInst != null){
                    
                    setHandledProducts.add(si.ProductCode__c);
                    Decimal totalTermnew=0;
                    for(Decimal d: termMap.get(key)){
                        if(totalTerm>0){
                          totalTermnew = d > 0?totalTermnew+d:totalTermnew-1;  
                        }
                    }
                    
                    if(totalTermnew != wrapInst.subscriptionTerm){
                            errorRecorded = true;
                            errcodes.add(new PO_Stage_Errors__c(Name ='PO-12', Error_Code__c ='PO-12' , 
                                                            Error_Message__c=validationCodes.get('PO-12') != null? validationCodes.get('PO-12').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                                                            PO_Stage_Id__c = si.Stage_PO__c,
                                                            PO_Stage_Item_Id__c = si.Id,
                                                            PO_Stage_Id__r = si.Stage_PO__r,
                                                            PO_Stage_Item_Id__r = si,
                                                            Error_Type__c = 'External'
                                                            ));
                            
                    }
                    if(totalQuant != wrapInst.quantity){
                            errorRecorded = true;
                            errcodes.add(new PO_Stage_Errors__c(Name = 'PO-11', Error_Code__c ='PO-11' , 
                                                            Error_Message__c=validationCodes.get('PO-11') != null? validationCodes.get('PO-11').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                                                            PO_Stage_Id__c = si.Stage_PO__c,
                                                            PO_Stage_Item_Id__c = si.Id,
                                                            PO_Stage_Id__r = si.Stage_PO__r,
                                                            PO_Stage_Item_Id__r = si,
                                                            Error_Type__c = 'External'
                                                            ));
                    
                    }
                    if(!SplitPOValidation.isTolerableDifference(totalPrice, wrapInst.totalPrice)){
                            errorRecorded = true;
                            errcodes.add(new PO_Stage_Errors__c(Name = 'PO-10', Error_Code__c ='PO-10' , 
                                                            Error_Message__c=validationCodes.get('PO-10') != null? validationCodes.get('PO-10').Error_Issue__c +' : '+si.ProductCode__c+', Difference : '+ String.valueOf(Math.abs(TotalPrice - wrapInst.TotalPrice).setScale(2, System.RoundingMode.HALF_UP)) : system.label.Generic_Validation_Error_Mgs, 
                                                            PO_Stage_Id__c = si.Stage_PO__c,
                                                            PO_Stage_Item_Id__c = si.Id,
                                                            PO_Stage_Id__r = si.Stage_PO__r,
                                                            PO_Stage_Item_Id__r = si,
                                                            Error_Type__c = 'External'
                                                            ));
                    }
                }else{
                    //If there is a extra line on Stage PO
                    if(unmatchedQuotes.containsKey(si.Stage_PO__r.Quote__c))    
                        unmatchedQuotes.get(si.Stage_PO__r.Quote__c).add(si.ProductCode__c);
                    else {
                        Set<string> tempset = new set<string>();
                        tempset.Add(si.ProductCode__c);
                        unmatchedQuotes.put(si.Stage_PO__r.Quote__c,tempset);
                    }
                }
            }
            if(errorRecorded && !(POStageHelper.poStagesToUpdateMap.containsKey(si.Stage_PO__c) && POStageHelper.poStagesToUpdateMap.get(si.Stage_PO__c).PO_Validation_Status__c == 'Failure')){
                    PO_Stage__c stg = POStageHelper.poStagesToUpdateMap.containsKey(si.Stage_PO__c) ? POStageHelper.poStagesToUpdateMap.get(si.Stage_PO__c) : new PO_Stage__c(Id = si.Stage_PO__c);
                    stg.PO_Validation_Status__c = 'Failure';
                    POStageHelper.poStagesToUpdateMap.put(stg.id,stg);
                }
        }
        for(PO_Item_Stage__c pi: poItemsToUpdate){
            if(qliMap.get(pi.Quote_Line__c).SBQQ__RequiredBy__c != null && qliMap.get(pi.Quote_Line__c).SBQQ__RequiredBy__r.SBQQ__Existing__c == false && stagePOrBundleParentMap.isEmpty() == false && 
               (stagePOrBundleParentMap.get(pi.Stage_Po__c) == null || !stagePOrBundleParentMap.get(pi.Stage_Po__c).contains(quoteLineRequiredBy.get(pi.Quote_Line__c)))){
                   if(!mapOfRenwLinetoSwap.containsKey(pi.Stage_PO__c)){
                       mapOfRenwLinetoSwap.put(pi.Stage_PO__c,new List<PO_Item_Stage__c>{pi});
                   }
                   else{
                       mapOfRenwLinetoSwap.get(pi.Stage_PO__c).add(pi);
                   }
               }
        }

        for(String prodCodeQuote :wrapMAp.keySet()){
            wrapProductCode obj = wrapMAp.get(prodCodeQuote);
            if(obj != null && !setHandledProducts.contains(obj.productCode)
                && !obj.productCode.contains('HW-CREDIT')){ //PRDOPS23-66
                if(unmatchedQuotes.containsKey(obj.quoteId))    
                        unmatchedQuotes.get(obj.quoteId).add(obj.productCode);
                    else {
                        Set<string> tempset = new set<string>();
                        tempset.Add(obj.productCode);
                        unmatchedQuotes.put(obj.quoteId,tempset);
                    }
            }
        }

        if(unmatchedQuotes.size()>0){
            for(id qid: unmatchedQuotes.keyset()){
                QuoteExtValidPOMAp.remove(qid);
                for(PO_Stage__c poi: quoteMap.get(qid).getSObjects('Stage_PO__r')){
                    Set<string> tempSet= unmatchedQuotes.get(qid);
                    List<string>tempstring =new  list<string>();
                    if(tempSet != null){
                         tempstring.addAll(tempSet);
                         tempSet = null;
                    }
                    if(!(POStageHelper.poStagesToUpdateMap.containsKey(poi.id) && POStageHelper.poStagesToUpdateMap.get(poi.id).PO_Validation_Status__c == 'Failure')){
                        PO_Stage__c stg = POStageHelper.poStagesToUpdateMap.containsKey(poi.id) ? POStageHelper.poStagesToUpdateMap.get(poi.id) : new PO_Stage__c(Id = poi.id);
                        stg.PO_Validation_Status__c = 'Failure';
                        POStageHelper.poStagesToUpdateMap.put(stg.id,stg);
                    }
                    string tempMes = validationCodes.get('PO-09') != null? validationCodes.get('PO-09').Error_Issue__c : system.label.Generic_Validation_Error_Mgs;
                    String errorMess = tempMes +' : '+String.join(tempstring,';');
                    errcodes.add(new PO_Stage_Errors__c(Name ='PO-09', Error_Code__c ='PO-09', 
                                                            Error_Message__c=errorMess, 
                                                            PO_Stage_Id__c = poi.id,
                                                            PO_Stage_Id__r = poi,
                                                            Error_Type__c = 'External'
                                                        ));
                }
                
            }
        }
        
         //Start : Logic for ALL ConsultSKU and travelSKU in one quote
        if(quoteIdPOStageIDMap != null && quoteIdPOStageIDMap.size()>0){
            for(id qid: quoteIdPOStageIDMap.keyset()){
                set<id> tempset = quoteIdPOStageIDMap.get(qid);
                if(tempset != null && tempset.size()>1){
                    //QuoteExtValidPOMAp.remove(qid);
                    for(id poID : tempset){
                        PO_Stage__c ps=   new PO_Stage__c(Id = Poid, Consult_Splitted__c = true, PO_Validation_Status__c = 'Failure');
                        //stageUpdates.put(poid,ps);
    
                        /*errcodes.add(new PO_Stage_Errors__c(Name ='PO-20', Error_Code__c ='PO-20', 
                                                                Error_Message__c=validationCodes.get('PO-20') != null? validationCodes.get('PO-20').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                                                                PO_Stage_Id__c = poid,
                                                                Error_Type__c = 'External'
                                                            ));*/
                    }
                }
                
            }
        }
        //End : Logic for ALL ConsultSKU and travelSKU in one quote
        List<Id> erroneousQuotes = new List<Id>();
        for(String quoteId : consultTravelMap.keySet()){
            Boolean alreadyPresent = false;
            Boolean onlyConsult = false;
            Boolean onlyTravel = false;
            Integer i=0;
            for(String stagePOId : consultTravelMap.get(quoteId).keySet()){
                if(!consultTravelMap.get(quoteId).get(stagePOId).contains('RBK-CONSULT') && consultTravelMap.get(quoteId).get(stagePOId).contains('RBK-TRAVEL-EXPENSES')){
                    onlyTravel = true;
                }
                else if(consultTravelMap.get(quoteId).get(stagePOId).contains('RBK-CONSULT')){
                    onlyTravel = false;
                    break;
                }
            }
            for(String stagePOId : consultTravelMap.get(quoteId).keySet()){
               if(consultTravelMap.get(quoteId).get(stagePOId).contains('RBK-TRAVEL-EXPENSES') &&
                   consultTravelMap.get(quoteId).get(stagePOId).contains('RBK-CONSULT') &&
                   consultTravelMap.get(quoteId).keySet().size() == 1){
                   continue;
               }
               if(consultTravelMap.get(quoteId).get(stagePOId).contains('RBK-TRAVEL-EXPENSES') && !alreadyPresent){
                   alreadyPresent = true;
                   if(i != consultTravelMap.get(quoteId).keySet().size()-1){
                       continue;
                   }
               }
               if((alreadyPresent == true && onlyTravel == false && consultTravelMap.get(quoteId).get(stagePOId).contains('RBK-CONSULT')) || (alreadyPresent == true && consultTravelMap.get(quoteId).keySet().size() > 1 && onlyTravel == false)){
                   erroneousQuotes.add(quoteId);
               }
               i++; 
            }
        }
        for(Id quoteErrorId : erroneousQuotes){
            QuoteExtValidPOMAp.remove(quoteErrorId );
            for(String stagePOId : consultTravelMap.get(quoteErrorId ).keySet()){
                if(!(POStageHelper.poStagesToUpdateMap.containsKey(stagePOId) && POStageHelper.poStagesToUpdateMap.get(stagePOId).PO_Validation_Status__c == 'Failure')){
                    PO_Stage__c stg = POStageHelper.poStagesToUpdateMap.containsKey(stagePOId) ? POStageHelper.poStagesToUpdateMap.get(stagePOId) : new PO_Stage__c(Id = stagePOId);
                    stg.PO_Validation_Status__c = 'Failure';
                    POStageHelper.poStagesToUpdateMap.put(stg.id,stg);
                }
                errcodes.add(new PO_Stage_Errors__c(Name ='PO-20', Error_Code__c ='PO-20', 
                                                        Error_Message__c=validationCodes.get('PO-20') != null? validationCodes.get('PO-20').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                                                        PO_Stage_Id__c = stagePOId,
                                                        Error_Type__c = 'External'
                                                    ));
            }
        }
        
        
        Set<id> successfullPOs = new Set<id>();
        // Success PO validated if all staged PO are valid related to quote.
        for(id qIDS: quoteMap.keyset()){
            Integer remainingValidPO = QuoteExtValidPOMAp.get(qIDS) != null? QuoteExtValidPOMAp.get(qIDS).size():0;
            Integer poStagedOnQuote = quoteMap.get(qIDS) != null && quoteMap.get(qIDS).getSObjects('Stage_PO__r') != null?quoteMap.get(qIDS).getSObjects('Stage_PO__r').size():0; 
            Decimal quoteAmount = quoteMap.get(qIDs) != null && quoteMap.get(qIDs).SBQQ__NetAmount__c != null?quoteMap.get(qIDs).SBQQ__NetAmount__c:0;
            Decimal POAmount = mapQuotePOAmount.get(qIDs) != null?mapQuotePOAmount.get(qIDs) : 0;
            
            /*Decimal POAmountTemp = POAmount !=quoteAmount  ? POAmount.round(System.RoundingMode.Floor):POAmount;
            Decimal quoteAmountTemp = POAmount !=quoteAmount  ? quoteAmount.round(System.RoundingMode.Floor):quoteAmount;
         
            Decimal POAmountTemp1 = POAmountTemp !=quoteAmountTemp  ? POAmount.round(System.RoundingMode.Floor):POAmountTemp;
            Decimal quoteAmountTemp1 = POAmountTemp !=quoteAmountTemp  ? quoteAmount.round(System.RoundingMode.CEILING):quoteAmountTemp;
            
            POAmount = POAmountTemp1 !=quoteAmountTemp1  ? POAmount.round(System.RoundingMode.CEILING):POAmountTemp1;
            quoteAmount = POAmountTemp1 !=quoteAmountTemp1  ? quoteAmount.round(System.RoundingMode.Floor):quoteAmountTemp1;*/
            
            if(remainingValidPO == poStagedOnQuote && SplitPOValidation.isTolerableDifference(POAmount,quoteAmount) && poStagedOnQuote != 0 ){
            
                system.debug('---------------test debug POAmount '+quoteAmount);
                successfullPOs.addAll(QuoteExtValidPOMAp.get(qids));
                for(ID stage: QuoteExtValidPOMAp.get(qids)){
                    boolean isConsultSplitted=false;
                    if(POStageHelper.poStagesToUpdateMap.containsKey(stage) && POStageHelper.poStagesToUpdateMap.get(stage).Consult_Splitted__c)
                        isConsultSplitted = true;
                    if(!(POStageHelper.poStagesToUpdateMap.containsKey(stage) && POStageHelper.poStagesToUpdateMap.get(stage).PO_Validation_Status__c == 'Failure')){
                        PO_Stage__c stg = POStageHelper.poStagesToUpdateMap.containsKey(stage) ? POStageHelper.poStagesToUpdateMap.get(stage) : new PO_Stage__c(Id = stage);
                        stg.PO_Validation_Status__c = 'Success';
                        POStageHelper.poStagesToUpdateMap.put(stg.id,stg);
                    }
                }

            }else{
                
              for(PO_Stage__c stageID: quoteMap.get(qIDS).getSObjects('Stage_PO__r')){
                         if(!SplitPOValidation.isTolerableDifference(POAmount,quoteAmount)){
                          PO_Stage_Errors__c error = new PO_Stage_Errors__c(Name = 'PO-16', Error_Code__c = 'PO-16', 
                                Error_Message__c = validationCodes.get('PO-16') != null? validationCodes.get('PO-16').Error_Issue__c +', Difference: '+ String.valueOf(Math.abs(POAmount-quoteAmount).setScale(2, System.RoundingMode.HALF_UP)): system.label.Generic_Validation_Error_Mgs, 
                                PO_Stage_Id__c = stageID.id,
                                PO_Stage_Id__r = stageID,
                                Error_Type__c = 'External'
                           );
                            errcodes.add(error);
                            if(!(POStageHelper.poStagesToUpdateMap.containsKey(stageID.id) && POStageHelper.poStagesToUpdateMap.get(stageID.id).PO_Validation_Status__c == 'Failure')){
                                PO_Stage__c stg = POStageHelper.poStagesToUpdateMap.containsKey(stageID.id) ? POStageHelper.poStagesToUpdateMap.get(stageID.id) : new PO_Stage__c(Id = stageID.id);
                                stg.PO_Validation_Status__c = 'Failure';
                                POStageHelper.poStagesToUpdateMap.put(stg.id,stg);
                            }
                         }else if(remainingValidPO != poStagedOnQuote && !(errcodes.size()>0)){
                        // If there is any Extra PO
                        
                         if(!(POStageHelper.poStagesToUpdateMap.containsKey(stageID.id) && POStageHelper.poStagesToUpdateMap.get(stageID.id).PO_Validation_Status__c == 'Internal Failure')){
                            PO_Stage__c stg = POStageHelper.poStagesToUpdateMap.containsKey(stageID.id) ? POStageHelper.poStagesToUpdateMap.get(stageID.id) : new PO_Stage__c(Id = stageID.id);
                            stg.PO_Validation_Status__c = 'Internal Failure';
                            POStageHelper.poStagesToUpdateMap.put(stg.id,stg);
                        }
                         PO_Stage_Errors__c error = new PO_Stage_Errors__c(Name = 'PO-100', Error_Code__c = 'PO-100', 
                         Error_Message__c = validationCodes.get('PO-100') != null? validationCodes.get('PO-100').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                                PO_Stage_Id__c = stageID.id,
                                PO_Stage_Id__r = stageID,
                                Error_Type__c = 'System Error'
                           );
                            errcodes.add(error);
                    }
               }
                    
                
                
            }
        
        }   
        //stagePOrBundleParentMap, quoteLineRequiredBy
        Map<String,Map<Id,List<PO_Item_Stage__c>>> toSwapQuoteLInesNumbers = new Map<String,Map<Id,List<PO_Item_Stage__c>>>();
        if(!onlyValidate){
            for(PO_Item_Stage__c pi : poItemsToUpdate){
                if((mapOfRenwLinetoSwap.containskey(pi.Stage_Po__c) && mapOfRenwLinetoSwap.get(pi.Stage_Po__c).contains(pi)) || (qliMap.get(pi.Quote_Line__c).SBQQ__Bundle__c == false &&stagePOrBundleParentMap.isEmpty() == false && stagePOrBundleParentMap.get(pi.Stage_Po__c) != null && !stagePOrBundleParentMap.get(pi.Stage_Po__c).contains(quoteLineRequiredBy.get(pi.Quote_Line__c)))){ 
                    
                    string mapKey=qliMap.get(pi.Quote_Line__c).SBQQ__ProductCode__c+''+qliMap.get(pi.Quote_Line__c).SBQQ__Quote__c+''+pi.Quantity__c;
                    if(!toSwapQuoteLInesNumbers.containsKey(mapKey)){
                        List<PO_Item_Stage__c> tempLst = new List<PO_Item_Stage__c>{pi};
                        toSwapQuoteLInesNumbers.put(mapKey, new Map<Id,List<PO_Item_Stage__c>>{pi.Stage_Po__c => tempLst});
                    }
                    else{
                        if(!toSwapQuoteLInesNumbers.get(mapKey).containsKey(pi.Stage_Po__c)){
                            toSwapQuoteLInesNumbers.get(mapKey).put(pi.Stage_Po__c,new List<PO_Item_Stage__c>{pi});
                        }
                        else{
                            toSwapQuoteLInesNumbers.get(mapKey).get(pi.Stage_Po__c).add(pi);
                        }
                        
                    }
                    //pi.Stage_Po__c = bundleParentStagePOMap.get(quoteLineRequiredBy.get(pi.Quote_Line__c));
                }
            }
        }
        for(String keyStr : toSwapQuoteLInesNumbers.keySet()){
            String po1Type = '',po2Type='';
            for(Id stagePOId : toSwapQuoteLInesNumbers.get(keyStr).keySet()){
                for(Integer i=0; i<toSwapQuoteLInesNumbers.get(keyStr).get(stagePOId).size(); i++){
                    if(toSwapQuoteLInesNumbers.get(keyStr).get(stagePOId) != null && toSwapQuoteLInesNumbers.get(keyStr).get(stagePOId).size() > 0){
                        PO_Item_Stage__c poToSwap1 = toSwapQuoteLInesNumbers.get(keyStr).get(stagePOId)[i];
                        if(bundleParentStagePOMap.get(quoteLineRequiredBy.get(poToSwap1.Quote_Line__c)) != null && 
                        toSwapQuoteLInesNumbers.get(keyStr).get(bundleParentStagePOMap.get(quoteLineRequiredBy.get(poToSwap1.Quote_Line__c))) != null
                        && toSwapQuoteLInesNumbers.get(keyStr).get(bundleParentStagePOMap.get(quoteLineRequiredBy.get(poToSwap1.Quote_Line__c))).size()>i){
                            PO_Item_Stage__c poToSwap2 = toSwapQuoteLInesNumbers.get(keyStr).get(bundleParentStagePOMap.get(quoteLineRequiredBy.get(poToSwap1.Quote_Line__c))).get(i);
                            String tempQuoteLineId = poToSwap1.Quote_Line__c;
                            poToSwap1.Quote_Line__c = poToSwap2.Quote_Line__c;
                            poToSwap1.Type__c = poToSwap2.Type__c = '';
                            if(qliMap.get(poToSwap1.Quote_Line__c).SBQQ__Group__r.Name != null && qliMap.get(poToSwap1.Quote_Line__c).SBQQ__Group__r.Name != 'Disposition Quote'){
                                poToSwap1.Type__c = qliMap.get(poToSwap1.Quote_Line__c).SBQQ__Group__r.Name == 'Renewal Quote' ? 'Renewal' : 'New';
                            }
                            if(qliMap.get(poToSwap2.Quote_Line__c).SBQQ__Group__r.Name != null && qliMap.get(poToSwap2.Quote_Line__c).SBQQ__Group__r.Name != 'Disposition Quote'){
                                poToSwap2.Type__c = qliMap.get(poToSwap2.Quote_Line__c).SBQQ__Group__r.Name == 'Renewal Quote' ? 'Renewal' : 'New';
                            }
                           // poToSwap1.Type__c = qliMap.get(poToSwap1.Quote_Line__c).SBQQ__Group__r.Name == 'Renewal Quote' && qliMap.get(poToSwap1.Quote_Line__c).SBQQ__Group__r.Name != null ? 'Renewal' : 'New';
                            poToSwap2.Quote_Line__c = tempQuoteLineId;
                           // poToSwap2.Type__c = qliMap.get(poToSwap2.Quote_Line__c).SBQQ__Group__r.Name == 'Renewal Quote' ? 'Renewal' : 'New';
                        }
                    }
                    
                }
            }
        } 
        
        if(errcodes.size()>0 && !onlyValidate){
            insert errcodes;
        }
        if(!POStageHelper.poStagesToUpdateMap.isEmpty() && !onlyValidate){
            update POStageHelper.poStagesToUpdateMap.values();
        }
        
        if(poItemsToUpdate.isEmpty() == false && !onlyValidate){
            update poItemsToUpdate;
        }
        
        if(successfullPOs.size()>0 && !onlyValidate){
            ID jobID = System.enqueueJob(new InitiateIntValidationAndOrderGeneration(successfullPOs,QuoteExtValidPOMAp,hasRcdmtIntErr));
            System.debug(LoggingLevel.DEBUG,'jobID'+jobID);
        }
        

    }
    private static List<PO_Item_Stage__c> findBestMatch(List<PO_Item_Stage__c> lstOfPI, Map<Id,Id> bundleParentStagePOMap, SBQQ__QuoteLine__c qli){
        Id StagePOId = null;
        List<PO_Item_Stage__c> matchedPO = new List<PO_Item_Stage__c>();
        if(qli.SBQQ__RequiredBy__c != null && bundleParentStagePOMap.get(qli.SBQQ__RequiredBy__c) != null){
            StagePOId = bundleParentStagePOMap.get(qli.SBQQ__RequiredBy__c);
        } 
        if(StagePOId != null){ 
            for(PO_Item_Stage__c pi : lstOfPI){
                if(pi.Stage_PO__c == StagePOId){
                    matchedPO.add(pi);
                }
            }
        }else{
            matchedPO = null; 
        }
        return matchedPO;
    }
    public static decimal calculateRubrikGoUnitPrice(Decimal term,Decimal Quant,Decimal TotalPrice){
        if(term== null)
            term =0;
        if(Quant== null)
            Quant =0;
        if(TotalPrice== null){
            TotalPrice =0;
        }
            Decimal monthlyPrice = TotalPrice/term;
            Decimal yearPricePerUnit = Quant != 0?((monthlyPrice/Quant)*12):0;
            
            return yearPricePerUnit/*.setScale(2).round(System.RoundingMode.CEILING)*/; 
        
    }
    
    public static Boolean isTolerableDifference(Decimal param1, Decimal param2){        
        Decimal difference = param1 - param2;
        difference = difference<0?difference * -1: difference;
        if(difference <= SplitPOValidation.threshold ){
            return true;
        }
        else {
            return false;
        }
    }
    
    
    public static decimal roundUpCustom(decimal param){
        if(param != null)
            return param.round(System.RoundingMode.CEILING);
        else
            return 0;
    }
    
    public class WrapProductCode{
        public decimal subscriptionTerm;
        public decimal quantity;
        public decimal totalprice;
        public string ProductCode;
        public string quoteId;
       
        public WrapProductCode(decimal subscriptionTerm,decimal quantity,decimal totalprice, string ProductCode, string quoteId){

                this.subscriptionTerm = subscriptionTerm;
                this.quantity = quantity;
                this.totalprice = totalprice;
                this.ProductCode = ProductCode;
                this.quoteId = quoteId;
        }
    }
}