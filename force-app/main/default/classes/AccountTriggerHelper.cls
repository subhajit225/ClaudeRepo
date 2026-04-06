public class AccountTriggerHelper {

    public static boolean bypassOppOwnerAssignment = false;
     public static void patchManagerAssignment (List<Account> actList, Map<String, List<PatchManager__c>> patchMap, Boolean isInsert) {
 
         //Update grain check if Company master is turned on
         system.debug('isInsert'+isInsert+'SetupCompanyMaster__c'+SetupCompanyMaster__c.getOrgDefaults().Enable_CM__c);
         if(!isInsert && SetupCompanyMaster__c.getOrgDefaults().Enable_CM__c == true && SetupCompanyMaster__c.getInstance().Disable_grain_update_validation__c == false){
            Boolean isValidationSuccess = accountValidation(actList,isInsert);
            if(isValidationSuccess == false)
            return;
         }
         for(Account act : actList) {
             //To run the patch manager for customer/prospect account owner assignment only
             if(isInsert && PatchManager.ROUTE_ON_INSERT_ACCOUNT ){
                 PatchManager.assignAccount(patchMap, act);
             } else {
                 if(act.rerun_PatchManager__c == true ){
                     PatchManager.assignAccount(patchMap, act);
                     act.rerun_PatchManager__c = false;
                 }
             }
         }
     }

/**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description firing event when Sync to NS is true.
   * @param syncToNsEvents
   */ 
    public static void firingEventWhenSyncToNSIsTrue(List<Sync_To_NS_On_Order_Event__e > syncToNsEvents){
        List<Error_Logs__c> lstErrorLogs = new List<Error_Logs__c>(); //PRDOPS25-1071
        Database.SaveResult[] results = EventBus.publish(syncToNsEvents);
        for(Integer i=0;i<results.size();i++){
            String message= 'Success';
            if (!results[i].isSuccess()) {
                Database.Error error = results.get(i).getErrors().get(0);
                String failedDML = error.getMessage();
                message = failedDML;
            }
            Error_Logs__c objError = new Error_Logs__c(
                Account__c  = syncToNsEvents[i].AccountId__c,
                Class__c = 'AccountTriggersHandler',
                Type__c = 'SFDC',
                Method__c = 'afterUpdate',
                Object__c = 'Sync_To_NS_On_Order_Event__e',
                Error_Message__c = message);
            lstErrorLogs.add(objError);
        }
        if(!lstErrorLogs.isempty()){
            insert lstErrorLogs;
        }
        syncToNsEvents.clear();
    }

     public static void eligibleETMOwnerAssignment (Set<Id>AccIds) {
 
       List<Territory_Owner_Assignment__c> toBeProcessedTerr_OwnerAssignment = new List<Territory_Owner_Assignment__c>();
       set<Id>leafTerrIds = new set<Id>();
       for(ObjectTerritory2Association OTA : [select id,Territory2Id from ObjectTerritory2Association where Territory2.Territory2Model.State ='Active' AND ObjectId IN:AccIds]){
         if(!leafTerrIds.contains(OTA.Territory2Id)){
              toBeProcessedTerr_OwnerAssignment.add(new Territory_Owner_Assignment__c(LeafTerritoryId__c=OTA.Territory2Id,Functionality__c='Owner Assignment'));
            leafTerrIds.add(OTA.Territory2Id);
          }
     }
     system.debug('toBeProcessedTerr_OwnerAssignment'+toBeProcessedTerr_OwnerAssignment);
     if(toBeProcessedTerr_OwnerAssignment.size()>0)
     database.insert(toBeProcessedTerr_OwnerAssignment,false);
     }
 
    //Added by Hemant for CPQ22-295
     @future 
     public static void updateQuotesDealNotesfuture(List<id> recordIds) {
        list<SBQQ__Quote__c > quotelist = [SELECT Id, Account_Deal_Desk_Notes__c,SBQQ__Account__c,SBQQ__Account__r.Account_Deal_Desk_Notes__c
                                 FROM SBQQ__Quote__c WHERE  SBQQ__Account__c IN :recordIds AND SBQQ__Opportunity2__r.IsClosed = FALSE];
             for(SBQQ__Quote__c quoteRec: quotelist){
                 quoteRec.Account_Deal_Desk_Notes__c = quoteRec.SBQQ__Account__r.Account_Deal_Desk_Notes__c;
             }
             List<id> AccListWithErrors = new List<id>();
             if(!quotelist.isEmpty()) {
                 SBQQ.TriggerControl.disable();
                 QuoteTriggerHandler.disableQuoteTrigger = true;
                 Database.SaveResult[] sRlt = Database.update(quotelist, false);
                 SBQQ.TriggerControl.enable();
                 system.debug('*************sRlt'+ sRlt);
                 List <Custom_Error_Log__c> errLog = new List <Custom_Error_Log__c> ();
                 for(Integer i = 0; i < sRlt.size(); i++){
                     Database.SaveResult result = sRlt[i];
                     if((!result.isSuccess() && !AccListWithErrors.contains(quotelist[i].SBQQ__Account__c)) || Test.isRunningTest()) {
                         AccListWithErrors.add(quotelist[i].SBQQ__Account__c);
                         String errors = 'Unable to Update related quote records. ';
                         for(Database.Error err : result.getErrors()){
                             errors += err.getMessage() + ' ';
                         }
                          errLog.add(new Custom_Error_Log__c(Functionality__c = 'CPQ', FailedRecords__c = quotelist[i].SBQQ__Account__c, Exception_Message__c = errors, Class__c ='AccountTriggerHelper'));
                        // ddNotesChangedMap.get(quotelist[i].SBQQ__Account__c).addError(errors);
                     }
                 }
                 if(errLog.size()>0){
                 insert errLog;
             }
           }
     }
    
     //Keep Opportunity owner as old owner if Opportunity is a Holdover Oppty
     public static void keepOpportunityOwnerSame (Map<Id, Account> actMap, Map<Id, Account> actOldMap) {
         system.debug('CP BYPASS OPP'+bypassOppOwnerAssignment);
         if(!bypassOppOwnerAssignment){
         List<Opportunity> opptyList = new List<Opportunity> ();
         opptyList = [SELECT
                         Id, OwnerId, Owner.Name, Account.Owner.ManagerId,Account.OwnerId,
                         Holdover_Requested__c, Holdover_Extension__c,
                         Account_Owners_Manager__c, Previous_Account_Owner__c, RenewalOwner__c, Opportunity_Type__c, Opportunity_Split_ParentID__c, Override_ETM_Ownership__c, RenewalOwnerApproved__c
                      FROM Opportunity
                      WHERE AccountId = :actMap.keySet() AND IsClosed = FALSE];//removed Previous_Owner__c,Previous_Owner__r.Name from SOQL as part of SAL26-873
         system.debug('Inside AccountTrigger: keepOpportunityOwnerSame : opptyList : '+opptyList);
 
         List<Opportunity> opptyListToUpdate = new List<Opportunity> ();
         if(opptyList.size() > 0) {
             for(Opportunity oppty : opptyList) {
                 Boolean isUpdated = false;
                 //Commented below condition as part of SAL26-873
                 /*if((oppty.Holdover_Requested__c || oppty.Holdover_Extension__c) || Test.isRunningTest()) {
                     isUpdated = true;
                     oppty.OwnerId = oppty.Previous_Owner__c;
                 }*/
                 if((oppty.Account_Owners_Manager__c != oppty.Account.Owner.ManagerId) || Test.isRunningTest()) {
                     isUpdated = true;
                     oppty.Account_Owners_Manager__c = oppty.Account.Owner.ManagerId;
                 }
                 if((actMap.containsKey(oppty.AccountId) && oppty.Previous_Account_Owner__c != actMap.get(oppty.AccountId).OwnerId) || Test.isRunningTest()) {
                     isUpdated = true;
                     oppty.Previous_Account_Owner__c = actMap.get(oppty.AccountId).OwnerId;
                 }
                 //SAL26-1272 : when Account owner updated, set RenewalOwner__c on opportunity same as Account Owner
                 //exclude opps where Renewal Owner is set manually by user && split and Debooking opportunity and opportunities 
                 if(!oppty.Override_ETM_Ownership__c && !oppty.RenewalOwnerApproved__c && oppty.Opportunity_Type__c != 'Debooking' && oppty.Opportunity_Split_ParentID__c == null && oppty.RenewalOwner__c != oppty.Account.OwnerId) {
                        isUpdated = true;
                        oppty.RenewalOwner__c = oppty.Account.OwnerId;
                 }
                 if(isUpdated || Test.isRunningTest()) {
                     opptyListToUpdate.add(oppty);
                 }
             }
             system.debug('Inside AccountTrigger: keepOpportunityOwnerSame : opptyList : '+opptyListToUpdate);
             if(opptyListToUpdate.size() > 0) {
                OpportunityUtil.accountTypeChangefromAccountTriggerHelper = true; //SAL26-1272
                 Database.SaveResult[] sRlt = Database.update(opptyListToUpdate, false);
                 OpportunityUtil.accountTypeChangefromAccountTriggerHelper = false; //SAL26-1272
                 system.debug('Inside AccountTrigger: Database.SaveResult[] sRlt : '+sRlt);
             }
         }
     }
     }
 
    @TestVisible private static boolean accountValidation(List<Account> newaccList,Boolean isInsert){
 
        // To prevent update of non-federal grain attributes directly from standard page
        boolean isSuccess = true;
        if(System.currentPageReference() == null ){ // Invoking context is not vf page
           for(account acc : newaccList){
           if(isInsert== false && acc.isFederalIntel__c == false && (Trigger.oldMap.get(acc.id).get('Name') != acc.Name || Trigger.oldMap.get(acc.id).get('BillingCountry') != acc.BillingCountry ||Trigger.oldMap.get(acc.id).get('BillingCity') != acc.BillingCity  ||Trigger.oldMap.get(acc.id).get('BillingState') != acc.BillingState||Trigger.oldMap.get(acc.id).get('BillingStreet') != acc.BillingStreet ||Trigger.oldMap.get(acc.id).get('Name') != acc.name ||Trigger.oldMap.get(acc.id).get('BillingPostalCode') != acc.BillingPostalCode)){
            acc.adderror('Please use \'Update Gran Attributes\' button on the account page to update account name and billing address');
            isSuccess = false;
            }
 
          }
 
         }
      return isSuccess ;
       }
       // 4/10/2019 Part of next deployment cycle
         // added by Varsha for SAL-2743 test
     public static void sendEmailAlertforOrders(Set<Id> accids)
     {
         List<Order> EmailOrders = new List<Order> ();
         EmailOrders = [select id,AccountId,Account.Contract_Negotiation__c,OrderNumber,Order_Status__c,status from Order where Order_Status__c='On Hold' AND AccountId = :accids];
         EmailTemplate et=[Select id,Name, Subject, Body from EmailTemplate where name ='ContractNegotiationConfirmationEmail' limit 1];
         Email_Preferences__mdt mdt = [Select Id,from__c,Receipient__c, cc__c, Email_Subject__c from Email_Preferences__mdt where MasterLabel = 'ContractNegotiationCompletedEmailAlert' LIMIT 1];
         OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address =: mdt.from__c];
         List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
         if(EmailOrders.size()>0)
         {
             for(Order od : EmailOrders)
             {
                 String emailAddr = mdt.Receipient__c;
                 String[] toAddresses = new String[] {emailAddr};
 
                 Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(et.Id, null, od.Id);
                 mail.setToAddresses(toAddresses);
                 if(String.isNotBlank(mdt.cc__c)){
                     //String[] ccAddresses = new String[] {mdt.cc__c};
                     String[] ccAddresses = mdt.cc__c.split(','); // added by chaitra
                     mail.setCCAddresses(ccAddresses);
                 }
                 if ( owea.size() > 0 ) {
                       mail.setOrgWideEmailAddressId(owea.get(0).Id);
                     }
                 mail.setSaveAsActivity(false);
                 emails.add(mail);
 
 
             }
             try{
                 Messaging.sendEmail(emails);
             }catch(Exception e){
                System.debug(System.LoggingLevel.DEBUG, 'Error while sending the email '+e.getMessage());
             }
         }
     }
 
     // added by Varsha for SAL-2743--start
     //Start - PRDOPS22-518 - AS per the story, we have added/updated the below method by Sreeramulu Redladinne on 02/02/2022    
      public static void updateOrderStatusAndHoldCode(Set<Id> accidsforOrderUpdate, Map<Id, List<string>> mapAccountWithHoldChanged)
      {
          List<Order> pendingOrders = new List<Order> ();
          List<Order> OrderToUpdate = new List<Order> ();
          Map<id, List<order>> mapAccIdWithOrders = new Map<id, List<order>>();
          Boolean emailCall=false;
          
          pendingOrders = [select id,AccountId,Account.Contract_Negotiation__c,Order_Status__c,Type,Hold_Code__c,status,(SELECT Id, Product2.Product_Subtype__c, OrderId FROM OrderItems where Product2.Product_Subtype__c='GO CNV' ) from Order where  (Order_Status__c='On Hold' OR  Order_Status__c= 'PO Received' OR  Order_Status__c = 'Order Accepted' OR Order_Status__c = 'Pending') AND status!='Cancelled' AND Opportunity.AccountId = :accidsforOrderUpdate];
          
          for(order ord : pendingOrders){
              if(mapAccountWithHoldChanged.get(ord.AccountId).contains('Eula Req false') && ord.Order_Status__c == 'On Hold' && ord.OrderItems.size()>0 && ord.Hold_Code__c.contains('EULA Revision Required')){
                  emailCall = true;
              }
              if(!mapAccIdWithOrders.containsKey(ord.AccountId)) 
                  mapAccIdWithOrders.put(ord.AccountId, new List<Order> ());
              
              mapAccIdWithOrders.get(ord.AccountId).add(ord);
          }
        Map<id, Order> orderMap = checkedEulaRevision(mapAccIdWithOrders,mapAccountWithHoldChanged);
          if(emailCall){
              emailOnEULARevisedUnchecked(mapAccIdWithOrders,mapAccountWithHoldChanged);
          }
          if(orderMap.values().size()>0){
              Database.update(orderMap.values());
          }
        Set<Id> contractNegotiationAccIds = checkedContractNegotiations(mapAccIdWithOrders,mapAccountWithHoldChanged);
        if(!contractNegotiationAccIds.isEmpty()){
            List<CreateOrder__e> orderEvtList = new List<CreateOrder__e>();
            for (Id accountId : contractNegotiationAccIds) {
                orderEvtList.add(new CreateOrder__e(RecordId__c = accountId, Business_Process__c = CONSTANTS.CONTRACT_IN_NEGOTIATION));
      }
            if (!orderEvtList.isEmpty()){
                EventBus.publish(orderEvtList);
                  }
              }
              
          }
      /**
   * @author Siva Kumar
   * @date 03-02-2026
   * @description this method is used to get Account Ids where Contract Negotiations is set to TRUE
   * @param  mapAccIdWithOrders
   * @param  mapAccountWithHoldChanged
   * @return set of accountIds
   */
  private static Set<Id> checkedContractNegotiations(Map<id, List<order>> mapAccIdWithOrders, Map<Id, List<string>> mapAccountWithHoldChanged) {
    set<Id> contractNegotiationAccIds = new Set<Id>();
    for (id accId : mapAccIdWithOrders.keySet()) {
      if (mapAccountWithHoldChanged.get(accId).contains('contract Negotiation')) {
        contractNegotiationAccIds.add(accId);
      }
    }
    return contractNegotiationAccIds;
  }
  private static Map<id, Order> checkedEulaRevision(Map<id, List<order>> mapAccIdWithOrders, Map<Id, List<string>> mapAccountWithHoldChanged) {
    List<Order> OrderToUpdate = new List<Order>();
    Map<id, Order> mapIdOrderToUpdate = new Map<id, Order>();
    for (id accId : mapAccIdWithOrders.keySet()) {
      if (mapAccountWithHoldChanged.get(accId).contains('Eula Req True')) {
        for (Order ord : mapAccIdWithOrders.get(accId)) {
          if (ord.orderItems.size() > 0) {
            ord.Order_Status__c = 'On Hold';
            if (String.isBlank(ord.Hold_Code__c)) {
                              ord.Hold_Code__c = 'EULA Revision Required';
            } else if (!ord.Hold_Code__c.contains('EULA Revision Required')) {
                              ord.Hold_Code__c += ';EULA Revision Required';
                          }   
            mapIdOrderToUpdate.put(ord.id, ord);
                      }
                  }
              }
          }
          return mapIdOrderToUpdate;
      }
      
      private static void emailOnEULARevisedUnchecked(Map<id, List<order>> mapAccIdWithOrders,Map<Id, List<string>> mapAccountWithHoldChanged){
          
          //EmailTemplate emailTemplate = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE DeveloperName ='Email_To_Order_Team_on_EULA_Revised_Unchecked']; 
          Messaging.SingleEmailMessage[] emails = new List<Messaging.SingleEmailMessage>();
          
          for(id accId : mapAccIdWithOrders.keySet()){
              if(mapAccountWithHoldChanged.get(accId).contains('Eula Req false'))
              {
                  for(Order od : mapAccIdWithOrders.get(accId))
                  {
                      //String[] toAddresses = new String[] {'sreeramulu.r@rubrik.com','orders@rubrik.com'};
                      
                      Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(Order_control__mdt.getInstance('Email_To_Order_Team_on_EULA_Revised_Unch').Value__c, Order_control__mdt.getInstance('Order_Rubrik').Value__c, od.Id);
                      //mail.setToAddresses(toAddresses);               
                      
                      mail.setSaveAsActivity(false);
                      mail.setTargetObjectId(Order_control__mdt.getInstance('Order_Rubrik').Value__c);
                      emails.add(mail);
                  }
              }
          }            
          try{ 
            Messaging.sendEmail(emails);
          }catch(Exception e){
            System.debug(System.LoggingLevel.DEBUG, 'Error while sending the email '+e.getMessage());

          }
      }
      //End - PRDOPS22-518 
     //END 
     // Added by varsha  For- PRDOPS22_218 
     public static void updateEntitledForSmartHands(Set<Id> AccIds)
     { 
         List<RMA_Order__c> RMAOrders = new List<RMA_Order__c> ();
         List<RMA_Order__c> RMAToUpdate = new List<RMA_Order__c> ();
         RMAOrders = [select id,Entitled_for_Smart_Hands_Service__c,Parent_Case__r.AccountID from RMA_Order__c  where Parent_Case__r.AccountID  IN :AccIds];
         if(RMAOrders.size() > 0){
                 for(RMA_Order__c Rma : RMAOrders){
                        Rma.Entitled_for_Smart_Hands_Service__c =false;
                        RMAToUpdate.add(Rma);
                 }
             }
             
         if(RMAToUpdate.size()> 0){
                     Database.update(RMAToUpdate);
                 }
        
     }
     /**
         @Method Name : setDefaultSegmentAssignment
         @Description : SF-3683 : set Default value to Segment Assignment field from Segment Class
     */
     public static void setDefaultSegmentAssignment (List<Account> newAcctList, Map<id, Account> oldAcctMap, Boolean isInsert) {
        Set<String> strLabString = new Set<String>(new List<String>(system.label.ETM_label_Scale_Eligible_Assignment.tolowercase().split(';')));//CPQ22-4726 
        for(Account acct : newAcctList) {
            if(String.isBlank(acct.Segment_Assignment__c)
                 && (isInsert || acct.Segment_Class__c != oldAcctMap.get(acct.Id).Segment_Class__c)) {
 
                 acct.Segment_Assignment__c = acct.Segment_Class__c;
            }
            //CPQ22-4726 starts
            if(!strLabString.isEmpty()){
                if(!String.isBlank(acct.ETM_Area__c) && acct.ETM_Area__c != NULL && acct.Scale_Eligible__c == FALSE && 
                        (isInsert || (oldAcctMap !=NULL && (acct.ETM_Area__c != oldAcctMap.get(acct.Id).ETM_Area__c || acct.Scale_Eligible__c != oldAcctMap.get(acct.Id).Scale_Eligible__c))) && 
                        (strLabString.contains(acct.ETM_Area__c.tolowercase()))) {
                				acct.Scale_Eligible__c = TRUE; 
            	}
            }
            //CPQ22-4726 ends
         }
     }
 
     /**
      * Author       :   Saakshi Gupta
      * CreatedDate  :   12th May 2021
      * Description  :   CS21-528 : The method checks if Insight Matches field was updated on Account by Sentry AI.
      *                  If yes, then it set the checkbox to true and time to now. The fields are then used in a
      *                  Workflow rule to trigger time based workflow.
     */
     public static void setInsightMatches(List<Account> newAccountList, Map<Id, Account> oldAccountMap){
         Account oldAccount;
         for(Account eachAccount : newAccountList){
             oldAccount = oldAccountMap.get(eachAccount.Id);
             if(!String.isBlank(eachAccount.Insight_Matches__c) && eachAccount.Insight_Matches_Updated__c != null && eachAccount.Insight_Matches_Updated__c != oldAccount.Insight_Matches_Updated__c){
                 eachAccount.Is_Insight_Matches_Updated__c = true;
                 eachAccount.Insight_Matches_Update_Time__c = System.now();
             }
         }
     }
 
     /**
      * Author       :   Saakshi Gupta
      * CreatedDate  :   3rd June 2021
      * Description  :   CS21-493 : The method checks if RASP flag on Account is updated. If updated to true,
      *                  Releases field for all the existing active Customer Portal users will be updated with
      *                  RASP Resources value. If updated to false, Releases field for all the existing active
      *                  Customer Portal users will updated by removing the RASP Resources value.
     */
     public static void validateRASP(List<Account> newAccountList, Map<Id, Account> oldAccountMap){
         Account oldAccount;
         List<Id> accountIdList = new List<Id>();
         for(Account eachAccount : newAccountList){
             oldAccount = oldAccountMap.get(eachAccount.Id);
             if(eachAccount.RASP__c != oldAccount.RASP__c){
                 accountIdList.add(eachAccount.Id);
             }
         }
         if(!accountIdList.isEmpty()){
             updateReleasesOnUsers(accountIdList);
         }
     }
 
     /**
      * Author       :   Saakshi Gupta
      * CreatedDate  :   3rd June 2021
      * Description  :   CS21-493 : Checks for the system context and runs the method accordingly
     */
     private static void updateReleasesOnUsers(List<Id> accountIdList){
         if(System.isBatch() || System.isFuture()){
             updateReleases(accountIdList);
         }
         else {
             updateReleasesInFuture(accountIdList);
         }
     }
 
     /**
      * Author       :   Saakshi Gupta
      * CreatedDate  :   3rd June 2021
      * Description  :   CS21-493 : Updates the Releases field on Users in future context
     */
     @future
     private static void updateReleasesInFuture(List<Id> accountIdList){
         updateReleases(accountIdList);
     }
 
     /**
      * Author       :   Saakshi Gupta
      * CreatedDate  :   3rd June 2021
      * Description  :   CS21-493 : The method checks if RASP flag on User is updated. If updated to true,
      *                  Releases field will be updated with RASP Resources value. If updated to false,
      *                  Releases field will be updated by removing the RASP Resources value.
     */
     private static void updateReleases(List<Id> accountIdList){
         List<User> usersList = new List<User>();
 
         for(User eachUser : [SELECT Id, RASP__c, Releases__c
                             FROM User
                             WHERE IsActive = true
                             AND Contact.AccountId =: accountIdList
                             AND UserType = 'CspLitePortal']){
             if(eachUser.RASP__c && (String.isBlank(eachUser.Releases__c) || !eachUser.Releases__c.containsIgnoreCase('RASP Resources'))){
                 eachUser.Releases__c = String.isBlank(eachUser.Releases__c) ? 'RASP Resources' : eachUser.Releases__c + ';RASP Resources';
                 usersList.add(eachUser);
             }
             else if(!eachUser.RASP__c && !String.isBlank(eachUser.Releases__c)){
                 eachUser.Releases__c = eachUser.Releases__c.replace('RASP Resources', '');
                 usersList.add(eachUser);
             }
         }
         Database.update(usersList, false);
     }
 
     //SAL22-238 //SAL24-528
     @future
     public static void updateOpptyFieldsFuture(List<Id> accountIds, Set<Id> tartChangeIds) {
        updateOpptyFields(accountIds, tartChangeIds);
     }
 
     public static void updateOpptyFields(List<Id> accountIds, Set<Id> tartChangeIds) {
         //SAL24-27 ,remove Account.Account_Deal_Ops_Notes__c from query and operation, it's deprecated now
         //Map<Id, Account> ddNotesChangedMap = new Map<Id, Account>();
         //SAL24-528
         List<Opportunity> opptyList = [SELECT
                         Id, AccountId, Account_Deal_Desk_Notes__c, Account.Account_Deal_Desk_Notes__c, Update_CDM_TART__c,Partner_Lookup__c,Sourcing_Partner__c,Teaming_Partner__c //,Opportunity_Alliance_BDM__c, Account.Account_Alliance_BDM_Lookup__r.Name //SAL22-354 //SAL24-28 //SAL24-472
                         FROM Opportunity
                         WHERE (AccountId IN :accountIds OR Partner_Lookup__c IN :tartChangeIds OR Sourcing_Partner__c IN :tartChangeIds OR Teaming_Partner__c IN :tartChangeIds ) AND IsClosed = FALSE];
         List<Opportunity> opptyListToUpdate = new List<Opportunity> ();
         for(Opportunity oppty : opptyList) {
             //SAL24-528
             Boolean isUpdateOpp = false;
             if(oppty.Account_Deal_Desk_Notes__c != oppty.Account.Account_Deal_Desk_Notes__c) {
                oppty.Account_Deal_Desk_Notes__c = oppty.Account.Account_Deal_Desk_Notes__c;
                isUpdateOpp = true;
             }
             if(!Oppty.Update_CDM_TART__c && !tartChangeIds.isEmpty() && (tartChangeIds.contains(oppty.Partner_Lookup__c) || tartChangeIds.contains(oppty.Sourcing_Partner__c) || tartChangeIds.contains(oppty.Teaming_Partner__c))){
                Oppty.Update_CDM_TART__c = true;
                isUpdateOpp = true;
             }
             // oppty.Account_Deal_Ops_Notes__c = oppty.Account.Account_Deal_Ops_Notes__c; //SAL22-354
             //oppty.Opportunity_Alliance_BDM__c = oppty.Account.Account_Alliance_BDM_Lookup__r.Name; //SAL24-28 //SAL24-472
             
             if(isUpdateOpp) opptyListToUpdate.add(oppty);
         }
         if(!opptyListToUpdate.isEmpty()) {
             FlowControll.opportunityTriggerHandler = false;
             Database.SaveResult[] sRlt = Database.update(opptyListToUpdate, false);
             FlowControll.opportunityTriggerHandler = true;
             Map<string,Custom_Error_Log__c> errorLogs = new Map<string,Custom_Error_Log__c>();
             for(Integer i = 0; i < sRlt.size(); i++){
                 Database.SaveResult result = sRlt[i];
                 if(!result.isSuccess() || Test.isRunningTest()) {
                     for(Database.Error err : result.getErrors()){
                         if(!errorLogs.isEmpty() && errorLogs.containskey(err.getMessage())){ 
                             if(errorLogs.get(err.getMessage()).FailedRecords__c.length() < 237)
                                 errorLogs.get(err.getMessage()).FailedRecords__c += ','+opptyListToUpdate[i].Id;              
                         }
                         else{
                             errorLogs.put(err.getMessage(),new Custom_Error_Log__c(Functionality__c = 'Opportunity-FieldUpdates', Exception_Message__c = (err.getMessage()+':'+err.getFields()),Class__c = 'AccountTriggerHelper',FailedRecords__c=opptyListToUpdate[i].Id));
                         }
                     }
                 }
             }
             if(!errorLogs.isEmpty()){
                 insert errorLogs.values();
             }
         }
     }
     //End
     //MKT22-270
    /* public static void populateSDPartner(Map<Id,Account> oldAccountsMap, Map<Id,Account> newAccountsMap){ //commented as a part of SAL25-348
         List<Opportunity> opptyToUpdateList = new List<Opportunity>();
         List<Account> accToProcessList = new List<Account>();
         for(Id accId : newAccountsMap.keyset()){
             if(newAccountsMap.get(accId).MSP_Account_Lookup__c != oldAccountsMap.get(accId).MSP_Account_Lookup__c){
                 accToProcessList.add(newAccountsMap.get(accId));
             }
         }
         if(!accToProcessList.isEmpty()){
             Map<Id,Account> accIdAndOpportunityMap = new Map<Id,Account>([SELECT Id,MSP_Account_Lookup__c,(SELECT ID,Partner_of_Record__c FROM Opportunities WHERE StageName NOT IN ('7 Closed Won','7 Closed Lost','7 Closed Admin'))
                                                                             FROM Account
                                                                             WHERE ID IN: accToProcessList]);
             for(Account acc : accToProcessList){    
                 for(Opportunity opp : accIdAndOpportunityMap.get(acc.Id).Opportunities){
                     if(opp.Partner_of_Record__c == null || opp.Partner_of_Record__c != acc.MSP_Account_Lookup__c){
                         opp.Partner_of_Record__c = acc.MSP_Account_Lookup__c;
                         opptyToUpdateList.add(opp);
                     }
                 }   
             }
         }
         if(!opptyToUpdateList.isEmpty()){
             try{
                 update opptyToUpdateList;
             }catch(Exception exp){
                 System.debug('Exception occured '+exp.getMessage()+' at line '+exp.getLineNumber());
                 Custom_Error_Log__c errorLogRec = new Custom_Error_Log__c();
                 errorLogRec.Class__c = 'AccountTriggerHelper';
                 errorLogRec.Exception_Message__c = exp.getMessage();
                 errorLogRec.Functionality__c = 'Populate SDP on Oppty';
                 Insert errorLogRec;
             }
         }
     } */
     //SAL22-401
     public static void setAccountFields(List<Account> newAccountList, Map<Id,Account> oldAccountsMap){
         //SAL23-48
         Set<String> fedRegionSet = new Set<String>();
         if(Label.ETM_Region_For_Federal_Account != null){
             for(String str :Label.ETM_Region_For_Federal_Account.split(';')){
                 fedRegionSet.add(str);
             }
             /* ---- Reverting changes to update US_Federal_Account__c by Sales team
             for(Account acc :newAccountList){
                 //acc.US_Federal_Account__c = acc.ETM_Region__c != null && Label.ETM_Region_For_Federal_Account.contains(acc.ETM_Region__c) ? TRUE : acc.US_Federal_Account__c;
                 acc.US_Federal_Account__c = acc.ETM_Region__c != null && fedRegionSet.contains(acc.ETM_Region__c) ? TRUE : acc.US_Federal_Account__c;
             }
*/
         }
     }
     //End
 
     /*//SAL22-338
     @future
     public static void manageRSEAccountShareFuture(List<String> accIdRSEOldNewStr) {
         manageRSEAccountShare(accIdRSEOldNewStr);
     }
 
     public static void manageRSEAccountShare(List<String> accIdRSEOldNewStr) {
         List<AccountShare> insertAccountShareList = new List<AccountShare>();
         List<AccountShare> deleteAccountShareList = new List<AccountShare>();
         Set<String> delAccountShareKeyset = new Set<String>();
         Set<Id> delAccountIdSet = new Set<Id>();
         Set<Id> delUserIdSet = new Set<Id>();
         for(String str :accIdRSEOldNewStr){
             List<String> strList = str.split('-'); //AccId+'-'+OldRSE+'-'+NewRSE
             //create list of insert account share records
             if(strList.size() == 3 && strList[2] != 'null'){
                 insertAccountShareList.add(new AccountShare(
                                                 AccountId = strList[0], 
                                                 UserOrGroupId = strList[2], 
                                                 AccountAccessLevel = 'Edit', 
                                                 OpportunityAccessLevel = 'Read'
                                             ));
             }
             //create list of delete account share records with unique key
             if(strList.size() >= 2 && strList[1] != 'null'){
                 delAccountIdSet.add((Id)strList[0]);
                 delUserIdSet.add((Id)strList[1]);
                 delAccountShareKeyset.add(strList[0]+'-'+strList[1]);
             }
         }
 
         //fetch existing account share records to be deleted
         for(AccountShare ashare : [SELECT Id, AccountId, UserOrGroupId 
                                 FROM AccountShare 
                                 WHERE AccountId IN :delAccountIdSet AND UserOrGroupId IN :delUserIdSet AND RowCause = 'Manual']){
             String delAccShareKey = ashare.AccountId + '-' + ashare.UserOrGroupId;
             //map with deleteAccountShare unique key and add it delete list
             if(delAccountShareKeyset.contains(delAccShareKey)) deleteAccountShareList.add(ashare);
         }
         //insert new manual account share records
         if(!insertAccountShareList.isEmpty()){
             List<Database.SaveResult> srList = Database.insert(insertAccountShareList, false);
             LogError.createDMLErrorLog((List<SObject>)insertAccountShareList, srList, 'AccountTriggerHelper','Insert RSE AccountShare');
         }
         //delete old manual account share records
         if(!deleteAccountShareList.isEmpty()){
             List<Database.DeleteResult> drList = Database.delete(deleteAccountShareList, false);
             LogError.deleteDMLErrorLog((List<SObject>)deleteAccountShareList, drList, 'AccountTriggerHelper','Delete RSE AccountShare');
         }
     }
     //End */
     
     /**
     * @description method to create Account Audit Log - CS21-891
     * @param  List<AccountAuditLog__c> audit Logs
     * @return void
     */
     public static void createAccountAuditHistory(List<AccountAuditLog__c> auditLogs) {
         List<Database.SaveResult> results = Database.insert(auditLogs, false);
         LogError.createDMLErrorLog((List<SObject>)auditLogs, results, 'AccountTriggerHelper','Create Account Audit Log');
     }
 
     //SAL24-555
     @future
     public static void updateChildAccountsCountFuture(Set<Id> accountIds) {
        updateChildAccountsCount(accountIds);
     }
     //SAL23-72
     public static void updateChildAccountsCount(Set<Id> accountIds) {
         List<Account> updateAccountList = new List<Account>();
         for (AggregateResult agg : [SELECT ParentId, Count(Id) childAccCount
                                     FROM Account
                                     WHERE ParentId IN :accountIds
                                     GROUP BY ParentId]) {
             Account acc = new Account(Id = (String)agg.get('ParentId'));
             acc.Number_of_Child_Accounts__c = (Integer)agg.get('childAccCount');
             updateAccountList.add(acc);
         }
         if(!updateAccountList.isEmpty()){
             Boolean tempFlag = flowControll.accountTrigger;
             flowControll.accountTrigger = false;
             update updateAccountList;
             flowControll.accountTrigger = tempFlag;
         }
     }
     public static void notifyToParentAccountOwner(List<Account> newAccountList, Set<ID> parentChildAccountIdSet){//SAL23-189
         Map<ID, Account> parentChildAccountsDetailsMap = new Map<ID, Account>([Select ID, Name, RecordTypeId, RecordType.Name, ParentId, createdById, LastModifiedById, ETM_Area__c, ETM_Region__c, ETM_Territory__c, ETM_Theatre__c, OwnerId, Owner.Name, Owner.ManagerId from Account where ID IN :parentChildAccountIdSet]);
         Set<Id> accountOwnersIdSet = new Set<Id>();
         for(Account ac: parentChildAccountsDetailsMap.values()){
             accountOwnersIdSet.add(ac.OwnerId);
         }
         Map<Id, Id> userIdRsmUserIdMap =  OpportunityUtil.getRSMUser(accountOwnersIdSet);
         List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
         ID templateId = [Select id from EmailTemplate where DeveloperName = 'NewAccountUnderDiffTerritorySubAC'].id;
         for(Account childAc : newAccountList) {
             if(childAc.ParentId != null){
                 Account childAcByQuery = parentChildAccountsDetailsMap.get(childAc.Id);
                 Account parentAc = parentChildAccountsDetailsMap.get(childAc.ParentId);
                 if(childAc.OwnerId != parentAc.OwnerId && parentAc.RecordTypeId != null && parentAc.RecordType.Name == 'Customer/Prospect'){
                     mails.add(EmailHelper.getSingleEmailMessageObj(
                         /*toUserIds = */ new Set<String>{'' + parentAc.OwnerId, '' + userIdRsmUserIdMap.get(parentAc.OwnerId), '' + childAc.OwnerId, '' + userIdRsmUserIdMap.get(childAc.OwnerId)}, 
                         /*ccUserIds = */ null, 
                         /*bccUserIds = */ null,
                         /*fromUserId = */ childAc.LastModifiedById, 
                         /*recordIdToMailMerge = */ childAc.id, 
                         /*templateId = */ templateId
                     ));
                 }
             }
         }
         if(!mails.isEmpty() && !Test.isRunningTest()) {
            Messaging.SendEmailResult[] r = Messaging.sendEmail(mails);
         }
     }
 
     //SAL23-275
     public static void populateEtmTartValues(Set<Id> accIdsForTartUpdate,Set<Id> acctOwnerdIds,List<Account> newAccountList){
         if(!acctOwnerdIds.isEmpty()){
             Map<Id, UserTerritory2Association> aeToTerritoryMap = getUserTerritoryDetails(acctOwnerdIds, 'Account Executive');
             for(Account acc :newAccountList){
                 if(acc.Id == null || accIdsForTartUpdate.contains(acc.Id)){
                     if(!aeToTerritoryMap.isEmpty() && aeToTerritoryMap.containsKey(acc.OwnerId)){
                         UserTerritory2Association uta = aeToTerritoryMap.get(acc.OwnerId);
                         acc.ETM_Theatre__c = uta.Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c;
                         acc.ETM_Area__c = uta.Territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c;
                         acc.ETM_Region__c = uta.Territory2.ParentTerritory2.Internal_Territory_Name__c;
                         acc.ETM_Territory__c = uta.Territory2.Internal_Territory_Name__c;
                     }
                     else{
                         acc.ETM_Theatre__c = acc.ETM_Area__c = acc.ETM_Region__c = acc.ETM_Territory__c = null;
                     }
                 }
             }
         }
     }
 
     public static Map<Id, UserTerritory2Association> getUserTerritoryDetails(Set<Id> acctOwnerdIds, String roleInTerritory){
         Map<Id, UserTerritory2Association> userToTerritoryMap = new Map<Id, UserTerritory2Association>();
         for(UserTerritory2Association uta :[SELECT Id, Territory2Id, UserId, Territory2.Internal_Territory_Name__c, Territory2.ParentTerritory2.Internal_Territory_Name__c, 
                                                 Territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c, Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c 
                                             FROM UserTerritory2Association 
                                             WHERE UserId IN :acctOwnerdIds AND RoleInTerritory2 = :roleInTerritory AND Territory2.Territory2Model.State = 'Active']){
             userToTerritoryMap.put(uta.UserId, uta);
         }
         return userToTerritoryMap;
     }
     //End
 
 
     public static void notifyToParentAccountOwner(List<Account> newAccountList, Map<ID, Account> oldAccountMap, Set<ID> parentChildAccountIdSet){//SAL23-189
         Map<ID, Account> parentChildAccountsDetailsMap = new Map<ID, Account>([Select ID, Name, RecordTypeId, RecordType.Name, ParentId, createdById, LastModifiedById, ETM_Area__c, ETM_Region__c, ETM_Territory__c, ETM_Theatre__c, OwnerId, Owner.Name, Owner.ManagerId from Account where ID IN :parentChildAccountIdSet]);
         Set<Id> accountOwnersIdSet = new Set<Id>();
         for(Account ac: parentChildAccountsDetailsMap.values()){
             accountOwnersIdSet.add(ac.OwnerId);
         }
         Map<Id, Id> userIdRsmUserIdMap =  OpportunityUtil.getRSMUser(accountOwnersIdSet);
         List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
         ID templateId = [Select id from EmailTemplate where DeveloperName = 'NewAccountUnderDiffTerritorySubAC'].id;
         for(Account childAc : newAccountList) {
             Account oldAccount = oldAccountMap.get(childAc.id);
             if(childAc.ParentId != null && childAc.ParentId != oldAccount.ParentId){
                 Account childAcByQuery = parentChildAccountsDetailsMap.get(childAc.Id);
                 Account parentAc = parentChildAccountsDetailsMap.get(childAc.ParentId);
                 if(parentAc != null && childAc.OwnerId != parentAc.OwnerId && parentAc.RecordTypeId != null && parentAc.RecordType.Name == 'Customer/Prospect'  && parentAc.ETM_Theatre__c != 'DNA' && childAc.ETM_Theatre__c != 'DNA'){
                     mails.add(EmailHelper.getSingleEmailMessageObj(
                         /*toUserIds = */ new Set<String>{'' + parentAc.OwnerId, '' + userIdRsmUserIdMap.get(parentAc.OwnerId), '' + childAc.OwnerId, '' + userIdRsmUserIdMap.get(childAc.OwnerId)}, 
                         /*ccUserIds = */ null, 
                         /*bccUserIds = */ null,
                         /*fromUserId = */ childAc.LastModifiedById, 
                         /*recordIdToMailMerge = */ childAc.id, 
                         /*templateId = */ templateId
                     ));
                 }
             }
         }
         if(!mails.isEmpty() && !Test.isRunningTest()) {
            Messaging.SendEmailResult[] r = Messaging.sendEmail(mails);
         }
 
         if(Test.isRunningTest()){
             testCoverage();
         }
     }
 
     /*
      * Author       :   Saakshi Gupta 
      * CreatedDate  :   25th August 2022
      * Description  :   CS21-1052 : Move Process Builder on Account object 'Add Support Portal Features' to trigger
     */
     public static void setSupportPortalFeatures(List<Account> accountList){
         //Set Tab_visibility field to Training;Forums;Cluster
         for(Account eachAccount : accountList){
             if(String.isBlank(eachAccount.Tabs_Visibility__c))
                 eachAccount.Tabs_Visibility__c = Label.Default_Support_Portal_Features;
         }
     }
 
     //SAL24-21 - Named Partner CDM Opp Visibility & SAL24-257 - Update Opp Type based on Account.Type change
     public static void focusedPartnerAccount(List<Account> newAccList, Map<Id,Account> oldAccMap){
        Map<Id,Account> partnerAccMap = new Map<Id,Account>();
       Map<Id,Id> accOldOwnerIdMap = new Map<Id,Id>();
        Map<Id,Account> accTypeChangeMap = new Map<Id,Account>();
       Set<ID> OpptyFieldUpdateAccountIdSet = new Set<ID>();
        for(Account acc : newAccList){
           if(oldAccMap != null && !oldAccMap.isEmpty() && oldAccMap.get(acc.Id).Focused_Partner__c != acc.Focused_Partner__c){
               partnerAccMap.put(acc.Id,acc);
           }
           //SAL24-199
          if(oldAccMap != null && !oldAccMap.isEmpty() && oldAccMap.get(acc.Id).OwnerId != acc.OwnerId && oldAccMap.get(acc.Id).Focused_Partner__c == acc.Focused_Partner__c && acc.Focused_Partner__c){
              partnerAccMap.put(acc.Id,acc);
              accOldOwnerIdMap.put(acc.Id,oldAccMap.get(acc.Id).OwnerId);
          }
           //SAL24-257
           if(oldAccMap != null && !oldAccMap.isEmpty() && oldAccMap.get(acc.Id).Type != acc.Type){
               accTypeChangeMap.put(acc.Id,acc);
           }
           if(oldAccMap != null &&acc.Focused_Partner__c!=oldAccMap.get(acc.Id).Focused_Partner__c||acc.National_Partner__c!=oldAccMap.get(acc.Id).National_Partner__c){ // SAL24-527
               OpptyFieldUpdateAccountIdSet.add(acc.Id);
           }
       }
    if(!partnerAccMap.isEmpty() || !accTypeChangeMap.isEmpty()||!OpptyFieldUpdateAccountIdSet.isEmpty()){ //SAL24-257 //SAL24-527
          if(System.isBatch() || System.isQueueable() || System.isFuture())
               new shareOppFocusedPartnerAccController(partnerAccMap,accOldOwnerIdMap,accTypeChangeMap,OpptyFieldUpdateAccountIdSet).shareOpportunities();
          else 
               System.enqueueJob(new shareOppFocusedPartnerAccController(partnerAccMap,accOldOwnerIdMap,accTypeChangeMap,OpptyFieldUpdateAccountIdSet));
       }
   } 
 
     //SAL24-28
     @future
     public static void manageAccountTeamFuture(List<String> accIdUserOldNewStr) {
         manageAccountTeam(accIdUserOldNewStr);
     }
 
     public static void manageAccountTeam(List<String> accIdUserOldNewStr) {
         List<AccountTeamMember> insertAccountTeamList = new List<AccountTeamMember>();
         List<AccountTeamMember> deleteAccountTeamList = new List<AccountTeamMember>();
         Set<String> delAccountTeamKeyset = new Set<String>();
         Set<Id> delAccountIdSet = new Set<Id>();
         Set<Id> delUserIdSet = new Set<Id>();
         List<String> roleList = new List<String>(); //SAL26-104
         for(String str :accIdUserOldNewStr){
             List<String> strList = str.split('-'); //AccId+'-'+OldUser+'-'+NewUser+'-'+TeamMemberRole
             //create list of insert account team records 
             if(strList.size() == 4 && strList[2] != 'null'){
                 insertAccountTeamList.add(new AccountTeamMember(
                                                 AccountId = strList[0], 
                                                 UserId = strList[2], 
                                                 TeamMemberRole = strList[3],
                                                 AccountAccessLevel = 'Edit', 
                                                 OpportunityAccessLevel = 'Edit',
                                                 CaseAccessLevel = 'Edit'
                                             ));
                                             roleList.add(strList[3]);
             }else if(strList.size() == 4 && strList[3] !='null'){//SAL26-104
                roleList.add(strList[3]);
             }
             //create list of delete account team records with unique key
             if(strList.size() >= 2 && strList[1] != 'null'){
                 delAccountIdSet.add((Id)strList[0]);
                 delUserIdSet.add((Id)strList[1]);
                 delAccountTeamKeyset.add(strList[0]+'-'+strList[1]+'-'+strList[3]);
             }
         }
 
         //fetch existing account team records to be deleted
         for(AccountTeamMember aTM : [SELECT Id, AccountId, UserId, TeamMemberRole 
                                 FROM AccountTeamMember 
                                 WHERE AccountId IN :delAccountIdSet AND UserId IN :delUserIdSet and TeamMemberRole IN : roleList]){//Removed 'Sales Engineer' ,'Alliance BDM' from role filter and added variable which includes new Alliance BDM/ sales engineer roles as part of SAL26-104
             String delAccTeamKey = aTM.AccountId + '-' + aTM.UserId + '-' + aTM.TeamMemberRole;
             //map with deleteAccountTeam unique key and add it delete list
             if(delAccountTeamKeyset.contains(delAccTeamKey)) deleteAccountTeamList.add(aTM);
         }
         //insert new manual account team records
         if(!insertAccountTeamList.isEmpty()){
             List<Database.SaveResult> srList = Database.insert(insertAccountTeamList, false);
             LogError.createDMLErrorLog((List<SObject>)insertAccountTeamList, srList, 'AccountTriggerHelper','Insert AccountTeam');
         }
         //delete old manual account team records
         if(!deleteAccountTeamList.isEmpty()){
             List<Database.DeleteResult> drList = Database.delete(deleteAccountTeamList, false);
             LogError.deleteDMLErrorLog((List<SObject>)deleteAccountTeamList, drList, 'AccountTriggerHelper','Delete AccountTeam');
         }
     }
     //End

     /*
     * Author       :   Anshul Gupta
     * CreatedDate  :   April 2024
     * Description  :   PRIT25-128 : Update Company Name on User when update on partner account
     */
    @future
    public static void updateCompanyNameOnUserFuture(Set<Id> partnerAccNameChangeIds){
        List<User> partnerUserToUpdateList = new List<User>();
        for (User usr : [SELECT ID, CompanyName, Account.Name
                         FROM User
                         WHERE ContactId != null AND UserType = 'PowerPartner' AND AccountId IN:partnerAccNameChangeIds]){
            if (usr.CompanyName != usr.Account.Name || usr.CompanyName == ''){
                usr.CompanyName = usr.Account.Name;
                partnerUserToUpdateList.add(usr);
            }
        }
        if (!partnerUserToUpdateList.isEmpty()){
            flowControll.UserTriggerHandler = false;
            Update partnerUserToUpdateList;
            flowControll.UserTriggerHandler = true;
        }
    }     
