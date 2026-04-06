public without sharing class PaymentScheduleCtrl {
    public PaymentScheduleCtrl() {
        
    }
    @AuraEnabled
    public static List<QuoteLineWrapper> getRelatedQuoteLines(String recordId){
        try {
            Set<Id> setQuoteLineIds = new Set<Id>();
            Boolean bUpdateStatus;
            Map<Id, List<Payment_Schedule__c>> quoteLinetoPaymentSchedules = new Map<Id, List<Payment_Schedule__c>>();
            List<SBQQ__QuoteLine__c> lstQuoteLines = [Select Id, Name, Payment_Options__c, SBQQ__SubscriptionTerm__c, SBQQ__Quantity__c, SBQQ__Quote__r.Name, 
                                                      SBQQ__ListPrice__c, SBQQ__TotalDiscountRate__c, SBQQ__NetTotal__c, SBQQ__Quote__c, SBQQ__Product__r.Name , SBQQ__Quote__r.Id, SBQQ__Quote__r.SBQQ__Status__c, SBQQ__Quote__r.SBQQ__NetAmount__c
                                                      From SBQQ__QuoteLine__c Where SBQQ__Quote__c =: recordId AND SBQQ__NetTotal__c!=0 AND SBQQ__Optional__c=:FALSE];
            List<QuoteLineWrapper> lstQuoteLineWrapper = new List<QuoteLineWrapper>();
            if(!lstQuoteLines.isEmpty()){
                for(SBQQ__QuoteLine__c oQuoteLine : lstQuoteLines){
                    setQuoteLineIds.add(oQuoteLine.Id);
                }
                
                if(!setQuoteLineIds.isEmpty()){
                    List<Payment_Schedule__c> lstPaymentSchedule = [Select Id, Name, Monthly_Amount__c,Term__c, Quote_Line__c,Payment__c,Override_Amount__c,Payment_Option__c,Type__c,Status__c,Number_of_Invoices__c From Payment_Schedule__c Where Quote_Line__c In:setQuoteLineIds];
                    //AND Type__c != 'Header' ORDER BY Payment_Index__c ASC];
                    bUpdateStatus =  getApprovedStatus(lstPaymentSchedule);
                    if(!lstPaymentSchedule.isEmpty()){
                        for(Payment_Schedule__c oPaymentSchedule : lstPaymentSchedule){
                            if(!oPaymentSchedule?.Type__c.equalsIgnoreCase('Header')){
                                if(!quoteLinetoPaymentSchedules.containsKey(oPaymentSchedule.Quote_Line__c)){
                                    quoteLinetoPaymentSchedules.put(oPaymentSchedule.Quote_Line__c, new List<Payment_Schedule__c> {oPaymentSchedule});
                                }else{
                                    quoteLinetoPaymentSchedules.get(oPaymentSchedule.Quote_Line__c).add(oPaymentSchedule);
                                }
                            }
                        }
                    }
                }
                for(SBQQ__QuoteLine__c oQuoteLine : lstQuoteLines){
                    QuoteLineWrapper oWrapper = new QuoteLineWrapper();
                    oWrapper.quoteLine = oQuoteLine;
                    oWrapper.bUpdateStatus = bUpdateStatus;
                    oWrapper.netTotal = oQuoteLine!=null ? oQuoteLine.SBQQ__Quote__r.SBQQ__NetAmount__c : 0;
                    oWrapper.dMonthlyPayment = oQuoteLine.SBQQ__NetTotal__c != null && oQuoteLine.SBQQ__SubscriptionTerm__c != null ? (oQuoteLine.SBQQ__NetTotal__c/oQuoteLine.SBQQ__SubscriptionTerm__c).setScale(2) : 0;
                    oWrapper.dPerMthperQty = oQuoteLine.SBQQ__NetTotal__c != null && oQuoteLine.SBQQ__SubscriptionTerm__c != null ? (oQuoteLine.SBQQ__NetTotal__c/oQuoteLine.SBQQ__SubscriptionTerm__c)/oQuoteLine.SBQQ__Quantity__c : 0;
                    if(oQuoteLine.Payment_Options__c != null && oQuoteLine.Payment_Options__c.equalsIgnoreCase('Annual')){
                        if(oQuoteLine?.SBQQ__SubscriptionTerm__c != null){
                            oWrapper.numberOfPayments =  Math.Round(oQuoteLine?.SBQQ__SubscriptionTerm__c/12);
                        }
                    }
                    if(oQuoteLine.Payment_Options__c != null && oQuoteLine.Payment_Options__c.equalsIgnoreCase('Quarterly')){
                        if(oQuoteLine?.SBQQ__SubscriptionTerm__c != null){
                            oWrapper.numberOfPayments =  Math.Round(oQuoteLine?.SBQQ__SubscriptionTerm__c/3);
                        }
                    }
                    if(oQuoteLine.Payment_Options__c != null && oQuoteLine.Payment_Options__c.equalsIgnoreCase('Monthly')){
                        if(oQuoteLine?.SBQQ__SubscriptionTerm__c != null){
                            oWrapper.numberOfPayments =  Math.Round(oQuoteLine?.SBQQ__SubscriptionTerm__c/1);
                        }
                    }
                    oWrapper.lstPaymentSchedule = quoteLinetoPaymentSchedules != null ? quoteLinetoPaymentSchedules.get(oQuoteLine.Id) : null;
                    lstQuoteLineWrapper.add(oWrapper);
                }
            }
            return lstQuoteLineWrapper;
        } catch (Exception e) {
            system.debug('Error Occured ' + e.getMessage() +'>>>'+ e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    
    public static Boolean getApprovedStatus(List<Payment_Schedule__c> lstPaymentSchedules){
        //List<Payment_Schedule__c> lstPaymentSchedule = [Select Id,Status__c From Payment_Schedule__c Where Quote_Line__c In:setQuoteLineIds AND Type__c = 'Header'];
        if(!lstPaymentSchedules.isEmpty() && lstPaymentSchedules != null){
            for( Payment_Schedule__c oPaymentSchedule : lstPaymentSchedules){
                if(oPaymentSchedule?.Status__c == 'Approved' && oPaymentSchedule?.Type__c?.equalsIgnoreCase('Header')){
                    return true;
                } 
            }
        }
        return false;
    }
    public class QuoteLineWrapper{
        @AuraEnabled
        public SBQQ__QuoteLine__c quoteLine{get;set;}
        @AuraEnabled
        public Decimal netTotal{get;set;}
        @AuraEnabled
        public Decimal dMonthlyPayment{get;set;}
        @AuraEnabled
        public Decimal dPerMthperQty{get;set;}
        @AuraEnabled
        public integer numberOfPayments{get;set;}
        @AuraEnabled
        public List<Payment_Schedule__c> lstPaymentSchedule{get;set;}
        @AuraEnabled
        public Boolean bUpdateStatus{get;set;}
    }
    @AuraEnabled
    public static Map<String,Object> createPayment(String recordId,Integer invoiceNumber ,String payment){
        Map<String,Object>mapOutputParams = new Map<String,Object>();
        try {
            if (invoiceNumber == null) {
                mapOutputParams.put('bSuccess',false);
                mapOutputParams.put('errMessage','Invoice number cannot be blank');         
                return mapOutputParams;
            }
            if (invoiceNumber <= 0) {
                mapOutputParams.put('bSuccess',false);
                mapOutputParams.put('errMessage','Invoice number cannot be zero');         
                return mapOutputParams;
            }
            
            Set<Id> setQuoteLineIds = new Set<Id>();
            //Fetch the quoteLines
            List<SBQQ__QuoteLine__c> lstQuoteLines = [Select Id, SBQQ__ListPrice__c, SBQQ__SubscriptionTerm__c, SBQQ__Quantity__c, SBQQ__TotalDiscountRate__c, SBQQ__NetTotal__c, SBQQ__Product__c, SBQQ__Quote__c  From SBQQ__QuoteLine__c Where SBQQ__Quote__c =: recordId AND SBQQ__Optional__c=:FALSE]; 
            if(!lstQuoteLines.isEmpty()){
                for(SBQQ__QuoteLine__c oQuoteLine : lstQuoteLines){
                    setQuoteLineIds.add(oQuoteLine.Id);
                }
                if(!setQuoteLineIds.isEmpty()){
                    List<Payment_Schedule__c> lstPaymentSchedule = [Select Id From Payment_Schedule__c Where Quote_Line__c In:setQuoteLineIds];
                    if(!lstPaymentSchedule.isEmpty()){
                        delete lstPaymentSchedule;
                    }
                }   
                //Insert new payment schedules
                insertPaymentSchedules(lstQuoteLines,invoiceNumber,payment); 
                mapOutputParams.put('bSuccess',true);
            }
        } catch (Exception e) {
            String sTemp = e.getMessage();
            mapOutputParams.put('bSuccess',false);
            mapOutputParams.put('errMessage',sTemp != null && sTemp.length() > 255 ? sTemp.substring(0, 255) : sTemp);           
        }
        return mapOutputParams;  
    }
    @AuraEnabled
    public static Map<String,Object> updatePaymentAmount(String jsonString , String sOverrideAmount ,String sMonthlyValue){
        
        Map<String,Object>mapOutputParams = new Map<String,Object>();
        try {
            system.Debug(jsonString);
            Set<Id>paymentIds = new Set<Id>();
            List<Payment_Schedule__c> lstPaymentSchedule = new List<Payment_Schedule__c>();
            
            if (jsonString == null) {
                mapOutputParams.put('bSuccess',false);
                mapOutputParams.put('errMessage','Amount cannot be blank');         
                return mapOutputParams;
            }
            Map<String, Object> qouteLineAndPaymentSchedules = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
            Map<String,Object> paymentSchedulesAndOverrideAmount = (Map<String, Object>) JSON.deserializeUntyped(sOverrideAmount);
            Map<String,Object>monthlyAmountAndPaymentSchedules = (Map<String, Object>) JSON.deserializeUntyped(sMonthlyValue);
            
            for (String key : qouteLineAndPaymentSchedules.keySet()) {
                paymentIds.add(key);
            }
            for (String key : paymentSchedulesAndOverrideAmount.keySet()) {
                paymentIds.add(key);
            }
            
            List<Payment_Schedule__c>lstPaymentSchedules = new List<Payment_Schedule__c>([Select Id ,Payment__c,Monthly_Amount__c,Term__c,Quote_Line__r.SBQQ__NetTotal__c,Quote_Line__r.SBQQ__SubscriptionTerm__c from Payment_Schedule__c where Id In :paymentIds]);
            
            for (Payment_Schedule__c oPayment : lstPaymentSchedules) {
                
                if(qouteLineAndPaymentSchedules.containsKey(oPayment.Id)){
                    system.debug(qouteLineAndPaymentSchedules.get(oPayment.Id));
                    oPayment.Term__c = (Decimal)qouteLineAndPaymentSchedules.get(oPayment.Id);
                    
                    system.debug(monthlyAmountAndPaymentSchedules.get(oPayment.Id));
                    oPayment.Payment__c = (Decimal)monthlyAmountAndPaymentSchedules.get(oPayment.Id);
                }
                if(paymentSchedulesAndOverrideAmount.containsKey(oPayment.Id)){
                    oPayment.Override_Amount__c = (Decimal)paymentSchedulesAndOverrideAmount.get(oPayment.Id);
                }
                lstPaymentSchedule.add(oPayment);
                
                
                
            }
            if(!lstPaymentSchedule.isEmpty()){
                
                update lstPaymentSchedule;
                // here bSucess is just another boolean identifier which is created to identify if the transaction was sucessfull on client side.
                mapOutputParams.put('bSuccess',true);  
                mapOutputParams.put('errMessage','Amount Updated Successfully');  
            }else{
                mapOutputParams.put('bSuccess',false);  
                mapOutputParams.put('errMessage','No Payment Schedule Found To Update');  
            }
            
            
        }
        catch (Exception e) {
            system.debug(e.getMessage()+e.getLineNumber());
            String sTemp = e.getMessage();
            mapOutputParams.put('bSuccess',false);
            mapOutputParams.put('errMessage',sTemp != null && sTemp.length() > 255 ? sTemp.substring(0, 255) : sTemp);           
        }
        return mapOutputParams;  
    }
    
    
    @AuraEnabled
    public static Boolean updateStatus(List<Id>lstQouteLineId , String status){
        
        List<Payment_Schedule__c> lstPaymentSchedule = [Select Id From Payment_Schedule__c Where Quote_Line__c In:lstQouteLineId AND Type__c = 'Header'];
        List<Payment_Schedule__c> schedulesToUpdate = new List<Payment_Schedule__c>();            
        for (Payment_Schedule__c oPaymentSchedule : lstPaymentSchedule) {
            Payment_Schedule__c schedule = new Payment_Schedule__c(
                Id = oPaymentSchedule.Id,
                Status__c = status
            );
            
            // Add to the list of records to update
            schedulesToUpdate.add(schedule);
        }
        
        // Update the Payment_Schedule__c records in the database
        if (!schedulesToUpdate.isEmpty()) {
            try {
                update schedulesToUpdate;
            } catch (DmlException e) {
                // Handle exceptions
                System.debug('Error updating payment schedules: ' + e.getMessage());
                return false;
            }
        }
        return true;
    }
    
    public static void insertPaymentSchedules(List<SBQQ__QuoteLine__c> lstQuoteLines, Integer invoiceNumber ,String payment) {
        
        List<Payment_Schedule__c> lstPaymentSchedule = new List<Payment_Schedule__c>();
        Map<Id, Payment_Schedule__c> headerMap = new Map<Id, Payment_Schedule__c>(); 
        
        for (SBQQ__QuoteLine__c quoteLine : lstQuoteLines) {
            if (quoteLine.SBQQ__NetTotal__c == null || quoteLine.SBQQ__Quantity__c == null) {
                continue;
            }
            
            // Determine the number of schedules based on SubscriptionTerm or a default value
            Integer scheduleCount = invoiceNumber ;
            
            // Create Header Payment Schedule
            Payment_Schedule__c headerSchedule = new Payment_Schedule__c(
                Quote_Line__c = quoteLine.Id,
                Type__c = 'Header',
                Product__c = quoteLine.SBQQ__Product__c,
                Quote_Number__c = quoteLine.SBQQ__Quote__c,
                Quantity__c = String.valueOf(quoteLine.SBQQ__Quantity__c),
                Unit_List__c = quoteLine.SBQQ__ListPrice__c,
                Discount__c = quoteLine.SBQQ__TotalDiscountRate__c,
                Net_Total__c = quoteLine.SBQQ__NetTotal__c,
                Payment_Option__c = payment
                
            );
            lstPaymentSchedule.add(headerSchedule);
            headerMap.put(quoteLine.Id, headerSchedule); // Add header to map
            
            // Create Line Payment Schedules (parent assignment to be handled after insert)
            for (Integer i = 0; i < scheduleCount; i++) {
                lstPaymentSchedule.add(new Payment_Schedule__c(
                    payment__c = 0,
                    Override_Amount__c = 0,
                    Quote_Line__c = quoteLine.Id,
                    Payment_Option__c = payment,
                    Number_of_Invoices__c = String.valueOf(invoiceNumber),
                    Type__c = 'Line',
                    Product__c = quoteLine.SBQQ__Product__c,
                    Quote_Number__c = quoteLine.SBQQ__Quote__c,
                    Payment_Index__c = i+1
                ));
            }
        }
        
        if (!lstPaymentSchedule.isEmpty()) {
            insert lstPaymentSchedule;
            
            // Update line schedules with the correct Parent__c values
            List<Payment_Schedule__c> lineSchedulesToUpdate = new List<Payment_Schedule__c>();
            for (Payment_Schedule__c schedule : lstPaymentSchedule) {
                if (schedule.Type__c == 'Line') {
                    Payment_Schedule__c headerSchedule = headerMap.get(schedule.Quote_Line__c);
                    if (headerSchedule != null) {
                        schedule.Parent__c = headerSchedule.Id; 
                        lineSchedulesToUpdate.add(schedule);
                    }
                }
            }
            
            if (!lineSchedulesToUpdate.isEmpty()) {
                update lineSchedulesToUpdate;
            }
        }
    }
    
}