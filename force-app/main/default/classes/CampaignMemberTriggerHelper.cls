public class CampaignMemberTriggerHelper{
    public static List<string> ListOfAccountStatus = new List<string> {'Existing Customer', 'Lost Opportunity', 'Prospect'};
    private static Set<String> campaignTypeSet = new Set<String>{'Direct Mail','Direct Mail - Digital','Webinar','Meeting Maker','Call Out Day','Telemarketing / Appointment Setting','Website','Advertising','Email - Paid','Email - Nurture','Asset','Social','Referral','Demo','Trial','Contact Us','Sporting / Cultural','Brik Day','Camp Rubrik','Seminar','Virtual Event','Tradeshow / Conference (Corporate)','Tradeshow / Conference (Regional)','Executive Event','User Group','EBC','Keynote','Breakout Session','Booth','Party','Sponsorship','Onsite Demo','Partner Integrated Campaign'};
    public static string NON_QUALIFIED = 'Non-Qualified';
    private static string OPEN = 'Open';
    private static string LOST_OPPORTUNITY ='Lost Opportunity';
    private static string PROSPECT ='Prospect';
    private static string ACTIVE_OPPORTUNITY ='Active Opportunity';
    private static string EXISTING_CUSTOMER ='Existing Customer';
    private static string MARKETING_NURTUREf = 'Marketing Nurture'; 
    private static string SALES_NURTURE = 'Sales Nurture';
    private static string RAW = 'RAW';
    private static string REPROCESS = 'Reprocess';
    private static string PARTNER_ROUNTING_QUEUE = 'Partner_Routing_Queue'; 
    private static string AMERMMQUEUEID = 'AMER-MM';
    public static Set<Id> CampRecursionIdSet = new Set<Id>(); 
    
    //MKT24-1149236
    private static Map<String, String> campaignTypeToContactScore = new Map<String, String>{
        'Trial' => 'Contact.Contact_Us__c',
        'Contact Us' => 'Contact.Contact_Us__c',
        'Party' => 'Contact.Low_Impact_Event__c',
        'Virtual Event' => 'Contact.Low_Impact_Event__c',
        'Sponsorship' => 'Contact.Low_Impact_Event__c',
        'Executive Event' => 'Contact.Low_Impact_Event__c',
        'Event' => 'Contact.Low_Impact_Event__c',
        'EBC' => 'Contact.Low_Impact_Event__c',
        'Tradeshow / Conference (Corporate)' => 'Contact.Low_Impact_Event__c',
        'Sporting / Cultural' => 'Contact.Low_Impact_Event__c',
        'Tradeshow / Conference (Regional)' => 'Contact.Low_Impact_Event__c',
        'Keynote' => 'Contact.Low_Impact_Event__c',
        'Seminar' => 'Contact.Medium_Impact_Event__c',
        'Booth' => 'Contact.Medium_Impact_Event__c',
        'User Group' => 'Contact.Medium_Impact_Event__c',
        'Breakout Session' => 'Contact.Medium_Impact_Event__c',
        'Camp Rubrik' => 'Contact.High_Impact_Event__c',
        'Brik Day' => 'Contact.High_Impact_Event__c',
        'Webinar' => 'Contact.Webinar__c',
        'Asset' => 'Contact.Digital_Download__c',
        'Social' => 'Contact.Digital_Download__c',
        'Advertising' => 'Contact.Digital_Download__c',
        'Content Syndication' => 'Contact.Digital_Download__c',
        'Demo' => 'Contact.Demo1__c'
    };
    private static Map<String, String> campaignTypeToLeadScore = new Map<String, String>{
        'Trial' => 'lead.Contact_Us__c',
        'Contact Us' => 'lead.Contact_Us__c',
        'Party' => 'lead.Low_Impact_Event__c',
        'Virtual Event' => 'lead.Low_Impact_Event__c',
        'Sponsorship' => 'lead.Low_Impact_Event__c',
        'Executive Event' => 'lead.Low_Impact_Event__c',
        'Event' => 'lead.Low_Impact_Event__c',
        'EBC' => 'lead.Low_Impact_Event__c',
        'Tradeshow / Conference (Corporate)' => 'lead.Low_Impact_Event__c',
        'Sporting / Cultural' => 'lead.Low_Impact_Event__c',
        'Tradeshow / Conference (Regional)' => 'lead.Low_Impact_Event__c',
        'Keynote' => 'lead.Low_Impact_Event__c',
        'Seminar' => 'lead.Medium_Impact_Event__c',
        'Booth' => 'lead.Medium_Impact_Event__c',
        'User Group' => 'lead.Medium_Impact_Event__c',
        'Breakout Session' => 'lead.Medium_Impact_Event__c',
        'Camp Rubrik' => 'lead.High_Impact_Event__c',
        'Brik Day' => 'lead.High_Impact_Event__c',
        'Webinar' => 'lead.Webinar__c',
        'Asset' => 'lead.Digital_Download__c',
        'Social' => 'lead.Digital_Download__c',
        'Advertising' => 'lead.Digital_Download__c',
        'Content Syndication' => 'lead.Digital_Download__c',
        'Demo' => 'lead.Demo1__c'
    };

    public static void populateFieldsOnInsert(List<CampaignMember> newCampMemLst){
        Map<Id, List<CampaignMember>> leadIdToCMs = new Map<Id, List<CampaignMember>>();
        Map<Id, List<CampaignMember>> contactIdToCMs = new Map<Id, List<CampaignMember>>();
        Map<Id, List<CampaignMember>> campaignIdToCampMembs = new Map<Id, List<CampaignMember>>();
        for(CampaignMember campMem : newCampMemLst){
            if(campMem.leadId != null){
                if(leadIdToCMs.containsKey(campMem.leadId))
                    leadIdToCMs.get(campMem.Leadid).add(campMem);
                else 
                    leadIdToCMs.put(campMem.Leadid, new List<CampaignMember>{campMem});
            }
            else if(campMem.contactId != null) {
                if(contactIdToCMs.containsKey(campMem.contactId))
                    contactIdToCMs.get(campMem.contactId).add(campMem);
                else 
                    contactIdToCMs.put(campMem.contactId, new List<CampaignMember>{campMem});
            }
        }
        
        if(!leadIdToCMs.isEmpty()){
            Set<Id> leadIds = leadIdToCMs.keySet();
                                    for(Lead pLead : [SELECT Id,ICID__c,Adobe_Experience_Cloud_ID__c, UTM_Campaign__c,UTM_Term__c, UTM_Content__c,  UTM_Medium__c, UTM_Source__c, Created_Through_Quick_Action__c, UTM_Type__c, UTM_Partner__c, //Added for MKT26-1526
                                    website_asset__c, website_placement__c, Status,Region__c,Theatre__c,Owner.Name,Last_Interacted_Campaign_Member__c,
                                    Winning_L2A_Account__r.Segment_Assignment__c, Winning_L2A_Account__r.RecordType.DeveloperName, 
                                    Winning_L2A_Account__r.Account_Status__c,Winning_L2A_Account__r.X6sense_Segments__c, Discount_Code__c, Event_Registration_Type__c,Web_Enhancement__c
                            FROM Lead 
                            WHERE Id IN : leadIds]){
                for(CampaignMember campMem : leadIdToCMs.get(pLead.Id)){
                    campMem.UTM_Campaign__c = pLead.UTM_Campaign__c ;
                    campMem.UTM_Medium__c = pLead.UTM_Medium__c;
                    campMem.UTM_Source__c = pLead.UTM_Source__c;
                    campMem.UTM_Term__c = pLead.UTM_Term__c;
                    campMem.UTM_Content__c = pLead.UTM_Content__c;
                    campMem.UTM_Type__c = pLead.UTM_Type__c;//Added for MKT26-1526
                    campMem.UTM_Partner__c = pLead.UTM_Partner__c;//Added for MKT26-1526
                    campMem.website_asset__c = pLead.website_asset__c;
                    campMem.website_placement__c = pLead.website_placement__c;
                    campMem.Lead_Status_Stamp__c = pLead.Status;
                    campMem.Region__c = pLead.Region__c;
                    campMem.Theatre__c = pLead.Theatre__c;
                    campMem.Lead_or_Contact_Owner__c = pLead.Owner.Name;
                    campMem.Discount_Code__c = pLead.Discount_Code__c;
                    campMem.Event_Registration_Type__c = pLead.Event_Registration_Type__c;
                    campMem.Web_Enhancement__c=pLead.Web_Enhancement__c;
                    campMem.Created_Through_Quick_Action__c=pLead.Created_Through_Quick_Action__c;
                    campMem.ICID__c=pLead.ICID__c;
                    campMem.Adobe_Experience_Cloud_ID__c=pLead.Adobe_Experience_Cloud_ID__c;
                    if(pLead.Winning_L2A_Account__c != null){
                        campMem.Account_Segment__c = pLead.Winning_L2A_Account__r.Segment_Assignment__c;
                        campMem.Account_Type__c = pLead.Winning_L2A_Account__r.RecordType.DeveloperName == 'Customer_Prospect'
                                                        ?pLead.Winning_L2A_Account__r.Account_Status__c : 'Partner';
						campMem.X6sense_Segments__c = pLead.Winning_L2A_Account__r.X6sense_Segments__c;
                    }
                }
            }
        }

        if(!contactIdToCMs.isEmpty()) {
            Set<Id> contactIds = contactIdToCMs.keySet();
            Map<Id, List<CampaignMember>> campaignIdToCMs = new Map<Id, List<CampaignMember>>();
            Map<Id, String> contactIdToAccFRName = new Map<Id, String>();
            for(Contact contactObj : [SELECT Id,UTM_Campaign__c,ICID__c,Adobe_Experience_Cloud_ID__c, UTM_Term__c, UTM_Content__c, UTM_Medium__c, UTM_Source__c,Created_Through_Quick_Action__c, UTM_Type__c, UTM_Partner__c, //Added for MKT26-1526
                                        website_asset__c, website_placement__c,Region__c, Theatre__c,Owner.Name,
                                        AccountId, Account.Segment_Assignment__c, Account.RecordType.DeveloperName, Account_Status__c, Account.X6sense_Segments__c, Discount_Code__c, Event_Registration_Type__c, Feature_Recommendation__c,Web_Enhancement__c
                                FROM Contact WHERE Id IN : contactIds]){
                for(CampaignMember campMem : contactIdToCMs.get(contactObj.Id)) {
                    campMem.UTM_Campaign__c = contactObj.UTM_Campaign__c ;
                    campMem.UTM_Medium__c = contactObj.UTM_Medium__c;
                    campMem.UTM_Source__c = contactObj.UTM_Source__c;
                    campMem.UTM_Term__c = contactObj.UTM_Term__c;
                    campMem.UTM_Content__c = contactObj.UTM_Content__c;
                    campMem.UTM_Type__c = contactObj.UTM_Type__c;//Added for MKT26-1526
                    campMem.UTM_Partner__c = contactObj.UTM_Partner__c;//Added for MKT26-1526
                    campMem.Region__c = contactObj.Region__c;
                    campMem.Theatre__c = contactObj.Theatre__c;
                    campMem.website_asset__c = contactObj.website_asset__c;
                    campMem.website_placement__c = contactObj.website_placement__c;
                    campMem.Lead_or_Contact_Owner__c = contactObj.Owner.Name;
                    campMem.Discount_Code__c = contactObj.Discount_Code__c;
                    campMem.Event_Registration_Type__c = contactObj.Event_Registration_Type__c;
                    campMem.Account_Segment__c = contactObj.Account.Segment_Assignment__c;
                    campMem.Created_Through_Quick_Action__c=contactObj.Created_Through_Quick_Action__c;
                    campMem.Account_Type__c = contactObj.Account.RecordType.DeveloperName == 'Customer_Prospect'
                                            ? contactObj.Account_Status__c : 'Partner';
                    campMem.Web_Enhancement__c=contactObj.Web_Enhancement__c;
                    campMem.X6sense_Segments__c = contactObj.Account.X6sense_Segments__c;
                    
                    if(contactObj.Feature_Recommendation__c != null) {
                        if(campaignIdToCMs.containsKey(campMem.campaignId))
                            campaignIdToCMs.get(campMem.campaignId).add(campMem);
                        else 
                            campaignIdToCMs.put(campMem.campaignId, new List<CampaignMember>{campMem});
                        contactIdToAccFRName.put(contactObj.Id, contactObj.AccountId+' - '+contactObj.Feature_Recommendation__c);
                    }
                }
            }
            if(!campaignIdToCMs.isEmpty()){
                Map<String, Id> frNameToId = new Map<String, Id>(); 
                Set<Id> campaignIds = campaignIdToCMs.keySet();
                List<String> accountFeatureNames = contactIdToAccFRName.values();
                //Query the frId here
                for(Feature_Recommendation__c fr : [SELECT Id, Account_Feature__c FROM Feature_Recommendation__c 
                                                        WHERE Account_Feature__c IN :accountFeatureNames
                                                        AND Status__c = 'Recommended']){
                    frNameToId.put(fr.Account_Feature__c, fr.Id);
                }
                List<Contact> updateContacts = new List<Contact>();
                for(Campaign ceresCampaign : [SELECT Id FROM Campaign WHERE ParentId = '7016f0000027EQ9' AND Id IN :campaignIds]){
                    for(CampaignMember mem : campaignIdToCMs.get(ceresCampaign.Id)) {
                        if(frNameToId.containsKey(contactIdToAccFRName.get(mem.ContactId))) {
                            mem.Feature_Recommendation__c = frNameToId.get(contactIdToAccFRName.get(mem.ContactId));
                            updateContacts.add(new Contact(Id = mem.ContactId, Feature_Recommendation__c=null));
                        }
                    }
                }
                if(!updateContacts.isEmpty()){
                    //block triggers
                    update updateContacts;
                }
            }
        }
    }
    
    private static void updateLeadAttributes(Map<Id, Id> leadIdToCampaignId, Map<Id,Lead> updateLeads){
        List<Id> campaignIds = leadIdToCampaignId.values();
        Map<Id, Campaign> finalCampaignMap = new Map<Id, Campaign>([SELECT Id, Name,type, Campaign_Type_Group__c, Campaign_Theme__c,GTM_Play__c,FCRM__FCR_Campaign_Sourced_By__c,Partner_Campaign_No_SDR_Follow_Up__c,Response_MQL_to_AE__c
        FROM Campaign
        WHERE Id IN :campaignIds]);
        if(!finalCampaignMap.isEmpty()){
            Map<Id, Id> leadIdToOwnerId = new Map<Id, Id>();
            for(Lead ld : [SELECT Id,MQL_Campaign_Type__c, Last_Run_L2A_Date__c,Campaign_Theme__c,GTM_Play__c,Direct_Routing_AE__c,PatchManager__c,PatchManager__r.ownerId,status,Deal_registration__c,MQL__c,Last_MQL_Date__c,OwnerId,Partner_MQL__c,rerun_PatchManager__c,L2A_Status__c
                            FROM Lead
                            WHERE Id IN: leadIdToCampaignId.keySet()
                            AND Deal_registration__c = false AND MQL__c = false AND Partner_MQL__c = false FOR UPDATE]){
                if(updateLeads.containsKey(ld.Id))
                    ld = updateLeads.get(ld.Id);
                else
                    updateLeads.put(ld.Id, ld);
            
                Id CampaignId = leadIdToCampaignId.get(ld.Id);
                ld.GTM_Play__c = finalCampaignMap.get(CampaignId).GTM_Play__c;
                ld.Campaign_Theme__c = finalCampaignMap.get(CampaignId).Campaign_Theme__c;
            }
        }
    }
    
    private static void updateContactAttributes(Map<Id, Id> contactIdToCampaignId, Map<Id,Contact> updateContacts){
        List<Id> campaignIds = contactIdToCampaignId.values();
        Map<Id, Campaign> finalCampaignMap = new Map<Id, Campaign>([SELECT Id, Name,type, Campaign_Theme__c,GTM_Play__c,FCRM__FCR_Campaign_Sourced_By__c,Partner_Campaign_No_SDR_Follow_Up__c,Response_MQL_to_AE__c
        FROM Campaign
        WHERE Id IN :campaignIds FOR UPDATE]);
        if(!finalCampaignMap.isEmpty()){
            Map<Id, Id> contactIdToOwnerId = new Map<Id, Id>();
            for(Contact ld : [SELECT Id,MQL_Campaign_Type__c,Campaign_Theme__c,GTM_Play__c,PatchManager__c,PatchManager__r.ownerId,MQL__c,Last_MQL_Date__c,OwnerId,Partner_MQL__c,rerun_PatchManager__c
                                FROM Contact
                                WHERE Id IN: contactIdToCampaignId.keySet()
                                AND MQL__c = false AND Partner_MQL__c = false FOR UPDATE]){
                if(updateContacts.containsKey(ld.Id))
                    ld = updateContacts.get(ld.Id);
                else
                    updateContacts.put(ld.Id, ld);
            
                Id CampaignId = contactIdToCampaignId.get(ld.Id);
                ld.GTM_Play__c = finalCampaignMap.get(CampaignId).GTM_Play__c;
                ld.Campaign_Theme__c = finalCampaignMap.get(CampaignId).Campaign_Theme__c;                   
            }
        }
    }
    
    public static void updateLeadsAndContactsAfterInsert(List<CampaignMember> newCampaignMemeber){
        Map<Id, Lead> updateLeads = new Map< Id, Lead>();
        Map<Id, Contact> updateContacts = new Map< Id, Contact>();

        List<CampaignMember> cmsWithLeads = new List<CampaignMember>();
        List<CampaignMember> cmsWithContacts = new List<CampaignMember>();
        Map<Id,Id> contactIdToCampaignId = new Map<Id,Id>();
        Map<Id,Id> contactIdToCampaignId1 = new Map<Id,Id>();
        Map<Id,Id> leadIdToCampaignId = new Map<Id,Id>(); 
        Map<Id,Id> leadIdToCampaignId1 = new Map<Id,Id>(); 
        Map<Id,Id> leadIdToAmplifyCampaignId = new Map<Id,Id>();
        Set<Id> excludeCampaignSet = new Set<Id>();
        Map<Id,CampaignMember> leadIdToCampaignMember = new Map<Id,CampaignMember>();
        Map<Id,CampaignMember> contactIdToCampaignMember = new Map<Id,CampaignMember>();

        for(HardCoded_RecordIds__mdt hr : [Select MasterLabel,Type__c from HardCoded_RecordIds__mdt where Type__c = 'Campaign-ActionableResponse']){
            Id idval = Id.ValueOf(hr.MasterLabel);
            excludeCampaignSet.add(Id.valueOf(idval));
        }

        for(CampaignMember newCM : newCampaignMemeber){
            if(newCM.LeadId != null){
                cmsWithLeads.add(newCM);
                if(!excludeCampaignSet.contains(newCM.CampaignId)){
                    if(newCM.HasResponded)
                        leadIdToCampaignId1.put(newCM.LeadId, newCM.CampaignId);
                    if((newCM.FCRM__FCR_QR__c || newCM.CFCR_PQL__c))
                        leadIdToCampaignId.put(newCM.LeadId, newCM.CampaignId);
                        leadIdToCampaignMember.put(newCM.LeadId, newCM);
                    if(newCM.Is_Amplify_Priority_Campaign__c && newCM.Status == 'Responded')
                        leadIdToAmplifyCampaignId.put(newCM.LeadId, newCM.CampaignId);
                }
            }
            else {
                cmsWithContacts.add(newCM);
                if(!excludeCampaignSet.contains(newCM.CampaignId)){
                    if(newCM.HasResponded)
                        contactIdToCampaignId1.put(newCM.ContactId, newCM.CampaignId);
                    if(newCM.FCRM__FCR_QR__c || newCM.CFCR_PQL__c) {
                        contactIdToCampaignId.put(newCM.ContactId,newCM.CampaignId);
                        contactIdToCampaignMember.put(newCM.ContactId, newCM);
                    }
                }
            }
        }
        if(!cmsWithLeads.isEmpty()){
            updateLastCampaignOnLead(cmsWithLeads, updateLeads);
        }
        if(!leadIdToCampaignId.isEmpty())
            updateFCRCFCRLeads(leadIdToCampaignId, updateLeads, leadIdToCampaignMember);
        //MKT23-265: call updateLeadAttributes
        if(!leadIdToCampaignId1.isEmpty()){
            updateLeadAttributes(leadIdToCampaignId1, updateLeads);
            stampLeadEngagements(leadIdToCampaignId1, updateLeads);
        }   
        //MKT23-265: call updateContactAttributes
        if(!contactIdToCampaignId1.isEmpty()){
            updateContactAttributes(contactIdToCampaignId1, updateContacts);
            stampContactEngagements(contactIdToCampaignId1, updateContacts);
        }   
        if(!cmsWithLeads.isEmpty() || !cmsWithContacts.isEmpty()){
            updateScoreFieldsLeadContact(cmsWithLeads, cmsWithContacts, updateLeads, updateContacts);
            updatePriorityDateLeadContact(cmsWithLeads, cmsWithContacts, updateLeads, updateContacts);
        }
        if(!contactIdToCampaignId.isEmpty())
            updateQRPQLContactFields(contactIdToCampaignId, updateContacts, contactIdToCampaignMember);
        
      	if(!leadIdToAmplifyCampaignId.isEmpty()){
            stampAmplifyCampgainDetailsOnLead(leadIdToAmplifyCampaignId, updateLeads);
        }
        if(!updateLeads.isEmpty()){
            System.debug('before updateLeads.values--'+updateLeads.values());
            update updateLeads.values();
            System.debug('After updateLeads.values--'+updateLeads.values());
        }
        if(!updateContacts.isEmpty()){
            update updateContacts.values();
        }
    }
	private static void stampAmplifyCampgainDetailsOnLead(Map<Id, Id> leadIdToAmplifyCampaignId, Map<Id,Lead> updateLeads){
        Map<Id, Lead> mapMQLLeadsForAmplifyCampaign = new Map<Id, Lead>([SELECT Id, MQL_Channel_Partner__c, MQL_Channel_CDM__c, Is_UTM_Term_Valid__c, MQL_Campaign_Type__c,Last_Run_L2A_Date__c,UTM_Term__c,Campaign_Theme__c,GTM_Play__c,Direct_Routing_AE__c,PatchManager__c,PatchManager__r.ownerId,status,Deal_registration__c,MQL__c,Last_MQL_Date__c,OwnerId,Partner_MQL__c,
                                                                         rerun_PatchManager__c,L2A_Status__c,Industry_Category__c,Partner_of_Record__c, Last_Applied_Routing_Modifier__c,Lead_Source_Most_Recent__c, Lead_Source_Most_Recent_Details__c, Amplify_Priority__c
                                                                         FROM Lead 
                														 WHERE Id IN: leadIdToAmplifyCampaignId.keySet() AND MQL__c = true FOR UPDATE]);
        Map<Id, Campaign> amplifyCampaignMap = new Map<Id, Campaign>();
        if(!mapMQLLeadsForAmplifyCampaign.isEmpty()){
			amplifyCampaignMap = new Map<Id, Campaign>([SELECT Id, Name,type, MDF_Funded__c, CDM__c, CDM__r.Name, Campaign_Partner__c, Campaign_Partner__r.Name, Campaign_Theme__c,GTM_Play__c,FCRM__FCR_Campaign_Sourced_By__c,Routing_Method__c,Partner_Campaign_No_SDR_Follow_Up__c,Response_MQL_to_AE__c,Campaign_Sales_Area__c,Campaign_Partner_Rep__c, Amplify_Priority__c, OwnerId
                                                FROM Campaign 
                                                WHERE Id IN :leadIdToAmplifyCampaignId.values() AND Amplify_Priority__c = true]);	            
        }
        if(!amplifyCampaignMap.isEmpty()){
            Map<Id,Id> contactIdToUserId = new Map<Id,Id>();
        	Set<Id> partnerRepIds = new Set<Id>();
            for(Id cmpId : amplifyCampaignMap.keySet()){
                partnerRepIds.add(amplifyCampaignMap.get(cmpId).Campaign_Partner_Rep__c);
            }
            
            for(User userObj : [SELECT Id,ContactId FROM User WHERE contactId IN : partnerRepIds]){
                if(userObj.ContactId != null){
                    contactIdToUserId.put(userObj.ContactId, userObj.Id);
                }
            } 
            for(Lead ld : mapMQLLeadsForAmplifyCampaign.values()){
                if(amplifyCampaignMap.containsKey(leadIdToAmplifyCampaignId.get(ld.Id))){
                    if(updateLeads.containsKey(ld.Id))
                        ld = updateLeads.get(ld.Id);
                    else
                        updateLeads.put(ld.Id, ld);                
                    ld.MQL_Channel_Partner__c = amplifyCampaignMap.get(leadIdToAmplifyCampaignId.get(ld.Id)).Campaign_Partner__c;
                    ld.MQL_Channel_CDM__c = amplifyCampaignMap.get(leadIdToAmplifyCampaignId.get(ld.Id)).CDM__c;
                    ld.MQL_Campaign_Type__c = 'Lead Share Program';
                    ld.Last_Applied_Routing_Modifier__c = 'Route to Partner';
                    if(amplifyCampaignMap.get(leadIdToAmplifyCampaignId.get(ld.Id)).Routing_Method__c == 'Route to Partner'){
                    	Id channelrepId = amplifyCampaignMap.get(leadIdToAmplifyCampaignId.get(ld.Id)).Campaign_Partner_Rep__c;
                    	if(contactIdToUserId.containsKey(channelrepId)){
                        	ld.Partner_of_Record__c = contactIdToUserId.get(channelrepId);
                    	}
                	} 
                    ld.Lead_Source_Most_Recent_Details__c = amplifyCampaignMap.get(leadIdToAmplifyCampaignId.get(ld.Id)).Name;
                    ld.rerun_PatchManager__c = true;
                    ld.Amplify_Priority__c = System.now();
                }
            }
        }
    }
    private static void updateFCRCFCRLeads(Map<Id, Id> leadIdToCampaignId, Map<Id,Lead> updateLeads, Map<Id, CampaignMember> leadIdToCampaignMember){
        List<Id> campaignIds = leadIdToCampaignId.values();
       Map<Id, Campaign> finalCampaignMap = new Map<Id, Campaign>([SELECT Id, Name,type, ETM_Role__c, RecordType.DeveloperName, MDF_Funded__c, CDM__c, CDM__r.Name, Campaign_Partner__c, Campaign_Partner__r.Name, Campaign_Theme__c,GTM_Play__c,FCRM__FCR_Campaign_Sourced_By__c,Routing_Method__c,Partner_Campaign_No_SDR_Follow_Up__c,Response_MQL_to_AE__c,Campaign_Sales_Area__c,Campaign_Partner_Rep__c, Amplify_Priority__c, OwnerId 
                                                FROM Campaign 
                                                WHERE Id IN :campaignIds]);
        if(!finalCampaignMap.isEmpty()){
            Set<Id> partnerRepIds = new Set<Id>();
            for(Id cmpId : finalCampaignMap.keySet()){
                partnerRepIds.add(finalCampaignMap.get(cmpId).Campaign_Partner_Rep__c);
            }
            Map<Id,Id> contactIdToUserId = new Map<Id,Id>();
            for(User userObj : [SELECT Id,ContactId FROM User WHERE contactId IN : partnerRepIds]){
                if(userObj.ContactId != null){
                    contactIdToUserId.put(userObj.ContactId, userObj.Id);
                }
            }

            Group pgp = [SELECT Id,DeveloperName from Group where DeveloperName =:PARTNER_ROUNTING_QUEUE];
            Map<Id, Id> leadIdToOwnerId = new Map<Id, Id>();
            for(Lead ld : [SELECT Id, MQL_Channel_Partner__c, ETM_Role__c, HasOptedOutOfEmail, Winning_L2A_Account__c, Alliance_BDM__c, MQL_Channel_CDM__c, Is_UTM_Term_Valid__c, MQL_Campaign_Type__c,Last_Run_L2A_Date__c,UTM_Term__c,Campaign_Theme__c,GTM_Play__c,Direct_Routing_AE__c,PatchManager__c,PatchManager__r.ownerId,status,Deal_registration__c,MQL__c,Last_MQL_Date__c,OwnerId,Partner_MQL__c,rerun_PatchManager__c,L2A_Status__c,Industry_Category__c,Partner_of_Record__c,
                           Lead_Source_Most_Recent__c, Lead_Source_Most_Recent_Details__c, Amplify_Priority__c, Last_Applied_Routing_Modifier__c
                           FROM Lead 
                            WHERE Id IN: leadIdToCampaignId.keySet() 
                            AND Deal_registration__c = false AND MQL__c = false AND Partner_MQL__c = false FOR UPDATE]){
                Lead lObject = ld;
                if(updateLeads.containsKey(ld.Id))
                    ld = updateLeads.get(ld.Id);
                else 
                    updateLeads.put(ld.Id, ld);
                ld.Last_MQL_Date__c = Date.today();
                Id campaignId = leadIdToCampaignId.get(ld.Id);
                 // changes move to the LeadTriggerHelper class
                //ld.Last_Applied_Routing_Modifier__c = finalCampaignMap.get(campaignId).Routing_Method__c;
                if(finalCampaignMap.get(campaignId).ETM_Role__c != null){
                    ld.ETM_Role__c = finalCampaignMap.get(campaignId).ETM_Role__c ;           
                 }                
                
                if(finalCampaignMap.get(campaignId).Campaign_Partner__c != null){
                    ld.MQL_Channel_Partner__c = finalCampaignMap.get(campaignId).Campaign_Partner__c;
                    ld.Partner_Marketing_Campaign__c = campaignId;
                }
                if(finalCampaignMap.get(campaignId).CDM__c != null){
                    ld.MQL_Channel_CDM__c = finalCampaignMap.get(campaignId).CDM__c;
                    ld.Partner_Marketing_Campaign__c = campaignId;
                }
                                
                
                ld.Campaign_Member_Status__c = leadIdToCampaignMember.get(ld.Id).Status;

                //TODO: Gaurav - Populate partner of record on Lead here
                if(finalCampaignMap.get(campaignId).Routing_Method__c == 'Route to Partner'){
                    Id channelrepId = finalCampaignMap.get(campaignId).Campaign_Partner_Rep__c;
                    if(contactIdToUserId.containsKey(channelrepId)){
                        ld.Partner_of_Record__c = contactIdToUserId.get(channelrepId);
                    }
                } 

                if(finalCampaignMap.get(campaignId).FCRM__FCR_Campaign_Sourced_By__c == 'Partner'){
                    ld.Partner_MQL__c = true;
                    // CHnages added for MTK22-53 add Lead_Rejection_Reason__c in queury
                    ld.Lead_Rejection_Reason__c=null;
                    ld.Last_Partner_Sourced_Date__c = Date.today();
                }else{
                    if(finalCampaignMap.get(campaignId).RecordType.DeveloperName == 'Event' && (leadIdToCampaignMember.get(ld.Id).Status == 'Attended - no engage' || leadIdToCampaignMember.get(ld.Id).Status == 'No Show') && ld.HasOptedOutOfEmail){
                        ld.MQL__c = false;
                    }else{
                        ld.MQL__c = true;
                    }
                    
                    ld.MQL_Campaign_Type__c = finalCampaignMap.get(campaignId).Type;
                    Campaign objCampaign = finalCampaignMap.get(campaignId);
                    if( objCampaign.FCRM__FCR_Campaign_Sourced_By__c == 'Marketing' && (objCampaign.Campaign_Partner__c != null || objCampaign.MDF_Funded__c || ld.Is_UTM_Term_Valid__c=='Yes' || ld.UTM_Term__c == 'msft' || ld.UTM_Term__c == 'microsoft')) {
                        ld.Last_Partner_Sourced_Date__c = Date.today();
                    }
                    ld.MQL_Campaign_Type__c = finalCampaignMap.get(campaignId).Type; 
                    // CHnages added for MTK22-53 add Lead_Rejection_Reason__c in queury
                    ld.Lead_Rejection_Reason__c=null;        
                    //MKT23-651 addcode here://
                    /*if(finalCampaignMap.get(campaignId).Campaign_Sales_Area__c == 'AMER-FED' && ld.Industry_Category__c !='SLG'){
                      ld.Federal_Lead__c=true;
                     }*/
                }
                /* Princy -- moved to Lead Routing
                
                if(finalCampaignMap.get(campaignId).Routing_Method__c=='Route to Partner' && ld.ownerId != pgp.Id){
                    ld.Route_to_Partner__c = true;
                    ld.L2A_Status__c = REPROCESS;
                    ld.rerun_PatchManager__c = true;
                }else */
                if('Marketing' == finalCampaignMap.get(campaignId).FCRM__FCR_Campaign_Sourced_By__c 
                    || 'Partner' == finalCampaignMap.get(campaignId).FCRM__FCR_Campaign_Sourced_By__c){
                        //MKT24-977: Assuming L2A has run by now
                            ld.rerun_PatchManager__c = true;    
                                        } else{
                    ld.rerun_PatchManager__c = true;
                    ld.L2A_Status__c = REPROCESS;         
                }
                ld.Campaign_Sourced_By__c = finalCampaignMap.get(campaignId).FCRM__FCR_Campaign_Sourced_By__c;
                /*if(finalCampaignMap.get(campaignId).Routing_Method__c=='Direct Route to User') {
                    ld.Direct_route_to_AE_Campaign__c = true;
                 }*/
                                
                if(finalCampaignMap.get(campaignId).Amplify_Priority__c){
                    ld.Lead_Source_Most_Recent_Details__c = finalCampaignMap.get(campaignId).Name;
                    ld.Amplify_Priority__c = System.now();
                }
            } 
        }
    }
    private static void updateLastCampaignOnLead(List<CampaignMember> newCampaignMemeber, Map<Id, Lead> updateLeads) {
        for(CampaignMember newCM : newCampaignMemeber){
            if(updateLeads.containsKey(newCM.LeadId)){
                //updateLeads.get(newCM.LeadId).Last_Campaign_Type__c = newCM.status;
                updateLeads.get(newCM.LeadId).Last_Interacted_Campaign_Member__c = String.valueOf(newCM.CampaignId);
            }
            else 
                updateLeads.put(newCM.LeadId, new Lead(Id=newCM.LeadId, Last_Interacted_Campaign_Member__c = String.valueOf(newCM.CampaignId)));
        }
    }
    private static void updateScoreFieldsLeadContact(List<CampaignMember> cmWithLeads, List<CampaignMember> cmsWithContacts, Map<Id, Lead> updateLeads, Map<Id, Contact> updateContacts){
        Set<String> relatedFieldsName = new Set<String>();
        for(String fieldName : campaignTypeToContactScore.values()){
            relatedFieldsName.add(fieldName);
        }
        for(String fieldName : campaignTypeToLeadScore.values()){
            relatedFieldsName.add(fieldName);
        }
        String query = 'SELECT Id, Campaign.Type, LeadId, ContactId';
        for(String fieldName : relatedFieldsName){
            query += (','+fieldName);
        }
        query = query+ ' FROM CampaignMember WHERE (Id IN: cmWithLeads OR Id IN: cmsWithContacts) AND HasResponded = TRUE';

        List<CampaignMember> cmList = (List<CampaignMember>) Database.query(query);
        for(CampaignMember cm : cmList){
            if(cm.LeadId != null && campaignTypeToLeadScore.containsKey(cm.Campaign.Type)){
                if(!updateLeads.containsKey(cm.LeadId)){
                    updateLeads.put(cm.LeadId, cm.Lead);
                }
                Lead ldObject = updateLeads.get(cm.LeadId);
                String ldFieldName = campaignTypeToLeadScore.get(cm.Campaign.Type).subStringAfter('lead.');
                Decimal ldFieldValue = (cm.Lead.get(ldFieldName) == null) ? 1 : (Decimal)cm.Lead.get(ldFieldName) + 1;
                ldObject.put(ldFieldName, ldFieldValue);  
            } else if(cm.ContactId != null && campaignTypeToContactScore.containsKey(cm.Campaign.Type)) {
                if(!updateContacts.containsKey(cm.ContactId)){
                    updateContacts.put(cm.ContactId, cm.Contact);
                }
                Contact contactObject = updateContacts.get(cm.ContactId);
                String contactFieldName = campaignTypeToContactScore.get(cm.Campaign.Type).subStringAfter('Contact.');
                Decimal ldFieldValue = (cm.Contact.get(contactFieldName) == null) ? 1 : (Decimal)cm.Contact.get(contactFieldName) + 1;
                contactObject.put(contactFieldName, ldFieldValue);
            }
        }
    }
    private static void updatePriorityDateLeadContact(List<CampaignMember> cmWithLeads, List<CampaignMember> cmsWithContacts, Map<Id, Lead> updateLeads, Map<Id, Contact> updateContacts){
        Set<String> highPriorityCampaignName = new set<String>();
        for(MQL_High_Priortiy_Campaign__mdt rsname:[SELECT Label, MasterLabel FROM MQL_High_Priortiy_Campaign__mdt]){
            highPriorityCampaignName.add(rsname.Label);
        }
        Set<Id> setOfHighPriorityLeads = new Set<Id>();
		Set<Id> setOfHighPriorityContacts = new Set<Id>();
        if(!highPriorityCampaignName.isEmpty()){
            for(CampaignMember cm : [SELECT Id, LeadId, ContactId, Status, FCRM__FCR_Response_Date__c
                                        FROM CampaignMember
                                        WHERE (Id IN :cmWithLeads OR (Id IN :cmsWithContacts AND Contact.Account.RecordType.DeveloperName = 'Customer_Prospect'))
                                        AND Campaign.Type IN :highPriorityCampaignName]){
                if(cm.LeadId != null) {
                    Lead lObject = updateLeads.containsKey(cm.LeadId)? updateLeads.get(cm.LeadId):new Lead(Id=cm.LeadId);
                    if(cm.Status == 'Attended-Hot' && cm.FCRM__FCR_Response_Date__c != null){
                        lObject.Priority_Date__c = cm.FCRM__FCR_Response_Date__c.date();
                    }else{
                        lObject.Priority_Date__c = Date.today();
                    }
                    updateLeads.put(lObject.Id, lobject);
                    setOfHighPriorityLeads.add(lObject.Id);
                }
                else if(cm.ContactId != null){
                    Contact cObject = updateContacts.containsKey(cm.ContactId)? updateContacts.get(cm.ContactId):new Contact(Id=cm.ContactId);
                    if(cm.Status == 'Attended-Hot' && cm.FCRM__FCR_Response_Date__c != null){
                        cObject.Priority_Date__c = cm.FCRM__FCR_Response_Date__c.date();
                    }else{
                        cObject.Priority_Date__c = Date.today();
                    }
                    updateContacts.put(cObject.Id, cObject);
                    setOfHighPriorityContacts.add(cObject.Id);
                }
            }
        }
        if(!cmWithLeads.isEmpty()){
			for(CampaignMember cm: cmWithLeads){
				if(cm.LeadId != null && cm.Status == 'Attended-Hot' && !setOfHighPriorityLeads.contains(cm.LeadId)){
					Lead lObject = updateLeads.containsKey(cm.LeadId)? updateLeads.get(cm.LeadId):new Lead(Id=cm.LeadId);
					if(cm.FCRM__FCR_Response_Date__c != null){
						lObject.Priority_Date__c = cm.FCRM__FCR_Response_Date__c.date();
						updateLeads.put(lObject.Id, lobject);
					}
				}
			}
		}
		if(!cmsWithContacts.isEmpty()){
			for(CampaignMember cm: cmsWithContacts){
				if(cm.ContactId != null && cm.Status == 'Attended-Hot' && !setOfHighPriorityContacts.contains(cm.ContactId)){
					Contact cObject = updateContacts.containsKey(cm.ContactId)? updateContacts.get(cm.ContactId):new Contact(Id=cm.ContactId);
					if(cm.FCRM__FCR_Response_Date__c != null){
						cObject.Priority_Date__c = cm.FCRM__FCR_Response_Date__c.date();
						updateContacts.put(cObject.Id, cObject);
					}
				}
			}
		}
    }
    
    public static void updateContactAndLeadAfterUpdate(List<CampaignMember> newCampMemLst,Map<Id,CampaignMember> oldCampaignMemeberMap){
        System.debug('updateContactAndLeadAfterUpdate-->');
        Map<Id, Lead> updateLeads = new Map< Id, Lead>();
        Map<Id, Contact> updateContact = new  Map<Id, Contact>();
        Map<Id,Id> contactIdToCampaignId = new Map<Id,Id>();
        Map<Id,Id> leadIdToCampaignId = new Map<Id,Id>();
        Map<Id,CampaignMember> leadIdToCampaignMember = new Map<Id,CampaignMember>();
        Map<Id,CampaignMember> contactIdToCampaignMember = new Map<Id,CampaignMember>();
        
        Map<Id,Id> leadIdToCampaignId1 = new Map<Id,Id>();
        Map<Id,Id> contactIdToCampaignId1 = new Map<Id,Id>();

        Set<Id> excludeCampaignSet = new Set<Id>();

        for(HardCoded_RecordIds__mdt hr : [Select MasterLabel,Type__c from HardCoded_RecordIds__mdt where Type__c = 'Campaign-ActionableResponse']){
            Id idval = Id.ValueOf(hr.MasterLabel);
            excludeCampaignSet.add(Id.valueOf(idval));
        }

        for(CampaignMember campMem : newCampMemLst){
            if(campMem.contactId != null 
                && (campMem.FCRM__FCR_QR__c || campMem.CFCR_PQL__c)
                && (campMem.FCRM__FCR_QR__c && oldCampaignMemeberMap.get(campMem.Id).FCRM__FCR_QR__c != campMem.FCRM__FCR_QR__c 
                    || campMem.CFCR_PQL__c && oldCampaignMemeberMap.get(campMem.Id).CFCR_PQL__c != campMem.CFCR_PQL__c
                )
            ){
                contactIdToCampaignId.put(campMem.contactId,campMem.CampaignId);
                contactIdToCampaignMember.put(campMem.contactId, campMem);
            }
            if(campMem.LeadId != null
                && !excludeCampaignSet.contains(campMem.CampaignId)
                && (campMem.FCRM__FCR_QR__c || campMem.CFCR_PQL__c)
                    && (campMem.FCRM__FCR_QR__c && oldCampaignMemeberMap.get(campMem.Id).FCRM__FCR_QR__c != campMem.FCRM__FCR_QR__c 
                    || (campMem.CFCR_PQL__c && oldCampaignMemeberMap.get(campMem.Id).CFCR_PQL__c != campMem.CFCR_PQL__c)
                )
            ){
                leadIdToCampaignId.put(campMem.LeadId, campMem.CampaignId);
                leadIdToCampaignMember.put(campMem.LeadId, campMem);
            }
            
            if(campMem.hasResponded && campMem.Status != oldCampaignMemeberMap.get(campMem.Id).Status){
                if(campMem.contactId != null){
                    contactIdToCampaignId1.put(campMem.contactId, campMem.CampaignId);
                }else{
                    leadIdToCampaignId1.put(campMem.LeadId, campMem.CampaignId);
                }
                
            } 
            
        }
        if(!contactIdToCampaignId.isEmpty()){
            updateQRPQLContactFields(contactIdToCampaignId, updateContact, contactIdToCampaignMember);
        }
        if(!leadIdToCampaignId.isEmpty()){
            updateFCRCFCRLeads(leadIdToCampaignId, updateLeads, leadIdToCampaignMember);
        }
        if(!leadIdToCampaignId1.isEmpty()){
            stampLeadEngagements(leadIdToCampaignId1, updateLeads);
        }
        if(!contactIdToCampaignId1.isEmpty()){
            stampContactEngagements(contactIdToCampaignId1, updateContact);
        }
        
        if(!updateContact.isEmpty())
            update updateContact.values();
        if(!updateLeads.isEmpty()){
            update updateLeads.values();
        }
    }

    private static void updateQRPQLContactFields(Map<Id,Id> contactIdToCampaignId, Map<Id, Contact> updateContact, Map<Id, CampaignMember> contactIdToCampaignMember){
        Set<Id> excludeCampaignSet = new Set<Id>();
        
        for(HardCoded_RecordIds__mdt hr : [SELECT MasterLabel,Type__c FROM HardCoded_RecordIds__mdt 
                                        WHERE Type__c = 'Campaign-ActionableResponse']){
            excludeCampaignSet.add(Id.ValueOf(hr.MasterLabel));
        } 

        Map<Id, Campaign> validCampaigns = new Map<Id, Campaign>([SELECT Id,Name, Type , ETM_Role__c, MDF_Funded__c, RecordType.DeveloperName, Campaign_Partner__c, Campaign_Partner__r.Name, CDM__c, CDM__r.Name, Response_MQL_to_AE__c,Campaign_Theme__c,GTM_Play__c,FCRM__FCR_Campaign_Sourced_By__c, Partner_Campaign_No_SDR_Follow_Up__c,Campaign_Partner_Rep__c,Routing_Method__c
                                                                FROM Campaign 
                                                                WHERE Id IN:contactIdToCampaignId.values() 
                                                                AND ID NOT IN:excludeCampaignSet FOR UPDATE]);
        Set<Id> partnerRepIds = new Set<Id>();
        for(Id cmpId : validCampaigns.keySet()){
            partnerRepIds.add(validCampaigns.get(cmpId).Campaign_Partner_Rep__c);
        }
        Map<Id,Id> contactIdToUserId = new Map<Id,Id>();
        for(User userObj : [SELECT Id,ContactId FROM User WHERE contactId IN : partnerRepIds]){
            if(userObj.ContactId != null){
                contactIdToUserId.put(userObj.ContactId, userObj.Id);
            }
        } 
        for(Contact conObj : [SELECT id, Name, MQL_Campaign_Type__c, ETM_Role__c, HasOptedOutOfEmail, Alliance_BDM__c, MQL_Channel_Partner__c, MQL_Channel_CDM__c,  Campaign_Theme__c,GTM_Play__c,MQL__c,UTM_Source__c,UTM_Term__c,contact_status__c, Account.Account_Status__c, Account.ownerId,
                        Partner_MQL__c,Account.Adaptive_Territory_Id__c,Last_MQL_Date__c,OwnerId, AccountId, Account.Name, Account.RecordType.Name,Account.RoutingSegment__c, 
                        Latest_UTM_Term__c, Is_UTM_Term_Valid__c, Last_Applied_Routing_Modifier__c,Partner_of_Record__c
                        FROM Contact 
                        WHERE id IN: contactIdToCampaignId.keySet() 
                        AND Account.RecordType.DeveloperName='Customer_Prospect'  
                        AND MQL__c = false 
                        AND Partner_MQL__c = false FOR UPDATE]) {
            Id campaignId = contactIdToCampaignId.get(conObj.Id);
            System.debug('campaignId---'+campaignId);
            if(validCampaigns.containsKey(campaignId)){
                if(!updateContact.containsKey(conObj.Id))
                    updateContact.put(conObj.Id,conObj);
                Contact conRec = updateContact.get(conObj.Id);
                if(validCampaigns.get(campaignId).ETM_Role__c != null){
                    conRec.ETM_Role__c = validCampaigns.get(campaignId).ETM_Role__c;
                }
                if(validCampaigns.get(campaignId).Campaign_Partner__c != null){
                    conRec.MQL_Channel_Partner__c = validCampaigns.get(campaignId).Campaign_Partner__c;
                    conRec.Partner_Marketing_Campaign__c = validCampaigns.get(campaignId).Id;
                }
                if(validCampaigns.get(campaignId).CDM__c != null){
                    conRec.MQL_Channel_CDM__c = validCampaigns.get(campaignId).CDM__c;
                    conRec.Partner_Marketing_Campaign__c = validCampaigns.get(campaignId).Id;
                }
               
                conRec.Campaign_Member_Status__c =  contactIdToCampaignMember.get(conRec.Id).Status;               
                //TODO: Gaurav copy the routing modifier and populate Partner of Record
                conRec.Last_Applied_Routing_Modifier__c = validCampaigns.get(campaignId).Routing_Method__c;
                if(validCampaigns.get(campaignId).Routing_Method__c == 'Route to Partner'){
                    Id channelrepId = validCampaigns.get(campaignId).Campaign_Partner_Rep__c;
                    if(contactIdToUserId.containsKey(channelrepId)){
                        conRec.Partner_of_Record__c = contactIdToUserId.get(channelrepId);
                    }
                }

                if(validCampaigns.get(campaignId).FCRM__FCR_Campaign_Sourced_By__c == 'Partner'){
                    conRec.Partner_MQL__c = true;
                    conRec.Last_Partner_Sourced_Date__c = Date.today();
                }
                else {
                    if(validCampaigns.get(campaignId).RecordType.DeveloperName == 'Event' && (contactIdToCampaignMember.get(conRec.Id).Status == 'Attended - no engage' || contactIdToCampaignMember.get(conRec.Id).Status == 'No Show') && conRec.HasOptedOutOfEmail){
                        conRec.MQL__c = false;
                    }else{
                        conRec.MQL__c = true;
                    }
                    
                    conRec.MQL_Campaign_Type__c = validCampaigns.get(contactIdToCampaignId.get(conObj.Id)).type;
                    Campaign objCampaign = validCampaigns.get(contactIdToCampaignId.get(conObj.Id));
                    if(validCampaigns.get(campaignId).FCRM__FCR_Campaign_Sourced_By__c == 'Marketing'&& (objCampaign.Campaign_Partner__c != null || objCampaign.MDF_Funded__c || conObj.Is_UTM_Term_Valid__c == 'Yes' || conObj.UTM_Term__c == 'msft' || conObj.UTM_Term__c == 'microsoft')){
                        conObj.Last_Partner_Sourced_Date__c = Date.today();
                    }
                }
                // Added Login to display manager view for Manager if role contain SDR Manager  for MKT22-74.. //
                conRec.ContactRejectReason__c=null;
                conRec.Last_MQL_Date__c = system.today();
                conRec.Campaign_Sourced_By__c = validCampaigns.get(contactIdToCampaignId.get(conObj.Id)).FCRM__FCR_Campaign_Sourced_By__c;
                //route Contact
                if((conObj.AccountId !=null && ACTIVE_OPPORTUNITY == conObj.Account.Account_Status__c) || validCampaigns.get(contactIdToCampaignId.get(conObj.Id)).Response_MQL_to_AE__c){
                    conRec.OwnerId = conObj.Account.OwnerId;
                }
            }
        } 
    }
    /**
    * Author           :   Saakshi Gupta
    * Created Date     :   27-03-2020
    * Description      :   This method creates Opportunity if a Campaign Member responds to a campaign and the campaign
    *                      is eligible for opportunity creation. Considering only Contacts as Members. This functionality
    *                      is not applicable for Lead members currently.
    */
    public static void createOpportunityOnResponse(List<CampaignMember> newList, Map<Id, CampaignMember> oldMap, Boolean isInsert, Boolean isUpdate) {
        Set<Id> campaignIdSet = new Set<Id>();
        Set<Id> respondedMemberIdSet = new Set<Id>();
        
        //Fetch Campaign Member Ids who responded to the Campaigns and their related Campaign Ids at insertion
        if(isInsert) {
            for(CampaignMember eachMember : newList) {
                if(eachMember.HasResponded && eachMember.ContactId != null) {
                    respondedMemberIdSet.add(eachMember.Id);
                    campaignIdSet.add(eachMember.CampaignId);
                }
            }
        }
        //Fetch Campaign Member Ids who responded to the Campaigns and their related Campaign Ids at updation
        else if(isUpdate){
            for(CampaignMember eachMember : newList) {
                CampaignMember oldMember = oldMap.get(eachMember.Id);
                if(eachMember.HasResponded && !oldMember.HasResponded && eachMember.ContactId != null) {
                    respondedMemberIdSet.add(eachMember.Id);
                    campaignIdSet.add(eachMember.CampaignId);
                }
            }
        }
        
        if(!respondedMemberIdSet.isEmpty()) {
            //Fetch related Campaign information if atleast one campaign member responded to the campaign
            List<Campaign> campaignList = fetchCampaigns(campaignIdSet, respondedMemberIdSet);
            
            if(!campaignList.isEmpty()) {
                //Prepare Opportunities list if atleast one campaign is eligible for opportunity creation
                List<Opportunity> opportunityListToBeInserted = prepareOpportunities(campaignList);
                
                Database.SaveResult[] results = Database.insert(opportunityListToBeInserted, false);
                
                for(Database.SaveResult eachResult : results) {
                    if(!eachResult.isSuccess()) {
                        for(Database.Error eachError : eachResult.getErrors()) {
                            System.debug('The following error has occurred.');
                            System.debug(eachError.getStatusCode() + ': ' + eachError.getMessage());
                            System.debug('Fields that affected this error: ' + eachError.getFields());
                        }
                    }
                }
            }
        }
    }
    
    /**
    * Author           :   Saakshi Gupta
    * Created Date     :   27-03-2020
    * Description      :   This method fetches the Campaigns and associated members, which are eligible for opportunity creation
    */
    private static List<Campaign> fetchCampaigns(Set<Id> campaignIdSet, Set<Id> respondedMemberIdSet) {
        return (new List<Campaign>([SELECT Id, Name, IsActive, Description,
                                    (SELECT Id, Contact.AccountId, Contact.Account.OwnerId,
                                     Contact.Name, Contact.Account.Name
                                     FROM CampaignMembers
                                     WHERE Id =: respondedMemberIdSet)
                                    FROM Campaign
                                    WHERE Id =: campaignIdSet
                                    AND Enabled_for_Opportunity_creation__c = true]));
    }
    
    /**
    * Author           :   Saakshi Gupta
    * Created Date     :   27-03-2020
    * Description      :   This method prepares Opportunity list to be inserted related to the member who responded to the campaign
    */
    private static List<Opportunity> prepareOpportunities(List<Campaign> campaignList) {
        List<Opportunity> opportunityList = new List<Opportunity>();
        Opportunity opportunityObject;
        
        List<Campaign_To_Opportunity_Field_Mapping__mdt> fieldMappingList = [SELECT Id, Field_value__c, Opportunity_field__c, Opportunity_field_Data_type__c
                                                                             FROM Campaign_To_Opportunity_Field_Mapping__mdt];
        
        for(Campaign eachCampaign : campaignList) {
            for(CampaignMember eachMember : eachCampaign.CampaignMembers) {
                opportunityObject = new Opportunity();
                opportunityObject.Name = eachMember.Contact.Account.Name + ' - ' + eachCampaign.Name + ' - ' + eachMember.Contact.Name;
                
                //Relate the opportunity to the Account of the member who responded to the campaign
                opportunityObject.AccountId = eachMember.Contact.AccountId;
                
                //Map the owner of the Account of the member who responded to the Opportunity owner
                opportunityObject.OwnerId = eachMember.Contact.Account.OwnerId;
                
                //Set Campaign Id to the campaign related to the member who initiated opportunity creation
                opportunityObject.CampaignId = eachCampaign.Id;
                
                //Set Campaign Description to the Opportunity Next Step field
                opportunityObject.Next_Step__c = eachCampaign.Description;
                
                //Map fields directly from the data stored in Campaign to Opportunity Field mapping custom metadata
                for(Campaign_To_Opportunity_Field_Mapping__mdt eachField : fieldMappingList) {
                    if(eachField.Opportunity_field_Data_type__c.equalsIgnoreCase('Text')) {
                        opportunityObject.put(eachField.Opportunity_field__c, eachField.Field_value__c);
                    }
                    else if(eachField.Opportunity_field_Data_type__c.equalsIgnoreCase('Number')) {
                        opportunityObject.put(eachField.Opportunity_field__c, Integer.valueOf(eachField.Field_value__c));
                    }
                    else if(eachField.Opportunity_field_Data_type__c.equalsIgnoreCase('Date')) {
                        opportunityObject.put(eachField.Opportunity_field__c, System.today() + Integer.valueOf(eachField.Field_value__c));
                    }
                }
                
                opportunityList.add(opportunityObject);
            }
        }   
        return opportunityList;
    }
    public static void updateFeatureRecommendationAfterInsert(List<CampaignMember> newCampMemLst){
        Set<Id> featureRecommendationIds = new Set<Id>();
        for(CampaignMember mem : newCampMemLst){
            if(mem.Feature_Recommendation__c != null) {
                featureRecommendationIds.add(mem.Feature_Recommendation__c);
            }
        }
        if(!featureRecommendationIds.isEmpty()){
            List<Feature_Recommendation__c> updateRecommendations = new List<Feature_Recommendation__c>();
            for(Feature_Recommendation__c recommend : [SELECT Id FROM Feature_Recommendation__c 
                                                        WHERE Id IN :featureRecommendationIds AND First_Email_Sent_Date__c = null]){
                recommend.First_Email_Sent_Date__c = Date.Today();
                updateRecommendations.add(recommend);
            }
            if(!updateRecommendations.isEmpty())
                update updateRecommendations;
        }
    }
    public static void updateFeatureRecommendationAfterUpdate(List<CampaignMember> newCampMemLst,Map<Id,CampaignMember> oldCampaignMemeberMap){
        Map<Id, Date> featureRecommendIdToResponse = new Map<Id, Date>();
        for(CampaignMember mem : newCampMemLst){
            if(mem.FCRM__FCR_Response_Date__c != null && mem.FCRM__FCR_Response_Date__c != oldCampaignMemeberMap.get(mem.Id).FCRM__FCR_Response_Date__c) {
                if(
                    (
                        featureRecommendIdToResponse.containskey(mem.Feature_Recommendation__c) 
                        && featureRecommendIdToResponse.get(mem.Feature_Recommendation__c) > mem.FCRM__FCR_Response_Date__c.date()
                    )
                    || !featureRecommendIdToResponse.containskey(mem.Feature_Recommendation__c)
                ) 
                    featureRecommendIdToResponse.put(mem.Feature_Recommendation__c, mem.FCRM__FCR_Response_Date__c.date());
            }
        }
        if(!featureRecommendIdToResponse.isEmpty()){
            List<Feature_Recommendation__c> updateRecommendations = new List<Feature_Recommendation__c>();
            for(Feature_Recommendation__c recommend : [SELECT Id, Contact_Response_Date__c FROM Feature_Recommendation__c 
                                                        WHERE Id IN :featureRecommendIdToResponse.keySet() AND Contact_Response_Date__c = null]){
                recommend.Contact_Response_Date__c = featureRecommendIdToResponse.get(recommend.Id);
                updateRecommendations.add(recommend);
            }
            if(!updateRecommendations.isEmpty())
                update updateRecommendations;  
        }
            }
    private static void stampLeadEngagements(Map<Id, Id> leadIdToCampaignId, Map<Id,Lead> updateLeads){
        List<Id> campaignIds = leadIdToCampaignId.values();
        Map<Id, Campaign> finalCampaignMap = new Map<Id, Campaign>([SELECT Id, Name,type, Campaign_Type_Group__c FROM Campaign WHERE Id IN :campaignIds]);
        if(!finalCampaignMap.isEmpty()){
            for(Lead ld : [SELECT Id, P0_Engagements__c, P1_Engagements__c, P2_Engagements__c, P3_Engagements__c FROM Lead WHERE Id IN : leadIdToCampaignId.keySet()]){
                Id CampaignId = leadIdToCampaignId.get(ld.Id);
                Decimal p0_Engagment = ld.P0_Engagements__c;
                Decimal p1_Engagment = ld.P1_Engagements__c;
                Decimal p2_Engagment = ld.P2_Engagements__c;
                Decimal p3_Engagment = ld.P3_Engagements__c;
                if(finalCampaignMap.get(CampaignId).Campaign_Type_Group__c == 'P0'){
                    p0_Engagment = p0_Engagment != null ? p0_Engagment + 1 : 1;
                }else if(finalCampaignMap.get(CampaignId).Campaign_Type_Group__c == 'P1'){
                    p1_Engagment = p1_Engagment != null ? p1_Engagment + 1 : 1;
                }else if(finalCampaignMap.get(CampaignId).Campaign_Type_Group__c == 'P2'){
                    p2_Engagment = p2_Engagment != null ? p2_Engagment + 1 : 1;
                }else if(finalCampaignMap.get(CampaignId).Campaign_Type_Group__c == 'P3'){
                    p3_Engagment = p3_Engagment != null ? p3_Engagment + 1 : 1;
                }
                
                if(!updateLeads.containsKey(ld.Id)){
                    updateLeads.put(ld.Id, ld);
                }else{
                    ld = updateLeads.get(ld.Id);
                }
                ld.P0_Engagements__c = p0_Engagment;
                ld.P1_Engagements__c = p1_Engagment;
                ld.P2_Engagements__c = p2_Engagment;
                ld.P3_Engagements__c = p3_Engagment;
                
                //Added for MKT26-1526
                ld.UTM_Campaign__c = null;
                ld.UTM_Medium__c = null;
                ld.UTM_Source__c = null;
                ld.UTM_Term__c = null;
                ld.UTM_Content__c =null;
                ld.UTM_Type__c = null;
                ld.UTM_Partner__c = null;
                ld.website_asset__c = null;
                ld.website_placement__c = null;
                
            }
        }
    }
    private static void stampContactEngagements(Map<Id, Id> contactIdToCampaignId, Map<Id,Contact> updateContacts){
        List<Id> campaignIds = contactIdToCampaignId.values();
        Map<Id, Campaign> finalCampaignMap = new Map<Id, Campaign>([SELECT Id, Name,type, Campaign_Type_Group__c FROM Campaign WHERE Id IN :campaignIds]);
        if(!finalCampaignMap.isEmpty()){
            for(Contact con : [SELECT Id, P0_Engagements__c, P1_Engagements__c, P2_Engagements__c, P3_Engagements__c FROM Contact WHERE Id IN : contactIdToCampaignId.keySet()]){
                Id CampaignId = contactIdToCampaignId.get(con.Id);
                Decimal p0_Engagment = con.P0_Engagements__c;
                Decimal p1_Engagment = con.P1_Engagements__c;
                Decimal p2_Engagment = con.P2_Engagements__c;
                Decimal p3_Engagment = con.P3_Engagements__c;
                if(finalCampaignMap.get(CampaignId).Campaign_Type_Group__c == 'P0'){
                    p0_Engagment = p0_Engagment != null ? p0_Engagment + 1 : 1;
                }else if(finalCampaignMap.get(CampaignId).Campaign_Type_Group__c == 'P1'){
                    p1_Engagment = p1_Engagment != null ? p1_Engagment + 1 : 1;
                }else if(finalCampaignMap.get(CampaignId).Campaign_Type_Group__c == 'P2'){
                    p2_Engagment = p2_Engagment != null ? p2_Engagment + 1 : 1;
                }else if(finalCampaignMap.get(CampaignId).Campaign_Type_Group__c == 'P3'){
                    p3_Engagment = p3_Engagment != null ? p3_Engagment + 1 : 1;
                }
                
                if(!updateContacts.containsKey(con.Id)){
                    updateContacts.put(con.Id, con);
                }else{
                    con = updateContacts.get(con.Id);
                }
                con.P0_Engagements__c = p0_Engagment;
                con.P1_Engagements__c = p1_Engagment;
                con.P2_Engagements__c = p2_Engagment;
                con.P3_Engagements__c = p3_Engagment;

                //Added for MKT26-1526
                con.UTM_Campaign__c = null;
                con.UTM_Medium__c = null;
                con.UTM_Source__c = null;
                con.UTM_Term__c = null;
                con.UTM_Content__c =null;
                con.UTM_Type__c = null;
                con.UTM_Partner__c = null;
                con.website_asset__c = null;
                con.website_placement__c = null;
            }
        }
    }
    
    
      /**
 * @description Crteates a Platform Event whenever a Status change of Lead/Contact happened or Lead is converted
 */
    public static void triggerCapiNotificationEvent(List<CampaignMember> newCampaignMembers, Map<Id, CampaignMember> oldCampaignMemberById)
    {
        Map<Id, Set<String>> personIdToEventNames = new Map<Id, Set<String>>();
        Map<Id, CampaignMember> personIdToCampaignMember = new Map<Id, CampaignMember>();
        
        Set<Id> contactIds = new Set<Id>();
        Set<Id> leadIds = new Set<Id>();
        
        for(CampaignMember currentCM : newCampaignMembers){
            CampaignMember previousCM = oldCampaignMemberById.get(currentCM.Id);
            if(previousCM == null) continue;
            
            if(String.isBlank(currentCM.UTM_Source__c) || !currentCM.UTM_Source__c.toLowerCase().contains('linkedin'))
                continue;
            
            Id personId = currentCM.ContactId != null ? currentCM.ContactId : currentCM.LeadId;
            if(personId == null) continue;
            
            Set<String> resolvedEvents = resolveEventNames(currentCM, previousCM);
                        if(resolvedEvents.isEmpty()) continue;
            
            if(!personIdToEventNames.containsKey(personId))
                personIdToEventNames.put(personId, new Set<String>());
            
            personIdToEventNames.get(personId).addAll(resolvedEvents);
            personIdToCampaignMember.put(personId, currentCM);
            
            if(currentCM.ContactId != null)
                contactIds.add(currentCM.ContactId);
            else
                leadIds.add(currentCM.LeadId);
        }
        
        if(personIdToEventNames.isEmpty()) return;
        Map<Id, Contact> contactById = new Map<Id, Contact>();
       for (SObject sob :  fetchRecordsByPrivacy(Contact.SObjectType,'Contact',contactIds,'FirstName, LastName, Email, Title, AccountId, MailingCountryCode').values()
            ) {
                contactById.put(sob.Id, (Contact) sob);
            }
        
        Map<Id, Lead> leadById = new Map<Id, Lead>();
        for (SObject sob :
             fetchRecordsByPrivacy(  Lead.SObjectType,  'Lead',  leadIds,  'FirstName, LastName, Email, Title, Company, Winning_L2A_Account__c, CountryCode').values()
            ) {
                leadById.put(sob.Id, (Lead) sob);
            }
        
        filterByDataUsePermission(personIdToEventNames,personIdToCampaignMember,contactById,leadById);
        
        if(personIdToEventNames.isEmpty()) return;    
        publishCapiPlatformEvents(personIdToEventNames,personIdToCampaignMember,contactById,leadById);
    }
    
    private static Map<Id, SObject> fetchRecordsByPrivacy(
        Schema.SObjectType sobjectType,
        String objectName,
        Set<Id> recordIds,
        String baseFields
    ) {
        Map<Id, SObject> recordsById = new Map<Id, SObject>();
        
        if (recordIds == null || recordIds.isEmpty()) {
            return recordsById;
        }
        
        String privacyField = getPrivacyField(sobjectType);
        if (privacyField == null) {
            return recordsById;
        }
        
        String soql =
            'SELECT Id, ' + String.escapeSingleQuotes(baseFields) + ', ' + String.escapeSingleQuotes(privacyField) +
            ' FROM ' + String.escapeSingleQuotes(objectName) +
            ' WHERE Id IN :recordIds' +
            ' AND Do_Not_Sell_Share__c = FALSE' +
            ' AND ' + String.escapeSingleQuotes(privacyField) + ' = TRUE';
        
        for (SObject sob : Database.query(soql)) {
            recordsById.put(sob.Id, sob);
        }
        
        return recordsById;
    }

    private static String getPrivacyField(Schema.SObjectType sobjectType) {
    Map<String, Schema.SObjectField> fields =
        sobjectType.getDescribe().fields.getMap();

    if (fields.containsKey('data_use_permitted__c')) {
        return 'data_use_permitted__c';
    }
    if (fields.containsKey('limited_use__c')) {
        return 'limited_use__c';
    }
    if (fields.containsKey('privacy_compliance__c')) {
        return 'privacy_compliance__c';
    }
    return null;
}


    private static Set<String> resolveEventNames(
        CampaignMember currentCM,
        CampaignMember previousCM
    ){
        Set<String> events = new Set<String>();
        
        if((
            currentCM.FCRM__FCR_QR__c && currentCM.FCRM__FCR_Response_Status__c == 'Non-Qualified' && previousCM.FCRM__FCR_Response_Status__c != 'Non-Qualified') || 
           (currentCM.CFCR_SRL__c == TRUE && previousCM.CFCR_SRL__c == FALSE && currentCM.CFCR_Current_Lead_Contact_Status__c == 'Non-Qualified')
        ){
            events.add('Non Qualified MQL');
        }
        
        if(
            currentCM.FCRM__FCR_Inquiry_Target__c && !previousCM.FCRM__FCR_Inquiry_Target__c
        ){
            events.add('Inquiry');
        }
        
        if(
            currentCM.FCRM__FCR_QR__c &&
            !previousCM.FCRM__FCR_QR__c
        ){
            events.add('MQL');
        }
        
        if(
            currentCM.FCRM__FCR_SAR__c &&
            !previousCM.FCRM__FCR_SAR__c
        ){
            events.add('SAL');
        }
        
        if(
            currentCM.CFCR_Meeting_Set__c &&
            !previousCM.CFCR_Meeting_Set__c
        ){
            events.add('Meeting Set');
        }
        
        if(
            currentCM.FCRM__FCR_SQR__c &&
            !previousCM.FCRM__FCR_SQR__c
        ){
            events.add('Opportunity Created');
        }
        
        if(
            currentCM.CFCR_Forecasted_Opp__c &&
            !previousCM.CFCR_Forecasted_Opp__c
        ){
            events.add('Forecasted Opportunity');
        }
        
        if(
            currentCM.FCRM__FCR_SQR_Won__c &&
            !previousCM.FCRM__FCR_SQR_Won__c
        ){
            events.add('Closed Won');
        }
        
        return events;
    }
    
    
    private static void filterByDataUsePermission(Map<Id, Set<String>> personIdToEventNames,Map<Id, CampaignMember> personIdToCampaignMember,Map<Id, Contact> contactById,Map<Id, Lead> leadById)
    {     
        
       
        for(Id personId : new Set<Id>(personIdToEventNames.keySet())){
            if(! (contactById.containsKey(personId) || leadById.containsKey(personId))){
                personIdToEventNames.remove(personId);
                personIdToCampaignMember.remove(personId);
            }
        }
    }
    
     /**
 * @description Publish a platform event to be picked up by the Mulesopft team
 */
  public static void publishCapiPlatformEvents(
    Map<Id, Set<String>> personIdToEventNames,
    Map<Id, CampaignMember> personIdToCampaignMember,
    Map<Id, Contact> contactById,
    Map<Id, Lead> leadById
){
    Map<String, String> eventNameToEndpoint = new Map<String, String>();
    for(CAPI_Event_Endpoint_Mapping__c mapping :
        [SELECT Event_Name__c,ConversionEventId__c
         FROM CAPI_Event_Endpoint_Mapping__c]){
        eventNameToEndpoint.put(
            mapping.Event_Name__c,
            mapping.ConversionEventId__c
        );
    }

    Set<Id> accountIds = new Set<Id>();

    for(Contact contact : contactById.values())
        if(contact.AccountId != null)
            accountIds.add(contact.AccountId);

    for(Lead lead : leadById.values())
        if(lead.Winning_L2A_Account__c != null)
            accountIds.add(lead.Winning_L2A_Account__c);

    Map<Id, Account> accountById = accountIds.isEmpty()
        ? new Map<Id, Account>()
        : new Map<Id, Account>(
            [SELECT Id, Name FROM Account WHERE Id IN :accountIds]
        );

    List<CAPI_Event_Notification__e> eventsToPublish =
        new List<CAPI_Event_Notification__e>();

    for(Id personId : personIdToEventNames.keySet()){
        Contact contact = contactById.get(personId);
        Lead lead = leadById.get(personId);
        if(contact == null && lead == null) continue;

        String emailAddress =
            contact != null ? contact.Email : lead.Email;
        if(String.isBlank(emailAddress)) continue;

        CampaignMember campaignMember =
            personIdToCampaignMember.get(personId);

        for(String eventName : personIdToEventNames.get(personId)){
            CAPI_Event_Notification__e platformEvent =
                new CAPI_Event_Notification__e();

            platformEvent.Event_Name__c = eventName;
            platformEvent.ConversionEventId__c = eventNameToEndpoint.get(eventName);

            platformEvent.ConversionEventHappened__c =
                System.currentTimeMillis(); 
           

            platformEvent.MACV__c =
                campaignMember.FCRM__FCR_Opportunity_Amount__c;

            platformEvent.CountryCode__c =
                contact != null
                    ? contact.MailingCountryCode
                    : lead.CountryCode;

            platformEvent.Email__c = EncodingUtil.convertToHex(
                Crypto.generateDigest(
                    'SHA-256',
                    Blob.valueOf(emailAddress)
                )
            );

            platformEvent.FirstName__c =
                contact != null ? contact.FirstName : lead.FirstName;
            platformEvent.LastName__c =
                contact != null ? contact.LastName : lead.LastName;
            platformEvent.Job_Title__c =
                contact != null ? contact.Title : lead.Title;

            platformEvent.Account_Name__c =
                contact != null &&
                accountById.containsKey(contact.AccountId)
                    ? accountById.get(contact.AccountId).Name
                    : lead != null &&
                      accountById.containsKey(lead.Winning_L2A_Account__c)
                        ? accountById.get(lead.Winning_L2A_Account__c).Name
                        : lead != null ? lead.Company : '';

            platformEvent.Record_Id__c =  campaignMember.Id;

            eventsToPublish.add(platformEvent);
            system.debug('eventsToPublish'+eventsToPublish);
        }
    }

    if(!eventsToPublish.isEmpty()){
        EventBus.publish(eventsToPublish);
    }
}

    
    
    }