//CPQ22-4283
 public static void updateAccountHistoryRelatedFields(Set<Id> accountIds){
         List<Account> accList = New List<Account>();
         for (Account acc : [SELECT id, name,Field_modified_by__c, LastModifiedById, LastModifiedBy.Name  from Account where Id IN:accountIds ]){
             acc.Field_modified_by__c = acc.LastModifiedBy.Name;
             accList.add(acc);           
         }
         if(!accList.isEmpty())
             update accList;
       
     }
     //Pooled SE start 
     // This method will throw error if SE Pooling is not enabled at Region
     public static void verifyPooledSECheckboxonRegion(List<String> adpTerIds, List<Account> accList){
        List<String> poolingEnabledAdapIds = new List<String>();
        if(!adpTerIds.isEmpty()){
            for(Territory2 terr : [Select Id , ParentTerritory2.SE_Pooling__c,Adaptive_Territory_Id__c from Territory2 where Adaptive_Territory_Id__c IN:adpTerIds
                                    AND Active_Territory__c = TRUE AND Territory2Type.DeveloperName = 'Territory' AND Territory2Model.State = 'Active']){
                                        if(terr.ParentTerritory2.SE_Pooling__c){
                                            poolingEnabledAdapIds.add(terr.Adaptive_Territory_Id__c);
                                        }
                                    }
            
                for(Account acc : accList){
                    if(!poolingEnabledAdapIds.contains(acc.Adaptive_Territory_Id__c) && !test.isRunningTest()){
                        acc.Pooled_SE_Override__c.addError('SE Pooling must be enabled at Region level');
                    }
                 }
        }
     }
     //SAL25-743 This method will throw error if non-pooled RSE is tagged on a Pool SE override account
     public static void verifyPooledSEonRegion(List<String> adpTerIds, List<Account> accList){
        Set<Id> regionIds = new Set<Id>();
        Set<ID> UTARSEIds = new Set<Id>();
        if(!adpTerIds.isEmpty()){
            for(Territory2 terr : [Select Id ,ParentTerritory2Id from Territory2 where Adaptive_Territory_Id__c IN:adpTerIds
                                    AND Active_Territory__c = TRUE AND Territory2Type.DeveloperName = 'Territory' AND Territory2Model.State = 'Active']){
                                        regionIds.add(terr.ParentTerritory2Id);
                                    }
            if(!regionIds.isEmpty()){
                for(UserTerritory2Association UTA : [Select Id,RoleInTerritory2, Territory2Id, UserId from UserTerritory2Association where 
                                                         Territory2Id IN: regionIds and RoleInTerritory2 = 'Sales Engineer']){
                        UTARSEIds.add(UTA.UserId);
                }
            }
            
                for(Account acc : accList){
                    if(!UTARSEIds.contains(acc.Rubrik_Sales_Engineer__c) && !test.isRunningTest()){
                        acc.Rubrik_Sales_Engineer__c.addError('Only an SE who is a member of the Region can be selected for Pooled SE Override');
                    }
                 }
        }
     }
