/* Class Name: OppEmailTriggerHandler
* Description: This class is for sending email for the opportunities having program conversion and stage as 3 Technical Validation.
* This is is now updated to send email for stage 3-5. //SAL24-249
*/
public class OppEmailTriggerHandler{
    public static EmailTemplate et;
    public static void sentEmailOnOppStage3(
        Map<Id,Opportunity> mapNewOpportunity,
        Map<Id,Opportunity> mapOldOpportunity,
        Map<ID, SBQQ__Quote__c> quoteMapTrgUpdate //FY25SR-2391
    ){
        List<Opportunity> oppList = mapNewOpportunity.values();
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();

        for(Opportunity opp : oppList) {
            if (opp.Click_Thru_Contact_Email__c == null || opp.Conversion_Terms_Accepted__c == true) continue;
        
            if ((opp.IAR__c|| (opp.SBQQ__PrimaryQuote__c!=null && quoteMapTrgUpdate.containsKey(opp.SBQQ__PrimaryQuote__c) 
                               && quoteMapTrgUpdate.get(opp.SBQQ__PrimaryQuote__c).LoD_refreshed_to_Subscription_Deal__c))  //RGCF2-66 //FY25SR-2391
                && (opp.StageName == '3 Technical Validation' || opp.StageName == '4 Business Justification' || opp.StageName == '5 Negotiate & Close' )
            ) {//SAL24-249
                if (opp.Click_Through_Email_Sent__c == false
                    && mapOldOpportunity.containsKey(opp.Id)
                    && mapOldOpportunity.get(opp.Id).StageName != opp.StageName) {
                    Messaging.SingleEmailMessage mail = sendClickthruEmail(opp);
                    opp.Click_Through_Email_Sent__c = true;
                    emailList.add(mail);
                }
                else if (opp.Resend_Click_Through_Email__c == true
                    && mapOldOpportunity.containsKey(opp.Id)
                    && mapOldOpportunity.get(opp.Id).Resend_Click_Through_Email__c == false) {
                    Messaging.SingleEmailMessage mail = sendClickthruEmail(opp);
                    opp.Resend_Click_Through_Email__c = false;
                    opp.Click_Through_Email_Sent__c = true;
                    emailList.add(mail);
                }
            }
        }

        if (!emailList.isEmpty()){
            try {
            Messaging.sendEmail(emailList);
            } catch(Exception ex) {
                System.debug('Email is not sent-sentEmailOnOppStage3: '+ex.getMessage()); 
            }
        }
    }

    private static Messaging.SingleEmailMessage sendClickthruEmail(
        Opportunity opp
    ) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
        String emailBody = 'Dear Customer,'
            + '<br> To complete your enrollment in this conversion program and switch from Life of Device to SaaS, you must submit the enrollment form using the below link and accept the terms and conditions.'   
            + '<br><br> Link to Enrollment Form - <a href="https://www.rubrik.com/lod-conversion?id='+opp.AccountId+'">https://www.rubrik.com/lod-conversion?Id='+opp.AccountId+'</a>'    //SAL24-249
            + '<br><br> Once you complete the conversion you will no longer have access to your Life of Device license and you will enjoy all the benefits of your new SaaS license!'   
            + '<br><br> Please work with your designated Rubrik Sales Representative if you have any questions.'    
            + '<br><br> Thank you for being a valued Rubrik customer!'  
            + '<br><br> Regards,'   
            + '<br> Rubrik Sales';  
            
        mail.setToAddresses(new List<String> { opp.Click_Thru_Contact_Email__c });  
        mail.setTreatTargetObjectAsRecipient(True); 
        List<Id> sendCc = new List<Id>();   
        sendCc.add(opp.OwnerId);    
        mail.setCcAddresses(sendCc);
        mail.setSubject('Please accept the LoD to SaaS conversion agreement');  
        mail.setHtmlBody(emailBody);    
            
