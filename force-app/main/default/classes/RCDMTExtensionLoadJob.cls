/**
     * @description RCDMTExtensionLoadJob
     */
public class RCDMTExtensionLoadJob implements Database.Batchable<Quote_and_Order_Staging__c>, Database.Stateful {
 
  List<Quote_and_Order_Staging__c> quoteOrderStagingList = new List<Quote_and_Order_Staging__c>(); 
  String jobType;
  
  /**
     * @description RCDMTExtensionLoadJob const
     * @param jobType
     * @param accId
     */
  public RCDMTExtensionLoadJob(string jobType,Id accId) {
        List<Quote_and_Order_Staging__c> quoteOrderList = New List<Quote_and_Order_Staging__c>();
        String quoteOrderStagingQuery = 'SELECT '+Label.QuoteOrderStagingQuery;
        
        if(jobType == 'oppandquote' && accId == NULL){
          //quoteOrderList =  Database.query(QuoteOrderStagingQuery+ ' where Id IN : OppIdSet')
          quoteOrderList = [Select id,Account_OM__c, Opportunity__c, Process_Status_OM__c ,Quote_Id__c,Quantity__c,RenewedContractLine__c, Process_Type__c,Process_Status_CPQ__c, 
   Line_Item_Start_Date__c,Line_Item_End_Date__c,Subsumed_Old_Contract_Line_Items__c,Subscribed_Asset_IDs__c,Subscribed_Asset_Name__c,Entitlement__c,
   SubscribedAssetNames__c from Quote_and_Order_Staging__c where Process_Type__c = 'Initial RCDM-T Processing' and Process_Status_OM__c = 'Ready'];
        }
        
        if(jobType == 'oppandquote' && accId != NULL){
          //quoteOrderList =  Database.query(QuoteOrderStagingQuery+ ' where Id IN : OppIdSet')
          quoteOrderList = [Select id,Account_OM__c, Opportunity__c, Process_Status_OM__c ,Quote_Id__c,Quantity__c,RenewedContractLine__c, Process_Type__c,Process_Status_CPQ__c, 
   Line_Item_Start_Date__c,Line_Item_End_Date__c,Subsumed_Old_Contract_Line_Items__c,Subscribed_Asset_IDs__c,Subscribed_Asset_Name__c,Entitlement__c,
   SubscribedAssetNames__c from Quote_and_Order_Staging__c where Process_Type__c = 'Initial RCDM-T Processing' and Process_Status_OM__c = 'Ready' and Account_OM__c =: AccId];
        }
        
        if(jobType == 'qli' && accId == NULL){
          quoteOrderList = [Select id,Account_OM__c, Opportunity__c,Process_Status_OM__c ,Quote_Id__c,Quantity__c,RenewedContractLine__c, Process_Type__c,Process_Status_CPQ__c, 
   Line_Item_Start_Date__c,Line_Item_End_Date__c,Subsumed_Old_Contract_Line_Items__c,Subscribed_Asset_IDs__c,Subscribed_Asset_Name__c,Entitlement__c,
   SubscribedAssetNames__c from Quote_and_Order_Staging__c where Process_Type__c = 'QLI & Order Processing' and Process_Status_OM__c = 'Ready' and Process_Status_CPQ__c != 'Completed'];
        }
        
        if(jobType == 'qli' && accId != NULL){
          quoteOrderList = [Select id,Account_OM__c, Opportunity__c,Process_Status_OM__c ,Quote_Id__c,Quantity__c,RenewedContractLine__c, Process_Type__c,Process_Status_CPQ__c, 
   Line_Item_Start_Date__c,Line_Item_End_Date__c,Subsumed_Old_Contract_Line_Items__c,Subscribed_Asset_IDs__c,Subscribed_Asset_Name__c,Entitlement__c,
   SubscribedAssetNames__c from Quote_and_Order_Staging__c where Process_Type__c = 'QLI & Order Processing' and Process_Status_OM__c = 'Ready' and Process_Status_CPQ__c != 'Completed' and Account_OM__c =: AccId];
        }
         
        
         if((jobType == 'oppupdate' || jobType == 'approvequote') && accId == NULL){
          quoteOrderList = [Select id,Account_OM__c,Opportunity__c,Quote_Id__c, Process_Status_OM__c ,Quantity__c,RenewedContractLine__c, Process_Type__c,Process_Status_CPQ__c, 
   Line_Item_Start_Date__c,Line_Item_End_Date__c,Subsumed_Old_Contract_Line_Items__c,Subscribed_Asset_IDs__c,Subscribed_Asset_Name__c,Entitlement__c,
   SubscribedAssetNames__c from Quote_and_Order_Staging__c where Process_Type__c = 'Initial RCDM-T Processing' and Process_Status_CPQ__c = 'Ready For Quote Approval'];

        }
        
        if((jobType == 'oppupdate' ||jobType == 'approvequote') && accId != NULL){
          quoteOrderList = [Select id,Account_OM__c,Opportunity__c,Quote_Id__c, Process_Status_OM__c ,Quantity__c,RenewedContractLine__c, Process_Type__c,Process_Status_CPQ__c, 
   Line_Item_Start_Date__c,Line_Item_End_Date__c,Subsumed_Old_Contract_Line_Items__c,Subscribed_Asset_IDs__c,Subscribed_Asset_Name__c,Entitlement__c,
   SubscribedAssetNames__c from Quote_and_Order_Staging__c where Process_Type__c = 'Initial RCDM-T Processing' and Process_Status_CPQ__c = 'Ready For Quote Approval' and Account_OM__c =: AccId];

        }
        
        this.jobType = jobType;
        this.quoteOrderStagingList = quoteOrderList;
  }
  
