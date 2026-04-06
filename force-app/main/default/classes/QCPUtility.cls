/**
* @Description        : Class which has utility methods which are called from Apex Web Service related to QCP
* @Author             : Chirag L
* Ver       Date            Author                 Modification
* 1.0      03-14-2022       Chirag L               Intial Draft
**/
global class QCPUtility {    
    /**
* Method : setPriorNetTotal
* Parameters : quote Id
* Description :  This method is used to update value of prior net total field
*/
    global static void setPriorNetTotal( String quoteId) {
        List<SBQQ__QuoteLine__c> lstQuoteLineUpdate  = new List<SBQQ__QuoteLine__c>();
        List<Custom_Error_Log__c> lstCustomErrorLog = new List<Custom_Error_Log__c>();
        SBQQ__Quote__c quoteToUpdate = new SBQQ__Quote__c();
        try{
            List<SBQQ__QuoteLine__c> lstQLToUpdate = new List<SBQQ__QuoteLine__c>();
            //RWD -1158 
            List<SBQQ__QuoteLine__c> lstQuoteLines = [SELECT Id,SBQQ__Quote__r.Is_RWD_Polaris_Quote__c,SBQQSC__RenewedContractLine__r.SBQQSC__NetPrice__c, SBQQSC__RenewedContractLine__r.Calculated_List_Price__c, SBQQSC__RenewedContractLine__r.SBQQSC__Product__r.Name, SBQQSC__RenewedContractLine__c, SBQQ__ListPrice__c, SBQQSC__RenewedContractLine__r.Subscription_Term__c, SBQQSC__RenewedContractLine__r.Quantity, SBQQ__Product__r.name,SBQQ__NetTotal__c,Prior_Net_Total__c,SBQQ__SubscriptionTerm__c,Prior_Subscription_Term__c,Prior_Net_Total_Temp__c, SBQQ__Number__c,SBQQ__Quote__c, SBQQ__Product__c,SBQQ__NetPrice__c,SBQQ__Quote__r.SBQQ__SubscriptionTerm__c,Pricing_Use_Case__c,SBQQ__Product__r.Product_Level__c,SBQQ__PriorQuantity__c  FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quoteId];
            System.debug('List PRice = ' +lstQuoteLines[0].SBQQ__ListPrice__c);
            System.debug('Net Price = ' +lstQuoteLines[0].SBQQSC__RenewedContractLine__r.SBQQSC__NetPrice__c);
            System.debug('Quantity = ' +lstQuoteLines[0].SBQQSC__RenewedContractLine__r.Quantity);
            
            // RWD - 1059 - Start
            /*
Map<String, Double> mapQCPPricingMultiplier = new Map<String, Double>();
Map<String, Set<String>> mapNewProductVsListOfOldProduct = new Map<String, Set<String>>();

for (SKU_Pricing_Percent__mdt objSKUPricingPercent : [SELECT Product_Name__c,QCP_Pricing_Multiplier__c, Price_Split_Percent__c FROM SKU_Pricing_Percent__mdt]) {
mapQCPPricingMultiplier.put(objSKUPricingPercent.Product_Name__c, objSKUPricingPercent.QCP_Pricing_Multiplier__c);
}

for(SKU_Pricing_Products__mdt objSKUPricingProduct : [SELECT Old_Product__c, New_Product__c FROM SKU_Pricing_Products__mdt]) {
if (mapNewProductVsListOfOldProduct.containsKey(objSKUPricingProduct.New_Product__c)) {
mapNewProductVsListOfOldProduct.get(objSKUPricingProduct.New_Product__c).add(objSKUPricingProduct.Old_Product__c);
} else {
mapNewProductVsListOfOldProduct.put(objSKUPricingProduct.New_Product__c, new Set<String> {objSKUPricingProduct.Old_Product__c});
}
}
*/
            for (SBQQ__QuoteLine__c quoteLine : lstQuoteLines) {
                System.debug('Master Subscription term before Loading = ' +quoteLine.SBQQ__SubscriptionTerm__c);
                System.debug('Master Contract Line Subscription term before Loading = ' +quoteLine.SBQQSC__RenewedContractLine__r.Subscription_Term__c);
                System.debug('Net Price inside loop = ' +quoteLine.SBQQSC__RenewedContractLine__r.SBQQSC__NetPrice__c);
                System.debug('Quantity inside loop = ' +quoteLine.SBQQSC__RenewedContractLine__r.Quantity);
                //RWD-1265
                //quoteLine.SBQQ__ListPrice__c = null;
                //TODO: Set field marking this quote as a polaris conversion
                /*
if (quoteLine.SBQQ__Product__r.Product_Level__c == 'Hardware') {
quoteLine.SBQQ__Renewal__c = true;
quoteLine.SBQQ__Existing__c = true;
System.debug('Renewed Sub hardware = ' +quoteLine.SBQQSC__RenewedContractLine__r.Subscription_Term__c);
quoteLine.Prior_Subscription_Term__c = quoteLine.SBQQSC__RenewedContractLine__r.Subscription_Term__c;
System.debug('prior Sub hardware = ' +quoteLine.Prior_Subscription_Term__c);
} else {
if (quoteLine.SBQQSC__RenewedContractLine__c != null) {
quoteLine.SBQQ__PriorQuantity__c = quoteLine.SBQQSC__RenewedContractLine__r.Quantity;
system.debug('Renewed Sub else = ' +quoteLine.SBQQSC__RenewedContractLine__r.Subscription_Term__c);
quoteLine.Prior_Subscription_Term__c = quoteLine.SBQQSC__RenewedContractLine__r.Subscription_Term__c;
System.debug('prior Sub else = ' +quoteLine.Prior_Subscription_Term__c);
}
}
*/
                lstQLToUpdate.add(quoteLine);
                System.debug('Net Total = ' +quoteLine.SBQQ__NetTotal__c);
            }
            
            if (!lstQLToUpdate.isEmpty()) {
                SBQQ.TriggerControl.disable();
                QuoteTriggerHandler.byPassQuoteTriggerForPolarisSKURestructuring = true;
                SBQQ_QuoteLineTriggerHandler.byPassQLITriggerForPolarisSKURestructuring = true;
                update lstQLToUpdate;
                SBQQ.TriggerControl.enable();
            }
            
            /* Following code has been commented as pricing use case functionality is not required anymore as per RWD - 1059

for (SBQQ__QuoteLine__c quoteLine : lstQLToUpdate) {
if (quoteline.SBQQ__SubscriptionTerm__c != null && quoteLine.SBQQ__NetTotal__c != null && quoteLine.Prior_Subscription_Term__c != null) {
System.debug('In If of calculation');
switch on quoteLine.Pricing_Use_Case__c {
when 'Others'{
System.debug('In Others');
quoteLine.Prior_Net_Total__c = (quoteLine.SBQQ__NetTotal__c/quoteLine.Prior_Subscription_Term__c) * quoteline.SBQQ__SubscriptionTerm__c;
quoteLine.Prior_Net_Total_Temp__c = quoteLine.Prior_Net_Total__c;
System.debug('quoteLine.Prior_Net_Total__c in others ='+quoteLine.Prior_Net_Total__c);
}
when 'Annual LoD to New LoD' {
System.debug('In Annual LoD to New LoD');
if (quoteLine.SBQQ__Product__r.name.contains('RS-HW')) {

quoteLine.Prior_Net_Total__c = (quoteLine.SBQQ__NetTotal__c/quoteLine.Prior_Subscription_Term__c) * quoteline.SBQQ__SubscriptionTerm__c * 0.2;
quoteLine.Prior_Net_Total_Temp__c = quoteLine.Prior_Net_Total__c;
System.debug('quoteLine.Prior_Net_Total__c in ANnusl LOD if'+quoteLine.Prior_Net_Total__c);
}
else if (quoteLine.SBQQ__Product__r.name.contains('RS-SW')) {

quoteLine.Prior_Net_Total__c = (quoteLine.SBQQ__NetTotal__c/quoteLine.Prior_Subscription_Term__c) * quoteline.SBQQ__SubscriptionTerm__c * 0.8;
quoteLine.Prior_Net_Total_Temp__c = quoteLine.Prior_Net_Total__c;
System.debug('quoteLine.Prior_Net_Total__c in ANnusl LOD else'+quoteLine.Prior_Net_Total__c);
}
}
when 'Subpro to Hybrid 2.0' {
System.debug('In Subpro');

if (quoteLine.SBQQ__Product__r.Product_Level__c == 'Hybrid Software' || quoteLine.SBQQ__Product__r.Product_Level__c == 'LOD Software'){
quoteLine.Prior_Net_Total__c = (quoteLine.SBQQ__NetTotal__c/quoteLine.Prior_Subscription_Term__c)  * quoteline.SBQQ__SubscriptionTerm__c;
quoteLine.Prior_Net_Total_Temp__c = quoteLine.Prior_Net_Total__c;
} else {
quoteLine.Prior_Net_Total__c = 0;
quoteLine.Prior_Net_Total_Temp__c = quoteLine.Prior_Net_Total__c;
}
}
}
lstQuoteLineUpdate.add(quoteLine);
} else {
System.debug('In Else');
Custom_Error_Log__c customErrorLog = new Custom_Error_Log__c();
customErrorLog.Name = 'Error Log from QCPUtility';
if (quoteLine.SBQQ__NetTotal__c == null && quoteline.SBQQ__SubscriptionTerm__c == null) {
customErrorLog.Exception_Message__c = 'SBQQ__SubscriptionTerm__c and SBQQ__NetTotal__c values are null hence Prior_Net_Total__c and Prior_Net_Total_Temp__c are not computed';
} else if (quoteline.SBQQ__SubscriptionTerm__c == null) {
customErrorLog.Exception_Message__c = 'SBQQ__SubscriptionTerm__c value is null hence Prior_Net_Total__c and Prior_Net_Total_Temp__c are not computed';
} else if (quoteLine.SBQQ__NetTotal__c == null) {
customErrorLog.Exception_Message__c = 'SBQQ__NetTotal__c value is null hence Prior_Net_Total__c and Prior_Net_Total_Temp__c are not computed';
}
if (quoteLine.Prior_Subscription_Term__c == null) {
if (customErrorLog.Exception_Message__c == null) {
customErrorLog.Exception_Message__c = 'Prior_Subscription_Term__c is null hence Prior_Net_Total__c and Prior_Net_Total_Temp__c are not computed';
} else {
customErrorLog.Exception_Message__c = 'Prior_Subscription_Term__c, '+ customErrorLog.Exception_Message__c;
}
}
lstCustomErrorLog.add(customErrorLog);
}
}*/
            
            /*
//RWD - 1059 Start
for (SBQQ__QuoteLine__c quoteLine : lstQLToUpdate) {
//if (quoteline.SBQQ__SubscriptionTerm__c != null && quoteLine.SBQQ__NetTotal__c != null && quoteLine.Prior_Subscription_Term__c != null) {
if (quoteline.SBQQ__SubscriptionTerm__c != null && quoteLine.SBQQSC__RenewedContractLine__c != null  && quoteLine.SBQQSC__RenewedContractLine__r.SBQQSC__NetPrice__c != null && quoteLine.SBQQSC__RenewedContractLine__r.Quantity != null && quoteLine.Prior_Subscription_Term__c != null) { // RWD - 1158
//System.debug('SC terms Not Null ' + quoteline.SBQQ__ProductName__c);
if (
mapNewProductVsListOfOldProduct.containsKey(quoteLine.SBQQ__Product__r.Name) &&
mapNewProductVsListOfOldProduct.get(quoteLine.SBQQ__Product__r.Name).contains(quoteLine.SBQQSC__RenewedContractLine__r.SBQQSC__Product__r.Name)
) {
//quoteLine.Prior_Net_Total__c = (quoteLine.SBQQ__NetTotal__c / quoteLine.Prior_Subscription_Term__c) * (quoteline.SBQQ__SubscriptionTerm__c) * (mapQCPPricingMultiplier.get(quoteLine.SBQQ__Product__r.name));
quoteLine.Prior_Net_Total__c = (((quoteLine.SBQQSC__RenewedContractLine__r.SBQQSC__NetPrice__c) * (quoteLine.SBQQSC__RenewedContractLine__r.Quantity )) / quoteLine.Prior_Subscription_Term__c) * (quoteline.SBQQ__SubscriptionTerm__c) * (mapQCPPricingMultiplier.get(quoteLine.SBQQ__Product__r.name)); // RWD - 1158
System.debug('Prior Net total for new LOD = ' +quoteLine.Prior_Net_Total__c + 'NetPrice ' + quoteLine.SBQQSC__RenewedContractLine__r.SBQQSC__NetPrice__c);
} else {
//quoteLine.Prior_Net_Total__c = (quoteLine.SBQQ__NetTotal__c / quoteLine.Prior_Subscription_Term__c) * (quoteline.SBQQ__SubscriptionTerm__c);
quoteLine.Prior_Net_Total__c = (((quoteLine.SBQQSC__RenewedContractLine__r.SBQQSC__NetPrice__c) * (quoteLine.SBQQSC__RenewedContractLine__r.Quantity )) / quoteLine.Prior_Subscription_Term__c) * (quoteline.SBQQ__SubscriptionTerm__c); // RWD - 1158
System.debug('Prior Net total for old = ' +quoteLine.Prior_Net_Total__c + 'NetPrice ' + quoteLine.SBQQSC__RenewedContractLine__r.SBQQSC__NetPrice__c);
}
quoteLine.Prior_Net_Total_Temp__c = quoteLine.Prior_Net_Total__c;
System.debug('Prior Net Temp = ' +quoteLine.Prior_Net_Total_Temp__c); 
lstQuoteLineUpdate.add(quoteLine);
} else {
Custom_Error_Log__c customErrorLog = new Custom_Error_Log__c();
customErrorLog.Name = 'Error Log from QCPUtility';
if (quoteLine.SBQQ__NetTotal__c == null && quoteline.SBQQ__SubscriptionTerm__c == null) {
customErrorLog.Exception_Message__c = 'SBQQ__SubscriptionTerm__c and SBQQ__NetTotal__c values are null hence Prior_Net_Total__c and Prior_Net_Total_Temp__c are not computed';
} else if (quoteline.SBQQ__SubscriptionTerm__c == null) {
customErrorLog.Exception_Message__c = 'SBQQ__SubscriptionTerm__c value is null hence Prior_Net_Total__c and Prior_Net_Total_Temp__c are not computed';
} else if (quoteLine.SBQQ__NetTotal__c == null) {
customErrorLog.Exception_Message__c = 'SBQQ__NetTotal__c value is null hence Prior_Net_Total__c and Prior_Net_Total_Temp__c are not computed';
}
if (quoteLine.Prior_Subscription_Term__c == null) {
if (customErrorLog.Exception_Message__c == null) {
customErrorLog.Exception_Message__c = 'Prior_Subscription_Term__c is null hence Prior_Net_Total__c and Prior_Net_Total_Temp__c are not computed';
} else {
customErrorLog.Exception_Message__c = 'Prior_Subscription_Term__c, '+ customErrorLog.Exception_Message__c;
}
}
lstCustomErrorLog.add(customErrorLog);
}
}

//RWD - 1059 End

SBQQ.TriggerControl.disable();
QuoteTriggerHandler.byPassQuoteTriggerForPolarisSKURestructuring = true;
SBQQ_QuoteLineTriggerHandler.byPassQLITriggerForPolarisSKURestructuring = true;
update lstQuoteLineUpdate;
SBQQ.TriggerControl.enable();
List<SBQQ__QuoteLine__c> ListupdatedLine = [SELECT Id, SBQQSC__RenewedContractLine__r.Subscription_Term__c, SBQQ__Product__r.Product_Level__c , SBQQSC__RenewedContractLine__c, SBQQSC__RenewedContractLine__r.Quantity, SBQQ__NetTotal__c,SBQQ__Quote__r.Prior_Deal_Value__c, Discount_Margin__c, SBQQ__PriorQuantity__c, Prior_Net_Total__c, Prior_Net_Total_Temp__c  FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quoteId];
for (SBQQ__QuoteLine__c updatedLine : ListupdatedLine) {
System.debug('Prior Deal in Prior Method = ' +updatedLine.SBQQ__Quote__r.Prior_Deal_Value__c);
System.debug('Prior_Net_Total__c = ' + updatedLine.Prior_Net_Total__c);
System.debug('Prior_Net_Total_Temp__c = ' + updatedLine.Prior_Net_Total_Temp__c);
}
// FORCING A CALCULATION 
*/          
            // RWD-1143 BEGINS
            system.debug('quoteId:'+quoteId);
            quoteToUpdate = [SELECT Id, Prior_Deal_Value__c, CalculatedCount__c, Polaris_Conversion_In_Progress__c, Margin__c, Consolidate_Lines__c, Force_Recalculation__c, Polaris_Conversion__c, Old_Polaris_Conversion__c,
                             (SELECT Id, Quote_Line_Type__c, Net_Total__c FROM SBQQ__LineItems__r WHERE Quote_Line_Type__c = 'Renewal' AND (Net_Total__c = null OR Net_Total__c = '' OR Net_Total__c = '$0.00')) FROM SBQQ__Quote__c 
                             WHERE Id =: quoteId LIMIT 1];
            System.debug('quoteToUpdate.Prior_Deal_Value__c = ' + quoteToUpdate.Prior_Deal_Value__c);
            System.debug('quoteToUpdate.SBQQ__LineItems__r.size() = ' + quoteToUpdate.SBQQ__LineItems__r.size());
            System.debug('quoteToUpdate.size() = ' + quoteToUpdate);
            quoteToUpdate.Polaris_Conversion__c = true;
            quoteToUpdate.Old_Polaris_Conversion__c = true;
            System.debug('quoteToUpdate.Polaris_Conversion__c= ' + quoteToUpdate.Polaris_Conversion__c);
            system.debug('quoteToUpdate.CalculatedCount__c'+quoteToUpdate.CalculatedCount__c);
            system.debug('quoteToUpdate.SBQQ__LineItems__r.size()'+quoteToUpdate.SBQQ__LineItems__r.size());
            if((quoteToUpdate.Prior_Deal_Value__c == null || quoteToUpdate.SBQQ__LineItems__r.size() > 0 || quoteToUpdate.Margin__c == null || quoteToUpdate.Margin__c == 0)  && (quoteToUpdate.CalculatedCount__c == null || quoteToUpdate.CalculatedCount__c <= 5)) {
                system.debug('---inside update IF---');
                if(quoteToUpdate.CalculatedCount__c == null) {
                    quoteToUpdate.CalculatedCount__c = 0;
                }
                quoteToUpdate.CalculatedCount__c = quoteToUpdate.CalculatedCount__c + 1;
                
                System.debug('Prior Deal in forceRecalc = ' + quoteToUpdate.Prior_Deal_Value__c);
                if (quoteToUpdate.Force_Recalculation__c ) {
                    quoteToUpdate.Force_Recalculation__c = false;
                } else {
                    quoteToUpdate.Force_Recalculation__c = true;
                }
                
                // RWD-1213 STARTS
                if (quoteToUpdate.Consolidate_Lines__c ) {
                    quoteToUpdate.Consolidate_Lines__c = false;
                } else {
                    quoteToUpdate.Consolidate_Lines__c = true;
                }
                // RWD-1213 ENDS
                
                update quoteToUpdate;
            }
            //update quoteToUpdate;
            // RWD-1143 ENDS 
            
            
        } catch(Exception exceptionMessage){
            system.debug('');
            Custom_Error_Log__c customErrorLog = new Custom_Error_Log__c();
            customErrorLog.Name = 'Error Log from QCPUtility';
            customErrorLog.Exception_Message__c = 'An exception occurred: ' + exceptionMessage.getMessage()+exceptionMessage.getLineNumber();
            lstCustomErrorLog.add(customErrorLog);
        } finally {
            if(!lstCustomErrorLog.isEmpty()) {
                insert lstCustomErrorLog;
            }
            
            system.debug('before the event call *********');
            if(quoteToUpdate.Margin__c != null && quoteToUpdate.Polaris_Conversion_In_Progress__c == true){
                // List to hold event objects to be published.
                List<QuoteUpdate__e> newsEventList = new List<QuoteUpdate__e>();
                // Create event objects.
                QuoteUpdate__e newsEvent1 = new QuoteUpdate__e(
                    QuoteId__c = quoteToUpdate.id,
                    Polaris_Conversion_In_Progress__c = false);
                // Add event objects to the list.
                newsEventList.add(newsEvent1);
                system.debug('newEventList ' + newsEventList);
                // Call method to publish events.
                List<Database.SaveResult> results = EventBus.publish(newsEventList);
                // Inspect publishing result for each event
                for (Database.SaveResult sr : results) {
                    if (sr.isSuccess()) {
                        System.debug('Successfully published event.************');
                    } else {
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('Error returned: *************' +
                                         err.getStatusCode() +
                                         ' - ' +
                                         err.getMessage());
                        }
                    }
                }
            }
        }
    }
    
    @future
    global static void updateQuotePolarisConversationComplete(List<ID> recordIds)
    {   
        // Get those records based on the IDs
        System.debug('recordIds 282 ' + recordIds);
        List<SBQQ__Quote__c> updateQuotes = New List<SBQQ__Quote__c>();
        //List<SBQQ__Quote__c> quotes = [SELECT Id, Name, Polaris_Conversion_In_Progress__c FROM SBQQ__Quote__c WHERE Id IN :recordIds];
        //if(!quotes.isEmpty()){
        for(SBQQ__Quote__c lp :  [SELECT Id, Name, Polaris_Conversion_In_Progress__c FROM SBQQ__Quote__c WHERE Id IN :recordIds]){
            lp.Polaris_Conversion_In_Progress__c = false;
            updateQuotes.add(lp);
        }
        system.debug('>>updateQuotes'+updateQuotes);
        //RWD-1573
        SBQQ.TriggerControl.disable();
        QuoteTriggerHandler.byPassQuoteTriggerForPolarisSKURestructuring = true;
        if(!updateQuotes.isEmpty()){
            update updateQuotes;
        }
        SBQQ.TriggerControl.enable();
        //}
        
    }
    
    /**
* Method : setDiscountMarginPercentChange
* Parameters : quote Id
* Description :  This method is used to update value of Discount Margin field
*/
    global static void setDiscountMarginPercentChange(String quoteId) {
        List<SBQQ__QuoteLine__c> lstQuoteLineUpdate  = new List<SBQQ__QuoteLine__c>();
        List<Custom_Error_Log__c> lstCustomErrorLog = new List<Custom_Error_Log__c>();
        try {
            List<SBQQ__QuoteLine__c> lstQLToUpdate = new List<SBQQ__QuoteLine__c>();
            List<SBQQ__QuoteLine__c> lstQuoteLines = [SELECT Id, SBQQSC__RenewedContractLine__r.Subscription_Term__c, Prior_Subscription_Term__c, SBQQ__Product__r.Product_Level__c , SBQQSC__RenewedContractLine__c, SBQQSC__RenewedContractLine__r.Quantity, SBQQ__NetTotal__c,SBQQ__Quote__r.Prior_Deal_Value__c, Discount_Margin__c, SBQQ__PriorQuantity__c, Prior_Net_Total__c  FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quoteId];
            for (SBQQ__QuoteLine__c quoteLine : lstQuoteLines) {
                System.debug('Discount Method');
                if (quoteLine.SBQQ__Product__r.Product_Level__c == 'Hardware') {
                    //quoteLine.SBQQ__Renewal__c = true;
                    quoteLine.SBQQ__Existing__c = true;
                    System.debug('Renewed Sub Hardware = ' +quoteLine.SBQQSC__RenewedContractLine__r.Subscription_Term__c);
                    quoteLine.Prior_Subscription_Term__c = quoteLine.SBQQSC__RenewedContractLine__r.Subscription_Term__c;
                    System.debug('prior Sub hardware = ' +quoteLine.Prior_Subscription_Term__c);
                } else {
                    if (quoteLine.SBQQSC__RenewedContractLine__c != null) {
                        quoteLine.SBQQ__PriorQuantity__c = quoteLine.SBQQSC__RenewedContractLine__r.Quantity;
                        System.debug('Renewed Sub else disc = ' +quoteLine.SBQQSC__RenewedContractLine__r.Subscription_Term__c);
                        quoteLine.Prior_Subscription_Term__c = quoteLine.SBQQSC__RenewedContractLine__r.Subscription_Term__c;
                        System.debug('prior Sub else disc = ' +quoteLine.Prior_Subscription_Term__c);
                    }
                }
                lstQLToUpdate.add(quoteLine);
            }
            
            if (!lstQLToUpdate.isEmpty()) {
                SBQQ.TriggerControl.disable();
                QuoteTriggerHandler.byPassQuoteTriggerForPolarisSKURestructuring = true;
                SBQQ_QuoteLineTriggerHandler.byPassQLITriggerForPolarisSKURestructuring = true;
                update lstQLToUpdate;
                SBQQ.TriggerControl.enable();
            }
            
            for (SBQQ__QuoteLine__c quoteLine : lstQLToUpdate) {
                System.debug('SubTerm = ' +quoteLine.Prior_Subscription_Term__c);
                
                if (quoteLine.SBQQ__NetTotal__c != null && quoteline.Prior_Net_Total__c != null && quoteline.Prior_Net_Total__c != 0) {
                    quoteLine.Discount_Margin__c = (quoteLine.SBQQ__NetTotal__c- quoteline.Prior_Net_Total__c) / quoteline.Prior_Net_Total__c;
                    lstQuoteLineUpdate.add(quoteLine);
                }
                else {
                    Custom_Error_Log__c customErrorLog = new Custom_Error_Log__c();
                    customErrorLog.Name = 'Error Log from QCPUtility';
                    if (quoteLine.SBQQ__NetTotal__c == null && (quoteline.Prior_Net_Total__c == null || quoteline.Prior_Net_Total__c == 0)) {
                        customErrorLog.Exception_Message__c = 'SBQQ__NetTotal__c , Prior_Net_Total__c values are not present hence Discount_Margin__c is not Computed';
                    } else if (quoteline.Prior_Net_Total__c == null) {
                        customErrorLog.Exception_Message__c = 'Prior_Net_Total__c value is null hence Discount_Margin__c is not Computed';
                    } else if (quoteline.Prior_Net_Total__c == 0) {
                        customErrorLog.Exception_Message__c = 'Prior_Net_Total__c value is 0 hence Discount_Margin__c is not Computed';
                    } else if (quoteLine.SBQQ__NetTotal__c == null) {
                        customErrorLog.Exception_Message__c = 'SBQQ__NetTotal__c value is null hence Discount_Margin__c is not Computed';
                    }
                    lstCustomErrorLog.add(customErrorLog);
                }
                SBQQ.TriggerControl.disable();
                QuoteTriggerHandler.byPassQuoteTriggerForPolarisSKURestructuring = true;
                SBQQ_QuoteLineTriggerHandler.byPassQLITriggerForPolarisSKURestructuring = true;
                update lstQuoteLineUpdate;
                SBQQ.TriggerControl.enable();
            }
        } catch(Exception exceptionMessage){
            Custom_Error_Log__c customErrorLog = new Custom_Error_Log__c();
            customErrorLog.Name = 'Error Log from QCPUtility';
            customErrorLog.Exception_Message__c = 'An exception occurred: ' + exceptionMessage.getMessage()+exceptionMessage.getLineNumber();
            lstCustomErrorLog.add(customErrorLog);
        } finally {
            if(!lstCustomErrorLog.isEmpty()) {
                insert lstCustomErrorLog;
            }
        }
    }       
    
    global static void updateSubscriptionTerm(List<String> lstQuoteLineIds, List<Date> lstStartDates, List<Date> lstEndDates) {
        List<SBQQ__QuoteLine__c> quoteLineToUpdateList = new List<SBQQ__QuoteLine__c>();
        List<Custom_Error_Log__c> lstCustomErrorLog = new List<Custom_Error_Log__c>();
        try {
            System.debug('RICKY lstQuoteLineIds='+lstQuoteLineIds);
            System.debug('RICKY lstStartDates='+lstStartDates);
            System.debug('RICKY lstEndDates='+lstEndDates);
            for (Integer index = 0; index < lstQuoteLineIds.size(); index++) {
                if (lstStartDates[index] != null && lstEndDates[index] != null) {
                    quoteLineToUpdateList.add(
                        new SBQQ__QuoteLine__c(
                            Id = lstQuoteLineIds[index],
                            SBQQ__SubscriptionTerm__c = Integer.valueOf(lstStartDates[index].monthsBetween(lstEndDates[index]))
                        )                        
                    );
                    System.debug('SUBCRIPTION = '+quoteLineToUpdateList[0].SBQQ__SubscriptionTerm__c);
                } else {
                    Custom_Error_Log__c customErrorLog = new Custom_Error_Log__c();
                    customErrorLog.Name = 'Error Log from QCPUtility';
                    if (lstStartDates[index] == null && lstEndDates[index] == null) {
                        customErrorLog.Exception_Message__c = 'Start Date  and End Date values are null hence SBQQ__SubscriptionTerm__c is not Computed';
                    } else if (lstEndDates[index] == null) {
                        customErrorLog.Exception_Message__c = 'End Date value is null hence  SBQQ__SubscriptionTerm__c is not Computed';
                    } else if (lstStartDates[index] == null) {
                        customErrorLog.Exception_Message__c = 'Start Date value is null hence  SBQQ__SubscriptionTerm__c is not Computed';
                    }
                    lstCustomErrorLog.add(customErrorLog);
                }
            }
            SBQQ.TriggerControl.disable();
            QuoteTriggerHandler.byPassQuoteTriggerForPolarisSKURestructuring = true;
            SBQQ_QuoteLineTriggerHandler.byPassQLITriggerForPolarisSKURestructuring = true;
            update quoteLineToUpdateList;
            SBQQ.TriggerControl.enable();
        } catch (Exception exceptionMessage) {
            Custom_Error_Log__c customErrorLog = new Custom_Error_Log__c();
            customErrorLog.Name = 'QCPUtility';
            customErrorLog.Exception_Message__c = 'An exception occurred: ' + exceptionMessage.getMessage()+exceptionMessage.getLineNumber();
            lstCustomErrorLog.add(customErrorLog);
        } finally {
            if(!lstCustomErrorLog.isEmpty()) {
                insert lstCustomErrorLog;
            }
        }
    }
}