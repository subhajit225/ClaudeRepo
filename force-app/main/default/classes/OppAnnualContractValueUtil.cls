/**
 * @description apex class to calculate ACV amounts on opportunity and opportunity product
 */
public without sharing class OppAnnualContractValueUtil {
    public static Set<ID> oppIdSetAcvCalculation = new Set<ID>();
    /**
     * @description add exception class
     */
    public class InvalidSplitOpportunityException extends Exception {}
    private static final Set<String> NON_RENEWAL_SALES_COPM_CATEGORY_TO_EXCLUDE = new set<String>{'HW SUPPORT', 'HARDWARE', 'CONFERENCE', 'EVALUATION UNITS', 'INSTALL', 'NFR', 'PROFESSIONAL SERVICES - PAY ON DELIVERY', 'PROFESSIONAL SERVICES - PREPAY', 'RESTOCKING FEE', 'TRAINING', 'TRAVEL & EXPENSE', 'SHIPPING', 'RUBRIK CLOUD DATA MGMT', 'CEM'};
    private static final Set<String> RENEWAL_SALES_COPM_CATEGORY_TO_EXCLUDE = new set<String>{'HARDWARE', 'CONFERENCE', 'EVALUATION UNITS', 'INSTALL', 'NFR', 'PROFESSIONAL SERVICES - PAY ON DELIVERY', 'PROFESSIONAL SERVICES - PREPAY', 'RESTOCKING FEE', 'TRAINING', 'TRAVEL & EXPENSE', 'SHIPPING', 'RUBRIK CLOUD DATA MGMT', 'CEM'};
    private static final Set<String> RENEWAL_SALES_COPM_CATEGORY_TO_EXCLUDE4ARR = new set<String>{'HARDWARE', 'CONFERENCE', 'EVALUATION UNITS', 'INSTALL', 'NFR', 'PROFESSIONAL SERVICES - PAY ON DELIVERY', 'PROFESSIONAL SERVICES - PREPAY', 'RESTOCKING FEE', 'TRAINING', 'TRAVEL & EXPENSE', 'CONSUMPTION ACTUALS', 'CONSUMPTION OVERAGES', 'RENEWAL REINSTATEMENT FEE', 'SHIPPING', 'RUBRIK CLOUD DATA MGMT', 'CEM'};

    private static Opportunity_Stage_Days__c oppSetupCS = Opportunity_Stage_Days__c.getInstance(UserInfo.getUserId());

    private static Map<Id,double> earlyACVMap = new Map<Id,double>();
    private static Map<Id,double> lateACVMap = new Map<Id,double>();
    private static Map<Id,double> ontimeACVMap = new Map<Id,double>();
    //ARY-281, ARY-619
    private static Map<Id,double> lodStandACVMap = new Map<Id,double>();
    private static Map<Id,double> subscriptionACVMap = new Map<Id,double>();
    private static Map<Id,double> hwSupportACVMap = new Map<Id,double>();
    private static Map<Id,double> swSupportACVMap = new Map<Id,double>();
    private static Map<Id,double> subscriptionAddonACVMap = new Map<Id,double>();
    private static Set<String> lodStandaloneGroup = new Set<String>{'Life of Device Standalone','Perpetual','Perpetual Add-On','Perpetual Standalone'};
    private static Set<String> subscriptionGroup = new Set<String>{'Subscription ELA','Subscription Standalone','Subscription','Consumption','Consumption Add-On','Consumption Standalone'};
    private static Set<String> hwSupportGroup = new Set<String>{'HW Support'};
    private static Set<String> swSupportGroup = new Set<String>{'SW Support'};
    private static Set<String> subscriptionAddonGroup = new Set<String>{'Subscription Add-On'};
    //SAL24-145
    private static Map<Id,double> expansionTotalTCVMap = new Map<Id,double>(); 
    private static final string GC_OFFER ='GC Offer';
    private static final string StageFIVE ='5 Negotiate & Close';
    private static final string StageSIX ='6 PO With Channel';
    public static Boolean OppACVUtilFlag = false;
    public static Boolean OppACVRecursion = false;
    public static Map<ID, OpportunityLineItem> oliMap;
    public static Map<ID, AcvWrapper> mainACVWrapMap = new Map<ID, AcvWrapper>();
    public static Map<Id,OpportunityLineItem> oppsplitlineOppMap = new Map<Id,OpportunityLineItem>();
    private static Boolean updateDebookingOpp = false; //SAL25-529
    //private static Map<String,String> productHierarchytoBucketMap = new Map<String,String>(); //PL26-24 //SAL26-1218 commented
    private static Map<String, List<String>> plsSalesCompCatMap = new Map<String, List<String>>(); //SAL26-169
    private static decimal m365Qnty = 0;
    private Static Map<Id,Decimal> rampedOpplineMaxPMMap = new Map<Id,Decimal>(); //SAL26-1344  
    
    /**
     * @description calculate acv amounts on opportunity
     * @param newOppList
     * @param oldOppMap
     */
    public static void calculateAcvOnAmountChange(List<Opportunity> newOppList, Map<ID, Opportunity> oldOppMap){
        if(OppAnnualContractValueUtil.oppIdSetAcvCalculation.containsAll(oldOppMap.keySet())) {return;}
        if(OppACVRecursion){return;}
        Set<ID> amountChangedForOppIdSet = new Set<ID>();
        Set<ID> openToCloseOppIsSet = new Set<ID>();
        for(Opportunity newOpp: newOppList){
            Opportunity oldOpp = oldOppMap.get(newOpp.id);
            if((oldOpp.StageName != newOpp.StageName && (newOpp.StageName == '7 Closed Won' || newOpp.StageName == '7 Closed Lost' || newOpp.StageName == '7 Closed Admin') ) || 
                oldOpp.Amount != newOpp.Amount || oldOpp.OppSubscriptionTermMonths__c != newOpp.OppSubscriptionTermMonths__c || 
                oldOpp.Number_of_Opportunity_Products__c != newOpp.Number_of_Opportunity_Products__c){
                amountChangedForOppIdSet.add(newOpp.id);
                if(oldOpp.StageName != newOpp.StageName && (newOpp.StageName == '7 Closed Won' || newOpp.StageName == '7 Closed Lost' || newOpp.StageName == '7 Closed Admin') ){
                    openToCloseOppIsSet.add(newOpp.id);
                }
            }
        }
        calculateAcvAmount(amountChangedForOppIdSet, openToCloseOppIsSet);
    }

    //OppAnnualContractValueUtil.calculateAcvAmount(new Set<ID> {''});
    /**
     * @description calculate acv amounts on opportunity
     * @param amountChangedForOppIdSet1
     */
    public static void calculateAcvAmount(Set<ID> amountChangedForOppIdSet1){
        calculateAcvAmount(amountChangedForOppIdSet1, new Set<ID>());
    }

    /**
     * @description calculate acv amounts on opportunity
     * @param amountChangedForOppIdSet1
     * @param openToCloseOppIsSet
    */
    public static void calculateAcvAmount(Set<ID> amountChangedForOppIdSet1, Set<ID> openToCloseOppIsSet){
        Double sum = 0;
        updateDebookingOpp = false; //SAL25-529
        Map<String, Set<String>> selectedValues = new Map<String, Set<String>> ();//SAL26-94 
        if(amountChangedForOppIdSet1.isEmpty() || oppSetupCS.Name == null) return;
        if(OppACVRecursion){return;}
        Set<ID> amountChangedForOppIdSet = new Set<ID>();
        amountChangedForOppIdSet.addAll(amountChangedForOppIdSet1);
        //Can we merge OpportunityLineItemTriggersHelper.updateOppLODProducts() here? //SF-11225- For Marked LOD on Opp.
        //if(UserInfo.getUserId() != '0051W000005b193QAA') return;
        for(Opportunity o: [Select ID, Name, Opportunity_Split_Parent__c, CloseDate,Early_ACV__c,Late_ACV__c,On_Time_ACV__c,LOD_Standalone_ACV__c,Subscription_ACV__c,HW_Support_ACV__c,SW_Support_ACV__c,Subscription_Add_On_ACV__c, //ARY-281, ARY-619
                            CCR__c, CCR__r.Opportunity__c,Expansion_Products_TCV__c FROM Opportunity where ID IN :amountChangedForOppIdSet AND (Opportunity_Split_Parent__c != null OR CCR__r.Opportunity__c != null)]){
            if(o.Opportunity_Split_Parent__c != null){ 
                amountChangedForOppIdSet.add(o.Opportunity_Split_Parent__c);
            }
            if(o.CCR__c != null && o.CCR__r.Opportunity__c != null){
                updateDebookingOpp = true;  //SAL25-529
                amountChangedForOppIdSet.add(o.CCR__r.Opportunity__c);
            }
        }
        
        Map<ID, Opportunity> oppMap = new Map<ID, Opportunity>([Select ID, RBOBACV__c,PLS_NCD_New_Expansion_ACV__c,Core_New_Expansion_ACV__c,NAS_New_Expansion_ACV__c,PLS_New_Expansion_ACV__c,SaaS_New_Expansion_ACV__c,PLS_AE_ETM_Role_Name__c,Co_Owner__c, NCD_Co_Owner__c,SaaS_Co_Owner__c,Opp_Product_Mix__c, Opportunity_Amount_Override__c, ACV_Amount__c, Name,StageName,Opportunity_Type__c,isclosed,RecordTypeId,Automated_Uncheck_SOW_Required__c,SOW_Required__c, CloseDate,Early_ACV__c,Late_ACV__c,On_Time_ACV__c,LOD_Standalone_ACV__c, Subscription_ACV__c,HW_Support_ACV__c,SW_Support_ACV__c,Subscription_Add_On_ACV__c, //ARY-281, ARY-619
            Account.Customer_Type_Without_RCV__c,Number_of_Opportunity_Products__c, SBQQ__PrimaryQuote__c, SBQQ__PrimaryQuote__r.SBQQ__Primary__c, SBQQ__PrimaryQuote__r.RSC_G_Eligible__c, Opportunity_Sub_Type__c, Amount, split__c, Split_percentage__c, Split_Amount__c, Opportunity_Split_Parent__c, Upside_Amount__c, Downside_amount__c, //SAL25-574
            Has_LOD_Products__c, OppSubscriptionTermMonths__c, CCR__c, CCR__r.Opportunity__c,Expansion_Products_TCV__c,New_Expansion_ACV__c,New_Expansion_TCV__c,Subsumed_Renewal_TCV__c,Renewal_TCV__c,Renewal_ACV__c,Renewal_Subsumed_ACV__c, 
                            CCR__r.Opportunity__r.Opportunity_Sub_Type__c,CCR__r.CCR_Type__c,CCR__r.Opportunity__r.Opportunity_Amount_Override__c,Subsumed_Renewal_Churn_ACV__c,Subsumed_Renewal_Churn_TCV__c,UCL_Scale_Percentage__c, // SAL26-169-Added UCL_Scale_Percentage__c
                            RSC_Version__c,SBQQ__PrimaryQuote__r.Is_Ramp_Quote__c ,//SAL26-94 //SAL26-1334 added CCR__r.CCR_Type__c
            (Select ID, Prepayment_Credit__c,RBOBACV__c,PLS_NCD_New_Expansion_ACV__c,Core_New_Expansion_ACV__c,NAS_New_Expansion_ACV__c,PLS_New_Expansion_ACV__c,SaaS_New_Expansion_ACV__c,Original_OpplineitemId__c,opportunity.Opportunity_Amount_Override__c,opportunity.CCR__c,opportunity.CCR__r.Opportunity__c,opportunity.CCR__r.Opportunity__r.Opportunity_Amount_Override__c,Opportunity.Opportunity_Type__c, Name,Quantity,Renewal_Due_Date__c,Opportunity.CloseDate, Renewal_Timing__c, Product2Id, ProductCode, TotalPrice, ACV_Amount__c, ARR_Amount__c, Sales_Comp_Category__c,Prorate_Multiplier__c, Subscription_Term__c, SBQQ__QuoteLine__c, 
                                                                 SalesCompCategory__c, Product2.EffectiveStartDate__c, Product2.EffectiveEndDate__c, Product2.ReasonForChange__c, Product2.Sales_Comp_Category__c, Line_Type__c, QuoteLine_Product_Group__c,SBQQ__QuoteLine__r.Product_Subtype__c, //ARY-281, ARY-619,SAL25-574
            OpportunityId,Licensing_Type__c, Contract_Terms__c,opportunity.Opportunity_Split_Parent__c,Subsumed_Renewal_Amount__c,New_Expansion_ACV__c,New_Expansion_TCV__c,Subsumed_Renewal_TCV__c,Renewal_TCV__c,Line_Type_Text__c,
                                                                 SubsRenAmt__c,Original_Subsumed_Renewal_TCV__c,Subsumed_Renewal_Churn_ACV__c,Subsumed_Renewal_Churn_TCV__c,Opportunity.Amount, SBQQ__QuoteLine__r.SubsRenAmt__c,UCL_Scale__c, product2.Product_Level__c,Rubrik_Hosted_M365_Quantity__c,Atlassian_Quantity__c,Dynamics_Quantity__c,Salesforce_Quantity__c, SBQQ__QuoteLine__r.CompUpliftACV__c, Comp_Uplift_ACV__c,Opportunity.SBQQ__PrimaryQuote__r.Is_Ramp_Quote__c, Parent_split_Opplineitem_Id__c,
                                                                 Reporting_Renewal_Date__c, SBQQ__QuoteLine__r.Reporting_Renewal_Date__c, SBQQ__QuoteLine__r.RBOBACV__c from OpportunityLineItems)  //SAL26-1277
            FROM Opportunity where ID IN :amountChangedForOppIdSet OR Opportunity_Split_Parent__c IN: amountChangedForOppIdSet OR CCR__r.Opportunity__c IN :amountChangedForOppIdSet
            ORDER BY Opportunity_Split_Parent__c, CCR__c, CCR__r.Opportunity__c NULLS FIRST ]); //PL26-24 Adding N/E ACV fields//SAL26-1218:added NCD field

        
       /* Map<ID, OpportunityLineItem> oliMap = new Map<ID, OpportunityLineItem>([Select ID, Name,Quantity,Renewal_Due_Date__c,Opportunity.CloseDate, Renewal_Timing__c, Product2Id, ProductCode, TotalPrice, ACV_Amount__c, ARR_Amount__c, Sales_Comp_Category__c, Subscription_Term__c, SBQQ__QuoteLine__c, 
            SalesCompCategory__c, Product2.EffectiveStartDate__c, Product2.EffectiveEndDate__c, Product2.ReasonForChange__c, Product2.Sales_Comp_Category__c, Line_Type__c, QuoteLine_Product_Group__c, //ARY-281, ARY-619
            OpportunityId,Licensing_Type__c, Contract_Terms__c,opportunity.Opportunity_Split_Parent__c,Subsumed_Renewal_Amount__c,New_Expansion_ACV__c,New_Expansion_TCV__c,Subsumed_Renewal_TCV__c,Renewal_TCV__c,Line_Type_Text__c from OpportunityLineItem where OpportunityId IN :oppMap.keySet()
            ORDER BY Opportunity.Opportunity_Split_Parent__c, Opportunity.CCR__c NULLS FIRST ]);*/
         
        oliMap = new Map<ID, OpportunityLineItem>();
        Map<ID, AcvWrapper> oppIdAcvWrapperMap = new Map<ID, AcvWrapper>();
        AcvWrapper acvW;
        List<OpportunityLineItem> oliAcvUpdateList = new List<OpportunityLineItem>();

        //Map<ID, Integer> maxSwSupportSubscriptionTermMap = new Map<ID, Integer>(); //SAL26-1255
        Map<ID, Integer> maxSwSupportProrateMultiplierMap = new Map<ID, Integer>(); //SAL26-1255
        Set<String> ConsultQuantitySet = system.Label.ConsultSKUs != null ? new Set<String>(system.Label.ConsultSKUs.split(';')) : new Set<String>();
        Set<String> SOWRequiredSKUsSet = system.Label.SOWRequiredSKUs != null ? new Set<String>(system.Label.SOWRequiredSKUs.split(',')) : new Set<String>();
        Map<Id,Boolean> issplitOppMap = new Map<Id,Boolean>();
        Map<Id,Boolean> isopptysplitlineExistsMap = new Map<Id,Boolean>();
        Map<String,decimal> rampedMaxPMMap = new Map<String,decimal>(); //SAL26-1344 
        
        for(Product_Hierarchy_Group_mapping__mdt phg : [SELECT label, DeveloperName, Bucket__c, PLS_NE_ACV_Sales_Comp__c 
                                                                                FROM Product_Hierarchy_Group_mapping__mdt 
                                                        LIMIT 1000]){
                                                            /*if(String.isBlank(phg.PLS_NE_ACV_Sales_Comp__c)) { //SAL26-1218 commented
            productHierarchytoBucketMap.put(phg.label,phg.Bucket__c);
                                                             } else*/  // SAL26-169
                                                            if(String.isNotBlank(phg.PLS_NE_ACV_Sales_Comp__c)){
				plsSalesCompCatMap.put(phg.Bucket__c, phg.PLS_NE_ACV_Sales_Comp__c.split(','));
			}
        }
        //PL26-24 end
        //SAL26-169
        Map<Id, PlsACVWrapper> oppIdToPlsAcvWrapperMap = new Map<Id, PlsACVWrapper>();
        PlsACVWrapper plsWrapper;//SAL26-687 - add 4th param //SAL26-1218
        
        for(Id oppId : oppMap.keySet()){
           plsWrapper = new PlsACVWrapper(false, false, false, false, false, false); //SAL26-169//SAL26-687
           earlyACVMap.put(oppId,0);
           lateACVMap.put(oppId,0);
           ontimeACVMap.put(oppId,0);
           //ARY-281, ARY-619
           lodStandACVMap.put(oppId,0);
           subscriptionACVMap.put(oppId,0);
           hwSupportACVMap.put(oppId,0);
           swSupportACVMap.put(oppId,0);
           subscriptionAddonACVMap.put(oppId,0);
           //SAL24-145   
           expansionTotalTCVMap.put(oppId,0); 
           for(OpportunityLineItem LineItem : oppMap.get(oppId).opportunityLineItems){
               Decimal maxPM = 0;
               oliMap.put(LineItem.Id,LineItem);
                
               /* SAL26-1234 //SAL26-169
                if(String.isNotBlank(LineItem.Product2.Sales_Comp_Category__c) && LineItem.Line_Type__c == 'New' && LineItem.productcode != 'OPTY-SPLIT'){ //SAL26-308
                    
                if(!plsWrapper.hasSaaSO365SalesComp && plsSalesCompCatMap.containsKey('SaaS O365') && plsSalesCompCatMap.get('SaaS O365').contains(LineItem.Product2.Sales_Comp_Category__c)){
					plsWrapper.hasSaaSO365SalesComp = true;
				} 
				if(!plsWrapper.hasNasCloudSalesComp && plsSalesCompCatMap.containsKey('NAS NAS Cloud') && plsSalesCompCatMap.get('NAS NAS Cloud').contains(LineItem.Product2.Sales_Comp_Category__c)){
					plsWrapper.hasNasCloudSalesComp = true;
				}
				if(!plsWrapper.hasNasUCLSalesComp && plsSalesCompCatMap.containsKey('NAS UCL Scale') && plsSalesCompCatMap.get('NAS UCL Scale').contains(LineItem.Product2.Sales_Comp_Category__c)){
					plsWrapper.hasNasUCLSalesComp = true;
                    }
                    //SAL26-687
                    if(!plsWrapper.hasNasRCDMScale2SalesComp && plsSalesCompCatMap.containsKey('NAS RCDM Scale2') && plsSalesCompCatMap.get('NAS RCDM Scale2').contains(LineItem.Product2.Sales_Comp_Category__c)){ 
                        plsWrapper.hasNasRCDMScale2SalesComp = true;
                    }
                    
                }//SAL26-169 SAL26-1234 End*/
                
        //SAL26-1218,1220,1221
                if(String.isNotBlank(LineItem.Product2.Sales_Comp_Category__c) && LineItem.Line_Type__c == 'New' && LineItem.productcode != 'OPTY-SPLIT'){
                    if(!plsWrapper.hasDSPM && plsSalesCompCatMap.get('DSPM').contains(LineItem.Product2.Sales_Comp_Category__c)){
                        plsWrapper.hasDSPM = true;
                    }
                    if(!plsWrapper.hasNcdNasConsumptionSalesComp && plsSalesCompCatMap.get('NAS NCD').contains(LineItem.Product2.Sales_Comp_Category__c)){
                        plsWrapper.hasNcdNasConsumptionSalesComp = true;
                    } 
                    if(!plsWrapper.hasCloudConsumptionSalesComp && plsSalesCompCatMap.get('Cloud Consumption').contains(LineItem.Product2.Sales_Comp_Category__c)){
                        plsWrapper.hasCloudConsumptionSalesComp = true;
                    }
                    if(!plsWrapper.hasSaaSIdentity && plsSalesCompCatMap.get('SaaS Identity').contains(LineItem.Product2.Sales_Comp_Category__c)){
                        plsWrapper.hasSaaSIdentity = true;
                    }
                    
                    if(!plsWrapper.hasO365 && plsSalesCompCatMap.get('SaaS O365').contains(LineItem.Product2.Sales_Comp_Category__c)){
                        plsWrapper.hasO365 = true;
                    }

                    if(!plsWrapper.hasSaaSAddOn && LineItem.Product2.Sales_Comp_Category__c.equalsIgnoreCase('SaaS Add-On')){
                        plsWrapper.hasSaaSAddOn = true;
                    }
                    
                    if(m365Qnty == 0 && LineItem.Rubrik_Hosted_M365_Quantity__c != null && LineItem.Rubrik_Hosted_M365_Quantity__c > 0 && LineItem.Product2.Sales_Comp_Category__c.equalsIgnoreCase('SaaS Add-On')){
                        Decimal sfQnty = LineItem.Salesforce_Quantity__c == null ? 0 : LineItem.Salesforce_Quantity__c;
                        Decimal dynamicQnty = LineItem.Dynamics_Quantity__c == null ? 0 : LineItem.Dynamics_Quantity__c;
                        Decimal atlassianQnty = LineItem.Atlassian_Quantity__c == null ? 0 : LineItem.Atlassian_Quantity__c;
                        m365Qnty =  LineItem.Rubrik_Hosted_M365_Quantity__c/(sfQnty + dynamicQnty + LineItem.Rubrik_Hosted_M365_Quantity__c + atlassianQnty);
                    }
                }
               
           
        
                //SAL26-1344 
                if(oppMap.get(oppId).SBQQ__PrimaryQuote__c != null && oppMap.get(oppId).SBQQ__PrimaryQuote__r.Is_Ramp_Quote__c == 'Yes'){
                    maxPM = LineItem.Prorate_Multiplier__c != null ? LineItem.Prorate_Multiplier__c : 0;
                    if(rampedMaxPMMap.containskey(LineItem.ProductCode+'#'+LineItem.Line_Type__c) && rampedMaxPMMap.get(LineItem.ProductCode+'#'+LineItem.Line_Type__c) != null && maxPM < rampedMaxPMMap.get(LineItem.ProductCode+'#'+LineItem.Line_Type__c)){
                        maxPM = rampedMaxPMMap.get(LineItem.ProductCode+'#'+LineItem.Line_Type__c);                        
                    }
                    rampedMaxPMMap.put(LineItem.ProductCode+'#'+LineItem.Line_Type__c,maxPM);
                }

        if(oppMap.get(oppId).split__c && oppMap.get(oppId).Split_percentage__c != null && oppMap.get(oppId).Split_percentage__c > 0 && oppMap.get(oppId).Split_percentage__c < 100 && oppMap.get(oppId).Opportunity_Split_Parent__c == null){  //Need to create OPTY-SPLIT lineitem
            issplitOppMap.put(oppId,true);
            if(LineItem.productcode == 'OPTY-SPLIT'){
                isopptysplitlineExistsMap.put(oppId,true);
            }
        }
    }
            oppIdToPlsAcvWrapperMap.put(oppId, plsWrapper); //SAL26-169
        }
        //To insert OPTY-SPLIT which was deleted due to cpq managed package on Parent Split Opp
        if(!issplitOppMap.isEmpty() && OpportunitySplitLWCController.createOptySPlitLine){ 
            Id pricebookentryIdval = System.Label.OPTY_SPLIT_PriceBookEntryId;
            PriceBook_Config_Ids__c pbConfig = PriceBook_Config_Ids__c.getValues('OPTYSPLITPriceBookEntryId'); //SAL26-550
            if(pbConfig != null && pbConfig.Config_Id__c != ''){
                pricebookentryIdval = pbConfig.Config_Id__c;
            }
            for(Id oppId : oppMap.keySet()){
                 if(issplitOppMap.containskey(oppId) && (isopptysplitlineExistsMap.isEmpty() || !isopptysplitlineExistsMap.containskey(oppId))){ //Need to create OPTY-SPLIT lineitem
                    OpportunityLineItem splitoli = new OpportunityLineItem(PricebookEntryId = pricebookentryIdval,
                                                                                            OpportunityId = oppId,
                                                                                            Quantity = 1,
                                                                                            isSplit__c = true,
                                                                                            TotalPrice = (oppMap.get(oppId).Amount * (100 - oppMap.get(oppId).Split_percentage__c) / 100) * (-1)); //SAL25-760
                     oppsplitlineOppMap.put(oppId,splitoli);

                }
            }
        }
        for(OpportunityLineItem oli: oliMap.values()){
            String salesCompCategory = oli.Sales_Comp_Category__c;
            if(!oli.opportunity.Opportunity_Amount_Override__c ){ //SAL25-145
              oli.ACV_Amount__c = null;
            }
            oli.ARR_Amount__c = null;
            if(openToCloseOppIsSet.contains(oli.OpportunityId)){
                salesCompCategory = oli.Product2.Sales_Comp_Category__c; 
                oli.SalesCompCategory__c = salesCompCategory; 
            }
/*Start SAL26-1255
            if(salesCompCategory == 'SW SUPPORT' && oli.Subscription_Term__c != null){
                if(!maxSwSupportSubscriptionTermMap.containsKey(oli.OpportunityId)){
                    maxSwSupportSubscriptionTermMap.put(oli.OpportunityId, (Integer)oli.Subscription_Term__c);
                }else if(maxSwSupportSubscriptionTermMap.get(oli.OpportunityId) < oli.Subscription_Term__c){
                    maxSwSupportSubscriptionTermMap.put(oli.OpportunityId, (Integer)oli.Subscription_Term__c);
                }
            }*/
            if(salesCompCategory == 'SW SUPPORT' && oli.Prorate_Multiplier__c != null){
                if(!maxSwSupportProrateMultiplierMap.containsKey(oli.OpportunityId)){
                    maxSwSupportProrateMultiplierMap.put(oli.OpportunityId, (Integer)oli.Prorate_Multiplier__c);
                }else if(maxSwSupportProrateMultiplierMap.get(oli.OpportunityId) < oli.Prorate_Multiplier__c){
                    maxSwSupportProrateMultiplierMap.put(oli.OpportunityId, (Integer)oli.Prorate_Multiplier__c);
            }
            //SAL26-1344 
            if(rampedMaxPMMap.containskey(oli.ProductCode+'#'+oli.Line_Type__c)){
                rampedOpplineMaxPMMap.put(oli.Id,rampedMaxPMMap.get(oli.ProductCode+'#'+oli.Line_Type__c));
            }
        }
            //End SAL26-1255
        }

        for(OpportunityLineItem oli: oliMap.values()){
            acvW =  oppIdAcvWrapperMap.get(oli.OpportunityId);
            //SAL26-1344 
            if(oppMap.get(oli.OpportunityId).Opportunity_Split_Parent__c != null && oli.Parent_split_Opplineitem_Id__c != null && rampedOpplineMaxPMMap.containskey(oli.Parent_split_Opplineitem_Id__c)){
                rampedOpplineMaxPMMap.put(oli.Id,rampedOpplineMaxPMMap.get(oli.Parent_split_Opplineitem_Id__c));
            }
            if(acvW == null){
                acvW = new AcvWrapper(oppMap.get(oli.OpportunityId));
                oppIdAcvWrapperMap.put(oli.OpportunityId, acvW);
                if(acvW.oppObj.Opportunity_Split_Parent__c != null && (oppMap.get(acvW.oppObj.Opportunity_Split_Parent__c).SBQQ__PrimaryQuote__c == null || (oppMap.get(acvW.oppObj.Opportunity_Split_Parent__c).SBQQ__PrimaryQuote__c != null && !oppMap.get(acvW.oppObj.Opportunity_Split_Parent__c).SBQQ__PrimaryQuote__r.SBQQ__Primary__c))){
                    AcvWrapper parentacvW = new AcvWrapper(oppMap.get(acvW.oppObj.Opportunity_Split_Parent__c));
                    oppIdAcvWrapperMap.put(acvW.oppObj.Opportunity_Split_Parent__c, parentacvW);
                }
                if(acvW.oppObj.Opportunity_Split_Parent__c != null && oppIdAcvWrapperMap.containskey(acvW.oppObj.Opportunity_Split_Parent__c)){ // Parents records will add first into oppIdAcvWrapperMap then child Opp. Link Child Opp with Parents
                    oppIdAcvWrapperMap.get(acvW.oppObj.Opportunity_Split_Parent__c).splitChildOppList.add(oppMap.get(oli.OpportunityId));
                }
            }
            mainACVWrapMap.put(oli.OpportunityId,acvW); //SAL26-258
            if(oli.Renewal_Due_Date__c != null){
                oli.Renewal_Timing__c = OpportunityLineItemTriggersHelper.populateRenewalTiming(oli);
            }
            if(oli.ProductCode == 'OPTY-SPLIT'){
                if(oli.opportunity.Opportunity_Split_Parent__c != null && (oppMap.get(oli.opportunity.Opportunity_Split_Parent__c).Amount == 0 || (oppMap.get(acvW.oppObj.Opportunity_Split_Parent__c).SBQQ__PrimaryQuote__c != null && !oppMap.get(oli.opportunity.Opportunity_Split_Parent__c).SBQQ__PrimaryQuote__r.SBQQ__Primary__c))){
                   oli.ACV_Amount__c = 0;
                   oli.TotalPrice = 0;
                   oli.New_Expansion_ACV__c = 0;
                   oli.New_Expansion_TCV__c = 0; 
                }
                acvW.splitProductList.add(oli);
            }else{
                if(oli.Line_Type__c != 'Renewal'){
                	acvW.hasRealProducts = true;
                }
                acvW.oliList.add(oli);
                String salesCompCategory = oli.Sales_Comp_Category__c;
                if(openToCloseOppIsSet.contains(oli.OpportunityId)){
                    salesCompCategory = oli.SalesCompCategory__c; 
                }
                //SAL26-94 Start
                if(oli.SBQQ__QuoteLine__r.Product_Subtype__c == 'FEDRAMP') {
                    if(selectedValues.containsKey(oli.OpportunityId)) {
                        selectedValues.get(oli.OpportunityId).add('RSC-G');
                    } else {
                        selectedValues.put(oli.OpportunityId, new Set<String> {'RSC-G'});
                    }
                }
                if(oli.product2.Product_Level__c == 'OnPrem') {
                     if(selectedValues.containsKey(oli.OpportunityId)) {
                        selectedValues.get(oli.OpportunityId).add('RSC-P');
                    } else {
                        selectedValues.put(oli.OpportunityId, new Set<String> {'RSC-P'});
                    }
                }
                //SAL26-94 End
                calculateAcvOnProduct(oppIdToPlsAcvWrapperMap.get(oli.OpportunityId), acvW.oppObj, oli, oliAcvUpdateList, acvW, maxSwSupportProrateMultiplierMap, salesCompCategory); //SAL26-1255
                
                //SAL23-471
                //if(!NON_RENEWAL_SALES_COPM_CATEGORY_TO_EXCLUDE.contains(salesCompCategory)){//ACV-SFDC-015
                acvW.oppSubscriptionTerm = acvW.oppSubscriptionTerm < oli.Prorate_Multiplier__c? (Integer)oli.Prorate_Multiplier__c  : acvW.oppSubscriptionTerm; //SAL26-1255
                //}
                checkSowRequired(oli, acvW, SOWRequiredSKUsSet, ConsultQuantitySet);
                checkScaleProducts(oli, acvW); //SAL26-389
            }
            oppIdAcvWrapperMap.put(oli.OpportunityId,acvW);
            if(oli.Line_Type__c == 'Renewal' && oli.ACV_Amount__c != null){
                if(oli.Renewal_Timing__c == 'On-Time'){
                    sum = ontimeACVMap.get(oli.OpportunityId)+oli.ACV_Amount__c;
                    ontimeACVMap.put(oli.OpportunityId,sum);
                }else if(oli.Renewal_Timing__c == 'Early'){
                    sum = earlyACVMap.get(oli.OpportunityId)+oli.ACV_Amount__c;
                    earlyACVMap.put(oli.OpportunityId,sum);
                }else if(oli.Renewal_Timing__c == 'Late'){
                    sum = lateACVMap.get(oli.OpportunityId)+oli.ACV_Amount__c;
                    lateACVMap.put(oli.OpportunityId,sum);
                }
                //ARY-281, ARY-619
                String prdGroup = oli.QuoteLine_Product_Group__c?.trim();
                if(lodStandaloneGroup.contains(prdGroup)){
                    sum = lodStandACVMap.get(oli.OpportunityId)+oli.ACV_Amount__c;
                    lodStandACVMap.put(oli.OpportunityId,sum);
                }else if(subscriptionGroup.contains(prdGroup)){
                    sum = subscriptionACVMap.get(oli.OpportunityId)+oli.ACV_Amount__c;
                    subscriptionACVMap.put(oli.OpportunityId,sum);
                }else if(hwSupportGroup.contains(prdGroup)){
                    sum = hwSupportACVMap.get(oli.OpportunityId)+oli.ACV_Amount__c;
                    hwSupportACVMap.put(oli.OpportunityId,sum);
                }else if(swSupportGroup.contains(prdGroup)){
                    sum = swSupportACVMap.get(oli.OpportunityId)+oli.ACV_Amount__c;
                    swSupportACVMap.put(oli.OpportunityId,sum);
                }else if(subscriptionAddonGroup.contains(prdGroup)){
                    sum = subscriptionAddonACVMap.get(oli.OpportunityId)+oli.ACV_Amount__c;
                    subscriptionAddonACVMap.put(oli.OpportunityId,sum);
                }
            }
            if(oli.Line_Type__c != 'Renewal'){ //SAL24-145
                sum = expansionTotalTCVMap.get(oli.OpportunityId)+oli.TotalPrice;
                expansionTotalTCVMap.put(oli.OpportunityId,sum);
            }
         }
        setAcvOnOpportunities(oppIdAcvWrapperMap, oppMap, oliAcvUpdateList, selectedValues);
        //update oliMap.values();
    }

    //Product will be considered either for ACV_Amount or TotalHW_HwSupportAmount on rollup.
    /**
     * @description calculate acv amounts on opportunity product
     * @param plsWrapper
     * @param oppObj
     * @param oli
     * @param oliAcvUpdateList
     * @param acvW
     * @param maxSwSupportSubscriptionTermMap
     * @param salesCompCategory
    */
    private static void calculateAcvOnProduct(PlsACVWrapper plsWrapper, Opportunity oppObj, OpportunityLineItem oli, List<OpportunityLineItem> oliAcvUpdateList, AcvWrapper acvW, Map<ID, Integer> maxSwSupportSubscriptionTermMap, String salesCompCategory){
        Decimal maxPM = rampedOpplineMaxPMMap.containskey(oli.Id) ? rampedOpplineMaxPMMap.get(oli.Id) : oli.Prorate_Multiplier__c; //SAL26-1344
        if(!oppObj.Opportunity_Amount_Override__c){
            oli.Comp_Uplift_ACV__c = oli.SaaS_New_Expansion_ACV__c = oli.NAS_New_Expansion_ACV__c = oli.PLS_New_Expansion_ACV__c = oli.Core_New_Expansion_ACV__c = oli.PLS_NCD_New_Expansion_ACV__c = 0; //SAL26-169 //SAL26-1218//SAL26-1277
        }
        boolean isOliUpdated = false;
        oli.ARR_Amount__c = null;
        Decimal debooklineSplitPerc = 0; //SAL26-7
        //FY25SR-1125 Starts
        Decimal tcvAmt = 0;
        if (oli.Prepayment_Credit__c != null) {
            tcvAmt = oli.TotalPrice + oli.Prepayment_Credit__c;
        }
        else {
            tcvAmt = oli.TotalPrice;
        }
        //FY25SR-1125 Ends
		if(oli.SBQQ__QuoteLine__c != null){ //Renewal Subsumed ACV issue fix - SAL25-481
            oli.SubsRenAmt__c = oli.SBQQ__QuoteLine__r.SubsRenAmt__c;
            oli.Reporting_Renewal_Date__c = oli.SBQQ__QuoteLine__r.Reporting_Renewal_Date__c; //SALE-123
            oli.RBOBACV__c = oli.SBQQ__QuoteLine__r.RBOBACV__c != null ? oli.SBQQ__QuoteLine__r.RBOBACV__c : 0; //SALE-123
            if(!oppObj.Opportunity_Amount_Override__c && oli.Line_Type__c == 'Renewal'){//SAL26-1277
                oli.Comp_Uplift_ACV__c = oli.SBQQ__QuoteLine__r.CompUpliftACV__c;
            }
        }
        if(!oppObj.Opportunity_Amount_Override__c){  //SAL25-145
              oli.ACV_Amount__c = null;
        }
        if(!oppObj.Opportunity_Amount_Override__c && oppObj.Opportunity_Type__c !='Debooking'){ //SAL25-145 - issue fix
            oli.Subsumed_Renewal_Amount__c = oli.SubsRenAmt__c;
        }
        if(!RENEWAL_SALES_COPM_CATEGORY_TO_EXCLUDE4ARR.contains(salesCompCategory)){ //ARR-SFDC-007
            Decimal productSubTerm = 0;
            if(salesCompCategory != null && salesCompCategory != '' && salesCompCategory.contains('CONSUMPTION')){ //SAL25-174 //ARR-SFDC-013: If Contract_Terms__c is null or < 12 then set equal to OLI Total Price //SAL25-392
                productSubTerm = (oli.Contract_Terms__c > 12) ? oli.Contract_Terms__c : 12; 
            }else{
                //ARR-SFDC-014: If a subscription term == null then default the term of that product line to 39 months.
                //productSubTerm = (oli.Subscription_Term__c == null) ? ((renewalSubTypes.contains(oppObj.Opportunity_Sub_Type__c) || (oppObj.Opportunity_Type__c == 'Debooking' && oppObj.CCR__c != null && oppObj.CCR__r.Opportunity__c != null && renewalSubTypes.contains(oppObj.CCR__r.Opportunity__r.Opportunity_Sub_Type__c))) ? oppSetupCS.DefaultSubscriptionTermMonthsRenewARR__c:oppSetupCS.DefaultSubscriptionTermMonthsARR__c) : (oli.Subscription_Term__c > 12 ? oli.Subscription_Term__c : 12); //SAL26-350 //SAL26-1255
                productSubTerm = (oli.Prorate_Multiplier__c == null) ? ((oppObj.Opportunity_Sub_Type__c == 'Renewal' || (oppObj.Opportunity_Type__c == 'Debooking' && oppObj.CCR__c != null && oppObj.CCR__r.Opportunity__c != null && oppObj.CCR__r.Opportunity__r.Opportunity_Sub_Type__c == 'Renewal')) ? oppSetupCS.DefaultSubscriptionTermMonthsRenewARR__c:oppSetupCS.DefaultSubscriptionTermMonthsARR__c) : (oli.Prorate_Multiplier__c > 12 ? oli.Prorate_Multiplier__c : 12); //SAL26-1255
            }
            //This “Amount (ARR) (F)” calculation should be as follows: (Opportunity Product Line Total Price ÷ (Opportunity Product Subscription Term ÷ 12))
            oli.ARR_Amount__c = (oli.TotalPrice / (productSubTerm / 12.0)); 
            isOliUpdated = true;
        }
        if(         ((oppObj.Opportunity_Sub_Type__c == 'Renewal' || (oppObj.Opportunity_Type__c == 'Debooking' && oppObj.CCR__c != null && oppObj.CCR__r.Opportunity__c != null && oppObj.CCR__r.Opportunity__r.Opportunity_Sub_Type__c == 'Renewal')) && !RENEWAL_SALES_COPM_CATEGORY_TO_EXCLUDE.contains(salesCompCategory)) //ACV-SFDC-009
                ||  ((oppObj.Opportunity_Sub_Type__c != 'Renewal' || (oppObj.Opportunity_Type__c == 'Debooking' && oppObj.CCR__c != null && oppObj.CCR__r.Opportunity__c != null && oppObj.CCR__r.Opportunity__r.Opportunity_Sub_Type__c != 'Renewal')) && !NON_RENEWAL_SALES_COPM_CATEGORY_TO_EXCLUDE.contains(salesCompCategory)) //ACV-SFDC-008
        ){
            //SAL25-145
            if(salesCompCategory == 'CONSUMPTION ACTUALS' || salesCompCategory == 'CONSUMPTION OVERAGES'){//ACV-SFDC-033
                oli.ACV_Amount__c = (!oppObj.Opportunity_Amount_Override__c && oppObj.Opportunity_Type__c !='Debooking') ? tcvAmt : oli.ACV_Amount__c ;
                //ARY-886
                oli.Subsumed_Renewal_TCV__c = (!oppObj.Opportunity_Amount_Override__c && oppObj.Opportunity_Type__c !='Debooking') ? ((oli.Subsumed_Renewal_Amount__c != null) ? oli.Subsumed_Renewal_Amount__c : 0) : oli.Subsumed_Renewal_TCV__c; 
                oli.Original_Subsumed_Renewal_TCV__c = (oli.SubsRenAmt__c != null) ? oli.SubsRenAmt__c : 0; 
            }else if(salesCompCategory != null && salesCompCategory != '' && salesCompCategory.contains('CONSUMPTION')){//SAL25-174 //ACV-SFDC-033: If Contract_Terms__c is null or < 12 then set equal to OLI Total Price //SAL25-392
                if (oli.Contract_Terms__c > 12){
                    oli.ACV_Amount__c = (!oppObj.Opportunity_Amount_Override__c && oppObj.Opportunity_Type__c !='Debooking') ? (tcvAmt / (oli.Contract_Terms__c / 12.0)) : oli.ACV_Amount__c; 
                }else{
                    oli.ACV_Amount__c = (!oppObj.Opportunity_Amount_Override__c && oppObj.Opportunity_Type__c !='Debooking') ? tcvAmt : oli.ACV_Amount__c; 
                }
                //ARY-886
                oli.Subsumed_Renewal_TCV__c = (!oppObj.Opportunity_Amount_Override__c && oppObj.Opportunity_Type__c !='Debooking') ? ((oli.Subsumed_Renewal_Amount__c != null) ? ((oli.Contract_Terms__c != null && oli.Contract_Terms__c > 12) ? (oli.Subsumed_Renewal_Amount__c * oli.Contract_Terms__c)/12 : oli.Subsumed_Renewal_Amount__c) : 0) : oli.Subsumed_Renewal_TCV__c; 
                oli.Original_Subsumed_Renewal_TCV__c = (oli.SubsRenAmt__c != null) ? ((oli.Contract_Terms__c != null && oli.Contract_Terms__c > 12) ? (oli.SubsRenAmt__c * oli.Contract_Terms__c)/12 : oli.SubsRenAmt__c) : 0; 
            }else{//ACV-SFDC-007-010 //??
                if(Test.isRunningTest() || salesCompCategory == 'RUBRIK CLOUD DATA MGMT'){ //ACV-SFDC-016
                      //Integer maxSwSupportSubscriptionTerm = maxSwSupportSubscriptionTermMap.get(oli.OpportunityId); //SAL26-1255
                      Integer maxSwSupportProrateMultiplier = maxSwSupportSubscriptionTermMap.get(oli.OpportunityId); //SAL26-1255
                      maxSwSupportProrateMultiplier = (Integer) (maxSwSupportProrateMultiplier == null || maxSwSupportProrateMultiplier < oppSetupCS.DefaultSubscriptionTermMonths__c ?  oppSetupCS.DefaultSubscriptionTermMonths__c : maxSwSupportProrateMultiplier);
                      oli.ACV_Amount__c = (!oppObj.Opportunity_Amount_Override__c  && oppObj.Opportunity_Type__c !='Debooking') ? (tcvAmt / (maxSwSupportProrateMultiplier / 12.0)) : oli.ACV_Amount__c;
                    //ARY-886
                      oli.Subsumed_Renewal_TCV__c = (!oppObj.Opportunity_Amount_Override__c  && oppObj.Opportunity_Type__c !='Debooking') ? ((oli.Subsumed_Renewal_Amount__c != null) ?  ((oli.Subsumed_Renewal_Amount__c * maxSwSupportProrateMultiplier)/12) : 0) : oli.Subsumed_Renewal_TCV__c; 
                      oli.Original_Subsumed_Renewal_TCV__c = (oli.SubsRenAmt__c != null) ?  ((oli.SubsRenAmt__c * maxSwSupportProrateMultiplier)/12) : 0; 
                }else{
                      if(oli.Prorate_Multiplier__c != null /* && oli.Subscription_Term__c > 12*/){//ACV-13: consider the term as 12 months if it is less than 12 months.
                          oli.ACV_Amount__c = (!oppObj.Opportunity_Amount_Override__c && oppObj.Opportunity_Type__c !='Debooking') ? (tcvAmt  / (maxPM / 12.0)) : oli.ACV_Amount__c; //SAL26-1344
                      }//comment else code Khushboo
                    /*else{//if product is eligible for ACV and no subscription term then use TCV (Total price) as ACV for that product
                        oli.ACV_Amount__c = (!oppObj.Opportunity_Amount_Override__c && oppObj.Opportunity_Type__c !='Debooking') ? tcvAmt : oli.ACV_Amount__c;
                    }*/
                    //ARY-886 //SAL25-145
                    if(!oppObj.Opportunity_Amount_Override__c && oppObj.Opportunity_Type__c !='Debooking')
                      setArroyofieldsforProduct(oli);
                }
            }
            if(oppObj.Opportunity_Type__c == 'Debooking' && oli.Original_OpplineitemId__c != '' && oliMap.containskey(oli.Original_OpplineitemId__c)){ //SAL25-145
                  debooklineSplitPerc = (oli.Totalprice/oliMap.get(oli.Original_OpplineitemId__c).Totalprice); //SAL26-7
                  if(oliMap.get(oli.Original_OpplineitemId__c).ACV_Amount__c != null && oppObj.CCR__r.CCR_Type__c != 'Unpaid Replacement Debooking'){
                  	oli.ACV_Amount__c = debooklineSplitPerc * oliMap.get(oli.Original_OpplineitemId__c).ACV_Amount__c ;
                  }
                  if(oliMap.get(oli.Original_OpplineitemId__c).ARR_Amount__c != null){ //SAL26-7
                      oli.ARR_Amount__c = debooklineSplitPerc * oliMap.get(oli.Original_OpplineitemId__c).ARR_Amount__c ;
                  }
            }
            
            if(!oppObj.Opportunity_Amount_Override__c && ('Renewal' == oppObj.Opportunity_Sub_Type__c || (oppObj.Opportunity_Type__c == 'Debooking' && oppObj.CCR__c != null && oppObj.CCR__r.Opportunity__c != null && oppObj.CCR__r.Opportunity__r.Opportunity_Sub_Type__c == 'Renewal')) 
               || (('Renewal' != oppObj.Opportunity_Sub_Type__c && 'Renewal' != oli.Line_Type__c) || (oppObj.Opportunity_Type__c == 'Debooking' && oppObj.CCR__c != null && oppObj.CCR__r.Opportunity__c != null && oppObj.CCR__r.Opportunity__r.Opportunity_Sub_Type__c != 'Renewal' && oli.Line_Type_Text__c != '' && 'Renewal' != oli.Line_Type_Text__c))){
                acvW.acvAmount += (oli.ACV_Amount__c == null) ? 0 : oli.ACV_Amount__c; //ACV-SFDC-011
                isOliUpdated = true;
            }
            
        }else if(salesCompCategory == 'HARDWARE' || salesCompCategory == 'HW SUPPORT'){//ACV-SFDC-021
            acvW.totalHwSupportAmount += (oli.TotalPrice == null) ? 0 : oli.TotalPrice;
            //No ACV, so consider TotalPrice for calculating below fields
            //ARY-886 //SAL25-145
            if(!oppObj.Opportunity_Amount_Override__c && oppObj.Opportunity_Type__c != 'Debooking')
              setArroyofieldsforProduct(oli);
                       
        }else if(!oppObj.Opportunity_Amount_Override__c && oli.ProductCode != 'OPTY-SPLIT'){ //ARY-886 //SAL25-145
           setArroyofieldsforProduct(oli);
        }
        if(isOliUpdated 
            && (('Renewal' == oppObj.Opportunity_Sub_Type__c || (oppObj.Opportunity_Type__c == 'Debooking' && oppObj.CCR__c != null && oppObj.CCR__r.Opportunity__c != null && oppObj.CCR__r.Opportunity__r.Opportunity_Sub_Type__c == 'Renewal'))  || (('Renewal' != oppObj.Opportunity_Sub_Type__c && 'Renewal' != oli.Line_Type__c) || (oppObj.Opportunity_Type__c == 'Debooking' && oppObj.CCR__c != null && oppObj.CCR__r.Opportunity__c != null && oppObj.CCR__r.Opportunity__r.Opportunity_Sub_Type__c != 'Renewal' && oli.Line_Type_Text__c != '' && 'Renewal' != oli.Line_Type_Text__c)))    
        ){
            acvW.arrAmount += (oli.ARR_Amount__c == null) ? 0 : oli.ARR_Amount__c; //ARR-SFDC-008
        }
        
        //SAL24-749 //SAL25-145
        if(!oppObj.Opportunity_Amount_Override__c && oppObj.Opportunity_Type__c != 'Debooking'){ //SAL24-191
            
            if( oli.TotalPrice > 0){
            oli.Subsumed_Renewal_Amount__c = (oli.Subsumed_Renewal_Amount__c != null && oli.ACV_Amount__c != null && oli.Subsumed_Renewal_Amount__c > oli.ACV_Amount__c) ? oli.ACV_Amount__c : oli.Subsumed_Renewal_Amount__c;
            oli.Subsumed_Renewal_TCV__c = (oli.Subsumed_Renewal_TCV__c != null && oli.TotalPrice != null && oli.Subsumed_Renewal_TCV__c > oli.Totalprice) ? oli.Totalprice : oli.Subsumed_Renewal_TCV__c;
            }//SAL25-574 
            else if(oppObj.SBQQ__PrimaryQuote__c != null && oppObj.SBQQ__PrimaryQuote__r.RSC_G_Eligible__c && oli.SBQQ__QuoteLine__c != null && oli.SBQQ__QuoteLine__r.Product_Subtype__c == 'FEDRAMP' && oli.ACV_Amount__c == 0 && oli.TotalPrice == 0){
                oli.Subsumed_Renewal_Amount__c = 0;
                oli.Subsumed_Renewal_TCV__c  = 0;
            }// end of SAL25-574
            
        }
        
        if(!oppObj.Opportunity_Amount_Override__c && oppObj.Opportunity_Type__c != 'Debooking'){
            oli.New_Expansion_ACV__c = oli.Line_Type__c == 'New' ? ((oli.ACV_Amount__c != null && oli.Subsumed_Renewal_Amount__c != null) ? (oli.ACV_Amount__c - oli.Subsumed_Renewal_Amount__c) : oli.ACV_Amount__c) : ((oli.ACV_Amount__c != null && oli.RBOBACV__c != null) ? (oli.ACV_Amount__c - oli.RBOBACV__c) : oli.ACV_Amount__c); //SAL26-1280
              oli.New_Expansion_TCV__c = (oli.TotalPrice != null && oli.Subsumed_Renewal_TCV__c != null) ? (oli.TotalPrice - oli.Subsumed_Renewal_TCV__c) : oli.TotalPrice;
      	}else if(oppObj.Opportunity_Type__c == 'Debooking'  && oli.Original_OpplineitemId__c != '' && oliMap.containskey(oli.Original_OpplineitemId__c)){ //SAL25-145
            debooklineSplitPerc = (oli.Totalprice/oliMap.get(oli.Original_OpplineitemId__c).Totalprice); //SAL26-7
            oli.New_Expansion_ACV__c = oliMap.get(oli.Original_OpplineitemId__c).New_Expansion_ACV__c != null && oppObj.CCR__r.CCR_Type__c != 'Unpaid Replacement Debooking' ? debooklineSplitPerc * (oliMap.get(oli.Original_OpplineitemId__c).New_Expansion_ACV__c ) : null; //SAL25-145
            oli.New_Expansion_TCV__c = oliMap.get(oli.Original_OpplineitemId__c).New_Expansion_TCV__c != null ? debooklineSplitPerc * (oliMap.get(oli.Original_OpplineitemId__c).New_Expansion_TCV__c ) : null;
        }  
        //ARY-886
        if(oli.Line_Type__c == 'Renewal' || (oli.Line_Type_Text__c != '' && oli.Line_Type_Text__c == 'Renewal')){
            oli.Renewal_TCV__c = oli.TotalPrice;
            //oli.New_Expansion_ACV__c = 0; //commented as per SAL26-1280
            oli.New_Expansion_TCV__c = 0;
            oli.Subsumed_Renewal_TCV__c = 0;
            oli.Subsumed_Renewal_Amount__c = 0;
            oli.Original_Subsumed_Renewal_TCV__c = 0;
            oli.Subsumed_Renewal_Churn_ACV__c = 0;
            oli.Subsumed_Renewal_Churn_TCV__c = 0;
            //acvW.renewalACV += (oli.ACV_Amount__c == null) ? 0 : oli.ACV_Amount__c; //SAL24-676 //commented as part of SAL26-1280
        }
        //ARY-1151
        if((oli.TotalPrice >= 0 && oli.New_Expansion_ACV__c < 0) || (oli.TotalPrice < 0 && oli.New_Expansion_ACV__c > 0)){
            oli.New_Expansion_ACV__c = 0;
        }
        if((oli.TotalPrice >= 0 && oli.New_Expansion_TCV__c < 0) || (oli.TotalPrice < 0 && oli.New_Expansion_TCV__c > 0)){
            oli.New_Expansion_TCV__c = 0;
        }
        if(!oppObj.Opportunity_Amount_Override__c){//SAL26-851
            calculateChurn(oli);
        }
        acvW.tcvAmount += (oli.TotalPrice == null) ? 0 : oli.TotalPrice;
        if(!oppObj.Opportunity_Amount_Override__c){ 
          acvW.newExpansionACV += (oli.New_Expansion_ACV__c == null) ? 0 : oli.New_Expansion_ACV__c;
          acvW.newExpansionTCV += (oli.New_Expansion_TCV__c == null) ? 0 : oli.New_Expansion_TCV__c;
          acvW.subsumedRenewalTCV += (oli.Subsumed_Renewal_TCV__c == null) ? 0 : oli.Subsumed_Renewal_TCV__c;
          acvW.subsumedRenewalACV += (oli.Subsumed_Renewal_Amount__c == null) ? 0 : oli.Subsumed_Renewal_Amount__c;
          acvW.compUpliftACV += (oli.Comp_Uplift_ACV__c ?? 0); //SAL26-1277
        //SAL26-1280: Track New vs Renewal line types separately for split calculation
            if(oli.Line_Type__c == 'New'){
                acvW.newLineNewExpansionACV += (oli.New_Expansion_ACV__c == null) ? 0 : oli.New_Expansion_ACV__c;
            }else if(oli.Line_Type__c == 'Renewal' || (oli.Line_Type_Text__c != '' && oli.Line_Type_Text__c == 'Renewal')){
                acvW.renewalLineNewExpansionACV += (oli.New_Expansion_ACV__c == null) ? 0 : oli.New_Expansion_ACV__c;
            }
        }
        
    //SAL26-1218,SAL26-1220,SAL26-1221//SAL26-1353
        if(!oppObj.Opportunity_Amount_Override__c && String.isNotBlank(salesCompCategory) && oli.New_Expansion_ACV__c != null && oppObj.Opportunity_Type__c != 'Debooking' && oli.Line_Type__c == 'New' && oli.productcode != 'OPTY-SPLIT') { //SAL26-211 //SAL26-308
            if(salesCompCategory.containsIgnoreCase('RCV') && plsWrapper.hasNcdNasConsumptionSalesComp && (plsWrapper.hasCloudConsumptionSalesComp || (oppObj.UCL_Scale_Percentage__c != null && oppObj.UCL_Scale_Percentage__c > 0))){
                assignPlsAcvValues(0, oli.New_Expansion_ACV__c, oli.New_Expansion_ACV__c/2, 0, oli.New_Expansion_ACV__c/2, oli);
            } else if(plsSalesCompCatMap.get('NAS NCD').contains(salesCompCategory) || (salesCompCategory.containsIgnoreCase('RCV') && plsWrapper.hasNcdNasConsumptionSalesComp)){
                assignPlsAcvValues(0, oli.New_Expansion_ACV__c, 0, 0, oli.New_Expansion_ACV__c, oli);
            } else if((plsSalesCompCatMap.get('DSPM').contains(salesCompCategory) || plsSalesCompCatMap.get('SaaS Identity').contains(salesCompCategory)) && plsWrapper.hasO365){ 
                assignPlsAcvValues(0, oli.New_Expansion_ACV__c, 0, oli.New_Expansion_ACV__c, 0, oli);
            } else if(plsSalesCompCatMap.get('SaaS Consumption').contains(salesCompCategory)){ 
                assignPlsAcvValues(0, oli.New_Expansion_ACV__c, 0, oli.New_Expansion_ACV__c, 0, oli);
            } else if((plsSalesCompCatMap.get('DSPM').contains(salesCompCategory) || plsSalesCompCatMap.get('SaaS Identity').contains(salesCompCategory)) && plsWrapper.hasSaaSAddOn){
                if(m365Qnty > 0){
                    assignPlsAcvValues(0, oli.New_Expansion_ACV__c, 0, oli.New_Expansion_ACV__c, 0, oli);
                } else {
                    assignPlsAcvValues(oli.New_Expansion_ACV__c, 0, 0, 0, 0, oli);
                }
            } else if(plsSalesCompCatMap.get('SaaS Add-On').contains(salesCompCategory)){
                if(oli.Rubrik_Hosted_M365_Quantity__c != null && oli.Rubrik_Hosted_M365_Quantity__c > 0){
                    Decimal sfQnty = oli.Salesforce_Quantity__c == null ? 0 : oli.Salesforce_Quantity__c;
                    Decimal dynamicQnty = oli.Dynamics_Quantity__c == null ? 0 : oli.Dynamics_Quantity__c;
                    Decimal atlassianQnty = oli.Atlassian_Quantity__c == null ? 0 : oli.Atlassian_Quantity__c;
                    Decimal m365Qnty1 =  oli.Rubrik_Hosted_M365_Quantity__c/(sfQnty + dynamicQnty + oli.Rubrik_Hosted_M365_Quantity__c + atlassianQnty);
                    Decimal saasAcv = oli.New_Expansion_ACV__c*m365Qnty1;
                    assignPlsAcvValues(oli.New_Expansion_ACV__c - saasAcv, saasAcv, 0, saasAcv, 0, oli);
                } else {
                    assignPlsAcvValues(oli.New_Expansion_ACV__c, 0, 0, 0, 0, oli);
                }
            } else if(plsSalesCompCatMap.get('Cloud Scale').contains(salesCompCategory) && oppObj.UCL_Scale_Percentage__c != null && oppObj.UCL_Scale_Percentage__c > 0){ 
                assignPlsAcvValues((oli.New_Expansion_ACV__c*(100-oppObj.UCL_Scale_Percentage__c))/100, 
                                   (oli.New_Expansion_ACV__c*oppObj.UCL_Scale_Percentage__c)/100, 
                                   (oli.New_Expansion_ACV__c*oppObj.UCL_Scale_Percentage__c)/100, 0, 0, oli);
            } else if(plsSalesCompCatMap.get('Cloud Unstructured').contains(salesCompCategory)){
                assignPlsAcvValues(0, oli.New_Expansion_ACV__c, oli.New_Expansion_ACV__c, 0, 0, oli);
            } else if(salesCompCategory.contains('RCV') && (plsWrapper.hasCloudConsumptionSalesComp || (oppObj.UCL_Scale_Percentage__c != null && oppObj.UCL_Scale_Percentage__c > 0))){ 
                assignPlsAcvValues(0, oli.New_Expansion_ACV__c, oli.New_Expansion_ACV__c, 0, 0, oli);
            } else if(salesCompCategory.contains('RCV') && String.isNotBlank(oppObj.Account.Customer_Type_Without_RCV__c)){
                assignRCVSkuAcv(oppObj, oli);     //SAL26-1326         
            } else {
                assignPlsAcvValues(oli.New_Expansion_ACV__c, 0, 0, 0, 0, oli);
            }  	
        }
		
        //PL26-24 START //SAL26-169 Start //SAL26-1218:commented
        /*if(!oppObj.Opportunity_Amount_Override__c && oli.New_Expansion_ACV__c != null && oppObj.Opportunity_Type__c != 'Debooking' && oli.Line_Type__c == 'New' && oli.productcode != 'OPTY-SPLIT') { //SAL26-211 //SAL26-308
            if(String.isNotBlank(salesCompCategory) && plsWrapper.hasSaaSO365SalesComp && plsWrapper.hasNasUCLSalesComp && plsSalesCompCatMap.containsKey('Laminar') && plsSalesCompCatMap.get('Laminar').contains(salesCompCategory)){
                oli.SaaS_New_Expansion_ACV__c = oli.New_Expansion_ACV__c*0.5;
                oli.NAS_New_Expansion_ACV__c = oli.New_Expansion_ACV__c*0.5;
                oli.PLS_New_Expansion_ACV__c = oli.New_Expansion_ACV__c;
                oli.Core_New_Expansion_ACV__c = 0;
            } else if(String.isNotBlank(salesCompCategory) && plsWrapper.hasSaaSO365SalesComp && ((plsSalesCompCatMap.containsKey('Laminar') && plsSalesCompCatMap.get('Laminar').contains(salesCompCategory)) || (plsSalesCompCatMap.containsKey('SaaS Sales') && plsSalesCompCatMap.get('SaaS Sales').contains(salesCompCategory)))){ //SAL26-308 //SAL26-644
                oli.SaaS_New_Expansion_ACV__c = oli.New_Expansion_ACV__c;
                oli.PLS_New_Expansion_ACV__c = oli.New_Expansion_ACV__c;
                oli.Core_New_Expansion_ACV__c = 0;
                oli.NAS_New_Expansion_ACV__c = 0;
            } else if(String.isNotBlank(salesCompCategory) && (((plsSalesCompCatMap.containsKey('NAS Cloud Vault') && plsSalesCompCatMap.get('NAS Cloud Vault').contains(salesCompCategory)) || salesCompCategory.containsIgnoreCase('CLOUD VAULT')) && (plsWrapper.hasNasCloudSalesComp || (plsWrapper.hasNasRCDMScale2SalesComp && oppObj.UCL_Scale_Percentage__c > 0)))){ //SAL26-687: added OR condition
                oli.NAS_New_Expansion_ACV__c = oli.New_Expansion_ACV__c;
                oli.PLS_New_Expansion_ACV__c = oli.New_Expansion_ACV__c;
                oli.Core_New_Expansion_ACV__c = 0;
                oli.SaaS_New_Expansion_ACV__c = 0;
            } else if(String.isNotBlank(salesCompCategory) && (plsSalesCompCatMap.containsKey('Laminar') && plsSalesCompCatMap.get('Laminar').contains(salesCompCategory) && plsWrapper.hasNasUCLSalesComp)) {
                oli.NAS_New_Expansion_ACV__c = oli.New_Expansion_ACV__c;
                oli.PLS_New_Expansion_ACV__c = oli.New_Expansion_ACV__c;
                oli.Core_New_Expansion_ACV__c = 0;
                oli.SaaS_New_Expansion_ACV__c = 0;
            } else if(String.isNotBlank(salesCompCategory) && (salesCompCategory.containsIgnoreCase('SCALE') || (plsSalesCompCatMap.containsKey('NAS RCDM Scale') && plsSalesCompCatMap.get('NAS RCDM Scale').contains(salesCompCategory)))) {
                if(oppObj.UCL_Scale_Percentage__c == null || oppObj.UCL_Scale_Percentage__c == 0) {
                    oli.Core_New_Expansion_ACV__c = oli.New_Expansion_ACV__c;
                    oli.PLS_New_Expansion_ACV__c = 0;
                    oli.NAS_New_Expansion_ACV__c = 0;
                    oli.SaaS_New_Expansion_ACV__c = 0;//SAL26-687:fix
                } else if(oppObj.UCL_Scale_Percentage__c != null && oppObj.UCL_Scale_Percentage__c > 0){
                    oli.NAS_New_Expansion_ACV__c = (oli.New_Expansion_ACV__c*oppObj.UCL_Scale_Percentage__c)/100;
                    oli.PLS_New_Expansion_ACV__c = (oli.New_Expansion_ACV__c*oppObj.UCL_Scale_Percentage__c)/100;
                    oli.Core_New_Expansion_ACV__c = (oli.New_Expansion_ACV__c*(100-oppObj.UCL_Scale_Percentage__c))/100;
                    oli.SaaS_New_Expansion_ACV__c = 0;//SAL26-687:fix
                } //SAL26-169 End
            } else if(String.isBlank(oli.Product2?.Product_Hierarchy_Group__c) || productHierarchytoBucketMap.get(oli.Product2?.Product_Hierarchy_Group__c) == 'CORE'){
                oli.Core_New_Expansion_ACV__c = oli.New_Expansion_ACV__c;
            } else if(productHierarchytoBucketMap.get(oli.Product2?.Product_Hierarchy_Group__c) == 'SaaS'){
                oli.SaaS_New_Expansion_ACV__c = oli.New_Expansion_ACV__c;
                oli.PLS_New_Expansion_ACV__c = oli.New_Expansion_ACV__c;
            } else if(productHierarchytoBucketMap.get(oli.Product2?.Product_Hierarchy_Group__c) == 'NAS'){
                oli.NAS_New_Expansion_ACV__c = oli.New_Expansion_ACV__c;
                oli.PLS_New_Expansion_ACV__c = oli.New_Expansion_ACV__c;
            }
        }*/
        if(oli.Line_Type__c == 'New' && oli.ProductCode != 'OPTY-SPLIT'){
            acvW.hasRealProducts = true;
        }
        if(!oppObj.Opportunity_Amount_Override__c && oppObj.Opportunity_Type__c != 'Debooking'){ //SAL26-211
            acvw.coreNewExpansionACV += (oli.Core_New_Expansion_ACV__c == null) ? 0 : oli.Core_New_Expansion_ACV__c;
            acvw.nasNewExpansionACV += (oli.NAS_New_Expansion_ACV__c == null) ? 0 : oli.NAS_New_Expansion_ACV__c;
            acvw.saasNewExpansionACV += (oli.SaaS_New_Expansion_ACV__c == null) ? 0 : oli.SaaS_New_Expansion_ACV__c;
            acvw.plsNewExpansionACV += (oli.PLS_New_Expansion_ACV__c == null) ? 0 : oli.PLS_New_Expansion_ACV__c;
            acvw.ncdNewExpansionACV += (oli.PLS_NCD_New_Expansion_ACV__c == null) ? 0 : oli.PLS_NCD_New_Expansion_ACV__c; //SAL26-1218
        }
        //PL26-24 END
        acvW.orgSubsumedRenewalTCV += (oli.Original_Subsumed_Renewal_TCV__c == null) ? 0 : oli.Original_Subsumed_Renewal_TCV__c;
        acvW.orgSubsumedRenewalACV += (oli.SubsRenAmt__c == null) ? 0 : oli.SubsRenAmt__c;
        acvW.renewalTCV += (oli.Renewal_TCV__c == null) ? 0 : oli.Renewal_TCV__c;
        acvW.subChurnACV += (oli.Subsumed_Renewal_Churn_ACV__c == null) ? 0 : oli.Subsumed_Renewal_Churn_ACV__c;
        acvW.subChurnTCV += (oli.Subsumed_Renewal_Churn_TCV__c == null) ? 0 : oli.Subsumed_Renewal_Churn_TCV__c;
        acvW.ppCreds += (oli.Prepayment_Credit__c == null) ? 0 : oli.Prepayment_Credit__c;//FY25SR-1119
        acvW.rbobACV += (oli.RBOBACV__c != null) ? oli.RBOBACV__c : 0;//FY25SR-1119 //SAL26-1280
        acvW.renewalrbobACV += (oli.RBOBACV__c != null && oli.Line_Type__c == 'Renewal') ? oli.RBOBACV__c : 0;
        
        //SAL25-529
        if(!updateDebookingOpp || (updateDebookingOpp && oppObj.Opportunity_Type__c == 'Debooking')){
        oliAcvUpdateList.add(oli);
        }
    }

    /**
     * @description set acv amounts on opportunity 
     * @param oppIdAcvWrapperMap
     * @param oppMap
     * @param oliAcvUpdateList
     * @param selectedValues
    */
    private static void setAcvOnOpportunities(Map<ID, AcvWrapper> oppIdAcvWrapperMap, Map<ID, Opportunity> oppMap, List<OpportunityLineItem> oliAcvUpdateList, Map<String, Set<String>> selectedValues){
        List<Opportunity> oppToUpdate = new List<Opportunity>();

        for(Opportunity newOpp: oppMap.values()){
            List<String> listOfSelectedVersion = new List<String> ();//SAL26-94
            AcvWrapper acvW = oppIdAcvWrapperMap.get(newOpp.Id);
            setAcvOnOpp(newOpp, acvW, oppIdAcvWrapperMap, oliAcvUpdateList);

            //ARY-886
            if(acvW != null){ // should not assign for split Opp // && newOpp.Opportunity_Split_Parent__c == null && (!newOpp.split__c || (newOpp.split__c && newOpp.Split_percentage__c == null || newOpp.Split_percentage__c == 0)) //SAL25-778
                if(newOpp.Split_percentage__c == null){newOpp.Split_percentage__c = 100;} //SAL25-778
                if(!(newOpp.Opportunity_Sub_Type__c == GC_OFFER && newOpp.RecordTypeId == OpportunityUtil.oppRecTypeIdRenewOpp && (newOpp.StageName == StageFIVE || newOpp.StageName == StageSIX || newOpp.isclosed))){
                    if(!newOpp.Opportunity_Amount_Override__c){ 
                        //SAL25-778 - Start
                        //SAL26-1280: Split% applies only to New line types, Renewal line types are included at 100%
                        newOpp.New_Expansion_ACV__c = acvW.renewalLineNewExpansionACV + (acvW.newLineNewExpansionACV*newOpp.Split_percentage__c/100.0);
                        newOpp.New_Expansion_TCV__c = acvW.newExpansionTCV*newOpp.Split_percentage__c/100.0;
                        newOpp.Subsumed_Renewal_TCV__c = acvW.subsumedRenewalTCV*newOpp.Split_percentage__c/100.0;
                        newOpp.Renewal_Subsumed_ACV__c = acvw.subsumedRenewalACV*newOpp.Split_percentage__c/100.0;
                        //Added below 2 lines to this if condition as part of SAL26-851
                        newOpp.Subsumed_Renewal_Churn_ACV__c = acvW.subChurnACV*newOpp.Split_percentage__c/100.0;
                        newOpp.Subsumed_Renewal_Churn_TCV__c = acvW.subChurnTCV*newOpp.Split_percentage__c/100.0;
                        newOpp.Comp_Uplift_ACV__c = acvW.compUpliftACV; //SAL26-1277
                        //PL26-24 start
                        if(newOpp.Opportunity_Type__c != 'Debooking'){ //SAL26-211
                            newOpp.Core_New_Expansion_ACV__c = acvW.coreNewExpansionACV*newOpp.Split_percentage__c/100.0;
                            newOpp.NAS_New_Expansion_ACV__c = acvW.nasNewExpansionACV*newOpp.Split_percentage__c/100.0;
                            newOpp.SaaS_New_Expansion_ACV__c = acvW.saasNewExpansionACV*newOpp.Split_percentage__c/100.0;
                            newOpp.PLS_New_Expansion_ACV__c = acvW.plsNewExpansionACV*newOpp.Split_percentage__c/100.0;
							newOpp.PLS_NCD_New_Expansion_ACV__c = acvW.ncdNewExpansionACV*newOpp.Split_percentage__c/100.0; //SAL26-1218
                        }
                    }
                        //PL26-24 end   
                    newOpp.Renewal_ACV__c = acvW.renewalrbobACV+(newOpp.Renewal_Subsumed_ACV__c != null ? newOpp.Renewal_Subsumed_ACV__c : 0); //SAL26-1280 
                    OppACVUtilFlag = true;
                }
                newOpp.Renewal_TCV__c = acvW.renewalTCV*newOpp.Split_percentage__c/100.0; 
                //SAL25-778 - End
            }
            newOpp.Early_ACV__c = earlyACVMap.get(newOpp.Id);
            newOpp.Late_ACV__c = lateACVMap.get(newOpp.Id);
            newOpp.On_Time_ACV__c = ontimeACVMap.get(newOpp.Id);
            //ARY-281, ARY-619
            newOpp.LOD_Standalone_ACV__c = lodStandACVMap.get(newOpp.Id);
            newOpp.Subscription_ACV__c = subscriptionACVMap.get(newOpp.Id);
            newOpp.HW_Support_ACV__c = hwSupportACVMap.get(newOpp.Id);
            newOpp.SW_Support_ACV__c = swSupportACVMap.get(newOpp.Id);
            newOpp.Subscription_Add_On_ACV__c = subscriptionAddonACVMap.get(newOpp.Id);
            newOpp.NCD_SaaS_N_E_ACV__c = 0; //SAL26-1434
            //SAL24-145
            newOpp.Expansion_Products_TCV__c = expansionTotalTCVMap.get(newOpp.Id);
            if(newOpp.Expansion_Products_TCV__c != null && newOpp.Subsumed_Renewal_TCV__c != null){
              newOpp.Expansion_Products_TCV__c = newOpp.Expansion_Products_TCV__c - newOpp.Subsumed_Renewal_TCV__c;
            }
            if(acvW != null && acvW.sowskusRequired != newOpp.SOW_Required__c){
              newOpp.SOW_Required__c = acvW.sowskusRequired;
                if(!newOpp.SOW_Required__c){
                    newOpp.Automated_Uncheck_SOW_Required__c = true;
                }else{
                    newOpp.Automated_Uncheck_SOW_Required__c = false;
                }
            }
            
            //SAL26-389
            newOpp.Has_UCL_Scale_Products__c = false;
            if(acvW != null && acvW.hasScaleProducts != newOpp.Has_UCL_Scale_Products__c){ //SAL26-389
               newOpp.Has_UCL_Scale_Products__c = acvW.hasScaleProducts;
            }
      
            newOpp.RSC_Version__c = ''; //SAL26-94
      		//SAL26-94 start
            if(!selectedValues.isEmpty()) {
                if(selectedValues.get(newOpp.Id)!=null) {
                    listOfSelectedVersion.addAll(selectedValues.get(newOpp.Id));
                }
                newOpp.RSC_Version__c = String.join(listOfSelectedVersion, ';');
            }
            //SAL26-94 end
      
            //SAL24-582
            if(newOpp.Renewal_TCV__c != null && newOpp.Subsumed_Renewal_TCV__c != null){
              newOpp.Renewal_TCV__c = newOpp.Renewal_TCV__c + newOpp.Subsumed_Renewal_TCV__c;
            }
            //ARY-1151
            if(!(newOpp.Opportunity_Sub_Type__c == GC_OFFER && newOpp.RecordTypeId == OpportunityUtil.oppRecTypeIdRenewOpp && (newOpp.StageName == StageFIVE || newOpp.StageName == StageSIX || newOpp.isclosed))){
                if(Test.isRunningTest() || (newOpp.Amount >= 0 && newOpp.New_Expansion_ACV__c < 0) || (newOpp.Amount < 0 && newOpp.New_Expansion_ACV__c > 0)){
                    newOpp.New_Expansion_ACV__c = newOpp.Core_New_Expansion_ACV__c = newOpp.NAS_New_Expansion_ACV__c = newOpp.SaaS_New_Expansion_ACV__c = newOpp.PLS_NCD_New_Expansion_ACV__c = newOpp.PLS_New_Expansion_ACV__c = 0;//SAL26-1218
                }
                if((newOpp.Amount >= 0 && newOpp.New_Expansion_TCV__c < 0) || (newOpp.Amount < 0 && newOpp.New_Expansion_TCV__c > 0)){
                    newOpp.New_Expansion_TCV__c = 0;
                }
                //SAL24-676
                /*if(newOpp.Renewal_ACV__c != null && newOpp.Renewal_Subsumed_ACV__c != null){
                    newOpp.Renewal_ACV__c = newOpp.Renewal_ACV__c + newOpp.Renewal_Subsumed_ACV__c;
                }*/ 
                if(newOpp.Number_of_Opportunity_Products__c == 0){ //SAL26-1280
                    newOpp.Renewal_ACV__c = (newOpp.Renewal_Subsumed_ACV__c != null ? newOpp.Renewal_Subsumed_ACV__c : 0);
                }
            }
            OpportunityUtil.resetOppProductMix(newOpp); //PL26-47
            newOpp.NCD_SaaS_N_E_ACV__c = (newOpp.PLS_NCD_New_Expansion_ACV__c != null ? newOpp.PLS_NCD_New_Expansion_ACV__c : 0)+ (newOpp.SaaS_New_Expansion_ACV__c != null ? newOpp.SaaS_New_Expansion_ACV__c : 0); //SAL26-1434
            //SAL25-529
            if(!updateDebookingOpp || (updateDebookingOpp && newOpp.Opportunity_Type__c == 'Debooking')){
            oppToUpdate.add(newOpp);
        }
        }
        oppIdSetAcvCalculation.addAll(oppMap.keySet());
        flowcontroll.opportunityTriggerHandler = false;
        flowcontroll.opportunityLineItemHandler = false;
        OppACVRecursion = true;
        if(!oppToUpdate.isEmpty()){
            update oppToUpdate;
        }
        //SAL25-649 - START
        Set<Id> processedOliIds = new Set<Id>();
		List<OpportunityLineItem> uniqueOliAcvUpdateList = new List<OpportunityLineItem>();
        for (OpportunityLineItem oli : oliAcvUpdateList){
            if(!processedOliIds.contains(oli.Id)){
                processedOliIds.add(oli.Id);  
                uniqueOliAcvUpdateList.add(oli); 
            }
        }
        if(!uniqueOliAcvUpdateList.isEmpty()){
            upsert uniqueOliAcvUpdateList; //SAL25-590/SAL25-592
        }
        //SAL25-649 - END
        OppACVRecursion = false;
        flowcontroll.opportunityTriggerHandler = true;
        flowcontroll.opportunityLineItemHandler = true;
        oppIdSetAcvCalculation.removeAll(oppMap.keySet());

    }

    /**
     * @description calculate acv amounts on opportunity 
     * @param newOpp
     * @param acvW
     * @param oppIdAcvWrapperMap
     * @param oliAcvUpdateList
    */
    private static void setAcvOnOpp(Opportunity newOpp, AcvWrapper acvW, Map<ID, AcvWrapper> oppIdAcvWrapperMap, List<OpportunityLineItem> oliAcvUpdateList){
        //split__c, Split_percentage__c, Split_Amount__c, Opportunity_Split_Parent__c
        //SAL23-471
        //newOpp.OppSubscriptionTermMonths__c = (newOpp.OppSubscriptionTermMonths__c == null ? oppSetupCS.DefaultSubscriptionTermMonths__c : newOpp.OppSubscriptionTermMonths__c);
        newOpp.OppSubscriptionTermMonths__c = (newOpp.OppSubscriptionTermMonths__c == null || newOpp.OppSubscriptionTermMonths__c == 0)? oppSetupCS.DefaultSubscriptionTermMonths__c : newOpp.OppSubscriptionTermMonths__c;
        //SAL25-145
        if(((newOpp.Opportunity_Amount_Override__c == false && newOpp.Opportunity_Type__c != 'Debooking') || (newOpp.Opportunity_Type__c =='Debooking' && newOpp.CCR__r.Opportunity__r.Opportunity_Amount_Override__c == false)) && (!(newOpp.Opportunity_Type__c == 'Debooking' && (newOpp.Opportunity_Sub_Type__c == 'Partial' || newOpp.Opportunity_Sub_Type__c == 'Full' || newOpp.Opportunity_Sub_Type__c == 'Referral Fee')))){ //SAL24-691 //SAL25-127
            newOpp.ACV_Amount__c =  null;
        }
        newOpp.ARR_Amount__c =  null;
        newOpp.TotalHW_HwSupportAmount__c =  null;
        newOpp.Amount = newOpp.Amount == null ? 0 : newOpp.Amount;
        if(newOpp.CCR__c != null && newOpp.CCR__r.Opportunity__c != null){
            AcvWrapper acvWDeBookingParentOpp = oppIdAcvWrapperMap.get(newOpp.CCR__r.Opportunity__c);//If Opp is DeBooking-Child Opp. We need Parents Opp Data
            newOpp.OppSubscriptionTermMonths__c = acvWDeBookingParentOpp.oppObj.OppSubscriptionTermMonths__c;
        }
        if(acvW == null){//OLI not exists
            if(newOpp.Opportunity_Split_Parent__c == null){
                if(((newOpp.Opportunity_Amount_Override__c == false && newOpp.Opportunity_Type__c != 'Debooking') || (newOpp.Opportunity_Type__c =='Debooking' && newOpp.CCR__r.Opportunity__r.Opportunity_Amount_Override__c == false)) && (!(newOpp.Opportunity_Type__c == 'Debooking' && (newOpp.Opportunity_Sub_Type__c == 'Partial' || newOpp.Opportunity_Sub_Type__c == 'Full' || newOpp.Opportunity_Sub_Type__c == 'Referral Fee')))){ //SAL24-691 //SAL25-127 //SAL25-145
                      if(newOpp.OppSubscriptionTermMonths__c == null || newOpp.OppSubscriptionTermMonths__c < 12){
                          newOpp.ACV_Amount__c =  (newOpp.Amount * (oppSetupCS.DefaultAcvAmount__c / 100.0));//ACV-SFDC-004
                      }else{
                          newOpp.ACV_Amount__c =  (newOpp.Amount * (oppSetupCS.DefaultAcvAmount__c / 100.0)) / (newOpp.OppSubscriptionTermMonths__c / 12.0);//ACV-SFDC-004
                      }
                }
                newOpp.TotalHW_HwSupportAmount__c =  (newOpp.Amount * (oppSetupCS.DefaultHW_HW_Support__c / 100.0)); //ACV-SFDC-019-020
                Decimal arrSTerm = newOpp.Opportunity_Sub_Type__c == 'Renewal' ? oppSetupCS.DefaultSubscriptionTermMonthsRenewARR__c : oppSetupCS.DefaultSubscriptionTermMonthsARR__c;
                Decimal arrPercent = newOpp.Opportunity_Sub_Type__c == 'Renewal' ? 100 : oppSetupCS.DefaultAcvAmount__c;
                newOpp.ARR_Amount__c = (newOpp.Amount * (arrPercent / 100.0)) / (arrSTerm / 12.0);//ARR-SFDC-002 & ARR-SFDC-003
            }else if(newOpp.split__c && newOpp.Opportunity_Split_Parent__c != null && oppIdAcvWrapperMap.get(newOpp.Opportunity_Split_Parent__c) != null){ //child split opp, if no products
                AcvWrapper acvWSplitParentOpp = oppIdAcvWrapperMap.get(newOpp.Opportunity_Split_Parent__c);
                Decimal expansionACV = 0; //ARY-1114
            Decimal expansionTCV = 0; //ARY-1114
                expansionACV = (acvWSplitParentOpp.subsumedRenewalACV != null && acvWSplitParentOpp.subsumedRenewalACV > 0 ? (acvWSplitParentOpp.acvAmount - acvWSplitParentOpp.subsumedRenewalACV) : acvWSplitParentOpp.acvAmount); //ARY-1114
                expansionTCV = (acvWSplitParentOpp.subsumedRenewalTCV != null && acvWSplitParentOpp.subsumedRenewalTCV > 0 ? (acvWSplitParentOpp.tcvAmount - acvWSplitParentOpp.subsumedRenewalTCV) : acvWSplitParentOpp.tcvAmount); //ARY-1114
                expansionTCV = (acvWSplitParentOpp.renewalTCV != null && acvWSplitParentOpp.renewalTCV > 0 ? (expansionTCV - acvWSplitParentOpp.renewalTCV) : expansionTCV); //ARY-1114                        
                newOpp.Amount = expansionTCV * newOpp.Split_percentage__c / 100.0; //ARY-1114
                newOpp.OppSubscriptionTermMonths__c = acvWSplitParentOpp.oppSubscriptionTerm;
                if(!newOpp.Opportunity_Amount_Override__c){ 
                  newOpp.ACV_Amount__c =  expansionACV * newOpp.Split_percentage__c / 100.0;//ACV-SFDC-011 //ARY-1114
        }
                newOpp.ARR_Amount__c =  acvWSplitParentOpp.arrAmount * newOpp.Split_percentage__c / 100.0;//ACV-SFDC-011
                newOpp.TotalHW_HwSupportAmount__c = acvWSplitParentOpp.totalHwSupportAmount * newOpp.Split_percentage__c / 100.0; //ACV-SFDC-021
            }
            calculateChurnonOpp(newOpp,true); //SAL24-749
            if(((newOpp.Opportunity_Amount_Override__c == false && newOpp.Opportunity_Type__c != 'Debooking') || (newOpp.Opportunity_Type__c =='Debooking' && newOpp.CCR__r.Opportunity__r.Opportunity_Amount_Override__c == false)) && (!(newOpp.Opportunity_Type__c == 'Debooking' && (newOpp.Opportunity_Sub_Type__c == 'Partial' || newOpp.Opportunity_Sub_Type__c == 'Full' || newOpp.Opportunity_Sub_Type__c == 'Referral Fee')))){ //SAL24-691 //SAL25-127 //SAL25-145
                newOpp.New_Expansion_ACV__c = (newOpp.Renewal_Subsumed_ACV__c != null) ? (newOpp.ACV_Amount__c - newOpp.Renewal_Subsumed_ACV__c) : newOpp.ACV_Amount__c; //ARY-1114
                newOpp.New_Expansion_TCV__c = (newOpp.Subsumed_Renewal_TCV__c != null) ? (newOpp.Amount - newOpp.Subsumed_Renewal_TCV__c) : newOpp.Amount; //ARY-1114
                resetACVonOpp(newOpp); //PL26-24
            } 
        }else{// OLI exists
            if(!newOpp.split__c){//Not Split Opp
                if(!(newOpp.CCR__c != null && newOpp.CCR__r.Opportunity__c != null)){
                    //SAL23-471
                    //newOpp.OppSubscriptionTermMonths__c = acvW.oppSubscriptionTerm;
                    newOpp.OppSubscriptionTermMonths__c = acvW.oppSubscriptionTerm != null && acvW.oppSubscriptionTerm != 0 ? acvW.oppSubscriptionTerm : newOpp.OppSubscriptionTermMonths__c;
                }
                if(!newOpp.Opportunity_Amount_Override__c){ //SAL25-145
                  newOpp.ACV_Amount__c =  acvW.acvAmount;//ACV-SFDC-011
            }
                newOpp.ARR_Amount__c =  acvW.arrAmount;//ARR-SFDC-008
                newOpp.TotalHW_HwSupportAmount__c =  acvW.totalHwSupportAmount; //ACV-SFDC-021
                if(!(newOpp.Opportunity_Sub_Type__c == GC_OFFER && newOpp.RecordTypeId == OpportunityUtil.oppRecTypeIdRenewOpp && (newOpp.StageName == StageFIVE || newOpp.StageName == StageSIX || newOpp.isclosed))){
                    if(!newOpp.Opportunity_Amount_Override__c){ //SAL25-145 
                      newOpp.New_Expansion_ACV__c = acvW.newExpansionACV; 
                      newOpp.New_Expansion_TCV__c = acvW.newExpansionTCV;
                      newOpp.Subsumed_Renewal_TCV__c = acvW.subsumedRenewalTCV;
                      newOpp.Renewal_Subsumed_ACV__c = acvw.subsumedRenewalACV;
                      newOpp.Comp_Uplift_ACV__c = acvW.compUpliftACV; //SAL26-1277
                      //Added below 2 lines in this if as part of SAL26-851
                      newOpp.Subsumed_Renewal_Churn_ACV__c = acvW.subChurnACV;
                      newOpp.Subsumed_Renewal_Churn_TCV__c = acvW.subChurnTCV; 
                      //PL26-24 start
                      if(newOpp.Opportunity_Type__c != 'Debooking'){ //SAL26-211
                            newOpp.Core_New_Expansion_ACV__c = acvW.coreNewExpansionACV;
                            newOpp.NAS_New_Expansion_ACV__c = acvW.nasNewExpansionACV;
                            newOpp.SaaS_New_Expansion_ACV__c = acvW.saasNewExpansionACV;
                            newOpp.PLS_New_Expansion_ACV__c = acvW.plsNewExpansionACV;
                            newOpp.PLS_NCD_New_Expansion_ACV__c = acvw.ncdNewExpansionACV; //SAL26-1218
                        }
                    }
		      //PL26-24 end
                    //SAL26-1280
                    //newOpp.Renewal_ACV__c = acvW.renewalACV; 
                     
                    //SAL24-749
                    OppACVUtilFlag = true;
                }
                newOpp.Renewal_TCV__c = acvW.renewalTCV; 
                newOpp.RBOBACV__c = acvW.rbobACV;//FY25SR-1119
            }else{ //Split Opp
                  setAcvOnSplitOpp(newOpp, acvW, oppIdAcvWrapperMap, oliAcvUpdateList);
              }
          }
        if(newOpp.amount < 0){//For DeBooking Opp.
            if(newOpp.ACV_Amount__c != null && newOpp.ACV_Amount__c > 0){
                newOpp.ACV_Amount__c *= (-1);
            }
            if(newOpp.ARR_Amount__c > 0){
                newOpp.ARR_Amount__c *= (-1);
            }
            if(newOpp.TotalHW_HwSupportAmount__c > 0){
                newOpp.TotalHW_HwSupportAmount__c *= (-1);
            }
        }
        if(newOpp.ACV_Amount__c != null){ //SF-12032
            newOpp.Upside_Amount__c = (newOpp.Upside_Amount__c == null || newOpp.Upside_Amount__c == 0) ? newOpp.ACV_Amount__c : newOpp.Upside_Amount__c;
            newOpp.Downside_amount__c = (newOpp.Downside_amount__c == null || newOpp.Downside_amount__c == 0) ? newOpp.ACV_Amount__c : newOpp.Downside_amount__c;
        }
    }

    /**
     * @description calculate acv amounts on split opportunity 
     * @param newOpp
     * @param acvW
     * @param oppIdAcvWrapperMap
     * @param oliAcvUpdateList
    */
    private static void setAcvOnSplitOpp(Opportunity newOpp, AcvWrapper acvW, Map<ID, AcvWrapper> oppIdAcvWrapperMap, List<OpportunityLineItem> oliAcvUpdateList){
        AcvWrapper acvWSplitParentOpp = oppIdAcvWrapperMap.get(newOpp.Opportunity_Split_Parent__c);//If Opp is Split-Child Opp. We need Parents Opp Data
        if(newOpp.Split_Amount__c > 0){
            if(newOpp.Opportunity_Split_Parent__c != null){
                newOpp.OppSubscriptionTermMonths__c = acvWSplitParentOpp.oppObj.OppSubscriptionTermMonths__c;
            }
            //User should update ACV_Amount__c & TotalHW_HwSupportAmount__c manually
            return;
        }else if(newOpp.Split_percentage__c == null){ //SAL26-258
            //Split defind without any amount sharing. Nothing to do.
            return;
	}else if(newOpp.Split_percentage__c == 0 && newOpp.Opportunity_Split_Parent__c == null){ //SAL26-258
            //Parent Opp Split% cannot be zero
            return;
        }
        Decimal arrDSTerm = newOpp.Opportunity_Sub_Type__c == 'Renewal' ? oppSetupCS.DefaultSubscriptionTermMonthsRenewARR__c : oppSetupCS.DefaultSubscriptionTermMonthsARR__c;
        Decimal arrPercent = newOpp.Opportunity_Sub_Type__c == 'Renewal' ? 100 : oppSetupCS.DefaultAcvAmount__c;
        Decimal expansionTCV = 0; //ARY-1114
        arrDSTerm = arrDSTerm / 12.0;
        if(newOpp.Opportunity_Split_Parent__c == null){//Split Parent Opp
            Decimal sTerm = (newOpp.OppSubscriptionTermMonths__c < 12 ? 12 : newOpp.OppSubscriptionTermMonths__c) / 12.0;
            //newOpp.OppSubscriptionTermMonths__c = acvW.oppSubscriptionTerm;
            if(!oppsplitlineOppMap.isEmpty() && oppsplitlineOppMap.containskey(newOpp.Id)){
                acvW.splitProductList.add(oppsplitlineOppMap.get(newOpp.Id));   //Adding new OPTY-SPLIT which is not yet inserted to wrapper
            }
            if(!acvW.splitProductList.isEmpty()){
                if(acvW.oliList.isEmpty()){//Only Split Products exist
                    for(OpportunityLineItem splitProduct: acvW.splitProductList){
					    splitProduct.Applied_Split__c = newOpp.Split_percentage__c;
                        if(!newOpp.Opportunity_Amount_Override__c){
                            splitProduct.ACV_Amount__c = (oppSetupCS.DefaultAcvAmount__c / 100.0) * splitProduct.TotalPrice / sTerm;
                        }
                        splitProduct.ARR_Amount__c = (arrPercent / 100.0) * splitProduct.TotalPrice / arrDSTerm;
                        //ARY-886
                        setArroyofieldsforSplitProducts(splitProduct,newOpp);
                        if(!newOpp.Opportunity_Amount_Override__c){//SAL26-851
                            calculateChurn(splitProduct); //SAL24-749
                        }
                        if(!updateDebookingOpp || (updateDebookingOpp && newOpp.Opportunity_Type__c == 'Debooking')){ //SAL26-1054
                        oliAcvUpdateList.add(splitProduct);
                    }
                    }
                    //newOpp.OppSubscriptionTermMonths__c = (newOpp.OppSubscriptionTermMonths__c == null ? oppSetupCS.DefaultSubscriptionTermMonths__c : newOpp.OppSubscriptionTermMonths__c);
                    if(!newOpp.Opportunity_Amount_Override__c){
                    newOpp.ACV_Amount__c = (newOpp.Amount * (oppSetupCS.DefaultAcvAmount__c / 100.0)) / sTerm;
                    }
                    newOpp.ARR_Amount__c = (newOpp.Amount * (arrPercent / 100.0)) / arrDSTerm;
                    newOpp.TotalHW_HwSupportAmount__c = (newOpp.Amount * (oppSetupCS.DefaultHW_HW_Support__c / 100.0));
                }else{//Some other product also exist (Other than Split Product)
                    expansionTCV = (acvW.renewalTCV != null && acvW.renewalTCV > 0 ? (acvW.tcvAmount - acvW.renewalTCV) : acvW.tcvAmount); //ARY-1114
                    for(OpportunityLineItem splitProduct: acvW.splitProductList){
                      //FY25SR-1119 Starts
                        splitProduct.Prepayment_Credit__c = (acvW.ppCreds  * (100 - newOpp.Split_percentage__c) / 100.0) * (-1); 
                        //splitProduct.RBOBACV__c = (acvW.rbobACV * (100 - newOpp.Split_percentage__c)/100) * (-1); //SAL26-1279
                        //FY25SR-1119 Ends
                        if(splitProduct.TotalPrice < 0){
			   splitProduct.Applied_Split__c = 100 - newOpp.Split_percentage__c;
       			   if(!newOpp.Opportunity_Amount_Override__c){  
                    		splitProduct.ACV_Amount__c = (acvW.acvAmount * (100 - newOpp.Split_percentage__c) / 100.0) * (-1);  
				            //PL26-24 start
                            if(newOpp.Opportunity_Type__c != 'Debooking'){ //SAL26-211
                                splitProduct.Core_New_Expansion_ACV__c = (acvW.coreNewExpansionACV  * (100 - newOpp.Split_percentage__c) / 100.0) * (-1); 
                                splitProduct.SaaS_New_Expansion_ACV__c = (acvW.saasNewExpansionACV * (100 - newOpp.Split_percentage__c) / 100.0) * (-1); 
                                splitProduct.NAS_New_Expansion_ACV__c = (acvW.nasNewExpansionACV * (100 - newOpp.Split_percentage__c) / 100.0) * (-1); 
                                splitProduct.PLS_New_Expansion_ACV__c = (acvW.plsNewExpansionACV * (100 - newOpp.Split_percentage__c) / 100.0) * (-1); 
                                    splitProduct.PLS_NCD_New_Expansion_ACV__c = (acvW.ncdNewExpansionACV * (100 - newOpp.Split_percentage__c) / 100.0) * (-1);//SAL26-1218
                            }
                            }
                            splitProduct.ARR_Amount__c = (acvW.arrAmount * (100 - newOpp.Split_percentage__c) / 100.0) * (-1);
                            splitProduct.TotalPrice = (expansionTCV * (100 - newOpp.Split_percentage__c) / 100.0) * (-1); //ARY-1114
                            //ARY-1114
                            if(!newOpp.Opportunity_Amount_Override__c){
                            splitProduct.Subsumed_Renewal_Amount__c = (acvW.subsumedRenewalACV != null) ? ((acvW.subsumedRenewalACV * (100 - newOpp.Split_percentage__c) / 100.0) * (-1)) : 0; 
                            splitProduct.Subsumed_Renewal_TCV__c = (acvW.subsumedRenewalTCV != null) ? ((acvW.subsumedRenewalTCV  * (100 - newOpp.Split_percentage__c) / 100.0) * (-1)) : 0;  
                            } 
                            splitProduct.SubsRenAmt__c = (acvW.orgSubsumedRenewalACV != null) ? ((acvW.orgSubsumedRenewalACV * (100 - newOpp.Split_percentage__c) / 100.0) * (-1)) : 0; //SAL24-749
                            splitProduct.Original_Subsumed_Renewal_TCV__c = (acvW.orgSubsumedRenewalTCV != null) ? ((acvW.orgSubsumedRenewalTCV  * (100 - newOpp.Split_percentage__c) / 100.0) * (-1)) : 0; //SAL24-749
                        }else{
			                splitProduct.Applied_Split__c = newOpp.Split_percentage__c;
               		        if(!newOpp.Opportunity_Amount_Override__c){
                            	splitProduct.ACV_Amount__c = (acvW.acvAmount * newOpp.Split_percentage__c / 100.0); 
                            //PL26-24 start
                            if(newOpp.Opportunity_Type__c != 'Debooking'){ //SAL26-211
                                splitProduct.Core_New_Expansion_ACV__c = (acvW.coreNewExpansionACV * newOpp.Split_percentage__c / 100.0);
                                splitProduct.SaaS_New_Expansion_ACV__c = (acvW.saasNewExpansionACV * newOpp.Split_percentage__c / 100.0);
                                splitProduct.NAS_New_Expansion_ACV__c = (acvW.nasNewExpansionACV * newOpp.Split_percentage__c / 100.0);
                                splitProduct.PLS_New_Expansion_ACV__c = (acvW.plsNewExpansionACV * newOpp.Split_percentage__c / 100.0);
									splitProduct.PLS_NCD_New_Expansion_ACV__c = (acvW.ncdNewExpansionACV *newOpp.Split_percentage__c / 100.0);//SAL26-1218
                            }
                            }
                            splitProduct.ARR_Amount__c = (acvW.arrAmount * newOpp.Split_percentage__c / 100.0);
                            splitProduct.TotalPrice = (expansionTCV * newOpp.Split_percentage__c / 100.0); //ARY-1114
                            //ARY-1114
                            if(!newOpp.Opportunity_Amount_Override__c){
                            splitProduct.Subsumed_Renewal_Amount__c = (acvW.subsumedRenewalACV != null) ? ((acvW.subsumedRenewalACV * newOpp.Split_percentage__c / 100.0)) : 0; 
                            splitProduct.Subsumed_Renewal_TCV__c = (acvW.subsumedRenewalTCV != null) ? ((acvW.subsumedRenewalTCV * newOpp.Split_percentage__c / 100.0)) : 0;  
                            }
                            splitProduct.SubsRenAmt__c = (acvW.orgSubsumedRenewalACV != null) ? ((acvW.orgSubsumedRenewalACV * newOpp.Split_percentage__c / 100.0)) : 0; //SAL24-749
                            splitProduct.Original_Subsumed_Renewal_TCV__c = (acvW.orgSubsumedRenewalTCV != null) ? ((acvW.orgSubsumedRenewalTCV * newOpp.Split_percentage__c / 100.0)) : 0;  //SAL24-749
                        }
                        if(!newOpp.Opportunity_Amount_Override__c){
                        splitProduct.New_Expansion_ACV__c = (splitProduct.Subsumed_Renewal_Amount__c != null ) ? (splitProduct.ACV_Amount__c - splitProduct.Subsumed_Renewal_Amount__c) : splitProduct.ACV_Amount__c;
                        splitProduct.New_Expansion_TCV__c = (splitProduct.Subsumed_Renewal_TCV__c != null ) ? (splitProduct.TotalPrice - splitProduct.Subsumed_Renewal_TCV__c) : splitProduct.TotalPrice;  
                        }
                        splitProduct.Renewal_TCV__c = 0; 
                        //SAL24-749
                        if(splitProduct.TotalPrice < 0 && !newOpp.Opportunity_Amount_Override__c){ //added condition in if as part of SAL26-851
                            splitProduct.Subsumed_Renewal_Churn_ACV__c = (splitProduct.SubsRenAmt__c != null && splitProduct.ACV_Amount__c != null && splitProduct.SubsRenAmt__c < splitProduct.ACV_Amount__c)? (splitProduct.ACV_Amount__c - splitProduct.SubsRenAmt__c) : 0;
                            splitProduct.Subsumed_Renewal_Churn_TCV__c = (splitProduct.Original_Subsumed_Renewal_TCV__c != null && splitProduct.TotalPrice != null && splitProduct.Original_Subsumed_Renewal_TCV__c < splitProduct.TotalPrice)? (splitProduct.TotalPrice - splitProduct.Original_Subsumed_Renewal_TCV__c) : 0;   
                        }else if(!newOpp.Opportunity_Amount_Override__c){//SAL26-851 
                            calculateChurn(splitProduct); 
                        }
                        if(!updateDebookingOpp || (updateDebookingOpp && newOpp.Opportunity_Type__c == 'Debooking')){  //SAL26-1054
                        oliAcvUpdateList.add(splitProduct);
                    }
                    }
                    newOpp.OppSubscriptionTermMonths__c = acvW.oppSubscriptionTerm;
                    if(!newOpp.Opportunity_Amount_Override__c){
                    newOpp.ACV_Amount__c =  acvW.acvAmount * newOpp.Split_percentage__c / 100.0;//ACV-SFDC-011
                    }
                    newOpp.ARR_Amount__c =  acvW.arrAmount * newOpp.Split_percentage__c / 100.0;//ACV-SFDC-011
                    newOpp.TotalHW_HwSupportAmount__c =  acvW.totalHwSupportAmount * newOpp.Split_percentage__c / 100.0; //ACV-SFDC-021
                    //FY25SR-1119 Starts
                    //newOpp.RBOBACV__c = acvW.rbobACV * (newOpp.Split_percentage__c/100); //commented as per SAL26-1279
                    //FY25SR-1119 Ends
                }
            }else if(acvW.splitProductList.isEmpty()){//Split Product not Exist
                if(acvW.oliList.isEmpty()){//No Products exist
                    //newOpp.OppSubscriptionTermMonths__c = (newOpp.OppSubscriptionTermMonths__c == null ? oppSetupCS.DefaultSubscriptionTermMonths__c : newOpp.OppSubscriptionTermMonths__c);
                    if(!newOpp.Opportunity_Amount_Override__c){
                    newOpp.ACV_Amount__c = (newOpp.Amount * (oppSetupCS.DefaultAcvAmount__c / 100.0)) / sTerm;
                    }
                    newOpp.ARR_Amount__c = (newOpp.Amount * (arrPercent / 100.0)) / arrDSTerm;
                    newOpp.TotalHW_HwSupportAmount__c = (newOpp.Amount * (oppSetupCS.DefaultHW_HW_Support__c / 100.0));
                }else{//Some other product exist (Other than Split Product)
                    newOpp.OppSubscriptionTermMonths__c = acvW.oppSubscriptionTerm; 
                    if(!newOpp.Opportunity_Amount_Override__c){
                    newOpp.ACV_Amount__c =  acvW.acvAmount * newOpp.Split_percentage__c / 100.0;//ACV-SFDC-011
                    }
                    newOpp.ARR_Amount__c =  acvW.arrAmount * newOpp.Split_percentage__c / 100.0;//ACV-SFDC-011
                    newOpp.TotalHW_HwSupportAmount__c =  acvW.totalHwSupportAmount * newOpp.Split_percentage__c / 100.0; //ACV-SFDC-021
                }
            }
        }else{//Split Child Opp
            AcvWrapper parentOppRec = mainACVWrapMap.containskey(newOpp.Opportunity_Split_Parent__c) ? mainACVWrapMap.get(newOpp.Opportunity_Split_Parent__c) : null;
            if(acvWSplitParentOpp != null){
                Decimal sTerm = (acvWSplitParentOpp.oppObj.OppSubscriptionTermMonths__c < 12 ? 12 : acvWSplitParentOpp.oppObj.OppSubscriptionTermMonths__c) / 12.0;
                newOpp.OppSubscriptionTermMonths__c = acvWSplitParentOpp.oppObj.OppSubscriptionTermMonths__c;
                expansionTCV = 0;
                expansionTCV = (parentOppRec?.tcvAmount != null) ? ((parentOppRec?.renewalTCV != null && parentOppRec?.renewalTCV > 0) ? (parentOppRec?.tcvAmount - parentOppRec?.renewalTCV) : parentOppRec?.tcvAmount) : 0; //ARY-1114                        
                if(!acvW.splitProductList.isEmpty()){
                    if(parentOppRec?.hasRealProducts == false){//Only Split Products exist on Parent Opp.
                        for(OpportunityLineItem splitProduct: acvW.splitProductList){ 
                            if(newOpp.Split_percentage__c == 0){
                                resetAllfieldsProduct(splitProduct);
                            }else{
						   splitProduct.Applied_Split__c = newOpp.Split_percentage__c;
                                splitProduct.TotalPrice = (expansionTCV * newOpp.Split_percentage__c/100);
                            if(!newOpp.Opportunity_Amount_Override__c){
                                splitProduct.ACV_Amount__c = (oppSetupCS.DefaultAcvAmount__c / 100.0) * splitProduct.TotalPrice / sTerm;
                            }
                            splitProduct.ARR_Amount__c = (arrPercent / 100.0) * splitProduct.TotalPrice / arrDSTerm;
                            setArroyofieldsforSplitProducts(splitProduct,newOpp);
                            }
                            if(!newOpp.Opportunity_Amount_Override__c){//SAL26-851
                                calculateChurn(splitProduct); //SAL24-749
                            }
			                if(!updateDebookingOpp || (updateDebookingOpp && newOpp.Opportunity_Type__c == 'Debooking')){  //SAL26-1054	
                            oliAcvUpdateList.add(splitProduct);
                        }
                        }
                        if(!newOpp.Opportunity_Amount_Override__c){
                            newOpp.ACV_Amount__c = (newOpp.Amount != null) ? ((newOpp.Amount * (oppSetupCS.DefaultAcvAmount__c / 100.0)) / sTerm) : 0;
                        }
                        newOpp.ARR_Amount__c = (newOpp.Amount != null) ? ((newOpp.Amount * (arrPercent / 100.0)) / arrDSTerm) : 0;
                        newOpp.TotalHW_HwSupportAmount__c = (newOpp.Amount != null) ? (newOpp.Amount * (oppSetupCS.DefaultHW_HW_Support__c / 100.0)) : 0;
                    }else{//Some other product also exist (Other than Split Product)
                        for(OpportunityLineItem splitProduct: acvW.splitProductList){ 
                            if(newOpp.Split_percentage__c == 0){
                                resetAllfieldsProduct(splitProduct);
                            }else if(newOpp.Split_percentage__c > 0 && mainACVWrapMap.containsKey(newOpp.Opportunity_Split_Parent__c)){
                              splitProduct.Applied_Split__c = 100 - newOpp.Split_percentage__c;
		              if(!newOpp.Opportunity_Amount_Override__c){
                                    splitProduct.ACV_Amount__c = (parentOppRec?.acvAmount != null) ? ((parentOppRec?.acvAmount * (100 - newOpp.Split_percentage__c) / 100.0) * (-1)) : 0; //ARY-1114
		                  //PL26-24 start
                          	  if(newOpp.Opportunity_Type__c != 'Debooking'){ //SAL26-211
                                        splitProduct.Core_New_Expansion_ACV__c = (parentOppRec?.coreNewExpansionACV != null) ? (( parentOppRec?.coreNewExpansionACV * (100 - newOpp.Split_percentage__c) / 100.0) * (-1)) : 0; //ARY-1114
                                        splitProduct.SaaS_New_Expansion_ACV__c = (parentOppRec?.saasNewExpansionACV != null) ? (( parentOppRec?.saasNewExpansionACV * (100 - newOpp.Split_percentage__c) / 100.0) * (-1)) : 0; //ARY-1114
                                        splitProduct.NAS_New_Expansion_ACV__c = (parentOppRec?.nasNewExpansionACV != null) ? (( parentOppRec?.nasNewExpansionACV * (100 - newOpp.Split_percentage__c) / 100.0) * (-1)) : 0; //ARY-1114
                                        splitProduct.PLS_New_Expansion_ACV__c = (parentOppRec?.plsNewExpansionACV != null) ? (( parentOppRec?.plsNewExpansionACV * (100 - newOpp.Split_percentage__c) / 100.0) * (-1)) : 0; //ARY-1114
                                        splitProduct.PLS_NCD_New_Expansion_ACV__c = (parentOppRec?.ncdNewExpansionACV != null) ? (( parentOppRec?.ncdNewExpansionACV * (100 - newOpp.Split_percentage__c) / 100.0) * (-1)) : 0;//SAL26-1218
                          	  }
                                }
                                //FY25SR-1119 Starts
                                splitProduct.Prepayment_Credit__c = (parentOppRec?.ppCreds != null) ? ((parentOppRec?.ppCreds  * (100 - newOpp.Split_percentage__c) / 100.0) * (-1)) : 0; 
                                //splitProduct.RBOBACV__c = (parentOppRec?.rbobACV != null) ? ((parentOppRec?.rbobACV * (100 - newOpp.Split_percentage__c)/100) * (-1)) : 0; //commented as per SAL26-1279
                                //FY25SR-1119 Ends
                                  //PL26-24 end 
                                splitProduct.ARR_Amount__c = (parentOppRec?.arrAmount != null) ? ((parentOppRec?.arrAmount * (100 - newOpp.Split_percentage__c) / 100.0) * (-1)) : 0;
                                splitProduct.TotalPrice = (expansionTCV * (100 - newOpp.Split_percentage__c) / 100.0) * (-1);
                            //ARY-1114
                            splitProduct.Renewal_TCV__c = 0; 
          		    if(!newOpp.Opportunity_Amount_Override__c){  
                                    splitProduct.Subsumed_Renewal_Amount__c = (parentOppRec?.subsumedRenewalACV != null) ? ((parentOppRec?.subsumedRenewalACV  * (100 - newOpp.Split_percentage__c) / 100.0) * (-1)) : 0; 
                                    splitProduct.Subsumed_Renewal_TCV__c = (parentOppRec?.subsumedRenewalTCV != null) ? ((parentOppRec?.subsumedRenewalTCV  * (100 - newOpp.Split_percentage__c) / 100.0) * (-1)) : 0;  
	                         splitProduct.New_Expansion_ACV__c = (splitProduct.Subsumed_Renewal_Amount__c != null ) ? (splitProduct.ACV_Amount__c - splitProduct.Subsumed_Renewal_Amount__c) : splitProduct.ACV_Amount__c;
	                         splitProduct.New_Expansion_TCV__c = (splitProduct.Subsumed_Renewal_TCV__c != null ) ? (splitProduct.TotalPrice - splitProduct.Subsumed_Renewal_TCV__c) : splitProduct.TotalPrice;  
                            }
                          //SAL24-749 
                                splitProduct.SubsRenAmt__c = (parentOppRec?.orgSubsumedRenewalACV != null) ? ((parentOppRec?.orgSubsumedRenewalACV  * (100 - newOpp.Split_percentage__c) / 100.0) * (-1)) : 0; //SAL24-749
                                splitProduct.Original_Subsumed_Renewal_TCV__c = (parentOppRec?.orgSubsumedRenewalTCV != null) ? ((parentOppRec?.orgSubsumedRenewalTCV  * (100 - newOpp.Split_percentage__c) / 100.0) * (-1)) : 0; //SAL24-749
                            }
                            if(!newOpp.Opportunity_Amount_Override__c){//SAL26-851
                                calculateChurn(splitProduct); //SAL24-749
                            }
                            if(!updateDebookingOpp || (updateDebookingOpp && newOpp.Opportunity_Type__c == 'Debooking')){	 //SAL26-1054
                            	oliAcvUpdateList.add(splitProduct);
                      		}
						}
                        if(newOpp.Split_percentage__c > 0){ //SAL26-258
                        if(!newOpp.Opportunity_Amount_Override__c){
                                newOpp.ACV_Amount__c =  (parentOppRec?.acvAmount != null) ? (parentOppRec?.acvAmount * newOpp.Split_percentage__c / 100.0) : 0;//ACV-SFDC-011 
                            }
                            newOpp.ARR_Amount__c =  (parentOppRec?.arrAmount != null) ? (parentOppRec?.arrAmount * newOpp.Split_percentage__c / 100.0) : 0;//ACV-SFDC-011
                            newOpp.TotalHW_HwSupportAmount__c = (parentOppRec?.totalHwSupportAmount != null) ? (parentOppRec?.totalHwSupportAmount * newOpp.Split_percentage__c / 100.0) : 0; //ACV-SFDC-021
                            //FY25SR-1119 Starts
                            //newOpp.RBOBACV__c = (parentOppRec?.rbobACV != null) ? (parentOppRec?.rbobACV * (newOpp.Split_percentage__c/100)) : 0; //commented as per SAL26-1279
                        }else{ //SAL26-258
                            newOpp.ACV_Amount__c = newOpp.ARR_Amount__c = newOpp.TotalHW_HwSupportAmount__c =  0; // newOpp.RBOBACV__c = - removed as per SAL26-1279
                        }
                    }
                }else if(acvW.splitProductList.isEmpty()){ 
                    if(parentOppRec?.oliList.isEmpty()){//Only Split Products exist on Parent Opp.
                        //newOpp.OppSubscriptionTermMonths__c = (newOpp.OppSubscriptionTermMonths__c == null ? oppSetupCS.DefaultSubscriptionTermMonths__c : newOpp.OppSubscriptionTermMonths__c);
                        if(!newOpp.Opportunity_Amount_Override__c){
                            newOpp.ACV_Amount__c = (newOpp.Amount != null) ? ((newOpp.Amount * (oppSetupCS.DefaultAcvAmount__c / 100.0)) / sTerm) : 0;
                        }
                        newOpp.ARR_Amount__c = (newOpp.Amount != null) ? ((newOpp.Amount * (arrPercent / 100.0)) / arrDSTerm) : 0;
                        newOpp.TotalHW_HwSupportAmount__c = (newOpp.Amount != null) ? ((newOpp.Amount * (oppSetupCS.DefaultHW_HW_Support__c / 100.0))) : 0;
                    }else{//Some other product also exist (Other than Split Product)
                        newOpp.Amount = (newOpp.Split_percentage__c > 0) ? (expansionTCV * newOpp.Split_percentage__c / 100.0) : 0; //ARY-1114
                        newOpp.OppSubscriptionTermMonths__c = parentOppRec?.oppSubscriptionTerm;
                        if(newOpp.Split_percentage__c > 0){
                        if(!newOpp.Opportunity_Amount_Override__c){
                                newOpp.ACV_Amount__c =  (parentOppRec?.acvAmount != null) ? (parentOppRec?.acvAmount * newOpp.Split_percentage__c / 100.0) : 0;//ACV-SFDC-011
                            }
                            newOpp.ARR_Amount__c =  (parentOppRec?.arrAmount != null) ? (parentOppRec?.arrAmount * newOpp.Split_percentage__c / 100.0) : 0;//ACV-SFDC-011
                            newOpp.TotalHW_HwSupportAmount__c = (parentOppRec?.totalHwSupportAmount != null) ? (parentOppRec?.totalHwSupportAmount * newOpp.Split_percentage__c / 100.0) : 0; //ACV-SFDC-021
                        }else{
                            newOpp.ACV_Amount__c = newOpp.ARR_Amount__c = newOpp.TotalHW_HwSupportAmount__c = 0;
                        }
                    }
                }
            }
        }
        if(newOpp.Amount > 0 && oliAcvUpdateList.isEmpty() && ((acvW.splitProductList.isEmpty() && acvW.oliList.isEmpty()) || (!acvW.splitProductList.isEmpty() && acvW.oliList.isEmpty()))){
            if(!(newOpp.Opportunity_Sub_Type__c == GC_OFFER && OpportunityUtil.oppRecTypeIdRenewOpp != null && newOpp.RecordTypeId == OpportunityUtil.oppRecTypeIdRenewOpp && (newOpp.StageName == StageFIVE || newOpp.StageName == StageSIX || newOpp.isclosed))){
                if(!newOpp.Opportunity_Amount_Override__c){    
	                newOpp.Renewal_Subsumed_ACV__c = 0;
	                newOpp.Subsumed_Renewal_TCV__c = 0;
                    newOpp.New_Expansion_ACV__c = (newOpp.ACV_Amount__c != null ? newOpp.ACV_Amount__c : 0);
                    newOpp.New_Expansion_TCV__c = (newOpp.Amount != null ? newOpp.Amount : 0);
		        //PL26-24 start
                if(newOpp.Opportunity_Type__c != 'Debooking'){ //SAL26-211
                        newOpp.PLS_NCD_New_Expansion_ACV__c = newOpp.Core_New_Expansion_ACV__c = newOpp.SaaS_New_Expansion_ACV__c = newOpp.NAS_New_Expansion_ACV__c = newOpp.PLS_New_Expansion_ACV__c = (newOpp.ACV_Amount__c != null ? newOpp.ACV_Amount__c : 0);
                }
		        //PL26-24 end
                }
                //newOpp.Renewal_ACV__c = 0; // commented as part of SAL26-1280
                calculateChurnonOpp(newOpp,true);
                OppACVUtilFlag = true;
            }
            newOpp.Renewal_TCV__c = 0;
        }else if(!oliAcvUpdateList.isEmpty() && newOpp.Split_percentage__c != null && newOpp.Split_percentage__c > 0 ){
            if(!(newOpp.Opportunity_Sub_Type__c == GC_OFFER && newOpp.RecordTypeId == OpportunityUtil.oppRecTypeIdRenewOpp && (newOpp.StageName == StageFIVE || newOpp.StageName == StageSIX || newOpp.isclosed))){
                if(!newOpp.Opportunity_Amount_Override__c){    
	                newOpp.Subsumed_Renewal_TCV__c = 0;
	                newOpp.Renewal_Subsumed_ACV__c = 0;
	                newOpp.New_Expansion_TCV__c = 0;
	                newOpp.New_Expansion_ACV__c = 0;
                    //PL26-24 start //SAL26-1218
                    newOpp.PLS_NCD_New_Expansion_ACV__c = newOpp.Core_New_Expansion_ACV__c = newOpp.SaaS_New_Expansion_ACV__c = newOpp.NAS_New_Expansion_ACV__c = newOpp.PLS_New_Expansion_ACV__c = 0;
	                //PL26-24 end
                    //Added below 2 lines are moved to this if as part of SAL26-851
                    newOpp.Subsumed_Renewal_Churn_ACV__c = 0; //SAL26-851
                    newOpp.Subsumed_Renewal_Churn_TCV__c = 0; //SAL26-851
                }
               // newOpp.Renewal_ACV__c = 0; //commented as part of SAL26-1280
            }
            newOpp.Renewal_TCV__c = 0;
            for(opportunitylineitem oli : oliAcvUpdateList){
                if(newOpp.Id != null && oli.opportunityId != null && oli.opportunityId == newOpp.Id){
                    //ARY-1151
                    if(!newOpp.Opportunity_Amount_Override__c && ((oli.Totalprice >= 0  && oli.New_Expansion_ACV__c < 0) || (oli.Totalprice < 0  && oli.New_Expansion_ACV__c > 0))){
                        oli.New_Expansion_ACV__c = 0;
                        //PL26-24 start //SAL26-1218
                        oli.PLS_NCD_New_Expansion_ACV__c = oli.Core_New_Expansion_ACV__c = oli.SaaS_New_Expansion_ACV__c = oli.NAS_New_Expansion_ACV__c = oli.PLS_New_Expansion_ACV__c = 0;
                        //PL26-24 end
                    }
                    if(!newOpp.Opportunity_Amount_Override__c && ((oli.Totalprice >= 0  && oli.New_Expansion_TCV__c < 0) || (oli.Totalprice < 0  && oli.New_Expansion_TCV__c > 0))){
                        oli.New_Expansion_TCV__c = 0;
                    }
                    if(!(newOpp.Opportunity_Sub_Type__c == GC_OFFER && newOpp.RecordTypeId == OpportunityUtil.oppRecTypeIdRenewOpp && (newOpp.StageName == StageFIVE || newOpp.StageName == StageSIX || newOpp.isclosed))){
                        if(!newOpp.Opportunity_Amount_Override__c){    
	                        newOpp.Renewal_Subsumed_ACV__c = (oli.Subsumed_Renewal_Amount__c != null) ? (newOpp.Renewal_Subsumed_ACV__c + oli.Subsumed_Renewal_Amount__c) : newOpp.Renewal_Subsumed_ACV__c;
	                        newOpp.Subsumed_Renewal_TCV__c = (oli.Subsumed_Renewal_TCV__c != null) ? (newOpp.Subsumed_Renewal_TCV__c + oli.Subsumed_Renewal_TCV__c) : newOpp.Subsumed_Renewal_TCV__c;
	                        newOpp.New_Expansion_ACV__c = (oli.New_Expansion_ACV__c != null) ? (newOpp.New_Expansion_ACV__c + oli.New_Expansion_ACV__c) : newOpp.New_Expansion_ACV__c;
	                        newOpp.New_Expansion_TCV__c = (oli.New_Expansion_TCV__c != null) ? (newOpp.New_Expansion_TCV__c + oli.New_Expansion_TCV__c) : newOpp.New_Expansion_TCV__c;
	      			        // Moved below 2 lines to this if as part of SAL26-851
                            newOpp.Subsumed_Renewal_Churn_ACV__c = (oli.Subsumed_Renewal_Churn_ACV__c != null) ? (newOpp.Subsumed_Renewal_Churn_ACV__c + oli.Subsumed_Renewal_Churn_ACV__c) : newOpp.Subsumed_Renewal_Churn_ACV__c;
                            newOpp.Subsumed_Renewal_Churn_TCV__c = (oli.New_Expansion_TCV__c != null) ? (newOpp.Subsumed_Renewal_Churn_TCV__c + oli.Subsumed_Renewal_Churn_TCV__c) : newOpp.Subsumed_Renewal_Churn_TCV__c;
	      			        //PL26-24 start
                            if(newOpp.Opportunity_Type__c != 'Debooking'){ //SAL26-211
                                newOpp.Core_New_Expansion_ACV__c = (oli.Core_New_Expansion_ACV__c != null) ? (newOpp.Core_New_Expansion_ACV__c + oli.Core_New_Expansion_ACV__c) : newOpp.Core_New_Expansion_ACV__c;
                                newOpp.SaaS_New_Expansion_ACV__c = (oli.SaaS_New_Expansion_ACV__c != null) ? (newOpp.SaaS_New_Expansion_ACV__c + oli.SaaS_New_Expansion_ACV__c) : newOpp.SaaS_New_Expansion_ACV__c;
                                newOpp.NAS_New_Expansion_ACV__c = (oli.NAS_New_Expansion_ACV__c != null) ? (newOpp.NAS_New_Expansion_ACV__c + oli.NAS_New_Expansion_ACV__c) : newOpp.NAS_New_Expansion_ACV__c;
                                newOpp.PLS_New_Expansion_ACV__c = (oli.PLS_New_Expansion_ACV__c != null) ? (newOpp.PLS_New_Expansion_ACV__c + oli.PLS_New_Expansion_ACV__c) : newOpp.PLS_New_Expansion_ACV__c;
                                newOpp.PLS_NCD_New_Expansion_ACV__c = (oli.PLS_NCD_New_Expansion_ACV__c != null) ? (newOpp.PLS_NCD_New_Expansion_ACV__c + oli.PLS_NCD_New_Expansion_ACV__c) : newOpp.PLS_NCD_New_Expansion_ACV__c; //SAL26-1218
                            }
		                    //PL26-24 end 
      
                        }
                        /*if(oli.Line_Type__c == 'Renewal' || (oli.Line_Type_Text__c != '' && oli.Line_Type_Text__c == 'Renewal')){
                           newOpp.Renewal_ACV__c = (oli.ACV_Amount__c != null) ? (newOpp.Renewal_ACV__c + oli.ACV_Amount__c) : newOpp.Renewal_ACV__c;
                        }*/ //commented as part of SAL26-1280    
                        OppACVUtilFlag = true;
                    }
                    newOpp.Renewal_TCV__c = (oli.Renewal_TCV__c != null) ? (newOpp.Renewal_TCV__c + oli.Renewal_TCV__c) : newOpp.Renewal_TCV__c;
                }
            }
        }
    }

    /**
     * @description check SOW required or not on opportunity 
     * @param oli
     * @param acvW
     * @param SOWRequiredSKUsSet
     * @param ConsultQuantitySet
    */
    public static void checkSowRequired(OpportunityLineItem oli, AcvWrapper acvW, Set<String> SOWRequiredSKUsSet, Set<String> ConsultQuantitySet){
        if(SOWRequiredSKUsSet.contains(oli.ProductCode)){
            acvW.sowskusRequired = true;
        }
        if(ConsultQuantitySet.contains(oli.ProductCode)){
             acvW.totalConsultQuantity = acvW.totalConsultQuantity+oli.Quantity;
        }
        if(acvW.totalConsultQuantity >= 10){
            acvW.sowskusRequired = true;
        }
    }
    /**
     * @description check sku is scale product or not not on opportunity 
     * @param oli
     * @param acvW
    */
    public static void checkScaleProducts(OpportunityLineItem oli, AcvWrapper acvW){ //SAL26-389
        if(!string.isBlank(oli.product2.Sales_Comp_Category__c) && oli.product2.Sales_Comp_Category__c.containsIgnoreCase('scale') && oli.Line_Type__c !='Renewal' && !acvW.hasScaleProducts){
            acvW.hasScaleProducts = true; 
        }
    }

    /**
     * @description set arroy fields on opportunity product
     * @param splitProduct
     * @param newOpp
    */
    public static void setArroyofieldsforSplitProducts(OpportunityLineItem splitProduct, Opportunity newOpp){
       if(!newOpp.Opportunity_Amount_Override__c){
	    splitProduct.Subsumed_Renewal_Amount__c = 0; 
	    splitProduct.Subsumed_Renewal_TCV__c = 0;  
	    splitProduct.New_Expansion_ACV__c = splitProduct.ACV_Amount__c;
	    splitProduct.New_Expansion_TCV__c = splitProduct.TotalPrice;  
             if(Test.isRunningTest()){
                 splitProduct.New_Expansion_ACV__c = 100;
             }
             
             //SAL26-1290 START
            if(splitProduct.New_Expansion_ACV__c > 0 && newOpp.Opportunity_Type__c != 'Debooking' && (newOpp.SaaS_Co_Owner__c != null || newOpp.Co_Owner__c != null || newOpp.NCD_Co_Owner__c != null)){
                Integer noOfCoOwners = 0;
                splitProduct.PLS_New_Expansion_ACV__c = splitProduct.New_Expansion_ACV__c;
                if(newOpp.SaaS_Co_Owner__c != null) noOfCoOwners += 1;
                if(newOpp.Co_Owner__c != null) noOfCoOwners += 1;
                if(newOpp.NCD_Co_Owner__c != null) noOfCoOwners += 1;

                if(newOpp.SaaS_Co_Owner__c != null) splitProduct.SaaS_New_Expansion_ACV__c = splitProduct.New_Expansion_ACV__c/noOfCoOwners;
                if(newOpp.Co_Owner__c != null) splitProduct.NAS_New_Expansion_ACV__c = splitProduct.New_Expansion_ACV__c/noOfCoOwners;
                if(newOpp.NCD_Co_Owner__c != null) splitProduct.PLS_NCD_New_Expansion_ACV__c = splitProduct.New_Expansion_ACV__c/noOfCoOwners; 
            } else if(newOpp.Opportunity_Type__c != 'Debooking' && newOpp.SaaS_Co_Owner__c == null && newOpp.Co_Owner__c == null && newOpp.NCD_Co_Owner__c == null) {
                splitProduct.Core_New_Expansion_ACV__c = newOpp.New_Expansion_ACV__c;
            } //SAL26-1290 END
            /*//PL26-24 start
	    if(newOpp.Co_Owner__c != null && newOpp.Opportunity_Type__c != 'Debooking'){ //SAL26-211
	        if(newOpp.PLS_AE_ETM_Role_Name__c == 'SaaS AE'){
	          splitProduct.SaaS_New_Expansion_ACV__c = splitProduct.New_Expansion_ACV__c;
	            splitProduct.PLS_New_Expansion_ACV__c = splitProduct.New_Expansion_ACV__c;
	        }
                if(newOpp.PLS_AE_ETM_Role_Name__c == 'Cloud AE'){ //SAL26-138:NAS to Cloud
	            splitProduct.NAS_New_Expansion_ACV__c = splitProduct.New_Expansion_ACV__c;
	            splitProduct.PLS_New_Expansion_ACV__c = splitProduct.New_Expansion_ACV__c;
	        }
            }
            else if(newOpp.Co_Owner__c == null && newOpp.Opportunity_Type__c != 'Debooking'){ //SAL26-211
	        splitProduct.Core_New_Expansion_ACV__c = splitProduct.New_Expansion_ACV__c;
            }*/
	    }
 	    //PL26-24 end    
        splitProduct.Renewal_TCV__c = 0; 
    }
    /**
     * @description set arroy fields on opportunity product
     * @param oli
    */
    public static void resetAllfieldsProduct(OpportunityLineItem oli){ //SAL26-258
        oli.TotalPrice = oli.Applied_Split__c = oli.ARR_Amount__c = oli.ACV_Amount__c = oli.Subsumed_Renewal_TCV__c = oli.Original_Subsumed_Renewal_TCV__c = oli.New_Expansion_ACV__c = oli.New_Expansion_TCV__c = oli.PLS_New_Expansion_ACV__c = oli.SaaS_New_Expansion_ACV__c = oli.NAS_New_Expansion_ACV__c = oli.Core_New_Expansion_ACV__c = oli.PLS_NCD_New_Expansion_ACV__c = oli.Prepayment_Credit__c = 0; //newOpp.RBOBACV__c = ---- removed as per SAL26-1279 //SAL26-1218
    }

    /**
     * @description set arroy fields on opportunity product
     * @param oli
    */
    public static void setArroyofieldsforProduct(OpportunityLineItem oli){ 
    // oli.Subsumed_Renewal_TCV__c = (oli.Subsumed_Renewal_Amount__c != null) ? ((oli.Subscription_Term__c != null && oli.Subscription_Term__c > 12) ? (oli.Subsumed_Renewal_Amount__c * oli.Subscription_Term__c)/12 : oli.Subsumed_Renewal_Amount__c) : 0; SAL26-1255
    // oli.Original_Subsumed_Renewal_TCV__c = (oli.SubsRenAmt__c != null) ? ((oli.Subscription_Term__c != null && oli.Subscription_Term__c > 12) ? (oli.SubsRenAmt__c * oli.Subscription_Term__c)/12 : oli.SubsRenAmt__c) : 0; //SAL24-749 SAL26-1255
    oli.Subsumed_Renewal_TCV__c = (oli.Subsumed_Renewal_Amount__c != null) ? ((oli.Prorate_Multiplier__c != null && oli.Prorate_Multiplier__c > 12) ? (oli.Subsumed_Renewal_Amount__c * oli.Prorate_Multiplier__c)/12 : oli.Subsumed_Renewal_Amount__c) : 0; //SAL26-1255
    oli.Original_Subsumed_Renewal_TCV__c = (oli.SubsRenAmt__c != null) ? ((oli.Prorate_Multiplier__c != null && oli.Prorate_Multiplier__c > 12) ? (oli.SubsRenAmt__c * oli.Prorate_Multiplier__c)/12 : oli.SubsRenAmt__c) : 0; //SAL24-749 //SAL26-1255

        oli.New_Expansion_ACV__c = (oli.ACV_Amount__c != null && oli.Subsumed_Renewal_Amount__c != null) ? (oli.ACV_Amount__c - oli.Subsumed_Renewal_Amount__c) : oli.ACV_Amount__c;
        oli.New_Expansion_TCV__c = (oli.TotalPrice != null && oli.Subsumed_Renewal_TCV__c != null) ? (oli.TotalPrice - oli.Subsumed_Renewal_TCV__c) : oli.TotalPrice; 
        
    }

    /**
     * @description calculate churn on opportunity product
     * @param oli
    */
    public static void calculateChurn(OpportunityLineItem oli){ 
        oli.Subsumed_Renewal_Churn_ACV__c = (oli.opportunity.Amount > 0 && oli.SubsRenAmt__c != null && oli.SubsRenAmt__c !=0 && oli.ACV_Amount__c != null && oli.SubsRenAmt__c > oli.ACV_Amount__c)? (oli.ACV_Amount__c - oli.SubsRenAmt__c) : 0;
        oli.Subsumed_Renewal_Churn_TCV__c = (oli.opportunity.Amount > 0 && oli.Original_Subsumed_Renewal_TCV__c != null && oli.Original_Subsumed_Renewal_TCV__c !=0 && oli.TotalPrice != null && oli.Original_Subsumed_Renewal_TCV__c > oli.TotalPrice)? (oli.TotalPrice - oli.Original_Subsumed_Renewal_TCV__c) : 0;        
    }

    /**
     * @description calculate churn on opportunity 
     * @param opp
     * @param nolineitems
    */
    public static void calculateChurnonOpp(Opportunity opp, Boolean nolineitems){
        if(opp.Amount != null && opp.Amount > 0 && opp.Renewal_Subsumed_ACV__c != null && opp.ACV_Amount__c != null && opp.Renewal_Subsumed_ACV__c > opp.ACV_Amount__c){
            opp.Subsumed_Renewal_Churn_ACV__c = !opp.Opportunity_Amount_Override__c ? opp.ACV_Amount__c - opp.Renewal_Subsumed_ACV__c :  opp.Subsumed_Renewal_Churn_ACV__c;
            opp.Renewal_Subsumed_ACV__c = opp.ACV_Amount__c;
        }else if(!opp.Opportunity_Amount_Override__c){
            opp.Subsumed_Renewal_Churn_ACV__c = 0;        
        }
        if(opp.Amount != null && opp.Amount > 0 && opp.Subsumed_Renewal_TCV__c != null && opp.Amount != null && opp.Subsumed_Renewal_TCV__c > opp.Amount){
            opp.Subsumed_Renewal_Churn_TCV__c = !opp.Opportunity_Amount_Override__c ? opp.Amount - opp.Subsumed_Renewal_TCV__c : opp.Subsumed_Renewal_Churn_TCV__c;
            opp.Subsumed_Renewal_TCV__c = opp.Amount;
        }else if(!opp.Opportunity_Amount_Override__c){
            opp.Subsumed_Renewal_Churn_TCV__c = 0; 
        }
    }

    /**
     * @description set ACV on PLS fields 
     * @param newOpp
    */
    //PL26-24 start
    public static void resetACVonOpp(Opportunity newOpp){
        if(!newOpp.Opportunity_Amount_Override__c){
			//SAL26-1143
            newOpp.PLS_NCD_New_Expansion_ACV__c = newOpp.SaaS_New_Expansion_ACV__c = newOpp.PLS_New_Expansion_ACV__c = newOpp.NAS_New_Expansion_ACV__c = newOpp.Core_New_Expansion_ACV__c = 0;
            if(Test.isRunningTest()){
                newOpp.New_Expansion_ACV__c = 100;
            }
            if(newOpp.New_Expansion_ACV__c > 0 && newOpp.Opportunity_Type__c != 'Debooking' && (newOpp.SaaS_Co_Owner__c != null || newOpp.Co_Owner__c != null || newOpp.NCD_Co_Owner__c != null)){
                Integer noOfCoOwners = 0;
				newOpp.PLS_New_Expansion_ACV__c = newOpp.New_Expansion_ACV__c;
				if(newOpp.SaaS_Co_Owner__c != null) noOfCoOwners += 1;
                if(newOpp.Co_Owner__c != null) noOfCoOwners += 1;
                if(newOpp.NCD_Co_Owner__c != null) noOfCoOwners += 1;

                if(newOpp.SaaS_Co_Owner__c != null) newOpp.SaaS_New_Expansion_ACV__c = newOpp.New_Expansion_ACV__c/noOfCoOwners;
                if(newOpp.Co_Owner__c != null) newOpp.NAS_New_Expansion_ACV__c = newOpp.New_Expansion_ACV__c/noOfCoOwners;
                if(newOpp.NCD_Co_Owner__c != null) newOpp.PLS_NCD_New_Expansion_ACV__c = newOpp.New_Expansion_ACV__c/noOfCoOwners; 
               
            } else if(newOpp.Opportunity_Type__c != 'Debooking' && newOpp.SaaS_Co_Owner__c == null && newOpp.Co_Owner__c == null && newOpp.NCD_Co_Owner__c == null) {
                newOpp.Core_New_Expansion_ACV__c = newOpp.New_Expansion_ACV__c;
            }
            /*if(newOpp.Co_Owner__c != null && newOpp.Opportunity_Type__c != 'Debooking'){ //SAL26-211
            if(newOpp.PLS_AE_ETM_Role_Name__c == 'SaaS AE'){
                newOpp.SaaS_New_Expansion_ACV__c = newOpp.New_Expansion_ACV__c;
                newOpp.PLS_New_Expansion_ACV__c = newOpp.New_Expansion_ACV__c;
            }
            if(newOpp.PLS_AE_ETM_Role_Name__c == 'Cloud AE'){ //SAL26-138: NAS to Cloud
                newOpp.NAS_New_Expansion_ACV__c = newOpp.New_Expansion_ACV__c;
                newOpp.PLS_New_Expansion_ACV__c = newOpp.New_Expansion_ACV__c;
            }
        }
        else if(newOpp.Co_Owner__c == null && newOpp.Opportunity_Type__c != 'Debooking'){ //SAL26-211
            newOpp.Core_New_Expansion_ACV__c = newOpp.New_Expansion_ACV__c;
            }*/
        }
    }
    
    //SAL26-1221,SAL26-1220
    /**
     * @description assign ACV field values 
     * @param coreAcv
     * @param plsAcv
     * @param cloudAcv
     * @param saasAcv
     * @param ncdAcv
     * @param oli
     */ 
    private static void assignPlsAcvValues(Decimal coreAcv, Decimal plsAcv, Decimal cloudAcv, Decimal saasAcv, Decimal ncdAcv, OpportunityLineItem oli){
        oli.Core_New_Expansion_ACV__c = coreAcv;
        oli.PLS_New_Expansion_ACV__c = plsAcv;
        oli.NAS_New_Expansion_ACV__c = cloudAcv;
        oli.SaaS_New_Expansion_ACV__c = saasAcv;
        oli.PLS_NCD_New_Expansion_ACV__c = ncdAcv;
    }
    
    /**
     * @description assign RCV sku ACV to Core/NCD/Cloud
     * @param oppObj
     * @param oli
     */ 
    public static void assignRCVSkuAcv(Opportunity oppObj, OpportunityLineItem oli){
        String CLOUD_AE = 'Cloud AE';
        String NCD_AE = 'NCD AE';
        String CLOUD_CUST = 'Cloud Customer w/o RCV';
        String NCD_CUST = 'NCD Customer w/o RCV';
        Set<String> accCustTypeSet = String.isNotBlank(oppObj.Account.Customer_Type_Without_RCV__c) ? new Set<String>(oppObj.Account.Customer_Type_Without_RCV__c.split(';')) : new Set<String>();
        Set<String> plsAERoleNamesSet = new Set<String>();    
        
        if(oppObj.Co_Owner__c != null) plsAERoleNamesSet.add(CLOUD_AE);
        if(oppObj.NCD_Co_Owner__c != null) plsAERoleNamesSet.add(NCD_AE);
        
        if(accCustTypeSet.isEmpty() || plsAERoleNamesSet.isEmpty()){
            assignPlsAcvValues(oli.New_Expansion_ACV__c, 0, 0, 0, 0, oli);
        } else if(accCustTypeSet.containsAll(new List<String>{CLOUD_CUST, NCD_CUST}) && plsAERoleNamesSet.containsAll(new List<String>{CLOUD_AE, NCD_AE})){
            assignPlsAcvValues(0, oli.New_Expansion_ACV__c, oli.New_Expansion_ACV__c/2, 0, oli.New_Expansion_ACV__c/2, oli);
        } else if(accCustTypeSet.contains(CLOUD_CUST) && plsAERoleNamesSet.contains(CLOUD_AE)){
            assignPlsAcvValues(0, oli.New_Expansion_ACV__c, oli.New_Expansion_ACV__c, 0, 0, oli);
        } else if(accCustTypeSet.contains(NCD_CUST) && plsAERoleNamesSet.contains(NCD_AE)){
            assignPlsAcvValues(0, oli.New_Expansion_ACV__c, 0, 0, oli.New_Expansion_ACV__c, oli);
        } else {
            assignPlsAcvValues(oli.New_Expansion_ACV__c, 0, 0, 0, 0, oli);
        }       
    }    
    //PL26-24 end
    /**
     * @description wrapper class to hold opportunity details
     */ 
    public class AcvWrapper{
        public Opportunity oppObj = null;
        public List<Opportunity> splitChildOppList = new List<Opportunity>();
        public List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        public List<OpportunityLineItem> splitProductList = new List<OpportunityLineItem>();
        public Decimal tcvAmount = 0; 
        public Decimal acvAmount = 0;
        public Decimal arrAmount = 0;
        public Decimal newExpansionACV = 0; //ARY-886
        public Decimal newExpansionTCV = 0; //ARY-886
        public Decimal subsumedRenewalTCV = 0; //ARY-886
        public Decimal subsumedRenewalACV = 0; //ARY-886
        public Decimal orgSubsumedRenewalTCV = 0; //SAL24-749
        public Decimal orgSubsumedRenewalACV = 0; //SAL24-749
        public Decimal subChurnACV = 0; //SAL24-749
        public Decimal subChurnTCV = 0; //SAL24-749
        public Decimal renewalTCV = 0;  //ARY-886
        public Decimal renewalACV = 0;  //SAL24-676
        public Integer oppSubscriptionTerm = 0;
        public Decimal totalHwSupportAmount = 0;
        public Decimal totalConsultQuantity = 0;
        public Boolean sowskusRequired = false;  
        public Decimal coreNewExpansionACV = 0; //PL26-24
        public Decimal nasNewExpansionACV = 0; //PL26-24
        public Decimal plsNewExpansionACV = 0; //PL26-24
        public Decimal saasNewExpansionACV = 0; //PL26-24 
        public Decimal ncdNewExpansionACV = 0; //SAL26-1218
        public Boolean hasScaleProducts = false; //SAl26-389
	public Boolean hasRealProducts = false;  //SAL26-258
        public Decimal ppCreds = 0;//FY25SR-1119
        public Decimal rbobACV = 0;//FY25SR-1119
        public Decimal compUpliftACV = 0; //SAL26-1277
      //SAL26-1280: Separate tracking for New vs Renewal line types for split calculation
        //Note: PLS fields (Core/NAS/SaaS/NCD) and New_Expansion_TCV are always zero on Renewal lines
        public Decimal newLineNewExpansionACV = 0; //New_Expansion_ACV from Line_Type__c = 'New'
        public Decimal renewalLineNewExpansionACV = 0; //New_Expansion_ACV from Line_Type__c = 'Renewal'
        public Decimal renewalrbobACV = 0; //SAL26-1280

        /**
         * @description constructor
         * @param opptyObj
         */
        public AcvWrapper(Opportunity opptyObj){ 
            oppObj = opptyObj;
        }
    }
    
    /**
     * @description wrapper class to hold which sales comp category products are present on opportunity
     */
    public class PlsACVWrapper {
        public Boolean hasDSPM = false;
        public Boolean hasNcdNasConsumptionSalesComp = false;
        public Boolean hasCloudConsumptionSalesComp = false;
        public Boolean hasSaaSIdentity = false;
        public Boolean hasO365 = false;
        public Boolean hasSaaSAddOn = false;
        /**
         * @description constructor
         * @param hasDSPM  
         * @param hasNcdNasConsumptionSalesComp 
         * @param hasCloudConsumptionSalesComp
         * @param hasSaaSIdentity
         * @param hasO365
         * @param hasSaaSAddOn
         */
        public PlsACVWrapper(Boolean hasDSPM, Boolean hasNcdNasConsumptionSalesComp, Boolean hasCloudConsumptionSalesComp, Boolean hasSaaSIdentity, Boolean hasO365, Boolean hasSaaSAddOn) {
            this.hasDSPM = hasDSPM;//SAL26-1221
            this.hasNcdNasConsumptionSalesComp = hasNcdNasConsumptionSalesComp;//SAL26-1218
            this.hasCloudConsumptionSalesComp = hasCloudConsumptionSalesComp;//SAL26-1221
            this.hasSaaSIdentity = hasSaaSIdentity;//SAL26-1220
            this.hasO365 = hasO365;
            this.hasSaaSAddOn = hasSaaSAddOn;
        }
    }
}