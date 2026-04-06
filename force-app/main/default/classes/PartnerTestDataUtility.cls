/******************************************************************************
* @description       : Test data utility class for Partner-related objects
* @author            : Ankit Gupta
* @last modified on  : 02-25-2026
* @last modified by  : Harshit Garg
* Modifications Log
* Ver   Date          Author           Modification
* 1.0   11-21-2025    Ankit Gupta      Initial Version
******************************************************************************/
public class PartnerTestDataUtility {

    /**
    * @description Creates Deal Registration records with flexible parameters for record type, status, and additional fields.
    * @param count Number of records to create.
    * @param recordTypeName Record type name (e.g., 'Reseller', 'OEM', 'Alliance', 'Service_Delivery_Partner', 'Internal', 'Engagement').
    * @param status Deal Registration Status (e.g., 'Submitted', 'Approved', 'Rejected', 'Pending Conversion', 'Escalated', 'Expired').
    * @param additionalFields Map of additional field values to set.
    * @return List<Deal_Registration__c> List of created Deal Registration records (not inserted).
    */
    public static List<Deal_Registration__c> createDealRegistrations(
        Integer count,
        String recordTypeName,
        String status,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();

        Id recordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get(recordTypeName)?.getRecordTypeId();
        commonFields.put('RecordTypeId', recordTypeId);
        commonFields.put('Deal_Registration_Status__c', status);

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<Deal_Registration__c>) TestDataFactoryDefaults.generateSObjects(count, 'deal_registration__c', commonFields, null);
    }

    /**
    * @description Creates Account records with flexible parameters for account type, record type, and additional fields.
    * @param count Number of records to create.
    * @param accountType Account Type (e.g., 'Partner', 'Customer', 'Prospect', 'Reseller', 'MSP', 'OEM').
    * @param recordTypeName Record type name (e.g., 'Partner/Distributor', 'Customer/Prospect', 'Standard').
    * @param additionalFields Map of additional field values to set.
    * @return List<Account> List of created Account records (not inserted).
    */
    public static List<Account> createAccounts(
        Integer count,
        String accountType,
        String recordTypeName,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();

        // Set Record Type if provided
        if (String.isNotBlank(recordTypeName)) {
            Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(recordTypeName)?.getRecordTypeId();
            if (recordTypeId != null) {
                commonFields.put('RecordTypeId', recordTypeId);
            }
        }

        // Set Account Type if provided
        if (String.isNotBlank(accountType)) {
            commonFields.put('Type', accountType);
        }

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<Account>) TestDataFactoryDefaults.generateSObjects(count, 'account', commonFields, null);
    }


    /**
    * @description Creates Opportunity records with flexible parameters for stage, account, and additional fields.
    * @param count Number of records to create.
    * @param stageName Opportunity Stage (e.g., '1 Discovery', '2 Consensus', '5 Negotiate & Close', '7 Closed').
    * @param accountId Related Account Id.
    * @param additionalFields Map of additional field values to set.
    * @return List<Opportunity> List of created Opportunity records (not inserted).
    */
    public static List<Opportunity> createOpportunities(
        Integer count,
        String stageName,
        String accountId,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();
        commonFields.put('AccountId', accountId);
        if (String.isNotBlank(stageName)) {
            commonFields.put('StageName', stageName);
        }
        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<Opportunity>) TestDataFactoryDefaults.generateSObjects(count, 'opportunity', commonFields, null);
    }

    /**
    * @description Creates PatchManager__c records with flexible parameters for record type, owner user, and additional fields.
    * @param count Number of records to create.
    * @param recordTypeName Record type name (e.g., 'Geographic', 'Domain').
    * @param userId User Id to populate CDM__c, AccountExecutive__c, and SDR__c.
    * @param additionalFields Map of additional field values to set.
    * @return List<PatchManager__c> List of created PatchManager records (not inserted).
    */
    public static List<PatchManager__c> createPatchManagers(
        Integer count,
        String recordTypeName,
        Id userId,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();

        Id recordTypeId = Schema.SObjectType.PatchManager__c.getRecordTypeInfosByName().get(recordTypeName)?.getRecordTypeId();
        commonFields.put('RecordTypeId', recordTypeId);
        commonFields.put('CDM__c', userId);
        commonFields.put('AccountExecutive__c', userId);
        commonFields.put('SDR__c', userId);

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<patchmanager__c>) TestDataFactoryDefaults.generateSObjects(count, 'patchmanager__c', commonFields, null);
    }

    /**
    * @description Creates Contact records with optional AccountId and additional fields.
    * @param count Number of records to create.
    * @param accountId Account Id to associate the Contact with.
    * @param additionalFields Map of additional field values to set.
    * @return List<Contact> List of created Contact records (not inserted).
    */
    public static List<Contact> createContacts(
        Integer count,
        String accountId,
        Map<String, Object> additionalFields
    ) {

        Map<String, Object> commonFields = new Map<String, Object>();
        commonFields.put('AccountId', accountId);
        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<Contact>) TestDataFactoryDefaults.generateSObjects(count, 'contact', commonFields, null);
    }


    /**
    * @description Creates Lead records with flexible parameters for status and additional fields.
    * @param count Number of records to create.
    * @param status Lead Status (e.g., 'RAW', 'Open', 'Qualified').
    * @param additionalFields Map of additional field values to set.
    * @return List<Lead> List of created Lead records (not inserted).
    */
    public static List<Lead> createLeads(
        Integer count,
        String status,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();

        // Set Status if provided
        if (String.isNotBlank(status)) {
            commonFields.put('Status', status);
        }

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<Lead>) TestDataFactoryDefaults.generateSObjects(count, 'lead', commonFields, null);
    }

    /**
    * @description Creates User records with flexible parameters for profile and additional fields.
    * @param count Number of users to create.
    * @param profileName Profile name to assign. Defaults to System Administrator if null.
    * @param additionalFields Map of additional field values to set.
    * @return List<User> List of created User records (not inserted).
    */

    public static List<User> createUsers(
        Integer count,
        String profileName,
        Map<String, Object> additionalFields
    ) {

        Profile profileToUse;
        if (profileName != null) {
            profileToUse = [SELECT Id, Name FROM Profile WHERE Name = :profileName LIMIT 1];
        } else {
            profileToUse = [ SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1 ];
        }

        Map<String, Object> commonFields = new Map<String, Object>();
        List<User> userList = new List<User>();

        for (Integer i = 0; i < count; i++) {
            commonFields.put('FirstName', 'Test');
            commonFields.put('LastName', 'User ' + i);
            commonFields.put('Email', 'testuser' + i + '@example.com.sandbox');
            commonFields.put('Username', 'testuser' + i + '@example.com.' + System.currentTimeMillis());
            commonFields.put('Alias', 'tusr' + i);
            commonFields.put('ProfileId', profileToUse.Id);
            commonFields.put('IsActive', true);
            // Add any additional fields
            if (additionalFields != null && !additionalFields.isEmpty()) {
                commonFields.putAll(additionalFields);
            }

            List<SObject> generated = TestDataFactoryDefaults.generateSObjects(1, 'user', commonFields, null);

            userList.add((User)generated[0]);
        }

        return userList;
    }


    /**
    * @description Creates Partner_Relation__c records with flexible parameters for involvement type, partner account, linked opportunity, and additional fields.
    * @param count Number of records to create.
    * @param involvementType Partner involvement type.
    * @param partnerAccountId Partner Account Id.
    * @param oppId Opportunity Id.
    * @param additionalFields Map of additional field values to set.
    * @return List<Partner_Relation__c> List of created Partner Relation records (not inserted).
    */
    public static List<Partner_Relation__c> createPartnerRelations(
        Integer count,
        String involvementType,
        String partnerAccountId,
        String oppId,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();

        commonFields.put('Involvement_Type__c', involvementType);
        commonFields.put('Partner_Account__c', partnerAccountId);
        commonFields.put('Opportunity__c', oppId);

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<Partner_Relation__c>) TestDataFactoryDefaults.generateSObjects(count, 'partner_relation__c', commonFields, null);
    }


    /**
    * @description Creates DR_PS_Escalation__c records with flexible parameters based on a Deal Registration.
    * @param count Number of records to create.
    * @param status Escalation Status.
    * @param escalationType Type of escalation.
    * @param dealType Deal initiation type.
    * @param deal Related Deal_Registration__c record for pre-populating fields.
    * @param additionalFields Map of additional field values to set.
    * @return List<DR_PS_Escalation__c> List of created Escalation records (not inserted).
    */
    public static List<DR_PS_Escalation__c> createDRPSEscalations(
        Integer count,
        String status,
        String escalationType,
        String dealType,
        Deal_Registration__c deal,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();

        commonFields.put('Status__c', status);
        commonFields.put('Escalation_Type__c', escalationType);
        commonFields.put('Escalation_Reason__c', 'test');
        commonFields.put('Deal_Initiated_Type__c', dealType);
        commonFields.put('Partner_Lookup__c', deal?.Partner_Lookup__c);
        commonFields.put('Existing_Opportunity__c', deal?.Opportunity__c);
        commonFields.put('End_User_Account__c', deal?.Company_Name__c);
        commonFields.put('Opportunity_Stage__c', deal?.Opportunity_Stage__c);
        commonFields.put('Opportunity_ACV__c', deal?.PID_Meeting_Task__c);
        commonFields.put('Deal_Reg_AE__c', deal?.OwnerId);
        commonFields.put('RVP__c', deal?.Theatre_VP__c);

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<DR_PS_Escalation__c>) TestDataFactoryDefaults.generateSObjects(count, 'dr_ps_escalation__c', commonFields, null);
    }

    /**
    * @description Creates Partner_Page_Configuration__c records with flexible parameters for image type and navigation.
    * @param count Number of records to create.
    * @param imageType Image Type (e.g., 'Menu', 'Menu Item', 'Welcome Page', 'Pop Up Card').
    * @param navigateURL URL to navigate to.
    * @param additionalFields Map of additional field values to set.
    * @return List<Partner_Page_Configuration__c> List of created records (not inserted).
    */
    public static List<Partner_Page_Configuration__c> createPartnerPageConfigurations(
        Integer count,
        String imageType,
        String navigateURL,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();

        commonFields.put('Image_Type__c', imageType);
        commonFields.put('Navigate_Url__c', navigateURL);

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<Partner_Page_Configuration__c>) TestDataFactoryDefaults.generateSObjects(count, 'partner_page_configuration__c', commonFields, null);
    }

    /**
    * @description Creates Incentives__c records with flexible parameters for record type, status, account, and additional fields.
    * @param count Number of records to create.
    * @param recordTypeName Record Type name for Incentives.
    * @param status Incentive Status (e.g., 'Approved', 'Submitted', 'Rejected').
    * @param accountId Account Id associated with the incentive.
    * @param additionalFields Map of additional field values to set.
    * @return List<Incentives__c> List of created Incentive records (not inserted).
    */
    public static List<Incentives__c> createIncentives(
        Integer count,
        String recordTypeName,
        String status,
        String accountId,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();

        Id recordTypeId = Schema.SObjectType.Incentives__c.getRecordTypeInfosByName().get(recordTypeName)?.getRecordTypeId();
        commonFields.put('RecordTypeId', recordTypeId);
        commonFields.put('Status__c', status);
        commonFields.put('Start__c', Date.today());
        commonFields.put('Account_Name__c', accountId);

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<Incentives__c>) TestDataFactoryDefaults.generateSObjects(count, 'incentives__c', commonFields, null);
    }

    /**
    * @description Creates CountryWithCode__c records.
    * @param count Number of records to create.
    * @param code Country code.
    * @param name Country name.
    * @param additionalFields Map of additional field values to set.
    * @return List<CountryWithCode__c> List of created records (not inserted).
    */
    public static List<CountryWithCode__c> createCountryWithCode(
        Integer count,
        String code,
        String name,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();

        commonFields.put('Code__c', code);
        commonFields.put('Name', name);

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<CountryWithCode__c>) TestDataFactoryDefaults.generateSObjects(count, 'countrywithcode__c', commonFields, null);
    }

    /**
    * @description Creates CodeWithCountry__c records.
    * @param count Number of records to create.
    * @param name Code Name.
    * @param country Country value.
    * @param additionalFields Map of additional field values to set.
    * @return List<CodeWithCountry__c> List of created records (not inserted).
    */
    public static List<CodeWithCountry__c> createCodeWithCountry(
        Integer count,
        String name,
        String country,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();

        commonFields.put('Name', name);
        commonFields.put('Country__c', country);

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<CodeWithCountry__c>) TestDataFactoryDefaults.generateSObjects(count, 'CodeWithCountry__c', commonFields, null);
    }

    /**
    * @description Creates statecodename__c records.
    * @param count Number of records to create.
    * @param name Code Name.
    * @param stateName State Name.
    * @param additionalFields Map of additional field values to set.
    * @return List<statecodename__c> List of created records (not inserted).
    */
    public static List<statecodename__c> createStateCodeWithName(
        Integer count,
        String name,
        String stateName,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();

        commonFields.put('Name', name);
        commonFields.put('State_Name__c', stateName);

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<statecodename__c>) TestDataFactoryDefaults.generateSObjects(count, 'statecodename__c', commonFields, null);
    }

    /**
    * @description Creates PartnerFundRequest records.
    * @param count Number of records to create.
    * @param status Status of the request.
    * @param accountId Channel Partner Account Id.
    * @param additionalFields Map of additional field values to set.
    * @return List<PartnerFundRequest> List of created records (not inserted).
    */
    public static List<PartnerFundRequest> createPartnerFundRequest(
        Integer count,
        String status,
        String accountId,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();

        commonFields.put('Status', status);
        commonFields.put('ChannelPartnerId', accountId);

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<PartnerFundRequest>) TestDataFactoryDefaults.generateSObjects(count, 'partnerfundrequest', commonFields, null);
    }

    /**
    * @description Creates PartnerFundRequest records.
    * @param count Number of records to create.
    * @param status Status of the claim.
    * @param pfRequestId Partner Fund request Id.
    * @param additionalFields Map of additional field values to set.
    * @return List<PartnerFundClaim> List of created records (not inserted).
    */
    public static List<PartnerFundClaim> createPartnerFundClaim(
        Integer count,
        String status,
        String pfRequestId,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();

        commonFields.put('Status', status);
        commonFields.put('RequestId', pfRequestId);

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<PartnerFundClaim>) TestDataFactoryDefaults.generateSObjects(count, 'partnerfundclaim', commonFields, null);
    }

    /**
    * @description Creates Territory2 records with flexible parameters for model, type, and additional fields.
    * @param count Number of records to create.
    * @param tModeId Territory2 Model Id.
    * @param terrTypeId Territory2 Type Id.
    * @param additionalFields Map of additional field values to set.
    * @return List<Territory2> List of created Territory2 records (not inserted).
    */
    public static List<Territory2> createTerritories(
        Integer count,
        String tModeId,
        String terrTypeId,
        Map<String, Object> additionalFields
    ) {
        List<Territory2> territory2rList = new List<Territory2>();
        Map<String, Object> commonFields = new Map<String, Object>();

        for (Integer i = 1; i <= count; i++) {
            commonFields.put('DeveloperName', 'CDM_' + i);
            commonFields.put('Adaptive_Territory_Id__c', '999999'+i);
            commonFields.put('Territory2ModelId', tModeId);
            commonFields.put('Territory2TypeId', terrTypeId);

            // Add any additional fields
            if (additionalFields != null && !additionalFields.isEmpty()) {
                commonFields.putAll(additionalFields);
            }

            List<SObject> generated = TestDataFactoryDefaults.generateSObjects( 1, 'territory2', commonFields, null);
            territory2rList.add((Territory2)generated[0]);
        }

        return territory2rList;
    }

    /**
    * @description Creates UserTerritory2Association records.
    * @param count Number of records to create.
    * @param roleInTerritory User role in the territory.
    * @param territory2Id Territory2 Id.
    * @param userId User Id.
    * @param additionalFields Map of additional field values to set.
    * @return List<UserTerritory2Association> List of created User Territory Association records (not inserted).
    */
    public static List<UserTerritory2Association> createUserTerritoryAssociations(
        Integer count,
        String roleInTerritory,
        String territory2Id,
        String userId,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();

        commonFields.put('RoleInTerritory2', roleInTerritory);
        commonFields.put('Territory2Id', territory2Id);
        commonFields.put('UserId', userId);

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<UserTerritory2Association>) TestDataFactoryDefaults.generateSObjects(count, 'userterritory2association', commonFields, null);
    }

    /**
    * @description Creates DealPartnerEmail__c records.
    * @param count Number of records to create.
    * @param name Name of the record.
    * @param type Email Type value.
    * @param additionalFields Map of additional field values to set.
    * @return List<DealPartnerEmail__c> List of created records (not inserted).
    */
    public static List<DealPartnerEmail__c> createDealPartnerEmail(
        Integer count,
        String name,
        String type,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();

        commonFields.put('Name', name);
        commonFields.put('Email__c', 'a@a.com.sandbox');
        commonFields.put('Type__c', type);

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<DealPartnerEmail__c>) TestDataFactoryDefaults.generateSObjects(count, 'dealpartneremail__c', commonFields, null);
    }

    /**
    * @description Creates Partner_Onboarding_Request__c records.
    * @param count Number of records to create.
    * @param recordTypeName Record type name.
    * @param status Onboarding Status.
    * @param additionalFields Map of additional field values to set.
    * @return List<Partner_Onboarding_Request__c> List of created Partner Onboarding records (not inserted).
    */
    public static List<Partner_Onboarding_Request__c> createPartnerOnBoardingRequest(
        Integer count,
        String recordTypeName,
        String status,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();

        Id recordTypeId = Schema.SObjectType.Partner_Onboarding_Request__c.getRecordTypeInfosByName().get(recordTypeName)?.getRecordTypeId();
        commonFields.put('RecordTypeId', recordTypeId);
        commonFields.put('PartnerType__c', 'Reseller');
        commonFields.put('Email__c', 'a@a.com.sandbox');
        commonFields.put('Partner_Onboarding_Status__c', status);
        commonFields.put('Address_1__c', 'test address');
        commonFields.put('Address_2__c', 'test address2');

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<Partner_Onboarding_Request__c>) TestDataFactoryDefaults.generateSObjects(count, 'partner_onboarding_request__c', commonFields, null);
    }


    /**
    * @description Creates MIP_Contract__c records with flexible parameters.
    * @param count Number of records to create.
    * @param accountId Partner Account Id.
    * @param contactId Contact Id.
    * @param userId CDM User Id.
    * @param status Contract Status.
    * @param additionalFields Map of additional field values to set.
    * @return List<MIP_Contract__c> List of created MIP Contract records (not inserted).
    */
    public static List<MIP_Contract__c> createMIPContract(
        Integer count,
        String accountId,
        String contactId,
        String userId,
        String status,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();

        commonFields.put('Partner_Account__c', accountId);
        commonFields.put('Partner_Contact_of_Signature__c', contactId);
        commonFields.put('CDM__c', userId);
        commonFields.put('Status__c', status);

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<MIP_Contract__c>) TestDataFactoryDefaults.generateSObjects(count, 'mip_contract__c', commonFields, null);
    }

    /**
    * @description Creates MIP_Account_Contribution__c records.
    * @param count Number of records to create.
    * @param accountId Partner Account Id.
    * @param mipContractId MIP Contract Id.
    * @param additionalFields Map of additional field values to set.
    * @return List<MIP_Account_Contribution__c> List of created records (not inserted).
    */
    public static List<MIP_Account_Contribution__c> createMIPAccountContribution(
        Integer count,
        String accountId,
        String mipContractId,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();

        commonFields.put('Partner_Account__c', accountId);
        commonFields.put('MIP_Contract__c', mipContractId);

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<MIP_Account_Contribution__c>) TestDataFactoryDefaults.generateSObjects(count, 'mip_account_contribution__c', commonFields, null);
    }

    /**
    * @description Creates MIP_Element__c records.
    * @param count Number of records to create.
    * @param recordTypeName Record type name.
    * @param mipContractId MIP Contract Id.
    * @param type Element Type.
    * @param additionalFields Map of additional field values to set.
    * @return List<MIP_Element__c> List of created records (not inserted).
    */
    public static List<MIP_Element__c> createMIPElement(
        Integer count,
        String recordTypeName,
        String mipContractId,
        String type,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();

        Id recordTypeId = Schema.SObjectType.MIP_Element__c.getRecordTypeInfosByName().get(recordTypeName)?.getRecordTypeId();
        commonFields.put('RecordTypeId', recordTypeId);
        commonFields.put('Element_Type__c', type);
        commonFields.put('MIP_Contract__c', mipContractId);

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<MIP_Element__c>) TestDataFactoryDefaults.generateSObjects(count, 'mip_element__c', commonFields, null);
    }

    /**
    * @description Creates PartnerMarketingBudget records.
    * @param count Number of records to create.
    * @param accountId Channel Partner Id.
    * @param additionalFields Map of additional field values to set.
    * @return List<PartnerMarketingBudget> List of created records (not inserted).
    */
    public static List<PartnerMarketingBudget> createPartnerMarketingBudget(
        Integer count,
        String accountId,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();

        commonFields.put('ChannelPartnerId', accountId);

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<PartnerMarketingBudget>) TestDataFactoryDefaults.generateSObjects(count, 'partnermarketingbudget', commonFields, null);
    }

    /**
    * @description Creates PartnerFundAllocation records.
    * @param count Number of records to create.
    * @param accountId Channel Partner Id.
    * @param budgetId Related Budget Id.
    * @param additionalFields Map of additional field values to set.
    * @return List<PartnerFundAllocation> List of created records (not inserted).
    */
    public static List<PartnerFundAllocation> createPartnerFundAllocation(
        Integer count,
        String accountId,
        String budgetId,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();

        commonFields.put('ChannelPartnerId', accountId);
        commonFields.put('BudgetId', budgetId);

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<PartnerFundAllocation>) TestDataFactoryDefaults.generateSObjects(count, 'partnerfundallocation', commonFields, null);
    }

	/**
    * @description Creates Partner_Registration_Request__c records.
    * @param count Number of records to create.
    * @param additionalFields Map of additional field values to set.
    * @return List<Partner_Registration_Request__c> List of created records (not inserted).
    */
    public static List<Partner_Registration_Request__c> createPartnerRegistrationRequest(
        Integer count,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();

        commonFields.put('Address__c', 'test address');
        commonFields.put('State__c', 'testState');
        commonFields.put('Country__c', 'United State');
        commonFields.put('State_Picklist__c', 'AZ');
        commonFields.put('Country_Picklist__c', 'United State');

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<Partner_Registration_Request__c>) TestDataFactoryDefaults.generateSObjects(count, 'partner_registration_request__c', commonFields, null);
    }

    /**
    * @description Creates WorkflowTriggerBypass__c records.
    * @param count Number of records to create.
    * @param name Name value.
    * @param isByPass Whether the trigger should be bypassed.
    * @param additionalFields Map of additional field values to set.
    * @return List<WorkflowTriggerBypass__c> List of created records (not inserted).
    */
    public static List<WorkflowTriggerBypass__c> createWorkflowTriggerBypass(
        Integer count,
        String name,
        Boolean isByPass,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();

        commonFields.put('Name', name);
        commonFields.put('ByPassTrigger__c', isByPass);

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<WorkflowTriggerBypass__c>) TestDataFactoryDefaults.generateSObjects(count, 'workflowtriggerbypass__c', commonFields, null);
    }

    /**
    * @description Creates Case records.
    * @param count Number of records to create.
    * @param recordTypeName Record type name.
    * @param accountId Account Id.
    * @param contactId Contact Id.
    * @param additionalFields Map of additional field values to set.
    * @return List<Case> List of created Case records (not inserted).
    */
    public static List<Case> createCases(
        Integer count,
        String recordTypeName,
        String accountId,
        String contactId,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();

        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(recordTypeName)?.getRecordTypeId();
        commonFields.put('RecordTypeId', recordTypeId);
        commonFields.put('Accountid', accountId);
        commonFields.put('ContactId', contactId);

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<Case>) TestDataFactoryDefaults.generateSObjects(count, 'case', commonFields, null);
    }

    /**
    * @description Creates ContentVersion records.
    * @param count Number of records to create.
    * @param pathOnClient Path of the file.
    * @param additionalFields Map of additional field values to set.
    * @return List<ContentVersion> List of created ContentVersion records (not inserted).
    */
    public static List<ContentVersion> createContentVersion(
        Integer count,
        String pathOnClient,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();
        commonFields.put('PathOnClient', pathOnClient);

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<ContentVersion>) TestDataFactoryDefaults.generateSObjects(count, 'contentversion', commonFields, null);
    }

    /**
    * @description Creates PermissionSetAssignment records.
    * @param count Number of records to create.
    * @param psName Permission Set Name.
    * @param userId Assignee User Id.
    * @param additionalFields Map of additional field values to set.
    * @return List<PermissionSetAssignment> List of created records (not inserted).
    */
    public static List<PermissionSetAssignment> createPermissionSetAssignment(
        Integer count,
        String psName,
        String userId,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();

        Id psId = [SELECT Id from PermissionSet WHERE Name =: psName].Id;
        commonFields.put('PermissionSetId', psId);
        commonFields.put('AssigneeId', userId);

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<PermissionSetAssignment>) TestDataFactoryDefaults.generateSObjects(count, 'permissionsetassignment', commonFields, null);
    }

    /**
    * @description Creates Campaign records.
    * @param count Number of records to create.
    * @param name Campaign Name.
    * @param additionalFields Map of additional field values to set.
    * @return List<Campaign> List of created campaign records (not inserted).
    */
    public static List<Campaign> createCampaign(
        Integer count,
        String name,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();
        commonFields.put('Name', name);

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<Campaign>) TestDataFactoryDefaults.generateSObjects(count, 'campaign', commonFields, null);
    }

    /**
    * @description Creates CampaignMember records.
    * @param count Number of records to create.
    * @param leadId Lead Id.
    * @param campId Campaign Id.
    * @param status Campaign Member Status.
    * @param additionalFields Map of additional field values to set.
    * @return List<CampaignMember> List of created campaign member records (not inserted).
    */
    public static List<CampaignMember> createCampaignMember(
        Integer count,
        String leadId,
        String campId,
        String status,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();

        commonFields.put('Leadid', leadId);
        commonFields.put('CampaignId', campId);
        commonFields.put('Status', status);

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<CampaignMember>) TestDataFactoryDefaults.generateSObjects(count, 'campaignmember', commonFields, null);
    }

    /**
    * @description Creates ContentDocumetLink records.
    * @param count Number of records to create.
    * @param linkedEntityId Linked Entity Id.
    * @param contentDocId Content Document Id.
    * @param additionalFields Map of additional field values to set.
    * @return List<ContentDocumentLink> List of created ContentDocumentLink records (not inserted).
    */
    public static List<ContentDocumentLink> createContentDocumentLinks(
        Integer count,
        String linkedEntityId,
        String contentDocId,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();
        commonFields.put('ContentDocumentId', contentDocId);
        commonFields.put('LinkedEntityId', linkedEntityId);

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<ContentDocumentLink>) TestDataFactoryDefaults.generateSObjects(count, 'ContentDocumentLink', commonFields, null);
    }

    /**
    * @description Creates DealregLeadMapping__c records.
    * @param count Number of records to create.
    * @param dealRegFieldAPIName Deal Registration Field API Name.
    * @param leadFieldAPIName Lead Field API Name.
    * @param additionalFields Map of additional field values to set.
    * @return List<DealregLeadMapping__c> List of created records (not inserted).
    */
    public static List<DealregLeadMapping__c> createDealRegLeadMapping(
        Integer count,
        String dealRegFieldAPIName,
        String leadFieldAPIName,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();

        commonFields.put('Name', dealRegFieldAPIName);
        commonFields.put('LeadFields__c', leadFieldAPIName);

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<DealregLeadMapping__c>) TestDataFactoryDefaults.generateSObjects(count, 'DealregLeadMapping__c', commonFields, null);
    }

}