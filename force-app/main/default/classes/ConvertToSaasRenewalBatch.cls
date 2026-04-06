/**Batch class which converts V1 to V2 SKUs on Renewal. */
/**
* @description :ConvertToSaasRenewalBatch - Batch class for conversion 
*/
public without sharing class ConvertToSaasRenewalBatch implements Database.batchable<sObject>{ 

    @TestVisible private static Boolean forceTestException = false;
    
    /**quotesToConvert */ 
    List<SBQQ__Quote__c> quotesToConvert ; 

    /**
     * @description : This is constructor 
     * @param quotesToConvert
     */
    public ConvertToSaasRenewalBatch(List<SBQQ__Quote__c> quotesToConvert){
        this.quotesToConvert = quotesToConvert; 
    } 
    
    /**
    * @description : Start Method 
    * @param BC
    * @return Database.getQueryLocator
    */
    public Database.QueryLocator start(Database.BatchableContext BC){ 
        String query = 'SELECT Id, Force_Recalculation__c, RWD_Deal_Ops_Exception__c, SBQQ__Type__c, Polaris_Conversion__c, Polaris_Conversion_In_Progress__c, Eligible_for_RCDM_T__c,Is_Federal_Eligible_Quote__c, Selective_Account_Eligible_for_RCDM_T__c,RCDMT_EOL_Date__c, Is_Customer_Fully_Transitioned__c,SBQQ__StartDate__c, SBQQ__LineItemCount__c FROM SBQQ__Quote__c WHERE Id IN: quotesToConvert AND Amended_Renewed_Service_Contract__r.Renew_to_Old_SKUs__c = FALSE  ';
        return Database.getQueryLocator(query); 
    }   
    
    /**
     * @description Execute 
     * @param info :BatchableContext, List of quotes
     * @param scope :List of quotes
     */
    public void execute(Database.BatchableContext info, List<SBQQ__Quote__c> scope){
        SBQQ__Quote__c q1;
        for(Sobject s: scope){
            q1=(SBQQ__Quote__c)s;
        }
        
        try{
            X0_RCDM_Dates__mdt rcdmDatesObj;    
            Boolean rcdmValidQuote = false;
            Date quotRangeEnd;
            
            //CPQ22-2071 
            if(rcdmDatesObj == null){
                rcdmDatesObj = [SELECT Id, Order_Sub_Type__c, Order_Type__c, IT_Product_Type__c, Licensing_Type__c, Subscription_Term__c, 
                                DeveloperName, Approval_Category__c, List_Price__c, Product_Level__c, Subscription_Pricing__c, Subscription_Type__c, 
                                EndDate_Day__c, EndDate_Month__c, EndDate_Year__c, StartDate_Day__c, StartDate_Month__c, StartDate_Year__c, 
                                Special_Price__c, Description__c, Sales_Comp_Category__c FROM X0_RCDM_Dates__mdt WHERE DeveloperName = 'RCDM_Dates' LIMIT 1];
                
            }
            Set<id> prodEligibleForRCDMT = new Set<id>();
            List<SBQQ__QuoteLineGroup__c> QLG = new List<SBQQ__QuoteLineGroup__c>();    
            if(/*rcdmDatesObj != null && rcdmDatesObj.EndDate_Year__c != null && rcdmDatesObj.EndDate_Month__c != null 
               && rcdmDatesObj.EndDate_Day__c != null &&*/ q1!= null && q1.RCDMT_EOL_Date__c!= null) {
                   // quotRangeEnd = Date.newInstance(Integer.valueOF(rcdmDatesObj.EndDate_Year__c), Integer.valueOF(rcdmDatesObj.EndDate_Month__c), 
                   //Integer.valueOF(rcdmDatesObj.EndDate_Day__c));
                   quotRangeEnd  = q1.RCDMT_EOL_Date__c; // added for CPQ22-3874                          
                   if(q1.Eligible_for_RCDM_T__c == true && q1.Is_Customer_Fully_Transitioned__c == false){
                       rcdmValidQuote = true;
                       QLG = [SELECT Id FROM SBQQ__QuoteLineGroup__c WHERE Name ='Renewal Quote' AND SBQQ__Quote__c =: q1.Id];
                       
                   }
               }

            
            Set<String> productCodesNotFound = new Set<String>();
            Renewal_Conversion_Status__c rcs = new Renewal_Conversion_Status__c();
            rcs.Quote__c = q1.Id;
            rcs.Status__c ='In Progress';
            SBQQ.TriggerControl.disable();
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true;
            insert rcs;
            
            Set<String> prodsTobeConverted = new Set<String>();
            string qLQuery = 'SELECT Id, SBQQ__ProductCode__c, SBQQ__Description__c, SBQQ__Discount__c, SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c, Subscribed_Asset_Name__c, SubscribedAssetNames__c, SBQQSC__RenewedContractLine__c, SBQQ__RequiredBy__c, SBQQ__StartDate__c, SBQQ__EndDate__c, TPH_Drive_Size__c, TPH_Models_Gen__c, TPH_Quantity__c';
            List<String> relatedList = new List<String>
            {'SBQQ__RequiredBy__r.SBQQ__Product__r.Product_level__c','SBQQ__Product__r.CPQ_Uplift__c','SBQQ__Product__r.Feature_Name__c',
                'SBQQ__RequiredBy__r.SBQQ__Product__r.After_Conversion_Product_Level__c','SBQQ__Product__r.Product_Type__c',
                'SBQQ__Quote__r.SBQQ__PriceBook__c','SBQQSC__RenewedContractLine__r.SBQQSC__RenewalQuantity__c',
                'SBQQSC__RenewedContractLine__r.SBQQSC__Product__r.Product_Payment_Option__c',
                'SBQQSC__RenewedContractLine__r.SBQQSC__Product__r.Support_Type__c','SBQQSC__RenewedContractLine__r.Payment_Options__c',
                'SBQQSC__RenewedContractLine__r.Support_Type__c','SBQQ__Product__r.Product_Level__c',
                'SBQQ__RequiredBy__r.SBQQ__Product__r.Support_Tier__c','SBQQ__Product__r.After_Conversion_Product_Level__c',
                'SBQQ__RequiredBy__r.SBQQ__Product__r.ProductCode', 'SBQQSC__RenewedContractLine__r.SBQQSC__Quantity__c'
                };
                    relatedList.add('SBQQ__Product__r.ProductCode');
            relatedList.add('SBQQ__Product__r.Description');
            relatedList.add('SBQQSC__RenewedContractLine__r.ServiceContract.Renew_to_Old_SKUs__c');
            relatedList.add('SBQQ__Product__r.License_Type__c');
            relatedList.add('SBQQ__Product__r.License_Category__c');
            relatedList.add('SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Product_Type__c'); //CPQ22-5017
            relatedList.add('SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__c'); //CPQ22-5017
            relatedList.add('SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Description');//CPQ22-5017
            
            qLQuery = qLQuery + ' , '+ + String.join( relatedList, ', ') ;
            qLQuery = qLQuery + ' FROM SBQQ__QuoteLine__c WHERE SBQQ__Product__r.Product_Level__c = null AND SBQQ__Quote__c = \'' + q1.Id + '\'';
            
            
            List<SBQQ__QuoteLine__c> qlList = Database.query(qLQuery);
            //Set<String> prodsTobeConverted1 = new Set<String>();
            string qLQuery1 = 'SELECT ';
            
            qLQuery1 = qLQuery1 + String.join( getAllFieldsForClone(), ',' );
            qLQuery1 = qLQuery1 + ' ,SBQQ__RenewedAsset__r.Name, SBQQ__Product__r.Description, SBQQ__Product__r.License_Type__c , SBQQ__Product__r.License_Category__c, SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Product_Type__c, SBQQ__Product__r.Product_Type__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Product__r.Product_Level__c = null AND SBQQ__Quote__c = \'' + q1.Id + '\'';
            
            
            List<SBQQ__QuoteLine__c> qlList1 = Database.query(qLQuery1);
            Map<Id, SBQQ__QuoteLine__c> qlListDEL = new Map<Id, SBQQ__QuoteLine__c>();
            
            
            
            Map<Id, SBQQ__QuoteLine__c> qlMap= new Map<Id, SBQQ__QuoteLine__c>(qlList);
            Map<Id, SBQQ__QuoteLine__c> qlMap1= new Map<Id, SBQQ__QuoteLine__c>(qlList1);
            Id Pricebookid;
            Set<Id> contractlines = new Set<Id>();
            Map<String,String> RenwedAssetQLMap = new Map<string, string>(); // To Store the map of Renewed Asset vs hardware id. To be used for parenting.
            Map<String,String> RenwedAssetSrNoQLMap = new Map<string, string>(); // To Store the map of Renewed Asset SrNo vs hardware id. To be used for parenting.
            
            for(SBQQ__QuoteLine__c ql: qlList){
                
                if(ql.SBQQSC__RenewedContractLine__r.ServiceContract.Renew_to_Old_SKUs__c == true)
                    integer i=1/0;
                
                Pricebookid = ql.SBQQ__Quote__r.SBQQ__PriceBook__c;
                prodsTobeConverted.add(ql.SBQQ__Product__r.ProductCode);
                if(ql.SBQQSC__RenewedContractLine__c != null)
                    contractlines.add(ql.SBQQSC__RenewedContractLine__c);
                /* Storing Map of subscribed asset id and hardware quote line, to handle scenario where linkage between support and hardware would be missing for example SUP CNV */
                
                if(qlMap1.get(ql.id).SBQQ__RenewedAsset__c != null){
                    RenwedAssetQLMap.put(qlMap1.get(ql.id).SBQQ__RenewedAsset__c,ql.id);
                    RenwedAssetSrNoQLMap.put(qlMap1.get(ql.id).SBQQ__RenewedAsset__r.Name,ql.id);
                }
                
            }
            Map<Id, String> contractLineSupportTierMap = new Map<Id, String>();
            Map<Id, Decimal> contractLineCapacity = new Map<Id, Decimal>();
            Map<Id, Boolean> contractLineAddRCDM = new Map<Id, Boolean>();
            Set<Id> contractLinesWithNoMappingV1 = new Set<Id>(); //Set of contract lines whose ent's asset does not have mapping. storing it for the contract where parent product might be missing.
            Set<Id> contractLinesWithNoMappingV2 = new Set<Id>();
            Map<String, String> contractLineAssetPC = new Map<String, String>();
            //Following Map is used to store contract line and its subscribed asset ids grouped by Combine Key : Used in CNV logic
            Map<Id, Map<String, List<String>>> conLineComKeyAssetMap = new Map<Id, Map<String, List<String>>>();
            Map<String, String> combKeyAssetNames = new Map<String, String>();
            Map<string, String> combKeySupTierMap = new Map<String, String>();
            Set<String> productTypes = new Set<String>{'RADAR','Sonar', 'App Flows'};
            //CPQ22-5017
            Set<Id> cliIdSet = new Set<Id>(); //CLI Id is added when there is asset and cli

            for(Entitlement ent: [SELECT Id, Asset.ProductCode,Asset.product2.Product_level__c, Asset.Name, Asset.Product2.After_Conversion_Product_Level__c, ContractLineItemId, 
              Product__r.Product_Level__c,Product__r.Add_on_Level__c,Product__r.Product_Type__c, Product__r.SBQQSC__EntitlementConversion__c,  ContractLineItem.SBQQSC__RenewalQuantity__c,
                                  AssetId, Asset.Support_Tier__c, Asset.Product_Usable_Capacity__c,ContractLineItem.SBQQSC__RequiredByProduct__c, Asset.SBQQ__CombineKey__c, ContractLineItem.ServiceContract.Add_RCDM__c, ContractLineItem.ServiceContractId, ContractLineItem.SBQQSC__RequiredByProduct__r.Usable_Capacity__c,ContractLineItem.SBQQSC__Quantity__c FROM Entitlement WHERE ContractLineItemId IN: contractlines AND
                                  (Renewal_Category__c = '' OR Renewal_Category__c = null OR Renewal_Category__c = 'Renew later')]){                
                                      // Update for CNV SKU
                                      
                                      if(ent.AssetId != null && ent.ContractLineItemId != null){
                                          Map<String, List<String>> tempMap1 = conLineComKeyAssetMap.containsKey(ent.ContractLineItemId)? 
                                              conLineComKeyAssetMap.get(ent.ContractLineItemId): new Map<String, List<String>>();
                                          
                                          List<String> tempSet1 = tempMap1.containsKey(ent.Asset.Support_Tier__c + '-' + ent.Asset.SBQQ__CombineKey__c + '-' + 
                                                                                       ent.Asset.ProductCode) ? 
                                              tempMap1.get(ent.Asset.Support_Tier__c + '-' + ent.Asset.SBQQ__CombineKey__c + '-' + ent.Asset.ProductCode): new List<String>();
                                          
                                          tempSet1.add(ent.assetid);    
                                          combKeySupTierMap.put(ent.Asset.Support_Tier__c + '-' + ent.Asset.SBQQ__CombineKey__c + '-' + ent.Asset.ProductCode, 
                                                                ent.Asset.Support_Tier__c);
                                          tempMap1.put(ent.Asset.Support_Tier__c + '-' + ent.Asset.SBQQ__CombineKey__c + '-' + ent.Asset.ProductCode, tempSet1);
                                          conLineComKeyAssetMap.put(ent.ContractLineItemId, tempMap1);
                                          String assetnames = combKeyAssetNames.containsKey(ent.Asset.Support_Tier__c + '-' + ent.Asset.SBQQ__CombineKey__c + '-' + 
                                                                                            ent.Asset.ProductCode) && 
                                              !combKeyAssetNames.get(ent.Asset.Support_Tier__c + '-' + ent.Asset.SBQQ__CombineKey__c + '-' + 
                                                                     ent.Asset.ProductCode).contains(ent.asset.name)? 
                                              combKeyAssetNames.get(ent.Asset.Support_Tier__c + '-' + ent.Asset.SBQQ__CombineKey__c + '-' + ent.Asset.ProductCode) + ',' + 
                                              ent.Asset.Name: ent.Asset.Name;
                                          combKeyAssetNames.put(ent.Asset.Support_Tier__c + '-' + ent.Asset.SBQQ__CombineKey__c + '-' + ent.Asset.ProductCode, assetnames);
                                          //CPQ22-5017 start
                                          if(String.isNotBlank(ent.ContractLineItem.SBQQSC__RequiredByProduct__c)) {
                                            cliIdSet.add(ent.ContractLineItemId);
                                          }//CPQ22-5017 end
                                          
                                      }
                                      
                                      if(ent.assetid != null){
                                          contractLineAssetPC.put(ent.ContractLineItemId,ent.Asset.ProductCode);
                                          if(ent.Asset.Product2.After_Conversion_Product_Level__c == null || ent.Asset.Product2.After_Conversion_Product_Level__c == '')
                                              if(ent.Asset.product2.Product_level__c == null || ent.Asset.product2.Product_level__c =='')
                                              contractLinesWithNoMappingV1.add(ent.ContractLineItemId);
                                          else if( ent.Asset.product2.Product_level__c != null){
                                              contractLinesWithNoMappingV2.add(ent.ContractLineItemId);// in case asset is v2 and contract line is in v1 then system will just show contract line as standlone.
                                          }
                                      }
                                      contractLineSupportTierMap.put(ent.ContractLineItemId, ent.Asset.Support_Tier__c);
                                      
                                      if(ent.assetid != null && ent.Asset.Product_Usable_Capacity__c != null){
                                          
                                          
                                          if(contractLineCapacity.get(ent.ContractLineItemId) != null){
                                              contractLineCapacity.put(ent.ContractLineItemId,contractLineCapacity.get(ent.ContractLineItemId)+ent.Asset.Product_Usable_Capacity__c);
                                          }else if(ent.assetid != null ){
                                              contractLineCapacity.put(ent.ContractLineItemId,ent.Asset.Product_Usable_Capacity__c);
                                          }
                                      }
                                      if(ent.assetid == null && ent.ContractLineItem.SBQQSC__RequiredByProduct__r.Usable_Capacity__c != null){
                                          
                                          
                                          if(contractLineCapacity.get(ent.ContractLineItemId) != null){
                                              contractLineCapacity.put(ent.ContractLineItemId,contractLineCapacity.get(ent.ContractLineItemId)+ent.ContractLineItem.SBQQSC__RequiredByProduct__r.Usable_Capacity__c);
                                          }else if(ent.assetid == null ){
                                              contractLineCapacity.put(ent.ContractLineItemId,ent.ContractLineItem.SBQQSC__RequiredByProduct__r.Usable_Capacity__c);
                                          }
                                      }
                                      //CPQ22-3455
                                       if(ent.assetid == null && ent.ContractLineItemId != null && ent.ContractLineItem.SBQQSC__RequiredByProduct__c == null){
                                          if(contractLineCapacity.get(ent.ContractLineItemId) != null){
                                              contractLineCapacity.put(ent.ContractLineItemId,contractLineCapacity.get(ent.ContractLineItemId)+ent.ContractLineItem.SBQQSC__Quantity__c);
                                          }else if(contractLineCapacity.get(ent.ContractLineItemId) == null ){
                                              contractLineCapacity.put(ent.ContractLineItemId,ent.ContractLineItem.SBQQSC__Quantity__c);
                                          }
                                      }
                                      //CPQ22-3455 Khushboo
                                      //CPQ22-4225 - Starts
                                      if(ent.ContractLineItemId != null && ent.Product__r.Add_on_Level__c == 'RCDM Add-On' && productTypes.contains(ent.Product__r.Product_Type__c) 
                                      && ent.Product__r.SBQQSC__EntitlementConversion__c == 'One per quote line' && ent.Product__r.Product_Level__c == null )  {
                                        contractLineCapacity.put(ent.ContractLineItemId, ent.ContractLineItem.SBQQSC__Quantity__c);
                                      }
                                      //CPQ22-4225 - Ends
                                      if(ent.ContractLineItemId != null && ent.ContractLineItem.ServiceContractId != null) {
                                          
                                          if(contractLineAddRCDM.containsKey(ent.ContractLineItemId) && contractLineAddRCDM.get(ent.ContractLineItemId) != null){
                                              contractLineAddRCDM.put(ent.ContractLineItemId,contractLineAddRCDM.get(ent.ContractLineItemId));
                                          } else {
                                              contractLineAddRCDM.put(ent.ContractLineItemId,ent.ContractLineItem.ServiceContract.Add_RCDM__c);
                                          }
                                          
                                      }
                                  }
            Map<String, Id> pbeMAP =  getPriceBookEntries(Pricebookid); //Pricebook Map
            Map<String, ProdMapWrapper> prodWrapMap = getProdMap(prodsTobeConverted,null); //WrapMap
            Map<String, SBQQ__QuoteLine__c> NewQuoteLineInstanceMap = new Map<String, SBQQ__QuoteLine__c>(); // ID will be of OLD records
            Map<Id, Id> existchildParentMap = new Map<Id, Id>();
            Map<String, String> hwSubMap = new Map<String, String>();
            Map<String, String> SuphwMap = new Map<String, String>();
            Map<String, String> ChildSaasMap = new Map<String, String>();
            Map<String, Boolean> gotChildSaasMap = new Map<String, Boolean>();
            Map<String, String> ProdFeatureMap = new Map<String, String>();
            
            Set<String> configSKUCode = new Set<String>();
            Set<String> optionSKUCode = new Set<String>();
            Set<String> standAloneSAAS = new Set<String>();
            Set<String> featureNames = new Set<String>();
            
            
            Map<String, SBQQ__QuoteLine__c> newInstProductOption = new Map<String, SBQQ__QuoteLine__c>();
            Set<String> quantCalculated = new Set<String>();
            Map<String, SBQQ__QuoteLine__c> consolidateKeyNewQuoteLineInstMap = new Map<String, SBQQ__QuoteLine__c>();
            Map<String, String> qlIDConsolidateInsMap = new Map<String, String>();
            List<Consolidated_Contract_Lines__c> consContractLinesInstances = new List<Consolidated_Contract_Lines__c>();
            
            
            List<SBQQ__QuoteLine__c> WithOutMappingQLs = new List<SBQQ__QuoteLine__c>(); //Will get populated based on missing After Conversion Product Level
            List<SBQQ__QuoteLine__c> WithOutMappingQLHardwares = new List<SBQQ__QuoteLine__c>();//Will get populated based on missing After Conversion Product Level hardware lines
            
            
            for(SBQQ__QuoteLine__c ql: qlList){
                if(ql.SBQQ__Product__r.Product_level__c != null){
                    //SBQQ__QuoteLine__c cloneQLNEWLINE = qlMap1.get(ql.id).clone();
                    //NewQuoteLineInstanceMap.put(ql.id,cloneQLNEWLINE);
                    continue;
                }
                
                //qlListDEL.add(ql);
                
                if(ql.SBQQ__Product__r.After_Conversion_Product_Level__c=='Does not Renew'){
                    qlListDEL.put(ql.id, ql);
                    continue;
                }
                
                String consolidateKey = '';
                
                String suptype = ql.SBQQSC__RenewedContractLine__r.Support_Type__c == null? 
                    (ql.SBQQSC__RenewedContractLine__r.SBQQSC__Product__r.Support_Type__c == null ? '' : 
                     ql.SBQQSC__RenewedContractLine__r.SBQQSC__Product__r.Support_Type__c) : ql.SBQQSC__RenewedContractLine__r.Support_Type__c;
                
                String paymentOption = ql.SBQQSC__RenewedContractLine__r.Payment_Options__c == null? 
                    (ql.SBQQSC__RenewedContractLine__r.SBQQSC__Product__r.Product_Payment_Option__c == null ? '' : 
                     ql.SBQQSC__RenewedContractLine__r.SBQQSC__Product__r.Product_Payment_Option__c) : 
                ql.SBQQSC__RenewedContractLine__r.Payment_Options__c;
                
                //Decimal PriorNetTotal = ql.SBQQSC__RenewedContractLine__r.TotalPrice;
                //Decimal uplift = ql.SBQQ__Product__r.CPQ_Uplift__c != null?(Decimal.ValueOf(ql.SBQQ__Product__r.CPQ_Uplift__c)/100):0;
                //Decimal PriorNetTotalWithUplift = ql.SBQQSC__RenewedContractLine__r.TotalPrice+(uplift*ql.SBQQSC__RenewedContractLine__r.TotalPrice);
                
                
                SBQQ__QuoteLine__c cloneQL = qlMap1.get(ql.id).clone();
                existchildParentMap.put(ql.Id, ql.SBQQ__RequiredBy__c);
                
                if(ql.SBQQSC__RenewedContractLine__c == null && 
                   (ql.SBQQ__Product__r.After_Conversion_Product_Level__c == null || ql.SBQQ__Product__r.After_Conversion_Product_Level__c == '' )){
                       if(ql.SBQQ__Product__r.Product_level__c == null){
                           WithOutMappingQLHardwares.add(ql);
                           productCodesNotFound.add(ql.SBQQ__Product__r.ProductCode);
                           continue;
                       }
                   }
                
                if(ql.SBQQSC__RenewedContractLine__c != null)
                {
                    if((contractLinesWithNoMappingV2 != null && contractLinesWithNoMappingV2.contains(ql.SBQQSC__RenewedContractLine__c))){
                        
                        
                        ql.SBQQ__RequiredBy__c = null;
                    }
                    
                    if((contractLinesWithNoMappingV1 != null && contractLinesWithNoMappingV1.contains(ql.SBQQSC__RenewedContractLine__c))){
                        WithOutMappingQLs.add(ql);
                        productCodesNotFound.add(contractLineAssetPC.get(ql.SBQQSC__RenewedContractLine__c));
                        
                    }
                    
                    
                    
                    if(ql.SBQQ__Product__r.After_Conversion_Product_Level__c == null 
                       || ql.SBQQ__Product__r.After_Conversion_Product_Level__c == ''){
                           if(ql.SBQQ__Product__r.Product_level__c == null){
                               WithOutMappingQLs.add(ql);
                               productCodesNotFound.add(ql.SBQQ__Product__r.ProductCode);
                               continue;
                           }
                       }
                    if(ql.SBQQ__RequiredBy__c != null && (ql.SBQQ__RequiredBy__r.SBQQ__Product__r.After_Conversion_Product_Level__c == null 
                                                          || ql.SBQQ__RequiredBy__r.SBQQ__Product__r.After_Conversion_Product_Level__c == '')){
                                                              if(ql.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_level__c == null){
                                                                  WithOutMappingQLs.add(ql);
                                                                  productCodesNotFound.add(ql.SBQQ__RequiredBy__r.SBQQ__Product__r.ProductCode);
                                                                  continue;
                                                                  
                                                              }
                                                          }
                    
                }
                
                ProdMapWrapper wrap = prodWrapMap.get(ql.SBQQ__Product__r.ProductCode);
                if(wrap == null){
                    if(ql.SBQQSC__RenewedContractLine__c != null)
                        WithOutMappingQLs.add(ql);
                    else {
                        WithOutMappingQLHardwares.add(ql);   
                    }
                    productCodesNotFound.add(ql.SBQQ__Product__r.Productcode);
                    continue;
                }
                
                if(wrap.isSplit){
                    List<Multi_Mapping_V2_Conversion__c> multiMapLst = 
                        wrap.splitMapRecordsWithOldSKU.get(ql.SBQQ__Product__r.Productcode + suptype + paymentOption);
                    //if(multiMapLst == null || (multiMapLst != null && !(multiMapLst.size() > 0))){
                    if(multiMapLst == null || (multiMapLst != null && !(!multiMapLst.isEmpty()))){
                        multiMapLst = wrap.splitMapRecordsWithOldSKU.get(ql.SBQQ__Product__r.Productcode + 'Default' + 'Default');
                    }
                    
                    if(multiMapLst != null){
                        if(ql.SBQQ__Product__r.After_Conversion_Product_Level__c == 'Support' && ql.SBQQSC__RenewedContractLine__c != null){
                            for(Multi_Mapping_V2_Conversion__c Itr: multiMapLst){
                                if(ITR.Target_Product__r.Eligible_for_RCDM_T__c){
                                    prodEligibleForRCDMT.add(Itr.Target_Product__c);
                                }
                                if(Itr.Target_Product__r.Productcode == 'Does not Renew'){
                                    Continue;
                                }
                                // Since order by is on option level always top parent will come first n hence forth.
                                SBQQ__QuoteLine__c cloneQLTemp = qlMap1.get(ql.Id).clone();
                                String extId = String.valueOF(ql.Id) + String.valueOf(Itr.Target_Product__c);
                                cloneQLTemp = cloneQuoteLineIns(ql, cloneQLTemp, null, itr, extId, pbeMAP);
                                
                                
                                if(Itr.Target_Product__r.Product_level__c == 'Support' && Itr.Target_Product__r.Product_Type__c != 'RCDM Support' 
                                   && ql.SBQQ__RequiredBy__c !=null 
                                   && ql.SBQQ__RequiredBy__r.SBQQ__Product__r.Support_Tier__c == Itr.Support_Tier__c)
                                {
                                    
                                    SuphwMap.put(extId, ql.SBQQ__RequiredBy__c);
                                    optionSKUCode.add(Itr.Target_Product__c);
                                    ProdFeatureMap.put(Itr.Target_Product__c, Itr.Feature_Name_on_New_Product__c);
                                    NewQuoteLineInstanceMap.put(extId, cloneQLTemp);
                                }
                                
                                if(Itr.Target_Product__r.Product_level__c == 'Support' && Itr.Target_Product__r.Product_Type__c != 'RCDM Support' 
                                   && ql.SBQQ__RequiredBy__c == null 
                                   && contractLineSupportTierMap.get(ql.SBQQSC__RenewedContractLine__c) == Itr.Support_Tier__c)
                                {
                                    
                                    SuphwMap.put(extId, ql.SBQQ__RequiredBy__c);
                                    optionSKUCode.add(Itr.Target_Product__c);
                                    ProdFeatureMap.put(Itr.Target_Product__c, Itr.Feature_Name_on_New_Product__c);
                                    NewQuoteLineInstanceMap.put(extId, cloneQLTemp);
                                }
                                
                                if(Itr.Target_Product__r.Product_level__c == 'Support' && Itr.Target_Product__r.Product_Type__c == 'RCDM Support'){
                                    cloneQLTemp.SubscribedAssetLookup__c = null;
                                    cloneQLTemp.Product_Type__c = Itr.Target_Product__r.Product_Type__c ;
                                    cloneQLTemp.Product_Subtype__c = Itr.Target_Product__r.Product_Subtype__c ;
                                    
                                    if(ql.SBQQSC__RenewedContractLine__c != null 
                                       && contractLineCapacity.get(ql.SBQQSC__RenewedContractLine__c) != null){
                                           quantCalculated.add(cloneQLTemp.required_by_ext_Id__c);
                                           cloneQLTemp.SBQQ__Quantity__c = contractLineCapacity.get(ql.SBQQSC__RenewedContractLine__c);
                                           cloneQLTemp.RWD_Expected_Default_Quantity__c =cloneQLTemp.SBQQ__Quantity__c;
                                           cloneQLTemp.Related_Asset_Total_Capacity__c = cloneQLTemp.SBQQ__Quantity__c;
                                       }
                                    NewQuoteLineInstanceMap.put(extId,cloneQLTemp);
                                }
                            }
                        }
                        else if(ql.SBQQSC__RenewedContractLine__c != null){
                            
                            
                            
                            Map<String, String> accessMap = new Map<String, String>();
                            for(Multi_Mapping_V2_Conversion__c Itr: multiMapLst){
                                
                                if(Itr.Target_Product__r.Productcode == 'Does not Renew'){
                                    continue;
                                }
                                
                                if(ITR.Target_Product__r.Eligible_for_RCDM_T__c){
                                    prodEligibleForRCDMT.add(Itr.Target_Product__c);
                                }
                                
                                // Since order by is on option level always top parent will come first n hence forth.
                                SBQQ__QuoteLine__c cloneQLTemp = qlMap1.get(ql.Id).clone();
                                String extId = String.valueOF(ql.Id) + String.valueOf(Itr.Target_Product__c);
                                cloneQLTemp = cloneQuoteLineIns(ql, cloneQLTemp, null, itr, extId, pbeMAP);
                                if((Itr.Target_Product__r.Product_level__c=='Hybrid Software' || Itr.Target_Product__r.Product_level__c=='LOD Software') )
                                {
                                    accessMap.put('SoftwareParent', extId);
                                    
                                    //consolidateKey = Itr.Target_Product__r.Productcode+'-'+String.ValueOF(ql.SBQQ__SubscriptionTerm__c)+'-'+suptype+'-'+paymentOption;
                                    consolidateKey = Itr.Target_Product__r.Productcode + '-' + 
                                        String.ValueOf(ql.SBQQ__SubscriptionTerm__c) + String.ValueOf(ql.SBQQ__StartDate__c) + 
                                        String.ValueOF(ql.SBQQ__EndDate__c);
                                    consolidateKey = ql.TPH_Drive_Size__c != null ? consolidateKey + '-' + ql.TPH_Drive_Size__c : consolidateKey;
                                    consolidateKey = ql.TPH_Models_Gen__c != null ? consolidateKey + '-' + ql.TPH_Models_Gen__c : consolidateKey;
                                    if(ql.SBQQSC__RenewedContractLine__c != null 
                                       && contractLineCapacity.get(ql.SBQQSC__RenewedContractLine__c) != null){
                                           quantCalculated.add(cloneQLTemp.required_by_ext_Id__c);
                                           cloneQLTemp.SBQQ__Quantity__c = contractLineCapacity.get(ql.SBQQSC__RenewedContractLine__c);
                                           cloneQLTemp.RWD_Expected_Default_Quantity__c = cloneQLTemp.SBQQ__Quantity__c;
                                           cloneQLTemp.Related_Asset_Total_Capacity__c = cloneQLTemp.SBQQ__Quantity__c;
                                       }
                                    
                                    if(consolidateKeyNewQuoteLineInstMap.containsKey(consolidateKey)){
                                        cloneQLTemp = consolidateKeyNewQuoteLineInstMap.get(consolidateKey);
                                        cloneQLTemp.SBQQ__Discount__c = ql.SBQQ__Discount__c > cloneQL.SBQQ__Discount__c ? ql.SBQQ__Discount__c: 
                                        cloneQL.SBQQ__Discount__c;
                                        //cloneQLTemp.Total_Prior_Net_Total__c = cloneQL.Total_Prior_Net_Total__c != null? cloneQL.Total_Prior_Net_Total__c : 0;
                                        //cloneQLTemp.Total_Prior_Net_Total__c = ql.Total_Prior_Net_Total__c != null ?  cloneQL.Total_Prior_Net_Total__c+ql.Total_Prior_Net_Total__c : cloneQL.Total_Prior_Net_Total__c;
                                        
                                        cloneQLTemp.SubscribedAssetNames__c = cloneQLTemp.SubscribedAssetNames__c != null 
                                            && cloneQLTemp.SubscribedAssetNames__c != '' ? cloneQLTemp.SubscribedAssetNames__c + ',' 
                                            + ql.SubscribedAssetNames__c : ql.SubscribedAssetNames__c;
                                        cloneQLTemp.Subscribed_Asset_Name__c = cloneQLTemp.SubscribedAssetNames__c;
                                        
                                        if(ql.SBQQSC__RenewedContractLine__c != null 
                                           && contractLineCapacity.get(ql.SBQQSC__RenewedContractLine__c) != null){
                                               quantCalculated.add(cloneQLTemp.required_by_ext_Id__c);
                                               cloneQLTemp.SBQQ__Quantity__c = cloneQLTemp.SBQQ__Quantity__c != null ? cloneQLTemp.SBQQ__Quantity__c + contractLineCapacity.get(ql.SBQQSC__RenewedContractLine__c) : contractLineCapacity.get(ql.SBQQSC__RenewedContractLine__c);
                                               cloneQLTemp.RWD_Expected_Default_Quantity__c =cloneQLTemp.SBQQ__Quantity__c;
                                               cloneQLTemp.Related_Asset_Total_Capacity__c = cloneQLTemp.SBQQ__Quantity__c;
                                           }
                                        
                                        consolidateKeyNewQuoteLineInstMap.put(consolidateKey, cloneQLTemp);
                                        Consolidated_Contract_Lines__c tempInst = new Consolidated_Contract_Lines__c();
                                        SBQQ__QuoteLine__c tempQLParent = new SBQQ__QuoteLine__c(
                                            required_by_ext_Id__c = cloneQLTemp.required_by_ext_Id__c);
                                        tempInst.putSobject('Quote_Line__r', tempQLParent);
                                        tempInst.Contract_Line_Item__c = ql.SBQQSC__RenewedContractLine__c;
                                            //Ankita
                                             if(ql.TPH_Drive_Size__c != null) {
                                                cloneQL.TPH_Quantity__c = String.valueOf(Integer.valueOf(cloneQL.TPH_Quantity__c) + Integer.valueOf(ql.TPH_Quantity__c));
                                            }  
                                        consContractLinesInstances.add(tempInst);
                                    }else{
                                        consolidateKeyNewQuoteLineInstMap.put(consolidateKey,cloneQLTemp);
                                    }
                                    
                                    
                                    
                                    configSKUCode.add(Itr.Target_Product__c);
                                    qlIDConsolidateInsMap.put(extId, cloneQLTemp.required_by_ext_Id__c);
                                }
                                
                                else if(Itr.Target_Product__r.Product_Type__c == 'HW Support'){
                                    accessMap.put('extId SupportLine: ', extId);
                                    SuphwMap.put(extId, accessMap.get('HardwareParent'));
                                    optionSKUCode.add(Itr.Target_Product__c);
                                }
                                else if(Itr.Target_Product__r.Product_level__c == 'Hardware'){
                                    accessMap.put('HardwareParent' , extId);
                                    hwSubMap.put(extId, accessMap.get('SoftwareParent'));
                                    cloneQLTemp.SBQQ__Existing__c = true;
                                    cloneQLTemp.SBQQSC__RenewedContractLine__c = null;
                                    cloneQLTemp.SBQQ__PriorQuantity__c = ql.SBQQ__Quantity__c;
                                    optionSKUCode.add(Itr.Target_Product__c);
                                    configSKUCode.add(Itr.Target_Product__c);
                                    ProdFeatureMap.put(Itr.Target_Product__c, Itr.Feature_Name_on_New_Product__c);
                                }
                                else if(Itr.Target_Product__r.Product_level__c == 'SaaS Software Addon' 
                                        || Itr.Target_Product__r.Product_level__c == 'Standalone Software Addon')
                                {
                                    if(ql.SBQQSC__RenewedContractLine__c != null 
                                       && contractLineCapacity.get(ql.SBQQSC__RenewedContractLine__c) != null)
                                    {
                                        quantCalculated.add(cloneQLTemp.required_by_ext_Id__c);
                                        cloneQLTemp.SBQQ__Quantity__c = contractLineCapacity.get(ql.SBQQSC__RenewedContractLine__c);
                                    }
                                    accessMap.put('extId ADDON: ', extId);
                                    ChildSaasMap.put(extId, 'SoftwareParent');
                                    gotChildSaasMap.put(extId, true);
                                    optionSKUCode.add(Itr.Target_Product__c);
                                    ProdFeatureMap.put(Itr.Target_Product__c, Itr.Feature_Name_on_New_Product__c);
                                }
                                else if(Itr.Target_Product__r.Product_level__c == 'Support' || Itr.Target_Product__r.Product_Type__c == 'RCDM Support'){
                                    cloneQLTemp.SubscribedAssetLookup__c = null;
                                    cloneQLTemp.Product_Type__c = Itr.Target_Product__r.Product_Type__c ;
                                    cloneQLTemp.Product_Subtype__c = Itr.Target_Product__r.Product_Subtype__c ;
                                    if(ql.SBQQSC__RenewedContractLine__c != null 
                                       && contractLineCapacity.get(ql.SBQQSC__RenewedContractLine__c) != null){
                                           quantCalculated.add(cloneQLTemp.required_by_ext_Id__c);
                                           cloneQLTemp.SBQQ__Quantity__c = contractLineCapacity.get(ql.SBQQSC__RenewedContractLine__c);
                                           cloneQLTemp.RWD_Expected_Default_Quantity__c = cloneQLTemp.SBQQ__Quantity__c;
                                           cloneQLTemp.Related_Asset_Total_Capacity__c = cloneQLTemp.SBQQ__Quantity__c;
                                       }
                                }
                                NewQuoteLineInstanceMap.put(extId,cloneQLTemp);
                            }
                        }
                    }else if(ql.SBQQSC__RenewedContractLine__c != null){
                        WithOutMappingQLs.add(ql);
                        productCodesNotFound.add(ql.SBQQ__Product__r.Productcode + 'PAYMENT OPTION & SUPPORT TYPE NOT FOUND ');
                        continue;
                    }
                    qlListDEL.put(ql.Id, ql);
                    continue;
                }
                
                Polaris_SKU_Mapping_V2__c targetKSU;
                
                if(ql.SBQQ__Product__r.After_Conversion_Product_Level__c == 'Support' && ql.SBQQ__Product__r.Product_Type__c != 'RCDM Support' 
                   && ql.SBQQ__Product__r.productcode.contains('CNV')){
                       Map<String, List<String>> tempMap1 = new Map<String, List<String>>();
                       if(conLineComKeyAssetMap.get(ql.SBQQSC__RenewedContractLine__c) != null)
                           tempMap1 = conLineComKeyAssetMap.get(ql.SBQQSC__RenewedContractLine__c);
                       
                       
                       Decimal perunitPNT = 0;
                       Decimal perunitPNTWU = 0;
                       
                       if(qlMap1.get(ql.Id) != null && qlMap1.get(ql.Id).Prior_Net_Total__c != null && ql.SBQQ__Quantity__c != null 
                          && qlMap1.get(ql.Id).Prior_Net_Total_With_Uplift__c !=null ){
                              perunitPNT = qlMap1.get(ql.Id).Prior_Net_Total__c / ql.SBQQ__Quantity__c;
                              perunitPNTWU = qlMap1.get(ql.Id).Prior_Net_Total_With_Uplift__c / ql.SBQQ__Quantity__c;
                          }
                       
                       for(String keyVar : tempMap1.keySet()){
                           String AssetId = '';
                           SBQQ__QuoteLine__c cloneQLTemp = qlMap1.get(ql.Id).clone();
                           for(String assetIdvar : tempMap1.get(keyVar) ){
                               if(RenwedAssetQLMap.containsKey(assetIdvar)){
                                   AssetId =assetIdvar;
                                   break;
                               }
                           }
                           
                           
                           targetKSU = wrap.supTierPRODMap.get(combKeySupTierMap.get(keyVar) + '-' + ql.SBQQ__Product__r.ProductCode) ;
                           if(targetKSU == null){
                               WithOutMappingQLs.add(ql);
                               
                               productCodesNotFound.add('CNV SKU Failure ' + ql.SBQQ__Product__r.ProductCode + '-->' + 
                                                        String.join(tempMap1.get(keyVar), ','));
                               continue;
                           }
                           
                           if(RenwedAssetQLMap.get(AssetId) != null){
                               SuphwMap.put(ql.Id + '' + keyVar, RenwedAssetQLMap.get(AssetId));
                               ProdFeatureMap.put(targetKSU.New_Product__c, targetKSU.Feature_Name_on_New_Product__c);
                               String parentTargetSKU = targetKSU != null ? targetKSU.New_Product__c: null;
                               configSKUCode.add(parentTargetSKU);
                           }
                           quantCalculated.add(ql.Id + '' + keyVar); // This ensures quantity is not recalculated in the end on the basis of capacity
                           cloneQLTemp = cloneQuoteLineIns(ql, cloneQLTemp, targetKSU, null, ql.Id + '' + keyVar, pbeMAP);
                           
                           cloneQLTemp.Prior_Net_Total__c = perunitPNT * tempMap1.get(keyVar).size();
                           cloneQLTemp.Prior_Net_Total_With_Uplift__c = perunitPNTWU * tempMap1.get(keyVar).size();
                           cloneQLTemp.SBQQ__Quantity__c = tempMap1.get(keyVar).size();
                           cloneQLTemp.RWD_Expected_Default_Quantity__c = cloneQLTemp.SBQQ__Quantity__c;
                           cloneQLTemp.Related_Asset_Total_Capacity__c = cloneQLTemp.SBQQ__Quantity__c;
                           //cloneQLTemp.SBQQ__SubscribedAssetIds__c = String.join(tempMap1.get(keyVar),',');
                           cloneQLTemp.SubscribedAssetNames__c = combKeyAssetNames.get(keyVar);
                           cloneQLTemp.Subscribed_Asset_Name__c = combKeyAssetNames.get(keyVar);
                           cloneQLTemp.Product_Type__c = targetKSU.New_Product__r.Product_Type__c;
                           cloneQLTemp.Product_Subtype__c = targetKSU.New_Product__r.Product_Subtype__c;
                           qlListDEL.put(ql.id, ql);
                           NewQuoteLineInstanceMap.put(ql.id+''+keyVar,cloneQLTemp);
                       }
                       //conLineComKeyAssetMap.remove(ql.SBQQSC__RenewedContractLine__c);
                       continue;
                   } 
                
                if(ql.SBQQ__Product__r.After_Conversion_Product_Level__c == 'Support' && ql.SBQQ__Product__r.Product_Type__c != 'RCDM Support'){
                    
                    targetKSU = ql.SBQQ__RequiredBy__c != null? 
                        wrap.supTierPRODMap.get(ql.SBQQ__RequiredBy__r.SBQQ__Product__r.Support_Tier__c + '-' + ql.SBQQ__Product__r.ProductCode) : 
                    wrap.supTierPRODMap.get(contractLineSupportTierMap.get(ql.SBQQSC__RenewedContractLine__c) + '-' + ql.SBQQ__Product__r.ProductCode);
                    
                    if(targetKSU != null){
                        
                        SuphwMap.put(ql.Id, ql.SBQQ__RequiredBy__c);
                    }
                    else if(ql.SBQQ__Product__r.ProductCode.contains('NRD')){ //CPQ22-5388 - Tag NRD Line correctly to required by Id
                        SuphwMap.put(ql.Id, ql.SBQQ__RequiredBy__c);
                    }
                    
                    
                    String childTargetSKU = targetKSU != null ? targetKSU.New_Product__c: null;
                    optionSKUCode.add(childTargetSKU);
                }
                else if(ql.SBQQ__Product__r.After_Conversion_Product_Level__c != 'Support'){
                    
                    if(ql.SBQQSC__RenewedContractLine__c != null){
                       
                        targetKSU = wrap.supTypePaymentOptionPRODMap.get(suptype + '-' + paymentOption + '-' + ql.SBQQ__Product__r.ProductCode);
                    }
                    
                    if(ql.SBQQ__Product__r.After_Conversion_Product_Level__c != 'Hybrid Software'  
                    && ql.SBQQ__Product__r.After_Conversion_Product_Level__c != 'LOD Software'){
                        
                        
                        if(ql.SBQQ__RequiredBy__c == null ){
                            standAloneSAAS.add(ql.Id);
                            
                        } 
                        {
                            Id tempReq = hwSubMap.containsKey(ql.SBQQ__RequiredBy__c) ? hwSubMap.get(ql.SBQQ__RequiredBy__c) : ql.SBQQ__RequiredBy__c;
                            ChildSaasMap.put(ql.Id, tempReq);
                            gotChildSaasMap.put(ql.Id, hwSubMap.containsKey(ql.SBQQ__RequiredBy__c));
                            String childTargetSKU = targetKSU != null ? targetKSU.New_Product__c: null;
                            optionSKUCode.add(childTargetSKU);
                        }
                    }
                }else if(ql.SBQQ__Product__r.After_Conversion_Product_Level__c == 'Support' && ql.SBQQ__Product__r.Product_Type__c == 'RCDM Support'){
                    cloneQL.SubscribedAssetLookup__c = null;
                    targetKSU = wrap.singleMapRecord.get(ql.SBQQ__Product__r.ProductCode);
                }
                if(targetKSU == null){
                    targetKSU = wrap.singleMapRecord.get(ql.SBQQ__Product__r.ProductCode);
                }
                if(targetKSU == null){
                    WithOutMappingQLs.add(ql);
                    
                    productCodesNotFound.add(ql.SBQQ__Product__r.ProductCode + 'PAYMENT OPTION or SUPPORT Type NOT Found');
                    continue;
                }
                if(targetKSU.New_Product__r.Productcode == 'Does not Renew'){
                    continue;
                }
                cloneQL.SBQQ__Product__c = targetKSU != null ? targetKSU.New_Product__c:null;
                String quantMapType = targetKSU.Quantity_Mapping_Type__c;
                Decimal quantRatio = targetKSU.Quantity_Ratio__c;
                if(targetKSU.New_Product__r.Eligible_for_RCDM_T__c){
                    prodEligibleForRCDMT.add(targetKSU.New_Product__c);
                }
                
                ProdFeatureMap.put(targetKSU.New_Product__c,targetKSU.Feature_Name_on_New_Product__c);
                //(!addedToOptionalSku){
                String parentTargetSKU = targetKSU != null ? targetKSU.New_Product__c:null;
                configSKUCode.add(parentTargetSKU);
                //addedToOptionalSku =false;
                //}
                cloneQL = cloneQuoteLineIns(ql,cloneQL,targetKSU,null,ql.id,pbeMAP);
                
                if(quantMapType == 'Ratio Based'){
                    cloneQL.SBQQ__Quantity__c = QL.SBQQ__Quantity__c*quantRatio;
                    cloneQL.RWD_Expected_Default_Quantity__c =cloneQL.SBQQ__Quantity__c;
                    cloneQL.Related_Asset_Total_Capacity__c = cloneQL.SBQQ__Quantity__c;
                    quantCalculated.add(cloneQL.required_by_ext_Id__c);
                    //cloneQL.SBQQ__EffectiveQuantity__c = cloneQL.SBQQ__Quantity__c ;
                }
                
                if(quantMapType == 'Appliance Based'){
                    if(ql.SBQQSC__RenewedContractLine__c != null && contractLineCapacity.get(ql.SBQQSC__RenewedContractLine__c) != null){
                        quantCalculated.add(cloneQL.required_by_ext_Id__c);
                        cloneQL.SBQQ__Quantity__c = contractLineCapacity.get(ql.SBQQSC__RenewedContractLine__c);
                        cloneQL.RWD_Expected_Default_Quantity__c = cloneQL.SBQQ__Quantity__c;
                        cloneQL.Related_Asset_Total_Capacity__c = cloneQL.SBQQ__Quantity__c;                    }
                }
                //CPQ22-5017 start - making RADAR without Asset "Ratio Based"
                if(String.isNotBlank(ql.SBQQSC__RenewedContractLine__c) && !cliIdSet.contains(ql.SBQQSC__RenewedContractLine__c) && ql.SBQQ__Product__r.Product_Type__c == 'RADAR' && String.isNotBlank(ql.SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__c)
                && (ql.SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Product_Type__c == '3rd Party Hardware' || ql.SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Description.contains('without chassis'))) {
                    cloneQL.SBQQ__Quantity__c = QL.SBQQ__Quantity__c*1;
                    cloneQL.RWD_Expected_Default_Quantity__c =cloneQL.SBQQ__Quantity__c;
                    cloneQL.Related_Asset_Total_Capacity__c = cloneQL.SBQQ__Quantity__c;
                    quantCalculated.add(cloneQL.required_by_ext_Id__c);
                }                
                //CPQ22-5017 end
                if((ql.SBQQ__Product__r.After_Conversion_Product_Level__c == 'Hybrid Software' 
                    || ql.SBQQ__Product__r.After_Conversion_Product_Level__c == 'LOD Software')){
                        cloneQL.SubscribedAssetLookup__c = null;
                        
                        if(ql.SBQQSC__RenewedContractLine__c != null && contractLineCapacity.get(ql.SBQQSC__RenewedContractLine__c) != null){
                            quantCalculated.add(cloneQL.required_by_ext_Id__c);
                            cloneQL.SBQQ__Quantity__c = contractLineCapacity.get(ql.SBQQSC__RenewedContractLine__c);
                            cloneQL.RWD_Expected_Default_Quantity__c =cloneQL.SBQQ__Quantity__c;
                            cloneQL.Related_Asset_Total_Capacity__c = cloneQL.SBQQ__Quantity__c;
                        }
                        
                        Boolean isFound = false;
                        if(ql.Subscribed_Asset_Name__c != null){
                            String tempsubassetsrno = ql.Subscribed_Asset_Name__c.deleteWhitespace();
                            List<String> lstsubAssetsrnos = tempsubassetsrno.split(',');
                            
                            for(String s: lstsubAssetsrnos){
                                if(RenwedAssetSrNoQLMap.containskey(s)){
                                    hwSubMap.put(RenwedAssetSrNoQLMap.get(s),ql.id);
                                    isFound = true;
                                }
                            }
                        }
                        
                        if(!isFound)
                            hwSubMap.put(ql.id,ql.id);
                        /*if(ql.SBQQ__RequiredBy__c != null )
                            hwSubMap.put(ql.SBQQ__RequiredBy__c,ql.id);
                            else
                            hwSubMap.put(ql.id,ql.id);
                            */      
                        //if(ql.SBQQ__RequiredBy__c != null){
                        String TargetSKUCode = targetKSU != null ? targetKSU.New_Product__r.Productcode:null;
                        //consolidateKey = TargetSKUCode+'-'+String.ValueOF(ql.SBQQ__SubscriptionTerm__c)+'-'+suptype+'-'+paymentOption;
                        consolidateKey = TargetSKUCode + '-' + String.ValueOf(ql.SBQQ__SubscriptionTerm__c) + String.ValueOf(ql.SBQQ__StartDate__c) + 
                            String.ValueOf(ql.SBQQ__EndDate__c);
                        consolidateKey = ql.TPH_Drive_Size__c != null ? consolidateKey + '-' + ql.TPH_Drive_Size__c : consolidateKey;
                        consolidateKey = ql.TPH_Models_Gen__c != null ? consolidateKey + '-' + ql.TPH_Models_Gen__c : consolidateKey;
                        if(consolidateKeyNewQuoteLineInstMap.containsKey(consolidateKey)){
                            cloneQL = consolidateKeyNewQuoteLineInstMap.get(consolidateKey);
                            cloneQL.SBQQ__Discount__c = ql.SBQQ__Discount__c > cloneQL.SBQQ__Discount__c? ql.SBQQ__Discount__c:cloneQL.SBQQ__Discount__c;
                            //cloneQL.Total_Prior_Net_Total__c = cloneQL.Total_Prior_Net_Total__c != null? cloneQL.Total_Prior_Net_Total__c :0;
                            //cloneQL.Total_Prior_Net_Total__c = ql.Total_Prior_Net_Total__c != null ?  cloneQL.Total_Prior_Net_Total__c+ql.Total_Prior_Net_Total__c : cloneQL.Total_Prior_Net_Total__c ;
                            Consolidated_Contract_Lines__c tempInst = new Consolidated_Contract_Lines__c();
                            SBQQ__QuoteLine__c tempQLParent = new SBQQ__QuoteLine__c(required_by_ext_Id__c=cloneQL.required_by_ext_Id__c);
                            tempInst.putSobject('Quote_Line__r', tempQLParent);
                            tempInst.Contract_Line_Item__c = ql.SBQQSC__RenewedContractLine__c;
                            consContractLinesInstances.add(tempInst);
                            
                            cloneQL.SubscribedAssetNames__c = cloneQL.SubscribedAssetNames__c != null && cloneQL.SubscribedAssetNames__c != ''? cloneQL.SubscribedAssetNames__c +','+ ql.SubscribedAssetNames__c : ql.SubscribedAssetNames__c ;
                            cloneQL.Subscribed_Asset_Name__c = cloneQL.SubscribedAssetNames__c;
                            
                            
                            if(ql.SBQQSC__RenewedContractLine__c != null && contractLineCapacity.get(ql.SBQQSC__RenewedContractLine__c) != null){
                                quantCalculated.add(cloneQL.required_by_ext_Id__c);
                                cloneQL.SBQQ__Quantity__c = cloneQL.SBQQ__Quantity__c != null ? cloneQL.SBQQ__Quantity__c + contractLineCapacity.get(ql.SBQQSC__RenewedContractLine__c) : contractLineCapacity.get(ql.SBQQSC__RenewedContractLine__c);
                                cloneQL.RWD_Expected_Default_Quantity__c =cloneQL.SBQQ__Quantity__c;
                                cloneQL.Related_Asset_Total_Capacity__c = cloneQL.SBQQ__Quantity__c;
                            }
                            
                                //Ankita
                                if(ql.TPH_Drive_Size__c != null) {
                                    cloneQL.TPH_Quantity__c = String.valueOf(Integer.valueOf(cloneQL.TPH_Quantity__c) + Integer.valueOf(ql.TPH_Quantity__c));
                                } 
                            consolidateKeyNewQuoteLineInstMap.put(consolidateKey,cloneQL);
                        }else{
                            consolidateKeyNewQuoteLineInstMap.put(consolidateKey,cloneQL);
                        }
                        //}
                        
                        
                        
                        qlIDConsolidateInsMap.put(ql.id,cloneQL.required_by_ext_Id__c);
                    }
                qlListDEL.put(ql.Id, ql);
                NewQuoteLineInstanceMap.put(ql.id,cloneQL);
            }
            
            //if(WithOutMappingQLs.isEmpty()){
            
            
            List<SBQQ__QuoteLine__c> optionLevel0Lines = new List<SBQQ__QuoteLine__c>();
            List<SBQQ__QuoteLine__c> optionLevel1Lines = new List<SBQQ__QuoteLine__c>();
            List<SBQQ__QuoteLine__c> optionLevel2Lines = new List<SBQQ__QuoteLine__c>();
            
            Map<String, String> DynamicOptionMap = new Map<String, String>();
            DynamicOptionMap = getProdFeature(configSKUCode,ProdFeatureMap.values());
            Map<String, String> keyProdOptionMap = new Map<String, String>();
            optionSKUCode.add(System.Label.RCDM_ProductId);
            keyProdOptionMap = returnAllProductOptions(configSKUCode,optionSKUCode);
            
            // Iterate to reparent the lines
            Set<String> instancesAlreadyAdded = new Set<String>();
            
            Map<String, String> childParentMap = new Map<String, String>();
            Map<String, SBQQ__QuoteLine__c> parentChildSaasMap = new Map<String, SBQQ__QuoteLine__c>();
            
            // Logic for Parenting !!
            for(String qlID: NewQuoteLineInstanceMap.keySet()){
                
                if(qlIDConsolidateInsMap.containsKey(qlID) && instancesAlreadyAdded.contains(qlIDConsolidateInsMap.get(qlID))){
                    continue;
                }else{
                    if(qlIDConsolidateInsMap.containsKey(qlID)){
                        instancesAlreadyAdded.add(qlIDConsolidateInsMap.get(qlID));
                    }
                }
                
                SBQQ__QuoteLine__c qli = NewQuoteLineInstanceMap.get(qlID);
                qli.SBQQ__NonDiscountable__c = false;
                
                
                if(hwSubMap.containsKey(qlID)){
                    
                    if(qlID != hwSubMap.get(qlID) && qlIDConsolidateInsMap.ContainsKey(hwSubMap.get(qlID))){
                        SBQQ__QuoteLine__c tempQLI = new SBQQ__QuoteLine__c(required_by_ext_Id__c = qlIDConsolidateInsMap.get(hwSubMap.get(qlID)));
                        //qli.SBQQ__RequiredBy__c = NewQuoteLineInstanceMap.get(hwSubMap.containsKey(qlID));
                        qli.putSobject('SBQQ__RequiredBy__r', tempQLI);
                        qli.SBQQ__OptionType__c = 'Related Product';
                        qli.SBQQ__OptionLevel__c = 1;
                        optionLevel1Lines.add(qli);
                        childParentMap.put(qlid, qlIDConsolidateInsMap.get(hwSubMap.get(qlID)));
                        qli.SBQQ__ProductOption__c = keyProdOptionMap.get
                            (NewQuoteLineInstanceMap.get(childParentMap.get(qlID)).SBQQ__Product__c + '-' + qli.SBQQ__Product__c);
                        qli.SBQQ__DynamicOptionId__c = DynamicOptionMap.get
                            (NewQuoteLineInstanceMap.get(childParentMap.get(qlID)).SBQQ__Product__c+ '-' 
                             + ProdFeatureMap.get(qli.SBQQ__Product__c));  
                        if(qli.SBQQ__ProductOption__c == null)
                            qli.SBQQ__DynamicOptionId__c = DynamicOptionMap.get
                            (NewQuoteLineInstanceMap.get(childParentMap.get(qlID)).SBQQ__Product__c+ '-' 
                             + ProdFeatureMap.get(qli.SBQQ__Product__c)) + ':' + qli.SBQQ__Product__c;
                    }else{
                        qli.SBQQ__OptionLevel__c = 0;
                        optionLevel0Lines.add(qli);
                    }
                }
                else if(SuphwMap.containsKey(qlID)){
                    
                    //String tempPRODOptionKey = newInstProductOption.get(qli.id);
                    
                    qli.SBQQ__OptionLevel__c = 0;
                    
                    if(SuphwMap.get(qlID) != null && NewQuoteLineInstanceMap.get(SuphwMap.get(qlID)) != null){
                        SBQQ__QuoteLine__c tempQLI = new SBQQ__QuoteLine__c(required_by_ext_Id__c = SuphwMap.get(qlID));
                        qli.putSobject('SBQQ__RequiredBy__r', tempQLI);
                        qli.SBQQ__OptionLevel__c = 2;
                        qli.SBQQ__OptionType__c = 'Related Product';
                        qli.SBQQ__DynamicOptionId__c = DynamicOptionMap.get(NewQuoteLineInstanceMap.get(SuphwMap.get(qlID)).SBQQ__Product__c
                                                                            + '-' + ProdFeatureMap.get(qli.SBQQ__Product__c));
                        qli.SBQQ__ProductOption__c = keyProdOptionMap.get(NewQuoteLineInstanceMap.get
                                                                          (SuphwMap.get(qlID)).SBQQ__Product__c + '-' + qli.SBQQ__Product__c);
                        
                    }
                    
                    optionLevel2Lines.add(qli);
                    if(SuphwMap.get(qlID) != null){
                        childParentMap.put(qlid, SuphwMap.get(qlID));  
                    }
                    
                }
                else if(ChildSaasMap.containsKey(qlID) && !standAloneSAAS.contains(qlID)){
                    SBQQ__QuoteLine__c tempQLI;
                    SBQQ__QuoteLine__c tempParentqli ;
                    String parentID;
                    if(gotChildSaasMap.get(qlID)){
                        parentID = qlIDConsolidateInsMap.get(ChildSaasMap.get(qlID));
                        //tempQLI = new SBQQ__QuoteLine__c(required_by_ext_Id__c= parentID);
                        //qli.putSobject('SBQQ__RequiredBy__r',tempQLI);
                        //tempParentqli = NewQuoteLineInstanceMap.get(ChildSaasMap.get(qlID)); Check lateron
                        tempParentqli = NewQuoteLineInstanceMap.get(parentID);
                        
                    }else{
                        parentID = qlIDConsolidateInsMap.get(hwSubMap.get(ChildSaasMap.get(qlID)));
                        //tempQLI = new SBQQ__QuoteLine__c(required_by_ext_Id__c= parentID);
                        //qli.putSobject('SBQQ__RequiredBy__r',tempQLI);
                        tempParentqli = NewQuoteLineInstanceMap.get(hwSubMap.get(ChildSaasMap.get(qlID)));
                    }
                    
                    if(parentID != null && parentID != ''){
                        tempQLI = new SBQQ__QuoteLine__c(required_by_ext_Id__c = parentID);
                        qli.putSobject('SBQQ__RequiredBy__r', tempQLI);
                        qli.SBQQ__OptionLevel__c = 1;
                        qli.SBQQ__OptionType__c = 'Related Product';
                        qli.SBQQ__ProductOption__c = keyProdOptionMap.get(tempParentqli.SBQQ__Product__c + '-' + qli.SBQQ__Product__c);
                        qli.SBQQ__DynamicOptionId__c = DynamicOptionMap.get(tempParentqli.SBQQ__Product__c + '-' + 
                                                                            ProdFeatureMap.get(qli.SBQQ__Product__c)); 
                        if(qli.SBQQ__Product__c != System.Label.RCDM_ProductId){
                            qli.SubscribedAssetNames__c = '';
                            qli.Subscribed_Asset_Name__c = '';
                        }
                        
                        //optionLevel1Lines.add(qli);
                        if(parentChildSaasMap.containsKey(parentID + '-' + qli.SBQQ__Product__c)){
                            SBQQ__QuoteLine__c oldQLI = parentChildSaasMap.get(parentID + '-' + qli.SBQQ__Product__c);
                                qli.Subscribed_Asset_Name__c = qli.Subscribed_Asset_Name__c!= null? qli.Subscribed_Asset_Name__c : '';
                                oldQLI.Subscribed_Asset_Name__c = oldQLI.Subscribed_Asset_Name__c != null 
                                    && oldQLI.Subscribed_Asset_Name__c != '' ? oldQLI.Subscribed_Asset_Name__c + ',' +
                                    qli.Subscribed_Asset_Name__c : qli.Subscribed_Asset_Name__c ;
                            
                            qli.SubscribedAssetNames__c = qli.SubscribedAssetNames__c!= null? qli.SubscribedAssetNames__c : '';
                            oldQLI.SubscribedAssetNames__c = oldQLI.SubscribedAssetNames__c != null && oldQLI.SubscribedAssetNames__c != ''? 
                                oldQLI.SubscribedAssetNames__c + ',' + qli.SubscribedAssetNames__c : qli.SubscribedAssetNames__c ;
                            
                            oldQLI.SBQQ__Discount__c = oldQLI.SBQQ__Discount__c != null? oldQLI.SBQQ__Discount__c : 0;
                            QLI.SBQQ__Discount__c = QLI.SBQQ__Discount__c != null? QLI.SBQQ__Discount__c:0;
                            oldQLI.SBQQ__Discount__c = oldQLI.SBQQ__Discount__c > qli.SBQQ__Discount__c ? oldQLI.SBQQ__Discount__c : 
                            qli.SBQQ__Discount__c;
                            if(QLI.SBQQSC__RenewedContractLine__c != null && contractLineCapacity.get(QLI.SBQQSC__RenewedContractLine__c) != null &&  !quantCalculated.contains(qli.required_by_ext_Id__c)){
                                oldQLI.SBQQ__Quantity__c = oldQLI.SBQQ__Quantity__c != null ? oldQLI.SBQQ__Quantity__c + 
                                    contractLineCapacity.get(QLI.SBQQSC__RenewedContractLine__c) : 
                                contractLineCapacity.get(QLI.SBQQSC__RenewedContractLine__c);
                                
                            }else{ 
                                oldQLI.SBQQ__Quantity__c = oldQLI.SBQQ__Quantity__c+ qli.SBQQ__Quantity__c;
                                
                            }
                            
                            oldQLI.RWD_Expected_Default_Quantity__c = oldQLI.SBQQ__Quantity__c;
                            oldQLI.Related_Asset_Total_Capacity__c = oldQLI.SBQQ__Quantity__c;
                            
                            if(qli.SBQQ__Product__c != System.Label.RCDM_ProductId) {
                                    oldQLI.SBQQ__SubscribedAssetIds__c = '';
                                oldQLI.SubscribedAssetNames__c = '';
                                oldQLI.Subscribed_Asset_Name__c = '';
                            }
                            
                            oldQLI.Total_Prior_Net_Total__c = oldQLI.Total_Prior_Net_Total__c != null ? oldQLI.Total_Prior_Net_Total__c :0;
                            oldQLI.Total_Prior_Net_Total__c = qli.Total_Prior_Net_Total__c !=null? oldQLI.Total_Prior_Net_Total__c + 
                                qli.Total_Prior_Net_Total__c: oldQLI.Total_Prior_Net_Total__c;
                            Consolidated_Contract_Lines__c tempInst = new Consolidated_Contract_Lines__c();
                            SBQQ__QuoteLine__c tempQLParent = new SBQQ__QuoteLine__c(required_by_ext_Id__c = oldQLI.required_by_ext_Id__c);
                            tempInst.putSobject('Quote_Line__r', tempQLParent);
                            tempInst.Contract_Line_Item__c = qli.SBQQSC__RenewedContractLine__c;
                            consContractLinesInstances.add(tempInst);
                            parentChildSaasMap.put(parentID + '-' + qli.SBQQ__Product__c,oldQLI);
                        }
                        else{
                            if(QLI.SBQQSC__RenewedContractLine__c != null && contractLineCapacity.get(QLI.SBQQSC__RenewedContractLine__c) != null && !quantCalculated.contains(qli.required_by_ext_Id__c)){
                                QLI.SBQQ__Quantity__c = contractLineCapacity.get(QLI.SBQQSC__RenewedContractLine__c);
                                QLI.RWD_Expected_Default_Quantity__c = QLI.SBQQ__Quantity__c;
                                QLI.Related_Asset_Total_Capacity__c = QLI.SBQQ__Quantity__c;
                            }
                            
                            if(qli.SBQQ__Product__c != System.Label.RCDM_ProductId) {
                                QLI.SubscribedAssetNames__c = '';
                                QLI.Subscribed_Asset_Name__c = '';
                            }
                            
                            
                            parentChildSaasMap.put(parentID + '-' + qli.SBQQ__Product__c, qli);
                            
                            childParentMap.put(qlid,parentID);
                        }
                            }
                        else{
                        qli.SBQQ__OptionLevel__c = 0;
                        qli.SBQQ__OptionType__c = '';
                        qli.SubscribedAssetLookup__c = null;
                        if(QLI.SBQQSC__RenewedContractLine__c != null && contractLineCapacity.get(QLI.SBQQSC__RenewedContractLine__c) != null && !quantCalculated.contains(qli.required_by_ext_Id__c)){
                            QLI.SBQQ__Quantity__c = contractLineCapacity.get(QLI.SBQQSC__RenewedContractLine__c);
                            QLI.RWD_Expected_Default_Quantity__c = QLI.SBQQ__Quantity__c;
                            QLI.Related_Asset_Total_Capacity__c = QLI.SBQQ__Quantity__c;
                        }
                        optionLevel0Lines.add(qli);
                    }
                }
                else if(standAloneSAAS.contains(qlID)){
                    
                    qli.SBQQ__OptionLevel__c = 0;
                    qli.SBQQ__OptionType__c = '';
                    qli.SubscribedAssetLookup__c = null;
                    if(QLI.SBQQSC__RenewedContractLine__c != null && contractLineCapacity.get(QLI.SBQQSC__RenewedContractLine__c) != null &&  !quantCalculated.contains(qli.required_by_ext_Id__c)){
                        QLI.SBQQ__Quantity__c = contractLineCapacity.get(QLI.SBQQSC__RenewedContractLine__c);
                        QLI.RWD_Expected_Default_Quantity__c = QLI.SBQQ__Quantity__c;
                        QLI.Related_Asset_Total_Capacity__c = QLI.SBQQ__Quantity__c;
                    }
                    optionLevel0Lines.add(qli);
                }
                else{
                    qli.SBQQ__OptionLevel__c = null;
                    qli.SubscribedAssetLookup__c = null;
                    qli.SBQQ__OptionType__c = '';
                    if(QLI.SBQQSC__RenewedContractLine__c != null && contractLineCapacity.get(QLI.SBQQSC__RenewedContractLine__c) != null && 
                       !quantCalculated.contains(qli.required_by_ext_Id__c)){
                           QLI.SBQQ__Quantity__c = contractLineCapacity.get(QLI.SBQQSC__RenewedContractLine__c);
                           QLI.RWD_Expected_Default_Quantity__c = QLI.SBQQ__Quantity__c;
                           QLI.Related_Asset_Total_Capacity__c = QLI.SBQQ__Quantity__c;
                       }//!quantCalculated.get(qli.required_by_ext_Id__c)
                    optionLevel0Lines.add(qli);
                }
            }
            optionLevel1Lines.addAll(parentChildSaasMap.values()); // Merged ADDON Lines
            
            List<SBQQ__QuoteLine__c> linesToBeSorted = new List<SBQQ__QuoteLine__c>();
            List<SBQQ__QuoteLine__c> listforRCDMT = new List<SBQQ__QuoteLine__c>(); //can be removed after 31stjuly 2024
            
            listforRCDMT.addAll(optionLevel0Lines);
            listforRCDMT.addAll(optionLevel1Lines);
            listforRCDMT.addAll(optionLevel2Lines);
            
            
            
            for(SBQQ__QuoteLine__c qli: listforRCDMT){
                
                //NEW Ad-Hoc RCDM
                
                
                if(rcdmValidQuote && qli.SBQQ__StartDate__c < quotRangeEnd && prodEligibleForRCDMT.contains(qli.SBQQ__Product__c)
                   /*&& (q1.Selective_Account_Eligible_for_RCDM_T__c == true || (q1.Selective_Account_Eligible_for_RCDM_T__c == false && contractLineAddRCDM.containsKey(qli.SBQQSC__RenewedContractLine__c) && contractLineAddRCDM.get(qli.SBQQSC__RenewedContractLine__c) == true))*/
                  ){
                      
                      SBQQ__QuoteLine__c rcdmQL = getRDCMTLine(qli.clone(),rcdmDatesObj,QLG);
                      SBQQ__QuoteLine__c tempQLI = new SBQQ__QuoteLine__c(required_by_ext_Id__c =  qli.required_by_ext_Id__c);
                      //qli.SBQQ__RequiredBy__c = NewQuoteLineInstanceMap.get(hwSubMap.containsKey(qlID));
                      rcdmQL.putSobject('SBQQ__RequiredBy__r', tempQLI);
                      rcdmQL.required_by_ext_Id__c = qli.required_by_ext_Id__c+'RCDMT';
                      rcdmQL.SBQQ__Quantity__c = qli.SBQQ__Quantity__c;
                      rcdmQL.SBQQ__StartDate__c = qli.SBQQ__StartDate__c;
                      
                      
                      if(qli.SBQQ__EndDate__c <= quotRangeEnd){
                          
                          rcdmQL.SBQQ__EndDate__c = qli.SBQQ__EndDate__c;
                      }else {
                          
                          rcdmQL.SBQQ__EndDate__c = quotRangeEnd;
                      }
                      rcdmQL.SubscribedAssetNames__c = qli.SubscribedAssetNames__c;
                      rcdmQL.RenewalQuantityPopulated__c =true;
                      rcdmQL.Subscribed_Asset_Name__c = qli.Subscribed_Asset_Name__c;
                      
                      rcdmQL.SBQQ__ProductOption__c = keyProdOptionMap.get(qli.SBQQ__Product__c + '-' + rcdmQL.SBQQ__Product__c);
                      
                      if(qli.SBQQ__OptionLevel__c == 0 || qli.SBQQ__OptionLevel__c == null){
                          rcdmQL.SBQQ__OptionLevel__c =1;
                          optionLevel1Lines.add(rcdmQL);
                      } else if(qli.SBQQ__OptionLevel__c == 1){
                          rcdmQL.SBQQ__OptionLevel__c =2;
                          optionLevel2Lines.add(rcdmQL);
                      }
                      
                      childParentMap.put(rcdmQL.required_by_ext_Id__c, qli.required_by_ext_Id__c);  
                      
                      
                      
                      
                  }
            }
            
            linesToBeSorted.addAll(optionLevel0Lines);
            optionLevel0Lines.clear();
            linesToBeSorted.addAll(optionLevel1Lines);
            optionLevel1Lines.clear();
            linesToBeSorted.addAll(optionLevel2Lines);
            optionLevel2Lines.clear();
            
            OrderQuoteLinesWrap returnList = setQuoteLineNumberForRenewal(linesToBeSorted,childParentMap, q1);
            optionLevel0Lines = returnList.option0List;
            optionLevel1Lines = returnList.option1List;
            optionLevel2Lines = returnList.option2List;
            
            try{
                SBQQ.TriggerControl.disable();
                TriggerControls.disableQuoteTrigger = true;
                TriggerControls.disableQuoteLineTrigger = true;
                if(!optionLevel0Lines.isEmpty())
                    insert optionLevel0Lines;
                
                
                SBQQ.TriggerControl.disable();
                TriggerControls.disableQuoteTrigger = true;
                TriggerControls.disableQuoteLineTrigger = true;
                if(!optionLevel1Lines.isEmpty())
                    insert optionLevel1Lines;
                
                SBQQ.TriggerControl.disable();
                TriggerControls.disableQuoteTrigger = true;
                TriggerControls.disableQuoteLineTrigger = true;
                
                if(!optionLevel2Lines.isEmpty())
                    insert optionLevel2Lines;
                
                
                if(!consContractLinesInstances.isEmpty()){
                    insert consContractLinesInstances;
                    q1.Consolidation_Identifier__c = true;
                }
                
                SBQQ.TriggerControl.disable();
                TriggerControls.disableQuoteTrigger = true;
                TriggerControls.disableQuoteLineTrigger = true;
                
                delete qlListDEL.values();
                
                    //CPQ22-3892 paritosh convert dsaas
                    convertDSAAS(q1);
                    //CPQ22-3892 Madhura to auto add RCDMT on V2 to V2 renewal
                    addRCDMTRenewal(q1);
                    
                    // V2 to V2 for M365 Renewals
                    convertV2ToV2(q1,FALSE,null);
                    
                    
                SBQQ.TriggerControl.enable();
                TriggerControls.disableQuoteTrigger = true;
                TriggerControls.disableQuoteLineTrigger = true;
                q1.Polaris_Conversion__c = true;
                q1.Polaris_Conversion_In_Progress__c = false;
                
                update q1;
                
                SBQQ.TriggerControl.disable();
                rcs = new Renewal_Conversion_Status__c();
                rcs.Quote__c = q1.id;
                if(WithOutMappingQLs.isEmpty())
                    rcs.Status__c = 'Completed';
                else{
                    String str = '';
                    rcs.Status__c = 'Partial Conversion completed';
                    for(String prodCode: productCodesNotFound ){
                        str = str + ',' + prodCode;
                    }
                    rcs.Fail_Reason__c = 'Mapping Not Found ' + str;
                }
                insert rcs;
                if (Test.isRunningTest() && forceTestException) {
                    throw new MyCustomException('Forced exception for testing.');
                }
            }Catch(Exception e){
                rcs = new Renewal_Conversion_Status__c();
                rcs.Quote__c = q1.id;
                rcs.Status__c = 'Failed';
               
                rcs.Fail_Reason__c = e.getStackTraceString() + '-' + e.getMessage();
                insert rcs;
            }
            //}else{
            /*if(!WithOutMappingQLs.isEmpty()){

            rcs = new Renewal_Conversion_Status__c();
            rcs.Quote__c = q1.Id;
            rcs.Status__c = 'Failed';
            String str = '';
            for(String prodCode: productCodesNotFound ){
            str = str + ',' + prodCode;
            }
            rcs.Fail_Reason__c = 'Mapping Not Found ' + str;
            insert rcs;
            /*FeedItem post = new FeedItem();
            post.Body = 'Mapping Not Found '+ str ;
            post.ParentId = q1.id;
            post.Title = 'Renewal Conversion Failure';
            insert post;*/
            //}
            if (Test.isRunningTest() && forceTestException) {
                throw new MyCustomException('Forced exception for testing.');
            }
        }catch(Exception e){
            if(e.getMessage() != 'Divide by 0'){
                Renewal_Conversion_Status__c rcs1 = new Renewal_Conversion_Status__c();
                rcs1.Quote__c = q1.Id;
                rcs1.Status__c = 'Failed';
               
                rcs1.Fail_Reason__c = e.getStackTraceString() + '-' + e.getMessage();
                //rcs1.Fail_Reason__c=e.getMessage();
                insert rcs1;
            }
        }
    }    
    
    /**
     * @description Finish Method
     * @param info
     */
    public void finish(Database.BatchableContext info){  
        
        Map<Id, Renewal_Conversion_Status__c> rcsMapQuote = new Map<Id, Renewal_Conversion_Status__c>();
        List<SBQQ__QuoteLine__c> quoteLineLst = [SELECT Id, SBQQ__Quote__c, SBQQSC__RenewedContractLine__r.ServiceContract.Renew_to_Old_SKUs__c, 
                                                 SBQQSC__RenewedContractLine__r.ServiceContractId, SBQQ__Product__r.License_Type__c, 
                                                 SBQQ__Product__r.License_Category__c FROM SBQQ__QuoteLine__c WHERE 
                                                 SBQQSC__RenewedContractLine__r.ServiceContract.Renew_to_Old_SKUs__c = TRUE 
                                                 AND SBQQ__Quote__c IN: quotesToConvert];
        
        
        for(SBQQ__QuoteLine__c quo: quoteLineLst){
            if(!rcsMapQuote.containsKey(quo.SBQQSC__RenewedContractLine__r.ServiceContractId)){
                Renewal_Conversion_Status__c rcs = new Renewal_Conversion_Status__c();
                rcs.Quote__c = quo.SBQQ__Quote__c;
                rcs.Status__c = 'Failed';
                rcs.Fail_Reason__c ='Contract ID : ' + quo.SBQQSC__RenewedContractLine__r.ServiceContractId + ' is marked as Renewal to OLD ';
                rcsMapQuote.put(quo.SBQQSC__RenewedContractLine__r.ServiceContractId,rcs);
            }
        }
        //if(rcsMapQuote.size() > 0)
        if(!rcsMapQuote.isEmpty())
            insert rcsMapQuote.values();
        /*
            List<SBQQ__Quote__c> quotetoupdate = new List<SBQQ__Quote__c>();
            for( SBQQ__Quote__c  quote: quotesToConvert){
            SBQQ__Quote__c TEMPREC = new SBQQ__Quote__c(id= quote.id );
            tempRec.Polaris_Conversion__c=true;
            quotetoupdate.add(tempRec);
            }
            SBQQ.TriggerControl.enable();
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true;

            update quotetoupdate;
            */
    } 
    
    /**
     * @description getRDCMTLine
     * @param RCDMTLine 
     * @param rcdmDatesObj1
     * @param groupLst 
     * @return SBQQ__QuoteLine__c
     */
    
    public static SBQQ__QuoteLine__c getRDCMTLine(SBQQ__QuoteLine__c RCDMTLine, X0_RCDM_Dates__mdt rcdmDatesObj1, 
                                                  List<SBQQ__QuoteLineGroup__c> groupLst)
    {
        
        SBQQ__QuoteLine__c rcdmQL = RCDMTLine;
        X0_RCDM_Dates__mdt rcdmDatesObj = rcdmDatesObj1;
        
        //if(groupLst != null && groupLst.size() > 0)
        if(groupLst != null && !groupLst.isEmpty())
            rcdmQL.SBQQ__Group__c = groupLst[0].Id;
        rcdmQL.SBQQSC__RenewedContractLine__c = null;
        rcdmQL.SBQQ__PricebookEntryId__c = System.Label.RCDM_PBEId;
        rcdmQL.SBQQ__Product__c = System.Label.RCDM_ProductId;
        rcdmQL.SBQQ__Discount__c = 100;
        rcdmQL.SBQQ__ListPrice__c = 130;
        rcdmQL.SBQQ__NetPrice__c = 0;
        rcdmQL.Minimum_Term__c = 0;
        rcdmQL.Disposition_Reason__c = 'None';
        rcdmQL.Is_Subscription_term_Minimum_term__c = false;
        rcdmQL.Product_Level__c = rcdmDatesObj != null ? rcdmDatesObj.Product_Level__c : 'OnPrem';
        rcdmQL.Product_Type__c = null;
        rcdmQL.SubscribedAssetLookup__c = null;
        rcdmQL.Promo_Disc__c = null;
        rcdmQL.CPQ_Prior_Discount__c = null;
        rcdmQL.SBQQ__OriginalPrice__c = rcdmDatesObj != null ? rcdmDatesObj.List_Price__c : 0;
        rcdmQL.SBQQ__CustomerPrice__c = 0;
        rcdmQL.SBQQ__SubscriptionPricing__c = rcdmDatesObj != null ? rcdmDatesObj.Subscription_Pricing__c : 'Fixed Price';
        rcdmQL.Approval_Category__c = rcdmDatesObj != null ? rcdmDatesObj.Approval_Category__c : '';
        rcdmQL.SBQQ__ProductSubscriptionType__c = 'One-time';
        rcdmQL.SBQQ__SubscriptionType__c = rcdmDatesObj != null ? rcdmDatesObj.Subscription_Type__c : 'One-time';
        rcdmQL.Approval_Flags__c = String.valueOf('/img/msg_icons/confirm16.png None');
        rcdmQL.Licensing_Model__c = rcdmDatesObj != null ? rcdmDatesObj.Licensing_Type__c : 'Subscription';
        rcdmQL.SBQQ__SpecialPrice__c = rcdmDatesObj != null ? rcdmDatesObj.Special_Price__c : 0;
        rcdmQL.SBQQ__Description__c = rcdmDatesObj != null ? rcdmDatesObj.Description__c : '';
        rcdmQL.License_Category__c = System.Label.RCDM_LicenseCategory; //'On Prem';
        rcdmQL.Product_Subtype__c = '';
        rcdmQL.Sales_Comp_Category__c = rcdmDatesObj != null ? rcdmDatesObj.Sales_Comp_Category__c: '';
        rcdmQL.SBQQ__DynamicOptionId__c = '';//REEN-24 added line
        rcdmQL.SBQQ__OptionType__c = 'Related Product'; //REEN-24 added line
        //REEN-92 start
        rcdmQL.Total_Prior_Net_Total__c = null;       
        rcdmQL.Total_Prior_Net_Total_With_Uplift__c = null;       
        rcdmQL.Prior_Net_Total__c = null;        
        rcdmQL.Prior_Net_Total_With_Uplift__c = null;
        rcdmQL.Discount_Margin__c = null;
        rcdmQL.DMA__c = null;
        //REEN-92 end
        
        
        return rcdmQL;
    }
    
    /***********************************************************************************************************
 * Method Name           : cloneQuoteLineIns
 * @description          : Clones an SBQQ__QuoteLine__c record and updates it based on product mapping rules 
 * @param masterQL       : The original/master SBQQ__QuoteLine__c record, used for retrieving Renewal Quantity.
 * @param quoteLine      : The cloned SBQQ__QuoteLine__c record to be updated and returned.
 * @param targetKSU      : Polaris_SKU_Mapping_V2__c record for product conversion, if applicable.
 * @param Itr            : Multi_Mapping_V2_Conversion__c record for product conversion, if applicable.
 * @param extID          : External ID to be set on the 'required_by_ext_Id__c' field.
 * @param pbeMAP         : Map of Product Code to PricebookEntryId for lookups.
 * @return               : The updated SBQQ__QuoteLine__c record.
 * 
 ***********************************************************************************************************/
    public static SBQQ__QuoteLine__c cloneQuoteLineIns(SBQQ__QuoteLine__c masterQL, SBQQ__QuoteLine__c quoteLine, Polaris_SKU_Mapping_V2__c targetKSU, 
                                                       Multi_Mapping_V2_Conversion__c Itr, String extID, Map<String, Id> pbeMAP)
    {
        
        // -------- Common defaults --------
        quoteLine.Disposition_Reason__c       = 'None';
        quoteLine.Flag_for_Discount__c = true;
        if (extID != null) {
            quoteLine.required_by_ext_Id__c = extID;
        }
        quoteLine.RenewalQuantityPopulated__c = true;
        
        // Reset shared fields
            quoteLine.SBQQ__ListPrice__c = null;
            quoteLine.SBQQ__OriginalPrice__c = null;
            quoteLine.Product_Option_Percent_of_Total__c = null;
            quoteLine.SBQQ__SubscriptionPercent__c = null;
            quoteLine.SBQQ__SubscriptionScope__c = null;
            quoteLine.SBQQ__BundledQuantity__c = null;
        quoteLine.SBQQ__SpecialPrice__c              = null;
        quoteLine.SBQQ__CustomerPrice__c             = null;
        quoteLine.SBQQ__RegularPrice__c              = null;
        quoteLine.SBQQ__ProratedListPrice__c         = null;
        quoteLine.SBQQ__NetPrice__c                  = null;
        quoteLine.SBQQ__ProratedPrice__c             = null;
        quoteLine.SBQQ__UnproratedNetPrice__c        = null;
        quoteLine.SBQQ__ProductOption__c             = null;
        
        // -------- Polaris SKU Mapping --------
        if (targetKSU != null && targetKSU.New_Product__c != null) {
            quoteLine.SBQQ__Product__c                 = targetKSU.New_Product__c;
            quoteLine.SBQQ__Description__c = targetKSU.New_Product__r.Description;
            quoteLine.Sales_Comp_Category__c = targetKSU.New_Product__r.Sales_Comp_Category__c;
            quoteLine.SBQQ__DefaultSubscriptionTerm__c = targetKSU.New_Product__r.SBQQ__SubscriptionTerm__c;
            
            if (pbeMAP != null && pbeMAP.containsKey(targetKSU.New_Product__r.ProductCode)) {
                quoteLine.SBQQ__PricebookEntryId__c = pbeMAP.get(targetKSU.New_Product__r.ProductCode);
        }
            
            // Always normal renewal path for Polaris
            quoteLine.RWD_Expected_Default_Quantity__c =
                masterQL.SBQQSC__RenewedContractLine__r.SBQQSC__RenewalQuantity__c;
        }
        
        else if (Itr != null && Itr.Target_Product__c != null) {
            quoteLine.SBQQ__Product__c = Itr.Target_Product__c;
            quoteLine.SBQQ__Description__c = Itr.Target_Product__r.Description;
            quoteLine.Sales_Comp_Category__c = Itr.Target_Product__r.Sales_Comp_Category__c;
            quoteLine.SBQQ__DefaultSubscriptionTerm__c = Itr.Target_Product__r.SBQQ__SubscriptionTerm__c;
            
            if (pbeMAP != null && pbeMAP.containsKey(Itr.Target_Product__r.ProductCode)) {
                quoteLine.SBQQ__PricebookEntryId__c = pbeMAP.get(Itr.Target_Product__r.ProductCode);
        }
            
            // Sub-case: V2 → V2 renewal (Renewal Type check)
            if (Itr.Renewal_Type__c != null && Itr.Renewal_Type__c == 'V2 To V2') {
                quoteLine.Product_Level__c       = Itr.Target_Product__r.Product_Level__c;
                quoteLine.Approval_Category__c   = Itr.Target_Product__r.Approval_Category__c;
                quoteLine.Replacement_Details__c = masterQL.Replacement_Details__c;
                
                if (Itr.Quantity_Multiplier__c != null) {
                    quoteLine.SBQQ__Quantity__c = masterQL.SBQQ__Quantity__c * Itr.Quantity_Multiplier__c;
                }
            }
            else {
                quoteLine.RWD_Expected_Default_Quantity__c =
                    masterQL.SBQQSC__RenewedContractLine__r.SBQQSC__RenewalQuantity__c;
                quoteLine.Support_Split_Percent__c = Itr.Pricing_Percent__c;
            }
        }

        return quoteLine;
    }
    
    /**
     * @description getProdFeature
     * @param Configid
     * @param featureNames 
     * @return Map<String, String>
     */
    public static Map<String, String> getProdFeature(Set<String> Configid, List<String> featureNames){
        Map<String, String> dynamicOptionIdMAp = new Map<String, String>();
        
        for(SBQQ__ProductFeature__c pf: [SELECT Id, SBQQ__ConfiguredSKU__c, Name FROM SBQQ__ProductFeature__c WHERE 
                                         SBQQ__ConfiguredSKU__c IN: configid AND Name IN: featureNames])
        {
            dynamicOptionIdMAp.put(pf.SBQQ__ConfiguredSKU__c + '-' + pf.Name, pf.Id);
        }
        return dynamicOptionIdMAp;
    }
    
    
    /**
     * @description returnAllProductOptions
     * @param configSKUCode
     * @param optionSKUCode 
     * @return Map<String, Id>
     */
    public static Map<String, Id> returnAllProductOptions(Set<String> configSKUCode, Set<String> optionSKUCode){   
        Map<String, Id> keyProdOptionId = new Map<String, Id>();
        for(SBQQ__ProductOption__c Pos: [SELECT Id, SBQQ__ConfiguredSKU__c, SBQQ__OptionalSKU__c FROM SBQQ__ProductOption__c WHERE 
                                         SBQQ__ConfiguredSKU__c IN: configSKUCode AND SBQQ__OptionalSKU__c IN: optionSKUCode])
        {
            keyProdOptionId.put(pos.SBQQ__ConfiguredSKU__c + '-' + pos.SBQQ__OptionalSKU__c, pos.Id);
        }
        return keyProdOptionId;
    }
    
    /**
     * @description getAllFieldsForClone
     * @return List<String>
     */
    public static List<String> getAllFieldsForClone(){
        Map<String, List<String>> allField = new Map<String, List<String>>();
        List<String> CreatableFields = new List<string>();
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();    
        Map <String, Schema.SObjectField> fieldMap = gd.get('SBQQ__QuoteLine__c').getDescribe().fields.getMap();
        
        for(Schema.SObjectField fieldAPI: fieldMap.values())
        {  
            Schema.DescribeFieldResult dfield = fieldAPI.getDescribe();
            if(!dfield.isCalculated() && dfield.getName() != 'SBQQ__RequiredBy__c'){
                CreatableFields.add(dfield.getName());
            }
            
        }
        return CreatableFields;
    }
    
    /**
     * @description getPriceBookEntries
     * @return Map<String, Id>
     * @param PricebookID
     */
    public static Map<String, Id> getPriceBookEntries(Id PricebookID){
        Map<String, Id> prodPBEMap = new Map<String, Id>();
        
        for(PricebookEntry pbe: [SELECT Pricebook2Id, Product2Id, Product2.Productcode, IsActive FROM PricebookEntry WHERE Pricebook2Id =: PricebookID])
        {
            prodPBEMap.put(pbe.Product2.Productcode, pbe.Id);
        }
        return prodPBEMap;
    }
    
    /**
 * @description
 * Retrieves and organizes product mapping information based on a set of source product codes and a renewal type. 
 *
 * @param soruceProds Set of source product codes to fetch mappings for.
 * @param renewalType Renewal type indicator  which controls filtering and mapping behavior.
 * @return Map<String, ProdMapWrapper> A map where keys are source product codes and values are wrapper objects
 *         containing related mapping records and metadata.
 */
    public static Map<String, ProdMapWrapper> getProdMap(Set<String> soruceProds, String renewalType){
        Map<String, ProdMapWrapper> prodWrapMap = new Map<String, ProdMapWrapper>();
        List<String> lstProductTypes = !String.isBlank(System.Label.CustomRenewalProductType) ? System.Label.CustomRenewalProductType.split(',') : null;
		if(renewalType != 'V2 To V2'){
        for(Polaris_SKU_Mapping_V2__c skuMap: [SELECT Id, Feature_Name_on_New_Product__c, New_Product__c, New_Product__r.Productcode, Old_Product__c,
                                               Old_Product__r.Productcode, New_Product__r.Eligible_for_RCDM_T__c, New_Product__r.Product_Type__c, 
                                               New_Product__r.Product_Subtype__c, Payment_Option__c, Quantity_Mapping_Type__c, Quantity_Ratio__c, 
                                               Support_Type__c, Support_Tier__c, New_Product__r.SBQQ__SubscriptionTerm__c,
                                               New_Product__r.Description, New_Product__r.Sales_Comp_Category__c
                                               FROM Polaris_SKU_Mapping_V2__c WHERE Old_Product__r.Productcode IN: soruceProds AND  Old_Product__r.Product_Type__c NOT IN:lstProductTypes])
        {
            ProdMapWrapper tempWrap;
            
            if(prodWrapMap.containsKey(skuMap.Old_Product__r.Productcode)){
                tempWrap = prodWrapMap.get(skuMap.Old_Product__r.Productcode);
            }else{
                    tempWrap = new ProdMapWrapper();
                tempWrap.supTypePaymentOptionPRODMap = new Map<String, Polaris_SKU_Mapping_V2__c>();
                tempWrap.supTierPRODMap = new Map<String, Polaris_SKU_Mapping_V2__c>();
                tempWrap.singleMapRecord = new Map<String, Polaris_SKU_Mapping_V2__c>();
                tempWrap.singleMapRecord.put(skuMap.Old_Product__r.Productcode,skuMap);
            }
            if(skuMap.Support_Type__c != null && skuMap.Payment_Option__c != null)
                tempWrap.supTypePaymentOptionPRODMap.put(skuMap.Support_Type__c + '-' + skuMap.Payment_Option__c + '-' + 
                                                         skuMap.Old_Product__r.Productcode, skuMap);
            if(skuMap.Support_Tier__c != null)
                tempWrap.supTierPRODMap.put(skuMap.Support_Tier__c + '-' + skuMap.Old_Product__r.Productcode, skuMap);
            tempWrap.countOFMapping = tempWrap.countOFMapping + 1;
            prodWrapMap.put(skuMap.Old_Product__r.Productcode, tempWrap);
            }
        }
        
        for(Multi_Mapping_V2_Conversion__c splitMap: getMultiMappings(soruceProds,renewalType))
        {
            ProdMapWrapper tempWrap;
			String keyTemp;
			if(renewalType != 'V2 To V2'){
				keyTemp = splitMap.Source_Product__r.Productcode + splitMap.Support_Type__c + splitMap.Payment_Option__c; 
            }
			else{
				keyTemp = splitMap.Source_Product__r.Productcode + splitMap.Storage_Tier__c + splitMap.Support_Type__c + splitMap.Payment_Option__c;
                soruceProds.add(splitMap.Source_Product__c);
                soruceProds.add(splitMap.Target_Product__c);
			}
            
            if(prodWrapMap.containsKey(splitMap.Source_Product__r.Productcode)){
                tempWrap = prodWrapMap.get(splitMap.Source_Product__r.Productcode);
            }else{
                tempWrap = new ProdMapWrapper();
                tempWrap.splitMapRecordsWithOldSKU = new Map<String, List<Multi_Mapping_V2_Conversion__c>>();
                tempWrap.isSplit = true;
            }
            if(tempWrap !=null && tempWrap.splitMapRecordsWithOldSKU.containsKey(keytemp)){
                tempWrap.splitMapRecordsWithOldSKU.get(keytemp).add(splitMap);
            }else{
                List<Multi_Mapping_V2_Conversion__c> tempList = new List<Multi_Mapping_V2_Conversion__c>();
                tempList.add(splitMap);
                tempWrap.splitMapRecordsWithOldSKU.put(keyTemp,tempList);
            }
            prodWrapMap.put(splitMap.Source_Product__r.Productcode,tempWrap);
			
			/* if(splitMap.Target_Product__c != null) {
                optionSKU.add(splitMap.Target_Product__c);
            }*/
        }
        
        return prodWrapMap;
    }
    
    /**
     * @description ProdMapWrapper
     * @return Map<String, Id>
     * @param PricebookID
     */
    public class ProdMapWrapper{
        /**supTypePaymentOptionPRODMap */
        Map<String, Polaris_SKU_Mapping_V2__c> supTypePaymentOptionPRODMap;
        /**supTierPRODMap */
        Map<String, Polaris_SKU_Mapping_V2__c> supTierPRODMap;
        /**singleMapRecord */
        Map<String, Polaris_SKU_Mapping_V2__c> singleMapRecord;
        /**splitMapRecordsWithOldSKU */
        Map<String, List<Multi_Mapping_V2_Conversion__c>> splitMapRecordsWithOldSKU;
        /**isSplit */
        Boolean isSplit = false;
        /**countOFMapping */
        Integer countOFMapping = 0;
    }
    
    /**setQuoteLineNumberForRenewal */
    /**
     * @description setQuoteLineNumberForRenewal
     * @return Map<String, Id>
     * @param newQuoteList
     * @param childParentMAp
     * @param quoteRecord
     */
    public static OrderQuoteLinesWrap setQuoteLineNumberForRenewal(List<SBQQ__QuoteLine__c> newQuoteList, Map<String, String> childParentMAp, SBQQ__Quote__c quoteRecord){
        
        OrderQuoteLinesWrap returnVar = new OrderQuoteLinesWrap();
        returnVar.option0List =  new List<SBQQ__QuoteLine__c>();
        returnVar.option1List = new List<SBQQ__QuoteLine__c>();
        returnVar.option2List = new List<SBQQ__QuoteLine__c>();
        
        Map<Decimal, List<SBQQ__QuoteLine__c>> optionLevelListMap = new Map<Decimal, List<SBQQ__QuoteLine__c>>();
        
        optionLevelListMap.put(0,returnVar.option0List);
        optionLevelListMap.put(1,returnVar.option1List);
        optionLevelListMap.put(2,returnVar.option2List); 
        
        Map<String, Integer> lineItemNumberMap = new Map<String, Integer>();
        Map<String, List<String>> lineItemParentChildMap = new Map<String, List<String>>();
        Map<String, String> lineItemParentRCDM = new Map<String, String>();
        Map<String, SBQQ__QuoteLine__c> quoteLineIDMap = new Map<String, SBQQ__QuoteLine__c>();
        
        for(SBQQ__QuoteLine__c quote: newQuoteList){
            String qid = quote.required_by_ext_Id__c;
            quoteLineIDMap.put(qid, quote);
            
            
            String parentID = childParentMAp.get(qid) != null ? childParentMAp.get(qid): qid;
            
            /*  Commenting for PB EDGE issue CPQ22-3629
            if(qid.contains('RCDMT')){
            lineItemParentRCDM.put(parentID,qid);
            continue;
            }*/
            if(!lineItemParentChildMap.ContainsKey(parentID)){
                lineItemParentChildMap.put(parentID, new List<String>{qid});
            }
            else{
                lineItemParentChildMap.get(parentID).add(qid);
            } 
        }
        /*Commenting for PB EDGE issue CPQ22-3629
            for(String keyStr: lineItemParentChildMap.keyset()){
            if(lineItemParentRCDM.containsKey(keyStr))
            lineItemParentChildMap.get(keyStr).add(lineItemParentRCDM.get(keyStr));
            }*/
        
        //REEN-24 correct order
        Integer nextInd = (Integer) quoteRecord.SBQQ__LineItemCount__c + 1;
        if(lineItemParentChildMap != null){
            //Iterate through each child line and store line number
            for(String parentLineID: lineItemParentChildMap.keyset()){
                if(lineItemNumberMap.containskey(parentLineID)){
                    nextInd = lineItemNumberMap.get(parentLineID)+1;
                }else{
                    quoteLineIDMap.get(parentLineID).SBQQ__number__c = nextInd;
                    lineItemNumberMap.put(parentLineID,nextInd);
                    nextInd = nextInd + 1;
                    
                    Decimal oplev = quoteLineIDMap.get(parentLineID).SBQQ__OptionLevel__c != null? 
                        quoteLineIDMap.get(parentLineID).SBQQ__OptionLevel__c : 0;
                    
                    optionLevelListMap.get(oplev).add(quoteLineIDMap.get(parentLineID));
                }
                
                if(lineItemParentChildMap.ContainsKey(parentLineID)){
                    //Iterate through each grand child line and store line number
                    for(String childId: lineItemParentChildMap.get(parentLineID)){
                        if(childId != parentLineID){
                            quoteLineIDMap.get(childId).SBQQ__number__c = nextInd;
                            Decimal oplev = quoteLineIDMap.get(childId).SBQQ__OptionLevel__c != null? 
                                quoteLineIDMap.get(childId).SBQQ__OptionLevel__c : 0;
                            
                            optionLevelListMap.get(oplev).add(quoteLineIDMap.get(childId));
                            lineItemNumberMap.put(childId,nextInd);
                            
                            if(lineItemParentChildMap.get(childId)!= null){
                                Integer sizetemp = lineItemParentChildMap.get(childId).size();
                                nextInd = nextInd + (sizetemp+1);
                            }
                            else{
                                nextInd = nextInd+1;
                            }
                        }
                    }
                }    
            } 
        } 
        return returnVar;
    }
    
    /**OrderQuoteLinesWrap
     * @description OrderQuoteLinesWrap
     * @return Map<String, Id>
     * @param newQuoteList
     */
    public class OrderQuoteLinesWrap{
        /**option0List */
        List<SBQQ__QuoteLine__c> option0List ; 
        /**option1List */
        List<SBQQ__QuoteLine__c> option1List ; 
        /**option2List */
        List<SBQQ__QuoteLine__c> option2List ; 
    }
    
        
        /**
         * @description //CPQ22-3892 renew old dsaas to new dsaas 
         *  @param quote The Quote record to convert. 
         */
        public static void convertDSAAS(SBQQ__Quote__c quote){ 


            //FY25SR-2022 exclude optional lines, added uplift and CLI clause
            List<SBQQ__QuoteLine__c>  qliList =  [select id, SBQQ__ProductCode__c, SBQQ__Quantity__c, SBQQ__StartDate__c, SBQQ__Quote__c, CPQ_Uplift__c, SBQQSC__RenewedContractLine__r.Channel_Uplift__c, SBQQ__Quote__r.SBQQ__LineItemCount__c,
                                                        SBQQSC__RenewedContractLine__c, SBQQSC__RenewedContractLine__r.Total_Price_Without_Promo__c, SBQQSC__RenewedContractLine__r.SBQQSC__ProrateMultiplier__c, SBQQSC__RenewedContractLine__r.SBQQSC__Quantity__c,
                                                        SBQQ__Product__r.Custom_Renewal_Product__c, SBQQ__Product__r.Custom_Renewal_Type__c, SBQQ__Product__r.Custom_Renewal_Product__r.Pricebook_Entry_Id__c,
                                                        SBQQ__Product__r.Custom_Renewal_Product__r.Product_Level__c, SBQQ__Product__r.Custom_Renewal_Product__r.Approval_Category__c, SBQQ__Product__r.Custom_Renewal_Product__r.Description,
                                                        SBQQ__Product__r.Custom_Renewal_Product__r.Support_Split_Percent__c, SBQQ__Product__r.Custom_Renewal_Product__r.Product_Type__c, SBQQ__Product__r.Custom_Renewal_Attributes__c,
                                                        Replacement_Motion__c,Replacement_Details__c,Arroyo_Subsumed_Old_Contract_Line_Items__c,SBQQ__EndDate__c,Disposition_Reason__c,SBQQ__Group__c //FY25SR-1663
                                                        FROM SBQQ__QuoteLine__c 
                                                        WHERE SBQQ__Quote__c =:quote.Id AND SBQQ__Product__r.Custom_Renewal_Product__c!=null AND SBQQ__Product__r.Custom_Renewal_Type__c = 'DSAAS' 
                                                        AND Quote_Line_Type__c = 'Renewal' AND SBQQ__Quote__r.SBQQ__Status__c != 'Approved' AND SBQQ__Optional__c=false
                                                        AND CPQ_Uplift__c != null AND SBQQSC__RenewedContractLine__c != null];
            if (qliList.size() == 0) return;

            Map<Id, PricebookEntry> pricebookMap = new Map<Id, PricebookEntry> ([select id, UnitPrice from PricebookEntry where  Product2.Support_Split_Percent__c!=null OR Product2.Product_Type__c like 'Cloud Vault %']);
            List<SBQQ__QuoteLine__c> quoteLinesOldDSAAS = new List<SBQQ__QuoteLine__c>();
            List<SBQQ__QuoteLine__c> quoteLinesDSAAS = new List<SBQQ__QuoteLine__c>();
            List<SBQQ__QuoteLine__c> quoteLinesRCV = new List<SBQQ__QuoteLine__c>();
            Map<SBQQ__QuoteLine__c, SBQQ__QuoteLine__c> parentMap = new Map<SBQQ__QuoteLine__c, SBQQ__QuoteLine__c>();
            Integer lineNumber = (Integer) qliList[0].SBQQ__Quote__r.SBQQ__LineItemCount__c + 1;

            for(SBQQ__QuoteLine__c qli: qliList){
                

                //delete old dsaas
                quoteLinesOldDSAAS.add(qli);

                Map<String, String> crAttMap = (Map<String, String>) JSON.deserialize(qli.SBQQ__Product__r.Custom_Renewal_Attributes__c, Map<String, String>.class);

                //create new DSAAS
                SBQQ__QuoteLine__c dsaasLine = qli.clone();
                dsaasLine.SBQQ__Product__c = qli.SBQQ__Product__r.Custom_Renewal_Product__c;
                dsaasLine.SBQQ__PriceBookEntryId__c = qli.SBQQ__Product__r.Custom_Renewal_Product__r.Pricebook_Entry_Id__c;
                dsaasLine.Product_Level__c = qli.SBQQ__Product__r.Custom_Renewal_Product__r.Product_Level__c;
                dsaasLine.Approval_Category__c = qli.SBQQ__Product__r.Custom_Renewal_Product__r.Approval_Category__c;
                dsaasLine.SBQQ__Description__c = qli.SBQQ__Product__r.Custom_Renewal_Product__r.Description;
                dsaasLine.Replacement_Details__c=qli.Replacement_Details__c!=null ?qli.Replacement_Details__c: null;//FY25SR-1663
                dsaasLine.Replacement_Motion__c=qli.Replacement_Motion__c!=null ?qli.Replacement_Motion__c: null;//FY25SR-1663
                if (qli.SBQQ__Product__r.Custom_Renewal_Product__r.Product_Type__c.contains('Cloud Vault') 
                    && crAttMap.containsKey('RCVQuantRatio')
                  ){
                    dsaasLine.SBQQ__Quantity__c = qli.SBQQ__Quantity__c * Integer.valueOf(crAttMap.get('RCVQuantRatio'));
                    dsaasLine.RenewalQuantityPopulated__c = true;
                }
                dsaasLine.Previous_Quantity_Value__c = dsaasLine.SBQQ__Quantity__c;
                dsaasLine.SBQQ__Number__c = lineNumber++;

                //calculate pricing
                Decimal targetUnitPrice = null;
                Decimal targetUnitPriceDSAAS = null;
                
                if (pricebookMap.containsKey(qli.SBQQ__Product__r.Custom_Renewal_Product__r.Pricebook_Entry_Id__c) && qli.SBQQSC__RenewedContractLine__c != null && qli.SBQQSC__RenewedContractLine__r.Total_Price_Without_Promo__c != null){
                    Decimal uplift = Decimal.valueOf(qli.CPQ_Uplift__c)/100 + (qli.SBQQSC__RenewedContractLine__r.Channel_Uplift__c!=null ? qli.SBQQSC__RenewedContractLine__r.Channel_Uplift__c : 0);
                    Decimal splitPercent = qli.SBQQ__Product__r.Custom_Renewal_Product__r.Support_Split_Percent__c;
                    targetUnitPrice = ((qli.SBQQSC__RenewedContractLine__r.Total_Price_Without_Promo__c / qli.SBQQSC__RenewedContractLine__r.SBQQSC__ProrateMultiplier__c) / qli.SBQQSC__RenewedContractLine__r.SBQQSC__Quantity__c) * (1 + uplift);
                    targetUnitPriceDSAAS = targetUnitPrice * (splitPercent != null ? splitPercent : 1);
                    if (qli.SBQQ__Product__r.Custom_Renewal_Product__r.Product_Type__c.contains('Cloud Vault') && crAttMap.containsKey('RCVQuantRatio')){
                        targetUnitPriceDSAAS = targetUnitPriceDSAAS / Integer.valueOf(crAttMap.get('RCVQuantRatio'));
                    }
                    Decimal listPriceDSAAS = pricebookMap.get(qli.SBQQ__Product__r.Custom_Renewal_Product__r.Pricebook_Entry_Id__c).UnitPrice;
                    dsaasLine.SBQQ__Discount__c = ((listPriceDSAAS - targetUnitPriceDSAAS) / listPriceDSAAS) * 100;
                    dsaasLine.Flag_for_Discount__c = true;
                    dsaasLine.Support_Split_Percent__c = splitPercent;

                    
                }

                quoteLinesDSAAS.add(dsaasLine);

                //create cva/cvb option
                if (qli.SBQQ__Product__r.Custom_Renewal_Attributes__c != null && crAttMap.containsKey('RCVProd')){
                    SBQQ__QuoteLine__c rcvLine = new SBQQ__QuoteLine__c(
                        SBQQ__Quote__c = qli.SBQQ__Quote__c,
                        SBQQ__Product__c = crAttMap.get('RCVProd'),
                        SBQQ__PriceBookEntryId__c = crAttMap.get('RCVProdPricebook'),
                        SBQQ__ProductOption__c = crAttMap.get('RCVProdOption'),
                        SBQQ__Quantity__c = qli.SBQQ__Quantity__c * Integer.valueOf(crAttMap.get('RCVQuantRatio')),
                        RenewalQuantityPopulated__c = true,
                        SBQQ__Number__c = lineNumber++,
                        SBQQ__StartDate__c = qli.SBQQ__StartDate__c,
                        SBQQSC__RenewedContractLine__c = qli.SBQQSC__RenewedContractLine__c,
                        //Replacement_Details__c=qli.Replacement_Details__c!=null ?qli.Replacement_Details__c: null,//FY25SR-1663
                        Replacement_Motion__c=qli.Replacement_Motion__c!=null ?qli.Replacement_Motion__c: null, //FY25SR-1663
                        Arroyo_Subsumed_Old_Contract_Line_Items__c=qli.Arroyo_Subsumed_Old_Contract_Line_Items__c!=null ?qli.Arroyo_Subsumed_Old_Contract_Line_Items__c: null, //FY25SR-1663
                        SBQQ__EndDate__c=qli.SBQQ__EndDate__c!=null ?qli.SBQQ__EndDate__c: null, //FY25SR-1663
                        Disposition_Reason__c=qli.Disposition_Reason__c!=null ?qli.Disposition_Reason__c: null, //FY25SR-1663
                        SBQQ__Group__c= qli.SBQQ__Group__c!=null ?qli.SBQQ__Group__c: null //FY25SR-1663   
                    );

                    //calculate pricing
                    if (qli.SBQQ__Product__r.Custom_Renewal_Product__r.Support_Split_Percent__c != null && pricebookMap.containsKey(rcvLine.SBQQ__PriceBookEntryId__c)){
                        Decimal targetUnitPriceRCV = (targetUnitPrice - targetUnitPriceDSAAS) / Integer.valueOf(crAttMap.get('RCVQuantRatio'));
                        Decimal listPriceRCV = pricebookMap.get(rcvLine.SBQQ__PriceBookEntryId__c).UnitPrice;
                        rcvLine.SBQQ__Discount__c = ((listPriceRCV - targetUnitPriceRCV) / listPriceRCV) * 100;
                        rcvLine.Flag_for_Discount__c = true;
                        rcvLine.Support_Split_Percent__c = 1 - qli.SBQQ__Product__r.Custom_Renewal_Product__r.Support_Split_Percent__c;

                        
                    }
                    
                    quoteLinesRCV.add(rcvLine);
                    parentMap.put(rcvLine, dsaasLine);
                }
            }

            //update deal ops exception to bypass discount floor
            //Below change as part of SF-72381 replaced fields RWD_Deal_Ops_Exception__c and RWD_Deal_Ops_Exception_Justification__c
            /*SBQQ__Quote__c quoteUpdate = new SBQQ__Quote__c(
                Id = quote.Id,
                RWD_Deal_Ops_Exception__c = 'Hardfloor Discount Exception - RCV',
                RWD_Deal_Ops_Exception_Justification__c = 'DSAAS conversion'
            );*/
            //commented as part of SMT2-17 sunset Quoting desk exception program CPQ22-6257
            /*SBQQ__Quote__c quoteUpdate = new SBQQ__Quote__c(
                Id = quote.Id,
                Quoting_Desk_Exception__c = 'Hardfloor Discount Exception - RCV',
                Quoting_Desk_Exception_Justification__c = 'DSAAS conversion'
            );*/
            
            if (quoteLinesDSAAS.size() > 0) {
                SBQQ.TriggerControl.disable();
            TriggerControls.disableQuoteLineTrigger = true;
                TriggerControls.disableQuoteTrigger = true;
                
                insert quoteLinesDSAAS;

                for (SBQQ__QuoteLine__c rcvLine : quoteLinesRCV){
                    rcvLine.SBQQ__RequiredBy__c = parentMap.get(rcvLine).Id;
                }
                insert quoteLinesRCV;

                delete quoteLinesOldDSAAS;

                //update quoteUpdate;//commented as part of SMT2-17 sunset Quoting desk exception program CPQ22-6257

                SBQQ.TriggerControl.enable();
            TriggerControls.disableQuoteLineTrigger = false;
                TriggerControls.disableQuoteTrigger = false;
            }
        }
//CPQ22-4202 autoAdd RCDMT for V2 to V2 renewal Lines
        /**
         * @description addRCDMTRenewal
         *  @param quote 
         */
    public static void addRCDMTRenewal(SBQQ__Quote__c quote){ 
    
        Map<Id,SBQQ__QuoteLine__c> mapClivsQli = new Map<Id,SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> qlToaddRCDMT = new list<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> insertRCDMT = new list<SBQQ__QuoteLine__c>();
        Map<String, String> keyProdOptionMap1 = new Map<String, String>();
        Set<String> configSKUCode1 = new Set<String>();
        Set<String> optionSKUCode1 = new Set<String>();
        Map<Id,Double> reqbyIdvsbndlno = new Map<Id,Double>();
        Map<Id,Id> bundlClivsRcdmCli = new Map<Id,Id>();
            Date EOLdate = quote.RCDMT_EOL_Date__c; 
        List<SBQQ__QuoteLine__c>  qliList =  [select id,SBQQ__Number__c, SBQQ__ProductCode__c,Quote_Line_Type__c,SBQQ__Group__c, SBQQ__Quantity__c, SBQQ__StartDate__c,SBQQ__EndDate__c, SBQQ__Quote__c,SBQQ__Quote__r.Eligible_for_RCDM_T__c,RenewalQuantityPopulated__c,SBQQ__Quote__r.Is_Customer_Fully_Transitioned__c, SBQQ__Quote__r.RCDMT_EOL_Date__c,SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,SBQQ__RequiredBy__r.SBQQ__Number__c,SBQQ__RequiredBy__c,SBQQ__Product__c,SBQQ__Product__r.Eligible_for_RCDM_T__c,Special_Program__c,SBQQSC__RenewedContractLine__c,SBQQ__ProductOption__c,SBQQ__OptionLevel__c,Subscribed_Asset_Name__c, SBQQSC__RenewedContractLine__r.Channel_Uplift__c,SubscribedAssetNames__c, SBQQ__Quote__r.SBQQ__LineItemCount__c, SBQQSC__RenewedContractLine__r.Total_Price_Without_Promo__c, SBQQSC__RenewedContractLine__r.SBQQSC__ProrateMultiplier__c, SBQQSC__RenewedContractLine__r.SBQQSC__Quantity__c,
                                                    SBQQ__Product__r.Custom_Renewal_Product__c, SBQQ__Product__r.Custom_Renewal_Type__c, SBQQ__Product__r.Custom_Renewal_Product__r.Pricebook_Entry_Id__c,
                                                    SBQQ__Product__r.Custom_Renewal_Product__r.Product_Level__c, SBQQ__Product__r.Custom_Renewal_Product__r.Approval_Category__c, SBQQ__Product__r.Custom_Renewal_Product__r.Description,
                                                    SBQQ__Product__r.Custom_Renewal_Product__r.Support_Split_Percent__c, SBQQ__Product__r.Custom_Renewal_Attributes__c 
                                                    FROM SBQQ__QuoteLine__c 
                                                    WHERE SBQQ__Quote__c =:quote.Id   AND SBQQ__Quote__r.SBQQ__Status__c != 'Approved' ];
    
    
    for(SBQQ__QuoteLine__c renwl : qliList){
        if(renwl.Quote_Line_Type__c == 'Renewal' && renwl.SBQQ__RequiredBy__c == null && renwl.SBQQ__Product__r.Eligible_for_RCDM_T__c &&  (renwl.Special_Program__c == null || renwl.Special_Program__c == '')) {
            mapClivsQli.put(renwl.SBQQSC__RenewedContractLine__c,renwl);
             
            configSKUCode1.add(renwl.SBQQ__Product__c);
            optionSKUCode1.add(System.Label.RCDM_ProductId);
            reqbyIdvsbndlno.put(renwl.id,renwl.SBQQ__Number__c);
        }else if(renwl.Quote_Line_Type__c == 'Renewal' && renwl.SBQQ__RequiredBy__c != null && renwl.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c!= null ){
        if(!reqbyIdvsbndlno.isEmpty() && reqbyIdvsbndlno.containsKey(renwl.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c)){
            reqbyIdvsbndlno.put(renwl.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,renwl.SBQQ__RequiredBy__r.SBQQ__Number__c);
           
        }
        }
    }
        keyProdOptionMap1 = returnAllProductOptions(configSKUCode1,optionSKUCode1);
        
        
        //check if renewal Line has RCDMT line on CLI
        
      for(ContractLineItem cli: [SELECT Id, Product2.Name,SBQQSC__RequiredById__c,EndDate FROM ContractLineItem WHERE SBQQSC__RequiredById__c IN: mapClivsQli.KeySet() and Product2.Name = 'RS-BT-RCDM-T'   ]){
                if(cli.EndDate < quote.RCDMT_EOL_Date__c && !mapClivsQli.isEmpty() &&  mapClivsQli.containsKey(cli.SBQQSC__RequiredById__c)){
                qlToaddRCDMT.add(mapClivsQli.get(cli.SBQQSC__RequiredById__c));
                bundlClivsRcdmCli.put(cli.SBQQSC__RequiredById__c,cli.Id);
            }
        }
        
        //logic to auto add RCDM-T
        if(qlToaddRCDMT.size() > 0){
            //Integer lineNumberrcdm = (Integer) qlToaddRCDMT[0].SBQQ__Quote__r.SBQQ__LineItemCount__c + 1;
        for(SBQQ__QuoteLine__c qle : qlToaddRCDMT){
            
        if(qle.SBQQ__Quote__r.Eligible_for_RCDM_T__c && !qle.SBQQ__Quote__r.Is_Customer_Fully_Transitioned__c  && qle.SBQQ__StartDate__c <= qle.SBQQ__Quote__r.RCDMT_EOL_Date__c && qle.SBQQ__Product__r.Eligible_for_RCDM_T__c)
            {
                   
                      
                      
                      SBQQ__QuoteLine__c rcdm = getRDCMTLine(qle.clone(),null,null);
                      if(!reqbyIdvsbndlno.isEmpty() && reqbyIdvsbndlno.containsKey(qle.Id)){
                         // rcdm.SBQQ__Number__c = lineNumberrcdm++;
                          rcdm.SBQQ__Number__c = reqbyIdvsbndlno.get(qle.Id)+1;
                      }
                     // SBQQ__QuoteLine__c rcdm = new SBQQ__QuoteLine__c();
                     // SBQQ__QuoteLine__c tempQLI = new SBQQ__QuoteLine__c(required_by_ext_Id__c =  qli.required_by_ext_Id__c);
                      rcdm.SBQQ__RequiredBy__c = qle.Id;
                     // rcdmQL.putSobject('SBQQ__RequiredBy__r', tempQLI);
                     // rcdmQL.required_by_ext_Id__c = qli.required_by_ext_Id__c+'RCDMT';
                      rcdm.SBQQ__Group__c = qle.SBQQ__Group__c;
                      rcdm.SBQQ__Quantity__c = qle.SBQQ__Quantity__c;
                      rcdm.SBQQ__StartDate__c = qle.SBQQ__StartDate__c;
                      rcdm.SBQQ__Quote__c = qle.SBQQ__Quote__c;
                      if(!bundlClivsRcdmCli.isEmpty()){
                          
                          rcdm.SBQQSC__RenewedContractLine__c = bundlClivsRcdmCli.get(qle.SBQQSC__RenewedContractLine__c);
                          rcdm.Arroyo_Subsumed_Old_Contract_Line_Items__c = bundlClivsRcdmCli.get(qle.SBQQSC__RenewedContractLine__c);
                          
                      }
                      
                      
                      if(qle.SBQQ__EndDate__c <= qle.SBQQ__Quote__r.RCDMT_EOL_Date__c){
                          
                          rcdm.SBQQ__EndDate__c = qle.SBQQ__EndDate__c;
                      }else {
                          
                          rcdm.SBQQ__EndDate__c = qle.SBQQ__Quote__r.RCDMT_EOL_Date__c;
                      }
                      rcdm.SubscribedAssetNames__c = qle.SubscribedAssetNames__c;
                      rcdm.RenewalQuantityPopulated__c =true;
                      rcdm.Subscribed_Asset_Name__c = qle.Subscribed_Asset_Name__c;
                      
                      rcdm.SBQQ__ProductOption__c = keyProdOptionMap1.get(qle.SBQQ__Product__c + '-' +System.Label.RCDM_ProductId);
                      
                      if(qle.SBQQ__OptionLevel__c == 0 || qle.SBQQ__OptionLevel__c == null){
                          rcdm.SBQQ__OptionLevel__c =1;
                          //optionLevel1Lines.add(rcdmQL);
                      } else if(qle.SBQQ__OptionLevel__c == 1){
                          rcdm.SBQQ__OptionLevel__c =2;
                          //optionLevel2Lines.add(rcdmQL);
                      }
                      
                      
                     insertRCDMT.add(rcdm); 
                      
                  }
        }
        }
        if(insertRCDMT.size() > 0){
            
            SBQQ.TriggerControl.disable();
            TriggerControls.disableQuoteLineTrigger = true;
            TriggerControls.disableQuoteTrigger = true;
            insert insertRCDMT;
            
            SBQQ.TriggerControl.enable();
            TriggerControls.disableQuoteLineTrigger = false;
            TriggerControls.disableQuoteTrigger = false;
        }
            
    }
    
    
/**
 * @description Handles conversion of quote lines with renewal type 'V2 To V2' in a given quote. 
 * @param quote The SBQQ__Quote__c record for which the V2 to V2 quote line conversion should be performed.
 * @param fromReplacementQLI A boolean flag indicating whether the conversion is triggered from a replacement quote line.
 * @param qlines The list of SBQQ__QuoteLine__c records to be converted.
 */
    public static void convertV2ToV2(SBQQ__Quote__c quote , Boolean fromReplacementQLI,List<SBQQ__QuoteLine__c> qlines){
        
        
        List<SBQQ__QuoteLine__c>  qliList = new  List<SBQQ__QuoteLine__c>();
        List<ID>  qliIds = new List<ID>();
        SBQQ__Quote__c quoteInScope;
        if(qlines != null && !qlines.isEmpty()){
            for (SBQQ__QuoteLine__c qls : qlines) {
            qliIds.add(qls.ID);
        }
        }
        
        try{
            String qLQuery = 'SELECT '  + String.join(getAllFieldsForClone(), ',' );
            qLQuery = qLQuery + ',SBQQ__ProductCode__c,SBQQ__Quote__r.SBQQ__PriceBook__c,SBQQSC__RenewedContractLine__r.Channel_Uplift__c,SBQQ__Quote__r.SBQQ__LineItemCount__c,SBQQSC__RenewedContractLine__r.Total_Price_Without_Promo__c,SBQQSC__RenewedContractLine__r.SBQQSC__ProrateMultiplier__c,SBQQSC__RenewedContractLine__r.SBQQSC__Quantity__c,SBQQ__RequiredBy__c,SBQQ__Product__r.Custom_Renewal_Product__c,SBQQ__Product__r.Custom_Renewal_Type__c,SBQQ__Product__r.Custom_Renewal_Product__r.Pricebook_Entry_Id__c,SBQQSC__RenewedContractLine__r.SBQQSC__RenewalQuantity__c,SBQQ__Product__r.Custom_Renewal_Product__r.Product_Level__c,SBQQ__Product__r.Custom_Renewal_Product__r.Approval_Category__c,SBQQ__Product__r.Custom_Renewal_Product__r.Description,SBQQSC__RenewedContractLine__r.Support_Type__c,SBQQ__Product__r.Custom_Renewal_Product__r.Support_Split_Percent__c,SBQQ__Product__r.Custom_Renewal_Product__r.Product_Type__c,SBQQ__Product__r.Custom_Renewal_Attributes__c,SBQQSC__RenewedContractLine__r.SBQQSC__Product__r.Support_Type__c,SBQQSC__RenewedContractLine__r.Payment_Options__c,SBQQSC__RenewedContractLine__r.SBQQSC__Product__r.Product_Payment_Option__c,SBQQSC__RenewedContractLine__r.Storage_Tier__c,SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Product__c,SBQQSC__RenewedContractLine__r.SBQQSC__Product__r.Storage_Tier__c, SBQQ__RequiredBy__r.SBQQ__Product__c,SBQQ__Product__r.License_per_Qty__c,SBQQSC__RenewedContractLine__r.Subscription_Term__c,SBQQ__Product__r.SBQQ__SubscriptionTerm__c, SBQQ__Quote__r.SBQQ__Type__c FROM SBQQ__QuoteLine__c WHERE ';
        if(fromReplacementQLI == FALSE){ 
            qLQuery +=    ' SBQQ__Quote__c =\''+ quote.Id +'\'' + ' AND SBQQ__Product__r.Custom_Renewal_Type__c = \'' + 'V2 To V2' + '\'' +' AND Quote_Line_Type__c = \'Renewal\'' + ' AND SBQQ__Optional__c = false' +' AND SBQQSC__RenewedContractLine__c != null AND Disposition_Reason__c =\'' +'Renewing' +'\'';
        }
        else{
            if(qliIds != null || !qliIds.isEmpty()){
                qLQuery +=    ' id IN :qliIds AND SBQQ__Product__r.Custom_Renewal_Type__c = \'V2 To V2\'' +' AND Quote_Line_Type__c = \'Renewal\'' + ' AND SBQQ__Optional__c = false' +' AND SBQQSC__RenewedContractLine__c != null AND Disposition_Reason__c =\'Renewing\'';
            /**
            qliList =  [SELECT id, SBQQ__Quote__r.SBQQ__PriceBook__c,SBQQ__PricebookEntryId__c,Product_Level__c,SBQQ__ProductCode__c, SBQQ__Quantity__c, SBQQ__StartDate__c, SBQQ__Quote__c, CPQ_Uplift__c, SBQQSC__RenewedContractLine__r.Channel_Uplift__c, SBQQ__Quote__r.SBQQ__LineItemCount__c,
                                                                SBQQSC__RenewedContractLine__c, SBQQSC__RenewedContractLine__r.Total_Price_Without_Promo__c, SBQQSC__RenewedContractLine__r.SBQQSC__ProrateMultiplier__c, SBQQSC__RenewedContractLine__r.SBQQSC__Quantity__c,SBQQ__RequiredBy__c,
                                                                SBQQ__Product__r.Custom_Renewal_Product__c,Product_Type__c, SBQQ__Product__r.Custom_Renewal_Type__c, SBQQ__Product__r.Custom_Renewal_Product__r.Pricebook_Entry_Id__c,SBQQSC__RenewedContractLine__r.SBQQSC__RenewalQuantity__c,
                                                                SBQQ__Product__r.Custom_Renewal_Product__r.Product_Level__c, SBQQ__Product__r.Custom_Renewal_Product__r.Approval_Category__c, SBQQ__Product__r.Custom_Renewal_Product__r.Description,SBQQSC__RenewedContractLine__r.Support_Type__c,
                                                                SBQQ__Product__r.Custom_Renewal_Product__r.Support_Split_Percent__c, SBQQ__Product__r.Custom_Renewal_Product__r.Product_Type__c, SBQQ__Product__r.Custom_Renewal_Attributes__c,SBQQSC__RenewedContractLine__r.SBQQSC__Product__r.Support_Type__c,SBQQSC__RenewedContractLine__r.Payment_Options__c,SBQQSC__RenewedContractLine__r.SBQQSC__Product__r.Product_Payment_Option__c,SBQQ__OptionLevel__c,
                        Replacement_Motion__c,SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Product__c,Support_Type__c,Replacement_Details__c,Arroyo_Subsumed_Old_Contract_Line_Items__c,SBQQ__EndDate__c,Disposition_Reason__c,SBQQ__Group__c,Storage_Tier__c, 
                        SBQQ__RequiredBy__r.SBQQ__Product__c,Support_Tier__c, Payment_Options__c, SBQQ__Product__r.License_per_Qty__c,Rubrik_Hosted_M365_Quantity__c,IsDiscCal__c, //FY25SR-1663
                        SubscribedAssetNames__c, Subscribed_Asset_Name__c, Flag_for_Discount__c, SBQQ__Discount__c
                                                                FROM SBQQ__QuoteLine__c 
                                                                WHERE id IN :qliIds AND  SBQQ__Product__r.Custom_Renewal_Type__c = 'V2 To V2' 
                                                                AND Quote_Line_Type__c = 'Renewal' AND  SBQQ__Optional__c=false AND
                                                                SBQQSC__RenewedContractLine__c != null];
                 */    
            }
        }
        
        qliList = Database.query(qLQuery);
        Map<String, ProdMapWrapper> prodWrapMap = new Map<String, ProdMapWrapper>();

        List<SBQQ__QuoteLine__c> quoteLinesRenewals = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> quoteLinesOld = new List<SBQQ__QuoteLine__c>();
        map<String,SBQQ__QuoteLine__c> parentRequiredByLines = new map<String,SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> childRequiredByLines = new  List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> grandChildLines = new  List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> grandParentLines = new  List<SBQQ__QuoteLine__c>();
        List<ID> parentHWLines = new  List<ID>();
        Map<Id, SBQQ__QuoteLine__c> oldGpToNewGpRecord = new Map<Id, SBQQ__QuoteLine__c>();
        Map<String, String> prodOptionMap = new Map<String, String>();
        Set<String> configSKU = new Set<String>();
        Set<String> optionSKU = new Set<String>();
        Map<String, String> DynamicOptionMap = new Map<String, String>();
        Integer lineNumber = (qliList !=null && !qliList.isEmpty()) ? (integer) qliList[0].SBQQ__Quote__r.SBQQ__LineItemCount__c + 1:1;
        set<String> prodCode = new set<String>();
        List<String> lstProductTypes = !String.isBlank(System.Label.CustomRenewalProductType) ? System.Label.CustomRenewalProductType.split(',') : null;
        Id Pricebookid;
        for (SBQQ__QuoteLine__c qli : qliList) {
            if(qli.SBQQ__RequiredBy__c != null) {
                configSKU.add(qli.SBQQ__RequiredBy__r.SBQQ__Product__c);
                if(qli.Product_Type__c == 'HW Support'){
                    grandChildLines.add(qli);
                    parentHWLines.add(qli.SBQQ__RequiredBy__c);
                }
            }
            if(qli.SBQQ__RequiredBy__c == null && qli.Product_Type__c == 'Hybrid Software'){
                grandParentLines.add(qli);
            }
            prodCode.add(qli.SBQQ__ProductCode__c);
            if(Pricebookid ==null){
                Pricebookid= qli.SBQQ__Quote__r.SBQQ__PriceBook__c;
            }
        }
        
        Map<Id,PricebookEntry> pricebookMap = new Map<Id,PricebookEntry> ([select id, UnitPrice from PricebookEntry where Pricebook2Id =: Pricebookid]);
        
        prodWrapMap = getProdMap(prodCode,'V2 To V2');
        for(Multi_Mapping_V2_Conversion__c mapping : getMultiMappings(prodCode,'V2 To V2')){
            if(mapping.Target_Product__c != null) {
                optionSKU.add(mapping.Target_Product__c);
                configSKU.add(mapping.Target_Product__c);
                configSKU.add(mapping.Source_Product__c);
            }
        }

        if (!configSKU.isEmpty() && !optionSKU.isEmpty()) {
            prodOptionMap = returnAllProductOptions(configSKU,optionSKU);
        }
        
        DynamicOptionMap = getProdFeature(configSKU, new List<string>{'R6000 Series - Rubrik Appliances'});
        for (SBQQ__QuoteLine__c qli : qliList) {
            quoteInScope = qli.SBQQ__Quote__r;
                if (qli.SBQQ__ProductCode__c == null) {
                    continue;
                }
                else{
                    // queue old line for removal
                    quoteLinesOld.add(qli);
                }

                // Get product mapping wrapper
                ProdMapWrapper wrap = prodWrapMap.get(qli.SBQQ__ProductCode__c);
                
                
                if(wrap == null) continue;
                // Build the key for split map`
                String supportType = qli.SBQQSC__RenewedContractLine__r.Support_Type__c == null? 
                    (qli.SBQQSC__RenewedContractLine__r.SBQQSC__Product__r.Support_Type__c == null ? qli.Support_Type__c : 
                     qli.SBQQSC__RenewedContractLine__r.SBQQSC__Product__r.Support_Type__c) : qli.SBQQSC__RenewedContractLine__r.Support_Type__c;
                
                String paymentOption = qli.SBQQSC__RenewedContractLine__r.Payment_Options__c == null? 
                    (qli.SBQQSC__RenewedContractLine__r.SBQQSC__Product__r.Product_Payment_Option__c == null ? qli.Payment_Options__c : 
                     qli.SBQQSC__RenewedContractLine__r.SBQQSC__Product__r.Product_Payment_Option__c) : 
                    qli.SBQQSC__RenewedContractLine__r.Payment_Options__c;

                String storageTier = qli.SBQQSC__RenewedContractLine__r.Storage_Tier__c == null? 
                    (qli.SBQQSC__RenewedContractLine__r.SBQQSC__Product__r.Storage_Tier__c == null ? qli.Storage_Tier__c : 
                     qli.SBQQSC__RenewedContractLine__r.SBQQSC__Product__r.Storage_Tier__c) : 
                    qli.SBQQSC__RenewedContractLine__r.Storage_Tier__c;

                String mappingKey =  String.isNotBlank(storageTier) && storageTier.contains('GB') ? qli.SBQQ__ProductCode__c + storageTier.replaceAll('\\s+', '').replace('GB', '') + supportType + paymentOption :
                qli.SBQQ__ProductCode__c + storageTier + supportType + paymentOption;
                
                
                if (!wrap.splitMapRecordsWithOldSKU.containsKey(mappingKey)) {
                    continue;
                    
                }
            

                List<Multi_Mapping_V2_Conversion__c> mappings = wrap.splitMapRecordsWithOldSKU.get(mappingKey);
                Decimal totalUnitPrice = 0;
                Decimal licensePerQuantity = (String.isBlank(qli.Product_Level__c)  && qli.SBQQ__Product__r.License_per_Qty__c != null) ? qli.SBQQ__Product__r.License_per_Qty__c : 1;
               
                for (Multi_Mapping_V2_Conversion__c mapping : mappings) {


                    if (mapping.Target_Product__c == null ) {
                        continue;
                    }
                  
                    if(pricebookMap.get(mapping.Target_Product__r.Pricebook_Entry_Id__c) !=null){
                        if (mapping.Quantity_Multiplier__c != null && mapping.Quantity_Multiplier__c != 1 ) {
                            totalUnitPrice += pricebookMap.get(mapping.Target_Product__r.Pricebook_Entry_Id__c).UnitPrice * mapping.Quantity_Multiplier__c * licensePerQuantity;
                        }else{
                            totalUnitPrice +=  pricebookMap.get(mapping.Target_Product__r.Pricebook_Entry_Id__c).UnitPrice * licensePerQuantity;
                        }
                    } else{
                        continue;
                    }
                }
                for (Multi_Mapping_V2_Conversion__c mapping : mappings) {
                
            if(totalUnitPrice !=null){
                    /*if (mapping.Target_Product__c == null ) {
                    continue;
                    }
                    */
                    
                    SBQQ__QuoteLine__c renewalLine = qli.clone();

                    renewalLine.EOL_Date__c = null;
                    renewalLine.End_of_Renewals_Date__c = null; //CPQ22-6396
                    renewalLine.EOL_Final_Renewal_Date__c = null;

                    if(qli.SBQQ__Product__c == mapping.Source_Product__c){
                        
                    renewalLine = cloneQuoteLineIns(qli, renewalLine, null, mapping, null, null);
                    renewalLine.Disposition_Reason__c = 'Renewing';
                    renewalLine.Support_Type__c = mapping.Target_Product__r.Support_Type__c;                //Added as part of ITNPI-3373
                    renewalLine.SBQQ__PricebookEntryId__c = mapping.Target_Product__r.Pricebook_Entry_Id__c;
                    if(mapping.Option_Level__c != null && mapping.Option_Level__c != 0){
                        childRequiredByLines.add(renewalLine);
                    
                    }
                    else{
                        parentRequiredByLines.put(renewalLine.SBQQSC__RenewedContractLine__c+'_'+qli.SBQQ__SubscriptionTerm__c,renewalLine);//ITNPI-2782
                    }
                   
                    //renewalLine = resetQuoteLineFields(renewalLine,qli,mapping);
                    
                    renewalLine.SBQQ__ProductOption__c = prodOptionMap != null && qli.SBQQ__RequiredBy__c != null && prodOptionMap.containsKey(qli.SBQQ__RequiredBy__r.SBQQ__Product__c + '-' + renewalLine.SBQQ__Product__c) ? prodOptionMap.get(qli.SBQQ__RequiredBy__r.SBQQ__Product__c + '-' + renewalLine.SBQQ__Product__c) : null;
                    renewalLine.SBQQ__OptionLevel__c =  renewalLine.SBQQ__ProductOption__c !=null ?  renewalLine.SBQQ__OptionLevel__c : 0;
                    if(renewalLine.Product_Level__c == 'Hybrid Software'){
                        oldGpToNewGpRecord.put(qli.Id, renewalLine);
                        renewalLine.SBQQ__OptionLevel__c = 0;
                    }
                    
                    renewalLine.SBQQ__Number__c = lineNumber++;
                    if(renewalLine.Product_Type__c == 'HW Support' && fromReplacementQLI == FALSE){
                        
                        SBQQ__QuoteLine__c hardwareLine = new SBQQ__QuoteLine__c(
                        Id = renewalLine.SBQQ__RequiredBy__c,
                        SBQQ__DynamicOptionId__c = DynamicOptionMap.get(renewalLine.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Product__c+'-'+'R6000 Series - Rubrik Appliances') + ':' + renewalLine.SBQQ__Product__c
                        );
                        renewalLine.SBQQ__OptionLevel__c = 2;
                        quoteLinesRenewals.add(hardwareLine);
                        renewalLine.SBQQ__OptionType__c = 'Related Product';
                    }
                    
                    renewalLine.Do_not_Renew__c = String.isNotBlank(qli.Product_Type__c) && lstProductTypes != null && lstProductTypes.contains(qli.Product_Type__c) ? true:false;///ITNPI-3207
                    
                    //renewalLine.Previous_Quantity_Value__c = renewalLine.SBQQ__Quantity__c;
                    // Pricing logic (retained)
                    applyPricingAndDiscount(qli,mapping,renewalLine, totalUnitPrice, pricebookMap);
                    /**Logic to handle old RBK v1 SKUs and handle the license per quantity */
                    //renewalLine.IsDiscCal__c  = ( licensePerQuantity != 1 ) ? true : renewalLine.IsDiscCal__c;
                    renewalLine.SBQQ__Quantity__c *=licensePerQuantity;
                    renewalLine.Rubrik_Hosted_M365_Quantity__c = mapping.Enable_M365_Quantity__c == false ? renewalLine.Rubrik_Hosted_M365_Quantity__c : renewalLine.SBQQ__Quantity__c;
                    renewalLine.Storage_Tier__c = (String.isNotBlank(renewalLine.Storage_Tier__c) && renewalLine.Storage_Tier__c !='None') ? '' : renewalLine.Storage_Tier__c;
                    renewalLine.SBQQ__ProrateMultiplier__c = null; 
                    quoteLinesRenewals.add(renewalLine);
                    }
            }     
            else{
                continue;
            }
                }
                
            }
            upsertAndDeleteQuoteLines(quoteLinesRenewals,quoteLinesOld,childRequiredByLines,parentRequiredByLines,prodOptionMap,oldGpToNewGpRecord,parentHWLines);
                if (Test.isRunningTest() && forceTestException) {
                    throw new MyCustomException('Forced exception for testing.');
                }
            } catch (Exception e) {
                Renewal_Conversion_Status__c rcs1 = new Renewal_Conversion_Status__c();
                if (quoteInScope != null) {
                    rcs1.Quote__c = quoteInScope.Id;
                    rcs1.Status__c = 'Failed';
                    rcs1.Fail_Reason__c = e.getStackTraceString() + '-' + e.getMessage();
                    //rcs1.Fail_Reason__c=e.getMessage();
                    insert rcs1;
                }
}

    }
    /**
 * @description 
 * Retrieves a list of active Multi_Mapping_V2_Conversion__c records for the given source product codes and renewal type.
 * @param sourceProds Set of source product codes to retrieve mappings for.
 * @param renewalType The renewal type filter. Used to optionally filter only active mappings.
 * @return List of Multi_Mapping_V2_Conversion__c records matching the provided criteria.
 */
 public static List<Multi_Mapping_V2_Conversion__c> getMultiMappings(Set<String> sourceProds, String  renewalType) {
        
        // Field list (superset of both queries)
        String fields = String.join(new List<String>{
            'Id',
            'Option_Level__c',
            'Storage_Tier__c',
            'Quantity_Multiplier__c',
            'Active__c',
            'Support_Tier__c',
            'Target_Product__r.SBQQ__SubscriptionTerm__c',
            'Payment_Option__c',
            'Target_Product__r.Product_Level__c',
            'Target_Product__r.Eligible_for_RCDM_T__c',
            'Target_Product__r.Product_Type__c',
            'Target_Product__r.Product_Subtype__c',
            'Target_Product__r.Support_Type__c',             //Added as part of ITNPI-3373
            'Pricing_Percent__c',
            'Source_Product__r.ProductCode',
            'Source_Product__c',
            'Support_Type__c',
            'Renewal_Type__c',
            'Target_Product__c',
            'Target_Product__r.ProductCode',
            'Feature_Name_on_New_Product__c',
            'Target_Product__r.Description',
            'Target_Product__r.Sales_Comp_Category__c',
            'Target_Product__r.Pricebook_Entry_Id__c',
            'Target_Product__r.Approval_Category__c',
            'Enable_M365_Quantity__c',
            'Parent_Record__c'
        }, ',');

        // Start base query
        String soql = 'SELECT ' + fields +
                    ' FROM Multi_Mapping_V2_Conversion__c WHERE Source_Product__r.ProductCode IN :sourceProds AND Renewal_Type__c = :renewalType';
        // Add Active filter if requested
        if (renewalType == 'V2 To V2') {
            soql += ' AND  Active__c = true';
        }

        // Order by
        soql += ' ORDER BY Option_Level__c';
        // Execute query
        //return Database.query(soql);
        return Database.query(soql);
    }

    /**
 * @description
 * Performs DML operations for renewal quote lines. Inserts the new renewal lines and deletes the old quote lines.
 *
 * @param renewalLines List of new SBQQ__QuoteLine__c 
 * @param oldLines List of existing SBQQ__QuoteLine__c 
 * @param childRequiredByLines List of newly created SBQQ__QuoteLine__c 
 * @param parentLinesMap map of Cotnract lines with the new SBQQ__QuoteLine__c 
 * @param prodOptionMap map of productionOption  
 * @param oldGpToNewGpRecord map of old GP to new GP
 * @param parentIds List of parent ids
 */
    private static void upsertAndDeleteQuoteLines(List<SBQQ__QuoteLine__c> renewalLines, List<SBQQ__QuoteLine__c> oldLines, List<SBQQ__QuoteLine__c> childRequiredByLines, map<String,SBQQ__QuoteLine__c> parentLinesMap, Map<String, String> prodOptionMap,Map<Id, SBQQ__QuoteLine__c> oldGpToNewGpRecord ,List<ID> parentIds) {
        if(renewalLines.isEmpty()){
                return;
            }
        SBQQ.TriggerControl.disable();
        TriggerControls.disableQuoteLineTrigger = true;
        TriggerControls.disableQuoteTrigger = true;

        upsert renewalLines;
        Map<Id, SBQQ__QuoteLine__c> parents = new Map<Id, SBQQ__QuoteLine__c>(
            [SELECT Id, SBQQ__RequiredBy__c FROM SBQQ__QuoteLine__c WHERE Id IN :parentIds]
        );
        
        Map<Id, Id> oldGpToNewId = new Map<Id, Id>();
            for (SBQQ__QuoteLine__c oldGp : oldLines) {
                if(oldGp.Product_Level__c == 'Hybrid Software'){
            		SBQQ__QuoteLine__c inserted = oldGpToNewGpRecord.get(oldGp.Id);
            		if(inserted != null && inserted.Id != null) {
                		oldGpToNewId.put(oldGp.Id, inserted.Id);
             		}
           		}
        	}
        
        /** Logic to handle Required by for the child lines and set product option value on them */
        for(SBQQ__QuoteLine__c childLines:childRequiredByLines ){
String cliSubscriptionKey = childLines.SBQQSC__RenewedContractLine__c+'_'+childLines.SBQQ__SubscriptionTerm__c;//ITNPI-2782
            childLines.SBQQ__RequiredBy__c = parentLinesMap.containsKey(cliSubscriptionKey) ? parentLinesMap.get(cliSubscriptionKey).Id:childLines.SBQQ__RequiredBy__c;
            childLines.SBQQ__ProductOption__c = parentLinesMap.containsKey(cliSubscriptionKey) ? prodOptionMap.get(parentLinesMap.get(cliSubscriptionKey).SBQQ__Product__c +'-'+childLines.SBQQ__Product__c) :null;
            childLines.SBQQ__OptionLevel__c = parentLinesMap.containsKey(cliSubscriptionKey) ? parentLinesMap.get(cliSubscriptionKey).SBQQ__OptionLevel__c +1:childLines.SBQQ__OptionLevel__c;      
        }
                
        for (SBQQ__QuoteLine__c parentRec : parents.values()) {
            Id oldGpId = parentRec.SBQQ__RequiredBy__c;
            if (oldGpId != null && oldGpToNewId.containsKey(oldGpId)) {
                parentRec.SBQQ__RequiredBy__c = oldGpToNewId.get(oldGpId);
                childRequiredByLines.add(parentRec);
            }
        }
        delete oldLines;
        update childRequiredByLines;

        SBQQ.TriggerControl.enable();
        TriggerControls.disableQuoteLineTrigger = false;
        TriggerControls.disableQuoteTrigger = false;
    }
    
    /**
 * @description
 * Applies pricing adjustments and discount calculations to a renewal quote line based on the original quote line
 * 
 * @param qli The original SBQQ__QuoteLine__c record representing the current quote line.
 * @param mapping The Multi_Mapping_V2_Conversion__c record used to map old product to new product details.
 * @param renewalLine The new SBQQ__QuoteLine__c record to which pricing and discount values are applied.
 * @param totalUnitPrice The total calculated unit price from all mapped target products.
 * @param pricebookMap A map of PricebookEntry records keyed by their Id for price lookup.
 */
    private static void applyPricingAndDiscount(SBQQ__QuoteLine__c qli, Multi_Mapping_V2_Conversion__c mapping, SBQQ__QuoteLine__c renewalLine, Decimal totalUnitPrice, Map<Id, PricebookEntry> pricebookMap) {
        if (!pricebookMap.containsKey(renewalLine.SBQQ__PriceBookEntryId__c) || qli.SBQQSC__RenewedContractLine__c == null) 
            return;

        Decimal uplift = (qli.CPQ_Uplift__c != null ? Decimal.valueOf(qli.CPQ_Uplift__c) : 0) / 100;
        uplift += qli.SBQQSC__RenewedContractLine__r.Channel_Uplift__c != null ? qli.SBQQSC__RenewedContractLine__r.Channel_Uplift__c : 0;
        Decimal unitPrice = (
            (qli.SBQQSC__RenewedContractLine__r.Total_Price_Without_Promo__c /
            qli.SBQQSC__RenewedContractLine__r.SBQQSC__ProrateMultiplier__c) /
            qli.SBQQSC__RenewedContractLine__r.SBQQSC__Quantity__c
        ) * (1 + uplift);
        Decimal listPrice = pricebookMap.get(renewalLine.SBQQ__PriceBookEntryId__c).UnitPrice;
        
        if(!qli.IsDiscCal__c || qli.SBQQ__Discount__c ==null){
            renewalLine.SBQQ__Discount__c = (totalUnitPrice != null && unitPrice !=null && totalUnitPrice > unitPrice) ? ((totalUnitPrice - unitPrice) / totalUnitPrice) * 100 : 0 ;
        }
        
        renewalLine.SBQQ__ListPrice__c = (renewalLine.SBQQ__ListPrice__c == null) ? pricebookMap.get(mapping.Target_Product__r.Pricebook_Entry_Id__c).UnitPrice : renewalLine.SBQQ__ListPrice__c;
        renewalLine.Flag_for_Discount__c = true;
        renewalLine.IsDiscCal__c = true;
    }
    /**
     * @description
     * Populates the Prior Net Total field on a quote line based on the renewal line's calculated values.
     * @param quoteLine The SBQQ__QuoteLine__c record representing the quote line.
     * @param qliListTotal A map containing the total unit price for each quote line.
     * @param cliKeyQLIMapping A map containing the CLI key to QLI mapping.
     */
    public static void populatePriorNetTotalOnQuoteLine(SBQQ__QuoteLine__c quoteLine, Map<Id, Decimal> qliListTotal,Map<String,String> cliKeyQLIMapping) {
        Decimal uplift = (quoteLine.CPQ_Uplift__c != null ? Decimal.valueOf(quoteLine.CPQ_Uplift__c) : 0) / 100;
        uplift += quoteLine.SBQQSC__RenewedContractLine__r.Channel_Uplift__c != null ? quoteLine.SBQQSC__RenewedContractLine__r.Channel_Uplift__c : 0;
        Decimal priorNetTotal = 0;
        Decimal pMultiplier = quoteLine.SBQQ__ProrateMultiplier__c;
        Decimal unitP = quoteLine.SBQQ__ListPrice__c;
        Decimal pntRatio = 0;
         
        //Store Prior Net Total initial value
        if (quoteLine.Do_not_Renew__c) {
            String cliKey = quoteLine.SBQQSC__RenewedContractLine__c != null ? quoteLine.SBQQSC__RenewedContractLine__c + '_' + quoteLine.SBQQ__ProrateMultiplier__c : null;///ITNPI-3207 //SAL26-1343 replaced subscription term with prorate multiplier
            string qlineKey = quoteLine.SBQQ__RequiredBy__c != null && quoteLine.SBQQ__ProductOption__c!=null && quoteLine.SBQQ__ProductOption__r.Refresh_Default_Option__c ? quoteLine.SBQQ__RequiredBy__c :(cliKeyQLIMapping!=null && cliKeyQLIMapping.containsKey(cliKey) ?cliKeyQLIMapping.get(cliKey):quoteLine.Id);//ITNPI-3207
            if(!qliListTotal.isEmpty() && qliListTotal !=null && qliListTotal.containsKey(qlineKey) && qliListTotal.get(qlineKey) != null){
                pntRatio = (quoteLine.SBQQ__ListPrice__c * quoteLine.SBQQ__Quantity__c)/qliListTotal.get(qlineKey);
            }
            //quoteLine.Prior_Net_Total__c = (quoteLine.Prior_Net_Total__c * pntRatio).setscale(2);
            
            //Calculate Prior ACV With Uplift
            quoteLine.PriorACVwithUplift__c = (quoteLine.PriorACVwithUplift__c == null || quoteLine.PriorACVwithUplift__c == 0)? ((((quoteLine.SBQQSC__RenewedContractLine__r.Total_Price_Without_Promo__c + (quoteLine.SBQQSC__RenewedContractLine__r.Total_Price_Without_Promo__c * uplift)) / ( quoteLine.SBQQSC__RenewedContractLine__r.SBQQSC__ProrateMultiplier__c / quoteLine.SBQQ__Product__r.SBQQ__SubscriptionTerm__c)) * ((pMultiplier/quoteLine.SBQQ__ProrateMultiplier__c)*12))) : quoteLine.PriorACVwithUplift__c; //SAL26-1343 replaced subscription term with prorate multiplier
            quoteLine.PriorACVwithUplift__c = quoteLine.PriorACVwithUplift__c!=null ? (quoteLine.PriorACVwithUplift__c * pntRatio).setscale(2):0 ;
            //Calculate RTA Without Uplift
            quoteLine.RTAwithoutUplift__c = (quoteLine.RTAwithoutUplift__c == null || quoteLine.RTAwithoutUplift__c == 0) ? ((quoteLine.SBQQSC__RenewedContractLine__r.Total_Price_Without_Promo__c / (quoteLine.SBQQSC__RenewedContractLine__r.SBQQSC__ProrateMultiplier__c /quoteLine.SBQQ__Product__r.SBQQ__SubscriptionTerm__c)/quoteLine.SBQQ__Product__r.SBQQ__SubscriptionTerm__c) * 12) : quoteLine.RTAwithoutUplift__c; //SAL26-1343 replaced subscription term with prorate multiplier
            quoteLine.RTAwithoutUplift__c = quoteLine.RTAwithoutUplift__c!=null?(quoteLine.RTAwithoutUplift__c * pntRatio).setscale(2):0;
            //Calculate Prior Net Total With Uplift
            quoteLine.Prior_Net_Total_With_Uplift__c = (quoteLine.Prior_Net_Total_With_Uplift__c == null || quoteLine.Prior_Net_Total_With_Uplift__c == 0) ? (((quoteLine.SBQQSC__RenewedContractLine__r.Total_Price_Without_Promo__c + (quoteLine.SBQQSC__RenewedContractLine__r.Total_Price_Without_Promo__c * uplift)) / ( quoteLine.SBQQSC__RenewedContractLine__r.SBQQSC__ProrateMultiplier__c / quoteLine.SBQQ__Product__r.SBQQ__SubscriptionTerm__c)) * pMultiplier) : quoteLine.Prior_Net_Total_With_Uplift__c; //SAL26-1343 replaced subscription term with prorate multiplier
            quoteLine.Prior_Net_Total_With_Uplift__c = quoteLine.Prior_Net_Total_With_Uplift__c!=null?(quoteLine.Prior_Net_Total_With_Uplift__c * pntRatio).setscale(2):0;
            //Calculate Discount Margin and DMA
            //quoteLine.Discount_Margin__c = quoteLine.Prior_Net_Total__c != 0 && quoteLine.SBQQ__NetTotal__c!=null? (quoteLine.SBQQ__NetTotal__c - quoteLine.Prior_Net_Total__c) / quoteLine.Prior_Net_Total__c : 0;
            //quoteLine.DMA__c = quoteLine.SBQQ__NetTotal__c!=null && quoteLine.Prior_Net_Total__c!=null?(quoteLine.SBQQ__NetTotal__c - quoteLine.Prior_Net_Total__c):0;
        }
    }
    /**
     * @description
     * Custom exception class for handling specific errors within the batch process.
     */
    public class MyCustomException extends Exception {
    
    }

}