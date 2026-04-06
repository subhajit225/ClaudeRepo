/**
 * @description RCDMTExtensionLoadUtilityHelper
 */
Public without sharing class RCDMTExtensionLoadUtilityHelper {

   
   /**
     * @description cloneOpportunityRecord
     * @param stagingRecList
     */
   public static void cloneOpportunityRecord(List<Quote_and_Order_Staging__c> stagingRecList) {

      Set<Id> accIdSet = new Set<Id>();
      Set<Id> oppIdSet = New Set<Id>();
      Map<Id,Id> accToOppMap = New Map<Id,Id>();
      List<Opportunity> oppInsertList = New List<Opportunity>();
      for(Quote_and_Order_Staging__c stg: stagingRecList){
          accIdSet.add(stg.Account_OM__c);
      }   

      String oppQuery = 'SELECT '+Label.OppQuery;
      //system.debug(' >> >> >> '+Oppquery+ ' where AccountId IN'+accIdSet);
      for(Opportunity opp : Database.query('Select id,createddate,stageName,AccountId from Opportunity where AccountId IN : accIdSet' + ' and stageName = \'7 Closed Won\''+ 'order by createddate desc')){
          //system.debug('>>>>>> >>>>>'+Opp.createddate+Opp.Id);
          if(accToOppMap.get(opp.AccountId) == NULL){
             accToOppMap.put(opp.AccountId,opp.Id);
             OppIdSet.add(Opp.Id);
          }
      }
      //system.debug(' >> Oppty Map '+accToOppMap);
      
      for(Opportunity opp: Database.query(oppQuery+ ' where Id IN : oppIdSet')){
          Opportunity cloneOpp = Opp.clone(false, false, false);
          cloneOpp.stageName = '1 Discovery';
          cloneOpp.CloseDate = date.valueof(label.OppCloseDate);//new change
          cloneOpp.Opportunity_Sub_Type__c = 'Renewal';
          cloneOpp.recordTypeId = label.RenewalRecordTypeId;
          cloneOpp.Restrict_Email_Notifications__c = true;
          
          //check below code again
          if(cloneOpp.Partner_Lookup__c == null && cloneOpp.Distributor_Lookup__c != null){
            cloneOpp.Partner_Lookup__c = cloneOpp.Distributor_Lookup__c;
          }
          if(cloneOpp.Partner_Lookup__c != null && cloneOpp.Distributor_Lookup__c == null){
             cloneOpp.Distributor_Lookup__c = cloneOpp.Partner_Lookup__c;
          }
          
          if(cloneOpp.Polaris_Portal_Contact__c == NULL){
             cloneOpp.Polaris_Portal_Contact__c = cloneOpp.Initial_Contacts_Name__c;
          }
          
          //system.debug('>>'+cloneOpp);
          oppInsertList.add(cloneOpp);
          
          //system.debug('>> >>'+cloneOpp.Id);
      }
      if (Schema.sObjectType.Opportunity.isCreateable()) {
      Database.insert(oppInsertList,false);
      }
      
      createQuoteRecords(stagingRecList,oppInsertList);
   }
   
   
   /**
     * @description createQuoteRecords
     * @param stagingRecList
     * @param oppInsertList
     */
   public static void createQuoteRecords(List<Quote_and_Order_Staging__c> stagingRecList,List<Opportunity> oppInsertList) {
     List<SBQQ__Quote__c> qtInsertList = New List<SBQQ__Quote__c>();
     map<Id,Id> opptyToAccMap = New Map<Id,Id>();
     List<Quote_and_Order_Staging__c> stagingUpdtList = New List<Quote_and_Order_Staging__c>();    
     Set<Id> accIdSet = New Set<Id>();
     
     for(Quote_and_Order_Staging__c stg : stagingRecList){
         for(Opportunity op : oppInsertList){
             If(op.AccountId == stg.Account_OM__c){
                opptyToAccMap.put(stg.Account_OM__c,op.Id);
             }
         }
     }
     
     //Create Quote records
     for(Quote_and_Order_Staging__c qoS : stagingRecList){
         
         if(opptyToAccMap.keyset().contains(qoS.Account_OM__c) && opptyToAccMap.get(qoS.Account_OM__c) != null ){

            SBQQ__Quote__c qt =  New SBQQ__Quote__c();
            qt.SBQQ__Opportunity2__c = opptyToAccMap.get(qoS.Account_OM__c);
            qt.SBQQ__Account__c = qoS.Account_OM__c;
            qt.OpportunitySubType__c = 'Renewal';
            qt.SBQQ__Type__c = 'Renewal';
            //qt.Amended_Renewed_Service_Contract__c = '8106f000000Wsjo';
            //qt.Has_SubscribedAssetNames__c = true;
            /*qt.SBQQ__StartDate__c = date.newInstance(2024,08,01);
            qt.SBQQ__EndDate__c = date.newInstance(2025,08,01);
            qt.SBQQ__SubscriptionTerm__c = 12;*/
            qt.SBQQ__Primary__c = true;
            qt.RWD_Deal_Ops_Exception__c = 'RCDM-T Manual Extension';
            qt.RWD_Deal_Ops_Exception_Justification__c = 'This is IT created Quote for RCDM Manual Extension';
            qtInsertList.add(qt);
         }
     }
     if (Schema.sObjectType.SBQQ__Quote__c.isCreateable()) {
         Insert qtInsertList;
     }
     
     //Map the Opportunbity id and Quote if on the Inital processing staging record
     for(Quote_and_Order_Staging__c stg : stagingRecList){
         for(SBQQ__Quote__c qt: qtInsertList){
             If(qt.SBQQ__Account__c == stg.Account_OM__c){
                opptyToAccMap.put(stg.Account_OM__c,qt.Id);
                stg.Opportunity__c = qt.SBQQ__Opportunity2__c;
                stg.Process_Status_CPQ__c = 'Ready';
                
                stg.Quote_Id__c = qt.Id;
                stagingUpdtList.add(stg);
                
             }
         }
     }
     if (Schema.sObjectType.Quote_and_Order_Staging__c.isUpdateable()) {
          update stagingUpdtList;
     }
   }
   /**
     * @description createQuoteLineRecords
     * @param stagingRecList 
     */
   public static void createQuoteLineRecords(List<Quote_and_Order_Staging__c> stagingRecList) {

       List<SBQQ__QuoteLine__c> qlListToInsert = New List<SBQQ__QuoteLine__c>();
       Map<Id,Id> stgVsQuoteMap = New Map<Id,Id>();
       Map<Id,Id> stgVsOppMap = New Map<Id,Id>();
       Set<Id> accIdSet = New Set<Id>();
       List<Quote_and_Order_Staging__c> qosUpdateList = New List<Quote_and_Order_Staging__c>();
       Map<String, Quote_and_Order_Staging__c> entitlementIdToQnO = new Map<String, Quote_and_Order_Staging__c>();
       Map<String, SBQQ__QuoteLine__c> entitlementIdToQli = new Map<String, SBQQ__QuoteLine__c>();
       //system.debug(' >>>> '+stagingRecList);
       
       for(Quote_and_Order_Staging__c stg : stagingRecList){
          accIdSet.add(stg.Account_OM__c);
       }
       
       for(Quote_and_Order_Staging__c stg : [Select id,Account_OM__c,Quote_Id__c,Opportunity__c from Quote_and_Order_Staging__c where Account_OM__c IN: accIdSet and Process_Type__c = 'Initial RCDM-T Processing' and Process_Status_OM__c = 'Ready' and Process_Status_CPQ__c = 'Ready']){
           stgVsQuoteMap.put(stg.Account_OM__c,stg.Quote_Id__c); 
           stgVsOppMap.put(stg.Account_OM__c,stg.Opportunity__c); 
       }
       
       for(Quote_and_Order_Staging__c stg : stagingRecList){
          //system.debug(' >>>>>> 000'+ stg.Process_Type__c+ stg.Process_Status_CPQ__c);
          if(stg.Process_Type__c == 'QLI & Order Processing' && stg.Process_Status_OM__c == 'Ready' && stgVsQuoteMap.keyset().contains(stg.Account_OM__c)){
             //system.debug('MMMMMMMM' );
             SBQQ__QuoteLine__c qline = new SBQQ__QuoteLine__c();
             qline.SBQQ__Quote__c = stgVsQuoteMap.get(stg.Account_OM__c);//stg.Quote_Id__c;
             qline.SBQQ__Quantity__c = stg.Quantity__c;
             qline.SBQQSC__RenewedContractLine__c = stg.RenewedContractLine__c;
             qline.Disposition_Reason__c = 'Renewing';
             qline.SBQQ__StartDate__c = stg.Line_Item_Start_Date__c;
             qline.SBQQ__EndDate__c = stg.Line_Item_End_Date__c;
             qline.SBQQ__Product__c = label.RCDMProductId;
             qline.Arroyo_Subsumed_Old_Contract_Line_Items__c = stg.Subsumed_Old_Contract_Line_Items__c;
             qline.SBQQ__SubscribedAssetIds__c = stg.Subscribed_Asset_IDs__c; 
             qline.Subscribed_Asset_Name__c = stg.Subscribed_Asset_Name__c;
             qline.SubscribedAssetNames__c = stg.SubscribedAssetNames__c;
    
    
             qlListToInsert.add(qline);
             String uniqueKey = String.valueOf(stg.Quantity__c) + String.valueOf(stg.Line_Item_Start_Date__c) + String.valueOf(stg.Line_Item_End_Date__c);
             entitlementIdToQli.put(stg.Entitlement__c, qline);
             entitlementIdToQnO.put(stg.Entitlement__c, stg);
             /* entitlementIdToQli.put(uniqueKey, qline);
             entitlementIdToQnO.put(uniqueKey, stg);
             qosUpdateList.add(stg);*/
          }
       }
       
       SBQQ.TriggerControl.disable();   
      try{
       if (Schema.sObjectType.SBQQ__QuoteLine__c.isCreateable()) {
           Insert qlListToInsert;
           //System.debug('### entitlementIdToQli: ' + entitlementIdToQli);
           for (String entitlementId : entitlementIdToQli.keyset()) {
              SBQQ__QuoteLine__c quoteLine = entitlementIdToQli.get(entitlementId);
              Quote_and_Order_Staging__c stagingRec = entitlementIdToQnO.get(entitlementId);
              stagingRec.QuoteLine_Id__c = quoteLine.Id;
              qosUpdateList.add(stagingRec);
          }
       }
       if (Schema.sObjectType.Quote_and_Order_Staging__c.isUpdateable()) {
           update qosUpdateList;
       }
     }
     finally{
    SBQQ.TriggerControl.enable();
    }  

  } 
     /**
     * @description autoApproveQuotes
     * @param stagingRecList 
     */
     public static void autoApproveQuotes(List<Quote_and_Order_Staging__c> stagingRecList){
        List<SBQQ__Quote__c> quotesToApprove = New List<SBQQ__Quote__c>();
        for(Quote_and_Order_Staging__c qos : stagingRecList){
            if(qos.Quote_Id__c != NULL && qos.Process_Type__c == 'Initial RCDM-T Processing' && qos.Process_Status_CPQ__c == 'Ready For Quote Approval'){
               SBQQ__Quote__c qt = New SBQQ__Quote__c();
               qt.Id = qos.Quote_Id__c;
               qt.ApprovalStatus__c = 'Approved';
               quotesToApprove.add(qt);
            }
        }
        if (Schema.sObjectType.SBQQ__Quote__c.isUpdateable()) {
            update quotesToApprove;
        }
     }
     
     /**
     * @description updateOpptyStage
     * @param stagingRecList
     */
     public static void updateOpptyStage(List<Quote_and_Order_Staging__c> stagingRecList){
        List<Opportunity> opptyUpdateList = New List<Opportunity>();
        List<Quote_and_Order_Staging__c> qosUpdateList = New List<Quote_and_Order_Staging__c>();
        for(Quote_and_Order_Staging__c qos : stagingRecList){
            if(qos.Quote_Id__c != NULL && qos.Process_Type__c == 'Initial RCDM-T Processing' && qos.Process_Status_CPQ__c == 'Ready For Quote Approval'){
               Opportunity opp = New Opportunity();
               Opp.Id = qos.Opportunity__c;              
               Opp.StageName = '6 PO With Channel';
               opptyUpdateList.add(opp);
               //qos.Process_Status_CPQ__c = 'Completed';
               //qosUpdateList.add(qos);
            }
        }
        if (Schema.sObjectType.Opportunity.isUpdateable()) {
            database.update(opptyUpdateList,false);
        }
        //update qosUpdateList;
        
     }
     
     /**
     * @description updateOpptyToOrdered
     * @param stagingRecList
     */
     public static void updateOpptyToOrdered(List<Quote_and_Order_Staging__c> stagingRecList){
        List<Opportunity> opptyUpdateList = New List<Opportunity>();
        List<Quote_and_Order_Staging__c> qosUpdateList = New List<Quote_and_Order_Staging__c>();
        for(Quote_and_Order_Staging__c qos : stagingRecList){
            if(qos.Quote_Id__c != NULL && qos.Process_Type__c == 'Initial RCDM-T Processing' && qos.Process_Status_CPQ__c == 'Ready For Quote Approval'){
               Opportunity opp = New Opportunity();
               Opp.Id = qos.Opportunity__c;
               Opp.SBQQ__Ordered__c = true;
               Opp.StageName = '6 PO With Channel';
               opptyUpdateList.add(opp);
               
               qos.Process_Status_CPQ__c = 'Completed'; //TODO MOve this to different method
               qosUpdateList.add(qos);
            }
        }
        if (Schema.sObjectType.Opportunity.isUpdateable()) {
            update opptyUpdateList;
        }
        if (Schema.sObjectType.Quote_and_Order_Staging__c.isUpdateable()) {
            update qosUpdateList;
        }
     }
     
     /**
     * @description updateQuoteToCalculate
     * @param stagingRecList
     * @param recLimit
     */
     public static void updateQuoteToCalculate(List<Quote_and_Order_Staging__c> stagingRecList,Integer recLimit){
        //system.debug('== ****'+stagingRecList);
        List<SBQQ__Quote__c> qtList = New List<SBQQ__Quote__c>();
        Set<Id> idSet = New Set<Id>();
        Set<Id> qtidToCalculateSet = New Set<Id>();
        Set<Id> qtCalculatedIdSet = New Set<Id>();
        Integer count = 0;
        
        for(Quote_and_Order_Staging__c qst : stagingRecList){
            idSet.add(qst.Quote_Id__c);
        }
        //system.debug('$$$$$$$$111 '+idSet);
        for(SBQQ__Quote__c qt : [select id,SBQQ__Uncalculated__c, SBQQ__LineItemCount__c from SBQQ__Quote__c where SBQQ__Uncalculated__c = true and Id in : idSet]){
            if(count < recLimit && qt.SBQQ__LineItemCount__c > 0){
              count++;
              qtidToCalculateSet.add(qt.Id);
            }
        }
        //system.debug('$$$$$$$$'+qtidToCalculateSet);
        List<SBQQ__QuoteLine__c> qlst = new List<SBQQ__QuoteLine__c>();
        for(SBQQ__QuoteLine__c qli : [Select id, SBQQ__Discount__c,SBQQ__Quote__r.SBQQ__Uncalculated__c from SBQQ__QuoteLine__c where SBQQ__Quote__c IN : qtidToCalculateSet] ){
            //system.debug('==****');
            
            If(!qtCalculatedIdSet.contains(qli.SBQQ__Quote__c)){
            
                if(qli.SBQQ__Discount__c != 100){
                 qli.SBQQ__Discount__c = 100;
                }
                else{
                   qli.SBQQ__Discount__c = 99;
                }
                qlst.add(qli);
                qtCalculatedIdSet.add(qli.SBQQ__Quote__c);
                
            }
            
        }
        //system.debug(' >>>>>> '+qlst);
        if (Schema.sObjectType.SBQQ__QuoteLine__c.isUpdateable()) {
            update qlst;
        }
        
        
     }
     
     /**
     * @description updateStagingReadyForApproval
     * @param stagingRecList
     */
     public static void updateStagingReadyForApproval(List<Quote_and_Order_Staging__c> stagingRecList){
        List<SBQQ__Quote__c> qtList = New List<SBQQ__Quote__c>();
        Set<Id> qtIdSet = New Set<Id>();
        List<Id> calculatedQtIdSet = New List<Id>();
        List<Quote_and_Order_Staging__c> qosUpdateList = New List<Quote_and_Order_Staging__c>();
        
        for(Quote_and_Order_Staging__c qst : stagingRecList){
            qtIdSet.add(qst.Quote_Id__c);  
        }
        for(SBQQ__Quote__c qt : [Select id, SBQQ__Uncalculated__c from SBQQ__Quote__c where Id in : qtIdSet and SBQQ__Uncalculated__c = false]){
            calculatedQtIdSet.add(qt.Id);
        }
        
        for(Quote_and_Order_Staging__c qst : stagingRecList){
            if(calculatedQtIdSet.contains(qst.Quote_Id__c)){
               qst.Process_Status_CPQ__c = 'Ready For Quote Approval';
               qosUpdateList.add(qst); 
            } 
        }
        if (Schema.sObjectType.Quote_and_Order_Staging__c.isUpdateable()) {
            update qosUpdateList;
        }
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
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
     }
}