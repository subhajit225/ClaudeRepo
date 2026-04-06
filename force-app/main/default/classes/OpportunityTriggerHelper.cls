public class OpportunityTriggerHelper {
    //No more in use
    public static String test ='';

    /*
    public static String RID ='Rubrik Initiated Deal';
    
    //added for SAL-1775
    private static void populatePrimaryCampaignSrc(List<Opportunity> oppList){
        Map<Id,List<Opportunity>> mapContactOpportunities  = new Map<Id,List<Opportunity>>();
        
        for(Opportunity oppInst : oppList){
            if(oppInst.Initial_Contacts_Name__c != null){
                if(!mapContactOpportunities.containsKey(oppInst.Initial_Contacts_Name__c)){
                    mapContactOpportunities.put(oppInst.Initial_Contacts_Name__c,new List<Opportunity>());
                }
                mapContactOpportunities.get(oppInst.Initial_Contacts_Name__c).add(oppInst);
            }
        }
        
        Map<Id,Id> mapContactIdCampaignId = new Map<Id,Id>();
        if(mapContactOpportunities.isEmpty() == false){            
            for(CampaignMember campMemb : [SELECT Id,CampaignId,ContactId
                                           FROM CampaignMember
                                           WHERE ContactId IN :mapContactOpportunities.keySet()
                                           ORDER BY CreatedDate ASC]){
                if(!mapContactIdCampaignId.containsKey(campMemb.CampaignId)){
                    mapContactIdCampaignId.put(campMemb.ContactId,campMemb.CampaignId); 
                }
            }
        }
        
        for(Opportunity oppInst : oppList){
            if(oppInst.Initial_Contacts_Name__c != null &&
                mapContactIdCampaignId.containsKey(oppInst.Initial_Contacts_Name__c)){
                oppInst.CampaignId = mapContactIdCampaignId.get(oppInst.Initial_Contacts_Name__c);
            }
        }
    }
    
    public static void setFieldsOnInsert (List<Opportunity> oppList) {
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        
        Map<String, Contact> contactMap = new Map<String, Contact>();
        Set<String> emailSet = new Set<String>();
        set<Id> updateOppwithaccIds = new set<Id>();
        Set<Id> customerAccIds = new Set<Id>();
        Set<Id> rubrikSalesEngineerIds = new Set<Id>();
        Set<Id> amendedServiceContracts = new Set<Id>(); //MSP1.1
        Set<Id> renewedServiceContracts = new Set<Id>(); //MSP1.1
        Map<Id,Id> allAccountWithOwnerIDs = new Map<Id,Id>(); //MSP1.1
        
        for(Opportunity opp : oppList) {
        
            opp.SE_Forecast_Category__c = opp.ForecastCategoryName;
            
            if(disableFuncCS.Is_Datos_User__c) {
                opp.Business_Unit__c = 'Mosaic';    
            }
            if(opp.Opportunity_Split_ParentID__c==null 
                && opp.Disable_Auto_OwnerAssignment__c==false 
                && opp.Opportunity_Type__c!='Debooking'
             ){
                updateOppwithaccIds.add(opp.AccountId);
            } 
            if(opp.StageName != NULL) {
                opp.Stage_Changed_Date__c = System.TODAY();
            }
            if(opp.SBQQ__Ordered__c) {
                opp.SBQQ__Ordered__c = FALSE;
            }
            if(String.isNotBlank(opp.Lead_Email_Hidden__c)) {
                emailSet.add(opp.Lead_Email_Hidden__c);
            }
           // if(opp.Converted_From_Lead__c) {
                DealRegUtilityHelper.setDealRegistrationType(opp, null);
          //  }
            rubrikSalesEngineerIds.add(opp.Rubrik_Sales_Engineer__c);
            
            //MSP1.1 
            if(opp.SBQQSC__AmendedServiceContract__c!= null){
                amendedServiceContracts.add(opp.SBQQSC__AmendedServiceContract__c);
            }
            
            //MSP1.1 
            if(opp.SBQQSC__RenewedServiceContract__c != null){
                renewedServiceContracts.add(opp.SBQQSC__RenewedServiceContract__c );
            }
            
        }
        
        Map<Id, ServiceContract> amendedServiceContractsMap;
        if(amendedServiceContracts.size()>0){
          amendedServiceContractsMap = new Map<Id,ServiceContract>([Select Id, SBQQSC__Opportunity__c, SBQQSC__Opportunity__r.Opportunity_Sub_Type__c from ServiceContract where ID IN :amendedServiceContracts]);  
        }
        Map<Id, ServiceContract> renewedServiceContractsMap;
        if(renewedServiceContracts.size()>0){
          renewedServiceContractsMap = new Map<Id,ServiceContract>([Select Id, SBQQSC__Opportunity__c, SBQQSC__Opportunity__r.Opportunity_Sub_Type__c from ServiceContract where ID IN :renewedServiceContracts]);  
        }
        
        List<Contact> cntList = [SELECT Id, Email, Name FROM Contact WHERE Email IN: emailSet ORDER BY CreatedDate ASC LIMIT 50000];
        for(Contact con : cntList) {
            contactMap.put(con.Email, con);
        }
       
        for( Account acc: [select id,OwnerId,RecordType.developername from account where Id IN: updateOppwithaccIds]){ // Irrespective of opportunity account being part of territory will keep opp owner same as account owner
            if(acc.RecordType.developername =='Customer_Prospect'){
                customerAccIds.add(acc.id);
            }
            allAccountWithOwnerIDs.put(acc.id,acc.OwnerId);
            
            
        } 
        for(Opportunity opp : oppList) {
            if(String.isNotBlank(opp.Lead_Email_Hidden__c) && contactMap.containskey(opp.Lead_Email_Hidden__c)) {
                opp.Initial_Contacts_Name__c = contactMap.get(Opp.Lead_Email_Hidden__c).Id;
            }
            //Adding for [SAL-293] -- Adding Workflow logic and timestamp logic to update all timestampfields
            //Start
            if( !customerAccIds.isEmpty()
                && opp.Opportunity_Split_ParentID__c==null 
                && opp.Disable_Auto_OwnerAssignment__c==false 
                && opp.Opportunity_Type__c!='Debooking'
                && (customerAccIds.contains(opp.AccountId))
                ){
                opp.OwnerId = allAccountWithOwnerIDs.get(opp.AccountId);
            } 
            if(opp.Manager_s_Note__c!=null || opp.Manager_s_Note__c!=''){
                opp.manager_note_date_time__c = Datetime.Now();
            }
            
            
            if(opp.Area_VP_Notes__c!=null || opp.Area_VP_Notes__c!=''){
                opp.Area_VP_Notes_Timestamp__c = Datetime.Now();
            }
            
            
            if(opp.RD_Notes__c!=null || opp.RD_Notes__c!=''){
                opp.RD_Notes_Timestamp__c = Datetime.Now();
            }
            
            
            if(opp.Theater_VP_Notes__c!=null || opp.Theater_VP_Notes__c!=''){
                opp.Theater_VP_Notes_Timestamp__c = Datetime.Now();
            }
            
            //MSP1.1
            if(opp.Opportunity_Sub_Type__c == 'MSP'){
                if(allAccountWithOwnerIDs.containsKey(opp.AccountId)){
                    opp.ownerId = allAccountWithOwnerIDs.get(opp.AccountId);
                }
            }
            //MSP1.1
            if(opp.SBQQSC__AmendedServiceContract__c!= null && amendedServiceContractsMap!= null){
                if(amendedServiceContractsMap.containsKey(opp.SBQQSC__AmendedServiceContract__c)){
                    ServiceContract tempSC = amendedServiceContractsMap.get(opp.SBQQSC__AmendedServiceContract__c);
                    system.debug('//Ashwini tempSC: '+tempSC);
                    if(tempSC.SBQQSC__Opportunity__c != null && 
                       tempSC.SBQQSC__Opportunity__r.Opportunity_Sub_Type__c != null &&
                       (tempSC.SBQQSC__Opportunity__r.Opportunity_Sub_Type__c == 'MSP Consumption Renewal' 
                        || tempSC.SBQQSC__Opportunity__r.Opportunity_Sub_Type__c == 'MSP')
                      ){
                      opp.Opportunity_Sub_Type__c = 'MSP';
                      opp.Opportunity_Type__c = 'Existing Customer';
                      if(allAccountWithOwnerIDs.containsKey(opp.AccountId)){
                        opp.ownerId = allAccountWithOwnerIDs.get(opp.AccountId);
                      }
                    }
                }
            }
            //MSP1.1
            if(opp.SBQQSC__RenewedServiceContract__c != null && renewedServiceContractsMap!= null){
                if(renewedServiceContractsMap.containsKey(opp.SBQQSC__RenewedServiceContract__c)){
                    ServiceContract tempSC = renewedServiceContractsMap.get(opp.SBQQSC__RenewedServiceContract__c);
                    system.debug('//Ashwini tempSC renewal: '+tempSC);
                    if(tempSC.SBQQSC__Opportunity__c != null && 
                       tempSC.SBQQSC__Opportunity__r.Opportunity_Sub_Type__c != null &&
                       tempSC.SBQQSC__Opportunity__r.Opportunity_Sub_Type__c == 'MSP'
                      ){
                      opp.Opportunity_Sub_Type__c = 'MSP Consumption Renewal';
                      opp.Opportunity_Type__c = 'Existing Customer';
                      if(allAccountWithOwnerIDs.containsKey(opp.AccountId)){
                        opp.ownerId = allAccountWithOwnerIDs.get(opp.AccountId);
                      }
                    }
                }
            }

        }
        populatePrimaryCampaignSrc(oppList);
    }
    
    //START - SF-1808
    public static void setPOandStage6TimeStamp (List<Opportunity> oppList, Map<Id, Opportunity> oldOppMap) {
        for(Opportunity opp : oppList){
            Opportunity oldOpp = oldOppMap.get(opp.id);
            if(opp.PO_Received_Notification_Sent__c != oldOpp.PO_Received_Notification_Sent__c && opp.PO_Received_Notification_Sent__c ){
                opp.PO_Notification_Sent_timestamp__c = system.now(); //capturing datetime of PO Notification sent
            }
            if(opp.StageName != oldOpp.StageName && opp.StageName == '6 PO With Channel' ){
                opp.Stage_6_TimeStamp__c = system.now(); //capturing datetime of stage 6
            }
        }
    }
    //END - SF-1808
    
    public static void setFieldsOnUpdate (List<Opportunity> oppList, Map<Id, Opportunity> oldOppMap) {
        List<Id> oppAccIdList = new List<Id>();
        Set<Id> oppIdSet = new Set<Id>();
        Set<String> dealRegLinkSet = new Set<String>();
        
        Set<Id> rubrikSalesEngineerIds = new Set<Id>();
        Map<String, SkipManualOrder__c > orderSkipAccs = SkipManualOrder__c.getAll();
        Set<Id> opptysToSkip = new Set<Id>();
        if(orderSkipAccs != null){
            for(SkipManualOrder__c setting: orderSkipAccs.values()){
                if(setting.Enabled__c){
                    opptysToSkip.add(setting.Account_Id__c);
                }
            }
        }
        
        Set<id> OpptyId = new set<id>();
        
        for(Opportunity opp : oppList){
            OpptyId.add(opp.id);
        }
        List<order> pocOrders = [select id, POC_Opportunity__c, POC_Type__c from order where POC_Opportunity__c in: OpptyId and  POC_type__c='Conditional PO'];
        
        map<id,order> optyPOCORderMap = new Map<id,order>();
        
        for(order ord: pocOrders){
            optyPOCORderMap.put(ord.POC_Opportunity__c,ord);
        }
        
        for(Opportunity opp : oppList) {
            
                     
            Opportunity oldOpp = oldOppMap.get(opp.id);

            if(opp.StageName != oldOpp.StageName) {
                opp.Stage_Changed_Date__c = System.TODAY();
            }
            
            if(opp.ForecastCategoryName != oldopp.ForecastCategoryName) {
                opp.SE_Forecast_Category__c = opp.ForecastCategoryName;
            }
            System.debug(opp.SBQQ__PrimaryQuote__c);
            System.debug(opp.StageName);
            System.debug(oldOpp.StageName);
            if(opp.SBQQ__PrimaryQuote__c != null ) {
                if(opp.StageName == System.Label.Order_Creation_Stage && opp.StageName != oldOpp.StageName && opp.SBQQ__Ordered__c != TRUE   &&  (!opptysToSkip.contains(opp.Distributor_Lookup__c) || (opptysToSkip.contains(opp.Distributor_Lookup__c) && (opp.Opportunity_Sub_Type__c == 'MSP' || optyPOCORderMap.get(opp.id) != null)))) {
                    opp.SBQQ__Ordered__c = TRUE;
                }
         }
         oppAccIdList.add(opp.AccountId);
         
         if(opp.Deal_Registration_Link__c  != null) {
             oppIdSet.add(opp.Id);  
             dealRegLinkSet.add(opp.Deal_Registration_Link__c);
         }

         //Process Builder - Sales Operations - Stamp Secondary/Renewal Owner on Approval
         //Moved change in trigger - keeping it in one place
         if(String.isNotBlank(opp.SecondaryOwnerSubmitter__c) && opp.SecondaryOwnerApproved__c != oldOpp.SecondaryOwnerApproved__c) {
             opp.SecondaryOwner__c = opp.SecondaryOwnerSubmitter__c;
         }
         if(String.isNotBlank(opp.RenewalOwnerSubmitter__c) && opp.RenewalOwnerApproved__c != oldOpp.RenewalOwnerApproved__c) {
             opp.RenewalOwner__c = opp.RenewalOwnerSubmitter__c;
         }
        
      }
    
     Map<String, Lead> dealRegLinkMap;
     if(dealRegLinkSet.size() > 0) {
         dealRegLinkMap = new Map<String, Lead> ([SELECT 
                                                     SDR_Led__c, Deal_Registration_Type__c, Deal_Reg_Approval_Status__c, Deal_Reg_Submitted_Date__c, 
                                                     Deal_Reg_Approval_Timestamp__c,Deal_Reg_Exp_Date__c, Alliance_Partner_Program__c, 
                                                     Deal_Registration_Number__c, Partner_Rep_Phone_Number__c, Partner_Rep_Email_Address__c, 
                                                     Distributor_Rep_Phone_Number__c, Distributor_Secondary_Email_Address__c, Partner_SE_Name__c, 
                                                     Partner_SE_Phone__c, Partner_SE_Email__c 
                                                  FROM Lead 
                                                  WHERE Id IN :dealRegLinkSet] );
     }

     for(Opportunity opp : oppList) {

         Opportunity oldOpp = oldOppMap.get(opp.id);

         //Adding Deal Reg to Opty - Start
         if(oldOpp.Deal_Registration_Link__c != opp.Deal_Registration_Link__c && opp.Deal_Registration_Link__c != null && dealRegLinkMap.containsKey(opp.Deal_Registration_Link__c)){          
             Lead regLink = (Lead) dealRegLinkMap.get(opp.Deal_Registration_Link__c);
             DealRegUtilityHelper.setDealRegistrationType(opp, regLink);             
             DealRegUtilityHelper.copyDealRegLeadToOpportunity(opp, regLink);    
         } else {
             DealRegUtilityHelper.setDealRegistrationType(opp, null);
         }
         //Adding Deal Reg to Opty - End
         
         //if(userManagerMap.containsKey(opp.Rubrik_Sales_Engineer__c)){
         //    opp.SE_Manager__c = userManagerMap.get(opp.Rubrik_Sales_Engineer__c);
         //}

         //SF-1002
         if(opp.SE_Misaligned__c && !oldopp.SE_Misaligned__c){
             opp.Rubrik_Sales_Engineer__c = opp.SE_Misalignment_User__c;
         }
     }
     
     //TODO: do we need below code? are we still using these fields?
     Map<String, Integer> opptyInactiveProduct = new Map<String, Integer>();
     Map<String, Integer> accTechContact = new Map<String, Integer>();
     AggregateResult[] groupedResults = [SELECT count(Id) activeCount, PricebookEntry.Product2.IsActive, OpportunityId FROM OpportunityLineItem WHERE PricebookEntry.Product2.IsActive = false AND OpportunityId IN: oppList GROUP BY PricebookEntry.Product2.IsActive, OpportunityId];
     for (AggregateResult ar : groupedResults)  {
         opptyInactiveProduct.put((Id)ar.get('OpportunityId'), (Integer)ar.get('activeCount'));
     }
     
     AggregateResult[] groupedResultsContact = [SELECT count(Id) primarytTechCount, Primary_Technical_Support_Contact__c, AccountId FROM Contact WHERE Primary_Technical_Support_Contact__c = TRUE AND AccountId IN: oppAccIdList GROUP BY Primary_Technical_Support_Contact__c, AccountId];
     for (AggregateResult ar : groupedResultsContact)  {
         accTechContact.put((Id)ar.get('AccountId'), (Integer)ar.get('primarytTechCount'));
     }
     
     for(Opportunity opp : oppList) {
         opp.Number_of_Inactive_Products__c = opptyInactiveProduct.get(opp.Id) != null ? opptyInactiveProduct.get(opp.Id) : 0;
         opp.Number_of_Primary_Technical_Contact__c = accTechContact.get(opp.AccountId) != null ? accTechContact.get(opp.AccountId) : 0;
         
         //Adding for [SAL-293] -- Adding Workflow logic and timestamp logic to update all timestampfields
         //Start
         if(opp.Manager_s_Note__c!=oldOppMap.get(opp.id).Manager_s_Note__c){
             opp.manager_note_date_time__c = Datetime.Now();
         }
         
         
         if(opp.Area_VP_Notes__c!=oldOppMap.get(opp.id).Area_VP_Notes__c){
             opp.Area_VP_Notes_Timestamp__c = Datetime.Now();
         }
         
         
         if(opp.RD_Notes__c!=oldOppMap.get(opp.id).RD_Notes__c){
             opp.RD_Notes_Timestamp__c = Datetime.Now();
         }
         
         
         if(opp.Theater_VP_Notes__c!=oldOppMap.get(opp.id).Theater_VP_Notes__c){
             opp.Theater_VP_Notes_Timestamp__c = Datetime.Now();
         }
         //End
     
     }
     //TODO: do we need below code? are we still using these fields?
 }
 
 public static void insertOpportunityContactRoles (List<Opportunity> oppList, Map<Id, Opportunity> oldMap) {
     Map<String, Id> existingContacts = new Map<String, Id>();
     if(oldMap != null && oldMap.size()>0){
         for(OpportunityContactRole ocr : [Select Id, OpportunityId, ContactId from OpportunityContactRole where OpportunityId in :oppList]){
             existingContacts.put(ocr.OpportunityId+''+ocr.ContactId, ocr.Id);
         }
     }
     List<OpportunityContactRole> ocrList = new List<OpportunityContactRole>();
     List<OpportunityContactRole> ocrListToUpdate = new List<OpportunityContactRole>();
     for(Opportunity opp : oppList) {
         if(String.isNotBlank(opp.Initial_Contacts_Name__c)) {
             if(existingContacts.containsKey(opp.Id+''+opp.Initial_Contacts_Name__c)){
                 OpportunityContactRole ocr = new OpportunityContactRole(
                     isPrimary = true,
                     Id = existingContacts.get(opp.Id+''+opp.Initial_Contacts_Name__c)
                 );
                 ocrListToUpdate.add(ocr);
             }
             else {
                 OpportunityContactRole ocr = new OpportunityContactRole(
                     OpportunityId = opp.Id, 
                     ContactId = opp.Initial_Contacts_Name__c, 
                     isPrimary = true
                 );
                 ocrList.add(ocr);
             }
         }
     }
     if(!ocrList.isEmpty()) {
        insert ocrList;
     }

     if(!ocrListToUpdate.isEmpty()) {
        update ocrListToUpdate;
     }
 }
 
 public static void valootoOrderProcess (List<Opportunity> valootoOpptyList, Map<Id, Opportunity> oldOppMap) {
     Map<Id, List<Order>> opptyOrdersMap = new Map<Id, List<Order>>();
     
     List<Order> ordList;
     for(Order ord : [SELECT Id, OrderNumber, OpportunityId FROM Order WHERE OpportunityId IN :valootoOpptyList ORDER BY CreatedDate DESC]) {
                          
                          if(opptyOrdersMap.containsKey(ord.OpportunityId)) {
                              ordList = opptyOrdersMap.get(ord.OpportunityId);
                          } else {
                              ordList = new List<Order>();
                          }
                          ordList.add(ord);
                          opptyOrdersMap.put(ord.OpportunityId, ordList);
                          System.debug('Inside OpportunityTriggerHelper - opptyOrdersMap == '+opptyOrdersMap+' ==size== '+opptyOrdersMap.size());
                      }
     
     List<Opportunity> updatedOpptyList = new List<Opportunity>();
     List<Order> updateOrdersList = new List<Order>();
     List<Opportunity> updateOrdersOpportunityList = new List<Opportunity>();
     
     for(Opportunity oppty : valootoOpptyList) {
         Opportunity oldOppty = (Opportunity) trigger.oldMap.get(oppty.Id);
         
         if(oppty.StageName == System.Label.Order_Creation_Stage 
            && oppty.StageName != oldOppty.StageName ) {
                
                if(opptyOrdersMap.containsKey(oppty.id)) { // Has Orders
                    updateOrdersList.add(opptyOrdersMap.get(oppty.id)[0]);
                    updateOrdersOpportunityList.add(oppty);
                } else { // No Orders
                    updatedOpptyList.add(oppty);
                }
            }
     }
     
     system.debug('Inside OpportunityTriggerHelper - updatedOpptyList --'+updatedOpptyList);
     Map<Id, Opportunity> opptyMap = new Map<Id, Opportunity> ( [SELECT 
                                                                 StageName, Account.name, Account.Id, Partner_Lookup__c, Distributor_Lookup__c, Distributor_lookup__r.Payment_Term__c, OwnerId, Owner.email, Rubrik_Sales_Engineer__c,Rubrik_Sales_Engineer__r.Email,
                                                                 Partner_Lookup__r.Shipping_Carrier__c , Partner_Lookup__r.Shipping_Method__c , Partner_Lookup__r.Shipping_Account_Number__c,Partner_Lookup__r.IncoTerms__c,
                                                                 Distributor_Lookup__r.Shipping_Carrier__c , Distributor_Lookup__r.Shipping_Method__c , Distributor_Lookup__r.Shipping_Account_Number__c,Distributor_Lookup__r.IncoTerms__c,
                                                                 Partner_Lookup__r.Distributor__r.Shipping_Carrier__c,Partner_Lookup__r.Distributor__r.Shipping_Method__c,Partner_Lookup__r.Distributor__r.Shipping_Account_Number__c,Partner_Lookup__r.Distributor__r.IncoTerms__c,
                                                                 Partner_Lookup__r.Payment_Term__c, Partner_Lookup__r.Distributor__r.Payment_Term__c,Partner_Lookup__r.Distributor__c, CloseDate,Pricebook2Id
                                                                 FROM Opportunity 
                                                                 WHERE Id =: updatedOpptyList OR Id =: updateOrdersOpportunityList] );
     
     List<OpportunityLineItem> listOI = [SELECT Id, Unitprice, TotalPrice, Valooto_Sales_Price__c ,Description, Quantity, Discount, PriceBookEntryId, OpportunityId  FROM OpportunityLineItem WHERE OpportunityId =: updatedOpptyList OR OpportunityId =: updateOrdersOpportunityList];
     List<OpportunityContactRole> ocr = [SELECT Id, Role, ContactId, Contact.Email, IsPrimary, OpportunityId FROM OpportunitycontactRole WHERE OpportunityId =: updatedOpptyList OR OpportunityId =: updateOrdersOpportunityList ];
     
     Map<Id, List<OpportunityLineItem>> opptyLineItemMap = ShGl_CommonUtility.convertListToMap(listOI, 'OpportunityId');
     Map<Id, List<OpportunityContactRole>> opptyContactRoleMap = ShGl_CommonUtility.convertListToMap(ocr, 'OpportunityId');
     
     if(!updatedOpptyList.isEmpty()){
         insertNewOrder(updatedOpptyList, opptyMap, opptyLineItemMap, opptyContactRoleMap);
     }
     
     System.debug('Inside OpportunityTriggerHelper - updateOrdersList == '+updateOrdersList+' ==size== '+updateOrdersList.size());
     // Added by Shadab for handling single order on opportunity
     if(!updateOrdersList.isEmpty()){
         updatetExistingOrder(updateOrdersList, opptyMap, opptyLineItemMap);
     }
 }
 
 //START - Valooto Order Process
 public static void insertNewOrder(List<Opportunity> oppList, Map<Id, Opportunity> opptyMap, Map<Id, List<OpportunityLineItem>> opptyLineItemMap, Map<Id, List<OpportunityContactRole>> opptyContactRoleMap) {
     try {
         if(!oppList.isEmpty()) {
             for(Opportunity opp : oppList) {
                 createOrderWithOrderItems(opp.id, opptyMap.get(opp.id), opptyLineItemMap.get(opp.id), opptyContactRoleMap.get(opp.id));
             }
         }
     } catch(Exception ex) {
         System.debug('Exception==Method: insertNewOrder== : '+ex);
     }
 }
 
 public static void createOrderWithOrderItems(Id oppId, Opportunity opp, List<OpportunityLineItem> listOI, List<OpportunityContactRole> ocr) {
     Order newOrd = new Order();
     
     newOrd.Order_Status__c = 'Pending';
     newOrd.AccountId = opp.Account.Id;
     newOrd.OpportunityId = opp.Id;
     newOrd.PONumber = 'n/a';
     newOrd.EffectiveDate = System.today();
     newOrd.RecordtypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Revenue Order').getRecordTypeId();
     newOrd.Type = 'Revenue';
     //newOrd.Ship_To_Name__c = Opp.Account.Id;
     newOrd.Opportunity_Owners_Email__c = opp.Owner.email;//Added per Kiet for Welcome Letter CL
     newOrd.Rubrik_Sales_Engineer__c = opp.Rubrik_Sales_Engineer__r.Email;
     newOrd.Pricebook2Id = opp.Pricebook2Id;
     
     if(opp.Distributor_Lookup__c != null) {
         newOrd.Bill_To_Name__c = Opp.Distributor_Lookup__c;
     }
     if(!ocr.isEmpty()) {
         newOrd.ShipToContact = ocr[0].Contact;
     }
     insert newOrd;
     
     List<OrderItem> opptyLineItemsList = new List<OrderItem>();
     for(OpportunityLineItem oi : listOI) {
         
         opptyLineItemsList.add( getOrderLineItem (newOrd, oi) );
     }
     insert opptyLineItemsList;
 }
 
 public static void updatetExistingOrder(List<Order> orderList, Map<Id, Opportunity> opptyMap, Map<Id, List<OpportunityLineItem>> opptyLineItemMap) {
     try {
         if(!orderList.isEmpty()) {
             List<OrderItem> orderItemsList = [SELECT Id FROM OrderItem WHERE orderId IN: orderList];
             if(!orderItemsList.isEmpty()) {
                 delete orderItemsList;
             }
             for(Order ord : orderList) {
                 updateOrderWithOrderItems(ord.Id, ord.OpportunityId, opptyMap.get(ord.OpportunityId), opptyLineItemMap.get(ord.OpportunityId));
             }
         }
     } catch(Exception ex) {
         System.debug('Exception==Method: insertNewOrder== '+ex);
     }
 }
 
 // Added new method to handle update of existing order. Logic: Only a single records per Oppoty
 public static void updateOrderWithOrderItems(Id orderId, Id oppId, Opportunity opp, List<OpportunityLineItem> listOI) {
     Order newOrd = new Order(Id = orderId);
     newOrd.Pricebook2Id = opp.Pricebook2Id;
     update newOrd;
     
     List<OrderItem> opptyLineItemsList = new List<OrderItem>();
     for(OpportunityLineItem oi : listOI) {
        
         opptyLineItemsList.add( getOrderLineItem (newOrd, oi) );
     }
     insert opptyLineItemsList;
 }
 
 private static OrderItem getOrderLineItem (Order newOrd, OpportunityLineItem oi) {
     OrderItem oli = new OrderItem();
     oli.OrderId = newOrd.Id;
     oli.PriceBookEntryId = oi.PriceBookEntryId;
     oli.Actual_Sales_Price__c = oi.Valooto_Sales_Price__c;
     oli.Sales_Price__c = (oi.TotalPrice/oi.quantity).setScale(2) ;
     oli.Description = oi.Description;
     oli.Quantity = oi.Quantity;
     
     if(oi.Discount != null) {
         oli.UnitPrice = oi.UnitPrice - (oi.UnitPrice * oi.Discount) / 100;
     } else {
         oli.UnitPrice = oi.UnitPrice;
     }
     return oli;
 }
 //END - Valooto Order Process
 
 
 public static void processOpportunitySplit(List<Opportunity> opptyList, Map<Id, Opportunity> oldOppMap, Set<Id> splitOpptyIdSet) {
     
     List<Opportunity> updateList = new List<Opportunity>();
     List<OpportunityLineItem> deleteList = new List<OpportunityLineItem>();
     List<OpportunityLineItem> lineItemUpdateList = new List<OpportunityLineItem>();
    
     ShGl_QueryConstants__mdt [] opptySplitQuery = [SELECT Query_String__c FROM ShGl_QueryConstants__mdt WHERE DeveloperName = 'OpportunitySplit_CopyQuery'];
     
     List<Opportunity> opptyListForSplitProcessing = Database.query(opptySplitQuery.get(0).Query_String__c +  ' WHERE Id IN :splitOpptyIdSet and Split__c = true');
     Map<Id, SObject> opptyMapForSplitProcessing = (Map<Id, SObject>) ShGl_CommonUtility.convertListToIdMap(opptyListForSplitProcessing);
     
     List<OpportunitySplitMapping__c> oppSplitMapping = [SELECT Default_Value__c,Field__c,From_Field__c,Id,Name,Prefix__c,Suffix__c,Skip_Update_if_child_has_value__c FROM OpportunitySplitMapping__c];
     
     if(!opptyMapForSplitProcessing.isEmpty()) {
         for(Opportunity vNewOpty : opptyList) {
             Opportunity vOldOpty = oldOppMap.get(vNewOpty.Id);
             
             //split Synch - Start
             System.debug('Inside OpportunityTriggerHelper : processOpportunitySplit : Id -> '+vNewOpty.id+' Split__c -> '+vNewOpty.split__c);
             System.debug('Inside OpportunityTriggerHelper : processOpportunitySplit : Old Amount -> '+vOldOpty.Amount+' New Amount -> '+vNewOpty.Amount);
             System.debug('Inside OpportunityTriggerHelper : processOpportunitySplit : Opportunity_Split_parent__c -> '+vNewOpty.Opportunity_Split_parent__c);
             System.debug('Inside OpportunityTriggerHelper : processOpportunitySplit : opptyMapForSplitProcessing -> '+opptyMapForSplitProcessing);
             if(vNewOpty.split__c && vNewOpty.Opportunity_Split_parent__c == null) {
                 
                 Double optyTotalValue = 0.00;
                 Double splitAmounts = 0.00;
                 boolean hasRealProducts = false;
                 OpportunityLineItem optySplitProductLineItem;
                 OpportunityLineItem staticAmountProductLineItem = null;
                 Opportunity primaryOpportunity = (Opportunity) opptyMapForSplitProcessing.get(vNewOpty.Id);
                 system.debug('Inside OpportunityTriggerHelper : processOpportunitySplit : primaryOpportunity -> '+primaryOpportunity);
                 system.debug('Inside OpportunityTriggerHelper : processOpportunitySplit : primaryOpportunity.OpportunityLineItems -> '+primaryOpportunity.OpportunityLineItems);
                 //get total value of the opportunity
                 for(OpportunityLineItem vLineItem : primaryOpportunity.OpportunityLineItems){
                     System.debug('Inside OpportunityTriggerHelper : processOpportunitySplit : vLineItem : '+vLineItem+'\n\n');
                     if(vLineItem.ProductCode == 'OPTY-SPLIT' && vLineItem.TotalPrice >= 0){
                         staticAmountProductLineItem = vLineItem;                 
                     } else if (vLineItem.ProductCode =='OPTY-SPLIT' && vLineItem.TotalPrice < 0.00){
                         
                     } else {
                         hasRealProducts = true;
                         if(primaryOpportunity.SBQQ__PrimaryQuote__c != null) {
                             if(primaryOpportunity.SBQQ__PrimaryQuote__c == vLineItem.SBQQ__QuoteLine__r.SBQQ__Quote__c){
                                 optyTotalValue = optyTotalValue + vLineItem.TotalPrice;
                             }
                         } else {
                             optyTotalValue = optyTotalValue + vLineItem.TotalPrice;
                         }
                     }
                 }
                 
                 if(hasRealProducts && staticAmountProductLineItem != null) {
                     deleteList.add(staticAmountProductLineItem);
                 }
                 if(optyTotalValue == 0.00 && !hasRealProducts && staticAmountProductLineItem != null) {
                     optyTotalValue = staticAmountProductLineItem.TotalPrice;
                 }
                 
                 for(Opportunity vChildOpty : primaryOpportunity.Split_Opportunities__r) {
                     if(vChildOpty.Split_Amount__c > 0.00) {
                         splitAmounts =+ vChildOpty.split_amount__c;
                     }
                 }
                 
                 //adjust the child split Opportunities
                 System.debug('Inside OpportunityTriggerHelper : processOpportunitySplit : optyTotalValue: '+optyTotalValue+' -> hasRealProducts: '+hasRealProducts+' -> staticAmountProductLineItem '+staticAmountProductLineItem);
                 System.debug('Inside OpportunityTriggerHelper : processOpportunitySplit : Split_Opportunities__r: '+primaryOpportunity.Split_Opportunities__r);
                 
                 
                 
                 for(Opportunity vChildOpty : primaryOpportunity.Split_Opportunities__r) {
                     vChildOpty = OpportunitySplitHelper.copyOpportunityFieldToSplit(vChildOpty, primaryOpportunity, oppSplitMapping);
                     System.debug('Inside OpportunityTriggerHelper : processOpportunitySplit : vChildOpty: '+vChildOpty+'\n\n\n');
                     if(vChildOpty.Split_Amount__c > 0.00) {
                         vChildOpty.Amount = vChildOpty.split_amount__c;
                     } else {
                         System.debug('Inside OpportunityTriggerHelper : processOpportunitySplit : vChildOpty percentage update: '+optyTotalValue+'\n\n\n');
                         vChildOpty.Amount = (optyTotalValue - splitAmounts) * (vChildOpty.Split_percentage__c / 100);
                     }
                     updateList.add(vChildOpty);
                     System.debug('Inside OpportunityTriggerHelper : processOpportunitySplit : udpateList: '+updateList+'\n\n\n');
                 }
                 //adjust the primary Opportunity
                 if(primaryOpportunity.Split_percentage__c == null){
                     primaryOpportunity.Split_percentage__c = 100;
                 }
                 
                 if(primaryOpportunity.Split_amount__c > 0){
                     primaryOpportunity.Amount = vNewOpty.split_amount__c;
                 }else {
                     System.debug('Inside OpportunityTriggerHelper : processOpportunitySplit : split_percentage__c : '+primaryOpportunity.Split_percentage__c);
                     primaryOpportunity.Amount = optyTotalValue * (primaryOpportunity.split_percentage__c / 100);
                 }
                 
                 optySplitProductLineItem = OpportunitySplitHelper.createOptySplitLineItem(primaryOpportunity, optyTotalValue-(((optyTotalValue-splitAmounts)*primaryOpportunity.split_percentage__c)/100));
                 System.debug('Inside OpportunityTriggerHelper : processOpportunitySplit : optyTotalValue: '+optyTotalValue+' -> '+splitAmounts+' -> '+optySplitProductLineItem+'\n\n\n');
                 System.debug('Inside OpportunityTriggerHelper : processOpportunitySplit : optySplitProductLineItem:'+optySplitProductLineItem);
                 lineItemUpdateList.add(optySplitProductLineItem); 
             }   
             //split Synch - End
         }
     }
     
     System.debug('Inside OpportunityTriggerHelper : processOpportunitySplit : Finally lineItemUpdateList -> '+lineItemUpdateList+'');
     System.debug('Inside OpportunityTriggerHelper : processOpportunitySplit : Finally updateList -> '+updateList+'');
     System.debug('Inside OpportunityTriggerHelper : processOpportunitySplit : Finally deleteList -> '+deleteList+'');
     if(!lineItemUpdateList.isEmpty()){
         upsert lineItemUpdateList;
     }
     if(!updateList.isEmpty()){
         update updateList;
     }
     
     if(!deleteList.isEmpty() && flowControll.deleteOptySplitAmount){
         delete deleteList;
     }

 }
 
 public static void increaseHoldoverCount (List<Id> userIdList) {
     system.debug('increaseHoldoverCount :: '+userIdList);
     Map<Id, User> userMap = new Map<Id, User> ([SELECT Id, Holdover_Count__c FROM User WHERE Id IN :userIdList]);
     for(Id usrId : userIdList) {
         if(userMap.containsKey(usrId)) {
             User usr = userMap.get(usrId);
             if(usr.Holdover_Count__c == null || usr.Holdover_Count__c < 0) 
                 usr.Holdover_Count__c = 0;
             
             usr.Holdover_Count__c ++;
             userMap.put(usrId, usr);
         }
     }
     update userMap.values();
 }
 
 public static void decreaseHoldoverCount (List<Id> userIdList) {
     Map<Id, User> userMap = new Map<Id, User> ([SELECT Id, Holdover_Count__c FROM User WHERE Id IN :userIdList]);
     for(Id usrId : userIdList) {
         if(userMap.containsKey(usrId)) {
             User usr = userMap.get(usrId);
             if(usr.Holdover_Count__c == null || usr.Holdover_Count__c <= 0) usr.Holdover_Count__c = 0;
             else usr.Holdover_Count__c --;
             userMap.put(usrId, usr);
         }
     }
     update userMap.values();
 }

 //SF-1002
 @future
 public static void unlockOpportunities(List<Id> opportunityIds){
     Approval.unlock(opportunityIds);
 }
 //EL-236
 public static void updatePartnerNameAtOrder(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpps) {
     Set<Id> opportunitiesChanged = new Set<Id>();
     for(Opportunity opp : newOpps){
         Opportunity oldOpp = oldOpps.get(opp.Id);
         if(oldOpp.Partner_Lookup__c != opp.Partner_Lookup__c || oldOpp.Polaris_Portal_Contact__c != opp.Polaris_Portal_Contact__c){
             opportunitiesChanged.add(opp.Id);
         }
     }
     
     
     
     List<Order> ordersToUpdate = new List<Order>();
     for(Order ord: [Select Id, OpportunityId, POC_Opportunity__c, Opportunity.Partner_Lookup__c, Opportunity.Polaris_Portal_Contact__c, Opportunity.Polaris_Portal_Contact__r.Email from Order where OpportunityId in :opportunitiesChanged]){
         if(ord.OpportunityId != null){
             Order ordToUpdate = new Order(Id=ord.Id, Partner_Name__c = ord.Opportunity.Partner_Lookup__c, 
                 Polaris_Contact__c = ord.Opportunity.Polaris_Portal_Contact__c);
             if(ord.Opportunity.Polaris_Portal_Contact__c != null){
                 ordToUpdate.Polaris_Contact_Email__c = ord.Opportunity.Polaris_Portal_Contact__r.Email;
             }
             ordersToUpdate.add(ordToUpdate);
         }
     }
     update ordersToUpdate;
 }

 //SAL-743
 //To Calculate the hours of an Opportunity in each Stage
 public static void ageInOppStageCalculation(List<Opportunity> OppList,Map<Id, Opportunity> oldOppMap){
     //get stage and its hoursInStage field API from Custom Setting 
     Map<String,OppStageAndHours__c> mapOfOppStages=OppStageAndHours__c.getAll();
     for(Opportunity o : OppList){
              Opportunity oOld=oldOppMap.get(o.id);
              //check if stage has changed
              if(o.StageName != oOld.StageName){
                  o.Time_of_Last_Stage_Change__c = datetime.now();
                  datetime previousStageChangeDate=oOld.Time_of_Last_Stage_Change__c ==null?oOld.createdDate:oOld.Time_of_Last_Stage_Change__c;
                   //if stage has changed, calculate the time how long opportunity is in previous stage
                   Long milliseconds = o.Time_of_Last_Stage_Change__c.getTime() - previousStageChangeDate.getTime();
                   Long seconds = milliseconds / 1000;
                   Long minutes = seconds / 60;
                   Long hoursLong = minutes / 60;
                   Integer hours = integer.valueof(hoursLong);
                   //check if custom setting has prior StageName
                   if(mapOfOppStages!=null && !mapOfOppStages.isEmpty()){
                       if(mapOfOppStages.containsKey(oOld.StageName)){
                           string HoursFieldAPI=mapOfOppStages.get(oOld.StageName).HoursInStage__c;
                           Decimal priorHours =(Decimal)o.get(HoursFieldAPI) ;
                           if(priorHours == null){
                                   priorHours =0;
                           }
                           priorHours = priorHours + hours;
                           o.put(HoursFieldAPI,priorHours);
                       }  
                   }   
              }  
     }                                     
 }
   
//End SAL-743

//SAL-823 : Polaris field logic update
//Desc : Update Polaris region field based opportunity owner's theatre field
public static void updatePolarisRegionField(){
 Map<Id,Id> OppOwnerMap = new Map<Id,Id>();
 for(Opportunity op : (List<Opportunity>) Trigger.new){
     if(op.StageName!=null && op.Has_Polaris_Product__c && string.Isblank(op.Polaris_Region__c)){
         OppOwnerMap.put(op.Id,op.OwnerId);
     }
 }
 
 Map<Id,User> userMap = new Map<Id,User>();
 if(OppOwnerMap!=null && OppOwnerMap.size()>0){
     for(User usr : [Select Id,Theatre__c from User where Id in :OppOwnerMap.values()]){
         userMap.put(usr.Id,usr);
     }
 }
 
 if(userMap!=null && userMap.size()>0){
     for(Opportunity opp : (List<Opportunity>) Trigger.new){
         if(OppOwnerMap.get(opp.Id)!=null && opp.OwnerId == OppOwnerMap.get(opp.Id) && userMap.get(opp.OwnerId)!=null && userMap.get(opp.OwnerId).Theatre__c!=null){
             if(userMap.get(opp.OwnerId).Theatre__c == 'EMEA'){
                 opp.Polaris_Region__c = 'Europe';
             }else{
                 opp.Polaris_Region__c = 'US';
             }
         }
     }
 }
}
//End of SAL-823
 //SAL-1052 -- Opportunity Issue Tracker and Debrief
 public static void updateIssueTrackers(List<Opportunity> opportunityList, Map<Id,Opportunity> oldMap) {
     Map<Id, Opportunity_Debrief__c> issueTrackerMap = new Map<Id, Opportunity_Debrief__c>([Select Id, Opportunity__c, Opportunity_Escalation_Stage__c from Opportunity_Debrief__c where Opportunity__c IN : opportunityList]);
     system.debug('issueTrackerMap: ' + issueTrackerMap);
     List<Opportunity_Debrief__c> opportunityDebriefUpdates = new List<Opportunity_Debrief__c>();
     if(oldMap != null && !oldMap.isEmpty()){
         for(Opportunity o : opportunityList){
             if(oldMap.containskey(o.Id) && o.Escalation_Stage__c != oldMap.get(o.Id).Escalation_Stage__c && o.IsClosed == FALSE){
                 system.debug('o: ' + o);
                 for(Opportunity_Debrief__c od : issueTrackerMap.values()){
                     system.debug('od: ' + od);
                     if(od.Opportunity__c == o.Id){
                         Opportunity_Debrief__c odu = new Opportunity_Debrief__c();
                         odu.Id = od.Id;
                         odu.Opportunity_Escalation_Stage__c = o.Escalation_Stage__c;
                         opportunityDebriefUpdates.add(odu);
                         system.debug('odu: ' + odu);
                     }
                 }
             }
         }
     }
     system.debug('opportunityDebriefUpdates: ' + opportunityDebriefUpdates);
     if(!opportunityDebriefUpdates.isEmpty()){
         Update opportunityDebriefUpdates;
     }
 }
//END of SAL-1052 -- Opportunity Issue Tracker and Debrief

 // Mosaic Process
 public static void manageOpportunityTeamMembers(Set<Id> mosaicOpportunityIdSet, Set<Id> nonMosaicOpportunityIdSet) {
     
     Map<Id, String> mapOpportunityIdWithRegion = new Map<Id, String>();
     
     for (Opportunity objOpportunity :[Select Id,Owner.Region__c From Opportunity Where Id IN : mosaicOpportunityIdSet]) {
         if (String.isBlank(objOpportunity.Owner.Region__c)) {
             mapOpportunityIdWithRegion.put(objOpportunity.Id, NULL);
         } else {
             mapOpportunityIdWithRegion.put(objOpportunity.Id, objOpportunity.Owner.Region__c.toLowerCase());
         }
     }
     
     Map<String, Set<Id>> mapRegionWithMosaicUserIds = new Map<String, Set<Id>>();
     //Set<Id> setMosaicUser = new Set<Id>();
     Set<Id> setMosaicRepUserId = new Set<Id>();
     Set<Id> setMosaicSeUserId = new Set<Id>();
     Set<Id> setMosaicUserIdForAll = new Set<Id>();
     for (Mosaic_Opportunity_Management_Mapping__mdt objMosaicMapping :[Select Id, Mosaic_Rep_Id__c, Mosaic_SE_Id__c, Opportunity_Owner_Region__c From Mosaic_Opportunity_Management_Mapping__mdt Where Opportunity_Owner_Region__c IN :mapOpportunityIdWithRegion.values() Or Opportunity_Owner_Region__c = '']) {
         if (String.isBlank(objMosaicMapping.Opportunity_Owner_Region__c)) {
             if (String.isNotBlank(objMosaicMapping.Mosaic_Rep_Id__c)) {
                 setMosaicUserIdForAll.add(objMosaicMapping.Mosaic_Rep_Id__c);
                 setMosaicRepUserId.add(objMosaicMapping.Mosaic_Rep_Id__c);
             }
             if (String.isNotBlank(objMosaicMapping.Mosaic_SE_Id__c)) {
                 setMosaicUserIdForAll.add(objMosaicMapping.Mosaic_SE_Id__c);
                 setMosaicSeUserId.add(objMosaicMapping.Mosaic_SE_Id__c);
             }
           //  setMosaicUser.addAll(setMosaicUserIdForAll);
         } else {
             Set<Id> setMosaicUserIds = new Set<Id>();
         
             if (String.isNotBlank(objMosaicMapping.Mosaic_Rep_Id__c)) {
                 setMosaicUserIds.add(objMosaicMapping.Mosaic_Rep_Id__c);
                 setMosaicRepUserId.add(objMosaicMapping.Mosaic_Rep_Id__c);
             }
             if (String.isNotBlank(objMosaicMapping.Mosaic_SE_Id__c)) {
                 setMosaicUserIds.add(objMosaicMapping.Mosaic_SE_Id__c);
                 setMosaicSeUserId.add(objMosaicMapping.Mosaic_SE_Id__c);
             }
           //  setMosaicUser.addAll(setMosaicUserIds);
             
             if (!setMosaicUserIds.isEmpty()) {
                 if (mapRegionWithMosaicUserIds.containsKey(objMosaicMapping.Opportunity_Owner_Region__c.toLowerCase())) {
                     setMosaicUserIds.addAll(mapRegionWithMosaicUserIds.get(objMosaicMapping.Opportunity_Owner_Region__c.toLowerCase()));
                 }
                 mapRegionWithMosaicUserIds.put(objMosaicMapping.Opportunity_Owner_Region__c.toLowerCase(), setMosaicUserIds);
             }
         }
     }
     
     Map<Id, Set<Id>> mapOpportunityIdWithTeamMemberId = new Map<Id, Set<Id>>();
     for (Id OpportunityId : mapOpportunityIdWithRegion.keySet()) {
         Set<Id> setMosaicUserIdForTeamMember = new Set<Id>();
         
         if (!setMosaicUserIdForAll.isEmpty()) {
             setMosaicUserIdForTeamMember.addAll(setMosaicUserIdForAll);
         }
         if (mapRegionWithMosaicUserIds.containsKey(mapOpportunityIdWithRegion.get(OpportunityId))) {
             setMosaicUserIdForTeamMember.addAll(mapRegionWithMosaicUserIds.get(mapOpportunityIdWithRegion.get(OpportunityId)));
         }
         mapOpportunityIdWithTeamMemberId.put(OpportunityId, setMosaicUserIdForTeamMember);
     }
     
     List<OpportunityTeamMember> listOpportunityTeamMemberToDelete = new List<OpportunityTeamMember>();
     
     for (OpportunityTeamMember opportunityTeamMemberObj :[SELECT Id,OpportunityId,UserId From OpportunityTeamMember WHERE (OpportunityId IN :mosaicOpportunityIdSet AND (UserId IN :setMosaicRepUserId OR UserId IN :setMosaicSeUserId) ) OR (OpportunityId IN :nonMosaicOpportunityIdSet AND Is_Auto_Added__c = TRUE)]) {
         if (nonMosaicOpportunityIdSet.contains(opportunityTeamMemberObj.OpportunityId)) {
             listOpportunityTeamMemberToDelete.add(opportunityTeamMemberObj);
         } else if (mapOpportunityIdWithTeamMemberId.containsKey(opportunityTeamMemberObj.OpportunityId)) {
             Set<Id> setUserIds = mapOpportunityIdWithTeamMemberId.get(opportunityTeamMemberObj.OpportunityId);
             if (setUserIds.contains(opportunityTeamMemberObj.UserId)) {
                 setUserIds.remove(opportunityTeamMemberObj.UserId);
             }
             mapOpportunityIdWithTeamMemberId.put(opportunityTeamMemberObj.OpportunityId, setUserIds);
         }
     }
     
     List<OpportunityTeamMember> listOpportunityTeamMemberToInsert = new List<OpportunityTeamMember>();
     for (Id opportunityId : mapOpportunityIdWithTeamMemberId.keySet()) {
         for (Id userId : mapOpportunityIdWithTeamMemberId.get(opportunityId)) {
             listOpportunityTeamMemberToInsert.add(new OpportunityTeamMember(OpportunityAccessLevel = 'Edit',OpportunityId = opportunityId,UserId = userId,Is_Auto_Added__c = TRUE,TeamMemberRole = setMosaicRepUserId.contains(userId) ? 'Sales Manager' : 'Sales Engineer'));
         }
     }
     
     if (!listOpportunityTeamMemberToInsert.isEmpty()) {
         insert listOpportunityTeamMemberToInsert;
     }
     
     if (!listOpportunityTeamMemberToDelete.isEmpty()) {
         delete listOpportunityTeamMemberToDelete;
     }
 }
 // Added for SAL1638
 public static boolean sendEmailAlertOnOppt(Set<ID> OppID){
     List<Opportunity> AllOppt = new List<Opportunity> ();
     Set<ID> optToUpdate = new Set<ID> ();
     AllOppt = [select id ,name,Opportunity_Sub_Type__c,RenewalOwner__r.Email,Owner.Manager.Email,Send_Hold_Off_Email__c,owner.Email from Opportunity where id = :OppID];
     EmailTemplate et=[Select id,Name, Subject, Body from EmailTemplate where name ='Order-Opportunity Not In Stage 6 Notification' limit 1];
     Email_Preferences__mdt mdt = [Select Id,from__c,Receipient__c, cc__c, Email_Subject__c from Email_Preferences__mdt where MasterLabel = 'POReceivedNotification' LIMIT 1];
     OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address =: mdt.from__c];
     List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
     if(AllOppt.size()>0){
         for( Opportunity oppr : AllOppt){   
             String OpportunityOwner = oppr.owner.Email;
             String ccmail1=mdt.Receipient__c;
             String ccmail2=mdt.cc__c;
             String ManagerEmail ;
             String RenewalOwner;
             String[] toAddresses = new String[] {OpportunityOwner};
             String[] ccAddresses = new String[] {ccmail1,ccmail2};
             Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(et.Id, null, oppr.Id);
             mail.setToAddresses(toAddresses);
             
             if(String.isNotBlank(oppr.Owner.Manager.Email)){
             ManagerEmail = oppr.Owner.Manager.Email;
             ccAddresses =new String[] {ccmail1,ccmail2,ManagerEmail};
             }
           
             if(oppr.Opportunity_Sub_Type__c=='Renewal' && String.isNotBlank(oppr.RenewalOwner__r.Email)){
             RenewalOwner=oppr.RenewalOwner__r.Email;
             ccAddresses =new String[] {ccmail1,ccmail2,RenewalOwner};
                 if(String.isNotBlank(oppr.Owner.Manager.Email)){
                 ManagerEmail = oppr.Owner.Manager.Email;
                 ccAddresses =new String[] {ccmail1,ccmail2,ManagerEmail,RenewalOwner};
                 }
             }
             mail.setCCAddresses(ccAddresses);
             
             if ( owea.size() > 0 ) {
                   mail.setOrgWideEmailAddressId(owea.get(0).Id);
                 }
             mail.setSaveAsActivity(false);
             emails.add(mail);
              }
         }
      Messaging.SendEmailResult[] results= Messaging.sendEmail(emails);
            if(results.size()> 0){return true;
            } return true;
        }
    */
}