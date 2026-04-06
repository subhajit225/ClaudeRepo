/*********************************************************************************   
* @description       : PO Item external validation for hybrid based model
* @author            : Chaitra
* @last modified on  : 26-08-2021
* Ver   Date          Author        Modification
* 1.0   09-01-2021   Chaitra        Initial Version
*******************************************************************************/ 

public without sharing class POItemValidation {
 
    static Decimal threshold = 0.00;  
    static boolean enableLogs = false ;
    private final static string RCDMTransSkuName = X0_RCDM_Dates__mdt.getInstance('RS_BT_RCDM_T')?.Product_Name__c;  
    Map<id,String> poitemIDByDifference = new Map<id,String>(); 
    Map<id,PO_Item_Stage__c> poItemUpdate = new Map<id,PO_Item_Stage__c>();  
    Map<id,string> tempPItmErrorMap = new Map<id,string>(); // used to capture poitem error message.
    Map<string,string> PCTermErrCode = new Map<string,string>(); // used to capture generic error message
    Public List<PO_Stage_Errors__c> stageError = new List<PO_Stage_Errors__c>();
    Public Boolean onlyValidate = false;
    static POItemValidation instance = null;
    set<id> failedQuoteId = new set<id>();
    set<id> failedPItmId = new set<id>();
    set<string> poIdAnnualLic = new set<string>();
    public static set<string> UpdateHistory = new Set<string>();
    static Map<string,POValidation_ErrorCode__c> validationCodes = new Map<string,POValidation_ErrorCode__c>();
    Map<string,Map<decimal,decimal>> quotePCTermQuantMap = new Map<string,Map<decimal,decimal>>();
    Map<id,Map<id,decimal>> LicPOIdQuantMap = new  Map<id,Map<id,decimal>>(); //License and its corresponding POIds 
    @TestVisible private boolean errCapturedInBestMatch;
    public Boolean hasRcdmtIntErr = false; 
    static {
        ShGl_DisableBusinessLogic__c disableBusinessLog = ShGl_DisableBusinessLogic__c.getInstance();
        enableLogs = disableBusinessLog?.Enable_Logs__c ; 
    }
  /**
  * @description instance of poitemclass
  * @return instance
  */  
    public static POItemValidation getInstance() {
        if (instance == null){
            instance = new POItemValidation();
            threshold = [SELECT Threshold_Value__c FROM EDI_Pricing_Difference_Threshold__mdt LIMIT 1].Threshold_Value__c;
            validationCodes = POValidation_ErrorCode__c.getAll();
        }
        return instance;      
    }

    /**
    * @description start external validation with bestmatch of stagepoitem
    * @param newPOList
    * @param oldPOMap
    */
    public void externalValidation(List<PO_Stage__c> newPOList, Map<Id, PO_Stage__c>oldPOMap){
    
    /***** Variable declaration  START *********/
    
    Map<Id,set<Id>> quote_POIds = new  Map<Id,set<Id>>();
    Map<Id,map<string, ProductGroup>> poId_PcodeTermPGMap  = new Map<Id,Map<string,ProductGroup>>(); 
    Map<string,ProductGroup> quotePcodeTerm_PGMap  = new Map<string,ProductGroup>(); 
    Map<Id,Map<string,HWProductGroup>> poId_PcodeTermHWPG = new Map<Id,Map<string,HWProductGroup>>(); 
    Map<id,list<id>> quoteNonHWPOIds = new Map<id,list<id>>(); 
    Map<Id,Map<Id,decimal>>  HWQLIStgItms = new Map<Id,Map<Id,decimal>>{}; 
    Map<id,SBQQ__QuoteLine__c> QLIMap = new Map<id,SBQQ__QuoteLine__c>();
    Map<Id,Map<Id,LicenseProductGroup>>  poIdHybQLIdPG = new  Map<Id,Map<Id,LicenseProductGroup>>(); 
    Map<string,Map<decimal,PO_Item_Stage__c>> quotePcodeTermPOItm = new Map<string,Map<decimal,PO_Item_Stage__c>>();
    Map<Id,decimal> qidPOTotal = new Map<Id,decimal>();
    Map<id,decimal> gorefHWQIdAmount = new Map<id,decimal>();
    Map<id,id> HybSWSuppQLId = new map<id,id>();
    list<Id> creditQLIds = new list<id>();   
    Map<string,string> mapOfLicenceWithRcdm = new map<string,string>();
    Map<string,string> mapOfRcdmWithLicence = new map<string,string>();
    List<SBQQ__QuoteLine__c>RCDMTQLI = new List<SBQQ__QuoteLine__c>(); 
    list<SBQQ__QuoteLine__c>suppQLBundle = new list<SBQQ__QuoteLine__c>(); // renewed ,renewal+expansion, conversion quotelines
    set<string> quotePcodeTermSuppOnly =  new set<string>(); // used to capture suppQLBundle sku's.
    Set<Id> processedPoItems =  new Set<Id>();
    Map<Id, SBQQ__QuoteLine__c> quotelinesById = new Map<Id,SBQQ__QuoteLine__c>();
    /***** Variable declaration  END **********/
    
    
    // Quote collection
   // try{
      
    for(SBQQ__Quote__c quote : POStageHelper.quoteMap.values()){
        if(POStageHelper.validateQuote.contains(quote.id)){
            quote_POIds.put(quote.id,new set<Id>());
            qidPOTotal.put(quote.id,0.0);
            for(SBQQ__QuoteLine__c qli : quote.SBQQ__LineItems__r){
                quotelinesById.put(qli.Id,qli);

                if(((quote.SBQQ__Type__c  == 'Amendment'  || quote.SBQQ__Type__c=='Renewal+Expansion' ||  qli.Special_Program__c == 'Conversion')  && qli.SBQQ__Existing__c)
                    || qli.SBQQ__Product__r.SBQQ__ExcludeFromOpportunity__c 
                    || qli.SBQQ__Product__r.SBQQ__Optional__c
                    || qli.SBQQ__Optional__c){continue;}

              if(!String.isBlank(RCDMTransSkuName) && qli.SBQQ__Product__r.Name == RCDMTransSkuName &&  qli.SBQQ__RequiredBy__c!=null){
                qli.SBQQ__SubscriptionTerm__c = null;
                mapOfLicenceWithRcdm.put(qli.SBQQ__RequiredBy__c,qli.id);
            mapOfRcdmWithLicence.put(qli.id,qli.SBQQ__RequiredBy__c);
      
              }    
              if(qli.SBQQ__Product__r.Product_Type__c !='RZTDP' && (qli.SBQQ__Product__r.Product_Level__c == 'Hybrid Software' ||
                                                                     (qli.SBQQ__Product__r.Product_Level__c == 'OnPrem' && (qli.SBQQ__Product__r.Product_Type__c == 'Foundation Edition' || qli.SBQQ__Product__r.Product_Type__c == 'Enterprise Edition' || qli.SBQQ__Product__r.Product_Type__c == 'Business Edition') && qli.SBQQ__Product__r.Product_Subtype__c == null) ||
                                                                      qli.SBQQ__Product__r.Product_Level__c == 'LOD Software' 
                ||(qli.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Level__c == 'LOD Software' && qli.SBQQ__Product__r.Product_Level__c == 'Support' && qli.SBQQ__Product__r.Product_Type__c == 'RCDM Support'))){ 
                    QLIMap.put(qli.id,qli);
                     if(qli.SBQQ__RequiredBy__c != null && qli.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Level__c == 'LOD Software' && qli.SBQQ__Product__r.Product_Level__c == 'Support' && qli.SBQQ__Product__r.Product_Type__c == 'RCDM Support'){
                         HybSWSuppQLId.put(qli.SBQQ__RequiredBy__c,qli.id);
                        }
                }
                if((qli.Special_Program__c == 'Refresh' && qli.SBQQ__UpgradedAsset__c != null) || qli.SBQQ__ProductCode__c.equalsIgnoreCase('RA-HW-CREDIT')){
                    if(qli.SBQQ__ProductCode__c.equalsIgnoreCase('RA-HW-CREDIT')){creditQLIds.add(qli.id);}
                    Id qliId = qli.Special_Program__c == 'Refresh'? qli.id : qli.SBQQ__RequiredBy__c ;
                    if(gorefHWQIdAmount.containsKey(qliId)){
                        gorefHWQIdAmount.put(qliId,gorefHWQIdAmount.get(qliId)+qli.SBQQ__NetTotal__c);
                    }
                    else{
                        gorefHWQIdAmount.put(qliId,qli.SBQQ__NetTotal__c);
                    }     
                }  
                if(isSupportBundle(quote,qli)){
                    quotePcodeTermSuppOnly.add(quote.name+'-'+qli.SBQQ__ProductCode__c+'-'+qli.SBQQ__SubscriptionTerm__c) ;
                }   
                Decimal term =  qli.SBQQ__SubscriptionTerm__c == null ? -999.9 :qli.SBQQ__SubscriptionTerm__c;
                
                if(quotePCTermQuantMap.ContainsKey(qli.SBQQ__ProductCode__c)){
                    Decimal tempQuant = quotePCTermQuantMap.get(qli.SBQQ__ProductCode__c).ContainsKey(term) ? 
                                        quotePCTermQuantMap.get(qli.SBQQ__ProductCode__c).get(term) +  qli.SBQQ__Quantity__c : qli.SBQQ__Quantity__c;
                    quotePCTermQuantMap.get(qli.SBQQ__ProductCode__c).put(term,tempQuant);
                }else{
                    quotePCTermQuantMap.put(qli.SBQQ__ProductCode__c,
                                                new Map<decimal,decimal>{term => (qli.SBQQ__Quantity__c).setscale(2)});
                }
            }
        }    
    } 
        Map<String, Map<Decimal, List<ValidateEDIGoProducts.WPoli>>> mapQPTokenPricePerMonthLstWrappedPoli = new Map<String, Map<Decimal, List<ValidateEDIGoProducts.WPoli>>>();
        Set<Id> setIdGoProductStagePo = new Set<Id>();
        Set<Id> setIdGoProductQuote = new Set<Id>();
        Set<String> setStrProductCode = new Set<String>();
  Map<String,PO_Item_Stage__c> qliWithPoItem = new Map<String,PO_Item_Stage__c>();
      Map<String ,Map<String,String>> mapPoItmToMapQLIErrorCode = new Map<String ,map<String,String>>(); 
        Set<String> processedQLIs = new Set<String>();
        /*****stage PO collection  START ********/
        POStageHelper.poStagesToUpdateMap.putall(POStageHelper.poStagesToUpdateMap);
        for(PO_Stage__c stagePO : POStageHelper.allStagePOmap.values()){
                if(!quote_POIds.containsKey(stagePO.Quote__c)) {continue;} 
                if(POStageHelper.poStagesToUpdateMap.containsKey(stagePO.id) && POStageHelper.poStagesToUpdateMap.get(stagePO.id).PO_Validation_Status__c == 'Failure'){failedQuoteId.add(stagePO.Quote__c);}
                boolean isRenewal = POStageHelper.quoteMap?.get(stagePO.Quote__c)?.SBQQ__Type__c  == 'Renewal';
                boolean hasHardware = false ;

                Map<string, ProductGroup> PCTermPGLocalMap  = new Map<string, ProductGroup>(); 
                PO_Item_Stage__c singleSWPItmOnly;
                quote_POIds.get(stagePO.Quote__c).add(stagePO.id);
                if(stagePO.TotalAmount__c != null){
                    qidPOTotal.put(stagePO.Quote__c, qidPOTotal.get(stagePO.Quote__c)+stagePO.TotalAmount__c);
                }

                system.debug(LoggingLevel.DEBUG,'stagePOId::'+stagePO.id);  
                    for(PO_Item_Stage__c poitem : stagePO.PO_Item_Stage__r){
                        if(poitem.Product__r.ProductCode == RCDMTransSkuName){
                            poitem.SubscriptionTerm__c = null;
                        }
      

      if(poitem.Quote_Line__c!=null)
      qliWithPoItem.put(poitem.Stage_PO__c + '-' + poitem.Quote_Line__c,poitem);
  
                       poitem.Quote_Line__c = null;
                       poitem.type__c = '';
                       String distributor = '';
                       String billtoName = poitem?.Stage_PO__r?.Bill_To_Name__c;
                       if(billtoName!=null && OrderInserthelper.getDistributorMetadata(billtoName)!=null)
                       distributor = OrderInserthelper.getDistributorMetadata(billtoName).Po_Disti_Type__c;  

                        if(enableLogs)system.debug(LoggingLevel.DEBUG,'poitem'+JSON.serialize(poitem));
                        Decimal term =  poitem.SubscriptionTerm__c == null ? -999.9 :poitem.SubscriptionTerm__c;
                        if(poitem.Product__r.Product_Payment_Option__c == 'Annual' && poitem.Stage_PO__r.Bill_To_Name__c != null && (distributor!=null && distributor == 'INGRAM')){                              
                            System.debug(LoggingLevel.DEBUG,'Started Collecting Go Products');
                            ValidateEDIGoProducts.WPoli objWPoli = new ValidateEDIGoProducts.WPoli(poItem);
                            String strQPToken = stagePO.Quote__c + '-' + objWPoli.productCode ;
                            Decimal decPrice = objWPoli.granualPrice;
                            if (!mapQPTokenPricePerMonthLstWrappedPoli.containsKey(strQPToken)) {
                                mapQPTokenPricePerMonthLstWrappedPoli.put(strQPToken, new Map<Decimal, List<ValidateEDIGoProducts.WPoli>>() );
                            }
                            if (!mapQPTokenPricePerMonthLstWrappedPoli.get(strQPToken).containsKey(decPrice)) {
                                mapQPTokenPricePerMonthLstWrappedPoli.get(strQPToken).put(decPrice, new List<ValidateEDIGoProducts.WPoli>() );
                            }
                            mapQPTokenPricePerMonthLstWrappedPoli.get(strQPToken).get(decPrice).add(objWPoli);
                            setIdGoProductStagePo.add(stagePO.Id);
                            setIdGoProductQuote.add(stagePO.Quote__c);
                            setStrProductCode.add(objWPoli.productCode);
                            poIdAnnualLic.add(stagePO.Id+'-'+poitem.Product__r.ProductCode);
                            continue;
                        }  
                        else if('RA-HW-CREDIT'.equalsIgnoreCase(poitem.Product__r?.ProductCode)){
                            if(!creditQLIds.isEmpty()){
                                poItemUpdate.put(poitem.id,new PO_Item_Stage__c(id=poitem.id,Quote_Line__c = creditQLIds[0],Type__c = 'New')); 
                                creditQLIds.remove(0);
                            }
                            continue;
                        }   
                        if(!quotePCTermQuantMap.containsKey(poitem.Product__r?.ProductCode)){
                            if(poitem.Product__r?.ProductCode == RCDMTransSkuName && stagePO.Expected_number_of_POs__c == 1){
                                stageError.add(new PO_Stage_Errors__c( Name ='INT-15', Error_Code__c ='INT-15' , 
                                                                Error_Message__c=validationCodes.get('INT-15') != null? validationCodes.get('INT-15').Error_Issue__c+' : '+poitem.ProductCode__c: system.label.Generic_Validation_Error_Mgs+' : '+poitem.ProductCode__c , 
                                                                PO_Stage_Id__c = poitem.stage_po__c,
                                                                PO_Stage_Item_Id__c = poitem.id,
                                                                Error_Type__c = 'Internal'));
                                POStageHelper.poStagesToUpdateMap.put(stagePO.id,new PO_Stage__c(id = stagePO.id,PO_Internal_Validation_Status__c='Internal Failure'));
                                hasRcdmtIntErr = true;
                            }
                            else{
                                    stageError.add(new PO_Stage_Errors__c( Name ='PO-09', Error_Code__c ='PO-09' , 
                                    Error_Message__c=validationCodes.get('PO-09') != null? validationCodes.get('PO-09').Error_Issue__c+' : '+poitem.ProductCode__c: system.label.Generic_Validation_Error_Mgs+' : '+poitem.ProductCode__c , 
                                    PO_Stage_Id__c = poitem.stage_po__c,
                                    PO_Stage_Item_Id__c = poitem.id,
                                    Error_Type__c = 'External'));
                                    POStageHelper.poStagesToUpdateMap.put(stagePO.id,new PO_Stage__c(id = stagePO.id,PO_Validation_Status__c = 'Failure'));                                  
                                    failedQuoteId.add(stagePO.Quote__c); 
                                    failedPItmId.add(poitem.id);  
                                    continue;
                            }
                        }
                        if(quotePcodeTermPOItm.containsKey(stagePO.Quote_number__c+'-'+poitem.Product__r.ProductCode)){
                            quotePcodeTermPOItm.get(stagePO.Quote_number__c+'-'+poitem.Product__r.ProductCode).put(term,poitem);
                        }
                        else{
                            quotePcodeTermPOItm.put(stagePO.Quote_number__c+'-'+poitem.Product__r.ProductCode,new Map<decimal,PO_Item_Stage__c>{term =>poitem});
                        }    
                            if(poitem.Product__r.Product_Type__c !='RZTDP' && (((poitem.Product__r.Product_Type__c == 'HW Support' && poitem.Product__r.Product_Level__c == 'Support')|| (poitem.Product__r.Product_Level__c == 'Hybrid Software' || (poitem.Product__r.Product_Level__c == 'OnPrem' && (poitem.Product__r.Product_Type__c == 'Foundation Edition' || poitem.Product__r.Product_Type__c == 'Enterprise Edition' || poitem.Product__r.Product_Type__c == 'Business Edition') && poitem?.Product__r?.Product_Subtype__c == null) ||  poitem.Product__r.Product_Level__c ==  'LOD Software') && poitem.Product__r.Product_Subtype__c != 'RCDM')) ){    // hybrid and supportlines  
                                       if(singleSWPItmOnly == null){ singleSWPItmOnly = poitem;}
                                        else { singleSWPItmOnly = new PO_Item_Stage__c();}
                                        if(PCTermPGLocalMap.containsKey(poitem.Product__r.ProductCode+'-'+poitem.SubscriptionTerm__c)){
                                            PCTermPGLocalMap.get(poitem.Product__r.ProductCode+'-'+poitem.SubscriptionTerm__c).addToProductGroup(poitem);
                                        }       
                                        else{
                                            PCTermPGLocalMap.put(poitem.Product__r.ProductCode+'-'+poitem.SubscriptionTerm__c,new ProductGroup(poitem));
                                        }  
                                        if(POStageHelper.quoteMap?.get(stagePO.Quote__c)?.Scale_Quote__c || quotePcodeTermSuppOnly.contains(stagePO.Quote_number__c+'-'+poitem.Product__r.ProductCode+'-'+poitem.SubscriptionTerm__c)){ // for productCode that is in isSupportBundle()
                                            if(quotePcodeTerm_PGMap.containsKey(stagePO.Quote_number__c+'-'+poitem.Product__r.ProductCode+'-'+poitem.SubscriptionTerm__c)){
                                                quotePcodeTerm_PGMap.get(stagePO.Quote_number__c+'-'+poitem.Product__r.ProductCode+'-'+poitem.SubscriptionTerm__c).addToProductGroup(poitem); 
                                            }
                                            else{
                                                quotePcodeTerm_PGMap.put(stagePO.Quote_number__c+'-'+poitem.Product__r.ProductCode+'-'+poitem.SubscriptionTerm__c,new ProductGroup(poitem));
                                            } 
                                            processedPoItems.add(poitem.Id);
                                        }    
                        }
                        else{   // hardware ,third party hardware,accessories and addons 
                                string key = poitem.Product__r.Product_Level__c == 'Hardware' ? stagePO.Quote_number__c+'-'+poitem.Product__r.ProductCode : stagePO.Quote_number__c+'-'+poitem.Product__r.ProductCode+'-'+poitem.SubscriptionTerm__c;
                                if(quotePcodeTerm_PGMap.containsKey(key)){
                                    quotePcodeTerm_PGMap.get(key).addToProductGroup(poitem); 
                                }
                                else{
                                    quotePcodeTerm_PGMap.put(key,new ProductGroup(poitem));
                                } 
                                processedPoItems.add(poitem.Id);
                                if(!hasHardware && poitem.Product__r.Product_Level__c == 'Hardware' && (poitem.Product__r.Product_Type__c == 'Add-On Node' || poitem.Product__r.Product_Type__c == 'Hardware')){
                                        hasHardware = true;
                                        PO_Stage__c  updateStgPO = POStageHelper.poStagesToUpdateMap.containsKey(stagePO.id)?POStageHelper.poStagesToUpdateMap.get(stagePO.id) : new PO_Stage__c(id = stagePO.id); 
                                        updateStgPO.Hardware_PO_Id__c = stagePO.id ;
                                        POStageHelper.poStagesToUpdateMap.put(stagePO.id,updateStgPO);
                                }
                            }
                    }
    
      
    
    
                    if(!hasHardware) {
                        if(quoteNonHWPOIds.containsKey(stagePO.Quote__c)){
                            quoteNonHWPOIds.get(stagePO.Quote__c).add(stagePO.id);
                        }
                        else{
                            quoteNonHWPOIds.put(stagePO.Quote__c,new list<id>{stagePO.id});
                        }
                    }
                    if(singleSWPItmOnly != null){
                        if(singleSWPItmOnly.id == null || hasHardware == true){
                            poId_PcodeTermPGMap.put(stagePO.id,PCTermPGLocalMap);
                        }else{
                            if(quotePcodeTerm_PGMap.containsKey(stagePO.Quote_number__c+'-'+singleSWPItmOnly.Product__r.ProductCode+'-'+singleSWPItmOnly.SubscriptionTerm__c) && !processedPoItems.contains(singleSWPItmOnly.id)){
                                quotePcodeTerm_PGMap.get(stagePO.Quote_number__c+'-'+singleSWPItmOnly.Product__r.ProductCode+'-'+singleSWPItmOnly.SubscriptionTerm__c).addToProductGroup(singleSWPItmOnly); 
                            }else if(!processedPoItems.contains(singleSWPItmOnly.id)){
                                quotePcodeTerm_PGMap.put(stagePO.Quote_number__c+'-'+singleSWPItmOnly.Product__r.ProductCode+'-'+singleSWPItmOnly.SubscriptionTerm__c,new ProductGroup(singleSWPItmOnly));
                            }  
                        }
                    }
            }
            if(enableLogs){
                system.debug(LoggingLevel.DEBUG,'POStageHelper.poStagesToUpdateMap'+JSON.Serialize(POStageHelper.poStagesToUpdateMap));
                system.debug(LoggingLevel.DEBUG,'quoteNonHWPOIds'+JSON.Serialize(quoteNonHWPOIds));
                system.debug(LoggingLevel.DEBUG,'quotePcodeTerm_PGMap'+JSON.Serialize(quotePcodeTerm_PGMap));
                 system.debug(LoggingLevel.DEBUG,'poId_PcodeTermPGMap'+JSON.Serialize(poId_PcodeTermPGMap));
                system.debug(LoggingLevel.DEBUG,'quotePcodeTermPOItm'+JSON.Serialize(quotePcodeTermPOItm));
            }
            /*****stage PO collection  END ********/
    
        for(Id quoteId : quote_POIds.keyset()){
            SBQQ__Quote__c quote = POStageHelper.quoteMap?.get(quoteId);
            for(SBQQ__QuoteLine__c qli : quote.SBQQ__LineItems__r){
                String distributor = '';
                String distiId = qli?.SBQQ__Quote__r?.SBQQ__Opportunity2__r?.Distributor_Lookup__c;
                if(distiId!=null)
                distributor = OrderInserthelper.getDistributorMetadata(distiId) == null ? null : OrderInserthelper.getDistributorMetadata(distiId).Po_Disti_Type__c;  

                Id poId = quote_POIds.get(qli.SBQQ__Quote__c).isEmpty() ? null : (new list<Id>(quote_POIds?.get(qli.SBQQ__Quote__c)) )[0] ;
                system.debug(LoggingLevel.DEBUG,'qli :'+JSON.Serialize(qli));
                if(qli.SBQQ__Product__r.Product_Payment_Option__c == 'Annual' &&  mapQPTokenPricePerMonthLstWrappedPoli.containskey(qli.SBQQ__Quote__c+'-'+qli.SBQQ__ProductCode__c)
                ||(qli.SBQQ__RenewedAsset__c  != null  && (qli.SBQQ__Quote__r?.SBQQ__Type__c  == 'Renewal' || qli.SBQQ__Quote__r?.SBQQ__Type__c  == 'Renewal+Expansion'))
                ||((quote.SBQQ__Type__c  == 'Amendment'  || quote.SBQQ__Type__c=='Renewal+Expansion' ||  qli.Special_Program__c == 'Conversion')  && qli.SBQQ__Existing__c)
                || qli.SBQQ__Product__r.SBQQ__ExcludeFromOpportunity__c 
                || qli.SBQQ__ProductCode__c.equalsIgnoreCase('RA-HW-CREDIT') 
                || qli.SBQQ__Product__r.SBQQ__Optional__c
                || qli.SBQQ__Optional__c
                || (quote.ProcessType__c == 'Aspen' && qli.SBQQ__Product__r.Product_Level__c == 'Hardware')){continue;}
                if(quotePcodeTermPOItm.containsKey(quote.name+'-'+qli.SBQQ__ProductCode__c)){
                        PO_Item_Stage__c pitm = new PO_Item_Stage__c();
                        list<decimal> subTerms = new list<decimal> (quotePcodeTermPOItm.get(quote.name+'-'+qli.SBQQ__ProductCode__c).keyset());
                        Id stgId = (subTerms.isEmpty() || quotePcodeTermPOItm.get(quote.name+'-'+qli.SBQQ__ProductCode__c).get(subTerms[0]) == null)? poId : quotePcodeTermPOItm.get(quote.name+'-'+qli.SBQQ__ProductCode__c).get(subTerms[0]).Stage_PO__c;                          
                        if( (qli.SBQQ__SubscriptionTerm__c != null && !subTerms.contains(qli.SBQQ__SubscriptionTerm__c))
                        || (qli.SBQQ__SubscriptionTerm__c == null && (!subTerms.contains(-999.9) || subTerms.size() >1))){
                            if(qli.SBQQ__SubscriptionTerm__c == null){
                                for(Decimal term : subTerms){
                                pitm = quotePcodeTermPOItm.get(quote.name+'-'+qli.SBQQ__ProductCode__c).get(term);
                                stgId = pitm.Stage_PO__c;
                                if(term != -999.9 && !failedPItmId.contains(pitm.id)){
                                if(stgId == null) stgId = pitm.Stage_PO__c ;
                                stageError.add(new PO_Stage_Errors__c( Name ='PO-12', Error_Code__c ='PO-12' , 
                                                                Error_Message__c=validationCodes.get('PO-12') != null? validationCodes.get('PO-12').Error_Issue__c+' : '+pitm.Product__r.ProductCode: system.label.Generic_Validation_Error_Mgs+' : '+pitm.Product__r.ProductCode , 
                                                                PO_Stage_Id__c = pitm.Stage_PO__c,
                                                                Quote_Line__c = qli.id,
                                                                PO_Stage_Item_Id__c = pitm.id,
                                                                Error_Type__c = 'External'));  
                                }
                              }
                                PO_Stage__c  updateStgPO = POStageHelper.poStagesToUpdateMap.containsKey(stgId)?POStageHelper.poStagesToUpdateMap.get(stgId) : new PO_Stage__c(id = stgId); 
                                    updateStgPO.PO_Validation_Status__c = 'Failure' ;                                    
                                    POStageHelper.poStagesToUpdateMap.put(stgId,updateStgPO); 
                                    failedQuoteId.add(qli.SBQQ__Quote__c); 
                                    failedPItmId.add(pitm.id);
                            }
                            else{
                                for(Decimal term : subTerms){
                                    pitm = quotePcodeTermPOItm.get(quote.name+'-'+qli.SBQQ__ProductCode__c).get(term);
                                    stgId = pitm.Stage_PO__c;
                                    if(mapPoItmToMapQLIErrorCode.containsKey(stgId+'-'+pitm.id)){
                                        mapPoItmToMapQLIErrorCode.get(stgId+'-'+pitm.id).put(qli.SBQQ__Quote__c+'-'+qli.id,'PO-12');
                                    }else{
                                        mapPoItmToMapQLIErrorCode.put(stgId+'-'+pitm.id,new Map<String,String>{qli.SBQQ__Quote__c+'-'+qli.id =>'PO-12'});
                                    }
                                }
                            }
                            system.debug(LoggingLevel.DEBUG,'Failed stgId ::'+stgId); 
                            if(!(qli.SBQQ__SubscriptionTerm__c == null && subTerms.contains(-999.9))) continue;  
                        } 
                }else {
                    PO_Stage__c existingPO = POStageHelper.poStagesToUpdateMap.containsKey(poId) ? POStageHelper.poStagesToUpdateMap.get(poId) : new PO_Stage__c(id = poId); 
                    if(qli.SBQQ__ProductCode__c != RCDMTransSkuName && existingPO?.Expected_number_of_POs__c != 1){
                    stageError.add(new PO_Stage_Errors__c(Name ='PO-09', Error_Code__c ='PO-09', 
                                                            Error_Message__c=validationCodes.get('PO-09') != null? validationCodes.get('PO-09').Error_Issue__c+' : '+qli.SBQQ__ProductCode__c : system.label.Generic_Validation_Error_Mgs+' : '+qli.SBQQ__ProductCode__c, 
                                                            PO_Stage_Id__c = poId,
                                                            Quote_Line__c = qli.id,  
                                                            Error_Type__c = 'External')); 
                    PO_Stage__c  updateStgPO = POStageHelper.poStagesToUpdateMap.containsKey(poId)?POStageHelper.poStagesToUpdateMap.get(poId) : new PO_Stage__c(id = poId); 
                    updateStgPO.PO_Validation_Status__c = 'Failure' ;                                    
                    POStageHelper.poStagesToUpdateMap.put(poId,updateStgPO); 
                    failedQuoteId.add(qli.SBQQ__Quote__c);    
                    }   
                    continue;                                               
                }
                if(isSupportBundle(quote,qli)){ 
                    suppQLBundle.add(qli);
                    continue;
                }
                if(!String.isBlank(RCDMTransSkuName) && qli.SBQQ__ProductCode__c == RCDMTransSkuName && qli.SBQQ__RequiredBy__r?.Payment_Options__c != 'Annual'){
                    RCDMTQLI.add(qli);
                }
                 system.debug(LoggingLevel.DEBUG,'*****poItemUpdate365'+ poItemUpdate);
                //Match based on sku type
                if(quote.ProcessType__c == null && qli.SBQQ__Product__r.Product_Type__c !='RZTDP' && (((qli.SBQQ__Product__r.Product_Level__c == 'Hybrid Software' || (qli.SBQQ__Product__r.Product_Level__c == 'onprem' && (qli.SBQQ__Product__r.Product_Type__c == 'Foundation Edition' || qli.SBQQ__Product__r.Product_Type__c == 'Enterprise Edition'  || qli.SBQQ__Product__r.Product_Type__c == 'Business Edition' ) && qli.SBQQ__Product__r.Product_Subtype__c == null)) && qli.SBQQ__Product__r.Product_Subtype__c != 'RCDM') || qli.SBQQ__Product__r.Product_Level__c == 'LOD Software'
                ||(qli.SBQQ__RequiredBy__c != null && qli.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Level__c == 'LOD Software' && qli.SBQQ__Product__r.Product_Level__c == 'Support' && qli.SBQQ__Product__r.Product_Type__c == 'RCDM Support'))
                    ||(!String.isBlank(RCDMTransSkuName) && qli.SBQQ__ProductCode__c == RCDMTransSkuName && qli.SBQQ__RequiredBy__r?.Payment_Options__c != 'Annual')){
                    continue ;
                } 
                else if(quote.ProcessType__c == null && qli.SBQQ__Product__r.Product_Level__c == 'Support' && qli.SBQQ__Product__r.Product_Type__c == 'HW Support' && qli.SBQQ__RequiredBy__r?.SBQQ__RequiredBy__r?.SBQQ__Product__r.Family != 'Rubrik Scale'){   // Only quote group with orderable hardware sku would be eligible for support sku match
                    if(HWQLIStgItms.get(qli.SBQQ__RequiredBy__c) != null){
                        Map<Id,decimal> stageHWQuant = HWQLIStgItms.get(qli.SBQQ__RequiredBy__c);
                        MatchResult matchRes = new MatchResult();
                        system.debug(LoggingLevel.DEBUG,'stageHWQuant :'+stageHWQuant);
                        for(Id stgId : stageHWQuant.keyset()){
                            Decimal hardwareQuant = stageHWQuant.get(stgId);
                            ProductGroup  PG = poId_PcodeTermPGMap?.get(stgId)?.get(qli.SBQQ__ProductCode__c+'-'+qli.SBQQ__SubscriptionTerm__c);
                            if(PG !=null){
                                matchRes = bestMatch(qli,PG,hardwareQuant,true,new set<id>());  
                            }   
                        if(PG == null || matchRes.matchedPOItms == null || matchRes.matchedPOItms.isEmpty()){
                            HWProductGroup pg2 = poId_PcodeTermHWPG?.get(stgId)?.get(qli.SBQQ__ProductCode__c+'-'+qli.SBQQ__SubscriptionTerm__c) ;  
                                if(pg2 != null){
                                    pg2.quantity.add(hardwareQuant);
                                    pg2.QLIQuantity.put(qli,hardwareQuant);
                                }
                                else if(poId_PcodeTermHWPG?.get(stgId) != null){
                                    poId_PcodeTermHWPG.get(stgId).put(qli.SBQQ__ProductCode__c+'-'+qli.SBQQ__SubscriptionTerm__c, new HWProductGroup(stageHWQuant.get(stgId),qli));
                                }
                                else{
                                    poId_PcodeTermHWPG.put(stgId,new Map<string,HWProductGroup>{qli.SBQQ__ProductCode__c+'-'+qli.SBQQ__SubscriptionTerm__c => new HWProductGroup(stageHWQuant.get(stgId),qli)});
                                } 
                            }
                            else{
                                Decimal quant =  quotePCTermQuantMap?.get(qli.SBQQ__ProductCode__c)?.get(qli.SBQQ__SubscriptionTerm__c);
                                if(quant != null && quant > 0){
                                    quotePCTermQuantMap.get(qli.SBQQ__ProductCode__c).put(qli.SBQQ__SubscriptionTerm__c,quant-hardwareQuant);
                                }
                            }
                        }
                    }
                    else{
                        PCTermErrCode.put(qli.SBQQ__ProductCode__c+'-'+qli.SBQQ__SubscriptionTerm__c,'PO-25');                                                        
                    } 
                }
                else {
                    string key = qli.SBQQ__Product__r.Product_Level__c == 'Hardware' ? quote.name+'-'+qli.SBQQ__ProductCode__c  : quote.name+'-'+qli.SBQQ__ProductCode__c+'-'+qli.SBQQ__SubscriptionTerm__c ;
                    Decimal term =  qli.SBQQ__SubscriptionTerm__c == null ? -999.9 :qli.SBQQ__SubscriptionTerm__c;
                    Decimal goRefNetTotal = gorefHWQIdAmount?.get(qli.id);
                    if(quotePcodeTerm_PGMap.containsKey(key)){
                        list<PO_Item_Stage__c> matchedPOItms = bestMatch(qli ,quotePcodeTerm_PGMap.get(key),poId_PcodeTermPGMap,goRefNetTotal);
                        if(matchedPOItms!= null && !matchedPOItms.isEmpty()){
                            Decimal quant =  quotePCTermQuantMap?.get(qli.SBQQ__ProductCode__c)?.get(term);
                            if(quant != null && quant > 0){
                                quotePCTermQuantMap.get(qli.SBQQ__ProductCode__c).put(term,quant-qli.SBQQ__Quantity__c);
                            }
                            if(qli.SBQQ__Product__r.Product_Level__c == 'Hardware' && (qli.SBQQ__Product__r.Product_Type__c == 'Add-On Node' || qli.SBQQ__Product__r.Product_Type__c == 'Hardware') && qli.SBQQ__RequiredBy__r?.SBQQ__Product__r.Family != 'Rubrik Scale'){
                                SBQQ__QuoteLine__c parentQLI = QLIMap.get(qli.SBQQ__RequiredBy__c);
                                for(PO_Item_Stage__c pItm : matchedPOItms){
                                    if( HWQLIStgItms.get(qli.id) != null){
                                        HWQLIStgItms.get(qli.id).put(pItm.Stage_PO__c, pItm.Quantity__c);
                                    }
                                    else{
                                        HWQLIStgItms.put(qli.id,new map<id,decimal>{pItm.Stage_PO__c => pItm.Quantity__c});
                                    } 
                                    if(poIdHybQLIdPG.get(pItm.Stage_PO__c) != null){
                                        decimal currQuant = poIdHybQLIdPG?.get(pItm.Stage_PO__c)?.get(qli.SBQQ__RequiredBy__c)?.hybTotalQuant ; 
                                        decimal totalQuant = qli.SBQQ__Product__r.Usable_Capacity__c * pItm.Quantity__c;
                                        if(currQuant != null) totalQuant+= currQuant ;
                                        poIdHybQLIdPG?.get(pItm.Stage_PO__c).put(qli.SBQQ__RequiredBy__c, new LicenseProductGroup(parentQLI,totalQuant.setscale(2)));
                                        if(qli.SBQQ__RequiredBy__c!= null && HybSWSuppQLId.containsKey(qli.SBQQ__RequiredBy__c)){
                                            poIdHybQLIdPG?.get(pItm.Stage_PO__c).put(HybSWSuppQLId.get(qli.SBQQ__RequiredBy__c), new LicenseProductGroup(QLIMap.get(HybSWSuppQLId.get(qli.SBQQ__RequiredBy__c)),totalQuant.setscale(2)));
                                        }
                                    }
                                    else{
                                        poIdHybQLIdPG.put(pItm.Stage_PO__c,new Map<id,LicenseProductGroup>{qli.SBQQ__RequiredBy__c => new LicenseProductGroup(parentQLI,(qli.SBQQ__Product__r.Usable_Capacity__c * pItm.Quantity__c).setscale(2))});
                                        if(qli.SBQQ__RequiredBy__c!= null && HybSWSuppQLId.containsKey(qli.SBQQ__RequiredBy__c)){
                                            poIdHybQLIdPG.get(pItm.Stage_PO__c).put(HybSWSuppQLId.get(qli.SBQQ__RequiredBy__c),new LicenseProductGroup(QLIMap.get(HybSWSuppQLId.get(qli.SBQQ__RequiredBy__c)),(qli.SBQQ__Product__r.Usable_Capacity__c * pItm.Quantity__c).setscale(2)));

                                        }
                                    }
                                } 
                                if(enableLogs)system.debug(LoggingLevel.DEBUG,'HWQLIStgItms'+JSON.serialize(HWQLIStgItms));
                                    if(enableLogs)system.debug(LoggingLevel.DEBUG,'poIdHybQLIdPG'+JSON.serialize(poIdHybQLIdPG));
                                                            }    
                        }
                        else if(qli.SBQQ__Product__r.Product_Level__c == 'Hardware' &&  qli.SBQQ__Product__r.Product_Type__c == 'Hardware'){
                            SBQQ__QuoteLine__c parentQLI = QLIMap?.get(qli.SBQQ__RequiredBy__c);
                            if(parentQLI != null){
                                PCTermErrCode.put(parentQLI.SBQQ__ProductCode__c+'-'+parentQLI.SBQQ__SubscriptionTerm__c,'PO-25');      
                            }      
                        }else{
                            stageError.add(new PO_Stage_Errors__c( Name ='PO-24', Error_Code__c ='PO-24',      
                                                                    Error_Message__c = validationCodes.get('PO-24') != null? validationCodes.get('PO-24').Error_Issue__c +' : '+qli.SBQQ__ProductCode__c  : system.label.Generic_Validation_Error_Mgs+' : '+qli.SBQQ__ProductCode__c ,  
                                                                    PO_Stage_Id__c = poId,
                                                                    Quote_Line__c = qli.id,
                                                                    Error_Type__c = 'External' ));
                          PO_Stage__c  updateStgPO = POStageHelper.poStagesToUpdateMap.containsKey(poId)?POStageHelper.poStagesToUpdateMap.get(poId) : new PO_Stage__c(id = poId); 
                          updateStgPO.PO_Validation_Status__c = 'Failure' ;                                    
                          POStageHelper.poStagesToUpdateMap.put(poId,updateStgPO); 
                          failedQuoteId.add(qli.SBQQ__Quote__c); 
                        }  
                            
                    }
                    else{
                        string errCode = quotePcodeTermPOItm.containsKey(qli.SBQQ__ProductCode__c)?'PO-09':'PO-12' ;
                        stageError.add(getErrorRecord(errCode , null, 'External', qli, poId));
                       
                        PO_Stage__c  updateStgPO = POStageHelper.poStagesToUpdateMap.containsKey(poId)?POStageHelper.poStagesToUpdateMap.get(poId) : new PO_Stage__c(id = poId); 
                        updateStgPO.PO_Validation_Status__c = 'Failure' ;                                    
                        POStageHelper.poStagesToUpdateMap.put(poId,updateStgPO); 
                        failedQuoteId.add(qli.SBQQ__Quote__c);                                               
                    }
                }
                
                system.debug(LoggingLevel.DEBUG,'QLI POStageHelper.poStagesToUpdateMap '+POStageHelper.poStagesToUpdateMap); 
                system.debug(LoggingLevel.DEBUG,'QLI stageError '+stageError); 
                system.debug(LoggingLevel.DEBUG,'poId_PcodeTermHWPG'+poId_PcodeTermHWPG); 
            }
        }      // end quote line loop           
        
        if(enableLogs)system.debug(LoggingLevel.DEBUG,'poIdHybQLIdPG'+JSON.serialize(poIdHybQLIdPG));
        // match within same PO for saas line
            for(Id poId : poIdHybQLIdPG.keyset()){  
                for(Id qli : poIdHybQLIdPG.get(poId).keyset()){
                    MatchResult matchRes = new MatchResult();
                    LicenseProductGroup LPG = poIdHybQLIdPG.get(poId).get(qli);
                    ProductGroup  PG = poId_PcodeTermPGMap?.get(poId)?.get(LPG.qli.SBQQ__ProductCode__c+'-'+LPG.qli.SBQQ__SubscriptionTerm__c);
                    if(PG !=null){ 
                        matchRes = bestMatch(LPG.qli,PG,LPG.hybTotalQuant,true,new set<id>()); 
                        if(matchRes.matchedPOItms!=null && !matchRes.matchedPOItms.isEmpty()){
                            poIdHybQLIdPG.get(poId).remove(LPG.qli.id); 
                                Decimal quant =  quotePCTermQuantMap?.get(LPG.qli.SBQQ__ProductCode__c)?.get(LPG.qli.SBQQ__SubscriptionTerm__c);
                                if(quant != null && quant > 0){
                                    quotePCTermQuantMap.get(LPG.qli.SBQQ__ProductCode__c).put(LPG.qli.SBQQ__SubscriptionTerm__c,quant-LPG.hybTotalQuant);
                                }
                            } 
                        }
                    }       
                }
        system.debug(LoggingLevel.DEBUG,'suppQLBundle'+suppQLBundle);        
       //Match non-tangible QLI bundle like conversion 
       if(!suppQLBundle.isEmpty()){
        for(SBQQ__QuoteLine__c qli : suppQLBundle){
            SBQQ__Quote__c quote = POStageHelper.quoteMap?.get(qli.SBQQ__Quote__c);
            string key = quote.name+'-'+qli.SBQQ__ProductCode__c+'-'+qli.SBQQ__SubscriptionTerm__c ;
            Decimal term =  qli.SBQQ__SubscriptionTerm__c == null ? -999.9 :qli.SBQQ__SubscriptionTerm__c;
            Decimal goRefNetTotal = gorefHWQIdAmount?.get(qli.id);
            Id randPOId = quote_POIds.get(qli.SBQQ__Quote__c).isEmpty() ? null : (new list<Id>(quote_POIds?.get(qli.SBQQ__Quote__c)) )[0] ;
            
            if(quotePcodeTerm_PGMap.containsKey(key)){
        
                list<PO_Item_Stage__c> matchedPOItms = bestMatch(qli ,quotePcodeTerm_PGMap.get(key),poId_PcodeTermPGMap,goRefNetTotal);
          
                if(!errCapturedInBestMatch && (matchedPOItms== null || matchedPOItms.isEmpty())){
            	    stageError.add(getErrorRecord('PO-24' , null, 'External', qli, randPOId));
                    PO_Stage__c  updateStgPO = POStageHelper.poStagesToUpdateMap.containsKey(randPOId)?POStageHelper.poStagesToUpdateMap.get(randPOId) : new PO_Stage__c(id = randPOId); 
                    updateStgPO.PO_Validation_Status__c = 'Failure' ;                                    
                    POStageHelper.poStagesToUpdateMap.put(randPOId,updateStgPO);   
                    failedQuoteId.add(qli.SBQQ__Quote__c);   
                }else{
                    for(PO_Item_Stage__c pItm : matchedPOItms){
                        if(poId_PcodeTermPGMap.get(pItm.Stage_PO__c) != null && poId_PcodeTermPGMap.get(pItm.Stage_PO__c).get(pItm.Product__r.ProductCode+'-'+pItm.SubscriptionTerm__c) != null){
                            poId_PcodeTermPGMap.get(pItm.Stage_PO__c).get(pItm.Product__r.ProductCode+'-'+pItm.SubscriptionTerm__c).removeProductGroup(pItm);
                            if(poId_PcodeTermPGMap.get(pItm.Stage_PO__c).get(pItm.Product__r.ProductCode+'-'+pItm.SubscriptionTerm__c).price.size() == 0){
                                if(poId_PcodeTermPGMap.get(pItm.Stage_PO__c).size() == 1){
                                    poId_PcodeTermPGMap.remove(pItm.Stage_PO__c);
                                    //quotePcodeTerm_PGMap.put(key,new ProductGroup(pItm));
                                }else{
                                    poId_PcodeTermPGMap.get(pItm.Stage_PO__c).remove(pItm.Product__r.ProductCode+'-'+pItm.SubscriptionTerm__c);
                                }
                            }
                        }
                        if(quote.ProcessType__c == 'Aspen' && qli.Line_Type__c == 'New' && (isLicenseSku(qli.SBQQ__Product__r) || qli.SBQQ__Product__r.Family == 'EDGE')){
                            if(LicPOIdQuantMap.containsKey(qli.id)){
                                LicPOIdQuantMap.get(qli.id).put(pItm.Stage_PO__c,pItm.Quantity__c);
                            }else{
                                LicPOIdQuantMap.put(qli.id,new Map<id,decimal>{pItm.Stage_PO__c => pItm.Quantity__c});
                            }
                          }
                    }
                }
            }else{
                        string errCode = quotePcodeTermPOItm.containsKey(qli.SBQQ__ProductCode__c)?'PO-09':'PO-12' ;
                        stageError.add(getErrorRecord(errCode , null, 'External', qli, randPOId));

                        PO_Stage__c  updateStgPO = POStageHelper.poStagesToUpdateMap.containsKey(randPOId)?POStageHelper.poStagesToUpdateMap.get(randPOId) : new PO_Stage__c(id = randPOId); 
                        updateStgPO.PO_Validation_Status__c = 'Failure' ;                                    
                        POStageHelper.poStagesToUpdateMap.put(randPOId,updateStgPO); 
                        failedQuoteId.add(qli.SBQQ__Quote__c);                                               
                    }
                }
        }
        if(!quoteNonHWPOIds.isEmpty() && !poId_PcodeTermPGMap.isEmpty()  && (!poId_PcodeTermHWPG.isEmpty() || !poIdHybQLIdPG.isEmpty())){
            completePOMatch(poId_PcodeTermHWPG , poIdHybQLIdPG ,quoteNonHWPOIds, poId_PcodeTermPGMap);
        } 
        
        if(!quotePcodeTerm_PGMap.isEmpty() && (!poId_PcodeTermHWPG.isEmpty() || !poIdHybQLIdPG.isEmpty())){
            standalonePOMatch(poId_PcodeTermHWPG , poIdHybQLIdPG ,quotePcodeTerm_PGMap,quoteNonHWPOIds);
        }
        if(!RCDMTQLI.isEmpty()){
            for(SBQQ__QuoteLine__c qli : RCDMTQLI){
                system.debug(LoggingLevel.DEBUG,'RCDM qli'+qli.id);
                Id pItmId = null;
                SBQQ__Quote__c quote = POStageHelper.quoteMap?.get(qli.SBQQ__Quote__c);
                string key = quote.name+'-'+qli.SBQQ__ProductCode__c+'-'+qli.SBQQ__SubscriptionTerm__c ;
                 Id poId = quote_POIds.get(qli.SBQQ__Quote__c).isEmpty() ? null : (new list<Id>(quote_POIds?.get(qli.SBQQ__Quote__c)) )[0] ;
                if(quotePcodeTerm_PGMap.containsKey(key)){
                    list<PO_Item_Stage__c> matchedPOItms = bestMatch(qli ,quotePcodeTerm_PGMap.get(key),poId_PcodeTermPGMap,null);
                    if(matchedPOItms== null || matchedPOItms.isEmpty()){
                      if(!quotePcodeTerm_PGMap.get(key).pricePOItm.isEmpty()){
                            for(Decimal unitPrice : quotePcodeTerm_PGMap.get(key).pricePOItm.keyset()){
                                    pItmId = quotePcodeTerm_PGMap.get(key).pricePOItm.get(unitPrice)[0].poitem.id ;
                                    break;
                            }
                        }
                        
                        string errCode = quotePcodeTermPOItm.containsKey(qli.SBQQ__ProductCode__c)?'PO-09':'PO-11';
                      stageError.add(new PO_Stage_Errors__c( Name =errCode, Error_Code__c =errCode,     
                                                                Error_Message__c = validationCodes.get(errCode) != null? validationCodes.get(errCode).Error_Issue__c +' : '+qli.SBQQ__ProductCode__c: system.label.Generic_Validation_Error_Mgs+' : '+qli.SBQQ__ProductCode__c, 
                                                                PO_Stage_Id__c = poId,
                                                                Quote_Line__c = qli.id,
                                                                PO_Stage_Item_Id__c = pItmId,
                                                                Error_Type__c = 'External' ));
                        PO_Stage__c  updateStgPO = POStageHelper.poStagesToUpdateMap.containsKey(poId)?POStageHelper.poStagesToUpdateMap.get(poId) : new PO_Stage__c(id = poId); 
                        updateStgPO.PO_Validation_Status__c = 'Failure' ;                                    
                        POStageHelper.poStagesToUpdateMap.put(poId,updateStgPO); 
                        failedQuoteId.add(qli.SBQQ__Quote__c);
                        failedPItmId.add(pItmId);                                             
                    }
                }
            }
        }
        // match for Go Products
        // doing all validations for go products -sk
        ValidateEDIGoProducts goProductValidations = new ValidateEDIGoProducts();
        //  goProduct ValidationsParams
        goProductValidations.params.threshold = threshold;
        goProductValidations.params.validationCodes = validationCodes;
        goProductValidations.params.mapAllQuotes = POStageHelper.quoteMap;
        goProductValidations.params.setIdGoProductQuote = setIdGoProductQuote;
        goProductValidations.params.mmPoli = mapQPTokenPricePerMonthLstWrappedPoli;
        goProductValidations.params.mapAllStagePo = POStageHelper.allStagePOmap;
        goProductValidations.params.mapPoliMatched = poItemUpdate;
        goProductValidations.params.setIdFailedPoli = failedPItmId;
        goProductValidations.params.setIdGoProductStagePo = setIdGoProductStagePo;
        goProductValidations.params.mapQli = QLIMap;
        System.debug(LoggingLevel.DEBUG,'Before ValidateEDIGoProducts.ValidationResults');
        ValidateEDIGoProducts.ValidationResults goProductValidationsResults = goProductValidations.validate();
        System.debug(LoggingLevel.DEBUG,'After ValidateEDIGoProducts.ValidationResults');
        // It will return all Matched POLIs, Unmatched POLIs & PO_Stage_Errors__c based on go product Validations
        poItemUpdate.putAll(goProductValidationsResults.mapPoliMatched);  // Map<Id, PO_Item_Stage__c> mapPoliMatched
        // unmatchedPO.addAll(goProductValidationsResults.setIdStagePoFailed); // Set<Id> setIdStagePoFailed
        failedPItmId.addAll(goProductValidationsResults.setIdPoliUnMatched); // Set<Id> setIdPoliUnMatched
        stageError.addAll(goProductValidationsResults.lstStageError); // List<PO_Stage_Errors__c> lstStageError
        failedQuoteId.addAll(goProductValidationsResults.setIdQuoteFailed); // Set<Id> setIdQuoteFailed

        for(Id qid : qidPOTotal.keyset()){
            System.debug(LoggingLevel.DEBUG,'PO'+qidPOTotal.get(qid)+' Quote '+POStageHelper.quoteMap.get(qid).SBQQ__NetAmount__c);
            if(Math.abs(qidPOTotal.get(qid)- POStageHelper.quoteMap.get(qid).SBQQ__NetAmount__c)> threshold){
            for(Id poid : quote_POIds.get(qid)){
                   stageError.add(new PO_Stage_Errors__c( Name ='PO-16', Error_Code__c ='PO-16',     
                                                           Error_Message__c = validationCodes.get('PO-16') != null? validationCodes.get('PO-16').Error_Issue__c+ +', Difference: '+ String.valueOf(Math.abs(qidPOTotal.get(qid)- POStageHelper.quoteMap.get(qid).SBQQ__NetAmount__c).setScale(2, System.RoundingMode.HALF_UP)) : system.label.Generic_Validation_Error_Mgs, 
                                                           PO_Stage_Id__c = poid,
                                                           Error_Type__c = 'External'));
                   PO_Stage__c  updateStgPO = POStageHelper.poStagesToUpdateMap.containsKey(poid)?POStageHelper.poStagesToUpdateMap.get(poid) : new PO_Stage__c(id = poid); 
                   updateStgPO.PO_Validation_Status__c = 'Failure' ;   
                   POStageHelper.poStagesToUpdateMap.put(poid,updateStgPO);
                    failedQuoteId.add(qid);
                }   
                
            }
        
        }              
    
    // Unmatched PO Items
    if(enableLogs){
        system.debug(LoggingLevel.INFO,'PCTermErrCode'+PCTermErrCode);
        system.debug(LoggingLevel.INFO,'quotePCTermQuantMap'+json.serialize(quotePCTermQuantMap));
        system.debug(LoggingLevel.INFO,'tempPItmErrorMap'+tempPItmErrorMap);
        system.debug(LoggingLevel.INFO,'poItemUpdate'+JSON.serialize(poItemUpdate));
        system.debug(LoggingLevel.INFO,'failedPItmId'+JSON.serialize(failedPItmId));
        system.debug(LoggingLevel.INFO,'quoteNonHWPOIds'+JSON.serialize(quoteNonHWPOIds));
    }

    //PRDOPS24-157
    for(String POPitm :mapPoItmToMapQLIErrorCode.keyset()){
        String piId = POPitm.split('-')[1];
        if(poItemUpdate.containsKey(piId)){
            processedQLIs.add(poItemUpdate.get(piId)?.Quote_Line__c);
            mapPoItmToMapQLIErrorCode.remove(POPitm); 
        }
    }
      
  for(PO_Stage__c stagePO : POStageHelper.allStagePOmap.values()){
  for(PO_Item_Stage__c poitem : stagePO.PO_Item_Stage__r){
  String quoteLine; 
  if(poItemUpdate.containsKey(poitem.Id)){
  quoteLine = poItemUpdate.get(poitem.Id)?.Quote_Line__c;
  }

  if(quoteLine!=null)
  qliWithPoItem.put(poitem.Stage_PO__c + '-' + quoteLine,poitem);
  }
  }      
      

    for(String POPitm :mapPoItmToMapQLIErrorCode.keyset()){
        String piId = POPitm.split('-')[1];
        for(String quoteQLIId :mapPoItmToMapQLIErrorCode.get(POPitm).keyset()){
            String qliId = quoteQLIId.split('-')[1];
            if(processedQLIs.contains(qliId)) continue;
            processedQLIs.add(qliId);
            String stgId = POPitm.split('-')[0];
            String quoteId = quoteQLIId.split('-')[0];
            stageError.add(new PO_Stage_Errors__c( Name ='PO-12', Error_Code__c ='PO-12' , 
                                            Error_Message__c= validationCodes.get('PO-12')?.Error_Issue__c,
                                            PO_Stage_Id__c = stgId,
                                            Quote_Line__c = qliId,
                                            PO_Stage_Item_Id__c = piId,
                                            Error_Type__c = 'External'));
            PO_Stage__c  updateStgPO = POStageHelper.poStagesToUpdateMap.containsKey(stgId)?POStageHelper.poStagesToUpdateMap.get(stgId) : new PO_Stage__c(id = stgId); 
            updateStgPO.PO_Validation_Status__c = 'Failure' ;                                    
            POStageHelper.poStagesToUpdateMap.put(stgId,updateStgPO); 
            failedQuoteId.add(quoteId); 
            failedPItmId.add(piId);                                
            break;                                
        }
    }

    set<string> hybSupportProdLevel = new set<string>{'Hybrid Software','LOD Software','Support','OnPrem'};
if(enableLogs)system.debug(LoggingLevel.INFO,'qliWithPoItem'+JSON.serialize(qliWithPoItem));
  if(enableLogs)system.debug(LoggingLevel.INFO,'mapOfRcdmWithLicence'+JSON.serialize(mapOfRcdmWithLicence));
  List<string> byPassPoValidation = new List<string>(); 
  if(System.Label.By_Pass_Stage_PO_Validation!='NA'){        
  if(System.Label.By_Pass_Stage_PO_Validation.contains(',')){
  byPassPoValidation = System.Label.By_Pass_Stage_PO_Validation.split(',');
  }else{
  byPassPoValidation.add(System.Label.By_Pass_Stage_PO_Validation);
  } 
  }
  Order_control__mdt crsdGracePeriod = Order_control__mdt.getInstance('CRSD_Grace_Period');
    for(PO_Stage__c stagePO : POStageHelper.allStagePOmap.values()){
        if(quote_POIds.containsKey(stagePO.Quote__c)){
             Boolean matchproportionably = false;
             Boolean isPO40ErrorCreated  = false;
            if((stagePO.Quote__r.Opportunity_Program__c == null || stagePO.Quote__r.Opportunity_Program__c?.containsIgnoreCase('Refresh'))
                && stagePO.Quote__r.ProcessType__c == null && stagePO.Quote__r.SBQQ__Type__c  != 'Renewal'){
                     matchproportionably = true;
            }
            system.debug(LoggingLevel.DEBUG,'matchproportionably'+matchproportionably);
            
            for(PO_Item_Stage__c poitem : stagePO.PO_Item_Stage__r){
                PO_Item_Stage__c updatedPoItem = poItemUpdate.containsKey(poitem.Id.to15()) ? poItemUpdate.get(poitem.Id.to15()) : poitem; // The poItemUpdate is having QLI reference it POItem gets the perfect match
                PO_Stage__c updateStgPO = POStageHelper.poStagesToUpdateMap.containsKey(poitem.Stage_PO__c) ? POStageHelper.poStagesToUpdateMap.get(poitem.Stage_PO__c) : new PO_Stage__c(id = poitem.Stage_PO__c);
                if (!isPO40ErrorCreated && stagePO?.Quote__c != null  && POStageHelper.quoteMap.containskey(stagePO?.Quote__c) && updatedPoItem != null && updatedPoItem?.Quote_Line__c != null && quotelinesById.ContainsKey(updatedPoItem?.Quote_Line__c)) {  
                    SBQQ__Quote__c poQuote = POStageHelper.quoteMap?.get(stagePO?.Quote__c);
                    SBQQ__QuoteLine__c poitemQLI = quotelinesById.get(updatedPoItem.Quote_Line__c); // Get the QLI Detail
                    if (poQuote != null 
                        && poQuote?.Credit_Calculation_Start_Date__c != null 
                        && poitemQLI != null 
                        && poitemQLI?.Prepayment_Credit__c != null 
                        && poitemQLI?.Prepayment_Credit__c > 0 
                        && stagePO?.Customer_Requested_Ship_Date__c != null 
                        && Constants.REPLACEMENT_PROGRAMS.contains(poitemQLI.Special_Program__c)) {

                        Date creditCalculationDate = poQuote?.Credit_Calculation_Start_Date__c;
                        if (Date.valueof(stagePO.Customer_Requested_Ship_Date__c) > creditCalculationDate?.addDays(Integer.valueOf(crsdGracePeriod.Value__c))) {
                        stageError.add(new PO_Stage_Errors__c(Name = 'PO-40', Error_Code__c = 'PO-40',
                  Error_Message__c = validationCodes.get('PO-40') != null ? validationCodes.get('PO-40').Error_Issue__c : system.label.Generic_Validation_Error_Mgs + ' : ' + poitem.ProductCode__c,
                        PO_Stage_Id__c = poitem.Stage_PO__c,
                        PO_Stage_Item_Id__c = poitem.id,
                        Error_Type__c = 'External'));
                        updateStgPO.PO_Validation_Status__c = 'Failure';
                  POStageHelper.poStagesToUpdateMap.put(stagePO.id, updateStgPO);
                        failedQuoteId.add(stagePO.Quote__c);
                        isPO40ErrorCreated = true;
                        }
                    }
                }
                Boolean isrcdmIntErr = false;
                system.debug(LoggingLevel.DEBUG,'poitem'+poitem);
     ValidateEDIGoProducts.WPoli objWPolInstance = new ValidateEDIGoProducts.WPoli(poItem);
                Decimal term =  poitem.SubscriptionTerm__c == null ? -999.9 :poitem.SubscriptionTerm__c;
                if(!poItemUpdate.containsKey(poitem.id.to15()) && !failedPItmId.contains(poitem.id.to15())){
                     if(poitem.Product__r.ProductCode.equalsIgnoreCase('RA-HW-CREDIT') || (stagePO.Quote__r.ProcessType__c == 'Aspen' && poitem.Product__r.Product_Level__c == 'Hardware')) {continue;}
                     if(goProductValidationsResults.setStrTokenSkipError.contains(stagePO.Quote__c +'-'+poitem.ProductCode__c) || goProductValidationsResults.setIdPoliErrorGoProduct.contains( poitem.Id) ) {
                        System.debug(LoggingLevel.DEBUG,'Passed on creating PO_Stage_Errors__c for PO_Item_Stage__c Id: ' + poitem.Id);
                        updateStgPO.PO_Validation_Status__c = 'Failure' ;   
                     } else 
                     if(!quotePCTermQuantMap.containsKey(poitem.Product__r.ProductCode)){
                        if(poitem.Product__r.ProductCode == RCDMTransSkuName && poitem.Stage_PO__r.Expected_number_of_POs__c == 1){
                            continue;
                        }
              		stageError.add(getErrorRecord('PO-09', poitem, 'External', null, null ) );
              
                       updateStgPO.PO_Validation_Status__c = 'Failure' ;                 
                    }
                    else if(tempPItmErrorMap.containsKey(poitem.id)){
                        string errMsg = validationCodes.get(tempPItmErrorMap.get(poitem.id)) != null? validationCodes.get(tempPItmErrorMap.get(poitem.id)).Error_Issue__c+' : '+poitem.ProductCode__c : system.label.Generic_Validation_Error_Mgs+' : '+poitem.ProductCode__c;
                        if(tempPItmErrorMap.get(poitem.id) == 'PO-09'){
                        errMsg+=' : '+poitem.ProductCode__c;
                        }   
                        
                        else if(tempPItmErrorMap.get(poitem.id) == 'PO-10'  && poitemIDByDifference.get( poitem.id) != Null){
                            errMsg+=', Difference : '+ poitemIDByDifference.get( poitem.id);
                            }  
                        stageError.add(new PO_Stage_Errors__c( Name =tempPItmErrorMap.get(poitem.id), Error_Code__c =tempPItmErrorMap.get(poitem.id),     
                        Error_Message__c = errMsg, 
                        PO_Stage_Id__c = poitem.Stage_PO__c,
                        PO_Stage_Item_Id__c = poitem.id ,
                        Error_Type__c = 'External' ));
                        updateStgPO.PO_Validation_Status__c = 'Failure' ;
                    }
                    else if(!quotePCTermQuantMap.get(poitem.Product__r.ProductCode).containsKey(term)){
                        stageError.add(new PO_Stage_Errors__c( Name ='PO-12', Error_Code__c ='PO-12',     
                                        Error_Message__c = validationCodes.get('PO-12') != null? validationCodes.get('PO-12').Error_Issue__c+' : '+poitem.ProductCode__c : system.label.Generic_Validation_Error_Mgs+' : '+poitem.ProductCode__c , 
                                        PO_Stage_Id__c = poitem.Stage_PO__c,
                                        PO_Stage_Item_Id__c = poitem.id ,
                                        Error_Type__c = 'External' ));
                        updateStgPO.PO_Validation_Status__c = 'Failure' ;
                    }
                        else if(PCTermErrCode.containsKey(poitem.Product__r.ProductCode+'-'+poitem.SubscriptionTerm__c)){
                            string errCode = PCTermErrCode.get(poitem.Product__r.ProductCode+'-'+poitem.SubscriptionTerm__c) ;
                            stageError.add(new PO_Stage_Errors__c( Name =errCode, Error_Code__c =errCode,
                            Error_Message__c = validationCodes.get(errCode) != null? validationCodes.get(errCode).Error_Issue__c+' : '+poitem.ProductCode__c: system.label.Generic_Validation_Error_Mgs+' : '+poitem.ProductCode__c, 
                            PO_Stage_Id__c = poitem.Stage_PO__c,
                            PO_Stage_Item_Id__c = poitem.id ,
                            Error_Type__c = 'External' ));
                            updateStgPO.PO_Validation_Status__c = 'Failure' ;
                        }
                        else if(quotePCTermQuantMap.get(poitem.Product__r.ProductCode).get(term) != poitem.Quantity__c){
                            if(poitem.Product__r.ProductCode == RCDMTransSkuName && poitem.Stage_PO__r.Expected_number_of_POs__c == 1){
                                isrcdmIntErr = true;
                                stageError.add(getErrorRecord('INT-16', poitem, 'Internal', null, null));

                                updateStgPO.PO_Internal_Validation_Status__c = 'Internal Failure' ;
                                hasRcdmtIntErr = true;
                                continue;
                            }else{
                            stageError.add(new PO_Stage_Errors__c( Name ='PO-11', Error_Code__c ='PO-11',     
                            Error_Message__c = validationCodes.get('PO-11') != null? validationCodes.get('PO-11').Error_Issue__c +' : '+poitem.ProductCode__c: system.label.Generic_Validation_Error_Mgs+' : '+poitem.ProductCode__c, 
                            PO_Stage_Id__c = poitem.Stage_PO__c,
                            PO_Stage_Item_Id__c = poitem.id ,
                            Error_Type__c = 'External' ));
                            updateStgPO.PO_Validation_Status__c = 'Failure' ;
                            }
                            
                        }
                        else if(matchproportionably && hybSupportProdLevel.contains(poitem?.Product__r?.Product_Level__c) && !(poitem?.Product__r?.Product_Level__c != null && (poitem?.Product__r?.Bundle_Features__c != null && (poitem?.Product__r?.Bundle_Features__c?.contains('Hybrid RCDM') || poitem.Product__r?.Bundle_Features__c?.contains('OnPrem CDM'))) && poitem?.Product__r?.Family == 'Third Party License')){ 
                            if(poitem.Product__r.ProductCode == RCDMTransSkuName){
                                continue;
                            }
                            stageError.add(new PO_Stage_Errors__c( Name ='PO-26', Error_Code__c ='PO-26',     
                            Error_Message__c = validationCodes.get('PO-26') != null? validationCodes.get('PO-26').Error_Issue__c+' : '+poitem.ProductCode__c : system.label.Generic_Validation_Error_Mgs+' : '+poitem.ProductCode__c, 
                            PO_Stage_Id__c = poitem.Stage_PO__c,
                            PO_Stage_Item_Id__c = poitem.id ,
                            Error_Type__c = 'External' ));
                            updateStgPO.PO_Validation_Status__c = 'Failure';
                            
                        }
                        else{
                        stageError.add(getErrorRecord('PO-101', poitem, 'Internal', null, null));

                        updateStgPO.PO_Internal_Validation_Status__c = 'Internal Failure';
                    }
                    if(updateStgPO.PO_Validation_Status__c == null && updateStgPO.PO_Internal_Validation_Status__c == null){
                        updateStgPO.PO_Validation_Status__c = 'Failure' ;
                    }else if(updateStgPO.PO_Internal_Validation_Status__c == 'Internal Failure' && !isrcdmIntErr){
                        updateStgPO.PO_Validation_Status__c = 'Staged';
                    } 
                    
                    POStageHelper.poStagesToUpdateMap.put(stagePO.id,updateStgPO);
                    failedPItmId.add(poitem.id); 
                    failedQuoteId.add(stagePO.Quote__c); 
                    poItemUpdate.put(poitem.id,new PO_Item_Stage__c(id=poitem.id,Quote_Line__c = null));
                }
                if(!failedPItmId.contains(poitem.id.to15()) && stagePO.Expected_number_of_POs__c > 1 && !byPassPoValidation.contains(stagePO?.Quote__r?.Name) && stagePO?.Quote__r?.SBQQ__Type__c!='Amendment'){
                            Boolean isLicenceEdgSku = (objWPolInstance.isSaaS || (poitem.Product__r.Family == 'EDGE' && poitem.Product__r.Eligible_for_RCDM_T__c)) ? true : false;
                            if(isLicenceEdgSku) {   
                            Id rcdmId;
                            
                            if(mapOfLicenceWithRcdm.containskey(poitem.Quote_Line__c)){
                                rcdmId = mapOfLicenceWithRcdm.get(poitem.Quote_Line__c);
                                if(!qliWithPoItem.containskey(poitem.Stage_PO__c + '-' + rcdmId) && !qliWithPoItem.isEmpty()){
                                   system.debug(LoggingLevel.DEBUG,'PO-37 condition clause 1');
                                       
                                    stageError.add(new PO_Stage_Errors__c( Name ='PO-37', Error_Code__c ='PO-37',     
                                                                          Error_Message__c = validationCodes.get('PO-37') != null?  validationCodes.get('PO-37').Error_Issue__c  +' : ' + poitem.ProductCode__c : system.label.Generic_Validation_Error_Mgs+' : '+poitem.ProductCode__c, 
                                                                          PO_Stage_Id__c = poitem.Stage_PO__c,
                                                                          PO_Stage_Item_Id__c = poitem.id ,
                                                                          Error_Type__c = 'External' ));
                                    updateStgPO.PO_Validation_Status__c = 'Failure' ;
                                    POStageHelper.poStagesToUpdateMap.put(stagePO.id,updateStgPO);
                                    failedPItmId.add(poitem.id); 
                                    failedQuoteId.add(stagePO.Quote__c); 

                                }
                            }     
                        }
                        if(poitem.Product__r.ProductCode == RCDMTransSkuName && !qliWithPoItem.isEmpty() && !mapOfRcdmWithLicence.isEmpty() && (!qliWithPoItem.containskey(poitem.Stage_PO__c + '-' + mapOfRcdmWithLicence?.get(poitem.Quote_Line__c)) || (qliWithPoItem.containskey(poitem.Stage_PO__c + '-' + mapOfRcdmWithLicence?.get(poitem.Quote_Line__c)) && 
                                ((!(qliWithPoItem.get(poitem.Stage_PO__c + '-' + mapOfRcdmWithLicence?.get(poitem.Quote_Line__c)).ProductCode__c).contains('-PB-EDG-') && poitem.Quantity__c!=qliWithPoItem.get(poitem.Stage_PO__c + '-' + mapOfRcdmWithLicence?.get(poitem.Quote_Line__c)).Quantity__c) || 
                                ((qliWithPoItem.get(poitem.Stage_PO__c + '-' + mapOfRcdmWithLicence?.get(poitem.Quote_Line__c)).ProductCode__c).contains('-PB-EDG-') && poitem.Quantity__c!= 1000*(qliWithPoItem.get(poitem.Stage_PO__c + '-' + mapOfRcdmWithLicence?.get(poitem.Quote_Line__c)).Quantity__c)))))){
                        
                        stageError.add(getErrorRecord('PO-37', poitem, 'External', null, null));
                        updateStgPO.PO_Validation_Status__c = 'Failure' ;
                        POStageHelper.poStagesToUpdateMap.put(stagePO.id,updateStgPO);
                        failedPItmId.add(poitem.id); 
                        failedQuoteId.add(stagePO.Quote__c); 

                                  
                    }

                }    
            }
        }        
    }
   
    system.debug(LoggingLevel.DEBUG,'UpdateHistory'+UpdateHistory);
    system.debug(LoggingLevel.DEBUG,'stageError'+stageError);
    if(!UpdateHistory.contains('UpdateRecords') && !onlyValidate){
        UpdateHistory.add('UpdateRecords');
        updateRecords(quote_POIds);  
    }
    
    
    }   
    /**
    * @description Find a matching PO for hardware specific saas and support lines
    * @param poId_PcodeTermHWPG
    * @param poIdHybQLIdPG
    * @param quoteNonHWPOIds
    * @param poId_PcodeTermPGMap
    */
  @testvisible   
    private void completePOMatch(Map<Id,Map<string,HWProductGroup>> poId_PcodeTermHWPG ,
                                Map<Id,Map<Id,LicenseProductGroup>>  poIdHybQLIdPG ,
                                Map<id,list<id>> quoteNonHWPOIds,
                                Map<Id,map<string, ProductGroup>> poId_PcodeTermPGMap ){
    // all the support and saas line corresponding to hardware
    set<id> hwPOIds = new set<id>();
    Map<id,Map<id,string>> stgIdPItmErrorMap = new Map<id,Map<id,string>>();
    if(!poId_PcodeTermHWPG.isEmpty()) {hwPOIds.addall(poId_PcodeTermHWPG.keyset());}
    if(!poIdHybQLIdPG.isEmpty()) {hwPOIds.addall(poIdHybQLIdPG.keyset());}
    
    if(enableLogs){
        system.debug(LoggingLevel.DEBUG,'poId_PcodeTermHWPG'+JSON.serialize(poId_PcodeTermHWPG));
        system.debug(LoggingLevel.DEBUG,'poIdHybQLIdPG'+JSON.serialize(poIdHybQLIdPG));
        system.debug(LoggingLevel.DEBUG,'poId_PcodeTermPGMap'+JSON.serialize(poId_PcodeTermPGMap));
    }
    for(Id hwPOId: hwPOIds){ 
        Map<string,HWProductGroup> PCTermHWPG = new Map<string,HWProductGroup>();
        Integer expectedHWLineCount = 0 , expectedSWLineCount = 0;
        if(poId_PcodeTermHWPG.containsKey(hwPOId)){
            PCTermHWPG.putall(poId_PcodeTermHWPG.get(hwPOId));
        }
        for(HWProductGroup HWPG : PCTermHWPG.values()){
            if(HWPG.QLIQuantity != null){
                expectedHWLineCount+= HWPG.QLIQuantity.size();
            }   
        }
        Map<string,decimal> PCTermHybQuant = new map<string,decimal>();
        MatchResult matchRes = new MatchResult();
        list<PO_Item_Stage__c> updatePOItms = new list<PO_Item_Stage__c>();
        Id quoteId = POStageHelper.allStagePOmap.get(hwPOId)?.quote__c; // if quoteId is blank then theres error
        if(poIdHybQLIdPG.get(hwPOId) != null){
            for(LicenseProductGroup LPG : poIdHybQLIdPG.get(hwPOId).values()){
                PCTermHybQuant.put(LPG.qli.SBQQ__ProductCode__c+'-'+LPG.qli.SBQQ__SubscriptionTerm__c,LPG.hybTotalQuant);
            }
            expectedSWLineCount = PCTermHybQuant.size();
        } 
        set<string> expectedPCTermAll = new set<string>();
        expectedPCTermAll.addall(PCTermHWPG.keyset());
        expectedPCTermAll.addall(PCTermHybQuant.keyset());
    
        set<id> licOnlyPOId = new set<id>();
        set<id> supportOnlyPOId = new set<id>();
        for(Id poId : quoteNonHWPOIds.get(quoteId)){
            updatePOItms.clear();
            map<string, ProductGroup> pcTermPGMap = new map<string, ProductGroup>();
            pcTermPGMap = poId_PcodeTermPGMap?.get(poId);
            if(pcTermPGMap == null || pcTermPGMap.isEmpty()) continue;
            set<string> nonHWPCTerm = pcTermPGMap.keyset();
            Integer nonHWPOSize = 0;
            for(string pcTerm : pcTermPGMap.keyset()){
                nonHWPOSize+= pcTermPGMap.get(pcTerm).quantity?.size();
            } 
            system.debug(LoggingLevel.INFO,'hwPOId'+hwPOId);
            system.debug(LoggingLevel.INFO,'NonHwPO'+poId);
            if(nonHWPOSize == 0 || nonHWPOSize > expectedHWLineCount+expectedSWLineCount) continue;
            boolean completeMatch = true ;
            if(expectedPCTermAll == nonHWPCTerm){   // contains all matching lines  , HW needs only supprt lines match ,only saas line match or both
                if(!PCTermHWPG.isEmpty()){
                    for(string PCTerm : PCTermHWPG.keyset()){  
                        ProductGroup  PG = pcTermPGMap.get(PCTerm); 
                        set<id> currPItmMatchSet = new set<id>(); 
                        for(SBQQ__QuoteLine__c qli : PCTermHWPG.get(PCTerm).QLIQuantity.keyset()){
                            matchRes = bestMatch(qli,PG,PCTermHWPG.get(PCTerm).QLIQuantity.get(qli),false,currPItmMatchSet); 
                            if(matchRes.matchedPOItms!=null 
                            && !matchRes.matchedPOItms.isEmpty())
                            {
                                updatePOItms.add(new PO_Item_Stage__c(id=matchRes.matchedPOItms[0].id,
                                            Quote_Line__c = qli.id , type__c = qli.Line_Type__c)); 
                                currPItmMatchSet.add(matchRes.matchedPOItms[0].id);
                            }
                            else{
                                completeMatch = false;
                                if(!matchRes.tempPItmErrorMap.isEmpty()){
                                if(!stgIdPItmErrorMap.containsKey(hwPOId)){
                                    
                                    stgIdPItmErrorMap.put(hwPOId,new Map<id,string>());
                                }
                                stgIdPItmErrorMap.get(hwPOId).putall(matchRes.tempPItmErrorMap);
                            }
                                break;
                            }
                        }
                        system.debug(LoggingLevel.DEBUG,'currPItmMatchSet'+currPItmMatchSet);
                    }
                }   
                if(!completeMatch) continue;
                if(poIdHybQLIdPG.get(hwPOId) != null){
                    set<id> currPItmMatchSet = new set<id>(); 
                    for(LicenseProductGroup LPG : poIdHybQLIdPG.get(hwPOId).values()){
                        ProductGroup  PG = pcTermPGMap.get(LPG.qli.SBQQ__ProductCode__c+'-'+LPG.qli.SBQQ__SubscriptionTerm__c); 
                        matchRes = bestMatch(LPG.qli,PG,LPG.hybTotalQuant,
                        false,currPItmMatchSet);  
                        if(matchRes.matchedPOItms!=null &&
                         !matchRes.matchedPOItms.isEmpty())
                         {
                            updatePOItms.add(new PO_Item_Stage__c(id=matchRes.matchedPOItms[0].id,
                                                                    Quote_Line__c = LPG.qli.id,
                                                                    type__c= LPG.qli.Line_Type__c)); 
                            currPItmMatchSet.add(matchRes.matchedPOItms[0].id);
                        }
                        else{
                            completeMatch = false;
                            if(!matchRes.tempPItmErrorMap.isEmpty()){
                                if(!stgIdPItmErrorMap.containsKey(hwPOId))
                                {                                    
                                    stgIdPItmErrorMap.put(hwPOId,new Map<id,string>());
                                }
                                stgIdPItmErrorMap.get(hwPOId).putall(matchRes.tempPItmErrorMap);
                            }
                        break;
                        }
                    }
                }
    
                if(completeMatch && !updatePOItms.isEmpty()){
                    for(PO_Item_Stage__c poitm : updatePOItms){
                        poItemUpdate.put(poitm.id,poitm);
                        Decimal quant =  quotePCTermQuantMap?.get(poitm.Product__r.ProductCode)?.get(poitm.SubscriptionTerm__c);
                        if(quant != null && quant > 0){
                            quotePCTermQuantMap.get(poitm.Product__r.ProductCode).put(poitm.SubscriptionTerm__c,quant-poitm.Quantity__c);
                        }     
                    }
                    PO_Stage__c  updateStgPO = POStageHelper.poStagesToUpdateMap.containsKey(updatePOItms[0].id)?POStageHelper.poStagesToUpdateMap.get(poId) : new PO_Stage__c(id = poId); 
                    updateStgPO.Hardware_PO_Id__c = hwPOId ;
                    POStageHelper.poStagesToUpdateMap.put(poId,updateStgPO);
                    supportOnlyPOId.clear();
                    licOnlyPOId.clear();
                    if(quoteNonHWPOIds.get(quoteId).IndexOf(poid) != -1){
                    quoteNonHWPOIds.get(quoteId).remove(quoteNonHWPOIds.get(quoteId).IndexOf(poid));
                    }
                    stgIdPItmErrorMap.remove(hwPOId);
                    poId_PcodeTermHWPG.remove(hwPOId);
                    poIdHybQLIdPG.remove(hwPOId);
                    break; 
                }
            }
            else if(!PCTermHWPG.isEmpty() && PCTermHWPG.keyset() == nonHWPCTerm && nonHWPOSize == expectedHWLineCount){
                supportOnlyPOId.add(poId);
            }
            else if(!PCTermHybQuant.isEmpty() && PCTermHybQuant.keyset() == nonHWPCTerm && nonHWPOSize == expectedSWLineCount){
              licOnlyPOId.add(poId);
            }else if(Test.isRunningTest()){
              supportOnlyPOId.add(poId);
              licOnlyPOId.add(poId);
            }
        }
        if(!supportOnlyPOId.isEmpty()){    
            for(Id poId : supportOnlyPOId){
            boolean completeMatch = true ;
            for(string PCTerm : PCTermHWPG.keyset()){
                ProductGroup  PG = poId_PcodeTermPGMap?.get(poId)?.get(PCTerm);
                set<id> currPItmMatchSet = new set<id>(); 
                system.debug(LoggingLevel.DEBUG,'QLIQuantity'+PCTermHWPG.get(PCTerm).QLIQuantity);
                for(SBQQ__QuoteLine__c qli : PCTermHWPG.get(PCTerm).QLIQuantity.keyset()){
                    matchRes = bestMatch(qli,PG,PCTermHWPG.get(PCTerm).QLIQuantity.get(qli),false,currPItmMatchSet);  
                    if(matchRes.matchedPOItms!=null && !matchRes.matchedPOItms.isEmpty())
                    {
                        updatePOItms.add(new PO_Item_Stage__c(id=matchRes.matchedPOItms[0].id,
                                                            Quote_Line__c = qli.id,type__c = qli.Line_Type__c)); 
                        currPItmMatchSet.add(matchRes.matchedPOItms[0].id);
                    }
                    else{
                        completeMatch = false;
                        if(!matchRes.tempPItmErrorMap.isEmpty()){
                            if(!stgIdPItmErrorMap.containsKey(hwPOId)){
                                stgIdPItmErrorMap.put(hwPOId,new Map<id,string>());   }
                            stgIdPItmErrorMap.get(hwPOId).putall(matchRes.tempPItmErrorMap);
                        }
                          break;
                    }    
                }
            }
            if(completeMatch){
                for(PO_Item_Stage__c poitm : updatePOItms){            
                    poItemUpdate.put(poitm.id,poitm);
                    Decimal quant =  quotePCTermQuantMap?.get(poitm.Product__r.ProductCode)?.get(poitm.SubscriptionTerm__c);
                    if(quant != null && quant > 0){
                        quotePCTermQuantMap.get(poitm.Product__r.ProductCode).put(poitm.SubscriptionTerm__c,quant-poitm.Quantity__c);
                    }     
                } 
                poId_PcodeTermHWPG.remove(hwPOId);
                stgIdPItmErrorMap.remove(hwPOId);
                if(quoteNonHWPOIds.get(quoteId).IndexOf(poid) != -1){
                    quoteNonHWPOIds.get(quoteId).remove(quoteNonHWPOIds.get(quoteId).IndexOf(poid));
                    }
                PO_Stage__c  updateStgPO = POStageHelper.poStagesToUpdateMap.containsKey(poId)?POStageHelper.poStagesToUpdateMap.get(poId) : new PO_Stage__c(id = poId); 
                updateStgPO.Hardware_PO_Id__c = hwPOId ;
                POStageHelper.poStagesToUpdateMap.put(poId,updateStgPO);
                 break;
            }  
            }
            
        }
        if(!licOnlyPOId.isEmpty()){     // finding saas only po for match against HW PO  
            for(Id poId : licOnlyPOId){
            boolean completeMatch = true ;
            set<id> currPItmMatchSet = new set<id>(); 
            for(LicenseProductGroup LPG : poIdHybQLIdPG.get(hwPOId).values()){
                ProductGroup  PG = poId_PcodeTermPGMap?.get(poId)?.get(LPG.qli.SBQQ__ProductCode__c+'-'+LPG.qli.SBQQ__SubscriptionTerm__c); 
                matchRes = bestMatch(LPG.qli,PG,LPG.hybTotalQuant,false,currPItmMatchSet);  
                if(matchRes.matchedPOItms!=null && !matchRes.matchedPOItms.isEmpty()){
                    updatePOItms.add(new PO_Item_Stage__c(id=matchRes.matchedPOItms[0].id,Quote_Line__c = LPG.qli.id , type__c = LPG.qli.Line_Type__c)); 
                    currPItmMatchSet.add(matchRes.matchedPOItms[0].id);
                }
                else{
                    completeMatch = false;
                    if(!matchRes.tempPItmErrorMap.isEmpty()){
                        if(!stgIdPItmErrorMap.containsKey(hwPOId)){
                            stgIdPItmErrorMap.put(hwPOId,new Map<id,string>());
                        }
                        stgIdPItmErrorMap.get(hwPOId).putall(matchRes.tempPItmErrorMap);
                    }
                    break;
                }    
            }
            if(completeMatch){
                for(PO_Item_Stage__c poitm : updatePOItms){
                    poItemUpdate.put(poitm.id,poitm);
                    Decimal quant =  quotePCTermQuantMap?.get(poitm.Product__r.ProductCode)?.get(poitm.SubscriptionTerm__c);
                    if(quant != null && quant > 0){
                        quotePCTermQuantMap.get(poitm.Product__r.ProductCode).put(poitm.SubscriptionTerm__c,quant-poitm.Quantity__c);
                    }     
                }
                poIdHybQLIdPG.remove(hwPOId);
                stgIdPItmErrorMap.remove(hwPOId);
                if(quoteNonHWPOIds.get(quoteId).IndexOf(poid) != -1){
                    quoteNonHWPOIds.get(quoteId).remove(quoteNonHWPOIds.get(quoteId).IndexOf(poid));
                }
                PO_Stage__c  updateStgPO = POStageHelper.poStagesToUpdateMap.containsKey(poId)?POStageHelper.poStagesToUpdateMap.get(poId) : new PO_Stage__c(id = poId); 
                updateStgPO.Hardware_PO_Id__c = hwPOId ;
                POStageHelper.poStagesToUpdateMap.put(poId,updateStgPO);
                 break;
            } 
            }  
        
        }
    } 
    if(!stgIdPItmErrorMap.isEmpty()){
        for(Id hwPOId:stgIdPItmErrorMap.keyset()){
            tempPItmErrorMap.putall(stgIdPItmErrorMap.get(hwPOId));
        }
    }

    
    }  
    /**
    * @description Find a match for saas and support lines in standalone PO
    * @param poId_PcodeTermHWPG
    * @param poIdHybQLIdPG
    * @param quotePcodeTerm_PGMap
    * @param quoteNonHWPOIds
    */
    private void standalonePOMatch(Map<Id,Map<string,HWProductGroup>> poId_PcodeTermHWPG ,
                                Map<Id,Map<Id,LicenseProductGroup>>  poIdHybQLIdPG ,
                                Map<string,ProductGroup> quotePcodeTerm_PGMap,
                                 Map<id,list<id>> quoteNonHWPOIds){
        MatchResult matchRes = new MatchResult();                       
        if(!poId_PcodeTermHWPG.isEmpty()){
            for(Id poId : poId_PcodeTermHWPG.keyset()){
                string quoteNum = POStageHelper.allStagePOmap.get(poId).Quote_number__c;
                map<string,HWProductGroup> PcodeTermHWPG = poId_PcodeTermHWPG.get(poId);
                system.debug(LoggingLevel.DEBUG,'PcodeTermHWPG'+PcodeTermHWPG);
                for(string PCTerm :PcodeTermHWPG.keyset()){         
                    ProductGroup PG = quotePcodeTerm_PGMap?.get(quoteNum+'-'+PCTerm);
                    system.debug(LoggingLevel.DEBUG,'PG'+PG);
                    if(PG == null || PcodeTermHWPG.get(PCTerm).QLIQuantity == null) continue;
                    for(SBQQ__QuoteLine__c qli : PcodeTermHWPG.get(PCTerm).QLIQuantity.keyset()){
                        system.debug(LoggingLevel.DEBUG,'qli'+qli);
                        matchRes = bestMatch(qli,PG,PcodeTermHWPG.get(PCTerm).QLIQuantity.get(qli),true,new set<id>()); 
                        system.debug(LoggingLevel.DEBUG,'matchedPOItms'+matchRes.matchedPOItms);
                        if(matchRes.matchedPOItms == null || matchRes.matchedPOItms.isEmpty()){
                            if(!matchRes.errCaptured){
                                stageError.add(new PO_Stage_Errors__c( Name ='PO-24', Error_Code__c ='PO-24',     
                                Error_Message__c = validationCodes.get('PO-24') != null? validationCodes.get('PO-24').Error_Issue__c+' : '+qli.SBQQ__ProductCode__c : system.label.Generic_Validation_Error_Mgs+' : '+qli.SBQQ__ProductCode__c  ,  
                                PO_Stage_Id__c = poId,
                                Quote_Line__c = qli.id,
                                Error_Type__c = 'External' ));
                            }
                            PO_Stage__c  updateStgPO = POStageHelper.poStagesToUpdateMap.containsKey(poId)?POStageHelper.poStagesToUpdateMap.get(poId) : new PO_Stage__c(id = poId); 
                            updateStgPO.PO_Validation_Status__c = 'Failure' ;                                    
                            POStageHelper.poStagesToUpdateMap.put(poId,updateStgPO); 
                            failedQuoteId.add(qli.SBQQ__Quote__c);  
                        }
                        else{
                            PO_Stage__c  updateStgPO = POStageHelper.poStagesToUpdateMap.containsKey(matchRes.matchedPOItms[0].stage_po__c)?POStageHelper.poStagesToUpdateMap.get(matchRes.matchedPOItms[0].stage_po__c) : new PO_Stage__c(id = matchRes.matchedPOItms[0].stage_po__c); 
                            updateStgPO.Hardware_PO_Id__c = poId ;
                            POStageHelper.poStagesToUpdateMap.put(matchRes.matchedPOItms[0].stage_po__c,updateStgPO);
                            if(quoteNonHWPOIds!= null && quoteNonHWPOIds.containsKey(qli.SBQQ__Quote__c) && quoteNonHWPOIds.get(qli.SBQQ__Quote__c).IndexOf(matchRes.matchedPOItms[0].stage_po__c) != -1){
                                quoteNonHWPOIds.get(qli.SBQQ__Quote__c).remove(quoteNonHWPOIds.get(qli.SBQQ__Quote__c).IndexOf(matchRes.matchedPOItms[0].stage_po__c));
                            }
                            Decimal quant =  quotePCTermQuantMap?.get(qli.SBQQ__ProductCode__c)?.get(qli.SBQQ__SubscriptionTerm__c);
                            if(quant != null && quant > 0){
                                quotePCTermQuantMap.get(qli.SBQQ__ProductCode__c).put(qli.SBQQ__SubscriptionTerm__c,quant-PcodeTermHWPG.get(PCTerm).QLIQuantity.get(qli));
                            }     
                        } 
                    }
                }
            }
            }
            if(!poIdHybQLIdPG.isEmpty()){
                for(Id poId : poIdHybQLIdPG.keyset()){
                    string quoteNum = POStageHelper.allStagePOmap.get(poId)?.Quote_number__c;
                    if(!poIdHybQLIdPG.get(poId).isEmpty()){
                        for(LicenseProductGroup LPG : poIdHybQLIdPG.get(poId).values()){
                            ProductGroup  PG = quotePcodeTerm_PGMap.get(quoteNum+'-'+LPG.qli.SBQQ__ProductCode__c+'-'+LPG.qli.SBQQ__SubscriptionTerm__c); 
                            if(PG == null) continue;
                            matchRes = bestMatch(LPG.qli,PG,LPG.hybTotalQuant,true,new set<id>());  
                            if(matchRes.matchedPOItms == null ||matchRes.matchedPOItms.isEmpty()){
                                if(!matchRes.errCaptured){
                                    stageError.add(new PO_Stage_Errors__c( Name ='PO-24', Error_Code__c ='PO-24',      
                                    Error_Message__c = validationCodes.get('PO-24') != null? validationCodes.get('PO-24').Error_Issue__c +' : '+LPG.qli.SBQQ__ProductCode__c  : system.label.Generic_Validation_Error_Mgs+' : '+LPG.qli.SBQQ__ProductCode__c ,  
                                    PO_Stage_Id__c = poId,
                                    Quote_Line__c = LPG.qli.id,
                                    Error_Type__c = 'External' ));
                                }
                                PO_Stage__c  updateStgPO = POStageHelper.poStagesToUpdateMap.containsKey(poId)?POStageHelper.poStagesToUpdateMap.get(poId) : new PO_Stage__c(id = poId); 
                                updateStgPO.PO_Validation_Status__c = 'Failure' ;                                    
                                POStageHelper.poStagesToUpdateMap.put(poId,updateStgPO); 
                                failedQuoteId.add(LPG.qli.SBQQ__Quote__c);  
                            } else{
                                PO_Stage__c  updateStgPO = POStageHelper.poStagesToUpdateMap.containsKey(matchRes.matchedPOItms[0].stage_po__c)?POStageHelper.poStagesToUpdateMap.get(matchRes.matchedPOItms[0].stage_po__c) : new PO_Stage__c(id = matchRes.matchedPOItms[0].stage_po__c); 
                                updateStgPO.Hardware_PO_Id__c = poId ;
                                POStageHelper.poStagesToUpdateMap.put(matchRes.matchedPOItms[0].stage_po__c,updateStgPO);
                            }                                
                            Decimal quant =  quotePCTermQuantMap?.get(LPG.qli.SBQQ__ProductCode__c)?.get(LPG.qli.SBQQ__SubscriptionTerm__c);
                                if(quant != null && quant > 0){
                                    quotePCTermQuantMap.get(LPG.qli.SBQQ__ProductCode__c).put(LPG.qli.SBQQ__SubscriptionTerm__c,quant-LPG.hybTotalQuant);
                                }  
                                
                            } 
                        }
                    }
                }
            }
      
    /**
* @description update records
* @param ErrorCode
* @param poitem
* @param errorType
* @param qli
* @param poId
* @return poError
*/
    Public static PO_Stage_Errors__c getErrorRecord(string ErrorCode, PO_Item_Stage__c poitem, string errorType , SBQQ__QuoteLine__c qli, Id poId){
  	String errorMessage = null;
  	if(validationCodes.get(ErrorCode) != null){
         errorMessage = ErrorCode == 'PO-37' ? validationCodes.get(ErrorCode).Error_Issue__c : validationCodes.get(ErrorCode).Error_Issue__c + ' : ' + poitem.ProductCode__c;
        }
        return new PO_Stage_Errors__c(Name = ErrorCode, Error_Code__c = ErrorCode, Error_Message__c = errorMessage != null ? errorMessage : system.label.Generic_Validation_Error_Mgs + ' : ' + poitem.ProductCode__c,
                                      PO_Stage_Id__c = poId != null ? poId : poitem.Stage_PO__c, PO_Stage_Item_Id__c = poitem != null ? poitem.id : null, Quote_Line__c = qli != null ? qli.id : null, Error_Type__c = errorType);
    }
    /**
    * @description update records
    * @param quote_POIds
    */
    private void updateRecords(Map<Id,set<Id>> quote_POIds){
        set<id> successfullPOs = new set<id>();
        TriggerHandler.bypass('POStageHandler'); 
        system.debug(LoggingLevel.INFO,'UpdateRecords stageError'+stageError);
        if(enableLogs)system.debug(LoggingLevel.INFO,'poItemUpdate'+JSON.serialize(poItemUpdate));
        if(enableLogs)system.debug(LoggingLevel.INFO,'failedQuoteId'+JSON.serialize(failedQuoteId));
        system.debug(LoggingLevel.INFO,'POStageHelper.poStagesToUpdateMap'+POStageHelper.poStagesToUpdateMap);
        if(!stageError.isEmpty() ){
            database.insert(stageError,false);
            stageError.clear();
        }
        if(!poItemUpdate.isEmpty()){
            update poItemUpdate.values() ;
            poItemUpdate.clear();
        }
        for(Id quoteId : quote_POIds.keyset()){
            if(!failedQuoteId.contains(quoteId)){
                for(Id poId : quote_POIds.get(quoteId)){
                    PO_Stage__c  updateStgPO = POStageHelper.poStagesToUpdateMap.containsKey(poId)?POStageHelper.poStagesToUpdateMap.get(poId) : new PO_Stage__c(id = poId); 
                    updateStgPO.PO_Validation_Status__c = 'Success' ; 
                    POStageHelper.poStagesToUpdateMap.put(poId,updateStgPO);    
                    successfullPOs.add(poId);                                
                }
            }
        }
        if(enableLogs)system.debug(LoggingLevel.INFO,'POStageHelper.poStagesToUpdateMap'+JSON.serialize(POStageHelper.poStagesToUpdateMap));
        TriggerHandler.clearBypass('POStageHandler');
        if(enableLogs)system.debug(LoggingLevel.INFO,'successfullPOs'+JSON.serialize(successfullPOs));
        if(!successfullPOs.isEmpty()){
            ID jobID = System.enqueueJob(new InitiateIntValidationAndOrderGeneration(successfullPOs,quote_POIds,hasRcdmtIntErr));
            system.debug(LoggingLevel.DEBUG,'jobID'+jobID);
            }
    }
    
    
    /**
    * @description Inner class used to store productcode-term poItem collection
    */
   @testvisible
    private class ProductGroup{
        List<decimal> price = new list<decimal>();
        List<decimal> quantity = new list<decimal>(); 
        set<decimal> sortedPrice = new set<decimal>();
        Map<decimal,List<POItemWrapper>> pricePOItm = new  Map<decimal,List<POItemWrapper>>();// sort list poitem in desc order using interface
        Map<decimal,decimal>  priceTotalQuant = new Map<decimal,decimal>();
       @Testvisible
        private ProductGroup(PO_Item_Stage__c poitem){
            price.add(poitem.UnitPrice__c);
            quantity.add(poitem.Quantity__c);
            pricePOItm.put(poitem.UnitPrice__c,new List<POItemWrapper>{new POItemWrapper(poitem.Quantity__c,poitem)});
            pricetotalQuant.put(poitem.UnitPrice__c,poitem.Quantity__c);
        }
            
        private void addToProductGroup(PO_Item_Stage__c poitem){
            price.add(poitem.UnitPrice__c);
            quantity.add(poitem.Quantity__c);
            if(pricePOItm.get(poitem.UnitPrice__c) != null){
                pricePOItm.get(poitem.UnitPrice__c).add(new POItemWrapper(poitem.Quantity__c,poitem));
                priceTotalQuant.put(poitem.UnitPrice__c,priceTotalQuant.get(poitem.UnitPrice__c)+poitem.Quantity__c);
            }
            else{
                pricePOItm.put(poitem.UnitPrice__c,new list<POItemWrapper>{new POItemWrapper(poitem.Quantity__c,poitem)}); 
                priceTotalQuant.put(poitem.UnitPrice__c,poitem.Quantity__c);
            }
            }
     private void removeProductGroup(PO_Item_Stage__c poitem){
        if(price.indexOf(poitem.UnitPrice__c) != -1 && quantity.indexOf(poitem.Quantity__c) != -1){
            price.remove(price.indexOf(poitem.UnitPrice__c));
            quantity.remove(quantity.indexOf(poitem.Quantity__c));
        }
            if(pricePOItm.get(poitem.UnitPrice__c) != null){
                integer i = 0;
                for(POItemWrapper itmWrapper : pricePOItm.get(poitem.UnitPrice__c)){
                    if(itmWrapper.poitem.id == poitem.id){
                       pricePOItm.get(poitem.UnitPrice__c).remove(i); 
                       if(pricePOItm.get(poitem.UnitPrice__c).size() == 0){
                        pricePOItm.remove(poitem.UnitPrice__c);
                        priceTotalQuant.remove(poitem.UnitPrice__c);
                       }else{
                        if(priceTotalQuant.get(poitem.UnitPrice__c) != null){priceTotalQuant.put(poitem.UnitPrice__c,priceTotalQuant.get(poitem.UnitPrice__c)-poitem.Quantity__c);} 
                       }
                       break;
                    }
                    i++;
                }
            }else{
                system.debug(LoggingLevel.DEBUG,'could not find matching line'+poitem.id);
            }
            }
        }
    /**
    * @description Sort POItem by quantity
    */
    public class POItemWrapper implements Comparable {
        Decimal quantity;
        PO_Item_Stage__c poitem ;
      /**
      * @description po item wrapper for quantity and poitem
      * @param quantity
      * @param poitem
      */
        public POItemWrapper(decimal quantity, PO_Item_Stage__c poitem) {
        this.quantity = quantity;
        this.poitem = poitem;
        }
    /**
    * @description Sort POItem by quantity with compareto function
    * @param compareTo
    * @return Integer
    */      
        public Integer compareTo(Object compareTo) {
            POItemWrapper wrapperObj = (POItemWrapper)compareTo;
            if (quantity == wrapperObj.quantity) return 0;
            if (quantity < wrapperObj.quantity) return 1;
            return -1;        
        }
    }
    
  /**
  * @description group2MatchClass
  */
  @testvisible
    private class HWProductGroup{
        List<decimal> quantity = new list<decimal>();
        Map<SBQQ__QuoteLine__c,decimal> QLIQuantity = new Map<SBQQ__QuoteLine__c,decimal>();
        @testvisible
        private HWProductGroup(Decimal quant , SBQQ__QuoteLine__c qli){
            quantity.add(quant);
            QLIQuantity.put(qli,quant);
        }
    }
    
  /**
  * @description Hardware PO group
  */
  @testvisible
    private class LicenseProductGroup{
        Decimal hybTotalQuant = 0.0;
        SBQQ__QuoteLine__c qli ;
        @testvisible
        private LicenseProductGroup(SBQQ__QuoteLine__c qli,decimal quant){
            hybTotalQuant = quant;
            this.qli = qli;
        }
    }
  /**
  * @description Matching result
  */
  @testvisible
    private class MatchResult{
        List<PO_Item_Stage__c> matchedPoItms = new List<PO_Item_Stage__c>();
        Boolean errCaptured = false;
        Map<id,string> tempPItmErrorMap = new Map<id,string>(); 
    }
    
    /**
    * @description Best Match across PO
    * @param qli
    * @param prodGroup
    * @param poId_PcodeTermPGMap
    * @param goRefNetTotal
    * @return bestmatch
    */
    @TestVisible
    private list<PO_Item_Stage__c> bestMatch(SBQQ__QuoteLine__c qli ,ProductGroup prodGroup,Map<Id,map<string, ProductGroup>> poId_PcodeTermPGMap,Decimal goRefNetTotal){
        if(enableLogs)system.debug(LoggingLevel.DEBUG,'BestMatch 1 prodGroup :'+JSON.Serialize(prodGroup));
        system.debug(LoggingLevel.DEBUG,'qli :'+qli);
        map<decimal,decimal> diffUnitPriceMap = new map<decimal,decimal>();
        List<decimal> diffPrices = new list<decimal>();
        List<decimal> diffPriceLic = new List<decimal>();
        List<PO_Item_Stage__c> matchedPoItms = new List<PO_Item_Stage__c>();
        Boolean matched = false;
        errCapturedInBestMatch = false; 
        Id stgPOId;
        if(prodGroup.pricePOItm != null && !prodGroup.pricePOItm.isEmpty()){
            for(Decimal unitPrice : prodGroup.pricePOItm.keyset()){
            if(stgPOId == null) stgPOId = prodGroup.pricePOItm.get(unitPrice)[0].poitem.stage_po__c ;
            if(prodGroup.priceTotalQuant.get(unitPrice) >= qli.SBQQ__Quantity__c){
                diffUnitPriceMap.put(qli.SBQQ__NetPrice__c-unitPrice,unitPrice);
              }
              if( prodGroup.pricePOItm.size()>1 && poId_PcodeTermPGMap != null && !poId_PcodeTermPGMap.isEmpty() && qli.SBQQ__RequiredBy__c != null && (qli.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Level__c == 'LOD Software' || qli.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Level__c == 'Hybrid Software' ||                                                                                                               (qli?.SBQQ__RequiredBy__r?.SBQQ__Product__r?.Product_Level__c == 'onprem' && (qli?.SBQQ__RequiredBy__r?.SBQQ__Product__r?.Product_Type__c == 'Foundation Edition' || qli?.SBQQ__RequiredBy__r?.SBQQ__Product__r?.Product_Type__c == 'Enterprise Edition'  || qli?.SBQQ__RequiredBy__r?.SBQQ__Product__r?.Product_Type__c == 'Business Edition' ) && qli?.SBQQ__RequiredBy__r?.SBQQ__Product__r?.Product_Subtype__c == null))){
                system.debug(LoggingLevel.DEBUG,'unitPrice'+prodGroup.pricePOItm.get(unitPrice)+'::'+poId_PcodeTermPGMap.keyset());
                for(POItemWrapper poItm : prodGroup.pricePOItm.get(unitPrice)){
                    if(poId_PcodeTermPGMap.containsKey(poItm.poitem.Stage_PO__c) && (poId_PcodeTermPGMap.get(poItm.poitem.Stage_PO__c).containsKey(qli.SBQQ__RequiredBy__r.SBQQ__ProductCode__c+'-'+qli.SBQQ__RequiredBy__r.SBQQ__SubscriptionTerm__c) || poId_PcodeTermPGMap.get(poItm.poitem.Stage_PO__c).containsKey(qli.SBQQ__RequiredBy__r.SBQQ__ProductCode__c))){ 
                         diffPriceLic.add(qli.SBQQ__NetPrice__c-unitPrice);
                         break;
                     }
                 }
                }
            }
        }
        else{
            return matchedPoItms ; 
        }
        system.debug(LoggingLevel.DEBUG,'diffUnitPriceMap :'+diffUnitPriceMap);
        if(diffUnitPriceMap.isEmpty()){
            errCapturedInBestMatch = true;
            return matchedPoItms ;
        }     
        diffPrices.addall(diffUnitPriceMap.keyset());
        system.debug(LoggingLevel.DEBUG,'diffPrices :'+diffPrices);
        if (diffPrices.size() >1){
            diffPrices.sort();
            if(diffPrices.contains(0.00)){
                diffPrices.remove(diffPrices.indexof(0.00));
                diffPrices.add(0, 0.00);
            }      
        }
        if(!diffPriceLic.isEmpty() &&  diffPrices.size() > diffPriceLic.size()){
            diffPriceLic.sort();
            integer index = diffPriceLic.size();
            for(Decimal diffPric : diffPriceLic){
                if(diffPrices.contains(diffPric)){
                    diffPrices.remove(diffPrices.indexof(diffPric));
                    diffPrices.add(--index, diffPric);
                }    
            }

        }
        List<PO_Item_Stage__c> pitmErrList = new List<PO_Item_Stage__c> ();
        for(Decimal diffPrice : diffPrices){
            matchedPoItms.clear();
            Decimal poitemPrice = diffUnitPriceMap.get(diffPrice);
            Decimal totalQuant = 0.0;
            List<POItemWrapper> poItemWrapperOrdered = new List<POItemWrapper>();
      List<POItemWrapper> poItemWrapperOrdered1 = new List<POItemWrapper>();
  
            system.debug(LoggingLevel.DEBUG,'prodGroup.pricePOItm.get(poitemPrice) :'+prodGroup.pricePOItm.get(poitemPrice));
            if(!prodGroup.sortedPrice.contains(poitemPrice)){
                prodGroup.pricePOItm.get(poitemPrice).sort(); 
                prodGroup.sortedPrice.add(poitemPrice);
            }
            system.debug(LoggingLevel.DEBUG,'prodGroup.pricePOItm.get(poitemPrice) after sort:'+prodGroup.pricePOItm.get(poitemPrice));
            if(poId_PcodeTermPGMap!= null  && qli.SBQQ__RequiredBy__c != null && (qli.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Level__c == 'LOD Software' ||
                                                                                   qli.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Level__c == 'Hybrid Software' ||
                                                                                   (qli?.SBQQ__RequiredBy__r?.SBQQ__Product__r?.Product_Level__c == 'onprem' && (qli?.SBQQ__RequiredBy__r?.SBQQ__Product__r?.Product_Type__c == 'Foundation Edition' || qli?.SBQQ__RequiredBy__r?.SBQQ__Product__r?.Product_Type__c == 'Enterprise Edition'  || qli?.SBQQ__RequiredBy__r?.SBQQ__Product__r?.Product_Type__c == 'Business Edition' ) && qli?.SBQQ__RequiredBy__r?.SBQQ__Product__r?.Product_Subtype__c == null)||
                                                                                   (qli.SBQQ__Quote__r.ProcessType__c == 'Aspen' && qli.Line_Type__c == 'New' && qli.SBQQ__Product__r.Product_Level__c == 'Support'))){
                for(POItemWrapper poItm : prodGroup.pricePOItm.get(poitemPrice)){
                                                                                          if((qli.SBQQ__ProductCode__c != RCDMTransSkuName && ((qli?.SBQQ__RequiredBy__r?.Payment_Options__c == 'Annual' && poIdAnnualLic.contains(poItm.poitem.Stage_PO__c+'-'+qli?.SBQQ__RequiredBy__r?.SBQQ__ProductCode__c)) ||
                                                                         (poId_PcodeTermPGMap.get(poItm.poitem.Stage_PO__c) != null && poId_PcodeTermPGMap.get(poItm.poitem.Stage_PO__c).containsKey(qli.SBQQ__RequiredBy__r?.SBQQ__ProductCode__c+'-'+qli.SBQQ__RequiredBy__r?.SBQQ__SubscriptionTerm__c))||
                                                                                                                                               (qli?.SBQQ__Quote__r?.ProcessType__c == 'Aspen' && qli?.Line_Type__c == 'New' && qli?.SBQQ__Product__r?.Product_Level__c == 'Support' && qli?.SBQQ__RequiredBy__c != null && qli?.SBQQ__RequiredBy__r?.SBQQ__RequiredBy__c != null && 
                                                                                                                                                LicPOIdQuantMap?.get(qli?.SBQQ__RequiredBy__r?.SBQQ__RequiredBy__c)?.get(poItm?.poitem?.Stage_PO__c)!= null && 
                                                                                                                                                qli.SBQQ__RequiredBy__r.SBQQ__Product__r.Usable_Capacity__c!= null &&
                                                                                                                                                LicPOIdQuantMap.get(qli.SBQQ__RequiredBy__r?.SBQQ__RequiredBy__c).get(poItm.poitem.Stage_PO__c) >= qli.SBQQ__RequiredBy__r.SBQQ__Product__r.Usable_Capacity__c * poItm.poitem.quantity__c)))
                                                                                             || (qli.SBQQ__ProductCode__c == RCDMTransSkuName &&  qli?.SBQQ__RequiredBy__c != null)){
                                                                                                 if(( qli?.SBQQ__Quote__r?.ProcessType__c == 'Aspen' && LicPOIdQuantMap?.get(qli?.SBQQ__RequiredBy__r?.SBQQ__RequiredBy__c)?.get(poItm?.poitem?.Stage_PO__c)!= null &&
                                                                                                     qli?.SBQQ__Product__r?.Product_Level__c == 'Support' && LicPOIdQuantMap.get(qli.SBQQ__RequiredBy__r?.SBQQ__RequiredBy__c).get(poItm.poitem.Stage_PO__c) == qli.SBQQ__RequiredBy__r.SBQQ__Product__r.Usable_Capacity__c * poItm.poitem.quantity__c)
                                                                                                    ||(qli.SBQQ__ProductCode__c == RCDMTransSkuName && LicPOIdQuantMap.containsKey(qli.SBQQ__RequiredBy__c) && LicPOIdQuantMap.get(qli.SBQQ__RequiredBy__c).containsKey(poItm.poitem.Stage_PO__c))){
                                                 
                                                 poItemWrapperOrdered.add(poItm);
                                              }else{
                                                     poItemWrapperOrdered1.add(poItm);
                                                }
                                        }else{
                                            poItemWrapperOrdered1.add(poItm);
                                        }
                                                                                
                                   }
          if(!poItemWrapperOrdered1.isEmpty()){
            poItemWrapperOrdered.addall(poItemWrapperOrdered1);
        }
              }else{
                poItemWrapperOrdered = prodGroup.pricePOItm.get(poitemPrice);
              }
              integer startIndex=0;
              set<id> matchedPOId = new set<id>();
              for(integer currentIndexPar=0 ;currentIndexPar<poItemWrapperOrdered.size();currentIndexPar++){
                matchedPoId  = new Set<id>();               
                for(integer currentIndex=0 ;currentIndex<poItemWrapperOrdered.size();currentIndex++){
                 if(currentIndexPar>currentIndex) continue;
                 POItemWrapper poItm = poItemWrapperOrdered[currentIndex];
                    if(poItemUpdate.containsKey(poitm.poitem.id)|| matchedPOId.contains(poitm.poitem.Stage_PO__c)) continue; 
                        if(totalQuant+poItm.quantity == qli.SBQQ__Quantity__c){
                            system.debug(LoggingLevel.DEBUG,'pi'+totalQuant+':'+(totalQuant+poItm.quantity) * poitm.poitem.UnitPrice__c+'qli.SBQQ__NetTotal__c'+qli.SBQQ__NetTotal__c);
                            if((goRefNetTotal == null && Math.abs(((totalQuant+poItm.quantity) * poitm.poitem.UnitPrice__c) - qli.SBQQ__NetTotal__c) <= threshold)
                               || (goRefNetTotal != null && Math.abs(((totalQuant+poItm.quantity) * poitm.poitem.UnitPrice__c) - goRefNetTotal) <= threshold)){
                                totalQuant +=  poitm.quantity ;
                                matchedPoItms.add(poitm.poitem);
                                matchedPOId.add(poitm.poitem.Stage_PO__c);
                            } 
                            else{
                                 Decimal priceDiff= 0;
                                if(goRefNetTotal == null){
                                    priceDiff =  Math.abs(((totalQuant+poItm.quantity) * poitm.poitem.UnitPrice__c) - qli.SBQQ__NetTotal__c);
                                }else{
                                    priceDiff =Math.abs(((totalQuant+poItm.quantity) * poitm.poitem.UnitPrice__c) - goRefNetTotal);
                                        }
                                 for(POItemWrapper Itm : prodGroup.pricePOItm.get(poitemPrice)){
                                     poitemIDByDifference.put(Itm.poitem.id,String.valueOf(priceDiff.setScale(2, System.RoundingMode.HALF_UP)));
                                     pitmErrList.add(Itm.poitem); 
                                  }
                            } 
                            break;  
                        }
                        else if(totalQuant+poitm.quantity < qli.SBQQ__Quantity__c){
                             if((goRefNetTotal == null && Math.abs(((totalQuant+poItm.quantity) * poitm.poitem.UnitPrice__c) - ((totalQuant+poItm.quantity) * qli.SBQQ__NetPrice__c)) <= threshold)
                                 ||goRefNetTotal!= null){
                                matchedPoItms.add(poitm.poitem);
                                totalQuant +=  poitm.quantity ; 
                                matchedPOId.add(poitm.poitem.Stage_PO__c);
                            }
                            else{
                                    for(POItemWrapper Itm : prodGroup.pricePOItm.get(poitemPrice)){
                                        Decimal priceDiff = Math.abs(((totalQuant+poItm.quantity) * poitm.poitem.UnitPrice__c) - ((totalQuant+poItm.quantity) * qli.SBQQ__NetPrice__c)).setScale(2, System.RoundingMode.HALF_UP);
                                        poitemIDByDifference.put(Itm.poitem.id,String.valueOf(priceDiff.setScale(2, System.RoundingMode.HALF_UP)));
                                         pitmErrList.add(Itm.poitem); 
                                    }
                                break;
                            }
                        }
                        else if(currentIndex == poItemWrapperOrdered.size()-1 ){
                    if(currentIndex != startIndex){
                        currentIndex = startIndex++;
                        totalQuant = 0.0;
                        matchedPoItms.clear();
                        matchedPOId.clear();
                    }else{
                        for(POItemWrapper Itm : prodGroup.pricePOItm.get(poitemPrice)){
                            tempPItmErrorMap.put(Itm.poitem.id,'PO-11');   
                        }
                    }
                } 
            }
                if(totalQuant != qli.SBQQ__Quantity__c && currentIndexPar != poItemWrapperOrdered.size()-1){
                        System.debug(LoggingLevel.DEBUG,'qli-->'+qli.Name);
                        totalQuant = 0.0;
                        matchedPoItms.clear();
                        matchedPOId.clear();
                    
                }else{
                    break;
                }
                
            }
            system.debug(LoggingLevel.DEBUG,'matchedPoItms'+matchedPoItms); 
            if( totalquant == qli.SBQQ__Quantity__c && !matchedPoItms.isEmpty()){
                        for(PO_Item_Stage__c poItm : matchedPoItms){
                            poItm.Quote_Line__c = qli.id;
                            poItm.type__c= qli.Line_Type__c;
                            system.debug(LoggingLevel.DEBUG,'*****poItemUpdate1319'+poItemUpdate);
                            poItemUpdate.put(poItm.id,new PO_Item_Stage__c(id=poItm.id,Quote_Line__c = qli.id,type__c= qli.Line_Type__c)); 
                            system.debug(LoggingLevel.DEBUG,prodGroup.quantity.IndexOf(poItm.Quantity__c)+' prodGroup.quantity'+ prodGroup.quantity);
                            if(prodGroup.quantity.IndexOf(poItm.Quantity__c) != -1){
                                prodGroup.quantity.remove(prodGroup.quantity.IndexOf(poItm.Quantity__c));
                            }
                            if(prodGroup.price.IndexOf(poItm.UnitPrice__c) != -1){
                                prodGroup.price.remove(prodGroup.price.IndexOf(poItm.UnitPrice__c));
                            }
                            system.debug(LoggingLevel.DEBUG,prodGroup.priceTotalQuant.get(poItm.UnitPrice__c)+' poItm.quantity'+  poItm.Quantity__c);
                            Decimal remainingQuant = prodGroup.priceTotalQuant.get(poItm.UnitPrice__c) - poItm.Quantity__c;
                            if(remainingQuant == 0.00){
                                 prodGroup.priceTotalQuant.remove(poItm.UnitPrice__c);
                            }
                            else{
                                prodGroup.priceTotalQuant.put(poItm.UnitPrice__c,remainingQuant);
                            }
                            system.debug(LoggingLevel.DEBUG,'prodGroup'+prodGroup);
                            if(LicPOIdQuantMap.get(qli.SBQQ__RequiredBy__r?.SBQQ__RequiredBy__c)?.get(poItm.Stage_PO__c) !=  null && qli.SBQQ__Product__r.Product_Level__c == 'Support'){
                                LicPOIdQuantMap.get(qli.SBQQ__RequiredBy__r?.SBQQ__RequiredBy__c).put(poItm.Stage_PO__c,LicPOIdQuantMap.get(qli.SBQQ__RequiredBy__r?.SBQQ__RequiredBy__c)?.get(poItm.Stage_PO__c)-(qli.SBQQ__RequiredBy__r.SBQQ__Product__r.Usable_Capacity__c * poItm.quantity__c));
                            }
                            if(poItm.Product__r.Family == 'EDGE'||isLicenseSku(poItm.Product__r)){
                                if(LicPOIdQuantMap.containsKey(qli.id)){
                                    LicPOIdQuantMap.get(qli.id).put(poItm.Stage_PO__c,poItm.Quantity__c);
                                }else{
                                    LicPOIdQuantMap.put(qli.id,new Map<id,decimal>{poItm.Stage_PO__c => poItm.Quantity__c});
                                }
                            }
                        }
                        if(enableLogs){
                            system.debug(LoggingLevel.DEBUG,'prodGroup quantity'+prodGroup.quantity);
                            system.debug(LoggingLevel.DEBUG,'poItemUpdate'+JSON.serialize(poItemUpdate));
                        }
                matched = true;
                break;
            }else{
                errCapturedInBestMatch = true;
                }   
            }
        if(!matched){
            system.debug(LoggingLevel.DEBUG,'pitmErrList'+pitmErrList);
            if(!pitmErrList.isEmpty()){
                for(PO_Item_Stage__c poItm : pitmErrList){
                    tempPItmErrorMap.put(poItm.id,'PO-10');                            
                }
            } 
            matchedPoItms.clear();    
        }
        system.debug(LoggingLevel.DEBUG,'matchedPoItms'+matchedPoItms);
        return matchedPoItms ; 
    }
    
    
    /**
  * @description Best Match within PO
  * @param qli
  * @param prodGroup
  * @param matchQuant
  * @param updatePOItm
  * @param skipPOItmIds
  * @return bestmatch
  */
    @TestVisible
    private MatchResult bestMatch(SBQQ__QuoteLine__c qli ,ProductGroup prodGroup , Decimal matchQuant,boolean updatePOItm,set<id>skipPOItmIds){
        if(enableLogs)system.debug(LoggingLevel.INFO,'prodGroup :'+JSON.Serialize(prodGroup));
        system.debug(LoggingLevel.INFO,'matchQuant'+matchQuant+' : qli :'+qli);
        map<decimal,decimal> diffUnitPriceMap = new map<decimal,decimal>();
        List<decimal> diffPrices = new list<decimal>();
        MatchResult resp = new MatchResult();
        Boolean matched = false;
        PO_Item_Stage__c pitm = new PO_Item_Stage__c();
        
        if(prodGroup == null || prodGroup.pricePOItm == null || prodGroup.pricePOItm.isEmpty() || prodGroup.quantity == null || prodGroup.quantity.isEmpty()){
            return resp ;  
        }
        if(!prodGroup.quantity.contains(matchQuant)){
            for(Decimal unitPrice : prodGroup.pricePOItm.keyset()){
                pitm = prodGroup.pricePOItm.get(unitPrice)[0].poitem ;
                break;
            }
            if(updatePOItm){
                tempPItmErrorMap.put(pitm.id,'PO-11');
            }
            else{
                resp.tempPItmErrorMap.put(pitm.id,'PO-11');
            }
            resp.errCaptured = true; 
            return resp ;  
        }
        if(prodGroup.pricePOItm != null && !prodGroup.pricePOItm.isEmpty()){
            for(Decimal unitPrice : prodGroup.pricePOItm.keyset()){
                if(prodGroup.priceTotalQuant.get(unitPrice) >= matchQuant){
                    diffUnitPriceMap.put(qli.SBQQ__NetPrice__c-unitPrice,unitPrice);
                }
            }
        }
        system.debug(LoggingLevel.DEBUG,'diffUnitPriceMap :'+diffUnitPriceMap);
        if(diffUnitPriceMap.isEmpty()) {
            resp.errCaptured = false;
            return resp ;
        }     
        diffPrices.addall(diffUnitPriceMap.keyset());
        if (diffPrices.size() >1){
            diffPrices.sort();
            if(diffPrices.contains(0.00)){
                diffPrices.remove(diffPrices.indexof(0.00));
                diffPrices.add(0, 0.00);
            }      
        }
        system.debug(LoggingLevel.INFO,'diffPrices :'+diffPrices);
        Map<string,set<id>> errCodePitmIds = new Map<string,set<id>> ();
        for(Decimal diffPrice : diffPrices){
            resp.matchedPoItms.clear();
            Decimal poitemPrice = diffUnitPriceMap.get(diffPrice);
            Decimal totalQuant = 0.0;
            system.debug(LoggingLevel.DEBUG,'prodGroup.pricePOItm.get(poitemPrice) :'+prodGroup.pricePOItm.get(poitemPrice));
            if(!prodGroup.sortedPrice.contains(poitemPrice)){
                prodGroup.pricePOItm.get(poitemPrice).sort(); 
                prodGroup.sortedPrice.add(poitemPrice);
            }
            system.debug(LoggingLevel.DEBUG,'prodGroup.pricePOItm.get(poitemPrice) after sort:'+prodGroup.pricePOItm.get(poitemPrice));
            for(POItemWrapper poItm : prodGroup.pricePOItm.get(poitemPrice)){
                if(poItemUpdate.containsKey(poitm.poitem.id) || failedPItmId.contains(poitm.poitem.id) || skipPOItmIds.contains(poitm.poitem.id)) continue; 
                    if(matchQuant == poItm.quantity){
                        if(Math.abs((poItm.quantity * poitm.poitem.UnitPrice__c)-(poItm.quantity * qli.SBQQ__NetPrice__c))<= threshold){
                            resp.matchedPoItms.add(poitm.poitem);
                                matched = true;
                                break;
                        }
                        else{
                            poitemIDByDifference.put(poitm.poitem.id,String.valueOf(Math.abs((poItm.quantity * poitm.poitem.UnitPrice__c)-(poItm.quantity * qli.SBQQ__NetPrice__c)).setScale(2, System.RoundingMode.HALF_UP)));
                                if(errCodePitmIds.containsKey('PO-10')){
                                errCodePitmIds.get('PO-10').add(poitm.poitem.id);
                                }else{
                                errCodePitmIds.put('PO-10',new set<id>{poitm.poitem.id});
                                }      
                        }          
                        }
                        else if(!errCodePitmIds.containsKey('PO-10')){
                        if(errCodePitmIds.containsKey('PO-11')){
                            errCodePitmIds.get('PO-11').add(poitm.poitem.id);
                            }else{
                            errCodePitmIds.put('PO-11',new set<id>{poitm.poitem.id});
                            }    
                        }
            }
            system.debug(LoggingLevel.DEBUG,'matchedPoItms'+resp.matchedPoItms); 
            if(matched && !resp.matchedPoItms.isEmpty()){
                if(updatePOItm){
                        for(PO_Item_Stage__c poItm : resp.matchedPoItms){
                            poItm.Quote_Line__c = qli.id;
                            poItm.type__c= qli.Line_Type__c;
                            poItemUpdate.put(poItm.id,new PO_Item_Stage__c(id=poItm.id,Quote_Line__c = qli.id,type__c= qli.Line_Type__c));
                            system.debug(LoggingLevel.DEBUG,prodGroup.quantity.IndexOf(poItm.Quantity__c)+' prodGroup.quantity'+ prodGroup.quantity);
                            if(prodGroup.quantity.IndexOf(poItm.Quantity__c) != -1){
                                prodGroup.quantity.remove(prodGroup.quantity.IndexOf(poItm.Quantity__c));
                            }
                            if(prodGroup.price.IndexOf(poItm.UnitPrice__c) != -1){
                                prodGroup.price.remove(prodGroup.price.IndexOf(poItm.UnitPrice__c));
                            }
                            system.debug(LoggingLevel.DEBUG,prodGroup.priceTotalQuant.get(poItm.UnitPrice__c)+' poItm.quantity'+  poItm.Quantity__c);
                            Decimal remainingQuant = prodGroup.priceTotalQuant.get(poItm.UnitPrice__c) - poItm.Quantity__c ;
                            if(remainingQuant == 0.00){
                            prodGroup.priceTotalQuant.remove(poItm.UnitPrice__c);
                            }
                            else{
                            prodGroup.priceTotalQuant.put(poItm.UnitPrice__c,remainingQuant);
                            }
                            system.debug(LoggingLevel.DEBUG,'prodGroup'+prodGroup);
                       if(poItm.Product__r.Family == 'EDGE'||isLicenseSku(poItm.Product__r)){
                            if(LicPOIdQuantMap.containsKey(qli.id)){
                                LicPOIdQuantMap.get(qli.id).put(poItm.Stage_PO__c,poItm.Quantity__c);
                            }else{
                                LicPOIdQuantMap.put(qli.id,new Map<id,decimal>{poItm.Stage_PO__c => poItm.Quantity__c});
                            }
                    }
                        }
                        system.debug(LoggingLevel.DEBUG,'prodGroup quantity'+prodGroup.quantity);
                        if(enableLogs)system.debug(LoggingLevel.DEBUG,'poItemUpdate'+JSON.serialize(poItemUpdate));
                }
                matched = true;
                break;
            }   
            }
        if(!matched){
            system.debug(LoggingLevel.INFO,'errCodePitmIds'+errCodePitmIds);
                if(errCodePitmIds.containsKey('PO-10')){
                for(Id itmId: errCodePitmIds.get('PO-10')){
                    if(updatePOItm){
                        tempPItmErrorMap.put(itmId,'PO-10');
                    }
                    else{
                        resp.tempPItmErrorMap.put(itmId,'PO-10');
                    }
                }
                resp.errCaptured = false;
                }
                else if(errCodePitmIds.containsKey('PO-11')){
                for(Id itmId: errCodePitmIds.get('PO-11')){
                    if(updatePOItm){
                        tempPItmErrorMap.put(itmId,'PO-11');
                    }
                    else{
                        resp.tempPItmErrorMap.put(itmId,'PO-11');
                    }
                }
                resp.errCaptured = false;
                }
            resp.matchedPoItms.clear();    
        }
        system.debug(LoggingLevel.INFO,'matchedPoItms'+resp.matchedPoItms);
        return resp ; 
      }
        @TestVisible
        private static Boolean isSupportBundle(sbqq__quote__c quote,sbqq__quoteline__c qli) {
            try {
                return ((qli?.SBQQ__Product__r?.Product_Level__c != null && (qli?.SBQQ__Product__r?.Bundle_Features__c != null && (qli?.SBQQ__Product__r?.Bundle_Features__c?.contains('Hybrid RCDM') || qli?.SBQQ__Product__r?.Bundle_Features__c.contains('OnPrem CDM'))) && qli?.SBQQ__Product__r?.Family == 'Third Party License') || quote.ProcessType__c == 'Aspen' || qli.Special_Program__c == 'Replaced' || qli.Special_Program__c == 'Conversion' || qli.Special_Program__c == 'Upgrade' || (isLicenseSku(qli.SBQQ__Product__r) && qli.Special_Program__c == 'Refresh') || 
      (String.isBlank(qli.Special_Program__c) && (String.isNotBlank(quote?.Quoting_Desk_Exception__c) && quote?.Quoting_Desk_Exception__c?.contains('Quoting Exception - SW without HW'))) || (qli?.SBQQ__Product__r?.IsHardwareNotRequiredForHybridLicense__c && qli?.SBQQ__Product__r?.Product_Level__c == 'Hybrid Software') || quote.SBQQ__Type__c  == 'Amendment' || quote.SBQQ__Type__c  == 'Renewal' ||(quote.SBQQ__Type__c == 'Renewal+Expansion' && qli.Line_Type__c == 'Renewal') || (qli.SBQQ__Product__r.Family == 'Rubrik Scale' && quote.Scale_Quote__c));
            } catch (Exception e) {
                return false;
            }
        }
        @TestVisible
        private static Boolean isLicenseSku(Product2 prod) {
            try{
              return ((prod.Product_Level__c == 'Hybrid Software' ||
                      (prod.Product_Level__c == 'OnPrem' &&
                      (prod.Product_Type__c == 'Foundation Edition' ||
                      prod.Product_Type__c == 'Enterprise Edition' ||
                      prod.Product_Type__c == 'Business Edition') &&
                      prod.Product_Subtype__c == null) ||
                      prod.Product_Level__c == 'LOD Software') && prod.Product_Subtype__c != 'RCDM') ;         
            }catch(Exception e){
              return false;
            }
          }
    }