        mail.setWhatId(opp.Id); 
        return mail;
    }

    //SAL24-443
    public static void sendTradeUpPDFAddendumEmail(Map<Id,Opportunity> mapNewOpportunity,Map<Id,Opportunity> mapOldOpportunity,Map<Id, SBQQ__Quote__c> quoteMap){
        List<Opportunity> oppList = mapNewOpportunity.values();
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        et = new EmailTemplate();
        et = [Select id,Name, Subject, Body from EmailTemplate where DeveloperName  ='TradeUp_PDF_Addendum_Email_Template' limit 1];
        for(Opportunity opp : oppList) {
            //if (opp.Click_Thru_Contact_Email__c == null || opp.PDF_Addendum_Email_Delivered__c || opp.PDF_Addendum_Email_Sent__c) {opp.Resend_PDF_Addendum_Email__c = false; continue; }
            if (opp.Old_TradeUp_Click_Thru_Process__c || opp.Click_Thru_Contact_Email__c == null) {opp.Resend_PDF_Addendum_Email__c = false; continue; }

            if(opp.SBQQ__PrimaryQuote__c != null && quoteMap != null && !quoteMap.isEmpty() && quoteMap.containsKey(opp.SBQQ__PrimaryQuote__c)){
                SBQQ__Quote__c primaryQuote = quoteMap.get(opp.SBQQ__PrimaryQuote__c);
                if(primaryQuote != null && primaryQuote.Trade_Up_Amounts__c != null && primaryQuote.Trade_Up_Amounts__c > 0
                    && (opp.StageName == '5 Negotiate & Close' )
                ) {
                    if (/*!opp.PDF_Addendum_Email_Sent__c &&*/
                        mapOldOpportunity.containsKey(opp.Id) &&
                        ((mapOldOpportunity.get(opp.Id).StageName != opp.StageName && !opp.PDF_Addendum_Email_Delivered__c && !opp.PDF_Addendum_Email_Sent__c)
                            || (opp.Resend_PDF_Addendum_Email__c && mapOldOpportunity.get(opp.Id).Resend_PDF_Addendum_Email__c != opp.Resend_PDF_Addendum_Email__c))) 
                    {
                        Messaging.SingleEmailMessage mail = sendTradeUpPDFAddendum(opp);
                        opp.PDF_Addendum_Email_Sent__c = true;
                        opp.Resend_PDF_Addendum_Email__c = false;
                        emailList.add(mail);
                    }
                }
            }
        }
        if (!emailList.isEmpty()){
            try {
            Messaging.sendEmail(emailList);
            } catch(Exception ex) {
                System.debug('Email is not sent-sendTradeUpPDFAddendumEmail: '+ex.getMessage()); 
            }
        }
    }
    //SAL24-749
    public static void sendchurnNotification(Map<Id,Opportunity> mapNewOpportunity,Map<Id,User> userMap,Map<Id,Id> churnNotificationMap){
        List<Opportunity> oppList = mapNewOpportunity.values();
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        et = new EmailTemplate();
        et = [Select id,Name, Subject, Body from EmailTemplate where DeveloperName  ='Opp_Expansion_Subsumed_Churn_R_E' limit 1];
        Email_Preferences__mdt renewalDirectorEmail = [Select Id,Receipient__c from Email_Preferences__mdt where MasterLabel = 'Subsumed_Renewal_Churn_Director_Email' LIMIT 1];
        for(Id oppId : churnNotificationMap.keyset()) {
            if(userMap.containskey(churnNotificationMap.get(oppId))){
                Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(et.Id, null, oppId);
                List<string> toAddress = new List<string>();
                List<string> sendCc = new List<string>();   
                toAddress.add(userMap.get(churnNotificationMap.get(oppId)).Email);
                if(userMap.get(churnNotificationMap.get(oppId)).ManagerId != null && userMap.get(churnNotificationMap.get(oppId)).Manager.isActive){
                    sendCc.add(userMap.get(churnNotificationMap.get(oppId)).Manager.Email);
                }
                if(renewalDirectorEmail != null && renewalDirectorEmail.Receipient__c != ''){
                  sendCc.add(renewalDirectorEmail.Receipient__c);
                }
                mail.setCcAddresses(sendCc);
                mail.setToAddresses(toAddress);  
                mail.setWhatId(oppId); 
                emailList.add(mail);
            }
        }
        if (!emailList.isEmpty()){
            try {
            Messaging.sendEmail(emailList);
            } catch(Exception ex) {
                System.debug('Email is not sent-sendchurnNotification: '+ex.getMessage()); 
            }
        }
    }
    public static Messaging.SingleEmailMessage sendTradeUpPDFAddendum(Opportunity opp) {

        Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(et.Id, null, opp.Id);
            
        mail.setToAddresses(new List<String> { opp.Click_Thru_Contact_Email__c });  
        List<Id> sendCc = new List<Id>();   
        sendCc.add(opp.OwnerId);
        //sendCc.add('0056f000009zhDa');
        mail.setCcAddresses(sendCc);
        mail.setWhatId(opp.Id); 
        mail.setSaveAsActivity(true);
        return mail;
    }
    //SAL24-443 - End

    /** SAL25-495 - start *SAL26-549:commented
    @future
    public static void sendEmailOppRequiresUCLScaleFuture(Set<Id> oliIds) {
        sendEmailOppRequiresUCLScale(oliIds);
    }
    public static void sendEmailOppRequiresUCLScale(Set<Id> oliIds) {
        // get UCL Scale product codes 
        Set<String> uclScaleProductCodesMdtset = OpportunityObjectTriggerHelper.getUclScaleProductCodesSet();
        if(uclScaleProductCodesMdtset.isEmpty()) return;
        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        
        // Prepare opportunity Ids set holding ucl scale opp products
        List<OpportunityLineItem> newOLIs = [SELECT Id, OpportunityId, UCL_Scale__c, ProductCode 
                                                FROM OpportunityLineItem 
                                                WHERE OpportunityId IN :oliIds
                                                AND UCL_Scale__c = null
                                                AND Productcode IN :uclScaleProductCodesMdtset];
        Set<Id> opportunityIdsSet = new Set<Id>();
        for(OpportunityLineItem oli : newOLIs){
            if(uclScaleProductCodesMdtset.contains(oli.ProductCode) && oli.UCL_Scale__c == null){
                opportunityIdsSet.add(oli.OpportunityId);
            }
        }
        if(opportunityIdsSet.isEmpty()) return;
        
        // Get opportunities details holding ucl scale products 
        List<Opportunity> oppToSendEmails = [SELECT Id, Name, Owner.Name, CloseDate, Amount, Rubrik_Sales_Engineer__r.Manager.Name, 
                                             Rubrik_Sales_Engineer__r.Manager.Email, Rubrik_Sales_Engineer__r.Manager.Manager.Name, 
                                             Rubrik_Sales_Engineer__r.Manager.Manager.Email, SBQQ__PrimaryQuote__r.SBQQ__NetAmount__c
                                             FROM Opportunity 
                                             WHERE Id IN :opportunityIdsSet
                                             AND RecordTypeId = :OpportunityUtil.oppRecTypeIdSalesOpp];        
        
        OrgWideEmailAddress orgWideEmail = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'Rubrik Sales Operations' LIMIT 1];
        for(Opportunity opp : oppToSendEmails) {
            // get email address for SED/SEM
            String email = String.isNotBlank(opp.Rubrik_Sales_Engineer__r.Manager.Manager.Email) ?
                opp.Rubrik_Sales_Engineer__r.Manager.Manager.Email : 
                opp.Rubrik_Sales_Engineer__r.Manager.Email;
           
            if(String.isNotBlank(email)){
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();            
                mail.setOrgWideEmailAddressId(orgWideEmail.Id);
                mail.setToAddresses(new List<String>{email}); 
                mail.setWhatId(opp.Id); 
                mail.setSaveAsActivity(false);
                mail.setPlainTextBody(getEmailBody(opp));
                mail.setSubject(opp.Name+' requires UCL/Scale % on Opportunity Products.');
                emailList.add(mail);
            }            
        }
  
        if(!emailList.isEmpty() && !Test.isRunningTest()){
            try {
            Messaging.sendEmail(emailList);
            } catch(Exception ex) {
                System.debug('Email is not sent-sendEmailOppRequiresUCLScale: '+ex.getMessage());
            }
        }
    }
    
    public static String getProductListUrl(Id oppId) {
        return URL.getOrgDomainURL().toExternalForm()+'/lightning/r/Opportunity/'+oppId+'/related/OpportunityLineItems/view';
    }
    
    public static String getEmailBody(Opportunity opp) {
        Decimal amount = opp?.SBQQ__PrimaryQuote__r != null ? opp?.SBQQ__PrimaryQuote__r?.SBQQ__NetAmount__c : opp.Amount == null ? 0 : opp.Amount;
        String body = 'The following opportunity have products that potentially have UCL/Scale % and need attention. Please populate UCL/Scale % on each Scale Opportunity Product.'+'\n\n';
        body += 'Instruction:'+'\n';
        body += '1. Follow this link '+ getProductListUrl(opp.Id) +'\n\n';
        body += '2. For EACH product line that has Sales Comp Category containing "Scale" SED or SEM must populate the field "UCL/Scale %"'+'\n\n';
        body += 'Opportunity Name: '+ opp.Name +'\n';
        body += 'Opportunity Owner: '+ opp.Owner.Name +'\n';
        body += 'Opportunity SE Director: '+ (String.isNotBlank(Opp.Rubrik_Sales_Engineer__r.Manager.Manager.Name) ? Opp.Rubrik_Sales_Engineer__r.Manager.Manager.Name : '')+'\n';
        body += 'Opportunity SEM: '+ (String.isNotBlank(Opp.Rubrik_Sales_Engineer__r.Manager.Name) ? Opp.Rubrik_Sales_Engineer__r.Manager.Name : '')+'\n';
        body += 'Opportunity TCV: '+ '$' + string.valueof(amount.format()) +'\n';
        body += 'Opportunity Close Date: '+ opp.CloseDate.month()+'/'+opp.CloseDate.day()+'/'+opp.CloseDate.year() +'\n';
        body += 'Opportunity Product List Link: '+ getProductListUrl(opp.Id) +'\n\n';
        body += 'Thanks!'; 
        
        return body;
    } 
    /** SAL25-495 End */
}