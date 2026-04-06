@isTest 
public with sharing class TestDataFactory {
    
    /*********************************
creates a unique string  
*********************************/
    public static String getUniqueName(){
        //makes a unique email address
        String orgId= UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName= orgId + dateString + randomInt; 
        return uniqueName.toLowerCase();    
    }
    
    
    public static Campaign insertCampaign(String strName){
        String campainRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Digital').getRecordTypeId();
        Campaign objCamp = new Campaign(Executed_By__c='Sales', Involvement_by_Customer_Marketing__c='Yes',RecordTypeId =CampainRecordTypeId,Campaign_Theme__c='Alliances',type='Digital', IsActive = True, Alliance_Partner__c = 'Cleversafe', Campaign_Sales_Theatre__c = 'APAC', Campaign_Sales_Area__c = 'APAC', Campaign_Sales_Region__c = 'APAC', Campaign_Sales_Sub_Region__c = 'APAC', Cost_Center__c = 'Alliance');
        objCamp.Alliance_Partner__c ='Amazon Web Services';
        objCamp.Campaign_Sales_Theatre__c = 'APAC';
        objCamp.Campaign_Sales_Area__c = 'APAC';
        objCamp.Campaign_Sales_Region__c='APAC';
        objCamp.Segment__c= 'Healthcare';
        objCamp.Cost_Center__c = 'Alliance';
        objCamp.GTM_Play__c = 'AWS';
        objCamp.Name = strName;
        return objCamp;
    }
    
    public static States__c insertStates(){
        States__c objStates = new States__c();
        objStates.Name = 'AK';
        return objStates;
    }
    
    public static Countries__c insertCountries(){
        Countries__c objCountries = new Countries__c();
        objCountries.Name = 'USA';
        return objCountries;
    }
    
    public static Deal_Registration__c getDealRegistration(){
        Deal_Registration__c vDeal = new Deal_Registration__c();
        vDeal.FirstName__c = 'Test';
        vDeal.LastName__c = 'Lead';
        vDeal.Phone__c = '123456789';
        vDeal.Company__c = 'REdSky';
        vDeal.Email__c = 'Test@REdSky.com';
        vDeal.Title__c = 'Sr.Dev';
        vDeal.Purchase_Timeframe__c = 'N/A';
        vDeal.Street__c = 'Street';
        vDeal.StateCode__c = 'AK';
        vDeal.PostalCode__c = '421302';
        vDeal.City__c = 'City';
        vDeal.Country__c = 'United States';
        vDeal.Partner__c = 'Rubrik';
        vDeal.Partner_Rep__c = 'Rep Name';
        vDeal.Partner_Rep_Phone_Number__c = '1234567890';
        vDeal.Partner_Rep_Email_Address__c = 'partner@redsky.com';
        vDeal.Secondary_Email_for_Deal_Reg__c = 'partner@redsky.com';
        return vDeal;
    }
    
    public static Lead insertLead(){
        Lead objLead = new Lead();
        objLead.FirstName = 'Test';
        objLead.LastName = 'Lead';
        objLead.Phone = '123456789';
        objLead.Company = 'REdSky';
        objLead.Email = 'Test@REdSky.com';
        objLead.Title = 'Sr.Dev';
        objLead.Purchase_Timeframe__c = 'N/A';
        objLead.Street = 'Street';
        objLead.StateCode = 'AK';
        objLead.LeadSource = 'E-mail';
        objLead.PostalCode = '421302';
        objLead.City = 'City';
        objLead.CountryCode = 'US';
        objLead.SDR_Led__c=true;
        objLead.Partner__c = 'Rubrik';
        objLead.Partner_Rep__c = 'Rep Name';
        objLead.Partner_Rep_Phone_Number__c = '1234567890';
        objLead.Partner_Rep_Email_Address__c = 'partner@redsky.com';
        objLead.Secondary_Email_for_Deal_Reg__c = 'partner@redsky.com';
        return objLead;
    }
    
    /*********************************
returns a fully populated Opportunity
*********************************/
    public static Opportunity getOpportunity(){
        Account vAccount = getAccount();
        insert vAccount;
        Contact vContact = getContact(vAccount);
        insert vContact;
        system.debug('vContact@@ '+vContact);
        Opportunity vOpportunity = getOpportunity(vAccount, vContact);
        return vOpportunity;
    }
    
    /*********************************
Opty with provided Contact
*********************************/
    public static Opportunity getOpportunity(Contact vContact){
        Account vAccount = getAccount();
        insert vAccount;
        Opportunity vOpportunity = getOpportunity(vAccount, vContact);
        return vOpportunity;
    }
    
    /*********************************
Opty with provided Account
*********************************/
    public static Opportunity getOpportunity(Account vAccount){     
        Contact vContact = getContact(vAccount);
        system.debug('getContact @@ '+vContact);
        insert vContact;
        Opportunity vOpportunity = getOpportunity(vAccount, vContact);
        return vOpportunity;
    }
    
    /*********************************
Primary Opportunity creation Method
*********************************/
    public static Opportunity getOpportunity(Account vAccount, Contact vContact){
        setTriggerSwitch('Opportunity', false);
        Opportunity vOpportunity = new Opportunity();
        vOpportunity.Name ='New mAWS Deal';
        vOpportunity.AccountId = vAccount.Id;
        vOpportunity.StageName = '1 Discovery';
        vOpportunity.Amount = 3000;
        vOpportunity.CloseDate = System.today()+30;
        vOpportunity.Type = 'New Customer';
        vOpportunity.Lead_Email_Hidden__c = vContact.Email;
        vOpportunity.Alliance_Partner_Name__c='Amazon';
        vOpportunity.Alliance_Source_Type__c='Alliance Initiated Deal';
        vOpportunity.Alliance_Source_Type_SW__c = 'Alliance Initiated Deal';
        vOpportunity.Initial_Contacts_Name__c = vContact.Id;
        vOpportunity.Deal_Registration_Type__c='Rubrik Sourced';
        vOpportunity.Champion__c = 'Champion';
        vOpportunity.Metric__c = 'Metric';
        vOpportunity.Economic_Buyer__c = 'Economic_Buyer';
        vOpportunity.Decision_Criteria__c = 'Decision_Criteria';
        vOpportunity.Decision_Process__c = 'Decision_Process';
        vOpportunity.Why_Rubrik__c = 'Why_Rubrik';
        vOpportunity.Why_do_anything__c = 'Why_do_anything';
        vOpportunity.Why_now__c = 'Why_now';
        vOpportunity.Partner_Representative__c = 'Partner_Representative';
        vOpportunity.Primary_Competitor__c = 'Avamar';
        vOpportunity.Alliance_HW_Partner__c = 'Cisco';
        vOpportunity.Alliance_Source_Type_HW__c = 'Why_do_anything';
        vOpportunity.Customer_AWS_Account_Number__c = 'Customer_AWS_Account_Number';
        vOpportunity.Customer_AWS_Account_Region__c = 'US East (N. Virginia)';
        vOpportunity.Lost_To_Won_Against__c = 'Arcserve';
        vOpportunity.Key_Feature_Needs__c = 'Other';
        vOpportunity.Other_Key_Feature_Need__c = 'Other_Key_Feature_Need';
        vOpportunity.Cloud_Type__c = 'Google';
        system.debug('vOpportunity '+vOpportunity);
        return vOpportunity;
    }
    
    
    /*********************************
Trigger Switch - Custom Setting that enables or disable Triggers
*********************************/
    public static void setTriggerSwitch(String vobject, boolean value){
        TriggerControl__c se =   TriggerControl__c.getValues(vobject);
        if(se == null){
            TriggerControl__c setting = new TriggerControl__c();
            setting.Name = vobject;
            setting.DisableTrigger__c = value;
            insert setting;
        }
        
    }
    
    
    
    /*********************************
Fully Populated Contact
*********************************/
    public static Contact getContact(){
        Account vAccount = getAccount();
        insert vAccount;        
        Contact vContact = getContact(vAccount);
        return vContact;
    }
    
    /*********************************
Primary Contact 
*********************************/
    public static Contact getContact(Account vAccount){
        setTriggerSwitch('Contact', false);
        Contact vContact = new Contact();
        vContact.LeadSource ='Email';
        vContact.LastName = 'Testlast';
        vContact.AccountId =vAccount.Id;
        String uniqueName = getUniqueName();        
        vContact.Email= uniqueName+'@test.com.sandbox';
        vContact.FirstName='firstTest'+vAccount.Id;     
        return vContact;
    }
    
    /*********************************
Create Account
*********************************/
    public static Account getAccount(){
        setTriggerSwitch('Account', false);
        Schema.DescribeSObjectResult cfrSchema = Schema.SObjectType.Account; 
        Map<String,Schema.RecordTypeInfo> AccountRecordTypeInfo = cfrSchema.getRecordTypeInfosByName();
        
        Account vAccount = new Account();
        vAccount.Name = 'Test Account';
        vAccount.recordTypeId = AccountRecordTypeInfo.get('Customer/Prospect').getRecordTypeId();
        
        return vAccount;        
    }
    
    /*********************************
Create Case
*********************************/
    public static Case getCase(Account vAccount, Contact vContact){
        Case vCase = new Case();
        vCase.Subject = getUniqueName();
        vCase.ContactId = vContact.Id;
        vCase.Jira_Reference_urls__c = 'test';
        vCase.Last_Case_Status__c = 'Customer requested close';
        vCase.Priority ='P2 - High';
        vCase.Status='New';
        vCase.Software_Version__c='4.0.1-GA';
        vCase.Type = 'Software';
        vCase.Product_Area__c='Hardware';
        vCase.Problem_Type__c ='Add Node';
        vCase.Description='Some description';
        
        vCase.Account=vAccount;
        
        return vCase;       
    }
    /*********************************
Create User
*********************************/
    public static User getUser(){
        UserRole vUserRole = new UserRole(DeveloperName = 'RubrikDeveloper1', Name = 'My Role');
        insert vUserRole;
                
        String uniqueName = getUniqueName();
        
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'last',
            Email = uniqueName +'@rubrik.com',
            Username = uniqueName +'@rubrik.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = uniqueName.substring(0,5),
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            UserRoleId = vUserRole.Id,
            Start_Date__c=System.Today().adddays(-30)
            
        );
        return u;
    }

    /*********************************
      Create Quote
    *********************************/
    public static List<SBQQ__Quote__c> getQuotes(set<Id> setOpportunityIds, Integer numOfRecords) {
        List<SBQQ__Quote__c> listQuote = new List<SBQQ__Quote__c>();

        for (Id opportunityId : setOpportunityIds) {
            for (Integer i = 0; i < numOfRecords; i++) {
                listQuote.add(
                    new SBQQ__Quote__c (
                        SBQQ__Opportunity2__c = opportunityId,
                        SBQQ__StartDate__c = Date.Today(),
                        Task_Products__c='RBK-DISK-RETENTION',
                        SBQQ__SubscriptionTerm__c = 36
                    )
                );
            }
        }

        return listQuote;
    }

    /*********************************
     Create User
    *********************************/
    public static List<User> getUsers(String strName, Set<Id> setProfileIds, Integer numOfRecords){
        List<User> listUser = new List<User>();

        for (Id profileId : setProfileIds) {
            Integer count = 0;
            for (Integer i = 0; i < numOfRecords; i++) {
                listUser.add(
                    new User (
                        Firstname = strName + count + '_' + i,
                        LastName = 'user',
                        ProfileId = profileId,
                        Username = strName + count + '_' + i + '@test.com',
                        Email = 'user@test.com.sandbox',
                        Alias = count + '_' + i,
                        TimeZoneSidKey = 'America/Los_Angeles',
                        LocaleSidKey = 'en_US',
                        EmailEncodingKey = 'UTF-8',
                        LanguageLocaleKey = 'en_US'
                    )
                );
            }
            count++;
        }
        return listUser;
    }

    /*********************************
     Create Group
    *********************************/
    public static List<Group> getGroups(String strName, Integer numOfRecords){
        List<Group> listGroup = new List<Group>();

        for (Integer i = 0; i < numOfRecords; i++) {
                listGroup.add(
                    new Group (
                        Name = strName + i
                    )
                );
        }
        return listGroup;
    }

    /*********************************
     Create Group Members
    *********************************/
    public static List<GroupMember> getGroupMembers(Id groupId, Set<Id> setUsers){
        List<GroupMember> listGroupMember = new List<GroupMember>();

        for (Id userId : setUsers) {
            listGroupMember.add(
                new GroupMember (
                    GroupId = groupId,
                    UserOrGroupId = userId
                )
            );
        }
        return listGroupMember;
    }

    /*********************************
     Create Approver
    *********************************/
    public static List<sbaa__Approver__c> getApprovers(Set<Id> setUserId, Set<Id> setGroupId){
        List<sbaa__Approver__c> listApprover = new List<sbaa__Approver__c>();
        Integer count = 1;

        for (Id userId : setUserId) {
            listApprover.add(
                new sbaa__Approver__c (
                    Name = 'Approver' + count,
                    sbaa__User__c = userId
                )
            );
            count++;
        }

        for (Id groupId : setGroupId) {
            listApprover.add(
                new sbaa__Approver__c (
                    Name = 'Approver' + count,
                    sbaa__GroupId__c = groupId
                )
            );
            count++;
        }

        return listApprover;
    }

    /*********************************
     Create Products
    *********************************/
    public static List<Product2> getProducts(String strName, Integer numOfRecords) {
        List<Product2> listProducts = new List<Product2>();

        for (Integer i = 0; i < numOfRecords; i++) {
                listProducts.add(
                    new Product2 (
                        Name = strName + i,
                        ProductCode = (strName + i).replace(' ', '').toUpperCase(),
                        isActive = True
                    )
                );
        }
        return listProducts;
    }

    /*********************************
     Create PriceBook
    *********************************/
    public static List<Pricebook2> getPricebook(String strName, Integer numOfRecords) {
        List<Pricebook2> listPricebook = new list<Pricebook2>();

        for (Integer i = 0; i < numOfRecords; i++) {
            listPricebook.add (
                new Pricebook2 (
                    Name = strName + i,
                    IsActive = True
                )
            );
        }
        return listPricebook;
    }

    /*********************************
     Create PriceBookEntry
    *********************************/
    public static List<PriceBookEntry> getPriceBookEntry(List<Id> listProductIds, List<Id> listPricebookIds) {
        List<PricebookEntry> listPriceBookEntry = new List<PricebookEntry>();

        for (Id productId : listProductIds) {
            for (Id pricebookId : listPricebookIds) {
                listPriceBookEntry.add (
                    new PricebookEntry (
                        Product2Id = productId,
                        Pricebook2Id = pricebookId,
                        UnitPrice = 100,
                        IsActive = True
                    )
                );
            }
        }
        return listPriceBookEntry;
    }

    /*********************************
     Create Quote Line
    *********************************/
    public static List<SBQQ__QuoteLine__c> getQuoteLines (Map<Id, List<Id>> mapQuoteIdWithProductIds) {
        List<SBQQ__QuoteLine__c> listQuoteLine = new List<SBQQ__QuoteLine__c>();

        for (Id quoteId : mapQuoteIdWithProductIds.keySet()) {
            Integer count = 1;
            for (Id productId : mapQuoteIdWithProductIds.get(quoteId)) {
                listQuoteLine.add(
                    new SBQQ__QuoteLine__c (
                        SBQQ__Quote__c = quoteId,
                        SBQQ__Product__c = productId,
                        SBQQ__Quantity__c = 1,
                        SBQQ__Number__c = count
                    )
                );
                count++;
            }
        }

        return listQuoteLine;
    }
    public static List<WorkflowTriggerBypass__c> setWorkflowTriggerBypassCS(boolean isTrue) {
        List<WorkflowTriggerBypass__c> wtList = new List<WorkflowTriggerBypass__c>();
        wtList.add(new WorkflowTriggerBypass__c(name='leadReassignOnBusinessUnitChange',ByPassTrigger__c=isTrue));
        wtList.add(new WorkflowTriggerBypass__c(name='cnsFirstAttemptUpdateLeadStatus',ByPassTrigger__c=isTrue));
        wtList.add(new WorkflowTriggerBypass__c(name='CreateSDRLedMeetingTask',ByPassTrigger__c=isTrue));
        wtList.add(new WorkflowTriggerBypass__c(name='updateLastOwnershipUpdateDate',ByPassTrigger__c=isTrue));
        wtList.add(new WorkflowTriggerBypass__c(name='updateOpportunitySource',ByPassTrigger__c=isTrue));
        wtList.add(new WorkflowTriggerBypass__c(name='salesOperationsAssignAccountSIC',ByPassTrigger__c=isTrue));
        wtList.add(new WorkflowTriggerBypass__c(name='salesOperationsSetEUResident',ByPassTrigger__c=isTrue));
        insert wtList;
        return wtList;
    }
     //Method to create Polaris Mapping Records
    public static Polaris_SKU_Mapping_V2__c  createPolarisSKUMappingRecord (Product2 oldProduct, Product2 newProduct) {
        System.debug('old Product = '+oldProduct+''+'New Porduct = '+newProduct);
        Polaris_SKU_Mapping_V2__c  polarisSKUMappingObj = new Polaris_SKU_Mapping_V2__c();
        polarisSKUMappingObj.Old_Product__c = oldProduct.Id;
        System.debug('Old Product SKU = '+polarisSKUMappingObj.Old_Product__c);
        polarisSKUMappingObj.New_Product__c = newProduct.Id;
        System.debug('New Product SKU = '+polarisSKUMappingObj.New_Product__c);
        polarisSKUMappingObj.Support_Tier__c = 'S2';
        return polarisSKUMappingObj;
    }
}