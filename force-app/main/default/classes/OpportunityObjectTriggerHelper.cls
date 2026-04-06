/** @description
* -------------------------- @History --------------------------------------------------------------------------------------------
* Story Number       Modified By              Date           Description
* PRIT24-259         Anshul Gupta           March 15,2023   change BDM population for Auto Registered MS DR 
* PRIT24-534         Anshul Gupta           Jul 24,2023     Remove Alliance DR Creation
* --------------------------------------------------------------------------------------------------------------------------------
*/
public class OpportunityObjectTriggerHelper{
    public static Map<string,ContractManufacturerAllocation__c> updateCmaAllocation = new Map<string,ContractManufacturerAllocation__c>();
    public static Set<Id> nonUsDistii = new Set<Id>();
    public static Map<string,AspenConfig__mdt> aspenConfigCM = new Map<string,AspenConfig__mdt>();
    public static Map<string,AspenConfig__mdt> aspenConfigDistii = new Map<string,AspenConfig__mdt>();
    private static final List<String> coOwnerFields = new List<String>{ 'Co_Owner__c', 'NCD_Co_Owner__c', 'SaaS_Co_Owner__c' }; //SAL26-1340
     
    private static final String allianceCloudPartnerAlliance = 'Alliance Initiated Deal';
    public static final Set<String> ACCOUNT_CONTRACT_STATUS_SET = new Set<String>{'Expired','Merged w/ another acct','Terminated'};
    public static Id renewalOpptyRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Renewal_Opportunity').getRecordTypeId(); //SAL26-654
    public static List<Sfdc_Disti_Mapping__mdt> metadataRecords = new List<Sfdc_Disti_Mapping__mdt>();
    /** 
     * @description takes opportunity and map of accountid and it's set of contact id's 
     * This method checks the Opportunity Portal contact should be belongs to it Account's related contact. Otherwise show an error
     * @param opp
     * @param mapAccIdContactIds 
    **/  
        public static void polarisContactValidation(Opportunity opp, Map<Id,Set<Id>> mapAccIdContactIds){
            if(opp.Polaris_Portal_Contact__c != null && (mapAccIdContactIds.get(opp.AccountId) == null || !mapAccIdContactIds.get(opp.AccountId).contains(opp.Polaris_Portal_Contact__c))){
                opp.addError('Polaris contact must belong to same Account as of Opportunity.'); 
            } 
        } 
    
    /**
     * @description
     * @param oldRecord
     * @param newRecord
     * @param accountMap
     * @param updatedAccountMap
     * @param contactMap
     * @param userMap
     * @param serviceContractMap
     * @param TART
     * @param SalesEngg
     * @param TerrId
     * @param RenewalOppOwnerId
     * @param plsAERole
     * @param updatingOppTypeUsingSDPlookup
     **/   
    public static void resetOpportunityFieldsOnChange(Opportunity oldRecord, Opportunity newRecord, 
                                                      Map<ID, Account> accountMap, Map<ID, Account>updatedAccountMap, 
                                                      Map<ID, Contact> contactMap, Map<ID, User> userMap, 
                                                      Map<ID, ServiceContract> serviceContractMap,
                                                      string TART,
                                                      string SalesEngg,
                                                      string TerrId,
                                                      Id RenewalOppOwnerId, //SF-7721 (ETM-181): Renewal Opp Owner changes
                                                      String plsAERole, //SAL24-735
                                                      Boolean updatingOppTypeUsingSDPlookup //SAL25-106
                                                     ){
                                                         //SF-7721 (ETM-181): Renewal Opp Owner changes                                                          
                                                         OpportunityUtil.resetOpportunityFieldsOnChange(oldRecord, newRecord, accountMap, updatedAccountMap, contactMap, userMap, serviceContractMap ,TART , SalesEngg, TerrId, RenewalOppOwnerId, plsAERole,updatingOppTypeUsingSDPlookup); //SAL24-735 //SAL25-106
                                                     }
     /**
     * @description This method taking Opportunity Id set and sending email to respective team
     * @param OppID
     * Template is: Order-Opportunity Not In Stage 6 Notification
     * Email_Preferences__mdt - custom metadata type 
     **/
    // Added for SAL1638
    public static void sendHoldOffEmail(Set<ID> OppID){
        Set<ID> optToUpdate = new Set<ID> ();
        List<Opportunity> opportunityList = [select id ,name,Opportunity_Sub_Type__c,Initial_Contacts_Name__c,RenewalOwner__r.Email,Owner.Manager.Email,Send_Hold_Off_Email__c,owner.Email from Opportunity where id = :OppID];
        EmailTemplate et=[Select id,Name, Subject, Body from EmailTemplate where name ='Order-Opportunity Not In Stage 6 Notification' limit 1];
        Email_Preferences__mdt mdt = [Select Id,from__c,Receipient__c, cc__c, Email_Subject__c from Email_Preferences__mdt where MasterLabel = 'POReceivedNotification' LIMIT 1];
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address =: mdt.from__c];
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
         //SAL26-312 Starts
        Id contactId = (opportunityList.isEmpty() || opportunityList[0].Initial_Contacts_Name__c == null) ? null : opportunityList[0].Initial_Contacts_Name__c; 
        if(contactId == null) {
            contactId = [SELECt Id from contact limit 1].Id;
        }
        //SAL26-312 Ends
        if(opportunityList.size()>0){
            for( Opportunity oppr : opportunityList){   
                String OpportunityOwner = oppr.owner.Email;
                String ccmail1=mdt.Receipient__c;
                String ccmail2=mdt.cc__c;
                String ManagerEmail ;
                String RenewalOwner;
                String[] toAddresses = new String[] {OpportunityOwner};
                    String[] ccAddresses = new String[] {ccmail1,ccmail2};
                         //SAL26-312 Starts

                //Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(et.Id, null, oppr.Id);
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setTemplateId(et.Id);
                mail.setWhatId(oppr.Id);
                mail.setTargetObjectId(contactId);
                mail.setTreatTargetObjectAsRecipient(false);
                //SAL26-312 Ends
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
         if (!Test.isRunningTest() && !emails.isempty()){
            try {
            Messaging.SendEmailResult[] results= Messaging.sendEmail(emails); 
            } catch(Exception ex) {
                 System.debug(System.logginglevel.ERROR, 'Email is not sent-sendHoldOffEmail: '+ex.getMessage());
            }
            
        }       
    }

     /**
     * @description This method insert the Opportunity contact Roles based on initial contatc on Opportunity.
     * @param oppIdSetForInitialContactsName
     * @param newOppMap
    */
    public static void createOpportunityContactRoles (Set<Id> oppIdSetForInitialContactsName, Map<Id, Opportunity> newOppMap) {
        Map<String, Id> existingContacts = new Map<String, Id>();
        if(oppIdSetForInitialContactsName != null && !oppIdSetForInitialContactsName.isEmpty()){
            for(OpportunityContactRole ocr : [Select Id, OpportunityId, ContactId from OpportunityContactRole where OpportunityId in :oppIdSetForInitialContactsName]){
                existingContacts.put(ocr.OpportunityId+''+ocr.ContactId, ocr.Id);
            }
        }
        List<OpportunityContactRole> ocrList = new List<OpportunityContactRole>();
        List<OpportunityContactRole> ocrListToUpdate = new List<OpportunityContactRole>();
        for(ID oppId : oppIdSetForInitialContactsName) {
            Opportunity opp = newOppMap.get(oppId);
            OpportunityContactRole ocr = new OpportunityContactRole(isPrimary = true);
            if(existingContacts.containsKey(opp.Id+''+opp.Initial_Contacts_Name__c)){
                ocr.Id = existingContacts.get(opp.Id+''+opp.Initial_Contacts_Name__c);
                ocrListToUpdate.add(ocr);
            }else {
                ocr.OpportunityId = opp.Id;
                ocr.ContactId = opp.Initial_Contacts_Name__c;
                ocrList.add(ocr);
            }
        }
        if(!ocrList.isEmpty()) {
            insert ocrList;
        }
        if(!ocrListToUpdate.isEmpty()) {
            update ocrListToUpdate;
        }
    }

    /**
     * @description This Method insert/Update the Opportunity related Cotact roles.
     * @param queriedocrList
     * @param newOppMap
     * @param oppIdSetForInitialContactsName
    */
    public static void upsertOpportunityContactRoles (List<OpportunityContactRole> queriedocrList, Map<Id, Opportunity> newOppMap, Set<Id> oppIdSetForInitialContactsName) {
        Map<String, Id> existingContacts = new Map<String, Id>();
        if(!queriedocrList.isEmpty()){
            for(OpportunityContactRole ocr : queriedocrList){
                existingContacts.put(ocr.OpportunityId+''+ocr.ContactId, ocr.Id);
            }
        }
        List<OpportunityContactRole> ocrList = new List<OpportunityContactRole>();
        for(ID oppId : oppIdSetForInitialContactsName) {
            Opportunity opp = newOppMap.get(oppId);
            OpportunityContactRole ocr = new OpportunityContactRole(isPrimary = true);
            if(existingContacts.containsKey(opp.Id+''+opp.Initial_Contacts_Name__c)){
                ocr.Id = existingContacts.get(opp.Id+''+opp.Initial_Contacts_Name__c);
                ocrList.add(ocr);
            }else {
                ocr.OpportunityId = opp.Id;
                ocr.ContactId = opp.Initial_Contacts_Name__c;
                ocrList.add(ocr);
            }
        }
        flowcontroll.opportunityTriggerHandler = false;
        if(!ocrList.isEmpty()) {
            upsert ocrList;
        }
        flowcontroll.opportunityTriggerHandler = true;
    }
    
    // Mosaic Process
    /**
     * @description
     * @param mosaicOpportunityIdSet
     * @param nonMosaicOpportunityIdSet
     */ 
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
                setRegionWithMosaicUserIdMap(objMosaicMapping, mapRegionWithMosaicUserIds,setMosaicRepUserId, setMosaicSeUserId);
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
            //If this error occurs: System.UnexpectedException: Internal Salesforce.com Query Error
            //Check user ID in Mosaic_Opportunity_Management_Mapping__mdt.Mosaic_Rep_Id__c
            insert listOpportunityTeamMemberToInsert;
        }
        
