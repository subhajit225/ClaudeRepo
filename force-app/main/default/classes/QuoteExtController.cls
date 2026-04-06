/**
* @description : This class is a controller and called from Custom Submit for Approval Lightning Component
*/ 
public with sharing class QuoteExtController {
    /**@description quote id */
    public Id quoteId {get; set;}
    /**@description approvals list*/
    public SBAA__Approval__c[] approvals {get; set;}
    /**@description quote record*/
    private SBQQ__Quote__c Quote;
    /**@description quote queried*/
    public static SBQQ__Quote__c queriedQuoteRecord;//GLCR-82
    /**@description quote fields*/
    public List<String> quoteFieldList = new List<String>();
    /**@description error message*/
    public String ErrorMessage {get; set;} 
    /**@description quote record types*/
    public static Map<String, Schema.RecordTypeInfo> QuoteRecoTypeDatas;//GLCR-82
    /**
* @description : COnstructor
* @param stdController standard controller
*/ 
    public QuoteExtController(ApexPages.StandardController stdController) {
        quoteId = stdController.getId();
        if (!Test.isRunningTest()){
            stdController.addFields(new List<String>{'Id', 'Name'}); 
        }        
        this.Quote = (SBQQ__Quote__c)stdController.getRecord();
    }
    
    /**
* @description : on submit handler
* @return void
*/ 
    public PageReference onSubmit() {
        Savepoint sp = Database.setSavepoint();
        try  { 
            System.debug(LoggingLevel.DEBUG, ' Run onSubmit');
            if (quoteId != null) {
            //GLCR-82 - Start
                    /*if (Userinfo.getUserID() != '0058Y00000B3uQQQAZ') {
                SBAA.ApprovalAPI.submit(quoteId, SBAA__Approval__c.Quote__c);
                // return new PageReference('/' + quoteId);
                    } else {*/
                updateQuote(quoteId, 'Submitted',true, null);
                    callApprovalAPI(quoteId);
                    //}
        //GLCR-82 - End
            }
        } catch(exception e) {
            Database.rollback(sp);
            system.debug(LoggingLevel.DEBUG, 'error' + e);
            ErrorMessage = e.getMessage();
            ApexPages.addMessages(e);
            sendFailureEmail(quoteId,e);//GLCR-82
            }
            //return new PageReference('/' + quoteId);
            return null;
        }
    //GLCR-82 - Start
    /**
* @description : call approval api
* @param quoteID - quote id
*/ 
        @future
        public static void callApprovalAPI(ID quoteID) {
            //QuoteIDforFuture = quoteID;
            //System.debug(LoggingLevel.DEBUG, 'QuoteIDforFutureQuoteIDforFuture.   '+QuoteIDforFuture);
            System.debug(LoggingLevel.DEBUG, 'SBAA__Approval__c.Quote__c.   ' + SBAA__Approval__c.Quote__c);
            try{
            //cpq22-5275 starts
            Boolean result = MapApprovalRecordsToClonedQuote.createApprovalRecords(quoteID);
            if(result == TRUE){
                //cpq22-5275 ends
                SBAA.ApprovalAPI.submit(quoteID, SBAA__Approval__c.Quote__c);
            }
            
            }catch(Exception ex){
                System.debug(LoggingLevel.DEBUG, 'exexexexexexex.     '+ex + '           ' + ex.getStackTraceString());
                updateQuote(quoteID,'',true, null);
                sendFailureEmail(quoteId,ex);
            }
        }
    //CPQ22-4796 added quote param
    /**
* @description : update quote
* @param quoteID quote id
* @param approvalStatus approval status
* @param updateRecordType update rrecord type?
* @param quote record
*/ 
    public static void updateQuote(ID quoteID, String approvalStatus,Boolean updateRecordType, SBQQ__Quote__c quote) {
        if(queriedQuoteRecord == null){
            queriedQuoteRecord = getQuoteRecord(quoteID)[0];
        }
        String recordTypeID = null;
        if(updateRecordType){
            recordTypeID = getRecordTypeID(approvalStatus,queriedQuoteRecord);
        }
            SBQQ__Quote__c QuoteforApproval = new SBQQ__Quote__c(
                ID = quoteID,
            ApprovalStatus__c = approvalStatus,
            RecordTypeId = recordTypeID
            );
        if(approvalStatus == 'Approved'){
                QuoteforApproval.SBQQ__Status__c = approvalStatus; //RSCG-59
                System.debug(LoggingLevel.DEBUG, 'MS EnteredOnSubmit for Approved Quote without disabling Triggers');
            SBQQ.TriggerControl.disable();
                update QuoteforApproval;
            TriggerControls.disableQuoteTrigger = true;
            SBQQ.TriggerControl.enable();
        }
        else {
            //CPQ22-4796 update Sales Rep Exception
            if (approvalStatus == 'Submitted' && quote.SBQQ__Opportunity2__c!=null){
               /*if (quote.SBQQ__Opportunity2__r.Bypass_PSO__c && (quote.ExceptionsOnQuote__c == null || !quote.ExceptionsOnQuote__c.contains(Label.Bypass_PSO))){
                    QuoteforApproval.ExceptionsOnQuote__c = (quote.ExceptionsOnQuote__c == null ? '' : quote.ExceptionsOnQuote__c) + ';' + Label.Bypass_PSO;
                    QuoteforApproval.RWD_Sales_Rep_Exception_Justification__c = quote.RWD_Sales_Rep_Exception_Justification__c != null ? quote.RWD_Sales_Rep_Exception_Justification__c : ',Bypass PSO automated';
                }
                */ 
				if (!quote.SBQQ__Opportunity2__r.Bypass_PSO__c && quote.RWD_Sales_Rep_Exception__c!=null && quote.RWD_Sales_Rep_Exception_Justification__c!=null){
                    //QuoteforApproval.ExceptionsOnQuote__c = quote.ExceptionsOnQuote__c.remove(Label.Bypass_PSO);
                    QuoteforApproval.RWD_Sales_Rep_Exception_Justification__c = quote.RWD_Sales_Rep_Exception_Justification__c.remove(',Bypass PSO automated');
                }
            } 	
                SBQQ.TriggerControl.disable();
                TriggerControls.disableQuoteTrigger = true;
                update QuoteforApproval;
            TriggerControls.disableQuoteTrigger = false;
                SBQQ.TriggerControl.enable();
            System.debug(LoggingLevel.DEBUG, 'EnteredOnSubmit');
            }
        }
    
    /**
* @description : get record type id
* @param approvalStatus approval status
* @param queriedQuoteRecord quote record
* @return record type id
*/ 
    public static String getRecordTypeID(String approvalStatus,SBQQ__Quote__c queriedQuoteRecord){
        System.debug(LoggingLevel.DEBUG, Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName());
        if (QuoteRecoTypeDatas == null) {
            QuoteRecoTypeDatas = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName();
        }
        String recordTypeID = QuoteRecoTypeDatas.get('Draft_Quote').getRecordTypeId();
        if(String.isNotBlank(approvalStatus) && approvalStatus == 'Submitted'){
            recordTypeID = QuoteRecoTypeDatas.get('Locked_Quote').getRecordTypeId();
        } else if(String.isNotBlank(approvalStatus) && approvalStatus == 'Approved'){ // //RSCG-59
            recordTypeID = QuoteRecoTypeDatas.get('Approved_Quote').getRecordTypeId();
        }else if(String.isBlank(approvalStatus)){
            if(queriedQuoteRecord.SBQQ__Type__c == 'Renewal+Expansion'){
                recordTypeID = QuoteRecoTypeDatas.get('RE_Quote').getRecordTypeId();
            }
        }
        return recordTypeID;
    }
    
    /**
* @description : send failure email
* @param quoteId quote id
* @param ex exception record
*/ 
        public static void sendFailureEmail(ID quoteId, Exception ex) {
        Boolean sendEmailToAdmins = false;
        String exceptionString = '';
            System.debug(LoggingLevel.DEBUG, 'Sendemail in exception called');
            ShGl_DisableBusinessLogic__c disableBusinessLogicCS = ShGl_DisableBusinessLogic__c.getInstance(UserInfo.getUserId());
            System.debug(LoggingLevel.DEBUG, 'disableBusinessLogicCS.   '+disableBusinessLogicCS);
        if(disableBusinessLogicCS.Approval_Issue_Notify_flag__c && String.isNotBlank(system.Label.Approval_Notifier_Admins_Mail)){
            sendEmailToAdmins = true;
            exceptionString = ex.getMessage() + ex.getStackTraceString();
        }
        //if (disableBusinessLogicCS.Approval_Issue_Notify_flag__c && system.Label.Approval_Notifier_Admins_Mail != null && String.isNotBlank(system.Label.Approval_Notifier_Admins_Mail) || Test.isRunningTest()) {
        if (system.Label.Approval_Notifier_Admins_Mail != null && String.isNotBlank(system.Label.Approval_Notifier_Admins_Mail) || Test.isRunningTest()) {
                List<Messaging.SingleEmailMessage> EmailList = new List<Messaging.SingleEmailMessage>();
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
                List<String> Address = new List<String>();
                if(Test.isRunningTest()){
                    Address = new List < String > {
                        'testApprovalNotifier@gmail.com'
                    };
                        }else{
                if(sendEmailToAdmins){
                            Address = system.Label.Approval_Notifier_Admins_Mail.split(',');
                        }
                Address.add(UserInfo.getUserEmail());
            }
                mail.toAddresses = Address;
                mail.setSenderDisplayName('System Generated <Do Not Reply>');
                mail.setSubject('Quote '+Quote.Name+' has a Issue In Approval Submission   ');
            mail.setHtmlBody('<P>Hi,</p> <p> CPQ System is Unable to Submit the <a href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + quoteId + '">Quote</a> due to an internal issue</p> <p style="color:red">' + exceptionString + '</p>.<br> Please reach out to admins for further support');
                EmailList.add(mail);                
                
                If (!Test.isRunningTest()){
                Messaging.sendEmail(EmailList); 
            }
            }
        }
    //GLCR-82 - End
        
    /**
* @description : redirect to quote
* @return null
*/ 
    public PageReference reDirect() {
        return new PageReference('/' + quoteId);
    }
    
    //CPQ22-4796 quoteId param changed to quote obj
    /**
* @description : on submit handler for lightning
* @param quote
* @param markApproved mark approved
* @return message
*/ 
    @AuraEnabled
    public static string onSubmitLtng(SBQQ__Quote__c quote, Boolean markApproved) {
        Id quoteId = quote.Id;
        try  { 
            if (quoteId != null) {
                //SF-28881
                if(checkQuoteCalculation(quoteId) == true ){
                    return 'calculation in progress';
                }
        //GLCR-82 - Start
                /*if (Userinfo.getUserID() != '0058Y00000B3uQQQAZ') {
                SBAA.ApprovalAPI.submit(quoteId, SBAA__Approval__c.Quote__c);
                
                // return new PageReference('/' + quoteId);
                } else {*/
                if(markApproved){
                    updateQuote(quoteId, 'Approved',true, quote); //RGCF2-59
                } else {
                updateQuote(quoteId, 'Submitted',true, quote);
                callApprovalAPI(quoteId);
                }
                //}
        //GLCR-82 - End
            }
        } catch(exception e) {
                
            sendFailureEmail(quoteId,e);//GLCR-82
                
            return e.getMessage();
        }
        return '';
        
    }
    
    /**
* @description : on quote recall handler
* @return void
*/ 
    public PageReference onRecall() {
        if (quoteId != null) {
            SBAA.ApprovalAPI.recall(quoteId, SBAA__Approval__c.Quote__c);
        }
        return new PageReference('/' + quoteId);
    }
    
    /**
* @description : on preview handler
* @return void
*/ 
    public PageReference onPreview() {
        if (quoteId != null) {
            approvals = SBAA.ApprovalAPI.preview(quoteId, SBAA__Approval__c.Quote__c);
        }
        return null;
    }
    
    /**
* @description : get quote record
* @param QuoteId quote id
* @return quotes
*/ 
    @AuraEnabled
    public static List<SBQQ__Quote__c> getQuoteRecord(String QuoteId) {    
        List<SBQQ__Quote__c> recordQuote = new List<SBQQ__Quote__c>();
    //GLCR-82 Added SBQQ__Type__c in query below
        recordQuote = [Select id, SBQQ__Uncalculated__c,SBQQ__Type__c from SBQQ__Quote__c where Id =: QuoteId];
        return recordQuote;
    }
    
    /**
* @description : Calls metrics class during Approval
* @param QuoteId
*/
    //Added for Arroyo
    //FY25SR-1125 - changed the Arroyo Metrics class
    @AuraEnabled
    public static void callArroyoQueuableMethod(String QuoteId){
        System.debug(LoggingLevel.DEBUG, '**metricCalcForArroyoQueueable**');
        Set<Id> recordQuote = new Set<Id>();
        recordQuote.add(QuoteId);
        System.enqueueJob(new MetricsCalculatorQueueable(recordQuote));
    }
    
    //SF-28881
    /**
* @description : check quote calc
* @param QuoteId quote id
* @return calc status
*/ 
    public static boolean checkQuoteCalculation(String QuoteId){      
        boolean calculationStatus = false;
        List<SBQQ__RecordJob__c> recJobList = new List<SBQQ__RecordJob__c>();
        List<AsyncApexJob> asyncjob = New List<AsyncApexJob>();
        
        recJobList = [Select id,SBQQ__JobDetails__c,SBQQ__JobId__c, SBQQ__JobStatus__c, SBQQ__RecordId__c, SBQQ__RedirectUrl__c, SBQQ__Stacktrace__c,CreatedDate, LastModifiedDate ,LastModifiedBy.Name from SBQQ__RecordJob__c where SBQQ__RecordId__c like: '%'+QuoteId+'%' AND SBQQ__RecordId__c like :'%QuoteCalculator'];
        
        If(recJobList.size() > 0){ 
            asyncjob = [Select id,Status,CreatedBy.Name from AsyncApexJob where Id =: recJobList[0].SBQQ__JobId__c AND CreatedBy.Name =: recJobList[0].LastModifiedBy.Name];
            
            if(asyncjob.size() > 0 && (asyncjob[0].Status == 'Processing' ||  asyncjob[0].Status == 'Queued' || asyncjob[0].Status == 'Holding' || asyncjob[0].Status == 'Preparing')){
                calculationStatus = true;
            }
            
        }
        return calculationStatus;
    }
    
  //Added for CPQ22-3378 Subsasset Validations
    /**
* @description : validate sub assets
* @param quotelineRecs quote line records
* @param dispositionLines disposition lines
* @return message
*/ 
  @AuraEnabled
    public static String validateSubsAssets(List<SBQQ__QuoteLine__c> quotelineRecs, List<CPQ_Disposition_Quote_Line__c> dispositionLines){
      List<String> subsasstNames = new List<String>();    
      Set<String> asstNames = new Set<String>();
      Map<Id,List<String>> qlIdSrnoMap = new Map<id,List<String>>();
      Map<String,Double> assIdCapacity = new Map<String,Double>();
      Map<Id,List<String>> mapReqIdandSrno = new Map<id,List<String>>();
      Map<Id,List<String>> mapPerpRscandSrno = new Map<id,List<String> >();
      Map<Id,List<String>> mapScaleSubsum = new map<Id,List<String>>();
      Map<Id,String> mapTPHrenwCLI = new map<Id,String>();
        Set<String> foundAssets = new Set<String>();
      List<String> splitSubs = new List<String>();
      String validationMSG;
      boolean isTPHreplaced = false;
      boolean isOverrideExcpPresent= false;//CPQ22-5934
      List<Integer> indexToRemove = new List<Integer>(); 
      ShGl_DisableFunctionalityLogic__c disablAssetValidation = ShGl_DisableFunctionalityLogic__c.getInstance();
      Boolean disable = disablAssetValidation.Disable_Asset_Validation__c;
      if(!disable){
            //Start : Added logic to bypass this validation for virtual addon and TPH as part of CPQ22-3838
            //Copy the records to new list
  List<SBQQ__QuoteLine__c> filterQuoteLineRecs = new List<SBQQ__QuoteLine__c>(quotelineRecs);
            
  for(Integer ql=0; ql<filterQuoteLineRecs.size();ql++){
      
if(
((filterQuoteLineRecs[ql].Product_Type__c == 'HW Support'|| filterQuoteLineRecs[ql].Product_Type__c == 'RCDM Support'|| filterQuoteLineRecs[ql].SBQQ__Product__r.Product_Subtype__c == 'LOD Addon') 
         && filterQuoteLineRecs[ql].SBQQ__RequiredBy__c == null 
         && filterQuoteLineRecs[ql].SBQQSC__RenewedContractLine__c != null 
         && filterQuoteLineRecs[ql].SBQQSC__RenewedContractLine__r.Product2Id != null 
         && ((
             filterQuoteLineRecs[ql].SBQQSC__RenewedContractLine__r.Product2.Name.contains('RCDM-HPE') ||
             filterQuoteLineRecs[ql].SBQQSC__RenewedContractLine__r.Product2.Name.contains('RCDM-DELL')||
             filterQuoteLineRecs[ql].SBQQSC__RenewedContractLine__r.Product2.Name.contains('RCDM-UCS') ||
             filterQuoteLineRecs[ql].SBQQSC__RenewedContractLine__r.Product2.Name.contains('RCDM-ELA'))
             || 
             ((filterQuoteLineRecs[ql].SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Product_Type__c == 'Add-On Node' && 
              !filterQuoteLineRecs[ql].SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Name.contains('-HW-')) || (filterQuoteLineRecs[ql].SBQQSC__RenewedContractLine__r.Required_by_Product_Code__c != null 
              && filterQuoteLineRecs[ql].SBQQSC__RenewedContractLine__r.Required_by_Product_Code__c.contains('-ADDON-NODE-')
              && !filterQuoteLineRecs[ql].SBQQSC__RenewedContractLine__r.Required_by_Product_Code__c.contains('-HW-')))
            )) ||// for RSC lines 
            (filterQuoteLineRecs[ql].Product_Level__c == 'Hybrid Software' 
                && filterQuoteLineRecs[ql].SBQQ__RequiredBy__c == null
                && filterQuoteLineRecs[ql].SBQQSC__RenewedContractLine__c != null 
                && ((filterQuoteLineRecs[ql].SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Product_Type__c == 'Add-On Node' && 
              !filterQuoteLineRecs[ql].SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Name.contains('-HW-')) || (filterQuoteLineRecs[ql].SBQQSC__RenewedContractLine__r.Required_by_Product_Code__c != null 
              && filterQuoteLineRecs[ql].SBQQSC__RenewedContractLine__r.Required_by_Product_Code__c.contains('-ADDON-NODE-')
              && !filterQuoteLineRecs[ql].SBQQSC__RenewedContractLine__r.Required_by_Product_Code__c.contains('-HW-'))))
){
                //store index for unwanted lines
                indexToRemove.add(filterQuoteLineRecs.indexOf(filterQuoteLineRecs[ql]));
                
                //SBQQ__QuoteLine__c index =  quotelineRecs.remove(filterQuoteLineRecs.indexOf(filterQuoteLineRecs[ql]));                        
            }
  }
  indexToRemove.sort();
  for(Integer i=indexToRemove.size()-1;i>=0;i--){
      //remove unwanted quotelines from list to process
      quotelineRecs.remove(indexToRemove[i]); 
  }
        // End of CPQ22-3838
      for(SBQQ__QuoteLine__c ql :  quotelineRecs)
      { 
        //CPQ22-5934 start
                if((ql.Quoting_Desk_Exception__c != null && ql.Quoting_Desk_Exception__c.contains('Renewal Exception - Line detail override')) 
                    || (ql.RWD_Deal_Ops_Exception__c !=null && ql.RWD_Deal_Ops_Exception__c.contains('Override renewal line details')))
                { 
                   isOverrideExcpPresent = true;
                }
                //CPQ22-5934 end
          //CPQ22-4537 start
          if(ql.Upgrade_Path__c!=null && ql.Product_Level__c!=null && ql.SBQQ__Product__r.Rel_SubsAsst__c==null 
             && ql.Account_s_Entitlement__c==null &&
             (ql.Quote_Line_Type__c=='New' || ql.Quote_Line_Type__c=='Renewal') && ql.SBQQ__Optional__c==false &&
             ql.SBQQ__Product__r.Product_Subtype__c != 'Scale MSP')           //ITNPI-2981: Condition added by Anjali to skip Utility upgrades
          {
              validationMSG = System.Label.Error_Msg_Account_s_Entitlement;
                    System.debug(LoggingLevel.DEBUG, 'inside non asset upgrade SKUs');
              break;   
          }
          else
          {
              if(!(ql.Upgrade_Path__c!=null && ql.Product_Level__c!=null && ql.SBQQ__Product__r.Rel_SubsAsst__c==null) && ql.Account_s_Entitlement__c!=null && (ql.Quote_Line_Type__c=='New' || ql.Quote_Line_Type__c=='Renewal')){
                  validationMSG = System.Label.Error_msg_on_non_upgrade_SKU;
                        System.debug(LoggingLevel.DEBUG, 'inside else non asset upgrade SKUs');
                  break;   
              }
          }   
       //CPQ22-4537 end   
       //add new validation error msg 
       if((String.isNotBlank(ql.SubscribedAssetNames__c) || String.isNotBlank(ql.Subscribed_Asset_Name__c)) &&  (ql.SBQQ__Product__r.Rel_SubsAsst__c!=null && ql.SBQQ__Product__r.Rel_SubsAsst__c!='' && ql.SBQQ__Product__r.Rel_SubsAsst__c.contains('Renew:RelatedAsst'))) 
       {
           Set<String> aa = new Set<String>();
           List<String> aaList = new List<String>();
           Set<String> bb = new Set<String>();
           List<String> bbList = new List<String>();
            if( String.isNotBlank(ql.SubscribedAssetNames__c))
               {
               aaList = ql.SubscribedAssetNames__c.split(',');
                for(String sst : aaList){
                     asstNames.add(sst.trim());
                        aa.add(sst.trim());
                         }
               }
              if( String.isNotBlank(ql.Subscribed_Asset_Name__c))
               {
               bbList = ql.Subscribed_Asset_Name__c.split(',');
                for(String sst : bbList){
                     asstNames.add(sst.trim());
                        bb.add(sst.trim());
                         }
               } 
               
          if((aaList!=null && bbList==null) || (aaList==null && bbList!=null) || !(aaList.size() == bbList.size() && aa.equals(bb))){
              validationMSG =  System.Label.Error_with_Subscribed_Asset_Fields;
              break;
          }
       }
       //end new validation error msg
       if(ql.SBQQ__Quote__r.RWD_Deal_Ops_Exception__c== null || ql.SBQQ__Quote__r.RWD_Deal_Ops_Exception__c== '' || !ql.SBQQ__Quote__r.RWD_Deal_Ops_Exception__c.contains('Override asset/date validation on submit for approval')){
           //get data for replace Scale from TPH
           if(ql.SBQQ__SubscriptionPricing__c == 'Fixed Price' && ql.Special_Program__c=='Replaced' && ql.Quote_Line_Type__c == 'New' && ql.SBQQ__ProductFamily__c == 'Rubrik Scale' && ql.Arroyo_Subsumed_Old_Contract_Line_Items__c!=null && ql.Arroyo_Subsumed_Old_Contract_Line_Items__c!=''){
                splitSubs =ql.Arroyo_Subsumed_Old_Contract_Line_Items__c.split(',');

                  if(splitSubs!= null && splitSubs.size() > 0){
                      List<String> subsCLI = new List<String>();
                      for(String st : splitSubs ){
                          subsCLI.add(st.trim());
                        mapScaleSubsum.put(ql.id,subsCLI);
                      }
                  }
           }
           if((ql.SBQQ__SubscriptionPricing__c == 'Fixed Price' && ql.Quote_Line_Type__c == 'Renewal' && ql.SBQQ__ProductFamily__c == 'Third Party License' && ql.Disposition_Reason__c == 'Replaced') || Test.isRunningTest()){
               mapTPHrenwCLI.put(ql.id,ql.SBQQSC__RenewedContractLine__c);
           }
           //CPQ22-4280 changed to contains check
           //error for missing Asset details : 
          if((ql.Quote_Line_Type__c == 'Renewal' &&(ql.Disposition_Reason__c == 'Renewing' || ql.Disposition_Reason__c == 'None' || ql.Disposition_Reason__c == '') && ql.SBQQ__Product__r.Rel_SubsAsst__c!=null && ql.SBQQ__Product__r.Rel_SubsAsst__c!='' && ql.SBQQ__Product__r.Rel_SubsAsst__c.contains('Renew:RelatedAsst')) && (ql.SubscribedAssetNames__c=='' || ql.SubscribedAssetNames__c==null || ql.Subscribed_Asset_Name__c == '' || ql.Subscribed_Asset_Name__c== null) && !isOverrideExcpPresent)//CPQ22-5934
          {
               validationMSG = System.Label.Error_with_Asset_Details;
                        System.debug(LoggingLevel.DEBUG, 'inside all blank');
               break;
          }
          //add common condition
          if(ql.Quote_Line_Type__c == 'Renewal' &&(ql.Disposition_Reason__c == 'Renewing' || ql.Disposition_Reason__c == 'None' || ql.Disposition_Reason__c == '') && ql.SBQQ__SubscriptionPricing__c == 'Fixed Price'){
               List<String> trimAssetNames = new List<String>();
               if( String.isNotBlank(ql.SubscribedAssetNames__c) )
               {
               subsasstNames = ql.SubscribedAssetNames__c.split(',');
                for(String sst : subsasstNames){
                   trimAssetNames.add(sst.trim());
                         }
               }
               if(trimAssetNames!= null && trimAssetNames.size()>0){
                  if(ql.SBQQ__Product__r.Rel_SubsAsst__c!=null && ql.SBQQ__Product__r.Rel_SubsAsst__c!='' && ql.SBQQ__Product__r.Rel_SubsAsst__c.contains('Renew:RelatedAsst')){
                      qlIdSrnoMap.put(ql.id,trimAssetNames);
                }
           //check for HW Support and NRD
              if(ql.SBQQ__RequiredBy__c!= null && ql.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c!= null && (ql.Product_Type__c == 'HW Support' || ql.SBQQ__ProductFamily__c  =='Non-Returnable Disk Service')){
                                System.debug(LoggingLevel.DEBUG, 'Inside HW support');
                   List<String> asstname =
                   mapReqIdandSrno.containsKey(ql.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c)?mapReqIdandSrno.get(ql.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c): new List<String>();
                   asstname.addAll(trimAssetNames);
                   mapReqIdandSrno.put(ql.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,asstname);
                                System.debug(LoggingLevel.DEBUG, 'mapReqIdandSrno>>'+mapReqIdandSrno);
              }
                //NRD under License
              else if(ql.SBQQ__RequiredBy__c!= null && ql.SBQQ__ProductFamily__c  =='Non-Returnable Disk Service'){
                                System.debug(LoggingLevel.DEBUG, 'inside NRD');
                  List<String> asstname =
                  mapReqIdandSrno.containsKey(ql.SBQQ__RequiredBy__c)?mapReqIdandSrno.get(ql.SBQQ__RequiredBy__c): new List<String>();
                  asstname.addAll(trimAssetNames);
                  mapReqIdandSrno.put(ql.SBQQ__RequiredBy__c,asstname);
               }
                            system.debug(LoggingLevel.DEBUG, 'mapReqIdandSrno>>'+mapReqIdandSrno);
          
          //check for s/w support skus
          if(ql.Sales_Comp_Category__c  =='SW SUPPORT' && ql.Product_Level__c =='Support' && ql.SBQQ__RequiredBy__c!= null && ql.SBQQ__RequiredBy__r.Licensing_Model__c == 'Perpetual'){
               mapPerpRscandSrno.put(ql.SBQQ__RequiredBy__c,trimAssetNames);
              }
                            System.debug(LoggingLevel.DEBUG, 'mapReqIdandSrno'+mapReqIdandSrno);
               
               }
           }
        //end common condition 
        if(ql.Quote_Line_Type__c == 'Renewal' &&(ql.Disposition_Reason__c == 'Renewing' || ql.Disposition_Reason__c == 'None' || ql.Disposition_Reason__c == '') && (ql.Product_Type__c == 'HW Support' ||  ql.SBQQ__ProductFamily__c  =='Non-Returnable Disk Service') && !isOverrideExcpPresent)//CPQ22-5934
             {
              if( !qlIdSrnoMap.isEmpty() && qlIdSrnoMap.containsKey(ql.Id) && qlIdSrnoMap.get(ql.Id).size() >0 && ql.SBQQ__Quantity__c !=qlIdSrnoMap.get(ql.Id).size()){
                            System.debug(LoggingLevel.DEBUG, 'inside Qunty error');
                      validationMSG =  System.Label.Error_with_Asset_Details;
                      break;
                  }
              }
       }  
       //CPQ22-4280 missing Asset Information error
        /* if(ql.SBQQ__Quote__r.RWD_Deal_Ops_Exception__c== null || ql.SBQQ__Quote__r.RWD_Deal_Ops_Exception__c== '' || !ql.SBQQ__Quote__r.RWD_Deal_Ops_Exception__c.contains('Edition Upgrade Asset Validation')){
          if(ql.Quote_Line_Type__c == 'New' && String.isNotBlank(ql.SBQQ__Product__r.Rel_SubsAsst__c) && ql.SBQQ__Product__r.Rel_SubsAsst__c.contains('New:RelatedAsst') && String.isBlank(ql.SubscribedAssetNames__c)){
                        System.debug(LoggingLevel.DEBUG, 'Inside Missing Asset');
              validationMSG = System.Label.Asset_Missing_Edition_SKU;
              break;
          }
          }
          */
                System.debug(LoggingLevel.DEBUG, '@@asstNames '+asstNames);
  }
//end of for loop

            //FY25SR-1231 start
            Set<String> refreshedAssetNames = new Set<String>();
            Set<Id> refreshedAssetIds = new Set<Id>();
            List<String> dispositions = new List<String> {'Renewing', 'Converted', 'Upgraded'};
            List<SBQQ__QuoteLine__c> renewalLines = new List<SBQQ__QuoteLine__c>();
            //FY25SR-1231 end
            Set<String> allAssetsFromQLs = new Set<String>(asstNames);
            for(Asset ast : [Select id,Name,SerialNumber,Product_Usable_Capacity__c, (SELECT Id, Type__c FROM Scale_Assets__r) from Asset where SerialNumber IN: allAssetsFromQLs]){
          assIdCapacity.put(ast.SerialNumber,ast.Product_Usable_Capacity__c);
                foundAssets.add(ast.SerialNumber);
                //FY25SR-1231 start
                for (Scale_Entitlement__c  scaleEnt : ast.Scale_Assets__r){
                    if (scaleEnt.Type__c !=null && scaleEnt.Type__c.containsIgnoreCase('refreshed')){
                        refreshedAssetNames.add(ast.SerialNumber);
                        refreshedAssetIds.add(ast.Id);
                    }
                }
                //FY25SR-1231 end
          }
      
      for(SBQQ__QuoteLine__c ql :  quotelineRecs){
                Boolean hasRefreshedAsset = false; //FY25SR-1231
                
          if(ql.SBQQ__Quote__r.RWD_Deal_Ops_Exception__c== null || ql.SBQQ__Quote__r.RWD_Deal_Ops_Exception__c== '' || !ql.SBQQ__Quote__r.RWD_Deal_Ops_Exception__c.contains('Override asset/date validation on submit for approval'))
          {
              if((ql.Quote_Line_Type__c == 'Renewal' && ql.SBQQ__SubscriptionPricing__c == 'Fixed Price' 
                        && (dispositions.contains(ql.Disposition_Reason__c) || ql.Disposition_Reason__c == 'None' || ql.Disposition_Reason__c == '')) 
             && (ql.SBQQ__Product__r.Rel_SubsAsst__c!=null && ql.SBQQ__Product__r.Rel_SubsAsst__c!='' && ql.SBQQ__Product__r.Rel_SubsAsst__c.contains('Renew:RelatedAsst')))
              {      
                        System.debug(LoggingLevel.DEBUG, '@@ql '+ql);

                        renewalLines.add(ql); //FY25SR-1231

          //capacity error //changes related to CPQ22-4515
          if(!assIdCapacity.isEmpty() && ql.SBQQ__Product__r.Product_Level__c!= '' &&  ql.SBQQ__Product__r.Product_Level__c!= null && ql.SBQQ__Product__r.Product_Level__c=='Hybrid Software'){
              
              Double capacity = 0;
              if( String.isNotBlank(ql.SubscribedAssetNames__c) )
               {
               subsasstNames = ql.SubscribedAssetNames__c.split(',');
                for(String sst : subsasstNames){
                    //FY25SR-1231 start
                    if (refreshedAssetNames.contains(sst)){
                        hasRefreshedAsset = true;
                    }
                    //FY25SR-1231 end
                   if(assIdCapacity.containsKey(sst.trim())) 
                   {
                       capacity+= assIdCapacity.get(sst.trim());
                   }
                                    else if(String.isBlank(validationMSG)){
                                        System.debug(LoggingLevel.DEBUG, 'missing Product usable quantity');
                    validationMSG = System.Label.Error_with_Asset_Details;
                              break;
                   } 
                 }
                                
                                if(String.isBlank(validationMSG) && ql.SBQQ__Quantity__c != capacity && !hasRefreshedAsset){
                                    System.debug(LoggingLevel.DEBUG, 'inside Quntity error');
                      validationMSG =  System.Label.Error_with_Asset_Details;
                      break;
              }
            }
          }
         }  
              
                    if((((ql.SBQQ__SubscriptionPricing__c == 'Fixed Price' && ql.Special_Program__c=='Replaced' && ql.Quote_Line_Type__c == 'New' && ql.SBQQ__ProductFamily__c == 'Rubrik Scale') && (ql.SubscribedAssetNames__c=='' || ql.SubscribedAssetNames__c==null || ql.Subscribed_Asset_Name__c == '' || ql.Subscribed_Asset_Name__c== null) ))){
                      if(!mapScaleSubsum.isEmpty() && !mapTPHrenwCLI.isEmpty() && mapScaleSubsum.containsKey(ql.Id)){
                          for(String str : mapTPHrenwCLI.values()){
                              if(mapScaleSubsum.get(ql.id).contains(str)){
                                  
                                  isTPHreplaced = true;
                              }
                          }
                      }
                        if(String.isBlank(validationMSG) && !isTPHreplaced){
                          validationMSG = System.Label.Error_with_Asset_Details;
                      }
                  }
              
          //if(ql.Quote_Line_Type__c == 'Renewal' && (ql.Disposition_Reason__c == 'Renewing' || ql.Disposition_Reason__c == 'None' || ql.Disposition_Reason__c == '')){
          //List<String> srnoTrimLst = new List<String>();
          if(String.isBlank(validationMSG) && !qlIdSrnoMap.isEmpty() && qlIdSrnoMap.containsKey(ql.id) && !isOverrideExcpPresent){//CPQ22-5934
              for(String srno : qlIdSrnoMap.get(ql.id)){
                  String asstname=srno.trim();
       
                       if((!mapReqIdandSrno.isEmpty() && mapReqIdandSrno.containsKey(ql.Id) && !mapReqIdandSrno.get(ql.Id).contains(asstname)) || 
                       (!mapPerpRscandSrno.isEmpty() && !mapPerpRscandSrno.get(ql.id).contains(asstname))){
        
                          validationMSG = System.Label.Error_with_Asset_Details;
                                    System.debug(LoggingLevel.DEBUG, 'validation'+validationMSG);
              
                          break;
                      }
              }
          }
        }                
      }

            //FY25SR-1231 start
            if (String.isBlank(validationMSG) && renewalLines!=null && renewalLines.size()>0 && refreshedAssetIds != null && refreshedAssetIds.size() > 0){//CPQ22-5934
                validationMSG = validateSharedAssetQty(refreshedAssetIds, refreshedAssetNames, renewalLines, dispositionLines);
            }
            //FY25SR-1231 end
            allAssetsFromQLs.removeall(foundAssets);
            if (String.isBlank(validationMSG) && !allAssetsFromQLs.isEmpty()) {
            String missingAssetString = String.join(new List<String>(allAssetsFromQLs), ', ');
            validationMSG = 'Invalid Serial Number ' + missingAssetString;
            }
      if(validationMSG!= null && validationMSG!=''){
      return validationMSG;
            }
            else{
                return null;
}
        }
        else return null;
    }


    /**
    * @description : validate qty for shared assets
    * @param refreshedAssetIds refresh asset Ids
    * @param refreshedAssetNames refreshed asset names
    * @param renewalLines renewal quote lines
    * @param dispositionLines disposition lines
    * @return validation message
    * Story : FY25SR-1231
    */ 
    public static String validateSharedAssetQty(Set<Id> refreshedAssetIds, Set<String> refreshedAssetNames, List<SBQQ__QuoteLine__c> renewalLines, List<CPQ_Disposition_Quote_Line__c> dispositionLines){

        try {

        List<SharedAssetGroup> sharedAssetGroups = new List<SharedAssetGroup>();
            Map<Id, Integer> renewalQtyByEntorCLI = new Map<Id, Integer>();
        String validationMSG;

        //get entitlements
        List<Entitlement> ents = [
            SELECT Id, ContractLineItemId, Quantity__c,
                (SELECT Id, Asset__c, Asset__r.Product_Usable_Capacity__c, Asset__r.SerialNumber, Asset__r.ProductCode FROM Scale_Entitlements__r WHERE Renewal_Category__c!='Refreshed') 
            FROM Entitlement 
            WHERE ID IN (SELECT Entitlement__c FROM Scale_Entitlement__c WHERE Asset__c IN :refreshedAssetIds)
            AND (NOT Renewal_Category__c IN ('Renewed', 'Replaced', 'Converted', 'Upgraded', 'Converted to L3'))
        ];

        //get renewal quantities
        for (SBQQ__QuoteLine__c ql : renewalLines){
                Id entId;

                if(!String.isBlank(ql.Replacement_Details__c)) {
                    ReplacementJson lineJson = (ReplacementJson) JSON.deserialize(ql.Replacement_Details__c, ReplacementJson.class);
                    if(lineJson.rowValues != null){
                        for(ReplacementJson.RowDetail row : lineJson.rowValues) {
                            entId = row.entId;
                        }
                    }
                }
                
                Id key = entId != null ? entId : ql.SBQQSC__RenewedContractLine__c;

                if (key != null){
                    if (renewalQtyByEntorCLI.containsKey(key)){
                        renewalQtyByEntorCLI.put(key, renewalQtyByEntorCLI.get(key) + (Integer) ql.SBQQ__Quantity__c);
                    }
                    else {
                        renewalQtyByEntorCLI.put(key, (Integer) ql.SBQQ__Quantity__c);
                }
            }
        }

        //get disposed quantities
        for (CPQ_Disposition_Quote_Line__c disposeLine : dispositionLines){
                Id entId;

                if(!String.isBlank(disposeLine.Replacement_Detail__c)) {
                    ReplacementJson lineJson = (ReplacementJson) JSON.deserialize(disposeLine.Replacement_Detail__c, ReplacementJson.class);
                    if(lineJson.rowValues != null){
                        for(ReplacementJson.RowDetail row : lineJson.rowValues) {
                            entId = row.entId;
                        }
                    }
                }

                Id key = entId != null ? entId : disposeLine.RenewedContractLine__c;

                if (key != null){
                    if (renewalQtyByEntorCLI.containsKey(key)){
                        renewalQtyByEntorCLI.put(key, renewalQtyByEntorCLI.get(key) + (Integer) disposeLine.Quantity__c);
                    }
                    else {
                        renewalQtyByEntorCLI.put(key, (Integer) disposeLine.Quantity__c);
                }
            }
        }

            //system.debug(LoggingLevel.DEBUG, 'validateSharedAssetQty refreshedAssetNames '+refreshedAssetNames);

        for (Entitlement ent : ents){
            SharedAssetGroup sharedGroup;

            //find shared group
            for (Scale_Entitlement__c scaleEnt : ent.Scale_Entitlements__r){
                for (SharedAssetGroup sharedGroupCheck : sharedAssetGroups){
                    if (sharedGroupCheck.assetIds != null && sharedGroupCheck.assetIds.contains(scaleEnt.Asset__c)){
                        sharedGroup = sharedGroupCheck;
                    }
                }
            }

            //create group if not found
            if (sharedGroup == null){
                sharedGroup = new SharedAssetGroup();
                sharedAssetGroups.add(sharedGroup);
            }

            sharedGroup.entIds.add(ent.Id);
            for (Scale_Entitlement__c scaleEnt : ent.Scale_Entitlements__r){
                if (sharedGroup.assetIds != null && !sharedGroup.assetIds.contains(scaleEnt.Asset__c)){
                    sharedGroup.assetIds.add(scaleEnt.Asset__c);
                    sharedGroup.assets.add(scaleEnt.Asset__r.SerialNumber);
                        sharedGroup.assetProds.add(scaleEnt.Asset__r.ProductCode);
                    sharedGroup.assetTotal += (Integer) scaleEnt.Asset__r.Product_Usable_Capacity__c;
                }
            }

            //get renewed qty or original qty
                Id key = renewalQtyByEntorCLI.containsKey(ent.Id) ? ent.Id : renewalQtyByEntorCLI.containsKey(ent.ContractLineItemId) ? ent.ContractLineItemId : null;
                Integer entQuantity =  (Integer) (key !=null ? renewalQtyByEntorCLI.get(key) : ent.Quantity__c);
            sharedGroup.entTotal += entQuantity;
        }


        //validate
        if (sharedAssetGroups != null && sharedAssetGroups.size() > 0){
            for (SharedAssetGroup sharedGroup : sharedAssetGroups){
                    //System.debug(LoggingLevel.DEBUG, 'validateSharedAssetQty shared group = '+sharedGroup);
                    if (sharedGroup.assetProds != null && sharedGroup.assetProds.size() == 1 && 
                    (sharedGroup.assetProds.contains('7402') || (sharedGroup.assetProds.contains('7412') && sharedGroup.assetTotal - sharedGroup.entTotal == 15))){
                        continue;
                    }
                if (sharedGroup.entTotal != sharedGroup.assetTotal){
                    validationMSG =  System.Label.Error_with_Asset_Details + '\n at shared asset';
                }
            }                
        }

        return validationMSG;
    }
        catch(Exception e){
            LogError.logCustomError('QuoteExtController', e.getMessage(), e.getStackTraceString(), 'validateSharedAssetQty');
            return null;
        }
    }
    
    /**
    * @description : shared asset group wrapper for FY25SR-1231
    */ 
    public class SharedAssetGroup{
        Set<Id> entIds = new Set<Id>();
        Set<Id> assetIds = new Set<Id>();
        List<String> assets = new List<String>();
        List<String> assetProds = new List<String>();
        Integer entTotal = 0;
        Integer assetTotal = 0; 
  }
    
    //MS CPQ22-3092 TradeUp Invalidate Check 
    /**
* @description : check invalid tradeup
* @param strgOfAssets assets
* @return message
*/ 
    @AuraEnabled
    public static String checkInvalidTradeUp(String strgOfAssets){
        String validationMSG;
        List<String> listOfAssets = strgOfAssets != null ? strgOfAssets.split(',\\s*|\\s+|\\n') : new List<String>();
        //Set<String> invalidAstSet = new Set<String>();

        for(Asset ast : [Select id ,Name,SerialNumber, Expiration_Date__c from Asset where SerialNumber IN: listOfAssets]){
            //Date elgblTrUpDate = ast.Expiration_Date__c.addDays(90);
            if(ast.Expiration_Date__c != null && Date.today() >= ast.Expiration_Date__c){
                System.debug(LoggingLevel.DEBUG, 'Inside Invalidate Quote or Cancel TradeUp');
                //invalidAstSet.add(ast.SerialNumber);
                validationMSG =  System.Label.Expired_Trade_Up_Credit;
                break;
            }
        }
        /* MS Placeholder for Showing Invalida Asset Names
        if(!invalidAstSet.isEmpty()){
            return String.join((Iterable<String>)invalidAstSet, ', ');
        }
        */
        return validationMSG;
    }
    /**fetch quote lines to be displayed on the Dispose Lines page*/
    @AuraEnabled
    /**
     * @description getQuoteLines
     * @return quotelines
     * @param quoteId
     */
    public static List<SBQQ__QuoteLine__c> getQuoteLines(String quoteId){ 
        List<SBQQ__Quote__c> allQuotes = new List<SBQQ__Quote__c>();
        Map<Id, SBQQ__QuoteLine__c> quoteLinesToShow = new Map<Id, SBQQ__QuoteLine__c>();
        //change for SF-72381
        allQuotes = [Select Id, Name, RWD_Deal_Ops_Exception__c,Quoting_Desk_Exception__c, (SELECT Id,Name, SBQQ__ProductCode__c, Subscribed_Asset_Name__c,SubscribedAssetNames__c,Quote_Line_Type__c ,Product_Type__c,
                                                                  SBQQ__Product__c, SBQQ__RequiredBy__r.SBQQ__Product__c, SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Product__c,SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,
                                                                  SBQQ__Product__r.Restrict_Quoting_For__c,SBQQ__RequiredBy__r.SBQQ__Product__r.Restrict_Quoting_For__c,SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Restrict_Quoting_For__c,
                                                                  Licensing_Model__c, SBQQ__RequiredBy__c, SBQQ__Optional__c, SBQQ__Existing__c, SBQQ__RequiredBy__r.Product_Type__c, 
                                                                  SBQQ__RequiredBy__r.SBQQ__Optional__c, SBQQ__RequiredBy__r.Arroyo_Subsumed_Old_Contract_Line_Items__c,SBQQ__RequiredBy__r.Subscribed_Asset_Name__c, SBQQ__RequiredBy__r.SubscribedAssetNames__c,
                                               Arroyo_Subscribed_Asset_Name__c, Arroyo_Subsumed_Old_Contract_Line_Items__c, SBQQ__Product__r.IsHardwareNotRequiredForHybridLicense__c, SBQQ__RequiredBy__r.SBQQ__Existing__c
                                               FROM SBQQ__LineItems__r WHERE Quote_Line_Type__c = 'New'
                                               ORDER BY SBQQ__Number__c ASC) FROM SBQQ__Quote__c where Id =: quoteId AND ProcessType__c != 'Aspen'];
        Map<Id, SBQQ__QuoteLine__c> allrscSKU = new Map<Id, SBQQ__QuoteLine__c>();
        Map<Id, SBQQ__QuoteLine__c> mapOfLineItems = new Map<Id, SBQQ__QuoteLine__c>();
        Set<Id> rscSKUswithHW = new Set<Id>();
        Set<Id> skuAll = new Set<Id>();
        
    //If New Quote Line and Deal Ops Exception given, then only proceed.
    if(allQuotes != null && !allQuotes.IsEmpty()){
            for(SBQQ__Quote__c quote : allQuotes){
                SBQQ__Quote__c existingQuote = allQuotes[0];
                for (SBQQ__QuoteLine__c quoteLine : existingQuote.SBQQ__LineItems__r) {
                    mapOfLineItems.put(quoteLine.id, quoteLine);
                    //change for SF-72381
                    if (quoteLine.Quote_Line_Type__c == 'New' && existingQuote.Quoting_Desk_Exception__c != null){ 
                        //SW without HW - If Quote Line Type = New AND Deal Ops Exception = "SW Without HW" , If RequiredBy != null AND Product = Hardware AND QuoteLine.Optional = TRUE, then check for fields and then error.
                        if (existingQuote.Quoting_Desk_Exception__c.contains('Quoting Exception - SW without HW') ) { //change for SF-72381
                            //Get All RSCs present in the Quote 
                            if(!quoteLine.SBQQ__Product__r.IsHardwareNotRequiredForHybridLicense__c) {
                                allrscSKU.put(quoteLine.Id, quoteLine);
                            } 
                            //Get All RSC Lines associated with HW, where Optional = false. This will give the true HWs associated with the SW.
                            if (quoteLine.SBQQ__RequiredBy__c != null && (quoteLine.Product_Type__c == 'Hardware' || quoteLine.Product_Type__c == 'Add-On Node') && !quoteLine.SBQQ__Optional__c && !quoteLine.SBQQ__Existing__c) {
                                rscSKUswithHW.add(quoteLine.SBQQ__RequiredBy__c);
                            }
                            
                            //Check for HW Support which is associated with HW where Optional = TRUE. In such cases, check for the mandatory fields for SW without HW OR
                            //Check for HW which is associated with RSC where Optional = TRUE. In such cases, check for the mandatory fields for SW without HW.
                            
                            //Add to the map to show the list of all HW which has Optional = true and Required By has details blank.
                            if (quoteLine.SBQQ__RequiredBy__c != null && (quoteLine.Product_Type__c == 'Hardware' || quoteLine.Product_Type__c == 'Add-On Node') && (quoteLine.SBQQ__Optional__c || quoteLine.SBQQ__Existing__c)) {
                                quoteLinesToShow.put(mapOfLineItems.get(quoteLine.SBQQ__RequiredBy__c).Id, mapOfLineItems.get(quoteLine.SBQQ__RequiredBy__c));
                            } 
                            //Add to the map to show the list of all HW Support which has Required By as Optional = true and has details blank on itself.
                            if (((quoteLine.SBQQ__RequiredBy__c == null && quoteLine.Product_Type__c == 'HW Support') || (quoteLine.SBQQ__RequiredBy__c != null && (quoteLine.SBQQ__RequiredBy__r.Product_Type__c == 'Hardware' || quoteLine.SBQQ__RequiredBy__r.Product_Type__c == 'Add-On Node') && quoteLine.Product_Type__c == 'HW Support' && (quoteLine.SBQQ__RequiredBy__r.SBQQ__Optional__c || quoteLine.SBQQ__RequiredBy__r.SBQQ__Existing__c))
                               )) {
                                quoteLinesToShow.put(quoteLine.Id, quoteLine);
                            }
                            //CPQ22-4680 starts//
                            if((quoteLine.SBQQ__Product__c != NULL && quoteLine.SBQQ__Product__r.Restrict_Quoting_For__c != NULL && quoteLine.SBQQ__Product__r.Restrict_Quoting_For__c.contains('Bypass SW Without HW Validation')) ||
                               (quoteLine.SBQQ__RequiredBy__c != NULL && ((quoteLine.SBQQ__RequiredBy__r.SBQQ__Product__c != NULL && quoteLine.SBQQ__RequiredBy__r.SBQQ__Product__r.Restrict_Quoting_For__c != NULL && quoteLine.SBQQ__RequiredBy__r.SBQQ__Product__r.Restrict_Quoting_For__c.contains('Bypass SW Without HW Validation')) ||
                               (quoteLine.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c != NULL && quoteLine.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Product__c != NULL && quoteLine.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Restrict_Quoting_For__c != NULL && quoteLine.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Restrict_Quoting_For__c.contains('Bypass SW Without HW Validation'))))){
                                skuAll.add(quoteLine.Id);
                            }
                           //CPQ22-4680 ends//

                        }
                    }
                }
            }
            //Check if the RSC SKUs are associated with HW which has Optional = False, 
            if (allrscSKU != null && !allrscSKU.isEmpty()) {
                for (SBQQ__QuoteLine__c quoteLineNew : allrscSKU.values()) {
                    if (!rscSKUswithHW.contains(quoteLineNew.Id) && !skuAll.contains(quoteLineNew.Id)) {
                        System.debug(LoggingLevel.DEBUG, 'Adding--'+quoteLineNew.Id);
                        quoteLinesToShow.put(quoteLineNew.Id, quoteLineNew);
                    }
                }
            }
        }
        return quoteLinesToShow.values();
    }

    @AuraEnabled
    /**
     * @description To get all Hardware Lines where Required By = null*
     * @return hwQuoteLinesToShow
     * @param quoteId
     */
    public static List<SBQQ__QuoteLine__c> getHWQuoteLines(String quoteId){ 
        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
        Map<Id, SBQQ__QuoteLine__c> hwQuoteLinesToShow = new Map<Id, SBQQ__QuoteLine__c>();
        //change for SF-72381
        quoteList = [Select Id, Name, RWD_Deal_Ops_Exception__c,Quoting_Desk_Exception__c,(Select Id, Name, SBQQ__ProductCode__c,Quote_Line_Type__c ,Product_Type__c,
                                                                  Licensing_Model__c, SBQQ__Optional__c, SBQQ__RequiredBy__c 
                                               FROM SBQQ__LineItems__r WHERE Quote_Line_Type__c = 'New' AND 
                                                  (Product_Type__c = 'Hardware' OR Product_Type__c = 'Add-On Node') AND 
                                                  SBQQ__RequiredBy__c = null
                                                                  ORDER BY SBQQ__Number__c ASC) FROM SBQQ__Quote__c where Id =: quoteId AND ProcessType__c != 'Aspen'];
        if(quoteList != null && !quoteList.IsEmpty()){
            for(SBQQ__Quote__c newQuote : quoteList){
                SBQQ__Quote__c nQuote = quoteList[0];
                for (SBQQ__QuoteLine__c qlRec : nQuote.SBQQ__LineItems__r) {
                    //change for SF-72381
                    if (qlRec.Quote_Line_Type__c == 'New' && nQuote.Quoting_Desk_Exception__c != null){ 
                        //Case 1: Check for HW without SW. In such cases, check for the mandatory fields for HW without SW.
                        if (nQuote.Quoting_Desk_Exception__c.contains('Quoting Exception - HW without SW')) { //change for SF-72381
                            hwQuoteLinesToShow.put(qlRec.Id, qlRec);
                      }
                    }
                }
            }
        }
        return hwQuoteLinesToShow.values();
    }
    
    @AuraEnabled 
    /**
     * @description Method to get the picklist values from the field
     * @param objectAPIName object apiname
     * @param fieldAPIName field name
     * @return map of picklist options
     */
    public static Map<String, String> getIndustryFieldValue(String objectAPIName, String fieldAPIName){
        Map<String, String> options = new Map<String, String>();
        Schema.SObjectType convertObj = Schema.getGlobalDescribe().get(objectAPIName);
        Schema.DescribeSObjectResult desResult = convertObj.getDescribe();
        Schema.DescribeFieldResult fieldResult = desResult.fields.getMap().get(fieldAPIName).getDescribe();
        
        List<Schema.PicklistEntry> pValues = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry p: pValues) {
            
            options.put(p.getValue(), p.getLabel());
        }
        return options;
    }
    
    @AuraEnabled
    /**
     * @description Method to update Quote Lines
     * @param qlvsSelected selected qotelines
     * @param changedQLList changed quotelines
     * @param quoteId quote id
     * @return quotelines update list
     */
    public static List<SBQQ__QuoteLine__c> updateQuoteLinesforHW(Map<String, String> qlvsSelected, List<SBQQ__QuoteLine__c> changedQLList, String quoteId){
        Map<Id, SBQQ__QuoteLine__c> mapOfChanged = new Map<Id, SBQQ__QuoteLine__c>();
        Map<Id, SBQQ__QuoteLine__c> quoteLinesToUpdate = new Map<Id, SBQQ__QuoteLine__c>();
        
        if (changedQLList != null && !changedQLList.isEmpty()) {
            for (SBQQ__QuoteLine__c qlRec : changedQLList) {
                mapOfChanged.put(qlRec.Id, qlRec);
            }
        }
        List<SBQQ__QuoteLine__c> selectedLines = [SELECT Id, SBQQ__ProductCode__c, Name,
                                                  Licensing_Model__c, Subscribed_Asset_Name__c,SubscribedAssetNames__c, Arroyo_Subsumed_Old_Contract_Line_Items__c
                                               FROM SBQQ__QuoteLine__c where (ID IN : qlvsSelected.keySet() OR Id IN : changedQLList)];
        if (selectedLines != null && !selectedLines.isEmpty()) {
            for (SBQQ__QuoteLine__c qlRec : selectedLines) {
                if (qlvsSelected != null && !qlvsSelected.isEmpty()) {
                    qlRec.Licensing_Model__c = qlvsSelected.get(qlRec.Id) != null ? qlvsSelected.get(qlRec.Id) : qlRec.Licensing_Model__c;
                    quoteLinesToUpdate.put(qlRec.Id, qlRec);
                }
                if (changedQLList != null && !changedQLList.isEmpty()) {
                    if (mapOfChanged != null && !mapOfChanged.isEmpty() && mapOfChanged.get(qlRec.Id) != null) {
                        if ((qlRec.SubscribedAssetNames__c != mapOfChanged.get(qlRec.Id).SubscribedAssetNames__c) || 
                            (qlRec.Arroyo_Subsumed_Old_Contract_Line_Items__c != mapOfChanged.get(qlRec.Id).Arroyo_Subsumed_Old_Contract_Line_Items__c)
                           ){
                            qlRec.SubscribedAssetNames__c = mapOfChanged.get(qlRec.Id).SubscribedAssetNames__c;
                            qlRec.Subscribed_Asset_Name__c = mapOfChanged.get(qlRec.Id).SubscribedAssetNames__c;
                            qlRec.Arroyo_Subsumed_Old_Contract_Line_Items__c = mapOfChanged.get(qlRec.Id).Arroyo_Subsumed_Old_Contract_Line_Items__c;
                            quoteLinesToUpdate.put(qlRec.Id, mapOfChanged.get(qlRec.Id));
                        }
                  }
              }
            }
        }
        update quoteLinesToUpdate.values();
        return quoteLinesToUpdate.values();
    } 
    //CPQ22-3975 Ends

    /***********************************************************************************************************
    * Method Name          : getLowerAndUpperBound
    * Date Created/Modified: 20/05/2025 - FY25SR-1745
    * Author               : Sumedha
    * @description         : Fetches the Lower Bound and Upper bound of Ary Criteria to be passed for SMS UI Screen
    * @return              : Custom Metadata record to be passed to the UI
    /**********************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static Replacement_Field_Mapping__mdt getLowerAndUpperBound() {
        Replacement_Field_Mapping__mdt objectData = 
            [SELECT Id, LowerBoundM__c, UpperBoundM__c 
               FROM Replacement_Field_Mapping__mdt 
              WHERE DeveloperName = :ReplacementConstants.REPLACEMENT_FILTER_CRITERIA_MDT];
        return objectData;
    }
    //CPQ22-5720 starts
   /**
 * @description Updates exception values on a quote record based on the custom approval submission
 * @param valuesStr Computed exception values.
 * @param recordId  ID of the quote to update.
 * @return The updated SBQQ__Quote__c record.
 */
    @AuraEnabled
    public static SBQQ__Quote__c processExcpValues(String valuesStr, Id recordId) {
        SBQQ__Quote__c q ;
        if(String.isNotBlank(recordId)){ 
         q = [SELECT Id,ExceptionsOnQuote__c  FROM SBQQ__Quote__c WHERE Id = :recordId LIMIT 1];
         q.ExceptionsOnQuote__c = null;
        }
        if (String.isNotBlank(valuesStr)) {
        String decodedVal = valuesStr.replace('&lt;', '<').replace('&gt;', '>').replace('&#36;', '$');
        q.ExceptionsOnQuote__c = decodedVal;
                     }
        update q;
    
     SBQQ__Quote__c quo = [select Id,SBQQ__NetAmount__c,ExceptionsOnQuote__c,QuoteApprovalCategory__c, Scale_Eligible__c,Selective_Account_Eligible_for_RCDM_T__c,Eligible_for_RCDM_T__c,RCDMCount__c
        ,SBQQ__Account__r.RCDMT_EOL_Date__c,RCDMT_EOL_Date__c,RWD_Opportunity_Close_Date__c,Is_Customer_Fully_Transitioned__c,Opportunity_Program__c,RWD_Deal_Ops_Exception__c
        ,RWD_Sales_Rep_Exception__c,RWD_Sales_Rep_Exception_Justification__c, SBQQ__StartDate__c,Polaris_Conversion__c,CreatedDate,Is_Scale_Utility_Quote__c
        ,Installed_By__c,Opportunity_Stage__c,Running_User_Profile__c,ApprovalStatus__c,Is_Selected_Partners_Customers_for_L3__c,Count_of_Rubrik_Basic_Edition__c
        ,Discount_Justification__c,SBQQ__Type__c,Discount_Floor_Breached__c,SBQQ__Account__c,Is_Refreshed_Identifier__c,Non_Standard_billing_term_detail__c
        ,Non_Standard_billing_flag__c,Is_RWD_Polaris_Quote__c,OpportunitySubType__c,Discounted_Units_due_to_CSAT_or_Sizing__c,Eligible_for_Onsite_Consulting__c,ETM_Area__c
        ,RWD_Eligible_LA_DA_Products_RSCP__c,Trade_Up_Serial_Numbers__c,ProcessType__c,RSCP_count__c,Manual_Fulfillment_Quote__c, SBQQ__ExpirationDate__c,Is_Data_Issue__c,SBQQ__SubscriptionTerm__c
        ,SBQQ__Opportunity2__r.Bypass_PSO__c, Opportunity_Type__c,Todays_Date__c, Quoting_Desk_Exception__c
         from sbqq__quote__c where id = :recordId LIMIT 1];
         return quo;
}

    /***********************************************************************************************************
    * Method Name          : quoteValidateAPI
    * Date Created/Modified: 03/12/2025 - CPQ22-6091
    * Author               : Mustakim
    * @description         : Calls QuoteValidator to evaluate product validation rules and prevent cloned Quote submission without proper calculation.
    * @param quoteId       : Id of the Quote to be evaluated.
    * @return               : Validation messages to be shown on the UI, or null/empty if no issues.
    /**********************************************************************************************************/
    @AuraEnabled
    public static String quoteValidateAPI(Id quoteId) {
        String valMsg;
        
        if(quoteId != null){
            QuoteReader reader = new QuoteReader();
            QuoteModel quote = reader.read(quoteId);

            String res = SBQQ.ServiceRouter.load(
                'SBQQ.QuoteAPI.QuoteValidator', 
                null, 
                JSON.serialize(quote)
            );
            List<String> msgs = (List<String>) JSON.deserialize(
                res, 
                                                                List<String>.class
                                                            );
            if(!msgs.isEmpty()){ valMsg = String.join(msgs, '\n');
            }
        }
        
        return valMsg;
    }
}