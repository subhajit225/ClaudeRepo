public class ScaleUtilityAmendHelper{
    
    static Boolean amendExecute = false;
    static Boolean amendDelExecute = false;
    public static List<ContractLineItem> contracLineItemList = new List<ContractLineItem>();
    public static Set<Date> startDateSet = New Set<Date>();
    public static Boolean quoteCreationInProgress = false;//flag to mark ql insert
    public static Boolean startDateChanged = false;
    public static Boolean quoteLineConsolidateFlag = false;
    public static Map<Id, Id> contractVsDisti = new Map<Id, Id>();
    
    public static void adjustSegmentLinesOnScaleUtilityAmend(List<SBQQ__Quote__c> qlist,Map<Id, SBQQ__Quote__c> qtNewMap,Map<Id, SBQQ__Quote__c> qtOldMap){
        ShGl_DisableBusinessLogic__c disabledBusinessLogic = ShGl_DisableBusinessLogic__c.getInstance();
        if(label.SUStartDateValidationBypass == 'false'){            
            Set<Id> contractIdSet = New Set<Id>();
            for(SBQQ__Quote__c qt : qlist){
                
                if(qt.SBQQ__Type__c == 'Amendment' && qt.Is_Scale_Utility_Quote__c == true && qt.SBQQ__Primary__c == true) {
                    contractIdSet.add(qt.Amended_Renewed_Service_Contract__c);
                  if(qt.OpportunitySubType__c != null && qt.OpportunitySubType__c == 'GC Offer' && qtOldMap.get(qt.id).SBQQ__StartDate__c != null && qtOldMap.get(qt.id).SBQQ__StartDate__c != qtNewMap.get(qt.id).SBQQ__StartDate__c){ 
                    qt.Adderror(label.QuoteStartDateValidation);
                }
                }
            }
            if(contractIdSet.size()>0){
                if(amendExecute == FALSE){
                    for(ContractLineItem ctline : [Select id,StartDate,EndDate,Quantity,Subscription_Term__c,ServiceContractId,SBQQSC__SegmentLabel__c,SBQQSC__SegmentKey__c,SBQQSC__SegmentIndex__c, Product_Type__c, ServiceContract.SBQQSC__Opportunity__r.Distributor_Lookup__c from ContractLineItem where ServiceContractId IN : contractIdSet /*and (SBQQSC__SegmentLabel__c != null or Product_Type__c = 'Edition Upgrade') order by SBQQSC__SegmentLabel__c desc*/]){
                        amendExecute = true;
                        contracLineItemList.add(ctline);
                        startDateSet.add(ctline.StartDate);
                        if (contractVsDisti.isEmpty() && !contractVsDisti.containsKey(ctline.ServiceContractId)) {
                            contractVsDisti.put(ctline.ServiceContractId, ctline.ServiceContract.SBQQSC__Opportunity__r.Distributor_Lookup__c);
                        }
                    }
                }
                
                for(SBQQ__Quote__c qt : qlist){ 
                    
                    if(!Test.isRunningTest() && qt.SBQQ__Type__c == 'Amendment' && qt.OpportunitySubType__c != null && qt.OpportunitySubType__c == 'GC Offer' && 
                       (startDateSet != null && !(startDateSet.contains(qt.SBQQ__StartDate__c)) || (qt.SBQQ__StartDate__c < Date.today())) && quoteCreationInProgress == true && qt.SBQQ__Primary__c == true                       
                      ){
                          
                          qt.Adderror(label.ScaleUAmenStartDateValidation);
                      } 

                      if (!contractVsDisti.isEmpty() && contractVsDisti.containsKey(qt.Amended_Renewed_Service_Contract__c) && contractVsDisti.get(qt.Amended_Renewed_Service_Contract__c) != null && qt.SBQQ__Distributor__c != null && qt.SBQQ__Distributor__c != contractVsDisti.get(qt.Amended_Renewed_Service_Contract__c) &&!disabledBusinessLogic.Disable_SBQQ_Quote_Validation_Rules__c /*&& qt.SBQQ__Primary__c == true && quoteCreationInProgress == true */) {
                        qt.Adderror(label.UtilityAmendmentQuoteDistiValidation);
                      }
                }
            }
            }
    }
    //CPQ4941 Starts
    public static void adjustSegmentLinesOnScaleUtilityAmendInsert(List<SBQQ__Quote__c> qlist){
        ShGl_DisableBusinessLogic__c disabledBusinessLogic = ShGl_DisableBusinessLogic__c.getInstance();
        if(label.SUStartDateValidationBypass == 'false'){            
            Set<Id> contractIdSet = New Set<Id>();
            
            for(SBQQ__Quote__c qt : qlist){
                
                if(qt.SBQQ__Type__c == 'Amendment' && qt.Is_Scale_Utility_Quote__c == true){ 
                    contractIdSet.add(qt.Amended_Renewed_Service_Contract__c);
                }
            }
            if(contractIdSet.size()>0){
                if(amendExecute == false || Test.isRunningTest()){ 
                
                    for(ContractLineItem ctline : [Select id,StartDate,EndDate,Quantity,Subscription_Term__c,ServiceContractId,SBQQSC__SegmentLabel__c,SBQQSC__SegmentKey__c,SBQQSC__SegmentIndex__c, Product_Type__c, ServiceContract.SBQQSC__Opportunity__r.Distributor_Lookup__c from ContractLineItem where ServiceContractId IN : contractIdSet /*and (SBQQSC__SegmentLabel__c != null or Product_Type__c = 'Edition Upgrade') order by SBQQSC__SegmentLabel__c desc*/]){
                        amendExecute = true;
                        contracLineItemList.add(ctline);
                        startDateSet.add(ctline.StartDate);
                        if (contractVsDisti.isEmpty() && !contractVsDisti.containsKey(ctline.ServiceContractId)) {
                            contractVsDisti.put(ctline.ServiceContractId, ctline.ServiceContract.SBQQSC__Opportunity__r.Distributor_Lookup__c);
                        }
                        
                    }
                }
                
                for(SBQQ__Quote__c qt : qlist){ 
                    
                    if(!Test.isRunningTest() && qt.SBQQ__Type__c == 'Amendment' && qt.OpportunitySubType__c != null && qt.OpportunitySubType__c == 'GC Offer' && 
                       (startDateSet != null && !(startDateSet.contains(qt.SBQQ__StartDate__c)) || (qt.SBQQ__StartDate__c < Date.today())) 
                      ){
                          
                          qt.Adderror(label.ScaleUAmenStartDateValidation); 
                      } 
                    if (!contractVsDisti.isEmpty() && contractVsDisti.containsKey(qt.Amended_Renewed_Service_Contract__c) && contractVsDisti.get(qt.Amended_Renewed_Service_Contract__c) != null && qt.SBQQ__Distributor__c != null && qt.SBQQ__Distributor__c != contractVsDisti.get(qt.Amended_Renewed_Service_Contract__c) &&!disabledBusinessLogic.Disable_SBQQ_Quote_Validation_Rules__c) {
                        qt.Adderror(label.UtilityAmendmentQuoteDistiValidation); 
                      }
                }
            }
        }
    }
    //CPQ22-4941 ends
    public static void restoreStartEndDate(List<SBQQ__Quoteline__c> qlist)
    {
        Map<Id, ContractLineItem> cnMapList;
        Set<Id> serviceLineSet = new Set<Id>();
        
        for(SBQQ__Quoteline__c qt: qlist)
        {
            if(qt.Product_Payment_Option__c != 'Monthly' 
               && (qt.Scale_Utility_Product_Identifier__c == 'M365 RSV SU' || qt.Scale_Utility_Product_RSV_OND__c == 'RSV') 
               && ((qt.RWD_Sales_Rep_Exception__c == null 
                    || (qt.RWD_Sales_Rep_Exception__c != null && !qt.RWD_Sales_Rep_Exception__c.contains('Scale Utility Payment Option Exception'))
                   )
                   && !Test.isRunningTest()))
            {
                System.debug('Scale');
                //qt.adderror(label.SUMonthlyPaymentError); 
            }
        }
        
    }
    
    
    //CSU-535 Starts
    @future
    public static void createAmendedScaleUGQLRecords(Set<Id> quoteIds){
        
        Map<String, List<SBQQ__QuoteLine__c>> qlOldMap = new Map<String, List<SBQQ__QuoteLine__c>>();
        List<SBQQ__QuoteLine__c> lstLinesDelete = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> lstLinesUpdatedQty = new List<SBQQ__QuoteLine__c>();
        Set<Id> setDelIds = new Set<Id>();
        List<String> lstUpgradeTypes =  !String.isBlank(System.Label.RBK_SUUpgradeEditions) ? System.Label.RBK_SUUpgradeEditions.split(',') : new List<String>{'SU FUE', 'SU FUP', 'SU EUP', 'SU FUB', 'SU BUE'};

        List<SBQQ__QuoteLine__c> lstQuoteLines = [SELECT Id, Name, SBQQ__Quote__c, GCID__c, SBQQ__RequiredBy__c, SBQQSC__UpgradedContractLine__c,
                                                  SBQQ__Quantity__c, SBQQ__EndDate__c, SBQQ__SubscriptionTerm__c, SBQQ__Quote__r.SBQQ__StartDate__c,
                                                  SBQQSC__UpgradedContractLine__r.StartDate, SBQQSC__UpgradedContractLine__r.EndDate, 
                                                  SBQQ__RequiredBy__r.SBQQ__StartDate__c, SBQQ__RequiredBy__r.SBQQ__EndDate__c,
                                                  SBQQ__RequiredBy__r.SBQQ__SubscriptionTerm__c, SBQQ__Quote__r.SBQQ__EndDate__c
                                                  FROM SBQQ__QuoteLine__c
                                                  WHERE SBQQ__Quote__c IN :quoteIds AND SBQQ__Quote__r.SBQQ__Type__c ='Amendment'
                                                  AND SBQQ__Quote__r.OpportunitySubType__c = 'GC Offer'
                                                  AND Scale_Utility_Product_Identifier__c in :lstUpgradeTypes
                                                  AND Product_Subtype__c = 'Scale MSP'
                                                  AND Line_Type__c != 'New'
                                                  ORDER BY SBQQSC__UpgradedContractLine__r.StartDate
                                                 ];
        
        if(!lstQuoteLines.isEmpty())
        {
            for(SBQQ__QuoteLine__c eachLine: lstQuoteLines)
            {
                List<SBQQ__QuoteLine__c> lstLines = new List<SBQQ__QuoteLine__c>();
                
                if(qlOldMap.containsKey(eachLine.SBQQ__RequiredBy__c)){
                    lstLines = qlOldMap.get(eachLine.SBQQ__RequiredBy__c);
                }
                
                lstLines.add(eachLine);
                qlOldMap.put(eachLine.SBQQ__RequiredBy__c, lstLines);
            }
            
            for(String eachParentItem : qlOldMap.keySet())
            {
                
                if(qlOldMap.get(eachParentItem).size() > 1)
                {
                    Decimal totalQuantity = 0;
                    Integer intIndex = 1;
                    Date startDt, endDt;
                    
                    for(SBQQ__QuoteLine__c eachLineItem: qlOldMap.get(eachParentItem))
                    {
                        totalQuantity += eachLineItem.SBQQ__Quantity__c;
                        
                        if(intIndex < qlOldMap.get(eachParentItem).size()){
                            lstLinesDelete.add(eachLineItem);
                            setDelIds.add(eachLineItem.Id);
                        }
                        
                        if(startDt == null || startDt > eachLineItem.SBQQSC__UpgradedContractLine__r.StartDate){
                            startDt = eachLineItem.SBQQSC__UpgradedContractLine__r.StartDate;
                        }
                        if(endDt == null || endDt < eachLineItem.SBQQSC__UpgradedContractLine__r.EndDate){
                            endDt = eachLineItem.SBQQSC__UpgradedContractLine__r.EndDate;
                        }
                        intIndex++;
                    }
                    
                    SBQQ__QuoteLine__c selectedUpgradeLine = qlOldMap.get(eachParentItem).get(qlOldMap.get(eachParentItem).size() - 1);
                    
                    //selectedUpgradeLine.SBQQ__Quantity__c = totalQuantity / qlOldMap.get(eachParentItem).size();
                    
                    selectedUpgradeLine.SBQQ__StartDate__c = selectedUpgradeLine.SBQQ__RequiredBy__r.SBQQ__StartDate__c != null ? 
                        selectedUpgradeLine.SBQQ__RequiredBy__r.SBQQ__StartDate__c : selectedUpgradeLine.SBQQ__Quote__r.SBQQ__StartDate__c != null ? 
                        selectedUpgradeLine.SBQQ__Quote__r.SBQQ__StartDate__c : startDt;
                    
                    selectedUpgradeLine.SBQQ__EndDate__c = selectedUpgradeLine.SBQQ__RequiredBy__r.SBQQ__EndDate__c != null ? 
                        selectedUpgradeLine.SBQQ__RequiredBy__r.SBQQ__EndDate__c : selectedUpgradeLine.SBQQ__Quote__r.SBQQ__EndDate__c != null ? 
                            selectedUpgradeLine.SBQQ__Quote__r.SBQQ__EndDate__c : endDt;
                    
                    
                    selectedUpgradeLine.SBQQ__SubscriptionTerm__c = selectedUpgradeLine.SBQQ__RequiredBy__r.SBQQ__SubscriptionTerm__c != null ? 
                        selectedUpgradeLine.SBQQ__RequiredBy__r.SBQQ__SubscriptionTerm__c : selectedUpgradeLine.SBQQ__StartDate__c.monthsBetween(selectedUpgradeLine.SBQQ__EndDate__c);
                    
                    lstLinesUpdatedQty.add(selectedUpgradeLine);
                }
            }
            if(!lstLinesUpdatedQty.isEmpty()){
                
                
                SBQQ.TriggerControl.disable();
                if(!Test.isRunningTest()){
                    update lstLinesUpdatedQty;
                }
                
                SBQQ.TriggerControl.enable();
            }
            if(!setDelIds.isEmpty()){
                
                
                List<Database.DeleteResult> lstResult = Database.delete(lstLinesDelete, false);
                
            }
            quoteLineConsolidateFlag = true;
        }
    }
    
    //@future
    public static void deleteQLRecs(Set<Id> quoteLineIdSet){
        
        if(!quoteLineIdSet.isEmpty()){
            List<SBQQ__QuoteLine__c> lstLinesDelete = [SELECT Id FROM SBQQ__QuoteLine__c WHERE Id IN: quoteLineIdSet];
            
            if(!lstLinesDelete.isEmpty()){
                List<Database.DeleteResult> lstResult = Database.delete(lstLinesDelete, false);
            }
        }
    }
}