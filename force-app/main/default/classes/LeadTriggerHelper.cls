/** 
 * @description This class is used to handle the lead trigger logic.
 * @author      :   Princy Jain
 * @createdDate :   22nd March 2021
 */
public class LeadTriggerHelper {
    private static Set<String> leadSourceSalesInboundSet = new Set<String>{'Content', 'Content Syndication', 'Email', 'Field Marketing', 'List Purchase', 'Promotions', 'Promotion', 'Social Media', 'Trade Show','Web', 'Webinar', 'Contact Sales', 'Channel List', 'Event partner'};
    private static Set<String> leadSourceSalesOutboundSet = new Set<String>{'Sales','LinkedIn','linkedin'};
    public static string NON_QUALIFIED = 'Non-Qualified';
    private static string OPEN = 'Open';
    private static string REPROCESS = 'Reprocess';
    //private static string MARKETING_Nurture = 'Nurture';
    private static string RAW = 'RAW';
    //private static string SALES_NURTURE = 'Nurture';
    private static Set<String> latticeGradeSet = new Set<String>{'a', 'b', 'c'};
    private static Set<String> campaignTypeSet = new Set<String>{'Digital','EBC','Field Marketing','Email','Paid Social','PPC','Promotions','Referral','Telemarketing','Trade Show','User Conference','Web','Webinar','Corporate-Sponsored Event'};
    private static string PARTNER_ROUNTING_QUEUE = 'Partner_Routing_Queue';
    private static string AMERMMQUEUEID = 'AMER-MM';
    private static final Set<String> setL2ATriggerFields = new Set<String>{'company', 'countrycode', 'postalcode', 'email'}; 
    public static Set<Id> setPatchManagerAfterMQL = new Set<Id>();

    private static Map<Id, Id> accountIdToSDR = new Map<Id, Id>();
    private static Map<Id, Id> accountIdToIAM = new Map<Id, Id>();
    private static Map<Id, Id> accountIdToAE = new Map<Id, Id>();

    private static Set<String> allIAMAreas = new Set<String> { 'ENT', 'MAJORS', 'AMER-FED', 'AMER-SLED', 'CEUR', 'NEUR', 'SEUR', 'MEA', 'WEUR', 'UK-IRL-MEA', 'ANZ'};
        
    /**
     * @description This method is used to filter out the leads which are not qualified based on the RiffRaff list.
     * @param newLeadList List<Lead> - List of leads to be filtered
     * @author      :   Princy Jain
     */
    public void riffraffFilter(List<Lead> newLeadList) {
        Map<String,List<string>> riffraffMap = new Map<String,List<string>>();
        for(Lead_RiffRaff__c rr : Lead_RiffRaff__c.getall().values()){
            if(riffraffMap.containsKey(rr.Type__c))
                riffraffMap.get(rr.Type__c).add(rr.Name.toLowerCase());
            else
                riffraffMap.put(rr.Type__c, new List<string>{rr.Name.toLowerCase()});

        }
        if(!riffraffMap.isEmpty()){
            for(Lead ld : newLeadList){
                if(!ld.Deal_Registration__c){
                    if(
                        !ld.P_0_Response__c
                        && NON_QUALIFIED != ld.status
                        && (
                            (
                                !string.isBlank(ld.Company)
                                && riffraffMap.containsKey('Company')
                                && riffraffMap.get('Company').contains(ld.company.toLowerCase())
                            ) || (
                                !String.isBlank(ld.email)
                                && riffraffMap.containsKey('Domain')
                                && riffraffMap.get('Domain').contains(ld.email.substringAfter('@').toLowerCase())
                            ) || (
                                !string.isBlank(ld.Title)
                                && riffraffMap.containsKey('Title')
                                && riffraffMap.get('Title').contains(ld.Title.toLowerCase())
                            ) || (
                                riffraffMap.containsKey('Name') &&
                                (
                                    !string.isBlank(ld.FirstName)
                                    && riffraffMap.get('Name').contains(ld.FirstName.toLowerCase())
                                ) || (
                                    !string.isBlank(ld.LastName)
                                    && riffraffMap.get('Name').contains(ld.LastName.toLowerCase())
                                )
                            )
                        )
                     ){
                        ld.status = NON_QUALIFIED;
                       ld.Lead_Rejection_Reason__c = Label.LeadRejectRiffRaff;
                    }
                    if(ld.MQL__c || ld.Partner_MQL__c)
                        ld.Last_MQL_Date__c = system.today();
                    if(ld.SAL__c)
                        ld.Last_SAL_Date__c = system.today();
                }
            }
        }
    }

    /**
     * @description This method is used to update the MQL and SAL fields on Lead object before update.
     * @param newLeadList List<Lead> - List of leads to be updated
     * @param oldLeadMap Map<Id,Lead> - Map of old lead records
     * @author      :   Princy Jain
     */
    public void mqlUpdatesBeforeUpdate(List<Lead> newLeadList, Map<Id,Lead> oldLeadMap){
        for(Lead ld : newLeadList){
            if(oldLeadMap.get(ld.Id).status != ld.status && (ld.status == 'Nurture' || ld.status == 'Non-Qualified')){
                      ld.MQL__c = false;
                      ld.Partner_MQL__c = false;
            }
            Boolean updatedMQL = oldLeadMap.get(ld.Id).MQL__c == false && ld.MQL__c ? true : false;
            if(updatedMQL || (oldLeadMap.get(ld.Id).Partner_MQL__c == false && ld.Partner_MQL__c)){
                ld.Last_MQL_Date__c = system.today();
                ld.Touches_since_MQL__c = 0;
                ld.Winning_L2A_Account__c = ld.Winning_L2A_System__c=='SF' ? ld.L2A_Account__c : (ld.Winning_L2A_System__c=='OP'?ld.OP_L2A_Account__c : null);
            }
            if(((oldLeadMap.get(ld.Id).MQL__c && ld.MQL__c == false) || (oldLeadMap.get(ld.Id).Partner_MQL__c && ld.Partner_MQL__c == false)) && !ld.Deal_Registration__c){
                ld.UnMQL_Date__c = system.today();
            }
            if(!ld.Deal_Registration__c && !ld.SAL__c && (ld.status == 'Working' || ld.status == 'Meeting Set') && oldLeadMap.get(ld.Id).status == 'Open'){
                ld.SAL__c = true;
               
            }
            if(ld.SAL__c && !oldLeadMap.get(ld.Id).SAL__c){
                ld.Last_SAL_Date__c = system.today();
            }
            
        }
    }
    
    /**
     * @description This method is used to update the Lead Rejection Reason field on Lead object.
     * @param newLeadList List<Lead> - List of leads to be updated
     * @param oldLeadMap Map<Id,Lead> - Map of old lead records
     * 
     */
    public void setLeadRejectReasonBlank (List<Lead> newLeadList, Map<Id,Lead> oldLeadMap) {
          for(Lead ld : newLeadList){
              
            if(oldLeadMap.get(ld.Id).status != ld.status && (ld.status == 'Open' || ld.status == 'RAW' || ld.status == 'Working' || ld.status == 'Meeting Set')){  
               ld.Lead_Rejection_Reason__c=null;
            }
              
          }
    }
  