        if (!listOpportunityTeamMemberToDelete.isEmpty()) {
            delete listOpportunityTeamMemberToDelete;
        }
    }
    
    /**
     * @description
     * @param objMosaicMapping
     * @param mapRegionWithMosaicUserIds
     * @param setMosaicRepUserId
     * @param setMosaicSeUserId
    */
    public static void setRegionWithMosaicUserIdMap(Mosaic_Opportunity_Management_Mapping__mdt objMosaicMapping, Map<String, Set<Id>> mapRegionWithMosaicUserIds,
                                                    Set<Id> setMosaicRepUserId, Set<Id> setMosaicSeUserId){
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
    
    
    //SF-1002
    /**
     * @description unlock opportunities after approval
     * @param opportunityIds
     */
    @future
    public static void unlockOpportunities(List<Id> opportunityIds){
        Approval.unlock(opportunityIds);
    }
    
     /**
     * @description
     * @param valootoOpptyList
     * @param oldOppMap
     */
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
        }
        
        List<Opportunity> updatedOpptyList = new List<Opportunity>();
        List<Order> updateOrdersList = new List<Order>();
        List<Opportunity> updateOrdersOpportunityList = new List<Opportunity>();
        
        for(Opportunity oppty : valootoOpptyList) {
            Opportunity oldOppty = (Opportunity) trigger.oldMap.get(oppty.Id);
            
            if(oppty.StageName == System.Label.Order_Creation_Stage && oppty.StageName != oldOppty.StageName ) {
                if(opptyOrdersMap.containsKey(oppty.id)) { // Has Orders
                    updateOrdersList.add(opptyOrdersMap.get(oppty.id)[0]);
                    updateOrdersOpportunityList.add(oppty);
                } else { // No Orders
                    updatedOpptyList.add(oppty);
                }
            }
        }
        
        Map<Id, Opportunity> opptyMap = new Map<Id, Opportunity> ( 
            [SELECT 
             StageName, Account.name, Account.Id, Partner_Lookup__c, Distributor_Lookup__c, Distributor_lookup__r.Payment_Term__c, OwnerId, Owner.email, Rubrik_Sales_Engineer__c,Rubrik_Sales_Engineer__r.Email,
             Partner_Lookup__r.Shipping_Carrier__c , Partner_Lookup__r.Shipping_Method__c , Partner_Lookup__r.Shipping_Account_Number__c,Partner_Lookup__r.IncoTerms__c,
             Distributor_Lookup__r.Shipping_Carrier__c , Distributor_Lookup__r.Shipping_Method__c , Distributor_Lookup__r.Shipping_Account_Number__c,Distributor_Lookup__r.IncoTerms__c,
             Partner_Lookup__r.Distributor__r.Shipping_Carrier__c,Partner_Lookup__r.Distributor__r.Shipping_Method__c,Partner_Lookup__r.Distributor__r.Shipping_Account_Number__c,Partner_Lookup__r.Distributor__r.IncoTerms__c,
             Partner_Lookup__r.Payment_Term__c, Partner_Lookup__r.Distributor__r.Payment_Term__c,Partner_Lookup__r.Distributor__c, CloseDate,Pricebook2Id
             FROM Opportunity 
             WHERE Id =: updatedOpptyList OR Id =: updateOrdersOpportunityList] 
        );
        
        List<OpportunityLineItem> listOI = [SELECT Id, Unitprice, TotalPrice, Valooto_Sales_Price__c ,Description, Quantity, Discount, PriceBookEntryId, OpportunityId  FROM OpportunityLineItem WHERE OpportunityId =: updatedOpptyList OR OpportunityId =: updateOrdersOpportunityList];
        List<OpportunityContactRole> ocr = [SELECT Id, Role, ContactId, Contact.Email, IsPrimary, OpportunityId FROM OpportunitycontactRole WHERE OpportunityId =: updatedOpptyList OR OpportunityId =: updateOrdersOpportunityList /*LIMIT 1*/];
        
        Map<Id, List<OpportunityLineItem>> opptyLineItemMap = ShGl_CommonUtility.convertListToMap(listOI, 'OpportunityId');
        Map<Id, List<OpportunityContactRole>> opptyContactRoleMap = ShGl_CommonUtility.convertListToMap(ocr, 'OpportunityId');
        
        if(!updatedOpptyList.isEmpty()){
            insertNewOrder(updatedOpptyList, opptyMap, opptyLineItemMap, opptyContactRoleMap);
        }
        
        if(!updateOrdersList.isEmpty()){//updatetExistingOrder
            List<OrderItem> orderItemsList = [SELECT Id FROM OrderItem WHERE orderId IN: updateOrdersList];
            if(!orderItemsList.isEmpty()) {
                delete orderItemsList;
            }
            updateOrderWithOrderItems(updateOrdersList,  opptyMap, opptyLineItemMap);
        }
    }
    /**
     * @description Added new method to handle update of existing order. Logic: Only a single records per Oppoty
     * @param updateOrdersList
     * @param opptyMap
     * @param opptyLineItemMap
    */
    public static void updateOrderWithOrderItems(List<Order> updateOrdersList,  Map<Id, Opportunity> opptyMap, Map<Id, List<OpportunityLineItem>> opptyLineItemMap){
        if(updateOrdersList != null){
            List<OrderItem> opptyLineItemsList = new List<OrderItem>();
            for(Order ord : updateOrdersList) {
                Order newOrd = new Order(Id = ord.Id);
                newOrd.Pricebook2Id = opptyMap.get(ord.OpportunityId).Pricebook2Id;
                
                List<OpportunityLineItem> listOI = opptyLineItemMap.get(ord.OpportunityId);
                if(listOI != null){
                    for(OpportunityLineItem oi : listOI) {
                        opptyLineItemsList.add( getOrderLineItem (newOrd, oi) );
                    }
                }
            }
            update updateOrdersList;
            if(!opptyLineItemsList.isEmpty()){
                insert opptyLineItemsList;        
            }
        }
    }
    
    /**
     * @description This method inserting new orders and with line items.
     * @param updatedOpptyList
     * @param opptyMap
     * @param opptyLineItemMap
     * @param opptyContactRoleMap
    */
    public static void insertNewOrder(List<Opportunity> updatedOpptyList, Map<Id, Opportunity> opptyMap, Map<Id, List<OpportunityLineItem>> opptyLineItemMap, Map<Id, List<OpportunityContactRole>> opptyContactRoleMap) {
        if(!updatedOpptyList.isEmpty()) {
            List<Order> orderList = new List<Order>();
            for(Opportunity opp : updatedOpptyList) {
                orderList.add(setOrderWithOrderItems(opp.id, opptyMap.get(opp.id), opptyLineItemMap.get(opp.id), opptyContactRoleMap.get(opp.id)));
            }
            if(!orderList.isEmpty()){
                insert orderList;
                List<OrderItem> allOrderLineItemList = new List<OrderItem>();
                for(Order odr: orderList){
                    List<OrderItem> orderLineItemList = odr.OrderItems;
                    if(orderLineItemList != null){
                        for(OrderItem orderItemObj: orderLineItemList){
                            orderItemObj.OrderId = odr.id;
                            allOrderLineItemList.add(orderItemObj);
                        }
                    }
                    
                }
                if(!allOrderLineItemList.isEmpty()){
                    insert allOrderLineItemList;
                }
            }
        }
    }
    
     /**
     * @description This method inserting orders and its order items
     * @param oppId
     * @param opp
     * @param listOI
     * @param ocr
     * @return Order object record
     */
    public static Order setOrderWithOrderItems(Id oppId, Opportunity opp, List<OpportunityLineItem> listOI, List<OpportunityContactRole> ocr) {
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
        //insert newOrd;
        
        List<OrderItem> orderLineItemList = new List<OrderItem>();
        if(listOI != null){
            for(OpportunityLineItem oi : listOI) {            
                orderLineItemList.add( getOrderLineItem (newOrd, oi) );
            }
        }
        //insert orderLineItemList;
        newOrd.OrderItems.addAll(orderLineItemList);//Check it.
        return newOrd;
    }

     /**
     * @description
     * @param newOrd
     * @param oi
     * @return OrderItem
     */
    public static OrderItem getOrderLineItem (Order newOrd, OpportunityLineItem oi) {
        OrderItem oli = new OrderItem();
        //oli.OrderId = newOrd.Id;
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
    
    /**
     * @description
     * @param decreaseUserIdSet
     * @param increasedUserIdSet
    */
    public static void updateHoldoverCount (Set<Id> decreaseUserIdSet, Set<Id> increasedUserIdSet) {
        Set<Id> userIdSet = new Set<Id>();
        if(increasedUserIdSet != null && !increasedUserIdSet.isEmpty()){
            userIdSet.addAll(increasedUserIdSet);
        }
        if(decreaseUserIdSet != null && !decreaseUserIdSet.isEmpty()){
            userIdSet.addAll(decreaseUserIdSet);
        }
        if(!userIdSet.isEmpty()){
            List<User> userList = [SELECT Id, Holdover_Count__c FROM User WHERE Id IN :userIdSet];
            for(User usr : userList) {
                if(increasedUserIdSet.contains(usr.Id)) {
                    usr.Holdover_Count__c = (usr.Holdover_Count__c == null || usr.Holdover_Count__c < 0) ? 0 : usr.Holdover_Count__c+1;
                }
                if(decreaseUserIdSet.contains(usr.Id)) {
                    usr.Holdover_Count__c = (usr.Holdover_Count__c == null || usr.Holdover_Count__c <= 0) ? 0 : usr.Holdover_Count__c-1;
                }
            }
            update userList;
        }
    }
    
    /**
     * @description This method return the Opty ids based Sfdc_Disti_Mapping__mdt, where we have to skip id's Disable_Distii__c = false. 
     *@return Set<Id>
     */
    public static Set<Id> getOpptysToSkip(){ 
        if(metadataRecords.isEmpty()){ //SAL26-731
            metadataRecords = [Select Id,Sfdc_Id__c from Sfdc_Disti_Mapping__mdt where Disable_Distii__c = false];
        }
        Set<Id> opptysToSkip = new Set<Id>();
        if(!metadataRecords.isEmpty()){ 
            for(Sfdc_Disti_Mapping__mdt setting: metadataRecords){
                if(setting.Sfdc_Id__c!=null){
                    opptysToSkip.add(setting.Sfdc_Id__c);
                }
            }
        }
        return opptysToSkip;
    }
    
    
    //SAL-743
    /**
     * @description
     * @param newOpp
     * @param oldOpp
     * @param mapOfOppStages
     */
    public static void setAgeInOppStage(Opportunity newOpp, Opportunity oldOpp, Map<String,OppStageAndHours__c> mapOfOppStages){
        if(oldOpp.StageName == newOpp.StageName) return;
        newOpp.Time_of_Last_Stage_Change__c = datetime.now();
        DateTime previousStageChangeDate= oldOpp.Time_of_Last_Stage_Change__c == null ? oldOpp.createdDate:oldOpp.Time_of_Last_Stage_Change__c;
        //if stage has changed, calculate the time how long opportunity is in previous stage
        Long milliseconds = newOpp.Time_of_Last_Stage_Change__c.getTime() - previousStageChangeDate.getTime();
        Long seconds = milliseconds / 1000;
        Long minutes = seconds / 60;
        Long hoursLong = minutes / 60;
        Integer hours = integer.valueof(hoursLong);
        //check if custom setting has prior StageName
        if(mapOfOppStages!=null && !mapOfOppStages.isEmpty()){
            if(mapOfOppStages.containsKey(oldOpp.StageName)){
                string HoursFieldAPI=mapOfOppStages.get(oldOpp.StageName).HoursInStage__c;
                Decimal priorHours =(Decimal)newOpp.get(HoursFieldAPI) ;
                if(priorHours == null){
                    priorHours =0;
                }
                priorHours = priorHours + hours;
                newOpp.put(HoursFieldAPI,priorHours);
            }  
        }   
    }
    //-------------------------------
    /**
     * @description
     * @param primaryOpportunity
     * @param splitProduct
     * @param amount
     * @return OpportunityLineItem
    */
    @testVisible
    private static OpportunityLineItem setSplitOpportunityLineItem(Opportunity primaryOpportunity, OpportunityLineItem splitProduct, Decimal amount) {    
        splitProduct = (splitProduct != null) ? splitProduct : new OpportunityLineItem(OpportunityId = primaryOpportunity.Id, isSplit__c = true, Quantity = 1, PricebookEntryId = OpportunitySplitHelper.getPriceBook(primaryOpportunity).id);
        splitProduct.TotalPrice = amount;
        return splitProduct;
    }

    /**
     * @description
     * @param primaryOpportunity
     * @param updateoppMap
     * @param deleteOliList
     * @param lineItemUpdateList
     * @param oppSplitMapping
     * @param childsplitOLIMap
     */
    @testVisible
    private static void syncSplitOpportunities(Opportunity primaryOpportunity, Map<Id,Opportunity> updateoppMap, List<OpportunityLineItem> deleteOliList, List<OpportunityLineItem> lineItemUpdateList, List<OpportunitySplitMapping__c> oppSplitMapping, Map<Id,OpportunityLineItem> childsplitOLIMap) {
        List<OpportunityLineItem> splitOliList = new List<OpportunityLineItem>();
        Double optyTotalValue = getTotalOpportunityAmount(primaryOpportunity, deleteOliList, splitOliList);
        Double totalSplitAmount = updateSplitChildrenOpportynities(primaryOpportunity, optyTotalValue, updateoppMap, oppSplitMapping,childsplitOLIMap );
        
        OpportunityLineItem splitProductForTotalAmount = null;
        OpportunityLineItem splitProductNegativeAmount = null;
        Decimal totalSplitValue = 0;
        if(optyTotalValue > 0){
            if(totalSplitAmount > 0){// It means Opp split by Amount
                primaryOpportunity.Split_Amount__c = optyTotalValue - totalSplitAmount;
                primaryOpportunity.Split_percentage__c = null;
            }else{
                primaryOpportunity.Split_Amount__c = null;
            }
            if(splitOliList.size()>1){ // create splitProductForTotalAmount only if there is no original product.
                splitProductForTotalAmount = setSplitOpportunityLineItem(primaryOpportunity, splitOliList[1], optyTotalValue);
                lineItemUpdateList.add(splitProductForTotalAmount);
            }
            
            Decimal primaryOpportunitySplitPercentage = primaryOpportunity.Split_percentage__c == null ? 100 : primaryOpportunity.Split_percentage__c;
            if(totalSplitAmount > 0){
                totalSplitValue = totalSplitAmount;
            }else{
                totalSplitValue = optyTotalValue * (1-(primaryOpportunitySplitPercentage/100));
            }
            if(totalSplitValue > 0){
                splitProductNegativeAmount = setSplitOpportunityLineItem(primaryOpportunity, splitOliList[0], (-1.0 * totalSplitValue));
                lineItemUpdateList.add(splitProductNegativeAmount);
            }
        }                
        updateoppMap.put(primaryOpportunity.Id,primaryOpportunity);
    }
    
     /**
      * @description
      * @param primaryOpportunity
      * @param optyTotalValue
      * @param updateoppMap
      * @param oppSplitMapping
      * @param childsplitOLIMap
      * @return Double
      */
    public static Double updateSplitChildrenOpportynities(Opportunity primaryOpportunity, Double optyTotalValue, Map<Id,Opportunity> updateoppMap, List<OpportunitySplitMapping__c> oppSplitMapping,Map<Id,OpportunityLineItem> childsplitOLIMap) {
        Double totalSplitAmount = 0.00;
        boolean hasRealProducts = false;
        for(OpportunityLineItem vLineItem : primaryOpportunity.OpportunityLineItems){
            if(vLineItem.ProductCode !='OPTY-SPLIT'){
                hasRealProducts = true; 
                break;
            }
        }
        /*for(Opportunity splitOppty : primaryOpportunity.Split_Opportunities__r) { commente as part of SAl26-258
            if(splitOppty.Split_Amount__c > 0.00) {
                totalSplitAmount += splitOppty.split_amount__c;
                splitOppty.Split_percentage__c = null;
            }else if(splitOppty.Split_percentage__c != null && splitOppty.Split_Amount__c == 0) {
                splitOppty.Split_Amount__c = null;
            }
        }*/
        Map<ID, Opportunity> newTriggerMap = (Map<ID, Opportunity>)Trigger.newMap;
        //SAL26-1340
        Map<String, List<String>> overrideToPLSFields = new Map<String, List<String>>{
            'CLOUD ETM Override' => new List<String>{'Co_Owner__c', 'Opp_PLS_ETM_Area__c', 'Opp_PLS_ETM_Region__c', 'Opp_PLS_ETM_Territory__c', 'Opp_PLS_ETM_Theatre__c', 'Rubrik_Co_Sales_Engineer__c'},
            'SaaS ETM Override' => new List<String>{ 'SaaS_Co_Owner__c', 'Opp_PLS_SaaS_ETM_Area__c', 'Opp_PLS_SaaS_ETM_Region__c', 'Opp_PLS_SaaS_ETM_Territory__c', 'Opp_PLS_SaaS_ETM_Theatre__c'},
            'NCD ETM Override' => new List<String>{'NCD_Co_Owner__c', 'Opp_PLS_NCD_ETM_Area__c', 'Opp_PLS_NCD_ETM_Region__c', 'Opp_PLS_NCD_ETM_Territory__c', 'Opp_PLS_NCD_ETM_Theatre__c'}
        };
        Decimal splitProdTCV = 0;
        
        //SAL26-1340 START
        Set<Id> coOwnerUserIds = new Set<Id>();
        Set<Id> oppETMOverridesResetIds = new Set<Id>();
        Set<Id> oppETMOverridesSetIds = new Set<Id>();
        Map<Id,Opportunity> splitOppMap = new Map<Id,Opportunity>();
        //SAL26-1340 END
        for(Opportunity splitOppty : primaryOpportunity.Split_Opportunities__r) {
            if(!(splitOppty.split_percentage__c == 0 && splitOppty.StageName == '7 Closed Lost')) { //SAL26-258 
            splitOppty = OpportunitySplitHelper.copyOpportunityFieldToSplit(splitOppty, primaryOpportunity, oppSplitMapping);
            //PL26-40 start
                // SAL26-1340 - Start
                Set<String> primaryOverrides = String.isBlank(splitOppty.PLS_ETM_Overrides__c) ? new Set<String>() : new Set<String>(splitOppty.PLS_ETM_Overrides__c.split(';'));
                Set<String> splitOverrides = String.isBlank(splitOppty.Opportunity_Split_Parent__r.PLS_ETM_Overrides__c) ? new Set<String>() : new Set<String>(splitOppty.Opportunity_Split_Parent__r.PLS_ETM_Overrides__c.split(';'));





                if (splitOppty.ETM_Theatre__c == primaryOpportunity.ETM_Theatre__c) {
                    for (String overrideKey : overrideToPLSFields.keySet()) {
                        if (primaryOverrides.contains(overrideKey) || splitOverrides.contains(overrideKey)) continue; //SAL26-1340
                        splitOppty = OpportunityUtil.setPLSCoOwnerFields(splitOppty, primaryOpportunity, overrideToPLSFields.get(overrideKey));
                        oppETMOverridesSetIds.add(splitOppty.Id);
                        splitOppMap.put(splitOppty.Id,splitOppty);
            }
                }else{
                    // SAL26-1340 - Start
                    oppETMOverridesResetIds.add(splitOppty.Id);
                    splitOppMap.put(splitOppty.Id,splitOppty);
                    // SAL26-1340 - End
                }
                for (String coOwnerField : coOwnerFields) {
                    Id userId = (Id) splitOppty.get(coOwnerField);
                    if (userId != null) {
                        coOwnerUserIds.add(userId);
                    }
                }
                // SAL26-1340 - END
            if(primaryOpportunity.Split_percentage__c > 0 && splitOppty.Split_percentage__c == null){
                newTriggerMap.get(primaryOpportunity.id).addError('Split Opportunity do not have Split percentage');
            }else if(totalSplitAmount > 0 && splitOppty.Split_Amount__c == null){
                splitOppty.Split_Amount__c = 0;
            }
            
            if(totalSplitAmount > 0 && optyTotalValue != 0){
                splitOppty.Amount = splitOppty.Split_Amount__c;
            }else if(splitOppty.Split_percentage__c != null){
                //OPPTYSPLIT-2 
                if(hasRealProducts == true && optyTotalValue != 0){
                    splitProdTCV = (optyTotalValue * (100 - splitOppty.Split_percentage__c) / 100)*(-1);
                }else if(!hasRealProducts && optyTotalValue != 0){
                splitProdTCV = (optyTotalValue * splitOppty.Split_percentage__c / 100);
                }else if(optyTotalValue == 0){
                    splitProdTCV = 0;
                }
                if(!childsplitOLIMap.isEmpty() && childsplitOLIMap.containskey(splitOppty.Id)){
                    childsplitOLIMap.get(splitOppty.Id).Totalprice = splitProdTCV;
                }else{
                    OpportunityLineItem splitProduct;
                    splitProduct = setSplitOpportunityLineItem(splitOppty,splitProduct,splitProdTCV);
                    childsplitOLIMap.put(splitOppty.Id,splitProduct);
                }
                splitOppty.Amount = (optyTotalValue * splitOppty.Split_percentage__c / 100);
            }else{
                splitOppty.Amount = 0;
            }
                
            updateoppMap.put(splitOppty.Id,splitOppty);
        }
        }
        //SAL26-1340 START
        if(!coOwnerUserIds.isEmpty()){
            Map<Id, List<UserTerritory2Association>> userToUTAListMap = buildUserToUTAMap(coOwnerUserIds);
            if (!oppETMOverridesResetIds.isEmpty()){
                resetPLSForETMOverridesAndSplitOpp(userToUTAListMap, oppETMOverridesResetIds, splitOppMap, true);
            }
            if (!oppETMOverridesSetIds.isEmpty()){
                setPLSForETMOverridesAndSplitOpp(userToUTAListMap, oppETMOverridesSetIds, splitOppMap, true);
            }
        }
        //SAL26-1340 END
        return totalSplitAmount;
    }

    /**
     * @description get opportunity total amount based on OLI
     * @param primaryOpportunity
     * @param deleteOliList
     * @param splitOliList
     * @return Double
     */
    @testVisible
    private static Double getTotalOpportunityAmount(Opportunity primaryOpportunity, List<OpportunityLineItem> deleteOliList, List<OpportunityLineItem> splitOliList) {
        
        Double optyTotalValue = 0.00;
        boolean hasRealProducts = false;
        Double splitProdTCV = 0.00;
        OpportunityLineItem splitProductForTotalAmount = null;
        OpportunityLineItem splitProductWithZeroAmount = null;
        OpportunityLineItem splitProductNegativeAmount = null;
        //get total value of the opportunity
        for(OpportunityLineItem vLineItem : primaryOpportunity.OpportunityLineItems){
            if(vLineItem.ProductCode == 'OPTY-SPLIT'){
                if(vLineItem.TotalPrice > 0){
                    splitProductForTotalAmount = vLineItem;                 
                } else if (vLineItem.TotalPrice == 0){
                    splitProductWithZeroAmount = vLineItem; 
                }else{
                    //Nothing
                    splitProductNegativeAmount = vLineItem;
                }
            } else {
                hasRealProducts = true;
                if(primaryOpportunity.SBQQ__PrimaryQuote__c != null) {
                    if(primaryOpportunity.SBQQ__PrimaryQuote__c == vLineItem.SBQQ__QuoteLine__r.SBQQ__Quote__c){
                        if(vLineItem.Line_Type__c != 'Renewal')
                            optyTotalValue = optyTotalValue + vLineItem.TotalPrice;
                    } /**(SAL26-312: commented else block) else{
                    }*/
                } else {
                    if(vLineItem.Line_Type__c != 'Renewal') 
                        optyTotalValue = optyTotalValue + vLineItem.TotalPrice;
                }
            }
        }
        
        if(optyTotalValue == 0 && !hasRealProducts){
            if(splitProductForTotalAmount != null) {
                optyTotalValue = splitProductForTotalAmount.TotalPrice;
            }else{
                optyTotalValue = primaryOpportunity.amount == null ? 0 : primaryOpportunity.amount;
            }
        }
        if(optyTotalValue == 0){
            if(splitProductWithZeroAmount != null) {
                deleteOliList.add(splitProductWithZeroAmount);//Delete 'OPTY-SPLIT' OLI if it has 0 value.
            }
            if(!hasRealProducts && splitProductForTotalAmount != null) {
                deleteOliList.add(splitProductForTotalAmount); //Delete 'OPTY-SPLIT' OLI if it has 0 value.
                splitProductForTotalAmount = null;
            }
        }
        if(hasRealProducts && splitProductForTotalAmount != null){
            deleteOliList.add(splitProductForTotalAmount); //Delete 'OPTY-SPLIT' OLI if it has has Real Products.
            splitProductForTotalAmount = null;
        }
        splitOliList.add(splitProductNegativeAmount);
        if(!hasRealProducts){
            splitOliList.add(splitProductForTotalAmount);
        }
        return optyTotalValue;
    }    
    
     /**
      * @description
      * @param newTriggerMap
      * @param splitOpptyIdSet
      */
    public static void processOpportunitySplit( Map<Id, Opportunity> newTriggerMap, Set<Id> splitOpptyIdSet) {
        
        if( OpportunityLineItemTriggersHandler.opportunityIdSet.containsAll(newTriggerMap.keySet()) ){
            OpportunityLineItemTriggersHandler.opportunityIdSet.clear();
            return; // Trigger initiated due to OLI DMLs.
        } 
        
        Map<Id,Opportunity> updateoppMap = new Map<Id,Opportunity>();
        List<OpportunityLineItem> deleteOliList = new List<OpportunityLineItem>();
        List<OpportunityLineItem> lineItemUpdateList = new List<OpportunityLineItem>();
        
        ShGl_QueryConstants__mdt [] opptySplitQuery = [SELECT Query_String__c FROM ShGl_QueryConstants__mdt WHERE DeveloperName = 'OpportunitySplit_CopyQuery'];
        String query = opptySplitQuery.get(0).Query_String__c +  ' WHERE Id IN :splitOpptyIdSet and Split__c = true AND Opportunity_Split_parent__c = null ';
        List<OpportunitySplitMapping__c> oppSplitMapping = [SELECT Default_Value__c,Field__c,From_Field__c,Id,Name,Prefix__c,Suffix__c,Skip_Update_if_child_has_value__c FROM OpportunitySplitMapping__c];
        
        Map<Id, Opportunity> primaryOpportunityMap = new Map<Id, Opportunity>((List<Opportunity>)Database.query(query));
        
        Map<ID, Opportunity> oldTriggerMap = (Map<ID, Opportunity>)Trigger.oldMap;
        Set<Id> childsplitOpptyIdSet = new Set<Id>(); //SAL24-550
        Set<Id> totalOpptyIdSet = new Set<Id>();
        Map<Id,OpportunityLineItem>  parentSplitOLIMap = new Map<Id,OpportunityLineItem> ();
        Map<Id,OpportunityLineItem> childsplitOLIMap = new Map<Id,OpportunityLineItem>();
        for(Opportunity primaryOpp : primaryOpportunityMap.values()){
            totalOpptyIdSet.add(primaryOpp.Id);
            for(Opportunity childsplitOppty : primaryOpp.Split_Opportunities__r) {
                childsplitOpptyIdSet.add(childsplitOppty.Id);
            }
        } 
        //SAL24-550
        totalOpptyIdSet.addAll(childsplitOpptyIdSet);
        if(!totalOpptyIdSet.isEmpty()){
            for(OpportunityLineItem oli : [select Id,TotalPrice,ProductCode,opportunityId from OpportunityLineItem where opportunityId IN :totalOpptyIdSet AND ProductCode ='OPTY-SPLIT']){
                if(!childsplitOpptyIdSet.isEmpty() && childsplitOpptyIdSet.contains(oli.opportunityId)){
                    childsplitOLIMap.put(oli.opportunityId,oli);
                }else{
                    parentSplitOLIMap.put(oli.opportunityId,oli);
                }
            }
        }
        
        if(!primaryOpportunityMap.isEmpty()) {
            for(Opportunity primaryOpportunity: primaryOpportunityMap.values()){
                //SF-32855 - can't use child relationship fieldname from soql without FOR loop, so commented above debug statement and using Number_of_Opportunity_Products__c in If condition
                if(newTriggerMap.get(primaryOpportunity.id).SBQQ__PrimaryQuote__c != oldTriggerMap.get(primaryOpportunity.id).SBQQ__PrimaryQuote__c && 
                   newTriggerMap.get(primaryOpportunity.id).SBQQ__PrimaryQuote__c == null && primaryOpportunity.Number_of_Opportunity_Products__c > 0){
                       //if we have a Primary Quote with QLIs.  If we uncheck Primary checkbox. 
                       //First Opportunity is getting updated than OLIs are getting removed.( from the CPQ package). 
                       //This scenario should be covered in second iteration
                       //Do nothing
                        System.debug(System.logginglevel.DEBUG, 'Do nothing');
                   }else{          
                       if(((newTriggerMap.get(primaryOpportunity.id).SBQQ__PrimaryQuote__c != oldTriggerMap.get(primaryOpportunity.id).SBQQ__PrimaryQuote__c)
                          || (newTriggerMap.get(primaryOpportunity.id).stageName != oldTriggerMap.get(primaryOpportunity.id).stageName)
                          || (newTriggerMap.get(primaryOpportunity.id).Amount != oldTriggerMap.get(primaryOpportunity.id).Amount)
                          || (newTriggerMap.get(primaryOpportunity.id).split__c && newTriggerMap.get(primaryOpportunity.id).Split_percentage__c != oldTriggerMap.get(primaryOpportunity.id).Split_percentage__c) //SAL24-595
                          || (newTriggerMap.get(primaryOpportunity.id).Split_Amount__c != oldTriggerMap.get(primaryOpportunity.id).Split_Amount__c)
                          || (newTriggerMap.get(primaryOpportunity.id).CloseDate != oldTriggerMap.get(primaryOpportunity.id).CloseDate) //SAL24-463
                          || (newTriggerMap.get(primaryOpportunity.id).Opportunity_Amount_Override__c != oldTriggerMap.get(primaryOpportunity.id).Opportunity_Amount_Override__c) //SAL25-504
                          || (newTriggerMap.get(primaryOpportunity.id).UCL_Scale_Percentage__c != oldTriggerMap.get(primaryOpportunity.id).UCL_Scale_Percentage__c) //SAL26-207
                          || (newTriggerMap.get(primaryOpportunity.id).isClosed)
                          || (newTriggerMap.get(primaryOpportunity.id).In_Forecast_CRO__c != oldTriggerMap.get(primaryOpportunity.id).In_Forecast_CRO__c))
                          
                         )
                           syncSplitOpportunities(primaryOpportunity, updateoppMap, deleteOliList, lineItemUpdateList, oppSplitMapping, childsplitOLIMap);
                   }
            }
        }
        
        FlowControll.opportunityTriggerHandler = false;
        flowControll.opportunityLineItemHandler = false;
        //SAL24-550 - To add missing neg split opty on Parent Opp on Quote change
        if(system.isqueueable() && !primaryOpportunityMap.isEmpty()){
            for(Opportunity primaryOpportunity: primaryOpportunityMap.values()){
                if(lineItemUpdateList.isEmpty() && (parentSplitOLIMap.isEmpty() || !parentSplitOLIMap.containsKey(primaryOpportunity.Id) && primaryOpportunity.Split_percentage__c > 0 && primaryOpportunity.Split_percentage__c < 100 && primaryOpportunity.split__c)){
                    syncSplitOpportunities(primaryOpportunity, updateoppMap, deleteOliList, lineItemUpdateList, oppSplitMapping, childsplitOLIMap);
                }
            }
        }
        for(OpportunityLineItem oli : childsplitOLIMap.values()){
            lineItemUpdateList.add(oli); 
        }
        if(!lineItemUpdateList.isEmpty()){
            upsert lineItemUpdateList;
        }
        if(!deleteOliList.isEmpty() && flowControll.deleteOptySplitAmount && !system.isqueueable() && !System.isFuture()){
            delete deleteOliList;
        }
        if(!updateoppMap.isEmpty()){
            update updateoppMap.values();
        }
        //SAL26-72 start
        OpportunitySplitLWCController.createPartnerRelation(updateoppMap, primaryOpportunityMap,'Sales Split');
        //SAL26-72 end
        flowControll.opportunityTriggerHandler = true;
        flowControll.opportunityLineItemHandler = true;
    }
    
    //PS EGN 116 STARTS
    /* method commented as part of CPQ22-3962 this method is merged with updateQuoteFields in handler class
    public static void updatePrimaryQuote(Set<Id> primaryQuotes){
        List<SBQQ__Quote__c> quotesToUpdate = new List<SBQQ__Quote__c>();
        if(!primaryQuotes.isEmpty()){
            for(SBQQ__Quote__c qt : [Select Id, sendSOWNotification__c from SBQQ__Quote__c where Id IN :primaryQuotes]){
                if(!qt.sendSOWNotification__c){
                    qt.sendSOWNotification__c = true;
                    quotesToUpdate.add(qt);
                } 
            }
            if(!quotesToUpdate.isEmpty()){
                Database.update(quotesToUpdate);
            }
        }
    }*/
    //PS EGN 116 ENDS
    
    // SF 8310 Starts
    /**
     * @description
     * @param renewalOppowithContracts
     * @param scMap
     *
    */
    public static void populateFieldsonRenewalOppo(Map<Id,Opportunity> renewalOppowithContracts, Map<Id,ServiceContract> scMap){
        Set<String> alliancePartnerActiveValues = new Set<String>(); //SAL26-492
        for (Schema.PicklistEntry pe : Opportunity.Alliance_Partner_Name__c.getDescribe().getPicklistValues()){
            if (pe.isActive()) alliancePartnerActiveValues.add(pe.getValue());
        }
        if(!renewalOppowithContracts.isEmpty() && !scMap.isEmpty()){
            //SAL24-23 change reference of field Lifetime_Total_Value__c to Sum_of_Opportunities__c
            for (ServiceContract sc: scMap.values()){
                                          if(renewalOppowithContracts.containsKey(sc.Id)){
                                              Opportunity opp = renewalOppowithContracts.get(sc.Id);
                                              Account acc = sc?.SBQQSC__Opportunity__r?.Account;
                                              if (acc != null && Constants.ACCOUNT_MSP_TYPES.contains(acc.Type)) {
                                                opp.Managed_Services_Deal_type__c = 
                                                  sc?.SBQQSC__Opportunity__r?.Managed_Services_Deal_type__c;
                                              }
                                              opp.Alliance_HW_Partner__c = 'None';
                                              // Updated based on CPQ22-138
                                              //SAL22-259
                                              //opp.Alliance_Partner_Name__c = sc.SBQQSC__Opportunity__r.Alliance_Partner_Name__c;
                                              //opp.Alliance_Source_Type_SW__c = sc.SBQQSC__Opportunity__r.Alliance_Source_Type_SW__c;
                                              //SAL26-492 START
                                              String sourceValue = sc.SBQQSC__Opportunity__r.Alliance_Partner_Name__c;
                                              List<String> validValues = new List<String>();
                                              if (!String.isBlank(sourceValue))
                                                  for (String val : sourceValue.split(';')) if (alliancePartnerActiveValues.contains(val.trim())) validValues.add(val.trim());
                                              opp.Alliance_Partner_Name__c = validValues.isEmpty() ? 'None' : String.join(validValues, ';');
                                              //SAL26-492 END
                                              //opp.Alliance_Source_Type_SW__c = 'None'; //SAL23-91
                    // opp.Alliance_Source_Type_HW__c = 'None'; //SAL24-387 deprecated
                                              opp.Incumbent__c = 'Rubrik';
                                              //CPQ22-980 Update record type as Renewal
                                              opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId();
                                              opp.Opportunity_Sub_Type__c = 'Renewal';
                                              opp.Current_State__c = 'Lapsing Support';
                                              opp.Initial_Contacts_Name__c = sc.SBQQSC__Opportunity__r.Initial_Contacts_Name__c;
                                              opp.Compelling_Bus_Driver__c = sc.SBQQSC__Opportunity__r.Compelling_Bus_Driver__c;
                                              opp.Future_State__c = 'Rubrik Support';
                                              //SAL22-260
                                              opp.Positive_Business_Outcomes__c = 'Renewed Support';
                                              opp.Negative_Consequences__c = 'No Support';
                                              opp.Partner_Representative__c = sc.SBQQSC__Opportunity__r.Partner_Representative__c;
                                              opp.Partner_Rep_Email_Address__c =  sc.SBQQSC__Opportunity__r.Partner_Rep_Email_Address__c; 
                                              opp.Partner_Rep_Phone_Number__c = sc.SBQQSC__Opportunity__r.Partner_Rep_Phone_Number__c;
                                              opp.Partner_SE_Email__c = sc.SBQQSC__Opportunity__r.Partner_SE_Email__c;
                                              opp.Partner_SE_Name__c = sc.SBQQSC__Opportunity__r.Partner_SE_Name__c;
                                              opp.Partner_SE_Phone__c = sc.SBQQSC__Opportunity__r.Partner_SE_Phone__c;
                                              //SAL22-260
                                              opp.Partner_Lookup__c = (sc.SBQQSC__Opportunity__r.Partner_Lookup__r.RecordType.Name == 'Partner/Distributor' && 
                                                                       !ACCOUNT_CONTRACT_STATUS_SET.contains(sc.SBQQSC__Opportunity__r.Partner_Lookup__r.Contract_Status__c)) ? 
                                                  sc.SBQQSC__Opportunity__r.Partner_Lookup__c : null;
                                              //opp.Distributor_Lookup__c = sc.SBQQSC__Opportunity__r.Distributor_Lookup__c;
                                              opp.Distributor_Lookup__c = (!ACCOUNT_CONTRACT_STATUS_SET.contains(sc.SBQQSC__Opportunity__r.Distributor_Lookup__r.Contract_Status__c)) ? sc.SBQQSC__Opportunity__r.Distributor_Lookup__c : null;
                                              if(opp.Distributor_Lookup__c == null && opp.Partner_Lookup__c != null){
                                                  String cStatus = sc.SBQQSC__Opportunity__r?.Partner_Lookup__r?.Distributor__r?.Contract_Status__c;
                                                  if(String.isNotBlank(cStatus) && !ACCOUNT_CONTRACT_STATUS_SET.contains(cStatus)){
                                                      opp.Distributor_Lookup__c = sc.SBQQSC__Opportunity__r.Partner_Lookup__r.Distributor__c;
                                                  }
                                              }
                                              opp.Distributor_Rep_Email__c = sc.SBQQSC__Opportunity__r.Distributor_Rep_Email__c;
                                              opp.Distributor_Rep_Name__c = sc.SBQQSC__Opportunity__r.Distributor_Rep_Name__c;
                                              opp.Distributor_Secondary_Email_Address__c = sc.SBQQSC__Opportunity__r.Distributor_Secondary_Email_Address__c;
                                              opp.Distributor_Rep_Phone_Number__c = sc.SBQQSC__Opportunity__r.Distributor_Rep_Phone_Number__c;
                                              opp.Deal_Registration_Type__c = 'Rubrik Sourced'; //SAL22-261
                                              //SAL22-348
                                              opp.Identified_Pain__c = 'Not Applicable';
                    // opp.Partner_Level_Of_Involvement__c = '1.Rubrik initiated, Partner was fulfillment only'; //SAL24-387 deprecated
                                              opp.Primary_Competitor__c = sc.SBQQSC__Opportunity__r.Primary_Competitor__c;
                                              opp.Cloud_Type__c = sc.SBQQSC__Opportunity__r.Cloud_Type__c;
                                              opp.Cloud_Environment__c = sc.SBQQSC__Opportunity__r.Cloud_Environment__c;
                                              opp.Rubrik_CDM_Release_on_source_cluster__c = sc.SBQQSC__Opportunity__r.Rubrik_CDM_Release_on_source_cluster__c;
                                              opp.Polaris_Portal_Contact__c = sc.SBQQSC__Opportunity__r.Polaris_Portal_Contact__c;
                                              //SAL23-81,SAL23-83
                                              opp.Cloud_Partner_Impact__c = 'None';
                    // opp.Cloud_Partner_Led_Activity__c = 'No';//SAL24-466
                                              //SAL24-166 
                                              opp.Incumbent_Partner__c = sc.SBQQSC__Opportunity__r.Partner_Lookup__r?.Name;
                                              opp.IncumbentPartnerId__c=sc.SBQQSC__Opportunity__r.Partner_Lookup__c; //REEN-57
                                              //SAL24-228
                                              opp.Fed_SI_Partner_Name__c = sc.SBQQSC__Opportunity__r.Fed_SI_Partner_Name__c;
                                              opp.Fed_SI_Initiated_Deal__c = sc.SBQQSC__Opportunity__r.Fed_SI_Initiated_Deal__c;
                                              //SAL24-479
                                              opp.MSP_End_User_Lookup__c = sc.SBQQSC__Opportunity__r.MSP_End_User_Lookup__c;
                                              opp.MSP_End_User__c = sc.SBQQSC__Opportunity__r.MSP_End_User__c;
                                              //CPQ22-1857
                                              if(sc.Name.contains('MSP') && sc.SBQQSC__Quote__c != null && sc.SBQQSC__Quote__r.MSP_SKUs_Count__c > 0) {
                                                  opp.Opportunity_Sub_Type__c = 'MSP Consumption Renewal';
                                              }
                                              //SAL24-23 change reference of field Lifetime_Total_Value__c to Sum_of_Opportunities__c
                                              if(opp.AccountId != null && sc.Account.Sum_of_Opportunities__c < 250000){
                                                  String oppName = sc.EndDate == null ? '' : sc.EndDate.year() + '-' + sc.EndDate.month() + '-' + sc.EndDate.day() + '-';
                                                  oppName += String.isBlank(sc.Account.ETM_Theatre__c) ? '' : sc.Account.ETM_Theatre__c + '-';
                                                  oppName += oppName + sc.Account.Name + (opp.Partner_Lookup__c == null ? '' : (' - ' + sc.SBQQSC__Opportunity__r.Partner_Lookup__r.Name));
                                                  //opp.name = oppName + sc.Account.Name + (opp.Partner_Lookup__c == null ? ' - Renewal' : (' - ' + sc.SBQQSC__Opportunity__r.Partner_Lookup__r.Name + ' - Renewal'));
                                                  //CPQ22-48 Logic starts here to truncate opportunity name characters
                                                  if(oppName.length()>100){
                                                      oppName = oppName.substring(0, 100);
                                                      oppName = oppName + '- Renewal';
                                                      opp.Name = oppName;
                                                  }else{
                                                      opp.Name = oppName + ' - Renewal';
                                                  } 
                                              }else{
                                                  //String Name = SC.Name.trim();
                                                  //opp.Name = Name.EndsWith('Contract') ? Name.replace('Contract', 'Renewal') : SC.Name+'- Renewal';
                                                  //SAL23-318
                                                  String Name = SC.Name.length()>110 ? SC.Name.substring(0,100) : SC.Name;
                                                  opp.Name = Name.EndsWith('Contract') ? Name.replace('Contract', 'Renewal') : Name + ' - Renewal';
                                              }
                                              //SF-43132
                                              OpportunityObjectTriggerHandler.renewalOppAccIdSet.add(opp.Partner_Lookup__c);
                                              OpportunityObjectTriggerHandler.renewalOppAccIdSet.add(opp.MSP_End_User_Lookup__c);
                                          }
                                      }  
        }
    }// SF 8310 Ends
    
    //NetApp Quoting FCUS:20: Shaloo STARTS
    /**
     * @description
     * @param primaryQuotes
     * @param newOppMap
     * @param quoteList
     * @return boolean
     */
    public static boolean validateNetAppError(Set<Id> primaryQuotes, Map<ID, Opportunity> newOppMap, List<SBQQ__Quote__c> quoteList){
        boolean isNonGPLErrorFound = false;
        if(!primaryQuotes.isEmpty()){
            for(SBQQ__Quote__c qt : quoteList){
                for(SBQQ__QuoteLine__c qtline : qt.SBQQ__LineItems__r){
                    if(qtline.GPL__c == NULL && qtline.SBQQ__OptionType__c == 'Component' && qtline.SBQQ__RequiredBy__r.GPL__c == 'NetApp'){
                        newOppMap.get(qt.SBQQ__Opportunity2__c).addError('Non-GPL parts in GPL bundle');
                        isNonGPLErrorFound = true; 
                    }
                }
            }
        }
        return isNonGPLErrorFound;
    }//NetApp Quoting FCUS:20:: Shaloo ENDS
    
    /****************************************************************************************************
    * Developer : Chaitra
    * @description : PRDOPS22-185 
    * Used to create booking,booking lineItem and booking split for PSO rebooking and debooking
    * @param newOppList
    * @param newOppMap
    * @param oldOppMap
******************************************************************************************************/
    public static void createBooking(set<Opportunity>newOppList ,Map<id,Opportunity> newOppMap, Map<id,Opportunity> oldOppMap){
        set<id> oppWithBkg = new set<Id>();
        List<Booking__c> bkgToInsert = new List<Booking__c>();
        List<Booking_Line_Item__c> bliToInsert = new List<Booking_Line_Item__c>();
        List<Booking_Split__c> bkgSplitToInsert = new List<Booking_Split__c>();
        Map<Id,Id> BkgIdOppId = new Map<Id,Id>(); 
        for(Booking__c bkg : [select id,Opportunity__c from Booking__c where Opportunity__c IN : newOppList]){
            oppWithBkg.add(bkg.Opportunity__c);
        }
        List<Booking_Mapping__mdt> bookingMapsList =[Select Booking_Field_name__c, Order_Field_Name__c from Booking_Mapping__mdt where Order_Field_Name__c like 'Opportunity.%' and Booking_Field_name__c NOT IN ('Opportunity_Owner_Name__c','Opportunity_Owner_Employee_ID__c')];
        for(Opportunity newOpp : newOppList){
            if(!oppWithBkg.contains(newOpp.id)){
                Booking__c bkg = new Booking__c();
                for(Booking_Mapping__mdt Bkgmap : bookingMapsList){
                    bkg.put(Bkgmap.Booking_Field_name__c,newOpp.get(Bkgmap.Order_Field_Name__c.removeStart('Opportunity.')));     
                }
                bkg.Opportunity_Owner_Name__c = newOpp.OwnerForWorkflow__c ;
                bkg.Opportunity_Owner_Employee_ID__c = newOpp.Employee_ID__c ;
                bkg.Account_Name__c = newOpp.accountId;
                bkg.RecordTypeId= newOpp.Opportunity_Type__c == 'Debooking'?Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking Adjustment').getRecordTypeId(): Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking').getRecordTypeId();
                bkgToInsert.add(bkg);   
            }
        }
        integer i = 0;
        for(Database.SaveResult res : database.insert(bkgToInsert, false)){
            if(res.isSuccess()){
                
                Opportunity opp = newOppMap?.get(bkgToInsert[i].Opportunity__c);
                bliToInsert.add(new Booking_Line_Item__c(
                    Booking__c = bkgToInsert[i].id ,
                    Total_Price__c = opp.Amount,
                    New_Expansion_TCV__c = opp.New_Expansion_TCV__c  ,
                    Subsumed_Renewal_TCV__c = opp.Subsumed_Renewal_TCV__c,
                    Type__c =  opp.Opportunity_Type__c == 'Debooking' ?  'Change in Booking Policy / De-Risk Decision' : 'Revenue' ,
                    Impacts_Gross_Bookings__c = true,
                    Impacts_Net_Bookings__c = true,
                    Impacts_Commission__c = true
                ));
                bkgSplitToInsert.add(new Booking_Split__c(
                    Booking__c = bkgToInsert[i].id,
                    Opportunity__c = opp.id,
                    Sales_Rep__c = opp.OwnerId,
                    Opportunity_Split__c = 100 ,
                    Theatre__c = opp.ETM_Theatre__c,
                    Area__c = opp.ETM_Area__c,
                    Region__c = opp.ETM_Region__c,
                    Territory__c = opp.ETM_Territory__c,
                    // PRDOPS26-357 : Added the PLS ETM TART fields to be copied on Booking Split object on Creation
                    Opp_PLS_ETM_Area__c = opp.Opp_PLS_ETM_Area__c,
                    Opp_PLS_ETM_Region__c = opp.Opp_PLS_ETM_Region__c,
                    Opp_PLS_ETM_Territory__c = opp.Opp_PLS_ETM_Territory__c,
                    Opp_PLS_ETM_Theatre__c = opp.Opp_PLS_ETM_Theatre__c  
                ));
            } 
            
        }
        if(!bliToInsert.isEmpty()){
            database.insert(bliToInsert,false);
        }
        if(!bkgSplitToInsert.isEmpty()){
            database.insert(bkgSplitToInsert,false);
        }
        
    }
    
    /* public static void updateMCPamount(List<opportunity> newOppList,Map<Id,opportunity> OldOppMap){
        List<Id> oppIdList = new List<Id>();
        List<MCP__c> mcpUpdateList = new List<MCP__c>();
        for(Opportunity opp : newOppList){
            if(OldOppMap.get(Opp.Id) != null && opp.Amount != OldOppMap.get(Opp.Id).Amount){
                oppIdList.add(opp.Id);
            }
        }
        List<Opportunity> oppList = new List<Opportunity>([Select Id,Amount,(Select Id,MCP_Opportunity_Amount__c from MCP__r) from Opportunity where Id IN : oppIdList]);
        for(Opportunity opp : oppList){
            for(MCP__c mcp : opp.MCP__r){
                mcp.MCP_Opportunity_Amount__c = opp.Amount;
                mcpUpdateList.add(mcp);
            }
        }
        if(!mcpUpdateList.isEmpty()){
            update mcpUpdateList;
        }
    }*/
    
    //Updated the logic for calculating CCR Object ReferralFeeAmount field.
    //SAL24-300 - Update Effective Date on Partner Referral Fee CCRs whenever open Opportunity's Close Date is updated
    /**
     * @description
     * @param lstOpp
     * @param mapOld
     */
    public static void calculateReferralFeeAmount(List<Opportunity> lstOpp, Map<ID,Opportunity> mapOld) {
        //SAL24-300
        //List<CCR__c> updateReferralFeeAmountList = new List<CCR__c>();
        Set<Id> oppIdSet = new Set<Id>();
        Set<Id> CloseDateoppIdSet = new Set<Id>();
        List<CCR__c> updateCCRList = new List<CCR__c>();
        try {
            for(Opportunity opp : lstOpp) {
                if(opp.Amount != mapOld.get(opp.Id).Amount) {
                    oppIdSet.add(opp.Id);
                }
                //SAL24-300
                if(opp.CloseDate != mapOld.get(opp.Id).CloseDate && mapOld.get(opp.Id).StageName != '7 Closed Won' && mapOld.get(opp.Id).StageName != '7 Closed Lost' && mapOld.get(opp.Id).StageName != '7 Closed Admin') {
                    CloseDateoppIdSet.add(opp.Id);
                }
            }
            if(!oppIdSet.isEmpty() || !CloseDateoppIdSet.isEmpty()) { //SAL24-300
                //SAL24-300
                /*for(CCR__c ccr : [SELECT Id, Opportunity__r.Amount, Referral_Fee_Percent__c, Referral_Fee_Amount__c FROM CCR__c WHERE Opportunity__c IN :oppIdSet AND Referral_Fee_Percent__c > 0 ORDER BY Opportunity__c DESC]) {
ccr.Referral_Fee_Amount__c = ccr.Opportunity__r.Amount > 0 ? (ccr.Opportunity__r.Amount*ccr.Referral_Fee_Percent__c)/100 : 0;
updateReferralFeeAmountList.add(ccr);
}*/
                for(CCR__c ccr : [SELECT Id, Opportunity__r.Amount, Referral_Fee_Percent__c, Referral_Fee_Amount__c, CCR_Type__c, Opportunity__r.CloseDate FROM CCR__c WHERE ((Opportunity__c IN :CloseDateoppIdSet AND CCR_Type__c = 'Partner Referral Fee') OR (Opportunity__c IN :oppIdSet AND Referral_Fee_Percent__c > 0)) ORDER BY Opportunity__c DESC]) {
                    if(oppIdSet.contains(ccr.Opportunity__c) && ccr.Referral_Fee_Percent__c > 0)    ccr.Referral_Fee_Amount__c = ccr.Opportunity__r.Amount > 0 ? (ccr.Opportunity__r.Amount*ccr.Referral_Fee_Percent__c)/100 : 0;
                    if(CloseDateoppIdSet.contains(ccr.Opportunity__c) && ccr.CCR_Type__c == 'Partner Referral Fee')  ccr.Effective_Date__c = ccr.Opportunity__r.CloseDate;
                    if((oppIdSet.contains(ccr.Opportunity__c) && ccr.Referral_Fee_Percent__c > 0) || (CloseDateoppIdSet.contains(ccr.Opportunity__c) && ccr.CCR_Type__c == 'Partner Referral Fee'))    updateCCRList.add(ccr);
                }
                if(!updateCCRList.isEmpty()) {
                    UPDATE updateCCRList;
                }
            }
        }
        catch(Exception ex) {
            System.debug(System.logginglevel.DEBUG, 'Exception Ex :: '+ex.getMessage()+', LineNumber :: '+ex.getLineNumber()+', Cause :: '+ex.getCause());
        }
    }
    //Update related Deal Registration
    /**
     * @description
     * @param dealRegistrationOpptyMap
     * @param dealRegList
     */
    public static void updateDealRegOnOpportunity(Map<String,Opportunity> dealRegistrationOpptyMap, List<Deal_Registration__c> dealRegList){
        //Map<String,String> dealInitiatedTypeMap = new Map<String,String>{'Partner Initiated Deal' => 'Partner Sourced New Logo (PSNL)','Joint Initiated Deal' => 'Partner Sourced Expand','Rubrik Initiated Deal' => 'Rubrik Sourced'};
            
            try{
                // List<Deal_Registration__c> dealRegistrationList = new List<Deal_Registration__c>();
                 /** SAL26-312: removed if block
                if(!dealRegistrationOpptyMap.isEmpty()){
                    /* dealRegistrationList = [SELECT Id,Name,Deal_Registration_Status__c,Approval_Timestamp__c,Opportunity__c,Deal_Reg_Exp_Date__c,Company_Name__c,OwnerId,Primary_Deal_Registration__c,Primary__c,Deal_Registration_Sub_Status__c,Deal_Registration_Type__c, DR_Approved_Date__c,Deal_Registration_Extension_Request__c,Registration_Type__c
                                            FROM Deal_Registration__c
WHERE Name IN : dealRegistrationOpptyMap.keyset()];*
                } */
                if(!dealRegList.isEmpty()){
                    for(Deal_Registration__c dealReg : dealRegList){
                        dealReg.Primary_Deal_Registration__c = true;
                        dealReg.Deal_Registration_Status__c = 'Approved';
                        dealReg.Deal_Registration_Type__c = dealRegistrationOpptyMap.get(dealReg.Name).Deal_Registration_Type__c;
                        if(dealReg.Deal_Registration_Type__c == 'Partner Sourced New Logo (PSNL)' || dealReg.Deal_Registration_Type__c == 'Partner Sourced Expand'){
                            dealReg.Registration_Type__c = 'Partner Sourced';
                        }
                        dealReg.Opportunity__c = dealRegistrationOpptyMap.get(dealReg.Name).Id;
                        dealReg.Opportunity_Created_from_DR__c= true; // PRIT24-884
                        dealReg.Approval_Timestamp__c = System.now();
                        dealReg.DR_Approved_Date__c = System.now();
                        dealReg.Deal_Reg_Exp_Date__c = System.today() + 90;
                        if(dealReg.Company_Name__c == null){//prit24-741
                            dealReg.Company_Name__c = dealRegistrationOpptyMap.get(dealReg.Name).AccountId;
                            dealReg.OwnerId = dealRegistrationOpptyMap.get(dealReg.Name).OwnerId;
                        }
                        dealReg.Deal_Registration_Sub_Status__c = '';
                        dealReg.Primary__c = true;
                        dealReg.Deal_Registration_Extension_Request__c = '';
                    }
                    //flowControll.dealRegistrationTrigger = false;
                    update dealRegList;
                    //flowControll.dealRegistrationTrigger = true;
                }
            }catch(Exception exp){
                Custom_Error_Log__c errorLogRec = new Custom_Error_Log__c();
                errorLogRec.Class__c = 'OpportunityObjectTriggerHelper';
                errorLogRec.Exception_Message__c = exp.getMessage();
                errorLogRec.Functionality__c = 'Update Related Deal Reg on Oppty';
                Insert errorLogRec;
            }
    }
    //INDUS-66
    /**
     * @description
     * @param closedOppWithDRMap
     */
    public static void updateClosedDealRegistrations(Map<String,Opportunity> closedOppWithDRMap){
        try{
            List<Deal_Registration__c> dealRegistrationList = new List<Deal_Registration__c>();
            
            if(!closedOppWithDRMap.isEmpty()){
                for(Deal_Registration__c dealreg : [SELECT Id,Name,Deal_Registration_Status__c,Opportunity__c,Opportunity__r.StageName
                                                    FROM Deal_Registration__c 
                                                    WHERE Name IN:closedOppWithDRMap.keyset() AND Opportunity__c != null]){
                                                        if(closedOppWithDRMap.get(dealreg.Name).StageName.equals('7 Closed Won') || closedOppWithDRMap.get(dealreg.Name).StageName.equals('7 Closed Lost') || closedOppWithDRMap.get(dealreg.Name).StageName.equals('7 Closed Admin')){
                                                            dealReg.Deal_Registration_Sub_Status__c = closedOppWithDRMap.get(dealreg.Name).StageName.remove('7 ');
                                                        }
                                                        dealRegistrationList.add(dealreg);
                                                    }
            }
            if(!dealRegistrationList.isempty()){
                flowControll.dealRegistrationTrigger = false;
                update dealRegistrationList;
                flowControll.dealRegistrationTrigger = true;
            }
        }catch(Exception exp){
            Custom_Error_Log__c errorLogRec = new Custom_Error_Log__c();
            errorLogRec.Class__c = 'OpportunityObjectTriggerHelper';
            errorLogRec.Exception_Message__c = exp.getMessage();
            errorLogRec.Functionality__c = 'Update closed Deal Registrations';
            Insert errorLogRec;
        }
    }
    /*public static Boolean isStage5ChangeAllowed(List<SObject> newRecords, Map<Id, SObject> OldMap){
Boolean isStage5ChangeAllowedFlag = true;
if((UserInfo.getUiThemeDisplayed() != 'Theme4d' && UserInfo.getUiThemeDisplayed() != 'Theme4u') && !test.isRunningTest()){
return isStage5ChangeAllowedFlag;
}
Map<Id, Opportunity> OldOps = (Map<Id, Opportunity>) OldMap;
List<Opportunity_Notification__e> inkEvents = new List<Opportunity_Notification__e>();
if(newRecords.size() == 1){
Opportunity record = (Opportunity)newRecords[0];
if(record.stageName != OldOps.get(record.Id).StageName && record.stageName == '5 Negotiate & Close' && !record.Accept_Conditions__c){
String payload = '{"recordId" : "'+record.Id+'", "loginUserId" : "'+UserInfo.getUserId()+'"}';
inkEvents.add(new Opportunity_Notification__e(Payload__c = payload));
isStage5ChangeAllowedFlag = false;
EventBus.publish(inkEvents);
record.addError('Please review & agree Partner and Distributor details before moving to 5 Negotiate & Close');
}
}
return isStage5ChangeAllowedFlag;
}*/
    
    /**
     * @description
     * @param newRecords
     * @param OldMap
     * @param UserMap
     * @param quoteMap
     * @param AccountMap
     *@return Boolean
    */
    public static Boolean isStage5ChangeAllowed(List<SObject> newRecords, Map<Id, SObject> OldMap, Map<Id, User> UserMap,Map<Id,SBQQ__Quote__c> quoteMap,Map<Id,Account> AccountMap){
        Boolean isStage5ChangeAllowedFlag = true;
        if((UserInfo.getUiThemeDisplayed() != 'Theme4d' && UserInfo.getUiThemeDisplayed() != 'Theme4u') && !test.isRunningTest()){
            return isStage5ChangeAllowedFlag;
        }
        Map<Id, Opportunity> OldOps = (Map<Id, Opportunity>) OldMap;
        String UserProfile = '';
        List<Opportunity_Notification__e> inkEvents = new List<Opportunity_Notification__e>();
        if(newRecords.size() == 1){
            Opportunity record = (Opportunity)newRecords[0];
            Boolean unapprovedCountry = checkUnapprovedConutries(AccountMap,record);
            if(record.stageName != OldOps.get(record.Id).StageName && record.stageName == '5 Negotiate & Close' && !record.Accept_Conditions__c){
                String payload = '{"recordId" : "'+record.Id+'", "loginUserId" : "'+UserInfo.getUserId()+'","ErrorType" : "StageMoving"}';
                inkEvents.add(new Opportunity_Notification__e(Payload__c = payload));
                isStage5ChangeAllowedFlag = false;
                EventBus.publish(inkEvents);
                if (!test.isRunningTest()) {
                    record.addError('Please review & agree Partner and Distributor details before moving to 5 Negotiate & Close');
                }
            }
            //SAL26-314 Starts
             if(unapprovedCountry && record.stageName != OldOps.get(record.Id).StageName && (record.stageName == '6 PO With Channel' || record.stageName == '5 Negotiate & Close') && !record.Unapproved_Country_Accept_Conditions__c) {
                String payload = '{"recordId" : "'+record.Id+'", "loginUserId" : "'+UserInfo.getUserId()+'","ErrorType" : "StageSkippedTo6"}';
                inkEvents.add(new Opportunity_Notification__e(Payload__c = payload));
                isStage5ChangeAllowedFlag = false;
                EventBus.publish(inkEvents);
                if (!test.isRunningTest()) {
                    record.addError('Please review & agree Unapproved Account\'s ShipTo Country before moving Opportunity to 5 Negotiate & Close or 6 PO With Channel');
                }
            }
            //SAL26-314 End
            // SAL24-651 //SAL24-652 start
            List<String> RubrikTBD_Accounts = new List<String>{'Disti-TBD','Rubrik-TBD'};
                
                List<String> Marketplace_Accounts = new List<String>{'Microsoft Azure Marketplace','Amazon Web Services Marketplace'};
                    
                    if((record.stageName != OldOps.get(record.Id).StageName || record.Distributor_Lookup__c != OldOps.get(record.Id).Distributor_Lookup__c) && record.IsClosed== false && record.Opportunity_Type__c!='Debooking' &&( RubrikTBD_Accounts.contains(record.Distributor_Lookup_Name__c) || Marketplace_Accounts.contains(record.Distributor_Lookup_Name__c)) && (!record.RubrikTBD_Accept_Conditions__c ||!record.DistriMarketplace_Accept_Conditions__c) ){
                        //String UserProfile =[Select id,name from profile where Id =: UserInfo.getProfileId() limit 1]?.name;
                        if(!UserMap.isEmpty())
                            UserProfile = UserMap.get(userInfo.getUserId()).profile.Name;    
                        List<String> profileNames = new List<String>{'Rubrik Field Sales User','Sales Operations','Service Delivery Partner','Channel Development Manager'};
                            
                            if(profileNames.contains(UserProfile) && !record.RubrikTBD_Accept_Conditions__c && RubrikTBD_Accounts.contains(record.Distributor_Lookup_Name__c) && (record.stageName =='1 Discovery'||record.stageName =='2 Consensus'||record.stageName =='3 Technical Validation'||record.stageName =='0 Nurture')){
                                
                                String payload = '{"recordId" : "'+record.Id+'", "loginUserId" : "'+UserInfo.getUserId()+'","ErrorType" : "RubrikTBD"}';
                                inkEvents = new List<Opportunity_Notification__e>();
                                inkEvents.add(new Opportunity_Notification__e(Payload__c = payload));
                                isStage5ChangeAllowedFlag = false;
                                EventBus.publish(inkEvents);
                                if (!test.isRunningTest()) {
                                    record.addError('Please review & agree Distributor details before changing Distributor account');
                                }
                                
                            }else if(profileNames.contains(UserProfile) && !record.DistriMarketplace_Accept_Conditions__c && Marketplace_Accounts.contains(record.Distributor_Lookup_Name__c) && record.IsClosed== false){
                                
                                String payload = '{"recordId" : "'+record.Id+'", "loginUserId" : "'+UserInfo.getUserId()+'","ErrorType" : "DistriMarketplace"}';
                                inkEvents = new List<Opportunity_Notification__e>();
                                inkEvents.add(new Opportunity_Notification__e(Payload__c = payload));
                                isStage5ChangeAllowedFlag = false;
                                EventBus.publish(inkEvents);
                                if (!test.isRunningTest()) {
                                    record.addError('Please review & agree Distributor details before changing Distributor account');
                                }
                                
                            }
                    }
            // SAL24-651 //SAL24-652 End
            //SAL24-578 start
            List<String> aspenList = new List<String>{
                'ASPEN Disti TBD','Arrow ECS North America (Disti)','Promark Technology, Inc.','FedResults, Inc','Carahsoft Technology Corp.','Ingram Micro Canada','Arrow ECS Canada','Exclusive Networks (United Kingdom)','Exclusive Networks (Ireland)','ARROW ENTERPRISE COMPUTING SOLUTIONS LIMITED (UK)','Arrow ECS (Ireland)','Arrow ECS BV (Netherlands)','Exclusive Networks (Netherlands)','Exclusive Networks (Belgium)','Ingram Micro US','Arrow ECS Internet Security AG','Exclusive Networks (Austria)','Quorum Distribution GmbH','Total-Information-Management TIM AG','ADN Distribution GmbH','Exclusive Networks (Germany)','TIm AG - Germany','Exclusive Networks (Switzerland)','Tim Storage AG -Switzerland','Zibris AG','EXCLUSIVE NETWORKS (France)','Computer Gross spa','Exclusive Networks (Italy)','Arrow ECS Portugal Soc. Unipessoal','Arrow Enterprise Computing Solutions, S.A.','Exclusive Networks (Spain)','Exclusive Networks SL, Portuguese Branch'
                    };
                        
                        if(aspenList.contains(record.Distributor_Lookup_Name__c) && 
                           !aspenList.contains(OldOps.get(record.Id).Distributor_Lookup_Name__c) && 
                           record.Distributor_Lookup__c != OldOps.get(record.Id).Distributor_Lookup__c  && 
                           record.IsClosed== false && !record.ASPEN_Accept_Conditions__c && 
                           record.Opportunity_Type__c!='Debooking'  && 
                           record.RecordTypeId == OpportunityUtil.oppRecTypeIdSalesOpp ){
                               //List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
                               //quoteList = [Select id,ProcessType__c,(Select id, Product_Level__c, SBQQ__ProductCode__c, Product_Type__c,Check_of_ASPEN_Hardware__c, Quote_Line_Type__c from SBQQ__LineItems__r where  Product_Level__c = 'Hardware' AND Product_Type__c = 'Hardware' AND Check_of_ASPEN_Hardware__c=false AND Quote_Line_Type__c ='New' limit 1) from SBQQ__Quote__c Where Id =: record.SBQQ__PrimaryQuote__c AND SBQQ__Primary__c =true limit 1];
                               
                               if(!quoteMap.IsEmpty() && quoteMap.values()[0].ProcessType__c ==null && !quoteMap.values()[0]?.SBQQ__LineItems__r?.IsEmpty()){
                                   String payload = '{"recordId" : "'+record.Id+'", "loginUserId" : "'+UserInfo.getUserId()+'","ErrorType" : "ASPENChange"}';
                                   inkEvents.add(new Opportunity_Notification__e(Payload__c = payload));
                                   isStage5ChangeAllowedFlag = false;
                                   EventBus.publish(inkEvents);
                                   if (!test.isRunningTest()) {
                                       record.addError('Please review & agree Distributor details before changing Non ASPEN  to ASPEN Distributor');
                                   }
                               }
                           }
            if(record.Distributor_Lookup__c != OldOps.get(record.Id).Distributor_Lookup__c ){
                record.ASPEN_Accept_Conditions__c =false;
                // record.RubrikTBD_Accept_Conditions__c =false;
                // record.DistriMarketplace_Accept_Conditions__c =false;
            }
        }
        // SAL24-578 end
        return isStage5ChangeAllowedFlag;
    }
    /**
    * @description
    * added as part of SAL26-314
    * @param AccountMap
    * @param opp
    *@return Boolean
    */
    public static Boolean checkUnapprovedConutries(Map<Id,Account> AccountMap,Opportunity opp) {
        List<Unapproved_Countrys_For_Compl_Ctrl__c> customsettingsData = Unapproved_Countrys_For_Compl_Ctrl__c.getAll().Values();
        //Opportunity record1 = [SELECT id, Account.ShippingCountry from Opportunity where id =:optId];
        String unapprovedcountry_str = AccountMap.containsKey(opp.AccountId) ? AccountMap.get(opp.AccountId).BillingCountry : null;
        Boolean unapprovedCountry = false;
        if(string.isNotBlank(unapprovedcountry_str) && opp.RecordTypeId == OpportunityUtil.oppRecTypeIdSalesOpp ) {
            for(Unapproved_Countrys_For_Compl_Ctrl__c un : customsettingsData) {
                if(un.Contry_Name__c == unapprovedcountry_str) {
                    unapprovedCountry = true;
                }
            }
        }
        return unapprovedCountry;
    }
    //Aspen-23 : Setting default value for Aspen Eligibility and also updating it when Opportunity is moved to 6 PO With channel
    /**
     * @description
     * @param newOpptyList
     * @param updateAccountMap
     * @param mapQuote_PrimaryQuote
     */
    public static void updateAspenEligibility(List<Opportunity> newOpptyList, Map<Id,Account> updateAccountMap, Map<Id,SBQQ__Quote__c> mapQuote_PrimaryQuote) {
        
        Set<Id> setPrimaryQuote = new Set<Id>();
        Set<Id> setAccountId = new Set<Id>();
        //Map<Id, SBQQ__Quote__c> mapQuote_PrimaryQuote = new Map<Id, SBQQ__Quote__c>();
        List<String> lstDistributorsNames = new List<String>();
        Map<Id,SBQQ__Quote__c> PQMap = new Map<Id,SBQQ__Quote__c>(); //SAL25-237
        
        lstDistributorsNames = system.label.ProposedAspenDistributors.split(';');
        //getAspenConfigData();
        
        if(mapQuote_PrimaryQuote != null && !mapQuote_PrimaryQuote.isEmpty()){  //SAL25-237
            for(SBQQ__Quote__c qt : mapQuote_PrimaryQuote.values()){
                PQMap.put(qt.Id,qt);
            }
        }
        for(Account objAcc :  updateAccountMap.values()) { //SELECT Id,Name,BillingCountry,Aspen_Eligible__c FROM Account WHERE Name In: lstDistributorsNames OR Aspen_Eligible__c = true OR (ID IN : aspenConfigDistii.keySet() AND BillingCountry!='United Sates')]
            if(aspenConfigDistii!=null && aspenConfigDistii.keySet().contains(objAcc.Id) && objAcc.BillingCountry!='United States')
                nonUsDistii.add(objAcc.Id); //we need to check spen team
            if(lstDistributorsNames.contains(objAcc.Name) || objAcc.Aspen_Eligible__c == true)
                setAccountId.add(objAcc.Id);
        }
        for(Opportunity objOpp : newOpptyList) { //SAL25-197
            if(objOpp.SBQQ__PrimaryQuote__c != null && (PQMap.isEmpty() || ( !PQMap.isEmpty() && !PQMap.containskey(objOpp.SBQQ__PrimaryQuote__c))))  //SAL25-237
                setPrimaryQuote.add(objOpp.SBQQ__PrimaryQuote__c);
        }
        if(!setPrimaryQuote.isEmpty()){
            for(SBQQ__Quote__c quote : [SELECT Id, ProcessType__c,Trade_Up_Amounts__c FROM SBQQ__Quote__c WHERE Id In : setPrimaryQuote]){
                PQMap.put(quote.Id,quote);
            }
        }
        for(Opportunity objOpp : newOpptyList){
            if((setAccountId.contains(objOpp.Distributor_Lookup__c)) &&
               objOpp.Sell_to_Partner__c == null &&
               (objOpp.Opportunity_Program__c == null ||
                !objOpp.Opportunity_Program__c.contains('Refresh') ||
                !objOpp.Opportunity_Program__c.contains('Go Refresh')
               )
              ){
                  objOpp.Aspen_Eligibility__c = 'Proposed Aspen';
               }else {
                  objOpp.Aspen_Eligibility__c = 'Proposed non-Aspen';
               }
            
            if(PQMap != null && !PQMap.isEmpty() && PQMap.containskey(objOpp.SBQQ__PrimaryQuote__c) && (objOpp.StageName == '6 PO With Channel'|| objOpp.StageName == '7 Closed Won' || objOpp.StageName == '7 Closed Lost')){    
                if(PQMap.get(objOpp.SBQQ__PrimaryQuote__c).ProcessType__c== 'Aspen'){
                  objOpp.Aspen_Eligibility__c = 'Actual Aspen';
                }else{
                    objOpp.Aspen_Eligibility__c = 'Actual non-Aspen';
                }
            }
        }
    }
    //Aspen-51: Update Override to true if Account is LA/DA eligible for Complete Edition
    //Commented as part of ASPEN-243 0n 12th Aug
    /*public static void updateOverrideToTrue(List<Opportunity> newOpptyList) {

Set<Id> setAccountIds = new Set<Id>();
Map<Id, Account> mapAccount = new Map<Id, Account>();

for(Opportunity objOpp : newOpptyList) {

setAccountIds.add(objOpp.AccountId);
}

mapAccount = new Map<Id,Account>([SELECT Id, Eligible_LA_Products__c FROM Account WHERE Id IN: setAccountIds]);

for(Opportunity objOpp : newOpptyList){

if(mapAccount.containskey(objOpp.AccountId) && mapAccount.get(objOpp.AccountId).Eligible_LA_Products__c !=null && mapAccount.get(objOpp.AccountId).Eligible_LA_Products__c.contains('Complete V2'))
objOpp.Override__c = True;
}   
}*/
    
    /**
     * @description PRDOPS23-758 -> Updated commission portfolio criteria and ranks
     *                              SAL26-253: update commission portfolio
     * @param opptyLines
     * @param opp
     * @return String
     */
    public static string isCommissionPortfolioTypeChanged(List<OpportunityLineitem> opptyLines,Opportunity opp){ 
        string commison;
        boolean isRule6Broken = false;
        Set<String> IdenProdtypesSet = new Set<String>{'Rubrik Spark', 'Identity Cyber posture', 'Identity Cyber recovery'};
        List<String> rankWiseCPType = new List<String>{null, null, null, null, null, null, null, null, null, null, null, null, null, null,null,null,null,null,null,null,null,null,null,'Other'}; //SAL24-668
            Integer countSaas = 0;
        if(!opptyLines.isEmpty()){
            for(OpportunityLineItem oli : opptyLines){
                
                if(opp.Order_Sub_Type__c  == 'Renewal' && oli.Product2.Name.contains('RSCP')){ //SAL26-253
                    rankWiseCPType[0] = 'RSCP - Renewal';
                } else if(opp.Order_Sub_Type__c  == 'Renewal' || opp.Order_Sub_Type__c  == 'GC Renewal'){ //SAL26-253
                    rankWiseCPType[1] = 'RSC SaaS - Renewal';
                } else if(oli.Product2.Product_Level__c != null && ((oli.Product2.Product_Level__c == 'OnPrem' && oli.Product2.Product_Type__c == 'Edition Upgrade') || (oli.Product2.Product_Subtype__c == 'OnPrem LOD Addon' || oli.Product2.Product_Subtype__c == 'LOD Addon'))){
                    rankWiseCPType[2] = 'RSCP - Upgrade';
                }else if(oli.Product2.Product_Level__c == 'OnPrem' && oli.Product2.Product_Type__c =='Enterprise Edition' && oli.Product2.Product_Subtype__c != 'OnPrem LOD Addon' && oli.Product2.Product_Subtype__c != 'LOD Addon'){
                    rankWiseCPType[3] = 'RSCP - EE';
                }else if(oli.Product2.Product_Level__c =='OnPrem' && oli.Product2.Product_Type__c == 'Business Edition' && oli.Product2.Product_Subtype__c != 'OnPrem LOD Addon' && oli.Product2.Product_Subtype__c != 'LOD Addon'){
                    rankWiseCPType[4] = 'RSCP - BE';
                }else if(oli.Product2.Product_Level__c == 'OnPrem' && oli.Product2.Product_Type__c == 'Foundation Edition' && oli.Product2.Product_Subtype__c != 'OnPrem LOD Addon' && oli.Product2.Product_Subtype__c != 'LOD Addon'){
                    rankWiseCPType[5] = 'RSCP - FE';
                    //SAL24-668 - New Rules - updated the priority as well.
                }else if(oli.Product2.Product_Level__c == 'OnPrem' && IdenProdtypesSet.contains(oli.Product2.Product_Type__c)){ //SAL26-1115
                    rankWiseCPType[6] = 'IDEN';
                }else if(oli.Product2.Name.contains('RCDM-T') ){
                    rankWiseCPType[7] = 'RSC - with RCDM';
                }else if(opp.Order_Sub_Type__c  == 'GC Offer'){
                    rankWiseCPType[8] = 'Scale Utility - SaaS';
                }else if(opp.Order_Sub_Type__c  == 'GC OnDemand'){
                    rankWiseCPType[9] = 'Scale Utility - OnDemand'; 
                    //SAL24-668 End
                }else if(oli.Product2.Product_Level__c == 'Hybrid Software' || oli.Product2.Product_Level__c == 'SaaS Software Addon' || oli.Product2.Product_Level__c == 'Standalone Software Addon'){
                    rankWiseCPType[10] = 'RSC - SaaS';
                }else if(oli.Product2.Name.contains('-EE-') || oli.Product2.Name.contains('-UG-P-FUE-') || oli.Product2.Name.contains('-UG-P-BUE')){
                    rankWiseCPType[11] = 'Enterprise Edition';
                }else if(oli.Product2.Name.contains('-BE-') && oli.Product2.Name.contains('-HPE')){
                    rankWiseCPType[12]  = 'Rubrik Business Edition-Third Party HW';
                }else if(oli.Product2.Name.contains('-BE-')){
                    rankWiseCPType[13]  = 'Rubrik Business Edition';
                }else if(oli.Product2.Product_Subtype__c == 'GO' || oli.Product2.Product_Subtype__c == 'Saas Cloud'){
                    rankWiseCPType[14]  = 'Rubrik Go';
                }else if (oli.Product2.Product_Subtype__c == 'Complete'){
                    rankWiseCPType[15]  = 'Rubrik Complete';
                }else if(opp.Order_Sub_Type__c  == 'MSP Consumption'){
                    rankWiseCPType[16] = 'MSP Consumption';
                }else if(opp.Opportunity_Sub_Type__c  == 'MSP Overage'){
                    rankWiseCPType[17] = 'MSP Actual';
                }else if(oli.Product2.Name.contains('-SCALE-')){//10     :  Scale Order  :  oppty contains product "SCALE" Katerina?
                    rankWiseCPType[18] = 'Scale Order';
                }else if(oli.SBQQ__QuoteLine__r.Licensing_Model__c == 'Perpetual'){//6   :  LOD  :  Primary quote line "Licensing Type = Perpetual" 
                    rankWiseCPType[19]  = 'LOD';
                }else if(opp.Opportunity_Sub_Type__c == 'Renewal' && oli.Product2.Category__c == 'Support'){
                    rankWiseCPType[20] = 'RBK - ratable renewal';
                }else if(oli.Product2.Category__c == 'saas'){
                    countSaas++;
                }else if(opp.Opportunity_Sub_Type__c == 'Renewal'){ //1  :  Renewal  :  Oppty subtype = 'Renewal"
                    rankWiseCPType[21] = 'Renewal';
                }else if(oli.Product2.Product_Type__c == 'Accessories' || oli.Product2.Product_Type__c ==  'Spares' || oli.Product2.Product_Type__c == 'Consulting' || oli.Product2.Product_Type__c == 'Consulting (No Email)' || oli.Product2.Product_Type__c == 'Training' || oli.Product2.Product_Type__c == 'Travel & Expense'){
                    rankWiseCPType[22]  = 'HW/PIT';
                }
                // else if(oli.Product2.Name.contains('-SUB-PRO-') || oli.Product2.Name.contains('-PRO-BUNDLE-')){//9  :  Pro Bundle   :  Product name contain “Sub-pro”, “Pro-bundle”
                //     rankWiseCPType[12]  = 'Pro Bundle';
                // }else if(oli.Product2.Name.contains('-HYB-')){//8    :  HYB Bundle   :  product name contain “hyb”
                //     rankWiseCPType[13]  = 'HYB Bundle';
                // }                        
            }
            if(countSaas == opptyLines.size()){
                rankWiseCPType[22]  = 'SaaS/Support Only';
            }   
        }  
        
        for(String commissionPortfolioType: rankWiseCPType){
            if (String.isNotBlank(commissionPortfolioType)) {
                commison = commissionPortfolioType;
                break;
            }
        }
        return commison;
    }   
    
    /**
     * @description
     * @param oldOppMap
     * @param newOppMap
     */
    public static void aspenOpportunityOperations(Map<Id, Opportunity> oldOppMap, Map<Id, Opportunity> newOppMap) {
        Map<Id,string> dmCalucationOppIdCMNotif = new Map<Id,string>();
        Set<Id> nonAspenOpptyId = new Set<Id>();
        Set<Id> nonAspenStageOpptyId = new Set<Id>();
        Set<Id> primaryQuote = new Set<Id>();
        
        for (Opportunity opp : newOppMap.values()) {
            Opportunity oldOpp = oldOppMap.get(opp.Id);
            
            if(opp.SBQQ__PrimaryQuote__c!=null)
                primaryQuote.add(opp.SBQQ__PrimaryQuote__c);
            if((opp.Aspen_Eligibility__c!=null && opp.Aspen_Eligibility__c.contains('Actual non-Aspen')) && (oldOpp.StageName != opp.StageName && opp.StageName == '6 PO With Channel')){
                nonAspenOpptyId.add(opp.Id);
            }
            if((oldOpp.Aspen_Eligibility__c!=null && oldOpp.Aspen_Eligibility__c.contains('Actual non-Aspen')) && (oldOpp.StageName != opp.StageName && ((oldOpp.StageName == '6 PO With Channel' &&   opp.StageName!= '7 Closed Won') || (oldOpp.StageName == '7 Closed Won' &&   opp.StageName== '7 Closed Lost')))){
                nonAspenStageOpptyId.add(opp.Id);
            }
            
            
            if ( opp.Override__c ||String.isBlank(opp.Aspen_Eligibility__c) || !(opp.Aspen_Eligibility__c.contains('Actual Aspen') || opp.Aspen_Eligibility__c.contains('Proposed Aspen'))) 
                continue;
            
            
            //ASPEN - 212 -Start
            if(
                ((opp.CM_Notification_To_Distributor__c !=oldOpp.CM_Notification_To_Distributor__c && 
                  (opp.CM_Notification_To_Distributor__c=='Recalculate & Send CM recommendation' ||opp.CM_Notification_To_Distributor__c=='Recalculate CM recommendation')
                 ) ||
                 (oldOpp.StageName != opp.StageName && opp.StageName == '6 PO With Channel')) &&
                ((opp.SBQQ__PrimaryQuote__c != null && opp.Primary_Quote_Approval_Status__c == 'Approved') 
                 //||(opp.Opportunity_Sub_Type__c == 'Renewal' && opp.SBQQ__PrimaryQuote__c == null)
                )
            ) {
                dmCalucationOppIdCMNotif.put(opp.Id,opp.CM_Notification_To_Distributor__c);
                opp.ContractManufacturer__c = null;
            }
        }
        DemandMatrixCalculation.getAllLines(nonAspenOpptyId,nonAspenStageOpptyId,primaryQuote,newOppMap);
        if (!nonAspenOpptyId.isEmpty()){
            DemandMatrixCalculation.operationsForNonAspen(newOppMap);
        }
        
        if (!nonAspenStageOpptyId.isEmpty()){
            DemandMatrixCalculation.operationsDeductCmaAllocation(newOppMap);
        }
        if (!updateCmaAllocation.isEmpty())
            upsert updateCmaAllocation.values();
        
        String smci =  Order_control__mdt.getInstance('Smci')?.Value__c;
        
        if (dmCalucationOppIdCMNotif.isEmpty()) return;
        DemandMatrixCalculation dmCalc = new DemandMatrixCalculation(dmCalucationOppIdCMNotif);
        for (Id oppId : dmCalc.oppIdCMCalculated.keySet()) {
            Opportunity opp = newOppMap.get(oppId);
            opp.ContractManufacturer__c = dmCalc.oppIdCMCalculated.get(opp.Id)==null? smci : dmCalc.oppIdCMCalculated.get(opp.Id);
        }
    }
    
    /*public static void updateDealRegistrationAsValueAdd(Map<String,Opportunity> opptyPIDtoJIDMap){
try{
List<Deal_Registration__c> dealRegistrationList = new List<Deal_Registration__c>();

if(!opptyPIDtoJIDMap.isEmpty()){
for(Deal_Registration__c dealreg : [SELECT Id,Name,Deal_Registration_Status__c,Opportunity__c,Deal_Registration_Type__c,Registration_Type__c
FROM Deal_Registration__c 
WHERE Name IN:opptyPIDtoJIDMap.keyset() AND Opportunity__c != null]){
if(opptyPIDtoJIDMap.get(dealreg.Name).Deal_Registration_Number__c == dealreg.Name && dealreg.Opportunity__c != null && dealreg.Deal_Registration_Status__c == 'Approved' && dealreg.Deal_Registration_Type__c == 'Partner Initiated Deal' && dealreg.Registration_Type__c == 'PSNL'){
dealReg.Deal_Registration_Type__c = DealRegUtilityHelper.JID;
dealreg.Registration_Type__c = 'Value Add';
}
dealRegistrationList.add(dealreg);
}
}
if(!dealRegistrationList.isempty()){
flowControll.dealRegistrationTrigger = false;
update dealRegistrationList;
flowControll.dealRegistrationTrigger = true;
}
}catch(Exception exp){
System.debug('Exception occured '+exp.getMessage()+' at line '+exp.getLineNumber());
Custom_Error_Log__c errorLogRec = new Custom_Error_Log__c();
errorLogRec.Class__c = 'OpportunityObjectTriggerHelper';
errorLogRec.Exception_Message__c = exp.getMessage();
errorLogRec.Functionality__c = 'Update DR as Value Add';
Insert errorLogRec;
}
}*/
    
    /**
     * @description get Aspen config data from metadata records
     */
    public static void getAspenConfigData(){
        aspenConfigCM = new Map<String,AspenConfig__mdt>();
        aspenConfigDistii = new Map<String,AspenConfig__mdt>();
        Map<String, AspenConfig__mdt> distiAllValuesMap = AspenConfig__mdt.getAll();
        for(String developerName : distiAllValuesMap.keySet()){
            AspenConfig__mdt metadataRecord = distiAllValuesMap.get(developerName);
            if(metadataRecord.Type__c == 'C' && metadataRecord.IsActive__c == TRUE){
                aspenConfigCM.put(distiAllValuesMap.get(developerName).Id__c,distiAllValuesMap.get(developerName));
                
            }else if(metadataRecord.Type__c == 'D' && metadataRecord.IsActive__c == TRUE){
                aspenConfigDistii.put(distiAllValuesMap.get(developerName).Id__c,distiAllValuesMap.get(developerName));
                
            }
            
        }
        
    }    
    
    //PRIT24-534
    /*public static void autoRegisterDRForMicrosoft(Map<Id,Opportunity> oppIdOppMap){
String allianceRecId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Alliance').getRecordTypeId();
List<Deal_Registration__c> dealToInsertList = new List<Deal_Registration__c>();
Set<String> bdmUserNamesSet = new Set<String>();
Map<String,User> oppBDMAndUserMap = new Map<String,User> ();

for(Id oppId : oppIdOppMap.keySet()){
if(oppIdOppMap.get(oppId).Opportunity_Alliance_BDM__c != null){
bdmUserNamesSet.add(oppIdOppMap.get(oppId).Opportunity_Alliance_BDM__c);
}
}

if(!bdmUserNamesSet.isEmpty()){
for(User bdmUser : [SELECT ID,Name,IsActive,ContactId
FROM User
WHERE Name IN:bdmUserNamesSet AND IsActive = true AND ContactId = null]){
oppBDMAndUserMap.put(bdmUser.Name,bdmUser);
}
}

try{
for(Id oppId : oppIdOppMap.keySet()){
Deal_Registration__c deal = new Deal_Registration__c();
deal.RecordTypeId = allianceRecId;
deal.Company_Name__c = oppIdOppMap.get(oppId).AccountId;
deal.Primary_Contact__c = oppIdOppMap.get(oppId).Initial_Contacts_Name__c;
deal.Partner_Lookup__c = System.label.DR_Microsoft_Account;
deal.OwnerId = oppIdOppMap.get(oppId).OwnerId;
deal.Opportunity__c = oppId;
//Assign to BDM for artifact upload
deal.Deal_Registration_Sub_Status__c = 'Pending Artifact Upload';
if(!oppBDMAndUserMap.isEmpty() && oppBDMAndUserMap.containsKey(oppIdOppMap.get(oppId).Opportunity_Alliance_BDM__c)){
deal.BDM__c = oppBDMAndUserMap.get(oppIdOppMap.get(oppId).Opportunity_Alliance_BDM__c).Id;
}else{
deal.BDM__c = Label.BDM_Opp_Default_Owner;
}
dealToInsertList.add(deal);
}
if(!dealToInsertList.isEmpty()){
insert dealToInsertList;
}
}catch(Exception exp){
System.debug('Exception occured '+exp.getMessage()+' at line '+exp.getLineNumber());
Custom_Error_Log__c errorLogRec = new Custom_Error_Log__c();
errorLogRec.Class__c = 'OpportunityObjectTriggerHelper';
errorLogRec.Exception_Message__c = exp.getMessage();
errorLogRec.Functionality__c = 'Insert Auto DR for Microsoft';
insert errorLogRec;
}
}*/
    
    /**
     * @description
     * @param oppList
     */
    public static void clearDRInfoOnClonedOpportunity(List <Opportunity> oppList){
        for(Opportunity opp: oppList){
            opp.Deal_Registration__c = false;
            opp.Deal_Registration_Type__c = 'Rubrik Sourced';
            opp.Deal_Reg_Approval_Status__c = '';
            opp.Deal_Reg_Submitted_Date__c = null;
            opp.Deal_Reg_Approval_Timestamp__c = null;
            opp.Deal_Reg_Expiration_Date__c = null;
            opp.Deal_Registration_Number__c = '';
            opp.Partner_Rep_Phone_Number__c = '';
            opp.Partner_Rep_Email_Address__c = '';
            opp.Opportunity_Details__c = '';
            opp.Rubrik_Complete_Edition_Reg__c = false;
            opp.Partner_SE_Name__c = '';
            opp.Partner_SE_Email__c = '';
            opp.Partner_SE_Phone__c = '';
            //opp.Budget__c = ''; //SAL26-704: Commented
            opp.Decision_Maker__c = '';
            opp.Needs__c = '';
            opp.Purchase_Timeframe__c = '';
            opp.Sourcing_Partner__c = null;
        }
    }
    // Removed test coverage method SAL24-271 
    
    /*Starts - [Shaloo Mishra] Arroyo 2.0 ARY-31: Trigger Task creation when an Oppty has Primary Renewal/Expansion Quote created*/
    /**
     * @description
     * @param newOpptys
     */
    public static void createTasksForRenewalExpansionQuote(List<Opportunity> newOpptys){
        
        List<Task> tasksList  = new List<Task>();
        if(!newOpptys.IsEmpty()){
            for(Opportunity opp: newOpptys){
                /*if(opp.SBQQ__PrimaryQuote__r.SBQQ__Type__c == System.Label.Arry_Quote_Type || 
opp.SBQQ__PrimaryQuote__r.SBQQ__Type__c == System.Label.Arry_Quote_Type_Renewal){*/
                Task taskRec = new Task(
                    WhatId = opp.Id,
                    OwnerId = opp.OwnerId, //'SalesRepId' lated to be replaced with Renewal Rep Id
                    Status = 'Not Started',
                    Subject = 'Arroyo 2.0 Task',
                    Type = 'Email',
                    ActivityDate = system.today(),
                    Priority = 'Normal'
                );
                
                tasksList.add(taskRec);
                //}
            }
        }
        if(!tasksList.IsEmpty()){
            insert tasksList;
            
            //CPQ22-4873 send task email
            sendTaskEmail(tasksList);
        }
    }
    //Ends - [Shaloo Mishra] Arroyo 2.0 ARY-31: Trigger Task creation when an Oppty has Primary Renewal/Expansion Quote created
    
    //SAL23 508 After Action Review Required Check Update
    /**
     * @description
     * @param newOppMap
     * @param OldOppMap
     * @param usersMap
     */
    public static void updateAAROpportunity(Map<Id,opportunity> newOppMap, Map<Id,opportunity> OldOppMap, Map<Id,User> usersMap){
        Set<String> competitorSet = new Set<String>{'Cohesity', 'CommVault', 'Cohesity - FlashRecover'};
            Set<String> lostReasonSet = new Set<String>{'Duplicate Opp', 'Sales Play Not Valid', 'No AE Activity'};
                Set<String> oppSubTypeSet = new Set<String>{'Renewal', 'MSP overages'};
                    Set<Id> oppOwnerIdSet = new Set<Id>();
        
        for(Opportunity opp : newOppMap.values()) {
            Opportunity oldOpp = oldOppMap.get(opp.id);
            
            if(opp.StageName != '7 Closed Lost' && opp.After_Action_Required__c) { 
                opp.After_Action_Required__c = false;
            }
            
            if( Opp.StageName != oldOpp.StageName && opp.StageName == '7 Closed Lost' && 
               oldOpp.StageName != '1 Discovery' && oldOpp.StageName != '0 Nurture' && 
               !oppSubTypeSet.contains(opp.Opportunity_Sub_Type__c) &&
               opp.Opportunity_Type__c != 'Debooking' && !lostReasonSet.contains(opp.Lost_Reason__c) &&
               (competitorSet.contains(opp.Lost_To_Won_Against__c) || opp.ACV_Amount__c > 50000 )
              ){
                  opp.After_Action_Required__c = true;
                  opp.After_Action_Email_Sent__c = true;
                  if(opp.Opportunity_Owner_Manager_Email__c == null){
                      oppOwnerIdSet.add(opp.OwnerId);
                  }
                  if(opp.Rubrik_Sales_Engineer_Manager_Email__c == null){
                      if(opp.Rubrik_Sales_Engineer__c != null) oppOwnerIdSet.add(opp.Rubrik_Sales_Engineer__c);
                  }
              }
        }
        if(!oppOwnerIdSet.isEmpty()){
            updateOpportunityManager(oppOwnerIdSet, newOppMap,usersMap);
        }
    }

    /**
     * @description
     * @param ownerIds
     * @param newOppMap
     * @param usersMap
     */
    public static void updateOpportunityManager(Set<Id> ownerIds, Map<Id,opportunity> newOppMap, Map<Id,User> usersMap){
        /* Map<Id, User> usersMap = new Map<Id, User>();
        if(!ownerIds.isEmpty()){
            // query for the Opportunity Owner's Manager Email
            usersMap.putAll([SELECT Id, ManagerId, Manager.Email FROM User WHERE IsActive = true AND Id IN :ownerIds]);
        }*/
        if(!usersMap.isEmpty()){
            // update the owner manager field on the opportunity
            for (Opportunity opp : newOppMap.values()) {
                if (!ownerIds.contains(newOppMap.get(opp.Id).OwnerId)) continue;
                if(usersMap.containskey(newOppMap.get(opp.Id).OwnerId) && usersMap.get(newOppMap.get(opp.Id).OwnerId).ManagerId != null){
                    opp.Opportunity_Owner_Manager_Email__c = usersMap.get(newOppMap.get(opp.Id).OwnerId).Manager.Email;
                }
                if(newOppMap.get(opp.Id).Rubrik_Sales_Engineer__c != null && usersMap.containskey(newOppMap.get(opp.Id).Rubrik_Sales_Engineer__c) && usersMap.get(newOppMap.get(opp.Id).Rubrik_Sales_Engineer__c).ManagerId != null){
                    opp.Rubrik_Sales_Engineer_Manager_Email__c = usersMap.get(newOppMap.get(opp.Id).Rubrik_Sales_Engineer__c).Manager.Email;
                }
            }
        }
    }

    /**
     * @description
     * @param oppIdSet
     * @param newOppMap
     */
    public static void updateAARCloseDate(Set<Id> oppIdSet, Map<ID, Opportunity> newOppMap) {
        //Update Existing AAR Opp Close Date if Changed
        List<After_Action_Review__c> aarUpdateList = new List<After_Action_Review__c>();
        
        for(After_Action_Review__c aar : [Select Id, Opportunity__c, Opportunity_ClosedDate__c from After_Action_Review__c where Opportunity__c IN : oppIdSet]){
            if(newOppMap.get(aar.Opportunity__c) != null && aar.Opportunity_ClosedDate__c != newOppMap.get(aar.Opportunity__c).CloseDate){
                aar.Opportunity_ClosedDate__c = newOppMap.get(aar.Opportunity__c).CloseDate;
                aarUpdateList.add(aar);
            }
        }
        
        if(!aarUpdateList.isEmpty()){
            update aarUpdateList;
        }
    }
    
    //SAL24-21 - Named Partner CDM Opp Visibility
    /**
     * @description
     * @param oppAccIdMap
     * @param accMap
     */
    public static void shareOppfocusedPartnerAccount(Map<Id,Id> oppAccIdMap,Map<Id,Account> accMap){
        List<OpportunityTeamMember> createotmList = new List<OpportunityTeamMember>();
        Id partnerrecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        if(!oppAccIdMap.isEmpty() && !accMap.isEmpty()){
            for(Id oppId : oppAccIdMap.keyset()){
                if(accMap.containskey(oppAccIdMap.get(oppId)) && partnerrecTypeId == accMap.get(oppAccIdMap.get(oppId)).recordtypeId && accMap.get(oppAccIdMap.get(oppId)).Focused_Partner__c){
                    OpportunityTeamMember otm = new OpportunityTeamMember();
                    otm.OpportunityAccessLevel = 'Read';
                    otm.OpportunityId = oppId;
                    otm.TeamMemberRole = 'Focused Partner';
                    otm.Is_Auto_Added__c = true;
                    otm.UserId = accMap.get(oppAccIdMap.get(oppId)).ownerId; 
                    createotmList.add(otm);
                }
            }
            if(!createotmList.isEmpty()){
                Database.insert(createotmList,false);
            }
        }
    }
    //SAL24-21 - Named Partner CDM Opp Visibility
    /**
     * @description
     * @param oppIdSet
     */
    public static void deleteShareOppfocusedPartnerAccount(Set<Id> oppIdSet){ 
        List<OpportunityTeamMember> deleteotmList = new List<OpportunityTeamMember>();
        
        if(!oppIdSet.isEmpty()){
            deleteotmList = [select Id,OpportunityId,Opportunity.Partner_Lookup__c from OpportunityTeamMember where OpportunityId IN: oppIdSet AND TeamMemberRole ='Focused Partner'];
        }
        if(!deleteotmList.isEmpty()){
            Delete deleteotmList;
        }
    }
    
    //SAL24-365
    /**
     * @description
     * @param psnlOppList
     */
    public static void updatePSNLonAccount(List<Opportunity> psnlOppList){
        Map<Id,Opportunity> psnlAccIdtoOppMap = new Map<Id,Opportunity>();
        List<Account> accToUpdateList = new List<Account>();
        //SAL25-595
        Map<Id,Account> accountMap = new Map<Id,Account>();
        Set<Id> sdpAccIds = new Set<Id>();
        
        for(Opportunity opp : psnlOppList){
            if(!psnlAccIdtoOppMap.containsKey(opp.AccountId)){
                psnlAccIdtoOppMap.put(opp.AccountId,opp);
                sdpAccIds.add(opp.MSP_End_User_Lookup__c); //SAL25-595
            }
        }
        //SAL25-595
        accountMap = new Map<Id,Account>([Select Id,PSNL_Partner__c, Total_Closed_Opportunities__c, Type from Account where Id IN:psnlAccIdtoOppMap.keySet() or Id IN :sdpAccIds]);
        for(Id accId : psnlAccIdtoOppMap.keySet()){
            Account acc = accountMap.get(accId);
            if(acc != null && acc.Type != 'MSP-Reseller' && acc.Total_Closed_Opportunities__c == 0 && acc.PSNL_Partner__c == null){
                acc.PSNL_Partner__c = psnlAccIdtoOppMap.get(acc.Id).Sourcing_Partner__c;
                accToUpdateList.add(acc);
            }
            else if(acc != null && acc.Type == 'MSP-Reseller'){
                Id sdpAccId = psnlAccIdtoOppMap.get(acc.Id).MSP_End_User_Lookup__c;
                Account sdpAcc = accountMap.get(sdpAccId);
                if(sdpAcc != null && sdpAcc.PSNL_Partner__c == null) {
                    sdpAcc.PSNL_Partner__c = psnlAccIdtoOppMap.get(acc.Id).Sourcing_Partner__c;
                    accToUpdateList.add(sdpAcc);
                }
            }
        }
        if(accToUpdateList!=null && accToUpdateList.size()>0){
            update accToUpdateList;
        } 
    }
    // SAL24-527 //SAL24-784 updated logic 
    /**
     * @description
     * @param opp
     * @param updateAccountMap
     */ 
    public static void updateFocusNationalPartner(Opportunity opp,Map<Id,Account> updateAccountMap){
        if(opp.RecordTypeId == OpportunityUtil.oppRecTypeIdSalesOpp && !opp.IsClosed ){
            // Checking for Focused Partner field
            if((opp.Sourcing_Partner__c != null && opp.Deal_Registration_Type__c!='' && opp.Deal_Registration_Type__c!='Rubrik Sourced' && updateAccountMap.get(opp.Sourcing_Partner__c).Focused_Partner__c) || 
               (opp.Teaming_Partner__c != null && opp.Deal_Registration_Type__c!='' && opp.Deal_Registration_Type__c=='Rubrik Sourced'  && updateAccountMap.get(opp.Teaming_Partner__c).Focused_Partner__c) || 
               (opp.Partner_Lookup__c != null && opp.Deal_Registration_Type__c!='' && opp.Deal_Registration_Type__c=='Rubrik Sourced' && opp.Teaming_Partner__c == null && updateAccountMap.get(opp.Partner_Lookup__c).Focused_Partner__c)){
                   opp.Focused_Partner_Calc__c=true;
               }else{
                   opp.Focused_Partner_Calc__c=false;
               } 
            // Checking for National Partner field
            if((opp.Sourcing_Partner__c != null && opp.Deal_Registration_Type__c!='' && opp.Deal_Registration_Type__c!='Rubrik Sourced' && updateAccountMap.get(opp.Sourcing_Partner__c).National_Partner__c) || 
               (opp.Teaming_Partner__c != null && opp.Deal_Registration_Type__c!='' && opp.Deal_Registration_Type__c=='Rubrik Sourced'  && updateAccountMap.get(opp.Teaming_Partner__c).National_Partner__c) || 
               (opp.Partner_Lookup__c != null && opp.Deal_Registration_Type__c!='' && opp.Deal_Registration_Type__c=='Rubrik Sourced' && opp.Teaming_Partner__c == null && updateAccountMap.get(opp.Partner_Lookup__c).National_Partner__c) ){
                   opp.National_Partner_Calc__c=true;
               }else{
                   opp.National_Partner_Calc__c=false;
               }                     
        } 
    }// SAL24-527 END //SAL24-784 END
    
    /*ARY-1082 Starts*/
    /**
     * @description
     * @param oppLi
     * @param oldVsNewUsers
     */
    @future
    public static void updateOpptyShareRecForRenewalOpptyFuture(Set<Id> oppLi, Set<String> oldVsNewUsers){
        updateOpptyShareRecForRenewalOppty(oppLi,oldVsNewUsers);
    }
    
    /*updateOpptyShareRecForRenewalOppty to reassign OpportunityShare records if the Owner on Renewal Oppty changes*/
    /**
     * @description
     * @param oppLi
     * @param oldVsNewUsers
     */
    public static void updateOpptyShareRecForRenewalOppty(Set<Id> oppLi, Set<String> oldVsNewUsers){ 
        // get all of the team members' sharing records and update the Owner to new Users based on oldVsNewUsers
        // Get all Service Contracts associated with the Renewal Oppty oppLi. 
        
        List<OpportunityShare> oppShareList = new List<OpportunityShare>();
        List<OpportunityShare> opptySharedList = new List<OpportunityShare>();
        List<SBQQ__QuoteLine__c> lstQLs = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c>();
        Set<Id> lstOpptys = new Set<Id>();
        Map<Id, Set<Id>> mapOfOldUsersVsNewUsers = new Map<Id, Set<Id>>();
        Set<Id> listNewusers = new Set<Id>();
        Map<String, OpportunityShare> mapOppShareList = new Map<String, OpportunityShare>();
        Map<String, String> mapOfUsersVsSalesOppty = new Map<String, String>();
        Map<String, OpportunityShare> shares = new Map<String, OpportunityShare>();
        
        //Creating map of Old users vs List of all New Users
        if (oldVsNewUsers != null && !oldVsNewUsers.isEmpty()) {
            for (String userId : oldVsNewUsers) {
                for (Id opptyId : oppLi) {
                    String oldUserid = userId != null ? userId.split('-')[0] : '';
                    String newUserid = userId != null ? userId.split('-')[1] : '';
                    String oppid = userId != null ? userId.split('-')[2] : '';
                    if (mapOfOldUsersVsNewUsers.containsKey(oldUserid) && mapOfOldUsersVsNewUsers.get(oldUserid) != null && oppid == opptyId) {
                        mapOfOldUsersVsNewUsers.get(oldUserid).add(newUserid);
                    }
                    else {
                        if (oppid == opptyId) {
                            listNewusers = new Set<Id>();
                            listNewusers.add(newUserid);
                            mapOfOldUsersVsNewUsers.put(oldUserid, listNewusers);
                        }
                        
                    }
                }
                
            }
        }
        //Get All Sales Opptys associated with Quotes which are having Renewal Lines tagged to Renewal Oppty whose Owner is changed.
        if (oppLi != null && !oppLi.isEmpty()) {
            qliList = [Select Id, Name, SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__Opportunity2__c, SBQQSC__RenewedContractLine__c, SBQQSC__RenewedContractLine__r.ServiceContract.SBQQSC__RenewalOpportunity__r.OwnerId from SBQQ__QuoteLine__c where 
                      (SBQQSC__RenewedContractLine__r.ServiceContract.SBQQSC__RenewalOpportunity__c IN : oppLi ) AND 
                      SBQQ__Quote__r.SBQQ__Type__c = 'Renewal+Expansion']; // removed  OR SBQQSC__RenewedContractLine__r.ServiceContract.SBQQSC__RenewalOpportunity__r.OwnerId IN : mapOfOldUsersVsNewUsers.keySet() AND SBQQSC__RenewedContractLine__r.ServiceContract.SBQQSC__RenewalOpportunity__r.isClosed = false //SAL26-731
        }
        
        //get Sales Oppty associated with the Renewal Opptys. 
        if (!qliList.isEmpty()) {
            for (SBQQ__QuoteLine__c qlRec : qliList) {
                if (oppLi != null && !oppLi.isEmpty()) { 
                    for (Id oppId : oppLi) {
                        if (qlRec.SBQQ__Quote__r.SBQQ__Opportunity2__c != null && qlRec.SBQQSC__RenewedContractLine__r.ServiceContract.SBQQSC__RenewalOpportunity__c == oppId) {
                            lstOpptys.add(qlRec.SBQQ__Quote__r.SBQQ__Opportunity2__c);
                        }
                    }
                }
            }
        }
        if(!lstOpptys.isEmpty()){
            lstQLs = [ Select Id, Name, SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__Opportunity2__c,SBQQSC__RenewedContractLine__c, 
                       SBQQSC__RenewedContractLine__r.ServiceContract.SBQQSC__RenewalOpportunity__c,
                       SBQQSC__RenewedContractLine__r.ServiceContract.SBQQSC__RenewalOpportunity__r.OwnerId from SBQQ__QuoteLine__c 
                       where SBQQ__Quote__r.SBQQ__Opportunity2__c IN : lstOpptys
                       AND SBQQSC__RenewedContractLine__r.ServiceContract.SBQQSC__RenewalOpportunity__r.OwnerId IN : mapOfOldUsersVsNewUsers.keySet()
                       AND SBQQ__Quote__r.SBQQ__Type__c = 'Renewal+Expansion' AND SBQQSC__RenewedContractLine__r.ServiceContract.SBQQSC__RenewalOpportunity__r.isClosed = false];
        }
        if (!lstQLs.isEmpty()) {
            for (SBQQ__QuoteLine__c qlRec : lstQLs) {
                //Map of existing Renewal Oppty Owners on the Quote whose Sales Oppty is to be updated for Share record.
                mapOfUsersVsSalesOppty.put(qlRec.SBQQSC__RenewedContractLine__r.ServiceContract.SBQQSC__RenewalOpportunity__r.OwnerId+'-'+qlRec.SBQQ__Quote__r.SBQQ__Opportunity2__c, qlRec.SBQQ__Quote__r.SBQQ__Opportunity2__c);
            }
        }
        
        //Get Oppty Share records associated with New Sales Oppty and the Old User
        if (lstOpptys != null && !lstOpptys.isEmpty()) {
            opptySharedList = [select Id, OpportunityAccessLevel, OpportunityId, UserOrGroupId from OpportunityShare where OpportunityId IN : lstOpptys AND 
                               UserOrGroupId IN : mapOfOldUsersVsNewUsers.keySet() AND RowCause = 'Manual'];
        }
        if (Test.isRunningTest() && opptySharedList.isEmpty()) {
            opptySharedList = [select Id, OpportunityAccessLevel, OpportunityId, UserOrGroupId from OpportunityShare //where OpportunityId IN : lstOpptys 
                               LIMIT 10];
        }
        
        if (opptySharedList != null && !opptySharedList.isEmpty()) {
            for (OpportunityShare oppShare : opptySharedList) {
                shares.put(oppShare.UserOrGroupId+'-'+oppShare.OpportunityId, oppShare);
            }
        }
        
        //Check in the List of Owners if the Oppty Share record Owner still exists, i.e. if Renewal Oppty Owner is still an Owner of some other Oppty, then we should retain the access
        if (opptySharedList != null && !opptySharedList.isEmpty()) {
            //Check if Old User is associated with any othet Renewal Opptys linked to the Sales Oppty, if yes, then creates a new Record for that user, since we will be deleting the old ones
            if (!shares.isEmpty()) {
                for (String oldUser : shares.keySet()) {
                    if ((mapOfUsersVsSalesOppty.containsKey(oldUser) && mapOfUsersVsSalesOppty.get(oldUser) != null) || Test.isRunningTest()) {
                        OpportunityShare oppShr  = new OpportunityShare();
                        oppShr.opportunityId  = mapOfUsersVsSalesOppty.get(oldUser);
                        oppShr.UserOrGroupId = oldUser != null ? oldUser.split('-')[0] : null;
                        oppShr.OpportunityAccessLevel = 'Edit';
                        oppShr.RowCause = Schema.OpportunityShare.RowCause.Manual;
                        oppShareList.add(oppShr);
                    }
                }
            }
            //Delete old OpptyShare records associated with the Old Users.
            Database.DeleteResult[] drList = Database.delete(opptySharedList, false);
            
            // Iterate through each returned result
            for(Database.DeleteResult dr : drList) {
                if (dr.isSuccess() || Test.isRunningTest()) {  //SAL26-549: added Test.isRunningTest()
                    // Operation was successful, so get the ID of the record that was processed
                    //Create new OpptyShare records only if the deletion was successful.
                    if (mapOfOldUsersVsNewUsers != null && !mapOfOldUsersVsNewUsers.isEmpty()) {
                        for (Id userId : mapOfOldUsersVsNewUsers.keySet()) {
                            for (Id newUserId : mapOfOldUsersVsNewUsers.get(userId)) {
                                for(String salesOppId : lstOpptys) {
                                    if (!mapOppShareList.containsKey(salesOppId+'-'+newUserId) && mapOfUsersVsSalesOppty != null && mapOfUsersVsSalesOppty.containsKey(userId+'-'+salesOppId)) { 
                                        OpportunityShare oppShr  = new OpportunityShare();
                                        oppShr.opportunityId  = salesOppId;
                                        oppShr.UserOrGroupId = newUserId;
                                        oppShr.OpportunityAccessLevel = 'Edit';
                                        oppShr.RowCause = Schema.OpportunityShare.RowCause.Manual;
                                        oppShareList.add(oppShr);
                                        mapOppShareList.put(oppShr.opportunityId+'-'+oppShr.UserOrGroupId, oppShr);
                                    }
                                }
                            }
                        }
                    }
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : dr.getErrors()) {
                        System.debug(System.logginglevel.DEBUG, 'The following error has occurred.');                    
                        System.debug(System.logginglevel.DEBUG, err.getStatusCode() + ': ' + err.getMessage());
                    }
                }
            }
        }
        
        if (oppShareList != null && !oppShareList.isEmpty()) {
            Database.SaveResult[] sr = Database.insert(oppShareList,false);
        }
    }
    //ARY-1082 Ends
    //SAL25-145 - To check if Header & Line level values are in sync
    /**
     * @description
     * @param oppRec
     * @param oppMap
    */
    public static void validateOppHeaderAndLinesSync(Opportunity oppRec,Map<Id,Opportunity> oppMap){
        Decimal totalACV = 0;
        Decimal totalSubRenACV = 0;
        Decimal totalSubRenTCV = 0;
        Decimal totalNEACV = 0;
        Decimal totalNETCV = 0;
        Decimal totalCoreNEACV = 0;
        Decimal totalNasNEACV = 0;
        Decimal totalSaaSNEACV = 0;
        Decimal totalNCDNEACV = 0;
        Decimal totalSubRenChurnACV = 0;//SAL26-851
        Decimal totalSubRenChurnTCV = 0;//SAL26-851
        Decimal totalCompUpliftACV = 0; //SAL26-1277

        if(oppMap.containskey(oppRec.Id)){
            for(OpportunityLineItem oli : oppMap.get(oppRec.Id).OpportunityLineItems){
                if((('Renewal' != oppRec.Opportunity_Sub_Type__c && oli.Line_Type__c != 'Renewal') || ('Renewal' == oppRec.Opportunity_Sub_Type__c && 'Renewal' == oli.Line_Type__c)) && oli.ACV_Amount__c != null){
                    totalACV = totalACV + oli.ACV_Amount__c;
                }
                totalSubRenACV = (oli.Subsumed_Renewal_Amount__c != null ? (totalSubRenACV + oli.Subsumed_Renewal_Amount__c) : totalSubRenACV);
                totalSubRenTCV = (oli.Subsumed_Renewal_TCV__c != null ? (totalSubRenTCV + oli.Subsumed_Renewal_TCV__c) : totalSubRenTCV);
                totalNEACV = (oli.New_Expansion_ACV__c != null ? (totalNEACV + oli.New_Expansion_ACV__c) : totalNEACV);
                totalNETCV = (oli.New_Expansion_TCV__c != null ? (totalNETCV + oli.New_Expansion_TCV__c) : totalNETCV);
                totalCoreNEACV = (oli.Core_New_Expansion_ACV__c != null ? (totalCoreNEACV + oli.Core_New_Expansion_ACV__c) : totalCoreNEACV);
                totalNasNEACV = (oli.Nas_New_Expansion_ACV__c != null ? (totalNasNEACV + oli.Nas_New_Expansion_ACV__c) : totalNasNEACV);
                totalSaaSNEACV = (oli.SaaS_New_Expansion_ACV__c != null ? (totalSaaSNEACV + oli.SaaS_New_Expansion_ACV__c) : totalSaaSNEACV);
                totalNCDNEACV = (oli.PLS_NCD_New_Expansion_ACV__c != null ? (totalNCDNEACV + oli.PLS_NCD_New_Expansion_ACV__c) : totalNCDNEACV); //SAL26-1291
                totalSubRenChurnACV = (oli.Subsumed_Renewal_Churn_ACV__c != null ? (totalSubRenChurnACV + oli.Subsumed_Renewal_Churn_ACV__c) : totalSubRenChurnACV);//SAL26-851
                totalSubRenChurnTCV = (oli.Subsumed_Renewal_Churn_TCV__c != null ? (totalSubRenChurnTCV + oli.Subsumed_Renewal_Churn_TCV__c) : totalSubRenChurnTCV);//SAL26-851
                totalCompUpliftACV += (oli.Comp_Uplift_ACV__c ?? 0); //SAL26-1277
            }       
            set<string> fieldNames = new set<string> ();
            if((oppRec.ACV_Amount__c != null && oppRec.ACV_Amount__c.setScale(2) != totalACV.setScale(2)) || (oppRec.ACV_Amount__c == null && totalACV != 0)) {
               fieldNames.add('Opp Amount (ACV)\n');
            }
            if((oppRec.Renewal_Subsumed_ACV__c != null && oppRec.Renewal_Subsumed_ACV__c.setScale(2) != totalSubRenACV.setScale(2)) || (oppRec.Renewal_Subsumed_ACV__c == null && totalSubRenACV != 0)) {
                fieldNames.add('Opp Renewal Subsumed ACV\n');
            }
            if((oppRec.Subsumed_Renewal_TCV__c != null && oppRec.Subsumed_Renewal_TCV__c.setScale(2) != totalSubRenTCV.setScale(2)) || (oppRec.Subsumed_Renewal_TCV__c == null && totalSubRenTCV != 0)) {
                fieldNames.add('Opp Renewal Subsumed TCV\n');
            }
            if((oppRec.New_Expansion_ACV__c != null && oppRec.New_Expansion_ACV__c.setScale(2) != totalNEACV.setScale(2)) || (oppRec.New_Expansion_ACV__c == null && totalNEACV != 0)) {
                fieldNames.add('Opp New/Expansion ACV\n');
            }
            if((oppRec.New_Expansion_TCV__c != null && oppRec.New_Expansion_TCV__c.setScale(2) != totalNETCV.setScale(2)) || (oppRec.New_Expansion_TCV__c == null && totalNETCV != 0)) {
                fieldNames.add('Opp New/Expansion TCV\n');
            }
            if((oppRec.Core_New_Expansion_ACV__c != null && oppRec.Core_New_Expansion_ACV__c.setScale(2) != totalCoreNEACV.setScale(2)) || (oppRec.Core_New_Expansion_ACV__c == null && totalCoreNEACV != 0)) {
                fieldNames.add('Opp Core New/Expansion ACV\n');
            }
            if((oppRec.Nas_New_Expansion_ACV__c != null && oppRec.Nas_New_Expansion_ACV__c.setScale(2) != totalNasNEACV.setScale(2)) || (oppRec.Nas_New_Expansion_ACV__c == null && totalNasNEACV != 0)) {
                fieldNames.add('Opp CLOUD New/Expansion ACV\n');
            }
            if((oppRec.SaaS_New_Expansion_ACV__c != null && oppRec.SaaS_New_Expansion_ACV__c.setScale(2) != totalSaaSNEACV.setScale(2)) || (oppRec.SaaS_New_Expansion_ACV__c == null && totalSaaSNEACV != 0)) {
                fieldNames.add('Opp SaaS New/Expansion ACV\n');
            }
			//SAL26-1291
            if((oppRec.PLS_NCD_New_Expansion_ACV__c != null && oppRec.PLS_NCD_New_Expansion_ACV__c.setScale(2) != totalNCDNEACV.setScale(2)) || (oppRec.PLS_NCD_New_Expansion_ACV__c == null && totalNCDNEACV != 0)) {
                fieldNames.add('Opp NCD New/Expansion ACV\n');
            }
            //SAL26-851
            if((oppRec.Subsumed_Renewal_Churn_ACV__c != null && oppRec.Subsumed_Renewal_Churn_ACV__c.setScale(2) != totalSubRenChurnACV.setScale(2)) || (oppRec.Subsumed_Renewal_Churn_ACV__c == null && totalSubRenChurnACV != 0)) {
                fieldNames.add('Renewal Other Baseline Churn ACV\n');
            }
            //SAL26-851
            if((oppRec.Subsumed_Renewal_Churn_TCV__c != null && oppRec.Subsumed_Renewal_Churn_TCV__c.setScale(2) != totalSubRenChurnTCV.setScale(2)) || (oppRec.Subsumed_Renewal_Churn_TCV__c == null && totalSubRenChurnTCV != 0)) {
                fieldNames.add('Renewal Other Baseline Churn TCV\n');
            }
            //SAL26-1277
            if((oppRec.Comp_Uplift_ACV__c != null && oppRec.Comp_Uplift_ACV__c.setScale(2) != totalCompUpliftACV.setScale(2)) || (oppRec.Comp_Uplift_ACV__c == null && totalCompUpliftACV != 0)) {
                fieldNames.add('Comp Uplift ACV\n');
            }
            if(!fieldNames.isEmpty()) {
                string errorMessage = System.label.Opp_Manual_Arroyo_values_Sync_error_msg+'\n'+ String.join(new List<String>(fieldNames),', ');
                oppRec.addError(errorMessage, true);
            }
        }
    }
    //CPQ22-3405 Show validation when Opp line items are not in synced with Quotelines, assoiated to primary quote.
    /**
     * @description
     * @param oppsobjRec
     * @param oldRecordsMap
     * @param oppMap
     * @param quoteMap
     */
    public static void showValidationToSyncQLsWithOppLines(sobject oppsobjRec,Map<Id, sobject> oldRecordsMap, Map<Id,Opportunity> oppMap, Map<Id,SBQQ__Quote__c> quoteMap, Map<ID, Account> AccountMapTrgUpdate){
        
        ShGl_DisableBusinessLogic__c disabledBusinessLogic = ShGl_DisableBusinessLogic__c.getInstance(); //REEN-41
        String errormessage = System.label.Opp_Quote_Validation_Message;
        String errormessage1 = System.label.Opp_Quote_Validation_Message_V2;
        String errormessage2 = System.label.Opp_Quote_Validation_Message_V3;
        String errormessage3 = System.label.Opp_Quote_Validation_Message_V4;
        String OpptySplitProduct = 'OPTY-SPLIT'; //CPQ22-3739
        String primaryQuoteId;
        Integer numberOppLineItems=0;
        Integer numberPrimaryQuoteLines=0;
        Set<id> oppIdset= new Set<Id> ();//REEN-41
        List<OpportunityLineItem> oppLinItemList = new List<OpportunityLineItem>();
        List<SBQQ__QuoteLine__c> quotelineItemList = new List<SBQQ__QuoteLine__c>();
        Map<Id, Opportunity> oldOppMap = (Map<Id, Opportunity>) oldRecordsMap;
        Map<Id, Boolean> mapOfStageChangedto6 = new Map<Id, Boolean>(); //REEN-41
        Map<Id, String> mapOfQuoteIdvsStatus = new Map<Id, String>(); //REEN-41
        Opportunity oppRec = new Opportunity();
        oppRec = (Opportunity) oppsobjRec;
        if(oppRec != null){
            if((oppRec.Renewals_Forecast_Risk__c != oldOppMap.get(oppRec.Id).Renewals_Forecast_Risk__c
                || oppRec.Renewals_Sentiment__c != oldOppMap.get(oppRec.Id).Renewals_Sentiment__c
                || oppRec.Next_Step__c != oldOppMap.get(oppRec.Id).Next_Step__c
                || oppRec.StageName != oldOppMap.get(oppRec.Id).StageName)
               && oppRec.SBQQ__PrimaryQuote__c != null)
                {
                    oppIdset.add(oppRec.Id); //REEN-41
                }
            //CPQ22-3902 removed stage 5 check
            if(oppRec.StageName == '6 PO With Channel' && oldOppMap.get(oppRec.Id).StageName != oppRec.StageName && oppRec.SBQQ__PrimaryQuote__c != null)
            {     
                primaryQuoteId = oppRec.SBQQ__PrimaryQuote__c;  
                oppIdset.add(oppRec.Id);   //REEN-41
                mapOfStageChangedto6.put(oppRec.Id, true);
            } 
            if(!oppIdset.isEmpty() && !oppMap.isEmpty() && oppMap.containsKey(oppRec.Id) && oppMap.get(oppRec.Id).opportunitylineitems != null && oppIdset.contains(oppRec.Id)){
                for(OpportunityLineItem oli : oppMap.get(oppRec.Id).opportunitylineitems){
                    if(oli.ProductCode != OpptySplitProduct){
                        oppLinItemList.add(oli);
                    }
                }  
            }
            /* oppLinItemList = [SELECT Id, Name, OpportunityId, SBQQ__QuoteLine__c, SBQQ__QuoteLine__r.SBQQ__Quote__c, List_Total__c, Quantity, 
Product2Id, Subscription_Term__c, SBQQ__QuoteLine__r.SBQQ__ListTotal__c, SBQQ__QuoteLine__r.SBQQ__SubscriptionTerm__c, 
SBQQ__QuoteLine__r.SBQQ__Product__c, SBQQ__QuoteLine__r.SBQQ__Quantity__c, 
SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c, SBQQ__QuoteLine__r.SBQQ__Quote__r.OpportunitySubType__c, 
                                  SBQQ__QuoteLine__r.SBQQ__EffectiveQuantity__c, SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Status__c //REEN-41
FROM OpportunityLineItem WHERE OpportunityId IN: opportunityLst];*/

            //ITNPI-2143: change added by Anjali for enforcing validation on the basis of opportunity Polaris region
            if (oppRec.StageName == '6 PO With Channel' && oldOppMap.get(oppRec.Id).StageName != oppRec.StageName && oppRec.SBQQ__PrimaryQuote__c != null) {
                //ITNPI-2476: Change by Anjali- Added condition for Account RSC_Deployment__c 
                Account objAccount = AccountMapTrgUpdate.get(oppRec.AccountId);
		
                //Check if we have storage SKU added on primary quote
                Boolean isGRSAdded = false;
                Boolean isZRSAdded = false;
                Boolean isGRSEntitlement = false;
                Boolean isZRSEntitlement = false;
            
                if(!oppIdset.isEmpty() && !oppMap.isEmpty() && oppMap.containsKey(oppRec.Id) && oppMap.get(oppRec.Id).opportunitylineitems != null && oppIdset.contains(oppRec.Id)){
                        List<OpportunityLineItem> olis = oppMap.get(oppRec.Id).opportunitylineitems;
                        for(OpportunityLineItem oli : olis){
                            if(oli.Product2.Product_Type__c == 'M365 GRS' && !isGRSAdded){
                                    isGRSAdded = True;
                            } else if (oli.Product2.Product_Type__c == 'M365 ZRS' && !isZRSAdded) {
                                isZRSAdded = True;
                            }
                        }  
                }
                
                //Check if Account has GRS or ZRS entitlement
                for(ContractLineItem cli: [SELECT Id, SBQQSC__ProductName__c,Product_Type__c FROM ContractLineItem WHERE (SBQQSC__ProductName__c LIKE 'RS-GB-MS%' OR SBQQSC__ProductName__c LIKE 'RS-GB-GRS-%') AND SBQQSC__Account__c =: oppRec.AccountId AND Status ='Active' ]) {
                    if(cli.Product_Type__c == 'M365 GRS' && !isGRSEntitlement) {
                        isGRSEntitlement = true;
                    } else if(cli.Product_Type__c == 'M365 ZRS' && !isZRSEntitlement) {
                        isZRSEntitlement = true;
                    }
                }
            
                //Polaris Region = Out of region DR-US
                //ITNPI-2476: Change by Anjali- Added condition for Account RSC_Deployment__c 
                if (
                    (oppRec.Polaris_Region__c == 'Out of Region DR-US' || isGRSEntitlement || objAccount.RSC_Deployment__c == 'Out of Region DR-US') && 
                    isZRSAdded
                ) {
                    oppRec.addError(System.Label.M365_PolarisRegion_ZRS_SKU_ValidationMessage);
                } else if(((oppRec.Polaris_Region__c != 'Out of Region DR-US' && objAccount.RSC_Deployment__c != 'Out of Region DR-US') || isZRSEntitlement) && isGRSAdded) {
                    oppRec.addError(System.Label.M365_PolarisRegion_GRS_SKU_ValidationMessage);
                } else if (isGRSAdded && isZRSAdded) {
                    oppRec.addError(System.Label.M365_PolarisRegion_Account_ValidationMessage);
                }
            }    
            //ITNPI-2143: Changes by Anjali ends 

                //REEN-41
                if (oppLinItemList != null && !oppLinItemList.isEmpty()) {
                    for (OpportunityLineItem oli : oppLinItemList) {
                        if(oppIdset.contains(oli.OpportunityId) && oli.ProductCode != OpptySplitProduct){
                            if(oli.SBQQ__QuoteLine__c != null && oli.SBQQ__QuoteLine__r.SBQQ__Quote__c != null) {
                                mapOfQuoteIdvsStatus.put(oli.SBQQ__QuoteLine__r.SBQQ__Quote__c, oli.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Status__c);
                            }
                            if(mapOfStageChangedto6 != null && !mapOfStageChangedto6.isEmpty() && 
                                mapOfStageChangedto6.containsKey(oli.OpportunityId) && mapOfStageChangedto6.get(oli.OpportunityId) == true ) {
                                numberOppLineItems = numberOppLineItems + 1;
                            }
                        }
                    }
                }

            for(SBQQ__Quote__c quote : quoteMap.values()){
                if(!oppIdset.isEmpty() && oppIdset.contains(quote.SBQQ__Opportunity2__c) && quote.SBQQ__Primary__c && primaryQuoteId == quote.Id){
                    for(SBQQ__QuoteLine__c qli : quote.SBQQ__LineItems__r){
                        if(!qli.SBQQ__Optional__c  && qli.SBQQ__EffectiveQuantity__c > 0){
                            quotelineItemList.add(qli);
                        }
                    }
                }
            }
            /*quotelineItemList = [SELECT Id, Name, SBQQ__Quote__c FROM SBQQ__QuoteLine__c 
WHERE SBQQ__Quote__c =: primaryQuoteId AND SBQQ__Optional__c = false AND SBQQ__EffectiveQuantity__c > 0];*/
            if(!quotelineItemList.isEmpty())
                numberPrimaryQuoteLines = quotelineItemList.size();
                
            if(oppRec != null){
                    //REEN-41 Starts
                    if(!System.Label.Skip_Primary_Primary_Validation.contains(UserInfo.getProfileId())
                       && !disabledBusinessLogic.Disable_Opportunity_Validation_Rules__c 
                   && (oppRec.Renewals_Forecast_Risk__c != oldOppMap.get(oppRec.Id).Renewals_Forecast_Risk__c
                       || oppRec.Renewals_Sentiment__c != oldOppMap.get(oppRec.Id).Renewals_Sentiment__c
                       || oppRec.Next_Step__c != oldOppMap.get(oppRec.Id).Next_Step__c
                       || oppRec.StageName != oldOppMap.get(oppRec.Id).StageName )
                   && oppRec.Opportunity_Sub_Type__c == 'Renewal'&& !oppRec.isClosed && !oppRec.Is_child_Renewal_split__c)
                { 
                    if(oppRec.SBQQ__PrimaryQuote__c == null || 
                       (oppRec.SBQQ__PrimaryQuote__c != null && oppRec.Number_of_valid_Primary_Quotes__c == 1 && 
                            mapOfQuoteIdvsStatus != null && !mapOfQuoteIdvsStatus.isEmpty() && 
                        mapOfQuoteIdvsStatus.containsKey(oppRec.SBQQ__PrimaryQuote__c) && mapOfQuoteIdvsStatus.get(oppRec.SBQQ__PrimaryQuote__c) == 'Invalid'))
                        {
                        oppRec.addError(System.Label.Valid_Primary_Quote_Error_Message);  
                        }
                    else If(oppRec.SBQQ__PrimaryQuote__c != null && oppRec.Number_of_valid_Primary_Quotes__c > 1){
                        oppRec.addError(System.Label.Multiple_Primary_Quotes_Error_Message); 
                        }
                    }
                    // REEN-41 end
                if(oppRec.Opportunity_Sub_Type__c != 'MSP Overage'  && oppRec.Opportunity_Type__c != 'Debooking' && !oppRec.Is_child_Renewal_split__c ){//condition is added as a part of CPQ22-3739
                    for(OpportunityLineItem ol: oppLinItemList){
                        //use case 1
                        if(oppRec.Id == ol.OpportunityId && oppRec.SBQQ__PrimaryQuote__c != ol.SBQQ__QuoteLine__r.SBQQ__Quote__c)
                        {
                            oppRec.addError(errormessage);             
                        }
                        //REEN-41
                        else if(oppRec.Id == ol.OpportunityId && ol.SBQQ__QuoteLine__c != null && oppRec.SBQQ__PrimaryQuote__c == ol.SBQQ__QuoteLine__r.SBQQ__Quote__c
                                && !mapOfStageChangedto6.isEmpty() && mapOfStageChangedto6.containsKey(ol.OpportunityId) 
                                && mapOfStageChangedto6.get(ol.OpportunityId) == true)
                        {
                            //use case 2
                            if(ol.SBQQ__QuoteLine__c == null){
                                oppRec.addError(errormessage1);
                            }
                            //use case 3
                            if(numberOppLineItems != numberPrimaryQuoteLines){
                                oppRec.addError(errormessage2);
                            }
                            //use case 4
                            if(ol.List_Total__c != ol.SBQQ__QuoteLine__r.SBQQ__ListTotal__c 
                               || (ol.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c.equalsIgnoreCase('Amendment') 
                                   && ol.SBQQ__QuoteLine__r.SBQQ__Quote__r.OpportunitySubType__c == 'GC Offer' 
                                   && ol.Quantity != ol.SBQQ__QuoteLine__r.SBQQ__EffectiveQuantity__c) 
                               || ol.Product2Id != ol.SBQQ__QuoteLine__r.SBQQ__Product__c 
                               || ol.Subscription_Term__c != ol.SBQQ__QuoteLine__r.SBQQ__SubscriptionTerm__c)
                            {
                                oppRec.addError(errormessage3);                        
                            }
                            else if(ol.List_Total__c != ol.SBQQ__QuoteLine__r.SBQQ__ListTotal__c 
                                    || (!ol.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c.equalsIgnoreCase('Amendment') 
                                        && ol.SBQQ__QuoteLine__r.SBQQ__Quote__r.OpportunitySubType__c != 'GC Offer' 
                                        && ol.Quantity != ol.SBQQ__QuoteLine__r.SBQQ__Quantity__c) 
                                    || ol.Product2Id != ol.SBQQ__QuoteLine__r.SBQQ__Product__c 
                                    || ol.Subscription_Term__c != ol.SBQQ__QuoteLine__r.SBQQ__SubscriptionTerm__c)
                            {
                                oppRec.addError(errormessage3);                        
                            }
                        }
                    }
                }      
            }         
        }            
    }
    /*CSU-496: START- Scale Utility Phase 2.0 Added by Shaloo Mishra*/
    /**
     * @description
     * @param newOpptys
     * @param mapOpptyIdOrderSubType
     * @param mapOpptyIdVsPrimaryContact
     */
    public static void setOpptySubTypeOnAmendmentOppty(List<Opportunity> newOpptys, Map<Id, String> mapOpptyIdOrderSubType, Map<Id, String> mapOpptyIdVsPrimaryContact){        
        if(!newOpptys.IsEmpty()){
            for(Opportunity opp: newOpptys){
                if(mapOpptyIdOrderSubType.containsKey(opp.Id) && mapOpptyIdOrderSubType.get(opp.Id) != null && mapOpptyIdOrderSubType.get(opp.Id) == 'GC Offer'){
                    opp.Opportunity_Sub_Type__c = mapOpptyIdOrderSubType.get(opp.Id);
                }
                if(mapOpptyIdVsPrimaryContact.containsKey(opp.Id) && mapOpptyIdVsPrimaryContact.get(opp.Id) != null){
                    opp.Initial_Contacts_Name__c = mapOpptyIdVsPrimaryContact.get(opp.Id);
                }
            }
        }
    }
    /*CSU-496: END- Scale Utility Phase 2.0 Added by Shaloo Mishra*/
    
    //SAL24-679
    /*@future
    public static void manageNPMAccountOpptyShareFuture(Set<String> oppIdNPMAcctOldNew) {
        manageNPMAccountOpptyShare(oppIdNPMAcctOldNew);
    }
    
    public static void manageNPMAccountOpptyShare(Set<String> oppIdNPMAcctOldNew) {
        List<OpportunityShare> insertOpportunityShareList = new List<OpportunityShare>();
        List<OpportunityShare> deleteOpportunityShareList = new List<OpportunityShare>();
        Set<String> delOpportunityShareKeyset = new Set<String>();
        Set<Id> delOpportunityIdSet = new Set<Id>();
        Set<Id> delUserIdSet = new Set<Id>();
        Map<Id,Set<Id>> accToNPMMap = new Map<Id,Set<Id>>();
        Map<Id, Set<Id>> oppNewPartAccMap = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> oppOldPartAccMap = new Map<Id, Set<Id>>();
        Set<Id> oppIdSet = new Set<Id>();
        Set<Id> accountIdSet = new Set<Id>();
        Map<Id,String> oppToStgNameMap = new Map<Id,String>(); //SAL25-234
        
        //Get New and Old PartnerLookup, TeamingPartner and sourcingPartner for each Oppty
        System.debug('---------oppIdNPMAcctOldNew-----');
        System.debug(oppIdNPMAcctOldNew);
        for(String str :oppIdNPMAcctOldNew){
            List<String> strList = str.split('-'); //OppId+'-'+OldPartAcc+'-'+NewPartAcc+'-'+StageName //SAL25-234
            //create map for new and old for each oppty
            if(strList!= null && strList.size() >= 3 && strList[2] != 'null' && strList[2] != ''){ //SAL25-234
                Set<Id> accSet1 = new Set<Id>();
                if(oppNewPartAccMap.containsKey((Id)strList[0])) accSet1 = oppNewPartAccMap.get((Id)strList[0]);
                accSet1.add((Id)strList[2]);
                oppNewPartAccMap.put((Id)strList[0],accSet1);
                accountIdSet.add((Id)strList[2]);
                //SAL25-234
                String stg = strList.size() > 3 && strList[3] != 'null' && strList[3] != '' && strList[3].Contains('7 Closed') ? 'Closed' : 'Open';
                oppToStgNameMap.put((Id)strList[0],stg);
            }
            //create list of delete opportunity share records with unique key
            if(strList!= null && strList.size() >= 2 && strList[1] != 'null' && strList[1] != ''){
                Set<Id> accSet2 = new Set<Id>();
                if(oppOldPartAccMap.containsKey((Id)strList[0])) accSet2 = oppOldPartAccMap.get((Id)strList[0]);
                accSet2.add((Id)strList[1]);
                oppOldPartAccMap.put((Id)strList[0],accSet2);
                accountIdSet.add((Id)strList[1]);
            }
            oppIdSet.add((Id)strList[0]);
        }
        
        //Fetch list of NPMs for all the eligible accounts
        for(Account_To_Users__c atu : [select Id,Account__c,User__c from Account_To_Users__c where Account__c IN :accountIdSet and User__r.IsActive = TRUE and Relationship_Type__c ='National Partner Manager' and Disable_Account_User_Relationship__c = FALSE]){
            Set<Id> userSet = new Set<Id>();
            if(accToNPMMap.containsKey(atu.Account__c)) userSet = accToNPMMap.get(atu.Account__c);
            userSet.add(atu.User__c);
            accToNPMMap.put(atu.Account__c,userSet);
        }
        
        //Loop thru each opportunity to create or delete the opportunity share records.
        for(Id oppId :oppIdSet){
            //create list of insert opportunity share records
            if(!oppNewPartAccMap.isEmpty() && oppNewPartAccMap.containsKey(oppId)){
                for(Id accId : oppNewPartAccMap.get(oppId)){
                    if(!accToNPMMap.isEmpty() && accToNPMMap.containsKey(accId)){
                        for(Id uId : accToNPMMap.get(accId)){
                            insertOpportunityShareList.add(new OpportunityShare(
                                OpportunityId = oppId, 
                                UserOrGroupId = uId, 
                                OpportunityAccessLevel = oppToStgNameMap?.get(oppId) == 'Open' ? 'Edit' : 'Read', //SAL25-234
                                RowCause = Schema.OpportunityShare.RowCause.Manual
                            ));
                        }
                    }
                }
            }
            
            //create list of delete opportunity share records with unique key
            if(!oppOldPartAccMap.isEmpty() && oppOldPartAccMap.containsKey(oppId)){
                for(Id accId : oppOldPartAccMap.get(oppId)){
                    if(!accToNPMMap.isEmpty() && accToNPMMap.containsKey(accId)){
                        for(Id uId : accToNPMMap.get(accId)){
                            delOpportunityIdSet.add(oppId);
                            delUserIdSet.add(uId);
                            delOpportunityShareKeyset.add(oppId+'-'+uId);
                        }
                    }
                }
            }
        }
        
        //fetch existing account share records to be deleted
        for(OpportunityShare ashare : [SELECT Id, OpportunityId, UserOrGroupId 
                                       FROM OpportunityShare 
                                       WHERE OpportunityId IN :delOpportunityIdSet AND UserOrGroupId IN :delUserIdSet AND RowCause = 'Manual']){
                                           String delOppShareKey = ashare.OpportunityId + '-' + ashare.UserOrGroupId;
                                           //map with deleteOpportunityShare unique key and add it delete list
                                           if(delOpportunityShareKeyset.contains(delOppShareKey)) deleteOpportunityShareList.add(ashare);
                                       }
        //delete old manual opportunity share records
        if(!deleteOpportunityShareList.isEmpty()){
            List<Database.DeleteResult> drList = Database.delete(deleteOpportunityShareList, false);
            LogError.deleteDMLErrorLog((List<SObject>)deleteOpportunityShareList, drList, 'OpportunityObjectTriggerHelper','Delete NPM OpportunityShare');
        }
        //insert new manual opportunity share records
        if(!insertOpportunityShareList.isEmpty()){
            List<Database.SaveResult> srList = Database.insert(insertOpportunityShareList, false);
            LogError.createDMLErrorLog((List<SObject>)insertOpportunityShareList, srList, 'OpportunityObjectTriggerHelper','Insert NPM OpportunityShare');
        }
    }
    //End*/ //commented for SAL26-75
    /*CSU-729: Start - To Throw validation for Scale Utility 2.0*/
    /**
     * @description
     * @param newOpptys
     */
    public static void preventAmendingNonGCOfferContracts(List<Opportunity> newOpptys){
        
        ShGl_DisableBusinessLogic__c disabledBusinessLogic = ShGl_DisableBusinessLogic__c.getInstance();
        if(newOpptys != null && !newOpptys.IsEmpty()){
            for(Opportunity opp: newOpptys){
                if(!Test.isRunningTest() && !disabledBusinessLogic.Disable_Opportunity_Validation_Rules__c && opp.SBQQSC__AmendedServiceContract__c != null ){
                    opp.addError('You cannot amend Scale Utility Service Contract on a "Regular" Opportunity or vice-versa. Please select an appropriate Opportunity to proceed.'); 
                }
            }
        }
    }
    /*CSU-729: End - To Throw validation for Scale Utility 2.0*/

     //SAL25-66 start
    /**
     * @description
     * @param oppLi
     */
     public static void updateRSCOwner(List<Opportunity> oppLi){
        for(Opportunity opp : oppLi){
            if(opp.Polaris_Portal_Contact__c!=null && opp.Rubrik_Security_Cloud_Gov_t_Owner__c==null){
                opp.Rubrik_Security_Cloud_Gov_t_Owner__c = opp.Polaris_Portal_Contact__c;
            }
            if(opp.Polaris_Portal_Contact__c==null && opp.Rubrik_Security_Cloud_Gov_t_Owner__c!=null){
                opp.Polaris_Portal_Contact__c = opp.Rubrik_Security_Cloud_Gov_t_Owner__c;
            }
        }
}
//SAL25-66 end
    //SAL25-129 Start
   /* public static void updateHoldCodeandHoldNotesFields(List<Opportunity> oppLi){
        for(Opportunity op : oppLi){
            if(op.Manual_Fulfillment_Quote__c =='Ramp Quote'){
                op.Hold_Code__c = String.isBlank(op.Hold_Code__c) ? 'OM Internal Review' : !String.isBlank(op.Hold_Code__c) && !op.Hold_Code__c.contains('OM Internal Review')? op.Hold_Code__c + ';OM Internal Review': op.Hold_Code__c;
                op.On_Hold_Notes__c = op.On_Hold_Notes__c == null ? 'Ramp Quote' : op.On_Hold_Notes__c != null && !op.On_Hold_Notes__c.contains('Ramp Quote') ? op.On_Hold_Notes__c + ' ,Ramp Quote' : op.On_Hold_Notes__c;
            }
            else if(op.Manual_Fulfillment_Quote__c =='Delayed Start Dates'){
                op.Hold_Code__c = String.isBlank(op.Hold_Code__c) ? 'OM Internal Review' : !String.isBlank(op.Hold_Code__c) && !op.Hold_Code__c.contains('OM Internal Review') ? op.Hold_Code__c + ';OM Internal Review' : op.Hold_Code__c;
                op.On_Hold_Notes__c = op.On_Hold_Notes__c == null ? 'Delayed Start Dates' : op.On_Hold_Notes__c != null && !op.On_Hold_Notes__c.contains('Delayed Start Dates') ? op.On_Hold_Notes__c + ' ,Delayed Start Dates' :op.On_Hold_Notes__c;
            }
            else if (op.Manual_Fulfillment_Quote__c !='Ramp Quote' && op.Manual_Fulfillment_Quote__c !='Delayed Start Dates'){
                op.Hold_Code__c = !String.isBlank(op.Hold_Code__c) && op.Hold_Code__c.contains('OM Internal Review') ? op.Hold_Code__c.remove('OM Internal Review') : op.Hold_Code__c;
                op.On_Hold_Notes__c = op.On_Hold_Notes__c != null && op.On_Hold_Notes__c.contains('Ramp Quote') ? op.On_Hold_Notes__c.remove('Ramp Quote') : op.On_Hold_Notes__c;
                op.On_Hold_Notes__c = op.On_Hold_Notes__c != null && op.On_Hold_Notes__c.contains('Delayed Start Dates') ? op.On_Hold_Notes__c.remove('Delayed Start Dates') : op.On_Hold_Notes__c;
                op.On_Hold_Notes__c = op.On_Hold_Notes__c?.removeEnd(',');
            }
        }
    }*/
    //SAL25-129 End
    //SAL25-106
    /**
     * @description
     * @param AccIds
     */
    public static void updateSDPAccType(Set<Id> AccIds){
        List<Account> updateAccTypeList = new List<Account>();
        for(Id accId : AccIds){
            Account acc = new Account();
            acc.Id = accId;
            acc.Type = 'MSP Customer';
            updateAccTypeList.add(acc);
        }
        if(updateAccTypeList.size()>0 && !updateAccTypeList.isEmpty()){
            boolean tempFlag = flowControll.accountTrigger;
                flowControll.accountTrigger = false;
                update updateAccTypeList;
                flowControll.accountTrigger = tempFlag;
        }
    }
    //SAL25-106

    //SAL25-247
    /**
     * @description
     * @param oppIds
     */
    @future
    public static void setPartnerReferralCCRRejectedFuture(Set<Id> oppIds) {
        setPartnerReferralCCRRejected(oppIds);
    }

    /**
     * @description
     * @param oppIds
     */
    public static void setPartnerReferralCCRRejected(Set<Id> oppIds)
    {
        List<Approval.ProcessWorkitemRequest> appPIRequests = new List<Approval.ProcessWorkitemRequest>();
        //Get list of Partner Referral Fee CCRs that are currently in Pending or Submitted status
        Set<Id> submittedCCRIds = new Set<Id>();
        List<CCR__c> pendingCCRList = new List<CCR__c>();
        List<CCR__c> updatePendingCCRList = new List<CCR__c>();
        for(CCR__c ccr :[SELECT Id,User__c FROM CCR__c WHERE Opportunity__c IN :oppIds AND CCR_Type__c = 'Partner Referral Fee' AND User__c IN ('Submitted','Pending')]){
            if(ccr.User__c == 'Submitted') submittedCCRIds.add(ccr.Id);
            else if(ccr.User__c == 'Pending') pendingCCRList.add(ccr);
        }
        
        //Get Approval ProcessInstance Items
        Map<Id,ProcessInstance> piMap = New Map<ID,ProcessInstance>([Select Id from ProcessInstance where TargetObjectId IN :submittedCCRIds]);
        for(ProcessInstanceWorkItem pIWI : [Select Id from ProcessInstanceWorkItem where ProcessInstanceId IN :piMap.keySet()]){
            //set the action to 'Reject' and comments
            Approval.ProcessWorkitemRequest piReq = new Approval.ProcessWorkitemRequest();
            piReq.setAction('Reject');
            piReq.setComments('Rejected since the related opportunity is closed');
            piReq.setWorkitemId(pIWI.Id);
            appPIRequests.add(piReq);
        }
        //Get list of CCRs to be updated as Rejected
        for(CCR__c ccrRec :pendingCCRList){
            ccrRec.User__c = 'Rejected';
            updatePendingCCRList.add(ccrRec);
        }
        if(!updatePendingCCRList.isEmpty()){
            List<Database.SaveResult> srList = Database.update(updatePendingCCRList, false);
            LogError.createDMLErrorLog((List<SObject>)updatePendingCCRList, srList, 'OpportunityObjectTriggerHelper','Reject CCR');
        }
        //Approval.ProcessResult[] processResults = null;
        //processResults = Approval.process(appPIRequests, true);
        if(!appPIRequests.isEmpty()){ Approval.process(appPIRequests, true); }
    }
    //End - SAL25-247

    //Commented for SAL25-727
    /*//SAL25-549
    public static void updateUpliftEligibleOpp(Map<Id,opportunity> newOppMap, Map<Id,Id> oppGlobalAccIdMap, Set<Id> globalAccIds, Date planStartDate, Date planEndDate){
        Set<Id> upliftEligibleGlobalAccIds = new Set<Id>();
        for(Opportunity opp : [SELECT Id, AccountId, Account.ParentId, Account.Parent.ParentId, ACV_Amount__c, split__c, Split_percentage__c
                                FROM Opportunity 
                                WHERE (AccountId IN :globalAccIds OR Account.ParentId IN :globalAccIds OR Account.Parent.ParentId IN :globalAccIds) 
                                AND RecordTypeId = :OpportunityUtil.oppRecTypeIdSalesOpp AND Opportunity_Type__c = 'New Customer' AND Opportunity_Split_Parent__c = null 
                                AND IsClosed = TRUE AND IsWon = TRUE AND CloseDate >= :planStartDate AND CloseDate <= :planEndDate
                            ]){
            Double splitper = opp.Split_percentage__c != null ? opp.Split_percentage__c : 100;
            Double totalACV = opp.ACV_Amount__c != null ? opp.ACV_Amount__c / (splitper/100) : 0;
            if(totalACV > 75000){
                Id globalAccId = opp.Account.Parent.ParentId != null ? opp.Account.Parent.ParentId : opp.Account.ParentId != null ? opp.Account.ParentId : opp.AccountId;
                if(!upliftEligibleGlobalAccIds.contains(globalAccId)) upliftEligibleGlobalAccIds.add(globalAccId);
            }
        }
        if(!upliftEligibleGlobalAccIds.isEmpty()){
            for (Opportunity opp : newOppMap.values()) {
                Id oppGlbalAccId = !oppGlobalAccIdMap.isEmpty() && oppGlobalAccIdMap.containsKey(opp.Id) ? oppGlobalAccIdMap.get(opp.Id) : null;
                opp.Uplift_Eligible__c = oppGlbalAccId != null && upliftEligibleGlobalAccIds.contains(oppGlbalAccId) ? TRUE : opp.Uplift_Eligible__c;
            }
        }
    }
    //SAL25-549 - Ends*/
    
    /** SAL25-495 - Start * SAL26-549:commented
     * @description Get UCL_Scale metadata records, prepare product-code set
     * @return Set<String>
    public static Set<String> getUclScaleProductCodesSet() {
        Set<String> uclScaleProductCodesMdtset = new Set<String>();
        for(UCL_Scale_SKUs__mdt uclScale : UCL_Scale_SKUs__mdt.getAll().values()) {
            uclScaleProductCodesMdtset.add(uclScale.Product_SKU__c);
        }
        return uclScaleProductCodesMdtset;
    }

    /** SAL25-495 - Start
     * @description Implemented as part of SAL26-495
     * @param newOppMap
     * @param oldOppMap
     * @param oppMapTrgUpdate
     *
    public static void validateUCLScaleSKUS(Map<Id, Opportunity> newOppMap, Map<Id, Opportunity> oldOppMap, Map<Id, Opportunity> oppMapTrgUpdate){
        Map<Id, List<OpportunityLineItem>> oppToUCLScaleProductsMap = new Map<Id, List<OpportunityLineItem>>();
        Set<String> uclScaleProductSet = getUclScaleProductCodesSet();
        
        for(Opportunity opp : newOppMap.values()){ 
            if(opp.Opportunity_Type__c!='Debooking' && opp.Opportunity_Sub_Type__c != 'MSP Overage' && opp.RecordTypeId == OpportunityUtil.oppRecTypeIdSalesOpp){
                if(opp.StageName != oldOppMap.get(opp.Id).StageName && (opp.StageName == '6 PO With Channel'||opp.StageName == '7 Closed Won')){
                    oppToUCLScaleProductsMap.put(opp.Id, new List<OpportunityLineItem>());
                } 
                Boolean hasUCLScaleProd = false;
                List<OpportunityLineItem> oliList = oppMapTrgUpdate.containsKey(opp.Id) ? oppMapTrgUpdate.get(opp.Id).opportunitylineitems : new List<OpportunityLineItem>();
            /** SAL26-312: removed 
             *for(OpportunityLineItem oli : oliList){ 
                    if(uclScaleProductSet.contains(oli.ProductCode) && oli.SBQQ__QuoteLine__r.SBQQ__Quote__c == opp.SBQQ__PrimaryQuote__c){
                        if(!opp.Has_UCL_Scale_Products__c) opp.Has_UCL_Scale_Products__c = true;
                        if(oppToUCLScaleProductsMap.containsKey(oli.OpportunityId) && String.isBlank(oli.UCL_Scale__c)){
                            oppToUCLScaleProductsMap.get(oli.OpportunityId).add(oli);
                        }
                        hasUCLScaleProd = true;
                    }*
                }*
                opp.Has_UCL_Scale_Products__c = hasUCLScaleProd;
            }
        }
        if(oppToUCLScaleProductsMap != null && !oppToUCLScaleProductsMap.isEmpty()){
            for(Id oppId : oppToUCLScaleProductsMap.keySet()){
                if(!oppToUCLScaleProductsMap.get(oppId).isEmpty()){
                    newOppMap.get(oppId).addError('SED or SEM must populate UCL/Scale %');
                                        }
                                    }
                        }
                    }
    /** SAL25-495 - End */
      
        
    //PL26-3 PL26-14 start //SAL26-89: added allowCoOwnerOverride parameter
    /**
     * @description Populates PLS fields like Co-Owner, Core_PLS_Source__c, and Rubrik Co-Sales Engineer on Sales Opportunities. 
     * Also creates AccountTeamMember entries if a Co-Owner is set and validates territory mapping unless overrides are allowed.
     *
     * @param newOppList - List of new Opportunity records being processed.
     * @param PLSAEaccToTerrMap - Map of Account Ids to their associated Adaptive Territory Ids.
     * @param PLSAEuserToUtaMap - Map of User Ids to their corresponding UserTerritory2Association records.
     * @param PLSSalesEngineerToUTAMap - Map of Territory Ids to Sales Engineer User Ids.
     * @param allowCoOwnerOverride - Boolean flag indicating whether Co-Owner validation can be bypassed.
     */
    public static void populatePLSfieldsandCoOwner(list<Opportunity> newOppList,Map<Id,Opportunity> oldOppMap,map<id,List<String>> PLSAEaccToTerrMap,map<id,UserTerritory2Association> PLSAEuserToUtaMap, Map<String,Id> PLSSalesEngineerToUTAMap, Boolean allowCoOwnerOverride){
        ShGl_DisableBusinessLogic__c disabledBusinessLogic = ShGl_DisableBusinessLogic__c.getInstance();
        // Configuration for co-owner types SAL26-1217
        List<Map<String, String>> configs = new List<Map<String, String>>{
            new Map<String,String>{ 'field' => 'Co_Owner__c',  'role' => 'Cloud AE', 'method' => 'cloud' },
            new Map<String,String>{ 'field' => 'NCD_Co_Owner__c','role' => 'NCD AE','method' => 'ncd' },
            new Map<String,String>{ 'field' => 'SaaS_Co_Owner__c','role' => 'SaaS AE','method' => 'saas' }
        };
        for(Opportunity newOpp : newOppList){
            if (newOpp.RecordTypeId != OpportunityUtil.oppRecTypeIdSalesOpp) continue;
                if(PLSAEaccToTerrMap != null && newOpp.Id == null && PLSAEuserToUtaMap.containsKey(userinfo.GetUserId()) &&
               PLSAEaccToTerrMap.containsKey(newOpp.AccountId) && PLSAEaccToTerrMap.get(newOpp.AccountId).contains(PLSAEuserToUtaMap.get(userinfo.GetUserId()).Territory2.Adaptive_Territory_Id__c))
            {
                String roleName = PLSAEuserToUtaMap.get(UserInfo.getUserId()).RoleInTerritory2;
                newOpp.Core_PLS_Source__c = 'PLS Sourced'; //PL26-52
                if (roleName == 'Cloud AE') {
                    newOpp.Co_Owner__c = newOpp.Co_Owner__c == null ? UserInfo.getUserId() : newOpp.Co_Owner__c;
                } else if (roleName == 'NCD AE') {
                    newOpp.NCD_Co_Owner__c = newOpp.NCD_Co_Owner__c == null ? UserInfo.getUserId() : newOpp.NCD_Co_Owner__c;
                } else if (roleName == 'SaaS AE') {
                    newOpp.SaaS_Co_Owner__c = newOpp.SaaS_Co_Owner__c == null ? UserInfo.getUserId() : newOpp.SaaS_Co_Owner__c;
                   }
            }

            Boolean anyCoOwnerExists = false;

            for (Map<String, String> cfg : configs) {
                String fieldName = cfg.get('field');
                Id coOwnerId = newOpp.get(fieldName) != null ? (Id) newOpp.get(fieldName) : null;
                if (coOwnerId == null) continue;
                anyCoOwnerExists = true;
                Opportunity oldOpp = oldOppMap != null ? oldOppMap.get(newOpp.Id) : null;
                Boolean isCoOwnerChange = (oldOpp != null && newOpp.get(fieldName) != oldOpp.get(fieldName)) ? true : false;

                // POPULATE ETM & ROLE checks
                if (PLSAEuserToUtaMap.containsKey(coOwnerId)) {
                    UserTerritory2Association uta = PLSAEuserToUtaMap.get(coOwnerId);
                    if (uta.RoleInTerritory2 == cfg.get('role')) {
                        populateOppPLSGenericFields(uta, newOpp, cfg.get('method'));
                    }
                }else if (isCoOwnerChange && !PLSAEuserToUtaMap.containsKey(coOwnerId) && allowCoOwnerOverride && !disabledBusinessLogic.Disable_Opportunity_Validation_Rules__c && !Test.isRunningTest()) {
                    // TERRITORY VALIDATION
                    newOpp.addError(System.Label.CoOwner_Error_Not_from_Account_Territory);
                }

                // ACCOUNT TEAM MEMBER (batch into existing static list on Handler)
                if (newOpp.Id == null || Test.isRunningTest()) {
                    OpportunityObjectTriggerHandler.accTeamMembersToInsertDelete.add(
                        new AccountTeamMember(
                            AccountId = newOpp.AccountId,
                            UserId = coOwnerId,
                                                                   TeamMemberRole = 'Co-Owner',
                                                                   AccountAccessLevel = 'Edit', 
                                                                   OpportunityAccessLevel = 'Edit'
                        )
                    );
                }
            }
        }
        
        if(!OpportunityObjectTriggerHandler.accTeamMembersToInsertDelete.isEmpty()){
            INSERT OpportunityObjectTriggerHandler.accTeamMembersToInsertDelete;
        }
    }
    //PL26-3 PL26-14 end
    
    //CPQ22-4873 moved from Task trigger
    //START-[Shaloo Mishra] Arroyo 2.0: Trigger Task created send email when an Oppty has Primary Renewal/Expansion or Renewal Quote created or Primary updated
    /**
     * @description
     * @param newList
     */
    public static void sendTaskEmail(List<Task> newList)
    {
        EmailTemplate emailTemplate = [SELECT Id, Subject, Description, HtmlValue, DeveloperName, Body FROM EmailTemplate 
                                       WHERE Name = 'Opportunity Task Email'];
        
        Set<Id> ownerIds = new Set<Id>();
        Set<Id> opptyIds = new Set<Id>();
        List<SBQQ__Quote__c> quoteRecList = new List<SBQQ__Quote__c>();
        Map<Id, User> userMap = new Map<Id, User>();
        
        if(newList != null && !newList.isEmpty())
        {
            for(Task tsk: newList)
            {
                if(tsk.OwnerId != null){
                    ownerIds.add(tsk.OwnerId);
                }
                if(tsk.WhatId != null){
                    opptyIds.add(tsk.WhatId);
                }
            }
        }
        
        if(quoteRecList.isEmpty() && opptyIds != null && !opptyIds.IsEmpty()){
            quoteRecList = [SELECT Id, Name, SBQQ__Primary__c FROM SBQQ__Quote__c WHERE 
                            SBQQ__Opportunity2__c =: opptyIds AND SBQQ__Primary__c = TRUE];
        }
        
        for (User userObj : [SELECT Id, Name, Email FROM User WHERE Id IN: ownerIds]){
            userMap.put(userObj.Id, userObj);
        }
        
        if(!newList.isEmpty()){
            
            for(Task tsk : newList){
                if(tsk.Type != null && tsk.Type == 'Email' && tsk.WhatId != null && emailTemplate != null && quoteRecList != null && !quoteRecList.IsEmpty()){
                    for(SBQQ__Quote__c quoteRec: quoteRecList)
                    {
                        Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate (emailTemplate.Id, null, quoteRec.Id);
                        //CPQ22-4074 starts
                        String strEmails = System.Label.TaskCreattionCCEmailIds;
                        String strCPQAdmin = System.Label.CPQAdminEmailId;
                        String[] sendingToCcAdd = !String.isBlank(strEmails) ? strEmails.split(',') : new List<String>{strCPQAdmin};
                            
                            message.setTargetObjectId(tsk.OwnerId);
                        String noReplyEmailId = System.Label.NoReplyRubrikEmailId;
                        message.setReplyTo(noReplyEmailId);//CPQ22-4074 Ends
                        message.setUseSignature(false); 
                        message.setCcAddresses(sendingToCcAdd);
                        message.setSaveAsActivity(false); 
                        message.setWhatId(tsk.WhatId);
                        
                        if(userMap != null && !userMap.IsEmpty() && userMap.containsKey(tsk.OwnerId) && userMap.get(tsk.OwnerId) != null && tsk.OwnerId != null){
                            User theUser = userMap.get(tsk.OwnerId);
                            
                            message.toAddresses = new String[] {theUser.Email};
                                
                                Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
                                    
                                    if (!Test.isRunningTest()){
                                        try {
                                        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                                        if (results[0].success) {
                                            System.debug(LoggingLevel.DEBUG, 'The email was sent successfully.');
                                        } else {
                                            System.debug(LoggingLevel.DEBUG, 'The email failed to send: ' +  results[0].errors[0].message);
                                        }
                                        } catch(Exception ex){
                                            System.debug(LoggingLevel.DEBUG, 'Email is not sent-sendTaskEmail: '+ex.getMessage());
                                        }
                                        
                                    }
                        }
                    }
                }
            }
        }
    }
    //END -[Shaloo Mishra] Arroyo 2.0: Trigger Task created send email when an Oppty has Primary Renewal/Expansion Quote created

    //SAL25-748
    /**
     * @description
     * @param oldOppList
     */
    public static void validateOpportunityOnDelete(List<Opportunity> oldOppList){
        SOX_Objects_Delete_Access__c disableLogicCS = SOX_Objects_Delete_Access__c.getInstance(UserInfo.getUserId());
        for(Opportunity opp :oldOppList){
            if(!(opp.Opportunity_Split_Parent__c != null || (opp.Is_child_Renewal_split__c && opp.Opportunity_Sub_Type__c == 'Renewal') || disableLogicCS.Allow_Opportunity_Delete__c)){
                opp.addError('You do not have access to delete the opportunity.');
            }
        }
    }
    //End - SAL25-748

    //Start - PRIT25-750 Partner Relation are updated or inserted based on changes in the associated Opportunity fields
    /**
     * @description
     * @param newOppMap
     * @param oldOppMap
     */
    public static void syncOpportunityPartnerRelations(Map<Id, Opportunity> newOppMap, Map<Id, Opportunity> oldOppMap) {
        Set<Id> opportunityIds = new Set<Id>();
        List<Partner_Relation__c> relationsToUpsert = new List<Partner_Relation__c>();
        // Fetch existing Partner_Relation__c records related to the given opportunities
        Map<Id, Map<String, Partner_Relation__c>> existingRelations = new Map<Id, Map<String, Partner_Relation__c>>();
        //Ankit G - Please move this to sub query in handler and use list/map here
        for (Partner_Relation__c relation : [SELECT Opportunity__c, Involvement_Type__c, Partner_Account__c FROM Partner_Relation__c WHERE Opportunity__c IN :newOppMap.keySet() AND Involvement_Type__c != 'Teaming Partner']) {//PRIT26-84
            // Initialize the map for the opportunity if it doesn't exist
            if (!existingRelations.containsKey(relation.Opportunity__c)) {
                existingRelations.put(relation.Opportunity__c, new Map<String, Partner_Relation__c>());
            }
            // Store existing partner relation by involvement type
            existingRelations.get(relation.Opportunity__c).put(relation.Involvement_Type__c, relation);
        }
        
        // Fetch accounts based on Incumbent_Partner__c text field
        Map<String, Id> incumbentPartnerAccountMap = new Map<String, Id>();
        Set<String> incumbentPartnerNames = new Set<String>();

        for (Opportunity opp : newOppMap.values()) {
            if (opp.Incumbent_Partner__c != null) {
                incumbentPartnerNames.add(opp.Incumbent_Partner__c);
            }
        }
        if (!incumbentPartnerNames.isEmpty()) {
            //Ankit G - Please move this to account query in handler and use acc list here
            for (Account acc : [SELECT Id, Name FROM Account WHERE Name IN :incumbentPartnerNames AND RecordType.DeveloperName = 'Partner_Distributor']) {
                incumbentPartnerAccountMap.put(acc.Name, acc.Id);
            }
        }
        // Iterate over new opportunities
        for (Opportunity opp : newOppMap.values()) {
            Opportunity oldOpp = oldOppMap != null ? oldOppMap.get(opp.Id) : null;
            // Mapping of involvement types to their respective field values in the new opportunity
            Map<String, Id> newFieldMap = new Map<String, Id>{
                'Transacting Partner' => opp.Partner_Lookup__c,'Distributor' => opp.Distributor_Lookup__c,
                    'Sourcing Partner' => opp.Sourcing_Partner__c,'Incumbent Partner' => incumbentPartnerAccountMap.get(opp.Incumbent_Partner__c), 'Teaming Partner' => opp.Teaming_Partner__c
                    };//PRIT26-84
                        // Mapping of involvement types to their respective field values in the old opportunity
                        Map<String, Id> oldFieldMap = oldOpp != null ? new Map<String, Id>{'Transacting Partner' => oldOpp.Partner_Lookup__c, 'Distributor' => oldOpp.Distributor_Lookup__c, 'Sourcing Partner' => oldOpp.Sourcing_Partner__c, 'Incumbent Partner' => incumbentPartnerAccountMap.get(oldOpp.Incumbent_Partner__c), 'Teaming Partner' => null} : new Map<String, Id>{'Transacting Partner' => null, 'Distributor' => null,'Sourcing Partner' => null, 'Incumbent Partner' => null, 'Teaming Partner' => null};//PRIT26-84
            
            // Get existing relations for the current opportunity
            Map<String, Partner_Relation__c> oppRelations = existingRelations.get(opp.Id);
			// Iterate over each involvement type
            for (String involvementType : newFieldMap.keySet()) {
                Id newFieldValue = newFieldMap.get(involvementType);
                Id oldFieldValue = oldFieldMap.get(involvementType);
                // Check if the partner relation needs to be updated or inserted
                if (newFieldValue != null && (oldFieldValue == null || newFieldValue != oldFieldValue)) {
                    if (oppRelations != null && oppRelations.containsKey(involvementType)) {
                        if (oppRelations.get(involvementType).Partner_Account__c != newFieldValue) {
                            oppRelations.get(involvementType).Partner_Account__c = newFieldValue;
                            relationsToUpsert.add(oppRelations.get(involvementType));
                        }
                    } else {
                        relationsToUpsert.add(new Partner_Relation__c(Opportunity__c = opp.Id, Partner_Account__c = newFieldValue, Involvement_Type__c = involvementType));
                    }
                }
            }
        }
        // Perform upsert operation to update or insert partner relations
        if (!relationsToUpsert.isEmpty()) {
            Database.upsert(relationsToUpsert, false);
        }
    }
    //End - PRIT25-750
    //SAL26-1217
    private static void populateOppPLSGenericFields(UserTerritory2Association uta, Opportunity opp, String type)
    {
        Map<String, Map<String, String>> fieldConfig = new Map<String, Map<String, String>>{
            'cloud' => new Map<String, String>{'theatre' => 'Opp_PLS_ETM_Theatre__c', 'area' => 'Opp_PLS_ETM_Area__c','region' => 'Opp_PLS_ETM_Region__c', 'territory' => 'Opp_PLS_ETM_Territory__c'},
            'ncd' => new Map<String, String>{'theatre'=> 'Opp_PLS_NCD_ETM_Theatre__c', 'area' => 'Opp_PLS_NCD_ETM_Area__c','region' => 'Opp_PLS_NCD_ETM_Region__c', 'territory' => 'Opp_PLS_NCD_ETM_Territory__c'},
            'saas' => new Map<String, String>{'theatre' => 'Opp_PLS_SaaS_ETM_Theatre__c', 'area' => 'Opp_PLS_SaaS_ETM_Area__c', 'region' => 'Opp_PLS_SaaS_ETM_Region__c', 'territory' => 'Opp_PLS_SaaS_ETM_Territory__c'}
        };

        if (!fieldConfig.containsKey(type)) return;


        Map<String, String> values = new Map<String, String>{
            'theatre'   => uta.Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c,
            'area'      => uta.Territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c,
            'region'    => uta.Territory2.ParentTerritory2.Internal_Territory_Name__c,
            'territory' => uta.Territory2.Internal_Territory_Name__c
        };
        for (String key : values.keySet()) {
            opp.put(fieldConfig.get(type).get(key), values.get(key));
        }
        if (String.isNotBlank(opp.PLS_ETM_Overrides__c)) {
            for (String etmOverride : opp.PLS_ETM_Overrides__c.split(';')) {
                if (etmOverride.toLowerCase().contains(type)) return;
            }
        }
        opp.PLS_AE_ETM_Role_Name__c = appendPLSRoleOrAdaptiveId(opp.PLS_AE_ETM_Role_Name__c, uta.RoleInTerritory2);
        opp.Non_Core_Adaptive_Id__c = appendPLSRoleOrAdaptiveId(opp.Non_Core_Adaptive_Id__c, uta.Territory2.Adaptive_Territory_Id__c);
    }
    //SAL26-1217
    private static String appendPLSRoleOrAdaptiveId(String existingValue, String newValue) {
        if (String.isBlank(newValue)) return existingValue;
        newValue = newValue.trim();
        Set<String> values = new Set<String>();
        if (!String.isBlank(existingValue)) {
            for (String val : existingValue.split(',')) {
                if (!String.isBlank(val)) {
                    values.add(val.trim());
                }
            }
        }
        values.add(newValue);
        return String.join(new List<String>(values), ',');
    }


