/**
 * @description       : Helper class of PartnerOnboardingRequestTrigger
 * @author            : Harshit Garg
 * @group             : 
 * @last modified on  : 02-18-2026
 * @last modified by  : Harshit Garg
**/

public without sharing class PartnerOnboardingRequestTriggerHelper {
    
    
    private Id distRecTypeId;
    private Id sdRecordTypeId;
    private Id resellerRecordTypeId;

    public static final String PARTNER_DISTRIBUTOR =  'Partner/Distributor';
    public static final String PARTNER = 'Reseller';
    public static final String PARTNER_MSPRESELLER = 'MSP-Reseller';
    public static final String APPROVED = 'Approved';
    public static final String L1_APPROVED = 'L1 Approved';
    public static final String PARTNER_MSP = 'MSP';
    public static final String COMPLIANT = 'Compliant';
    public static final String SIGNED_ACTIVE = 'Signed - Active';
    public static final String CHANNEL_MARKETING = 'Channel Marketing';
    public static final String ADMIN = 'Admin';
    public static final String SALES = 'Sales';
    public static final String TECHNICAL = 'Technical';
    public static final String ACTIVE = 'Active';
    
    public boolean stopContractcreation;
    
    /**
     * @description constructor of PartnerOnboardingRequestTriggerHelper
     */
    public PartnerOnboardingRequestTriggerHelper(){
        stopContractcreation = false;
		Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Partner_Onboarding_Request__c.getRecordTypeInfosByName();
		
        distRecTypeId = rtMapByName.get('Distributor').getRecordTypeId();
		sdRecordTypeId = rtMapByName.get('Service Delivery').getRecordTypeId();
		resellerRecordTypeId = rtMapByName.get('Reseller').getRecordTypeId();
    }
    
    /**
     * @description To assign the correct owner to request record
     * @param newList List of new records
     */
    public void assignOwner(List<Partner_Onboarding_Request__c> newList){
        List<Partner_Onboarding_Request__c> lstPOR = new List<Partner_Onboarding_Request__c>();
        Map<String,List<PatchManager__c>> patchMap = new Map<String,List<PatchManager__c>>();
        for(Partner_Onboarding_Request__c PO_Request : newList){
            if(PO_Request.RecordTypeId != ResellerRecordTypeId){
                continue;
            }
        	lstPOR.add(PO_Request);
            if(PatchManager.ROUTE_ON_INSERT_PARTNER){
            	patchMap = PatchManager.getPatchMap(lstPOR, PatchManager.PARTNER_ONBOARDING);
                PatchManager.assignPartner(patchMap, PO_Request);
            }else{
                PO_Request.OwnerId = label.POB_Exception_UserId;
            }
            lstPOR.clear();
    	}
    }
    
    /**
     * @description To set comments if request is rejected
     * @param oldMap Map of old records
     * @param newList List of new records
     */
    public void setComments(Map<Id, Partner_Onboarding_Request__c> oldMap, List<Partner_Onboarding_Request__c> newList){
        
        Set<String> POBIds = new Set<String>();
        List<Partner_Onboarding_Request__c> convertPOList = new List<Partner_Onboarding_Request__c>();
        Partner_Onboarding_Request__c oldPR;
        for(Partner_Onboarding_Request__c PO_Request : newList){
        	oldPR = oldMap.get(PO_Request.Id);
            if(oldPR.Partner_Onboarding_Status__c != PO_Request.Partner_Onboarding_Status__c && PO_Request.Partner_Onboarding_Status__c  == 'Rejected'){
            	POBIds.add(PO_Request.Id);
                convertPOList.add(PO_Request);
            }
        }
        
        if(POBIds.isEmpty()){
            return;
        }
        
        List<ProcessInstanceStep> steps = [SELECT Id, StepStatus, Comments, ProcessInstance.TargetObjectId FROM ProcessInstanceStep WHERE StepStatus = 'Rejected' AND ProcessInstance.TargetObjectId IN :POBIds];
        Map<Id, String> commentsMap = new Map<Id, String>();
        for(ProcessInstanceStep step : steps){
            commentsMap.put(step.ProcessInstance.TargetObjectId, step.Comments);
        }
        
        for (Partner_Onboarding_Request__c pob : convertPOList) {
        	if (commentsMap.containsKey(pob.Id)) {
            	pob.Rejection_Comments__c = commentsMap.get(pob.Id);
            }
        }
    }
    
    /**
     * @description Create account, contact and contract if request is approved
     * @param oldMap Map of old records
     * @param newList List of new records
     */
    public void convertPartnerOnBoarding(Map<Id, Partner_Onboarding_Request__c> oldMap, List<Partner_Onboarding_Request__c> newList) {
        try {
            Partner_Onboarding_Request__c oldPR;
            List<Partner_Onboarding_Request__c> convertPOList = new List<Partner_Onboarding_Request__c>();
            for(Partner_Onboarding_Request__c PO_Request : newList){
                oldPR = oldMap.get(PO_Request.Id);
                if((PC_319InsightWebServiceCallOut.stoprecurssion == false || PO_Request.Partner_Onboarding_Status__c == 'Approved')
                        && (PO_Request.PartnerType__c == PARTNER || PO_Request.PartnerType__c == PARTNER_MSPRESELLER || (PO_Request.RecordTypeId != null && PO_Request.RecordTypeId == ResellerRecordTypeId))
                        && (oldPR.Partner_Onboarding_Status__c != PO_Request.Partner_Onboarding_Status__c && PO_Request.Partner_Onboarding_Status__c  == 'Approved')){
                    
                        convertPOList.add(PO_Request);
                }
            }
            
            if(convertPOList.isEmpty()){
                return;
            }
        
            Map<String, Account> existingpobAccMap = new Map<String, Account>();
            Set<Id> cdmIDSet = new Set<Id>();

            Map<String, Partner_Onboarding_Request__c> companyNameMap = new Map<String, Partner_Onboarding_Request__c>();
            Map<String, Partner_Onboarding_Request__c> pobMap = new Map<String, Partner_Onboarding_Request__c>();
            for (Partner_Onboarding_Request__c poRecord : convertPOList) {
                if (!String.isBlank(poRecord.Company_Name__c)) {
                    companyNameMap.put(poRecord.Company_Name__c.toLowerCase(), poRecord);
                }
                pobMap.put(poRecord.Email__c, poRecord);
                cdmIDSet.add(poRecord.OwnerID);
                
            }

            Map<String, Account> accountMap = new Map<String, Account>();
            Map<String, String> accountTypeMap = new Map<String, String>();
            Map<String, Id> contactMap = new Map<String, Id>();
            

            for (Contact conRecord : [SELECT Id, Name, Email, AccountId, Account.Name, Account.Type
                                          FROM Contact
                                          WHERE Email IN :pobMap.keySet()
                                          ORDER BY CreatedDate ASC]) {
                if (conRecord.AccountId != null && (pobMap.get(conRecord.Email).PartnerType__c == conRecord.Account.Type && pobMap.get(conRecord.Email).Company_Name__c == conRecord.Account.Name)) {
                        
					contactMap.put(conRecord.Email, conRecord.Id);
                    accountMap.put(conRecord.Account.Name.toLowerCase(), conRecord.Account);
                }
            }
            if (contactMap.isEmpty() && !companyNameMap.isEmpty()) {
                for (Account accRecord : [SELECT Id, Name, RecordTypeId, Type
                                              FROM Account
                                              WHERE Name IN :companyNameMap.keySet()]) {
                    if (accRecord.Type == companyNameMap.get(accRecord.Name.toLowerCase()).PartnerType__c) {
                        accountMap.put(accRecord.Name.toLowerCase(), accRecord);
                        existingpobAccMap.put(companyNameMap.get(accRecord.Name.toLowerCase()).Id, accRecord);
                    }
                }
            }
            
			existingpobAccMap.putAll(createAccountForOnboarding(convertPOList, cdmIDSet, accountMap, contactMap));
            
            /* update Account Lookup on POB - START*/
			List<Partner_Onboarding_Request__c> updatepobList = new List<Partner_Onboarding_Request__c>();
            for (Partner_Onboarding_Request__c pob : convertPOList){
                Partner_Onboarding_Request__c updatepob = new Partner_Onboarding_Request__c(
                    Id = pob.Id
                );
				if (existingpobAccMap.containskey(pob.Id)){
                    updatepob.Account__c = existingpobAccMap.get(pob.Id).Id;
                }
                updatepobList.add(updatepob);
            }
            if(!updatepobList.isEmpty()){
                update updatepobList;
            }
            /* update Account Lookup on POB - END*/

            Map<String, String> contactEmailIdMap = createContactsForOnboarding(convertPOList, accountMap, contactMap);

            createContractsForOnboarding(convertPOList, accountMap, contactEmailIdMap);
            
        } catch (Exception ex) {
            //PRIT-24-862 - start
            insert new Custom_Error_Log__c(
                Class__c = 'PartnerOnboardingRequestTriggerHelper',
                Exception_Message__c = ex.getMessage(),
                Functionality__c = 'Enable as Partner'
            );
            //PRIT-24-862 - end
        }
    }
	
    @TestVisible
	private Map<String, Account> createAccountForOnboarding(List<Partner_Onboarding_Request__c> convertPOList, Set<Id> cdmIDSet, Map<String, Account> accountMap,  Map<String, Id> contactMap){
		Map<String, Account> pobAccMap = new Map<String, Account>();
        if(accountMap == null){
			accountMap = new Map<String, Account>();
		}	
		
		if(contactMap == null){
			contactMap = new Map<String, Id>();
		}
		if(convertPOList == null || convertPOList.isEmpty()){
			return pobAccMap;
		}
		Map<Id, List<UserTerritory2Association>> cdmTerritoryAssociationMap = new Map<Id, List<UserTerritory2Association>>();
		if (cdmIDSet != null && !cdmIDSet.isEmpty()) {
            List<UserTerritory2Association> territoryAssList = [SELECT Id, UserId, User.Name, Territory2Id, Territory2.Internal_Territory_Name__c, Territory2.ParentTerritory2Id, Territory2.ParentTerritory2.Internal_Territory_Name__c, Territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c, Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c, RoleInTerritory2, Territory2.Territory2Type.DeveloperName
                                                                         FROM UserTerritory2Association
                                                                         WHERE Territory2.Territory2Model.State = 'Active' AND Territory2.Internal_Territory_Name__c LIKE '%CDM-%' AND UserId IN :cdmIDSet];

            if (!territoryAssList.isEmpty()) {
                for (UserTerritory2Association terAss : territoryAssList) {
					if (!cdmTerritoryAssociationMap.containsKey(terAss.UserId)) {
						cdmTerritoryAssociationMap.put(terAss.UserId, new List<UserTerritory2Association>());
                    }
					cdmTerritoryAssociationMap.get(terAss.UserId).add(terAss);
                }
            }
        }
		
		
		Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(PARTNER_DISTRIBUTOR).getRecordTypeId();
		Map<String, StateCodeName__C> mapStatusStateCodeCustomSetting = StateCodeName__C.getAll();
		Map<String, CountryWithCode__c> mapStatusCountryCodeCustomSetting = CountryWithCode__c.getAll();
		String accountType;
		Account accRecord;
		
		for (Partner_Onboarding_Request__c pr_Record : convertPOList) {
            if (!accountMap.containsKey(pr_Record.Company_Name__c.toLowerCase()) && !contactMap.containsKey(pr_Record.Email__c)) {
					
                accountType = '';
                if (pr_Record.PartnerType__c == PARTNER) {
                    accountType = PARTNER;
                } else if (pr_Record.PartnerType__c == PARTNER_MSPRESELLER) {
                    accountType = PARTNER_MSPRESELLER;
                }

				accRecord = new Account();
                accRecord.Name = pr_Record.Company_Name__c;
                accRecord.BillingStreet = pr_Record.Address_1__c+' '+pr_Record.Address_2__c;
                accRecord.BillingCity = pr_Record.City__c;
                accRecord.BillingCountry = pr_Record.Country__c;
                accRecord.BillingPostalCode = pr_Record.Postal_Code__c;
                accRecord.RecordTypeId = devRecordTypeId;
                accRecord.Type = accountType;
                accRecord.OwnerId = pr_Record.OwnerID;
                accRecord.Contract_Status__c = 'Signed-Active';
                accRecord.Territory__c = pr_Record.Territory__c;
                accRecord.Distributor__c = pr_Record.Distributor_Account__c;
                accRecord.Partner_Account_Status__c = ACTIVE;
                if((pr_Record.Partner_Onboarding_Status__c == APPROVED || (pr_Record.PartnerType__c == PARTNER_MSP && pr_Record.Partner_Onboarding_Status__c == L1_APPROVED)) && pr_Record.PartnerType__c != 'Alliance Partner'){
                    accRecord.Program_Status__c = COMPLIANT;
                    accRecord.Partner_Agreement_Status__c = SIGNED_ACTIVE;
                    accRecord.Agreed_To_POC_terms__c = true;
                    accRecord.Trade_Compliance_Screened__c = true;
                }

                if(mapStatusCountryCodeCustomSetting.containsKey(pr_Record.Country__c) &&  pr_Record.StateProvince__c != null){
                    accRecord.BillingState = mapStatusStateCodeCustomSetting.get(mapStatusCountryCodeCustomSetting.get(pr_Record.Country__c).code__C+'-'+pr_Record.StateProvince__c).State_Name__c;
                } else {
                    accRecord.BillingState = null;
                }

                if(!cdmTerritoryAssociationMap.isEmpty()){
                    for(UserTerritory2Association terrAss : cdmTerritoryAssociationMap.get(pr_Record.OwnerID)){
                        if(accRecord.ETM_Theatre__c ==null && terrAss.Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c != null && terrAss.Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c.contains('CDM-')){
                            accRecord.ETM_Theatre__c = terrAss.Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c;
                            accRecord.ETM_Area__c = terrAss.Territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c;
                            accRecord.ETM_Region__c = terrAss.Territory2.ParentTerritory2.Internal_Territory_Name__c;
                            accRecord.ETM_Territory__c = terrAss.Territory2.Internal_Territory_Name__c;
                        }else if(accRecord.ETM_Theatre__c ==null && terrAss.Territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c != null && terrAss.Territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c.contains('CDM-')){
                            accRecord.ETM_Theatre__c = terrAss.Territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c;
                            accRecord.ETM_Area__c = terrAss.Territory2.ParentTerritory2.Internal_Territory_Name__c;
                            accRecord.ETM_Region__c = terrAss.Territory2.Internal_Territory_Name__c;
                        }else if(accRecord.ETM_Theatre__c ==null && terrAss.Territory2.ParentTerritory2.Internal_Territory_Name__c != null && terrAss.Territory2.ParentTerritory2.Internal_Territory_Name__c.contains('CDM-')){
                            accRecord.ETM_Theatre__c = terrAss.Territory2.ParentTerritory2.Internal_Territory_Name__c;
                            accRecord.ETM_Area__c = terrAss.Territory2.Internal_Territory_Name__c;
                        }else if(accRecord.ETM_Theatre__c ==null && terrAss.Territory2.Internal_Territory_Name__c != null && terrAss.Territory2.Internal_Territory_Name__c.contains('CDM-')){
                            accRecord.ETM_Theatre__c = terrAss.Territory2.ParentTerritory2.Internal_Territory_Name__c;
                        }
                    }
                }
                pobAccMap.put(pr_Record.Id,accRecord);
            }
        }
		
		
        if(!pobAccMap.isEmpty()){
            insert pobAccMap.values();
            for(Account accRec : pobAccMap.values()){
                accRec.isPartner = true;
                accountMap.put(accRec.Name.toLowerCase(), accRec);
            }
			//check if we can bypass account trigger
            update pobAccMap.values(); //Enable PartnerAccount 
        }
		
		
   
		return pobAccMap;
	}
	
    @TestVisible
	private Map<String,String> createContactsForOnboarding(List<Partner_Onboarding_Request__c> convertPOList, Map<String, Account> accountMap,  Map<String, Id> contactMap){
		Map<String,String> contactEmailIdMap = new Map<String,String>();
		
        if(accountMap == null){
			accountMap = new Map<String, Account>();
		}	
		
		if(contactMap == null){
			contactMap = new Map<String, Id>();
		}
        if(convertPOList == null || convertPOList.isEmpty()){
			return contactEmailIdMap;
		}
		
		List<Contact> newContactsList = new List<contact>();
        List<Contact> updateContactsList = new List<contact>();
        for(Partner_Onboarding_Request__c prRequestNew : convertPOList){
            if(accountMap.containsKey(prRequestNew.Company_Name__c.toLowerCase()) && !contactMap.containsKey(prRequestNew.Email__c)){
                Contact conSalesRecord = new Contact();
                Contact conTechnicalRecord = new Contact();
                Contact conRecord = new Contact(
							LastName = prRequestNew.Last_Name__c,
                            FirstName = prRequestNew.First_Name__c,
                            AccountId = accountMap.get(prRequestNew.Company_Name__c.toLowerCase()).Id,
                            Email = prRequestNew.Email__c,
                            Title = prRequestNew.Title__c,
                            LeadSource = CHANNEL_MARKETING,
                            OwnerId = prRequestNew.OwnerID,
                            Primary_Role__c = ADMIN,
                            Phone = prRequestNew.Phone__c
                );    

                if(String.isNotBlank(prRequestNew.Sales_Contact_Email__c) && prRequestNew.Email__c != prRequestNew.Sales_Contact_Email__c && !prRequestNew.Same_As_Portal_Admin__c){
                    conSalesRecord.LastName = prRequestNew.Sales_Contact_Last_Name__c;
                    conSalesRecord.FirstName = prRequestNew.Sales_Contact_First_Name__c;
                    conSalesRecord.AccountId = accountMap.get(prRequestNew.Company_Name__c.toLowerCase()).Id;
                    conSalesRecord.Email = prRequestNew.Sales_Contact_Email__c;
                    conSalesRecord.Title = prRequestNew.Sales_Contact_Title__c;
                    conSalesRecord.LeadSource = CHANNEL_MARKETING;
                    conSalesRecord.OwnerId = prRequestNew.OwnerID;
                    conSalesRecord.Primary_Role__c = SALES;
                    conSalesRecord.Phone = prRequestNew.Sales_Contact_Phone__c;
                    newContactsList.add(conSalesRecord);
                }

                if(String.isNotBlank(prRequestNew.Technical_Contact_Email__c) && prRequestNew.Email__c != prRequestNew.Sales_Contact_Email__c && prRequestNew.Email__c != prRequestNew.Technical_Contact_Email__c && !prRequestNew.Same_As_Portal_Admin__c && ((prRequestNew.Sales_Contact_Email__c != prRequestNew.Technical_Contact_Email__c && !prRequestNew.Same_As_Sales_Contact__c) || (prRequestNew.Sales_Contact_Email__c == prRequestNew.Technical_Contact_Email__c && prRequestNew.Same_As_Sales_Contact__c))){
                    conTechnicalRecord.LastName = prRequestNew.Technical_Contact_Last_Name__c;
                    conTechnicalRecord.FirstName = prRequestNew.Technical_Contact_First_Name__c;
                    conTechnicalRecord.AccountId = accountMap.get(prRequestNew.Company_Name__c.toLowerCase()).Id;
                    conTechnicalRecord.Email = prRequestNew.Technical_Contact_Email__c;
                    conTechnicalRecord.Title = prRequestNew.Technical_Contact_Title__c;
                    conTechnicalRecord.LeadSource = CHANNEL_MARKETING;
                    conTechnicalRecord.OwnerId = prRequestNew.OwnerID;
                    conTechnicalRecord.Phone = prRequestNew.Technical_Contact_Phone__c;
					conTechnicalRecord.Primary_Role__c = (prRequestNew.Sales_Contact_Email__c != prRequestNew.Technical_Contact_Email__c && !prRequestNew.Same_As_Sales_Contact__c)?TECHNICAL:SALES;
                    newContactsList.add(conTechnicalRecord);
                }

                if(accountMap.get(prRequestNew.Company_Name__c.toLowerCase()).RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByName().get(PARTNER_DISTRIBUTOR).getRecordTypeId() && (prRequestNew.Partner_Onboarding_Status__c == APPROVED || (prRequestNew.PartnerType__c == PARTNER_MSPRESELLER && prRequestNew.Partner_Onboarding_Status__c == L1_APPROVED))){
                    conRecord.create_Portal_User__c = true;
                    conSalesRecord.create_Portal_User__c = true;
                    conTechnicalRecord.create_Portal_User__c = true;
                }
                newContactsList.add(conRecord);
            } else if (contactMap.containsKey(prRequestNew.Email__c) && prRequestNew.Partner_Onboarding_Status__c == APPROVED || (prRequestNew.PartnerType__c == PARTNER_MSPRESELLER && prRequestNew.Partner_Onboarding_Status__c == L1_APPROVED)) {
                            
                Contact updateCon = new Contact(
                        id = contactMap.get(prRequestNew.Email__c),
                        email = prRequestNew.Email__c
                );
                updateCon.create_Portal_User__c = true;
                updateCon.Primary_Role__c = ADMIN;
                updateContactsList.add(updateCon);  
            }
		}

        if(!newContactsList.isEmpty()){
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.DuplicateRuleHeader.AllowSave = true;
            Database.SaveResult[] sr = Database.insert(newContactsList, dml);
        }

        for(Contact c : newContactsList){
            contactEmailIdMap.put(c.email.toLowerCase(),c.Id);
        }

        if(!updateContactsList.isEmpty()){
            update updateContactsList;
        }

        for(Contact c : updateContactsList){
            contactEmailIdMap.put(c.email.toLowerCase(),c.Id);
        }
		return contactEmailIdMap;
	}
	
    @TestVisible
	private void createContractsForOnboarding(List<Partner_Onboarding_Request__c> convertPOList, Map<String, Account> accountMap,  Map<String, String> contactEmailIdMap){
		/*Contract creation - START  **/
		
		if(stopContractcreation == true){
			return;
		}
		stopContractcreation = false;
		
		if(accountMap == null){
			accountMap = new Map<String, Account>();
		}	
		
		if(contactEmailIdMap == null){
			contactEmailIdMap = new Map<String, String>();
		}

        if(convertPOList == null || convertPOList.isEmpty()){
			return;
		}
		
        Boolean flag = false;
        Boolean flagPD = false;
        List<Contract> contractList = new List<Contract>();
		Contract ct;
 
        for(Partner_Onboarding_Request__c prRequestNew : convertPOList){
            if(accountMap.isEmpty() || !accountMap.containsKey(prRequestNew.Company_Name__c.toLowerCase()) || contactEmailIdMap.isEmpty() || !contactEmailIdMap.containsKey(prRequestNew.Email__c.toLowerCase())){
				continue;
			}
			
			ct = new Contract();
			ct.Territory__c = prRequestNew.Territory__c != null && prRequestNew.Territory__c != '' ? prRequestNew.Territory__c : '';
			ct.AccountId = accountMap.get(prRequestNew.Company_Name__c.toLowerCase()).Id;
            ct.CustomerSignedDate = Date.valueOf(prRequestNew.CreatedDate);
			ct.CustomerSignedTitle = (String.isNotBlank(prRequestNew.Title__c) && prRequestNew.Title__c.length() > 40)?prRequestNew.Title__c.left(40):prRequestNew.Title__c;
            ct.CustomerSignedId = contactEmailIdMap.get(prRequestNew.Email__c.toLowerCase());
			ct.Click_Through__c = true;
            ct.StartDate = System.today();
            ct.CompanySignedDate = System.today();
            ct.Contract_Status__c = ACTIVE;
            ct.CompanySignedId = UserInfo.getuserId();
			
			if(String.isNotBlank(prRequestNew.Master_Terms__c) && (prRequestNew.PartnerType__c == PARTNER_MSPRESELLER || prRequestNew.PartnerType__c == PARTNER) && prRequestNew.Partner_Onboarding_Status__c == APPROVED){
                ct.ContractTerm = 1000;
				ct.Terms_Download_Url__c = prRequestNew.Master_Terms__c;
                ct.ClickThroughContract_Name__c = 'Master';
                ct.Agreement_Type__c = 'Master Agreement';
                ct.Territory_Country__c = prRequestNew.Country__c;
                contractList.add(ct);
            }
			if(String.isNotBlank(prRequestNew.Secondary_Terms__c) && (prRequestNew.PartnerType__c == PARTNER_MSPRESELLER || prRequestNew.PartnerType__c == PARTNER) && prRequestNew.Partner_Onboarding_Status__c == APPROVED){
                ct = ct.clone();
				ct.ContractTerm = 1000;
				ct.Terms_Download_Url__c = prRequestNew.Secondary_Terms__c;
                ct.ClickThroughContract_Name__c = 'Secondary';
				ct.Agreement_Type__c = PARTNER;
				ct.Territory_Country__c = prRequestNew.Country__c;
				contractList.add(ct);
			}
			if(String.isNotBlank(prRequestNew.Secondary_Terms__c) && (prRequestNew.PartnerType__c == PARTNER_MSPRESELLER || prRequestNew.PartnerType__c == PARTNER) && prRequestNew.Partner_Onboarding_Status__c == APPROVED
				&& prRequestNew.Country__c == 'United States' && String.isNotBlank(prRequestNew.Segment__c) && prRequestNew.Segment__c.containsIgnoreCase('Commercial/Enterprise')){
					
                ct = ct.clone();
				ct.ContractTerm = 12;
				ct.Terms_Download_Url__c = prRequestNew.Secondary_Terms__c;
                ct.ClickThroughContract_Name__c = 'Preferred Distributor';
				ct.Agreement_Type__c = 'Preferred Distributor';
				ct.Territory_Country__c = prRequestNew.Country__c;
				contractList.add(ct);
			}
			if(String.isNotBlank(prRequestNew.Tertiary_Terms__c) && prRequestNew.PartnerType__c == PARTNER_MSPRESELLER && prRequestNew.Partner_Onboarding_Status__c == APPROVED){
                ct = ct.clone();
				ct.ContractTerm = 1000;
				ct.Terms_Download_Url__c = prRequestNew.Tertiary_Terms__c;
                ct.ClickThroughContract_Name__c = 'Tertiary';
                ct.Agreement_Type__c = PARTNER_MSPRESELLER;
				ct.Territory_Country__c = null;
                contractList.add(ct);
            }
        }
                    
        if(!contractList.isEmpty()){
            insert contractList;
            List<Id> contractListId = new List<Id>();
            for(Contract ctr : contractList){
                contractListId.add(ctr.Id);
            }
            PartnerOnboardingRequestTriggerHelper.contractpdfcreation(contractListId, Network.getNetworkId());
        }
        /*Contract creation - END */
	}
    
	/**
     * @description create contract pdf for distributor and sevice delivery requests
     * @param contractListId List of Contract Ids
	 * @param netId Network Id
     */
    @future(callout=true)
    public static void contractpdfcreation(List<Id> contractListId, Id netId){
        List<Contract> contractList = new List<Contract>();
        List<ContentVersion> cvList = new List<ContentVersion>();
        List<ContentVersion> newcvList = new List<ContentVersion>();
        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
        Map<string,string> cvMap = new Map<string,string>();
        string Endpoint;
        try{
            contractList = [SELECT Id,Terms_Download_Url__c,ClickThroughContract_Name__c,status,Contract_Status__c
                            FROM Contract
                            WHERE Id IN:contractListId];
            for (Contract ct : contractList){
                ct.Contract_Status__c = ACTIVE;
                ct.status = 'Activated';
                Http http = new Http();
                Endpoint = ct.Terms_Download_Url__c;
                HttpRequest req1 = new HttpRequest();
                req1.setEndpoint(Endpoint);
                req1.setMethod('GET');
		        req1.setHeader('Content-Type', 'application/pdf');
        	    req1.setCompressed(true);
                req1.setHeader('Authorization','Bearer '+system.label.pactsafe_access_token);
                HTTPResponse res1;
                if(!Test.isRunningTest()){
                    res1 = http.send(req1);
                }else{
                    res1 = new HttpResponse();
                    res1.setBodyAsBlob(Blob.valueOf('test'));
                }
                
                Blob retFile = res1.getBodyAsBlob();
                cvList.add(FileClass.insertCVBlob('ClickThrough'+ct.ClickThroughContract_Name__c+'Contract.pdf',retFile, netId));
            }
            if(!contractList.isEmpty()){
                update contractList;
            }
            if(!cvList.isEmpty()){
                insert cvList;
                newcvList = [SELECT Id,Title, ContentDocumentId
                            FROM ContentVersion
                            WHERE Id IN: cvList];
                for(ContentVersion cv : newcvList){
                    cvMap.put(cv.Title,cv.ContentDocumentId);
                }
            }
            for(Contract ct : contractList){
                cdlList.add(FileClass.insertCDL(cvMap.get('ClickThrough'+ct.ClickThroughContract_Name__c+'Contract.pdf'),ct.Id));
            }
            if(!cdlList.isEmpty()){
                insert cdlList;
            }
        } catch (Exception ex) {
            // Exception handling for contractpdfcreation method
			insert new Custom_Error_Log__c(
                Class__c = 'PartnerOnboardingRequestTriggerHelper',
                Exception_Message__c = ex.getMessage(),
                Functionality__c = 'Enable as Partner'
            );
        }
    }
    
	/**
     * @description To invoke insight service
     * @param oldMap Map of old records
     * @param newList List of new records
     */
    public void insightWebServiceCallOut(Map<Id, Partner_Onboarding_Request__c> oldMap, List<Partner_Onboarding_Request__c> newList){
	
		if(PC_319InsightWebServiceCallOut.stoprecurssion == true){
			return;
		}
        Partner_Onboarding_Request__c oldPR;
        List<String> pobIdList = new List<String>();
        for(Partner_Onboarding_Request__c PO_Request : newList){
        	oldPR = oldMap.get(PO_Request.Id);
            if((PO_Request.PartnerType__c == PARTNER || PO_Request.PartnerType__c == PARTNER_MSPRESELLER || (PO_Request.RecordTypeId != null && PO_Request.RecordTypeId == ResellerRecordTypeId))
				&& ((oldPR.Partner_Onboarding_Status__c != PO_Request.Partner_Onboarding_Status__c && PO_Request.Partner_Onboarding_Status__c == 'L1 Approved' && PO_Request.Country__c != 'United States')
						|| (oldPR.Partner_Onboarding_Status__c != PO_Request.Partner_Onboarding_Status__c && PO_Request.Partner_Onboarding_Status__c == 'L2 Approved' && PO_Request.Country__c == 'United States'))){
                    pobIdList.add(PO_Request.Id);
                    
			}else if((PO_Request.RecordTypeId == DistRecTypeId || PO_Request.RecordTypeId == SDRecordTypeId) 
					&& (oldPR.Partner_Onboarding_Status__c != PO_Request.Partner_Onboarding_Status__c && ((PO_Request.Partner_Onboarding_Status__c == 'L3 Approved' && PO_Request.RecordTypeId == DistRecTypeId) || (PO_Request.Partner_Onboarding_Status__c == 'L2 Approved' && PO_Request.RecordTypeId == SDRecordTypeId)))){
                   	pobIdList.add(PO_Request.Id);
            }
        }
        
        if(!pobIdList.isEmpty()){
            PC_319InsightWebServiceCallOut.mainRequest(pobIdList);
        }
    }

    /**
     * @description To populate channel program level and channel program name on newly created accounts
     * @param accIds Set of Account Ids
     */
    public static void accountChannelprogMapping(Set<String> accIds) {
        try{
            List<Account> accList = [select id, ispartner, name, BillingCountry, ETM_Theatre__c, toLabel(type)
                       from Account
                       where Id IN:accIds];
            Map<string, string> accChannelMap = new Map<string, string>();
            List<Channel_Program_Member_settings__mdt> channelMappings = [SELECT MasterLabel, Channel_Program__c, Countries__c, Level__c, Owner_Theater__c, Partner_Type__c
                                                                          FROM Channel_Program_Member_settings__mdt
                                                                          order by Countries__c asc
                                                                          NULLS LAST];

            Boolean isValidCm;
            for (Account acc : accList){
                for (Channel_Program_Member_settings__mdt cm : channelMappings){
                    isValidCm = !string.isBlank(acc.type) && acc.type.contains(PARTNER) && cm.Partner_Type__c.contains(acc.type) && ((acc.ETM_Theatre__c != null && cm.Owner_Theater__c != null && cm.Owner_Theater__c.contains(acc.ETM_Theatre__c)) || (String.isBlank(acc.ETM_Theatre__c)));
                    if(isValidCm && !string.isBlank(acc.BillingCountry) && !string.isBlank(cm.Countries__c) && cm.Countries__c.contains(acc.BillingCountry)){
                        accChannelMap.put(acc.Id,cm.Channel_Program__c+':'+cm.Level__c);
                    }else if(isValidCm && string.isBlank(cm.Countries__c) && !accChannelMap.containskey(acc.Id)){
                        accChannelMap.put(acc.Id,cm.Channel_Program__c+':'+cm.Level__c);
                    }
                }
            }
            set<string> channelprogSet = new set<string>();
            set<string> channelproglevelSet = new set<string>();
            List<string> tempArr = new List<string>();
            List<ChannelProgramMember> cpmList = new List<ChannelProgramMember>();
            List<ChannelProgramLevel> cplList = new List<ChannelProgramLevel>();
            for(string mapValues : accChannelMap.values()){
                if(!mapValues.contains(':')){
                    continue;
                }
                tempArr = mapValues.split(':');
                channelprogSet.add(tempArr[0]);
                channelproglevelSet.add(tempArr[1]);
            }
            if (!channelproglevelSet.isEmpty()){
                cplList = [select id, name, ProgramId, Program.Name
                           from ChannelProgramLevel
                           where name IN:channelproglevelSet AND Program.Name IN:channelprogSet];
            }
            for(Account acc : accList){
                for(ChannelProgramLevel cpl : cplList){
                    if(!accChannelMap.isEmpty() && accChannelMap.get(acc.Id) == cpl.Program.Name+':'+cpl.Name){
                        cpmList.add(new ChannelProgramMember(PartnerId = acc.Id,ProgramId = cpl.ProgramId,LevelId = cpl.Id));
                    }
                }
            }
            if(!cpmList.isEmpty()){
                insert cpmList;
            }
        } catch (Exception ex) {
            // Exception handling for accountChannelprogMapping method

            insert new Custom_Error_Log__c(
                Class__c = 'PartnerOnboardingRequestTriggerHelper',
                Exception_Message__c = ex.getMessage(),
                Functionality__c = 'accountChannelprogMapping'
            );
        }
    }
}