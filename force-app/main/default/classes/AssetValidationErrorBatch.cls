/**
* @Description        : This is the Batch class which which will sent out a CSV file where approved/In-Review Quotelines with Asset Details Mismatch are present. The batch runs twice a week.
* @Author             : Madhura
* Ver       Date            Author                 Modification
* 1.0      12-16-2024       Madhura                Intial Draft
**/ 

global class AssetValidationErrorBatch implements Database.Batchable < sObject > , Schedulable, Database.Stateful {
    
    public List <SBQQ__QuoteLine__c> quoteLineIds = new List <SBQQ__QuoteLine__c>();
    public Map <Id, String> mapQliError = new Map <Id, String>();
    //List <Batch_Error_Log__c> batchErrLogList = new List <Batch_Error_Log__c>();
    //List <Batch_Error_Log__c> batchErrLogListExisting = new List <Batch_Error_Log__c>();
    public Id recordId;
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        /*DateTime aDate = System.now();
System.debug(aDate);
String lastModifed = String.valueOf(DateTime.newInstance(aDate.date().addDays(-15), aDate.time()));
lastModifed =lastModifed + 'T';*/
        
        //String  lastModifed = System.Label.last_Modified_Date;
        String lastModifed = String.valueOf(System.Today().addDays(-15));
        lastModifed = lastModifed + 'T00:00:00Z';
        System.debug('Here : ' + lastModifed);
        //DateTime   md =    DateTime.valueOfGMT(lastModifed);
        String review = 'In Review';
        String approved = 'Approved';
        String lineType = 'Renewal';
        String query = '';
        ///*and LastModifiedDate >=  \'' +md+ '\'*/
        /* query = 'Select Id, SBQQ__Quantity__c, SBQQ__ProductFamily__c, Arroyo_Subsumed_Old_Contract_Line_Items__c, SBQQSC__RenewedContractLine__c,
Arroyo_Subscribed_Asset_Name__c, SubscribedAssetNames__c, SBQQ__Quote__r.SBQQ__Primary__c, SBQQ__Quote__r.Opportunity_Stage__c, Special_Program__c, Subscribed_Asset_Name__c, RWD_Sales_Rep_Exception__c, RWD_Deal_Ops_Exception__c,
SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Product_Type__c, SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Item_Type__c,
SBQQ__RequiredBy__r.SBQQ__Product__r.Item_Type__c, SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Type__c, SBQQ__Product__r.Rel_SubsAsst__c,
(select id, SBQQ__Product__r.Usable_Capacity__c, SBQQ__Quantity__c from SBQQ__Quote_Lines__r where(SBQQ__Product__r.Product_Level__c = 'Hardware'
AND SBQQ__Product__r.Product_Type__c = 'Hardware') OR(SBQQ__Product__r.Product_Type__c = 'Add-On Node'
AND SBQQ__Product__r.Item_Type__c = 'Non-inventory Item'))
From SBQQ__QuoteLine__c where Quote_Line_Type__c = 'Renewal'
and SBQQ__Quote__r.SBQQ__Status__c = 'In Review'
and((NOT(Disposition_Reason__c IN('Renew Later'))) OR Special_Program__c != null) and SBQQ__Optional__c = false and product_level__c != null and SBQQ__Product__r.Rel_SubsAsst__c = 'Renew:RelatedAsset'
and LastModifiedDate > lastModifed'*/
        
        query ='select Id,Family_and_ProductLevel__c,License_Subtype__c,SBQQ__RenewedAsset__c,SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Product_Type__c,'
            + 'SBQQSC__RenewedContractLine__r.Product2.Name,SBQQSC__RenewedContractLine__r.Product2Id,SBQQ__Product__r.Product_Subtype__c,SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Name,'
            + 'SBQQSC__RenewedContractLine__r.Product2.Product_Level__c,DiscJustiReq__c,Sales_Comp_Category__c,Product_Subtype__c,SBQQSC__RenewedContractLine__c,'
            + 'SBQQ__Quote__r.SBQQ__Type__c,SBQQ__Quote__r.Co_Term__c,Subscribed_Asset_Name__c,SBQQ__Quote__r.RWD_Deal_Ops_Exception__c,Special_Program__c,SBQQ__RequiredBy__r.Licensing_Model__c,'
            + 'SBQQ__SubscribedAssetIds__c,Arroyo_Subsumed_Old_Contract_Line_Items__c,SBQQ__StartDate__c,SBQQ__Product__c,SBQQ__Product__r.Product_Level__c,'
            + 'SBQQ__Product__r.Eligible_for_RCDM_T__c,SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,SBQQ__RequiredBy__r.Quote_Line_Type__c,SBQQ__RequiredBy__r.SBQQ__Quantity__c,'
            + 'SBQQ__RequiredBy__r.Disposition_Reason__c,Scale_Utility_Product__c,EOL_Product_Status__c, SBQQ__EffectiveStartDate__c,SBQQ__Product__r.Rel_SubsAsst__c,'
            + 'SBQQ__RequiredBy__r.SBQQ__ProductCode__c, SBQQ__EffectiveEndDate__c, SBQQ__ProductCode__c,SBQQ__ProductFamily__c,Product_Type__c,SBQQ__Discount__c,'
            + 'Add_on_Level__c,Line_Type__c,Required_By_Product_Code__c,SBQQ__RequiredBy__c,SBQQ__RequiredBy__r.SBQQ__Product__r.Category__c, SBQQ__Product__r.X0__c, '
            + 'SubscribedAssetNames__c,SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Category__c,SBQQSC__RenewedContractLine__r.SBQQSC__Product__r.Product_Level__c,'
            + 'SBQQ__ListPrice__c,SBQQ__ProratedListPrice__c,SBQQ__ListTotal__c,Licensing_Model__c,SBQQ__Product__r.Is_Attributes_Blank__c,SBQQ__Product__r.SBQQ__ExcludeFromOpportunity__c,'
            + 'SBQQ__Source__c,TPH_Models_Gen__c,TPH_Drive_Size__c,TPH_OEM__c,TPH_Quantity__c,SBQQ__Existing__c,SBQQ__EffectiveQuantity__c,SBQQ__Optional__c,SBQQ__AdditionalDiscountAmount__c,'
            + 'SBQQ__EndDate__c, SBQQ__SubscriptionPricing__c, Quote_Line_Type__c,  QuoteLine_Group_Name__c, Disposition_Reason__c, Check_of_POLARIS_Hardware__c, Check_of_ASPEN_Hardware__c, '
            + 'SKU_Type__c, License_Category__c, SBQQ__Product__r.License_Category__c, Product_Level__c,SBQQ__Quantity__c,Replace_By__c,SBQQ__Group__c,SBQQ__Group__r.Name,'
            + 'PRE_Promo_Expiration_Date__c,Promo_Code__c,List_Price_Update__c,Target_NetTotal__c,SBQQ__NetTotal__c,Wrapper_Line__c,Storage_Tier__c,SBQQSC__RenewedContractLine__r.Required_by_Product_Code__c,'
            + 'SBQQ__OptionType__c,SBQQ__Product__r.IsHardwareNotRequiredForHybridLicense__c,SBQQ__RequiredBy__r.Product_Type__c,SBQQ__RequiredBy__r.Arroyo_Subsumed_Old_Contract_Line_Items__c,'
            + 'SBQQ__RequiredBy__r.Subscribed_Asset_Name__c,SBQQ__RequiredBy__r.SubscribedAssetNames__c,SBQQ__RequiredBy__r.SBQQ__Optional__c,SBQQ__RequiredBy__r.SBQQ__Existing__c,'
            + 'SBQQSC__RenewedContractLine__r.AMER_FED_Exception__c, SBQQ__RequiredBy__r.Ary_Product_Type__c, SBQQ__Product__r.Sales_Comp_Category__c, SBQQ__Product__r.Product_Master_Id__c,'
            + 'SBQQ__Product__r.Restrict_Quoting_For__c, SBQQ__RequiredBy__r.SBQQ__Product__c, SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Product__c, SBQQ__RequiredBy__r.SBQQ__Product__r.Restrict_Quoting_For__c'
            + ', SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Restrict_Quoting_For__c, Upgrade_Path__c,Account_s_Entitlement__c,SBQQ__RequiredBy__r.Product_Level__c'
            + ',SBQQ__RequiredBy__r.SBQQ__ProductFamily__c, Edition__c, SBQQ__Product__r.Bundle_Features__c'
            + ' from SBQQ__QuoteLine__c where (SBQQ__Quote__r.SBQQ__Status__c =  \'' +review+ '\' OR  SBQQ__Quote__r.SBQQ__Status__c = \'' +approved+ '\' ) and LastModifiedDate > ' +lastModifed+ ' ';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List < SBQQ__QuoteLine__c > quotelineRecs) {
        List < String > subsasstNames = new List < String > ();
        Set < String > asstNames = new Set < String > ();
        Map < Id, List < String >> qlIdSrnoMap = new Map < id, List < String >> ();
        Map < String, Double > assIdCapacity = new Map < String, Double > ();
        Map < Id, List < String >> mapReqIdandSrno = new Map < id, List < String >> ();
        Map < Id, List < String >> mapPerpRscandSrno = new Map < id, List < String > > ();
        Map < Id, List < String >> mapScaleSubsum = new map < Id, List < String >> ();
        Map < Id, String > mapTPHrenwCLI = new map < Id, String > ();
        List < String > splitSubs = new List < String > ();
        String validationMSG;
        Boolean isTPHreplaced = false;
        List < Integer > indexToRemove = new List < Integer > ();
        System.debug('show result>' + quotelineRecs);
        
        ShGl_DisableFunctionalityLogic__c disablAssetValidation = ShGl_DisableFunctionalityLogic__c.getInstance();
        Boolean disable = disablAssetValidation.Disable_Asset_Validation__c;
        
        try{
            //Start : Added logic to bypass this validation for virtual addon and TPH as part of CPQ22-3838
            //Copy the records to new list
            if (!quotelineRecs.isEmpty()) {
                List < SBQQ__QuoteLine__c > filterQuoteLineRecs = new List < SBQQ__QuoteLine__c > (quotelineRecs);
                System.debug('show result filterQuoteLineRecs >' + filterQuoteLineRecs.size());
                
                for (Integer ql = 0; ql < filterQuoteLineRecs.size(); ql++) {
                    System.debug('ql.SBQQ__ProductCode__c' + filterQuoteLineRecs[ql].SBQQ__ProductCode__c);
                    System.debug('ql.SBQQSC__RenewedContractLine__r.Product2Id' + filterQuoteLineRecs[ql].SBQQSC__RenewedContractLine__r.Product2Id);
                    System.debug('ql.Product_Type__c ' + filterQuoteLineRecs[ql].Product_Type__c);
                    System.debug('ql.SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Name' + filterQuoteLineRecs[ql].SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Name);
                    
                    if (
                        ((filterQuoteLineRecs[ql].Product_Type__c == 'HW Support' || filterQuoteLineRecs[ql].Product_Type__c == 'RCDM Support' || filterQuoteLineRecs[ql].SBQQ__Product__r.Product_Subtype__c == 'LOD Addon') &&
                         filterQuoteLineRecs[ql].SBQQ__RequiredBy__c == null &&
                         filterQuoteLineRecs[ql].SBQQSC__RenewedContractLine__c != null &&
                         filterQuoteLineRecs[ql].SBQQSC__RenewedContractLine__r.Product2Id != null &&
                         ((
                             filterQuoteLineRecs[ql].SBQQSC__RenewedContractLine__r.Product2.Name.contains('RCDM-HPE') ||
                             filterQuoteLineRecs[ql].SBQQSC__RenewedContractLine__r.Product2.Name.contains('RCDM-DELL') ||
                             filterQuoteLineRecs[ql].SBQQSC__RenewedContractLine__r.Product2.Name.contains('RCDM-UCS') ||
                             filterQuoteLineRecs[ql].SBQQSC__RenewedContractLine__r.Product2.Name.contains('RCDM-ELA')) ||
                          ((filterQuoteLineRecs[ql].SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Product_Type__c == 'Add-On Node' &&
                            !filterQuoteLineRecs[ql].SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Name.contains('-HW-')) || (filterQuoteLineRecs[ql].SBQQSC__RenewedContractLine__r.Required_by_Product_Code__c != null &&
                                                                                                                                            filterQuoteLineRecs[ql].SBQQSC__RenewedContractLine__r.Required_by_Product_Code__c.contains('-ADDON-NODE-') &&
                                                                                                                                            !filterQuoteLineRecs[ql].SBQQSC__RenewedContractLine__r.Required_by_Product_Code__c.contains('-HW-')))
                         )) || // for RSC lines 
                        (filterQuoteLineRecs[ql].Product_Level__c == 'Hybrid Software' &&
                         filterQuoteLineRecs[ql].SBQQ__RequiredBy__c == null &&
                         filterQuoteLineRecs[ql].SBQQSC__RenewedContractLine__c != null &&
                         ((filterQuoteLineRecs[ql].SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Product_Type__c == 'Add-On Node' &&
                           !filterQuoteLineRecs[ql].SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Name.contains('-HW-')) || (filterQuoteLineRecs[ql].SBQQSC__RenewedContractLine__r.Required_by_Product_Code__c != null &&
                                                                                                                                           filterQuoteLineRecs[ql].SBQQSC__RenewedContractLine__r.Required_by_Product_Code__c.contains('-ADDON-NODE-') &&
                                                                                                                                           !filterQuoteLineRecs[ql].SBQQSC__RenewedContractLine__r.Required_by_Product_Code__c.contains('-HW-'))))
                    ) {
                        System.debug('Inside If 3838');
                        
                        //store index for unwanted lines
                        indexToRemove.add(filterQuoteLineRecs.indexOf(filterQuoteLineRecs[ql]));
                        
                        //SBQQ__QuoteLine__c index =  quotelineRecs.remove(filterQuoteLineRecs.indexOf(filterQuoteLineRecs[ql]));                        
                    }
                }
            }
            indexToRemove.sort();
            for (Integer i = indexToRemove.size() - 1; i >= 0; i--) {
                //remove unwanted quotelines from list to process
                quotelineRecs.remove(indexToRemove[i]);
            }
            System.debug('indexToRemoveList' + indexToRemove.size());
            System.debug('Filtered records' + quotelineRecs.size());
            System.debug('show result> after' + quotelineRecs);
            // End of CPQ22-3838
            if (!quotelineRecs.isEmpty())
                for (SBQQ__QuoteLine__c ql: quotelineRecs) {
                    //add new validation error msg 
                    if ((String.isNotBlank(ql.SubscribedAssetNames__c) || String.isNotBlank(ql.Subscribed_Asset_Name__c)) && (ql.SBQQ__Product__r.Rel_SubsAsst__c != null && ql.SBQQ__Product__r.Rel_SubsAsst__c != '' && ql.SBQQ__Product__r.Rel_SubsAsst__c.contains('Renew:RelatedAsst'))) {
                        Set < String > aa = new Set < String > ();
                        List < String > aaList = new List < String > ();
                        Set < String > bb = new Set < String > ();
                        List < String > bbList = new List < String > ();
                        
                        if (String.isNotBlank(ql.SubscribedAssetNames__c)) {
                            aaList = ql.SubscribedAssetNames__c.split(',');
                            for (String sst: aaList) {
                                asstNames.add(sst.trim());
                                aa.add(sst.trim());
                            }
                        }
                        if (String.isNotBlank(ql.Subscribed_Asset_Name__c)) {
                            bbList = ql.Subscribed_Asset_Name__c.split(',');
                            for (String sst: bbList) {
                                asstNames.add(sst.trim());
                                bb.add(sst.trim());
                            }
                        }
                        
                        if ((aaList != null && bbList == null) || (aaList == null && bbList != null) || !(aaList.size() == bbList.size() && aa.equals(bb))) {
                            mapQliError.put(ql.Id, 'Missing SN');
                        }
                    }
                    //end new validation error msg
                    if (ql.SBQQ__Quote__r.RWD_Deal_Ops_Exception__c == null || ql.SBQQ__Quote__r.RWD_Deal_Ops_Exception__c == '' || !ql.SBQQ__Quote__r.RWD_Deal_Ops_Exception__c.contains('Override asset/date validation on submit for approval')) {
                        System.debug('ql.SBQQ__Product__r.Rel_SubsAsst__c' + ql.SBQQ__Product__r.Rel_SubsAsst__c);
                        System.debug('ql.Quote_Line_Type__c' + ql.Quote_Line_Type__c);
                        System.debug('ql.Disposition_Reason__c' + ql.Disposition_Reason__c);
                        System.debug('ql.id>>' + ql.id);
                        System.debug('ql.SubscribedAssetNames__c>>' + ql.SubscribedAssetNames__c);
                        System.debug('ql.Subscribed_Asset_Name__c>>' + ql.Subscribed_Asset_Name__c);
                        //get data for replace Scale from TPH
                        if (ql.SBQQ__SubscriptionPricing__c == 'Fixed Price' && ql.Special_Program__c == 'Replaced' && ql.Quote_Line_Type__c == 'New' && ql.SBQQ__ProductFamily__c == 'Rubrik Scale' && ql.Arroyo_Subsumed_Old_Contract_Line_Items__c != null && ql.Arroyo_Subsumed_Old_Contract_Line_Items__c != '') {
                            splitSubs = ql.Arroyo_Subsumed_Old_Contract_Line_Items__c.split(',');
                            
                            if (splitSubs != null && splitSubs.size() > 0) {
                                List < String > subsCLI = new List < String > ();
                                for (String st: splitSubs) {
                                    subsCLI.add(st.trim());
                                    mapScaleSubsum.put(ql.id, subsCLI);
                                }
                            }
                        }
                        if (ql.SBQQ__SubscriptionPricing__c == 'Fixed Price' && ql.Quote_Line_Type__c == 'Renewal' && ql.SBQQ__ProductFamily__c == 'Third Party License' && ql.Disposition_Reason__c == 'Replaced') {
                            mapTPHrenwCLI.put(ql.id, ql.SBQQSC__RenewedContractLine__c);
                        }
                        //CPQ22-4280 changed to contains check
                        //error for missing Asset details : 
                        if ((ql.Quote_Line_Type__c == 'Renewal' && (ql.Disposition_Reason__c == 'Renewing' || ql.Disposition_Reason__c == 'None' || ql.Disposition_Reason__c == '') && ql.SBQQ__Product__r.Rel_SubsAsst__c != null && ql.SBQQ__Product__r.Rel_SubsAsst__c != '' && ql.SBQQ__Product__r.Rel_SubsAsst__c.contains('Renew:RelatedAsst')) && (ql.SubscribedAssetNames__c == '' || ql.SubscribedAssetNames__c == null || ql.Subscribed_Asset_Name__c == '' || ql.Subscribed_Asset_Name__c == null)) {
                            
                            System.debug('inside all blank');
                            mapQliError.put(ql.Id, 'Missing SN');
                            // break;
                        }
                        //add common condition
                        if (ql.Quote_Line_Type__c == 'Renewal' && (ql.Disposition_Reason__c == 'Renewing' || ql.Disposition_Reason__c == 'None' || ql.Disposition_Reason__c == '') && ql.SBQQ__SubscriptionPricing__c == 'Fixed Price') {
                            List < String > trimAssetNames = new List < String > ();
                            if (String.isNotBlank(ql.SubscribedAssetNames__c)) {
                                subsasstNames = ql.SubscribedAssetNames__c.split(',');
                                for (String sst: subsasstNames) {
                                    trimAssetNames.add(sst.trim());
                                }
                            }
                            if (trimAssetNames != null && trimAssetNames.size() > 0) {
                                if (ql.SBQQ__Product__r.Rel_SubsAsst__c != null && ql.SBQQ__Product__r.Rel_SubsAsst__c != '' && ql.SBQQ__Product__r.Rel_SubsAsst__c.contains('Renew:RelatedAsst')) {
                                    qlIdSrnoMap.put(ql.id, trimAssetNames);
                                }
                                //check for HW Support and NRD
                                if (ql.SBQQ__RequiredBy__c != null && ql.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c != null && (ql.Product_Type__c == 'HW Support' || ql.SBQQ__ProductFamily__c == 'Non-Returnable Disk Service')) {
                                    System.debug('Inside HW support');
                                    List < String > asstname =
                                        mapReqIdandSrno.containsKey(ql.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c) ? mapReqIdandSrno.get(ql.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c) : new List < String > ();
                                    asstname.addAll(trimAssetNames);
                                    mapReqIdandSrno.put(ql.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c, asstname);
                                    System.debug('mapReqIdandSrno>>' + mapReqIdandSrno);
                                }
                                //NRD under License
                                else if (ql.SBQQ__RequiredBy__c != null && ql.SBQQ__ProductFamily__c == 'Non-Returnable Disk Service') {
                                    System.debug('inside NRD');
                                    List < String > asstname =
                                        mapReqIdandSrno.containsKey(ql.SBQQ__RequiredBy__c) ? mapReqIdandSrno.get(ql.SBQQ__RequiredBy__c) : new List < String > ();
                                    asstname.addAll(trimAssetNames);
                                    mapReqIdandSrno.put(ql.SBQQ__RequiredBy__c, asstname);
                                }
                                system.debug('mapReqIdandSrno>>' + mapReqIdandSrno);
                                
                                //check for s/w support skus
                                if (ql.Sales_Comp_Category__c == 'SW SUPPORT' && ql.Product_Level__c == 'Support' && ql.SBQQ__RequiredBy__c != null && ql.SBQQ__RequiredBy__r.Licensing_Model__c == 'Perpetual') {
                                    mapPerpRscandSrno.put(ql.SBQQ__RequiredBy__c, trimAssetNames);
                                }
                                System.debug('mapReqIdandSrno' + mapReqIdandSrno);
                                
                            }
                        }
                        //end common condition 
                        if (ql.Quote_Line_Type__c == 'Renewal' && (ql.Disposition_Reason__c == 'Renewing' || ql.Disposition_Reason__c == 'None' || ql.Disposition_Reason__c == '') && ql.Product_Type__c == 'HW Support' || ql.SBQQ__ProductFamily__c == 'Non-Returnable Disk Service') {
                            System.debug('ql.SBQQ__Quantity__c' + ql.SBQQ__Quantity__c);
                            if (!qlIdSrnoMap.isEmpty() && qlIdSrnoMap.containsKey(ql.Id) && qlIdSrnoMap.get(ql.Id).size() > 0 && ql.SBQQ__Quantity__c != qlIdSrnoMap.get(ql.Id).size()) {
                                System.debug('inside Qunty error');
                                mapQliError.put(ql.Id, 'Quantity Missmatch');
                                //validationMSG =  System.Label.Error_with_Asset_Details;
                                //System.debug('which line ?3'+ql.SBQQ__Product__r.Name);
                                // break;
                            }
                        }
                    }
                    
                }
            
            //end of for loop
            for (Asset ast: [Select id, Name, SerialNumber, Product_Usable_Capacity__c from Asset where SerialNumber IN: asstNames]) {
                assIdCapacity.put(ast.SerialNumber, ast.Product_Usable_Capacity__c);
                System.debug('@@assIdCapacity ' + assIdCapacity);
            }
            
            for (SBQQ__QuoteLine__c ql: quotelineRecs) {
                if (ql.SBQQ__Quote__r.RWD_Deal_Ops_Exception__c == null || ql.SBQQ__Quote__r.RWD_Deal_Ops_Exception__c == '' || !ql.SBQQ__Quote__r.RWD_Deal_Ops_Exception__c.contains('Override asset/date validation on submit for approval')) {
                    if ((ql.Quote_Line_Type__c == 'Renewal' && ql.SBQQ__SubscriptionPricing__c == 'Fixed Price' &&
                         (ql.Disposition_Reason__c == 'Renewing' || ql.Disposition_Reason__c == 'None' || ql.Disposition_Reason__c == '')) &&
                        (ql.SBQQ__Product__r.Rel_SubsAsst__c != null && ql.SBQQ__Product__r.Rel_SubsAsst__c != '' && ql.SBQQ__Product__r.Rel_SubsAsst__c.contains('Renew:RelatedAsst'))) {
                            System.debug('@@ql ' + ql);
                            //capacity error //changes related to CPQ22-4515
                            if (!assIdCapacity.isEmpty() && ql.SBQQ__Product__r.Product_Level__c != '' && ql.SBQQ__Product__r.Product_Level__c != null && ql.SBQQ__Product__r.Product_Level__c == 'Hybrid Software') {
                                
                                Double capacity = 0;
                                if (String.isNotBlank(ql.SubscribedAssetNames__c)) {
                                    subsasstNames = ql.SubscribedAssetNames__c.split(',');
                                    for (String sst: subsasstNames) {
                                        if (assIdCapacity.containsKey(sst.trim())) {
                                            capacity += assIdCapacity.get(sst.trim());
                                        } else {
                                            System.debug('missing Product usable quantity');
                                            mapQliError.put(ql.Id, 'Quantity Missmatch');
                                            // validationMSG = System.Label.Error_with_Asset_Details;
                                            //break;
                                        }
                                    }
                                    System.debug('Capacity ' + capacity);
                                    if (ql.SBQQ__Quantity__c != capacity) {
                                        System.debug('inside Quntity error');
                                        // validationMSG =  System.Label.Error_with_Asset_Details;
                                        System.debug('which line ?3');
                                        mapQliError.put(ql.Id, 'Quantity Missmatch');
                                        // break;
                                    }
                                }
                            }
                        }
                    //check for replaceScale
                    System.debug('mapScaleSubsum1' + mapScaleSubsum);
                    System.debug('mapTPHrenwCLI1' + mapTPHrenwCLI);
                    
                    if ((ql.SBQQ__SubscriptionPricing__c == 'Fixed Price' && ql.Special_Program__c == 'Replaced' && ql.Quote_Line_Type__c == 'New' && ql.SBQQ__ProductFamily__c == 'Rubrik Scale') && (ql.SubscribedAssetNames__c == '' || ql.SubscribedAssetNames__c == null || ql.Subscribed_Asset_Name__c == '' || ql.Subscribed_Asset_Name__c == null)) {
                        if (!mapScaleSubsum.isEmpty() && !mapTPHrenwCLI.isEmpty() && mapScaleSubsum.containsKey(ql.Id)) {
                            for (String str: mapTPHrenwCLI.values()) {
                                if (mapScaleSubsum.get(ql.id).contains(str)) {
                                    System.debug('mapScaleSubsum' + mapScaleSubsum);
                                    System.debug('mapTPHrenwCLI' + mapTPHrenwCLI);
                                    
                                    isTPHreplaced = true;
                                }
                            }
                        }
                        if (!isTPHreplaced) {
                            //validationMSG = System.Label.Error_with_Asset_Details;
                            mapQliError.put(ql.Id, 'Missing SN');
                            //System.debug('which TPH'+ql.SBQQ__Product__r.Name);
                        }
                    }
                    
                    
                    
                    
                    //if(ql.Quote_Line_Type__c == 'Renewal' && (ql.Disposition_Reason__c == 'Renewing' || ql.Disposition_Reason__c == 'None' || ql.Disposition_Reason__c == '')){
                    //List<String> srnoTrimLst = new List<String>();
                    if (!qlIdSrnoMap.isEmpty() && qlIdSrnoMap.containsKey(ql.id)) {
                        for (String srno: qlIdSrnoMap.get(ql.id)) {
                            String asstname = srno.trim();
                            System.debug('asstname' + asstname);
                            
                            if ((!mapReqIdandSrno.isEmpty() && mapReqIdandSrno.containsKey(ql.Id) && !mapReqIdandSrno.get(ql.Id).contains(asstname)) ||
                                (!mapPerpRscandSrno.isEmpty() && !mapPerpRscandSrno.get(ql.id).contains(asstname))) {
                                    System.debug('mapPerpRscandSrno' + mapPerpRscandSrno);
                                    System.debug('mapReqIdandSrno' + mapReqIdandSrno);
                                    
                                    mapQliError.put(ql.Id, 'Missing SN');
                                    System.debug('validation' + validationMSG);
                                    System.debug('!mapReqIdandSrno.get(ql.Id).contains(asstname)' + !mapReqIdandSrno.get(ql.Id).contains(asstname));
                                    
                                    // System.debug('which line ?8'+ql.SBQQ__Product__r.Name);
                                    // break;
                                }
                        }
                    }
                }
            }
            
        }   catch(Exception e){
            system.debug('@@ Error Details '+e.getMessage());   
        }
        
        System.debug('mapQliError>>'+mapQliError);
    }
    public void finish(Database.BatchableContext bc) {
        String header = 'Id'+','+'Validation';
        String finalstr = header ;
        String fileRow = '';
        //fileRow = fileRow + ',' + 'Id';
        // fileRow = fileRow + ',' + 'Validation';
        //String fileRow = '';
        String generatedCSVFile = 'Id'+','+'Validation'+ '\n';
        String emailBody = 'The Following QuoteLines records have Asset Validations';
        System.debug('mapQliError'+mapQliError);
        if(!mapQliError.isEmpty()) {
            for (Id qlid: mapQliError.keyset()) {
                fileRow = '';
                fileRow = fileRow.replaceFirst(',', '');
                fileRow = fileRow + ',' + qlid;
                fileRow = fileRow + ',' + mapQliError.get(qlid);
                fileRow = fileRow.replaceFirst(',', '');
                generatedCSVFile =  generatedCSVFile+fileRow + '\n';
                System.debug('generatedCSVFile'+generatedCSVFile);
            }
        }
        Messaging.EmailFileAttachment csvAttachment = new Messaging.EmailFileAttachment();
        Blob csvBlob ;
        csvBlob = blob.valueOf(generatedCSVFile);
        String csvName = 'Quotelinedetails' +  Date.today().format() + '.csv';
        csvAttachment.setFileName(csvName);
        csvAttachment.setBody(csvBlob);
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {
            'cpq_it_admin@rubrik.com'
                };
                    String subject = 'QL details for Asset Validation  '+  Date.today().format();
        email.setSubject(subject);
        email.setHtmlBody('Here is the CSV file ');
        
        email.setToAddresses(toAddresses);
        email.setPlainTextBody('Quoteline');
        email.setFileAttachments(new Messaging.EmailFileAttachment[] {
            csvAttachment
                });
        if(!test.isRunningTest() ){
            Messaging.SendEmailResult[] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {
                email
                    });
        }
    }
    public void execute(SchedulableContext sc){}
}