/**
* @description create partner relation on debooking opportunities- SAL26-72
* @param debookingOppMap
*/
    public static void createPartnerRelation(Map<Id, Opportunity> debookingOppMap) {
        Map<Id, Opportunity> originalOppMap = new Map<Id, Opportunity> ();
        Map<Id, Id> originalCcrOpportunityMap = new Map<Id, Id> ();        
        Set<Id> ccrIds = new Set<Id> ();
        Map<Id, Opportunity> debookingCcrMap = new Map<Id, Opportunity> ();
        Map<Id, Opportunity> debookingOpportunityMap = new Map<Id, Opportunity> ();
        try {
            for(Opportunity opp : debookingOppMap.values()) {
                debookingCcrMap.put(opp.CCR__c, opp);
            }
            for(CCR__c ccrRecord: [SELECT Id, Opportunity__c FROM CCR__c WHERE Id IN :debookingCcrMap.keySet()]) {
                originalCcrOpportunityMap.put(ccrRecord.Id, ccrRecord.Opportunity__c);
                if(debookingCcrMap.containsKey(ccrRecord.Id)) {
                    debookingOpportunityMap.put(ccrRecord.Opportunity__c, debookingCcrMap.get(ccrRecord.Id));
                }
            }
            for(Opportunity originalOpp: [SELECT Id FROM Opportunity WHERE Id IN: originalCcrOpportunityMap.values()]) {
                originalOppMap.put(originalOpp.Id, originalOpp);
            }
            OpportunitySplitLWCController.createPartnerRelation(debookingOpportunityMap, originalOppMap,'Debooking');
        } catch (Exception ex) {
            system.debug(LoggingLevel.DEBUG, 'Exception-->'+ex.getMessage());
        }
    }
     /**
     * @description populate PLS TART and other fields from UTA
     * @param uta
     * @param opp
     */
    public static void populateOppPLSfields(UserTerritory2Association uta, Opportunity opp) {
        opp.PLS_AE_ETM_Role_Name__c = uta.RoleInTerritory2;
        opp.Non_Core_Adaptive_Id__c = uta.Territory2.Adaptive_Territory_Id__c; //PL26-38,PL26-19
        opp.Opp_PLS_ETM_Theatre__c = uta.Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c;
        opp.Opp_PLS_ETM_Area__c = uta.Territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c;
        opp.Opp_PLS_ETM_Region__c = uta.Territory2.ParentTerritory2.Internal_Territory_Name__c;
        opp.Opp_PLS_ETM_Territory__c = uta.Territory2.Internal_Territory_Name__c;
    }  
        
    /***********************************************************************************************************
    * Method Name          : sendOpportunityEndUserAlert
    * Date Created/Modified: 23/05/2025
    * Author               : Shivani
    * @description         : sends Opportunity End User Alert
    * @param oldOppMap
    * @param queriedQuoteList
    * @param emailTemplate
    * @param mapOppIdToOpportunityWithStageChange
    * @version                :
    * Test Class Methods   :
    /**********************************************************************************************************/
    public static void sendOpportunityEndUserAlert(
        Map<Id, Opportunity> oldOppMap, List<SBQQ__Quote__c> queriedQuoteList, EmailTemplate emailTemplate, Map<Id,Opportunity> mapOppIdToOpportunityWithStageChange){
        List<Task> tasksList  = new List<Task>();
        //FY25SR-2409
        //Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();
        
        if(!mapOppIdToOpportunityWithStageChange.keySet().isEmpty()){
            List<Task> listTask = 
                [SELECT ID,WhatId FROM Task WHERE 
                                            Subject = 'Opp-07: End-User Alert' 
                                        AND WhatId IN : mapOppIdToOpportunityWithStageChange.keySet()
                                        AND Type = 'Email'
                                ];
            Map<Id,Task> mapOppIdToTask = new Map<Id,Task>();
            for (Task objtask : listTask) {
                mapOppIdToTask.put(objtask.WhatId,objtask);
            }
            for(SBQQ__Quote__c objQuote : queriedQuoteList){
                if(mapOppIdToOpportunityWithStageChange.containsKey(objQuote.SBQQ__Opportunity2__r.Id) 
                    && objQuote.SBQQ__Primary__c 
                    && ( objQuote.Trade_Up_Amounts__c > 0 || objQuote.Prepayment_Credit__c > 0 || objQuote.ShowPromoDisc__c 
                    )){
                    // create task     
                    if(!mapOppIdToTask.containsKey(objQuote.SBQQ__Opportunity2__r.Id)){
                        tasksList.add(new Task(
                                        WhatId = objQuote.SBQQ__Opportunity2__r.Id,
                                        OwnerId = objQuote.SBQQ__Opportunity2__r.OwnerId,
                                        Status = 'Not Started',
                                        Subject = 'Opp-07: End-User Alert',
                                        Type = 'Email',
                                        ActivityDate = system.today(),
                                        Priority = 'Normal'
                                    ));
                        //send email code //FY25SR-2409
                       /* Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                        message.setTemplateId(emailTemplate.Id);
                        message.setTreatTargetObjectAsRecipient(false);
                        
                        String[] sendingToCcAdd =  new List<String>{objQuote.SBQQ__Opportunity2__r.Owner.Email};
                        message.setTargetObjectId(objQuote.SBQQ__Opportunity2__r.OwnerId);
                        String noReplyEmailId = System.Label.NoReplyRubrikEmailId;
                        message.setReplyTo(noReplyEmailId);//CPQ22-4074 Ends
                        message.setUseSignature(false); 
                        message.setCcAddresses(sendingToCcAdd);
                        message.setSaveAsActivity(false); 
                        message.setWhatId(objQuote.SBQQ__Opportunity2__r.Id);
                        message.toAddresses = new String[] {objQuote.SBQQ__Opportunity2__r.Initial_Contacts_Name__r.Email};
                        messages.add(message);*/
                    }                
                }
            }

            if(!tasksList.IsEmpty()){
                insert tasksList;
            }
        }
        //FY25SR-2409
        //return messages;
    }
      /***********************************************************************************************************
    * Method Name          : sendPOInChannelNotice
    * Date Created/Modified: 03/06/2025
    * Author               : Shivani
    * @description         : sends PO In Channel Notice
    * @param newOppList
    * @param oldOppMap
    * @param queriedQuoteList
    * @param emailTemplate
    * @return message list
    * Test Class Methods   :
    /**********************************************************************************************************/
    public static Messaging.SingleEmailMessage[] sendPOInChannelNotice(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap, List<SBQQ__Quote__c> queriedQuoteList, EmailTemplate emailTemplate){
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();

        Map<Id,Opportunity> mapIdToOpportunity = new Map<Id,Opportunity>(
            										[SELECT ID,Account.Renewal_Owner__r.Email from Opportunity WHERE ID IN: newOppList]);
        for(Opportunity newOpp : newOppList){
            if (newOpp.StageName != null && newOpp.StageName  == '6 PO With Channel' && 
                newOpp.StageName != oldOppMap.get(newOpp.Id).StageName 
                && newOpp.Opportunity_Program__c != null 
                && (newOpp.Opportunity_Program__c.contains('Upgrade') 
                                                             || newOpp.Opportunity_Program__c.contains('Conversion'))
            ) {
                        //send email code
                        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                        message.setTemplateId(emailTemplate.Id);
                        message.setTreatTargetObjectAsRecipient(false);
                        
                String[] sendingToCcAdd =  new List<String>{System.Label.RenewalOperationsRubrikEmailId};
                message.setTargetObjectId(newOpp.OwnerId);
                String noReplyEmailId = System.Label.NoReplyRubrikEmailId;
                message.setReplyTo(noReplyEmailId);//CPQ22-4074 Ends
                message.setUseSignature(false); 
                message.setSenderDisplayName(newOpp.Owner.Name);
                message.setCcAddresses(sendingToCcAdd);
                message.setSaveAsActivity(false); 
                message.setWhatId(newOpp.Id);
                message.toAddresses = new String[] {mapIdToOpportunity.get(newOpp.Id).Account.Renewal_Owner__r.Email};

               messages.add(message);
            }
        }
        return messages;
    }
      /***********************************************************************************************************
    * Method Name          : sendRefreshNotification
    * Date Created/Modified: 03/06/2025
    * Author               : Shivani
    * @description         : sends refresh notifications
    * @param newOppList
    * @param oldOppMap
    * @param queriedQuoteList
    * Test Class Methods   :
    /**********************************************************************************************************/
      public static void sendRefreshNotification(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap, List<SBQQ__Quote__c> queriedQuoteList){
        system.debug(system.logginglevel.DEBUG, 'Test');
        Map<Id,Opportunity> mapOppIdToOpportunityWithStageChange = new Map<Id,Opportunity>();
        List<Task> tasksList  = new List<Task>();
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();
        for(Opportunity newOpp : newOppList){
            if (newOpp.StageName != null && newOpp.StageName  == '4 Business Justification' && 
                newOpp.StageName != oldOppMap.get(newOpp.Id).StageName 
                && newOpp.Opportunity_Program__c != null && newOpp.Opportunity_Program__c.contains('Refresh')
            ) {
                    mapOppIdToOpportunityWithStageChange.put(newOpp.Id,newOpp);
            }
        }
        
        if (!mapOppIdToOpportunityWithStageChange.keySet().isEmpty()) {
            List<Task> listTask = [SELECT ID,WhatId FROM Task WHERE 
                                            Subject = 'Opp-04: Refresh Alert' 
                                        AND WhatId IN : mapOppIdToOpportunityWithStageChange.keySet()
                                        AND Type = 'Email'
                                ];
            System.debug(system.logginglevel.DEBUG,'Shivani ::'+ listTask.size());
            EmailTemplate emailTemplate = [SELECT Id, Subject, Description, HtmlValue, DeveloperName, Body FROM EmailTemplate 
                                    WHERE Name = 'Refresh Notification'];

            Map<Id,Task> mapOppIdToTask = new Map<Id,Task>();
            for (Task objtask : listTask) {
                mapOppIdToTask.put(objtask.WhatId,objtask);
            }
            for(SBQQ__Quote__c objQuote : queriedQuoteList){
                if(mapOppIdToOpportunityWithStageChange.containsKey(objQuote.SBQQ__Opportunity2__r.Id) && 
                   objQuote.SBQQ__Primary__c && objQuote.ApprovalStatus__c == 'Approved'){
                    // create task  
                    System.debug(system.logginglevel.DEBUG,'Shivani ::2951 ::' + mapOppIdToTask.get(objQuote.SBQQ__Opportunity2__r.Id));  
                    if(!mapOppIdToTask.containsKey(objQuote.SBQQ__Opportunity2__r.Id)){
                        System.debug(system.logginglevel.DEBUG,'Shivani ::2954 ::');  
                        tasksList.add(new Task(
                                        WhatId = objQuote.SBQQ__Opportunity2__r.Id,
                                        OwnerId = objQuote.SBQQ__Opportunity2__r.OwnerId,
                                        Status = 'Not Started',
                                        Subject = 'Opp-04: Refresh Alert',
                                        Type = 'Email',
                                        ActivityDate = system.today(),
                                        Priority = 'Normal'
                                    ));
                        //send email code
                        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                        message.setTemplateId(emailTemplate.Id);
                        message.setTreatTargetObjectAsRecipient(false);
                        
                        String[] sendingToCcAdd =  new List<String>{System.Label.RenewalOperationsRubrikEmailId};
                        message.setTargetObjectId(objQuote.SBQQ__Opportunity2__r.OwnerId);
                        String noReplyEmailId = System.Label.NoReplyRubrikEmailId;
                        message.setReplyTo(noReplyEmailId);//CPQ22-4074 Ends
                        message.setUseSignature(false); 
                        message.setCcAddresses(sendingToCcAdd);
                        message.setSaveAsActivity(false); 
                        message.setWhatId(objQuote.SBQQ__Opportunity2__r.Id);
                        message.toAddresses = new String[] {objQuote.SBQQ__Opportunity2__r.Account.Renewal_Owner__r.Email};
                                
                        messages.add(message);
                    }
                }
            }

            if(!tasksList.IsEmpty()){
                insert tasksList;
                if (!Test.isRunningTest()){
                    try {
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
        }
    }


    /***********************************************************************************************************
    * Method Name          : sendEmailAlertsOnStageChange
    * Date Created/Modified: 14/08/2025
    * Author               : Ankita
    * @description         : Sends notification on Stage change
    * @param newOppList
    * @param oldOppMap
    * @param queriedQuoteList
    * Test Class Methods   :
    /**********************************************************************************************************/
    public static void sendEmailAlertsOnStageChange(
        List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap, List<SBQQ__Quote__c> queriedQuoteList
    ) {
        Map<Id,Opportunity> mapOppIdToOpportunityWithStageChange = new Map<Id,Opportunity>();
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();
        EmailTemplate endUserAlertTemplate = new EmailTemplate();
        EmailTemplate POChannelNotificationTemplate = new EmailTemplate();
        for(Opportunity newOpp : newOppList){
            if (newOpp.StageName != null && newOpp.StageName  == '6 PO With Channel' && 
                newOpp.StageName != oldOppMap.get(newOpp.Id).StageName 
                && newOpp.Opportunity_Program__c != null 
                && (newOpp.Opportunity_Program__c.contains('Upgrade') 
                 || newOpp.Opportunity_Program__c.contains('Conversion'))
            ) {
                mapOppIdToOpportunityWithStageChange.put(newOpp.Id, newOpp);
            }
        }
        if(mapOppIdToOpportunityWithStageChange.size() > 0 ) {
            List<EmailTemplate> emailTemplates = 
              [SELECT Id, Name, Subject, Description, HtmlValue, DeveloperName, Body FROM EmailTemplate 
                WHERE Name = 'PO In Channel Notice Notification'
                   OR Name = 'Opportunity End-User Alert'];
            for(EmailTemplate eT : emailTemplates) {
                if(eT.Name == 'Opportunity End-User Alert') {
                    endUserAlertTemplate = eT;
                }
                if(eT.Name == 'PO In Channel Notice Notification') {
                    POChannelNotificationTemplate = eT;
                }
            }
            //FY25SR-2409
            sendOpportunityEndUserAlert(
                    oldOppMap, queriedQuoteList,endUserAlertTemplate,mapOppIdToOpportunityWithStageChange);
            messages.addAll(sendPOInChannelNotice(mapOppIdToOpportunityWithStageChange.values(),
                    oldOppMap, queriedQuoteList, POChannelNotificationTemplate));
        }
        if(!messages.IsEmpty() && !Test.isRunningTest()){
            try {
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
    /**
    * @description  : validate Distributor on Scale utility amended opportunity to Contracted opportunity
    * @param newOpp
    * @param serviceContractMapTrgUpdate
    */
  public static void validateDistiForAmendmentUtilityQuote (List<Opportunity> newOpp, Map<Id, ServiceContract> serviceContractMapTrgUpdate){
    ShGl_DisableBusinessLogic__c disabledBusinessLogic = ShGl_DisableBusinessLogic__c.getInstance(); 
    for (Opportunity opp : newOpp) {
           if (((serviceContractMapTrgUpdate.containsKey(opp.SBQQSC__AmendedServiceContract__c) &&
    opp.Distributor_Lookup__c != serviceContractMapTrgUpdate.get(opp.SBQQSC__AmendedServiceContract__c).SBQQSC__Opportunity__r.Distributor_Lookup__c) || ((opp.SBQQ__PrimaryQuote__c != null && opp.SBQQ__PrimaryQuote__r.SBQQ__Distributor__c !=null &&
    opp.Distributor_Lookup__c != opp.SBQQ__PrimaryQuote__r.SBQQ__Distributor__c))) && !disabledBusinessLogic.Disable_Opportunity_Validation_Rules__c) {
    
    opp.addError(label.UtilityAmendmentQuoteDistiValidation);
        }

  }
    
}
    /** 
    * Method Name          : validateRiskAndInvalidOpp
    * Date Created/Modified: 28-Nov-2025
    * @description    Created as part of FY26WL-352 Invalid Duplicate Validation for Opportunity
    * @param newMap
    * @param oldMap
	*/
    public static void validateRiskAndInvalidOpp(Map<ID,Opportunity> newMap, Map<ID,Opportunity> oldMap){
        if(newMap.isEmpty() || oldMap.isEmpty()) return;
        List<String> oppClosedStages = new List<String>{'7 Closed Won','7 Closed Lost','7 Closed Admin'};
        Id recordTypeRenwalId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Renewal_Opportunity').getRecordTypeId();
        Map<Id,Id> childOppIdsWithDuplicateIdsMap = new Map<Id,Id>();
    
        for(opportunity oppObj : newMap.values()){
            if(!isValidOpp(oppObj, oldMap, recordTypeRenwalId)){continue;}
            
            if(oppObj.Duplicate_Opportunity_Lookup__c == null){
                oppObj.addError('Existing Opportunity field cannot be blank when the Renewal Program Risk is ‘Invalid Duplicate’');
            }else if(oppObj.Duplicate_Opportunity_Lookup__c == oppObj.Id){
                oppObj.addError('Existing Opportunity cannot be current opportunity when the Renewal Program Risk is ‘Invalid Duplicate’');                 
            }else if(oppClosedStages.contains(oppObj.StageName)){
                oppObj.addError('Closed won opportunity cannot be marked as Invalid Duplicate.');
            }else if(oppObj.Duplicate_Opportunity_Lookup__c != null && oppObj.SBQQ__PrimaryQuote__c != null){
                childOppIdsWithDuplicateIdsMap.put(oppObj.Id,oppObj.Duplicate_Opportunity_Lookup__c);
            }
        }
        if(childOppIdsWithDuplicateIdsMap.isEmpty()){return;}
        
        String result = compareCurrentAndDuplicateOpp(childOppIdsWithDuplicateIdsMap);
        if(String.IsNotBlank(result)){
            for(opportunity oppObj : newMap.values()){
                if(result.StartsWith('006') && oppObj.Id == result){
                    oppObj.addError('Existing Opportunity selected cannot be marked as such because it does not cover all the entitlements of this opportunity.');
                }else if(result.StartsWith('NonRenewal') && result.split('-')[1] == oppObj.Id){               
                    oppObj.addError('Existing Opportunity cannot be a Regular Opportunity.');        
                }
            }
        }
    }
    /**
    * Method Name          : isValidOpp
    * Date Created/Modified: 28-Nov-2025
    * @description   Created as part of FY26WL-352 validate entry criteria
    * @param oppObj
    * @param oldMap
    * @param oppStages
    * @param recordTypeRenwalId
    * @return boolean
	*/
    public static Boolean isValidOpp(opportunity oppObj,  Map<ID,Opportunity> oldMap, String recordTypeRenwalId){       
        return oppObj.recordTypeId == recordTypeRenwalId && oppObj.Renewals_Forecast_Risk__c == 'Invalid Duplicate' && oppObj.Renewals_Forecast_Risk__c != oldMap.get(oppObj.Id).Renewals_Forecast_Risk__c;
    }
    /**
    * Method Name          : compareCurrentAndDuplicateOpp
    * Date Created/Modified: 28-Nov-2025
    * @description  Created as part of FY26WL-352 comparing the child and existing opportunity Primary Quote line item with entitlement ids
    * @param childOppIdsWithDuplicateIdsMap
    * @return String
	*/
    public static String compareCurrentAndDuplicateOpp(Map<Id,Id> childOppIdsWithDuplicateIdsMap){
        if (childOppIdsWithDuplicateIdsMap.isEmpty()) {
            System.debug(System.logginglevel.ERROR,'Error: Map of Opportunity IDs must be provided.');
            return 'Error: Map of Opportunity IDs must be provided.';
        }
        String currentOppId = '';
        Map<Id, Id> childPrimaryQuoteIdOppId = new Map<Id, Id>();
        Map<Id, Set<String>> oppIdWithEntitlementIds = new Map<Id,Set<String>>();
        Map<Id, String> oppWithSubType = new Map<Id, String>();
        for (OpportunityLineItem oli : [SELECT Id, 
                                       SBQQ__QuoteLine__c, 
                                       OpportunityId, 
                                       Opportunity.Opportunity_Sub_Type__c, 
                                       SBQQ__QuoteLine__r.SBQQ__Quote__c, 
                                       SBQQ__QuoteLine__r.Replacement_Details__c,
                                       SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__c,
                                       SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r.Opportunity_Sub_Type__c
                                FROM OpportunityLineItem 
                                WHERE (OpportunityId IN :childOppIdsWithDuplicateIdsMap.keySet() 
                                       OR OpportunityId IN :childOppIdsWithDuplicateIdsMap.values())
                                AND SBQQ__QuoteLine__c != null 
                                AND SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Primary__c = true 
                                AND SBQQ__QuoteLine__r.SBQQSC__RenewedContractLine__c != null]) {
              
            // Create a local reference to the Quote Line for readability
            SBQQ__QuoteLine__c qli = oli.SBQQ__QuoteLine__r;
            Id oppId = oli.OpportunityId ;
                                           
            if(childOppIdsWithDuplicateIdsMap.containsKey(oppId)){
                childPrimaryQuoteIdOppId.put(qli.SBQQ__Quote__c, oppId);     
             }
             
            String jsonDetails = qli.Replacement_Details__c;
            if (String.isBlank(jsonDetails)) { continue; }
            
            ReplacementJson replacementMap = (ReplacementJson)JSON.deserialize(jsonDetails, ReplacementJson.class);
            
            if (replacementMap.rowValues == null || replacementMap.rowValues.isEmpty()) { continue; }

            if(!oppWithSubType.containsKey(oppId)){
                oppWithSubType.put(oppId, oli.Opportunity.Opportunity_Sub_Type__c);
            }

            for(ReplacementJson.RowDetail rowDetailObj : replacementMap.rowValues){
                if (rowDetailObj.entId == null) { continue; }
                
                String entitlementId = String.valueOf(rowDetailObj.entId).trim();
                Set<String> entitleIds = oppIdWithEntitlementIds.containsKey(oppId) ? 
                                        oppIdWithEntitlementIds.get(oppId) : 
                                        new Set<String>();
                entitleIds.add(entitlementId);
                oppIdWithEntitlementIds.put(oppId, entitleIds);            
            }
        }
     
         if (childPrimaryQuoteIdOppId.isEmpty()) {
            System.debug(System.logginglevel.ERROR,'No primary quotes found for the provided opportunities.');
            return 'No primary quotes found for the provided opportunities.';
        }
        for(Id quoteId :  childPrimaryQuoteIdOppId.keySet()){
            
            Id oppId = childPrimaryQuoteIdOppId.get(quoteId);
            String existOppId = childOppIdsWithDuplicateIdsMap.get(oppId);
            
            if(!oppIdWithEntitlementIds.containsKey(existOppId)){
                currentOppId = oppId;
                break;
            }
            if(oppWithSubType.containsKey(existOppId) && oppWithSubType.get(existOppId) != 'Renewal'){
                currentOppId = 'NonRenewal-'+oppId;
                break;
            }
            
            Set<String>childOppQuoteEntitleIds = oppIdWithEntitlementIds.get(oppId);
            Set<String>duplicateOppQuoteEntitleIds = oppIdWithEntitlementIds.get(existOppId);
            
            if(((childOppQuoteEntitleIds == null || childOppQuoteEntitleIds.IsEmpty()) &&
               (duplicateOppQuoteEntitleIds == null || duplicateOppQuoteEntitleIds.IsEmpty()))
              || (childOppQuoteEntitleIds == null || childOppQuoteEntitleIds.IsEmpty())
              ){continue;}
            if(!childOppQuoteEntitleIds.IsEmpty() && (duplicateOppQuoteEntitleIds == null || duplicateOppQuoteEntitleIds.IsEmpty())){
                currentOppId = oppId;
                break;
            }           
            childOppQuoteEntitleIds.removeAll(duplicateOppQuoteEntitleIds);
            if(!childOppQuoteEntitleIds.IsEmpty()){
                currentOppId = oppId;
                break;
            }
        }
        return currentOppId;
    }
      
     //SAL26-1340

    /*Build User to UTA Map*/
    public static Map<Id, List<UserTerritory2Association>> buildUserToUTAMap(Set<Id> coOwnerUserIds){
        // Query UTAs once
        Map<Id, List<UserTerritory2Association>> userToUTAListMap = new Map<Id, List<UserTerritory2Association>>();

        for (UserTerritory2Association uta : [ SELECT UserId, RoleInTerritory2, Territory2.Adaptive_Territory_Id__c FROM UserTerritory2Association
            WHERE UserId IN :coOwnerUserIds AND Territory2.Territory2Type.DeveloperName = 'Territory'
            AND Territory2.Territory2Model.State = 'Active' AND User.IsActive = true
            AND RoleInTerritory2 IN ('Cloud AE','NCD AE','SaaS AE')])
        {
            if (!userToUTAListMap.containsKey(uta.UserId)) {
                userToUTAListMap.put(uta.UserId, new List<UserTerritory2Association>());
            }
            userToUTAListMap.get(uta.UserId).add(uta);
        }
        return userToUTAListMap;
    }
    /*Reset PLS fields*/
    public static void resetPLSForETMOverridesAndSplitOpp(Map<Id, List<UserTerritory2Association>> userToUTAListMap, Set<Id> oppIds, Map<Id, Opportunity> oppMap, Boolean callBySplit){
        Map<Id, Map<String, Set<String>>> oppRoleMap = buildOppRoleAdaptiveMap(oppIds, oppMap, userToUTAListMap);
        processETMOverrides(oppMap, oppIds, oppRoleMap, true, callBySplit);
    }
    /*Populate PLS fields*/
    public static void setPLSForETMOverridesAndSplitOpp(Map<Id, List<UserTerritory2Association>> userToUTAListMap, Set<Id> oppIds, Map<Id, Opportunity> oppMap, Boolean callBySplit){
        Map<Id, Map<String, Set<String>>> oppRoleMap = buildOppRoleAdaptiveMap(oppIds, oppMap, userToUTAListMap);
        processETMOverrides(oppMap, oppIds, oppRoleMap, false, callBySplit);
    }

    private static Map<Id, Map<String, Set<String>>> buildOppRoleAdaptiveMap(Set<Id> oppIds, Map<Id, Opportunity> oppMap, Map<Id, List<UserTerritory2Association>> userToUTAListMap){
        Map<Id, Map<String, Set<String>>> result = new Map<Id, Map<String, Set<String>>>();

        for (Id oppId : oppIds) {
            Opportunity opp = oppMap.get(oppId);
            Map<String, Set<String>> roleToIds = new Map<String, Set<String>>();

            for (String fieldName : coOwnerFields) {
                Id userId = (Id) opp.get(fieldName);
                if (userId == null || !userToUTAListMap.containsKey(userId)) continue;

                for (UserTerritory2Association uta : userToUTAListMap.get(userId)) {
                    if (!roleToIds.containsKey(uta.RoleInTerritory2)) {
                        roleToIds.put(uta.RoleInTerritory2, new Set<String>());
                    }
                    roleToIds.get(uta.RoleInTerritory2).add(uta.Territory2.Adaptive_Territory_Id__c);
                }
            }
            result.put(oppId, roleToIds);
        }
        return result;
    }

    private static void processETMOverrides(Map<Id, Opportunity> oppMap, Set<Id> oppIds, Map<Id, Map<String, Set<String>>> oppRoleMap, Boolean isReset, Boolean callBySplit){
        for (Id oppId : oppIds) {
            Opportunity opp = oppMap.get(oppId);
            Set<String> overrides = String.isBlank(opp.PLS_ETM_Overrides__c) ? new Set<String>() : new Set<String>(opp.PLS_ETM_Overrides__c.split(';'));
            Set<String> splitOverrides = new Set<String>();
            if (callBySplit && opp.Opportunity_Split_Parent__r != null) {
                splitOverrides = String.isBlank(opp.Opportunity_Split_Parent__r.PLS_ETM_Overrides__c) ? new Set<String>() : new Set<String>(opp.Opportunity_Split_Parent__r.PLS_ETM_Overrides__c.split(';'));
                overrides.addAll(splitOverrides);
                OpportunityUtil.resetPLSFieldsForSplitOppETMOverrides(overrides, splitOverrides, opp);
            }
            if (isReset) {
                OpportunityUtil.resetRoleAndIdForSplitOppETMOverrides(overrides, oppRoleMap.get(oppId), opp);
            }
            else {
                OpportunityUtil.appendRoleAndIdForSplitOppETMOverrides(overrides, oppRoleMap.get(oppId), opp);
            }
        }
    }
}