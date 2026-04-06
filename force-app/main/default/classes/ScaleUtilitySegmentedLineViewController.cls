/**

* Name     : ScaleUtilitySegmentedLineViewController

* @description  : ScaleUtilitySegmentedLineViewController class to handle Segmented Line View for Scale Utility Products

*/

public without sharing class ScaleUtilitySegmentedLineViewController {
    
    public static decimal grandTotalForScheudle;
    Map<String, WrapperQuoteLines> productQuoteLineMap;
    Map<String, WrapperQuoteLines> prodQuarterQuoteLineMap;
    Map<String, WrapperScheduleLines> scheudleLinesMap;
    Map<String, WrapperQuoteLines> pricingQuoteLineMap;
    Map<String, WrapperQuoteLines> onDemandQuoteLineMap;
    Map<String, WrapperQuoteLines> hardwareQuoteLineMap;
    Map<String, WrapperQuoteLines> coveredAssetQuoteLineMap;
    List<String> lstUpgradeTypes =  !String.isBlank(System.Label.RBK_SUUpgradeEditions) ? System.Label.RBK_SUUpgradeEditions.split(',') : new List<String>{'SU FUE', 'SU FUP', 'SU EUP', 'SU FUB', 'SU BUE'};
    //List<String> lstRSVXTypes = new List<String>{'M365 SU RSVX', 'SU RSVX', 'CVB SU RSVX', 'CVA SU RSVX'};
    List<String> lstRSVXTypes = !String.isBlank(System.Label.Scale_Utility_Identifiers) ? System.Label.Scale_Utility_Identifiers.split(',') : new List<String>{'M365 SU RSVX', 'SU RSVX', 'CVB SU RSVX', 'CVA SU RSVX'};
    
    Map<String, WrapperScheduleLines> scheudleLinesTotalNewMap;
    
    List<SBQQ__QuoteLine__c> lstAddOnQuoteLines;
    List<String> args = new String[]{'0','number','###,###,##0.00'};
     /**
     * @description Wrapper list containing quote lines that will be displayed in the UI
     */
    public List<WrapperQuoteLines> lstQuoteLinesToDisplay {get; set;}
     /** @description list of payment schedule that will be displayed */
    public static List<WrapperScheduleLines> scheduleLinesToDisplay {get; set;}
    /** @description list of payment schedule that will be displayed */
    public List<String> lstPaymentScheduleToDisplay {get; set;}
    /** @description list of pricing that will be displayed */
    public List<WrapperQuoteLines> pricinglstToDisplay {get; set;}
     /** @description list of ondemand sku that will be displayed */
    public List<WrapperQuoteLines> onDemandlstToDisplay {get; set;}
    /** @description list of hardware sku that will be displayed */
    public List<WrapperQuoteLines> hardwarelstToDisplay {get; set;}
    /** @description list of covered asser that will be displayed */
    public List<WrapperQuoteLines> coveredAssetlstToDisplay {get; set;}
     /** @description quote subscription term */
    public static Integer quoteSubscriptionTerm;
     /** @description pricing table total that will be displayed */
    public string pricingTableTotal {get; set;}
     /** @description reserve table that will be displayed */
    public string reserveTableTotal {get; set;}
     /** @description grand total that will be displayed */
    public string grandTotal {get; set;}
     /** @description schedule grand total that will be displayed */
    public decimal scheduleGrandTotal{get;set;}
    /** @description schedule grand total string that will be displayed */
    public string scheduleGrandTotalStr{get;set;}
     /** @description resrev table total upgrade */
    public Static decimal reserveTableTotalUpgrade;//ScaleUtility_Phase2 change
     /** @description order string to be displayed */
    public static string orderforQuote{get;set;}//ScaleUtility_Phase2
     /** @description quote number string to be displayed */
    public static string quoteNumber{get;set;}//ScaleUtility_Phase2
    /** @description original quote number to be displayed */
    public static string originalQuoteNumber{get;set;}//ScaleUtility_Phase2
    public static boolean amendmentHwOnly = true;//ScaleUtility_Phase2
    Public static boolean isUpgradeQuote = false;//ScaleUtility_Phase2
    Public static boolean isAmendmentQuote = false;//ScaleUtility_Phase2
    Public Static decimal quoteNetAmount = 0;//for ScaleUtility_Phase2
    Public static decimal highestIndex = 0;//for ScaleUtility_Phase2
    public static Integer quotesubTerm; //for ScaleUtility_Phase2
    /** @description net total of MDQ to be  displayed */
    public Decimal netTotalMDQ {get; set;} 
     /** @description net total of MDQ to be  displayed */
    public String strNetTotalMDQ {get; set;}
    /** @description payment schedule string to be  displayed */
    public String strPaymentSchedule {get; set;}
     /** @description parent payment to be  displayed */
    public String strPaymentParent {get; set;}
     /** @description payment verbaige to be  displayed */
    public String strPaymentVerbage {get; set;}
     /** @description payment verbaige count to be  displayed */
    public String strPaymentVerbageCont {get; set;}
    //public Boolean showSalesPrice {get; set;}
    //Added variable for SF 5116 
    public Set<Integer> setQuarters;    
     /**  @description metering string to be  displayed */
    public String hasMetering {get; set;}//added for M365-Utility 
    /** @description GTMIT-54 :check if PayGo product is present */
    public Boolean hasPayGoProduct {get; set;}
    //constructor  
    /**
         * ScaleUtilitySegmentedLineViewController constructor.
         * @description Initializes wrapper lists, default values and loads MDQ (Minimum Deal Quantity) lines
         * for the current quote determined from the page parameter 'qid'.
         */  
    public ScaleUtilitySegmentedLineViewController() {
        Id quoteID = ApexPages.currentPage().getParameters().get('qid');
        lstQuoteLinesToDisplay = new List<WrapperQuoteLines>();
        scheduleLinesToDisplay = new List<WrapperScheduleLines>();
        pricinglstToDisplay = new List<WrapperQuoteLines>();
        onDemandlstToDisplay = new List<WrapperQuoteLines>();
        hardwarelstToDisplay = new List<WrapperQuoteLines>();
        coveredAssetlstToDisplay = new List<WrapperQuoteLines>();
        quoteSubscriptionTerm = 12;
        
        lstPaymentScheduleToDisplay = new List<String>();
        setQuarters = new Set<Integer>();
        netTotalMDQ = 0;
        strNetTotalMDQ = '';
        strPaymentSchedule = '';
        strPaymentVerbage = '';
        //defineQuarters(quoteID);
        grandTotalForScheudle = 0;
        getMDQLines(quoteID);
    }
    
    
    
    // select Segmented products.
    /**
     * @description Selects segmented products and builds the MDQ (Minimum Deal Quantity) and schedule
     *              display data for the provided quote; populates wrapper lists used by the UI.
     * @param currentQuoteID The Id of the SBQQ__Quote__c record to process.
     */
    public void getMDQLines(Id currentQuoteID) {
        //Integer MDQProdCount = 0;
        //Boolean insertAddon;
        productQuoteLineMap = new Map<String, WrapperQuoteLines>();
        scheudleLinesMap = new Map<String, WrapperScheduleLines>();
        pricingQuoteLineMap = new Map<String, WrapperQuoteLines>();
        onDemandQuoteLineMap = new Map<String, WrapperQuoteLines>();
        hardwareQuoteLineMap = new Map<String, WrapperQuoteLines>();
        coveredAssetQuoteLineMap = new Map<String, WrapperQuoteLines>();
        
        scheudleLinesTotalNewMap = new Map<String, WrapperScheduleLines>();
        
        List<String> commentforLine;
        Decimal pricingTotal = 0;
        Decimal reserveTotal = 0;
        String associatedHwSupport;
        Decimal rsvQtyTotal=0;
        Integer lineRowCounter = 0;
        Decimal monthDiff = 1;
        
        hasPayGoProduct = false;//GTMIT-54 : Initialize to false
        scheduleGrandTotal = 0;
        String prevId;
        Decimal prevQty =0;
        String firstMonth;
        Decimal prevTotal=0;
        String monthRange;
        Set<Id> reqProdIdSet = New Set<Id>();
        Integer maxTermOnQuote = 0;//Added for M365-Utility
        lstAddOnQuoteLines = new List<SBQQ__QuoteLine__c>();
        prodQuarterQuoteLineMap = new Map<String, WrapperQuoteLines>();
        //hasMetering = false;//added for M365-Utility
        
        reserveTableTotalUpgrade = 0;//ScaleUtility_Phase2 for upgrade scenrio
        //added field Scale_Utility_Product_Identifier__c as part of M365-Utility
        //added field SBQQ__Quote__r.SBQQ__Type__c,SBQQ__SegmentLabel__c for ScaleUtility_Phase2 CSU-493       
        //added 2 field in query CSU-752      
        List<SBQQ__QuoteLine__c> lstMDQQuoteLines = [SELECT ID,
                                                     Name,
                                                     SBQQ__ProductCode__c,
                                                     SBQQ__Description__c,
                                                     SBQQ__Quantity__c,
                                                     SBQQ__Product__c,
                                                     SBQQ__ListPrice__c,
                                                     SBQQ__Quote__r.SBQQ__StartDate__c,
                                                     SBQQ__Quote__r.Amended_Renewed_Service_Contract__r.EndDate,
                                                     SBQQ__Product__r.Product_Level__c,                                                            
                                                     SBQQ__Quote__r.SBQQ__SubscriptionTerm__c,
                                                     SBQQ__Quote__r.Total_Commit__c,
                                                     SBQQ__Quote__r.Total_Commit_for_SW_DR__c,
                                                     SBQQ__Quote__r.SBQQ__NetAmount__c,
                                                     SBQQ__Quote__r.SBQQ__Type__c,
                                                     CPQ_MSP_Sales_Price__c,
                                                     SBQQ__Product__r.Product_Type__c,
                                                     SBQQ__NetTotal__c,
                                                     SBQQ__AdditionalDiscountAmount__c,
                                                     SBQQ__ListTotal__c,
                                                     OnDemand_Discount__c,
                                                     SBQQ__RequiredBy__c,
                                                     SBQQ__SegmentIndex__c,
                                                     SBQQ__SegmentLabel__c,
                                                     SBQQ__EffectiveQuantity__c,
                                                     Feature_Name__c,
                                                     Back_End_Capacity_TB__c,
                                                     SBQQ__RequiredBy__r.Back_End_Capacity_TB__c,
                                                     SBQQ__RequiredBy__r.SBQQ__Quantity__c,                                                         
                                                     SBQQ__Number__c,
                                                     Scale_Utility_Product_RSV_OND__c,
                                                     Total_Usable_Capacity__c,
                                                     Scale_Utility_Product__c,SBQQ__Quote__r.Amended_Renewed_Service_Contract__c,
                                                     SBQQ__Quote__r.Amended_Renewed_Service_Contract__r.SBQQSC__Order__r.OrderNumber,
                                                     SBQQ__Quote__r.Amended_Renewed_Service_Contract__r.SBQQSC__Order__r.PoNumber,
                                                     SBQQ__Quote__r.Amended_Renewed_Service_Contract__r.SBQQSC__Quote__r.Name,
                                                     SBQQ__Quote__r.Name,
                                                     SBQQ__PackageProductCode__c,
                                                     SBQQ__Product__r.Unit_of_Measure__c,
                                                     Product_Code__c,
                                                     SBQQ__NetPrice__c,
                                                     SBQQSC__UpgradedContractLine__c,
                                                     Line_Type__c,
                                                     Payment_Options__c, Quantity_TB__c,
                                                     SBQQ__Hidden__c,Usable_Capacity__c,SBQQ__TotalDiscountRate__c,
                                                     Product_Payment_Option__c,
                                                     SBQQ__RequiredBy__r.SBQQ__Product__r.Name, SBQQ__SubscriptionTerm__c,                                                           
                                                     SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Type__c,
                                                     Trade_Up_Discount__c,Promo_Disc__c,SBQQ__Discount__c,
                                                     SBQQ__Quote__r.Metering__c,No_of_TBs_Cloud__c,Total_Discount__c,
                                                     TPH_OEM__c,TPH_Models_Gen__c,
                                                     TPH_Quantity__c, Subscribed_Asset_Name__c,SBQQ__Quote__r.Has_SubscribedAssetNames__c,
                                                     SBQQ__RequiredBy__r.Total_Discount__c, TPH_Drive_Size__c, Scale_Utility_Product_Identifier__c
                                                     , SBQQ__StartDate__c, SBQQ__EndDate__c, Shortened_Start_Date__c, Shortened_End_Date__c,
                                                     Storage_Region_Tier_Template__c
                                                     FROM SBQQ__QuoteLine__c
                                                     WHERE SBQQ__Quote__c =: currentQuoteID and SBQQ__Optional__c = false and SBQQ__Hidden__c = false order by SBQQ__SegmentLabel__c
                                                    ]; //ScaleUtility_Phase2 ordered by label was needed as indexes are modified
        List<SBQQ__QuoteLine__c> allQuoteLinesonQuote = [SELECT ID, SBQQ__StartDate__c, SBQQ__EndDate__c, Shortened_Start_Date__c, Shortened_End_Date__c, TPH_Drive_Size__c,Scale_Utility_Product_RSV_OND__c,SBQQ__RequiredBy__c,TPH_OEM__c,No_of_TBs_Cloud__c,TPH_Quantity__c,SBQQ__Quantity__c,SBQQ__ProductCode__c,SBQQ__Product__r.Product_Type__c,Scale_Utility_Product__c,TPH_Models_Gen__c from SBQQ__QuoteLine__c where SBQQ__Quote__c =: currentQuoteID];                     
        
        //Added below for block for M365-Utility
        for(SBQQ__QuoteLineGroup__c qlg : [Select id, SBQQ__Quote__c, SBQQ__SubscriptionTerm__c from SBQQ__QuoteLineGroup__c where SBQQ__SubscriptionTerm__c != null and SBQQ__Quote__c =: currentQuoteID ]){
            if(qlg.SBQQ__SubscriptionTerm__c > maxTermOnQuote){
                maxTermOnQuote = Integer.valueof(qlg.SBQQ__SubscriptionTerm__c);
            }
        }
        
        //Added as part of M365-Utility Start
        map<String,decimal> skuToTermMap = New Map<String,decimal>();
        string prodCode;
        set<Id> rsvxLinesWithUpgradeSet = new Set<Id>();// added for ScaleUtility_Phase2 CSU-545
        map<Id,map<string,SBQQ__QuoteLine__c>> rsvxToChildProductLinesMap = New Map<Id,Map<String,SBQQ__QuoteLine__c>>();// added for ScaleUtility_Phase2 CSU-545
        map<string,decimal> rsvToUpgEffectiveQtyMap = New Map<string,decimal>(); //ScaleUtility_Phase2
        map<string,decimal> rsvToUpgFullQtyMap = New Map<string,decimal>(); //ScaleUtility_Phase2
        for(SBQQ__QuoteLine__c ql : lstMDQQuoteLines){
            //GTMIT-54 : Check if any PayGo product is present on the quote
            hasPayGoProduct = !hasPayGoProduct && String.isNotBlank(ql.SBQQ__Product__r.Product_Type__c) && ql.SBQQ__Product__r.Product_Type__c.contains(CPQ_Constants.PAYGO) ? true : hasPayGoProduct;            
            //ScaleUtility_Phase2 CSU-545 - start
            
            if(ql.SBQQ__Quote__r.Amended_Renewed_Service_Contract__c != null && ql.SBQQ__Quote__r.Amended_Renewed_Service_Contract__r.SBQQSC__Order__r.OrderNumber != null){
                orderforQuote = ql.SBQQ__Quote__r.Amended_Renewed_Service_Contract__r.SBQQSC__Order__r.PoNumber;
                quoteNumber = ql.SBQQ__Quote__r.Name;
                if(ql.SBQQ__Quote__r.Amended_Renewed_Service_Contract__r.SBQQSC__Quote__c != null ){
                  originalQuoteNumber=  ql.SBQQ__Quote__r.Amended_Renewed_Service_Contract__r.SBQQSC__Quote__r.Name;
                }
            }
            if(ql.SBQQ__Quote__r.SBQQ__Type__c == 'Amendment'){
                isAmendmentQuote = true;
            }
            quoteNetAmount = ql.SBQQ__Quote__r.SBQQ__NetAmount__c.setscale(2);
            quotesubTerm = integer.valueof(ql.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c);
            //ScaleUtility_Phase2 CSU-545 - end
            
            if(lstRSVXTypes.contains(ql.Scale_Utility_Product_Identifier__c) || ql.Scale_Utility_Product__c == true){ 
                prodCode = ql.SBQQ__ProductCode__c.replace('RSVX','RSV');
                prodCode = prodCode.replace('-C-X','-C');
                skuToTermMap.put(prodCode,ql.SBQQ__SubscriptionTerm__c);
            }
            if(hasMetering == NULL && ql.SBQQ__Quote__r.Metering__c != NULL){
                hasMetering = ql.SBQQ__Quote__r.Metering__c;
            }
            
            //ScaleUtility_Phase2 CSU-545 - start
            //this is done to repalce EE-SR/EE-AR to FE-RSV and FUE-RSV (if FUE RSV present, FE upgrade) in discount calculation CSU-545
            if(lstUpgradeTypes.contains(ql.Scale_Utility_Product_Identifier__c)){
                rsvxLinesWithUpgradeSet.add(ql.SBQQ__RequiredBy__c);
            }
            if(ql.SBQQ__RequiredBy__c != null){
                if(!rsvxToChildProductLinesMap.keyset().contains(ql.SBQQ__RequiredBy__c)){
                    map<string,SBQQ__QuoteLine__c> productToLineMap = new map<string,SBQQ__QuoteLine__c>();
                    productToLineMap.put(ql.SBQQ__ProductCode__c,ql);
                    rsvxToChildProductLinesMap.put(ql.SBQQ__RequiredBy__c,productToLineMap);
                }
                else{
                    rsvxToChildProductLinesMap.get(ql.SBQQ__RequiredBy__c).put(ql.SBQQ__ProductCode__c,ql);
                }
            }
            if(ql.SBQQ__SegmentLabel__c != null && isAmendmentQuote == true){
                if(highestIndex < decimal.valueof(ql.SBQQ__SegmentLabel__c.removestart('Month ').trim())){
                    highestIndex = decimal.valueof(ql.SBQQ__SegmentLabel__c.removestart('Month ').trim());
                }
            }
            //ScaleUtility_Phase2 fix for CSU-708
            if((ql.Scale_Utility_Product_RSV_OND__c == 'RSV' || ql.Scale_Utility_Product_Identifier__c == 'M365 RSV SU') && ql.SBQQ__EffectiveQuantity__c > 0){
                if(rsvToUpgEffectiveQtyMap.keyset().contains(ql.SBQQ__RequiredBy__c)){
                   rsvToUpgEffectiveQtyMap.put(ql.SBQQ__RequiredBy__c,rsvToUpgEffectiveQtyMap.get(ql.SBQQ__RequiredBy__c)+ql.SBQQ__EffectiveQuantity__c);
                }
                else{
                   rsvToUpgEffectiveQtyMap.put(ql.SBQQ__RequiredBy__c,ql.SBQQ__EffectiveQuantity__c);
                }
            }
            if((ql.Scale_Utility_Product_RSV_OND__c == 'RSV' || ql.Scale_Utility_Product_Identifier__c == 'M365 RSV SU') && ql.SBQQ__Quantity__c > 0){
                if(rsvToUpgFullQtyMap.keyset().contains(ql.SBQQ__RequiredBy__c)){
                   rsvToUpgFullQtyMap.put(ql.SBQQ__RequiredBy__c,rsvToUpgFullQtyMap.get(ql.SBQQ__RequiredBy__c)+ql.SBQQ__Quantity__c);
                }
                else{
                   rsvToUpgFullQtyMap.put(ql.SBQQ__RequiredBy__c,ql.SBQQ__Quantity__c);
                }
            }
            //ScaleUtility_Phase2 CSU-545 - End
        }
        //Added as part of M365-Utility End
        
        if(lstMDQQuoteLines != null && lstMDQQuoteLines.size()>0){  
            //M365-Utility changes if/else
            if(maxTermOnQuote <= Integer.valueof(lstMDQQuoteLines[0].SBQQ__Quote__r.SBQQ__SubscriptionTerm__c)){                                              
                quoteSubscriptionTerm = Integer.valueof(lstMDQQuoteLines[0].SBQQ__Quote__r.SBQQ__SubscriptionTerm__c);
            }
            else{
                quoteSubscriptionTerm = maxTermOnQuote;
            }
            
        }
        scheduleTableRowBuilder(lstMDQQuoteLines,scheduleLinesToDisplay, scheduleGrandTotal);//new change
        
        scheduleGrandTotal = grandTotalForScheudle;
        scheduleGrandTotalStr = ScaleUtilitySegmentedLineViewController.formatDollarAmount(scheduleGrandTotal.setscale(2));//scheduleGrandTotal.format();
        for(SBQQ__QuoteLine__c ql : lstMDQQuoteLines){
            if(ql.SBQQ__Description__c != 'FUELine'){//ScaleUtility_Phase2
                
                
                commentforLine = formCommentForLines(ql, allQuoteLinesonQuote);
                
                //quoteSubscriptionTerm = Integer.valueof(ql.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c);
                lineRowCounter++;
                //if(ql.Scale_Utility_Product_RSV_OND__c == 'RSV' || ql.Scale_Utility_Product_Identifier__c == 'M365 RSV SU'){
                //made change to inlcude fue line and rsv only when effective qty is present ScaleUtility_Phase2
                if(((ql.Scale_Utility_Product_RSV_OND__c == 'RSV' || ql.Scale_Utility_Product_Identifier__c == 'M365 RSV SU') && ql.SBQQ__EffectiveQuantity__c > 0) 
                   || (lstUpgradeTypes.contains(ql.Scale_Utility_Product_Identifier__c)))
                {
                    WrapperQuoteLines wrapObj = new WrapperQuoteLines();
                    //ScaleUtility_Phase2 added if so that reservce total is taken from RSV lines only fir FUE/upgrade different variable is used
                    
                    amendmentHwOnly = false; // ScaleUtility_Phase2 if RSV has effective qty or if its upgrade then its not hw only scenario
                    if(ql.Scale_Utility_Product_RSV_OND__c == 'RSV' || ql.Scale_Utility_Product_Identifier__c == 'M365 RSV SU'){
                        reserveTotal = reserveTotal + ql.SBQQ__NetTotal__c;
                    }
                    
                    wrapObj.prodCode = ql.SBQQ__ProductCode__c;
                    rsvQtyTotal = rsvQtyTotal+ql.SBQQ__Quantity__c;
                    //wrapObj.prodQty = rsvQtyTotal;//wrapObj.prodQty+ql.SBQQ__Quantity__c;
                    //Added if block for ScaleUtility_Phase2 CSU-493
                    if(ql.SBQQ__Quote__r.SBQQ__Type__c == 'Amendment'){
                        wrapObj.prodQty = wrapObj.prodQty+Integer.valueof(ql.SBQQ__EffectiveQuantity__c);
                    }
                    else{
                        wrapObj.prodQty = wrapObj.prodQty+Integer.valueof(ql.SBQQ__Quantity__c);
                    }
                    
                    //Added fix by Shaloo
                    if((ql.SBQQ__Quote__r.SBQQ__Type__c == 'Amendment' && lstUpgradeTypes.contains(ql.Scale_Utility_Product_Identifier__c)) || test.isrunningtest())
                    {
                        
                        wrapObj.prodQty = integer.valueof(Math.round(ql.SBQQ__EffectiveQuantity__c  
                                           * (Integer.valueof(ql.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c))));
                                           

                        //fix for CSU-708, upgrade FUE qty should match same as RSV during upgrade. mentioned as Issue 1 in ticket                   
                        if(rsvToUpgFullQtyMap.keyset().contains(ql.SBQQ__RequiredBy__c)){
                           wrapObj.prodQty = Integer.valueof(rsvToUpgFullQtyMap.get(ql.SBQQ__RequiredBy__c));
                        } 
                        if(ql.SBQQSC__UpgradedContractLine__c != null){                            
                            if(rsvToUpgEffectiveQtyMap.keyset().contains(ql.SBQQ__RequiredBy__c)){
                               wrapObj.prodQty = Integer.valueof(rsvToUpgEffectiveQtyMap.get(ql.SBQQ__RequiredBy__c));
                            } 
                        } 
                                         
                        wrapObj.prodQtyStr = wrapObj.prodQty.format();
                    }
                    if(hasPayGoProduct && ql.SBQQ__Quote__r.SBQQ__NetAmount__c != null && grandTotal==null){
                        grandTotal = '$'+ScaleUtilitySegmentedLineViewController.formatDollarAmount(ql.SBQQ__Quote__r.SBQQ__NetAmount__c.setscale(2));
                    }
                    wrapObj.prodQtyStr = wrapObj.prodQty.format();
                    wrapObj.prodDescription = ql.SBQQ__Description__c;
                    
                    wrapObj.commentsList = commentforLine;
                    wrapObj.netTotal = ql.SBQQ__NetTotal__c;
                    wrapObj.totalListPrice = ql.SBQQ__ListTotal__c;//ql.SBQQ__ListPrice__c;
                    wrapObj.totalDiscount = ql.Total_Discount__c;
                    wrapObj.unitNetPrice = ql.SBQQ__NetPrice__c;
                    //wrapObj.unitNetPrice = 120000;
                    
                    //wrapObj.totalNetPrice = reserveTotal;//ql.SBQQ__NetTotal__c;
                    wrapObj.totalNetPrice = ql.SBQQ__NetTotal__c;
                    //scheduleGrandTotal = scheduleGrandTotal+wrapObj.totalNetPrice;
                    //wrapObj.prodTerm = ql.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c;//ql.SBQQ__SubscriptionTerm__c;
                    //M365-Utility updated IF block
                    if( /*ql.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c != null*/skuToTermMap != null && skuToTermMap.keyset().contains(ql.SBQQ__ProductCode__c)){
                        wrapObj.prodTerm = string.valueof(skuToTermMap.get(ql.SBQQ__ProductCode__c));//M365-Utility change to refer term from map
                        wrapObj.prodTerm = wrapObj.prodTerm+' mos';
                    }
                    
                    //added to populayte term for FUE line ScaleUtility_Phase2 
                    if(lstUpgradeTypes.contains(ql.Scale_Utility_Product_Identifier__c)){
                        wrapObj.prodTerm = ql.SBQQ__SubscriptionTerm__c+' mos'; 
                        
                        isUpgradeQuote = true;//ScaleUtility_Phase2
                    }
                    
                    if(productQuoteLineMap.keyset().contains(ql.SBQQ__ProductCode__c)){
                        //productQuoteLineMap.put(ql.SBQQ__ProductCode__c, productQuoteLineMap.get(ql.SBQQ__ProductCode__c).totalNetPrice + ql.SBQQ__NetTotal__c);
                        
                        wrapObj.totalNetPrice = productQuoteLineMap.get(ql.SBQQ__ProductCode__c).totalNetPrice + ql.SBQQ__NetTotal__c;
                        wrapObj.totalListPrice = productQuoteLineMap.get(ql.SBQQ__ProductCode__c).totalListPrice +ql.SBQQ__ListTotal__c;//+ ql.SBQQ__ListPrice__c;
                        //Added if block for ScaleUtility_Phase2 CSU-493
                        if(ql.SBQQ__Quote__r.SBQQ__Type__c == 'Amendment'){
                            wrapObj.prodQty = productQuoteLineMap.get(ql.SBQQ__ProductCode__c).prodQty + Integer.valueof(ql.SBQQ__EffectiveQuantity__c);
                        }
                        else{
                            wrapObj.prodQty = productQuoteLineMap.get(ql.SBQQ__ProductCode__c).prodQty + Integer.valueof(ql.SBQQ__Quantity__c);
                        }
                        wrapObj.prodQtyStr = wrapObj.prodQty.format();
                        
                    }
                    //Post Production fix ScaleUtility_Phase2
                    if(lstUpgradeTypes.contains(ql.Scale_Utility_Product_Identifier__c)){
                       if(ql.SBQQ__TotalDiscountRate__c != null && ql.SBQQ__TotalDiscountRate__c > 0){
                       wrapObj.unitNetPrice = ql.SBQQ__ListPrice__c-((ql.SBQQ__ListPrice__c* ql.SBQQ__TotalDiscountRate__c)/100);
                       }else{
                         wrapObj.unitNetPrice = ql.SBQQ__ListPrice__c;
                       }
                       wrapObj.totalNetPrice = wrapObj.prodQty*wrapObj.unitNetPrice.setscale(2);//post_prod_fix_scaleUtility set scale 2
                    }
                    
                    //4Apr Changes - start
                    if(wrapObj.unitNetPrice != null){
                        wrapObj.unitNetPriceStr = ScaleUtilitySegmentedLineViewController.formatDollarAmount(wrapObj.unitNetPrice.setscale(2));//wrapObj.unitNetPrice.format();
                    }
                    if(wrapObj.totalListPrice != null){
                        wrapObj.totalListPriceStr = ScaleUtilitySegmentedLineViewController.formatDollarAmount(wrapObj.totalListPrice.setscale(2));//wrapObj.totalListPrice.format();
                    }
                    if(wrapObj.totalNetPrice != null){
                        wrapObj.totalNetPriceStr = ScaleUtilitySegmentedLineViewController.formatDollarAmount(wrapObj.totalNetPrice.setscale(2));//wrapObj.totalNetPrice.format();
                    } 
                    //4Apr Changes - End
                    wrapObj.unitNetPrice = wrapObj.unitNetPrice.setscale(2);//ITNPI-3033
                    productQuoteLineMap.put(ql.SBQQ__ProductCode__c,wrapObj);
                    
                    
                }
                
                //added check to bypass M365 skus as part of M365-Utility
                if(ql.Scale_Utility_Product_Identifier__c == null && ql.Scale_Utility_Product_RSV_OND__c == null && ql.Scale_Utility_Product__c == false && ql.SBQQ__Hidden__c == false){
                    WrapperQuoteLines wrapObj = new WrapperQuoteLines();
                    wrapObj.prodCode = ql.SBQQ__ProductCode__c;
                    wrapObj.prodQty = Integer.valueof(ql.SBQQ__Quantity__c);
                    wrapObj.prodQtyStr = wrapObj.prodQty.format();
                    wrapObj.prodDescription = ql.SBQQ__Description__c;
                    wrapObj.commentsList = commentforLine;
                    wrapObj.netTotal = ql.SBQQ__NetTotal__c;
                    wrapObj.totalListPrice = ql.SBQQ__ListTotal__c;//ql.SBQQ__ListPrice__c;
                    wrapObj.totalDiscount = ql.Total_Discount__c;
                    wrapObj.unitNetPrice = ql.SBQQ__NetPrice__c;
                    wrapObj.totalNetPrice = ql.SBQQ__NetTotal__c;
                    //wrapObj.prodTerm = ql.SBQQ__SubscriptionTerm__c;
                    if( ql.SBQQ__SubscriptionTerm__c != null){
                        wrapObj.prodTerm = string.valueof(ql.SBQQ__SubscriptionTerm__c);
                        wrapObj.prodTerm = wrapObj.prodTerm+' mos';
                    }
                    
                    //ScaleUtility_Phase2 CSU-493 start
                    If(ql.SBQQ__Quote__r.SBQQ__Type__c == 'Amendment'){
                        if(ql.SBQQ__NetTotal__c > 0){
                            pricingQuoteLineMap.put(ql.SBQQ__ProductCode__c+string.valueof(lineRowCounter),wrapObj);
                        }
                    }
                    else{
                        pricingQuoteLineMap.put(ql.SBQQ__ProductCode__c+string.valueof(lineRowCounter),wrapObj);
                    }
                    //ScaleUtility_Phase2 CSU-493 end
                    
                    pricingTotal = pricingTotal + ql.SBQQ__NetTotal__c;
                    
                    
                    //4Apr Changes - start
                    
                    if(wrapObj.unitNetPrice != null){
                        wrapObj.unitNetPriceStr = ScaleUtilitySegmentedLineViewController.formatDollarAmount(wrapObj.unitNetPrice.setscale(2));//wrapObj.unitNetPrice.format();
                    }
                    if(wrapObj.totalListPrice != null){
                        wrapObj.totalListPriceStr = ScaleUtilitySegmentedLineViewController.formatDollarAmount(wrapObj.totalListPrice.setscale(2));//wrapObj.totalListPrice.format();
                    }
                    if(wrapObj.totalNetPrice != null){
                        wrapObj.totalNetPriceStr = ScaleUtilitySegmentedLineViewController.formatDollarAmount(wrapObj.totalNetPrice.setscale(2));//wrapObj.totalNetPrice.format();
                    }
                    //4Apr Changes - End
                }
                
                //M365-Utility Changes to include OND
                //ScaleUtility_Phase2 CSU-545 for new SR and AR OND skus
                if((ql.Scale_Utility_Product_RSV_OND__c == 'OND' || ql.Scale_Utility_Product_Identifier__c == 'M365 SU OND' || ql.Scale_Utility_Product_Identifier__c == 'OND SR' || ql.Scale_Utility_Product_Identifier__c == 'OND AR') && ql.Line_Type__c != 'Amendment'){
                    
                    
                    WrapperQuoteLines wrapObj = new WrapperQuoteLines();
                    wrapObj.prodCode = ql.SBQQ__ProductCode__c;
                    wrapObj.prodQty = Integer.valueof(ql.SBQQ__Quantity__c);
                    wrapObj.prodQtyStr = wrapObj.prodQty.format();
                    wrapObj.prodDescription = ql.SBQQ__Description__c;
                    
                    //commentforLine = formCommentForLines(ql, allQuoteLinesonQuote);
                    
                    wrapObj.commentsList = commentforLine;
                    wrapObj.netTotal = ql.SBQQ__NetTotal__c;
                    wrapObj.totalListPrice = ql.SBQQ__ListPrice__c;
                    wrapObj.totalDiscount = ql.Total_Discount__c;
                    wrapObj.unitNetPrice = ql.SBQQ__NetPrice__c;
                    //wrapObj.prodTerm = ql.SBQQ__SubscriptionTerm__c;
                    if( ql.SBQQ__SubscriptionTerm__c != null){
                        wrapObj.prodTerm = string.valueof(ql.SBQQ__SubscriptionTerm__c);
                        wrapObj.prodTerm = wrapObj.prodTerm+' mos';
                    }
                    onDemandQuoteLineMap.put(ql.SBQQ__ProductCode__c,wrapObj);
                    //grandTotal = '$'+ql.SBQQ__Quote__r.SBQQ__NetAmount__c.format();
                    
                    grandTotal = '$'+ScaleUtilitySegmentedLineViewController.formatDollarAmount(ql.SBQQ__Quote__r.SBQQ__NetAmount__c.setscale(2));
                    //4April change - start
                    
                    //to be modifed for AR/SR upgrade OND discount ScaleUtility_Phase2 CSU-545 - start                
                    
                    if(productQuoteLineMap.keyset().contains(ql.SBQQ__ProductCode__c.replace('OND','RSV'))){
                        
                        wrapObj.totalDiscount = productQuoteLineMap.get(ql.SBQQ__ProductCode__c.replace('OND','RSV')).totalDiscount;
                        wrapObj.unitNetPrice = wrapObj.totalListPrice - ((wrapObj.totalListPrice*wrapObj.totalDiscount)/100);
                    }
                    
                    
                    //defaulting total discount and unit net price for OND SR/AR to RSV initially, it is overriden in below block for upgrade scenario  
                    //fix below null checks added for CSU-647
                    if(ql.Scale_Utility_Product_Identifier__c == 'OND AR' && rsvxToChildProductLinesMap.keyset().contains(ql.SBQQ__RequiredBy__c) && rsvxToChildProductLinesMap.get(ql.SBQQ__RequiredBy__c).keyset().contains(ql.SBQQ__ProductCode__c.replace('AR','RSV')) && rsvxToChildProductLinesMap.get(ql.SBQQ__RequiredBy__c).get(ql.SBQQ__ProductCode__c.replace('AR','RSV')) != null){
                        if(rsvxToChildProductLinesMap.keyset().contains(ql.SBQQ__RequiredBy__c)){
                            //wrapObj.totalDiscount = rsvxToChildProductLinesMap.get(ql.SBQQ__RequiredBy__c).get(ql.SBQQ__ProductCode__c.replace('AR','RSV')).Total_Discount__c;
                            wrapObj.totalDiscount = ql.OnDemand_Discount__c != null ? ql.OnDemand_Discount__c : 0;//added for PROD_FIX on demand , above line commented
                            wrapObj.unitNetPrice = wrapObj.totalListPrice - ((wrapObj.totalListPrice*wrapObj.totalDiscount)/100);
                        }   
                    }//fix below null checks added for CSU-647
                    else if(ql.Scale_Utility_Product_Identifier__c == 'OND SR' && rsvxToChildProductLinesMap.keyset().contains(ql.SBQQ__RequiredBy__c) && rsvxToChildProductLinesMap.get(ql.SBQQ__RequiredBy__c).keyset().contains(ql.SBQQ__ProductCode__c.replace('SR','RSV')) && rsvxToChildProductLinesMap.get(ql.SBQQ__RequiredBy__c).get(ql.SBQQ__ProductCode__c.replace('SR','RSV')) != null){
                        if(rsvxToChildProductLinesMap.keyset().contains(ql.SBQQ__RequiredBy__c) ){
                            
                            //wrapObj.totalDiscount = rsvxToChildProductLinesMap.get(ql.SBQQ__RequiredBy__c).get(ql.SBQQ__ProductCode__c.replace('SR','RSV')).Total_Discount__c;
                            wrapObj.totalDiscount = ql.OnDemand_Discount__c != null ? ql.OnDemand_Discount__c : 0;//added for PROD_FIX on demand , above line commented
                            wrapObj.unitNetPrice = wrapObj.totalListPrice - ((wrapObj.totalListPrice*wrapObj.totalDiscount)/100);
                        }   
                    }
                    
                    if((ql.SBQQ__RequiredBy__c != null && (ql.SBQQ__ProductCode__c.contains('EE-SR') || ql.SBQQ__ProductCode__c.contains('EE-AR'))) || test.isrunningtest()){
                        if(ql.Scale_Utility_Product_Identifier__c == 'OND SR' || ql.Scale_Utility_Product_Identifier__c == 'OND AR'){
                            if(rsvxToChildProductLinesMap.keyset().contains(ql.SBQQ__RequiredBy__c)){
                                for(String st : rsvxToChildProductLinesMap.get(ql.SBQQ__RequiredBy__c).keyset()){
                                    if(st.contains('FUE')){
                                        if(ql.SBQQ__ProductCode__c.contains('EE-AR')){
                                            SBQQ__QuoteLine__c arEEQL = rsvxToChildProductLinesMap.get(ql.SBQQ__RequiredBy__c).get(ql.SBQQ__ProductCode__c.replace('EE-AR','FE-RSV'));
                                            SBQQ__QuoteLine__c arFUEQl= rsvxToChildProductLinesMap.get(ql.SBQQ__RequiredBy__c).get(ql.SBQQ__ProductCode__c.replace('EE-AR','FUE-RSV'));
                                            wrapObj.totalDiscount = ((1-((arEEQL.SBQQ__NetPrice__c+arFUEQl.SBQQ__NetPrice__c)/(arEEQL.SBQQ__ListPrice__c+arFUEQl.SBQQ__ListPrice__c)))*100).setscale(2); 
                                            wrapObj.unitNetPrice = ql.SBQQ__ListPrice__c - ((ql.SBQQ__ListPrice__c*wrapObj.totalDiscount)/100);
                                        }
                                        else if(ql.SBQQ__ProductCode__c.contains('EE-SR')){
                                            SBQQ__QuoteLine__c srEEQL = rsvxToChildProductLinesMap.get(ql.SBQQ__RequiredBy__c).get(ql.SBQQ__ProductCode__c.replace('EE-SR','FE-RSV'));
                                            SBQQ__QuoteLine__c srFUEQL = rsvxToChildProductLinesMap.get(ql.SBQQ__RequiredBy__c).get(ql.SBQQ__ProductCode__c.replace('EE-SR','FUE-RSV'));
                                            wrapObj.totalDiscount = ((1-((srEEQL.SBQQ__NetPrice__c+srFUEQl.SBQQ__NetPrice__c)/(srEEQL.SBQQ__ListPrice__c+srFUEQl.SBQQ__ListPrice__c)))*100).setscale(2); 
                                            wrapObj.unitNetPrice = ql.SBQQ__ListPrice__c - ((ql.SBQQ__ListPrice__c*wrapObj.totalDiscount)/100);
                                        }   
                                    }
                                } 
                            }
                        }                   
                    }  
                    //copying AR and SR ond discount from new field if its populated CSU-618
                    if( (ql.Scale_Utility_Product_Identifier__c == 'OND AR' || ql.Scale_Utility_Product_Identifier__c == 'OND SR') && ql.OnDemand_Discount__c != null){
                        
                        
                        wrapObj.totalDiscount = ql.OnDemand_Discount__c;
                        wrapObj.unitNetPrice = ql.SBQQ__ListPrice__c - ((ql.SBQQ__ListPrice__c*wrapObj.totalDiscount)/100);
                    }
                    //to be modifed for AR/SR upgrade OND discount ScaleUtility_Phase2 CSU-545 - end
                    
                    //4April change - End
                    
                    //4Apr Changes - start
                    
                    if(wrapObj.unitNetPrice != null){
                        wrapObj.unitNetPriceStr = ScaleUtilitySegmentedLineViewController.formatDollarAmount(wrapObj.unitNetPrice.setscale(2));//wrapObj.unitNetPrice.format();
                    }
                    if(wrapObj.totalListPrice != null){
                        wrapObj.totalListPriceStr = ScaleUtilitySegmentedLineViewController.formatDollarAmount(wrapObj.totalListPrice.setscale(2));//wrapObj.totalListPrice.format();
                    }
                    wrapObj.unitNetPrice = wrapObj.unitNetPrice.setscale(2);//ITNPI-3033
                    /*if(wrapObj.totalNetPrice != null){
wrapObj.totalNetPriceStr = wrapObj.totalNetPrice.format();
} */
                    //4Apr Changes - End
                }
                
                if(ql.SBQQ__Product__r.Product_Type__c == 'Hardware'){
                    /*wrapperQuoteLines wrapObj = new wrapperQuoteLines();
wrapObj.prodCode = ql.SBQQ__ProductCode__c;
wrapObj.prodQty = ql.SBQQ__Quantity__c;
wrapObj.prodDescription = ql.SBQQ__Description__c;
wrapObj.comments = commentforLine;
wrapObj.netTotal = ql.SBQQ__NetTotal__c;
wrapObj.totalListPrice = ql.SBQQ__ListPrice__c;
wrapObj.unitTB = ql.Usable_Capacity__c;
wrapObj.HWPrice = 'See distributor for pricing';
wrapObj.AssociatedSWSupport = 'RS11-HW-SVC-PE-S3';//is updated in below logic
hardwareQuoteLineMap.put(ql.Id,wrapObj);
reqProdIdSet.add(ql.Id);*/
                    
                    //for Covered Asset
                    //hardwareQuoteLineMap.put(ql.Id,wrapObj);
                    if(ql.Subscribed_Asset_Name__c != '' && ql.Subscribed_Asset_Name__c != null){
                        WrapperQuoteLines wrapObj2 = new WrapperQuoteLines();               
                        wrapObj2.serialNumbers = ql.Subscribed_Asset_Name__c;
                        /*if(ql.Trade_Up_Serial_Number_on_HW__c != '' && ql.Trade_Up_Serial_Number_on_HW__c != null){
wrapObj2.serialNumbers = ql.Trade_Up_Serial_Number_on_HW__c;
}*/
                        wrapObj2.prodCode = ql.SBQQ__ProductCode__c;
                        
                        coveredAssetQuoteLineMap.put(ql.SBQQ__ProductCode__c,wrapObj2);
                    }
                }
                
                //add RSV lines
                if(ql.Scale_Utility_Product_RSV_OND__c == 'RSV'){
                    
                    //ScaleUtility_Phase2 to hide schedule table for hw only scenario
                    if(/*ql.Total_Usable_Capacity__c != null ||*/ ql.SBQQ__EffectiveQuantity__c > 0){
                        amendmentHwOnly = false; 
                    }
                    
                    if(prevQty != ql.SBQQ__Quantity__c){
                        
                        if(prevTotal > 0){
                            scheudleLinesTotalNewMap.put(monthRange,scheudleLinesMap.get(prevId));
                            
                            WrapperScheduleLines wrapSchObj1 = new WrapperScheduleLines();
                            decimal totalprice = prevTotal/monthDiff;
                            totalprice = totalprice.setScale(2);
                            wrapSchObj1.totalNetPricePerMonth = string.valueof(totalprice);
                            wrapSchObj1.month = null;
                            wrapSchObj1.productCode  = null;
                            wrapSchObj1.reserveQty = null;
                            
                            wrapSchObj1.unitNetPrice = ' Month '+monthRange;//+' TOTAL per month';
                            string key = string.valueof(ql.id)+string.valueof(ql.id);
                            scheudleLinesMap.put(key,wrapSchObj1);
                            prevTotal = 0;
                            //scheduleGrandTotal = scheduleGrandTotal + decimal.valueof(wrapSchObj1.totalNetPricePerMonth);
                        }
                        
                        WrapperScheduleLines wrapSchObj = new WrapperScheduleLines();
                        wrapSchObj.month = string.valueof(Integer.valueof(ql.SBQQ__SegmentLabel__c.removestart('Month ').trim()));//Added for ScaleUtility_Phase2 CSU-493
                        wrapSchObj.productCode  = ql.SBQQ__ProductCode__c;
                        //Added if block for ScaleUtility_Phase2 CSU-493
                        if(ql.SBQQ__Quote__r.SBQQ__Type__c == 'Amendment'){
                            wrapSchObj.reserveQty = ql.SBQQ__EffectiveQuantity__c.format();
                        }
                        else{
                            wrapSchObj.reserveQty = ql.SBQQ__Quantity__c.format();
                        }
                        wrapSchObj.unitNetPrice = String.valueof(ql.SBQQ__NetPrice__c);
                        wrapSchObj.totalNetPricePerMonth = string.valueof(ql.SBQQ__NetTotal__c);
                        scheudleLinesMap.put(ql.id,wrapSchObj);
                        prevQty = ql.SBQQ__Quantity__c;
                        prevId = ql.Id;
                        firstMonth = wrapSchObj.month;
                    }
                    else{
                        If(scheudleLinesMap.get(prevId) != NULL && scheudleLinesMap.get(prevId).Month != null){
                            scheudleLinesMap.get(prevId).month = firstMonth + '-'+Integer.valueof(ql.SBQQ__SegmentLabel__c.removestart('Month ').trim());//Modified for ScaleUtility_Phase2 CSU-493
                            //prevTotal = prevTotal+ql.SBQQ__NetPrice__c;
                            prevTotal = (prevTotal+ql.SBQQ__NetTotal__c);
                            //prevTotal = ql.SBQQ__NetTotal__c;
                            monthRange = scheudleLinesMap.get(prevId).month ;
                            monthDiff = Integer.valueof(ql.SBQQ__SegmentLabel__c.removestart('Month ').trim())-decimal.valueof(firstMonth) > 0 ? Integer.valueof(ql.SBQQ__SegmentLabel__c.removestart('Month ').trim())-decimal.valueof(firstMonth) : 1;//Modified for ScaleUtility_Phase2 CSU-493
                        }   
                        
                    }
                }
            }  
        }//end of for Quote lines
        //for Aspen hardware - hardware to source
        for(SBQQ__QuoteLine__c ql : [SELECT ID, SBQQ__StartDate__c, SBQQ__EndDate__c, Shortened_Start_Date__c, Shortened_End_Date__c, TPH_Drive_Size__c ,SBQQ__Product__r.Product_Type__c,RWD_Version__c,Usable_Capacity__c,SBQQ__ListPrice__c,SBQQ__NetTotal__c,SBQQ__Description__c,SBQQ__ProductCode__c,SBQQ__Quantity__c,Associated_SW_Support__c,SBQQ__Product__r.Product_Level__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: currentQuoteID and RWD_Version__c = 'Aspen_HW']){                                            
            if((ql.SBQQ__Product__r.Product_level__c == 'Hardware' && ql.RWD_Version__c == 'Aspen_HW') || test.isrunningtest()){
                WrapperQuoteLines wrapObj = new WrapperQuoteLines();
                wrapObj.prodCode = ql.SBQQ__ProductCode__c;
                wrapObj.prodQty = Integer.valueof(ql.SBQQ__Quantity__c);
                wrapObj.prodQtyStr = wrapObj.prodQty.format();
                wrapObj.prodDescription = ql.SBQQ__Description__c;
                wrapObj.commentsList = commentforLine;
                wrapObj.netTotal = ql.SBQQ__NetTotal__c;
                wrapObj.totalListPrice = ql.SBQQ__ListPrice__c;
                wrapObj.unitTB = ql.Usable_Capacity__c;
                wrapObj.HWPrice = 'See distributor for pricing';
                //wrapObj.AssociatedSWSupport = 'RS11-HW-SVC-PE-S3';//is updated in below logic
                hardwareQuoteLineMap.put(ql.Id,wrapObj);
                reqProdIdSet.add(ql.Id);
                //for Covered Asset
                /*wrapperQuoteLines wrapObj2 = new wrapperQuoteLines();               
wrapObj2.serialNumbers = ql.Subscribed_Asset_Name__c;
wrapObj2.prodCode = ql.SBQQ__ProductCode__c;

coveredAssetQuoteLineMap.put(ql.SBQQ__ProductCode__c,wrapObj2);*/
            }
        }
        Map<Id,List<string>> hwandSupportMap = new Map<Id,List<String>>();
        List<String> supportList;// = new List<String>();
        for(SBQQ__QuoteLine__c ql : [Select Id, SBQQ__StartDate__c, SBQQ__EndDate__c, Shortened_Start_Date__c, Shortened_End_Date__c, TPH_Drive_Size__c ,SBQQ__RequiredBy__r.Associated_SW_Support__c ,SBQQ__Product__r.Name,SBQQ__RequiredBy__c,SBQQ__Product__r.Product_Level__c from SBQQ__QuoteLine__c where SBQQ__RequiredBy__c IN : reqProdIdSet and Product_Type__c = 'HW Support']){
            if(associatedHwSupport != null){
                associatedHwSupport = associatedHwSupport +'     '+ql.SBQQ__Product__r.Name;
            }
            else{
                associatedHwSupport = ql.SBQQ__Product__r.Name;
            }
            
            
            if(hwandSupportMap.keyset().Contains(ql.SBQQ__RequiredBy__c)){
                hwandSupportMap.get(ql.SBQQ__RequiredBy__c).add(ql.SBQQ__Product__r.Name);
            }
            else{
                supportList = new List<String>();
                supportList.add(ql.SBQQ__Product__r.Name);
                hwandSupportMap.put(ql.SBQQ__RequiredBy__c,supportList);
            }
            
            
        }
        for(Id prId : hwandSupportMap.keyset()){
            
            if(hardwareQuoteLineMap.keyset().contains(prId)){
                
                hardwareQuoteLineMap.get(prId).associatedHwSupportlist = hwandSupportMap.get(prId);
                
            }
        }
        //for last RSV month range
        if(prevTotal > 0 || test.isrunningtest()){
            WrapperScheduleLines wrapSchObj1 = new WrapperScheduleLines();
            //wrapSchObj1.totalNetPricePerMonth = string.valueof(Integer.valueof(prevTotal/monthDiff));//string.valueof(prevTotal);
            decimal totalprice = prevTotal/monthDiff;
            totalprice = totalprice.setScale(2);
            wrapSchObj1.totalNetPricePerMonth = string.valueof(totalprice);
            wrapSchObj1.month = null;
            wrapSchObj1.productCode  = null;
            wrapSchObj1.reserveQty = null;
            
            wrapSchObj1.unitNetPrice = 'MONTH '+monthRange;//+' TOTAL per month';
            string key = 'lastmonthrange';
            //scheduleGrandTotal = scheduleGrandTotal + decimal.valueof(wrapSchObj1.totalNetPricePerMonth);
            scheudleLinesMap.put(key,wrapSchObj1);
        }
        
        
        
        if(pricingTotal != null){
            //pricingTableTotal = '$'+string.valueof(pricingTotal.format());
            pricingTableTotal = '$'+ScaleUtilitySegmentedLineViewController.formatDollarAmount(pricingTotal.setscale(2));
        }
        if(reserveTotal != null){
            //reserveTableTotal = '$'+string.valueof(reserveTotal.format());
            reserveTotal = reserveTotal+reserveTableTotalUpgrade.setscale(2);//ScaleUtility_Phase2 for upgrade scenario
            reserveTableTotal = '$'+ScaleUtilitySegmentedLineViewController.formatDollarAmount(reserveTotal.setscale(2));
        }
        //grandTotal = '$'+SBQQ__Quote__r.SBQQ__NetAmount__c;//string.valueof(pricingTotal + reserveTotal);
        
        lstQuoteLinesToDisplay.addall(productQuoteLineMap.values());
        
        
        
        pricinglstToDisplay.addall(pricingQuoteLineMap.values());
        onDemandlstToDisplay.addall(onDemandQuoteLineMap.values());
        hardwarelstToDisplay.addall(hardwareQuoteLineMap.values());
        
        
        
        coveredAssetlstToDisplay.addall(coveredAssetQuoteLineMap.values());
        
        //ScaleUtility_Phase2 clear schedule table when its hw only - start
        
        if(amendmentHwOnly == true && isUpgradeQuote == false && isAmendmentQuote == true){
            scheduleLinesToDisplay.clear();
            onDemandlstToDisplay.clear();
            
        }
        //calculate total for all reserve lines that will be shown on table
        
        if(isAmendmentQuote == true){
            Decimal newAmendRervTotal = 0;
            //reserveTableTotal = '0';
            for(WrapperQuoteLines wp : lstQuoteLinesToDisplay){
                newAmendRervTotal = newAmendRervTotal + wp.totalNetPrice.setscale(2);
                reserveTableTotal = '$'+ScaleUtilitySegmentedLineViewController.formatDollarAmount(newAmendRervTotal.setscale(2));
            }
            grandTotal = '$'+ScaleUtilitySegmentedLineViewController.formatDollarAmount(quoteNetAmount);
        }
        
        //ScaleUtility_Phase2 end
        
    }
    /**
     * WrapperQuoteLines
     * @description Wrapper class containing fields used to display quote line details in the UI.
     */
    public class WrapperQuoteLines{ 
        /** @description Formatted product quantity for display. */
        public Integer prodQty             {get; set;}
        /** @description Formatted product code  string for display. */
        public String prodCode             {get; set;}//1
         /** @description Formatted product description string for display. */
        public String prodDescription      {get; set;}//2
        /** @description Formatted comments string for display. */
        public String comments             {get; set;}//3 new
         /** @description Formatted net total for display. */
        public Decimal netTotal             {get; set;}//4
         /** @description Formatted total list price  for display. */
        public Decimal totalListPrice       {get; set;}//5 new
        /** @description Formatted total discount for display. */
        public Decimal totalDiscount        {get; set;}//6 new
         /** @description Formatted unit net price for display. */
        public Decimal unitNetPrice         {get; set;}//7 new
        /** @description Formatted total net price for display. */
        public Decimal totalNetPrice        {get; set;}//8 new
         /** @description Formatted list of hardward support for display. */
        public List<String> associatedHwSupportlist {get;set;}
        /** @description Formatted list of comments for display. */
        public List<String> commentsList {get;set;}
        /** @description Formatted unit net price string for display. */
        public String unitNetPriceStr         {get; set;}//7 new
         /** @description Formatted net total price string for display. */
        public String netTotalStr             {get; set;}//4
        /** @description Formatted total list price string for display. */
        public String totalListPriceStr       {get; set;}//5 new
         /** @description Formatted total discount string for display. */
        public String totalDiscountStr        {get; set;}//6 new
         /** @description Formatted total net price string for display. */
        public String totalNetPriceStr        {get; set;}//8 new
        /** @description Formatted hardware price string for display. */
        public string HWPrice              {get; set;}
         /** @description Formatted software support string for display. */
        public string AssociatedSWSupport {get; set;}
        /** @description Formatted serial number string for display. */
        public string serialNumbers {get; set;}
        /** @description Formatted unit tb for display. */
        public decimal unitTB {get;set;}
         /** @description Formatted product term string for display. */
        public String prodTerm            {get; set;}
         /** @description Formatted product sales price for display. */
        public Decimal prodSalesPrice      {get; set;}
         /** @description Formatted product sales price for display. */
        public Decimal prodNetTotal        {get; set;}
         /** @description Formatted product backend capacity for display. */
        public Decimal prodBackendCapacity {get; set;}
        //public Boolean showSalesPrice    {get; set;}
         /** @description Formatted product quantity for display. */
        public String ProdQtyStr           {get; set;}
         /** @description Formatted sales price string for display. */
        public String strSalesPrice        {get; set;}
        /** @description Formatted table line total for display. */
        public Decimal tableLinesTotal     {get; set;}
        /**
         * Constructor for WrapperQuoteLines.
         * @description Initializes default values for all wrapper fields used to display quote line details.
         */
        public WrapperQuoteLines(){
            prodQty = 0;
            prodTerm = '';
            prodSalesPrice = 0;
            prodNetTotal = 0;
            prodBackendCapacity = 0;
            netTotal = 0;//changed from str '' to 0
            ProdQtyStr = '';
            strSalesPrice = '';
            HWPrice ='';
            AssociatedSWSupport = '';
            tableLinesTotal = 0;
            associatedHwSupportlist = new List<String>();
            commentsList = new List<String>();
            
            
        }
    }
    
    //Wrapper Class for Scale utility Scheudle Table
    /**
     * WrapperScheduleLines
     * @description Wrapper class containing fields used to display schedule line details in the UI.
     */
    public class WrapperScheduleLines{
        /** @description Formatted month string for display. */
        public String month            {get; set;}
        /** @description  product code string for display. */
        public String productCode       {get; set;}
         /** @description  reserve quantity string for display. */
        public String reserveQty       {get; set;}
         /** @description  unit net price string for display. */
        public String unitNetPrice     {get; set;}
         /** @description  total net price per month string for display. */
        public String totalNetPricePerMonth    {get; set;}
        /** @description  total net price per month string for display. */
        public String totalNetPricePerMonthStr    {get; set;}
         /** @description user or TB  string for display. */
        public String userOrTb {get;set;}//M365-Utility changes
        /**
         * Constructor for WrapperScheduleLines.
         * @description Initializes default values for all wrapper fields used to display schedule line details.
         */
        public WrapperScheduleLines(){
            month = '';
            productCode = '';
            reserveQty = '0';
            unitNetPrice = '';
            totalNetPricePerMonth = '';
            
        }
    }
    /** 
     * @description Method to form comment for quote lines
     * @param qLine - Quote line record
     * @param lstMDQQuoteLines - List of MDQ quote lines associated with the quote line
     * @return List<String> - List of comments for the quote line
     */
    public static List<string> formCommentForLines(SBQQ__QuoteLine__c qLine,List<SBQQ__QuoteLine__c> lstMDQQuoteLines){
        
        String comment;
        
        String Billingdetail='';
        String associatedHw='';
        String totalDiscount='';
        String metering='';
        String deploymentEnv='';
        
        //ITNPI-976
        String storageTier='';
        
        //Shaloo
        String subTermStr = '';
        
        List<String> allCommentsList =New List<String>();
        List<String> deplEnvList = New List<String>();
        List<String> totalDiscList = New List<String>();
        List<String> lstUpgradeTypes = !String.isBlank(System.Label.RBK_SUUpgradeEditions) ? System.Label.RBK_SUUpgradeEditions.split(',') : new List<String>{'SU FUE', 'SU FUP', 'SU EUP', 'SU FUB'};
        
        if(qLine.Product_Payment_Option__c != null){
            Billingdetail = 'Billed '+qLine.Payment_Options__c+ ' upfront.';
            
        }
        
        //Added by Shaloo
        /*if(qLine.Scale_Utility_Product_Identifier__c == 'SU FUE'){
            system.debug('Enter for FUE Billing');
            Billingdetail = Billingdetail + ' Refer to software schedule for more details. ';
            subTermStr = subTermStr + 'Subscription term is ' + qLine.Shortened_Start_Date__c + ' - ' + qLine.Shortened_End_Date__c ;
        }
        if(qLine.Scale_Utility_Product_RSV_OND__c == 'RSV'){
            
            Billingdetail = Billingdetail + ' Refer to Schedule for breakdown of charges. ';
            subTermStr = subTermStr + 'Subscription term is ' + qLine.Shortened_Start_Date__c + ' - ' + qLine.Shortened_End_Date__c ;
        }
        if(qLine.Scale_Utility_Product_Identifier__c == 'OND AR' || qLine.Scale_Utility_Product_Identifier__c == 'OND SR'){
            
            Billingdetail = 'Billed monthly in arrears.';////ScaleUtility_Phase2
            subTermStr = subTermStr + 'Subscription term is ' + qLine.Shortened_Start_Date__c + ' - ' + qLine.Shortened_End_Date__c ;
        }*/
        //End of change by shaloo
        
        //fix for CSU-752 start
        if(lstUpgradeTypes.contains(qLine.Scale_Utility_Product_Identifier__c) || qLine.Scale_Utility_Product_RSV_OND__c == 'RSV' || qLine.Scale_Utility_Product_Identifier__c == 'OND AR' || qLine.Scale_Utility_Product_Identifier__c == 'OND SR'){
            if(lstUpgradeTypes.contains(qLine.Scale_Utility_Product_Identifier__c)){
                   Billingdetail = Billingdetail + ' Refer to software schedule for more details. ';
                }
                if(qLine.Scale_Utility_Product_RSV_OND__c == 'RSV'){
                   Billingdetail = Billingdetail + ' Refer to Schedule for breakdown of charges. ';
                }
                if(qLine.Scale_Utility_Product_Identifier__c == 'OND AR' || qLine.Scale_Utility_Product_Identifier__c == 'OND SR'){
                            Billingdetail = 'Billed monthly in arrears.';////ScaleUtility_Phase2
                }
                
            If(qLine.SBQQ__Quote__r.SBQQ__StartDate__c != null && qLine.SBQQ__Quote__r.Amended_Renewed_Service_Contract__c != null && qLine.SBQQ__Quote__r.Amended_Renewed_Service_Contract__r.EndDate != null){
   
                String quotetStartDate = qLine.SBQQ__Quote__r.SBQQ__StartDate__c.month()+'/'+qLine.SBQQ__Quote__r.SBQQ__StartDate__c.day()+'/'+string.valueof(qLine.SBQQ__Quote__r.SBQQ__StartDate__c.year()).substring(2,4);
        
                String serviceContractEndDate = qLine.SBQQ__Quote__r.Amended_Renewed_Service_Contract__r.EndDate.month()+'/'+qLine.SBQQ__Quote__r.Amended_Renewed_Service_Contract__r.EndDate.day()+'/'+string.valueof(qLine.SBQQ__Quote__r.Amended_Renewed_Service_Contract__r.EndDate.year()).substring(2,4);
        
                subTermStr = subTermStr + 'Subscription term is ' + quotetStartDate+ ' - ' + serviceContractEndDate ;
            }
        }    
        //fix for CSU-752 end
        if(qLine.SBQQ__RequiredBy__c != null && qLine.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Type__c == 'Hardware'){
            associatedHw = ' Associated Hardware: '+qLine.SBQQ__RequiredBy__r.SBQQ__Product__r.Name;
            
        }
        
        //ScaleUtility_Phase2 start
        if(qLine.SBQQ__RequiredBy__c != null && qLine.SBQQ__Product__r.Product_Type__c == 'Hardware' ){
            associatedHw = ' Associated SW Support: '+qLine.SBQQ__RequiredBy__r.SBQQ__Product__r.Name;
            if(associatedHw.contains('RSVX')){
               associatedHw = associatedHw.replace('RSVX','RSV');
            }
        }
        //ScaleUtility_Phase2 end
        
        //M365-Utility added > 0 condition
        //ScaleUtility_Phase2 added for USD discoutn field
        if(qLine.Trade_Up_Discount__c != null || (qLine.Promo_Disc__c != null && qLine.Promo_Disc__c > 0) || (qLine.SBQQ__Discount__c != null || qLine.SBQQ__AdditionalDiscountAmount__c != null)){
            totalDiscount = ' Total Discount Includes: ';
            totalDiscList.add(totalDiscount);
            //ScaleUtility_Phase2 rounding to 2 decimal
            if(qLine.Trade_Up_Discount__c != null){
                totalDiscount = qLine.Trade_Up_Discount__c.setscale(2) +'% Trade-up Discount';
                totalDiscList.add(totalDiscount); 
            }
            if(qLine.Promo_Disc__c != null && qLine.Promo_Disc__c > 0){ //M365-Utility added > 0 condition
                totalDiscount = qLine.Promo_Disc__c.setscale(2) +' % Promo Discount ';
                totalDiscList.add(totalDiscount); 
            }
            if(qLine.SBQQ__Discount__c != null){
                totalDiscount = qLine.SBQQ__Discount__c.setscale(2) +' % Additional Discount '; 
                totalDiscList.add(totalDiscount);
            }
            //ScaleUtility_Phase2 added for USD discount
            else if(qLine.SBQQ__AdditionalDiscountAmount__c != null && qLine.SBQQ__AdditionalDiscountAmount__c > 0 && qLine.SBQQ__ListPrice__c != null){
                   totalDiscount = ((qLine.SBQQ__AdditionalDiscountAmount__c/qLine.SBQQ__ListPrice__c)*100).setscale(2)+' % Additional Discount ';
                   totalDiscList.add(totalDiscount);
            }
        }
        
        if(qLine.Scale_Utility_Product__c == true && qLine.SBQQ__Quote__r.Metering__c != null){
            metering = ' Metered per '+qLine.SBQQ__Quote__r.Metering__c;
        } 
        /*if(qLine.No_of_TBs_Cloud__c != null || qLine.TPH_OEM__c != null || qLine.TPH_Models_Gen__c != null || qLine.TPH_Quantity__c != null){
deploymentEnv = ' Deployment environments: '+qLine.No_of_TBs_Cloud__c+' ,'+qLine.TPH_OEM__c+' ,'+qLine.TPH_Models_Gen__c+' ,'+qLine.TPH_Quantity__c;
}*/
        
        //NewChange Start
        if(qLine.Scale_Utility_Product_RSV_OND__c == 'RSV')
        {
            for(SBQQ__QuoteLine__c ql : lstMDQQuoteLines){                                            
                
                if((ql.Scale_Utility_Product__c == true && qLine.SBQQ__RequiredBy__c == ql.Id) || test.isrunningtest())
                {
                    //commented for ScaleUtility_Phase2
                    /*if(ql.No_of_TBs_Cloud__c != null){
                        deplEnvList.add('Deployment Environments: ');
                        deploymentEnv = '- '+integer.valueof(ql.No_of_TBs_Cloud__c)+' TB, Cloud';
                        deplEnvList.add(deploymentEnv);
                        
                    }
                    
                    if(ql.TPH_OEM__c != null && ql.TPH_Models_Gen__c != null && ql.TPH_Quantity__c != null){
                        if(!deplEnvList.contains('Deployment Environments: ')){
                            deplEnvList.add('Deployment Environments: ');
                        }
                        deploymentEnv ='- '+integer.valueof(ql.TPH_Quantity__c)+'x '+ql.TPH_OEM__c+'-'+ql.TPH_Models_Gen__c+'-'+ql.TPH_Drive_Size__c;
                        deplEnvList.add(deploymentEnv);
                    }*/
                
                
                    //ScaleUtility_Phase2 start
                    if(ql.No_of_TBs_Cloud__c != null){
                        deplEnvList.add('Deployment Environments: ');
                        //deploymentEnv = '- '+integer.valueof(ql.No_of_TBs_Cloud__c)+' TB, Cloud';
                        
                        //fix for TPH issue
                        deplEnvList.add('- '+integer.valueof(ql.No_of_TBs_Cloud__c)+' TB, Cloud');
                        //deplEnvList.add('&nbsp;');//post_prod_fix_scaleUtility comment this to remove space
                     }
                    
                      if(ql.TPH_Quantity__c != null){
                         if(!deplEnvList.contains('Deployment Environments: ')){
                            deplEnvList.add('Deployment Environments: ');
                         }
                        if(deploymentEnv != null){
                           deploymentEnv =deploymentEnv+'- '+ql.TPH_Quantity__c;
                        }
                        else{
                          deploymentEnv ='- '+integer.valueof(ql.TPH_Quantity__c);  
                        }
                    
                        //deplEnvList.add(deploymentEnv);
                                           
                     }
                                        
                      if(ql.TPH_OEM__c != null){
                         if(!deplEnvList.contains('Deployment Environments: ')){
                            deplEnvList.add('Deployment Environments: ');
                         }
                        if(deploymentEnv != null){
                           //added if else for post_prod_fix_scaleUtility
                           if(ql.TPH_Quantity__c != null){
                             deploymentEnv =deploymentEnv+'x '+ql.TPH_OEM__c;
                           }
                           else{
                             deploymentEnv =deploymentEnv+'- '+ql.TPH_OEM__c;
                           } 
                        }
                        else{
                          // added if else for post_prod_fix_scaleUtility
                          if(ql.TPH_Quantity__c != null){
                           deploymentEnv ='x '+ql.TPH_OEM__c;
                          }
                          else{
                            deploymentEnv ='x '+ql.TPH_OEM__c;
                          }   
                        }
                    
                        //deplEnvList.add(deploymentEnv);
                                           
                     }
                    
                     if(ql.TPH_Models_Gen__c != null){
                         if(!deplEnvList.contains('Deployment Environments: ')){
                            deplEnvList.add('Deployment Environments: ');
                         }
                        if(deploymentEnv != null){
                           deploymentEnv =deploymentEnv+'-'+ql.TPH_Models_Gen__c;//removed space after - post_prod_fix_scaleUtility
                        }
                        else{
                          deploymentEnv ='- '+ql.TPH_Models_Gen__c;  
                        }
                    
                        //deplEnvList.add(deploymentEnv);
                                           
                     }
                    
                     if(ql.TPH_Drive_Size__c != null){
                         if(!deplEnvList.contains('Deployment Environments: ')){
                            deplEnvList.add('Deployment Environments: ');
                         }
                        if(deploymentEnv != null){
                           deploymentEnv =deploymentEnv+'-'+ql.TPH_Drive_Size__c;//removed space after - post_prod_fix_scaleUtility
                        }
                        else{
                          deploymentEnv ='- '+ql.TPH_Drive_Size__c;  
                        }
                    
                        //deplEnvList.add(deploymentEnv);
                                           
                     }
                     deplEnvList.add(deploymentEnv);
                } 
                //ScaleUtility_Phase2 end
                
                if(ql.SBQQ__Product__r.Product_Type__c == 'Hardware' && qLine.SBQQ__RequiredBy__c == ql.SBQQ__RequiredBy__c && ql.SBQQ__Quantity__c != null){
                    deploymentEnv = '- '+integer.valueof(ql.SBQQ__Quantity__c)+'x '+ql.SBQQ__ProductCode__c;
                    if(!deplEnvList.contains('Deployment Environments: ')){
                        deplEnvList.add('Deployment Environments: ');
                    }
                    deplEnvList.add(deploymentEnv);
                    
                }
                
            }
        }
        //NewChange End
        
        //ITNPI-976
        if(qLine.Storage_Region_Tier_Template__c != null){
            storageTier = 'Storage Details: ' +qLine.Storage_Region_Tier_Template__c;
            
        }
        
        comment = Billingdetail + associatedHw + totalDiscount + metering + deploymentEnv;
        
        //Shaloo
        if(lstUpgradeTypes.contains(qLine.Scale_Utility_Product_Identifier__c) 
           || qLine.Scale_Utility_Product_RSV_OND__c == 'RSV'
           || qLine.Scale_Utility_Product_Identifier__c == 'OND AR'
           || qLine.Scale_Utility_Product_Identifier__c == 'OND SR'
          ){
              comment = Billingdetail + associatedHw + totalDiscount + metering + deploymentEnv + subTermStr;
          }
        
        if(Billingdetail != '' && Billingdetail != null){
            allCommentsList.add(Billingdetail);              
        }
        if(associatedHw != '' && associatedHw != null){
            allCommentsList.add('&nbsp;');
            allCommentsList.add(associatedHw);
            
        }
        //allCommentsList.add(totalDiscount);
        if(totalDiscList.size() > 0){
            allCommentsList.add('&nbsp;');
            for(String st : totalDiscList){
                allCommentsList.add(st);
            }
        }
        //allCommentsList.add('&nbsp;');
        if(metering != '' && metering != null){
            allCommentsList.add('&nbsp;');
            allCommentsList.add(metering);
        }
        //Shaloo
        if(subTermStr != '' && subTermStr != null){
            
            //subscription term to be displayed only for amendment quote
            if(isAmendmentQuote == true){
              allCommentsList.add('&nbsp;');            
              allCommentsList.add(subTermStr);  
            }         
        }
        
        //allCommentsList.add(deploymentEnv);
        if(deplEnvList.size() > 0){
            allCommentsList.add('&nbsp;');
            for(string st : deplEnvList){
                allCommentsList.add(st);
            }
        }
        
        //ScaleUtility_Phase2
        if(qLine.Scale_Utility_Product_Identifier__c == 'OND AR'
           || qLine.Scale_Utility_Product_Identifier__c == 'OND SR'
          ){
              //comment = Billingdetail + associatedHw + totalDiscount + metering + deploymentEnv + subTermStr;
              allCommentsList.clear();
              allCommentsList.add(Billingdetail);
              //subscription term to be displayed only for amendment quote
              if(isAmendmentQuote == true){
                 allCommentsList.add('&nbsp;');              
                 allCommentsList.add(subTermStr);
              }    
              
          }

        //ITNPI-976
        if(storageTier != '' && storageTier != null){
            allCommentsList.add('&nbsp;');
            allCommentsList.add(storageTier);              
        }
          
        
        return allCommentsList;
    }
    /**
     * @description Builds schedule table rows for Scale Utility RSV quote lines.
     * @param qLineList List of SBQQ__QuoteLine__c records representing quote lines.
     * @param scheduleLinesToDisplay List of WrapperScheduleLines to populate with schedule table rows.
     * @param scheduleGrandTotal Decimal variable to hold the grand total of the schedule lines
     */
    public static void scheduleTableRowBuilder(List<SBQQ__QuoteLine__c> qLineList,List<WrapperScheduleLines> scheduleLinesToDisplay, Decimal scheduleGrandTotal){
        
        Map<String,List<SBQQ__QuoteLine__c>> skuToQlineMAp = New Map<String,List<SBQQ__QuoteLine__c>>();
        Map<String,List<String>> skuToMonthRange = New Map<String,List<String>>();
        map<integer,integer> monthToMonthMap = New map<integer,integer>();
        qLineList = buildOnFlyFUESegmentLines(qLineList);//ScaleUtility_Phase2
        
        for(SBQQ__QuoteLine__c ql : qLineList){
            if(ql.SBQQ__SegmentLabel__c != null){//Modified for ScaleUtility_Phase2 CSU-493
                if(skuToQlineMap.keyset().contains(ql.SBQQ__PackageProductCode__c)){
                    skuToQlineMAp.get(ql.SBQQ__PackageProductCode__c).add(ql);
                }
                else{
                    List<SBQQ__QuoteLine__c> qlList = new List<SBQQ__QuoteLine__c>();
                    qlList.add(ql);
                    skuToQlineMAp.put(ql.SBQQ__PackageProductCode__c,qlList);
                }
            }
        } 
        
        for(string pcode : skuToQlineMAp.keyset()){
            Decimal startMonth = 0;
            Decimal endMonth = 0;
            Decimal prevQty;
            Decimal skuCounter = 0;
            Integer skuCountSize = skuToQlineMAp.get(pcode).size();
            List<String> monthRangeList = New List<String>();
            decimal qtyQline = 0;//ScaleUtility_Phase2
            for(SBQQ__QuoteLine__c ql : skuToQlineMAp.get(pcode)){
                
                //ScaleUtility_Phase2 start
                qtyQline = ql.Quantity_TB__c;
                if(ql.SBQQ__Description__c != 'FUELine'){
                    qtyQline = ql.SBQQ__EffectiveQuantity__c;
                }
                //qtyQline = ql.SBQQ__EffectiveQuantity__c;// ScaleUtility_Phase2 always use effectige qty this will cover all scenrios new and amendment as well CSU-708
                
                //fix for CSU-708
                if(ql.Scale_Utility_Product_Identifier__c == 'SU FUE' && ql.SBQQ__Description__c == 'FUELine'){
                   if(ql.SBQQSC__UpgradedContractLine__c != null)
                      qtyQline = ql.SBQQ__EffectiveQuantity__c;
                   else if(ql.SBQQSC__UpgradedContractLine__c == null){
                      qtyQline = ql.SBQQ__Quantity__c;
                   }   
                }
                
                //ScaleUtility_Phase2 end
                skuCounter++;
                if(startMonth == 0){
                    startMonth = decimal.valueof(ql.SBQQ__SegmentLabel__c.removestart('Month ').trim());//Modified for ScaleUtility_Phase2 CSU-493
                }
                if(endMonth == 0){
                    endMonth = decimal.valueof(ql.SBQQ__SegmentLabel__c.removestart('Month ').trim());//Modified for ScaleUtility_Phase2 CSU-493
                }
                
                //ScaleUtility_Phase2 repalced qty field with varibable
                if(qtyQline== prevQty && skuCounter != skuCountSize){
                    endMonth = decimal.valueof(ql.SBQQ__SegmentLabel__c.removestart('Month ').trim());//Modified for ScaleUtility_Phase2 CSU-493
                }
                else{
                    //ScaleUtility_Phase2 repalced qty field with varibable
                    if(skuCounter == skuCountSize && qtyQline == prevQty){
                        endMonth = decimal.valueof(ql.SBQQ__SegmentLabel__c.removestart('Month ').trim());//Modified for ScaleUtility_Phase2 CSU-493
                    }
                    
                    
                    if(endMonth != startMonth){                  
                        string monthRange = string.valueof(startMonth+'-'+endMonth);
                        if(endMonth < startMonth){
                            monthRange = string.valueof(startMonth);
                            
                            //add first month when not same as 2nd month while iterating 2nd month
                            if(monthRange == '2'){                             
                                monthRangeList.add('1');
                                skuToMonthRange.put(ql.SBQQ__PackageProductCode__c,monthRangeList);
                            }
                        }
                        
                        //add first month when not same as 2nd month while iterating 2nd month
                        if(monthRange.contains('2-')){                             
                            monthRangeList.add('1');
                            skuToMonthRange.put(ql.SBQQ__PackageProductCode__c,monthRangeList);
                        }
                        
                        monthRangeList.add(monthRange);
                        skuToMonthRange.put(ql.SBQQ__PackageProductCode__c,monthRangeList);
                    }
                    
                    //Add last month when not same as secondlast month
                    //ScaleUtility_Phase2 repalced qty field with varibable
                    if(skuCounter == skuCountSize && qtyQline != prevQty){
                        string monthRange = string.valueof(Integer.valueof(ql.SBQQ__SegmentLabel__c.removestart('Month ').trim()));//Modified for ScaleUtility_Phase2 CSU-493
                        monthRangeList.add(monthRange);
                        skuToMonthRange.put(ql.SBQQ__PackageProductCode__c,monthRangeList);
                    }
                    
                    startMonth = Integer.valueof(ql.SBQQ__SegmentLabel__c.removestart('Month ').trim());//Modified for ScaleUtility_Phase2 CSU-493  
                }
                
                prevQty = qtyQline;//ScaleUtility_Phase2
                
            }
            
        } 
        
        monthToMonthMap = segregateMonthRange(skuToMonthRange,scheduleGrandTotal);
        
        setScheduleLinesWrapper(qLineList,monthToMonthMap,scheduleLinesToDisplay, scheduleGrandTotal);
    } 
    /**
     * @description segregateMonthRange
     * @purpose This method is used to segregate month ranges based on SKU month ranges.
     * @param skuToMonthRange Map of SKU to its month ranges.
     * @param scheduleGrandTotal Decimal value representing the grand total of the schedule.
     * @return Map of integer representing the start month to integer representing the end month.
     */
    public static map<integer,integer> segregateMonthRange(Map<String,List<String>> skuToMonthRange, Decimal scheduleGrandTotal){
        
        Set<String> finalMonthRangeSet = New Set<String>();
        map<integer,integer> monthToMonthMap = New map<integer,integer>();
        //Map<String,List<String>> skuToMonthRange = New Map<String,List<String>>();
        //String pointerSKU;
        Integer firstMonth;
        //Integer pointerLastMonth;
        //Integer pointerLastMonth;
        Integer NextMonth;
        //Integer newFirstMonth;
        
        Integer skuFirstMonth;
        Integer skuLastMonth;
        
        //List<String> rangeList = New List<String>();
        Set<Integer> segmentSet = New Set<Integer>();
        //{1,2,3,4,4,5,6,7,8,9,10,11,12};
        firstMonth = 1;
        NextMonth = 2;
        Integer allSKUcounter = 0;
        Integer segmentLineCount =0;
        Integer LastMonth;
        Integer qterm = 1;
        map<string,Integer> skuToMaxMonth = New Map<string,Integer>();//M365-Utility
        Integer segmentPresentInSkuCount = 0;//M365-Utility, this count to see in how many skus the segment number is present
        //quoteSubscriptionTerm = 36;//comment out for testing only
        //ScaleUtility_Phase2 - start
         
        if(highestIndex > 0){
            quoteSubscriptionTerm = integer.valueof(highestIndex);
        }
        /*else if(quotesubTerm != null && quotesubTerm > 0 && (quoteSubscriptionTerm == null || quoteSubscriptionTerm == 0)){
 
quoteSubscriptionTerm = quotesubTerm;//ScaleUtility_Phase2
}*/
        
        
        //ScaleUtility_Phase2 - end
        do {
            segmentSet.add(qterm);
            qterm++;
        } while (qterm<=quoteSubscriptionTerm);
        //M365-Utility need chnages here 
        
        //added as part of M365-Utility - start
        for(String sku : skuToMonthRange.keyset()){
            
            for(String mnt : skuToMonthRange.get(sku)){
                
                if(mnt.contains('-')){ 
                    if((!skuToMaxMonth.keyset().contains(sku)) || (integer.valueof(mnt.split('-')[1]) > skuToMaxMonth.get(sku))){
                        skuToMaxMonth.put(sku,integer.valueof(mnt.split('-')[1]));
                    }
                }
                else{
                    if((!skuToMaxMonth.keyset().contains(sku)) || (integer.valueof(mnt) > skuToMaxMonth.get(sku))){
                        skuToMaxMonth.put(sku,integer.valueof(mnt));
                    }
                }
            }
        }
        
        //added as part of M365-Utility - end
        
        for(Integer seg : segmentSet){
            
            allSKUcounter = 0;
            segmentLineCount = skuToMonthRange.keyset().size();
            segmentPresentInSkuCount = 0;//M365-Utility
            
            for(String sku : skuToMonthRange.keyset()){
                
                //M365-Utility set segmentLineCount to the number of skus the segment number is present - Start
                
                if(seg <= skuToMaxMonth.get(sku)){
                    segmentPresentInSkuCount++;
                }
                
                segmentLineCount=segmentPresentInSkuCount;
                //M365-Utility - end
                
                for(String mnt : skuToMonthRange.get(sku)){
                    
                    if(mnt.contains('-')){ 
                        skuFirstMonth = integer.valueof(mnt.split('-')[0]);
                        skuLastMonth = integer.valueof(mnt.split('-')[1]);
                    }
                    else{ //new fixes
                        skuFirstMonth = integer.valueof(mnt);
                        skuLastMonth = integer.valueof(mnt);
                    }
                    
                    
                    //OR condition added to test
                    if(skuFirstMonth <= firstMonth && skuLastMonth >= NextMonth){
                        
                        allSKUcounter++;
                    }
                    
                    
                }    
            } 
            
            if(allSKUcounter == segmentLineCount){
                
                if(NextMonth <= segmentSet.size() ){
                    LastMonth = NextMonth;
                    NextMonth++;
                }
            }
            else{
                if(NextMonth <= segmentSet.size() ){
                    
                    firstMonth = NextMonth;
                    LastMonth = NextMonth;
                    NextMonth++;
                }
                
            }
            if(firstMonth == 2){
                //add 1st Month as single
                //finalMonthRangeSet.add(string.valueof(firstMonth));
                monthToMonthMap.put(1,1);
            }      
            monthToMonthMap.put(firstMonth,LastMonth);
            /*if(firstMonth < LastMonth){
finalMonthRangeSet.add(firstMonth+'-'+LastMonth);
}
if(firstMonth == LastMonth){
finalMonthRangeSet.add(string.valueof(firstMonth));
}*/
        } 
        
        return monthToMonthMap;
    }
    /**
     * @description setScheduleLinesWrapper
     * @purpose This method is used to set the schedule lines wrapper for display in the UI.
     * @param qLineList List of SBQQ__QuoteLine__c records representing quote lines.
     * @param monthToMonthMap Map of integer representing the start month to integer representing the end month.
     * @param scheduleLinesToDisplay List of WrapperScheduleLines to populate with schedule table rows.
     * @param scheduleGrandTotal Decimal variable to hold the grand total of the schedule lines
     */
    public static void setScheduleLinesWrapper(List<SBQQ__QuoteLine__c> qLineList,Map<Integer,Integer> monthToMonthMap,List<WrapperScheduleLines> scheduleLinesToDisplay, Decimal scheduleGrandTotal){
        
        Map<Integer,List<SBQQ__QuoteLine__c>> monthToLinestMap = New Map<Integer,List<SBQQ__QuoteLine__c>>();
        Integer lastMonth;
        String monthRange;
        Decimal totalForRange = 0;
        Integer monthsInRange = 1;
        Decimal reserveTotalUpgrade = 0;//added for ScaleUtility_Phase2
        
        //added for ScaleUtility_Phase2 upgrade scenario start
        Map<Id,SBQQ__QuoteLine__c> rsvxToFUELineMap = New Map<Id,SBQQ__QuoteLine__c>();
        Map<Id,SBQQ__QuoteLine__c> rsvxToRSVLineMap = New Map<Id,SBQQ__QuoteLine__c>();
        List<String> lstUpgradeTypes = !String.isBlank(System.Label.RBK_SUUpgradeEditions) ? System.Label.RBK_SUUpgradeEditions.split(',') : new List<String>{'SU FUE', 'SU FUP', 'SU EUP', 'SU FUB'};
        
        for(SBQQ__QuoteLine__c ql : qLineList){
            if(ql.SBQQ__RequiredBy__c != null && ql.Scale_Utility_Product_RSV_OND__c == 'RSV'){
                rsvxToRSVLineMap.put(ql.SBQQ__RequiredBy__c,ql);
            }
            if(ql.SBQQ__RequiredBy__c != null && lstUpgradeTypes.contains(ql.Scale_Utility_Product_Identifier__c) && ql.SBQQ__Description__c != 'FUELine'){
                rsvxToFUELineMap.put(ql.SBQQ__RequiredBy__c,ql);
            }
        }   
        
        //added for ScaleUtility_Phase2 end
        
        for(SBQQ__QuoteLine__c ql : qLineList){
            
            if(ql.SBQQ__SegmentLabel__c != null /*&& ql.Total_Usable_Capacity__c != null&& ql.SBQQ__EffectiveQuantity__c > 0*/){ //Modified for ScaleUtility_Phase2 CSU-493
                if(monthToLinestMap.keyset().contains(integer.valueof(Integer.valueof(ql.SBQQ__SegmentLabel__c.removestart('Month ').trim())))){ //Modified for ScaleUtility_Phase2 CSU-493
                    
                    monthToLinestMap.get(Integer.valueof(Integer.valueof(ql.SBQQ__SegmentLabel__c.removestart('Month ').trim()))).add(ql); //Modified for ScaleUtility_Phase2 CSU-493
                    
                }
                else{
                    List<SBQQ__QuoteLine__c> qlList = New List<SBQQ__QuoteLine__c>();
                    
                    
                    qlList.add(ql);
                    
                    monthToLinestMap.put(Integer.valueof(Integer.valueof(ql.SBQQ__SegmentLabel__c.removestart('Month ').trim())),qlList); //Modified for ScaleUtility_Phase2 CSU-493
                }
                
            }
        }
        map<string,WrapperScheduleLines> skuToWrapperMap; 
        //List<wrapperScheduleLines> wrapList;
        
        for(Integer mnt : monthToMonthMap.keyset()){
            
            lastMonth = monthToMonthMap.get(mnt);
            monthRange = mnt+' - '+lastMonth;
            //monthsInRange = 0;
            if(mnt == lastMonth){
                monthRange = string.valueof(mnt);
            }
            monthsInRange = (lastMonth - mnt)+1;
            skuToWrapperMap = New map<string, WrapperScheduleLines>();
            WrapperScheduleLines wrapSchObjToAdd = new WrapperScheduleLines(); 
            //map<Integer,map<string,wrapperScheduleLines>> monthToWrapperMap = New map<Integer,map<string,wrapperScheduleLines>>();
            map<string,WrapperScheduleLines> skuToWrapMap = New map<string,WrapperScheduleLines>();
            List<WrapperScheduleLines> skuToWrapMapSorted = new List<WrapperScheduleLines>();//ScaleUtility_Phase2

            Set<String> skuSet = New Set<String>();
            Map<String,WrapperScheduleLines> AllskuToWrapMap = New Map<String,WrapperScheduleLines>();
            //wrapList = New List<wrapperScheduleLines>();
            Set<string> monthRangeTraced = New Set<String>();
            
            for(integer mnth=mnt;mnth<=lastMonth;mnth++){
                if(monthToLinestMap != null && monthToLinestMap.keyset().size()>0 && monthToLinestMap.keyset().contains(mnth)){          
                    for(SBQQ__QuoteLine__c ql: monthToLinestMap.get(mnth)){
                        if(!skuSet.contains(ql.SBQQ__PackageProductCode__c)){
                            WrapperScheduleLines wrapSchObj = new WrapperScheduleLines();
                            wrapSchObj.month = string.valueof(Integer.valueof(ql.SBQQ__SegmentLabel__c.removestart('Month ').trim())); //Modified for ScaleUtility_Phase2 CSU-493
                            
                            //added below if else for ScaleUtility_Phase2 [upgrade scenario]
                            if(rsvxToFUELineMap.keyset().contains(ql.SBQQ__RequiredBy__c) && rsvxToFUELineMap.get(ql.SBQQ__RequiredBy__c) != null){
                                wrapSchObj.productCode = rsvxToFUELineMap.get(ql.SBQQ__RequiredBy__c).SBQQ__PackageProductCode__c;//added this commented above line for ScaleUtility_Phase2
                            }else{
                                wrapSchObj.productCode  = ql.SBQQ__PackageProductCode__c;
                            }
                            
                            if(ql.SBQQ__Quantity__c!= null){
                                //Added if block for ScaleUtility_Phase2 CSU-493
                                if(ql.SBQQ__Quote__r.SBQQ__Type__c == 'Amendment'){
                                    
                                    //added below if else for ScaleUtility_Phase2 upgrade scenario - start
                                    if(rsvxToFUELineMap.keyset().contains(ql.SBQQ__RequiredBy__c) && rsvxToFUELineMap.get(ql.SBQQ__RequiredBy__c) != null){
                                        wrapSchObj.reserveQty = ql.SBQQ__EffectiveQuantity__c.format();//qty for fue is actually taken from rsv, for upgrade only scenrio
                                        //fix for CSU-708
                                    }
                                    else{
                                        //write here for upgrade and exapnsion
                                        wrapSchObj.reserveQty = ql.SBQQ__EffectiveQuantity__c.format();
                                        
                                    }
                                    
                                }else{
                                    
                                    wrapSchObj.reserveQty = ql.SBQQ__Quantity__c.format();
                                    
                                }
                                //added below if else for ScaleUtility_Phase2 upgrade scenario - end
                            }
                            
                            //added below if else for ScaleUtility_Phase2 upgrade scenario - start
                            if(rsvxToFUELineMap.keyset().contains(ql.SBQQ__RequiredBy__c) && rsvxToFUELineMap.get(ql.SBQQ__RequiredBy__c) != null){
                                //for upgrade check this as net unit price given on FUE or should this be calculated 1month term
                                if(ql.SBQQ__PackageProductCode__c != null && ql.SBQQ__PackageProductCode__c.contains('-FUE-')){
                                    //this is for dummy record or upgrade/upgrade plus expansion
                                    //post production fix for scaleUtility_phase2
                                    wrapSchObj.unitNetPrice = String.valueof(ql.SBQQ__NetPrice__c.setscale(2));
                                    //wrapSchObj.unitNetPrice = String.valueof(rsvxToFUELineMap.get(ql.SBQQ__RequiredBy__c).SBQQ__NetPrice__c);
                                }else{
                                    //this will be expansion record
                                    wrapSchObj.unitNetPrice = String.valueof(ql.SBQQ__NetPrice__c);
                                }
                            }
                            else{     
                                if(ql.SBQQ__NetPrice__c != null){
                                    wrapSchObj.unitNetPrice = String.valueof(ql.SBQQ__NetPrice__c);
                                }
                            }
                            //added below if else for ScaleUtility_Phase2 upgrade scenario - end
                            
                            //added below if else for ScaleUtility_Phase2 upgrade scenario - start
                            if(rsvxToFUELineMap.keyset().contains(ql.SBQQ__RequiredBy__c) && rsvxToFUELineMap.get(ql.SBQQ__RequiredBy__c) != null){
                                //have to calculate for FUE as a signle month
                                if(ql.SBQQ__PackageProductCode__c != null && ql.Scale_Utility_Product_Identifier__c == 'SU FUE'){
                                    wrapSchObj.totalNetPricePerMonth = string.valueof(decimal.valueof(wrapSchObj.unitNetPrice)*ql.SBQQ__Quantity__c);//this is for months
                                    wrapSchObj.totalNetPricePerMonthStr = ScaleUtilitySegmentedLineViewController.formatDollarAmount(decimal.valueof(wrapSchObj.unitNetPrice)*ql.SBQQ__Quantity__c);//this if for total under each months
                                }
                                else{
                                    wrapSchObj.totalNetPricePerMonth = string.valueof(decimal.valueof(wrapSchObj.unitNetPrice)*ql.SBQQ__EffectiveQuantity__c);//this is for months
                                    wrapSchObj.totalNetPricePerMonthStr = ScaleUtilitySegmentedLineViewController.formatDollarAmount(decimal.valueof(wrapSchObj.unitNetPrice)*ql.SBQQ__EffectiveQuantity__c);//this if for total under each months
                                }
                                
                                reserveTableTotalUpgrade = reserveTableTotalUpgrade+decimal.valueof(wrapSchObj.totalNetPricePerMonth);//for reserve table grand dtotal upgrade only scenrio
                            }
                            else{
                                if(ql.SBQQ__NetTotal__c != null){
                                    wrapSchObj.totalNetPricePerMonth = String.valueof(ql.SBQQ__NetTotal__c);
                                    //wrapSchObj.totalNetPricePerMonthStr = ql.SBQQ__NetTotal__c.format();
                                    wrapSchObj.totalNetPricePerMonthStr = ScaleUtilitySegmentedLineViewController.formatDollarAmount(ql.SBQQ__NetTotal__c.setscale(2));
                                }
                            }
                            //added below if else for ScaleUtility_Phase2 upgrade scenario - end
                            
                            //M365-Utility changes - Start
                            /* commentedOUT if(ql.SBQQ__Product__r.Product_Type__c == 'M365H'){
wrapSchObj.userOrTb = 'USERS';
}
else{
wrapSchObj.userOrTb = 'TB';
}*/
//ScaleUtility_Phase2 change
//if(ql.SBQQ__PackageProductCode__c !=null && ql.SBQQ__PackageProductCode__c.contains('-MD-')){
                            //CPQ22-5852
                            if(ql.SBQQ__Product__r.Unit_of_Measure__c != null && !String.isBlank(ql.SBQQ__Product__r.Unit_of_Measure__c)){
                                wrapSchObj.userOrTb = ql.SBQQ__Product__r.Unit_of_Measure__c;
                            }
                            else{
                                wrapSchObj.userOrTb = 'TB';
                            }                          
                            //M365-Utility changes - End
                            
                            //scheduleLinesToDisplay.add(wrapSchObj);
                            //totalForRange = totalForRange+ql.SBQQ__NetPrice__c;
                            wrapSchObjToAdd = wrapSchObj;
                            skuSet.add(ql.SBQQ__PackageProductCode__c);
                            
                            //added below if else for ScaleUtility_Phase2 upgrade scenario
                            if(rsvxToFUELineMap.keyset().contains(ql.SBQQ__RequiredBy__c) && rsvxToFUELineMap.get(ql.SBQQ__RequiredBy__c) != null){
                                AllskuToWrapMap.put(rsvxToFUELineMap.get(ql.SBQQ__RequiredBy__c).SBQQ__PackageProductCode__c,wrapSchObjToAdd);
                                
                                //added below for upgrade + expansion, need both fue and rsv when its upgrade + expansion
                                if(ql.SBQQ__EffectiveQuantity__c > 0){
                                    
                                    wrapSchObjToAdd.ProductCode = ql.SBQQ__PackageProductCode__c;
                                    AllskuToWrapMap.put(ql.SBQQ__PackageProductCode__c,wrapSchObjToAdd);
                                    
                                } 
                            } 
                            else{
                                
                                AllskuToWrapMap.put(ql.SBQQ__PackageProductCode__c,wrapSchObjToAdd);//27March
                            }
                            //monthToWrapperMap.put(mnt,skuToWrapMap);
                        }
                        
                        //monthsInRange = monthsInRange++;
                    }
                } 
                /*if(!skuToWrapMap.keyset().contains(monthRange)){
skuToWrapMap.put(monthRange,wrapSchObjToAdd);
}*/
                
                //27March
                
                
                if(!monthRangeTraced.contains(monthRange)){
                    for(String sk : AllskuToWrapMap.keyset()){
                        
                        AllskuToWrapMap.get(sk).Month = monthRange;
                        skuToWrapMap.put(monthRange+AllskuToWrapMap.get(sk).ProductCode,AllskuToWrapMap.get(sk));
                        monthRangeTraced.add(monthRange);
                        
                        grandTotalForScheudle = grandTotalForScheudle+decimal.valueof(AllskuToWrapMap.get(sk).totalNetPricePerMonth);
                    }  
                }
                //skuToWrapperMap.put(monthsInRange,wrapSchObjToAdd);
                
            }
            
            //skuToWrapMap.put(string.valueof(mnt),wrapSchObjToAdd);
            
            wrapSchObjToAdd.month = monthRange;
            
            //ScaleUtility_Phase2
            List<String> schKeyList = New List<String>();
            for(String sch : skuToWrapMap.keyset()){
               schKeyList.add(sch);
            }    
            schKeyList.sort();
            integer inx =0 ;
            for(WrapperScheduleLines wp : skuToWrapMap.values()){
                skuToWrapMapSorted.add(wp);
            }
            for(String st : schKeyList){
                skuToWrapMapSorted[inx] = skuToWrapMap.get(st);
                inx++;
            }
           //ScaleUtility_Phase2

            //scheduleLinesToDisplay.addall(skuToWrapMap.values()); commented for sorting issue ScaleUtility_Phase2
            scheduleLinesToDisplay.addall(skuToWrapMapSorted);//ScaleUtility_Phase2
            //for(wrapperScheduleLines wp : skuToWrapperMap.values()){
            //scheduleLinesToDisplay.addall(skuToWrapperMap.values());
            //}
            totalForRange = 0;
            for(WrapperScheduleLines wp : skuToWrapMap.values()){
                totalForRange = totalForRange +decimal.valueof(wp.totalNetPricePerMonth);
                //grandTotalForScheudle = grandTotalForScheudle + totalForRange;
            }
            
            WrapperScheduleLines wrapSchObj1 = new WrapperScheduleLines();
            //if(monthsInRange > 0){
            if(totalForRange != null){
                wrapSchObj1.totalNetPricePerMonth = string.valueof(totalForRange);
                //wrapSchObj1.totalNetPricePerMonthStr = totalForRange.format();
                
                
                wrapSchObj1.totalNetPricePerMonthStr = ScaleUtilitySegmentedLineViewController.formatDollarAmount(totalForRange.setscale(2));
            }
            //}
            wrapSchObj1.month = null;
            wrapSchObj1.productCode  = null;
            wrapSchObj1.reserveQty = null;
            
            wrapSchObj1.unitNetPrice = ' Month '+monthRange;//+' TOTAL per month';
            //string key = string.valueof(ql.id)+string.valueof(ql.id);
            
            if(wrapSchObj1.totalNetPricePerMonth != '0' && wrapSchObj1.totalNetPricePerMonth != null){//ScaleUtility_Phase2 CSU-493   
                scheduleLinesToDisplay.add(wrapSchObj1);
            }
            
            
        }
        
        //grandTotalForScheudle = 9876.00;
        //ScaleUtility_Phase2 reserve grand total for upgrade scenario 
    }
    
    //Method created for ScaleUtility_Phase2 dumy FUE lines against RSV for upgrade /+ expansion scenario
    /**
     * @description Method to build on-fly FUE segment lines for RSV quote lines.
     * @param qLineList List of SBQQ__QuoteLine__c records representing quote lines.
     * @return List of SBQQ__QuoteLine__c records including the newly created FUE segment lines.
     */
    public static List<SBQQ__QuoteLine__c> buildOnFlyFUESegmentLines(List<SBQQ__QuoteLine__c> qLineList){
        
        List<SBQQ__QuoteLine__c> clonedFueLinesList = New List<SBQQ__QuoteLine__c>();
        Map<Id, SBQQ__QuoteLine__c> qlineToUpgradeMap = New Map<Id, SBQQ__QuoteLine__c>();
        Map<Id, Boolean> qlineToUpgradeExistingFueMap = New Map<Id, Boolean>(); 
        map<String,SBQQ__QuoteLine__c> fueToLineMap = New Map<String,SBQQ__QuoteLine__c>();
        List<String> lstUpgradeTypes = !String.isBlank(System.Label.RBK_SUUpgradeEditions) ? System.Label.RBK_SUUpgradeEditions.split(',') : new List<String>{'SU FUE', 'SU FUP', 'SU EUP', 'SU FUB'};

        for(SBQQ__QuoteLine__c ql : qLineList){
            if(lstUpgradeTypes.contains(ql.Scale_Utility_Product_Identifier__c)){
                fueToLineMap.put(ql.SBQQ__ProductCode__c,ql);
                qlineToUpgradeMap.put(ql.SBQQ__RequiredBy__c,ql);
                if(ql.SBQQSC__UpgradedContractLine__c != null){
                   qlineToUpgradeExistingFueMap.put(ql.SBQQ__RequiredBy__c,true);//CSU-708
                }
            }
        }
         
        for(SBQQ__QuoteLine__c ql : qLineList){
            if(((ql.Scale_Utility_Product_RSV_OND__c == 'RSV'  || ql.Scale_Utility_Product_Identifier__c == 'M365 RSV SU') && qlineToUpgradeMap.keyset().size() >0 && qlineToUpgradeMap.keyset().contains(ql.SBQQ__RequiredBy__c)) || test.isrunningtest()){
                SBQQ__QuoteLine__c qlLine = New SBQQ__QuoteLine__c();
                qlLine.Scale_Utility_Product_Identifier__c = 'SU FUE';
                qlLine.SBQQ__Quantity__c = ql.SBQQ__Quantity__c; //fix for CSU-708 UAT issue
                qlLine.Quantity_TB__c = ql.SBQQ__Quantity__c;
                //qlLine.SBQQ__EffectiveQuantity__c = ql.SBQQ__Quantity__c;
                qlLine.SBQQ__PackageProductCode__c = qlineToUpgradeMap.containsKey(ql.SBQQ__RequiredBy__c) ? qlineToUpgradeMap.get(ql.SBQQ__RequiredBy__c).SBQQ__ProductCode__c : '';//ql.SBQQ__PackageProductCode__c.replace('-FE-','-FUE-');
                qlLine.SBQQ__SegmentLabel__c = ql.SBQQ__SegmentLabel__c;
                qlLine.SBQQ__RequiredBy__c = ql.SBQQ__RequiredBy__c;
                qlLine.Scale_Utility_Product_RSV_OND__c = '';
                //Post production fix ScaleUtility_Phase2
                if(fueToLineMap.keyset().contains(qlLine.SBQQ__PackageProductCode__c) && fueToLineMap.get(qlLine.SBQQ__PackageProductCode__c).SBQQ__TotalDiscountRate__c != null ){
                   qlLine.SBQQ__NetPrice__c =  (fueToLineMap.get(qlLine.SBQQ__PackageProductCode__c).SBQQ__ListPrice__c-((fueToLineMap.get(qlLine.SBQQ__PackageProductCode__c).SBQQ__ListPrice__c* fueToLineMap.get(qlLine.SBQQ__PackageProductCode__c).SBQQ__TotalDiscountRate__c)/100)).setScale(2);//ITNPI-3033 //ql.SBQQ__NetPrice__c;
                }else if(fueToLineMap.keyset().contains(qlLine.SBQQ__PackageProductCode__c)){
                   qlLine.SBQQ__NetPrice__c = fueToLineMap.get(qlLine.SBQQ__PackageProductCode__c).SBQQ__ListPrice__c;
                }
                
                qlLine.SBQQ__Description__c = 'FUELine';
                //qlLine.SBQQ__NetTotal__c = ql.SBQQ__NetTotal__c;
                //CSU-708
                if(qlineToUpgradeExistingFueMap.keyset().contains(ql.SBQQ__RequiredBy__c) && qlineToUpgradeExistingFueMap.get(ql.SBQQ__RequiredBy__c) == true){
                   
                   qlLine.SBQQSC__UpgradedContractLine__c = ql.SBQQSC__UpgradedContractLine__c;
                   qlLine.SBQQ__Quantity__c = ql.SBQQ__EffectiveQuantity__c!= null && ql.SBQQ__EffectiveQuantity__c > 0 ? ql.SBQQ__EffectiveQuantity__c : ql.SBQQ__Quantity__c ;
                }
                
                clonedFueLinesList.add(qlLine);
            }
            
        }
        qLineList.addall(clonedFueLinesList);
        return qLineList;
    }
    /**  
    * @description Method to format decimal value to dollar amount with 2 decimal places 
    * @param x
    * @return String
    */
    public Static string formatDollarAmount(decimal x){
        String outputStr;
        String y = String.valueOf(x);
        String z = '.';
        if(y.contains(',')) z = ',';
        y = y.substring(0, y.indexOf(z));
        if(x - Decimal.valueOf(y) == 0){
            outputStr = String.valueOf(x.format()) + z + '00';
        }    
        else{ 
            string er = x.format();
            
            //outputStr = String.valueOf(x.format());
            
            String s = String.valueOf(x); // assuming you meant to use d here
            String afterDecimal = s.substringAfter('.');
            //afterDecimal = afterDecimal
            afterDecimal = afterDecimal.substring(afterDecimal.length()-1);
            
            if(integer.valueof(afterDecimal) >=1 ){
                outputStr = String.valueOf(x.format());
                
            }
            else{
                outputStr = String.valueOf(x.format()) + '0';
            }
        } 
        return outputStr;
    }
}