/**
 * @description       : Helper class of DealRegistrationTrigger 
 * @author            : Harshit Garg
 * @group             : 
 * @last modified on  : 03-02-2026
 * @last modified by  : Harshit Garg
**/
public without sharing class DealRegistrationTriggerHelper{
    public static string allianceRecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Alliance').getRecordTypeId();
    public static string resellerRecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();
    public static string serviceDeliveryRecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByDeveloperName().get('Service_Delivery_Partner').getRecordTypeId(); // PRIT24-887
    public static string oemRecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('OEM').getRecordTypeId();
    public static string engagementRecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Engagement').getRecordTypeId(); //PRIT26-10
    //prit24-869-start
    public static string salesRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
    //prit24-869-end
    private Map<String, String> mapOfMapping;
    private Map<String, String> mapOfCountryCode;
    //PRIT26-255
    public static Set<Id> tbhManagerIds = new Set<Id>();
    public static Set<Id> tbhSkipLevelManagerIds = new Set<Id>();

    /**
     * @description To validate the deal request data
     * @param newList List of new records
     * @param oldMap Map of old records
     */
    public void validateDeals(List<Deal_Registration__c> newList, Map<Id, Deal_Registration__c> oldMap){
        Map<Id, List<Deal_Registration__c>> userIdToCheck = new Map<Id, List<Deal_Registration__c>>();
        List<String> profileWithAccessList = System.Label.DealRegProfileIds.split(';');
        List<String> userWithAccessList = System.Label.DealRegUserIds.split(';');
        Deal_Registration__c oldDrObj;
        Map<Id, Id> drToLeadIdMap = new Map<Id, Id>();
        List<Deal_Registration__c> dealsWithoutLead = new List<Deal_Registration__c>();
          
        for (Deal_Registration__c newDrObj : newList){
            oldDrObj = oldMap.get(newDrObj.Id);
            /* PRIT24-713 : START */
            if ((newDrObj.Deal_Registration_Status__c == 'Approved' || newDrObj.Deal_Registration_Status__c == 'Expired') && newDrObj.Opportunity__c != null && newDrObj.Company_Name__c != oldDrObj.Company_Name__c && !profileWithAccessList.contains(UserInfo.getProfileId())){
                newDrObj.addError('You are not allowed to change account name once DR is approved.');
            }
            if ((newDrObj.Deal_Registration_Status__c == 'Approved' || newDrObj.Deal_Registration_Status__c == 'Expired') && newDrObj.Opportunity__c != null && newDrObj.Partner_Lookup__c != oldDrObj.Partner_Lookup__c && !profileWithAccessList.contains(UserInfo.getProfileId())){
                newDrObj.addError('You are not allowed to change partner once DR is approved.');
            }
            if ((newDrObj.Deal_Registration_Status__c == 'Approved' || newDrObj.Deal_Registration_Status__c == 'Expired') && newDrObj.Opportunity__c != null && newDrObj.Distributor__c != oldDrObj.Distributor__c && !profileWithAccessList.contains(UserInfo.getProfileId())){
                newDrObj.addError('You are not allowed to change distributor once DR is approved.');
            }
            /* PRIT24-713 : END */
            if ((newDrObj.Deal_Registration_Status__c == 'Approved' || newDrObj.Deal_Registration_Status__c == 'Expired') && oldDrObj.Opportunity__c != null && newDrObj.Opportunity__c != null && newDrObj.Opportunity__c != oldDrObj.Opportunity__c && !profileWithAccessList.contains(UserInfo.getProfileId()) && !userWithAccessList.contains(UserInfo.getUserId())){
                newDrObj.addError('You are not allowed to change opportunity once DR is approved.');
            }
            if (oldDrObj.Deal_Registration_Status__c != newDrObj.Deal_Registration_Status__c && newDrObj.Deal_Registration_Status__c == 'Approved' && oldDrObj.Deal_Registration_Status__c != 'Expired' && newDrObj.Opportunity__c != null && newDrObj.Partner_Lookup__c == null){
                newDrObj.addError('DR approval not allowed without Partner Lookup');
            }
            
            if (oldDrObj.Lead__c != newDrObj.Lead__c && oldDrObj.Lead__c != null && newDrObj.Lead__c == null) {
                drToLeadIdMap.put(newDrObj.Id, oldDrObj.Lead__c);
                dealsWithoutLead.add(newDrObj);
            }
        }
        
        if (drToLeadIdMap.isEmpty()) {
            return;
        }

        Map<Id,Lead> convertedLeads = new Map<Id,Lead>([SELECT Id FROM Lead WHERE Id IN :drToLeadIdMap.values() AND IsConverted = TRUE]);
        if (convertedLeads.isEmpty()) {
            return;
        }

        for (Deal_Registration__c dr : dealsWithoutLead) {
            if(convertedLeads.containsKey(drToLeadIdMap.get(dr.Id))){
                 dr.addError('Cannot remove an already converted Lead');
            }
        }
        
    }
    
    /**
     * @description To enqueue PC_DealRegL2AMatch job for deals without company
     * @param newList List of new records
     */
    public void dealRegL2AMatch(List<Deal_Registration__c> newList){
        List<Deal_Registration__c> dealsWithoutCompany = new List<Deal_Registration__c>();
        for(Deal_Registration__c dr : newList){
            if(dr.Company_Name__c == null){
                dealsWithoutCompany.add(dr);
            }
        }
        
        if(!Test.isRunningTest() && !dealsWithoutCompany.isEmpty()){
            System.enqueueJob(new PC_DealRegL2AMatch(dealsWithoutCompany));
        }
    }

    /**
     * @description To enqueue PC_DealRegL2AMatch job for deals without company
     * @param newList List of new records
     * @param oldMap Map of old records
     */
    public void setExpiryDateExtension(List<Deal_Registration__c> newList, Map<Id, Deal_Registration__c> oldMap){
        Deal_Registration__c oldDrObj;
        Date newExpDate ;
        for (Deal_Registration__c newDrObj : newList){
            oldDrObj = oldMap.get(newDrObj.Id);
            //PRIT25-484 start
            if (newDrObj.Deal_Registration_Expiration__c != null 
                && newDrObj.Deal_Reg_Exp_Date__c == oldDrObj.Deal_Reg_Exp_Date__c
                && newDrObj.Deal_Registration_status__c != 'Pending Meeting' 
                && newDrObj.Deal_Registration_Extension_Request__c != 'Pending Meeting Ext. Req. for next 10 Days' 
                && newDrObj.Deal_Registration_Sub_Status__c != oldDrObj.Deal_Registration_Sub_Status__c 
                && newDrObj.Deal_Registration_Sub_Status__c == 'Extension Approved' 
                && newDrObj.Opportunity__c != null)
            {
                    newExpDate = oldDrObj.Deal_Registration_Status__c == 'Expired'? System.Today() : newDrObj.Deal_Reg_Exp_Date__c;
                    newDrObj.Deal_Reg_Exp_Date__c = newExpDate != null ? newExpDate + 45 : newDrObj.Deal_Registration_Expiration__c + 45;
                    newDrObj.Deal_Registration_Status__c = 'Approved';
            }
            
            if (oldDrObj.Deal_Registration_Status__c == newDrObj.Deal_Registration_Status__c 
                && String.isNotBlank(newDrObj.Deal_Registration_Extension_Request__c) 
                && oldDrObj.Deal_Registration_Extension_Request__c != newDrObj.Deal_Registration_Extension_Request__c 
                && newDrObj.Deal_Registration_Extension_Request__c == 'Pending Meeting Ext. Req. for next 10 Days' 
                && newDrObj.Deal_Registration_Status__c.equals('Pending Meeting'))
            {
                newDrObj.Deal_Reg_Exp_Date__c = newDrObj.Deal_Registration_Expiration__c != null ? newDrObj.Deal_Registration_Expiration__c.addDays(10) : newDrObj.Deal_Reg_Exp_Date__c.addDays(10);
            }

            //PRIT26-10
            if(newDrObj.recordTypeId == EngagementRecordTypeId 
               && oldDrObj.Deal_Registration_Status__c != newDrObj.Deal_Registration_Status__c 
               && newDrObj.Deal_Registration_Status__c.equals('Approved'))
            {
                newDrObj.Deal_Reg_Exp_Date__c = Date.today().addDays(90);
            }
        }
    }
    
    /**
     * @description To update lead and opportunity on deal registration status or expiration date change
     * @param newList List of new records
     * @param oldMap Map of old records
     */
    public void updateOldLeadAndOppty(List<Deal_Registration__c> newList, Map<Id, Deal_Registration__c> oldMap){
        Map<String, Deal_Registration__c> oppDrMap = new Map<string, Deal_Registration__c>();
        Deal_Registration__c oldDrObj;
        Map<String, String> leadStatusMap = new Map<String, String>();
        Map<String, Date> leadExpDateMap = new Map<String, Date>();
        for (Deal_Registration__c newDrObj : newList){
            oldDrObj = oldMap.get(newDrObj.Id);
            if (newDrObj.Lead__c != null && oldDrObj.Deal_Registration_Status__c != newDrObj.Deal_Registration_Status__c){
                leadStatusMap.put(newDrObj.Lead__c, newDrObj.Deal_Registration_Status__c);
            }
            if (newDrObj.Deal_Registration_Expiration__c != null && newDrObj.Lead__c != null && oldDrObj.Deal_Registration_Expiration__c != newDrObj.Deal_Registration_Expiration__c && newDrObj.Deal_Registration_Status__c == 'Pending Conversion'){
                leadExpDateMap.put(newDrObj.Lead__c, newDrObj.Deal_Registration_Expiration__c);
            }
            if (newDrObj.Primary_Deal_Registration__c && newDrObj.Deal_Registration_Expiration__c != null && newDrObj.Opportunity__c != null && oldDrObj.Deal_Registration_Expiration__c != newDrObj.Deal_Registration_Expiration__c && (newDrObj.Deal_Registration_Status__c == 'Approved' || newDrObj.Deal_Registration_Status__c == 'Expired')){//prit25-593
                oppDrMap.put(newDrObj.Opportunity__c, newDrObj);
            }
        }
        if (!oppDrMap.isEmpty()){
            //Updation of Opportunity's Expiry date
            DealRegistrationTriggerHelper.updateOpportunities(JSON.serialize(oppDrMap));
        }
        if (!leadStatusMap.isEmpty() || !leadExpDateMap.isEmpty()){
            updateLeads(leadStatusMap,leadExpDateMap);
        }
    }

    private void updateLeads(Map<String, String> leadStatusMap, Map<String, Date> leadExpDateMap){

        Map<Id,Lead> leadMap = new Map<Id,Lead>();

        if (leadStatusMap != null && !leadStatusMap.isEmpty()){
            for (Lead l : [SELECT Id, IsConverted, Deal_Reg_Approval_Status__c, Deal_Registration_Number__c
                               FROM Lead
                               WHERE Id IN :leadStatusMap.keySet() AND IsConverted = FALSE])
            {
                l.Deal_Reg_Approval_Status__c = leadStatusMap.get(l.Id);
                leadMap.put(l.Id, l);
            }
        }
        
        if (leadExpDateMap != null && !leadExpDateMap.isEmpty()){
            Lead leadRec;
            for(String leadId : leadExpDateMap.keySet()){
				leadRec = leadMap.containsKey(leadId) ? leadMap.get(leadId) : new Lead(Id = leadId);
                leadRec.copy_of_Deal_Reg_Expiry_Date__c = leadExpDateMap.get(leadId);
                leadMap.put(leadId, leadRec);
            }
        }
        
            
        if (!leadMap.isEmpty()){
            flowControll.LeadTriggerHandler = false;
            update leadMap.values();
        }    
    }

    /**
     * @description To update opportunity asynchronously
     * @param oppMapStr Serialized Map of opp id and deal reg record
     */
    @future
    public static void updateOpportunities(String oppMapStr){
        
        if(oppMapStr == null || String.isBlank(oppMapStr)){
            return;
        }
        Map<String, Deal_Registration__c> dealRegOppMap = (Map<String, Deal_Registration__c>)JSON.deserialize(oppMapStr,Map<String, Deal_Registration__c>.class);
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity opp;
        for (String oppId : dealRegOppMap.keySet()){
            opp = new Opportunity(Id = oppId);
            opp.Deal_Reg_Expiration_Date__c = dealRegOppMap.get(oppId).Deal_Registration_Expiration__c;
            opp.Deal_Reg_Approval_Status__c = dealRegOppMap.get(oppId).Deal_Registration_Status__c;
            oppList.add(opp);
        }
        
        if (!oppList.isEmpty()){
            flowControll.opportunityTriggerHandler = false;
            update oppList;
        }
    }

    /**
     * @description To convert the leads
     * @param newList List of new records
     * @param oldMap Map of old records
     */
    public void manageConvertedLeads(List<Deal_Registration__c> newList, Map<Id, Deal_Registration__c> oldMap){
        List<Deal_Registration__c> convertedDeals = new List<Deal_Registration__c>();
        
        List<Lead> leadListToUpsert = new List<Lead>();
        Lead leadRec;
        for (Deal_Registration__c vDealReg : newList){
            if ((vDealReg.Deal_Registration_Status__c == 'Pending Conversion') && (vDealReg.Deal_Registration_Status__c != oldMap.get(vDealReg.Id).Deal_Registration_Status__c)){
                convertedDeals.add(vDealReg);
                leadRec = copyDealRegToLead(vDealReg, new Lead());
                //PRIT24-358 - start
                if (vDealReg.Lead__c != null && vDealReg.Lead_Share_Campaign__c){
                    leadRec.Id = vDealReg.Lead__c;
                }
                leadListToUpsert.add(leadRec);
            }
        }
        if (leadListToUpsert.isEmpty()){
            return;
        }
        
        Database.UpsertResult[] upsertResult = Database.upsert(leadListToUpsert, false);
        for (Integer i = 0; i < upsertResult.size(); i++){
            if (upsertResult[i].isSuccess() && upsertResult[i].isCreated()){
                convertedDeals[i].Primary__c = true;
                convertedDeals[i].Lead__c = upsertResult[i].getId();
                convertedDeals[i].Conversion_Result__c = 'Lead Conversion Success!';
                convertedDeals[i].isConverted__c = true;
            }
        }
        FCRM.FCR_SupportAPI.setRepeatResponseUserForContext();  
    }

    @TestVisible
    private Lead copyDealRegToLead(Deal_Registration__c vDealReg, Lead vLead){
        if (mapOfMapping == null){
            mapOfMapping = new Map<String, String>();
            List<DealregLeadMapping__c> dealMappings = DealregLeadMapping__c.getAll().values();
            for (DealregLeadMapping__c mapping : dealMappings){
                mapOfMapping.put(mapping.Name, mapping.LeadFields__c);
            }
        }
        if (vLead == null){
            vLead = new Lead();
        }
        if (mapOfCountryCode == null){
            mapOfCountryCode = new Map<String, String>();
        }
        List<CodeWithCountry__c> countryCode = CodeWithCountry__c.getAll().values();
        for (CodeWithCountry__c c : countryCode){
            mapOfCountryCode.put(c.Country__c, c.Name);
        }
        for (String key : mapOfMapping.keySet()){
            String destinationField = mapOfMapping.get(key);
            Object sourceValue = vDealReg.get(key);
            vLead.put(destinationField, sourceValue);
            if (key == 'Country__c' && sourceValue != null){
                vLead.put('CountryCode', mapOfCountryCode.get((String) sourceValue));
            }
        }
        vLead.Deal_Registration__c = true;
        vLead.skipValidationRules__c = true;
        vLead.Sourcing_Partner__c = vDealReg.Partner_Lookup__c;
        if (vLead.LeadSource == null && !vDealReg.Lead_Share_Campaign__c){
            vLead.LeadSource = system.label.LEAD_SOURCE_CHANNEL;
        }
        return vLead;
    }

    /**
     * @description To update the related opportunity
     * @param newDRList List of new records
     * @param oldDRMap Map of old records
     */
    public void updateRelatedOpportunity(List<Deal_Registration__c> newDRList, Map<Id, Deal_Registration__c> oldDRMap){
        List<Opportunity> oppToUpdateList = new List<Opportunity>();
        List<Deal_Registration__c> allianceDRList = new List<Deal_Registration__c>();
        Map<Id, Opportunity> allianceDROpptyMap = new Map<Id, Opportunity>();
        List<Deal_Registration__c> resellerDRList = new List<Deal_Registration__c>();
        Map<Id, Opportunity> resellerDROpptyMap = new Map<Id, Opportunity>();
        //PRIT24-656
        List<Deal_Registration__c> oemDRList = new List<Deal_Registration__c>();
        Map<Id, Opportunity> oemDROpptyMap = new Map<Id, Opportunity>();
        //PRIT24-656
        List<Deal_Registration__c> sdpDRList = new List<Deal_Registration__c>();
        Map<Id, Opportunity> sdpDROpptyMap = new Map<Id, Opportunity>();
        Map<Id, Deal_Registration__c> oppIdDRMap = new Map<Id, Deal_Registration__c>();
        Set<Id> partnerAccOnNewDRIdSet = new Set<Id>();

        for (Deal_Registration__c dealReg : newDRList){
            if (oldDRMap.get(dealReg.Id).Deal_Registration_Status__c != dealReg.Deal_Registration_Status__c && dealReg.Deal_Registration_Status__c.equals('Approved') && !oldDRMap.get(dealReg.Id).Deal_Registration_Status__c.equals('Expired') && !oldDRMap.get(dealReg.Id).Deal_Registration_Status__c.equals('Pending Conversion') && dealReg.Opportunity__c != null){
                Opportunity opp = new Opportunity(
                    Id = dealReg.Opportunity__c
                );

                if (dealReg.Primary_Deal_Registration__c){
                    opp.Deal_Registration__c = true;
                    opp.Deal_Registration_Type__c = dealReg.Deal_Registration_Type__c;
                    opp.Deal_Reg_Approval_Status__c = dealReg.Deal_Registration_Status__c;
                    opp.Deal_Reg_Submitted_Date__c = dealReg.Deal_Reg_Submitted_Date__c;
                    opp.Deal_Reg_Approval_Timestamp__c = dealReg.Approval_Timestamp__c;
                    opp.Deal_Reg_Expiration_Date__c = dealReg.Deal_Registration_Expiration__c;
                    opp.Deal_Registration_Number__c = dealReg.Name;
                    opp.Partner_Rep_Phone_Number__c = dealReg.Partner_Rep_Phone_Number__c;
                    opp.Partner_Rep_Email_Address__c = dealReg.Partner_Rep_Email_Address__c;
                    opp.Opportunity_Details__c = dealReg.Opportunity_Details__c;
                    opp.Sourcing_Partner__c = dealReg.Partner_Lookup__c;
                    opp.Partner_Representative__c = dealReg.Partner_Rep__c;
                }
                
                opp.PS_Escalated_New__c = (oldDRMap.get(dealReg.Id).Deal_Registration_Sub_Status__c != dealReg.Deal_Registration_Sub_Status__c &&(dealReg.Deal_Registration_Sub_Status__c =='RVP Approved' || dealReg.Deal_Registration_Sub_Status__c =='RSM Approved'))?'Stage Gate':opp.PS_Escalated_New__c;

                if (dealReg.RecordTypeId == ResellerRecordTypeId){
                    resellerDRList.add(dealReg);
                    resellerDROpptyMap.put(opp.Id, opp);
                }else if (dealReg.RecordTypeId == AllianceRecordTypeId){
                    allianceDRList.add(dealReg);
                    allianceDROpptyMap.put(opp.Id, opp);
                }else if (dealReg.RecordTypeId == ServiceDeliveryRecordTypeId){
                    opp.PS_Escalated_New__c = ((oldDRMap.get(dealReg.Id).Deal_Registration_Sub_Status__c != dealReg.Deal_Registration_Sub_Status__c) && dealReg.GSI_NDA__c)?'GSI - NDA':opp.PS_Escalated_New__c;
                    sdpDRList.add(dealReg);
                    sdpDROpptyMap.put(opp.Id, opp);
                }else if (dealReg.RecordTypeId == OEMRecordTypeId){   //PRIT24-656
                    oemDRList.add(dealReg);
                    oemDROpptyMap.put(opp.Id, opp);
                }
                //PRIT24-656
                oppIdDRMap.put(dealReg.Opportunity__c, dealReg);
                partnerAccOnNewDRIdSet.add(dealReg.Partner_Lookup__c);
            }
        
        }
        
        
        
        
        if (!resellerDRList.isEmpty() && !resellerDROpptyMap.isEmpty()){
            oppToUpdateList = updateResellerInformation(resellerDRList, resellerDROpptyMap);
            //PRIT24-656
            addCustomerContactAsOppRole(resellerDRList, resellerDROpptyMap);
            //PRIT24-656
        }
        if (!allianceDRList.isEmpty() && !allianceDROpptyMap.isEmpty()){
            oppToUpdateList = updateAlliancePartnerInformation(allianceDRList, allianceDROpptyMap);
            //PRIT24-656
            addCustomerContactAsOppRole(allianceDRList, allianceDROpptyMap);
            //PRIT24-656
        }
        if (!sdpDRList.isEmpty() && !sdpDROpptyMap.isEmpty()){
            oppToUpdateList = updateSDPInformation(sdpDRList, sdpDROpptyMap);
            //PRIT24-656
            addCustomerContactAsOppRole(sdpDRList, sdpDROpptyMap);
            //PRIT24-656
        }
        //PRIT24-656
        if (!oemDRList.isEmpty() && !oemDROpptyMap.isEmpty()){
            addCustomerContactAsOppRole(oemDRList, oemDROpptyMap);
        }
        if (!oppToUpdateList.isEmpty()){
            flowControll.opportunityTriggerHandler = false;
            List<Opportunity> oppBeforeUpdateList = [SELECT Id, Partner_Lookup__c, Sourcing_Partner__c, Teaming_Partner__c,
                                                     Distributor_Lookup__c, Incumbent_Partner__c
                                                     FROM Opportunity
                                                     WHERE Id IN:oppToUpdateList];
            /* PRIT24-814 : START */
            Set<Id> oppIds = new Set<Id>();
            try{
                update oppToUpdateList;
                for(Opportunity opp : oppToUpdateList){
                    oppIds.add(opp.Id);
                }
                if (!oppIds.isEmpty()){
                    callOpportunityHelperMethods(oppBeforeUpdateList, oppIdDRMap, partnerAccOnNewDRIdSet, new Map<Id, Opportunity>(oppToUpdateList));
                }
            }catch(exception ex){
                insert new Custom_Error_Log__c(
                    Class__c = 'DealRegistrationTriggerHelper',
                    Exception_Message__c = ex.getMessage(),
                    Functionality__c = 'updateRelatedOpportunity'
                );
            }
            /* PRIT24-814 : END */
            flowControll.opportunityTriggerHandler = true;
        }
    }

    /* PRIT24-814 : START */
    /**
     * @description To invoke the opportunity trigger related methods
     * @param oppBeforeUpdteList List of opps before update
     * @param oppIdDealRegMap Map of deal records
     * @param partnerAccIdSet set of account Ids
     * @param newOppMap Map of new opp records
     */
    public static void callOpportunityHelperMethods(List<Opportunity> oppBeforeUpdteList, Map<Id, Deal_Registration__c> oppIdDealRegMap, Set<Id> partnerAccIdSet, Map<Id, Opportunity> newOppMap){
        Map<Id, Id> oppIdAccIdMap = new Map<Id, Id>();
        Map<Id, Account> accIdAccountMap = new Map<Id, Account>();
        Map<Id, Account> accIdAccountParamMap = new Map<Id, Account>();
        Set<String> oppIdOldAccIdNewAccIdSet = new Set<String>();
        Set<Id> oppIdFocusDeleteSet = new Set<Id>();
        Map<Id,Opportunity> newOpptyMap = new Map<Id,Opportunity>(); //PRIT25-750
        Map<Id,Opportunity> oldOpptyMap = new Map<Id,Opportunity>(); //PRIT25-750

        for (Account acc : [SELECT ID, RecordTypeId, Focused_Partner__c, OwnerId
                            FROM Account
                            WHERE Id IN:partnerAccIdSet]){
            accIdAccountMap.put(acc.Id, acc);
        }

        for (Opportunity opp : oppBeforeUpdteList){
            if (oppIdDealRegMap.containsKey(opp.Id) && oppIdDealRegMap.get(opp.Id).Partner_Lookup__c != null && accIdAccountMap.containsKey(oppIdDealRegMap.get(opp.Id).Partner_Lookup__c) && opp.Partner_Lookup__c != oppIdDealRegMap.get(opp.Id).Partner_Lookup__c){
                accIdAccountParamMap.put(oppIdDealRegMap.get(opp.Id).Partner_Lookup__c, accIdAccountMap.get(oppIdDealRegMap.get(opp.Id).Partner_Lookup__c));
                oppIdAccIdMap.put(opp.Id, oppIdDealRegMap.get(opp.Id).Partner_Lookup__c);
                oppIdFocusDeleteSet.add(opp.Id);
            }
            if(opp.Partner_Lookup__c != newOppMap.get(opp.Id).Partner_Lookup__c || opp.Sourcing_Partner__c != newOppMap.get(opp.Id).Sourcing_Partner__c || 
               opp.Distributor_Lookup__c != newOppMap.get(opp.Id).Distributor_Lookup__c){
                newOpptyMap.put(opp.Id,newOppMap.get(opp.Id));
                oldOpptyMap.put(opp.Id,opp);
            }
        }

        if (!oppIdFocusDeleteSet.isEmpty()){
            OpportunityObjectTriggerHelper.deleteShareOppfocusedPartnerAccount(oppIdFocusDeleteSet);
        }
        if (!oppIdAccIdMap.isEmpty() && !accIdAccountParamMap.isEmpty()){
            OpportunityObjectTriggerHelper.shareOppfocusedPartnerAccount(oppIdAccIdMap, accIdAccountParamMap);
        }
        if (!newOpptyMap.isEmpty()){
            OpportunityObjectTriggerHelper.syncOpportunityPartnerRelations(newOpptyMap,oldOpptyMap);
        }
    }

    /* PRIT24-814 : END */
    //PRIT24-656 - OEM/Reseller
    /**
     * @description To create the contact role records
     * @param dealRegList List of new records
     * @param oppMap Map of Opportunity records
     */
    public static void addCustomerContactAsOppRole(List<Deal_Registration__c> dealRegList, Map<Id, Opportunity> oppMap){
        try{
            Map<String, Id> emailWithAccIds = new Map<String, Id>();
            Map<Id, Deal_Registration__c> accIdDealRegMap = new Map<Id, Deal_Registration__c>();
            Map<String, Id> oppContactWithOpportunityId = new Map<String, Id>();
            List<Contact> conToInsert = new List<Contact>();
            Map<String, OpportunityContactRole> ocrToInsertMap = new Map<String, OpportunityContactRole>();

            //for Alliance/ServiceDelivery
            Map<Id, Id> oppIdToContactId = new Map<Id, Id>();
            Map<String, Id> oppConWithOppId = new Map<String, Id>();

            for (Deal_Registration__c dealReg : dealRegList){
                if (dealReg.RecordTypeId == ResellerRecordTypeId || dealReg.RecordTypeId == OEMRecordTypeId){
                    emailWithAccIds.put(dealReg.Email__c, dealReg.Company_Name__c);
                    accIdDealRegMap.put(dealReg.Company_Name__c, dealReg);
                }else if (dealReg.RecordTypeId == AllianceRecordTypeId || dealReg.RecordtypeId == ServiceDeliveryRecordTypeId){
                    oppConWithOppId.put(dealReg.Opportunity__c + '-' + dealReg.Primary_Contact__c, dealReg.Opportunity__c);
                    oppIdToContactId.put(dealReg.Opportunity__c, dealReg.Primary_Contact__c);
                }
            }
            
            String key;
            //if same email contact exist on any acc as deal reg email
            for (Contact c : [SELECT Id, Name, Email, AccountId, Account.RecordType.Name
                            FROM Contact
                            WHERE Email IN:emailWithAccIds.keySet() AND Email != null])
            {
                
                if (accIdDealRegMap.get(c.AccountId) != null && c.Email == accIdDealRegMap.get(c.AccountId).Email__c){
                    emailWithAccIds.remove(c.Email);
                    key = accIdDealRegMap.get(c.AccountId).Opportunity__c + '-' + c.Id;
                    if (!oppContactWithOpportunityId.containsKey(key)){
                        oppContactWithOpportunityId.put(key, accIdDealRegMap.get(c.AccountId).Opportunity__c);
                    }
                } else{
                    emailWithAccIds.remove(c.Email);
                }
            }

            //check if contact Role exists on Opportunity on DR
            if (!oppContactWithOpportunityId.isEmpty()){
                for (OpportunityContactRole ocr : [SELECT Id, ContactId, OpportunityId
                                                FROM OpportunityContactRole
                                                WHERE OpportunityId IN:oppContactWithOpportunityId.values()]){
                    key = ocr.OpportunityId + '-' + ocr.ContactId;
                    if (oppContactWithOpportunityId.containsKey(key)){
                        oppContactWithOpportunityId.remove(key);
                    }
                }
            }

            //create new Contact Role list to insert
            if (!oppContactWithOpportunityId.isEmpty()){
                for (String oppConId : oppContactWithOpportunityId.keySet()){
                    ocrToInsertMap.put(oppConId, new OpportunityContactRole(
                        OpportunityId = oppConId.split('-')[0], 
                        ContactId = oppConId.split('-')[1]
                    ));
                }
            }

            //check if remaining email associated to any lead
            List<Database.LeadConvert> leadConverts = new list<Database.LeadConvert>();
            Map<String, String> leadToAccId = new Map<String, String>();
            Map<Id, Lead> leadListToUpdateForConversion = new Map<Id, Lead>();
        
            for (Lead lead : [SELECT Id, Email, Status, OwnerId, Deal_Registration__c, Deal_Reg_Approval_Status__c
                              FROM Lead
                              WHERE Email IN:emailWithAccIds.keySet() AND isConverted = false]){
                if (lead.Status == 'RAW'){
                    lead.Status = 'Nurture';
                    lead.Lead_Rejection_Reason__c = 'Automated unMQL (Admin Only)';
                    leadListToUpdateForConversion.put(lead.Id, lead);
                }
                if (lead.Deal_Registration__c && lead.Deal_Reg_Approval_Status__c == 'Expired'){
                    lead.Deal_Registration__c = false;
                    leadListToUpdateForConversion.put(lead.Id, lead);
                }
                if (String.valueOf(lead.OwnerId).subString(0, 3) == '00G'){
                    lead.OwnerId = accIdDealRegMap.get(emailWithAccIds.get(lead.Email)).OwnerId;
                    leadListToUpdateForConversion.put(lead.Id, lead);
                }
                if (!leadListToUpdateForConversion.containsKey(lead.Id)){
                    Database.LeadConvert lc = new database.LeadConvert();
                    lc.setLeadId(lead.Id);
                    lc.setAccountId(emailWithAccIds.get(lead.Email));
                    lc.setDoNotCreateOpportunity(true);
                    lc.setConvertedStatus(lead.Status);
                    leadConverts.add(lc);
                    leadToAccId.put(lead.Id, emailWithAccIds.get(lead.Email));
                    emailWithAccIds.remove(lead.Email);
                }
            }

            //updating leads then converting them
            if (!leadListToUpdateForConversion.isEmpty()){
                flowControll.LeadTriggerHandler = false;
                flowControll.contactTrigger = false;
                list<Database.SaveResult> leadResults = Database.update (leadListToUpdateForConversion.values(), false);

                for (Lead lead : leadListToUpdateForConversion.values()){
                    Database.LeadConvert lc = new database.LeadConvert();
                    lc.setLeadId(lead.Id);
                    lc.setAccountId(emailWithAccIds.get(lead.Email));
                    lc.setDoNotCreateOpportunity(true);
                    lc.setConvertedStatus(lead.Status);
                    leadConverts.add(lc);
                    leadToAccId.put(lead.Id, emailWithAccIds.get(lead.Email));
                    emailWithAccIds.remove(lead.Email);
                }
            }

            //convertingLeads
            List<Database.LeadConvertResult> lcr = Database.convertLead(leadConverts);
            flowControll.LeadTriggerHandler = true;
            flowControll.contactTrigger = true;
        

            //insert opp contact role for converted leads
            if (!leadToAccId.isEmpty()){
                for (Lead lead : [SELECT Id, ConvertedContactId
                                from Lead
                                WHERE Id IN:leadToAccId.keySet()]){
                    if (accIdDealRegMap.containsKey(leadToAccId.get(lead.Id)) && lead.ConvertedContactId != null){
                        //PRIT24-711 - added contact id check
                        ocrToInsertMap.put(accIdDealRegMap.get(leadToAccId.get(lead.Id)).Opportunity__c + '-' + lead.ConvertedContactId, new OpportunityContactRole(
                            OpportunityId = accIdDealRegMap.get(leadToAccId.get(lead.Id)).Opportunity__c, 
                            ContactId = lead.ConvertedContactId
                        ));
                    }
                }
            }

            //no lead or Contact with email found then insert new contact and opp contact role
            if (!emailWithAccIds.isEmpty()){
                for (Id accId : emailWithAccIds.values()){
                    conToInsert.add(new Contact(
                        AccountId = accId, 
                        Email = accIdDealRegMap.get(accId).Email__c, 
                        FirstName = accIdDealRegMap.get(accId).FirstName__c, 
                        LastName = accIdDealRegMap.get(accId).LastName__c, 
                        Title = accIdDealRegMap.get(accId).Title__c, 
                        OwnerId = accIdDealRegMap.get(accId).OwnerId,  //dealRegOpp Owner
                        Phone = accIdDealRegMap.get(accId).Phone__c,  //PRIT24-725
                        LeadSource = 'Deal Registration Approval' //PRIT24-725
                    ));
                }
                insert conToInsert;

                for (Contact c : conToInsert){
                    String oppId = accIdDealRegMap.get(c.AccountId).Opportunity__c;
                    ocrToInsertMap.put(oppId + '-' + c.Id, new OpportunityContactRole(
                        OpportunityId = oppId, 
                        ContactId = c.Id
                    ));
                }
            }

            //for Alliance/ServiceDelivery
            for (OpportunityContactRole ocr : [SELECT Id, OpportunityId, ContactId
                                            FROM OpportunityContactRole
                                            WHERE OpportunityId IN:oppConWithOppId.values() AND ContactId IN:oppIdToContactId.values()]){
                String oppConId = ocr.OpportunityId + '-' + ocr.ContactId;
                if (oppConWithOppId.containsKey(oppConId)){
                    oppConWithOppId.remove(oppConId); //ocr exists
                }
            }
            if (!oppConWithOppId.isEmpty()){
                for (String oppConId : oppConWithOppId.keySet()){
                    ocrToInsertMap.put(oppConId, new OpportunityContactRole(
                        OpportunityId = oppConId.split('-')[0], 
                        ContactId = oppConId.split('-')[1]
                    ));
                }
            }

            if (!ocrToInsertMap.isEmpty()){
                insert ocrToInsertMap.values();
            }

        } catch (Exception e){
            //PRIT-24-711 - start
            Custom_Error_Log__c errorLogRec = new Custom_Error_Log__c(
                Class__c = 'DealRegistrationTriggerHelper',
                Exception_Message__c = e.getMessage(),
                Functionality__c = 'Deal Reg OCR Creation');
            insert errorLogRec;
            //PRIT-24-711 - end
        }
    }

    /**
     * @description To change the deal owner
     * @param oldDRMap Map of old deal records
     * @param newDRMap Map of new deal records
     */
    public void changeDROwner(Map<Id, Deal_Registration__c> oldDRMap, Map<Id, Deal_Registration__c> newDRMap){
        Set<Deal_Registration__c> drAccChangedIdSet = new Set<Deal_Registration__c>();
        Set<ID> accIdSet = new Set<ID>();

        for (Deal_Registration__c deal : newDRMap.values()){
            if ((ResellerRecordTypeId == deal.RecordTypeId || OEMRecordTypeId == deal.RecordTypeId || ServiceDeliveryRecordTypeId == deal.RecordTypeId) && String.isNotBlank(deal.Company_Name__c) && oldDRMap.get(deal.Id).Company_Name__c != deal.Company_Name__c && deal.Deal_Registration_Status__c != 'Approved' && deal.Deal_Registration_Status__c != 'Rejected' && deal.Deal_Registration_Status__c != 'Expired'){
                //prit24-900
                drAccChangedIdSet.add(deal);
                accIdSet.add(deal.Company_Name__c);
            }
            if ((ResellerRecordTypeId == deal.RecordTypeId || OEMRecordTypeId == deal.RecordTypeId) && oldDRMap.get(deal.Id).Deal_Registration_Status__c != deal.Deal_Registration_Status__c && deal.Deal_Registration_Status__c.equals('Pending Conversion') && String.isBlank(deal.Company_Name__c)){
                deal.OwnerId = System.Label.Sales_Data_Ops_Queue_Id;
            }
        }
        
        if(drAccChangedIdSet.isEmpty()){
            return;
        }
        
        Map<Id, Account> accMap = new Map<Id, Account>([SELECT ID, Name, OwnerId, Owner.Name, Owner.IsActive, Owner.ManagerId, Owner.Manager.isActive, Owner.Manager.ManagerId
                           FROM Account
                           WHERE ID IN:accIdSet]);
                           
        if(accMap.isEmpty()){
            return;
        }
        
        Account acc;
        for (Deal_Registration__c dr : drAccChangedIdSet){
            if(!accMap.containsKey(dr.Company_Name__c)){
                continue;
            }
            acc = accMap.get(dr.Company_Name__c);
            if (String.isNotBlank(acc.OwnerId) && acc.Owner.IsActive && String.isNotBlank(acc.Owner.Name)){
                dr.OwnerId = acc.Owner.Name.containsIgnoreCase(System.Label.PC_TBHUser) ? (acc.Owner.Manager.isActive ? acc.Owner.ManagerId : acc.Owner.Manager.ManagerId) : acc.OwnerId;
            }
        }
    }

    //PRIT25-192 : Update SDR/TVP if anytime owner of DR is changed
    /**
     * @description To populate actors
     * @param newDealRegList Map of old deal records
     * @param oldMap Map of Old deal records  
     * @param patchMap Map of Patch Managers
     */
    public void populateDRActors(List<Deal_Registration__c> newDealRegList, Map<Id, Deal_Registration__c> oldMap, Map<String, List<PatchManager__c>> patchMap){
        Set<Id> ownerIdSet = new Set<Id>();
        for (Deal_Registration__c deal : newDealRegList){
            if ((oldMap == null || deal.OwnerId != oldMap.get(deal.Id).OwnerId) && (deal.Deal_Registration_Status__c == 'Submitted' || deal.Deal_Registration_Status__c == 'Pending Meeting') && deal.RecordTypeId != EngagementRecordTypeId){
                ownerIdSet.add(deal.OwnerId);
            }
        }
        
        Map<Id,User> ownerIdManagerMap =  new Map<Id, User>([SELECT Id, ManagerId, Manager.ManagerId, Manager.Manager.ManagerId, Manager.isActive, Manager.Manager.isActive
                            FROM User WHERE Id = :ownerIdSet]);
                            
        Map<Id, User> presidentUsers = new Map<Id, User> ([SELECT Id, Business_Group__c, Name, UserRole.Name, Title FROM User WHERE Business_Group__c = 'GVP' AND Title LIKE '%president%']);
        
        User u;
        Id avpUserId;
        if (!ownerIdManagerMap.isEmpty()){
            for (Deal_Registration__c drObj : newDealRegList){

                PatchManager__c pmRec = PatchManager.assignDealReg(patchMap, drObj);
                drObj.PatchManager__c = pmRec != null ? pmRec.Id : null;
                
                //PRIT25-19 : Replace VP as Sarah King whenever Brian McCarthy is assigned as VP
                drObj.Theatre_VP__c = (drObj.Theatre_VP__c != null && drObj.Theatre_VP__c == System.Label.brianMcCarthyUserId)?System.Label.ExceptionalAMER:drObj.Theatre_VP__c;

                u = ownerIdManagerMap.get(drObj.OwnerId);
				
				if(u == null){
					continue;
                }
                //PRIT26-255
                drObj.Sales_Manager__c = (tbhManagerIds.contains(u.Id) || tbhSkipLevelManagerIds.contains(u.Id))?u.Id:(u.Manager.isActive ? u.ManagerId : u.Manager.ManagerId);

                drObj.Theatre_VP__c = tbhSkipLevelManagerIds.contains(u.Id)?u.Id:((tbhManagerIds.contains(u.Id) && u.Manager.isActive)?u.ManagerId:((tbhManagerIds.contains(u.Id) && !u.Manager.isActive)?((pmRec != null && pmRec.TLevel1__c == 'AMER') ? System.Label.ExceptionalAMER : System.Label.exceptionalEMEA_APAC) :((u.Manager.Manager.IsActive)?u.Manager.ManagerId:(pmRec != null && pmRec.TLevel1__c == 'AMER') ? System.Label.ExceptionalAMER : System.Label.exceptionalEMEA_APAC)));

                u = ownerIdManagerMap.get(drObj.OwnerId);
                
                if(u == null){
                    continue;
                }
                //PRIT26-255
                drObj.Sales_Manager__c = (tbhManagerIds.contains(u.Id) || tbhSkipLevelManagerIds.contains(u.Id))?u.Id:(u.Manager.isActive ? u.ManagerId : u.Manager.ManagerId);

                drObj.Theatre_VP__c = tbhSkipLevelManagerIds.contains(u.Id)?u.Id:((tbhManagerIds.contains(u.Id) && u.Manager.isActive)?u.ManagerId:((tbhManagerIds.contains(u.Id) && !u.Manager.isActive)?((pmRec != null && pmRec.TLevel1__c == 'AMER') ? System.Label.ExceptionalAMER : System.Label.exceptionalEMEA_APAC) :((u.Manager.Manager.IsActive)?u.Manager.ManagerId:(pmRec != null && pmRec.TLevel1__c == 'AMER') ? System.Label.ExceptionalAMER : System.Label.exceptionalEMEA_APAC)));

                if (!u.Manager.isActive && !u.Manager.Manager.IsActive){
                    drObj.Theatre_VP__c = (pmRec != null && pmRec.TLevel1__c == 'AMER') ? System.Label.ExceptionalAMER : System.Label.exceptionalEMEA_APAC;
                    drObj.Sales_Manager__c = (pmRec != null && pmRec.TLevel1__c == 'AMER') ? System.Label.ExceptionalAMER : System.Label.exceptionalEMEA_APAC;
                }
                
                //PRIT26-109 : Populate AVP
                
                avpUserId = u.Manager.Manager.ManagerId;
                if(!presidentUsers.containsKey(avpUserId) && avpUserId != System.Label.ExceptionalAMER && avpUserId != System.Label.exceptionalEMEA_APAC){
                    drObj.AVP__c = u.Manager.Manager.ManagerId;
                }
            }
        }
    }

    /**
     * @description To populate deal registration fields
     * @param newDRList List of deal records
     * @param oldDRMap Map of old deal records
     */
    public void setDealRegistrationParameters(List<Deal_Registration__c> newDRList, Map<Id, Deal_Registration__c> oldDRMap){
        Set<Id> accIds = new Set<Id>();
        List<Deal_Registration__c> dealRegWithAccounts = new List<Deal_Registration__c>();
        List<Deal_Registration__c> dealRegWithPartnerLookup = new List<Deal_Registration__c>();
        for (Deal_Registration__c dealReg : newDRList)
        {
            if (Trigger.isBefore && Trigger.isInsert && dealReg.Deal_Reg_Exp_Date__c == null && dealReg.Deal_Registration_Status__c == 'Submitted' && dealReg.Deal_Reg_Submitted_Date__c != null){
                dealReg.Deal_Reg_Exp_Date__c = Date.today().addDays(20); //prit26-285
            }
            
            if (dealReg.Partner_Lookup__c != null){
                accIds.add(dealReg.Partner_Lookup__c);
                dealRegWithPartnerLookup.add(dealReg);
            }
            
            if(String.isNotBlank(dealReg.Company_Name__c) && String.isNotBlank(dealReg.Deal_Registration_Status__c) 
               && (dealReg.Deal_Registration_Status__c == 'Submitted' || dealReg.Deal_Registration_Status__c == 'Pending Meeting')
               && (oldDRMap == null || dealReg.Deal_Registration_Status__c == oldDRMap.get(dealReg.Id).Deal_Registration_Status__c))
            {
                //deal has account
                accIds.add(dealReg.Company_Name__c);
                dealRegWithAccounts.add(dealReg);
            }else if(String.isBlank(dealReg.Company_Name__c) && String.isNotBlank(dealReg.Deal_Registration_Status__c) && String.isNotBlank(dealReg.Company__c)
                     && (oldDRMap == null || dealReg.Deal_Registration_Status__c == oldDRMap.get(dealReg.Id).Deal_Registration_Status__c) 
                     && (dealReg.Deal_Registration_Status__c.equals('Submitted') || dealReg.Deal_Registration_Status__c.equals('Pending Meeting')))
            {
                dealReg.Deal_Registration_Type__c = 'Partner Sourced New Logo (PSNL)';//'Partner Initiated Deal'; PRIT24-754
                dealReg.Registration_Type__c = 'Partner Sourced';//'PSNL'; PRIT24-754
            }else if((dealReg.RecordTypeId == ResellerRecordTypeId || (dealReg.RecordTypeId == AllianceRecordTypeId && dealReg.Alliance_Type__c == 'Cloud')) 
                     && String.isNotBlank(dealReg.Deal_Registration_Status__c) && String.isNotBlank(dealReg.Opportunity__c)
                     && (oldDRMap == null || dealReg.Deal_Registration_Status__c != oldDRMap.get(dealReg.Id).Deal_Registration_Status__c) 
                     && dealReg.Deal_Registration_Status__c == 'Approved' 
                     && (oldDRMap == null || oldDRMap.get(dealReg.Id).Deal_Registration_Status__c != 'Expired') 
                     && dealReg.Primary_Deal_Registration__c == false && dealReg.Deal_Registration_Type__c == 'Partner Sourced New Logo (PSNL)')
            {
                dealReg.Deal_Registration_Type__c = 'Rubrik Sourced';
                dealReg.Registration_Type__c = 'Value Add';
            }
        }
            
        //for deals with accounts
        if(accIds.isEmpty()) return;
        Map<Id, Account> accMap = new Map<Id, Account>([SELECT ID, Name, Type, Account_Status__c, MSP_Sub_Type__c, OwnerId, Owner.IsActive
                                                        FROM Account
                                                        WHERE ID IN : accIds]);
                                                        
        if(accMap.isEmpty()) return;
                                                        
        if(!dealRegWithAccounts.isEmpty()){
            setDealRegistrationType(dealRegWithAccounts,accMap);
        }
        
        if(!dealRegWithPartnerLookup.isEmpty()){
            populateGSIDealReg(dealRegWithPartnerLookup,accMap);
        }
    }
    
    private void setDealRegistrationType(List<Deal_Registration__c> dealRegWithAccounts, Map<Id, Account> accMap){
        if(dealRegWithAccounts == null || dealRegWithAccounts.isEmpty() || accMap == null || accMap.isEmpty()){
            return;
        }
        String accType;
        String accStatus;
        for(Deal_Registration__c deal : dealRegWithAccounts)
        {
            if(!accMap.containsKey(deal.Company_Name__c)){
                continue;
            }
            accType = accMap.get(deal.Company_Name__c).Type;
            accStatus = accMap.get(deal.Company_Name__c).Account_Status__c;
            if(accType == 'Customer' || accType == 'MSP-Reseller' || accType == 'MSP' || accType == 'MSP Customer'){
                deal.Deal_Registration_Type__c = accStatus == 'Existing Customer'?'Partner Sourced Expand':(accStatus == 'Prospect'?'Partner Sourced New Logo (PSNL)':(accStatus == 'Active Opportunity'?'Rubrik Sourced':null));
                deal.Registration_Type__c = accStatus == 'Existing Customer'?'Partner Sourced':(accStatus == 'Prospect'?'Partner Sourced':(accStatus == 'Active Opportunity'?'Value Add':null));
            }else if(accType == 'Prospect'){
                deal.Deal_Registration_Type__c = 'Partner Sourced New Logo (PSNL)';
                deal.Registration_Type__c = 'Partner Sourced';
            }
        }
    }
    
    //PRIT24-827 - start - populate GSI on Deal Registration && Global Account Manager
    private void populateGSIDealReg(List<Deal_Registration__c> dealRegWithPartnerLookup, Map<Id, Account> accMap){
        if(dealRegWithPartnerLookup == null || dealRegWithPartnerLookup.isEmpty() || accMap == null || accMap.isEmpty()){
            return;
        }

        for (Deal_Registration__c dr : dealRegWithPartnerLookup){
            if(!accMap.containsKey(dr.Partner_Lookup__c)){
                continue;
            }
            if (dr.Deal_Registration_Status__c != 'Approved' && dr.Deal_Registration_Status__c != 'Expired' && (dr.RecordTypeId == ServiceDeliveryRecordTypeId || dr.RecordTypeId == ResellerRecordTypeId) && accMap.get(dr.Partner_Lookup__c).MSP_Sub_Type__c == 'GSI'){
                dr.GSI_Deal_Registration__c = true;
                dr.Global_Account_Manager__c = dr.Global_Account_Manager__c == null?(accMap.get(dr.Partner_Lookup__c).Owner.isActive?accMap.get(dr.Partner_Lookup__c).OwnerId:Label.POB_Exception_UserId):dr.Global_Account_Manager__c;
            } else if(accMap.get(dr.Partner_Lookup__c).MSP_Sub_Type__c != 'GSI'){
                dr.GSI_Deal_Registration__c = false;
                dr.Global_Account_Manager__c = null;
            }
        }
    }

    /**
     * @description To populate end user info
     * @param newDRList List of deal records
     */
    public void autoPopulateEndUserInformation(List<Deal_Registration__c> newDRList){
        Map<Id, Deal_Registration__c> contactIdDealRegMap = new Map<Id, Deal_Registration__c>();
        Map<String, Alliance_Partner_Account_Mapping__mdt> acccIdAlliancePartnerMap = DealRegUtilityHelper.getAlliancePartnerMapping();

        for (Deal_Registration__c deal : newDRList){
            if ((deal.RecordTypeId == AllianceRecordTypeId || deal.RecordTypeId == ServiceDeliveryRecordTypeId) && (deal.Deal_Registration_Status__c == 'Submitted') && deal.Primary_Contact__c != null && deal.Company_Name__c != null){
                contactIdDealRegMap.put(deal.Primary_Contact__c, deal);
            }
        }

        if (contactIdDealRegMap.isEmpty()){
            return;
        }

        Map<Id, Contact> contactIdContactMap = new Map<Id, Contact>([SELECT Id, FirstName, LastName, Title, Phone, Email, AccountId, Account.Name, Account.BillingStreet, Account.BillingCity, Account.BillingPostalCode, Account.BillingStateCode, Account.BillingCountry, Account.MSFT_OCI_Cloud_Alliance_BDM__c, Account.MSFT_OCI_Cloud_Alliance_BDM__r.IsActive, Account.AWS_GCP_Cloud_Alliance_BDM__c, Account.AWS_GCP_Cloud_Alliance_BDM__r.IsActive
                                FROM Contact
                                WHERE ID IN:contactIdDealRegMap.keyset()]);

        if (contactIdContactMap.isEmpty()){
            return;
        }

        Deal_Registration__c deal;
        Contact con;
        Boolean isCloudAlliance;
        for (Id conId : contactIdContactMap.keySet()){
            if (!contactIdDealRegMap.containsKey(conId)){
                continue;
            }
            con = contactIdContactMap.get(conId);
            deal = contactIdDealRegMap.get(conId);
            deal.Company__c = con.Account.Name;
            deal.Street__c = con.Account.BillingStreet;
            deal.City__c = con.Account.BillingCity;
            deal.PostalCode__c = con.Account.BillingPostalCode;
            deal.Country__c = con.Account.BillingCountry;

            deal.StateCode__c = con.Account.BillingCountry == 'United States'?con.Account.BillingStateCode:deal.StateCode__c;
            deal.FirstName__c = con.FirstName;
            deal.LastName__c = con.LastName;
            deal.Title__c = con.Title;
            deal.Phone__c = con.Phone;
            deal.Email__c = con.Email;

            deal.Deal_Reg_Submitted_Date__c = Date.today();
            deal.Deal_Reg_Exp_Date__c = Date.today().addDays(20); // prit26-285

            deal.Alliance_Type__c = (deal.RecordTypeId == AllianceRecordTypeId && deal.Partner_Lookup__c != null && acccIdAlliancePartnerMap.get(deal.Partner_Lookup__c) != null)?acccIdAlliancePartnerMap.get(deal.Partner_Lookup__c).Account_Type__c:deal.Alliance_Type__c;
            isCloudAlliance = (deal.RecordTypeId == AllianceRecordTypeId && deal.Alliance_Type__c == 'Cloud');

            if (isCloudAlliance && ((con.Account.MSFT_OCI_Cloud_Alliance_BDM__c != null && con.Account.MSFT_OCI_Cloud_Alliance_BDM__r.IsActive) || (con.Account.AWS_GCP_Cloud_Alliance_BDM__c != null && con.Account.AWS_GCP_Cloud_Alliance_BDM__r.IsActive))){
                deal.BDM__c = (con.Account.MSFT_OCI_Cloud_Alliance_BDM__c != null) ? con.Account.MSFT_OCI_Cloud_Alliance_BDM__c : con.Account.AWS_GCP_Cloud_Alliance_BDM__c; //prit26-464
            }else if(isCloudAlliance){
                deal.BDM__c = Label.BDM_Opp_Default_Owner;
            }

            deal.BDM__c = (deal.RecordTypeId == AllianceRecordTypeId && deal.Alliance_Type__c != 'Cloud')?UserInfo.getUserId():deal.BDM__c;
        }
    }

    /**
     * @description To update reseller info
     * @param resellerDealRegList List of deal records
     * @param resellerDROpptyMap map of opportunity
     * @return List of Opportunity records
     */
    public List<Opportunity> updateResellerInformation(List<Deal_Registration__c> resellerDealRegList, Map<Id, Opportunity> resellerDROpptyMap){
        List<OpportunityContactRole> ocrToInsertList = new List<OpportunityContactRole>();
        List<Contact> contactToInsertList = new List<Contact>();
        Map<Id, Opportunity> opptyIdOpptyMap = new Map<Id, Opportunity>();

        for (Opportunity opty : [SELECT ID, Name, Partner_of_Record__c, Account.MSP_Account_Lookup__c, MSP_End_User_Lookup__c, SDR_Led__c, Deal_Registration_Type__c, Initial_Contacts_Name__c, Initial_Contacts_Name__r.Email, AccountId, OwnerId, Partner_Lookup__c, Sourcing_Partner__c, Teaming_Partner__c
                                 FROM Opportunity
                                 WHERE Id IN:resellerDROpptyMap.keySet()]){
            opptyIdOpptyMap.put(opty.Id, opty);
        }

        Opportunity resellerOpportunity;
        Boolean isFocusedPartner;
        Boolean isNationalPartner;
        for (Deal_Registration__c dealReg : resellerDealRegList){
            if(!resellerDROpptyMap.containsKey(dealReg.Opportunity__c)){
                continue;
            }
            resellerOpportunity = resellerDROpptyMap.get(dealReg.Opportunity__c);
            resellerOpportunity.Partner_SE_Name__c = dealReg.Partner_SE_Name__c;
            resellerOpportunity.Partner_SE_Email__c = dealReg.Partner_SE_Email__c;
            resellerOpportunity.Partner_SE_Phone__c = dealReg.Partner_SE_Phone__c; 
            resellerOpportunity.Decision_Maker__c = dealReg.Authority__c;
            resellerOpportunity.Distributor_Rep_Phone_Number__c = dealReg.Distributor_Rep_Phone_Number__c;
            resellerOpportunity.Distributor_Secondary_Email_Address__c = dealReg.Distributor_Secondary_Email_Address__c;
            resellerOpportunity.Distributor_Lookup__c = dealReg.Distributor__c;
            resellerOpportunity.Partner_Lookup__c = dealReg.Partner_Lookup__c;

            resellerOpportunity.Sell_to_Partner__c = (dealReg.Sell_to_Partner__c != null && Label.NetApp_Account_Ids.contains(dealReg.Sell_to_Partner__c)) ? dealReg.Sell_to_Partner__c : resellerOpportunity.Sell_to_Partner__c;

            isFocusedPartner = dealReg.Focused_Partner__c;
            isNationalPartner = dealReg.National_Partner__c;

            if ((resellerOpportunity.Sourcing_Partner__c != null && dealReg.Deal_Registration_Type__c != 'Rubrik Sourced' && isFocusedPartner) || (resellerOpportunity.Partner_Lookup__c != null && dealReg.Deal_Registration_Type__c == 'Rubrik Sourced' && opptyIdOpptyMap.get(dealReg.Opportunity__c).Teaming_Partner__c == null && isFocusedPartner)){
                resellerOpportunity.Focused_Partner_Calc__c = true;
            }

            if ((resellerOpportunity.Partner_Lookup__c != null && dealReg.Deal_Registration_Type__c != 'Rubrik Sourced' && isNationalPartner) || (resellerOpportunity.Partner_Lookup__c != null && dealReg.Deal_Registration_Type__c == 'Rubrik Sourced' && opptyIdOpptyMap.get(dealReg.Opportunity__c).Teaming_Partner__c == null && isNationalPartner)){
                resellerOpportunity.National_Partner_Calc__c = true;
            }
        
            //PRIT24-741-start - this logic should run if dr is MSP and type is reseller
            if (!dealReg.Dedicated_Managed_Service__c){
                continue;
            }
            
            if (opptyIdOpptyMap.get(dealReg.Opportunity__c).Partner_of_Record__c == null && opptyIdOpptyMap.get(dealReg.Opportunity__c).Account.MSP_Account_Lookup__c == null){ //Harshit -- no need of two if blocks
                resellerOpportunity.Partner_of_Record__c = dealReg.Partner_Lookup__c;
            }
            if (opptyIdOpptyMap.get(dealReg.Opportunity__c).Partner_of_Record__c == null && opptyIdOpptyMap.get(dealReg.Opportunity__c).Account.MSP_Account_Lookup__c != null){
                resellerOpportunity.Partner_of_Record__c = dealReg.Partner_Lookup__c;
            }
            if (opptyIdOpptyMap.get(dealReg.Opportunity__c).MSP_End_User_Lookup__c == null){
                resellerOpportunity.MSP_End_User_Lookup__c = dealReg.Company_Name__c;
            }
            if (opptyIdOpptyMap.get(dealReg.Opportunity__c).Partner_Lookup__c == null){
                resellerOpportunity.Partner_Lookup__c = dealReg.Partner_Lookup__c;
            }
            //PRIT24-741-end
        }
        return resellerDROpptyMap.values();
    }

    /**
     * @description To update alliance info
     * @param allianceDealRegList List of deal records
     * @param allianceDROpptyMap map of opportunity
     * @return List of Opportunity records
     */
    public List<Opportunity> updateAlliancePartnerInformation(List<Deal_Registration__c> allianceDealRegList, Map<Id, Opportunity> allianceDROpptyMap){
        Map<String, Alliance_Partner_Account_Mapping__mdt> acccIdAlliancePartnerMap = DealRegUtilityHelper.getAlliancePartnerMapping();
        List<String> cloudAllianceValuesList = DealRegUtilityHelper.getPicklistValue('Opportunity', 'Alliance_Partner_Name__c');
        List<String> allianceHWValuesList = DealRegUtilityHelper.getPicklistValue('Opportunity', 'Alliance_HW_Partner__c');
        List<String> securityAllianceValuesList = DealRegUtilityHelper.getPicklistValue('Opportunity', 'Security_Alliance_Partner__c');
        
        Map<Id, Opportunity> opptyIdOpptyMap = new Map<Id, Opportunity>([SELECT ID, Name, Alliance_Partner_Name__c, Alliance_HW_Partner__c, SDR_Led__c, Deal_Registration_Type__c, Security_Alliance_Partner__c
                                 FROM Opportunity
                                 WHERE Id IN:allianceDROpptyMap.keySet()]);

        Opportunity opp;
        Opportunity dealRegOpp;
        Alliance_Partner_Account_Mapping__mdt alliPartMdt;
        Boolean isCloudValue;
        Boolean isHWValue;
        Boolean isSecureValue;
        
        for (Deal_Registration__c dealReg : allianceDealRegList){
            if((!opptyIdOpptyMap.containsKey(dealReg.Opportunity__c) || !allianceDROpptyMap.containsKey(dealReg.Opportunity__c) || !acccIdAlliancePartnerMap.containsKey(dealReg.Partner_Lookup__c) || acccIdAlliancePartnerMap.get(dealReg.Partner_Lookup__c) == null) && !Test.isRunningTest()){
                continue;
            }
            opp = opptyIdOpptyMap.get(dealReg.Opportunity__c);
            dealRegOpp = allianceDROpptyMap.get(dealReg.Opportunity__c);
            alliPartMdt = acccIdAlliancePartnerMap.get(dealReg.Partner_Lookup__c);
            if(Test.isRunningTest()){
                alliPartMdt = new Alliance_Partner_Account_Mapping__mdt(Account_ID__c = dealReg.Partner_Lookup__c,
                                    Account_Type__c = 'Security',
                                    Account_Name__c = 'Okta.com, Inc.',
                                    Alliance_Account_Name__c = 'Okta'
                                );
            }
            
            isCloudValue = cloudAllianceValuesList.contains(alliPartMdt.Alliance_Account_Name__c);
            isHWValue = allianceHWValuesList.contains(alliPartMdt.Alliance_Account_Name__c);
            isSecureValue = securityAllianceValuesList.contains(alliPartMdt.Alliance_Account_Name__c);
            
            
            if (isCloudValue && opp.Alliance_Partner_Name__c == null || opp.Alliance_Partner_Name__c == 'None'){
                dealRegOpp.Alliance_Partner_Name__c = alliPartMdt.Alliance_Account_Name__c;
            } else if (isCloudValue && opp.Alliance_Partner_Name__c != null && !opp.Alliance_Partner_Name__c.contains(alliPartMdt.Alliance_Account_Name__c)){
                dealRegOpp.Alliance_Partner_Name__c = opp.Alliance_Partner_Name__c + ';' + alliPartMdt.Alliance_Account_Name__c;
            } else if (isHWValue && opp.Alliance_HW_Partner__c == null || opp.Alliance_HW_Partner__c == 'None'){
                dealRegOpp.Alliance_HW_Partner__c = alliPartMdt.Alliance_Account_Name__c;
            } else if (isHWValue && opp.Alliance_HW_Partner__c != null){
                dealRegOpp.Alliance_HW_Partner__c = opp.Alliance_HW_Partner__c + ';' + alliPartMdt.Alliance_Account_Name__c;
            } else if (isSecureValue && opp.Security_Alliance_Partner__c == null || opp.Security_Alliance_Partner__c == 'None'){
                dealRegOpp.Security_Alliance_Partner__c = alliPartMdt.Alliance_Account_Name__c;
            } else if (isSecureValue && opp.Security_Alliance_Partner__c != null){
                dealRegOpp.Security_Alliance_Partner__c = opp.Security_Alliance_Partner__c + ';' + alliPartMdt.Alliance_Account_Name__c;
            }
        }
        return allianceDROpptyMap.values();
    }

    /**
     * @description To update SDP info
     * @param sdpDealRegList List of deal records
     * @param sdpDROpptyMap map of opportunity
     * @return List of Opportunity records
     */
    public List<Opportunity> updateSDPInformation(List<Deal_Registration__c> sdpDealRegList, Map<Id, Opportunity> sdpDROpptyMap){
        Map<Id, Opportunity> opptyIdOpptyMap = new Map<Id, Opportunity>([SELECT ID, Name, Partner_of_Record__c, MSP_End_User_Lookup__c, Account.MSP_Account_Lookup__c, AccountId, Partner_Lookup__c, SDR_Led__c, Deal_Registration_Type__c
                                 FROM Opportunity
                                 WHERE Id IN:sdpDROpptyMap.keySet()]);

        Opportunity opp;
        Opportunity sdpOpp;
        for (Deal_Registration__c dealReg : sdpDealRegList){
            if(!opptyIdOpptyMap.containsKey(dealReg.Opportunity__c) || !sdpDROpptyMap.containsKey(dealReg.Opportunity__c)){
                continue;
            }
            opp = opptyIdOpptyMap.get(dealReg.Opportunity__c);
            sdpOpp = sdpDROpptyMap.get(dealReg.Opportunity__c);
            if (opp.Partner_of_Record__c == null){ 
                sdpOpp.Partner_of_Record__c = dealReg.Partner_Lookup__c;
            }
            if (opp.MSP_End_User_Lookup__c == null){
                sdpOpp.MSP_End_User_Lookup__c = dealReg.Company_Name__c;
            }
            if (opp.Partner_Lookup__c == null){
                sdpOpp.Partner_Lookup__c = dealReg.Partner_Lookup__c;
            }
        }
        return sdpDROpptyMap.values();
    }

    /**
     * @description To update territory info
     * @param newList List of deal records
     * @param oldMap map of old deal
     */
    public void populateCDMTerritoryonDealReg(List<Deal_Registration__c> newList, Map<Id, Deal_Registration__c> oldMap){
        Map<String, Id> dealRegToUserIds = new Map<String, Id>();
        Map<Id, String> userIdToTerritoryName = new Map<Id, String>();

        for (Deal_Registration__c dealReg : newList){
            if (dealReg.CDM__c != null && (oldMap == null || (oldMap != null && dealReg.CDM__c != oldMap.get(dealReg.Id).CDM__c))){
                    dealRegToUserIds.put(dealReg.Name, dealReg.CDM__c);
            }
        }
        for (UserTerritory2Association uta : [SELECT Id, UserId, Territory2Id, Territory2.Internal_Territory_Name__c, Territory2.ParentTerritory2Id, Territory2.ParentTerritory2.Internal_Territory_Name__c, Territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c, Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c, RoleInTerritory2, Territory2.Territory2Type.DeveloperName
                                              FROM UserTerritory2Association
                                              WHERE Territory2.Territory2Model.State = 'Active' AND Territory2.Territory2Type.DeveloperName = 'Territory' AND UserId IN:dealRegToUserIds.values()
                                              AND Territory2.Internal_Territory_Name__c LIKE 'CDM-%']){//PRIT25-259
            userIdToTerritoryName.put(uta.UserId, uta.Territory2.Internal_Territory_Name__c);
        }

        for (Deal_Registration__c dealReg : newList){
            if (dealRegToUserIds.containsKey(dealReg.Name) && userIdToTerritoryName.containsKey(dealRegToUserIds.get(dealReg.Name))){
                dealReg.CDM_Territory__c = userIdToTerritoryName.get(dealRegToUserIds.get(dealReg.Name));
            } else if (dealReg.CDM__c == null){
                dealReg.CDM_Territory__c = null;
            }
        }
    }

    //PRIT24-827 - end
    //PRIT24-161 - start
    /**
     * @description To populate persona
     * @param newList List of deal records
     * @param oldMap map of old deal
     */
    public void populateDealPersonas(List<Deal_Registration__c> newList, Map<Id, Deal_Registration__c> oldMap){
        Map<String, List<PatchManager__c>> patchMap = PatchManager.getPatchMap(newList, PatchManager.DEAL_REG);
        populateCDM(newList, oldMap, patchMap);
        populateCDMManager(newList);//prit26-285
        populateBDM(newList, oldMap, patchMap);
        populateDRActors(newList, oldMap, patchMap);
        populateCDMTerritoryonDealReg(newList, oldMap);
        setInternalDRStatus(newList, oldMap);
    }

    /**
     * @description To populate CDM
     * @param newList List of deal records
     * @param oldMap map of old deal
     * @param patchMap map of patch manager
     */
    public void populateCDM(List<Deal_Registration__c> newList, Map<Id, Deal_Registration__c> oldMap, Map<String, List<PatchManager__c>> patchMap){
        //For TART
        Set<String> roleInTerritory = new Set<String>{ Label.CDM_DR_Routing_Role, Label.CDM_Manager_Role, Label.CDM_VP_Role, 'CDM' };
        Map<Id, Deal_Registration__c> companyToDRMap = new Map<Id, Deal_Registration__c>();
        Map<Id, Deal_Registration__c> ownerIdDealRegMap = new Map<Id, Deal_Registration__c>();
        Map<Id, Id> companyToTerritoryMap = new Map<Id, Id>();
        Set<Id> territoryIDSet = new Set<Id>();
        Map<Id, Id> territoryToCDMUser = new Map<Id, Id>();
        Set<Id> accsOnDrSet = new Set<Id>();
        Map<Id, Account> accsOnDrMap = new Map<Id, Account>();
        Map<Id, Id> accAccOwnerMap = new Map<Id, Id>();
        Map<Id, Id> tbhUserMap = new Map<Id, Id>();
        List<Deal_Registration__c> drList = new List<Deal_Registration__c>();
        String tbhUser = '%' + System.Label.PC_TBHUser + '%';
        for (Deal_Registration__c dr : newList){
            if (((oldMap == null || oldMap.get(dr.Id).Partner_Lookup__c != dr.Partner_Lookup__c) || (oldMap == null || oldMap.get(dr.Id).Company_Name__c != dr.Company_Name__c) || (oldMap == null && dr.Company_Name__c == null && dr.Partner_Lookup__c == null)) && (dr.Deal_Registration_Status__c == 'Pending Meeting' || dr.Deal_Registration_Status__c == 'Submitted')){
                if(dr.Partner_Lookup__c != null)
                    accsOnDrSet.add(dr.Partner_Lookup__c);
                if(dr.Company_Name__c != null)
                    accsOnDrSet.add(dr.Company_Name__c);
                drList.add(dr);
            }
        }

        for (Account a : [SELECT Id, OwnerId, Owner.IsActive, Focused_Partner__c, ETM_Theatre__c
                          FROM Account
                          WHERE Id IN:accsOnDrSet]){
            accsOnDrMap.put(a.Id, a);
            accAccOwnerMap.put(a.Id,a.OwnerId);
        }
        
        
        for(User u : [SELECT Id, Name, isActive, ManagerId, Manager.isActive, Manager.ManagerId, Manager.Manager.isActive FROM User WHERE Id IN :accAccOwnerMap.values() and Name LIKE :tbhUser]){
            //PRIT26-255
            tbhUserMap.put(u.Id, u.Manager.isActive ? u.ManagerId : u.Manager.ManagerId);
            if(u.Manager.isActive){
                tbhManagerIds.add(u.ManagerId);
            }
            if(u.Manager.Manager.isActive){
                tbhSkipLevelManagerIds.add(u.Manager.ManagerId);
            }
        }

        for (Deal_Registration__c dr : drList){
            PatchManager__c pmRec;
            if(dr.RecordTypeId != EngagementRecordTypeId){
                pmRec = PatchManager.assignDealReg(patchMap, dr);
                dr.PatchManager__c = pmRec != null ? pmRec.Id : null;

                if (dr.RecordTypeId == OEMRecordTypeId && dr.OEM_SubType__c == 'Revshare' && oldMap == null){
                    dr.OEM_L1_Approver__c = System.Label.OEM_L1_Approver;
                    dr.Deal_Registration_Sub_Status__c = 'Pending L1 Approval';
                }

                if (pmRec != null && pmRec.RecordType.Name == 'Geographic' && !dr.GSI_Deal_Registration__c){
                    if (pmRec.CDM__c != null){
                        dr.CDM__c = pmRec.CDM__c;
                    }
                    if (String.isBlank(dr.Company_Name__c) && pmRec.CDM__c != null && pmRec.CDM__r.IsActive){
                        dr.OwnerId = pmRec.CDM__c;
                    } else if ((pmRec.CDM__c != null && !pmRec.CDM__r.IsActive) || pmRec.CDM__c == null){
                        dr.OwnerId = pmRec.OwnerId;
                    }
                }
                
                if (pmRec != null && dr.Partner_Lookup__c != null && accsOnDrMap.get(dr.Partner_Lookup__c) != null && !accsOnDrMap.get(dr.Partner_Lookup__c).Focused_Partner__c){
                    if (dr.Company_Name__c == null || (accsOnDrMap.get(dr.Company_Name__c) != null && accsOnDrMap.get(dr.Company_Name__c).ETM_Theatre__c != null && accsOnDrMap.get(dr.Company_Name__c).ETM_Theatre__c != 'AMER' && pmRec != null && pmRec.TLevel1__c != 'AMER')){
                            dr.CDM__c = (pmRec.CDM__c != null && pmRec.CDM__r.IsActive) ? pmRec.CDM__c : pmRec.OwnerId;
                    } else if (dr.Company_Name__c != null && ((accsOnDrMap.get(dr.Company_Name__c) != null && accsOnDrMap.get(dr.Company_Name__c).ETM_Theatre__c != null && accsOnDrMap.get(dr.Company_Name__c).ETM_Theatre__c == 'AMER') || (pmRec != null && pmRec.TLevel1__c == 'AMER'))){
                        companyToDRMap.put(dr.Company_Name__c, dr);//adding company id for owner.
                    }
                } else if (dr.Partner_Lookup__c != null && accsOnDrMap.get(dr.Partner_Lookup__c) != null && accsOnDrMap.get(dr.Partner_Lookup__c).Focused_Partner__c){
                    dr.CDM__c = accsOnDrMap.get(dr.Partner_Lookup__c).OwnerId;
                } else if (dr.Partner_Lookup__c == null && accsOnDrMap.get(dr.Partner_Lookup__c) == null && pmRec != null){
                    dr.CDM__c = pmRec.CDM__r.IsActive ? pmRec.CDM__c : pmRec.OwnerId;
                }

                if (dr.RecordTypeId == OEMRecordTypeId && pmRec != null){
                    dr.CDM__c = pmRec.CDM__r.IsActive ? pmRec.CDM__c : pmRec.OwnerId;
                }
            }

            //Owner Assignment
            if (dr.Company_Name__c != null && accsOnDrMap.get(dr.Company_Name__c) != null && accsOnDrMap.get(dr.Company_Name__c).Owner.IsActive){
                Id accOwner = accsOnDrMap.get(dr.Company_Name__c).OwnerId;
                //PRIT26-255
                dr.OwnerId = tbhUserMap.containsKey(accOwner) ? tbhUserMap.get(accOwner): accOwner;
            } else if ((dr.RecordTypeId == ResellerRecordTypeId || dr.RecordTypeId == OEMRecordTypeId) && dr.Company_Name__c == null && pmRec != null && pmRec.CDM__c != null && pmRec.CDM__r.IsActive){
                if (dr.Partner_Lookup__c != null && accsOnDrMap.get(dr.Partner_Lookup__c) != null && accsOnDrMap.get(dr.Partner_Lookup__c).Focused_Partner__c){
                    Id partnerAccOwner = accsOnDrMap.get(dr.Partner_Lookup__c).OwnerId;
                    //PRIT26-255
                    dr.OwnerId = tbhUserMap.containsKey(partnerAccOwner) ? tbhUserMap.get(partnerAccOwner): partnerAccOwner;
                } else{
                    dr.OwnerId = pmRec.CDM__c;
                }
            } else if (dr.Company_Name__c != null && accsOnDrMap.get(dr.Company_Name__c) != null && !accsOnDrMap.get(dr.Company_Name__c).Owner.IsActive && dr.GSI_Deal_Registration__c && pmRec != null && pmRec.CDM__c != null && pmRec.CDM__r.IsActive){
                dr.OwnerId = pmRec.CDM__c;
            }
        }

        for (Account a : [SELECT Id, OwnerId
                          FROM Account
                          WHERE Id IN:companyToDRMap.keySet()]){
            ownerIdDealRegMap.put(a.OwnerId, companyToDRMap.get(a.Id));
        }

        for (UserTerritory2Association uta : [SELECT Id, UserId, Territory2Id, RoleInTerritory2, Territory2.Territory2Type.DeveloperName
                                              FROM UserTerritory2Association
                                              WHERE Territory2.Territory2Model.State = 'Active' AND Territory2.Territory2Type.DeveloperName = 'Territory' AND UserId IN:ownerIdDealRegMap.keyset() AND RoleInTerritory2 =: Label.AccountExecRoleName ]){
            territoryIDSet.add(uta.Territory2Id);
            companyToTerritoryMap.put(ownerIdDealRegMap.get(uta.UserId).Company_Name__c, uta.Territory2Id);
        }

        for (UserTerritory2Association uta : [SELECT Id, UserId, User.isActive, Territory2Id, RoleInTerritory2, Territory2.Territory2Type.DeveloperName
                                              FROM UserTerritory2Association
                                              WHERE Territory2.Territory2Model.State = 'Active' AND Territory2.Territory2Type.DeveloperName = 'Territory' AND User.isActive = true AND RoleInTerritory2 IN:roleInTerritory AND Territory2Id IN:territoryIDSet]){
            if (uta.RoleInTerritory2 == Label.CDM_DR_Routing_Role || uta.RoleInTerritory2 == Label.CDM_Manager_Role || uta.RoleInTerritory2 == Label.CDM_VP_Role || uta.RoleInTerritory2 == 'CDM'){
                territoryToCDMUser.put(uta.Territory2Id, uta.UserId);
            }
        }
        Id terrId;
        for (Deal_Registration__c dr : ownerIdDealRegMap.values()){
            terrId = companyToTerritoryMap.get(dr.Company_Name__c);
            if (territoryToCDMUser.containsKey(terrId)){
                dr.CDM__c = territoryToCDMUser.get(terrId);
            } 
        }
        
    }
     
    /**
     * @description To populate CDM Manager
     * @param newList List of deal records
     */
    public void populateCDMManager(List<Deal_Registration__c> newList){
        Set<Id> CDMIds = new Set<Id>();
        Map<Id, Id> CDMtoManagerMap = new Map<Id, Id>();
        for(Deal_Registration__c dr: newList){
            if(dr.CDM__c != null)
                CDMIds.add(dr.CDM__c);
        }
        for(User u :[SELECT Id, ManagerId FROM User WHERE Id IN:CDMIds]){
            CDMtoManagerMap.put(u.Id, u.ManagerId);
        }
        for(Deal_Registration__c dr: newList){
            if(dr.CDM__c != null && CDMtoManagerMap.containsKey(dr.CDM__c)){
                dr.CDM_Manager__c = CDMtoManagerMap.get(dr.CDM__c);
            }
        }
    }
    
    /**
     * @description To populate BDM
     * @param newList List of deal records
     * @param oldMap map of old deal
     * @param patchMap map of patch manager
     */
    public void populateBDM(List<Deal_Registration__c> newList, Map<Id, Deal_Registration__c> oldMap, Map<String, List<PatchManager__c>> patchMap){
        List<GSI_BDM_GAM_Mapping__c> mappingRecords = GSI_BDM_GAM_Mapping__c.getAll().values();
        Set<Id> partnerAccIds = new Set<Id>();
        for (Deal_Registration__c dr : newList){
            if ((dr.GSI_Deal_Registration__c || dr.RecordTypeId == ServiceDeliveryRecordTypeId) && dr.BDM__c == null && dr.Partner_Lookup__c != null){
                partnerAccIds.add(dr.Partner_Lookup__c);
            }
        }
        if (partnerAccIds.isEmpty()) return;
        
        Map<Id,Account> partnerAccountMap =new Map<Id,Account>([Select Id,ParentId from Account Where Id IN: partnerAccIds]);
        String BDMWithCountry;
        String BDMWithoutCountry;
        for (Deal_Registration__c dr : newList){
            if (!partnerAccountMap.containsKey(dr.Partner_Lookup__c)) continue;
            dr.CDM__c = null;
            PatchManager__c pmRec = PatchManager.assignDealReg(patchMap, dr);
            if (pmRec == null) continue;
            String partnerId = partnerAccountMap.get(dr.Partner_Lookup__c)?.ParentId ?? dr.Partner_Lookup__c;
            for(GSI_BDM_GAM_Mapping__c mappingRecord : mappingRecords){
                if(!(mappingRecord.Active__c && mappingRecord.Account_ID__c == partnerId && mappingRecord.Theatre__c == pmRec.TLevel1__c)){
                    continue;
                }
                if(mappingRecord.Country__c == dr.Country__c){
                    BDMWithCountry = mappingRecord.BDM_Id__c;
                }else if(mappingRecord.Country__c == null){
                    BDMWithoutCountry = mappingRecord.BDM_Id__c;
                }
            }
            dr.BDM__c = BDMWithCountry ?? BDMWithoutCountry ?? UserInfo.getUserId();
        }
    }

    /**
     * @description To set status
     * @param newList List of deal records
     * @param oldMap map of old deal
     */
    public void setInternalDRStatus(List<Deal_Registration__c> newList, Map<Id, Deal_Registration__c> oldMap){
        for(Deal_Registration__c dr : newList){
            if(!(dr.RecordTypeId == ServiceDeliveryRecordTypeId && dr.GSI_NDA__c)){
                continue;
            }
            if(oldMap == null || oldMap.get(dr.Id).GSI_NDA__c != dr.GSI_NDA__c){//on insert
                dr.Deal_Registration_Status__c = 'Escalated';
                dr.Deal_Registration_Sub_Status__c = 'GSI-NDA Pending Approval';
            }else if(oldMap != null && dr.Deal_Registration_Status__c != oldMap.get(dr.Id).Deal_Registration_Status__c && dr.Deal_Registration_Status__c == 'Approved'){// on update
                dr.PS_Escalated__c = true;
            }
        }
    }
}