    /**
     * @description This method is used to update the Lead Rejection Reason field on Lead object.   
     * @param newLeadList List<Lead> - List of leads to be updated
     * @param oldLeadMap Map<Id,Lead> - Map of old lead records
     */
    public void rerunLeadRamdomLogic (List<Lead> newLeadList, Map<Id,Lead> oldLeadMap) {
        List<GroupMember> MemeberList = RoutingUtil.getMMQueueMemeberList('AMERMM');
        Set<Id> UserList = RoutingUtil.getAvailableUsers(MemeberList);
        List<GroupMember> MemeberListJapan = new List<GroupMember>(); 
        Set<Id> availableUsersJapan = new Set<Id>() ;
        MemeberListJapan=RoutingUtil.getMMQueueMemeberList('JAPAN');
       availableUsersJapan=RoutingUtil.getAvailableUsers(MemeberListJapan);
        for(Lead ld : newLeadList){
            if(oldLeadMap.get(ld.Id).ReassignLead__c != ld.ReassignLead__c && ld.ReassignLead__c==true  ){ 
                if ('JAPAN-A'==ld.Area__c ) {
                    
                    if(!availableUsersJapan.iSEmpty())
                        ld.OwnerId=RoutingUtil.generateRandomOwner(availableUsersJapan); 
                    ld.ReassignLead__c=false;
                }
                else {
                    ld.addError('You can only Reassign Lead for this Segmentsation.');
                }
                
            }
        }
    }
    /**
     * @description This method is used to update winning L2A account owner on Lead object. 
     * @param newLeadList List<Lead> - List of leads to be updated
     * @param oldLeadMap Map<Id,Lead> - Map of old lead records
     */
    public void updateWinl2AAccountOwner(List<Lead> newLeadList, Map<Id,Lead> oldLeadMap){
            map<String,String> accountOwberMap = new map<String,String>();
            set<String> accountIds = new set<String>();
            set<String> leadIdsMap = new set<String>();
            for(Lead ld : newLeadList){
                if(ld.Winning_L2A_Account__c !=null && oldLeadMap.get(ld.Id).Winning_L2A_Account__c != ld.Winning_L2A_Account__c){
                accountIds.add(ld.Winning_L2A_Account__c);
                leadIdsMap.add(ld.id);
             } 
        }
        if(accountIds.size()>0) {
           List<Account> accoutOwnerList = [Select id,name,OwnerId from Account where id IN:accountIds];
           
           for(Account rsAccopunt: accoutOwnerList) {
               accountOwberMap.put(rsAccopunt.Id,rsAccopunt.OwnerId);
           }
        }
        
        for(Lead ld : newLeadList){
                if(ld.Winning_L2A_Account__c !=null && oldLeadMap.get(ld.Id).Winning_L2A_Account__c != ld.Winning_L2A_Account__c){
                 if(accountOwberMap.containsKey(ld.Winning_L2A_Account__c)){
                  ld.Winning_Account_Owner__c= accountOwberMap.get(ld.Winning_L2A_Account__c);
                 }
                } else if(ld.Winning_L2A_Account__c ==null) {
                    ld.Winning_Account_Owner__c=null;
                }
        }
       
    }
    /**
     * @description This method is used to update fields on status change.
     * @param newLeadList List<Lead> - List of leads to be updated
     * @param oldLeadMap Map<Id,Lead> - Map of old lead records
     */
    public void onStatusChange(List<Lead> newLeadList, Map<Id, Lead> oldLeadMap){
        List<Lead> leadsOfInterest = (oldLeadMap==null)?newLeadList: getLeadsWithStatus(newLeadList, oldLeadMap);
        if(!leadsOfInterest.isEmpty()){
            if(!WorkflowTriggerBypass__c.getInstance('updateLastOwnershipUpdateDate').ByPassTrigger__c){
                updateLastStatusChangeDate(leadsOfInterest);
            }
        }
    }
    /**
     * @description This method is used to update the last status change date on Lead object.
     * @param leadsOfInterest List<Lead> - List of leads to be updated
     */
    public void updateLastStatusChangeDate(List<Lead> leadsOfInterest){
        for(Lead L1 : leadsOfInterest){
            if(L1.Status != null)
                L1.Last_Status_Updated_TimeStamp__c = system.now();
        }
    }
    /**
     * @description This method is used to get the leads with status changed.
     * @param newLeadList List<Lead> - List of new leads
     * @param oldLeadMap Map<Id, Lead> - Map of old lead records
     * @return List<Lead> - List of leads with status changed
     */
    private List<Lead> getLeadsWithStatus(List<Lead> newLeadList, Map<Id, Lead> oldLeadMap){
        List<Lead> leads = new List<Lead>();
        for(Lead L1 : newLeadList){
            if(L1.Status != oldLeadMap.get(L1.Id).Status)
                leads.add(L1);
        }
        return leads;
    }
    /**
     * @description This method is used to set the status to RAW for leads of interest.
     * @param leadsOfInterest List<Lead> - List of leads to be updated
     */
    public void setStatusToRaw(List<Lead> leadsOfInterest){
        for(Lead lObject: leadsOfInterest){
            if('DiscoverOrg'  == lObject.LeadSource
                || 'Sales'  == lObject.LeadSource
                || String.isBlank(lObject.LeadSource)
                &&(
                    'Non-Qualified'  != lObject.Status
                    && Label.LeadRejectRiffRaff != lObject.Lead_Rejection_Reason__c
                )
            )
                lObject.Status = 'RAW';
        }
    }
    /**
     * @description This method is used to reset the Agreed to Edge Trail Agreement field on Lead object.
     * @param newLeadList List<Lead> - List of new leads
     * @param oldLeadMap Map<Id, Lead> - Map of old lead records
     */
    public void resetAgreedToEdgeTrailAgreement(List<Lead> newLeadList, Map<Id, Lead> oldLeadMap){
        List<Lead> leadsOfInterest = (oldLeadMap==null)?newLeadList: getLeadsWithAgreedToEdgeTrailAgreement(newLeadList, oldLeadMap);
        for(Lead L1 : leadsOfInterest){
            if(L1.Agreed_to_Edge_Trail_Agreement__c )
                L1.Agree_to_Edge_Trial_Date__c = System.Today();
        }
    }
    /**
     * @description This method is used to get the leads with Agreed to Edge Trail Agreement field changed.
     * @param newLeadList List<Lead> - List of new leads
     * @param oldLeadMap Map<Id, Lead> - Map of old lead records
     * @return List<Lead> - List of leads with Agreed to Edge Trail Agreement field changed
     */
    private List<Lead> getLeadsWithAgreedToEdgeTrailAgreement(List<Lead> newLeadList, Map<Id, Lead> oldLeadMap){
        List<Lead> leads = new List<Lead>();
        for(Lead L1 : newLeadList){
            if(L1.Agreed_to_Edge_Trail_Agreement__c && !oldLeadMap.get(L1.Id).Agreed_to_Edge_Trail_Agreement__c){
                leads.add(L1);
            }
        }
        return leads;
    }
    /**
     * @description This method is used to reset the ownership change date on Lead object.
     * @param newLeadList List<Lead> - List of new leads
     * @param oldLeadMap Map<Id, Lead> - Map of old lead records 
     */
    public void resetOwnershipChangeDate(List<Lead> newLeadList, Map<Id, Lead> oldLeadMap){
        List<Lead> leadsOfInterest = (oldLeadMap==null)?newLeadList: getLeadsWithLeadOwnerChanged(newLeadList, oldLeadMap);
        for(Lead newObj : leadsOfInterest){
            newObj.Last_Ownership_Changed_Date__c = System.now();
        }
    }
    /**
     * @description This method is used to get the leads with lead owner changed.
     * @param newLeadList List<Lead> - List of new leads
     * @param oldLeadMap Map<Id, Lead> - Map of old lead records
     * @return List<Lead> - List of leads with lead owner changed
     */
    private List<Lead> getLeadsWithLeadOwnerChanged(List<Lead> newLeadList, Map<Id, Lead> oldLeadMap){
        List<Lead> leads = new List<Lead>();
        for(Lead newObj : newLeadList){
            if(oldLeadMap.get(newObj.Id).Lead_Owner__c !=  newObj.Lead_Owner__c){
                leads.add(newObj);
            }
        }
        return leads;
    }
    /**
     * @description This method is used to reset the L2A status on Lead object.
     * @param newLeadList List<Lead> - List of new leads
     * @param oldLeadMap Map<Id, Lead> - Map of old lead records
     */
    public void resetL2Astatus(List<Lead> newLeadList, Map<Id, Lead> oldLeadMap){
        for(Lead newObj : newLeadList){
            Lead oldObj = oldLeadMap.get(newObj.Id);
            if(newObj.L2A_Status__c == 'PROCESSED' &&  newObj.Status != 'Meeting Set' && (
                oldObj.Company  !=  newObj.Company || oldObj.Street  !=  newObj.Street ||
                oldObj.Country  !=  newObj.Country || oldObj.City  !=  newObj.City ||
                oldObj.State  !=  newObj.State || oldObj.PostalCode  !=  newObj.PostalCode ||
                oldObj.Phone  !=  newObj.Phone || oldObj.Email  !=  newObj.Email
            )
            ){
                newObj.L2A_Status__c = 'Reprocess';
            }
        }
    }
    /**
     * @description This method is used to reset the fields on Lead object.
     * @param newLeadList List<Lead> - List of new leads
     */
    public void resetFields(List<Lead> newLeadList){
        for(Lead newObj : newLeadList){
            newObj.skipValidationRules__c = false;
            newObj.Sell_to_Partner_Text__c = newObj.Sell_to_Partner__c;
        }
    }
    /**
     * @description This method is used to update the last ownership update date on Lead object.
     * @param newLeadList List<Lead> - List of new leads
     * @param oldLeadMap Map<Id, Lead> - Map of old lead records
     */
    public void updateLastOwnershipUpdateDate(List<Lead> newLeadList, Map<Id, Lead> oldLeadMap){
        if(!WorkflowTriggerBypass__c.getInstance('updateLastOwnershipUpdateDate').ByPassTrigger__c){
            List<Lead> leadsOfInterest = (oldLeadMap==null)?newLeadList: getLeadsWithChangedOwnerid(newLeadList, oldLeadMap);
            for(Lead L1 : leadsOfInterest){
                if(L1.OwnerId != null){
                    L1.Last_Ownership_Changed_Date__c = system.now();
                }
            }
        }
    }
    /**
     * @description This method is used to get the leads with changed owner id.
     * @param newLeadList List<Lead> - List of new leads
     * @param oldLeadMap Map<Id, Lead> - Map of old lead records
     * @return List<Lead> - List of leads with changed owner id
     */
    private List<Lead> getLeadsWithChangedOwnerid(List<Lead> newLeadList, Map<Id, Lead> oldLeadMap){
        List<Lead> leads = new List<Lead>();
        for(Lead newObj : newLeadList){
            if(oldLeadMap.get(newObj.Id).OwnerId !=  newObj.OwnerId){
                leads.add(newObj);
            }
        }
        return leads;
    }
    /**
     * @description This method is used to update the status to Sales Loft on Lead object.
     * @param newLeadList List<Lead> - List of new leads
     * @param oldLeadMap Map<Id, Lead> - Map of old lead records
     */
    public void updateStatusToSalesLoft(List<Lead> newLeadList, Map<Id, Lead> oldLeadMap){
        if(!WorkflowTriggerBypass__c.getInstance('updateLastOwnershipUpdateDate').ByPassTrigger__c){
            for(Lead L1 : newLeadList){
                if(L1.SalesloftPersonStatus__c!=null && L1.SalesloftPersonStatus__c != oldLeadMap.get(L1.Id).SalesloftPersonStatus__c){
                    L1.Status = L1.SalesloftPersonStatus__c;
                }
            }
        }
    }
    /**
     * @description This method is used to rerun the Patch Manager on Lead object.
     * @param newLeadList List<Lead> - List of new leads
     * @param oldLeadMap Map<Id, Lead> - Map of old lead records
     */
    public void rerunPatchManager(List<Lead> newLeadList, Map<Id, Lead> oldLeadMap){
        List<Lead> assignLeadList = new List<Lead>();
        for(Lead lObject : newLeadList){
            if(lObject.rerun_PatchManager__c && !oldLeadMap.get(lObject.Id).rerun_PatchManager__c){
                assignLeadList.add(lObject);
            }
        }
        Map<Id, String> leadIdToCampaignRoutingMethod = new Map<Id, String>();
        for(CampaignMember cmpMem : [SELECT Id, Campaign.Routing_Method__c, CampaignId, LeadId FROM CampaignMember 
                                     WHERE LeadId IN : assignLeadList AND 
                                     CFCR_Current_Stage_in_Funnel__c IN ('Meeting Set', 'MQL', 'Inside Sales Accepted Lead')]){
            if(!leadIdToCampaignRoutingMethod.containsKey(cmpMem.LeadId)){
                leadIdToCampaignRoutingMethod.put(cmpMem.LeadId, cmpMem.Campaign.Routing_Method__c);
            }
        }
        if(!assignLeadList.isEmpty()) {
            try {
                assignPatchManager(assignLeadList);
                for( Lead objlead : assignLeadList ) {
                    objlead.PatchManager_Status_Message__c = 'Success';
                    objlead.Last_Applied_Routing_Modifier__c = leadIdToCampaignRoutingMethod.containsKey(objlead.Id) ? leadIdToCampaignRoutingMethod.get(objlead.Id) : 'MQL to SDR';
                }
            }catch(Exception e) {
                for( Lead objlead : assignLeadList ) {
                    objLead.rerun_PatchManager__c = false;
                    objlead.PatchManager_Status_Message__c = e.getMessage() + '\n' + e.getStackTraceString();
                }
            }
        }
    }
    /**
     * @description This method is used to assign the Patch Manager on Lead object.
     * @param assignLeadList List<Lead> - List of leads to be assigned
     * @param oldLeadMap Map<Id, Lead> - Map of old lead records
     */
    public void setP0ResposeDate(List<Lead> newLeadList, Map<Id, Lead> oldLeadMap){
        List<Lead> leadsOfInterest = (oldLeadMap==null)?newLeadList: getP0ResposeChanged(newLeadList, oldLeadMap);
        for(Lead lObject : leadsOfInterest){
            if(lObject.P_0_Response__c)
               lObject.P_0_Response_Date__c =  DateTime.now();
        }
    }
    /**
     * @description This method is used to get the leads with P0 response changed.
     * @param newLeadList List<Lead> - List of new leads
     * @param oldLeadMap Map<Id, Lead> - Map of old lead records
     * @return List<Lead> - List of leads with P0 response changed
     */
    private List<Lead> getP0ResposeChanged(List<Lead> newLeadList, Map<Id, Lead> oldLeadMap) {
        List<Lead> leads = new List<Lead>();
        for(Lead newObj : newLeadList){
            if(oldLeadMap.get(newObj.Id).P_0_Response__c !=  newObj.P_0_Response__c){
                leads.add(newObj);
            }
        }
        return leads;
    }

