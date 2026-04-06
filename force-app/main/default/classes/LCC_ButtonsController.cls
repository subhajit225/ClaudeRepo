public without sharing class LCC_ButtonsController {         

    private static String quotedString(String s) { 
        return '\'' + s + '\'';
    }
		
    @AuraEnabled
    public static Order getOrder(String rmaId, String orderType, String orderSubType){
        try { 
            String q = '';
            q += 'SELECT Id, Cancel_RMA__c ';
            q += 'FROM Order ';
            q += 'WHERE ';
            q += 'RMA_Request__c = ' + quotedString(rmaId);
            q += '  AND Order_Sub_Type__c = ' + quotedString(orderSubType);
            q += '  AND Type = ' + quotedString(orderType);
            q += '  LIMIT 1';
            return Database.query(q);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static void cancelOrder(String orderId){
        try {
            update new Order (
                Id = orderId ,Cancel_RMA__c = true
            );
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

@AuraEnabled
    public static string saveRecord(sobject rec){
        string message = '';
        try{
            system.debug('@@ rec '+rec);
        	update rec;

        }catch(Exception e){
            if(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                message = 'Exception occurred : '+e.getMessage().subStringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION,').removeEnd(': []');
            } else {
                message = 'Exception occurred : '+e.getMessage();
            }
            system.debug('@@ Exception occurred '+e.getMessage());
        }
        return message;
    }
    /**
     * Method to save an Order record and handle updates for associated phantom orders.
     * This method casts the input sObject to an Order, updates it, and if an associated
     * phantom order number is present, sets its Sync_to_NetSuite__c flag and updates it as well.
     *
     * @param orderRec Generic sObject expected to be of type Order, representing the main order to save.
     *
     * @return String A success message (empty string) or error message if an exception occurs.
     *
     * @author Naveen Selvaraj
     * @date 07-05-2025
     */
    @AuraEnabled
  public static String saveOrderRecord(sObject orderRec, List<Object> actionItems) {
    string message = '';
    try {
        List<Order> ordersToUpdate = new List<Order>();
        Order orderRecord = (Order) orderRec;
      List<String> actionItemsList = new List<String>();
      for (Object item : actionItems) {
         actionItemsList.add((String)item);
      }
        ordersToUpdate.add(orderRecord);
        String phantomOrderId = orderRecord.Associated_Order_Numbers__c != null ? orderRecord.Associated_Order_Numbers__c.trim() : null;
      if (phantomOrderId != null && actionItemsList != null && !actionItemsList.isEmpty() && actionItemsList.contains('SubmitPhantomOrder')) {
        Order phantomOrder = [SELECT Id, Sync_to_NetSuite__c FROM Order WHERE OrderNumber = :phantomOrderId LIMIT 1];
        phantomOrder.Sync_to_NetSuite__c = true;
        ordersToUpdate.add(phantomOrder);
        }
        if (!ordersToUpdate.isEmpty()) {
        update ordersToUpdate;
        }
    } catch (Exception e) {
        if (e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
        message = 'Exception occurred : ' + e.getMessage().subStringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION,').removeEnd(': []');
        } else {
        message = 'Exception occurred : ' + e.getMessage();
        }
    }
    return message;
    }
    @AuraEnabled
    public static string resynEdi(string poId){
        string message = '';
        try{
            
           FlowControll.opportunityTriggerHandler = false; 
           
           List<PO_Stage__c> poStageupdates = [Select id,Opportunity__c, Quote__r.SBQQ__Opportunity2__c, Quote__r.SBQQ__Opportunity2__r.SBQQ__Ordered__c, PO_Validation_Status__c, PO_Internal_Validation_Status__c, (select id from Orders__r) from PO_Stage__c where id =:poId ];
           
           if(poStageupdates[0].PO_Validation_Status__c != 'Success' && poStageupdates[0].PO_Validation_Status__c != 'Success - 855 Sent')
               return 'Validation is not completed, PO validation status is not success';
            
           if(poStageupdates[0].Orders__r != null && !poStageupdates[0].Orders__r.isEmpty())
                return 'Please delink all the orders linked to Opportunity';
            
            if(poStageupdates[0].Quote__r.SBQQ__Opportunity2__r.SBQQ__Ordered__c){
                poStageupdates[0].PO_Internal_Validation_Status__c = 'Internal Failure';   
                Opportunity updateOpp = new Opportunity(Id = poStageupdates[0].Quote__r.SBQQ__Opportunity2__c, SBQQ__Ordered__c = false);
                update poStageupdates; 
                update updateOpp;
            }          
 

        }catch(Exception e){
            if(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                message = 'Exception occurred : '+e.getMessage().subStringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION,').removeEnd(': []');
            } else {
                message = 'Exception occurred : '+e.getMessage();
            }
            system.debug('@@ Exception occurred '+e.getMessage());
        }
        return message;
    }
    @AuraEnabled
    public static void saveOpportunity(Opportunity rec){
        try{
            update rec;
        } catch (Exception ex){
            if(ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                throw new AuraHandledException('Error : '+ex.getMessage().subStringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION,').removeEnd(': []'));
            } else {
                throw new AuraHandledException('Error : '+ex.getMessage());
            }
        }
        update rec;
    }
 @AuraEnabled
    public static List<OrderItem> getOrderItems(string ordId){
        List<OrderItem> orditemList = new List<OrderItem>();
        orditemList = [SELECT id,SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__ExpirationDate__c,Order.Type,Order.Order_Sub_Type__c,OrderId,SerialNumber__c,SBQQ__QuoteLine__r.Subscribed_Asset_Name__c,Product2.License_Type__c,SBQQ__SubscriptionTerm__c,product2.SBQQ__SubscriptionPricing__c, Support_Start_Date__c, Support_End_Date__c from Orderitem WHERE OrderId=: ordId];
        return orditemList;
    }
  @AuraEnabled
    public static List<OrderItem> getRMAOrderItems(string ordId){
        List<OrderItem> orditemList = new List<OrderItem>();
        orditemList = [SELECT id,UnitPrice,Order.Type,Order.Order_Sub_Type__c,OrderId from Orderitem WHERE OrderId=: ordId];
        return orditemList;
    } 
   @AuraEnabled
    public static Account getAccountRec(string accId, Boolean legacyQuote){
        Account accountRec = new Account();
        Id userId = userInfo.getUserId(); 
        List<GroupMember> lstgroupmember = [Select group.Name, UserOrGroupId, GroupId From GroupMember where group.Name = 'Access to Legacy Quote' AND 
                                            UserOrGroupId =: userId LIMIT 1];
        if (legacyQuote == false) {
            //if(lstgroupmember.size()>0){
            if(!lstgroupmember.isEmpty()){
        		accountRec = [SELECT Id,Name,Is_Refreshed__c,BillingCountry,BillingStreet,BillingCity,BillingState,BillingPostalCode,ShippingPostalCode,
                       ShippingCountry,ShippingStreet,ShippingState,ShippingCity from Account WHERE Id=: accId];
            }else{
                accountRec = null;
            }
        }
        else {
            accountRec = [SELECT Id,Name,Is_Refreshed__c,BillingCountry,BillingStreet,BillingCity,BillingState,BillingPostalCode,ShippingPostalCode,
                       ShippingCountry,ShippingStreet,ShippingState,ShippingCity from Account WHERE Id=: accId];
        }
        //System.debug('legacyQuote-'+legacyQuote+'accountRec->'+accountRec);
        return accountRec;
    }     
    @AuraEnabled
    public static response_Wrapper upsertRSCProcess(object req,Boolean isFreeTrial,Boolean gtcScreeningPassed,Account acct){
        String str =  JSON.serialize(req);
        response_Wrapper response = new response_Wrapper();
        Entitlement freeTrialEntitlement = new Entitlement();
        Entitlement rscEntitlement = new Entitlement();
        Account_Screening__c screeningRecordObj = new Account_Screening__c();
        Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(str);
        RSC_Process__c recordsForUpdate = new RSC_Process__c();
        try{
            system.debug('acct obj' + acct);
            
            Id accountId = (Id)m.get('AccountID__c');
            system.debug('acct Id' + accountId);

            if(isFreeTrial){
                if(!gtcScreeningPassed)
                startGtcSreening(acct); 
                publishEntUpdateEvent(acct.Id);
                //freeTrialEntitlement = createFreeEntitlementRecord(accountId);    
			}
            
            List<RSC_Process__c>  rSCProcess = [Select Id from RSC_Process__c where AccountID__c = : accountId];
            if(!isFreeTrial){
                rscEntitlement = [Select id from Entitlement where AccountId = : accountId AND Status = 'Active' AND Type= 'Admin' AND SubType__c = 'RSC' Limit 1];
            }
            recordsForUpdate.AccountID__c = (Id)m.get('AccountID__c');
            recordsForUpdate.Customer_Suggest_URL__c = (String)m.get('Customer_Suggest_URL__c');
            system.debug('Expiry date ' + date.valueOf((String)m.get('Expiry_Date__c')));
            recordsForUpdate.Expiry_Date__c = date.valueOf((String)m.get('Expiry_Date__c'));
            recordsForUpdate.PolarisRegion__c = (String)m.get('PolarisRegion__c');
            recordsForUpdate.Polaris_Suggest_URL__c = (String)m.get('Polaris_Suggest_URL__c');
            recordsForUpdate.RSC_Contact_Email__c = (String)m.get('RSC_Contact_Email__c');
            recordsForUpdate.RSC_Status__c = 'Initiated';
            if(rscEntitlement!= null){
                //recordsForUpdate.Entitlement__c = freeTrialEntitlement?.Id;
                recordsForUpdate.Entitlement__c = rscEntitlement?.Id;
            }
            
            if(isFreeTrial){
               recordsForUpdate.Free_trail__c = 'Free Trial';    
            }else{
                recordsForUpdate.Free_trail__c = '';    
            }
    
            if(rSCProcess != null && !rSCProcess.isEmpty()){
                recordsForUpdate.Id = RSCProcess[0].Id;
            }
            system.debug('record to upsert' + recordsForUpdate);
            upsert recordsForUpdate;
            response.rscRecId = recordsForUpdate.Id;
            response.isSuccess = true;
        }catch(exception ex){
            response.isSuccess = false;	
            response.errorMessage = ex.getMessage();	 
        }
        system.debug('response is ' + JSON.serialize(response));
        return response;
    }
    
    @future
    public static void publishEntUpdateEvent(String acctId){
        try{
            EntitlementUpdate__e updateEnt=  new EntitlementUpdate__e(RecordId__c = acctId);
        	EventBus.publish(updateent);
        } 
        catch(Exception ex){
        	throw new AuraHandledException(ex.getMessage());    
        }
    }
  @AuraEnabled
    public static List<wrapperClass> getSetupCompanyMaster(){
        List<wrapperClass> wcList = new List<wrapperClass>();
        SetupCompanyMaster__c cm = new SetupCompanyMaster__c();
        cm = SetupCompanyMaster__c.getInstance();
        system.debug('@@@ cm '+cm);
        User u = [select Id,Division,Profile.Name from User where Id=: userinfo.getUserId()];
        wcList.add(new wrapperClass(cm.Enable_CM__c,u.Division,u.Profile.Name));
        return wcList;
    }
    public class wrapperClass{
        @AuraEnabled public Boolean Enable_CM;
        @AuraEnabled public String userDivision;
        @AuraEnabled public String profName;
        public wrapperClass(Boolean Enable_CM1,String userDivision1, String profName1){
            Enable_CM = Enable_CM1;
            userDivision = userDivision1;
            profName = profName1;
        }
    }
 /*@AuraEnabled
    public static void singleEmail(Apttus__APTS_Agreement__c agr){
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setInReplyTo('krpatel@apttus.com');
        message.setTemplateId('00X1D000000NIpD');
        message.setTargetObjectId(agr.Apttus__Primary_Contact__c);
        message.setWhatId(agr.Id);
        message.setSaveAsActivity(false);
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        if (results[0].success) {
            System.debug('The email was sent successfully.');
        } else {
            System.debug('The email failed to send: '
                  + results[0].errors[0].message);
        }
    }*/
    
    @AuraEnabled	
public Static response_Wrapper createEntitlementSupportRec(Entitlement_Warranty_Details__c req){	
response_Wrapper response = new response_Wrapper();	
List<Entitlement> ent = new List<Entitlement>();	
if(req.Entitlement__c != null)	
ent = [select id, name,(select Id from Entitlement_Warrenty_Details__r) from Entitlement where id =: req.Entitlement__c];	    
	
///list<Entitlement_Warranty_Details__c> warrantyList = [select Id from Entitlement_Warranty_Details__c where Entitlement__c =: req.Entitlement__c];	
//List<User> users = [SELECT Contact.AccountId, ContactId, Contact.Account.ownerId,Contact.Account.Name, email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];	
try{
Integer index = ent[0].Entitlement_Warrenty_Details__r.size();	
index++;	
req.name = ent[0].name + '-' +  index;    
insert req;	
response.warrentyRec = req;	
//PC_PartnerSpecializationRequestCtrlr.callpactsafe(spReq.Partner_Company_Name__c,users[0].Contact.Account.Name, users[0].email, users[0].ContactId, spReq.id, spReq.Country__c);	
} catch(DMLException  e) {	
response.isSuccess = false;	
response.errorMessage = e.getDmlMessage(0);	
}	
return response;	
}	
public class response_Wrapper {	
@auraEnabled public List<Contact> contactRecords{get;set;}	
//@auraEnabled public Map<String,List<picklistOptions>> pickListOptns{get;set;}	
@auraEnabled public List<Account> accList{get;set;}	
@auraEnabled public List<user> userRecds{get;set;}	
@auraEnabled public Entitlement_Warranty_Details__c warrentyRec{get;set;}	
        @auraEnabled public String rscRecId{get;set;}
@auraEnabled public boolean isSuccess{get;set;}	
@auraEnabled public string errorMessage  {get;set;}	
public response_Wrapper(){	
this.isSuccess = true;	
this.errorMessage = '';	
this.userRecds = new List<user>();	
this.contactRecords = new List<Contact>();	
this.accList = new List<Account>();	
this.warrentyRec = new Entitlement_Warranty_Details__c();	
            this.rscRecId = '';
//this.pickListOptns = new Map<String,List<picklistOptions>>();	
}	
}	
@AuraEnabled	
public static List<ContentDocument> getFiles(string recordId){	
// TO avoid following exception	
// System.QueryException: Implementation restriction: ContentDocumentLink requires	
// a filter by a single Id on ContentDocumentId or LinkedEntityId using the equals operator or	
// multiple Id's using the IN operator.	
// We have to add sigle record id into set or list to make SOQL query call	
Set<Id> recordIds=new Set<Id>{recordId};	
Set<Id> documentIds = new Set<Id>();	
List<ContentDocumentLink> cdl=[SELECT id,LinkedEntityId,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN:recordIds];	
for(ContentDocumentLink cdLink:cdl){	
documentIds.add(cdLink.ContentDocumentId);	
}	
return [SELECT Id,Title,FileType,CreatedDate FROM ContentDocument WHERE id IN: documentIds];	
}	
@AuraEnabled	
public static void deleteFiles(string sdocumentId){	
delete [SELECT Id,Title,FileType from ContentDocument WHERE id=:sdocumentId];	
}
    
    @AuraEnabled	
    public static response_Wrapper doCallout(string recordId){
        return PolarisApi.restProvisionApiCall(recordId);
    }
	
/******************************************************
   * Description : This Method is going to create Entitlement Record For Free Trail If Not Found or will update End Date to 45 Days.
   * Arguements :  AccountId   
   * Return : void 	   
   * Author : Prashant
   * Ticket : PRDOPS25-1304
   * CreatedDate : 10-01-2025
   * ******************************************************/ 
    public static  Entitlement createFreeEntitlementRecord(Id AccountId){
        Entitlement freeRscEntitlement = new Entitlement();
        List<Entitlement> freeRscEntitlements = new List<Entitlement>();
        List<RSC_Process__c>  rscList = [Select Id,RSC_Status__c,Entitlement__c from RSC_Process__c where AccountID__c = : accountId];
        
        freeRscEntitlements =  [Select id,startdate,enddate from Entitlement where AccountId =: AccountId AND Type= 'Admin' AND   SubType__c = 'RSC' Limit 1];
        system.debug('freeRscEntitlements ' + freeRscEntitlements);
        if(freeRscEntitlements != null && !freeRscEntitlements.isEmpty()){
                freeRscEntitlement.Id = freeRscEntitlements[0].Id;
        }else{
            freeRscEntitlement.AccountId = AccountId;
            freeRscEntitlement.Name = 'RSC';
            freeRscEntitlement.Type = 'Admin'; 
        }
        if(rscList != null && !rscList.isEmpty() && rscList.size() > 0){
            freeRscEntitlement.RSC_Status__c = rscList[0]?.RSC_Status__c;
        }else{
            freeRscEntitlement.RSC_Status__c = 'Initiated';
        }
        
        freeRscEntitlement.startdate = system.today();
		freeRscEntitlement.Entitlement_Subtype__c = 'Free Trial';
        freeRscEntitlement.SubType__c = 'RSC';
    	freeRscEntitlement.endDate = system.today().addDays(45);

        // New Field To Be introduced
        system.debug('freeRscEntitlement before Upsert' + freeRscEntitlement);
		upsert  freeRscEntitlement;
        if(!rscList.isempty()){
            for(RSC_Process__c rscRec : rscList){
                rscRec.Entitlement__c = freeRscEntitlement.Id;   
            }
        }
        update rscList;
       
        return freeRscEntitlement;
    }
    /******************************************************
   * Description : This Method is going to create GTC Screening Record If Not Found or will initiate it.
   * Arguements :  Account   
   * Return : void 	   
   * Author : Prashant
   * Ticket : PRDOPS25-1304
   * CreatedDate : 10-01-2025
   * ******************************************************/ 
    public static  void startGtcSreening(Account accountObject){
        List<Account_Screening__c> getScrreningRecordBasedOnAccountId = [select id,GTC_Screen_Status_Message__c from Account_Screening__c where account__c = :accountObject.Id Limit 1];
        Account_Screening__c initateScreening = new Account_Screening__c();
        if(getScrreningRecordBasedOnAccountId != null && !getScrreningRecordBasedOnAccountId.isEmpty()){
            initateScreening.Id =   getScrreningRecordBasedOnAccountId[0].Id;                                                   
        }
        initateScreening.Name = accountObject.Name;
        initateScreening.Screening_Eligibility__c =true;
        initateScreening.Screening_Action__c ='Start';
        initateScreening.Screening_Action_Status__c ='Ready';
        initateScreening.Account__c = accountObject.Id;
        initateScreening.Unique_Parent_Id__c = accountObject.Id;
        upsert initateScreening;
        accountObject.Account_Screening__c=initateScreening.id;
        update accountObject; 
    }
   /**
   * @description This method will Set Quote as Primary and Update and Create INT-02 Errorcode.
   * @param quote
   * @return string
   */   
    @AuraEnabled
    public static string updateQuoteAndCreatePoStageError(SBQQ__Quote__c  quote) {
        if (quote == null || quote.Id == null) {
            throw new AuraHandledException('Quote is null or not persisted.');
        }
        string message = '';
        List<PO_Stage_Errors__c> errorList = [Select Id,Quote_Update_Status__c,Quote_Update_Message__c from PO_Stage_Errors__c where opportunity__c!=null and Quote__c!=null and opportunity__c =: Quote.SBQQ__Opportunity2__c];
        Map<Id,SBQQ__Quote__c> setQuoteToPrimary = new Map<Id,SBQQ__Quote__c>();
        Map<Id,PO_Stage_Errors__c> errorCodeMap = new Map<Id,PO_Stage_Errors__c>();
        PO_Stage_Errors__c errorCode = new PO_Stage_Errors__c(); 
        if(errorList.isempty()){
            errorCode.Name = 'INT-02';
            errorCode.Error_Code__c = 'INT-02';
            errorCode.opportunity__c = Quote.SBQQ__Opportunity2__c;
            errorCode.quote__c = quote.Id; 
            errorCodeMap.put(quote.Id,errorCode);
           // message = 'New Error Code Created On ' + Quote.Name;
            if(!errorCodeMap.isempty() && errorCodeMap.containskey(quote.Id)){
                if(quote.SBQQ__Primary__c){
                    errorCodeMap.get(quote.id).Quote_Update_Status__c = constants.QUOTE_UPDATED_NOTREQUIRED_STATUS;//'Quote Update Not Required';
                    errorCodeMap.get(quote.id).Quote_Update_Message__c = constants.QUOTE_UPDATED_NOTREQUIRED_MESSAGE;// 'Quote is already Approved and Primary.';
                }else if(!setQuoteToPrimary.containskey(Quote.Id)){
                    setQuoteToPrimary.put(quote.Id,new SBQQ__Quote__c(Id = quote.Id,SBQQ__Primary__c = true));    
                }
                if(!setQuoteToPrimary.isempty()){
                    POStageErrorsTriggerHandler.erroMessagesOnUpdateOfQuoteToPrimary(setQuoteToPrimary.values(),errorCodeMap);
                }
                message  += 'New Error Code Created On ' + quote.Name +  ' With Message After Trying Quote as Primary ' + errorCodeMap.get(Quote.Id).Quote_Update_Message__c; 
            }
        }else{
            message = 'Request has Already been Processed On Opportunity: ' +quote.SBQQ__Opportunity2__r.Name;
        }
     
        if(!errorCodeMap.isempty()){
            insert errorCodeMap.values();
        }
        return message;
    } 
	
    @AuraEnabled
    public static List<AssetDetailWrapper> fetchAssetsWithOrderLines(){
        List<AssetDetailWrapper> wrapperList = new List<AssetDetailWrapper>();
        List<String> asstNames = new List<String>();
        Map<Id,Orderitem> orderItemMap = new Map<Id,Orderitem>([Select Id,order.OrderNumber,OrderItemNumber,order.Account.Name,order.Actual_Order_Ship_Date__c,Trade_Up_SerialNumber__c,product2.name,SBQQ__QuoteLine__r.SBQQ__Quote__r.Name from OrderItem where order.Order_Status__c ='Shipped' order by createddate DESC limit 5000]);
        Set<String> tradeSetialNumber = new Set<String>();
        Map<Id,List<String>> orderItemWithAssets= new Map<Id,List<String>>();
        Map<String,Asset> getAllAssets = new Map<String,Asset>();
        for(OrderItem ordItem : orderItemMap.values()){
            List<String> tradeToSplitList = new List<String>();
            if(ordItem.Trade_Up_SerialNumber__c!=null){
                if(ordItem.Trade_Up_SerialNumber__c.contains(',')){
                    String tradeToSplit = ordItem.Trade_Up_SerialNumber__c;
                    tradeToSplitList = tradeToSplit.deleteWhitespace().split(',');
                }else{
		    tradeToSplitList.add(ordItem.Trade_Up_SerialNumber__c);
                }
            orderItemWithAssets.put(ordItem.Id,tradeToSplitList);
            asstNames.addAll(tradeToSplitList);
            }
        }
        for(Asset asst : [Select Id,name,purchasedate,Free_HW_Refresh_Forfeited__c from Asset where Name IN : asstNames]){
            getAllAssets.put(asst.name,asst);
        }
        
        for(Id oi : orderItemWithAssets.keyset()){
            // 
            
            OrderItem oiRecord = orderItemMap.get(oi);
            AssetDetailWrapper asstWrapp = new AssetDetailWrapper();
            asstWrapp.orderItemId = oi;
            asstWrapp.ordernumber = oiRecord.Order.ordernumber;
	    asstWrapp.AccountName = oiRecord.order.Account.Name;
            asstWrapp.ProductName = oiRecord.product2.name;
            asstWrapp.QuoteNumber = oiRecord.SBQQ__QuoteLine__r.SBQQ__Quote__r.Name;
            asstWrapp.PurchaseDate = oiRecord.order.Actual_Order_Ship_Date__c;
            asstWrapp.OInumber = oiRecord.OrderItemNumber;
            String assetNames = '';
            String  purchaseDates = '';
            if(orderItemWithAssets.containskey(oi)){
                for(String asstName : orderItemWithAssets.get(oi)){
                    if(!getAllAssets.containskey(asstName) || getAllAssets.get(asstName).Free_HW_Refresh_Forfeited__c == false){
                        assetNames += asstName + ',';
                        //purchaseDates += getAllAssets.get(asstName).purchasedate + ',';
                    }
                }
            }
            if(assetNames!=null && !String.isBlank(assetNames)){
                asstWrapp.AssetName = assetNames;
                wrapperList.add(asstWrapp);
            }
            
        }
        
        return wrapperList;
    }
    
    public class AssetDetailWrapper{
        @auraEnabled public Id orderItemId{get; set;}
        @auraEnabled public String AccountName{get; set;}
	@auraEnabled public String OrderNumber{get; set;}
    	@auraEnabled public String AssetName{get; set;}
        @auraEnabled public Date PurchaseDate{get; set;}
        @auraEnabled public String ProductName{get; set;}
        @auraEnabled public String TradeSerialNumber{get; set;}
        @auraEnabled public String QuoteNumber{get; set;}
        @auraEnabled public String OInumber{get; set;}
        public void AssetDetailWrapper(Id orderItemId,String AccountName,String AssetName,Date PurchaseDate,String ProductName,String TradeSerialNumber,String QuoteNumber, string OInumber,string ordernumber){
            orderItemId = orderItemId;
            AccountName = AccountName;
            AssetName = AssetName;
            PurchaseDate = PurchaseDate;
            ProductName = ProductName; 
            TradeSerialNumber = TradeSerialNumber;
            QuoteNumber = QuoteNumber;
            OInumber = OInumber;
	    ordernumber = ordernumber;
		
        }
    }
	
    
   /******************* CPQ22- 4922 starts **********************************************/ 
   @AuraEnabled
   public static Id getQuoteInsert(Id oppId, Id oppOwnerId, Id oppInitialConName, Id oppAccountId, Id oppPartnerLookup,
                                                         Id oppDistributorLookup , String priceBookId, String PriceBook, String accBillingCountry, String accName, String accBillingStreet,
                                                         string accBillingCity, String accBillingState, String accBillingPostalCode, String accShippingPostalCode, String accShippingCountry,
                                                         String accShippingStreet, String accShippingState, String accShippingCity, String oppOpportunitySubType, String oppInstallationAss,
                                                         Boolean oppacRef, Boolean accRefreshIndicator){
               try{
                   SBQQ__Quote__c sq = new SBQQ__Quote__c();
                   sq.SBQQ__Opportunity2__c =  oppId;
                   sq.SBQQ__SalesRep__c = oppOwnerId;
                   sq.SBQQ__PrimaryContact__c = oppInitialConName;
                   sq.SBQQ__Account__c = oppAccountId;
                   sq.ShowNFROnePager__c  = (oppOpportunitySubType == 'MSP' ? true: false);
                   sq.SBQQ__Partner__c =    oppPartnerLookup;
                   sq.SBQQ__Distributor__c =  oppDistributorLookup;
                   sq.SBQQ__PricebookId__c = priceBookId ;
                   sq.SBQQ__PriceBook__c = PriceBook;
                   sq.SBQQ__BillingCountry__c = accBillingCountry;
                   sq.SBQQ__BillingName__c = accName;
                   sq.SBQQ__BillingStreet__c = accBillingStreet;
                   sq.SBQQ__BillingCity__c = accBillingCity;
                   sq.SBQQ__BillingState__c = accBillingState;
                   sq.SBQQ__BillingPostalCode__c = accBillingPostalCode;
                   sq.SBQQ__ShippingPostalCode__c = accShippingPostalCode;
                   sq.SBQQ__ShippingCountry__c = accShippingCountry;
                   sq.SBQQ__ShippingStreet__c = accShippingStreet;
                   sq.SBQQ__ShippingState__c =  accShippingState;
                   sq.SBQQ__ShippingCity__c =   accShippingCity;
                   sq.OpportunitySubType__c = oppOpportunitySubType;
                   sq.Installation_Assigned_To__c = oppInstallationAss;
                   sq.Is_Refreshed__c =  oppacRef;
                   sq.Is_Refreshed_Identifier__c = accRefreshIndicator;
                   insert sq;
                   system.debug('sq.id is :'+sq.Id);
                   return sq.Id;                                             
               }
            catch(Exception e){
                system.debug('inside Aura except getQuoteInsert ' + e.getMessage());
                   throw new AuraHandledException('Error while inserting Quote '+e.getMessage());
            }
                       
       }
   /******************* CPQ22- 4922 ends **********************************************/ 
    
}