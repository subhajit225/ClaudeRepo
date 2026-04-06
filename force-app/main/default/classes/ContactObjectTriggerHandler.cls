public class ContactObjectTriggerHandler extends TriggerManager.GenericTriggerHandler{

    public override void onBeforeInsert(List<sObject> newRecords) {
        List<Contact> newContactList = (List<Contact>) newRecords;
        for(Contact conObj: newContactList){
            ContactObjectTriggerHelper.fieldUpdates(conObj, null);
        }
        ContactObjectTriggerHelper.allowMax2PrimaryContactMail(newContactList, null);
         ContactObjectTriggerHelper.populateUTMTerm( newContactList, null );
         ContactObjectTriggerHelper.setMarketingOptInAndOut(newContactList, null);
        ContactObjectTriggerHelper.setPrivacyCompliance( newContactList, null);
        ContactObjectTriggerHelper.calculateLeadScore(newContactList, null);
        ContactObjectTriggerHelper.calculateMQLPriority(newContactList, null);
    }

    public override void onBeforeUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap) {
        Map<ID, Contact> oldRecMap = (Map<ID, Contact>) oldRecordsMap;
        Map<ID, Contact> newRecMap = (Map<ID, Contact>) newRecordsMap;
        Set<ID> meetingSetStatusContactIdSet = new Set<ID>();
        
        ContactObjectTriggerHelper.allowMax2PrimaryContactMail(newRecMap.values(), oldRecMap);
        for(Contact conObj: newRecMap.values()){
            if(conObj.Contact_Status__c != oldRecMap.get(conObj.id).Contact_Status__c && conObj.Contact_Status__c == 'Meeting Set'){
                meetingSetStatusContactIdSet.add(conObj.id);
            }
            ContactObjectTriggerHelper.fieldUpdates(conObj,oldRecMap.get(conObj.id));
            
        }

        Map<Id,CampaignMember> latestCampaignMap = new Map<Id,CampaignMember>();
        if(!meetingSetStatusContactIdSet.isEmpty()){
            //query for all the latest campaignMembers to where the Lead is added recently
            for(CampaignMember cm : [SELECT Id,CreatedDate,ContactID,CampaignId,Meeting_set__c FROM CampaignMember where ContactID in :meetingSetStatusContactIdSet order by ContactID,CreatedDate desc]){
                if(!latestCampaignMap.keyset().contains(cm.ContactID)){
                    cm.Meeting_set__c = true;
                    latestCampaignMap.put(cm.ContactID,cm);
                }
            }
        }
        
        Map<Id, CampaignMember> conTocmpMember = new Map<Id, CampaignMember>();
        for(CampaignMember cmpMem : [Select Id, Campaign.Routing_Method__c, ContactId FROM CampaignMember Where FCRM__FCR_QR__c = true and ContactId IN : newRecMap.keySet() order by createdDate desc]){
            if(!conTocmpMember.containsKey(cmpMem.ContactId)){
                conTocmpMember.put(cmpMem.ContactId, cmpMem);
            }
        }
        
        List<Contact> contactsList = new List<Contact>();
        for(Contact conObj: newRecMap.values()){
            if(latestCampaignMap.keySet().contains(conObj .Id)){
                conObj.Meeting_Set_Campaign_ID__c = latestCampaignMap.get(conObj.Id).CampaignId;
            }
            
            if(conObj.ReRoute_Contact__c && conObj.ReRoute_Contact__c != oldRecMap.get(conObj.Id).ReRoute_Contact__c
            ){
                conObj.Last_Applied_Routing_Modifier__c = conTocmpMember.containsKey(conObj.Id) && conTocmpMember.get(conObj.Id).Campaign != null   ? conTocmpMember.get(conObj.Id).Campaign.Routing_Method__c : 'MQL to SDR';
                //contactsList.add(conObj); 
            }
        }
        ContactObjectTriggerHelper.setLeadShareExpirationDate(newRecMap.values(), oldRecMap);
        ContactObjectTriggerHelper.captureOwnerProfile(newRecMap.values(), oldRecMap); 
         ContactObjectTriggerHelper.populateUTMTerm( newRecMap.values(), oldRecMap );
         ContactObjectTriggerHelper.setMarketingOptInAndOut(newRecMap.values(), oldRecMap);
        ContactObjectTriggerHelper.setPrivacyCompliance( newRecMap.values(), oldRecMap);
        ContactObjectTriggerHelper.calculateLeadScore(newRecMap.values(), oldRecMap);
        ContactObjectTriggerHelper.calculateMQLPriority(newRecMap.values(), oldRecMap);
        ContactObjectTriggerHelper.setContactRejectReasonBlank(newRecMap.values(), oldRecMap);
        
        if(!latestCampaignMap.isEmpty()){ 
            update latestCampaignMap.values();
        }
    }

    public override void onAfterInsert(Map<ID, sObject> newRecordsMap) {
        Map<ID, Contact> newRecMap = (Map<ID, Contact>) newRecordsMap;
        List<ID> portalContacts = new List<Id>();
        Map<id,String> domainAccountMap = new Map<id,String>();
        Map<String,Contact> newEmailContactMap = new Map<String,Contact>();

        Set<Id> contactList = new Set<Id>();
        Set<Id> etaAccountIdSet = new Set<Id>();
        for(Contact con : newRecMap.values()){
            if( con.Agreed_to_Edge_Trial_Agreement__c){
                contactList.add(con.id);
                if(con.AccountId != null){
                    etaAccountIdSet.add(con.AccountId);
                }
            }
            if(con.AccountId != null){
                if(con.create_Portal_User__c){
                    portalContacts.add(con.id);
                    if(String.isNotBlank(con.Email)){
                        newEmailContactMap.put(con.Email, con);
                    }
                }
                if(String.isNotBlank(con.Email) && con.Email.contains('@')){
                    domainAccountMap.put(con.AccountId, con.Email.substringAfter('@').toLowerCase());
                }
            }
        }
        ContactObjectTriggerHelper.manageEntitlement(newRecMap.values(), etaAccountIdSet);
        if(!contactList.isEmpty()){
            ContactObjectTriggerHelper.trialEdgeContact(contactList);
        }
        if(!domainAccountMap.isEmpty()){
            AccountServiceController.createNewDomain(domainAccountMap, false);
        }
        if(!portalContacts.isEmpty()){
            if(checkRecursive.runOnce() && !System.isFuture() && !System.isBatch()){
                ContactService.createPortalUser(portalContacts);
            }
        }
        
        //Commented as a part PRIT25-575 and 639. Code moved to UserTriggerHandler
        //ContactObjectTriggerHelper.updatePartnerRegRequest(newEmailContactMap);
        ContactObjectTriggerHelper.insertContactIntoCampaign(newRecMap.values(), newRecMap, true);//??
        ContactObjectTriggerHelper.RollUpOnAccToCon(newRecMap.values(), null);
    }

    public override void onAfterUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap) {
        Map<ID, Contact> oldRecMap = (Map<ID, Contact>) oldRecordsMap;
        Map<ID, Contact> newRecMap = (Map<ID, Contact>) newRecordsMap;

        List<ID> portalContacts = new List<Id>();
        //Map<id,String> domainAccountMap = new Map<id,String>();
        //Set<String> newConEmailSet = new Set<String>();

        Set<Id> contactList = new Set<Id>();
        Set<Id> existContactList = new Set<Id>();
        Set<Id> etaAccountIdSet = new Set<Id>();
        Map<String,Contact> newEmailContactMap = new Map<String,Contact>();
        List<Id> updatedCompanyContacts = new List<Id>();//PRIT25-91

        for(Contact con : newRecMap.values()){
            Contact oldContact = oldRecMap.get(con.id);
            if( con.Agreed_to_Edge_Trial_Agreement__c &&  !oldContact.Agreed_to_Edge_Trial_Agreement__c){
                existContactList.add(con.id);
                contactList.add(con.id);
                if(con.AccountId != null){
                    etaAccountIdSet.add(con.AccountId);
                }
            }

            if(con.AccountId != null){
                if(con.create_Portal_User__c && !oldContact.create_Portal_User__c){
                    portalContacts.add(con.id);
                    if(String.isNotBlank(con.Email)){
                        newEmailContactMap.put(con.Email, con);
                    }
                }
            }
            
            //PRIT25-91 - start
            if(con.AccountId != null && oldContact.AccountId != null && con.AccountId != oldContact.AccountId)
            {
                updatedCompanyContacts.add(con.Id);
            }
            //PRIT25-91 - end
            
            
            
        }
        ContactObjectTriggerHelper.manageEntitlement(newRecMap.values(), etaAccountIdSet);
        if(!contactList.isEmpty()){
            ContactObjectTriggerHelper.trialEdgeContact(contactList);
        }
        if(!portalContacts.isEmpty()){
            if(checkRecursive.runOnce() && !System.isFuture() && !System.isBatch()){
                ContactService.createPortalUser(portalContacts);
            }
        }
        
        //PRIT25-91 -start
        if(!updatedCompanyContacts.isEmpty()){
            ContactObjectTriggerHelper.checkPartnerContacts(updatedCompanyContacts);
        }
        //PRIT25-91 - end
        
        //Commented as a part PRIT25-575 and 639. Code moved to UserTriggerHandler
        //ContactObjectTriggerHelper.updatePartnerRegRequest(newEmailContactMap);
        ContactObjectTriggerHelper.rollupAccrediated(newRecMap.values(), oldRecMap);
        ContactObjectTriggerHelper.insertContactIntoCampaign(newRecMap.values(), oldRecMap, false);
        ContactObjectTriggerHelper.RollUpOnAccToCon(newRecMap.values(), oldRecMap);
        ContactObjectTriggerHelper.routeContacts(newRecMap.values(), oldRecMap);

    }
    public override void onAfterDelete(Map<ID, sObject> oldRecordsMap) {
        Map<ID, Contact> oldRecMap = (Map<ID, Contact>) oldRecordsMap;
        ContactObjectTriggerHelper.RollUpOnAccToCon(null, oldRecMap);
    }
}