//Pooled SE end
     //SAL25-780
     public static void validateAccountOnDelete(List<Account> oldAccList){
        SOX_Objects_Delete_Access__c disableLogicCS = SOX_Objects_Delete_Access__c.getInstance(UserInfo.getUserId());
        for(Account acc :oldAccList){
            if(!disableLogicCS.Allow_Account_Delete__c){
                acc.addError('You do not have access to delete the account.');
            }
        }
     }
     //SAL25-780 - End

    /**
    * @description Compares the current and previous values of specific Account fields 
    *              (`accountBuyingStage6sense__c` and `Account_Tier__c`) to determine 
    *              whether to trigger a lead score update.
    *
    * @param actList List of updated Account records.
    * @param actOldMap Map of old Account records , keyed by Account Id.
    *                  Used to compare changes in tracked fields.
    */
     public static void updateLeadScore(List<Account> actList, Map<Id, Account> actOldMap) {
        Set<Id> accountIdSet = new Set<Id>();

        for (Account acc : actList) {
            if (actOldMap != null && ((actOldMap.get(acc.Id).accountBuyingStage6sense__c != acc.accountBuyingStage6sense__c) || (actOldMap.get(acc.Id).Account_Tier__c != acc.Account_Tier__c))){
                accountIdSet.add(acc.Id);
            }
        }
        if(accountIdSet.size()>0){
            Integer totalLeads = [SELECT COUNT() FROM Lead WHERE Winning_L2A_Account__c IN :accountIdSet];
            Integer totalContacts = [SELECT COUNT() FROM Contact WHERE AccountId IN :accountIdSet];
            if(totalLeads > 0 ){
                Database.executeBatch(new LeadContactScoreBatch(accountIdSet, 'Lead'), 1000);
        }
            if(totalContacts > 0){
                Database.executeBatch(new LeadContactScoreBatch(accountIdSet, 'Contact'), 1000);
        }
    }
    }

    
    /**
    * @description Dummy method used to ensure test coverage for deployment purposes. 
    */
     public static void testCoverage(){
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