/**
* @File Name : QuoteTriggerHelperForEmail.cls
* @description :This class is used to send Proactive Deal Governance Notice.
* @Author :Shivani
* @Last Modified By :
* @Last Modified On : June 17, 2025
* @Modification Log :
* Test Class        :QuoteTriggerHelperForEmailTest
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | June 17, 2025 |   | Initial Version
**/
public without sharing class QuoteTriggerHelperForEmail {
  /***********************************************************************************************************
      * Method Name          : sendProactiveDealGovernanceNotice
      * Date Created/Modified: 10/06/2025
      * Author               : Shivani
      * @description         : Send Proactive Deal Governance Notice. This method is created as part of FY25SR-1112
      * @param newMap
      * @param oldMap
    /**********************************************************************************************************/
    public static void sendProactiveDealGovernanceNotice(Map<Id,SBQQ__Quote__c> newMap,Map<Id,SBQQ__Quote__c> oldMap){
        //FY25SR-2304 start (moved queries to async method)
        Set<Id> accountIds = new Set<Id>(); 
        Set<Id> eligibleQuotes = new Set<Id>();

        //FY25SR-2304 check conditions before logic
        for(Id quoteId : newMap.keySet()){
            SBQQ__Quote__c quote = newMap.get(quoteId);
            if (quote != null && (quote.SBQQ__Primary__c  &&
                quote.ApprovalStatus__c!= null && quote.ApprovalStatus__c == 'Approved' &&
                (  oldMap != null && oldMap.get(quoteId) != null && 
                   ( oldMap.get(quoteId).SBQQ__Primary__c != quote.SBQQ__Primary__c 
                    || oldMap.get(quoteId).ApprovalStatus__c  != quote.ApprovalStatus__c )
                ) && quote.Renewal_Ops_Reviewed__c == false)){
                    eligibleQuotes.add(quote.Id);
                    accountIds.add(quote.SBQQ__Account__c);
            }
        }
        
        if (eligibleQuotes.size() > 0){
            if (!System.isBatch() && !System.IsFuture()){
                processQuotesAsync(eligibleQuotes, accountIds);
            }
            //added in case of auto-approved quotes
            else if (System.IsFuture()){
                processQuotes(eligibleQuotes, accountIds);
            }
        }
        //FY25SR-2304 end
    }

    /***********************************************************************************************************
      * Method Name          : processQuotesAsync
      * Date Created/Modified: 09/10/2025
      * Author               : Paritosh
      * @description         : Async version
      * @param eligibleQuotes
      * @param accountIds
      * Test Class Methods   :
    /**********************************************************************************************************/
    @future
    public static void processQuotesAsync(Set<Id> eligibleQuotes, Set<Id> accountIds) {
        processQuotes(eligibleQuotes, accountIds);
    }
    
    /***********************************************************************************************************
      * Method Name          : processQuotes
      * Date Created/Modified: 13/06/2025
      * Author               : Shivani
      * @description         : Creates and sends email notice for the Deal Governance. This method is created as part of FY25SR-1112
      * @param eligibleQuotes
      * @param accountIds
      * Test Class Methods   :
    /**********************************************************************************************************/
    public static void processQuotes(Set<Id> eligibleQuotes, Set<Id> accountIds) {
        //FY25SR-2304 start (moved queries from sendProactiveDealGovernanceNotice to here)
        Map<Id,SBQQ__Quote__c> quoteMap = new Map<Id,SBQQ__Quote__c>(
            [SELECT Id, SBQQ__Primary__c, ApprovalStatus__c, SBQQ__Account__c, SBQQ__Status__c, Name, Renewal_Ops_Reviewed__c, CreatedDate,
            SBQQ__Opportunity2__r.OwnerId,SBQQ__Opportunity2__r.Owner.Email,SBQQ__Opportunity2__r.Account.Renewal_Owner__r.Email, SBQQ__Opportunity2__r.Account.Renewal_Owner__r.Manager.Email,
            (
                SELECT Id,Disposition_Reason__c,Product__c,Quote__c, Product__r.Replacement_Category__c,Product__r.ProductCode
                FROM Disposition_Quote_Lines__r 
                WHERE Product__r.Replacement_Category__c != null
            )
            FROM SBQQ__Quote__c WHERE Id IN: eligibleQuotes]
        );   
        Map<Id,SBQQ__QuoteLine__c> mapQuoteLines = QuoteTriggerHelper.getquotelines(eligibleQuotes);

        //FY25SR-2304 get entitlements related to account
        List<Entitlement> entitlements = [SELECT Id, Name, AccountId, Product__r.Replacement_Category__c, EndDate
         FROM Entitlement WHERE AccountId IN :accountIds AND EndDate >= Last_N_Days:456 AND EndDate <= Last_N_Days:90 ];

        //FY25SR-2304 end

        Map<String, List<SBQQ__QuoteLine__c>> quoteLineMap = new Map<String, List<SBQQ__QuoteLine__c>>();
        for (SBQQ__QuoteLine__c line : mapQuoteLines.values()) {
            if(line.Quote_Line_Type__c == 'New' && line.SBQQ__Product__r.Replacement_Category__c != null && !line.SBQQ__Product__r.Replacement_Category__c.equalsIgnoreCase(ReplacementConstants.NON_REPLACEABLE)){
                if (!quoteLineMap.containsKey(line.SBQQ__Quote__c + ':' + line.SBQQ__Product__r.Replacement_Category__c)) {
                    quoteLineMap.put(line.SBQQ__Quote__c + ':' + line.SBQQ__Product__r.Replacement_Category__c, new List<SBQQ__QuoteLine__c>());
                }
                
                quoteLineMap.get(line.SBQQ__Quote__c + ':' + line.SBQQ__Product__r.Replacement_Category__c).add(line);
            }
        }
        Map<String, List<CPQ_Disposition_Quote_Line__c>> dispositionQuoteLinesMap = new Map<String, List<CPQ_Disposition_Quote_Line__c>>();
        for(SBQQ__Quote__c quote : quoteMap.values()){
        for (CPQ_Disposition_Quote_Line__c line : quote.Disposition_Quote_Lines__r) {
                if (line.Product__r.Replacement_Category__c != null && !line.Product__r.Replacement_Category__c.equalsIgnoreCase(ReplacementConstants.NON_REPLACEABLE)) {
                    if (!dispositionQuoteLinesMap.containsKey(line.Quote__c + ':' + line.Product__r.Replacement_Category__c)){
                        dispositionQuoteLinesMap.put(line.Quote__c + ':' + line.Product__r.Replacement_Category__c, new List<CPQ_Disposition_Quote_Line__c>());
                    }
                	dispositionQuoteLinesMap.get(line.Quote__c + ':' + line.Product__r.Replacement_Category__c).add(line);
                }
                
            }    
        }

        //FY25SR-2304 start
        Map<String, List<Entitlement>> entitlementsMap = new Map<String, List<Entitlement>>();
        for (Entitlement ent : entitlements){
            if (!entitlementsMap.containsKey(ent.AccountId + ':' + ent.Product__r.Replacement_Category__c)){
                entitlementsMap.put(ent.AccountId + ':' + ent.Product__r.Replacement_Category__c, new List<Entitlement>());
            }
            entitlementsMap.get(ent.AccountId + ':' + ent.Product__r.Replacement_Category__c).add(ent);
        }
        //FY25SR-2304 end
      
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();
        Set<Id> setQuotesProcessed = new Set<Id>();
        for(Id quoteId : quoteMap.keySet()){
            if(quoteId != null && !setQuotesProcessed.contains(quoteId)){

                Boolean addEmail = false; //FY25SR-2304 moved out

                String htmlBody = '<table border="1" cellspacing="0" cellpadding="8" style="border-collapse: collapse; text-align: center;">';
                htmlBody += '<tr style="background-color: #f8e8a0; font-weight: bold;">';
                htmlBody += '<th rowspan="2">Replacement Category</th>';
                htmlBody += '<th colspan="2">Disposed Products</th>';
                htmlBody += '<th rowspan="2" style="max-width: 40%;width: 40%;">New Expansion Products</th>';
                htmlBody += '</tr>';
                htmlBody += '<tr style="background-color: #f8e8a0; font-weight: bold;">';
                htmlBody += '<th>Renew Later</th>';
                htmlBody += '<th>At Risk</th>';
                htmlBody += '</tr>';
                
                for(String objQuoteReplacementCategory : dispositionQuoteLinesMap.keySet()){
                    String renewLaterLines = '';
                    String atRiskLines = '';
                    String newLines = '';
                    if(quoteLineMap.containskey(objQuoteReplacementCategory)){
                        quoteId = objQuoteReplacementCategory.split(':')[0];
                        htmlBody += '<tr>';
                        htmlBody += '<td>' + objQuoteReplacementCategory.split(':')[1] + '</td>';
                        //htmlBody += '<td rowspan="2">' + objQuoteReplacementCategory.split(':')[1] + '</td>';
                        //htmlBody += '<td>Product Code</td>';
                        //htmlBody += '<td>Product Code</td>';
                        //htmlBody += '<td>Product Code</td>';
                        //htmlBody += '</tr>';
                        //htmlBody += '<tr>';
                        for(CPQ_Disposition_Quote_Line__c cpqDispoObj : dispositionQuoteLinesMap.get(objQuoteReplacementCategory)){
                            if(cpqDispoObj.Disposition_Reason__c == 'Renew Later'){
                                renewLaterLines = renewLaterLines != '' ? renewLaterLines + ', '+ cpqDispoObj.Product__r.ProductCode 
                                        : renewLaterLines + cpqDispoObj.Product__r.ProductCode;
                                addEmail = TRUE;
                            } else if(cpqDispoObj.Disposition_Reason__c == 'At Risk'){
                                atRiskLines = atRiskLines != '' ? atRiskLines + ', '+ cpqDispoObj.Product__r.ProductCode 
                                        : atRiskLines + cpqDispoObj.Product__r.ProductCode;
                                addEmail = TRUE;
                            }
                        }
        
                        for(SBQQ__QuoteLine__c qliObj : quoteLineMap.get(objQuoteReplacementCategory)){
                            addEmail = TRUE;
                            newLines = newLines != '' ? newLines + ', '+ qliObj.SBQQ__Product__r.ProductCode 
                                        : newLines + qliObj.SBQQ__Product__r.ProductCode;
                        }
        
                        htmlBody += '<td>' + renewLaterLines + '</td>';
                        htmlBody += '<td>' + atRiskLines + '</td>';
                        htmlBody += '<td>' + newLines + '</td>';
                        htmlBody += '</tr>';
                    }
                }
        
                htmlBody += '</table>';

                //FY25SR-2304 if disposed table is blank, clear html
                if (!addEmail){
                    htmlBody = '';
                }

                //FY25SR-2304 start (Create table for entitlements)
                Boolean addEmailEnt = false;
                String htmlBodyEnt = '<br/><br/><br/>';
                htmlBodyEnt += '<table border="1" cellspacing="0" cellpadding="8" style="border-collapse: collapse; text-align: center;">';
                htmlBodyEnt += '<tr style="background-color: #f8e8a0; font-weight: bold;">';
                htmlBodyEnt += '<th rowspan="2">Replacement Category</th>';
                htmlBodyEnt += '<th colspan="2">Account Level</th>';
                htmlBodyEnt += '<th rowspan="2" style="max-width: 40%;width: 40%;">New Expansion Products</th>';
                htmlBodyEnt += '</tr>';
                htmlBodyEnt += '<tr style="background-color: #f8e8a0; font-weight: bold;">';
                htmlBodyEnt += '<th>Entitlement</th>';
                htmlBodyEnt += '<th>Entitlement End Date</th>';
                htmlBodyEnt += '</tr>';

                Id accountId = quoteMap.get(quoteId).SBQQ__Account__c;
                DateTime quoteCreatedDate = quoteMap.get(quoteId).CreatedDate;
                DateTime rangeStart = quoteCreatedDate.addDays(Integer.valueOf(Label.Deal_Gov_Notice_Ent_Range.split(',')[0]));
                DateTime rangeEnd = quoteCreatedDate.addDays(Integer.valueOf(Label.Deal_Gov_Notice_Ent_Range.split(',')[1]));

                for (String objQuoteReplacementCategory : quoteLineMap.keySet()){
                    String replacementCategory = objQuoteReplacementCategory.split(':')[1];

                    if (entitlementsMap.containsKey(accountId + ':' + replacementCategory)){
                        List<Entitlement> entsInDateRange = new List<Entitlement>();
                        for (Entitlement ent : entitlementsMap.get(accountId + ':' + replacementCategory)){
                            if (ent.EndDate >= rangeStart && ent.EndDate <= rangeEnd){
                                entsInDateRange.add(ent);
                            }
                        }

                        if (entsInDateRange.size() == 0) continue;
                        addEmail = TRUE;
                        addEmailEnt = TRUE;

                        htmlBodyEnt += '<tr>';
                        htmlBodyEnt += '<td rowspan='+entsInDateRange.size()+'>' + replacementCategory + '</td>';

                        htmlBodyEnt += '<td>' + entsInDateRange[0].Name + '</td>';
                        htmlBodyEnt += '<td>' + entsInDateRange[0].EndDate.format() + '</td>';

                        String newLines = '';
                        for(SBQQ__QuoteLine__c qliObj : quoteLineMap.get(objQuoteReplacementCategory)){
                            newLines = newLines != '' ? newLines + ', '+ qliObj.SBQQ__Product__r.ProductCode 
                                        : newLines + qliObj.SBQQ__Product__r.ProductCode;
                        }

                        htmlBodyEnt += '<td rowspan='+entsInDateRange.size()+'>' + newLines + '</td>';
                        htmlBodyEnt += '</tr>';

                        for (Integer i=1; i<entsInDateRange.size(); i++){
                            htmlBodyEnt += '<tr>';
                            htmlBodyEnt += '<td>' + entsInDateRange[i].Name + '</td>';
                            htmlBodyEnt += '<td>' + entsInDateRange[i].EndDate.format() + '</td>';
                            htmlBodyEnt += '</tr>';
                        }
                    }
                }

                htmlBodyEnt += '</table>';

                if (addEmailEnt){
                    htmlBody += htmlBodyEnt;
                }
                //FY25SR-2304 end

        
                String subject = 'R+E Potential Subsumed Quote ' + quoteMap.get(quoteId).Name;
        
                htmlBody += '<br/><br/><br/>';
        
                htmlBody += 'Expansion Opportunity Link: ' + URL.getOrgDomainUrl().toExternalForm()+ '/' + quoteMap.get(quoteId).SBQQ__Opportunity2__r.Id + '<br/>';
                htmlBody += 'Primary Quote Link: ' + URL.getOrgDomainUrl().toExternalForm() + '/' + quoteMap.get(quoteId).Id + '<br/>';
        
                String renewalopscompanyEmail = System.Label.renewalops_company_com;
                List<String> toAddresses = new List<String>{
                        renewalopscompanyEmail,
                        quoteMap.get(quoteId).SBQQ__Opportunity2__r.Account.Renewal_Owner__r.Email}; 
        
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.setToAddresses(toAddresses);
                message.setSubject(subject);
                message.setHtmlBody(htmlBody); 

                List<String> sendingToCcAdd = new List<String>();
                if(quoteMap.containsKey(quoteId)){
                    if(quoteMap.get(quoteId).SBQQ__Opportunity2__r.Owner != null){
                        sendingToCcAdd.add(quoteMap.get(quoteId).SBQQ__Opportunity2__r.Owner.Email);
                    }
                    //CPQ22-6083
                    if(quoteMap.get(quoteId).SBQQ__Opportunity2__r.AccountId != null 
                        && quoteMap.get(quoteId).SBQQ__Opportunity2__r.Account.Renewal_Owner__c != null 
                        && quoteMap.get(quoteId).SBQQ__Opportunity2__r.Account.Renewal_Owner__r.Manager != null){
                        sendingToCcAdd.add(quoteMap.get(quoteId).SBQQ__Opportunity2__r.Account.Renewal_Owner__r.Manager.Email);
                    }
                }
                //String[] sendingToCcAdd =  new List<String>{quoteMap.get(quoteId).SBQQ__Opportunity2__r.Owner.Email};
                message.setTargetObjectId(quoteMap.get(quoteId).SBQQ__Opportunity2__r.OwnerId);
                String noReplyEmailId = System.Label.NoReplyRubrikEmailId;
                message.setReplyTo(noReplyEmailId);//CPQ22-4074 Ends
                message.setUseSignature(false); 
                message.setCcAddresses(sendingToCcAdd);
                message.setSaveAsActivity(false); 
                message.setWhatId(quoteMap.get(quoteId).SBQQ__Opportunity2__r.Id);

                if(addEmail) {
                    messages.add(message);
                    setQuotesProcessed.add(quoteId);
                }
            }
        }
    
        if(!messages.IsEmpty() && !Test.isRunningTest()){                  
            try {
                System.debug(system.logginglevel.DEBUG,'The email was sent successfully. :::' + messages.size());
                Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                if (results[0].success) {
                    System.debug(system.logginglevel.DEBUG,'The email was sent successfully.');
                } else {
                    System.debug(system.logginglevel.DEBUG,'The email failed to send: ' +  results[0].errors[0].message);
                }
            } catch(Exception ex){
                System.debug(system.logginglevel.DEBUG,'Email is not sent-sendTaskEmail: '+ex.getMessage());
            }
        }
    }
    /***********************************************************************************************************
    * Method Name          : blankOutRenewalOpsFieldsOnQuoteClone
    * Date Created/Modified: 10/06/2025
    * Author               : Shivani
    * @description         : Blanks Out Renewal Ops fields on Cloning of Quote. This method is created as part of FY25SR-1112
    * @param newQuoteList
    * Test Class Methods   :
    /**********************************************************************************************************/
    public static void blankOutRenewalOpsFieldsOnQuoteClone(List<SBQQ__Quote__c> newQuoteList){
        for(SBQQ__Quote__c objQuote : newQuoteList){
            objQuote.Renewal_Ops_Notes__c = '';
            objQuote.Renewal_Ops_Reviewed__c = false;
        }
    }
}