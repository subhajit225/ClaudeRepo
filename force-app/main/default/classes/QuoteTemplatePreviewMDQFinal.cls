public with sharing class QuoteTemplatePreviewMDQFinal {


    Map<String, wrapperQuoteLines> productQuoteLineMap;
    Map<String, wrapperQuoteLines> prodQuarterQuoteLineMap;
    List<SBQQ__QuoteLine__c> lstAddOnQuoteLines;
    List<String> args = new String[]{'0','number','###,###,##0.00'};
    public List<wrapperQuoteLines> lstQuoteLinesToDisplay {get; set;}
    public List<String> lstPaymentScheduleToDisplay {get; set;}
    public Decimal netTotalMDQ {get; set;} 
    public String strNetTotalMDQ {get; set;}
    public String strPaymentSchedule {get; set;}
    public String strPaymentParent {get; set;}
    public String strPaymentVerbage {get; set;}
    public String strPaymentVerbageCont {get; set;}
    //public Boolean showSalesPrice {get; set;}
    //Added for SF 5116 
    public Set<Integer> setQuarters;    
    
    //constructor    
   public QuoteTemplatePreviewMDQFinal() {
        Id quoteID = ApexPages.currentPage().getParameters().get('qid');
        lstQuoteLinesToDisplay = new List<wrapperQuoteLines>();
        lstPaymentScheduleToDisplay = new List<String>();
        setQuarters = new Set<Integer>();
        netTotalMDQ = 0;
        strNetTotalMDQ = '';
        strPaymentSchedule = '';
        strPaymentVerbage = '';
        defineQuarters(quoteID);
        getMDQLines(quoteID);
    }
    
    public void defineQuarters(Id currentQuoteID){ 
        //Id currentQuoteID = 'a6T1k0000004axt';
        Map<String,List<Integer>> mapYear_lstQuarters = new Map<String,List<Integer>>();
        Map<Id,List<SBQQ__QuoteLine__c>> MapId_QLI = new Map<Id,List<SBQQ__QuoteLine__c>>();
        Map<Integer,Boolean> mapQuarter = new Map<Integer,Boolean>();
        //Set<Integer> setQuarters = new Set<Integer>();
        List<SBQQ__QuoteLine__c> lstMDQQuoteLines = [SELECT ID,
                                                            Name,
                                                            SBQQ__ProductCode__c,
                                                            SBQQ__Description__c,
                                                            SBQQ__Quantity__c,
                                                            SBQQ__Product__c,
                                                            SBQQ__ListPrice__c,
                                                            SBQQ__Quote__r.SBQQ__SubscriptionTerm__c,
                                                            CPQ_MSP_Sales_Price__c,
                                                            SBQQ__NetTotal__c,
                                                            SBQQ__RequiredBy__c,
                                                            SBQQ__SegmentIndex__c,
                                                            SBQQ__EffectiveQuantity__c,
                                                            Feature_Name__c,
                                                            Back_End_Capacity_TB__c,
                                                            SBQQ__RequiredBy__r.Back_End_Capacity_TB__c,
                                                            SBQQ__RequiredBy__r.SBQQ__Quantity__c,
                                                            SBQQ__SegmentLabel__c,
                                                            SBQQ__Number__c
                                                        FROM SBQQ__QuoteLine__c
                                                        WHERE SBQQ__Quote__c =: currentQuoteID
                                                        AND (SBQQ__SegmentIndex__c != null OR Feature_Name__c =: 'Add-Ons')
                                                        ORDER BY SBQQ__SegmentLabel__c ASC NULLS LAST];
        for(SBQQ__QuoteLine__c objQuoteLine : lstMDQQuoteLines){
            if(MapId_QLI.containsKey(objQuoteLine.SBQQ__RequiredBy__c)){
                MapId_QLI.get(objQuoteLine.SBQQ__RequiredBy__c).add(objQuoteLine);
            }else{
                List<SBQQ__QuoteLine__c> lstQLI = new List<SBQQ__QuoteLine__c>();
                lstQLI.add(objQuoteLine);
                MapId_QLI.put(objQuoteLine.SBQQ__RequiredBy__c,lstQLI);
            }
        }
        // system.debug('mapSize----'+MapId_QLI.size());
        // for(String strId : MapId_QLI.keyset()){
        //     system.debug('---size---'+MapId_QLI.get(strId).size());
        //     for(SBQQ__QuoteLine__c QLI : MapId_QLI.get(strId)){
        //         system.debug('---QLI---'+QLI);
        //     }
        // }
        
        // String year = 'Year';
        // Integer intYear = 1;
        //mapYear_lstQuarters
        for(Id strId : MapId_QLI.keyset()){
            String year = 'Year';
            Integer intYear = 1;
            for(SBQQ__QuoteLine__c QLI : MapId_QLI.get(strId)){
                
                if(mapYear_lstQuarters.containsKey(QLI.SBQQ__RequiredBy__c+'_'+year+'_'+intYear)){
                    if(mapYear_lstQuarters.get(QLI.SBQQ__RequiredBy__c+'_'+year+'_'+intYear).size() == 4){
                        intyear += 1;
                        list<Integer> intList = new list<Integer>();
                        if(QLI.Back_End_Capacity_TB__c != null){
                            intList.add(QLI.Back_End_Capacity_TB__c.intValue());
                            mapYear_lstQuarters.put(QLI.SBQQ__RequiredBy__c+'_'+year+'_'+intYear,intList);
                            
                        }
                        
                    }else{
                        if(QLI.Back_End_Capacity_TB__c != null){
                            mapYear_lstQuarters.get(QLI.SBQQ__RequiredBy__c+'_'+year+'_'+intYear).add(QLI.Back_End_Capacity_TB__c.intValue());    
                        }
                    }
                }else{
                    list<Integer> intList = new list<Integer>();
                    if(QLI.Back_End_Capacity_TB__c != null){
                        intList.add(QLI.Back_End_Capacity_TB__c.intValue());
                        mapYear_lstQuarters.put(QLI.SBQQ__RequiredBy__c+'_'+year+'_'+intYear,intList);
                    }
                        
                }
            }            
        }
        for(String strKey : mapYear_lstQuarters.keyset()){
            Integer intialCapacity = 0;
            for(Integer capacity : mapYear_lstQuarters.get(strKey)){
                if(intialCapacity == 0){
                    system.debug('intialCapacity at start--'+intialCapacity);
                    intialCapacity = capacity;
                    system.debug('intialCapacity at end---'+intialCapacity);
                }else if(intialCapacity != capacity){
                    List<String> lststring = strKey.split('_');
                    if(lststring.size() == 3 ){
                        if(lststring[2].isNumeric()){
                            integer intQuarters = integer.valueOf(lststring[2]) * 4;
                            setQuarters.add(intQuarters);
                            intQuarters--;
                            setQuarters.add(intQuarters);
                            intQuarters--;
                            setQuarters.add(intQuarters);
                            intQuarters--;
                            setQuarters.add(intQuarters);
                            Break;
                        }
                    }
                }
            }
        }//End of for
        system.debug('Valid Quarters---'+setQuarters);
        // for(SBQQ__QuoteLine__c objQuoteLine : lstMDQQuoteLines){
        //     if(objQuoteLine.SBQQ__SegmentIndex__c != null){
        //         system.debug('objQuoteLine.SBQQ__SegmentIndex__c'+objQuoteLine.SBQQ__SegmentIndex__c);
        //         if(mapYear_lstQuarters.containsKey(objQuoteLine.SBQQ__RequiredBy__c+'_'+year+'_'+intYear)){
        //             system.debug('size---'+mapYear_lstQuarters.get(objQuoteLine.SBQQ__RequiredBy__c+'_'+year+'_'+intYear).size());
        //             if(mapYear_lstQuarters.get(objQuoteLine.SBQQ__RequiredBy__c+'_'+year+'_'+intYear).size() == 4){
        //                 intyear += 1;
        //                 list<Integer> intList = new list<Integer>();
        //                 intList.add(objQuoteLine.Back_End_Capacity_TB__c.intValue());
        //                 mapYear_lstQuarters.put(objQuoteLine.SBQQ__RequiredBy__c+'_'+year+'_'+intYear,intList);
        //             }else{
        //                 mapYear_lstQuarters.get(objQuoteLine.SBQQ__RequiredBy__c+'_'+year+'_'+intYear).add(objQuoteLine.Back_End_Capacity_TB__c.intValue());    
        //             }
        //         }else{
        //             list<Integer> intList = new list<Integer>();
        //                 intList.add(objQuoteLine.Back_End_Capacity_TB__c.intValue());
        //             mapYear_lstQuarters.put(objQuoteLine.SBQQ__ProductCode__c+'_'+year+'_'+intYear,intList);
        //         }    
        //     }
        // }
        // for(string strkey : mapYear_lstQuarters.keyset()){
        //     system.debug('Size '+mapYear_lstQuarters.get(strkey).size());
        //     system.debug('Key '+strkey);
        //     for(Integer intKey : mapYear_lstQuarters.get(strkey)){
        //         system.debug('strkey --- '+strkey+'-intKey-'+ intKey);
        //     }
        // }
    }
    
    // select Segmented products.
    public void getMDQLines(Id currentQuoteID) {
        Integer MDQProdCount = 0;
        Boolean insertAddon;
        productQuoteLineMap = new Map<String, wrapperQuoteLines>();
        lstAddOnQuoteLines = new List<SBQQ__QuoteLine__c>();
        prodQuarterQuoteLineMap = new Map<String, wrapperQuoteLines>();
               
        List<SBQQ__QuoteLine__c> lstMDQQuoteLines = [SELECT ID,
                                                            Name,
                                                            SBQQ__ProductCode__c,
                                                            SBQQ__Description__c,
                                                            SBQQ__Quantity__c,
                                                            SBQQ__Product__c,
                                                            SBQQ__ListPrice__c,
                                                            SBQQ__Quote__r.SBQQ__SubscriptionTerm__c,
                                                            SBQQ__Quote__r.Total_Commit__c,
                                                            SBQQ__Quote__r.Total_Commit_for_SW_DR__c,
                                                            CPQ_MSP_Sales_Price__c,
                                                            SBQQ__NetTotal__c,
                                                            SBQQ__RequiredBy__c,
                                                            SBQQ__SegmentIndex__c,
                                                            SBQQ__EffectiveQuantity__c,
                                                            Feature_Name__c,
                                                            Back_End_Capacity_TB__c,
                                                            SBQQ__RequiredBy__r.Back_End_Capacity_TB__c,
                                                            SBQQ__RequiredBy__r.SBQQ__Quantity__c,
                                                            SBQQ__SegmentLabel__c,
                                                            SBQQ__Number__c,
                                                            MSP_Add_On_CONS_OutputDocument_Exception__c
                                                        FROM SBQQ__QuoteLine__c
                                                        WHERE SBQQ__Quote__c =: currentQuoteID
                                                        AND ((SBQQ__SegmentIndex__c != null OR Feature_Name__c =: 'Add-Ons')
                                                        OR MSP_Add_On_CONS_OutputDocument_Exception__c=true)
                                                        ORDER BY SBQQ__SegmentLabel__c ASC NULLS LAST];
        system.debug('Size---'+lstMDQQuoteLines.size());              
        system.debug('lstMDQQuoteLines---'+lstMDQQuoteLines);
        
        strPaymentVerbage ='Consumption Fees will be invoiced monthly in arrears based on the Billing Report, with billing to commence on the date of shipment of the Product to Company (the “Billing Commencement Date”).';
        strPaymentVerbageCont = 'During the period from the Billing Commencement Date to the end of the calendar month in which the Billing Commencement Date occurred, billing will be based on actual use. For the full calendar month following the Billing Commencement date, billing will be based on actual use. Every subsequent calendar month will be billed at the greater of the minimum monthly charge as specified in the order form or the actual usage.';
            
        for(SBQQ__QuoteLine__c objQL : lstMDQQuoteLines) {
            if(objQL.Feature_Name__c == 'Add-Ons') {
                lstAddOnQuoteLines.add(objQL);
            }
            if(objQL.SBQQ__SegmentIndex__c == 1) {
                MDQProdCount++;
            }
            if((objQL.SBQQ__ProductCode__c == 'RBK-SW-CONS' && objQL.SBQQ__Quote__r.Total_Commit__c == 0)||(objQL.SBQQ__ProductCode__c == 'RBK-SW-CONS-DR' && objQL.SBQQ__Quote__r.Total_Commit_for_SW_DR__c == 0)){
                strPaymentVerbage = 'Consumption Fees will be invoiced monthly in arrears based on the Billing Report, with billing to commence on the date of shipment of the Product to Company (the “Billing Commencement Date”).';
                strPaymentVerbageCont = 'During the period from the Billing Commencement Date to the contract end date, billing will be based on actual use.';
        
                } 
                
        }
        
        for(SBQQ__QuoteLine__c objQL : lstMDQQuoteLines)     {
            if(objQL.SBQQ__SegmentIndex__c != null  ) {
                    system.debug('objQL.SBQQ__SegmentIndex__c-----'+objQL.SBQQ__SegmentIndex__c);
                    insertAddon = false;
                    if(productQuoteLineMap.containsKey(objQL.SBQQ__ProductCode__c+'_'+objQL.SBQQ__Number__c)) {
                        System.debug('i====');
                        wrapperQuoteLines wrapObj = new wrapperQuoteLines();
                        wrapObj.prodTerm = objQL.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c;
                        wrapObj = productQuoteLineMap.get(objQL.SBQQ__ProductCode__c+'_'+objQL.SBQQ__Number__c);
                        wrapObj.prodQty += objQL.SBQQ__Quantity__c;
                        wrapObj.prodSalesPrice = objQL.CPQ_MSP_Sales_Price__c;
                        wrapObj.strSalesPrice = '$' + objQL.CPQ_MSP_Sales_Price__c;
                        wrapObj.prodNetTotal += ObjQl.SBQQ__NetTotal__c;
                        wrapObj.prodBackendCapacity = objQL.Back_End_Capacity_TB__c;
                        wrapObj.netTotal = '$' + String.format(wrapObj.prodNetTotal.format(), args) + '.00';
                        System.debug('wrapObj.netTotal=111==='+wrapObj.netTotal);
                        if (objQL.SBQQ__Quote__r.Total_Commit__c != null){
                            wrapObj.strProdQty = (objQL.SBQQ__Quote__r.Total_Commit__c > 0) ? String.format(wrapObj.prodQty.format(), args) : String.format('0', args);
                        } else{
                            wrapObj.strProdQty = String.format(wrapObj.prodQty.format(), args);
                        }                       
                        if (objQL.SBQQ__EffectiveQuantity__c > 0) {
                         productQuoteLineMap.put(objQL.SBQQ__ProductCode__c+'_'+objQL.SBQQ__Number__c, wrapObj);
                        }
                    }
                    else {
                        System.debug('into else====');
                        insertAddon = true;
                        wrapperQuoteLines wrapObj = new wrapperQuoteLines();
                        wrapObj.prodTerm = objQL.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c;
                        wrapObj.prodCode = objQL.SBQQ__ProductCode__c;
                        wrapObj.prodDescription = objQL.SBQQ__Description__c;
                        wrapObj.prodQty += objQL.SBQQ__Quantity__c.round(System.RoundingMode.HALF_UP);
                        wrapObj.prodSalesPrice = objQL.CPQ_MSP_Sales_Price__c;
                        wrapObj.strSalesPrice = '$' + objQL.CPQ_MSP_Sales_Price__c;
                        wrapObj.prodNetTotal = ObjQl.SBQQ__NetTotal__c;
                        wrapObj.prodBackendCapacity = objQL.Back_End_Capacity_TB__c;
                        wrapObj.netTotal = '$' + String.format(wrapObj.prodNetTotal.format(), args) + '.00';
                        if (objQL.SBQQ__Quote__r.Total_Commit__c != null){
                            wrapObj.strProdQty = (objQL.SBQQ__Quote__r.Total_Commit__c > 0) ? String.format(wrapObj.prodQty.format(), args) : String.format('0', args);
                        } else{
                            wrapObj.strProdQty = String.format(wrapObj.prodQty.format(), args);
                        }   
                        if (objQL.SBQQ__EffectiveQuantity__c > 0) {
                         productQuoteLineMap.put(objQL.SBQQ__ProductCode__c+'_'+objQL.SBQQ__Number__c, wrapObj);
                        }
                        //productQuoteLineMap.put(objQL.SBQQ__ProductCode__c+'_'+objQL.SBQQ__Number__c, wrapObj);
                    }
                    
                    if(insertAddon == true) {  
                        for(SBQQ__QuoteLine__c objAddonQL : lstAddOnQuoteLines) {
                            if(objAddonQL.SBQQ__RequiredBy__c == objQL.SBQQ__RequiredBy__c || objAddonQL.MSP_Add_On_CONS_OutputDocument_Exception__c==true) {
                                System.debug('into if22==');
                                wrapperQuoteLines wrapObj = new wrapperQuoteLines();
                                wrapObj.prodTerm = objAddonQL.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c;
                                wrapObj.prodCode = objAddonQL.SBQQ__ProductCode__c;
                                wrapObj.prodDescription = objAddonQL.SBQQ__Description__c;
                                wrapObj.prodQty += objAddonQL.SBQQ__Quantity__c.round(System.RoundingMode.HALF_UP);
                                wrapObj.prodSalesPrice = objAddonQL.CPQ_MSP_Sales_Price__c;
                                wrapObj.strSalesPrice = '$' + String.format(wrapObj.prodSalesPrice.setscale(2).format(), args);
                                wrapObj.prodNetTotal = objAddonQL.SBQQ__NetTotal__c;
                                wrapObj.prodBackendCapacity = objAddonQL.Back_End_Capacity_TB__c;
                                wrapObj.netTotal = '$' + String.format(wrapObj.prodNetTotal.format(), args) + '.00';
                                if (objQL.SBQQ__Quote__r.Total_Commit__c != null){
                                    wrapObj.strProdQty = (objQL.SBQQ__Quote__r.Total_Commit__c > 0) ? String.format(wrapObj.prodQty.format(), args) : String.format('0', args);
                                } else{
                                    wrapObj.strProdQty = String.format(wrapObj.prodQty.format(), args);
                                }   
                                System.debug('wrapObj.netTotal Addon===='+wrapObj.netTotal);
                                if (objAddonQL.SBQQ__EffectiveQuantity__c >0) {
                                    productQuoteLineMap.put(objAddonQL.SBQQ__ProductCode__c+'_'+objAddonQL.SBQQ__Number__c, wrapObj);
                                }
                            }
                        }
                    }
            }
            netTotalMDQ += objQL.SBQQ__NetTotal__c;
            strNetTotalMDQ = '$' + String.format(netTotalMDQ.format(), args) + '.00';
        }
        lstQuoteLinesToDisplay.addall(productQuoteLineMap.values());
        
        Decimal paySchedule = 0;
        Decimal paymentParent = 0;
        String strPaymentToDisplay;
        String strParent;
        String strMonthsToDisplay;
        Integer initialMonth = 1;
        Integer endMonth = 3;
        Integer initialMonthYearly = 1;
        Integer endMonthYearly = 3;
        Integer quarter = 1;
        Integer quarterYearly = 1;
        Integer type = 0;
        Boolean addHeader = true;
        Boolean check4iteration;
        Integer displayPayment = 0;
        
        for(SBQQ__QuoteLine__c objQL : lstMDQQuoteLines) {
            check4iteration = false;
            system.debug('endMonth---->>>'+endMonth);
            system.debug('endMonthYearly---->>>'+endMonthYearly);
            system.debug('initialMonth---->>>'+initialMonth);
            system.debug('initialMonthYearly---->>>'+initialMonthYearly);
            
            if(objQL.SBQQ__SegmentIndex__c != null ) {
                System.debug('Label===='+objQL.SBQQ__ProductCode__c+'--num---'+objQL.SBQQ__Number__c+'--seg----'+objQL.SBQQ__SegmentIndex__c);
                if(objQL.SBQQ__SegmentLabel__c == 'Quarter  '+quarter || objQL.SBQQ__SegmentLabel__c == 'Quarter '+quarter) {
                    
                    if(setQuarters.contains(objQL.SBQQ__SegmentIndex__c.intValue())) {
                        system.debug('Here');
                        if(initialMonth + 12 == endMonth){
                            endMonthYearly -= 9;
                        }
                        strMonthsToDisplay = 'Months ' + initialMonth + ' - ' + endMonth + ' :';
                        if(objQL.Back_End_Capacity_TB__c != null && objQL.CPQ_MSP_Sales_Price__c != null) {
                            strParent = '';  
                            paySchedule = ((objQL.Back_End_Capacity_TB__c * objQL.CPQ_MSP_Sales_Price__c) * 1000 *objQL.SBQQ__RequiredBy__r.SBQQ__Quantity__c).setScale(0);
                            strPaymentSchedule = String.format(paySchedule.format(), args);
                            strParent = objQL.SBQQ__ProductCode__c + ' minimum commitment of ';
                            strParent += objQL.Back_End_Capacity_TB__c + ' TB at $' + objQL.CPQ_MSP_Sales_Price__c;
                            strParent += ' for ' + String.format(objQL.SBQQ__RequiredBy__r.SBQQ__Quantity__c.format(), args) + ' Appliance ';
                            strParent += ' = $' + strPaymentSchedule;
                            if (objQL.SBQQ__EffectiveQuantity__c > 0 ){
                            paymentParent += paySchedule;
                            }
                            if(addHeader) {
                                lstPaymentScheduleToDisplay.add('');
                                lstPaymentScheduleToDisplay.add(strMonthsToDisplay);
                                addHeader = false;
                            }
                            if (objQL.SBQQ__EffectiveQuantity__c > 0 ){
                            lstPaymentScheduleToDisplay.add(strParent);
                            }
                        } 
                        check4iteration = true;
                        type++;
                        if(type == MDQProdCount) {
                            type = 0;
                            quarter++;
                            initialMonth += 3;
                            endMonth += 3;
                            initialMonthYearly += 3;
                            endMonthYearly += 3;
                            addHeader = true;
                        }
                    } 
                    else{
                        System.debug('into else greater month======');
                        if(prodQuarterQuoteLineMap.containsKey(objQL.SBQQ__ProductCode__c+'_'+objQL.SBQQ__RequiredBy__c)) {
                            wrapperQuoteLines wrapObj = new wrapperQuoteLines();
                            wrapObj.prodTerm = objQL.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c;
                            wrapObj = prodQuarterQuoteLineMap.get(objQL.SBQQ__ProductCode__c+'_'+objQL.SBQQ__RequiredBy__c);
                            wrapObj.prodSalesPrice = objQL.CPQ_MSP_Sales_Price__c;
                            wrapObj.prodBackendCapacity = objQL.Back_End_Capacity_TB__c;
                            //wrapObj.showSalesPrice = objQL.SBQQ__Quote__r.Show_Sales_Price_on_Disti__c;
                            prodQuarterQuoteLineMap.put(objQL.SBQQ__ProductCode__c+'_'+objQL.SBQQ__RequiredBy__c, wrapObj);
                        }
                        else{
                            wrapperQuoteLines wrapObj = new wrapperQuoteLines();
                            wrapObj.prodTerm = objQL.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c;
                            wrapObj.prodCode = objQL.SBQQ__ProductCode__c;
                            wrapObj.prodDescription = objQL.SBQQ__Description__c;
                            wrapObj.prodSalesPrice = objQL.Back_End_Capacity_TB__c;
                            //wrapObj.showSalesPrice = objQL.SBQQ__Quote__r.Show_Sales_Price_on_Disti__c;
                            prodQuarterQuoteLineMap.put(objQL.SBQQ__ProductCode__c+'_'+objQL.SBQQ__RequiredBy__c, wrapObj);
                        }
                        type++;
                        if(type == MDQProdCount) {
                            type = 0;
                            quarter++;
                        }
                        system.debug('Segment Index ----'+objQL.SBQQ__SegmentIndex__c.intValue());
                        if(math.mod(objQL.SBQQ__SegmentIndex__c.intValue(), 4) == 0) {
                            system.debug('Math Mod 0');
                            check4iteration = true;
                            if(initialMonthYearly + 2 == endMonthYearly){
                                endMonthYearly += 9;
                            }
                            
                            strMonthsToDisplay = 'Months ' + initialMonthYearly + ' - ' + endMonthYearly + ' :';
                            System.debug('month string---'+strMonthsToDisplay);
                            if(objQL.Back_End_Capacity_TB__c != null && objQL.CPQ_MSP_Sales_Price__c != null && objQL.SBQQ__RequiredBy__c!= null) {
                                strParent = '';  
                                paySchedule = ((prodQuarterQuoteLineMap.get(objQL.SBQQ__ProductCode__c+'_'+objQL.SBQQ__RequiredBy__c).prodBackendCapacity * prodQuarterQuoteLineMap.get(objQL.SBQQ__ProductCode__c+'_'+objQL.SBQQ__RequiredBy__c).prodSalesPrice) * 1000 *objQL.SBQQ__RequiredBy__r.SBQQ__Quantity__c).setScale(0);
                                strPaymentSchedule = String.format(paySchedule.format(), args);
                                strParent = objQL.SBQQ__ProductCode__c + ' minimum commitment of ';
                                strParent += (prodQuarterQuoteLineMap.get(objQL.SBQQ__ProductCode__c+'_'+objQL.SBQQ__RequiredBy__c).prodBackendCapacity) + ' TB at $' + objQL.CPQ_MSP_Sales_Price__c;
                                strParent += ' for ' + String.format(objQL.SBQQ__RequiredBy__r.SBQQ__Quantity__c.format(), args) + ' Appliance ';
                                strParent += ' = $' + strPaymentSchedule;
                                if (objQL.SBQQ__EffectiveQuantity__c > 0 ){
                                paymentParent += paySchedule;
                                }
                                if(addHeader) {
                                    lstPaymentScheduleToDisplay.add('');
                                    lstPaymentScheduleToDisplay.add(strMonthsToDisplay);
                                    addHeader = false;
                                }
                                if(quarterYearly == MDQProdCount) {
                                    addHeader = true;
                                    initialMonthYearly += 12;
                                    endMonthYearly += 12;
                                    quarterYearly = 0;
                                    initialMonth += 12;
                                    endMonth += 12;
                                }
                                if (objQL.SBQQ__EffectiveQuantity__c >0 ) {
                                lstPaymentScheduleToDisplay.add(strParent);
                                }
                            }
                            quarterYearly++;
                            
                        }//SF 5116 Added extra condition to accomodate half or quarter year only 
                        else if (initialMonthYearly < objQL.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c  
                               && endMonthYearly >= objQL.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c 
                               && math.mod(objQL.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c.intValue(), 12) != 0) {
                                system.debug('Here end month');
                                check4iteration = true;
                            strMonthsToDisplay = 'Months ' + initialMonthYearly + ' - ' + integer.valueOf(objQL.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c) + ' :';
                            if(objQL.Back_End_Capacity_TB__c != null && objQL.CPQ_MSP_Sales_Price__c != null) {
                                strParent = '';  
                                paySchedule = ((prodQuarterQuoteLineMap.get(objQL.SBQQ__ProductCode__c+'_'+objQL.SBQQ__RequiredBy__c).prodBackendCapacity * prodQuarterQuoteLineMap.get(objQL.SBQQ__ProductCode__c+'_'+objQL.SBQQ__RequiredBy__c).prodSalesPrice) * 1000 *objQL.SBQQ__RequiredBy__r.SBQQ__Quantity__c).setScale(0);
                                strPaymentSchedule = String.format(paySchedule.format(), args);
                                strParent = objQL.SBQQ__ProductCode__c + ' minimum commitment of ';
                                strParent += (prodQuarterQuoteLineMap.get(objQL.SBQQ__ProductCode__c+'_'+objQL.SBQQ__RequiredBy__c).prodBackendCapacity) + ' TB at $' + objQL.CPQ_MSP_Sales_Price__c;
                                strParent += ' for ' + String.format(objQL.SBQQ__RequiredBy__r.SBQQ__Quantity__c.format(), args) + ' Appliance ';
                                strParent += ' = $' + strPaymentSchedule;
                                if (objQL.SBQQ__EffectiveQuantity__c > 0 ){
                                paymentParent += paySchedule;
                                }
                                if(addHeader) {
                                    lstPaymentScheduleToDisplay.add('');
                                    lstPaymentScheduleToDisplay.add(strMonthsToDisplay);
                                    addHeader = false;
                                }
                                if(quarterYearly == MDQProdCount) {
                                    addHeader = true;
                                    initialMonthYearly += 12;
                                    endMonthYearly = integer.valueOf(objQL.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c);
                                    quarterYearly = 0;
                                }  
                                if (objQL.SBQQ__EffectiveQuantity__c > 0 ){
                                lstPaymentScheduleToDisplay.add(strParent);
                                }
                            }
                            quarterYearly++;
                        }
                    }
                    if(check4iteration) {
                        system.debug('Check For Iteration');
                        displayPayment++;
                        for(SBQQ__QuoteLine__c objAddonQL : lstAddOnQuoteLines) {
                            if(objQL.Back_End_Capacity_TB__c != null && objAddonQL.CPQ_MSP_Sales_Price__c != null && objAddonQL.SBQQ__RequiredBy__c == objQL.SBQQ__RequiredBy__c) {
                                strParent = '';
                                paySchedule = ((objQL.Back_End_Capacity_TB__c * objAddonQL.CPQ_MSP_Sales_Price__c) * 1000 * objQL.SBQQ__RequiredBy__r.SBQQ__Quantity__c).setScale(0);
                                strPaymentSchedule = String.format(paySchedule.format(), args);
                                strParent = objAddonQL.SBQQ__ProductCode__c + ' minimum commitment of ';
                                strParent += objQL.Back_End_Capacity_TB__c + ' TB at $' + objAddonQL.CPQ_MSP_Sales_Price__c;
                                strParent += ' for ' + String.format(objQL.SBQQ__RequiredBy__r.SBQQ__Quantity__c.format(), args) + ' Appliance ';
                                strParent += ' = $' + strPaymentSchedule;
                                if (objAddonQL.SBQQ__EffectiveQuantity__c > 0) {
                                paymentParent += paySchedule;
                                lstPaymentScheduleToDisplay.add(strParent);
                                }
                            }
                        }
                        
                    }
                    if(displayPayment == MDQProdCount) {
                        System.debug('into Payment-----');
                        strPaymentParent = String.format(paymentParent.format(), args);
                        strPaymentToDisplay = 'Payment of $' + strPaymentParent + ' due per month';
                        lstPaymentScheduleToDisplay.add(strPaymentToDisplay);
                        lstPaymentScheduleToDisplay.add('');
                        lstPaymentScheduleToDisplay.add('');
                        displayPayment = 0;
                        paymentParent = 0;
                        paySchedule = 0;
                    }
                }
            }
        }
        System.debug('lstPaymentScheduleToDisplay==Size==='+lstPaymentScheduleToDisplay.size());
        for(String str : lstPaymentScheduleToDisplay){
            System.debug('lstPaymentScheduleToDisplay====='+str);
        }
    }
    
    public class wrapperQuoteLines{ 
        public Decimal prodQty             {get; set;}
        public String prodCode             {get; set;}
        public String prodDescription      {get; set;}
        public Decimal prodTerm            {get; set;}
        public Decimal prodSalesPrice      {get; set;}
        public Decimal prodNetTotal        {get; set;}
        public Decimal prodBackendCapacity {get; set;}
        //public Boolean showSalesPrice    {get; set;}
        public String netTotal             {get; set;}
        public String strProdQty           {get; set;}
        public String strSalesPrice        {get; set;}
        
        public wrapperQuoteLines(){
            prodQty = 0;
            prodTerm = 0;
            prodSalesPrice = 0;
            prodNetTotal = 0;
            prodBackendCapacity = 0;
            netTotal = '';
            strProdQty = '';
            strSalesPrice = '';
        }
    }
}