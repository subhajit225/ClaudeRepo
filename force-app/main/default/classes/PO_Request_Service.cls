/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-10-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class PO_Request_Service {
    public static boolean stopContractcreation = false;
    public static string APPROVED = 'Approved';
    public static string L1_APPROVED = 'L1 Approved';
    public static string REJECTED = 'Rejected';
    public static string PARTNER_MSPRESELLER = 'MSP-Reseller';
    public static string PARTNER = 'Reseller';
    public static string CHANNEL_MARKETING = 'Channel Marketing';
    public static string NONE = 'None';
    public static string NON_APPlICABLE = 'Non Applicable';
    public static string COMPLIANT = 'Compliant';
    public static string PROBATION = 'Probation';
    public static string UNSIGNED = 'Unsigned';
    public static string SIGNED_ACTIVE = 'Signed - Active';
    public static string ACTIVE = 'Active';
    public static string PARTNER_DISTRIBUTOR =  'Partner/Distributor';
    public static final String AGREMENT_ATTACHMENT = '%Agreement%';
    public static final String CONTRACT = '%Contract%';
    public static string PARTNER_MSP = 'MSP';
    public static string ADMIN = 'Admin';
    public static string SALES = 'Sales';
    public static string TECHNICAL = 'Technical';

    public static void setComments(List<Partner_Onboarding_Request__c> convertPOList){
        Set<String> POBIds = new Set<String>();
        for (Partner_Onboarding_Request__c pob : convertPOList) {
            POBIds.add(pob.Id);
        }
        List<ProcessInstance> piList = [SELECT Id, TargetObjectId, (SELECT Id, StepStatus, Comments
                                                                    FROM Steps
                                                                    where StepStatus = 'Rejected')
                                        From ProcessInstance
                                        where TargetObjectId IN:POBIds];
        for (Partner_Onboarding_Request__c pob : convertPOList) {
            for (ProcessInstance pi : piList) {
                for (ProcessInstanceStep step : pi.Steps) {
                    if (pi.TargetObjectId == pob.Id) {
                        pob.Rejection_Comments__c = step.Comments;
                    }
                }
            }
        }
    }

    public static void setflagpartnerMsp(List<Partner_Onboarding_Request__c> convertPOList) {
        Map<String, String> partnerAccMap = new Map<String, String>();
        List<Account> updateaccRecord = new List<Account>();

        for (Partner_Onboarding_Request__c poRecord : convertPOList) {
            if (!String.isBlank(poRecord.Company_Name__c)) {
                partnerAccMap.put(poRecord.Company_Name__c, poRecord.PartnerType__c);
            }
        }

        List<Account> accRecord = [SELECT Id, Name, Type, RecordTypeId
                                   FROM Account
                                   WHERE Name IN :partnerAccMap.keySet()];
        for (Account acc : accRecord) {
            if (partnerAccMap != null && partnerAccMap.containsKey(acc.Name) && partnerAccMap.get(acc.Name) == PARTNER_MSPRESELLER && acc.Type == PARTNER) {
                Account rec = new Account();
                rec.Id = acc.Id;
                rec.Type = PARTNER_MSPRESELLER;
                updateaccRecord.add(rec);
            }
        }

        if (!updateaccRecord.isEmpty()) {
            update updateaccRecord;
        }
    }

    public static void convertPRtoContact(List<Partner_Onboarding_Request__c> convertPOList) {
        try {
            String contactAccountName = '';
            Map<String, Account> pobAccMap = new Map<String, Account>();
            Map<String, Account> existingpobAccMap = new Map<String, Account>();
            List<Partner_Onboarding_Request__c> updatepobList = new List<Partner_Onboarding_Request__c>();
            Set<Id> cdmIDSet = new Set<Id>();
            if (!convertPOList.isEmpty()) {
                Map<String, String> companyNameMap = new Map<String, String>();
                Map<String, String> companyNamePobIdMap = new Map<String, String>();
                List<String> contactEmailList = new List<String>();
                Map<String, Partner_Onboarding_Request__c> pobMap = new Map<String, Partner_Onboarding_Request__c>();
                for (Partner_Onboarding_Request__c poRecord : convertPOList) {
                    if (!String.isBlank(poRecord.Company_Name__c)) {
                        companyNameMap.put(poRecord.Company_Name__c, poRecord.PartnerType__c);
                    }
                    contactEmailList.add(poRecord.Email__c);
                    pobMap.put(poRecord.Email__c, poRecord);
                    cdmIDSet.add(poRecord.OwnerID);
                    companyNamePobIdMap.put(poRecord.Company_Name__c, poRecord.Id);
                }

                Map<String, Id> accountMap = new Map<String, Id>();
                Map<String, String> accountTypeMap = new Map<String, String>();
                Map<String, Id> contactMap = new Map<String, Id>();
                Map<Id, Account> accountIdRecordMap = new Map<Id, Account>();
                Map<Id, List<UserTerritory2Association>> cdmTerritoryAssociationMap = new Map<Id, List<UserTerritory2Association>>();

                for (Contact conRecord : [SELECT Id, Name, Email, AccountId, Account.Name, Account.Type
                                          FROM Contact
                                          WHERE Email IN :contactEmailList
                                          ORDER BY CreatedDate ASC]) {
                    if (conRecord.AccountId != null && pobMap != null && !pobMap.isEmpty() && pobMap.containsKey(conRecord.Email)) {
                        if (pobMap.get(conRecord.Email).PartnerType__c == conRecord.Account.Type && pobMap.get(conRecord.Email).Company_Name__c == conRecord.Account.Name) {
                            contactMap.put(conRecord.Email, conRecord.Id);
                            if (conRecord.AccountId != null) {
                                accountMap.put(conRecord.Account.Name, conRecord.AccountId);
                                contactAccountName = conRecord.Account.Name;
                            }
                        }
                    }
                }
                if (contactMap.isEmpty() && !companyNameMap.isEmpty()) {
                    for (Account accRecord : [SELECT Id, Name, RecordTypeId, Type
                                              FROM Account
                                              WHERE Name IN :companyNameMap.keySet()]) {
                        if (companyNameMap != null && companyNameMap.containsKey(accRecord.Name) && accRecord.Type == companyNameMap.get(accRecord.Name)) {
                            accountMap.put(accRecord.Name, accRecord.Id);
                            accountIdRecordMap.put(accRecord.Id, accRecord);
                            contactAccountName = accRecord.Name;
                            if (companyNamePobIdMap.containsKey(accRecord.Name)) {
                                existingpobAccMap.put(companyNamePobIdMap.get(accRecord.Name), accRecord);
                            }
                        }
                    }
                }
                if (!cdmIDSet.isEmpty()) {
                    List<UserTerritory2Association> territoryAssList = [SELECT Id, UserId, User.Name, Territory2Id, Territory2.Internal_Territory_Name__c, Territory2.ParentTerritory2Id, Territory2.ParentTerritory2.Internal_Territory_Name__c, Territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c, Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c, RoleInTerritory2, Territory2.Territory2Type.DeveloperName
                                                                         FROM UserTerritory2Association
                                                                         WHERE Territory2.Territory2Model.State = 'Active' AND Territory2.Internal_Territory_Name__c LIKE '%CDM-%' AND UserId IN :cdmIDSet];

                    if (!territoryAssList.isEmpty()) {
                        for (UserTerritory2Association terAss : territoryAssList) {
                            if (cdmTerritoryAssociationMap.containsKey(terAss.UserId)) {
                                cdmTerritoryAssociationMap.get(terAss.UserId).add(terAss);
                            } else {
                                List<UserTerritory2Association> terrRecList = new List<UserTerritory2Association>();
                                terrRecList.add(terAss);
                                cdmTerritoryAssociationMap.put(terAss.UserId, terrRecList);
                            }
                        }
                    }
                }

                for (Partner_Onboarding_Request__c pr_Record : convertPOList) {
                    if ((accountMap.isEmpty() || (!accountMap.containsKey(pr_Record.Company_Name__c)) && contactMap.isEmpty())) {
                        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(PARTNER_DISTRIBUTOR).getRecordTypeId();
                        String accountType = '';
                        if (pr_Record.PartnerType__c == 'Reseller') {
                            accountType = PARTNER;
                        } else if (pr_Record.PartnerType__c == 'MSP-Reseller') {
                            accountType = PARTNER_MSPRESELLER;
                        }

                        Account AccRecord = new Account();
                        AccRecord.Name = pr_Record.Company_Name__c;
                        AccRecord.BillingStreet = pr_Record.Address_1__c+' '+pr_Record.Address_2__c;
                        AccRecord.BillingCity = pr_Record.City__c;
                        AccRecord.BillingCountry = pr_Record.Country__c;
                        AccRecord.BillingPostalCode = pr_Record.Postal_Code__c;
                        AccRecord.RecordTypeId = devRecordTypeId;
                        AccRecord.Type = accountType;
                        AccRecord.OwnerId = pr_Record.OwnerID;
                        AccRecord.Contract_Status__c = 'Signed-Active';
                        AccRecord.Territory__c = pr_Record.Territory__c;
                        AccRecord.Distributor__c = pr_Record.Distributor_Account__c;
                        if((pr_Record.Partner_Onboarding_Status__c == APPROVED || (pr_Record.PartnerType__c == PARTNER_MSP && pr_Record.Partner_Onboarding_Status__c == L1_APPROVED)) && pr_Record.PartnerType__c != 'Alliance Partner'){
                            AccRecord.Program_Status__c = COMPLIANT;
                            AccRecord.Partner_Agreement_Status__c = SIGNED_ACTIVE;
                            AccRecord.Agreed_To_POC_terms__c = true;
                            AccRecord.Trade_Compliance_Screened__c = true;
                        }

                        Map<String, StateCodeName__C> mapStatusStateCodeCustomSetting = StateCodeName__C.getAll();
                        Map<String, CountryWithCode__c> mapStatusCountryCodeCustomSetting = new Map<String, CountryWithCode__c>();
                        mapStatusCountryCodeCustomSetting = CountryWithCode__c.getAll();
                        String uniqueCode = '';
                        if(mapStatusCountryCodeCustomSetting.containsKey(pr_Record.Country__c) &&  pr_Record.StateProvince__c != null){
                            uniqueCode = mapStatusCountryCodeCustomSetting.get(pr_Record.Country__c).code__C+'-'+pr_Record.StateProvince__c;
                            AccRecord.BillingState = mapStatusStateCodeCustomSetting.get(uniqueCode).State_Name__c;
                        } else {
                            AccRecord.BillingState = null;
                        }

                        if(!cdmTerritoryAssociationMap.isEmpty()){
                            for(UserTerritory2Association terrAss : cdmTerritoryAssociationMap.get(pr_Record.OwnerID)){
                                if(AccRecord.ETM_Theatre__c ==null && terrAss.Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c != null && terrAss.Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c.contains('CDM-')){
                                    AccRecord.ETM_Theatre__c = terrAss.Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c;
                                    AccRecord.ETM_Area__c = terrAss.Territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c;
                                    AccRecord.ETM_Region__c = terrAss.Territory2.ParentTerritory2.Internal_Territory_Name__c;
                                    AccRecord.ETM_Territory__c = terrAss.Territory2.Internal_Territory_Name__c;
                                }else if(AccRecord.ETM_Theatre__c ==null && terrAss.Territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c != null && terrAss.Territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c.contains('CDM-')){
                                    AccRecord.ETM_Theatre__c = terrAss.Territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c;
                                    AccRecord.ETM_Area__c = terrAss.Territory2.ParentTerritory2.Internal_Territory_Name__c;
                                    AccRecord.ETM_Region__c = terrAss.Territory2.Internal_Territory_Name__c;
                                }else if(AccRecord.ETM_Theatre__c ==null && terrAss.Territory2.ParentTerritory2.Internal_Territory_Name__c != null && terrAss.Territory2.ParentTerritory2.Internal_Territory_Name__c.contains('CDM-')){
                                    AccRecord.ETM_Theatre__c = terrAss.Territory2.ParentTerritory2.Internal_Territory_Name__c;
                                    AccRecord.ETM_Area__c = terrAss.Territory2.Internal_Territory_Name__c;
                                }else if(AccRecord.ETM_Theatre__c ==null && terrAss.Territory2.Internal_Territory_Name__c != null && terrAss.Territory2.Internal_Territory_Name__c.contains('CDM-')){
                                    AccRecord.ETM_Theatre__c = terrAss.Territory2.ParentTerritory2.Internal_Territory_Name__c;
                                }
                            }
                        }
                        pobAccMap.put(pr_Record.Id,AccRecord);
                    }
                }

                try{
                    if(!pobAccMap.isEmpty()){
                        insert pobAccMap.values();
                        for(Account accRec : pobAccMap.values()){
                            if(String.isNotBlank(accRec.Contract_Status__c) && !accRec.Contract_Status__c.equals('Rejected')){
                                accRec.isPartner = true;
                            }
                            accountMap.put(accRec.Name, accRec.Id);
                            accountIdRecordMap.put(accRec.Id,accRec);
                            accountTypeMap.put(accRec.Name, accRec.RecordTypeId);
                        }
                        update pobAccMap.values(); //Enable PartnerAccount
                    }
                    /* update Account Lookup on POB - START*/
                    for (Partner_Onboarding_Request__c pob : convertPOList){
                        Partner_Onboarding_Request__c updatepob = new Partner_Onboarding_Request__c(
                            Id = pob.Id
                        );
                        if (!pobAccMap.isEmpty() && pobAccMap.containskey(pob.Id)){
                            updatepob.Account__c = pobAccMap.get(pob.Id).Id;
                        } else if (!existingpobAccMap.isEmpty() && existingpobAccMap.containskey(pob.Id)){
                            updatepob.Account__c = existingpobAccMap.get(pob.Id).Id;
                        }
                        updatepobList.add(updatepob);
                    }
                    if(!updatepobList.isEmpty()){
                        update updatepobList;
                    }
                    /* update Account Lookup on POB - END*/
                } catch (DMLException ex) {
                    //PRIT-24-862 - start
                    Custom_Error_Log__c errorLogRec = new Custom_Error_Log__c(
                        Class__c = 'PO_Request_Service',
                        Exception_Message__c = ex.getMessage(),
                        Functionality__c = 'Enable as Partner'
                    );
                    insert errorLogRec;
                    //PRIT-24-862 - end
                }

                List<Contact> newContactsList = new List<contact>();
                List<Contact> updateContactsList = new List<contact>();
                for(Partner_Onboarding_Request__c prRequestNew : convertPOList){
                    if(!accountMap.isEmpty() && (accountMap.containsKey(prRequestNew.Company_Name__c) && contactMap.isEmpty())){
                        Contact conSalesRecord = new Contact();
                        Contact conTechnicalRecord = new Contact();
                        Contact conRecord = new Contact(
                            LastName = prRequestNew.Last_Name__c,
                            FirstName = prRequestNew.First_Name__c,
                            AccountId = accountMap.get(prRequestNew.Company_Name__c),
                            Email = prRequestNew.Email__c,
                            Title = prRequestNew.Title__c,
                            LeadSource = CHANNEL_MARKETING,
                            OwnerId = prRequestNew.OwnerID,
                            Primary_Role__c = ADMIN,
                            Phone = prRequestNew.Phone__c
                        );

                        if(prRequestNew.Email__c != prRequestNew.Sales_Contact_Email__c && !prRequestNew.Same_As_Portal_Admin__c){
                            conSalesRecord.LastName = prRequestNew.Sales_Contact_Last_Name__c;
                            conSalesRecord.FirstName = prRequestNew.Sales_Contact_First_Name__c;
                            conSalesRecord.AccountId = accountMap.get(prRequestNew.Company_Name__c);
                            conSalesRecord.Email = prRequestNew.Sales_Contact_Email__c;
                            conSalesRecord.Title = prRequestNew.Sales_Contact_Title__c;
                            conSalesRecord.LeadSource = CHANNEL_MARKETING;
                            conSalesRecord.OwnerId = prRequestNew.OwnerID;
                            conSalesRecord.Primary_Role__c = SALES;
                            conSalesRecord.Phone = prRequestNew.Sales_Contact_Phone__c;
                            newContactsList.add(conSalesRecord);
                        }

                        if(prRequestNew.Email__c != prRequestNew.Sales_Contact_Email__c && prRequestNew.Email__c != prRequestNew.Technical_Contact_Email__c && prRequestNew.Sales_Contact_Email__c != prRequestNew.Technical_Contact_Email__c && !prRequestNew.Same_As_Portal_Admin__c && !prRequestNew.Same_As_Sales_Contact__c){
                            conTechnicalRecord.LastName = prRequestNew.Technical_Contact_Last_Name__c;
                            conTechnicalRecord.FirstName = prRequestNew.Technical_Contact_First_Name__c;
                            conTechnicalRecord.AccountId = accountMap.get(prRequestNew.Company_Name__c);
                            conTechnicalRecord.Email = prRequestNew.Technical_Contact_Email__c;
                            conTechnicalRecord.Title = prRequestNew.Technical_Contact_Title__c;
                            conTechnicalRecord.LeadSource = CHANNEL_MARKETING;
                            conTechnicalRecord.OwnerId = prRequestNew.OwnerID;
                            conTechnicalRecord.Primary_Role__c = TECHNICAL;
                            conTechnicalRecord.Phone = prRequestNew.Technical_Contact_Phone__c;
                            newContactsList.add(conTechnicalRecord);
                        }

                        if(prRequestNew.Email__c != prRequestNew.Sales_Contact_Email__c && prRequestNew.Email__c != prRequestNew.Technical_Contact_Email__c && prRequestNew.Sales_Contact_Email__c == prRequestNew.Technical_Contact_Email__c && !prRequestNew.Same_As_Portal_Admin__c && prRequestNew.Same_As_Sales_Contact__c){
                            conTechnicalRecord.LastName = prRequestNew.Technical_Contact_Last_Name__c;
                            conTechnicalRecord.FirstName = prRequestNew.Technical_Contact_First_Name__c;
                            conTechnicalRecord.AccountId = accountMap.get(prRequestNew.Company_Name__c);
                            conTechnicalRecord.Email = prRequestNew.Technical_Contact_Email__c;
                            conTechnicalRecord.Title = prRequestNew.Technical_Contact_Title__c;
                            conTechnicalRecord.LeadSource = CHANNEL_MARKETING;
                            conTechnicalRecord.OwnerId = prRequestNew.OwnerID;
                            conTechnicalRecord.Primary_Role__c = SALES;
                            conTechnicalRecord.Phone = prRequestNew.Technical_Contact_Phone__c;
                            newContactsList.add(conTechnicalRecord);
                        }

                        if(accountTypeMap.get(prRequestNew.Company_Name__c) == Schema.SObjectType.Account.getRecordTypeInfosByName().get(PARTNER_DISTRIBUTOR).getRecordTypeId() && (prRequestNew.Partner_Onboarding_Status__c == APPROVED || (prRequestNew.PartnerType__c == PARTNER_MSPRESELLER && prRequestNew.Partner_Onboarding_Status__c == L1_APPROVED))){
                            conRecord.create_Portal_User__c = true;
                            conSalesRecord.create_Portal_User__c = true;
                            conTechnicalRecord.create_Portal_User__c = true;
                        }
                        newContactsList.add(conRecord);
                    } else {
                        //update
                        if (contactMap != null && contactMap.containsKey(prRequestNew.Email__c)) {
                            if (prRequestNew.Partner_Onboarding_Status__c == APPROVED || (prRequestNew.PartnerType__c == PARTNER_MSPRESELLER && prRequestNew.Partner_Onboarding_Status__c == L1_APPROVED)){
                                Contact updateCon = new Contact(
                                    id = contactMap.get(prRequestNew.Email__c)
                                );
                                updateCon.create_Portal_User__c = true;
                                updateCon.Primary_Role__c = ADMIN;
                                updateContactsList.add(updateCon);
                            }
                        }
                    }
                }

                if(!newContactsList.isEmpty()){
                    Database.DMLOptions dml = new Database.DMLOptions();
                    dml.DuplicateRuleHeader.AllowSave = true;
                    Database.SaveResult[] sr = Database.insert(newContactsList, dml);
                }

                Map<String,String> contactEmailIdMap = new Map<String,String>();
                for(Contact c : newContactsList){
                    contactEmailIdMap.put(c.email,c.Id);
                }

                if(!updateContactsList.isEmpty()){
                    update updateContactsList;
                }

                for(Contact c : updateContactsList){
                    contactEmailIdMap.put(c.email,c.Id);
                }

                /*Contract creation - START  **/
                Boolean flag = false;
                Boolean flagPD = false;
                List<Contract> contractList = new List<Contract>();
                if(stopContractcreation == false){
                    stopContractcreation = true;
                    for(Partner_Onboarding_Request__c prRequestNew : convertPOList){
                        if(!accountMap.isEmpty() && accountMap.containsKey(prRequestNew.Company_Name__c) && !contactEmailIdMap.isEmpty() && contactEmailIdMap.containsKey(prRequestNew.Email__c)){
                            for(Integer i=1;i<=3;i++){
                                flag = false;
                                Contract ct = new Contract();
                                ct.Territory__c= prRequestNew.Territory__c != null && prRequestNew.Territory__c != '' ? prRequestNew.Territory__c : '';
                                if(i==1 && !string.isBlank(prRequestNew.Master_Terms__c) && (prRequestNew.PartnerType__c == PARTNER_MSPRESELLER || prRequestNew.PartnerType__c == PARTNER) && prRequestNew.Partner_Onboarding_Status__c == APPROVED){
                                    ct.Terms_Download_Url__c = prRequestNew.Master_Terms__c;
                                    ct.ClickThroughContract_Name__c = 'Master';
                                    ct.Agreement_Type__c = 'Master Agreement';
                                    ct.Territory_Country__c = prRequestNew.Country__c;
                                    flag = true;
                                }else if(i== 2 && !string.isBlank(prRequestNew.Secondary_Terms__c) && (prRequestNew.PartnerType__c == PARTNER_MSPRESELLER || prRequestNew.PartnerType__c == PARTNER) && prRequestNew.Partner_Onboarding_Status__c == APPROVED){
                                    ct.Terms_Download_Url__c = prRequestNew.Secondary_Terms__c;
                                    ct.ClickThroughContract_Name__c = 'Secondary';
                                    if(prRequestNew.partnertype__c == 'MSP'){
                                        ct.Agreement_Type__c = 'MSP';
                                    }else{
                                        ct.Agreement_Type__c = 'Reseller';
                                        ct.Territory_Country__c = prRequestNew.Country__c;
                                    }
                                    if(flagPD){
                                        ct.ClickThroughContract_Name__c = 'Preferred Distributor';
                                        ct.Agreement_Type__c = 'Preferred Distributor';
                                        ct.Territory_Country__c = prRequestNew.Country__c;
                                    }
                                    flag = true;
                                    if(!flagPD && prRequestNew.Country__c == 'United States' && String.isNotBlank(prRequestNew.Segment__c) && prRequestNew.Segment__c.containsIgnoreCase('Commercial/Enterprise')){
                                        flagPD = true;
                                        i=1;
                                    }
                                }else if(i==3 && !string.isBlank(prRequestNew.Tertiary_Terms__c) && prRequestNew.PartnerType__c == PARTNER_MSPRESELLER && prRequestNew.Partner_Onboarding_Status__c == APPROVED){
                                    ct.Terms_Download_Url__c = prRequestNew.Tertiary_Terms__c;
                                    ct.ClickThroughContract_Name__c = 'Tertiary';
                                    ct.Agreement_Type__c = 'MSP-Reseller';
                                    flag = true;
                                }
                                if(flag){
                                    ct.AccountId = accountMap.get(prRequestNew.Company_Name__c);
                                    ct.CustomerSignedDate = Date.valueOf(prRequestNew.CreatedDate);
                                    //PRIT24-631
                                    if(prRequestNew.Title__c != null && prRequestNew.Title__c.length() > 40){
                                        ct.CustomerSignedTitle = prRequestNew.Title__c.left(40);
                                    }
                                    ct.CustomerSignedId = contactEmailIdMap.get(prRequestNew.Email__c);
                                    if(flagPD && i==2){
                                        ct.ContractTerm = 12;
                                        flagPD = false;
                                    }else{
                                        ct.ContractTerm = 1000;
                                    }
                                    ct.Click_Through__c = true;
                                    ct.StartDate = system.today();
                                    ct.CompanySignedDate = system.today();
                                    ct.Contract_Status__c = 'Active';
                                    ct.CompanySignedId = UserInfo.getuserId();

                                    contractList.add(ct);
                                    flag = false;
                                }
                            }
                        }
                    }
                }
                if(!contractList.isEmpty()){
                    insert contractList;
                    List<Id> contractListId = new List<Id>();
                    for(Contract ct : contractList){
                        contractListId.add(ct.Id);
                    }
                    PO_Request_Service.contractpdfcreation(contractListId, Network.getNetworkId());
                }
                /*Contract creation - END */
            }
        } catch (Exception ex) {
            // Exception handling for convertPOtoContact method
        }
    }
    public static void createAccountDistSD(Map<Id, Partner_Onboarding_Request__c> approvedDistSDMap) {
        List<Partner_Onboarding_Request__c> updatepobList = new List<Partner_Onboarding_Request__c>();
        List<string> accIdSet = new List<string>();
        List<Account> updateAccList = new List<Account>();
        Map<String,boolean> resellerAccount = new Map<String,boolean>();
        Map<String,string> companyNameMap = new Map<String,string>();
        Map<String,string> companyIdMap = new Map<String,string>();
        Map<String, Account> pobAccMap = new Map<string,Account>();
        Map<String, Account> existingpobAccMap = new Map<string,Account>();
        Map<String, StateCodeName__C> mapStatusStateCodeCustomSetting = StateCodeName__C.getAll();
        Map<String, CountryWithCode__c> mapStatusCountryCodeCustomSetting = new Map<String, CountryWithCode__c>();
        mapStatusCountryCodeCustomSetting = CountryWithCode__c.getAll();
        string uniqueCode='';

        Id partnerDistRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Id DistTypeId = Schema.SObjectType.Partner_Onboarding_Request__c.getRecordTypeInfosByName().get('Distributor').getRecordTypeId();
        Id SDRecordTypeId = Schema.SObjectType.Partner_Onboarding_Request__c.getRecordTypeInfosByName().get('Service Delivery').getRecordTypeId();

        for(Partner_Onboarding_Request__c pob : approvedDistSDMap.values()){
            if(!string.isBlank(pob.Company_Name__c)){
                companyNameMap.put(pob.Company_Name__c.toLowercase(),pob.Id);
            }else if(pob.Account__c != null){
                companyNameMap.put(pob.Account_Name__c.toLowercase(),pob.Id);
            }
        }
        /* Query existing Accounts for Distributor & SD record type - START*/
        if (!companyNameMap.isEmpty() || !companyIdMap.isEmpty()){
            for (Account accRecord : [select Id, Name, Type, RecordTypeId
                                      from Account
                                      where Name IN:companyNameMap.keySet() AND RecordTypeId = :partnerDistRecordTypeId]){
                if ((approvedDistSDMap.get(companyNameMap.get(accRecord.Name.toLowercase())).RecordTypeId == DistTypeId && accRecord.Type == 'Distributor') || (approvedDistSDMap.get(companyNameMap.get(accRecord.Name.toLowercase())).RecordTypeId == SDRecordTypeId && (accRecord.Type == 'Reseller' || accRecord.Type == 'MSP' || accRecord.Type == 'MSP-Reseller'))){
                    existingpobAccMap.put(companyNameMap.get(accRecord.Name.toLowercase()), accRecord); //Map of POBId & Account
                    if (accRecord.Type == 'Reseller' || accRecord.Type == 'MSP' || accRecord.Type == 'MSP-Reseller'){
                        accIdSet.add(accRecord.Id);
                        resellerAccount.put(accRecord.Id, false);
                    }
                }
            }
        }
        /* Query existing Accounts for Distributor & SD record type - END*/
        /* Query existing Contract for SD record type to set Account Type based on Contract Agreemnt Type - START*/
        if (!accIdSet.isEmpty()){
            for (Contract con : [select Id, Contract_Status__c, Agreement_Type__c, AccountId
                                 from Contract
                                 where Agreement_Type__c = 'Reseller' AND Contract_Status__c = 'Active' AND AccountId IN:accIdSet]){
                resellerAccount.put(con.AccountId, true);
            }
        }
        /* Query existing Contract for SD record type to set Account Type based on Contract Agreemnt Type - END*/
        try{
            /* create Account for Distributor & SD record type - START*/
            for (Partner_Onboarding_Request__c pob : approvedDistSDMap.values()){
                uniqueCode = '';
                if ((existingpobAccMap.isEmpty() || !existingpobAccMap.containskey(pob.Id))){
                    Account acc = new Account(
                        BillingStreet = pob.Address_1__c + ' ' + pob.Address_2__c,
                        BillingCity = pob.City__c,
                        BillingCountry = pob.Country__c,
                        BillingPostalCode = pob.Postal_Code__c,
                        RecordTypeId = partnerDistRecordTypeId,
                        Type = pob.PartnerType__c,
                        OwnerId = pob.OwnerID,
                        Trade_Compliance_Screened__c = true,
                        Partner_Account_Status__c = ACTIVE,
                        Program_Status__c = COMPLIANT,
                        Agreed_To_POC_terms__c = true,
                        Partner_Agreement_Status__c = SIGNED_ACTIVE,
                        Contract_Status__c = 'Signed-Active',
                        Credit_Limit__c = pob.Credit_Limit__c
                    );
                    if (!string.isBlank(pob.Company_Name__c))
                        acc.Name = pob.Company_Name__c;
                    else if(pob.Account__c != null){
                        acc.Name = pob.Account_Name__c;
                    }
                    if(pob.RecordTypeId == DistTypeId){
                        acc.Type = 'Distributor';
                    }else if(pob.RecordTypeId == SDRecordTypeId){
                        acc.Type = 'MSP';
                    }
                    if(mapStatusCountryCodeCustomSetting.containsKey(pob.Country__c) &&  pob.StateProvince__c != null){
                        uniqueCode = mapStatusCountryCodeCustomSetting.get(pob.Country__c).code__C+'-'+pob.StateProvince__c;
                        acc.BillingState = mapStatusStateCodeCustomSetting.get(uniqueCode).State_Name__c;
                    } else{
                        acc.BillingState = null;
                    }
                    pobAccMap.put(pob.Id,acc);
                }
            }
            if(!pobAccMap.isEmpty()){
                insert pobAccMap.values();
                for(Account accRec : pobAccMap.values()){
                    accRec.isPartner = true;
                }
                update pobAccMap.values(); // Enable PartnerAccount
            }
            /* create Account for Distributor & SD record type - END*/
            /* update Account Lookup on POB - START*/
            for (Partner_Onboarding_Request__c pob : approvedDistSDMap.values()){
                Partner_Onboarding_Request__c updatepob = new Partner_Onboarding_Request__c(
                    Id = pob.Id, 
                    RecordTypeId = pob.RecordTypeId, 
                    Partner_Selling_Countries__c = pob.Partner_Selling_Countries__c, 
                    Credit_Limit__c = pob.Credit_Limit__c
                );
                if (!pobAccMap.isEmpty() && pobAccMap.containskey(pob.Id))
                    updatepob.Account__c = pobAccMap.get(pob.Id).Id;
                else if(!existingpobAccMap.isEmpty() && existingpobAccMap.containskey(pob.Id))
                    updatepob.Account__c = existingpobAccMap.get(pob.Id).Id;
                updatepobList.add(updatepob);
            }
            /* update Account Lookup on POB - END*/
            /* update Account for Distributor & SD record type - START*/
            for(Partner_Onboarding_Request__c pob : updatepobList){
                if(!existingpobAccMap.isEmpty() && existingpobAccMap.containskey(pob.Id) ){
                    Account acc = new Account();
                    acc = existingpobAccMap.get(pob.Id);
                    if(pob.Account__c != null && pob.RecordTypeId == SDRecordTypeId && !resellerAccount.isEmpty() && resellerAccount.containskey(pob.Account__c) && resellerAccount.get(pob.Account__c) == true){
                        acc.Type = 'MSP-Reseller';
                    }
                    acc.Trade_Compliance_Screened__c = true;
                    acc.Partner_Account_Status__c = ACTIVE;
                    acc.Program_Status__c = COMPLIANT;
                    acc.Partner_Agreement_Status__c = SIGNED_ACTIVE;
                    acc.Contract_Status__c = 'Signed-Active';
                    acc.Credit_Limit__c = pob.Credit_Limit__c;
                    updateAccList.add(acc);
                }
            }
            /* update Account for Distributor & SD record type - END*/

            if(!updateAccList.isEmpty()){
                update updateAccList;
            }
            if(!updatepobList.isEmpty()){
                flowcontroll.POBTriggerHandler = false;
                update updatepobList;
                createContractDistSD(updatepobList,DistTypeId,SDRecordTypeId); //contract creation
            }
    } catch (DMLException ex) {
        // DML Exception handling for Account Insert
    }
}
    public static void validateAttachment(List<Partner_Onboarding_Request__c> pobList) {
        Set<Id> pobWithAttchRecords = new Set<Id>();
        List<Id> pobIdList = new List<Id>();
        for(Partner_Onboarding_Request__c pob : pobList){
            pobIdList.add(pob.Id);
        }
        for(ContentDocumentLink cdl : [SELECT Id,ContentDocumentId,LinkedEntityId
                                        FROM ContentDocumentLink
                                        WHERE LinkedEntityId IN:pobIdList AND (ContentDocument.Title LIKE :AGREMENT_ATTACHMENT OR ContentDocument.Title LIKE :CONTRACT)]){
             pobWithAttchRecords.add(cdl.LinkedEntityId);
        }
        for(Partner_Onboarding_Request__c pob : pobList){
            if(!pobWithAttchRecords.contains(pob.Id)) {
                pob.addError(System.label.POB_Attachment_Validation);
            }
        }
    }

    public static void createContractDistSD(List<Partner_Onboarding_Request__c> pobList,Id DistTypeId,Id SDRecordTypeId){
        List<Contract> contractList = new List<Contract>();
        List<string> agreementTypeSet = new List<string>();
        List<string> pobIdList = new List<string>();
        List<string> contractListId = new List<string>();
        agreementTypeSet.add('Distributor');
        agreementTypeSet.add('MSP');
        agreementTypeSet.add('Master Agreement');
        for (Partner_Onboarding_Request__c pob : pobList){
            for (string agrType : agreementTypeSet){
                if ((pob.RecordTypeId == DistTypeId && agrType != 'MSP') || (pob.RecordTypeId == SDRecordTypeId && agrType != 'Distributor')){
                    Contract ct = new Contract(
                        Agreement_Type__c = agrType,
                        Territory_Country__c = pob.Partner_Selling_Countries__c,
                        AccountId = pob.Account__c,
                        StartDate = system.today(),
                        ContractTerm = 1000,
                        Contract_Negotiated__c = true,
                        Contract_Attached__c = 'Yes'
                    );
                    contractList.add(ct);
                    pobIdList.add(pob.Id);
                }
            }
            if(!contractList.isEmpty()){
                insert contractList;
                for(contract con : contractList){
                    contractListId.add(con.Id);
                }
                contractDistSDpdfcreation(contractListId,pobIdList);
            }
        }
    }
    @future(callout=true)
    public static void contractDistSDpdfcreation(List<Id> contractListId, List<Id> pobIdList){
        List<Contract> contractList = new List<Contract>();
        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
        Map<string,List<string>> cdlMap = new  Map<string,List<string>>();
        Map<string,List<string>> accContractMap = new Map<string,List<string>>();
        Map<string,string> accPOBMap = new Map<string,string>();
        try{
            contractList = [select Id, status, Contract_Status__c, AccountId
                            from Contract
                            where Id IN:contractListId];
            for (Contract ct : contractList){
                ct.status = 'Activated';
                ct.Contract_Status__c = 'Active';
                if(accContractMap.isEmpty() || !accContractMap.containsKey(ct.AccountId))
                    accContractMap.put(ct.AccountId,new List<string>());
                accContractMap.get(ct.AccountId).add(ct.Id);
            }
            if (!pobIdList.isEmpty()){
                for (Partner_Onboarding_Request__c pob : [select Id, Account__c
                                                          from Partner_Onboarding_Request__c
                                                          where Id IN:pobIdList]){
                    accPOBMap.put(pob.Account__c, pob.Id);
                }
                for (ContentDocumentLink cdl : [select Id, ContentDocumentId, LinkedEntityId
                                                from ContentDocumentLink
                                                where LinkedEntityId IN:pobIdList]){
                    if (cdlMap.isEmpty() || !cdlMap.containsKey(cdl.LinkedEntityId))
                        cdlMap.put(cdl.LinkedEntityId, new List<string>());
                    cdlMap.get(cdl.LinkedEntityId).add(cdl.ContentDocumentId);
                }
                for(string accId : accContractMap.keyset()){
                    for(string docId : cdlMap.get(accPOBMap.get(accId))){
                        for(string contractId : accContractMap.get(accId)){
                            ContentDocumentLink newcdl = new ContentDocumentLink();
                            newcdl.LinkedEntityId = contractId;
                            newcdl.ContentDocumentId = docId;
                            newcdl.ShareType = 'I';
                            newcdl.Visibility = 'AllUsers';
                            cdlList.add(newcdl);
                        }
                    }
                }
            }

            if(!contractList.isEmpty()){
                update contractList;
            }
            if(!cdlList.isEmpty()){
                insert cdlList;
            }
        } catch (Exception ex) {
            // Exception handling for contractDistSDpdfcreation method
        }
    }

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
                ct.Contract_Status__c = 'Active';
                ct.status = 'Activated';
                Http http = new Http();
                Endpoint = ct.Terms_Download_Url__c;
                HttpRequest req1 = new HttpRequest();
                req1.setEndpoint(Endpoint);
                req1.setMethod('GET');
		        req1.setHeader('Content-Type', 'application/pdf');
        	    req1.setCompressed(true);
                req1.setHeader('Authorization','Bearer '+system.label.pactsafe_access_token);
                HTTPResponse res1 = http.send(req1);
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
        }
    }

    public static void accountChannelprogMapping(Set<String> accIds) {
        List<Account> accList = new List<Account>();
        try{
            accList = [select id, ispartner, name, BillingCountry, ETM_Theatre__c, toLabel(type)
                       from Account
                       where Id IN:accIds];
            Map<string, string> accChannelMap = new Map<string, string>();
            List<Channel_Program_Member_settings__mdt> channelMappings = [SELECT MasterLabel, Channel_Program__c, Countries__c, Level__c, Owner_Theater__c, Partner_Type__c
                                                                          FROM Channel_Program_Member_settings__mdt
                                                                          order by Countries__c asc
                                                                          NULLS LAST];
            for (Account acc : accList){
                for (Channel_Program_Member_settings__mdt cm : channelMappings){
                    if(!string.isBlank(acc.type) && acc.type.contains(PARTNER) && cm.Partner_Type__c.contains(acc.type) && ((acc.ETM_Theatre__c != null && cm.Owner_Theater__c != null && cm.Owner_Theater__c.contains(acc.ETM_Theatre__c)) || (String.isBlank(acc.ETM_Theatre__c)))){
                        if(!string.isBlank(acc.BillingCountry) && !string.isBlank(cm.Countries__c) && cm.Countries__c.contains(acc.BillingCountry)){
                            accChannelMap.put(acc.Id,cm.Channel_Program__c+':'+cm.Level__c);
                        }else if(string.isBlank(cm.Countries__c) && !accChannelMap.containskey(acc.Id)){
                            accChannelMap.put(acc.Id,cm.Channel_Program__c+':'+cm.Level__c);
                        }
                    }
                }
            }
            set<string> channelprogSet = new set<string>();
            set<string> channelproglevelSet = new set<string>();
            List<string> tempArr = new List<string>();
            List<ChannelProgramMember> cpmList = new List<ChannelProgramMember>();
            List<ChannelProgramLevel> cplList = new List<ChannelProgramLevel>();
            for(string mapValues : accChannelMap.values()){
                if(mapValues.contains(':')){
                    tempArr = mapValues.split(':');
                    channelprogSet.add(tempArr[0]);
                    channelproglevelSet.add(tempArr[1]);
                }
            }
            if (!channelproglevelSet.isEmpty()){
                cplList = [select id, name, ProgramId, Program.Name
                           from ChannelProgramLevel
                           where name IN:channelproglevelSet AND Program.Name IN:channelprogSet];
            }
            for(Account acc : accList){
                for(ChannelProgramLevel cpl : cplList){
                    if(!accChannelMap.isEmpty() && accChannelMap.get(acc.Id) == cpl.Program.Name+':'+cpl.Name){
                        ChannelProgramMember cpm = new ChannelProgramMember();
                        cpm.PartnerId = acc.Id;
                        cpm.ProgramId = cpl.ProgramId;
                        cpm.LevelId = cpl.Id;
                        cpmList.add(cpm);
                    }
                }
            }
            if(!cpmList.isEmpty()){
                insert cpmList;
            }
        } catch (Exception ex) {
            // Exception handling for accountChannelprogMapping method
        }
    }

    public static void fieldEditRestriction(Map<Id, Partner_Onboarding_Request__c> oldMap, List<Partner_Onboarding_Request__c> newList){
        Set<string> queueNameSet = new Set<string>();
        Set<string> modifiedSet = new Set<string>();
        List<GroupMember> grpMemList = new List<GroupMember>();
        List<POB_Field_editing_restriction__mdt> restrictionMetaList = new List<POB_Field_editing_restriction__mdt>();

        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType leadSchema = schemaMap.get('Partner_Onboarding_Request__c');
        Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();

        restrictionMetaList = [select Id, Field_API_Name__c, MasterLabel, DeveloperName, Queue_Name__c
                               from POB_Field_editing_restriction__mdt];
        for (GroupMember gMem : [Select Group.Name, Group.DeveloperName
                                 from GroupMember
                                 where UserOrGroupId = :userinfo.getUserId() and Group.Type = 'Queue']){
            queueNameSet.add(gMem.Group.DeveloperName);
        }
        for(Partner_Onboarding_Request__c pob : newList){
            for(POB_Field_editing_restriction__mdt meta : restrictionMetaList){
                if(!Test.isRunningTest() && !queueNameSet.contains(meta.Queue_Name__c)){
                    if(oldMap != null && pob.get(meta.Field_API_Name__c) != oldMap.get(pob.Id).get(meta.Field_API_Name__c)){
                        pob.addError(meta.MasterLabel+' cannot be edited');
                    }
                    if(oldMap == null){
                        if(fieldMap.get(meta.Field_API_Name__c).getDescribe().getType() == Schema.DisplayType.BOOLEAN){
                            if(pob.get(meta.Field_API_Name__c) == true)
                                pob.addError(meta.MasterLabel+' cannot be edited');
                        }else if(pob.get(meta.Field_API_Name__c) != null){
                            pob.addError(meta.MasterLabel+' cannot be edited');
                        }
                    }
                }
            }
        }
    }

    //PRIT25-542: Recall the Approval Process on change of record owner
    public static void recallApprovalProcess(List<Id> recallApprovalList){
		List<Approval.ProcessWorkItemRequest> preqList = new List<Approval.ProcessWorkItemRequest>();
		for(ProcessInstanceWorkitem piw : [SELECT Id FROM ProcessInstanceWorkItem WHERE ProcessInstance.TargetObjectId IN :recallApprovalList AND ProcessInstance.Status = 'Pending']){
			Approval.ProcessWorkItemRequest preq= new Approval.ProcessWorkItemRequest();
			preq.setAction('Removed');
			preq.setWorkItemId(piw.Id);
			preqList.add(preq);
		}
		Approval.process(preqList);
	}
}