    /** 
     * @description CS21-104, CS21-393 : Update an existing contact when Agree To Edge Trial flag is checked on corresponding Lead
     * @author Saakshi Gupta
     * @createdDate  26th March 2021
     * @param newLeadList List<Lead> - List of new leads
     * @param oldLeadMap Map<Id, Lead> - Map of old lead records
    */
    public void processContactForEdgeTrial(List<Lead> newLeadList, Map<Id, Lead> oldLeadMap) {
        List<Contact> contactListToBeUpserted = new List<Contact>();
        Set<String> emailSet = new Set<String>();

        //Create a set of emails of Leads for which Agree to Edge Trial checkbox value has been changed from false to true
        for(Lead l : newLeadList){
            if(!String.isBlank(l.Email) && l.Agreed_to_Edge_Trail_Agreement__c && (oldLeadMap == null || !oldLeadMap.get(l.Id).Agreed_to_Edge_Trail_Agreement__c)){
                emailSet.add(l.Email);
            }
        }

        //Prepare a list of Contacts to be upserted
        if(!emailSet.isEmpty()){
            contactListToBeUpserted = prepareContactListForEdgeTrial(emailSet);
        }
        updateContactListForEdgeTrial(contactListToBeUpserted);
    }
    /** 
     * @description Prepare a list of contacts to be upserted corresponding to the Leads whose Agree to Edge Trial flag has been changed to true
     * @author Saakshi Gupta
     * @createdDate  26th March 2021
     * @param emailSet Set<String> - Set of emails of Leads for which Agree to Edge Trial checkbox value has been changed from false to true
    */
    @TestVisible
    private List<Contact> prepareContactListForEdgeTrial(Set<String> emailSet){
        List<Contact> contactListToBeUpserted = new List<Contact>();

        Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT Id, Email, Agreed_to_Edge_Trial_Agreement__c, Agreed_to_POC_terms__c,
                                                            Agreed_to_POC_terms_Date__c, Agree_to_Edge_Trial_Date__c, LeadSource,
                                                            Meeting_Set_Campaign_ID__c, Lead_Source_Campaign_Details__c,
                                                            Lead_Source_Most_Recent__c, Lead_Source_Most_Recent_Details__c,
                                                            FirstName, LastName, AccountId,
                                                            (SELECT Id, Email, UserType FROM Users)
                                                            FROM Contact
                                                            WHERE Email =: emailSet
                                                            ORDER BY Email]);

        if(contactMap.isEmpty()) return contactListToBeUpserted;

            Map<String, List<Contact>> emailToContactListMap = new Map<String, List<Contact>>();
        Map<String, Contact> partnerContactEmailToContactMap = new Map<String, Contact>();
            Set<String> agreedEmailSet = new Set<String>();
            Set<String> notAgreedEmailSet = new Set<String>();
        Set<String> partnerEmailSet = new Set<String>();
        Set<String> customerEmailSet = new Set<String>();

            for(Id eachContactId : contactMap.keySet()){
                Contact contactRecord = contactMap.get(eachContactId);

            //Prepare a set of Partner Contacts so that it can be verified later if a new contact needs to be created or not
            if(!contactRecord.Users.isEmpty() && contactRecord.Users[0].UserType.equalsIgnoreCase('PowerPartner')) {
                partnerContactEmailToContactMap.put(contactRecord.Email, contactRecord);
                partnerEmailSet.add(contactRecord.Email);
            }
            //Add the remaining contacts as a list as values with the email address as key
            else {
                if(!emailToContactListMap.containsKey(contactRecord.Email)){
                    emailToContactListMap.put(contactRecord.Email, new List<Contact>{contactRecord});
                }
                else {
                    emailToContactListMap.get(contactRecord.Email).add(contactRecord);
                }

                if(!contactRecord.Users.isEmpty() && contactRecord.Users[0].UserType.equalsIgnoreCase('CSPLitePortal'))
                    customerEmailSet.add(contactRecord.Email);
            }

            //If a contact has not agreed to edge trial and another contact with the same email address has not already agreed, then add to the set
            if(!contactRecord.Agreed_to_Edge_Trial_Agreement__c && !agreedEmailSet.contains(contactRecord.Email)){
                    notAgreedEmailSet.add(contactRecord.Email);
                }
            //If a contact has not agreed to edge trial and another contact with the same email address has already agreed, then remove from the set
            else if(!contactRecord.Agreed_to_Edge_Trial_Agreement__c && agreedEmailSet.contains(contactRecord.Email)){
                notAgreedEmailSet.remove(contactRecord.Email);
            }
            //If a contact has already agreed to edge trial, then remove the email address from the set, so that the contacts with this email
            //address will not be processed
            else if(contactRecord.Agreed_to_Edge_Trial_Agreement__c){
                notAgreedEmailSet.remove(contactRecord.Email);
                    agreedEmailSet.add(contactRecord.Email);
                }
            }

        //Return if there is no contact to be processed on for edge trial
        if(notAgreedEmailSet.size() < 1) return contactListToBeUpserted;

        //Process the contacts for which Customer Portal users already exist. Update the contact fields only
        for(String customerEmail : customerEmailSet){
            if(notAgreedEmailSet.contains(customerEmail)){
                for(Contact eachContact : emailToContactListMap.get(customerEmail)){
                    if(!eachContact.Users.isEmpty()){
                        setContactFields(eachContact);
                        contactListToBeUpserted.add(eachContact);
                        notAgreedEmailSet.remove(customerEmail);
                        break;
                    }
                }
            }
                }

        Contact contactRecord;
                for(String eachEmail : notAgreedEmailSet){
            contactRecord = new Contact();

            //Process the contacts which do not have a Customer Portal user. Setting the fields on Contact will trigger an existing logic to create the
            //Support portal user for Edge trial
            if(emailToContactListMap.containsKey(eachEmail)){
                contactRecord = emailToContactListMap.get(eachEmail)[0];
                setContactFields(contactRecord);
                contactListToBeUpserted.add(contactRecord);
                }
            //Process the remaining contacts for which there is a Partner Contact existing but not a Customer Portal Contact. Clone the contact from the
            //Partner user and set the Edge trial fields which will trigger existing logic of Edge trial user creation
            else if(partnerEmailSet.contains(eachEmail)){
                contactRecord = (partnerContactEmailToContactMap.get(eachEmail)).clone(false, false, false, false);
                setContactFields(contactRecord);
                contactListToBeUpserted.add(contactRecord);
            }
        }
        return contactListToBeUpserted;
    }
    /**
     * @description This method is used to set the fields on Contact object.
     * @param contactRecord Contact - Contact record to be updated
     */
    private void setContactFields(Contact contactRecord){
        contactRecord.Agreed_to_Edge_Trial_Agreement__c = true;
        contactRecord.Agreed_to_POC_terms__c = true;
        contactRecord.Agreed_to_POC_terms_Date__c = System.today();
        contactRecord.Agree_to_Edge_Trial_Date__c = System.today();
        contactRecord.LeadSource = !String.isBlank(contactRecord.LeadSource) ? contactRecord.LeadSource : 'Sales - Edge Trial';
        contactRecord.Meeting_Set_Campaign_ID__c = System.Label.Sales_Edge_Request_Campaign_Id;
        contactRecord.Lead_Source_Campaign_Details__c = contactRecord.LeadSource != 'Sales - Edge Trial'
                                                        ? contactRecord.Lead_Source_Campaign_Details__c
                                                        : System.Label.Sales_Edge_Request_Campaign_Id;
        contactRecord.Lead_Source_Most_Recent__c = 'Sales';
        contactRecord.Lead_Source_Most_Recent_Details__c = 'Sales - Edge Trial';
    }
    /**
     * @description This method is used to update the contact list for edge trial.
     * @param contactList List<Contact> - List of contacts to be updated
     */
    private void updateContactListForEdgeTrial(List<Contact> contactList){
        Database.UpsertResult[] saveResults = Database.upsert(contactList, false);

        for(Database.UpsertResult eachResult : saveResults){
            if (!eachResult.isSuccess()) {
                for(Database.Error eachError : eachResult.getErrors()) {
                    System.debug(LoggingLevel.DEBUG, 'The following error has occurred:');
                    System.debug(LoggingLevel.DEBUG,eachError.getStatusCode() + ': ' + eachError.getMessage());
                    System.debug(LoggingLevel.DEBUG,'Fields that affected this error: ' + eachError.getFields());
                }
            }
        }
    }
    /**
     * @description This method is used to unMQL the leads.
     * @param newLeadList List<Lead> - List of new leads
     * @param oldLeadMap Map<Id, Lead> - Map of old lead records
     */
    public void unmqlLead(List<Lead> newLeadList, Map<Id, Lead> oldLeadMap){
        List<Lead> leadsOfInterest = getLeadsWithStatus(newLeadList, oldLeadMap);
        for(Lead l: leadsOfInterest){
            if((l.MQL__c || l.Partner_MQL__c)
                && ('Nurture' == l.Status
                    || 'Non-Qualified' == l.Status
                )
            ){
                l.MQL__c = false;
                l.Partner_MQL__c = false;
                l.UnMQL_Date__c = Date.today();    
            }
        }
    }
    /**
     * @description This method is used to insert lead into campaign.
     * @param newLeadList List<Lead> - List of new leads
     * @param oldLeadMap Map<Id, Lead> - Map of old lead records
     * @param isInsert Boolean - Flag to check if it is insert operation
     */
    public void insertLeadIntoCampaign(List<Lead> newLeadList, Map<Id, Lead> oldLeadMap, boolean isInsert){
        String campId = System.Label.CampaignId;
        List<Id> existingLeadIdList = new List<Id>();
        List<CampaignMember> campaignMemberInsertList = new List<CampaignMember>();
        if(campId != null){
            List<CampaignMember> campaignMemberList = new List<CampaignMember>([Select Id,LeadId from CampaignMember where CampaignId = :campId]);
            for(CampaignMember cm : campaignMemberList){
                if(cm.leadId != null)
                    existingLeadIdList.add(cm.leadId);
            }
        }
        for (lead ld : newLeadList){
            if(isInsert && ld.Salesloft_Cadence_Most_Recent__c != null && ld.Salesloft_Cadence_Most_Recent__c.contains(System.label.CampaignMatchingString) && !existingLeadIdList.contains(ld.id)){
                CampaignMember cm = new CampaignMember();
                cm.CampaignId = campId;
                cm.leadId = ld.Id;
                cm.status = 'Filled-out Form';
                campaignMemberInsertList.add(cm);
            }else if(!isInsert && ld.Salesloft_Cadence_Most_Recent__c != null && ld.Salesloft_Cadence_Most_Recent__c.contains(System.label.CampaignMatchingString) && ld.Salesloft_Cadence_Most_Recent__c != oldLeadMap.get(ld.Id).Salesloft_Cadence_Most_Recent__c && !existingLeadIdList.contains(ld.id)){
                CampaignMember cm = new CampaignMember();
                cm.CampaignId = campId;
                cm.leadId = ld.Id;
                cm.status = 'Filled-out Form';
                campaignMemberInsertList.add(cm);
            }
        }try{
            if(!campaignMemberInsertList.isEmpty()){
                insert campaignMemberInsertList;
            }   
        }catch(Exception ex){
            System.debug(LoggingLevel.DEBUG,ex.getMessage());
        }
    }
    /**
     * @description This method is used to run L2A after zoom info.
     * @param newLeadList List<Lead> - List of new leads
     * @param oldLeadMap Map<Id, Lead> - Map of old lead records
     */
    public void runL2AafterZoomInfo(List<Lead> newLeadList, Map<Id, Lead> oldLeadMap){
        for(Lead leadRecord : newLeadList){
            if(isLeadL2AFieldsUpdated(leadRecord, oldLeadMap.get( leadRecord.Id ))){
                //MKT24-977: Reprocess the leads if not done already
                leadRecord.L2A_Status__c = 'Reprocess';
            }
        }
    } 
    /**
     * @description This method is used to run L2A on flag check.
     * @param newLeadList List<Lead> - List of new leads
     * @param oldLeadMap Map<Id, Lead> - Map of old lead records
     */
    public void runL2AOnFlagCheck(List<Lead> newLeadList, Map<Id, Lead> oldLeadMap){
        List<Id> leadIds = new List<Id>();
        List<Boolean> runL2AFlags = new List<Boolean>();
        for(Lead leadRecord : newLeadList){
            if(leadRecord.Run_L2A__c && leadRecord.Run_L2A__c!= oldLeadMap.get(leadRecord.Id).Run_L2A__c){
                /*LeadTriggerHelper.runL2AService(leadRecord.id,
                                                LeadTriggerHelper.setPatchManagerAfterMQL.contains(leadRecord.Id));*/
                leadIds.add(leadRecord.Id);
                runL2AFlags.add(LeadTriggerHelper.setPatchManagerAfterMQL.contains(leadRecord.Id));
            }
        }
        if(!leadIds.isEmpty()){
             System.enqueueJob(new runL2AServiceBulk(leadIds, runL2AFlags));
        }
    }
    /**
     * @description This method is used to check if the lead L2A fields are updated.
     * @param newLead Lead - New lead record
     * @param oldLead Lead - Old lead record
     * @return Boolean - True if L2A fields are updated, false otherwise
     */
    private Boolean isLeadL2AFieldsUpdated( Lead newLead, Lead oldLead ) {
        for(String field : setL2ATriggerFields) {
            if( String.valueOf( newLead.get(field) ) != String.valueOf( oldLead.get(field) ) ) {
                return true;
            }
        }
        return false;
    }
    /**
     * @description This method is used to assign the Patch Manager on Lead object.
     * @param leads List<Lead> - List of leads to be assigned
     */
    private void assignPatchManager(List<Lead> leads){
        Map<String, List<PatchManager__c>> patchMap = PatchManager1.getPatchMap(leads);
        System.debug(LoggingLevel.DEBUG,'#assignPatchManager#patchMap:'+patchMap);
        Map<Id, PatchManager__c> leadIdToPatchManager = PatchManager1.assignLead(patchMap, leads);
        System.debug(LoggingLevel.DEBUG,'#assignPatchManager#leadIdToPatchManager:'+leadIdToPatchManager);
        
        for(Lead lObject : leads){
            PatchManager__c vManager = leadIdToPatchManager.get(lObject.Id);
            System.debug(LoggingLevel.DEBUG,'#assignPatchManager#vManager:'+vManager);
            if(vManager != null){
                lObject.PatchManager__c=vManager.Id;
                lObject.AssignLeadInAfter__c = true;
            }else if(lObject.Winning_L2A_Account__c != null){
                lObject.AssignLeadInAfter__c = true;
            }
            lObject.rerun_PatchManager__c = false;
        }
    }
    /**
     * @description This method is used to assign the owner of the lead.
     * @param newLeadMap Map<Id, Lead> - Map of new lead records
     * @param oldLeadMap Map<Id, Lead> - Map of old lead records
     */
    public void assignOwner(Map<Id, Lead> newLeadMap, Map<Id, Lead> oldLeadMap){
        Map<Id, Lead> leadIdToLead = new Map<Id, Lead>();
        List<Id> leadIds = new List<Id>();
        Map<Id, Boolean> mapIdWithFalseFallback = new Map<Id, Boolean>();
        for(Id lObjectId : newLeadMap.keySet()){
            Lead lobject = newLeadMap.get(lObjectId);
            if(lObject.AssignLeadInAfter__c
                && lObject.AssignLeadInAfter__c!=oldLeadMap.get(lObject.Id).AssignLeadInAfter__c){
                    leadIds.add(lObject.Id);
                    leadIdToLead.put(lObjectId, lObject);
                    mapIdWithFalseFallback.put(lObjectId, false);
            }
        }
        if(!leadIds.isEmpty()){
            //assignLeadOwner(leadIds);
            MQLRoutingService service = new MQLRoutingService(new Set<Id>(leadIds), 'Lead');
            List<Lead_Routing_Rule__mdt> allRules = service.getAllRules();
            Map<Id, Lead_Routing_Rule__mdt> leadToRule = service.stampRulesOnRecords(allRules);
            System.debug(LoggingLevel.DEBUG,'#LeadTriggerHelper#assignOwner#leadToRule:'+leadToRule);
            if(!leadToRule.isEmpty()){
                MQLRoutingOwnerAssignService1 ownerService = new MQLRoutingOwnerAssignService1(new Set<Id>(leadIds), allRules);
                ownerService.assignOwners(leadToRule, leadIdToLead, mapIdWithFalseFallback);  
            }
        }
    }
    /**
     * @description This method is used to clear the FCR reason on Lead object.
     * @param newLeads List<Lead> - List of new leads
     * @param oldLeadMap Map<Id, Lead> - Map of old lead records
     */
    public void clearFCRReason(List<Lead> newLeads, Map<Id,Lead> oldLeadMap){
        Set<String> activeMeetingStatus = new Set<String>{'Open', 'Working', 'Meeting Set'};
        for(Lead lObject : newLeads){
            if(lObject.CFCR_Status_Reason__c != null
                && activeMeetingStatus.contains(lobject.Status)
                && (oldLeadMap==null || lObject.Status != oldLeadMap.get(lObject.Id).Status)){
                    lObject.CFCR_Status_Reason__c = null;
            }
        }
    }
    /**
     * @description This method is used to set the nurture timeout on Lead object.
     * @param newLeads List<Lead> - List of new leads
     * @param oldLeadMap Map<Id, Lead> - Map of old lead records
     */
    public void setNurturetimeout(List<Lead> newLeads, Map<Id,Lead> oldLeadMap){
        Set<String> nurtureStatus = new Set<String>{'Nurture','Non-Qualified'};
        for(Lead lObject : newLeads){
            if(nurtureStatus.contains(lobject.Status) && lObject.Last_MQL_Date__c != null
                && (oldLeadMap==null || lObject.Status != oldLeadMap.get(lObject.Id).Status)){
                    lObject.FCRM__FCR_Nurture_Timeout__c = lObject.Last_MQL_Date__c+30;
            }
        }
    }
    
    /**
     * @description This method is used to uncheck the direct route to AE campaign on Lead object.
     * @param newLeads List<Lead> - List of new leads
     * @param oldLeadMap Map<Id, Lead> - Map of old lead records
     */
    public void uncheckDirectRouteToAECampaign(List<Lead> newLeads, Map<Id, Lead> oldLeadMap){
        for(Lead newLead : newLeads){
            if(newLead.Direct_route_to_AE_Campaign__c && !newLead.MQL__c && oldLeadMap.get(newLead.Id).MQL__c) newLead.Direct_route_to_AE_Campaign__c = false;
        }
    }
    /**
     * @description This method is used to populate the winning L2A account on Lead object.
     * @param newLeads List<Lead> - List of new leads
     * @param oldLeadMap Map<Id, Lead> - Map of old lead records
     */
    public void populateWinningL2AAccount(List<Lead> newLeads, Map<Id, Lead> oldLeadMap){
        for(Lead newLead : newLeads){
            if(newLead.L2A_Confidence_Code__c != oldLeadMap.get(newLead.Id).L2A_Confidence_Code__c
                || newLead.OP_Confidence_Level__c != oldLeadMap.get(newLead.Id).OP_Confidence_Level__c
                || newLead.OP_L2A_Account__c != oldLeadMap.get(newLead.Id).OP_L2A_Account__c
                || newLead.L2A_Account__c != oldLeadMap.get(newLead.Id).L2A_Account__c
            ) {
                newLead.Winning_L2A_Account__c = newLead.L2A_Confidence_Code__c > 2 ? newLead.L2A_Account__c : (newLead.OP_Confidence_Level__c > 4 ? newLead.OP_L2A_Account__c : null);
            }
        }
    }      
    /**
     * @description This method is used to uncheck the L2A status on Lead object.
     * @param newLeads List<Lead> - List of new leads
     * @param oldLeadMap Map<Id, Lead> - Map of old lead records
     */
    public void uncheckL2AStatus(List<Lead> newLeads, Map<Id, Lead> oldLeadMap){
        for(Lead newLead : newLeads){
            if('Processed' == newLead.L2A_Status__c && newLead.L2A_Status__c != oldLeadMap.get(newLead.Id).L2A_Status__c){
                newLead.Last_Run_L2A_Date__c = DateTime.now();
            }
        }
    }
    /**
     * @description This method is used to populate the UTM term on Lead object.
     * @param newLeads List<Lead> - List of new leads
     * @param oldLeadMap Map<Id, Lead> - Map of old lead records
     */
    public  void populateUTMTerm(List<Lead> newLeads, Map<Id, Lead> oldLeadMap) {

    Map<String, BDMRoutingConfiguration__mdt> UTMSourceConfig = null;

    for (Lead objLead : newLeads) {

        Boolean utmChanged = false;

        if (oldLeadMap == null) {
            utmChanged = true;
        } else {
            Lead oldLead = oldLeadMap.get(objLead.Id);
            utmChanged =
                objLead.UTM_Campaign__c != oldLead.UTM_Campaign__c ||
                objLead.UTM_Medium__c   != oldLead.UTM_Medium__c ||
                objLead.UTM_Partner__c  != oldLead.UTM_Partner__c ||
                objLead.UTM_Source__c   != oldLead.UTM_Source__c ||
                objLead.UTM_Content__c  != oldLead.UTM_Content__c ||
                objLead.UTM_Term__c     != oldLead.UTM_Term__c ||
                objLead.UTM_Type__c     != oldLead.UTM_Type__c;
        }

        // Handle Latest UTM Term update
        if (objLead.UTM_Term__c != null &&
            (oldLeadMap == null || oldLeadMap.get(objLead.Id).UTM_Term__c != objLead.UTM_Term__c)) {

            if (UTMSourceConfig == null) {
                UTMSourceConfig = RoutingUtil.getBDMDefaultUserDetails();
            }

            if (UTMSourceConfig.containsKey(objLead.UTM_Term__c)) {
                objLead.Latest_UTM_Term__c = objLead.UTM_Term__c;
                objLead.Last_UTM_Term_Date__c = Date.today();
            }
        }

        // Build Last UTM String only if something changed
        if (utmChanged) {
            String utmString = '';

            if (objLead.UTM_Campaign__c != null)
                utmString += 'utm_campaign=' + objLead.UTM_Campaign__c + '& ';
            if (objLead.UTM_Medium__c != null)
                utmString += 'utm_medium=' + objLead.UTM_Medium__c + '& ';
            if (objLead.UTM_Partner__c != null)
                utmString += 'utm_partner=' + objLead.UTM_Partner__c + '& ';
            if (objLead.UTM_Source__c != null)
                utmString += 'utm_source=' + objLead.UTM_Source__c + '& ';
            if (objLead.UTM_Content__c != null)
                utmString += 'utm_content=' + objLead.UTM_Content__c + '& ';
            if (objLead.UTM_Term__c != null)
                utmString += 'utm_term=' + objLead.UTM_Term__c + '& ';
            if (objLead.UTM_Type__c != null)
                utmString += 'utm_type=' + objLead.UTM_Type__c + '& ';

            if (utmString.endsWith('& ')) {
                utmString = utmString.substring(0, utmString.length() - 2);
            }

            if (!String.isBlank(utmString)) {
                objLead.Last_UTM_String__c = utmString;
            }
        }
    }
}

    /**
     * @description This method is used to set the lead share expiration date on Lead object.
     * @param newLeads List<Lead> - List of new leads
     * @param oldLeadMap Map<Id, Lead> - Map of old lead records
     */
    public void setLeadShareExpirationDateMeetingSet(List<Lead> newLeads, Map<Id, Lead> oldLeadMap){
        for(Lead ld : newLeads){
            if(ld.Lead_Share_Program_Expiration_Date__c != null && ld.MeetingDate__c != null && oldLeadMap.get(ld.Id).MeetingDate__c != ld.MeetingDate__c){
                Date meetingDate = date.newinstance(ld.MeetingDate__c.year(), ld.MeetingDate__c.month(), ld.MeetingDate__c.day());
                if(ld.Lead_Share_Program_Expiration_Date__c <= meetingDate.addDays(5)){
                    ld.Lead_Share_Program_Expiration_Date__c = meetingDate + 5 ;
                }
            }
        }
    }
    /**
     * @description This method is used to update the lead sharing date on Lead object.
     * @param newLeads List<Lead> - List of new leads
     * @param oldLeadMap Map<Id, Lead> - Map of old lead records
     */
    public void updateLeadSharingDate(List<Lead> newLeads, Map<Id, Lead> oldLeadMap){
        for(Lead ld : newLeads){
            if('Campaign - Partner of Record' == ld.Routing_Rule_Applied__c && oldLeadMap.get(ld.Id).Routing_Rule_Applied__c != ld.Routing_Rule_Applied__c){
                ld.Lead_Share_Program_Expiration_Date__c = system.today() + 90;
            }
        }
    }
    /**
     * @description This method is used to capture the owner profile on Lead object.
     * @param newLeadList List<Lead> - List of new leads
     * @param oldLeadMap Map<Id, Lead> - Map of old lead records
     */
    public  void captureOwnerProfile (List<Lead> newLeadList, Map<Id,Lead> oldLeadMap) {
        
        Profile currentProfile = [SELECT Id, Name FROM Profile WHERE Id =: userinfo.getProfileId() LIMIT 1];
        for(Lead ld : newLeadList){
            if(oldLeadMap.get(ld.Id).ownerId != ld.ownerId){ 
                ld.Last_Ownership_Changed_Profile__c = currentProfile.Name;
            }
        }
    }
    /**
     * @description This method is used to update the rejection reason on Lead object.
     * @param newLeadList List<Lead> - List of new leads
     * @param oldLeadMap Map<Id, Lead> - Map of old lead records
     */
    public void updateRejectionReason(List<Lead> newLeadList, Map<Id,Lead> oldLeadMap){
        for(Lead ld : newLeadList){
            if(ld.status != oldLeadMap.get(ld.Id).status && ld.status == 'Nurture' && ld.Lead_Rejection_Reason__c == null){
                ld.Lead_Rejection_Reason__c = 'Automated unMQL (Admin Only)';
            }
        }
    }
    /**
     * @description This method is used to set the privacy compliance on Lead object.
     * @param newLeadRecords List<Lead> - List of new leads
     * @param oldLeadMap Map<Id, Lead> - Map of old lead records
    
     */
    public void setPrivacyCompliance(List<Lead> newLeadRecords, Map<Id, Lead> oldLeadMap){
        Set<String> setOfDirectLeadSources = new Set<String>();
        Set<String> setOfOptedInCountries = new Set<String>();
        for(Direct_and_Indirect_Lead_Source__mdt leadSourceMDt: [SELECT MasterLabel, Direct_Lead_Source__c FROM Direct_and_Indirect_Lead_Source__mdt WHERE Direct_Lead_Source__c= true]){
            setOfDirectLeadSources.add(leadSourceMDt.MasterLabel.deleteWhiteSpace());
        }
        for(Privacy_Opted_Countries__mdt countryOptMDt: [SELECT Country_Code__c FROM Privacy_Opted_Countries__mdt WHERE Privacy_Opt_In__c = true]){
        	setOfOptedInCountries.add(countryOptMDt.Country_Code__c);
        }
        for(Lead ld : newLeadRecords){
            
            Lead oldLd = (oldLeadMap != null) ? oldLeadMap.get(ld.Id) : null;

            if(oldLeadMap == null 
               || ld.CountryCode != oldLd.CountryCode 
               || ld.Email_Opt_In__c != oldLd.Email_Opt_In__c 
               || ld.HasOptedOutOfEmail != oldLd.HasOptedOutOfEmail 
               || ld.LeadSource != oldLd.LeadSource
               || ld.Re_compute_Data_Use_Permitted__c != oldLd.Re_compute_Data_Use_Permitted__c){                   
                if(!ld.HasOptedOutOfEmail){
                       if(ld.Email_Opt_In__c || (ld.LeadSource !=null && setOfDirectLeadSources.contains(ld.LeadSource.deleteWhiteSpace()))){                           
                           ld.Data_Use_Permitted__c = true;
                       } else {
                        ld.Data_Use_Permitted__c = false;
                    }
                }else{
                    ld.Data_Use_Permitted__c = false;
                }
            }
            ld.Data_Use_Permitted__c = (ld.CountryCode == 'CN') ? false : ld.Data_Use_Permitted__c;
            ld.Re_compute_Data_Use_Permitted__c = false;
        }

    }
    /**
     * @description This method is used to set the marketing opt-in and opt-out dates on Lead object.
     * @param newLeadRecords List<Lead> - List of new leads
     * @param oldLeadMap Map<Id, Lead> - Map of old lead records
     */
    public void setMarketingOptInAndOut(List<Lead> newLeadRecords, Map<Id, Lead> oldLeadMap){
        for(Lead ld : newLeadRecords){
            if((oldLeadMap == null || (oldLeadMap != null && ld.HasOptedOutOfEmail != oldLeadMap.get(ld.Id).HasOptedOutOfEmail)) && ld.HasOptedOutOfEmail){
                ld.Marketing_Opt_Out_Date__c = System.now();
            }
            if((oldLeadMap == null || (oldLeadMap != null && ld.Email_Opt_In__c != oldLeadMap.get(ld.Id).Email_Opt_In__c)) && ld.Email_Opt_In__c){
                ld.Marketing_Opt_In_Date__c = System.now();
            }
        }
    }

    /**
     * @description Calculates the lead score for a list of new or updated Lead records.
     * The score is derived from various factors including job function, job level,
     * engagement scores, and account attributes like buying stage and tier.
     *
     * @param newLeadRecords The list of Lead records being inserted or updated.
     * @param oldLeadMap A map of existing Lead records (before update) with their Ids as keys.
     *                      If null, it indicates an insert operation.
     */
    public void calculateLeadScore(List<Lead> newLeadRecords, Map<Id, Lead> oldLeadMap) {
        Set<Id> accountIds = new Set<Id>();
        
        for (Lead ld : newLeadRecords) {
            if (ld.Winning_L2A_Account__c != null) {
                accountIds.add(ld.Winning_L2A_Account__c);
            }
            if(ld.L2A_Account__c != null && !accountIds.contains(ld.L2A_Account__c)){
                accountIds.add(ld.L2A_Account__c);
            }
            if(ld.OP_L2A_Account__c != null && !accountIds.contains(ld.OP_L2A_Account__c)){
                accountIds.add(ld.OP_L2A_Account__c);
            }
        }
        
        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, accountBuyingStage6sense__c, Account_Tier__c FROM Account WHERE Id IN :accountIds]);
    
        for (Lead ld : newLeadRecords) {
            if (oldLeadMap == null || (
                ld.Job_Function__c != oldLeadMap.get(ld.Id)?.Job_Function__c ||
                ld.JobLevel__c != oldLeadMap.get(ld.Id)?.JobLevel__c ||
                ld.accountBuyingStage6sense__c != oldLeadMap.get(ld.Id)?.accountBuyingStage6sense__c ||
                (ld.Winning_L2A_Account__c != null && accountMap.get(ld.Winning_L2A_Account__c)?.accountBuyingStage6sense__c != oldLeadMap.get(ld.Id)?.accountBuyingStage6sense__c) ||
                ld.Winning_L2A_Account__c != oldLeadMap.get(ld.Id)?.Winning_L2A_Account__c ||
                ld.L2A_Account__c != oldLeadMap.get(ld.Id)?.L2A_Account__c ||
                ld.OP_L2A_Account__c != oldLeadMap.get(ld.Id)?.OP_L2A_Account__c ||
                ld.Winning_L2A_System__c != oldLeadMap.get(ld.Id)?.Winning_L2A_System__c ||
                ld.L2A_Confidence_Code__c != oldLeadMap.get(ld.Id)?.L2A_Confidence_Code__c ||
                ld.OP_L2A_Confidence_Type__c != oldLeadMap.get(ld.Id)?.OP_L2A_Confidence_Type__c ||
                ld.CountryCode != oldLeadMap.get(ld.Id)?.CountryCode ||
                ld.AnnualRevenue != oldLeadMap.get(ld.Id)?.AnnualRevenue ||
                ld.NumberOfEmployees != oldLeadMap.get(ld.Id)?.NumberOfEmployees ||
                ld.P0_Engagements__c != oldLeadMap.get(ld.Id)?.P0_Engagements__c ||
                ld.P1_Engagements__c != oldLeadMap.get(ld.Id)?.P1_Engagements__c ||
                ld.P2_Engagements__c != oldLeadMap.get(ld.Id)?.P2_Engagements__c ||
                ld.P3_Engagements__c != oldLeadMap.get(ld.Id)?.P3_Engagements__c || 
                ld.Update_Lead_Score__c)
                ) 
            {
                Decimal leadScore = ld.Job_Function_Score__c + ld.Job_Level_Score__c;
                Decimal engagementScore = (ld.P0_Engagements__c != null ? ld.P0_Engagements__c * 60 : 0) +
                                        (ld.P1_Engagements__c != null ? ld.P1_Engagements__c * 40 : 0) +
                                        (ld.P2_Engagements__c != null ? ld.P2_Engagements__c * 10 : 0) +
                                        (ld.P3_Engagements__c != null ? ld.P3_Engagements__c * 3 : 0);
                
                engagementScore = Math.min(engagementScore, 60);
                leadScore += engagementScore;
                Integer buyingStageScore = 0;
                String buyingStage = ld.Winning_L2A_Account__c != null ? accountMap.get(ld.Winning_L2A_Account__c)?.accountBuyingStage6sense__c : ld.accountBuyingStage6sense__c;
                if (buyingStage == 'Purchase' || buyingStage == 'Decision') {
                    buyingStageScore = 40;
                } else if (buyingStage == 'Consideration' || buyingStage == 'Awareness') {
                    buyingStageScore = 30;
                } else {
                    buyingStageScore = 0;
                }
                leadScore += buyingStageScore;    
                String calculatedAccountTier = calculateAccountTier(ld, accountMap);
                if (calculatedAccountTier == 'Tier 1' || calculatedAccountTier == 'Tier 2') {  
                    ld.Lead_Score_Number__c = leadScore + 20;
                } else if (calculatedAccountTier == 'Tier 3' || calculatedAccountTier == 'Tier 4') {
                    ld.Lead_Score_Number__c = leadScore + 10;
                } else {
                    ld.Lead_Score_Number__c = leadScore;
                }
                if(ld.Update_Lead_Score__c){
                    ld.Update_Lead_Score__c = false;
                }
                ld.CFCR_Admin_Score_Increment__c = ( ld.CFCR_Admin_Score_Increment__c == null ) ? 1: ( ld.CFCR_Admin_Score_Increment__c == 1 ? 2 : 1 );
            }
        }    
    }

    /**
     * @description Calculates and assigns the MQL priority for each Lead based on their lead score.
     *
     * @param newLeadRecords List of new or updated Lead records.
     * @param oldLeadMap Map of old Lead records (before update) with Lead Id as the key.
     *                   This helps in checking if the Lead Score has changed.
     */
    public void calculateMQLPriority(List<Lead> newLeadRecords, Map<Id, Lead> oldLeadMap) {
        System.debug(LoggingLevel.DEBUG,'newLeadRecords :: '+ newLeadRecords);
       
        for (Lead ld : newLeadRecords) {
            if(oldLeadMap == null || (oldLeadMap != null && ( ld.Lead_Score_Number__c != oldLeadMap.get(ld.Id)?.Lead_Score_Number__c))){
                System.debug(LoggingLevel.DEBUG,'oldLeadMap :: '+ oldLeadMap);
                ld.MQL_Priority_txt__c = ld.Lead_Score_Number__c >= 140 ? 'P0' : ld.Lead_Score_Number__c >= 120 ? 'P1' : ld.Lead_Score_Number__c >= 80  ? 'P2' : 'P3';
            }
        }
    }   
    /**
     * @description Determines the account tier for a given Lead based on various factors,
     *              including mapped account tiers, confidence codes, revenue, and employee count.
     *
     * @param ld The Lead record for which the account tier needs to be calculated.
     * @param accountMap A map of Account Ids to Account records, used to fetch the Account Tier
     *                   if a matching account is found.
     * @return The calculated account tier as a String (e.g., 'Tier 1', 'Tier 2', etc.).
     *
     */
    private String calculateAccountTier(Lead ld, Map<Id, Account> accountMap) {
        if (ld.Winning_L2A_Account__c != null && !String.isEmpty(ld.Winning_L2A_System__c)) {
            return accountMap.get(ld.Winning_L2A_Account__c)?.Account_Tier__c;
        }
        if (ld.L2A_Confidence_Code__c == 2 && ld.L2A_Account__c != null) {
            return accountMap.get(ld.L2A_Account__c)?.Account_Tier__c;
        }
        if (ld.OP_L2A_Confidence_Type__c != null &&
            (ld.OP_L2A_Confidence_Type__c.equalsIgnoreCase('LOW CONFIDENCE WITH DOMAIN') ||
             ld.OP_L2A_Confidence_Type__c.equalsIgnoreCase('LOW CONFIDENCE WHITESPACE')) &&
            ld.OP_L2A_Account__c != null) {
            return accountMap.get(ld.OP_L2A_Account__c)?.Account_Tier__c;
        }
    
        String amerCountries = System.Label.AMER_Countries;
        Set<String> amerCountrySet = new Set<String>(amerCountries.split(','));
        Boolean isAMER = amerCountrySet.contains(String.valueOf(ld.CountryCode));
    
        if (isAMER) {
            if (ld.AnnualRevenue >= 1000000000) return 'Tier 1';
            if (ld.AnnualRevenue >= 500000000) return 'Tier 2';
            if (ld.AnnualRevenue >= 250000000) return 'Tier 3';
            if (ld.AnnualRevenue >= 100000000) return 'Tier 4';
            if (ld.AnnualRevenue >= 0) return 'Tier 5';
        } else {
            if (ld.AnnualRevenue >= 10000000000.0) return 'Tier 1';
            if (ld.AnnualRevenue >= 300000000) return 'Tier 2';
            if (ld.AnnualRevenue >= 250000000) return 'Tier 3';
            if (ld.AnnualRevenue >= 100000000) return 'Tier 4';
            if (ld.AnnualRevenue >= 0) return 'Tier 5';
        }
    
        if (ld.NumberOfEmployees >= 2500) return 'Tier 1';
        if (ld.NumberOfEmployees >= 1000) return 'Tier 2';
        if (ld.NumberOfEmployees >= 750) return 'Tier 3';
        if (ld.NumberOfEmployees >= 500) return 'Tier 4';
        if (ld.NumberOfEmployees >= 0) return 'Tier 5';
    
        return 'Tier 5';
    }
}