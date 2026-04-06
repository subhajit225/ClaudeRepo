// Main SBQQ_QuoteLine__c Trigger's Handler //
/**
 * @description Handler for SBQQ_QuoteLine__c trigger. Contains logic for populating fields, validation, and business rules on QuoteLine records.
 * Called populateFieldsOnQuoteLine Method
 * Method calling is done on After Update of QuoteLine
 * Deployed on 23rd May 2020
 */

public without sharing class SBQQ_QuoteLineTriggerHandler extends TriggerHandler {
    public static boolean recursionCheck = false;  
    /** dispositionFlag*/
    public static Boolean dispositionFlag = false; //added for Arroyo
    private Boolean isDisabled =false;
    private Boolean isFieldEditabilityDisabled =false;
    private Boolean isQuotableValDisabled =false; //CPQ22-4821
    //Build under SF-8787 can be used globally 
    public static Map<Id,SBQQ__QuoteLine__c> QLIRelatedObjectsMap =new Map<Id,SBQQ__QuoteLine__c>();
    public static Boolean byPassQLITriggerForPolarisSKURestructuring = false;// RWD -392
    
    /**
     * @description Constructor for SBQQ_QuoteLineTriggerHandler. Initializes trigger settings and disables logic if configured.
     */
    public SBQQ_QuoteLineTriggerHandler() {
        
        ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance();
        isDisabled = disabled.Disable_SBQQ_QuoteLine_Triggers__c;
        isFieldEditabilityDisabled = disabled.Disable_Field_Editability_Control_Fun__c;//CPQ22-6097
        isQuotableValDisabled = disabled.Disable_Quotable_Validation__c; //CPQ22-4821
        
        ///// DO NOT RUN MORE THAN 2 TIME - Avoid Recursion /////
        Integer mxloopCount = Integer.valueOf(disabled.TriggerMaxLoopCount__c);
        this.setMaxLoopCount(mxloopCount);           
    }
    
    public override void beforeInsert() {
        if(!isDisabled) { 
            if(!byPassQLITriggerForPolarisSKURestructuring){// RWD -392
                SBQQ_QuoteLineTriggerHelper.populateFieldsOnInsert((List<SBQQ__QuoteLine__c>) Trigger.new);
                //SBQQ_QuoteLineTriggerHelper.populateAssetDetails((List<SBQQ__QuoteLine__c>) Trigger.new);
                // START - SAL-148
                //Start - Commented as part of GLCR-101. Commented because this method is just populating maps and nothing else
                //SBQQ_QuoteLineTriggerHelper.populateBundlePremiumSupportAndSubscriptionTerm((List<SBQQ__QuoteLine__c>) Trigger.new);
                //End - Commented as part of GLCR-101
                // END -  SAL-148 
                //SBQQ_QuoteLineTriggerHelper.populateDiscountThreshold((List<SBQQ__QuoteLine__c>) Trigger.new); //ARY-383
            }
            SBQQ_QuoteLineTriggerHelper.quoteOrderNotification();
            /*beforeInsert This invoke is needed because when the new Bundles are inserted, it does not sets the Optional field correctly
and does not handles the scenario when user updates the Qty on QLI, to have optional toggeled */
            SBQQ_QuoteLineTriggerHelper.autoAddONDSKUs((List<SBQQ__QuoteLine__c>)Trigger.new, 'beforeInsert');
            
           
                      
        }
    }
    
    public override void beforeUpdate() {
        if(!isDisabled) {
            if(!byPassQLITriggerForPolarisSKURestructuring){// RWD -392
                
                // Start Build under SF-8787 can be used globally
                if(QLIRelatedObjectsMap.isEmpty()){
                    QLIRelatedObjectsMap = SBQQ_QuoteLineTriggerHelper.getQLIRelatedObjectInfo(((Map<Id,SBQQ__QuoteLine__c>)Trigger.newMap).keyset());
                }
                // End Build under SF-8787 can be used globally

                //CPQ22-6097 Start
                if(!isFieldEditabilityDisabled && !QLIRelatedObjectsMap.isEmpty() && !System.isBatch() && !System.isFuture() && !System.isQueueable() && !System.isScheduled()){
                    SBQQ_QuoteLineTriggerHelper.enforceFieldEditablility(Trigger.new, (Map<Id, SBQQ__QuoteLine__c>)Trigger.oldMap,QLIRelatedObjectsMap);
                }
                //CPQ22-6097 END

                //RWD-1013/RWD-382
                SBQQ_QuoteLineTriggerHelper.populateReinstatementFeeSkuDefaultValue((List<SBQQ__QuoteLine__c>) Trigger.new);
                
                //SF 8332 Starts
                if(!LockQuoteValidationByPass.byPassValidation){
                    if(!QLIRelatedObjectsMap.isEmpty()){
                        SBQQ_QuoteLineTriggerHelper.validateQuoteLines((Map<Id,SBQQ__QuoteLine__c>) Trigger.newMap,QLIRelatedObjectsMap);          
                    }   
                }  
                //SF 8332 Ends
                //Ensuring Renewal HW Quotes are Existing -RWD-1475
                for(SBQQ__QuoteLine__c quoteLine : (List<SBQQ__QuoteLine__c>)Trigger.new){
                    // if(quoteLine.Line_Type__c == 'Renewal' && quoteLine.Product_Level__c == 'Hardware' && !quoteLine.SBQQ__Existing__c && !quoteLine.Is_Refresh__c){
                    //     quoteLine.SBQQ__Existing__c = true;
                    // }
                    
                    if(quoteLine.Line_Type__c == 'Renewal' && quoteLine.Product_Level__c == 'Hardware' && !quoteLine.SBQQ__Existing__c && quoteLine.Special_Program__c !='Refresh'){
                        quoteLine.SBQQ__Existing__c = true;
                    }

                    quoteLine.Product_Code__c = quoteLine.SBQQ__PackageProductCode__c;
                    SBQQ__QuoteLine__c oldQli = (SBQQ__QuoteLine__c) Trigger.oldMap.get(quoteLine.Id);
                    // RWD-432: SETTING OLD CO-TERM Checkbox FIELD VALUE BEGINS
                    if (quoteLine.Co_Term__c != oldQli.Co_Term__c ) {
                        quoteLine.Old_Co_Term__c =  quoteLine.Co_Term__c;
                    }

                    //MS CPQ22-5366 Starts
                    if ((quoteLine.Scale_Utility_Product_RSV_OND__c == 'RSV' || quoteLine.Scale_Utility_Product_Identifier__c == 'M365 RSV SU') && quoteLine.SBQQ__SegmentLabel__c != null && quoteLine.SBQQ__RequiredBy__c != null && quoteLine.SBQQSC__UpgradedContractLine__c != null && oldQli.Quantity_TB__c == null && quoteLine.Quantity_TB__c != null) {
                        quoteLine.SBQQ__PriorQuantity__c = quoteLine.Quantity_TB__c;
                    }
                    //MS CPQ22-5366 Ends

                }
                
                SBQQ_QuoteLineTriggerHelper.quoteOrderNotification();
                /*GLCR-101 - Start Commented for loop - and moved the code to existing for loop above     
List<SBQQ__QuoteLine__c> newQliList = new List<SBQQ__QuoteLine__c> ();
for(SBQQ__QuoteLine__c qli : (List<SBQQ__QuoteLine__c>)Trigger.new) {
qli.Product_Code__c = qli.SBQQ__PackageProductCode__c;

SBQQ__QuoteLine__c oldQli = (SBQQ__QuoteLine__c) Trigger.oldMap.get(qli.Id);

// RWD-432: SETTING OLD CO-TERM Checkbox FIELD VALUE BEGINS
if (qli.Co_Term__c != oldQli.Co_Term__c ) {
qli.Old_Co_Term__c =  qli.Co_Term__c;
}*/ //GLCR-101 - End
                
                /*
List<String> listAssetId = qli.SBQQ__SubscribedAssetIds__c == null ? new List<String>() : qli.SBQQ__SubscribedAssetIds__c.split(',');
List<String> listAssetName = qli.SubscribedAssetNames__c == null ? new List<String>() : qli.SubscribedAssetNames__c.split(',');
//if(qli.SBQQ__SubscribedAssetIds__c != null && qli.SBQQ__SubscribedAssetIds__c != oldQli.SBQQ__SubscribedAssetIds__c) {
if(
listAssetId.size() != listAssetName.size()
|| (qli.SBQQ__SubscribedAssetIds__c != null
&& qli.SBQQ__SubscribedAssetIds__c != oldQli.SBQQ__SubscribedAssetIds__c)
) {
newQliList.add(qli);
}
*/
                //}GLCR-101 Commented for loop
                /*
if(newQliList.size() > 0) {
SBQQ_QuoteLineTriggerHelper.populateAssetDetails(newQliList);
}
*/
                // START - SAL-148 // TODO: pass only Quotelines with term
                //Start - Commented as part of GLCR-101. Commented because this method is just populating maps and nothing else
                //SBQQ_QuoteLineTriggerHelper.populateBundlePremiumSupportAndSubscriptionTerm((List<SBQQ__QuoteLine__c>) Trigger.new);
                //End - Commented as part of GLCR-101.
                // END -  SAL-148 
                //CPQ22-874
                //SBQQ_QuoteLineTriggerHelper.calculateCustomPOT((List<SBQQ__QuoteLine__c>)Trigger.new);
            }
            //CPQ22-1104
            //Commented as part of GLCR-101
            //SBQQ_QuoteLineTriggerHelper.populateSubscribedAssetIds((Map<Id,SBQQ__QuoteLine__c>)Trigger.oldMap, Trigger.New,QuoteIds,quoteDetailsMap);

            // SBQQ_QuoteLineTriggerHelper.populateDiscountThreshold((List<SBQQ__QuoteLine__c>) Trigger.new); //ARY-383
            /*beforeUpdate This invoke is needed because when user does not update anything on the QLI and only inserts FUE*/
            SBQQ_QuoteLineTriggerHelper.autoAddONDSKUs((List<SBQQ__QuoteLine__c>)Trigger.new, 'beforeUpdate');//beforeUpdate
                       // SBQQ_QuoteLineTriggerHelper.populateDiscountThreshold((List<SBQQ__QuoteLine__c>) Trigger.new); //ARY-383
           ScaleUtilityAmendHelper.restoreStartEndDate((List<SBQQ__QuoteLine__c>) Trigger.new);//ScaleUtility_phase2

        }
    }
    
    public override void beforeDelete() {
        if(!isDisabled) {
            Set<Id> quoteIdSet = new Set<Id>();
            Map<Id,SBQQ__Quote__c> quoteIdRecordMap;
            Boolean hasUpgrades = false;
            List<String> lstUpgradeTypes = new List<String>{'SU FUE', 'SU FUP', 'SU EUP', 'SU FUB', 'SU BUE', 'SU BUP'};

            for(SBQQ__QuoteLine__c quoteLine :(List<SBQQ__QuoteLine__c>)Trigger.old){
                if (quoteLine.Replacement_Motion__c != null && quoteLine.Product_Type__c != ReplacementConstants.ACCESSORIES) {//FY25SR-2385 start
                    quoteLine.addError('You can’t delete this line from the quote cart. Please go to the SMS screen to delete it. ' +
                                       'To restore the line, please refresh the page.');
                }//FY25SR-2385 end
                if(quoteLine.SBQQ__Quote__c != null){
                    quoteIdSet.add(quoteLine.SBQQ__Quote__c);
                }
                if(String.isNotBlank(quoteLine.Scale_Utility_Product_Identifier__c) && lstUpgradeTypes.contains(quoteLine.Scale_Utility_Product_Identifier__c)){
                    hasUpgrades = true;
                }
            }
            if(!quoteIdSet.isEmpty()){
                if(Schema.sObjectType.SBQQ__Quote__c.isAccessible()) {
                    quoteIdRecordMap = new Map<Id,SBQQ__Quote__c>([SELECT Id,SBQQ__Type__c from SBQQ__Quote__c WHERE ID =:quoteIdSet]);
                    SBQQ_QuoteLineTriggerHelper.stopDeletionOfRenewalLines(Trigger.old,quoteIdRecordMap); //Arroyo 2.0 Added by Sameer Kulkarni
                } 
            }

            if(hasUpgrades) {
                SBQQ_QuoteLineTriggerHelper.autoAddONDSKUs((List<SBQQ__QuoteLine__c>)Trigger.old, 'beforeDelete');//afterDelete
            }
            
        }
    }
    
    public override void afterInsert() {
        if(!isDisabled) {  
            Map<Id,String> quoteIdToProdType = new Map<Id,String>();
            if(!byPassQLITriggerForPolarisSKURestructuring){// RWD -392
                set<Id> qliId = new Set<Id>(); 
                for(SBQQ__QuoteLine__c qli : (List<SBQQ__QuoteLine__c>)Trigger.new) {
                    qliId.add(qli.Id);
                    
                }  
                if(!System.IsBatch() && !System.isFuture() ) {
                    SBQQ_QuoteLineTriggerHelper.datePolicy(qliId, false);  
                    //SBQQ_QuoteLineTriggerHelper.makeFieldsNullWhenCloned(qliId);
                }
            }
            for(SBQQ__QuoteLine__c quoteLine : (List<SBQQ__QuoteLine__c>) Trigger.New) {
                //Arroyo 2.0 ARY-71: STARTS - Logic-Starts BY Shaloo to stamp approval identifier for Arroyo approvals once new lines are added to a Quote
                if(quoteLine.SBQQSC__RenewedContractLine__c == null || quoteLine.Quote_Line_Type__c == 'New'){
                    dispositionFlag = TRUE;
                }
                //Arroyo 2.0 ARY-71: ENDS - Logic-Starts BY Shaloo to stamp approval identifier for Arroyo approvals once new lines are added to a Quote
                //GTMIT-49: Starts -Logic - filter quotes having qli's with Product_Type__c contains PAYGO .
                if (!quoteIdToProdType.containsKey(quoteLine.SBQQ__Quote__c) && String.isNotBlank(quoteLine.Product_Type__c) && quoteLine.Product_Type__c.contains(CPQ_Constants.PAYGO) ) {
                    quoteIdToProdType.put(quoteLine.SBQQ__Quote__c,quoteLine.Product_Type__c);
                }//GTMIT-49: Ends -Logic -filter quotes having qli's with Product_Type__c contains PAYGO .
            }
            //Arroyo 2.0 ARY-71: STARTS - To stamp approval identifier for Arroyo approvals once new lines are added to a Quote
            if(dispositionFlag){
                SBQQ_QuoteLineTriggerHelper.updateApprovalIdentifierForDisposition((Map<Id, SBQQ__QuoteLine__c>) Trigger.newMap);//afterInsert
            }
            //Arroyo 2.0 ARY-71: ENDS - To stamp approval identifier for Arroyo approvals once new lines are added to a Quote
            //Arroyo 2.0 ARY-71 STARTS: Logic Added by Shaloo to populate Quote Group on new lines for Renewal+Expansion for Arroyo
            SBQQ_QuoteLineTriggerHelper.populateQuoteLineGroup((List<SBQQ__QuoteLine__c>)Trigger.new);
            //Arroyo 2.0 ARY-71 ENDS: Logic Added by Shaloo to populate Quote Group on new lines for Renewal+Expansion for Arroyo
            //SBQQ_QuoteLineTriggerHelper.autoAddONDSKUs((List<SBQQ__QuoteLine__c>)Trigger.new, 'afterInsert');//afterInsert
            //CPQ22-4821 calling on insertion
            if(!isQuotableValDisabled){
                SBQQ_QuoteLineTriggerHelper.quotableByValidation((Map<Id,SBQQ__QuoteLine__c>)Trigger.newMap,new Map<Id,SBQQ__QuoteLine__c>(),(Map<Id,SBQQ__QuoteLine__c>)Trigger.oldMap,Trigger.isInsert);//ITNPI-3372
            }
            if(!quoteIdToProdType.isEmpty()){
                // GTMIT-49: Starts - To populate PayGo identifier on opportunity once PayGo SKU is added to a Quote
            	SBQQ_QuoteLineTriggerHelper.populateFieldsOnOpportunity(quoteIdToProdType,false);
               //GTMIT-49: Ends - To populate PayGo identifier on opportunity once PayGo SKU is added to a Quote
            }         
			SBQQ_QuoteLineTriggerHelper.quotableByCountriesValidation((Map<Id,SBQQ__QuoteLine__c>)Trigger.newMap,(Map<Id,SBQQ__QuoteLine__c>)Trigger.oldMap,Trigger.isInsert);
            
        }
    }
    
    public override void afterUpdate() {
        String quoteType = '';
        Date quotStartRange = Date.newInstance(2022, 8, 15);
        Date quotRangeEnd   = Date.newInstance(2024, 1, 31);
        Date todayPlussubTerm = Date.today();
        if(!isDisabled) {  
            if(!byPassQLITriggerForPolarisSKURestructuring) {// RWD-392 Start
                SBQQ_QuoteLineTriggerHelper.populateFieldsOnQuoteLine((Map<Id,SBQQ__QuoteLine__c>)Trigger.newMap);
                
                Map<Id,SBQQ__QuoteLine__c> oldQliMap = (Map<Id,SBQQ__QuoteLine__c>)Trigger.oldMap;
                Set<ID> quoteIdSet = new Set<ID>();
                set<Id> qliId = new Set<Id>(); 
                for(SBQQ__QuoteLine__c qli : (List<SBQQ__QuoteLine__c>)Trigger.new) {
                    qliId.add(qli.Id);
                    //GLCR-101 - Start - commented because not being used anywhere
                    /*if(qli.SBQQ__SubscriptionTerm__c != oldQliMap.get(qli.id).SBQQ__SubscriptionTerm__c){
quoteIdSet.add(qli.SBQQ__Quote__c);
}*/
                    //GLCR-101 - End - commented because not being used anywhere
                } 
                if(!System.IsBatch() && !System.isFuture() && !System.isQueueable()) {
                    SBQQ_QuoteLineTriggerHelper.datePolicy(qliId, false);
                }
                /*
if(!quoteIdSet.isEmpty()){
Map<ID, Opportunity> oliMap = new Map<ID, Opportunity>([Select ID, Name FROM Opportunity where SBQQ__PrimaryQuote__c IN :quoteIdSet]);
if(!oliMap.isEmpty()){
OppAnnualContractValueUtil.calculateAcvAmount(oliMap.keySet());
}
}*/
                /*    
Set<Id> qliItemId = new Set<Id>();
Set<Id> quotIdset = new set<Id>();
for(SBQQ__QuoteLine__c qli : (List<SBQQ__QuoteLine__c>)Trigger.new) {
qliItemId.add(qli.Id);

}
X0_RCDM_Dates__mdt rcdmDatesObj = new X0_RCDM_Dates__mdt();
rcdmDatesObj = [SELECT Id, DeveloperName, EndDate_Day__c, EndDate_Month__c, EndDate_Year__c,StartDate_Day__c, StartDate_Month__c,StartDate_Year__c FROM X0_RCDM_Dates__mdt where DeveloperName = 'RCDM_Dates' LIMIT 1];

List<SBQQ__QuoteLine__c> quotList = new List<SBQQ__QuoteLine__c>();
if(qliItemId.size()>0){
List<SBQQ__QuoteLine__c> quoteList = [Select Id,
SBQQ__Quote__r.SBQQ__Account__c,
SBQQ__Quote__r.SBQQ__Account__r.Account_Status__c,
SBQQ__Quote__r.SBQQ__StartDate__c,
SBQQ__Quote__r.Is_Renewal_Quote__c,
SBQQ__Quote__r.Amended_Renewed_Service_Contract__c,
SBQQ__Quote__r.SBQQ__Type__c,
SBQQ__Quote__r.SBQQ__Opportunity2__c,
SBQQ__Quote__r.SBQQ__SubscriptionTerm__c,
SBQQ__Quote__r.IsRCDMAdded__c,
SBQQ__Quote__r.Todays_Date__c
from SBQQ__QuoteLine__c 
where Id IN:qliItemId];
if(quoteList.size()>0){
if(rcdmDatesObj != null) {
quotStartRange = Date.newInstance(Integer.valueOF(rcdmDatesObj.StartDate_Year__c), Integer.valueOF(rcdmDatesObj.StartDate_Month__c), Integer.valueOF(rcdmDatesObj.StartDate_Day__c));
quotRangeEnd = Date.newInstance(Integer.valueOF(rcdmDatesObj.EndDate_Year__c), Integer.valueOF(rcdmDatesObj.EndDate_Month__c), Integer.valueOF(rcdmDatesObj.EndDate_Day__c));
}
for(SBQQ__QuoteLine__c quotObj:quoteList){
if(quotObj.SBQQ__Quote__r.Todays_Date__c != null && quotObj.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c != null) {
todayPlusSubTerm = quotObj.SBQQ__Quote__r.Todays_Date__c.addMonths(Integer.valueOF(quotObj.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c));
}
System.debug('>>> todayPlusSubTerm: '+todayPlusSubTerm);
//if(quotObj.SBQQ__Quote__r.SBQQ__Account__c!=null && quotObj.SBQQ__Quote__r.SBQQ__Account__r.Account_Status__c == 'Existing Customer' && ((quotObj.SBQQ__Quote__r.SBQQ__StartDate__c >=quotStartRange) && (quotObj.SBQQ__Quote__r.SBQQ__StartDate__c <=quotRangeEnd))){
if(quotObj.SBQQ__Quote__r.IsRCDMAdded__c == false && quotObj.SBQQ__Quote__r.SBQQ__Account__c!=null && ((quotObj.SBQQ__Quote__r.Todays_Date__c >=quotStartRange) && (todayPlusSubTerm <=quotRangeEnd))){
quotList.add(quotObj);
quoteIdSet.add(quotObj.SBQQ__Quote__c);
}
}
}
}
if(quotList.size()>0){
system.debug('CallingCPQAPI');
if(quoteType == 'Quote') {
SBQQ_QuoteLineTriggerHelper.createQuoteLineFromAPI(quotList,quotIdSet, quotStartRange, quotRangeEnd);
//SBQQ_QuoteLineTriggerHelper.create0RCDM(quotIdSet);
} else if (quoteType == 'Renewal') {
SBQQ_QuoteLineTriggerHelper.createQuoteLineFromAPIRenewal(quoteIdSet, quotStartRange, quotRangeEnd);
//SBQQ_QuoteLineTriggerHelper.create0RCDM(quotIdSet);
}
}*/ 
            }
            //CPQ22-1104
            SBQQ_QuoteLineTriggerHelper.validateSubscribedAssetIds((Map<Id,SBQQ__QuoteLine__c>)Trigger.oldMap, Trigger.New);
            //Arroyo 2.0 ARY-71: STARTS - To stamp approval identifier for Arroyo approvals once renewal lines have Dispositions updated to a Quote
            Map<Id, SBQQ__QuoteLine__c> oldQuoteLineValues = (Map<Id, SBQQ__QuoteLine__c>) Trigger.oldMap;
           for(SBQQ__QuoteLine__c quoteLine : (List<SBQQ__QuoteLine__c>) Trigger.New) {
                
                
                if(oldQuoteLineValues.get(quoteLine.Id).Disposition_Reason__c != quoteLine.Disposition_Reason__c){
                    
                    
                    dispositionFlag = TRUE;
                }
            }
            //Arroyo 2.0 ARY-71: ENDS - To stamp approval identifier for Arroyo approvals once renewal lines have Dispositions updated to a Quote
            //Arroyo 2.0 ARY-71: STARTS - To stamp approval identifier for Arroyo approvals once renewal lines have Dispositions updated to a Quote
            if(dispositionFlag){
                system.debug(LoggingLevel.INFO, 'dispositionFlag block');
                //SBQQ_QuoteLineTriggerHelper.updateApprovalIdentifierForDisposition((Map<Id, SBQQ__QuoteLine__c>) Trigger.newMap);//afterUpdate
            }
            //Arroyo 2.0 ARY-71: ENDS - To stamp approval identifier for Arroyo approvals once renewal lines have Dispositions updated to a Quote
            //Arroyo 2.0 ARY-71 STARTS: Logic Added by Shaloo to populate Quote Group on new lines for Renewal+Expansion for Arroyo
            SBQQ_QuoteLineTriggerHelper.populateQuoteLineGroup((List<SBQQ__QuoteLine__c>)Trigger.new);
            //Arroyo 2.0 ARY-71 ENDS: Logic Added by Shaloo to populate Quote Group on new lines for Renewal+Expansion for Arroyo
            
            Map<Id,SBQQ__QuoteLine__c> newMapQLI = (Map<Id,SBQQ__QuoteLine__c>)Trigger.newMap;
            SBQQ_QuoteLineTriggerHelper.setSourceListPrice(newMapQLI.keySet(), (Map<Id,SBQQ__QuoteLine__c>)Trigger.oldMap);//ITNPI-2901 Added parameter
            //CPQ22-4821 calling on updation
            if(!isQuotableValDisabled){
               
                if(!isQuotableValDisabled){
                    if(!QLIRelatedObjectsMap.isEmpty()){
						SBQQ_QuoteLineTriggerHelper.quotableByValidation((Map<Id,SBQQ__QuoteLine__c>)Trigger.newMap,(Map<Id,SBQQ__QuoteLine__c>)Trigger.oldMap,QLIRelatedObjectsMap,Trigger.isInsert); //ITNPI-3372
                    }
                }
      			
                if(!QLIRelatedObjectsMap.isEmpty()){
					SBQQ_QuoteLineTriggerHelper.quotableByCountriesValidation((Map<Id,SBQQ__QuoteLine__c>)Trigger.newMap,QLIRelatedObjectsMap,Trigger.isInsert);
                }   
            }
        }
    }
    
    public override void afterDelete() {
        if(!isDisabled) {
            Map<Id,String> quoteIdToProdType = new Map<Id,String>();          
            //Arroyo 2.0 ARY-71: STARTS - To stamp approval identifier for Arroyo approvals once renewal lines have Dispositions are deleted from a Quote
          /**  Map<Id, SBQQ__QuoteLine__c> oldQuoteLineValues = (Map<Id, SBQQ__QuoteLine__c>) Trigger.oldMap;
           
            for(SBQQ__QuoteLine__c quoteLine : oldQuoteLineValues.values()) {
                if(quoteLine.SBQQSC__RenewedContractLine__c == null || quoteLine.Quote_Line_Type__c == 'New'){
                    
                    SBQQ_QuoteLineTriggerHelper.updateApprovalIdentifierForDisposition((Map<Id, SBQQ__QuoteLine__c>) Trigger.oldMap);//if new lines added got deleted
                }
            }**/
    SBQQ_QuoteLineTriggerHelper.updateApprovalIdentifierForDisposition((Map<Id, SBQQ__QuoteLine__c>) Trigger.oldMap);//if new lines added got deleted        //SBQQ_QuoteLineTriggerHelper.updateAssetNameOnQlI((Map<Id, SBQQ__QuoteLine__c>) Trigger.oldMap);//move to QCP
            //Arroyo 2.0 ARY-71: EBDS - To stamp approval identifier for Arroyo approvals once renewal lines have Dispositions are deleted from a Quote
            //CPQ22-5393
            set<Id> qliId = new Set<Id>();
            for(SBQQ__QuoteLine__c qli : (List<SBQQ__QuoteLine__c>)Trigger.old) {
                    qliId.add(qli.Id);
                //GTMIT-49: Starts -Logic - filter quotes having qli's with Product_Type__c contains PAYGO .
                if (!quoteIdToProdType.containsKey(qli.SBQQ__Quote__c) && String.isNotBlank(qli.Product_Type__c) && qli.Product_Type__c.contains(CPQ_Constants.PAYGO) ) {
                    quoteIdToProdType.put(qli.SBQQ__Quote__c,qli.Product_Type__c);
                }//GTMIT-49: Ends -Logic -filter quotes having qli's with Product_Type__c contains PAYGO .
            }
            
            if(!quoteIdToProdType.isEmpty()){
                // GTMIT-49: Starts - To populate PayGo identifier on opportunity once PayGo SKU is added to a Quote
            	SBQQ_QuoteLineTriggerHelper.populateFieldsOnOpportunity(quoteIdToProdType,true);
               //GTMIT-49: Ends - To populate PayGo identifier on opportunity once PayGo SKU is added to a Quote
            }
            if(!System.IsBatch() && !System.isFuture() ) {
                SBQQ_QuoteLineTriggerHelper.datePolicy(qliId, true);  
            }
        }
    }
    /**
     * @description Handles logic after a deleted SBQQ_QuoteLine__c record is undeleted.
    */
    public override void afterUndelete() {
        system.debug(LoggingLevel.INFO, 'Inside afterUndelete');
    }
}