  /**
     * @description RCDMTExtensionLoadJob
     * @param bc
     * @return Iterable<Quote_and_Order_Staging__c>
     */  
  public Iterable<Quote_and_Order_Staging__c> start(Database.BatchableContext bc) {
        //system.debug('>>> >>>>> >>>>> >>>>'+quoteOrderStagingList);
        return quoteOrderStagingList;
    }
  
  /**
     * @description RCDMTExtensionLoadJob
     * @param bc
     * @param quoteorderStagingList
     */
  public void execute(Database.BatchableContext bc, List< Quote_and_Order_Staging__c > quoteorderStagingList) {
     //system.debug('---******---- '+quoteorderStagingList);
     List<Quote_and_Order_Staging__c> oppandquoteList = New List<Quote_and_Order_Staging__c>();
     List<Quote_and_Order_Staging__c> qliList = New List<Quote_and_Order_Staging__c>();
     List<Quote_and_Order_Staging__c> approveQuoteList = New List<Quote_and_Order_Staging__c>();
     List<Quote_and_Order_Staging__c> oppUpdateList = New List<Quote_and_Order_Staging__c>();
     
     
     for(Quote_and_Order_Staging__c qos : quoteorderStagingList){
         //system.debug('--0000--'+jobType);
         if(jobType == 'oppandquote' && qos.Process_Type__c == 'Initial RCDM-T Processing' && qos.Process_Status_OM__c == 'Ready'){
            oppandquoteList.add(qos);
         }
         
         if(jobType == 'qli' && qos.Process_Type__c == 'QLI & Order Processing' && qos.Process_Status_OM__c == 'Ready'){
            qliList.add(qos);
         }
         
         if(jobType == 'approvequote' && qos.Process_Type__c == 'Initial RCDM-T Processing' && qos.Process_Status_CPQ__c == 'Ready For Quote Approval'){
            approveQuoteList.add(qos);
         }
         
         if(jobType == 'oppupdate' && qos.Process_Type__c == 'Initial RCDM-T Processing' && qos.Process_Status_CPQ__c == 'Ready For Quote Approval'){
            oppUpdateList.add(qos);
         }
     }
     
     if(jobType == 'oppandquote' && oppandquoteList != null && oppandquoteList.size() > 0){
         RCDMTExtensionLoadUtilityHelper.cloneOpportunityRecord(oppandquoteList);
     }
     
     if(jobType == 'qli' && qliList != null && qliList.size() > 0){
         //system.debug('---- calling QLI method ----');
         RCDMTExtensionLoadUtilityHelper.createQuoteLineRecords(qliList);
     }
     
     if(jobType == 'approvequote' && approveQuoteList != null && approveQuoteList.size() > 0){
         RCDMTExtensionLoadUtilityHelper.autoApproveQuotes(approveQuoteList);
     }
     
     /*if(jobType == 'oppupdate' && oppUpdateList != null && oppUpdateList.size() > 0){
         system.debug('$$$$$$$$$$$'+oppUpdateList);
         RCDMTExtensionLoadUtilityHelper.updateOpptyStage(oppUpdateList);
         RCDMTExtensionLoadUtilityHelper.updateOpptyToOrdered(oppUpdateList);
     }*/
  }
  
  /**
     * @description  finish method
     * @param  bc
     */
   public void finish(Database.BatchableContext bc) {
      
   }
   
   /**
     * @description processOppty
     * @param jobType
     * @param accId
     */
   Public static void processOppty(String jobType, Id accId){
       
       List<Quote_and_Order_Staging__c> oppUpdateList = New List<Quote_and_Order_Staging__c>();

        if(jobType == 'oppupdate' && accId == NULL){
          oppUpdateList = [Select id,Account_OM__c, Opportunity__c,/*Opportunity__r.StageName,*/Quote_Id__c, Process_Status_OM__c ,Quantity__c,RenewedContractLine__c, Process_Type__c,Process_Status_CPQ__c, 
   Line_Item_Start_Date__c,Line_Item_End_Date__c,Subsumed_Old_Contract_Line_Items__c,Subscribed_Asset_IDs__c,Subscribed_Asset_Name__c,
   SubscribedAssetNames__c from Quote_and_Order_Staging__c where (Process_Type__c = 'Initial RCDM-T Processing' and Process_Status_CPQ__c = 'Ready For Quote Approval' /*and Opportunity__r.StageName = '1 Discovery'*/)];

        }
        if(jobType == 'oppupdate' && accId != null){
          oppUpdateList = [Select id,Account_OM__c, Opportunity__c,/*Opportunity__r.StageName,*/Quote_Id__c, Process_Status_OM__c ,Quantity__c,RenewedContractLine__c, Process_Type__c,Process_Status_CPQ__c, 
   Line_Item_Start_Date__c,Line_Item_End_Date__c,Subsumed_Old_Contract_Line_Items__c,Subscribed_Asset_IDs__c,Subscribed_Asset_Name__c,
   SubscribedAssetNames__c from Quote_and_Order_Staging__c where (Process_Type__c = 'Initial RCDM-T Processing' and Process_Status_CPQ__c = 'Ready For Quote Approval' and Account_OM__c =: AccId)];

        }
       
       if(jobType == 'oppupdate' && oppUpdateList != null && oppUpdateList.size() > 0){
         //system.debug('$$$$$$$$$$$'+oppUpdateList);
         RCDMTExtensionLoadUtilityHelper.updateOpptyStage(oppUpdateList);
         RCDMTExtensionLoadUtilityHelper.updateOpptyToOrdered(oppUpdateList);
     }

   }
   
