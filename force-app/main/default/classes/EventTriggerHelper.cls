public class EventTriggerHelper {
    //literals
    private static final String MGM_MEETING_TYPE = 'Marketing Generated Meeting';
    private static final String ISLM_MEETING_TYPE = 'Inside Sales Led Meeting';
    private static final String FSLM_MEETING_TYPE = 'Field Sales Led Meeting';
    private static final String TRANSFORMATION_TEAM_GENERATED_MEETING_TYPE = 'Transformation Team Generated Meeting';

    private static final String OPPTYSOURCED_MEETING_OUTCOME = 'Opportunity Sourced';
    private static final String NOOPPTYSOURCED_MEETING_OUTCOME = 'No Opportunity Sourced';
    private static final String CANCELLED_MEETING_OUTCOME = 'Meeting Cancelled';

    
    /*public void populateETMFields(List<Event> newEvents){
        Set<Id> assignedUserIds = new Set<Id>();
        for(Event eve : newEvents){
            if(eve.OwnerId != null)
                assignedUserIds.add(eve.OwnerId);
        }
        if(!assignedUserIds.isEmpty()){
            Map<Id, UserTerritory2Association> userIdToTerritoryAssn = new Map<Id, UserTerritory2Association>();
            //find the territories
            for(UserTerritory2Association usrAssoctn : [SELECT UserId, Territory2.Internal_Territory_Name__c, Territory2.ParentTerritory2.Internal_Territory_Name__c, Territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c, Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c 
                                                        FROM UserTerritory2Association
                                                        WHERE UserId IN :assignedUserIds AND isActive = TRUE AND Territory2.Territory2Model.State='Active']) {
                userIdToTerritoryAssn.put(usrAssoctn.UserId, usrAssoctn);
            }
 
            for(Event eve : newEvents){
                if(userIdToTerritoryAssn.containskey(eve.OwnerId)){
                    UserTerritory2Association assn = userIdToTerritoryAssn.get(eve.OwnerId);
                    eve.ETM_Territory__c = assn.Territory2.Internal_Territory_Name__c;
                    eve.ETM_Region__c = assn.Territory2.ParentTerritory2.Internal_Territory_Name__c;
                    eve.ETM_Area__c = assn.Territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c;
                    eve.ETM_Theatre__c = assn.Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c;
                }
            }
        }
    }*/

    /**
     * @description Updates the custom field 'Created_By_Manager__c' on Event records.
     * 
     * @param newEvents List of Event records being processed (typically from a trigger context).
     * 
     */
    public void updateCreatedByManager(List<Event> newEvents){
        // Run Meeting Chaclled Status//
        Set<Id> OwnerIds  = new Set<Id>();
        for(Event eve : newEvents){ 
            if(eve.Type == EventTriggerHelper.ISLM_MEETING_TYPE && eve.SOPs_Selected_Owner__c != null ){
                OwnerIds .add(eve.SOPs_Selected_Owner__c);
            } else{
                OwnerIds.add(userinfo.getUserId());
            }
        }

        Map<Id,User> mapOfUser = new Map<Id,User>([SELECT Id,Name,Title, ManagerId, Manager.Name, Manager.Email, Sales_Manager__c FROM User WHERE Id IN: OwnerIds ]);
        if(!mapOfUser.isEmpty()){
            for(Event eve : newEvents){
                if(eve.Type == EventTriggerHelper.ISLM_MEETING_TYPE && mapOfUser.containskey(eve.SOPs_Selected_Owner__c) ){
                    eve.Created_By_Manager__c = mapOfUser.get(eve.SOPs_Selected_Owner__c).Manager.Name;
                    eve.OwnerManagerEmail__c = mapOfUser.get(eve.SOPs_Selected_Owner__c).Manager.Email;
                } else{
                    eve.Created_By_Manager__c = mapOfUser.get(userinfo.getUserId()).Sales_Manager__c;
                }
            }
        }
    }

    /**
     * @description Updates Event records with information from related Lead or Contact records before insertion.
     * This method checks the WhoId field of each Event, determines if it is associated with a Lead or Contact,
     * and enriches the Event with corresponding data such as Name or other relevant fields.
     * @param newEvents List of Event records being processed .
     * 
     */

    public void updateEventFromLeadContactBeforeInsert(List<Event> newEvents){
        Set<Id> ldIds = new Set<Id>();
        Set<Id> conIds = new Set<Id>();
        for(Event evt : newEvents){
            if(evt.WhoId != null && evt.WhoId.getSObjectType() == Lead.sobjectType){
                ldIds.add(evt.WhoId);
            }else if(evt.WhoId != null && evt.WhoId.getSObjectType() == Contact.sobjectType){
                conIds.add(evt.WhoId);
            }
        }
        
        Map<Id,Contact> contactMap = new Map<Id, Contact>([SELECT Id,Last_MQL_Date__c,Campaign_Sourced_By__c, MQL_Channel_Partner__r.Name, MQL_Channel_CDM__r.Email, Account.Account_Tier__c, Account.ETM_Area__c, Account.ETM_Region__c, 
                                                           Account.ETM_Territory__c, Account.ETM_Theatre__c, Account.Account_Status__c FROM Contact WHERE Id IN : conIds]);
        Map<Id,Lead> leadMap = new Map<Id, Lead>([SELECT Id,Last_MQL_Date__c, MQL_Channel_Partner__r.Name, MQL_Channel_CDM__r.Email, Winning_L2A_Account__c, Winning_L2A_Account__r.Account_Tier__c, 
                                                  Winning_L2A_Account__r.ETM_Area__c, Winning_L2A_Account__r.ETM_Region__c, Winning_L2A_Account__r.ETM_Territory__c, Winning_L2A_Account__r.ETM_Theatre__c,
                                                  Winning_L2A_Account__r.Account_Status__c,Campaign_Sourced_By__c FROM Lead WHERE Id IN : ldIds]);
        
        Date today = Date.today();

        for(Event evt : newEvents){
            Date lastMqlDate;
            String campaignSource;
            
            if(evt.WhoId != null && evt.WhoId.getSObjectType() == Lead.sobjectType){
                if(!evt.IsChild ){
                    evt.Account_Tier__c = leadMap.get(evt.WhoId).Winning_L2A_Account__r.Account_Tier__c;
                }
                if(leadMap.get(evt.WhoId).Winning_L2A_Account__c != null){
              		evt.Account_Status__c = leadMap.get(evt.WhoId).Winning_L2A_Account__r.Account_Status__c;
                }
               evt.MQL_Channel_Partner__c = leadMap.get(evt.WhoId).MQL_Channel_Partner__r.Name;
               evt.MQL_Channel_CDM_email__c = leadMap.get(evt.WhoId).MQL_Channel_CDM__r.Email;
                lastMqlDate = leadMap.get(evt.WhoId).Last_MQL_Date__c;
                campaignSource = leadMap.get(evt.WhoId).Campaign_Sourced_By__c;
            }else if(evt.WhoId != null && evt.WhoId.getSObjectType() == Contact.sobjectType){
                if(!evt.IsChild ){
                    evt.Account_Tier__c = contactMap.get(evt.WhoId).Account.Account_Tier__c;
                }
               evt.Account_Status__c = contactMap.get(evt.WhoId).Account.Account_Status__c;
               evt.MQL_Channel_Partner__c = contactMap.get(evt.WhoId).MQL_Channel_Partner__r.Name;
               evt.MQL_Channel_CDM_email__c = contactMap.get(evt.WhoId).MQL_Channel_CDM__r.Email;			   
                lastMqlDate = contactMap.get(evt.WhoId).Last_MQL_Date__c;
                campaignSource = contactMap.get(evt.WhoId).Campaign_Sourced_By__c;
            }
             if(evt.Type == 'Inside Sales Led Meeting' && lastMqlDate != null){
                 Integer daysDiff = lastMqlDate.daysBetween(today);      
                 if (daysDiff > 60) {
                     evt.Outreach_In_Out_Activity__c = 'Outbound';
                 } else if (daysDiff <= 60 && campaignSource == 'Sales') {
                     evt.Outreach_In_Out_Activity__c = 'Outbound';
                 } else if (daysDiff <= 60 && campaignSource == 'Marketing') {
                     evt.Outreach_In_Out_Activity__c = 'Inbound';
            }
        }
            else if (lastMqlDate == null){
                evt.Outreach_In_Out_Activity__c = 'Outbound';
        }
    }
        
        populateETMFields(newEvents, leadMap, contactMap);   
        assignCDMName(newEvents, leadMap, contactMap);
    }
    /**
     * @description Populates Event records with ETM (Event Territory Management) related fields using associated Lead or Contact information.
     * This method examines the WhoId field on each Event, determines whether it references a Lead or Contact,
     * and updates ETM-specific fields on the Event based on data from the corresponding record.
     * @param newEvents List of Event records being processed (typically from a before-insert trigger context).
     * @param leadMap Map of Lead IDs to Lead records for quick lookup of Lead-related data.
     * @param contactMap Map of Contact IDs to Contact records for quick lookup of Contact-related data.
     * 
     */
    public void populateETMFields(List<Event> newEvents, Map<Id,Lead> leadMap, Map<Id,Contact>contactMap){
        Set<Id> assignedUserIds = new Set<Id>();
        for(Event eve : newEvents){
            if(eve.OwnerId != null)
                assignedUserIds.add(eve.OwnerId);
        }
        if(!assignedUserIds.isEmpty()){
            Map<Id, UserTerritory2Association> userIdToTerritoryAssn = new Map<Id, UserTerritory2Association>();
            //find the territories
            for(UserTerritory2Association usrAssoctn : [SELECT UserId, RoleInTerritory2, Territory2.Internal_Territory_Name__c, Territory2.ParentTerritory2.Internal_Territory_Name__c, Territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c, Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c 
                                                        FROM UserTerritory2Association
                                                        WHERE UserId IN :assignedUserIds AND isActive = TRUE AND Territory2.Territory2Model.State='Active' AND RoleInTerritory2 = 'Account Executive']) {
                                                            userIdToTerritoryAssn.put(usrAssoctn.UserId, usrAssoctn);
                                                        }
            for(Event eve : newEvents){
                if(eve.WhoId == null && userIdToTerritoryAssn.containskey(eve.OwnerId) && eve.Type != TRANSFORMATION_TEAM_GENERATED_MEETING_TYPE){
                    assignETMAsTheUserETM(eve, userIdToTerritoryAssn.get(eve.OwnerId));
                }
                if(eve.WhoId != null && eve.WhoId.getSObjectType() == Contact.sobjectType){
                    if(userIdToTerritoryAssn.containskey(eve.OwnerId) && eve.Type != TRANSFORMATION_TEAM_GENERATED_MEETING_TYPE){
                        assignETMAsTheUserETM(eve, userIdToTerritoryAssn.get(eve.OwnerId));
                    }else if(contactMap.containskey(eve.WhoId)){
                        Contact conForTerritoryAssgn = contactMap.get(eve.WhoId);
                        eve.ETM_Territory__c = conForTerritoryAssgn.Account.ETM_Territory__c;
                        eve.ETM_Region__c = conForTerritoryAssgn.Account.ETM_Region__c;
                        eve.ETM_Area__c = conForTerritoryAssgn.Account.ETM_Area__c;
                        eve.ETM_Theatre__c = conForTerritoryAssgn.Account.ETM_Theatre__c;
                    }
                }else if(eve.WhoId != null && eve.WhoId.getSObjectType() == Lead.sobjectType){
                    if(leadMap.get(eve.WhoId).Winning_L2A_Account__c == null && userIdToTerritoryAssn.containskey(eve.OwnerId) && eve.Type != TRANSFORMATION_TEAM_GENERATED_MEETING_TYPE){
                        assignETMAsTheUserETM(eve, userIdToTerritoryAssn.get(eve.OwnerId));
                    }else if(leadMap.containskey(eve.WhoId) && leadMap.get(eve.WhoId).Winning_L2A_Account__c != null){
                        Lead leadForTerritoryAssgn = leadMap.get(eve.WhoId);
                        eve.ETM_Territory__c = leadForTerritoryAssgn.Winning_L2A_Account__r.ETM_Territory__c;
                        eve.ETM_Region__c = leadForTerritoryAssgn.Winning_L2A_Account__r.ETM_Region__c;
                        eve.ETM_Area__c = leadForTerritoryAssgn.Winning_L2A_Account__r.ETM_Area__c;
                        eve.ETM_Theatre__c = leadForTerritoryAssgn.Winning_L2A_Account__r.ETM_Theatre__c;
                    }
                }
            }
        }
    }

    /**
     * @description Assigns ETM (Event Territory Management) information to an Event based on the provided User-Territory association.
     * This method takes a single Event and its corresponding UserTerritory2Association record to populate ETM-related fields on the Event.
     * @param eve The Event record that needs ETM fields populated.
     * @param assn The UserTerritory2Association record containing territory and user details for assignment.
     * 
     */
    public void assignETMAsTheUserETM(Event eve, UserTerritory2Association assn){
        eve.ETM_Territory__c = assn.Territory2.Internal_Territory_Name__c;
        eve.ETM_Region__c = assn.Territory2.ParentTerritory2.Internal_Territory_Name__c;
        eve.ETM_Area__c = assn.Territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c;
        eve.ETM_Theatre__c = assn.Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c;
    }
    /**
     * @description Assigns the CDM (Customer Development Manager) name to Event records based on related Lead or Contact information.
     * This method determines the associated Account for each Event (through Lead or Contact), finds the corresponding Territory,
     * retrieves the active CDM user assigned to that Territory, and updates the Event with the CDM's name.
     * @param newEvents List of Event records being processed (typically from a before-insert or before-update trigger context).
     * @param leadMap Map of Lead IDs to Lead records for quick lookup when the Event is associated with a Lead.
     * @param contactMap Map of Contact IDs to Contact records for quick lookup when the Event is associated with a Contact.
     * 
     */
    public void assignCDMName(List<Event> newEvents, Map<Id, Lead> leadMap, Map<Id, Contact> contactMap) {
        if (newEvents != null || !newEvents.isEmpty()) {
            Set<Id> accountIdSet = new Set<Id>();
            Map<Event, Id> eventToAccountMap = new Map<Event, Id>();
            for (Event eve : newEvents) {
                if (eve.WhoId != null || eve.type == EventTriggerHelper.ISLM_MEETING_TYPE) {
                    Id accountId = null;
                    Schema.SObjectType whoIdType = eve.WhoId.getSObjectType();
                    if (whoIdType == Contact.sObjectType) {
                        Contact con = contactMap.get(eve.WhoId);
                        if (con != null) {
                            accountId = con.AccountId;
                        }
                    } else if (whoIdType == Lead.sObjectType) {
                        Lead ld = leadMap.get(eve.WhoId);
                        if (ld != null) {
                            accountId = ld.Winning_L2A_Account__c;
                        }
                    }
                    if (accountId != null) {
                        accountIdSet.add(accountId);
                        eventToAccountMap.put(eve, accountId);
                    }
                }
            }
            if (!accountIdSet.isEmpty()) {
                Map<Id, String> accountIdToUserName = new Map<Id, String>();
                for (Territory2 terr : [
                    SELECT Id,
                            (SELECT UserId, User.Name FROM UserTerritory2Associations
                            WHERE IsActive = true AND RoleInTerritory2 = 'CDM - DR Owner'
                            AND User.IsActive = true
                            LIMIT 1),
                            (SELECT ObjectId FROM ObjectTerritory2Associations
                            WHERE ObjectId IN :accountIdSet)
                    FROM Territory2
                    WHERE Id IN (
                        SELECT Territory2Id
                        FROM ObjectTerritory2Association
                        WHERE ObjectId IN :accountIdSet
                        AND Territory2.Territory2Model.State = 'Active'
                    )
                ]) {
                    if (!terr.UserTerritory2Associations.isEmpty()) {
                        String cdmUserName = terr.UserTerritory2Associations[0].User.Name;
                        for (ObjectTerritory2Association ota : terr.ObjectTerritory2Associations) {
                            accountIdToUserName.put(ota.ObjectId, cdmUserName);
                        }
                    }
                }
                for (Event eve : eventToAccountMap.keySet()) {
                    Id accountId = eventToAccountMap.get(eve);
                    String cdmName = accountIdToUserName.get(accountId);
                    if (cdmName != null) {
                        eve.CDM_Name__c = cdmName;
                    }
                }
            }
        }
    }

    /**
     * @description Sets a default value for the Event Type field on Event records before insertion.
     * 
     * @param newEvents List of Event records being processed (typically from a before-insert trigger context).
     * 
     */
    public void setDefaultEventType(List<Event> newEvents){
        Profile currentUserProfile = [SELECT Id,Name FROM Profile WHERE Id =: userInfo.getProfileId() LIMIT 1];
        if(currentUserProfile.Name == 'Rubrik Marketing User'){
            for(Event evt : newEvents){
                if(evt.Type == null){
                    evt.Type = EventTriggerHelper.MGM_MEETING_TYPE;
                }
            }
        }
    }
    /**
     * @description Validates Event records to check for the presence of an NBM (Next Best Meeting) scenario.
     * 
     * @param newEvents List of Event records being processed (typically from a trigger context).
     * 
     */
    public void checkNBM(List<Event> newEvents) {
        
        for(Event evt : newEvents){
            if(evt.Created_Through_Quick_Action__c || EventTriggerHelper.MGM_MEETING_TYPE == evt.Type || UserInfo.getName() == 'OutReach Integration User'){
                evt.NBM_Complete__c = 'Yes';
            }
        }
    }
    /**
     * @description Updates completion-related fields on Event records during an update operation.
     * 
     * @param newEvents List of Event records being updated (typically from a trigger context).
     * @param oldEvents Map of Event IDs to their previous versions for detecting changes.
     * 
     */
    public void updateCompletionAttributes(List<Event> newEvents, Map<Id,Event> oldEvents){
        // Run Meeting Chaclled Status//
        for(Event eve : newEvents){
            // Meeting  Cancel Condition//
            if(oldEvents.get(eve.Id).Post_Meeting_Status__c != eve.Post_Meeting_Status__c) {
                if (EventTriggerHelper.CANCELLED_MEETING_OUTCOME == eve.Post_Meeting_Status__c 
                || EventTriggerHelper.OPPTYSOURCED_MEETING_OUTCOME == eve.Post_Meeting_Status__c
                || EventTriggerHelper.NOOPPTYSOURCED_MEETING_OUTCOME == eve.Post_Meeting_Status__c){
                    if(eve.Completed_By__c ==null){
                        eve.Completed_By__c= UserInfo.getFirstName() +' ' +UserInfo.getLastName();
                        eve.Completed_Date__c = Date.today();
                    }
                }
                if( EventTriggerHelper.CANCELLED_MEETING_OUTCOME == eve.Post_Meeting_Status__c && eve.Event_Status__c =='Not Started' ) 
                    eve.Event_Status__c ='Cancelled';
                if(EventTriggerHelper.CANCELLED_MEETING_OUTCOME != eve.Post_Meeting_Status__c) 
                    eve.Event_Status__c='Completed';
            }  
        }
    }

    /*public void updateInsideSalesPoints(List<Event> newEvents, Map<Id,Event> oldEvents) {
        for(Event eve : newEvents){
            // Meeting  Cancel Condition//
            if( (oldEvents.get(eve.Id).Post_Meeting_Status__c != eve.Post_Meeting_Status__c
                || oldEvents.get(eve.Id).WhatId != eve.WhatId)
                && EventTriggerHelper.ISLM_MEETING_TYPE == eve.Type
                && EventTriggerHelper.CANCELLED_MEETING_OUTCOME != eve.Post_Meeting_Status__c 
                && eve.Qualification_Complete__c && !eve.Excluded__c) {
                if( eve.WhatId != null &&  eve.RelatedtoObject__c=='Opportunity'  
                    && (eve.Meeting_Type__c=='Net New' || eve.Meeting_Type__c=='Unverified') ) {
                        eve.Inside_Sales_Points__c=1;
                }
                else 
                    eve.Inside_Sales_Points__c=0.5;
            }
        }
    }*/
    /**
     * @description Stamps or updates a custom date field on Event records based on related Opportunity data or Event changes.
     * 
     * @param newEvents List of Event records being processed (typically from an update trigger context).
     * @param oldEvents Map of old Event records keyed by their IDs, used to detect field changes.
     * 
     */
    public void stampOpportunityDate(List<Event> newEvents, Map<Id,Event> oldEvents){
        for(Event eve : newEvents){
            if(eve.WhatId!=null && eve.WhatId!=oldEvents.get(eve.Id).WhatId
                && eve.WhatId.getSObjectType() == Opportunity.sobjectType
                && (oldEvents.get(eve.Id).WhatId==null || oldEvents.get(eve.Id).WhatId.getSObjectType() != Opportunity.sobjectType)){
                    eve.Opportunity_Stamp_Date__c = Datetime.now();
            }
        }
    }
    /**
     * @description Updates related Lead and Contact records after Event insertion.
     * 
     * @param newEvents List of Event records being processed (typically from an after-insert trigger context).
     * 
     */
    public void updateLeadAndContactsAfterInsert(List<Event> newEvents) {
        Map<Id, Lead> leadsToUpdate = new Map<Id, Lead>();
        Map<Id, Contact> contactsToUpdate = new Map<Id, Contact>();

        List<Event> leadEventsNBM = new List<Event>();
        List<Event> contactEventsNBM = new List<Event>();
        List<Event> stampMeetingCategoryEvents = new List<Event>();
        
        Set<Id> contactIdsForNBM = new Set<Id>();
        Set<Id> leadIdsForNBM = new Set<Id>();

        for(Event eve : newEvents) {
            if(eve.NBM_Complete__c == 'Yes') {
                stampMeetingCategoryEvents.add(eve);
                if(eve.WhoId.getSObjectType() == Contact.sobjectType){
                    contactEventsNBM.add(eve);
                    contactIdsForNBM.add(eve.WhoId);
                }
                else if(eve.WhoId.getSObjectType() == Lead.sobjectType){
                    leadEventsNBM.add(eve);
                    leadIdsForNBM.add(eve.WhoId);
                }
            }
        }
        if(!stampMeetingCategoryEvents.isEmpty()){
            stampMeetingCatForLeadContact(stampMeetingCategoryEvents, leadsToUpdate, contactsToUpdate);
        }
        if(!contactEventsNBM.isEmpty()) {
            checkNBMForContacts(contactEventsNBM, contactIdsForNBM, contactsToUpdate);
        }
        if(!leadEventsNBM.isEmpty()){
            checkNBMForLeads(leadEventsNBM, leadIdsForNBM, leadsToUpdate);
        }

        if(!contactsToUpdate.isEmpty()) {
            update contactsToUpdate.values();
        }
        if(!leadsToUpdate.isEmpty()) {
            update leadsToUpdate.values();
        }
    }
    /**
     * @description Updates related Lead and Contact records after Event records have been updated.
     * @param newEvents List of updated Event records from the trigger context.
     * @param oldEvents Map of old Event records keyed by their Ids for comparison.
     * 
     */
    public void updateLeadAndContactsAfterUpdate(List<Event> newEvents, Map<Id,Event> oldEvents) {
        Map<Id, Lead> leadsToUpdate = new Map<Id, Lead>();
        Map<Id, Contact> contactsToUpdate = new Map<Id, Contact>();

        List<Event> leadEventsNBM = new List<Event>();
        List<Event> contactEventsNBM = new List<Event>();
        List<Event> deactivateLeadEvents = new List<Event>();
        List<Event> deactivateContactEvents = new List<Event>();
        List<Event> completedLeadEvents = new List<Event>();
        List<Event> completedContactEvents = new List<Event>();
        List<Event> stampMeetingCategoryEvents = new List<Event>();
        
        Set<Id> contactIdsForNBM = new Set<Id>();
        Set<Id> contactIdsToDeactivate = new Set<Id>();
        Set<Id> leadIdsForNBM = new Set<Id>();

        for(Event eve : newEvents) {
            if(eve.NBM_Complete__c == 'Yes' && 
            (eve.Meeting_Category__c != oldEvents.get(eve.Id).Meeting_Category__c ||
             eve.NBM_Complete__c != oldEvents.get(eve.Id).NBM_Complete__c)){
                stampMeetingCategoryEvents.add(eve);
            }
            
            if( eve.NBM_Complete__c == 'Yes' && eve.NBM_Complete__c != oldEvents.get(eve.Id).NBM_Complete__c) {
                //Trigger NBM flow
                if(eve.WhoId.getSObjectType() == Contact.sobjectType){
                    contactEventsNBM.add(eve);
                    contactIdsForNBM.add(eve.WhoId);
                }
                else if(eve.WhoId.getSObjectType() == Lead.sobjectType){
                    leadEventsNBM.add(eve);
                    leadIdsForNBM.add(eve.WhoId);
                }
            }

            if(eve.Post_Meeting_Status__c != oldEvents.get(eve.Id).Post_Meeting_Status__c  && eve.NBM_Complete__c == 'Yes') {
                if(eve.WhoId.getSObjectType() == Contact.sobjectType){
                    //Trigger completion flow
                    completedContactEvents.add(eve);
                }
                else if(eve.WhoId.getSObjectType() == Lead.sobjectType){
                    completedLeadEvents.add(eve);
                }
                if(EventTriggerHelper.OPPTYSOURCED_MEETING_OUTCOME ==eve.Post_Meeting_Status__c) {
                    //Trigger NBM flow
                    if(eve.WhoId.getSObjectType() == Contact.sobjectType){
                        contactEventsNBM.add(eve);
                        contactIdsForNBM.add(eve.WhoId);
                    }
                    else if(eve.WhoId.getSObjectType() == Lead.sobjectType){
                        leadEventsNBM.add(eve);
                        leadIdsForNBM.add(eve.WhoId);
                    }    
                }   
                else if( EventTriggerHelper.NOOPPTYSOURCED_MEETING_OUTCOME == eve.Post_Meeting_Status__c
                    || EventTriggerHelper.CANCELLED_MEETING_OUTCOME == eve.Post_Meeting_Status__c) {  
                    if(eve.WhoId.getSObjectType() == Contact.sobjectType){
                        //Trigger no interest flow
                        deactivateContactEvents.add(eve);
                        contactIdsToDeactivate.add(eve.WhoId);
                    }
                    else if(eve.WhoId.getSObjectType() == Lead.sobjectType){
                        deactivateLeadEvents.add(eve);
                    }       
                }
            }
        }
        if(!stampMeetingCategoryEvents.isEmpty()){
            stampMeetingCatForLeadContact(stampMeetingCategoryEvents, leadsToUpdate, contactsToUpdate);
        }
        if(!contactEventsNBM.isEmpty()) {
            checkNBMForContacts(contactEventsNBM, contactIdsForNBM, contactsToUpdate);
        }
        if(!leadEventsNBM.isEmpty()){
            checkNBMForLeads(leadEventsNBM, leadIdsForNBM, leadsToUpdate);
        }
        if(!completedContactEvents.isEmpty()){
            updateCompletionAttributesOnContact(completedContactEvents, contactsToUpdate);
        }
        if(!completedLeadEvents.isEmpty()){
            updateCompletionAttributesOnLead(completedLeadEvents, leadsToUpdate);
        }
        if(!deactivateLeadEvents.isEmpty()) {
            deactivateLeads(deactivateLeadEvents, leadsToUpdate);
        }
        if(!deactivateContactEvents.isEmpty()) {
            deactivateContacts(deactivateContactEvents, contactIdsToDeactivate, contactsToUpdate);
        }
        if(!contactsToUpdate.isEmpty()) {
            update contactsToUpdate.values();
        }
        if(!leadsToUpdate.isEmpty()) {
            update leadsToUpdate.values();
        }
    }
    private void stampMeetingCatForLeadContact(List<Event> events, Map<Id, Lead> leadsToUpdate ,Map<Id, Contact> contactsToUpdate){
        Set<String> meetingTypes = new Set<String>{FSLM_MEETING_TYPE, TRANSFORMATION_TEAM_GENERATED_MEETING_TYPE};
        for(Event eve : events){
            if(eve.WhoId.getSObjectType() == Contact.sobjectType){
                Contact con = contactsToUpdate.containsKey(eve.WhoId) ? contactsToUpdate.get(eve.WhoId) : new Contact(Id = eve.WhoId);
                if(meetingTypes.contains(eve.Type)){
                    con.Meeting_Category__c = eve.Meeting_Category__c;
                    contactsToUpdate.put(con.Id, con);
                }
            }else if(eve.WhoId.getSObjectType() == Lead.sobjectType){
                Lead led =  leadsToUpdate.containsKey(eve.WhoId) ? leadsToUpdate.get(eve.WhoId) : new Lead(Id = eve.WhoId);
                if(meetingTypes.contains(eve.Type)){
                    led.Meeting_Category__c = eve.Meeting_Category__c;
                    leadsToUpdate.put(led.Id, led);
                }
            }
        }
    }
    private void checkNBMForContacts(List<Event> events, Set<Id> contactIds,  Map<Id, Contact> contactsToUpdate ){
        Map<Id, Contact> conIdToRec = new Map<Id, Contact>([SELECT Id, Contact_Status__c 
                                                            FROM Contact WHERE Id IN :contactIds
                                                            AND Account.RecordType.Name != 'Partner/Distributor']);

        for(Event eve : events){
            if(conIdToRec.get(eve.WhoId) != null) {
                Contact con = contactsToUpdate.containsKey(eve.WhoId) ? contactsToUpdate.get(eve.WhoId) : conIdToRec.get(eve.WhoId);

                con = updateMeetingInfo(con, eve);
                con.ContactRejectReason__c = '';
                con.NBM_Complete__c = eve.NBM_Complete__c=='Yes';

                if('Active Opportunity (System Use)' != conIdToRec.get(eve.WhoId).Contact_Status__c)
                    con.Contact_Status__c = 'Meeting Set';
                contactsToUpdate.put(con.Id, con);
            }
        }
    }
    //NBM Flow for leads
    private void checkNBMForLeads(List<Event> events, Set<Id> leadIds, Map<Id, Lead> leadsToUpdate){
        Map<Id, Lead> leadIdToRec = new Map<Id, Lead>([SELECT Id, Winning_L2A_Account__r.Account_Status__c 
                                                        FROM Lead WHERE Id IN :leadIds
                                                        AND  Winning_L2A_Account__r.RecordType.Name != 'Partner/Distributor']);

        for(Event eve : events){
            if(leadIdToRec.get(eve.WhoId) != null) {
                Lead led = leadsToUpdate.containsKey(eve.WhoId) ? leadsToUpdate.get(eve.WhoId) : leadIdToRec.get(eve.WhoId);

                led = updateMeetingInfo(led, eve);
                led = setFANFields(eve, led);
                led.Lead_Rejection_Reason__c = '';
                led.NBM_Complete__c = eve.NBM_Complete__c=='Yes';

                if('Active Opportunity (System Use)' != leadIdToRec.get(eve.WhoId).Winning_L2A_Account__r.Account_Status__c)
                    led.Status = 'Meeting Set';
                leadsToUpdate.put(led.Id, led);
            }
        }
        
    }
    private Lead setFANFields(Event eve, Lead tempLead) {
        tempLead.Current_Backup_Vendor__c=eve.Current_Backup_Vendor__c;
        tempLead.Need__c=eve.Need__c;
        tempLead.Persona__c=eve.Persona__c;
        tempLead.VM_Count__c=eve.VM_Count__c;
        tempLead.Product_Focus__c =eve.Product_Focus__c;
        tempLead.Why_is_this_problem_worth_solving_now__c =eve.Why_is_this_problem_worth_solving_now__c;
        return tempLead;
    }
    private void deactivateLeads(List<Event> deactivateEvents, Map<Id, Lead> leadsToUpdate) {
        for(Event eve : deactivateEvents) {
            Lead tempLead = leadsToUpdate.containsKey(eve.WhoId) ? leadsToUpdate.get(eve.WhoId) : new Lead(Id = eve.WhoId);

            //copy the meeting info
            tempLead = updateMeetingInfo(tempLead, eve);
            tempLead = setFANFields(eve, tempLead);

            tempLead.status = 'Nurture';
            tempLead.Lead_Rejection_Reason__c='Contacted/No Interest';
            tempLead.MQL__c = false;
            tempLead.SAL__c = false;
            tempLead.Partner_MQL__c = false;
            tempLead.UnMQL_Date__c=Date.today();
            tempLead.NBM_Complete__c = eve.NBM_Complete__c == 'Yes';
            
            leadsToUpdate.put(tempLead.Id, tempLead);
        }
    }
    private void deactivateContacts(List<Event> deactivateEvents, Set<Id> contactIdsToDeactivate, Map<Id, Contact> contactsToUpdate) {
        Map<Id, Contact> contactIdToRec = new Map<Id, Contact>([SELECT Id, Contact_Status__c FROM Contact WHERE Id IN :contactIdsToDeactivate]);
        //TODO: if not active opportunity
        for(Event eve : deactivateEvents) {
            Contact tempCon = contactsToUpdate.containsKey(eve.WhoId) ? contactsToUpdate.get(eve.WhoId) : new Contact(Id = eve.WhoId);
            //copy the meeting info
            tempCon = updateMeetingInfo(tempCon, eve);
            if('Active Opportunity (System Use)' != contactIdToRec.get(eve.WhoId).Contact_Status__c){
                tempCon.Contact_Status__c = 'Nurture';
                tempCon.ContactRejectReason__c='Contacted/No Interest';
                tempCon.MQL__c = false;
                tempCon.SAL__c = false;
                tempCon.Partner_MQL__c = false;
                tempCon.UnMQL_Date__c=Date.today();
                tempCon.Post_Meeting_Status__c = eve.Post_Meeting_Status__c;
                tempCon.NBM_Complete__c = eve.NBM_Complete__c == 'Yes';
            }
            contactsToUpdate.put(tempCon.Id, tempCon);
        }
    }
    /**
     * @description Removes child Event records from the provided list based on specific business rules.
     * @param newEventsList List of Event records being processed (typically from a trigger context).
     * 
     */
    public void removeChildEvent(List<Event> newEventsList){
        Set<Id> whoIdSet = new Set<Id>();
        for(Event ev : newEventsList){
            whoIdSet.add(ev.WhoId);
        }
        if(!whoIdSet.isEmpty()){
            deleteChildEventAsync(whoIdSet);
        }
    }
    //MKT22-271
    /**
     * @description Asynchronously deletes child Event records associated with the specified WhoIds.
     * @param eventWhoIdSet Set of WhoIds (Lead or Contact IDs) whose associated child Events should be deleted.
     * 
     */
    @future
    public static void deleteChildEventAsync(Set<Id> eventWhoIdSet){
        List<Event> childEventToRemoveList = new List<Event>(); 
        if(eventWhoIdSet!=null && !eventWhoIdSet.isEmpty()){
            for(Event eve : [SELECT ID,WhoId,IsChild,OwnerId,CreatedById,Type
                                FROM Event
                                WHERE WhoId IN: eventWhoIdSet]){
                if((EventTriggerHelper.MGM_MEETING_TYPE == eve.Type || EventTriggerHelper.ISLM_MEETING_TYPE ==eve.Type) && eve.OwnerId.equals(eve.CreatedById) && eve.IsChild){
                    childEventToRemoveList.add(eve);
                }
            }
        }
        if(!childEventToRemoveList.isEmpty()){
            delete childEventToRemoveList;
        }
    }
    /**
     * @description Clears or removes specific custom field values from Event records during update or delete operations.
     * @param oldEvents List of existing Event records before the update or delete operation.
     * 
     */
    public void removeEventInfo(List<Event> oldEvents){
        List<Lead> leadList = new List<Lead>();
        List<Contact> conList = new List<Contact>();
        List<Lead> delleadList = new List<Lead>();
        List<Contact> delconList = new List<Contact>();
        List<Event> eveList = new List<Event>();
        Set<Id> ldIdSet = new Set<Id>();
        Set<Id> conIdSet = new Set<Id>();
        Map<string,Lead> ldEveMap = new Map<string,Lead>();
        Map<string,Contact> conEveMap = new Map<string,Contact>();
        for(Event eve : oldEvents){
            if(eve.WhoId != null && eve.WhoId.getSObjectType().getDescribe().getName() == 'Lead'){
                ldIdSet.add(eve.WhoId);
            }
            if(eve.WhoId != null && eve.WhoId.getSObjectType().getDescribe().getName() == 'Contact'){
                conIdSet.add(eve.WhoId);
            }
        }
        leadList = [select Id,Meeting_Id__c,MeetingDate__c,Did_meeting_happen__c,Meeting_Completed_By__c,Meeting_Completed_Date__c,Post_Meeting_Status__c from Lead where Id IN:ldIdSet AND Meeting_Id__c != ''];
        conList = [select Id,Meeting_Id__c,MeetingDate__c,Did_meeting_happen__c,Meeting_Completed_By__c,Meeting_Completed_Date__c,Post_Meeting_Status__c from Contact where Id IN:conIdSet AND Meeting_Id__c != ''];
        for(Lead ld : leadList){
            if(ld.Meeting_Id__c != '')
                ldEveMap.put(ld.Meeting_Id__c,ld);
        }
        for(Contact con : conList){
            if(con.Meeting_Id__c != '')
                conEveMap.put(con.Meeting_Id__c,con);
        }
        for(Event eve : oldEvents){
            if(eve.WhoId != null && !ldEveMap.isEmpty() && ldEveMap.containskey(eve.Id)){
                Lead ld = new Lead();
                ld = ldEveMap.get(eve.Id);
                ld.Id=eve.WhoId;
                ld.Meeting_Id__c = '';
                ld.MeetingDate__c=null;
                ld.Meeting_Completed_By__c='';
                ld.Meeting_Completed_Date__c=null;
                ld.Post_Meeting_Status__c='';
                ld.NBM_Complete__c = false;
                ld.EventType__c = null;
                ld.SDR_Led__c = false;
                delleadList.add(ld);
            }
            if(eve.WhoId != null && !conEveMap.isEmpty() && conEveMap.containskey(eve.Id)){
                Contact con = new Contact();
                con = conEveMap.get(eve.Id);
                con.Id=eve.WhoId;
                con.Meeting_Id__c = '';
                con.MeetingDate__c=null;
                con.Meeting_Completed_By__c='';
                con.Meeting_Completed_Date__c=null;
                con.Post_Meeting_Status__c='';
                con.EventType__c = null;
                con.NBM_Complete__c = false;
                con.SDRLed__c = false;
                delconList.add(con);
            }
        }
        if(!delleadList.isEmpty()){
            flowControll.LeadTriggerHandler = false;
            update delleadList;
        } 
        if(!delconList.isEmpty()){
            flowControll.ContactTrigger = false;
            update delconList;
        }  
    }
    /**
     * @description Copies the value from the custom field 'Activity_Type__c' to the standard 'Type' field on Event records.
     * @param newEvents List of Event records being processed (typically from a before-insert or before-update trigger context).
     * 
     */
    public void copyActivityTypeToType(List<Event> newEvents){
        for(Event evt : newEvents){
            if(evt.Activity_Type__c != null)
                evt.Type = evt.Activity_Type__c;
        }
    }
    private Lead updateMeetingInfo(Lead led, Event eve) {
        led.Meeting_Id__c = eve.Id;
        led.MeetingDate__c = eve.StartDateTime;
        led.Created_Through_Quick_Action__c = eve.Created_Through_Quick_Action__c;
        led.EventType__c = eve.Type;
        led.Post_Meeting_Status__c = eve.Post_Meeting_Status__c;
        led.Last_Updated_Meeting_Date__c = Datetime.now();
        return led;
    }
    private Contact updateMeetingInfo(Contact con, Event eve) {
        con.Meeting_Id__c = eve.Id;
        con.MeetingDate__c = eve.StartDateTime;
        con.Created_Through_Quick_Action__c = eve.Created_Through_Quick_Action__c;
        con.EventType__c = eve.Type;
        con.Post_Meeting_Status__c = eve.Post_Meeting_Status__c;
        con.SDRLed__c = (eve.Type == EventTriggerHelper.ISLM_MEETING_TYPE && eve.Post_Meeting_Status__c!=null && EventTriggerHelper.CANCELLED_MEETING_OUTCOME != eve.Post_Meeting_Status__c);
        con.Last_Updated_Meeting_Date__c = DateTime.now();
        return con;
    }
    private void updateCompletionAttributesOnLead(List<Event> completedEvents, Map<Id, Lead> leadsToUpdate){
        for(Event eve : completedEvents) {
            Lead led = leadsToUpdate.containsKey(eve.WhoId) ? leadsToUpdate.get(eve.WhoId) : new Lead(Id = eve.WhoId);    
            led.Meeting_Completed_By__c = eve.Completed_By__c;
            led.Meeting_Completed_Date__c = eve.Completed_Date__c;
            led.SDR_Led__c = (eve.Type == EventTriggerHelper.ISLM_MEETING_TYPE && eve.Post_Meeting_Status__c!=null && EventTriggerHelper.CANCELLED_MEETING_OUTCOME != eve.Post_Meeting_Status__c);
            leadsToUpdate.put(led.Id, led);
        }
    }
    private void updateCompletionAttributesOnContact(List<Event> completedEvents, Map<Id, Contact> contactsToUpdate){
        for(Event eve : completedEvents) {
            Contact con = contactsToUpdate.containsKey(eve.WhoId) ? contactsToUpdate.get(eve.WhoId) : new Contact(Id = eve.WhoId);    

            con.Meeting_Completed_By__c = eve.Completed_By__c;
            con.Meeting_Completed_Date__c = eve.Completed_Date__c;

            contactsToUpdate.put(con.Id, con);
        }
    }
    /**
     * @description Sets the Meeting Type on Event records that represent ISL-booked meetings.
     * @param newEvents List of Event records being processed (typically from a before-insert or before-update trigger context).
     * 
     */
    public void setMeetingTypeForISLBookedMeetings(List<Event> newEvents){ 
        Set<Id> whoIds = new Set<Id>();        
        if(!newEvents.isEmpty()){
            for(Event eve: newEvents){
                if(eve.Type == EventTriggerHelper.ISLM_MEETING_TYPE){
                    whoIds.add(eve.WhoId);
                }
            }
        }
        List<Event> eventQueryForEventsInCurrentQuarter = new List<Event>();
        if(!whoIds.isEmpty()){
            eventQueryForEventsInCurrentQuarter = [SELECT Id, WhoId, Event_Status__c, Completed_Date__c,StartDateTime FROM Event WHERE Type =: EventTriggerHelper.ISLM_MEETING_TYPE AND (Completed_Date__c = THIS_FISCAL_QUARTER OR StartDateTime = THIS_FISCAL_QUARTER) AND WhoId IN: whoIds];
        }
        Map<Id, List<Event>> mapOfWhoWithCompletedEvents = new Map<Id, List<Event>>();
        Map<Id, List<Event>> mapOfWhoWithOpenEvent = new Map<Id, List<Event>>();
        if(!eventQueryForEventsInCurrentQuarter.isEmpty()){
            for(Event eve1: eventQueryForEventsInCurrentQuarter){
                String eveCompleteDetails = '';
                if(eve1.Completed_Date__c != null){
                    eveCompleteDetails = GeneralUtility.determineFinancialYearAndQuarter(eve1.Completed_Date__c); 
                }
                
                String eveCreatedDetails = GeneralUtility.determineFinancialYearAndQuarter(date.newinstance(eve1.StartDateTime.year(), eve1.StartDateTime.month(), eve1.StartDateTime.day()));
                String todaysDetails = GeneralUtility.determineFinancialYearAndQuarter(System.today());
                
                //check for completed events
                if(eveCompleteDetails == todaysDetails && eve1.Event_Status__c == 'Completed'){
                    if(!mapOfWhoWithCompletedEvents.containsKey(eve1.WhoId)){
                        mapOfWhoWithCompletedEvents.put(eve1.WhoId, new List<Event>());
                    }
                    mapOfWhoWithCompletedEvents.get(eve1.WhoId).add(eve1);
                }
                if(eveCreatedDetails == todaysDetails && eve1.Event_Status__c != 'Completed' && eve1.Event_Status__c != 'Cancelled'){
                    if(!mapOfWhoWithOpenEvent.containsKey(eve1.WhoId)){
                        mapOfWhoWithOpenEvent.put(eve1.WhoId, new List<Event>());
                    }
                    mapOfWhoWithOpenEvent.get(eve1.WhoId).add(eve1);
                }
            }
        }
        if(!newEvents.isEmpty()){
            for(Event eve: newEvents){
                if(eve.Type == EventTriggerHelper.ISLM_MEETING_TYPE){
                    //not the 1st completed meeting in the current quarter
                    if(mapOfWhoWithCompletedEvents.containsKey(eve.WhoId)){
                        eve.Meeting_Type__c = 'Follow Up';
                    }
                    //not the 1st open meeting in the current quarter
                    else if(mapOfWhoWithOpenEvent.containsKey(eve.WhoId)){
                        eve.Meeting_Type__c = 'Unverified';
                    }else{
                        eve.Meeting_Type__c = 'Net New';
                    }
                }else{
                    eve.Meeting_Type__c = null;
                }
            }
        }
    }
    /**
     * @description Sets the Meeting Type on Event records when ISL (Inside Sales) meetings are marked as completed.
     * @param newEvents List of Event records being processed (typically from an update trigger context).
     * @param oldEvents Map of old Event records keyed by Id for detecting changes in status or other relevant fields.
     * 
     */
    public void setMeetingTypeForISLCompletedMeetings(List<Event> newEvents, Map<Id,Event> oldEvents){
        Set<Id> whoIds = new Set<Id>();
        if(!newEvents.isEmpty()){
            for(Event eve: newEvents){
                if(eve.Type == EventTriggerHelper.ISLM_MEETING_TYPE && eve.Event_Status__c == 'Completed' && oldEvents.get(eve.Id).Event_Status__c != 'Completed'){
                    whoIds.add(eve.WhoId);
                }
            }
        }
        List<Event> eventQueryToGetAllEvents = new List<Event>();
        if(!whoIds.isEmpty()){
            eventQueryToGetAllEvents = [SELECT Id, Event_Status__c, WhoId, Completed_Date__c,StartDateTime FROM Event WHERE Type =: EventTriggerHelper.ISLM_MEETING_TYPE AND WhoId IN: whoIds];
        }
        
        Map<Id, List<Event>> mapOfWhoWithCompletedEvents = new Map<Id, List<Event>>();
        Map<Id, List<Event>> mapOfWhoWithOpenEvent = new Map<Id, List<Event>>();
        if(!eventQueryToGetAllEvents.isEmpty()){
            for(Event evee: eventQueryToGetAllEvents){
                if(!oldEvents.containsKey(evee.Id)){
                    String eveFiscalDetail = '';
                    if(evee.Completed_Date__c != null){
                        eveFiscalDetail = GeneralUtility.determineFinancialYearAndQuarter(evee.Completed_Date__c);
                    }
                    String todaysDetail = GeneralUtility.determineFinancialYearAndQuarter(System.today());
                    //check for completed events
                    if(eveFiscalDetail == todaysDetail && evee.Event_Status__c == 'Completed'){
                        if(!mapOfWhoWithCompletedEvents.containsKey(evee.WhoId)){
                            mapOfWhoWithCompletedEvents.put(evee.WhoId, new List<Event>());
                        }
                        mapOfWhoWithCompletedEvents.get(evee.WhoId).add(evee);
                    }
                    if(evee.Event_Status__c != 'Completed' && evee.Event_Status__c != 'Cancelled'){
                        if(!mapOfWhoWithOpenEvent.containsKey(evee.WhoId)){
                            mapOfWhoWithOpenEvent.put(evee.WhoId, new List<Event>());
                        }
                        mapOfWhoWithOpenEvent.get(evee.WhoId).add(evee);
                    }
                }
            }
        }
        List<Event> updateAllOpenMeetings = new List<Event>();
        if(!newEvents.isEmpty()){
            for(Event ev: newEvents){
                if(ev.Type == EventTriggerHelper.ISLM_MEETING_TYPE && ev.Event_Status__c == 'Completed' && oldEvents.get(ev.Id).Event_Status__c != 'Completed'){                 
                    //not the 1st completed meeting in the current quarter
                    if(mapOfWhoWithCompletedEvents.containsKey(ev.WhoId)){
                        ev.Meeting_Type__c = 'Follow Up';
                    }
                    //it is the 1st completed meeting in the current quarter
                    else{
                        ev.Meeting_Type__c = 'Net New';
                        if(mapOfWhoWithOpenEvent.containsKey(ev.WhoId)){
                            updateAllOpenMeetings.addAll(mapOfWhoWithOpenEvent.get(ev.WhoId));
                        }
                    }
                }
            }
        }
        if(!updateAllOpenMeetings.isEmpty()){
            for(Event eve: updateAllOpenMeetings){
                eve.Meeting_Type__c = 'Follow Up';
            }
            update updateAllOpenMeetings;  
        }
    }
    /**
     * @description Updates the Meeting Status field on Event records based on specific business logic.
     * @param newEvents List of Event records being processed (typically from a trigger context).
     * @param oldEvents Map of old Event records keyed by Id, used to compare previous values for detecting changes.
     * 
     */
	public void setMeetingStatus(List<Event> newEvents, Map<Id,Event> oldEvents){ 
         if(!newEvents.isEmpty()){
            for(Event eve: newEvents){
                if(eve.MeetingCancelled__c == TRUE && eve.Post_Meeting_Status__c == null ){
                   eve.Post_Meeting_Status__c = 'Meeting Cancelled';
                   eve.Cancellation_reason__c = 'System Closed No Action';
                   eve.Event_Status__c = 'Cancelled';
                }
            }
        }
    }
	/**
     * @description Updates the custom field 'Owner_Email__c' on Event records based on the Event owner's email address.
     * @param newEvents List of new Event records being processed (typically from a trigger context).
     * @param oldEvents Map of old Event records keyed by Id, used for comparison during update operations.
     * 
     */
	public void updateOwnerEmail(List<Event> newEvents, Map<Id,Event> oldEvents) {
        Set<Id> bookedByIds = new Set<Id>();
        Map<Id, Event> eventsToUpdate = new Map<Id, Event>();
        for (Event newEvent : newEvents) {
            Event oldEvent = oldEvents.get(newEvent.Id);
            if (newEvent.type == EventTriggerHelper.ISLM_MEETING_TYPE && newEvent.SOPs_Selected_Owner__c != oldEvent.SOPs_Selected_Owner__c ) {
                eventsToUpdate.put(newEvent.Id, newEvent);
                bookedByIds.add(newEvent.SOPs_Selected_Owner__c);
            }
        }
        if (!bookedByIds.isEmpty()) {
            Map<Id, User> ownerMap = new Map<Id, User>([SELECT Id, Manager.Name, Manager.Email, Profile.Name FROM User WHERE Id IN :bookedByIds ]);
            for (Event eventToUpdate : eventsToUpdate.values()) {
                if (ownerMap.containsKey(eventToUpdate.SOPs_Selected_Owner__c)) {
                    eventToUpdate.OwnerManagerEmail__c = ownerMap.get(eventToUpdate.SOPs_Selected_Owner__c).Manager.Email;
                }
            }
        }
    }
}