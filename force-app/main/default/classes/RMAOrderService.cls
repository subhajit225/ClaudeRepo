public class RMAOrderService {
    public static Set<ID> ordersIDset = new Set<ID>(); 
    public static Set<ID> OrderIDsToSendEmail= new set<ID>();
    public static List<string> EmailAddress =New List<String>();
    public static Map<String, List<String>> MapOrderIDEmailAddress = new Map<String, List<String>>(); 
    public static Map<String, string> MapOrderIdAndRequestor= new Map<String, String>(); 
    public static Map<ID, Order> MapOrderIdAndOrderRec= new Map<ID, Order>();
    public static Map<String, EmailTemplate> MapTempNameAndTempRec= new Map<String, EmailTemplate>();
    public static EmailTemplate temp = new EmailTemplate ();
    Public static string EmailType ='';
    Public static string flashMessage='';
    public static Boolean isResendEmail = false;
    Public static map<string,UpdateShippingCarrierServiceLevel__c>serviceLevelMap = new map<string,UpdateShippingCarrierServiceLevel__c>();
    public static Map<String, CountryWithCode__c> mapStatusCounrtyCodeCustomSetting = new map<String, CountryWithCode__c>();
    
    static{
        mapStatusCounrtyCodeCustomSetting = CountryWithCode__c.getAll();
        //Populate shippingCarrier , serviceLevel and SCAC Code based on RMA Order
         for(UpdateShippingCarrierServiceLevel__c shippingcarrier: [select id,OrderServiceLevel__c,SCAC__c,
                                                                    OrderShippingCarrier__c,RMAServiceType__c,Shipping_Country__c from UpdateShippingCarrierServiceLevel__c]){
            serviceLevelMap.put(shippingcarrier.RMAServiceType__c+':'+shippingcarrier.Shipping_Country__c,shippingcarrier);
         }
    }
    
    public static void createOrder(List<RMA_Order__c> RMAList){
         ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
         EmailType='FLASH_EMAIL';
         set<Id> rmaIdsFlash = new set<Id>();
        
         for(RMA_Order__c rma : RMAList){
             rmaIdsFlash.add(rma.id);
              if(!disableFuncCS.Disable_old_RMA_Trigger__c)
                createOrderWithOrderItems(rma.id);  // oldtrigger code is replaced with createRMAOrderWithOrderItems
        }
         if(!rmaIdsFlash.isEmpty() && disableFuncCS.Disable_old_RMA_Trigger__c){ // new optimized code
              createRMAOrderWithOrderItems(rmaIdsFlash);   
         }
         if(!ordersIDset.isEmpty()){
         sendingEmail(temp,rmaIdsFlash,EmailType);
         }
         
     }
     //Logic updated for PRDOPS21_278
     public static void sendEmailtoFlash(Set<ID> orderIdToProcess){
         Set<string> EmailIDs = new Set<String>();
         List<String> creatorsAddress=new List<String>();
         Set<ID> orderRmaIDs = New set<ID>();
         List<EmailTemplate> etList= [Select id,Name, Subject, Body from EmailTemplate where name ='Order-Flash Integration Template VF'or name ='Order-TSP Integration Template VF' limit 2];
         for(EmailTemplate et : etList){
             MapTempNameAndTempRec.put(et.Name, et);
         }
         temp = MapTempNameAndTempRec.get('Order-Flash Integration Template VF');
         
         for(Order ord:[Select Id,Resend_Smart_Hands_Email_to_Flash__c,Order_Sub_Type__c,Smart_Hands_Provider__c, RMA_Request__r.Additional_Interested_Parties_RMA__c,RMA_Request__r.CreatedBy.Email from Order where Id IN:orderIdToProcess]){
             if(ord.RMA_Request__r.Additional_Interested_Parties_RMA__c != Null){
                 if(ord.RMA_Request__r.Additional_Interested_Parties_RMA__c.contains(',')){
                     EmailAddress = ord.RMA_Request__r.Additional_Interested_Parties_RMA__c.split(',');
                 }
                 else{
                     EmailAddress.add(ord.RMA_Request__r.Additional_Interested_Parties_RMA__c);
                 }
            }
             MapOrderIDEmailAddress.put(ord.id,EmailAddress);
             MapOrderIdAndRequestor.put(ord.id,ord.RMA_Request__r.CreatedBy.Email);
             MapOrderIdAndOrderRec.put(ord.id,ord);
         }
     }
     public static void sendingEmail(EmailTemplate et,set<ID> rmaData,string Type){
         try{
             System.debug('************'+ et.Name);
              List<RMA_Order__c> rmaUpdateList = new List<RMA_Order__c>();
             Set<Id> updateFlashMessage = new Set<Id>();
             List<Messaging.SingleEmailMessage> allEmails = new List<Messaging.SingleEmailMessage>();
             List<String> ccAddresses = new List<String>();
             String[] toAddresses = new List<String>();
             Map<string,Email_Preferences__mdt > mapNameEmailpref = new Map<string,Email_Preferences__mdt >();
             List<RMA_Event__e> rmaEvents = new List<RMA_Event__e>();
             User u = [Select Id from User where IsActive = true and Id=:UserInfo.getUserId() LIMIT 1];
             //Email_Preferences__mdt mdt = [Select Id, Receipient__c,from__c, cc__c, Email_Subject__c from Email_Preferences__mdt where MasterLabel = 'SendFlashEmail' LIMIT 1];
             List<Email_Preferences__mdt> mdt = [SELECT Id, Receipient__c, From__c, CC__c, Email_Subject__c,MasterLabel FROM Email_Preferences__mdt WHERE MasterLabel = 'SendTSPEmail'  or MasterLabel = 'SendFlashEmail'];
             for(Email_Preferences__mdt mdtRec : mdt){
                 mapNameEmailpref.put(mdtRec.MasterLabel, mdtRec );
             }
             OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address =: mapNameEmailpref.get('SendFlashEmail').From__c];
            /* if(mdt.cc__c != null){
                 for(String address: mdt.cc__c.split(',')){
                     ccAddresses.add(address.trim());
                 }
             }*/
             Id tempId2 = et.Id;
             for(Id od : MapOrderIDEmailAddress.keyset()){
                 tempId2 = et.Id;
                 ccAddresses = new List<String>();
                 if(MapOrderIdAndOrderRec.get(od).Smart_Hands_Provider__c == 'TSP Inc.'){
                    if(mapNameEmailpref.get('SendTSPEmail').cc__c != null){
                        for(String address: mapNameEmailpref.get('SendTSPEmail').cc__c.split(',')){
                            ccAddresses.add(address.trim());
                        }
                    }
                    if(mapNameEmailpref.get('SendTSPEmail').Receipient__c != null){
                        toAddresses.add(mapNameEmailpref.get('SendTSPEmail').Receipient__c);
                    }
                 }else{

                 if(mapNameEmailpref.get('SendFlashEmail').cc__c != null){
                     for(String address: mapNameEmailpref.get('SendFlashEmail').cc__c.split(',')){
                         ccAddresses.add(address.trim());
                     }
                 }
                 if(MapOrderIDEmailAddress.get(od).size() > 0){
                     toAddresses.addall(MapOrderIDEmailAddress.get(od));
                 }
                 toAddresses.add(MapOrderIdAndRequestor.get(od));
                }
                 if(MapOrderIdAndOrderRec.get(od).Smart_Hands_Provider__c == 'TSP Inc.' && (et.Name=='Order-Flash Integration Template VF - Updated' || et.Name=='Order-TSP Integration Template VF') ){
                     system.debug('');
                     tempId2 = MapTempNameAndTempRec.get('Order-TSP Integration Template VF').Id;
                    
                 }else if(MapOrderIdAndOrderRec.get(od).Smart_Hands_Provider__c == 'TSP Inc.'  && et.Name=='Order-Flash Integration Template VF'){
                    // tempId2 = MapTempNameAndTempRec.get('VF_Send_TSP_Email').Id;
                    if(isResendEmail){
                        tempId2 = MapTempNameAndTempRec.get('Order-TSP Integration Template VF').Id; 
                    }else{
                    continue;
                    }
                 }
                 Messaging.SingleEmailMessage emails = Messaging.renderStoredEmailTemplate(tempId2,u.id,od);
                 emails.setTargetObjectId(u.id);
                 emails.setToAddresses(toAddresses);
                 emails.setCcAddresses(ccAddresses);
                 emails.setTemplateId(tempId2);
                 emails.setSaveAsActivity(false);
                 if (owea.size() > 0 ) {
                     emails.setOrgWideEmailAddressId(owea.get(0).Id);
                 }
                 allEmails.add(emails);
             }
              Messaging.SendEmailResult[] results = Messaging.sendEmail(allEmails);
             //Record error in debug log
                 for(Messaging.SendEmailResult eachResult : results) {
                     if(!eachResult.isSuccess()) {
                         for(Messaging.SendEmailError eachError : eachResult.getErrors()) {
                             System.debug('The following error has occurred for the record : ' + eachError.getTargetObjectId());
                             System.debug(eachError.getStatusCode() + ': ' + eachError.getMessage());
                             System.debug('Fields that affected this error: ' + eachError.getFields());
                         }
                     }
                 }
             for(RMA_Order__c rmaOrderData : [SELECT Id,Flash_Email_History__c from RMA_Order__c where  Id IN:rmaData]){
                 if(Type=='FLASH_EMAIL'){
                     if(rmaOrderData.Flash_Email_History__c == null){
                         flashMessage +='Email is sent at '+Datetime.now().format();
                     }
                     else{
                         flashMessage +=rmaOrderData.Flash_Email_History__c + '\n' +'Email is sent at '+Datetime.now().format();
                     }
                 }
                 if(Type=='SMART_HANDS_ADDED'){
                     flashMessage +=rmaOrderData.Flash_Email_History__c + '\n' +'Email for Smart Hands Updated is sent at '+Datetime.now().format();
                 }
                 if(Type=='SMART_HANDS_REMOVED'){
                     flashMessage +=rmaOrderData.Flash_Email_History__c+ '\n'+'Email for Smart Hands Removed is sent at '+Datetime.now().format();
                 }
                 if(Type=='RESEND_FLASH'){
                     flashMessage +=rmaOrderData.Flash_Email_History__c+ '\n' +'Email is Resent at '+Datetime.now().format();
                 }
                 //PRODOPS23-19
                 if(flashMessage != null && flashMessage.contains('DATETIME_CHANGE_REQUESTED')){
                    flashMessage = flashMessage.replace('DATETIME_CHANGE_REQUESTED', 'EMAIL_TRIGGERED');
                }
                    rmaUpdateList.add(new RMA_Order__c (Id = rmaOrderData.Id, Flash_Email_History__c = flashMessage));  
                   rmaEvents.add(new RMA_Event__e(RMA_Id__c = rmaOrderData.Id, Flash_Message__c = flashMessage));
             }
              /*if(rmaEvents.size()>0){
                 EventBus.publish(rmaEvents);
              } */
              if(!rmaUpdateList.isEmpty()){
                  flowControll.RMATriggerHandler = false;
                  update rmaUpdateList;
             }
         } 
         catch(System.EmailException emlEx) {
             string EmailFailure ;
             EmailFailure = 'Email Failed: ' + emlEx;
         }     
     }
 
    /* oldtrigger code is replaced with createRMAOrderWithOrderItems */
     public static void createOrderWithOrderItems(Id rmaId) {
      system.debug('In Method --createOrderWithOrderItems');
         try{
             
             Order neworder = new Order();
             RMA_Order__c RMAOrder = [select Parent_Case__c,Parent_Case__r.AccountID, Ship_To_Phone_Number__c,Ship_To_Contact_Name__c,Ship_To_Name__c,Ship_To_Name__r.Name,Ship_To_Email__c, Parent_Case__r.Account.Distributor__c,Parent_Case__r.Account.Distributor__r.Payment_Term__c,
                                      Memory__c, Power_Supply__c, Status__c, Node__c, Drive__c,SSD__C, NIC__c,Chassis__c,Service_Type__c, Shipping_Street__c, Shipping_City__c, ShippingState__c, Shipping_Zip_Postal_Code__c,
                                      ShippingCountry__c, Node_Quantity__c, Drive_Quantity__c, Chasis_Quantity__c,Memory_Quantity__c, Power_Supply_Quantity__c, NIC_Quantity__c, Appliance_Quantity__c, Cluster_ID__c, Appliance__c, CMOS_Battery__c, CMOS_Battery_Quantity__c,
                                      Parent_Case__r.Account.Distributor__r.Shipping_Carrier__c , Parent_Case__r.Account.Distributor__r.Shipping_Method__c , Parent_Case__r.Account.Distributor__r.Shipping_Account_Number__c,Parent_Case__r.Account.Distributor__r.IncoTerms__c,
                                      Vendor_Message__c, Send_Smart_Hands_Service__c, Date_of_Smart_Hands_Arrival__c, Time_of_Smart_Hands_Tech_Arrival__c, Customer_Ref_number__c /* @Author: Sukesh K @Description: for DGWD-128, DGWD-17, DGWD-152 */
                                      from RMA_Order__C where Id =:rmaId];
 
             neworder.status='Pending';
             neworder.AccountId=RMAOrder.Parent_Case__r.AccountID;
            neworder.Vendor_Message__c = RMAOrder.Vendor_Message__c;    /* @Author: Sukesh K @Description: for DGWD-128 */
            neworder.Customer_Ref_number__c = RMAOrder.Customer_Ref_number__c;    /* @Author: Sukesh K @Description: for DGWD-152 */
             //neworder.OpportunityId=opp.Id;
             neworder.EffectiveDate=system.Today();
             if(rmaOrder.Parent_Case__r.Account.Distributor__r.Payment_Term__c != null )
                 neworder.Payment_Terms__c = rmaOrder.Parent_Case__r.Account.Distributor__r.Payment_Term__c;
 
             if(rmaOrder.Parent_Case__r.Account.Distributor__c != null )
                 neworder.Bill_To_Name__c = rmaOrder.Parent_Case__r.Account.Distributor__r.Payment_Term__c;
 
             if(rmaOrder.Parent_Case__r.Account.Distributor__r.Shipping_Carrier__c != null )
                 neworder.Shipping_Carrier__c = rmaOrder.Parent_Case__r.Account.Distributor__r.Shipping_Carrier__c;
 
             if(rmaOrder.Parent_Case__r.Account.Distributor__r.Shipping_Account_Number__c != null )
                 neworder.Shipping_Account_Number__c = rmaOrder.Parent_Case__r.Account.Distributor__r.Shipping_Account_Number__c;
 
             if(rmaOrder.Parent_Case__r.Account.Distributor__r.IncoTerms__c != null )
                 neworder.IncoTerms__c = rmaOrder.Parent_Case__r.Account.Distributor__r.IncoTerms__c;
 
             Map<String, StateCodeName__C> mapStatusStateCodeCustomSetting = StateCodeName__C.getAll();
              string uniqueCode='';
             if(mapStatusCounrtyCodeCustomSetting.containsKey(rmaOrder.ShippingCountry__C))
                 uniqueCode = mapStatusCounrtyCodeCustomSetting.get(rmaOrder.ShippingCountry__C).code__C+'-'+rmaOrder.ShippingState__c;
             System.debug('unique Code'+uniquecode);
             newOrder.Shippingcountry=rmaOrder.ShippingCountry__C;
             newOrder.ShippingcountryCode=mapStatusCounrtyCodeCustomSetting.get(rmaOrder.ShippingCountry__C).code__C;
             newOrder.Shippingcity=rmaOrder.Shipping_City__c;
             newOrder.Shippingstreet=rmaOrder.Shipping_street__C;
             newOrder.ShippingstateCode= !uniquecode.contains('-null')?uniquecode.substring(3,5):null;//mapStatusStateCodeCustomSetting.get(uniqueCode).State_Name__c; //rmaOrder.ShippingState__c;
             newOrder.ShippingPostalCode=rmaOrder.Shipping_Zip_Postal_Code__c;
             newOrder.Service_Type__c=rmaOrder.Service_Type__c;
             newOrder.Ship_To_Name__c =rmaOrder.Ship_To_Name__r.Name;
             newOrder.Bill_To_Name__c =rmaOrder.Ship_To_Name__c;
             newOrder.ShipToContactName__c=rmaOrder.Ship_To_Contact_Name__c;
             newOrder.Ship_To_Email__c=rmaOrder.Ship_To_Email__c;
             newOrder.Ship_To_Phone_Number__c =rmaOrder.Ship_To_Phone_Number__c;
            //newOrder.Shipping_Carrier__c = Label.RMA_Shipping_Carrier;
            //Added by Ikyatha  @DGWD-160
            string shippingcountry = rmaOrder.ShippingCountry__C.toUppercase();
            
            if(serviceLevelMap.containskey(rmaOrder.Service_Type__c+':'+shippingcountry)){
            newOrder.Shipping_Carrier__c = serviceLevelMap.get(rmaOrder.Service_Type__c+':'+shippingcountry).OrderShippingCarrier__c;

            newOrder.Service_Level__c = serviceLevelMap.get(rmaOrder.Service_Type__c+':'+shippingcountry).OrderServiceLevel__c;
            neworder.scac__c=serviceLevelMap.get(rmaOrder.Service_Type__c+':'+shippingcountry).scac__c;
            }
             newOrder.Shipping_Method__c = Label.RMA_Shipping_Terms;
             newOrder.Service_Type__c = rmaOrder.Service_Type__c;
 
             neworder.Pricebook2Id = system.label.RMA_PriceBookID;
             newOrder.Type ='RMA';
             Id OrderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('RMA Order').getRecordTypeId();
             if(OrderRecordTypeId != null)
             newOrder.RecordTypeId= OrderRecordTypeId;
 
             newOrder.RMA_Request__C= RMAOrder.id;
             newOrder.PO_Number__c = 'n/a';
            /*
                @Author: Sukesh K
                @Description: for DGWD-17
                Created techOrder
                Created techOrderLineItems for techOrder
                Added Order_Sub_Type__c
                    neworder: 'Part Order'
                    techOrder: 'Tech Order'
            */
            neworder.Order_Sub_Type__c = 'Part Order';
            insert newOrder;

            Order techOrder;
            Boolean shouldCreateTechOrder = RMAOrder.Send_Smart_Hands_Service__c;
            if (shouldCreateTechOrder) {
                techOrder = createTechOrderByCloning(newOrder, RMAOrder.Date_of_Smart_Hands_Arrival__c, RMAOrder.Time_of_Smart_Hands_Tech_Arrival__c);
                Order o = [SELECT OrderNumber FROM Order WHERE Id = :newOrder.Id LIMIT 1];
                techOrder.Linked_RMA_Part_order__c = o.OrderNumber;
                  
                     if(serviceLevelMap.containskey('DefaultShippingInfo:Default')){
                         techorder.Shipping_Carrier__c = serviceLevelMap.get('DefaultShippingInfo:Default').OrderShippingCarrier__c;
                         techorder.Service_Level__c =  serviceLevelMap.get('DefaultShippingInfo:Default').OrderServiceLevel__c;
                         techorder.scac__c =  serviceLevelMap.get('DefaultShippingInfo:Default').scac__c;
                    }
                insert techOrder;
            }
             List<OrderItem> orderLineItemsList = new List<OrderItem>();
 
             Map<Id,Id> pricbookEntryMap = new Map<Id,Id>();
             Map<Id,Decimal> pricbookEntryPriceMap = new Map<Id,Decimal>();/*isActive = true and */
                for(PricebookEntry pbe : [select id, UnitPrice,product2ID from PricebookEntry where  PriceBook2ID =:System.label.RMA_PriceBookID]){
                    pricbookEntryMap.put(pbe.product2ID,pbe.Id);
                    pricbookEntryPriceMap.put(pbe.id,pbe.UnitPrice);
                }
                system.debug('pricbookEntryMap=='+pricbookEntryMap+'==size'+pricbookEntryMap.size());
                system.debug('pricbookEntryPriceMap=='+pricbookEntryPriceMap+'==size'+pricbookEntryPriceMap.size());
            if (shouldCreateTechOrder) {

                Id techOrderProductId = System.label.Product_Id_Tech_Order;
                If (Test.isRunningTest()) {
                    techOrderProductId = [SELECT Id FROM  Product2 WHERE Name = 'X-SVC-TECH' LIMIT 1 ].Id;
                }
                Id techOliPricebookEntryId = pricbookEntryMap.get(techOrderProductId);
                orderLineItemsList.add(
                    createTechOrderLineItem(techOrder.Id, techOliPricebookEntryId,pricbookEntryPriceMap.get(techOliPricebookEntryId)
                ));
            }
             List<String> assetList = new List<String>();
             List<String> driveList = new List<String>();
             List<String> memoryList = new List<String>();
             List<String> nicList = new List<String>();
             List<String> psuList = new List<String>();
             List<String> chassisList = new List<String>();
             List<String> nodeList = new List<String>();
             List<String> cmosList = new List<String>();
             List<String> nodeListForMemory = new List<String>();
             List<String> nodeListForDrive = new List<String>();
             List<String> AssetListForPSU = new List<String>();
             List<String> AssetListForChassis = new List<String>();
             if(!String.isBlank(RMAOrder.Appliance__c) && RMAOrder.Appliance_Quantity__c != null){
                 if(RMAOrder.Appliance__c.contains(',')){
                 assetList = RMAOrder.Appliance__c.split(',');
                 }
                 else{
                     assetList.add(RMAOrder.Appliance__c);
                 }
             system.debug('assetList=='+assetList);
                 for(Asset asset : [select id,serial_Number__C,Product2ID from Asset where serial_Number__c IN:assetList ]) {
                     OrderItem oli = new OrderItem();
                     oli.Assets__c = asset.serial_Number__C;
                     oli.orderId = neworder.Id;
                     system.debug('pricbookEntryMap.get(asset.Product2ID)'+pricbookEntryMap.get(asset.Product2ID));
                     oli.PriceBookEntryId = pricbookEntryMap.get(asset.Product2ID);
                     system.debug('pricbookEntryMap.get(oli.PriceBookEntryId)'+pricbookEntryMap.get(oli.PriceBookEntryId));
                     oli.UnitPrice = pricbookEntryPriceMap.get(oli.PriceBookEntryId);
                     oli.Sales_Price__c = oli.UnitPrice;
                     oli.Failed_Serial_Number__c = asset.Serial_Number__c;
                      oli.RMA_Component_Type__c = 'Appliance';
                     oli.Quantity = 1;
                     orderLineItemsList.add(oli);
                 }
 
 
             }
 
             Map<String,Id> productMap = new Map<String,Id>();
                for(Product2 prod : [select id,productcode from product2 where (productcode != null OR productcode != '')]){
                    productMap.put(prod.productcode,prod.Id);
                }
                system.debug('productMap=='+productMap+'==size'+productMap.size());
 
 
                if(!String.isBlank(RMAOrder.Drive__c) || !String.isBlank(RMAOrder.SSD__c)){
                     String driveType;
                    if(!String.isBlank(RMAOrder.Drive__c)){
                         if(RMAOrder.Drive__c=='Other'){
                             driveType='HDD';
                             if(!String.isBlank(RMAOrder.Node__c)){
                                 if(RMAOrder.Node__c.contains(',')){
                                     nodeListForDrive = RMAOrder.Node__c.split(',');
                                 }
                                 else{
                                     nodeListForDrive.add(RMAOrder.Node__c);
                                 }
                             }
                         } 
                         else{
                         if(RMAOrder.Drive__c.contains(',')){
                             driveList = RMAOrder.Drive__c.split(',');
                         }
                         else{
                             driveList.add(RMAOrder.Drive__c);
 
                         }
                     }
                    }
                 
                     if(!String.isBlank(RMAOrder.SSD__c)){
                         if(RMAOrder.SSD__c=='Other'){
                                 driveType='SSD';
                                 if(RMAOrder.Node__c.contains(',')){
                                     nodeListForDrive = RMAOrder.Node__c.split(',');
                                 }
                                 else{
                                     nodeListForDrive.add(RMAOrder.Node__c);
                                 }
                         } 
                         else{
                                 if(RMAOrder.SSD__c.contains(',')){
                                     driveList = RMAOrder.SSD__c.split(',');
                                 }
                                 else{
                                     driveList.add(RMAOrder.SSD__c);
                                 }
                         }
                     }
                     Map<ID, asset> driveParentIdAndParentAsset = new Map<ID, Asset>();
                     Map<ID, drive__c> driveAssetIdAndOriginalAsset = new Map<ID, drive__c>();
                     Set<Id> driveParentID = new Set<Id>();
                         //added for OTHER logic
                     Set<Id> driveNodeParentID = new Set<Id>();
                     Map<ID, Node__c> driveNodeAssetIdAndOriginalAssetMap = new Map<ID, Node__c>();
                     Map<ID, asset> driveNodeparentIdAndAssetMap = new Map<ID, Asset>();
                     String relatedProdFamily;
                     String  relatedNicType;
                     String  relatedApplianceModel;
                     String  relatedProdCode;
                     if(driveList.size() > 0){
                     for(Drive__C dr :[select Id,Serial_Number__c, node__r.Asset__r.Serial_Number__c,Asset__r.Serial_Number__c, node__r.Asset__r.Id,node__r.Asset__r.parentId,node__r.Asset__r.Product2.ProductCode,node__r.Asset__r.Product2.Id,node__r.Asset__r.Product2.Family,node__r.Asset__r.Product2.Product_NIC_Type__c,node__r.Asset__r.Product2.Appliance_Model__c, Type__C from Drive__c where Serial_Number__c IN: driveList]){
                         driveAssetIdAndOriginalAsset.put(dr.Id,dr);
                         if(dr.node__r.Asset__r.parentId !=NULL){
                             driveParentID.add(dr.node__r.Asset__r.parentId);
                         }
                     }
                     if(driveParentID.size() > 0){
                         for(Asset driveAsData :[select Id,Serial_Number__c,ParentId,Product2.ProductCode,Product2.Id,Product2.Family,Product2.Product_NIC_Type__c,Product2.Appliance_Model__c from Asset where Id IN: driveParentID]){
                             driveParentIdAndParentAsset.put(driveAsData.Id,driveAsData);
                         }
                     }
                     for(Drive__C dr :driveAssetIdAndOriginalAsset.values()){
                        if(dr.node__r.Asset__r.parentId != NULL && driveParentIdAndParentAsset.containsKey(dr.node__r.Asset__r.parentId)){
                             Asset DriveParentAsset = driveParentIdAndParentAsset.get(dr.node__r.Asset__r.parentId);
                             relatedProdFamily = DriveParentAsset.Product2.Family != null? DriveParentAsset.Product2.Family : '';
                             relatedProdFamily=relatedProdFamily.toUppercase();
                             relatedNicType = DriveParentAsset.Product2.Product_NIC_Type__c != null ? DriveParentAsset.Product2.Product_NIC_Type__c : '';
                             relatedApplianceModel = DriveParentAsset.Product2.Appliance_Model__c != null ?DriveParentAsset.Product2.Appliance_Model__c:'';
                             relatedProdCode = DriveParentAsset.Product2.ProductCode;
                             relatedProdCode =relatedProdCode.toUpperCase();
                        }
                        else{
                            relatedProdFamily = dr.node__r.Asset__r.Product2.Family != null? dr.node__r.Asset__r.Product2.Family : '';
                            relatedProdFamily=relatedProdFamily.toUppercase();
                            relatedNicType = dr.node__r.Asset__r.Product2.Product_NIC_Type__c != null ? dr.node__r.Asset__r.Product2.Product_NIC_Type__c : '';
                            relatedApplianceModel = dr.node__r.Asset__r.Product2.Appliance_Model__c != null ?dr.node__r.Asset__r.Product2.Appliance_Model__c:'';
                            relatedProdCode = dr.node__r.Asset__r.Product2.ProductCode;
                            relatedProdCode =relatedProdCode.toUpperCase();
                        }
                         /* <--START--> SF-91  Added Logic for new Mapping Helper method*/
                        Spares_Mapping__c mapping = RMASparePartsMappingHelper.returnSparePartCode(relatedProdFamily, relatedNicType,  relatedApplianceModel); 
 
                        if(mapping != null){
                            
 
                            ID driveprodId = dr.Type__c == 'HDD'? productMap.get(mapping.HDD__c): productMap.get(mapping.SSD__c);
                            system.debug('driveprodId'+driveprodId);
                            /* < END ---- SF-91> */
                        
                        if(driveprodId != null){
                                OrderItem oli = new OrderItem();
                                oli.Assets__c = dr.node__r.Asset__r.serial_number__c;
                             oli.orderId = neworder.Id;
                              oli.RMA_Component_Type__c = dr.Type__c;
                             if(pricbookEntryMap.containsKey(driveprodId)){
                                 system.debug('pricbookEntryMap.get(driveprodId)'+pricbookEntryMap.get(driveprodId));
                                 oli.PriceBookEntryId =  pricbookEntryMap.get(driveprodId);
                                 oli.UnitPrice = pricbookEntryPriceMap.get(oli.PriceBookEntryId);
                                 oli.Sales_Price__c = oli.UnitPrice;
                                 oli.Failed_Serial_Number__c = dr.Serial_Number__c;
                                 oli.Quantity = 1;
 
                                 orderLineItemsList.add(oli);
                             }
                             else{
                             system.debug('RMA_PriceBookID'+system.label.RMA_PriceBookID);
                                 PricebookEntry pbe = new PricebookEntry(UnitPrice=0.0,Product2Id=driveprodId,Pricebook2ID=system.label.RMA_PriceBookID, IsActive=true);
                                 insert pbe;
                                 oli.PriceBookEntryId =  pbe.ID;
                                 oli.UnitPrice = pbe.UnitPrice;
                                 oli.Sales_Price__c = pbe.UnitPrice;
                                 oli.Failed_Serial_Number__c = dr.Serial_Number__c;
                                  oli.RMA_Component_Type__c = driveType;
                                 oli.Quantity = 1;
 
                                 orderLineItemsList.add(oli);
 
                                     }
                         }
                         }
                        }
                    }
                    else{
                        if(nodeListForDrive.size() > 0){
                             for(Node__c driveNodeData :[select Id,Serial_Number__c, Asset__r.Serial_Number__c, asset__r.ParentId,Asset__r.Product2.ProductCode,Asset__r.Product2.Id,Asset__r.Product2.Family,Asset__r.Product2.Product_NIC_Type__c,Asset__r.Product2.Appliance_Model__c, cpu_model__c from Node__c where Serial_Number__c IN: nodeListForDrive]){
                                 driveNodeAssetIdAndOriginalAssetMap.put(driveNodeData.Id,driveNodeData);
                                 if(driveNodeData.Asset__r.ParentId != Null){
                                     driveNodeParentID.add(driveNodeData.Asset__r.ParentId);
                                 }
                             }
                             if(driveNodeParentID.size() > 0){
                                 for(Asset driveNodeAsData :[select Id,Serial_Number__c,ParentId,Product2.ProductCode,Product2.Id,Product2.Family,Product2.Product_NIC_Type__c,Product2.Appliance_Model__c from Asset where id IN: driveNodeParentID]){
                                     driveNodeparentIdAndAssetMap.put(driveNodeAsData.Id,driveNodeAsData);
                                 }
                             }
                             for(Node__c dr :driveNodeAssetIdAndOriginalAssetMap.values()) {
                                 if( dr.asset__r.ParentId !=Null && driveNodeparentIdAndAssetMap.containsKey(dr.asset__r.ParentId)){
                                     Asset nodeAssetinfo=driveNodeparentIdAndAssetMap.get(dr.asset__r.ParentId);
                                     relatedProdFamily=nodeAssetinfo.Product2.Family;
                                     relatedProdFamily=relatedProdFamily.toUppercase();
                                     relatedNicType = nodeAssetinfo.Product2.Product_NIC_Type__c != null ? nodeAssetinfo.Product2.Product_NIC_Type__c : '';
                                     relatedApplianceModel = nodeAssetinfo.Product2.Appliance_Model__c != null ?nodeAssetinfo.Product2.Appliance_Model__c:'';
                                     relatedProdCode =nodeAssetinfo.Product2.ProductCode;
                                     System.debug('relatedProdFamily'+relatedProdFamily);
                                     System.debug('relatedNicType '+relatedNicType );
                                     System.debug('relatedApplianceModel '+relatedApplianceModel );
                                 }
                                 else{
                                         System.debug(' entering into Memory is OTHER else part');
                                      relatedProdFamily = dr.Asset__r.Product2.Family != null? dr.Asset__r.Product2.Family : '';
                                      relatedProdFamily=relatedProdFamily.toUppercase();
                                      relatedNicType = dr.Asset__r.Product2.Product_NIC_Type__c != null ? dr.Asset__r.Product2.Product_NIC_Type__c : '';
                                      relatedApplianceModel = dr.Asset__r.Product2.Appliance_Model__c != null ?dr.Asset__r.Product2.Appliance_Model__c:'';
                                      relatedProdCode = dr.Asset__r.Product2.ProductCode;
                                      System.debug('relatedProdFamily'+relatedProdFamily);
                                      System.debug('relatedNicType '+relatedNicType );
                                        System.debug('relatedApplianceModel '+relatedApplianceModel );
                                 }
                                 Spares_Mapping__c mapping = RMASparePartsMappingHelper.returnSparePartCode(relatedProdFamily, relatedNicType,  relatedApplianceModel); 
     
                                 if(mapping != null){
                                 
     
                                     ID driveprodId = driveType == 'HDD'? productMap.get(mapping.HDD__c): productMap.get(mapping.SSD__c);
                                     system.debug('driveprodId'+driveprodId);
                                     /* < END ---- SF-91> */
                                     if(driveprodId != null){
                                     OrderItem oli = new OrderItem();
                                     oli.orderId = neworder.Id;
                                     oli.assets__c = dr.Asset__r.serial_number__c;
                                      oli.RMA_Component_Type__c = driveType;
                                     if(pricbookEntryMap.containsKey(driveprodId)){
                                    
                                     oli.PriceBookEntryId =  pricbookEntryMap.get(driveprodId);
                                     oli.UnitPrice = pricbookEntryPriceMap.get(oli.PriceBookEntryId);
                                     oli.Sales_Price__c = oli.UnitPrice;
                                     oli.Failed_Serial_Number__c = dr.Serial_Number__c;
                                     oli.Quantity = 1;
     
                                     orderLineItemsList.add(oli);
                                     }
                                     else{
                                     system.debug('RMA_PriceBookID'+system.label.RMA_PriceBookID);
                                         PricebookEntry pbe = new PricebookEntry(UnitPrice=0.0,Product2Id=driveprodId,Pricebook2ID=system.label.RMA_PriceBookID, IsActive=true);
                                         insert pbe;
                                         oli.PriceBookEntryId =  pbe.ID;
                                         oli.UnitPrice = pbe.UnitPrice;
                                         oli.Sales_Price__c = pbe.UnitPrice;
                                         oli.Failed_Serial_Number__c = dr.Serial_Number__c;
                                         oli.Quantity = 1;
     
                                         orderLineItemsList.add(oli);
     
                                     }
                                 }
                             }
                         }
                        }
                    }
                         
     
                 }
                     if(!String.isBlank(RMAOrder.Memory__c)){
                         System.debug('entering into Memory not blank');
                         Set<Id> memNodeParentID = new Set<Id>();
                         Map<ID, Node__c> memoryNodeAssetIdAndOriginalAssetMap = new Map<ID, Node__c>();
                         Map<ID, asset> memNodeparentIdAndAssetMap = new Map<ID, Asset>();
                         String relatedProdFamily;
                         String  relatedNicType;
                         String  relatedApplianceModel;
                         String  relatedProdCode;
                         System.debug('Memory__c***'+RMAOrder.Memory__c);
                         if(RMAOrder.Memory__c == 'Other'){
                        System.debug(' entering into Memory is OTHER');
                             if(!String.isBlank(RMAOrder.Node__c)){
                                 if(RMAOrder.Node__c.contains(',')){
                                     nodeListForMemory = RMAOrder.Node__c.split(',');
                                 }
                                 else{
                                     nodeListForMemory.add(RMAOrder.Node__c);
                                 }
                             }
                             System.debug('nodeListForMemory***'+nodeListForMemory);
                             for(Node__c memNodeData :[select Id,Serial_Number__c, Asset__r.Serial_Number__c, asset__r.ParentId,Asset__r.Product2.ProductCode,Asset__r.Product2.Id,Asset__r.Product2.Family,Asset__r.Product2.Product_NIC_Type__c,Asset__r.Product2.Appliance_Model__c, cpu_model__c from Node__c where Serial_Number__c IN: nodeListForMemory]){
                                 memoryNodeAssetIdAndOriginalAssetMap.put(memNodeData.Id,memNodeData);
                                 if(memNodeData.Asset__r.ParentId != Null){
                                     memNodeParentID.add(memNodeData.Asset__r.ParentId);
                                 }
     
                             }
                             if(memNodeParentID.size() > 0){
                                 for(Asset MemNodeAsData :[select Id,Serial_Number__c,ParentId,Product2.ProductCode,Product2.Id,Product2.Family,Product2.Product_NIC_Type__c,Product2.Appliance_Model__c from Asset where id IN: memNodeParentID]){
                                     memNodeparentIdAndAssetMap.put(MemNodeAsData.Id,MemNodeAsData);
                                 }
                             }
                             for(Node__c dr :memoryNodeAssetIdAndOriginalAssetMap.values()) {
                                 if( dr.asset__r.ParentId !=Null && memNodeparentIdAndAssetMap.containsKey(dr.asset__r.ParentId)){
                                     Asset nodeAssetinfo=memNodeparentIdAndAssetMap.get(dr.asset__r.ParentId);
                                     relatedProdFamily=nodeAssetinfo.Product2.Family;
                                     relatedProdFamily=relatedProdFamily.toUppercase();
                                     relatedNicType = nodeAssetinfo.Product2.Product_NIC_Type__c != null ? nodeAssetinfo.Product2.Product_NIC_Type__c : '';
                                     relatedApplianceModel = nodeAssetinfo.Product2.Appliance_Model__c != null ?nodeAssetinfo.Product2.Appliance_Model__c:'';
                                     relatedProdCode =nodeAssetinfo.Product2.ProductCode;
                                     System.debug('relatedProdFamily'+relatedProdFamily);
                                     System.debug('relatedNicType '+relatedNicType );
                                     System.debug('relatedApplianceModel '+relatedApplianceModel );
                                 }
                                 else{
                                         System.debug(' entering into Memory is OTHER else part');
                                      relatedProdFamily = dr.Asset__r.Product2.Family != null? dr.Asset__r.Product2.Family : '';
                                      relatedProdFamily=relatedProdFamily.toUppercase();
                                      relatedNicType = dr.Asset__r.Product2.Product_NIC_Type__c != null ? dr.Asset__r.Product2.Product_NIC_Type__c : '';
                                      relatedApplianceModel = dr.Asset__r.Product2.Appliance_Model__c != null ?dr.Asset__r.Product2.Appliance_Model__c:'';
                                      relatedProdCode = dr.Asset__r.Product2.ProductCode;
                                      System.debug('relatedProdFamily'+relatedProdFamily);
                                      System.debug('relatedNicType '+relatedNicType );
                                        System.debug('relatedApplianceModel '+relatedApplianceModel );
                                 }
                                 Spares_Mapping__c mapping = RMASparePartsMappingHelper.returnSparePartCode(relatedProdFamily, relatedNicType,  relatedApplianceModel); 
     
                                 if(mapping != null){
                                 
     
                                     ID memprodId = productMap.get(mapping.Memory__c);
                                     system.debug('memprodId'+memprodId);
                                     /* < END ---- SF-91> */
                                     if(memprodId != null){
                                     OrderItem oli = new OrderItem();
                                     oli.assets__c = dr.Asset__r.serial_number__c;
                                     oli.orderId = neworder.Id;
                                      oli.RMA_Component_Type__c = 'Memory';
                                     if(pricbookEntryMap.containsKey(memprodId)){
                                     system.debug('pricbookEntryMap.get(memprodId)'+pricbookEntryMap.get(memprodId));
                                     oli.PriceBookEntryId =  pricbookEntryMap.get(memprodId);
                                     oli.UnitPrice = pricbookEntryPriceMap.get(oli.PriceBookEntryId);
                                     oli.Sales_Price__c = oli.UnitPrice;
                                     oli.Failed_Serial_Number__c = dr.Serial_Number__c;
                                     oli.Quantity = 1;
     
                                     orderLineItemsList.add(oli);
                                     }
                                     else{
                                     system.debug('RMA_PriceBookID'+system.label.RMA_PriceBookID);
                                         PricebookEntry pbe = new PricebookEntry(UnitPrice=0.0,Product2Id=memprodId,Pricebook2ID=system.label.RMA_PriceBookID, IsActive=true);
                                         insert pbe;
                                         oli.PriceBookEntryId =  pbe.ID;
                                         oli.UnitPrice = pbe.UnitPrice;
                                         oli.Sales_Price__c = pbe.UnitPrice;
                                         oli.Failed_Serial_Number__c = dr.Serial_Number__c;
                                         oli.Quantity = 1;
     
                                         orderLineItemsList.add(oli);
     
                                     }
                                 }
                             }
                         }
                         }
                         else{
                             if(RMAOrder.Memory__c.contains(',')){
                                     memoryList = RMAOrder.Memory__c.split(',');
                             }
                             else{
                                 memoryList.add(RMAOrder.Memory__c);
                             }
                         
                             Map<ID, asset> memoryParentIdAndAssetMap = new Map<ID, Asset>();
                             Map<ID, Memory__c> memoryAssetIdAndOriginalAssetMap = new Map<ID, Memory__c>();
                             Set<Id> memoryParentID = new Set<Id>();
                        
                             for(Memory__c dr :[select Id,Serial_Number__c, node__r.Asset__r.Serial_Number__c, node__r.Asset__r.Id,node__r.Asset__r.parentId,node__r.Asset__r.Product2.ProductCode,node__r.Asset__r.Product2.Id,node__r.Asset__r.Product2.Family ,node__r.Asset__r.Product2.Product_NIC_Type__c,node__r.Asset__r.Product2.Appliance_Model__c from Memory__c where Serial_Number__c IN: memoryList]){
                                 memoryAssetIdAndOriginalAssetMap.put(dr.Id,dr);
                                 if(dr.node__r.Asset__r.parentId != NULL  ){
                                     memoryParentID.add(dr.node__r.Asset__r.parentId);
                                 }
                             }
                             if(memoryParentID.size() > 0 ){
                                 for(Asset parentAsData :[select Id,Serial_Number__c,ParentId,Product2.ProductCode,Product2.Id,Product2.Family,Product2.Product_NIC_Type__c,Product2.Appliance_Model__c from Asset where Id IN: memoryParentID]){
                                     memoryParentIdAndAssetMap.put(parentAsData.Id,parentAsData);
                                 }
                             }
                         
                             for(Memory__c dr :memoryAssetIdAndOriginalAssetMap.values()){
                                 if(dr.node__r.Asset__r.parentId !=NULL && memoryParentIdAndAssetMap.containsKey(dr.node__r.Asset__r.parentId) ){
                                         Asset memoryParentAsset= memoryParentIdAndAssetMap.get(dr.node__r.Asset__r.parentId);
                                         relatedProdFamily = memoryParentAsset.Product2.Family != null? memoryParentAsset.Product2.Family : '';
                                         relatedProdFamily=relatedProdFamily.toUppercase();
                                         relatedNicType = memoryParentAsset.Product2.Product_NIC_Type__c != null ? memoryParentAsset.Product2.Product_NIC_Type__c : '';
                                         relatedApplianceModel = memoryParentAsset.Product2.Appliance_Model__c != null ?memoryParentAsset.Product2.Appliance_Model__c:'';
                                         relatedProdCode = memoryParentAsset.Product2.ProductCode;
                                         relatedProdCode =relatedProdCode.toUpperCase();
                                     }
                                     else{
                                         relatedProdFamily = dr.node__r.Asset__r.Product2.Family != null? dr.node__r.Asset__r.Product2.Family : '';
                                         relatedProdFamily=relatedProdFamily.toUppercase();
                                         relatedNicType = dr.node__r.Asset__r.Product2.Product_NIC_Type__c != null ? dr.node__r.Asset__r.Product2.Product_NIC_Type__c : '';
                                         relatedApplianceModel = dr.node__r.Asset__r.Product2.Appliance_Model__c != null ?dr.node__r.Asset__r.Product2.Appliance_Model__c:'';
                                         relatedProdCode = dr.node__r.Asset__r.Product2.ProductCode;
                                         relatedProdCode =relatedProdCode.toUpperCase();
                                     }
                                 /* <--START--> SF-91  Added Logic for new Mapping Helper method*/
                                 Spares_Mapping__c mapping = RMASparePartsMappingHelper.returnSparePartCode(relatedProdFamily, relatedNicType,  relatedApplianceModel); 
     
                                 if(mapping != null) {
                                     
     
                                 ID memprodId = productMap.get(mapping.Memory__c);
                                 system.debug('memprodId'+memprodId);
                                 /* < END ---- SF-91> */
                                 if(memprodId != null){
                                         OrderItem oli = new OrderItem();
                                         oli.assets__c =dr.node__r.Asset__r.serial_number__c;
                                         oli.orderId = neworder.Id;
                                          oli.RMA_Component_Type__c = 'Memory';
                                         if(pricbookEntryMap.containsKey(memprodId)){
                                         system.debug('pricbookEntryMap.get(memprodId)'+pricbookEntryMap.get(memprodId));
                                         oli.PriceBookEntryId =  pricbookEntryMap.get(memprodId);
                                         oli.UnitPrice = pricbookEntryPriceMap.get(oli.PriceBookEntryId);
                                         oli.Sales_Price__c = oli.UnitPrice;
                                         oli.Failed_Serial_Number__c = dr.Serial_Number__c;
                                         oli.Quantity = 1;
     
                                         orderLineItemsList.add(oli);
                                         }
                                         else{
                                         system.debug('RMA_PriceBookID'+system.label.RMA_PriceBookID);
                                             PricebookEntry pbe = new PricebookEntry(UnitPrice=0.0,Product2Id=memprodId,Pricebook2ID=system.label.RMA_PriceBookID, IsActive=true);
                                             insert pbe;
                                             oli.PriceBookEntryId =  pbe.ID;
                                             oli.UnitPrice = pbe.UnitPrice;
                                             oli.Sales_Price__c = pbe.UnitPrice;
                                             oli.Failed_Serial_Number__c = dr.Serial_Number__c;
                                             oli.Quantity = 1;
     
                                             orderLineItemsList.add(oli);
     
                                         }
                                     }
                                 }
                             }
                         }
                 
                     }
     
                 if(!String.isBlank(RMAOrder.Power_Supply__c)){
                     if(RMAOrder.Power_Supply__c == 'Other'){
                         if(!String.isBlank(RMAOrder.Appliance__c)){
                             if(RMAOrder.Appliance__c.contains(',')){
                                 AssetListForPSU = RMAOrder.Appliance__c.split(',');
                             }
                             else{
                                 AssetListForPSU.add(RMAOrder.Appliance__c);
                             }
 
                         }
                         for(Asset dr :[select id,serial_number__c,Product2.Id,product2.Family,product2.Product_NIC_Type__c, product2.Appliance_Model__c,product2.ProductCode from Asset where  Serial_Number__c IN: AssetListForPSU]){
     
                             String relatedProdFamily = dr.Product2.Family != null? dr.Product2.Family : '';
                              relatedProdFamily=relatedProdFamily.toUppercase();
                              String  relatedNicType = dr.Product2.Product_NIC_Type__c != null ? dr.Product2.Product_NIC_Type__c : '';
                              String  relatedApplianceModel = dr.Product2.Appliance_Model__c != null ?dr.Product2.Appliance_Model__c:'';
                             String  relatedProdCode = dr.Product2.ProductCode;
                             /* <--START--> SF-91  Added Logic for new Mapping Helper method*/
                             Spares_Mapping__c mapping = RMASparePartsMappingHelper.returnSparePartCode(relatedProdFamily, relatedNicType,  relatedApplianceModel); 
      
                             if(mapping != null){
                                 
      
                             ID psuprodId = productMap.get(mapping.PSU__c);
                             system.debug('psuprodId'+psuprodId);
                             /* < END ---- SF-91> */
                             if(psuprodId != null){
                                     OrderItem oli = new OrderItem();
                                     oli.assets__c = dr.serial_number__c;
                                  oli.orderId = neworder.Id;
                                  oli.RMA_Component_Type__c = 'PSU';
                                  if(pricbookEntryMap.containsKey(psuprodId)){
                                  system.debug('pricbookEntryMap.get(psuprodId)'+pricbookEntryMap.get(psuprodId));
                                  oli.PriceBookEntryId =  pricbookEntryMap.get(psuprodId);
                                  oli.UnitPrice = pricbookEntryPriceMap.get(oli.PriceBookEntryId);
                                  oli.Sales_Price__c = oli.UnitPrice;
                                  oli.Failed_Serial_Number__c = dr.Serial_Number__c;
                                  oli.Quantity = 1;
      
                                  orderLineItemsList.add(oli);
                                  }
                                  else{
                                  system.debug('RMA_PriceBookID'+system.label.RMA_PriceBookID);
                                      PricebookEntry pbe = new PricebookEntry(UnitPrice=0.0,Product2Id=psuprodId,Pricebook2ID=system.label.RMA_PriceBookID, IsActive=true);
                                      insert pbe;
                                      oli.PriceBookEntryId =  pbe.ID;
                                      oli.UnitPrice = pbe.UnitPrice;
                                      oli.Sales_Price__c = pbe.UnitPrice;
                                      oli.Failed_Serial_Number__c = dr.Serial_Number__c;
                                      oli.Quantity = 1;
      
                                      orderLineItemsList.add(oli);
      
                                  }
                          }
                          }
                         }
                     }
                     else{
                         if(RMAOrder.Power_Supply__c.contains(',')){
                             psuList = RMAOrder.Power_Supply__c.split(',');
                         }
                         else{
                             psuList.add(RMAOrder.Power_Supply__c);
                         }
                     
                        for(Power_Supply__c dr :[select id,Serial_Number__c,Asset__r.Serial_Number__c, Asset__r.Product2.ProductCode,Asset__r.Product2.Id,Asset__r.Product2.Family,Asset__r.Product2.Product_NIC_Type__c,Asset__r.Product2.Appliance_Model__c from Power_Supply__c where Serial_Number__c IN: psuList]){
     
                            String relatedProdFamily = dr.Asset__r.Product2.Family != null? dr.Asset__r.Product2.Family : '';
                             relatedProdFamily=relatedProdFamily.toUppercase();
                             String  relatedNicType = dr.Asset__r.Product2.Product_NIC_Type__c != null ? dr.Asset__r.Product2.Product_NIC_Type__c : '';
                             String  relatedApplianceModel = dr.Asset__r.Product2.Appliance_Model__c != null ?dr.Asset__r.Product2.Appliance_Model__c:'';
                            String  relatedProdCode = dr.Asset__r.Product2.ProductCode;
                            /* <--START--> SF-91  Added Logic for new Mapping Helper method*/
                            Spares_Mapping__c mapping = RMASparePartsMappingHelper.returnSparePartCode(relatedProdFamily, relatedNicType,  relatedApplianceModel); 
     
                            if(mapping != null){
                                
     
                            ID psuprodId = productMap.get(mapping.PSU__c);
                            system.debug('psuprodId'+psuprodId);
                            /* < END ---- SF-91> */
                            if(psuprodId != null){
                                    OrderItem oli = new OrderItem();
                                    oli.assets__c = dr.Asset__r.Serial_Number__c;
                                 oli.orderId = neworder.Id;
                                 oli.RMA_Component_Type__c = 'PSU';
                                 if(pricbookEntryMap.containsKey(psuprodId)){
                                 system.debug('pricbookEntryMap.get(psuprodId)'+pricbookEntryMap.get(psuprodId));
                                 oli.PriceBookEntryId =  pricbookEntryMap.get(psuprodId);
                                 oli.UnitPrice = pricbookEntryPriceMap.get(oli.PriceBookEntryId);
                                 oli.Sales_Price__c = oli.UnitPrice;
                                 oli.Failed_Serial_Number__c = dr.Serial_Number__c;
                                 oli.Quantity = 1;
     
                                 orderLineItemsList.add(oli);
                                 }
                                 else{
                                 system.debug('RMA_PriceBookID'+system.label.RMA_PriceBookID);
                                     PricebookEntry pbe = new PricebookEntry(UnitPrice=0.0,Product2Id=psuprodId,Pricebook2ID=system.label.RMA_PriceBookID, IsActive=true);
                                     insert pbe;
                                     oli.PriceBookEntryId =  pbe.ID;
                                     oli.UnitPrice = pbe.UnitPrice;
                                     oli.Sales_Price__c = pbe.UnitPrice;
                                     oli.Failed_Serial_Number__c = dr.Serial_Number__c;
                                     oli.Quantity = 1;
     
                                     orderLineItemsList.add(oli);
     
                                 }
                         }
                         }
                        }
                     }
     
                 }
     
                    if(!String.isBlank(RMAOrder.Chassis__c)){
                     if(RMAOrder.Chassis__c == 'Other'){
                         if(!String.isBlank(RMAOrder.Appliance__c)){
                             if(RMAOrder.Appliance__c.contains(',')){
                                 AssetListForchassis = RMAOrder.Appliance__c.split(',');
                             }
                             else{
                                 AssetListForchassis.add(RMAOrder.Appliance__c);
                             }
 
                         }
                         for(Asset dr :[select id,serial_number__c, Product2.Id,product2.Family,product2.Product_NIC_Type__c, product2.Appliance_Model__c,product2.ProductCode from Asset where  Serial_Number__c IN: AssetListForchassis]){
     
                             String relatedProdFamily = dr.Product2.Family != null? dr.Product2.Family : '';
                              relatedProdFamily=relatedProdFamily.toUppercase();
                              String  relatedNicType = dr.Product2.Product_NIC_Type__c != null ? dr.Product2.Product_NIC_Type__c : '';
                              String  relatedApplianceModel = dr.Product2.Appliance_Model__c != null ?dr.Product2.Appliance_Model__c:'';
                             String  relatedProdCode = dr.Product2.ProductCode;
                             /* <--START--> SF-91  Added Logic for new Mapping Helper method*/
                             Spares_Mapping__c mapping = RMASparePartsMappingHelper.returnSparePartCode(relatedProdFamily, relatedNicType,  relatedApplianceModel); 
      
                             if(mapping != null){
                                 
      
                             ID chassisprodId = productMap.get(mapping.Chassis__c);
                             //system.debug('psuprodId'+psuprodId);
                             /* < END ---- SF-91> */
                             if(chassisprodId != null){
                                     OrderItem oli = new OrderItem();
                                     oli.assets__c = dr.serial_number__c;
                                  oli.orderId = neworder.Id;
                                   oli.RMA_Component_Type__c = 'Chassis';
                                  if(pricbookEntryMap.containsKey(chassisprodId)){
                                  //system.debug('pricbookEntryMap.get(psuprodId)'+pricbookEntryMap.get(psuprodId));
                                  oli.PriceBookEntryId =  pricbookEntryMap.get(chassisprodId);
                                  oli.UnitPrice = pricbookEntryPriceMap.get(oli.PriceBookEntryId);
                                  oli.Sales_Price__c = oli.UnitPrice;
                                  oli.Failed_Serial_Number__c = dr.Serial_Number__c;
                                  oli.Quantity = 1;
      
                                  orderLineItemsList.add(oli);
                                  }
                                  else{
                                  system.debug('RMA_PriceBookID'+system.label.RMA_PriceBookID);
                                      PricebookEntry pbe = new PricebookEntry(UnitPrice=0.0,Product2Id=chassisprodId,Pricebook2ID=system.label.RMA_PriceBookID, IsActive=true);
                                      insert pbe;
                                      oli.PriceBookEntryId =  pbe.ID;
                                      oli.UnitPrice = pbe.UnitPrice;
                                      oli.Sales_Price__c = pbe.UnitPrice;
                                      oli.Failed_Serial_Number__c = dr.Serial_Number__c;
                                      oli.Quantity = 1;
      
                                      orderLineItemsList.add(oli);
      
                                  }
                          }
                          }
                         }
                     }
                     else{
                        if(RMAOrder.Chassis__c.contains(',')){
                         chassisList = RMAOrder.Chassis__c.split(',');
                         }
                         else{
                             chassisList.add(RMAOrder.Chassis__c);
                         }
                        for(Chassis__c dr :[select id,Serial_Number__c,Asset__r.serial_number__c,Asset__r.Product2.ProductCode,Asset__r.Product2.Id,Asset__r.Product2.Family,Asset__r.Product2.Product_NIC_Type__c,Asset__r.Product2.Appliance_Model__c from Chassis__c where Serial_Number__c IN: chassisList]){
                            String relatedProdFamily = dr.Asset__r.Product2.Family != null? dr.Asset__r.Product2.Family : '';
                             relatedProdFamily=relatedProdFamily.toUppercase();
                             String  relatedNicType = dr.Asset__r.Product2.Product_NIC_Type__c != null ? dr.Asset__r.Product2.Product_NIC_Type__c : '';
                             String  relatedApplianceModel = dr.Asset__r.Product2.Appliance_Model__c != null ?dr.Asset__r.Product2.Appliance_Model__c:'';
     
                            String  relatedProdCode = dr.Asset__r.Product2.ProductCode;
                            /* <--START--> SF-91  Added Logic for new Mapping Helper method*/
                            Spares_Mapping__c mapping = RMASparePartsMappingHelper.returnSparePartCode(relatedProdFamily, relatedNicType,  relatedApplianceModel); 
     
                            if(mapping != null){
                                
     
                            ID chassisprodId = productMap.get(mapping.Chassis__c);
                            system.debug('chassisprodId'+chassisprodId);
                            /* < END ---- SF-91> */
                            if(chassisprodId != null){
                                    OrderItem oli = new OrderItem();
                                    oli.assets__c = dr.Asset__r.serial_number__c;
                                 oli.orderId = neworder.Id;
                                 
                                 oli.RMA_Component_Type__c = 'Chassis';
                                 if(pricbookEntryMap.containsKey(chassisprodId)){
                                 system.debug('pricbookEntryMap.get(chassisprodId)'+pricbookEntryMap.get(chassisprodId));
                                 oli.PriceBookEntryId =  pricbookEntryMap.get(chassisprodId);
                                 oli.UnitPrice = pricbookEntryPriceMap.get(oli.PriceBookEntryId);
                                 oli.Sales_Price__c = oli.UnitPrice;
                                 oli.Failed_Serial_Number__c = dr.Serial_Number__c;
                                 oli.Quantity = 1;
     
                                 orderLineItemsList.add(oli);
                                 }
                                 else{
                                 system.debug('RMA_PriceBookID'+system.label.RMA_PriceBookID);
                                     PricebookEntry pbe = new PricebookEntry(UnitPrice=0.0,Product2Id=chassisprodId,Pricebook2ID=system.label.RMA_PriceBookID, IsActive=true);
                                     insert pbe;
                                     oli.PriceBookEntryId =  pbe.ID;
                                     oli.UnitPrice = pbe.UnitPrice;
                                     oli.Sales_Price__c = pbe.UnitPrice;
                                     oli.Failed_Serial_Number__c = dr.Serial_Number__c;
                                     oli.Quantity = 1;
     
                                     orderLineItemsList.add(oli);
     
                                 }
                         }
                         }
                        }
                     }
     
                    }
                    if(!String.isBlank(RMAOrder.Node__c) && RMAOrder.Node_Quantity__c != null){
                         if(RMAOrder.Node__c.contains(',')){
                             nodeList = RMAOrder.Node__c.split(',');
                         }
                         else{
                             nodeList.add(RMAOrder.Node__c);
                         }
     
                         //SF-6769 Introduced new CPU Model
                         Map<String, String> skuReplacementForNewCPUModel = new Map<String, String>();
                         //Added for SF-7053: UPdate RMA process to handle parent Asset
                         Map<ID, asset> NodeparentIdAndAssetMap = new Map<ID, Asset>();
                         Map<ID, Node__c> NodeAssetIdAndOriginalAssetMap = new Map<ID, Node__c>();
                         Set<Id> nodeParentID= new Set<Id>();
                         String relatedProdFamily;
                         String  relatedNicType;
                         String  relatedApplianceModel;
                         String  relatedProdCode;
                         
                         for(RMA_Spares_Replacement__mdt replacementSKUs: [Select Label, CPU_Model__c, Replacement_SKU__c from RMA_Spares_Replacement__mdt]){
                             skuReplacementForNewCPUModel.put(replacementSKUs.Label+'_'+replacementSKUs.CPU_Model__c, replacementSKUs.Replacement_SKU__c);
                         }
                         for(Node__c nodedata :[select Id,Serial_Number__c, Asset__r.Serial_Number__c,asset__r.ParentId,Asset__r.Product2.ProductCode,Asset__r.Product2.Id,Asset__r.Product2.Family,Asset__r.Product2.Product_NIC_Type__c,Asset__r.Product2.Appliance_Model__c, cpu_model__c from Node__c where Serial_Number__c IN: nodeList]){
                             NodeAssetIdAndOriginalAssetMap.put(nodedata.Id,nodedata);
                             if(nodedata.Asset__r.ParentId != Null){
                                 nodeParentID.add(nodedata.Asset__r.ParentId);
                             }
                         }
                         if(nodeParentID.size() > 0){
                             for(Asset AsData :[select Id,Serial_Number__c,ParentId,Product2.ProductCode,Product2.Id,Product2.Family,Product2.Product_NIC_Type__c,Product2.Appliance_Model__c from Asset where id IN: nodeParentID]){
                                 NodeparentIdAndAssetMap.put(AsData.Id,AsData);
                             }
                         }
                         // edited to check parentId
                        for(Node__c dr :NodeAssetIdAndOriginalAssetMap.values()){
                            if( dr.asset__r.ParentId !=Null && NodeparentIdAndAssetMap.containsKey(dr.asset__r.ParentId)){
                                Asset nodeAssetinfo=NodeparentIdAndAssetMap.get(dr.asset__r.ParentId);
                                relatedProdFamily=nodeAssetinfo.Product2.Family;
                                relatedProdFamily=relatedProdFamily.toUppercase();
                                relatedNicType = nodeAssetinfo.Product2.Product_NIC_Type__c != null ? nodeAssetinfo.Product2.Product_NIC_Type__c : '';
                                relatedApplianceModel = nodeAssetinfo.Product2.Appliance_Model__c != null ?nodeAssetinfo.Product2.Appliance_Model__c:'';
                                relatedProdCode =nodeAssetinfo.Product2.ProductCode;
                            }
                            else{
                                 relatedProdFamily = dr.Asset__r.Product2.Family != null? dr.Asset__r.Product2.Family : '';
                                 relatedProdFamily=relatedProdFamily.toUppercase();
                                 relatedNicType = dr.Asset__r.Product2.Product_NIC_Type__c != null ? dr.Asset__r.Product2.Product_NIC_Type__c : '';
                                 relatedApplianceModel = dr.Asset__r.Product2.Appliance_Model__c != null ?dr.Asset__r.Product2.Appliance_Model__c:'';
                                 relatedProdCode = dr.Asset__r.Product2.ProductCode;
                            }
                            /* <--START--> SF-91  Added Logic for new Mapping Helper method*/
                            Spares_Mapping__c mapping = RMASparePartsMappingHelper.returnSparePartCode(relatedProdFamily, relatedNicType,  relatedApplianceModel); 
     
                            if(mapping != null){
                                String nodeName = mapping.Node__c;
                                if(skuReplacementForNewCPUModel.containsKey(nodeName+'_'+dr.cpu_model__c)){
                                    nodeName = skuReplacementForNewCPUModel.get(nodeName+'_'+dr.cpu_model__c);
                                }
                            ID nodeprodId = productMap.get(nodeName);
                            system.debug('nodeprodId'+nodeprodId);
                            /* < END ---- SF-91> */
                            if(nodeprodId != null){
                                    OrderItem oli = new OrderItem();
                                    oli.assets__c = dr.Asset__r.serial_number__c;
                                 oli.orderId = neworder.Id;
                                  oli.RMA_Component_Type__c = 'Node';
                                 for(id ids : pricbookEntryMap.KeySet()){
                                     system.debug('key=='+pricbookEntryMap.get(ids));
                                 }
                                 if(pricbookEntryMap.containsKey(nodeprodId)){
                                 system.debug('pricbookEntryMap.get(nodeprodId)'+pricbookEntryMap.get(nodeprodId));
                                 oli.PriceBookEntryId =  pricbookEntryMap.get(nodeprodId);
                                 oli.UnitPrice = pricbookEntryPriceMap.get(oli.PriceBookEntryId);
                                 oli.Sales_Price__c = oli.UnitPrice;
                                 oli.Failed_Serial_Number__c = dr.Serial_Number__c;
                                 
                                 oli.Quantity = 1;
     
                                 orderLineItemsList.add(oli);
                                 }
                                 else{
                                 system.debug('RMA_PriceBookID'+system.label.RMA_PriceBookID);
                                     PricebookEntry pbe = new PricebookEntry(UnitPrice=0.0,Product2Id=nodeprodId,Pricebook2ID=system.label.RMA_PriceBookID, IsActive=true);
                                     insert pbe; 
                                     oli.PriceBookEntryId =  pbe.ID;
                                     oli.UnitPrice = pbe.UnitPrice;
                                     oli.Sales_Price__c = pbe.UnitPrice;
                                     oli.Failed_Serial_Number__c = dr.Serial_Number__c;
                                     oli.Quantity = 1;
     
                                     orderLineItemsList.add(oli);
     
                                     }
                             }
                             }   
                        }
     
                    }
     
                    if(!String.isBlank(RMAOrder.NIC__c)){
                    if(RMAOrder.NIC__c.contains(',')){
                     nicList = RMAOrder.NIC__c.split(',');
                     }
                     else{
                         nicList.add(RMAOrder.NIC__c);
                     }
                        for(NIC__c dr :[select id,Serial_Number__c, node__r.Asset__r.Serial_Number__c, node__r.Asset__r.Product2.ProductCode,node__r.Asset__r.Product2.Id,node__r.Asset__r.Product2.Family,node__r.Asset__r.Product2.Product_NIC_Type__c,node__r.Asset__r.Product2.Appliance_Model__c,Asset__r.Product2.ProductCode from NIC__c where Serial_Number__c IN: nicList]){
                            String relatedProdFamily = dr.node__r.Asset__r.Product2.Family != null? dr.node__r.Asset__r.Product2.Family : '';
                             relatedProdFamily=relatedProdFamily.toUppercase();
                             String  relatedNicType = dr.node__r.Asset__r.Product2.Product_NIC_Type__c != null ? dr.node__r.Asset__r.Product2.Product_NIC_Type__c : '';
                             String  relatedApplianceModel = dr.node__r.Asset__r.Product2.Appliance_Model__c != null ?dr.node__r.Asset__r.Product2.Appliance_Model__c:'';
     
                            String  relatedProdCode = dr.Asset__r.Product2.ProductCode;
                            Spares_Mapping__c mapping = RMASparePartsMappingHelper.returnSparePartCode(relatedProdFamily, relatedNicType,  relatedApplianceModel); 
     
                            if(mapping != null){
                            ID nicprodId = productMap.get(mapping.NIC__c);
                            system.debug('nicprodId'+nicprodId);
                            /* < END ---- SF-91> */
                            if(nicprodId != null){
                                    OrderItem oli = new OrderItem();
                                    oli.assets__c = dr.node__r.Asset__r.serial_number__c;
                                 oli.orderId = neworder.Id;
                                  oli.RMA_Component_Type__c = 'NIC';
                                 if(pricbookEntryMap.containsKey(nicprodId)){
                                 system.debug('pricbookEntryMap.get(nicprodId)'+pricbookEntryMap.get(nicprodId));
                                 oli.PriceBookEntryId =  pricbookEntryMap.get(nicprodId);
                                 oli.UnitPrice = pricbookEntryPriceMap.get(oli.PriceBookEntryId);
                                 oli.Sales_Price__c = oli.UnitPrice;
                                 oli.Failed_Serial_Number__c = dr.Serial_Number__c;
                                 oli.Quantity = 1;
     
                                 orderLineItemsList.add(oli);
                                 }
                                 else{
                                 system.debug('RMA_PriceBookID'+system.label.RMA_PriceBookID);
                                     PricebookEntry pbe = new PricebookEntry(UnitPrice=0.0,Product2Id=nicprodId,Pricebook2ID=system.label.RMA_PriceBookID, IsActive=true);
                                     upsert pbe;
     
                                     oli.PriceBookEntryId =  pbe.ID;
                                     oli.UnitPrice = pbe.UnitPrice;
                                     oli.Sales_Price__c = pbe.UnitPrice;
                                     oli.Failed_Serial_Number__c = dr.Serial_Number__c;
                                     oli.Quantity = 1;
     
                                     orderLineItemsList.add(oli);
     
                                 }
                         }
                         }
                        }
                       }
                       
                       if(!String.isBlank(RMAOrder.CMOS_Battery__c)){
                    if(RMAOrder.CMOS_Battery__c.contains(',')){
                         cmosList = RMAOrder.CMOS_Battery__c.split(',');
                     }
                     else{
                         cmosList.add(RMAOrder.CMOS_Battery__c);
                     }
                       //for(integer i=0 ;  i< RMAOrder.CMOS_Battery_Quantity__c; i++) {
                            
                            ID cmosProdId = productMap.get(Label.CMOS_Battery_Product);
                            system.debug('cmosProdId'+cmosProdId);
                            /* < END ---- SF-91> */
                            if(cmosProdId != null){
                                    OrderItem oli = new OrderItem();
                                 oli.orderId = neworder.Id;
                                  oli.RMA_Component_Type__c = 'CMOS Battery';
                                 if(pricbookEntryMap.containsKey(cmosProdId)){
                                 system.debug('pricbookEntryMap.get(cmosProdId)'+pricbookEntryMap.get(cmosProdId));
                                 oli.PriceBookEntryId =  pricbookEntryMap.get(cmosProdId);
                                 oli.UnitPrice = pricbookEntryPriceMap.get(oli.PriceBookEntryId);
                                 oli.Sales_Price__c = oli.UnitPrice;
                                 //oli.Failed_Serial_Number__c = RMAOrder.CMOS_Battery__c;
                                 oli.Quantity = RMAOrder.CMOS_Battery_Quantity__c;
     
                                 orderLineItemsList.add(oli);
                                 }
                                 else{
                                 system.debug('RMA_PriceBookID'+system.label.RMA_PriceBookID);
                                     PricebookEntry pbe = new PricebookEntry(UnitPrice=0.0,Product2Id=cmosProdId,Pricebook2ID=system.label.RMA_PriceBookID, IsActive=true);
                                     upsert pbe;
     
                                     oli.PriceBookEntryId =  pbe.ID;
                                     oli.UnitPrice = pbe.UnitPrice;
                                     oli.Sales_Price__c = pbe.UnitPrice;
                                     //oli.Failed_Serial_Number__c = RMAOrder.CMOS_Battery__c;
                                     oli.Quantity = RMAOrder.CMOS_Battery_Quantity__c;
     
                                     orderLineItemsList.add(oli);
     
                                 }
                         }
                         //}
                        
                       }
     
     
     
                    
                     if(orderLineItemsList.size()>0){
                     insert orderLineItemsList;
                    map<string,List<string>> producttypecountMap=new map<string,List<string>>();
                    for(orderitem item : orderLineItemsList){
                        if(!producttypecountMap.containskey(item.PricebookEntry.Product2.Product_Subtype__c)){
                            producttypecountMap.put(item.PricebookEntry.Product2.Product_Subtype__c+':'+item.order.ordernumber,new List<string>{item.PricebookEntry.Product2.Product_Subtype__c});
                        }else{
                        producttypecountMap.get(item.PricebookEntry.Product2.Product_Subtype__c+':'+item.order.ordernumber).add(item.PricebookEntry.Product2.Product_Subtype__c);
                        }
                    }
                      string sow='';
                      string vendormessage='';
                      String phoneNumber = '';
                       vendormessage='';
                       if(techorder.Vendor_Message__c == null)
                       techorder.Vendor_Message__c='';
                          sow='Scope:';
                          for(string item :producttypecountMap.keyset() ){
                           string splititem = item.split(':')[0];
                           if(splititem != 'null'){
                              if(producttypecountMap.containskey(splititem+techorder.linked_RMA_Part_Order__C)){
                                  sow= sow +splititem+'('+producttypecountMap.get(splititem+techorder.linked_RMA_Part_Order__C).size()+'),';
                              }
                              }
                           }
                           if(mapStatusCounrtyCodeCustomSetting.containsKey(RMAOrder.ShippingCountry__c) &&
                           mapStatusCounrtyCodeCustomSetting.get(RMAOrder.ShippingCountry__c).Phone__c != null){
                          phoneNumber = mapStatusCounrtyCodeCustomSetting.get(RMAOrder.ShippingCountry__c).Phone__c;
                          }else {
                               phoneNumber = '+1-800-997-5896';  
                           } 
                        vendorMessage = sow+' Replacement(s) Contact Rubrik Support before performing part replacements '+phoneNumber +' Case#:'+techorder.rma_request__r.Parent_Case__r.CaseNumber;
                        techorder.Vendor_Message__c = (String.isNotBlank(techorder.Vendor_Message__c)) ? techorder.Vendor_Message__c +' '+vendorMessage : vendorMessage;
                        // PRDOPS22-455
                         String vendorMessageLimitCheck = techorder.Vendor_Message__c;
                        if(vendorMessageLimitCheck.length() > 260 ){
                        techorder.Vendor_Message__c = vendorMessageLimitCheck.substring(0, 260) + '...';
                        }
                      update techorder;
                  
                  }
                 system.debug('neworder=='+neworder);
                 system.debug('orderLineItemsList=='+orderLineItemsList+'==size of orderLineItemsList=='+orderLineItemsList.size());
                 ordersIDset.add(neworder.Id);
                 if(!ordersIDset.isEmpty()){
                 sendEmailtoFlash(ordersIDset);
                 }
                 System.debug('******ORDER CREATED BY VARSHA ID ***** '+ordersIDset);
     
             }catch(Exception ex){
                 Error_Logs__c el = new Error_Logs__c(
                 Error_Type__c = 'RMA Order Error',
                 Error_Message__c = ex.getMessage() + '\r\n' + ex.getStackTraceString(),
                 Type__c = 'SFDC'
                 );
                 insert el;
                 System.debug('Exception==Method: createOrderWithOrderItems==Class== RMAOrderService'+ex);
             }
         }
    /* oldtrigger code is replaced with createRMAOrderWithOrderItems */
    public static void createRMAOrderWithOrderItems(Set<Id> rmaIdSet) {
          try{
              Set<ID> ordersIDset = new Set<ID>();
              Map<Id,RMA_Order__c> rmaIdMap;
              List<RMA_Order__c> RMAOrderList = new List<RMA_Order__c>();
              List<Order> neworderList = new List<Order>();
              List<OrderItem> pbeOrderLineItemsList = new List<OrderItem>();
              Map<Id,Order> ordrmaMap = new Map<Id,Order>();
              Map<string,PricebookEntry> PricebookEntryUpsertMap = new Map<string,PricebookEntry>();
              Map<string,List<OrderItem>> orderLineItemsMap = new Map<string,List<OrderItem>>();
              List<sparesWrapperClass> sparesWrapperClassList = new List<sparesWrapperClass>();
              List<Spares_Mapping__c> sparesList = new List<Spares_Mapping__c>();
              
              sparesList = RMASparePartsMappingHelper.returnSparePartCodeQueryAll();
              rmaIdMap = new Map<Id,RMA_Order__c>([select Parent_Case__c,Parent_Case__r.CaseNumber,Parent_Case__r.AccountID,Smart_Hands_Provider__c, Ship_To_Phone_Number__c,Ship_To_Contact_Name__c,Ship_To_Name__c,Ship_To_Name__r.Name,Ship_To_Email__c, Parent_Case__r.Account.Distributor__c,Parent_Case__r.Account.Distributor__r.Payment_Term__c,
                                                   Memory__c, Power_Supply__c, Status__c, Node__c, Drive__c,SSD__C, NIC__c,Chassis__c,Service_Type__c, Shipping_Street__c, Shipping_City__c, ShippingState__c, Shipping_Zip_Postal_Code__c,
                                                   ShippingCountry__c, Node_Quantity__c, Drive_Quantity__c, Chasis_Quantity__c,Memory_Quantity__c, Power_Supply_Quantity__c, NIC_Quantity__c, Appliance_Quantity__c, Cluster_ID__c, Appliance__c, CMOS_Battery__c, CMOS_Battery_Quantity__c,
                                                   Parent_Case__r.Account.Distributor__r.Shipping_Carrier__c , Parent_Case__r.Account.Distributor__r.Shipping_Method__c , Parent_Case__r.Account.Distributor__r.Shipping_Account_Number__c,Parent_Case__r.Account.Distributor__r.IncoTerms__c,
                                                   Vendor_Message__c, Send_Smart_Hands_Service__c, Date_of_Smart_Hands_Arrival__c, Time_of_Smart_Hands_Tech_Arrival__c, Customer_Ref_number__c  /* @Author: Sukesh K @Description: for DGWD-128, DGWD-17, DGWD-152 */
                                                   from RMA_Order__C where Id IN:rmaIdSet]);
              for(Id rmakeyId : rmaIdMap.keySet()){
                  Order neworder = new Order();
                  neworder.status='Pending';
                  // PRDOPS23-22
                  neworder.AccountId=rmaIdMap.get(rmakeyId).Ship_To_Name__c;
                  neworder.Vendor_Message__c = rmaIdMap.get(rmakeyId).Vendor_Message__c;    /* @Author: Sukesh K @Description: for DGWD-128 */
                  neworder.Customer_Ref_number__c = rmaIdMap.get(rmakeyId).Customer_Ref_number__c;    /* @Author: Sukesh K @Description: for DGWD-152 */
                  //neworder.OpportunityId=opp.Id;
                  neworder.EffectiveDate=system.Today();
                  
                  Map<String, StateCodeName__C> mapStatusStateCodeCustomSetting = StateCodeName__C.getAll();
                  Map<String, CountryWithCode__c> mapStatusCounrtyCodeCustomSetting = CountryWithCode__c.getAll();
                  string uniqueCode='';
                  if(mapStatusCounrtyCodeCustomSetting.containsKey(rmaIdMap.get(rmakeyId).ShippingCountry__C))
                      uniqueCode = mapStatusCounrtyCodeCustomSetting.get(rmaIdMap.get(rmakeyId).ShippingCountry__C).code__C+'-'+rmaIdMap.get(rmakeyId).ShippingState__c;
                  newOrder.Shippingcountry=rmaIdMap.get(rmakeyId).ShippingCountry__C;
                  newOrder.ShippingcountryCode=mapStatusCounrtyCodeCustomSetting.get(rmaIdMap.get(rmakeyId).ShippingCountry__C).code__C;
                  newOrder.Shippingcity=rmaIdMap.get(rmakeyId).Shipping_City__c;
                  newOrder.Shippingstreet=rmaIdMap.get(rmakeyId).Shipping_street__C;
                  newOrder.ShippingstateCode= !uniquecode.contains('-null')?uniquecode.substring(3,5):null;//mapStatusStateCodeCustomSetting.get(uniqueCode).State_Name__c; //rmaOrder.ShippingState__c;
                  newOrder.ShippingPostalCode=rmaIdMap.get(rmakeyId).Shipping_Zip_Postal_Code__c;
                  newOrder.Service_Type__c=rmaIdMap.get(rmakeyId).Service_Type__c;
                  newOrder.Ship_To_Name__c =rmaIdMap.get(rmakeyId).Ship_To_Name__r.Name;
                  newOrder.Bill_To_Name__c =rmaIdMap.get(rmakeyId).Ship_To_Name__c;
                  newOrder.ShipToContactName__c=rmaIdMap.get(rmakeyId).Ship_To_Contact_Name__c;
                  newOrder.Ship_To_Email__c=rmaIdMap.get(rmakeyId).Ship_To_Email__c;
                  newOrder.Ship_To_Phone_Number__c =rmaIdMap.get(rmakeyId).Ship_To_Phone_Number__c;
                  //newOrder.Shipping_Carrier__c = Label.RMA_Shipping_Carrier;
                  //Added by Ikyatha  @DGWD-160
                    string shippingcountry = rmaIdMap.get(rmakeyId).ShippingCountry__C.toUppercase();
                    if(serviceLevelMap.containskey(rmaIdMap.get(rmakeyId).Service_Type__c+':'+shippingcountry)){
                    newOrder.Shipping_Carrier__c = serviceLevelMap.get(rmaIdMap.get(rmakeyId).Service_Type__c+':'+shippingcountry).OrderShippingCarrier__c;
        
                    newOrder.Service_Level__c = serviceLevelMap.get(rmaIdMap.get(rmakeyId).Service_Type__c+':'+shippingcountry).OrderServiceLevel__c;
                    neworder.scac__c=serviceLevelMap.get(rmaIdMap.get(rmakeyId).Service_Type__c+':'+shippingcountry).scac__c;
                    }
                  newOrder.Shipping_Method__c = Label.RMA_Shipping_Terms;
                  newOrder.Service_Type__c = rmaIdMap.get(rmakeyId).Service_Type__c;
                  
                  neworder.Pricebook2Id = system.label.RMA_PriceBookID;
                  newOrder.Type ='RMA';
                  Id OrderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('RMA Order').getRecordTypeId();
                  if(OrderRecordTypeId != null)
                      newOrder.RecordTypeId= OrderRecordTypeId;
                  
                  newOrder.RMA_Request__C= rmakeyId;
                  newOrder.PO_Number__c = 'n/a';
                  /*
                    @Author: Sukesh K
                    @Description: for DGWD-17
                    Created techOrder
                    Created techOrderLineItems for techOrder
                    Added Order_Sub_Type__c
                        neworder: 'Part Order'
                        techOrder: 'Tech Order'
                */
                neworder.Order_Sub_Type__c = 'Part Order';
                neworderList.add(newOrder);
                
              }
             if(!neworderList.isEmpty()){
                  insert neworderList;
             }
             for(Order ord : neworderList){
                  ordrmaMap.put(ord.RMA_Request__c,ord);
                  ordersIDset.add(ord.Id);
             }
             Map<String,String> techorderMap = new Map<String,String>();  
             if(!ordersIDset.isEmpty()){
                 List<Order> techorderList = new List<Order>();    
                 Map<string,string> ordnumRMAMap = new Map<string,string>();
                 for(Order o : [SELECT OrderNumber,RMA_Request__c FROM Order WHERE Id IN :ordersIDset]){
                     ordnumRMAMap.put(o.RMA_Request__c,o.OrderNumber);
                 }
                 for(Id rmakeyId : rmaIdMap.keySet()){
                    Order techOrder;
                    Boolean shouldCreateTechOrder = rmaIdMap.get(rmakeyId).Send_Smart_Hands_Service__c;
                    if (shouldCreateTechOrder) {
                        techOrder = createTechOrderByCloning(ordrmaMap.get(rmakeyId), rmaIdMap.get(rmakeyId).Date_of_Smart_Hands_Arrival__c, rmaIdMap.get(rmakeyId).Time_of_Smart_Hands_Tech_Arrival__c);
                        techOrder.Linked_RMA_Part_order__c = ordnumRMAMap.get(rmakeyId);
                       
                           
    
                        if(serviceLevelMap.containskey('DefaultShippingInfo:Default')){
                         techorder.Shipping_Carrier__c = serviceLevelMap.get('DefaultShippingInfo:Default').OrderShippingCarrier__c;
                         techorder.Service_Level__c =  serviceLevelMap.get('DefaultShippingInfo:Default').OrderServiceLevel__c;
                         techorder.scac__c =  serviceLevelMap.get('DefaultShippingInfo:Default').scac__c;
                        }
                         techorderList.add(techOrder);
                    }
                  }
                  if(!techorderList.isEmpty()){
                      insert techorderList;
                  }
                 for(Id rmakeyId : rmaIdMap.keySet()){ 
                    for(Order tord : techorderList){
                        if(ordnumRMAMap.containsKey(rmakeyId) && ordnumRMAMap.get(rmakeyId) == tord.Linked_RMA_Part_order__c)
                            techorderMap.put(rmakeyId,tord.Id); 
                    }
                 }
              }
              
              List<OrderItem> orderLineItemsList = new List<OrderItem>();
              
              Map<Id,Id> pricbookEntryMap = new Map<Id,Id>();
              Map<Id,Decimal> pricbookEntryPriceMap = new Map<Id,Decimal>();/*isActive = true and */
              for(PricebookEntry pbe : [select id, UnitPrice,product2ID from PricebookEntry where  PriceBook2ID =:System.label.RMA_PriceBookID]){
                  pricbookEntryMap.put(pbe.product2ID,pbe.Id);
                  pricbookEntryPriceMap.put(pbe.id,pbe.UnitPrice);
              }
              system.debug('pricbookEntryMap=='+pricbookEntryMap+'==size'+pricbookEntryMap.size());
              system.debug('pricbookEntryPriceMap=='+pricbookEntryPriceMap+'==size'+pricbookEntryPriceMap.size());
              
              Id techOrderProductId = System.label.Product_Id_Tech_Order;
              If (Test.isRunningTest()) {
                  techOrderProductId = [SELECT Id FROM  Product2 WHERE Name = 'X-SVC-TECH' LIMIT 1 ].Id;
              }
              Id techOliPricebookEntryId = pricbookEntryMap.get(techOrderProductId);
              for(Id rmakeyId : rmaIdMap.keySet()){
                  if (rmaIdMap.get(rmakeyId).Send_Smart_Hands_Service__c) {
                        orderLineItemsList.add(
                        createTechOrderLineItem(techorderMap.get(rmakeyId), techOliPricebookEntryId,pricbookEntryPriceMap.get(techOliPricebookEntryId)
                    ));
                }
              }
              List<String> assetList = new List<String>();
              List<String> driveList = new List<String>();
              List<String> memoryList = new List<String>();
              List<String> nicList = new List<String>();
              List<String> psuList = new List<String>();
              List<String> chassisList = new List<String>();
              List<String> nodeList = new List<String>();
              List<String> cmosList = new List<String>();
              List<String> nodeListForMemory = new List<String>();
              List<String> nodeListForDrive = new List<String>();
              List<String> AssetListForPSU = new List<String>();
              List<String> AssetListForChassis = new List<String>();
              Map<Id,List<String>> assetRMAMap = new Map<Id,List<String>>();
              Map<Id,List<String>> nodeRMADriveMap = new Map<Id,List<String>>();
              Map<Id,List<String>> driveRMAMap = new Map<Id,List<String>>();
              Map<String,Asset> astSNMap = new Map<string,Asset>();
              string serialNumber;
              string assetSerialNumber;
              String driveType;
              
              for(Id rmakeyId : rmaIdMap.keySet()){
                  List<string> tempList1 = new List<string>();
                  if(!String.isBlank(rmaIdMap.get(rmakeyId).Appliance__c) && rmaIdMap.get(rmakeyId).Appliance_Quantity__c != null){
                      if(rmaIdMap.get(rmakeyId).Appliance__c.contains(',')){
                          tempList1 = rmaIdMap.get(rmakeyId).Appliance__c.split(',');
                          assetList = rmaIdMap.get(rmakeyId).Appliance__c.split(',');
                      }
                      else{
                          tempList1.add(rmaIdMap.get(rmakeyId).Appliance__c);
                          assetList.add(rmaIdMap.get(rmakeyId).Appliance__c);
                      }
                      assetRMAMap.put(rmakeyId,tempList1);
                  }
              }
              
              if(!assetList.isEmpty()){
                  List<Asset> assetRecList = new List<Asset>();
                  assetRecList = [select id,serial_Number__C,Product2ID from Asset where serial_Number__c IN:assetList];
                  for(Asset ast: assetRecList){
                      astSNMap.put(ast.serial_Number__c,ast);
                  }
                  for(Id rmakeyId : rmaIdMap.keySet()){
                      for(String serialNum : assetRMAMap.get(rmakeyId)){
                          if(astSNMap.containskey(serialNum)){
                              Asset asset = new Asset();
                              asset = astSNMap.get(serialNum);
                              OrderItem oli = new OrderItem();
                              oli.Assets__c = asset.serial_Number__C;
                              oli.orderId = ordrmaMap.get(rmakeyId).Id; //oli.orderId = neworder.Id;
                              oli.PriceBookEntryId = pricbookEntryMap.get(asset.Product2ID);
                              oli.UnitPrice = pricbookEntryPriceMap.get(oli.PriceBookEntryId);
                              oli.Sales_Price__c = oli.UnitPrice;
                              oli.Failed_Serial_Number__c = asset.Serial_Number__c;
                              oli.RMA_Component_Type__c = 'Appliance';
                              oli.Quantity = 1;
                              orderLineItemsList.add(oli);
                          }
                      }
                  }
              }
              
              Map<String,Id> productMap = new Map<String,Id>();
              for(Product2 prod : [select id,productcode from product2 where (productcode != null OR productcode != '')]){
                  productMap.put(prod.productcode,prod.Id);
              }
              system.debug('productMap=='+productMap+'==size'+productMap.size());
              
              for(Id rmakeyId : rmaIdMap.keySet()){
                  List<string> tempList1 = new List<string>();
                  if(!String.isBlank(rmaIdMap.get(rmakeyId).Drive__c) || !String.isBlank(rmaIdMap.get(rmakeyId).SSD__c)){
                      if(!String.isBlank(rmaIdMap.get(rmakeyId).Drive__c)){
                          if(rmaIdMap.get(rmakeyId).Drive__c=='Other'){
                              driveType='HDD';
                              if(!String.isBlank(rmaIdMap.get(rmakeyId).Node__c)){
                                  if(rmaIdMap.get(rmakeyId).Node__c.contains(',')){
                                      tempList1.addAll(rmaIdMap.get(rmakeyId).Node__c.split(','));
                                      nodeListForDrive.addAll(rmaIdMap.get(rmakeyId).Node__c.split(','));
                                  }
                                  else{
                                      tempList1.add(rmaIdMap.get(rmakeyId).Node__c);
                                      nodeListForDrive.add(rmaIdMap.get(rmakeyId).Node__c);
                                  }
                                  nodeRMADriveMap.put(rmakeyId,tempList1);
                              }
                          } 
                          else{
                              if(rmaIdMap.get(rmakeyId).Drive__c.contains(',')){
                                  tempList1.addAll(rmaIdMap.get(rmakeyId).Drive__c.split(','));
                                  driveList.addAll(rmaIdMap.get(rmakeyId).Drive__c.split(','));
                              }
                              else{
                                  tempList1.add(rmaIdMap.get(rmakeyId).Drive__c);
                                  driveList.add(rmaIdMap.get(rmakeyId).Drive__c);
                              }
                              driveRMAMap.put(rmakeyId,tempList1);
                          }
                      }
                      if(!String.isBlank(rmaIdMap.get(rmakeyId).SSD__c)){
                          if(rmaIdMap.get(rmakeyId).SSD__c=='Other'){
                              driveType='SSD';
                              if(rmaIdMap.get(rmakeyId).Node__c.contains(',')){
                                  tempList1.addAll(rmaIdMap.get(rmakeyId).Node__c.split(','));
                                  nodeListForDrive.addAll(rmaIdMap.get(rmakeyId).Node__c.split(','));
                              }
                              else{
                                  tempList1.add(rmaIdMap.get(rmakeyId).Node__c);
                                  nodeListForDrive.add(rmaIdMap.get(rmakeyId).Node__c);
                              }
                              nodeRMADriveMap.put(rmakeyId,tempList1); 
                          } 
                          else{
                              if(rmaIdMap.get(rmakeyId).SSD__c.contains(',')){
                                  tempList1.addAll(rmaIdMap.get(rmakeyId).SSD__c.split(','));
                                  driveList.addAll(rmaIdMap.get(rmakeyId).SSD__c.split(','));
                              }
                              else{
                                  tempList1.add(rmaIdMap.get(rmakeyId).SSD__c);
                                  driveList.add(rmaIdMap.get(rmakeyId).SSD__c);
                              }
                              driveRMAMap.put(rmakeyId,tempList1);
                          }
                      }
                  }
              }
              Map<string,List<string>> driveParentIDRMAMap = new Map<string,List<string>>();
              Map<ID, asset> driveParentIdAndParentAsset = new Map<ID, Asset>();
              Map<ID, drive__c> driveAssetIdAndOriginalAsset = new Map<ID, drive__c>();
              Set<Id> driveParentID = new Set<Id>();
              //added for OTHER logic
              Set<Id> driveNodeParentID = new Set<Id>();
              Map<ID, Node__c> driveNodeAssetIdAndOriginalAssetMap = new Map<ID, Node__c>();
              Map<ID, asset> driveNodeparentIdAndAssetMap = new Map<ID, Asset>();
              String relatedProdFamily;
              String  relatedNicType;
              String  relatedApplianceModel;
              String  relatedProdCode;
              String dType;
              if(driveList.size() > 0){
                  for(Drive__C dr :[select Id,Serial_Number__c,Asset__r.Serial_Number__c,node__r.Asset__r.Serial_Number__c, node__r.Asset__r.Id,node__r.Asset__r.parentId,node__r.Asset__r.Product2.ProductCode,node__r.Asset__r.Product2.Id,node__r.Asset__r.Product2.Family,node__r.Asset__r.Product2.Product_NIC_Type__c,node__r.Asset__r.Product2.Appliance_Model__c, Type__C from Drive__c where Serial_Number__c IN: driveList]){
                      driveAssetIdAndOriginalAsset.put(dr.Id,dr);
                      if(dr.node__r.Asset__r.parentId !=NULL){
                          driveParentID.add(dr.node__r.Asset__r.parentId);
                          for(Id rmakeyId : driveRMAMap.keySet()){
                              if(driveRMAMap.get(rmakeyId).contains(dr.Serial_Number__c)){
                                  if(driveParentIDRMAMap.isEmpty() || !driveParentIDRMAMap.containskey(rmakeyId))
                                      driveParentIDRMAMap.put(rmakeyId,new List<string>());
                                  driveParentIDRMAMap.get(rmakeyId).add(dr.node__r.Asset__r.parentId); //Map of RMAId and AssetId
                              }
                          }
                      }
                  }
                  
                  if(driveParentID.size() > 0){
                      for(Asset driveAsData :[select Id,Serial_Number__c,ParentId,Product2.ProductCode,Product2.Id,Product2.Family,Product2.Product_NIC_Type__c,Product2.Appliance_Model__c from Asset where Id IN: driveParentID]){
                          driveParentIdAndParentAsset.put(driveAsData.Id,driveAsData);
                      }
                  }
                  
                  sparesWrapperClassList.clear();
                  for(Id rmakeyId : rmaIdMap.keySet()){
                      for(Drive__C dr :driveAssetIdAndOriginalAsset.values()){
                          if(dr.node__r.Asset__r.parentId != NULL && !driveParentIDRMAMap.isEmpty() && driveParentIDRMAMap.containskey(rmakeyId) && driveParentIDRMAMap.get(rmakeyId).contains(dr.node__r.Asset__r.parentId) && driveParentIdAndParentAsset.containsKey(dr.node__r.Asset__r.parentId)){
                              Asset DriveParentAsset = driveParentIdAndParentAsset.get(dr.node__r.Asset__r.parentId);
                              relatedProdFamily = DriveParentAsset.Product2.Family != null? DriveParentAsset.Product2.Family : '';
                              relatedProdFamily=relatedProdFamily.toUppercase();
                              relatedNicType = DriveParentAsset.Product2.Product_NIC_Type__c != null ? DriveParentAsset.Product2.Product_NIC_Type__c : '';
                              relatedApplianceModel = DriveParentAsset.Product2.Appliance_Model__c != null ?DriveParentAsset.Product2.Appliance_Model__c:'';
                              relatedProdCode = DriveParentAsset.Product2.ProductCode;
                              relatedProdCode =relatedProdCode.toUpperCase();
                              dType = dr.type__c;
                              serialNumber = dr.serial_number__c;
                              assetSerialNumber = dr.node__r.Asset__r.Serial_Number__c;
                          }
                          else{
                              relatedProdFamily = dr.node__r.Asset__r.Product2.Family != null? dr.node__r.Asset__r.Product2.Family : '';
                              relatedProdFamily=relatedProdFamily.toUppercase();
                              relatedNicType = dr.node__r.Asset__r.Product2.Product_NIC_Type__c != null ? dr.node__r.Asset__r.Product2.Product_NIC_Type__c : '';
                              relatedApplianceModel = dr.node__r.Asset__r.Product2.Appliance_Model__c != null ?dr.node__r.Asset__r.Product2.Appliance_Model__c:'';
                              relatedProdCode = dr.node__r.Asset__r.Product2.ProductCode;
                              relatedProdCode =relatedProdCode.toUpperCase();
                              dtype = dr.type__c;
                              serialNumber = dr.serial_number__c;
                              assetSerialNumber = dr.node__r.Asset__r.Serial_Number__c;
                          }
                          Spares_Mapping__c spareRec = RMASparePartsMappingHelper.returnSparePartRecord(sparesList,relatedProdFamily,relatedNicType,relatedApplianceModel);
                          sparesWrapperClassList.add(new sparesWrapperClass(rmakeyId,serialNumber,dType,assetSerialNumber,spareRec));
                      }
                  }
                  /* <--START--> SF-91  Added Logic for new Mapping Helper method*/
                  
                  for(sparesWrapperClass spw : sparesWrapperClassList){
                      ID driveprodId = spw.driveType == 'HDD'? productMap.get(spw.mappingRec.HDD__c): productMap.get(spw.mappingRec.SSD__c);
                      
                      /* < END ---- SF-91> */
                      
                      if(driveprodId != null){
                          OrderItem oli = new OrderItem();
                          oli.Assets__c = spw.AssetSN;
                          oli.orderId = ordrmaMap.get(spw.rmakeyId).Id; //oli.orderId = neworder.Id;
                          oli.RMA_Component_Type__c = spw.driveType;
                          if(pricbookEntryMap.containsKey(driveprodId)){
                              oli.PriceBookEntryId =  pricbookEntryMap.get(driveprodId);
                              oli.UnitPrice = pricbookEntryPriceMap.get(oli.PriceBookEntryId);
                              oli.Sales_Price__c = oli.UnitPrice;
                              oli.Failed_Serial_Number__c = spw.SN;
                              oli.Quantity = 1;
                              
                              orderLineItemsList.add(oli);
                          }
                          else{
                              PricebookEntry pbe = new PricebookEntry(UnitPrice=0.0,Product2Id=driveprodId,Pricebook2ID=system.label.RMA_PriceBookID, IsActive=true);
                              PricebookEntryUpsertMap.put(driveprodId+system.label.RMA_PriceBookID,pbe);//insert pbe;
                              //oli.PriceBookEntryId =  pbe.ID;
                              oli.UnitPrice = pbe.UnitPrice;
                              oli.Sales_Price__c = pbe.UnitPrice;
                              oli.Failed_Serial_Number__c = spw.SN;
                              oli.RMA_Component_Type__c = driveType;
                              oli.Quantity = 1;
                              
                              pbeOrderLineItemsList.add(oli);
                              orderLineItemsMap.put(driveprodId+system.label.RMA_PriceBookID,pbeOrderLineItemsList);
                          }
                      }
                  }
              }
              if(nodeListForDrive.size() > 0){
                  driveParentIDRMAMap.clear();
                  for(Node__c driveNodeData :[select Id,Serial_Number__c,Asset__r.Serial_Number__c,asset__r.ParentId,Asset__r.Product2.ProductCode,Asset__r.Product2.Id,Asset__r.Product2.Family,Asset__r.Product2.Product_NIC_Type__c,Asset__r.Product2.Appliance_Model__c, cpu_model__c from Node__c where Serial_Number__c IN: nodeListForDrive]){
                      driveNodeAssetIdAndOriginalAssetMap.put(driveNodeData.Id,driveNodeData);
                      if(driveNodeData.Asset__r.ParentId != Null){
                          driveNodeParentID.add(driveNodeData.Asset__r.ParentId);
                          for(Id rmakeyId : nodeRMADriveMap.keySet()){
                              if(nodeRMADriveMap.get(rmakeyId).contains(driveNodeData.Serial_Number__c)){
                                  if(driveParentIDRMAMap.isEmpty() || !driveParentIDRMAMap.containskey(rmakeyId))
                                      driveParentIDRMAMap.put(rmakeyId,new List<string>());
                                  driveParentIDRMAMap.get(rmakeyId).add(driveNodeData.Asset__r.ParentId); //Map of RMAId and AssetId
                              }
                          }
                      }
                  }
                  if(driveNodeParentID.size() > 0){
                      for(Asset driveNodeAsData :[select Id,Serial_Number__c,ParentId,Product2.ProductCode,Product2.Id,Product2.Family,Product2.Product_NIC_Type__c,Product2.Appliance_Model__c from Asset where id IN: driveNodeParentID]){
                          driveNodeparentIdAndAssetMap.put(driveNodeAsData.Id,driveNodeAsData);
                      }
                  }
                  sparesWrapperClassList.clear();
                  for(Id rmakeyId : rmaIdMap.keySet()){
                      for(Node__c dr :driveNodeAssetIdAndOriginalAssetMap.values()) {
                          if( dr.asset__r.ParentId !=Null && !driveParentIDRMAMap.isEmpty() && driveParentIDRMAMap.containskey(rmakeyId) && driveParentIDRMAMap.get(rmakeyId).contains(dr.asset__r.ParentId) && driveNodeparentIdAndAssetMap.containsKey(dr.asset__r.ParentId)){
                              Asset nodeAssetinfo=driveNodeparentIdAndAssetMap.get(dr.asset__r.ParentId);
                              relatedProdFamily=nodeAssetinfo.Product2.Family;
                              relatedProdFamily=relatedProdFamily.toUppercase();
                              relatedNicType = nodeAssetinfo.Product2.Product_NIC_Type__c != null ? nodeAssetinfo.Product2.Product_NIC_Type__c : '';
                              relatedApplianceModel = nodeAssetinfo.Product2.Appliance_Model__c != null ?nodeAssetinfo.Product2.Appliance_Model__c:'';
                              relatedProdCode =nodeAssetinfo.Product2.ProductCode;
                              serialNumber = dr.serial_number__c;
                              assetSerialNumber = dr.Asset__r.Serial_Number__c;
                          }
                          else{
                              relatedProdFamily = dr.Asset__r.Product2.Family != null? dr.Asset__r.Product2.Family : '';
                              relatedProdFamily=relatedProdFamily.toUppercase();
                              relatedNicType = dr.Asset__r.Product2.Product_NIC_Type__c != null ? dr.Asset__r.Product2.Product_NIC_Type__c : '';
                              relatedApplianceModel = dr.Asset__r.Product2.Appliance_Model__c != null ?dr.Asset__r.Product2.Appliance_Model__c:'';
                              relatedProdCode = dr.Asset__r.Product2.ProductCode;
                              serialNumber = dr.serial_number__c;
                              assetSerialNumber = dr.Asset__r.Serial_Number__c;
                              System.debug('relatedProdFamily'+relatedProdFamily);
                              System.debug('relatedNicType '+relatedNicType );
                              System.debug('relatedApplianceModel '+relatedApplianceModel );
                          }
                          //Spares_Mapping__c mapping = RMASparePartsMappingHelper.returnSparePartCode(relatedProdFamily, relatedNicType,  relatedApplianceModel); 
                          Spares_Mapping__c spareRec = RMASparePartsMappingHelper.returnSparePartRecord(sparesList,relatedProdFamily,relatedNicType,relatedApplianceModel);
                          sparesWrapperClassList.add(new sparesWrapperClass(rmakeyId,serialNumber,'',assetSerialNumber,spareRec));
                      }
                  }
                  for(sparesWrapperClass spw : sparesWrapperClassList){ //if(mapping != null){
                      
                      ID driveprodId = driveType == 'HDD'? productMap.get(spw.mappingRec.HDD__c): productMap.get(spw.mappingRec.SSD__c);
                      //ID driveprodId = driveType == 'HDD'? productMap.get(mapping.HDD__c): productMap.get(mapping.SSD__c);
                      /* < END ---- SF-91> */
                      if(driveprodId != null){
                          OrderItem oli = new OrderItem();
                          oli.assets__c = spw.AssetSN;
                          oli.orderId = ordrmaMap.get(spw.rmakeyId).Id;//neworder.Id;
                          oli.RMA_Component_Type__c = driveType;
                          if(pricbookEntryMap.containsKey(driveprodId)){
                              
                              oli.PriceBookEntryId =  pricbookEntryMap.get(driveprodId);
                              oli.UnitPrice = pricbookEntryPriceMap.get(oli.PriceBookEntryId);
                              oli.Sales_Price__c = oli.UnitPrice;
                              oli.Failed_Serial_Number__c = spw.SN; //dr.serial_Number__c;
                              oli.Quantity = 1;
                              
                              orderLineItemsList.add(oli);
                          }
                          else{
                              PricebookEntry pbe = new PricebookEntry(UnitPrice=0.0,Product2Id=driveprodId,Pricebook2ID=system.label.RMA_PriceBookID, IsActive=true);
                              PricebookEntryUpsertMap.put(driveprodId+system.label.RMA_PriceBookID,pbe);//insert pbe;
                              //oli.PriceBookEntryId =  pbe.ID;
                              oli.UnitPrice = pbe.UnitPrice;
                              oli.Sales_Price__c = pbe.UnitPrice;
                              oli.Failed_Serial_Number__c = spw.SN; //dr.serial_Number__c;
                              oli.Quantity = 1;
                              
                              pbeOrderLineItemsList.add(oli);
                              orderLineItemsMap.put(driveprodId+system.label.RMA_PriceBookID,pbeOrderLineItemsList);
                              
                          }
                      }
                  }
                  
              }
              
              Map<Id,List<String>> nodeMemoryRMAMap = new Map<Id,List<String>>();
              Map<String,List<String>> memNodeParentIDRMAMap = new Map<String,List<String>>();
              Set<Id> memNodeParentID = new Set<Id>();
              Map<ID, Node__c> memoryNodeAssetIdAndOriginalAssetMap = new Map<ID, Node__c>();
              Map<ID, asset> memNodeparentIdAndAssetMap = new Map<ID, Asset>();
              for(Id rmakeyId : rmaIdMap.keySet()){
                  List<string> tempList1 = new List<string>();
                  if(!String.isBlank(rmaIdMap.get(rmakeyId).Memory__c)){
                      if(rmaIdMap.get(rmakeyId).Memory__c == 'Other'){
                          if(!String.isBlank(rmaIdMap.get(rmakeyId).Node__c)){
                              if(rmaIdMap.get(rmakeyId).Node__c.contains(',')){
                                  tempList1 = rmaIdMap.get(rmakeyId).Node__c.split(',');
                                  nodeListForMemory = rmaIdMap.get(rmakeyId).Node__c.split(',');
                              }
                              else{
                                  tempList1.add(rmaIdMap.get(rmakeyId).Node__c);
                                  nodeListForMemory.add(rmaIdMap.get(rmakeyId).Node__c);
                              }
                              nodeMemoryRMAMap.put(rmakeyId,tempList1);
                          }
                      }
                  }
              }
              if(!nodeListForMemory.isEmpty()){
                  for(Node__c memNodeData :[select Id,Serial_Number__c,Asset__r.Serial_Number__c,asset__r.ParentId,Asset__r.Product2.ProductCode,Asset__r.Product2.Id,Asset__r.Product2.Family,Asset__r.Product2.Product_NIC_Type__c,Asset__r.Product2.Appliance_Model__c, cpu_model__c from Node__c where Serial_Number__c IN: nodeListForMemory]){
                      memoryNodeAssetIdAndOriginalAssetMap.put(memNodeData.Id,memNodeData);
                      if(memNodeData.Asset__r.ParentId != Null){
                          memNodeParentID.add(memNodeData.Asset__r.ParentId);
                          for(Id rmakeyId : nodeMemoryRMAMap.keySet()){
                              if(nodeMemoryRMAMap.get(rmakeyId).contains(memNodeData.Serial_Number__c)){
                                  if(memNodeParentIDRMAMap.isEmpty() || !memNodeParentIDRMAMap.containskey(rmakeyId))
                                      memNodeParentIDRMAMap.put(rmakeyId,new List<string>());
                                  memNodeParentIDRMAMap.get(rmakeyId).add(memNodeData.Asset__r.ParentId);
                              }
                          }
                      }
                      
                  }
              }
              if(memNodeParentID.size() > 0){
                  for(Asset MemNodeAsData :[select Id,Serial_Number__c,ParentId,Product2.ProductCode,Product2.Id,Product2.Family,Product2.Product_NIC_Type__c,Product2.Appliance_Model__c from Asset where id IN: memNodeParentID]){
                      memNodeparentIdAndAssetMap.put(MemNodeAsData.Id,MemNodeAsData);
                  }
              }
              sparesWrapperClassList.clear();
              for(Id rmakeyId : rmaIdMap.keySet()){
                  for(Node__c dr :memoryNodeAssetIdAndOriginalAssetMap.values()) {
                      if( dr.asset__r.ParentId !=Null && !memNodeParentIDRMAMap.isEmpty() && memNodeParentIDRMAMap.containskey(rmakeyId) && memNodeParentIDRMAMap.get(rmakeyId).contains(dr.asset__r.ParentId) && memNodeparentIdAndAssetMap.containsKey(dr.asset__r.ParentId)){
                          Asset nodeAssetinfo=memNodeparentIdAndAssetMap.get(dr.asset__r.ParentId);
                          relatedProdFamily=nodeAssetinfo.Product2.Family;
                          relatedProdFamily=relatedProdFamily.toUppercase();
                          relatedNicType = nodeAssetinfo.Product2.Product_NIC_Type__c != null ? nodeAssetinfo.Product2.Product_NIC_Type__c : '';
                          relatedApplianceModel = nodeAssetinfo.Product2.Appliance_Model__c != null ?nodeAssetinfo.Product2.Appliance_Model__c:'';
                          relatedProdCode =nodeAssetinfo.Product2.ProductCode;
                          serialNumber = dr.serial_number__c;
                          assetSerialNumber = dr.Asset__r.Serial_Number__c;
                      }
                      else{
                          relatedProdFamily = dr.Asset__r.Product2.Family != null? dr.Asset__r.Product2.Family : '';
                          relatedProdFamily=relatedProdFamily.toUppercase();
                          relatedNicType = dr.Asset__r.Product2.Product_NIC_Type__c != null ? dr.Asset__r.Product2.Product_NIC_Type__c : '';
                          relatedApplianceModel = dr.Asset__r.Product2.Appliance_Model__c != null ?dr.Asset__r.Product2.Appliance_Model__c:'';
                          relatedProdCode = dr.Asset__r.Product2.ProductCode;
                          serialNumber = dr.serial_number__c;
                          assetSerialNumber = dr.Asset__r.Serial_Number__c;
                      }
                      //Spares_Mapping__c mapping = RMASparePartsMappingHelper.returnSparePartCode(relatedProdFamily, relatedNicType,  relatedApplianceModel); 
                      Spares_Mapping__c spareRec = RMASparePartsMappingHelper.returnSparePartRecord(sparesList,relatedProdFamily,relatedNicType,relatedApplianceModel);
                      sparesWrapperClassList.add(new sparesWrapperClass(rmakeyId,serialNumber,'',assetSerialNumber,spareRec));
                  }
              }
              
              for(sparesWrapperClass spw : sparesWrapperClassList){ //if(mapping != null){
                  
                  ID memprodId = productMap.get(spw.mappingRec.Memory__c);
                  // ID memprodId = productMap.get(mapping.Memory__c);
                  
                  /* < END ---- SF-91> */
                  if(memprodId != null){    
                      OrderItem oli = new OrderItem();
                      oli.assets__c = spw.AssetSN;
                      oli.orderId = ordrmaMap.get(spw.rmakeyId).Id;//neworder.Id;
                      oli.RMA_Component_Type__c = 'Memory';
                      if(pricbookEntryMap.containsKey(memprodId)){
                          oli.PriceBookEntryId =  pricbookEntryMap.get(memprodId);
                          oli.UnitPrice = pricbookEntryPriceMap.get(oli.PriceBookEntryId);
                          oli.Sales_Price__c = oli.UnitPrice;
                          oli.Failed_Serial_Number__c = spw.SN;//dr.Serial_Number__c;
                          oli.Quantity = 1;
                          
                          orderLineItemsList.add(oli);
                      }
                      else{
                          PricebookEntry pbe = new PricebookEntry(UnitPrice=0.0,Product2Id=memprodId,Pricebook2ID=system.label.RMA_PriceBookID, IsActive=true);
                          PricebookEntryUpsertMap.put(memprodId+system.label.RMA_PriceBookID,pbe);//insert pbe;
                          //oli.PriceBookEntryId =  pbe.ID;
                          oli.UnitPrice = pbe.UnitPrice;
                          oli.Sales_Price__c = pbe.UnitPrice;
                          oli.Failed_Serial_Number__c = spw.SN;//dr.Serial_Number__c;
                          oli.Quantity = 1;
                          
                          pbeOrderLineItemsList.add(oli);
                          orderLineItemsMap.put(memprodId+system.label.RMA_PriceBookID,pbeOrderLineItemsList);
                      }
                  }
              }
              
              Map<Id,List<String>> memoryListRMAMap = new Map<Id,List<String>>();
              Map<String,List<String>> memoryParentIDRMAMap = new Map<String,List<String>>();
              for(Id rmakeyId : rmaIdMap.keySet()){ 
                  List<string> tempList1 = new List<string>();
                  if(!String.isBlank(rmaIdMap.get(rmakeyId).Memory__c) && rmaIdMap.get(rmakeyId).Memory__c != 'Other'){
                      if(rmaIdMap.get(rmakeyId).Memory__c.contains(',')){
                          memoryList = rmaIdMap.get(rmakeyId).Memory__c.split(',');
                          tempList1 = rmaIdMap.get(rmakeyId).Memory__c.split(',');
                      }
                      else{
                          memoryList.add(rmaIdMap.get(rmakeyId).Memory__c);
                          tempList1.add(rmaIdMap.get(rmakeyId).Memory__c);
                      }
                      memoryListRMAMap.put(rmakeyId,tempList1);
                      
                  }

              }
              Map<ID, asset> memoryParentIdAndAssetMap = new Map<ID, Asset>();
              Map<ID, Memory__c> memoryAssetIdAndOriginalAssetMap = new Map<ID, Memory__c>();
              Set<Id> memoryParentID = new Set<Id>();
              if(!memoryList.isEmpty()){
                  for(Memory__c dr :[select Id,Serial_Number__c,node__r.Asset__r.Id,node__r.Asset__r.Serial_Number__c,node__r.Asset__r.parentId,node__r.Asset__r.Product2.ProductCode,node__r.Asset__r.Product2.Id,node__r.Asset__r.Product2.Family ,node__r.Asset__r.Product2.Product_NIC_Type__c,node__r.Asset__r.Product2.Appliance_Model__c from Memory__c where Serial_Number__c IN: memoryList]){
                      memoryAssetIdAndOriginalAssetMap.put(dr.Id,dr);
                      if(dr.node__r.Asset__r.parentId != NULL  ){
                          memoryParentID.add(dr.node__r.Asset__r.parentId);
                          for(Id rmakeyId : memoryListRMAMap.keySet()){
                              if(memoryListRMAMap.get(rmakeyId).contains(dr.Serial_Number__c)){
                                  if(memoryParentIDRMAMap.isEmpty() || !memoryParentIDRMAMap.containskey(rmakeyId))
                                      memoryParentIDRMAMap.put(rmakeyId,new List<string>());
                                  memoryParentIDRMAMap.get(rmakeyId).add(dr.node__r.Asset__r.parentId);
                              }
                          }
                      }
                  }
              }
              if(memoryParentID.size() > 0 ){
                  for(Asset parentAsData :[select Id,Serial_Number__c,ParentId,Product2.ProductCode,Product2.Id,Product2.Family,Product2.Product_NIC_Type__c,Product2.Appliance_Model__c from Asset where Id IN: memoryParentID]){
                      memoryParentIdAndAssetMap.put(parentAsData.Id,parentAsData);
                  }
              }
              sparesWrapperClassList.clear();
              for(Id rmakeyId : rmaIdMap.keySet()){ 
                  for(Memory__c dr :memoryAssetIdAndOriginalAssetMap.values()){
                      if(dr.node__r.Asset__r.parentId !=NULL && !memoryParentIDRMAMap.isEmpty() && memoryParentIDRMAMap.containskey(rmakeyId) && memoryParentIDRMAMap.get(rmakeyId).contains(dr.node__r.Asset__r.parentId) && memoryParentIdAndAssetMap.containsKey(dr.node__r.Asset__r.parentId) ){
                          Asset memoryParentAsset= memoryParentIdAndAssetMap.get(dr.node__r.Asset__r.parentId);
                          relatedProdFamily = memoryParentAsset.Product2.Family != null? memoryParentAsset.Product2.Family : '';
                          relatedProdFamily=relatedProdFamily.toUppercase();
                          relatedNicType = memoryParentAsset.Product2.Product_NIC_Type__c != null ? memoryParentAsset.Product2.Product_NIC_Type__c : '';
                          relatedApplianceModel = memoryParentAsset.Product2.Appliance_Model__c != null ?memoryParentAsset.Product2.Appliance_Model__c:'';
                          relatedProdCode = memoryParentAsset.Product2.ProductCode;
                          relatedProdCode =relatedProdCode.toUpperCase();
                          serialNumber = dr.serial_number__c;
                          assetSerialNumber = dr.node__r.Asset__r.Serial_Number__c;
                      }
                      else{
                          relatedProdFamily = dr.node__r.Asset__r.Product2.Family != null? dr.node__r.Asset__r.Product2.Family : '';
                          relatedProdFamily=relatedProdFamily.toUppercase();
                          relatedNicType = dr.node__r.Asset__r.Product2.Product_NIC_Type__c != null ? dr.node__r.Asset__r.Product2.Product_NIC_Type__c : '';
                          relatedApplianceModel = dr.node__r.Asset__r.Product2.Appliance_Model__c != null ?dr.node__r.Asset__r.Product2.Appliance_Model__c:'';
                          relatedProdCode = dr.node__r.Asset__r.Product2.ProductCode;
                          relatedProdCode =relatedProdCode.toUpperCase();
                          serialNumber = dr.serial_number__c;
                          assetSerialNumber = dr.node__r.Asset__r.Serial_Number__c;
                      }
                      /* <--START--> SF-91  Added Logic for new Mapping Helper method*/ 
                      //mapping = RMASparePartsMappingHelper.returnSparePartCode(relatedProdFamily, relatedNicType,  relatedApplianceModel); 
                      Spares_Mapping__c spareRec = RMASparePartsMappingHelper.returnSparePartRecord(sparesList,relatedProdFamily,relatedNicType,relatedApplianceModel);
                      sparesWrapperClassList.add(new sparesWrapperClass(rmakeyId,serialNumber,'',assetSerialNumber,spareRec));
                  }
              }
              
              for(sparesWrapperClass spw : sparesWrapperClassList){ //if(mapping != null){
                  
                  ID memprodId = productMap.get(spw.mappingRec.Memory__c);
                  //ID memprodId = productMap.get(mapping.Memory__c);
                  
                  /* < END ---- SF-91> */
                  if(memprodId != null){
                      OrderItem oli = new OrderItem();
                      oli.assets__c = spw.AssetSN;
                      oli.orderId = ordrmaMap.get(spw.rmakeyId).Id;//neworder.Id;
                      oli.RMA_Component_Type__c = 'Memory';
                      if(pricbookEntryMap.containsKey(memprodId)){
                          oli.PriceBookEntryId =  pricbookEntryMap.get(memprodId);
                          oli.UnitPrice = pricbookEntryPriceMap.get(oli.PriceBookEntryId);
                          oli.Sales_Price__c = oli.UnitPrice;
                          oli.Failed_Serial_Number__c = spw.SN;//dr.serial_number__c;
                          oli.Quantity = 1;
                          
                          orderLineItemsList.add(oli);
                      }
                      else{
                          PricebookEntry pbe = new PricebookEntry(UnitPrice=0.0,Product2Id=memprodId,Pricebook2ID=system.label.RMA_PriceBookID, IsActive=true);
                          PricebookEntryUpsertMap.put(memprodId+system.label.RMA_PriceBookID,pbe);//insert pbe;
                          //oli.PriceBookEntryId =  pbe.ID;
                          oli.UnitPrice = pbe.UnitPrice;
                          oli.Sales_Price__c = pbe.UnitPrice;
                          oli.Failed_Serial_Number__c = spw.SN;//dr.serial_number__c;
                          oli.Quantity = 1;
                          
                          pbeOrderLineItemsList.add(oli);
                          orderLineItemsMap.put(memprodId+system.label.RMA_PriceBookID,pbeOrderLineItemsList);
                      }
                  }
              }
              
              
              Map<string,List<string>> AssetListForPSURMAMap = new Map<string,List<string>>();
              for(Id rmakeyId : rmaIdMap.keySet()){ 
                  List<string> tempList1 = new List<string>();
                  if(!String.isBlank(rmaIdMap.get(rmakeyId).Power_Supply__c)){
                      if(rmaIdMap.get(rmakeyId).Power_Supply__c == 'Other'){
                          if(!String.isBlank(rmaIdMap.get(rmakeyId).Appliance__c)){
                              if(rmaIdMap.get(rmakeyId).Appliance__c.contains(',')){
                                  AssetListForPSU = rmaIdMap.get(rmakeyId).Appliance__c.split(',');
                                  tempList1 = rmaIdMap.get(rmakeyId).Appliance__c.split(',');
                              }
                              else{
                                  AssetListForPSU.add(rmaIdMap.get(rmakeyId).Appliance__c);
                                  tempList1.add(rmaIdMap.get(rmakeyId).Appliance__c);
                              }
                              AssetListForPSURMAMap.put(rmakeyId,tempList1);
                              
                          }
                      }
                  }
              }
              sparesWrapperClassList.clear();
              if(!AssetListForPSU.isEmpty()){
                  for(Asset dr :[select id,serial_number__c,Product2.Id,product2.Family,product2.Product_NIC_Type__c, product2.Appliance_Model__c,product2.ProductCode from Asset where  Serial_Number__c IN: AssetListForPSU]){
                      for(Id rmakeyId : AssetListForPSURMAMap.keySet()){
                          if(AssetListForPSURMAMap.get(rmakeyId).contains(dr.serial_number__c)){
                              relatedProdFamily = dr.Product2.Family != null? dr.Product2.Family : '';
                              relatedProdFamily=relatedProdFamily.toUppercase();
                              relatedNicType = dr.Product2.Product_NIC_Type__c != null ? dr.Product2.Product_NIC_Type__c : '';
                              relatedApplianceModel = dr.Product2.Appliance_Model__c != null ?dr.Product2.Appliance_Model__c:'';
                              relatedProdCode = dr.Product2.ProductCode;
                              serialNumber = dr.serial_number__c;
                              /* <--START--> SF-91  Added Logic for new Mapping Helper method*/
                              
                              //mapping = RMASparePartsMappingHelper.returnSparePartCode(relatedProdFamily, relatedNicType,  relatedApplianceModel); 
                              Spares_Mapping__c spareRec = RMASparePartsMappingHelper.returnSparePartRecord(sparesList,relatedProdFamily,relatedNicType,relatedApplianceModel);
                              sparesWrapperClassList.add(new sparesWrapperClass(rmakeyId,serialNumber,'',serialNumber,spareRec));
                          }
                      }
                  }
              }
              for(sparesWrapperClass spw : sparesWrapperClassList){ //if(mapping != null){
                  
                  ID psuprodId = productMap.get(spw.mappingRec.PSU__c);
                  //ID psuprodId = productMap.get(mapping.PSU__c);
                  /* < END ---- SF-91> */
                  if(psuprodId != null){
                      OrderItem oli = new OrderItem();
                      oli.assets__c = spw.SN;
                      oli.orderId = ordrmaMap.get(spw.rmakeyId).Id;//neworder.Id;
                      oli.RMA_Component_Type__c = 'PSU';
                      if(pricbookEntryMap.containsKey(psuprodId)){
                          oli.PriceBookEntryId =  pricbookEntryMap.get(psuprodId);
                          oli.UnitPrice = pricbookEntryPriceMap.get(oli.PriceBookEntryId);
                          oli.Sales_Price__c = oli.UnitPrice;
                          oli.Failed_Serial_Number__c = spw.SN;//dr.serial_number__c;
                          oli.Quantity = 1;
                          
                          orderLineItemsList.add(oli);
                      }
                      else{
                          PricebookEntry pbe = new PricebookEntry(UnitPrice=0.0,Product2Id=psuprodId,Pricebook2ID=system.label.RMA_PriceBookID, IsActive=true);
                          if(PricebookEntryUpsertMap.isEmpty() || !PricebookEntryUpsertMap.containskey(psuprodId+system.label.RMA_PriceBookID))
                              PricebookEntryUpsertMap.put(psuprodId+system.label.RMA_PriceBookID,pbe);//insert pbe;
                          // oli.PriceBookEntryId =  pbe.ID;
                          oli.UnitPrice = pbe.UnitPrice;
                          oli.Sales_Price__c = pbe.UnitPrice;
                          oli.Failed_Serial_Number__c = spw.SN;//dr.serial_number__c;
                          oli.Quantity = 1;
                          
                          pbeOrderLineItemsList.add(oli);
                          orderLineItemsMap.put(psuprodId+system.label.RMA_PriceBookID,pbeOrderLineItemsList);
                      }
                  }
              }
              
              Map<string,List<string>> psuListRMAMap = new Map<string,List<string>>();
              for(Id rmakeyId : rmaIdMap.keySet()){ 
                  List<string> tempList1 = new List<string>();
                  if(!String.isBlank(rmaIdMap.get(rmakeyId).Power_Supply__c) && rmaIdMap.get(rmakeyId).Power_Supply__c != 'Other'){
                      if(rmaIdMap.get(rmakeyId).Power_Supply__c.contains(',')){
                          tempList1 = rmaIdMap.get(rmakeyId).Power_Supply__c.split(',');
                          psuList = rmaIdMap.get(rmakeyId).Power_Supply__c.split(',');
                      }
                      else{
                          tempList1.add(rmaIdMap.get(rmakeyId).Power_Supply__c);
                          psuList.add(rmaIdMap.get(rmakeyId).Power_Supply__c);
                      }
                      psuListRMAMap.put(rmakeyId,tempList1);
                  }
              }
              sparesWrapperClassList.clear();
              if(!psuList.isEmpty()){
                  for(Power_Supply__c dr :[select id,Serial_Number__c,Asset__r.Serial_Number__c,Asset__r.Product2.ProductCode,Asset__r.Product2.Id,Asset__r.Product2.Family,Asset__r.Product2.Product_NIC_Type__c,Asset__r.Product2.Appliance_Model__c from Power_Supply__c where Serial_Number__c IN: psuList]){
                      for(Id rmakeyId : psuListRMAMap.keySet()){
                          if(psuListRMAMap.get(rmakeyId).contains(dr.Serial_Number__c)){
                              relatedProdFamily = dr.Asset__r.Product2.Family != null? dr.Asset__r.Product2.Family : '';
                              relatedProdFamily=relatedProdFamily.toUppercase();
                              relatedNicType = dr.Asset__r.Product2.Product_NIC_Type__c != null ? dr.Asset__r.Product2.Product_NIC_Type__c : '';
                              relatedApplianceModel = dr.Asset__r.Product2.Appliance_Model__c != null ?dr.Asset__r.Product2.Appliance_Model__c:'';
                              relatedProdCode = dr.Asset__r.Product2.ProductCode;
                              serialNumber = dr.serial_number__c;
                              assetSerialNumber = dr.Asset__r.Serial_Number__c;
                              /* <--START--> SF-91  Added Logic for new Mapping Helper method*/
                              
                              //mapping = RMASparePartsMappingHelper.returnSparePartCode(relatedProdFamily, relatedNicType,  relatedApplianceModel); 
                              Spares_Mapping__c spareRec = RMASparePartsMappingHelper.returnSparePartRecord(sparesList,relatedProdFamily,relatedNicType,relatedApplianceModel);
                              sparesWrapperClassList.add(new sparesWrapperClass(rmakeyId,serialNumber,'',assetSerialNumber,spareRec));
                          }
                      }
                  }
              }
              for(sparesWrapperClass spw : sparesWrapperClassList){ //if(mapping != null){
                  
                  ID psuprodId = productMap.get(spw.mappingRec.PSU__c);
                  //ID psuprodId = productMap.get(mapping.PSU__c);
                  /* < END ---- SF-91> */
                  if(psuprodId != null){
                      OrderItem oli = new OrderItem();
                      oli.assets__c = spw.AssetSN;
                      oli.orderId = ordrmaMap.get(spw.rmakeyId).Id;//neworder.Id;
                      oli.RMA_Component_Type__c = 'PSU';
                      if(pricbookEntryMap.containsKey(psuprodId)){
                          oli.PriceBookEntryId =  pricbookEntryMap.get(psuprodId);
                          oli.UnitPrice = pricbookEntryPriceMap.get(oli.PriceBookEntryId);
                          oli.Sales_Price__c = oli.UnitPrice;
                          oli.Failed_Serial_Number__c = spw.SN;//dr.serial_number__c;
                          oli.Quantity = 1;
                          
                          orderLineItemsList.add(oli);
                      }
                      else{
                          PricebookEntry pbe = new PricebookEntry(UnitPrice=0.0,Product2Id=psuprodId,Pricebook2ID=system.label.RMA_PriceBookID, IsActive=true);
                          if(PricebookEntryUpsertMap.isEmpty() || !PricebookEntryUpsertMap.containskey(psuprodId+system.label.RMA_PriceBookID))
                              PricebookEntryUpsertMap.put(psuprodId+system.label.RMA_PriceBookID,pbe);//insert pbe;
                          //oli.PriceBookEntryId =  pbe.ID;
                          oli.UnitPrice = pbe.UnitPrice;
                          oli.Sales_Price__c = pbe.UnitPrice;
                          oli.Failed_Serial_Number__c = spw.SN;//dr.serial_number__c;
                          oli.Quantity = 1;
         
                          pbeOrderLineItemsList.add(oli);
                          orderLineItemsMap.put(psuprodId+system.label.RMA_PriceBookID,pbeOrderLineItemsList);
                      }
                  }
              }
              
              Map<string,List<string>> AssetListForchassisRMAMap = new Map<string,List<string>>();
              for(Id rmakeyId : rmaIdMap.keySet()){
                  List<string> tempList1 = new List<string>();
                  if(!String.isBlank(rmaIdMap.get(rmakeyId).Chassis__c)){
                      if(rmaIdMap.get(rmakeyId).Chassis__c == 'Other'){
                          if(!String.isBlank(rmaIdMap.get(rmakeyId).Appliance__c)){
                              if(rmaIdMap.get(rmakeyId).Appliance__c.contains(',')){
                                  tempList1 = rmaIdMap.get(rmakeyId).Appliance__c.split(',');
                                  AssetListForchassis = rmaIdMap.get(rmakeyId).Appliance__c.split(',');
                              }
                              else{
                                  tempList1.add(rmaIdMap.get(rmakeyId).Appliance__c);
                                  AssetListForchassis.add(rmaIdMap.get(rmakeyId).Appliance__c);
                              }
                              AssetListForchassisRMAMap.put(rmakeyId,tempList1);
                          }
                      }
                  }
              }
              sparesWrapperClassList.clear();
              if(!AssetListForchassis.isEmpty()){
                  for(Asset dr :[select id,serial_number__c,Product2.Id,product2.Family,product2.Product_NIC_Type__c, product2.Appliance_Model__c,product2.ProductCode from Asset where  Serial_Number__c IN: AssetListForchassis]){
                      for(Id rmakeyId : AssetListForchassisRMAMap.keySet()){
                          if(AssetListForchassisRMAMap.get(rmakeyId).contains(dr.Serial_Number__c)){
                              relatedProdFamily = dr.Product2.Family != null? dr.Product2.Family : '';
                              relatedProdFamily=relatedProdFamily.toUppercase();
                              relatedNicType = dr.Product2.Product_NIC_Type__c != null ? dr.Product2.Product_NIC_Type__c : '';
                              relatedApplianceModel = dr.Product2.Appliance_Model__c != null ?dr.Product2.Appliance_Model__c:'';
                              relatedProdCode = dr.Product2.ProductCode;
                              serialNumber = dr.serial_number__c;
                              /* <--START--> SF-91  Added Logic for new Mapping Helper method*/
                              
                              //mapping = RMASparePartsMappingHelper.returnSparePartCode(relatedProdFamily, relatedNicType,  relatedApplianceModel);
                              Spares_Mapping__c spareRec = RMASparePartsMappingHelper.returnSparePartRecord(sparesList,relatedProdFamily,relatedNicType,relatedApplianceModel);
                              sparesWrapperClassList.add(new sparesWrapperClass(rmakeyId,serialNumber,'','',spareRec));
                          }
                      }
                  }
              }
              for(sparesWrapperClass spw : sparesWrapperClassList){ //if(mapping != null){
                  
                  ID chassisprodId = productMap.get(spw.mappingRec.Chassis__c);
                  //ID chassisprodId = productMap.get(mapping.Chassis__c);
                  /* < END ---- SF-91> */
                  if(chassisprodId != null){
                      OrderItem oli = new OrderItem();
                      oli.assets__c = spw.SN;
                      oli.orderId = ordrmaMap.get(spw.rmakeyId).Id;//neworder.Id;
                      oli.RMA_Component_Type__c = 'Chassis';
                      if(pricbookEntryMap.containsKey(chassisprodId)){
                          oli.PriceBookEntryId =  pricbookEntryMap.get(chassisprodId);
                          oli.UnitPrice = pricbookEntryPriceMap.get(oli.PriceBookEntryId);
                          oli.Sales_Price__c = oli.UnitPrice;
                          oli.Failed_Serial_Number__c = spw.SN;//dr.serial_number__c;
                          oli.Quantity = 1;
                          
                          orderLineItemsList.add(oli);
                      }
                      else{
                          PricebookEntry pbe = new PricebookEntry(UnitPrice=0.0,Product2Id=chassisprodId,Pricebook2ID=system.label.RMA_PriceBookID, IsActive=true);
                          if(PricebookEntryUpsertMap.isEmpty() || PricebookEntryUpsertMap.containskey(chassisprodId+system.label.RMA_PriceBookID))
                              PricebookEntryUpsertMap.put(chassisprodId+system.label.RMA_PriceBookID,pbe);//insert pbe;
                          //oli.PriceBookEntryId =  pbe.ID;
                          oli.UnitPrice = pbe.UnitPrice;
                          oli.Sales_Price__c = pbe.UnitPrice;
                          oli.Failed_Serial_Number__c = spw.SN;//dr.serial_number__c;
                          oli.Quantity = 1;
                          
                          pbeOrderLineItemsList.add(oli);
                          orderLineItemsMap.put(chassisprodId+system.label.RMA_PriceBookID,pbeOrderLineItemsList);
                      }
                  }
              }
              
              Map<string,List<string>> chassisListRMAMap = new Map<string,List<string>>();
              for(Id rmakeyId : rmaIdMap.keySet()){
                  List<string> tempList1 = new List<string>();
                  if(!String.isBlank(rmaIdMap.get(rmakeyId).Chassis__c) && rmaIdMap.get(rmakeyId).Chassis__c != 'Other'){
                      if(rmaIdMap.get(rmakeyId).Chassis__c.contains(',')){
                          tempList1 = rmaIdMap.get(rmakeyId).Chassis__c.split(',');
                          chassisList = rmaIdMap.get(rmakeyId).Chassis__c.split(',');
                      }
                      else{
                          tempList1.add(rmaIdMap.get(rmakeyId).Chassis__c);
                          chassisList.add(rmaIdMap.get(rmakeyId).Chassis__c);
                      }
                      chassisListRMAMap.put(rmakeyId,tempList1);
                  }
              }
              sparesWrapperClassList.clear();
              if(!chassisList.isEmpty()){
                  for(Chassis__c dr :[select id,Serial_Number__c,Asset__r.serial_number__c, Asset__r.Product2.ProductCode,Asset__r.Product2.Id,Asset__r.Product2.Family,Asset__r.Product2.Product_NIC_Type__c,Asset__r.Product2.Appliance_Model__c from Chassis__c where Serial_Number__c IN: chassisList]){
                      for(Id rmakeyId :chassisListRMAMap.keySet()){
                          if(chassisListRMAMap.get(rmakeyId).contains(dr.serial_number__c)){
                              relatedProdFamily = dr.Asset__r.Product2.Family != null? dr.Asset__r.Product2.Family : '';
                              relatedProdFamily=relatedProdFamily.toUppercase();
                              relatedNicType = dr.Asset__r.Product2.Product_NIC_Type__c != null ? dr.Asset__r.Product2.Product_NIC_Type__c : '';
                              relatedApplianceModel = dr.Asset__r.Product2.Appliance_Model__c != null ?dr.Asset__r.Product2.Appliance_Model__c:'';
                              
                              relatedProdCode = dr.Asset__r.Product2.ProductCode;
                              serialNumber = dr.serial_number__c;
                              assetSerialNumber = dr.Asset__r.serial_number__c;
                              /* <--START--> SF-91  Added Logic for new Mapping Helper method*/
                              
                              //mapping = RMASparePartsMappingHelper.returnSparePartCode(relatedProdFamily, relatedNicType,  relatedApplianceModel); 
                              Spares_Mapping__c spareRec = RMASparePartsMappingHelper.returnSparePartRecord(sparesList,relatedProdFamily,relatedNicType,relatedApplianceModel);
                              sparesWrapperClassList.add(new sparesWrapperClass(rmakeyId,serialNumber,'',assetSerialNumber,spareRec));
                          }
                      }
                  }
              }
              for(sparesWrapperClass spw : sparesWrapperClassList){ //if(mapping != null){
                  
                  ID chassisprodId = productMap.get(spw.mappingRec.Chassis__c);
                  //ID chassisprodId = productMap.get(mapping.Chassis__c);
                  /* < END ---- SF-91> */
                  if(chassisprodId != null){
                      OrderItem oli = new OrderItem();
                      oli.assets__c = spw.AssetSN;
                      oli.orderId = ordrmaMap.get(spw.rmakeyId).Id;//neworder.Id;
                      oli.RMA_Component_Type__c = 'Chassis';
                      if(pricbookEntryMap.containsKey(chassisprodId)){
                          oli.PriceBookEntryId =  pricbookEntryMap.get(chassisprodId);
                          oli.UnitPrice = pricbookEntryPriceMap.get(oli.PriceBookEntryId);
                          oli.Sales_Price__c = oli.UnitPrice;
                          oli.Failed_Serial_Number__c = spw.SN;//dr.serial_number__c;
                          oli.Quantity = 1;
                          
                          orderLineItemsList.add(oli);
                      }
                      else{
                          PricebookEntry pbe = new PricebookEntry(UnitPrice=0.0,Product2Id=chassisprodId,Pricebook2ID=system.label.RMA_PriceBookID, IsActive=true);
                          if(PricebookEntryUpsertMap.isEmpty() || PricebookEntryUpsertMap.containskey(chassisprodId+system.label.RMA_PriceBookID))
                              PricebookEntryUpsertMap.put(chassisprodId+system.label.RMA_PriceBookID,pbe);//insert pbe;
                          //i.PriceBookEntryId =  pbe.ID;
                          oli.UnitPrice = pbe.UnitPrice;
                          oli.Sales_Price__c = pbe.UnitPrice;
                          oli.Failed_Serial_Number__c = spw.SN;//dr.serial_number__c;
                          oli.Quantity = 1;
                          
                          pbeOrderLineItemsList.add(oli);
                          orderLineItemsMap.put(chassisprodId+system.label.RMA_PriceBookID,pbeOrderLineItemsList);
                      }
                  }
              }
              Map<string,List<string>> nodeListRMAMap = new Map<string,List<string>>();
              for(Id rmakeyId : rmaIdMap.keySet()){ 
                  List<string> tempList1 = new List<string>();
                  if(!String.isBlank(rmaIdMap.get(rmakeyId).Node__c) && rmaIdMap.get(rmakeyId).Node_Quantity__c != null){
                      if(rmaIdMap.get(rmakeyId).Node__c.contains(',')){
                          tempList1 = rmaIdMap.get(rmakeyId).Node__c.split(',');
                          nodeList = rmaIdMap.get(rmakeyId).Node__c.split(',');
                      }
                      else{
                          tempList1.add(rmaIdMap.get(rmakeyId).Node__c);
                          nodeList.add(rmaIdMap.get(rmakeyId).Node__c);
                      }
                      nodeListRMAMap.put(rmakeyId,tempList1);
                  }
              }
              //SF-6769 Introduced new CPU Model
              Map<string,List<string>> nodeParentIDRMAMap = new Map<string,List<string>>();
              Map<String, String> skuReplacementForNewCPUModel = new Map<String, String>();
              //Added for SF-7053: UPdate RMA process to handle parent Asset
              Map<ID, asset> NodeparentIdAndAssetMap = new Map<ID, Asset>();
              Map<ID, Node__c> NodeAssetIdAndOriginalAssetMap = new Map<ID, Node__c>();
              Set<Id> nodeParentID= new Set<Id>();
              //ring relatedProdFamily;
              //ring  relatedNicType;
              //ring  relatedApplianceModel;
              //ring  relatedProdCode;
              String CPUModel;
              for(RMA_Spares_Replacement__mdt replacementSKUs: [Select Label, CPU_Model__c, Replacement_SKU__c from RMA_Spares_Replacement__mdt]){
                  skuReplacementForNewCPUModel.put(replacementSKUs.Label+'_'+replacementSKUs.CPU_Model__c, replacementSKUs.Replacement_SKU__c);
              }
              if(!nodeList.isEmpty()){
                  for(Node__c nodedata :[select Id,Serial_Number__c,Asset__r.Serial_Number__c,Asset__r.Product_Type__c,asset__r.ParentId,Asset__r.Product2.ProductCode,Asset__r.Product2.Id,Asset__r.Product2.Family,Asset__r.Product2.Product_NIC_Type__c,Asset__r.Product2.Appliance_Model__c, cpu_model__c from Node__c where Serial_Number__c IN: nodeList]){
                      NodeAssetIdAndOriginalAssetMap.put(nodedata.Id,nodedata);
                      if(nodedata.Asset__r.ParentId != Null){
                          nodeParentID.add(nodedata.Asset__r.ParentId);
                          for(Id rmakeyId : nodeListRMAMap.keySet()){
                              if(nodeListRMAMap.get(rmakeyId).contains(nodedata.Serial_Number__c)){
                                  if(nodeParentIDRMAMap.isEmpty() || !nodeParentIDRMAMap.containskey(rmakeyId))
                                      nodeParentIDRMAMap.put(rmakeyId,new List<string>());
                                  nodeParentIDRMAMap.get(rmakeyId).add(nodedata.Asset__r.ParentId); //Map of RMAId and AssetId
                              }
                          }
                      }
                  }
              }
              if(nodeParentID.size() > 0){
                  system.debug('******'+nodeParentID);
                  for(Asset AsData :[select Id,Serial_Number__c,ParentId,Product2.ProductCode,Product2.Id,Product2.Family,Product2.Product_NIC_Type__c,Product2.Appliance_Model__c from Asset where id IN: nodeParentID]){
                      NodeparentIdAndAssetMap.put(AsData.Id,AsData);
                  }
              }
              sparesWrapperClassList.clear();
              // edited to check parentId
              for(Id rmakeyId : rmaIdMap.keySet()){ 
                  for(Node__c dr :NodeAssetIdAndOriginalAssetMap.values()){
                      system.debug('******1'+dr);
                      if( dr.asset__r.ParentId !=Null && nodeParentIDRMAMap.get(rmakeyId).contains(dr.Asset__r.ParentId) && NodeparentIdAndAssetMap.containsKey(dr.asset__r.ParentId)){
                          system.debug('******2'+dr);
                          Asset nodeAssetinfo=NodeparentIdAndAssetMap.get(dr.asset__r.ParentId);
                          relatedProdFamily=nodeAssetinfo.Product2.Family;
                          relatedProdFamily=relatedProdFamily.toUppercase();
                          relatedNicType = nodeAssetinfo.Product2.Product_NIC_Type__c != null ? nodeAssetinfo.Product2.Product_NIC_Type__c : '';
                          relatedApplianceModel = nodeAssetinfo.Product2.Appliance_Model__c != null ?nodeAssetinfo.Product2.Appliance_Model__c:'';
                          relatedProdCode =nodeAssetinfo.Product2.ProductCode;
                          CPUModel = dr.cpu_model__c;
                          assetSerialNumber = dr.Asset__r.serial_number__c;
                          if(dr.Asset__r.Product_Type__c == 'Spares'  )
                              serialNumber = dr.serial_number__c;
                              
                      }
                      else{
                          system.debug('******3'+dr);
                          relatedProdFamily = dr.Asset__r.Product2.Family != null? dr.Asset__r.Product2.Family : '';
                          relatedProdFamily=relatedProdFamily.toUppercase();
                          relatedNicType = dr.Asset__r.Product2.Product_NIC_Type__c != null ? dr.Asset__r.Product2.Product_NIC_Type__c : '';
                          relatedApplianceModel = dr.Asset__r.Product2.Appliance_Model__c != null ?dr.Asset__r.Product2.Appliance_Model__c:'';
                          relatedProdCode = dr.Asset__r.Product2.ProductCode;
                          serialNumber = dr.serial_number__c;
                          CPUModel = dr.cpu_model__c;
                          assetSerialNumber = dr.Asset__r.serial_number__c;
                      }
                      /* <--START--> SF-91  Added Logic for new Mapping Helper method*/
                      
                      //mapping = RMASparePartsMappingHelper.returnSparePartCode(relatedProdFamily, relatedNicType,  relatedApplianceModel); 
                      system.debug('******'+relatedProdFamily+ '*'+ relatedNicType+ '**'+ serialNumber+'*' + relatedApplianceModel);
                      Spares_Mapping__c spareRec = RMASparePartsMappingHelper.returnSparePartRecord(sparesList,relatedProdFamily,relatedNicType,relatedApplianceModel);
                      system.debug('******'+ spareRec);
                      sparesWrapperClassList.add(new sparesWrapperClass(rmakeyId,serialNumber,'',assetSerialNumber,spareRec));
                  }
              }
              
              for(sparesWrapperClass spw : sparesWrapperClassList){ //if(mapping != null){
                  string  nodeName = spw.mappingRec.Node__c;
                  //string  nodeName = mapping.Node__c;
                  if(skuReplacementForNewCPUModel.containsKey(nodeName+'_'+CPUModel)){
                      nodeName = skuReplacementForNewCPUModel.get(nodeName+'_'+CPUModel);
                  }
                  ID nodeprodId = productMap.get(nodeName);
                  system.debug('nodeprodId'+nodeprodId);
                  /* < END ---- SF-91> */
                  if(nodeprodId != null){
                      OrderItem oli = new OrderItem();
                      oli.assets__c = spw.AssetSN;
                      oli.orderId = ordrmaMap.get(spw.rmakeyId).Id;//neworder.Id;
                      oli.RMA_Component_Type__c = 'Node';
                      for(id ids : pricbookEntryMap.KeySet()){
                          system.debug('key=='+pricbookEntryMap.get(ids));
                      }
                      if(pricbookEntryMap.containsKey(nodeprodId)){
                          oli.PriceBookEntryId =  pricbookEntryMap.get(nodeprodId);
                          oli.UnitPrice = pricbookEntryPriceMap.get(oli.PriceBookEntryId);
                          oli.Sales_Price__c = oli.UnitPrice;
                          oli.Failed_Serial_Number__c = spw.SN;//dr.serial_number__c;
                          
                          oli.Quantity = 1;
                          
                          orderLineItemsList.add(oli);
                      }
                      else{
                          PricebookEntry pbe = new PricebookEntry(UnitPrice=0.0,Product2Id=nodeprodId,Pricebook2ID=system.label.RMA_PriceBookID, IsActive=true);
                          if(PricebookEntryUpsertMap.isEmpty() || PricebookEntryUpsertMap.containskey(nodeprodId+system.label.RMA_PriceBookID))
                              PricebookEntryUpsertMap.put(nodeprodId+system.label.RMA_PriceBookID,pbe);//insert pbe; 
                          //oli.PriceBookEntryId =  pbe.ID;
                          oli.UnitPrice = pbe.UnitPrice;
                          oli.Sales_Price__c = pbe.UnitPrice;
                          oli.Failed_Serial_Number__c = spw.SN;//dr.serial_number__c;
                          oli.Quantity = 1;
                          
                          pbeOrderLineItemsList.add(oli);
                          orderLineItemsMap.put(nodeprodId+system.label.RMA_PriceBookID,pbeOrderLineItemsList);
                          
                      }
                  }
              }
              
              Map<string,List<string>> nicListRMAMap = new Map<string,List<string>>();
              for(Id rmakeyId : rmaIdMap.keySet()){  
                  List<string> tempList1 = new List<string>();
                  if(!String.isBlank(rmaIdMap.get(rmakeyId).NIC__c)){
                      if(rmaIdMap.get(rmakeyId).NIC__c.contains(',')){
                          tempList1 = rmaIdMap.get(rmakeyId).NIC__c.split(',');
                          nicList = rmaIdMap.get(rmakeyId).NIC__c.split(',');
                      }
                      else{
                          tempList1.add(rmaIdMap.get(rmakeyId).NIC__c);
                          nicList.add(rmaIdMap.get(rmakeyId).NIC__c);
                      }
                      nicListRMAMap.put(rmakeyId,tempList1);
                  }
              }
              system.debug('@@ nicList '+nicList);
              system.debug('@@ nicListRMAMap '+nicListRMAMap);
              sparesWrapperClassList.clear();
              if(!nicList.isEmpty()){
                  for(NIC__c dr :[select id,Serial_Number__c,node__r.Asset__r.Serial_Number__c, node__r.Asset__r.Product2.ProductCode,node__r.Asset__r.Product2.Id,node__r.Asset__r.Product2.Family,node__r.Asset__r.Product2.Product_NIC_Type__c,node__r.Asset__r.Product2.Appliance_Model__c,Asset__r.Product2.ProductCode from NIC__c where Serial_Number__c IN: nicList]){
                      for(Id rmakeyId : nicListRMAMap.keySet()){ 
                          if(nicListRMAMap.get(rmakeyId).contains(dr.serial_number__c)){
                              relatedProdFamily = dr.node__r.Asset__r.Product2.Family != null? dr.node__r.Asset__r.Product2.Family : '';
                              relatedProdFamily=relatedProdFamily.toUppercase();
                              relatedNicType = dr.node__r.Asset__r.Product2.Product_NIC_Type__c != null ? dr.node__r.Asset__r.Product2.Product_NIC_Type__c : '';
                              relatedApplianceModel = dr.node__r.Asset__r.Product2.Appliance_Model__c != null ?dr.node__r.Asset__r.Product2.Appliance_Model__c:'';
                              
                              relatedProdCode = dr.Asset__r.Product2.ProductCode;
                              serialNumber= dr.Serial_Number__c;
                              assetSerialNumber = dr.node__r.Asset__r.serial_number__c;
                              //mapping = RMASparePartsMappingHelper.returnSparePartCode(relatedProdFamily, relatedNicType,  relatedApplianceModel); 
                              Spares_Mapping__c spareRec = RMASparePartsMappingHelper.returnSparePartRecord(sparesList,relatedProdFamily,relatedNicType,relatedApplianceModel);
                              sparesWrapperClassList.add(new sparesWrapperClass(rmakeyId,serialNumber,'',assetSerialNumber,spareRec));
                          }
                      }
                  }
              }
              
              for(sparesWrapperClass spw : sparesWrapperClassList){ //if(mapping != null){
                  ID nicprodId = productMap.get(spw.mappingRec.NIC__c);
                  //ID nicprodId = productMap.get(mapping.NIC__c);
                  /* < END ---- SF-91> */
                  if(nicprodId != null){
                      OrderItem oli = new OrderItem();
                      oli.assets__c = spw.AssetSN;
                      oli.orderId = ordrmaMap.get(spw.rmakeyId).Id;//neworder.Id;
                      oli.RMA_Component_Type__c = 'NIC';
                      if(pricbookEntryMap.containsKey(nicprodId)){
                          oli.PriceBookEntryId =  pricbookEntryMap.get(nicprodId);
                          oli.UnitPrice = pricbookEntryPriceMap.get(oli.PriceBookEntryId);
                          oli.Sales_Price__c = oli.UnitPrice;
                          oli.Failed_Serial_Number__c = spw.SN;//dr.serial_number__c;
                          oli.Quantity = 1;
                          
                          orderLineItemsList.add(oli);
                      }
                      else{
                          PricebookEntry pbe = new PricebookEntry(UnitPrice=0.0,Product2Id=nicprodId,Pricebook2ID=system.label.RMA_PriceBookID, IsActive=true);
                          if(PricebookEntryUpsertMap.isEmpty() || PricebookEntryUpsertMap.containskey(nicprodId+system.label.RMA_PriceBookID))
                              PricebookEntryUpsertMap.put(nicprodId+system.label.RMA_PriceBookID,pbe);//upsert pbe;
                          //oli.PriceBookEntryId =  pbe.ID;
                          oli.UnitPrice = pbe.UnitPrice;
                          oli.Sales_Price__c = pbe.UnitPrice;
                          oli.Failed_Serial_Number__c = spw.SN;//dr.serial_number__c;
                          oli.Quantity = 1;
                          
                          pbeOrderLineItemsList.add(oli);
                          orderLineItemsMap.put(nicprodId+system.label.RMA_PriceBookID,pbeOrderLineItemsList);
                          
                      }
                  }
              }
              
              for(Id rmakeyId : rmaIdMap.keySet()){
                  if(!String.isBlank(rmaIdMap.get(rmakeyId).CMOS_Battery__c)){
                      if(rmaIdMap.get(rmakeyId).CMOS_Battery__c.contains(',')){
                          cmosList = rmaIdMap.get(rmakeyId).CMOS_Battery__c.split(',');
                      }
                      else{
                          cmosList.add(rmaIdMap.get(rmakeyId).CMOS_Battery__c);
                      }
                      //for(integer i=0 ;  i< RMAOrder.CMOS_Battery_Quantity__c; i++) {
                      
                      
                      ID cmosProdId = productMap.get(Label.CMOS_Battery_Product);
                      /* < END ---- SF-91> */
                      if(cmosProdId != null){
                          OrderItem oli = new OrderItem();
                          oli.orderId = ordrmaMap.get(rmakeyId).Id;//neworder.Id;
                          oli.RMA_Component_Type__c = 'CMOS Battery';
                          if(pricbookEntryMap.containsKey(cmosProdId)){
                              oli.PriceBookEntryId =  pricbookEntryMap.get(cmosProdId);
                              oli.UnitPrice = pricbookEntryPriceMap.get(oli.PriceBookEntryId);
                              oli.Sales_Price__c = oli.UnitPrice;
                              //oli.Failed_Serial_Number__c = rmaIdMap.get(rmakeyId).CMOS_Battery__c;
                              oli.Quantity = rmaIdMap.get(rmakeyId).CMOS_Battery_Quantity__c;
                              
                              orderLineItemsList.add(oli);
                          }
                          else{
                              PricebookEntry pbe = new PricebookEntry(UnitPrice=0.0,Product2Id=cmosProdId,Pricebook2ID=system.label.RMA_PriceBookID, IsActive=true);
                              PricebookEntryUpsertMap.put(String.valueOf(cmosProdId)+system.label.RMA_PriceBookID,pbe);//upsert pbe;
                              
                              //oli.PriceBookEntryId =  pbe.ID;
                              oli.UnitPrice = pbe.UnitPrice;
                              oli.Sales_Price__c = pbe.UnitPrice;
                              //oli.Failed_Serial_Number__c = rmaIdMap.get(rmakeyId).CMOS_Battery__c;
                              oli.Quantity = rmaIdMap.get(rmakeyId).CMOS_Battery_Quantity__c;
                              
                              pbeOrderLineItemsList.add(oli);
                              orderLineItemsMap.put(String.valueOf(cmosProdId)+system.label.RMA_PriceBookID,pbeOrderLineItemsList);
                              
                          }
                      }
                      //}
                      
                  }
                  
              }
              try{
                  system.debug('@@ Final PricebookEntryUpsertMap=='+PricebookEntryUpsertMap);
                  if(!PricebookEntryUpsertMap.isEmpty()){
                      upsert PricebookEntryUpsertMap.values();
                  }
                  for(string keystr : PricebookEntryUpsertMap.keySet()){
                      for(orderItem ordItem : orderLineItemsMap.get(keystr)){
                          ordItem.PriceBookEntryId = PricebookEntryUpsertMap.get(keystr).Id;
                      }
                  }
                  system.debug('@@ Final pbeOrderLineItemsList=='+pbeOrderLineItemsList);
                  if(!pbeOrderLineItemsList.isEmpty()){
                      insert pbeOrderLineItemsList;
                  }
              }catch(Exception ex){
                  Error_Logs__c el = new Error_Logs__c(
                      Error_Type__c = 'RMA Order Error',
                      Error_Message__c = ex.getMessage() + '\r\n' + ex.getStackTraceString(),
                      Type__c = 'SFDC'
                  );
                  insert el;
                  System.debug('Exception==Method: createRMAOrderWithOrderItems==Class== RMAOrderService'+ex+' at line '+ex.getLineNumber());
              }
              system.debug('@@ Final orderLineItemsList=='+orderLineItemsList);
              if(!orderLineItemsList.isEmpty()){
                  insert orderLineItemsList;
              }
               set<string>itemids= new set<string>();
               map<string,List<string>> serailnumbersmap= new map<string,List<string>>();
                     for(orderitem item: orderLineItemsList ){
                     itemids.add(item.id);
                     }
                     for(orderitem item : pbeOrderLineItemsList ){
                     itemids.add(item.id);
                     }
                     
                   List<orderitem> itemList =[select id,assets__c,order.rma_request__c,Order.Linked_RMA_Part_order__c,order.Order_Sub_Type__c,order.ordernumber,PricebookEntry.Product2.Product_Subtype__c from orderitem where id in:itemids];
              
                   List<order>updatetechorderList = new List<order>();
                   List<orderItem> updatetechOrderItemList = new List<orderItem>();
                   map<string,string> techitemids = new map<string,string>();

                     map<string,List<string>> producttypecountMap=new map<string,List<string>>();
                    for(orderitem item : itemList){
                        if(!producttypecountMap.containskey(item.PricebookEntry.Product2.Product_Subtype__c+':'+item.order.ordernumber)){
                            producttypecountMap.put(item.PricebookEntry.Product2.Product_Subtype__c+':'+item.order.ordernumber,new List<string>{item.PricebookEntry.Product2.Product_Subtype__c});
                        }else{
                        producttypecountMap.get(item.PricebookEntry.Product2.Product_Subtype__c+':'+item.order.ordernumber).add(item.PricebookEntry.Product2.Product_Subtype__c);
                        }

                        if(item.order.Order_Sub_Type__c == 'Part Order'){
                            if(!serailnumbersmap.containskey(item.order.ordernumber))
                            serailnumbersmap.put(item.order.ordernumber,new List<string>{item.assets__c});
                            else
                            serailnumbersmap.get(item.order.ordernumber).add(item.assets__c);
                        }else{
                            techitemids.put(item.order.Linked_RMA_Part_order__c ,item.id);
                        }
                    }
                   system.debug('???????????'+producttypecountMap);
                       
                      string sow='';
                      string vendormessage='';
                      String phoneNumber = '';
                       vendormessage='';
                      sow='Scope:';
                      for(string item :producttypecountMap.keyset() ){
                         
                          string splititem = item.split(':')[0];
                           if(splititem != 'null'){
                          sow= sow +splititem+'('+producttypecountMap.get(item).size()+'),';
                          }
                       } 
                         for(Id rmakeyId : rmaIdMap.keySet()){
                           order techorder = new order();
                           string si='';
                            if(mapStatusCounrtyCodeCustomSetting.containsKey(ordrmaMap.get(rmakeyId).Shippingcountry) &&
                                mapStatusCounrtyCodeCustomSetting.get(ordrmaMap.get(rmakeyId).Shippingcountry).Phone__c != null){
                                phoneNumber = mapStatusCounrtyCodeCustomSetting.get(ordrmaMap.get(rmakeyId).Shippingcountry).Phone__c;
                            }else {
                                phoneNumber = '+1-800-997-5896';  
                            }
                           if(ordrmaMap.get(rmakeyId).Vendor_Message__c == null)
                           si = '';
                           else
                           si = ordrmaMap.get(rmakeyId).Vendor_Message__c;
                                vendorMessage = sow+'Replacement(s) Contact Rubrik Support before performing part replacements '+ phoneNumber +' Case#:'+rmaIdMap.get(rmakeyId).Parent_Case__r.CaseNumber;
                                techorder.Vendor_Message__c = si+' '+vendorMessage;
                            //PRDOPS22-455 Starts - Prashant
                             String vendorMessageLimitCheck = techorder.Vendor_Message__c;
                            if(vendorMessageLimitCheck.length() > 260 ){
                            techorder.Vendor_Message__c = vendorMessageLimitCheck.substring(0, 260) + '...';
                            } 
                             
                             if(techordermap.get(rmakeyId)!=null){
                            techorder.id = techordermap.get(rmakeyId);
                            updatetechorderList.add(techorder);
                            }
                          }
                           for(string ordernumber: serailnumbersmap.keyset()){
                            if((techitemids.containskey(ordernumber) && techitemids.get(ordernumber)!=null) && (serailnumbersmap.containskey(ordernumber) && serailnumbersmap.get(ordernumber)!=null)){
                               orderItem item = new orderItem();
                            item.id = techitemids.get(ordernumber);
                            item.assets__c = string.join(serailnumbersmap.get(ordernumber), ', ');
                             updatetechOrderItemList.add(item);
                            }
                          }
                  if(updatetechorderList.size()>0){
                     update updatetechorderList;
                  }
                  if(updatetechOrderItemList.size()>0){
                     update updatetechOrderItemList;
                  }
              // system.debug('neworder=='+neworder);
              system.debug('orderLineItemsList=='+orderLineItemsList+'==size of orderLineItemsList=='+orderLineItemsList.size());
              Set<id> techOrderWithTSPList = new set<id>();
              Set<id> rmaIDsTSP = new set<id>();
              for(Id rmakeyId : rmaIdMap.keySet()){
                  if (rmaIdMap.get(rmakeyId).Send_Smart_Hands_Service__c && rmaIdMap.get(rmakeyId).Smart_Hands_Provider__c == 'TSP Inc.') {
                       techOrderWithTSPList.add(techorderMap.get(rmakeyId));
                      rmaIDsTSP.add(rmakeyId);
                  }
              }
              // commenting the next 4 lines as part of DGWD2-1 to prevent email trigger while creating an RMA Tech order. Link to the ticklet https://rubrik.atlassian.net/browse/DGWD2-1
              /* if(!techOrderWithTSPList.isEmpty()){
                  sendEmailtoFlash(techOrderWithTSPList);
                  sendingEmail(MapTempNameAndTempRec.get('Order-TSP Integration Template VF'),rmaIDsTSP,'FLASH_EMAIL');
              } */
              //(neworder.Id);
             // Commenting the next line as part of PRDOPS24-895
             //   sendEmailtoFlash(ordersIDset);
              System.debug('******ORDER CREATED ***** '+ordersIDset);
         
          }catch(Exception ex){
              Error_Logs__c el = new Error_Logs__c(
                  Error_Type__c = 'RMA Order Error',
                  Error_Message__c = ex.getMessage() + '\r\n' + ex.getStackTraceString(),
                  Type__c = 'SFDC'
              );
              insert el;
              System.debug('Exception==Method: createRMAOrderWithOrderItems==Class== RMAOrderService'+ex+' at line '+ex.getLineNumber());
          }
      } 
         public static void updateRelatedOrders(Set<Id> RMAIDs) {
             EmailType='SMART_HANDS_ADDED';
             Set<ID> ordersToResendEmail = new Set<ID>();
             EmailTemplate temp1 = new EmailTemplate();
             temp1=[Select id,Name, Subject, Body from EmailTemplate where name ='Order-Flash Integration Template VF - Updated' limit 1];
             for(order rmaOrder : [select id,RMA_Request__C from Order where RMA_Request__C IN: RMAIds AND Order_Sub_Type__c = 'Tech Order']) { // PRDOPS23-19
                 ordersToResendEmail.add(rmaOrder.id);
             }
             if(!ordersToResendEmail.isEmpty()) {
                 sendEmailtoFlash(ordersToResendEmail);
                 sendingEmail(temp1,RMAIDs,EmailType);
             }
             
         }
         public static void smartHandRemovedEmails(Set<Id> RMAIDsmarthands) {
             EmailType='SMART_HANDS_REMOVED';
             Set<ID> ordersToSendEmailSmartHands = new Set<ID>();
             EmailTemplate smartHandsremoved = new EmailTemplate();
             smartHandsremoved=[Select id,Name, Subject, Body from EmailTemplate where name ='Order-Flash Integration Template VF -SmartHands Removed' limit 1];
             for(order rmaOrder : [select id,RMA_Request__C from Order where RMA_Request__C IN: RMAIDsmarthands]) {
                 ordersToSendEmailSmartHands.add(rmaOrder.id);
             }
             if(!ordersToSendEmailSmartHands.isEmpty()) {
                 sendEmailtoFlash(ordersToSendEmailSmartHands);
                 sendingEmail(smartHandsremoved,RMAIDsmarthands,EmailType);
             }
             
         }
         public static void mailOnResendButton(Set<Id> RMAIDResendButton) {
             EmailType='RESEND_FLASH';
             Set<ID> ResendButtonOrder = new Set<ID>();
             for(order rmaOrder : [select id,RMA_Request__C from Order where RMA_Request__C IN: RMAIDResendButton]) {
                 ResendButtonOrder.add(rmaOrder.id);
             }
             if(!ResendButtonOrder.isEmpty()) {
                 isResendEmail = true;
                 sendEmailtoFlash(ResendButtonOrder);
                 sendingEmail(temp,RMAIDResendButton,EmailType);
                 updateResendField(RMAIDResendButton);
             }
             
         }
         public static void updateResendField(Set<Id> updateRMA){  
             List<RMA_Order__c> updateResendField = New List<RMA_Order__c>();
             for(RMA_Order__c rma:[Select id,Resend_Flash_Email__c from RMA_Order__c where id IN :updateRMA]){
                 rma.Resend_Flash_Email__c = false;
                 updateResendField.add(rma);
             }
             if(!updateResendField.isEmpty()) {
                 update updateResendField;
             }
         }
         
         //added for SF-4311
         public static void associateNodes(Set<Id> OrderIDs) {
             set<ID> RmaIDs= new Set<Id>();
             List<order> allOrder = [Select id,name,Type,RMA_Request__r.Id from order where id=:OrderIDs];
             if(allOrder.size()> 0)
             {
                 for(Order od : allOrder)
                 {
                     RmaIDs.add(od.RMA_Request__r.Id);
                 }
             
             }
             List<String> nodeListNew = new List<String>();
             if(RmaIDs.size() > 0){
             List<RMA_Order__c>NewRMAOrder = [select  Node__c, Drive__c,SSD__C, NIC__c,Chassis__c,Service_Type__c, Shipping_Street__c, Shipping_City__c, ShippingState__c, Shipping_Zip_Postal_Code__c,ShippingCountry__c, Node_Quantity__c, Drive_Quantity__c, Chasis_Quantity__c,Memory_Quantity__c, Power_Supply_Quantity__c, NIC_Quantity__c from RMA_Order__C where Id =:RmaIDs];
             if(NewRMAOrder.size()>0){
                 for(RMA_Order__c RmaRequest :NewRMAOrder)
                 {
                     if(!String.isBlank(RmaRequest.Node__c) && RmaRequest.Node_Quantity__c != null){
                         if(RmaRequest.Node__c.contains(',')){
                             nodeListNew = RmaRequest.Node__c.split(',');
                         }
                         else{
                             nodeListNew.add(RmaRequest.Node__c);
                         }
                     }
                 }
             }
             }
             Map<String,string> OldNodeAndAssetMap= new Map<String,string>();
             Map<String,string> oldNodeDetailsMap= new Map<String,string>();
             if(nodeListNew.size() > 0){
             List<Node__c> NodeData=[select Id,name,asset__r.Id, asset__r.Name,chassis__c,chassis__r.Id from Node__c where name in:nodeListNew];
             if(NodeData.size()>0){
                 for(Node__c nodeInfo : NodeData)
                 {
                     OldNodeAndAssetMap.put(nodeInfo.name,nodeInfo.asset__r.Id );
                     oldNodeDetailsMap.put(nodeInfo.name,nodeInfo.chassis__r.Id);
                 }
             }
             }
             Map<string,String> newNodeAndAsset =new Map<string,String>();
             Map<string,String> NodeAndChassisAssMap=new Map<string,String>();  
             if(RmaIDs.size() > 0){
             List<order> orderData =[select id,name,status,OrderNumber, RMA_Request__r.name,RMA_Request__r.ID,(select ID,Failed_Serial_Number__c,SerialNumber__c from OrderItems) from order where  RMA_Request__r.ID =:RmaIDs];
             if(orderData.size()>0){
                 for(Order od :orderData)
                 {
                     if(!od.OrderItems.isEmpty()){
                         for(OrderItem oi :od.OrderItems)
                         {
                             if(OldNodeAndAssetMap.containsKey(oi.Failed_Serial_Number__c))
                             {
                                 newNodeAndAsset.put(oi.SerialNumber__c,OldNodeAndAssetMap.get(oi.Failed_Serial_Number__c));
                                 NodeAndChassisAssMap.put(oi.SerialNumber__c,oi.Failed_Serial_Number__c);
                                 
                             }
                             
                             
                         }
                     }
                     
                 }
             } 
             }
             List<Asset> AssetRecords = [select id,name,ParentId from asset where name IN :newNodeAndAsset.KeySet()];
             List<Asset> AssetToUpdate = new List<Asset>();
             Set<Id> NewAssetID = new Set<ID>();
             if(AssetRecords.size()> 0){
                 for(Asset ast : AssetRecords)
                 { 
                  NewAssetID.add(ast.id);
                  if(newNodeAndAsset.ContainsKey(ast.name)){
                      ast.ParentId=newNodeAndAsset.get(ast.name);
                      AssetToUpdate.add(ast);
                  }
                 }
             }
             if(AssetToUpdate.size()> 0){
             Update AssetToUpdate;
             }
             
             // Chassis updation on Node--start
             Map<String,String> newnodedataMap = new Map<String,String>();
             if(NewAssetID.size() > 0){
             List<Node__c> newNodedata =[select Id,name,asset__r.Id, asset__r.Name,chassis__c from Node__c where asset__r.Id in:NewAssetID ];
             if(newNodedata.size() > 0){
                 for(Node__c nd :newNodedata)
                 {
                     if(newNodeAndAsset.ContainsKey(nd.asset__r.Name))
                     {
                         newnodedataMap.put(nd.name,NodeAndChassisAssMap.get(nd.asset__r.Name));
                         
                     }
                     
                 }
             }
             }
             List<Node__c> newNodeRecords = [select Id,name,asset__r.Id, asset__r.Name,chassis__c from Node__c where name IN :newnodedataMap.KeySet()];
             List<Node__c> nodeToUpdate = New List<Node__c>(); 
             if(newNodeRecords.size()>0){
                 for(Node__c nr : newNodeRecords)
                 {
                     if(newnodedataMap.ContainsKey(nr.name))
                     {
                         nr.chassis__c=oldNodeDetailsMap.get(newnodedataMap.get(nr.name));
                         nodeToUpdate.add(nr);
                     }
                 }
             }
             if(nodeToUpdate.size() > 0){
             update nodeToUpdate;
             }
             
         }
         //end

 
         /*
             @Author: Sukesh K
             @Description: for DGWD-17
         */
        public static Order createTechOrderByCloning(Order partsOrder, Date dateSupportEnd, String strTimeSupportEnd) {
            System.debug('In public static Order createTechOrder: ');
            Order techOrder = partsOrder.Clone();
            techOrder.Order_Sub_Type__c = 'Tech Order';
            techOrder.Support_Start_Date__c = System.today();
            techOrder.Support_End_Date__c = DateTime.newInstance(
                dateSupportEnd,
                Time.newInstance(
                    Integer.valueOf(strTimeSupportEnd.split(':')[0]),
                    Integer.valueOf(strTimeSupportEnd.split(':')[1]),
                    0,
                    0
                )
            );
            techOrder.Deliver_By__c = dateSupportEnd;
            techorder.Est_Delivery_Time__c =  Time.newInstance(
                    Integer.valueOf(strTimeSupportEnd.split(':')[0]),
                    Integer.valueOf(strTimeSupportEnd.split(':')[1]),
                    0,
                    0);
            System.debug('Create Tech Order: ' + techOrder);
            return techOrder;

        }
        /*
            @Author: Sukesh K
            @Description: for DGWD-17
        */
        public static OrderItem createTechOrderLineItem(Id orderId, Id priceBookEntryId, Decimal unitPrice) {
            OrderItem techOli = new OrderItem(
                orderId = orderId,
                PriceBookEntryId = priceBookEntryId,
                UnitPrice = unitPrice,
                Sales_Price__c = unitPrice,
                Quantity = 1
            );
            return techOli;
        }

        /*
            @Author: Sukesh K
            @Description: for DGWD-17 
        */
        public static void upsertTechOrders(Set<Id> setIdsRMA) { 
            System.debug('IN public static void upsertTechOrders: ');
            System.debug('number of Ids Recieved: ' + setIdsRMA.size() + '\n' + 'Ids Recieved: ' + setIdsRMA);
            List<Order> techOrders = new List<Order>();
            List<OrderItem> techOli = new List<OrderItem>();
            Map<Id,Order> ordrmaMap = new Map<Id,Order>();
            Map<Id, RMA_Order__c> mapIdRMAOrder = new Map<Id, RMA_Order__c>(
                [
                    SELECT
                        Parent_Case__c,Parent_Case__r.CaseNumber,
                        Parent_Case__r.AccountID,
                        Ship_To_Phone_Number__c,
                        Ship_To_Contact_Name__c,
                        Ship_To_Name__c,
                        Ship_To_Name__r.Name,
                        Ship_To_Email__c,
                        Parent_Case__r.Account.Distributor__c,
                        Parent_Case__r.Account.Distributor__r.Payment_Term__c,
                        Memory__c,
                        Power_Supply__c,
                        Status__c,
                        Node__c,
                        Drive__c,
                        SSD__C,
                        NIC__c,
                        Chassis__c,
                        Service_Type__c,
                        Shipping_Street__c,
                        Shipping_City__c,
                        ShippingState__c,
                        Shipping_Zip_Postal_Code__c,
                        Send_Smart_Hands_Service__c,
                        Date_of_Smart_Hands_Arrival__c,
                        Time_of_Smart_Hands_Tech_Arrival__c,
                        ShippingCountry__c,
                        Node_Quantity__c,
                        Drive_Quantity__c,
                        Chasis_Quantity__c,
                        Memory_Quantity__c,
                        Power_Supply_Quantity__c,
                        NIC_Quantity__c,
                        Appliance_Quantity__c,
                        Cluster_ID__c,
                        Appliance__c,
                        CMOS_Battery__c,
                        CMOS_Battery_Quantity__c,
                        Vendor_Message__c,
                        Parent_Case__r.Account.Distributor__r.Shipping_Carrier__c,
                        Parent_Case__r.Account.Distributor__r.Shipping_Method__c,
                        Parent_Case__r.Account.Distributor__r.Shipping_Account_Number__c,
                        Parent_Case__r.Account.Distributor__r.IncoTerms__c,
                        (SELECT Id FROM Orders__r WHERE Order_Sub_Type__c = 'Tech Order')
                    FROM RMA_Order__C
                    WHERE Id IN :setIdsRMA
                ]
            );
            
            List<order>partoderlist = [select id,RMA_Request__c,Vendor_Message__c,ordernumber,Shipping_Carrier__c,Service_Level__c,scac__c,
            (SELECT Id,order.ordernumber,PricebookEntry.Product2.Product_Subtype__c,Assets__c FROM orderitems) from order where 
             RMA_Request__c in: setIdsRMA and Order_Sub_Type__c = 'Part Order'];
              map<string,List<string>> producttypecountMap=new map<string,List<string>>();
              List<orderItem> updatetechOrderItemList = new List<orderItem>();
              map<string,string> techitemids = new map<string,string>();
              map<string,List<string>> serailnumbersMap= new map<string,List<string>>();

            for(Order ord : partoderlist){
                  ordrmaMap.put(ord.RMA_Request__c,ord);
                    for(orderitem item : ord.orderitems){
                        if(!producttypecountMap.containskey(item.PricebookEntry.Product2.Product_Subtype__c+':'+item.order.ordernumber)){
                            producttypecountMap.put(item.PricebookEntry.Product2.Product_Subtype__c+':'+item.order.ordernumber,new List<string>{item.PricebookEntry.Product2.Product_Subtype__c});
                        }else{
                        producttypecountMap.get(item.PricebookEntry.Product2.Product_Subtype__c+':'+item.order.ordernumber).add(item.PricebookEntry.Product2.Product_Subtype__c);
                        }

                        if(!serailnumbersmap.containskey(item.order.ordernumber))
                            serailnumbersmap.put(item.order.ordernumber,new List<string>{item.assets__c});
                        else
                            serailnumbersmap.get(item.order.ordernumber).add(item.assets__c);
                    }
                  
             }
            
                  
                      string sow='';
                      string vendormessage='';
                      string phoneNumber = '';
                      
            for (RMA_Order__c rmaOrder : mapIdRMAOrder.values()) {
                System.debug('rmaOrder: ' + rmaOrder);
                if (!rmaOrder.Orders__r.isEmpty()) {
                    continue; // has existing tech Order
                }
                order techorder = new order();
                techorder = createTechOrderByCloning(
                        generateOrderFromRMA(rmaOrder),
                        rmaOrder.Date_of_Smart_Hands_Arrival__c,
                        rmaOrder.Time_of_Smart_Hands_Tech_Arrival__c
                    );
                   
                     if(serviceLevelMap.containskey('DefaultShippingInfo:Default')){
                         techorder.Shipping_Carrier__c = serviceLevelMap.get('DefaultShippingInfo:Default').OrderShippingCarrier__c;
                         techorder.Service_Level__c =  serviceLevelMap.get('DefaultShippingInfo:Default').OrderServiceLevel__c;
                         techorder.scac__c =  serviceLevelMap.get('DefaultShippingInfo:Default').scac__c;
                     }
                techOrder.Linked_RMA_Part_order__c = ordrmaMap.get(rmaOrder.id).ordernumber;
                //DGWD2-16: adding next 4 lines to auto-populate the Shipping carrier and SCAC field on the order when the Smart Hand Provider = TSP Inc. Link to the ticket https://rubrik.atlassian.net/browse/DGWD2-16
                if (techOrder.Smart_hands_provider__c == 'TSP Inc.') {
					techOrder.Shipping_Carrier__c = 'TSP';
					techOrder.SCAC__c = 'TPSCHD';
				}  
                 vendormessage='';
                          sow='Scope:';
                           string si='';
                           if(ordrmaMap.get(rmaOrder.id).Vendor_Message__c == null)
                           si = '';
                           else
                           si = ordrmaMap.get(rmaOrder.id).Vendor_Message__c;
                          for(string item :producttypecountMap.keyset() ){
                         
                           string splititem = item.split(':')[0];
                              if(producttypecountMap.containskey(splititem+':'+techorder.linked_RMA_Part_Order__C)){
                                  sow= sow +splititem+'('+producttypecountMap.get(splititem+':'+techorder.linked_RMA_Part_Order__C).size()+'),';
                              }
                           } 

                            if(mapStatusCounrtyCodeCustomSetting.containsKey(RMAOrder.ShippingCountry__c) &&
                                mapStatusCounrtyCodeCustomSetting.get(RMAOrder.ShippingCountry__c).Phone__c != null){
                                phoneNumber = mapStatusCounrtyCodeCustomSetting.get(RMAOrder.ShippingCountry__c).Phone__c;
                            }else {
                               phoneNumber = '+1-800-997-5896';  
                           }
                
                        vendorMessage = sow+' Replacement(s) Contact Rubrik Support before performing part replacements '+phoneNumber+' Case#: '+mapIdRMAOrder.get(rmaOrder.id).Parent_Case__r.CaseNumber;
                        techorder.Vendor_Message__c =si+' '+vendorMessage;
                         String vendorMessageLimitCheck = techorder.Vendor_Message__c;        
                        if(vendorMessageLimitCheck.length() > 260 ){
                        techorder.Vendor_Message__c = vendorMessageLimitCheck.substring(0, 260) + '...';
                        }
                
                techOrders.add(techorder);
                    
                
            }
            insert techOrders;

            PricebookEntry pbe;
            if (!Test.isRunningTest()) {
                pbe = [
                    SELECT Id, UnitPrice, Product2ID
                    FROM PricebookEntry
                    WHERE Product2ID = :System.label.Product_Id_Tech_Order
                    LIMIT 1
                ];
            } else {
                pbe = [
                    SELECT Id, UnitPrice, Product2ID
                    FROM PricebookEntry
                    WHERE Product2ID IN (SELECT Id FROM Product2 WHERE Name = 'X-SVC-TECH')
                ];
            }

            for (Order techOrder : techOrders) {
                 orderitem techlineItem = new orderItem();
                 techlineItem = createTechOrderLineItem(techOrder.Id, pbe.Id, pbe.UnitPrice);
                 techlineItem.Assets__c = string.join(serailnumbersmap.get(techOrder.Linked_RMA_Part_order__c), ', ');
                 techOli.add(techlineItem);
            }
            insert techOli;
        }


        /*
            @Author: Sukesh K
            @Description: for DGWD-17
        */
        public static Order generateOrderFromRMA(RMA_Order__c rmaOrder) {
            Order newOrder = new Order();
            newOrder.status = 'Pending';
            //PRDOPS23-22
            newOrder.AccountId = rmaOrder.Ship_To_Name__c;
            newOrder.EffectiveDate = system.Today();
            
            Map<String, StateCodeName__C> mapStatusStateCodeCustomSetting = StateCodeName__C.getAll();
            Map<String, CountryWithCode__c> mapStatusCounrtyCodeCustomSetting = CountryWithCode__c.getAll();
            string uniqueCode = '';
            if (mapStatusCounrtyCodeCustomSetting.containsKey(rmaOrder.ShippingCountry__C)) {
                uniqueCode =
                    mapStatusCounrtyCodeCustomSetting.get(rmaOrder.ShippingCountry__C).code__C +
                    '-' +
                    rmaOrder.ShippingState__c;
            }
            newOrder.Shippingcountry = rmaOrder.ShippingCountry__C;
            newOrder.ShippingcountryCode = mapStatusCounrtyCodeCustomSetting.get(rmaOrder.ShippingCountry__C).code__C;
            newOrder.Shippingcity = rmaOrder.Shipping_City__c;
            newOrder.Shippingstreet = rmaOrder.Shipping_street__C;
            newOrder.ShippingstateCode = !uniquecode.contains('-null') ? uniquecode.substring(3, 5) : null; //mapStatusStateCodeCustomSetting.get(uniqueCode).State_Name__c; //rmaOrder.ShippingState__c;
            newOrder.ShippingPostalCode = rmaOrder.Shipping_Zip_Postal_Code__c;
            newOrder.Service_Type__c = rmaOrder.Service_Type__c;
            newOrder.Ship_To_Name__c = rmaOrder.Ship_To_Name__r.Name;
            newOrder.Bill_To_Name__c = rmaOrder.Ship_To_Name__c;
            newOrder.ShipToContactName__c = rmaOrder.Ship_To_Contact_Name__c;
            newOrder.Ship_To_Email__c = rmaOrder.Ship_To_Email__c;
            newOrder.Ship_To_Phone_Number__c = rmaOrder.Ship_To_Phone_Number__c;
            //newOrder.Shipping_Carrier__c = Label.RMA_Shipping_Carrier;
            newOrder.Shipping_Method__c = Label.RMA_Shipping_Terms;
            newOrder.Service_Type__c = rmaOrder.Service_Type__c;
            newOrder.Vendor_Message__c = rmaOrder.Vendor_Message__c;
             if(serviceLevelMap.containskey(rmaOrder.Service_Type__c+':'+rmaOrder.Shipping_Zip_Postal_Code__c)){
            newOrder.Shipping_Carrier__c = serviceLevelMap.get(rmaOrder.Service_Type__c+':'+rmaOrder.Shipping_Zip_Postal_Code__c).OrderShippingCarrier__c;

            newOrder.Service_Level__c = serviceLevelMap.get(rmaOrder.Service_Type__c+':'+rmaOrder.Shipping_Zip_Postal_Code__c).OrderServiceLevel__c;
            
            }
            newOrder.Pricebook2Id = system.label.RMA_PriceBookID;
            newOrder.Type = 'RMA';
            Id orderRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('RMA Order').getRecordTypeId();
            if (orderRecordTypeId != null) {
                newOrder.RecordTypeId = orderRecordTypeId;
            }

            newOrder.RMA_Request__C = RMAOrder.id;
            newOrder.PO_Number__c = 'n/a';
            return newOrder;
        }

        //end
      public class sparesWrapperClass{
          string rmakeyId;
          string SN;
          string driveType;
          string AssetSN;
          Spares_Mapping__c mappingRec;
          public sparesWrapperClass(string rmakeyId1,string SN1,string driveType1,string AssetSN1,Spares_Mapping__c mappingRec1){
              mappingRec = new Spares_Mapping__c();
              rmakeyId = rmakeyId1; 
              driveType = driveType1;
              SN = SN1;
              AssetSN = AssetSN1;
              mappingRec = mappingRec1;
          }
      }

       
     }