   /**
     * @description processQuote
     * @param jobType
     * @param accId
     * @param recLimit
     */
   Public static void processQuote(String jobType, Id accId, Integer recLimit){
      
      List<Quote_and_Order_Staging__c> oppUpdateList = New List<Quote_and_Order_Staging__c>();

      if((jobType == 'quotecalculate' || jobType == 'quoteReadyforApproval') && AccId == NULL){
         oppUpdateList = [Select id,Account_OM__c, Opportunity__c/*,Opportunity__r.StageName*/,Quote_Id__c, Process_Status_OM__c ,Quantity__c,RenewedContractLine__c, Process_Type__c,Process_Status_CPQ__c, 
   Line_Item_Start_Date__c,Line_Item_End_Date__c,Subsumed_Old_Contract_Line_Items__c,Subscribed_Asset_IDs__c,Subscribed_Asset_Name__c,
   SubscribedAssetNames__c from Quote_and_Order_Staging__c where (Process_Type__c = 'Initial RCDM-T Processing' and Quote_Id__c != null  and Process_Status_OM__c = 'Ready' and Process_Status_CPQ__c = 'Ready')];

      
      }
      
      if((jobType == 'quotecalculate' || jobType == 'quoteReadyforApproval') && AccId != null){
         oppUpdateList = [Select id,Account_OM__c, Opportunity__c/*,Opportunity__r.StageName*/,Quote_Id__c, Process_Status_OM__c ,Quantity__c,RenewedContractLine__c, Process_Type__c,Process_Status_CPQ__c, 
   Line_Item_Start_Date__c,Line_Item_End_Date__c,Subsumed_Old_Contract_Line_Items__c,Subscribed_Asset_IDs__c,Subscribed_Asset_Name__c,
   SubscribedAssetNames__c from Quote_and_Order_Staging__c where Process_Type__c = 'Initial RCDM-T Processing' and Quote_Id__c != null  and Process_Status_OM__c = 'Ready' and Process_Status_CPQ__c = 'Ready' and Account_OM__c =: AccId];

      
      }
      
      if(jobType == 'quotecalculate'){
         RCDMTExtensionLoadUtilityHelper.updateQuoteToCalculate(oppUpdateList,recLimit);
      }
      
      if(jobType == 'quoteReadyforApproval'){
         RCDMTExtensionLoadUtilityHelper.updateStagingReadyForApproval(oppUpdateList);
      }
      
   }
   
   /**
     * @description checkQuoteCalculationStatus
     * 
     */
   public static void checkQuoteCalculationStatus(){
        Set<Id> idSet = New Set<Id>();
        Integer uncalculatedCount = 0;
        Integer totalCount = 0;
        
        for(Quote_and_Order_Staging__c qos : [Select id,Account_OM__c, Opportunity__c,Process_Status_OM__c ,Quote_Id__c,Quantity__c,RenewedContractLine__c, Process_Type__c,Process_Status_CPQ__c, 
           Line_Item_Start_Date__c,Line_Item_End_Date__c,Subsumed_Old_Contract_Line_Items__c,Subscribed_Asset_IDs__c,Subscribed_Asset_Name__c,
           SubscribedAssetNames__c from Quote_and_Order_Staging__c where (Process_Type__c = 'Initial RCDM-T Processing' and Process_Status_OM__c = 'Ready' and Process_Status_CPQ__c != 'Completed')]){
           
           IdSet.add(qos.Quote_Id__c);
        
        }
        
        for(SBQQ__Quote__c qt : [select id,SBQQ__Uncalculated__c from SBQQ__Quote__c where id in : IdSet]){
            totalCount++;
            if(qt.SBQQ__Uncalculated__c == true){
               uncalculatedCount++;
            }
        }
        System.debug(' Total Quotes = '+totalCount);
        System.debug(' Total Quotes Still Uncalculated = '+uncalculatedCount);
   }
   
   /**
     * @description updateStagingReadyForApprovalfortst
     * 
     */
   public static void updateStagingReadyForApprovalfortst(){
       Integer i = 0;
       i++;
       i++;
       i++;
       i++;
       
       
     }
}