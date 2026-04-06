/***********************************************************************************************************
* Class Name           : NewMetricsCalculator
* Date Created/Modified: 30/04/2024
* Author               : Sumedha Holla
* @description         : This class is used to calculate metrics for new framework
* Test Class           :
/**********************************************************************************************************/
public without sharing class NewMetricsCalculator {
    /***********************************************************************************************************
    * Method Name          : calculateMetrics
    * Date Created/Modified: 30/04/2024
    * Author               : Sumedha Holla
    * @description         : To calculate metrics for each of the Expansion Lines.
    * @param               quoteId
    /**********************************************************************************************************/
    @future
    public static void calculateMetrics (Set<Id> quoteId) {
        Map<Id, ReplacementJson> replacementDets = new Map<Id, ReplacementJson>();
        List<SBQQ__QuoteLine__c> qLines = MetricsCalculatorUtil.getAllLines (quoteId);
        List<SBQQ__QuoteLine__c> qNewLines = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> qRenewalLines = new List<SBQQ__QuoteLine__c>();
        Map<Id, String> linesToUpdateOldCLI = new Map<Id, String>();
        Map<Id, Decimal> qliIdvsRTA = new Map<Id, Decimal>();
        Map<Id, Decimal> qlvsRTA = new Map<Id, Decimal>();
        Map<id,Decimal> qliListTotal = new Map<id,Decimal>();
        Map<Id, SBQQ__QuoteLine__c> qlvsACVUpdates = new Map<Id, SBQQ__QuoteLine__c>();
        if (qLines != null && !qLines.isEmpty()) {
            for (SBQQ__QuoteLine__c qLine : qLines) {
                if (qLine.Quote_Line_Type__c == ReplacementConstants.QUOTE_TYPE_NEW) {
                    qNewLines.add(qLine);
                    if(qLine.Special_Program__c != 'Refresh' && string.isNotBlank(qLine.Special_Program__c)){
                        String qlineKey = qLine.SBQQ__RequiredBy__c != null && qLine.SBQQ__ProductOption__r.Refresh_Default_Option__c && Label.AutoAddSKUProductTypes.contains(qLine.SBQQ__Product__r.Product_Type__c)? qLine.SBQQ__RequiredBy__c : qLine.Id;
                        Decimal listTotal = qLine.SBQQ__ListPrice__c*qLine.SBQQ__Quantity__c;
                        if(qliListTotal.containsKey(qlineKey)){
                            qliListTotal.put(qlineKey,qliListTotal.get(qlineKey)+listTotal);
                        }else{
                            qliListTotal.put(qlineKey,listTotal);
                        } 
                    }
                }else if (qLine.Quote_Line_Type__c == ReplacementConstants.QUOTE_TYPE_RENEWAL) {
                        qRenewalLines.add(qLine);
                    }
                }
           
            //qNewLines = MetricsCalculatorUtil.getRenOrExpLines(qLines, ReplacementConstants.QUOTE_TYPE_NEW);
            //qRenewalLines = MetricsCalculatorUtil.getRenOrExpLines(qLines, ReplacementConstants.QUOTE_TYPE_RENEWAL);
            replacementDets = MetricsCalculatorUtil.deserealiseReplacementDets (qLines);
        
            List<String> selectedEntIds = MetricsCalculatorUtil.getSelectedEntitlements(replacementDets);
            if (selectedEntIds != null && !selectedEntIds.isEmpty()) {
                MetricsCalculatorUtil.getSelectedContractLineItems(selectedEntIds);
            }
            
            MetricsCalculatorUtil.qlivsclivsSelQty = MetricsCalculatorUtil.getSelectedQtyPerSelection(replacementDets);
            
            if (MetricsCalculatorUtil.cliIdvsCLI != null && !MetricsCalculatorUtil.cliIdvsCLI.isEmpty() && qLines!= null && !qLines.isEmpty()) {
                //linesToUpdateOldCLI = getSubsOldCLI(selectedEntIds, entIdvsCLIId);
                qliIdvsRTA = MetricsCalculatorUtil.calculateRTA(MetricsCalculatorUtil.cliIdvsCLI.keySet()/*, qRenewalLines*/);
                qlvsRTA = MetricsCalculatorUtil.calculateSubsumedAmt(qliIdvsRTA, qLines);
            }
            qlvsACVUpdates = MetricsCalculatorUtil.calculateMetricsOnQuoteLines (qLines, qlvsRTA, qNewLines,qliListTotal);  
        }
    } 
}