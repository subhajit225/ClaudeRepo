/******************************************************************************
* @description       : Test data utility class for Marketing-related objects
* @author            : Ankit Gupta
* @last modified on  : 11-21-2025
* @last modified by  : Ankit Gupta
* Modifications Log
* Ver   Date          Author           Modification
* 1.0   11-21-2025    Ankit Gupta      Initial Version
******************************************************************************/
public class MarketingTestDataUtility {

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
    * @description Creates OpportunitySplitMapping__c records
    * @param count Number of records to create
    * @param additionalFields Map of additional field values to set
    * @return List<OpportunitySplitMapping__c> List of created records (not inserted)
    */
    public static List<OpportunitySplitMapping__c> createOpportunitySplitMappings(
        Integer count,
        String fieldName,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();
        commonFields.put('Field__c', fieldName);

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<OpportunitySplitMapping__c>) TestDataFactoryDefaults.generateSObjects(count, 'OpportunitySplitMapping__c', commonFields, null);
    }

    /**
    * @description Creates OpportunityContactRole records
    * @param count Number of records to create
    * @param opportunityId Opportunity Id
    * @param contactId Contact Id
    * @param role Role (e.g., 'Decision Maker', 'Influencer', 'Economic Buyer')
    * @param additionalFields Map of additional field values to set
    * @return List<OpportunityContactRole> List of created records (not inserted)
    */
    public static List<OpportunityContactRole> createOpportunityContactRoles(
        Integer count,
        String opportunityId,
        String contactId,
        String role,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();

        commonFields.put('OpportunityId', opportunityId);
        commonFields.put('ContactId', contactId);
        if (String.isNotBlank(role)) {
            commonFields.put('Role', role);
        }

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<OpportunityContactRole>) TestDataFactoryDefaults.generateSObjects(count, 'OpportunityContactRole', commonFields, null);
    }

    /**
    * @description Creates After_Action_Review__c records
    * @param count Number of records to create
    * @param opportunityId Opportunity Id
    * @param additionalFields Map of additional field values to set
    * @return List<After_Action_Review__c> List of created records (not inserted)
    */
    public static List<After_Action_Review__c> createAfterActionReviews(
        Integer count,
        String opportunityId,
        Date closedDate,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();

        if (String.isNotBlank(opportunityId)) {
            commonFields.put('Opportunity__c', opportunityId);
            commonFields.put('Opportunity_ClosedDate__c', closedDate);
        }

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<After_Action_Review__c>) TestDataFactoryDefaults.generateSObjects(count, 'after_action_review__c', commonFields, null);
    }

    /**
    * @description Creates Order records
    * @param count Number of records to create
    * @param accountId Account Id
    * @param contractId Contract Id (optional)
    * @param additionalFields Map of additional field values to set
    * @return List<Order> List of created records (not inserted)
    */
    public static List<Order> createOrders(
        Integer count,
        String accountId,
        String contractId,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();

        commonFields.put('AccountId', accountId);
        commonFields.put('ContractId', contractId);

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<Order>) TestDataFactoryDefaults.generateSObjects(count, 'Order', commonFields, null);
    }

    /**
    * @description Creates OpportunityLineItem records
    * @param count Number of records to create
    * @param opportunityId Opportunity Id
    * @param pricebookEntryId PricebookEntry Id
    * @param additionalFields Map of additional field values to set
    * @return List<OpportunityLineItem> List of created records (not inserted)
    */
    public static List<OpportunityLineItem> createOpportunityLineItems(
        Integer count,
        String opportunityId,
        String pricebookEntryId,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();

        commonFields.put('OpportunityId', opportunityId);
        commonFields.put('PricebookEntryId', pricebookEntryId);

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<OpportunityLineItem>) TestDataFactoryDefaults.generateSObjects(count, 'OpportunityLineItem', commonFields, null);
    }


    /**
    * @description Creates Pricebook2 records
    * @param count Number of records to create
    * @param additionalFields Map of additional field values to set
    * @return List<Pricebook2> List of created records (not inserted)
    */
    public static List<Pricebook2> createPricebooks(
        Integer count,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<Pricebook2>) TestDataFactoryDefaults.generateSObjects(count, 'Pricebook2', commonFields, null);
    }


    /**
    * @description Creates SBQQ__Quote__c records
    * @param count Number of records to create
    * @param opportunityId Opportunity Id
    * @param accountId Account Id
    * @param additionalFields Map of additional field values to set
    * @return List<SBQQ__Quote__c> List of created records (not inserted)
    */
    public static List<SBQQ__Quote__c> createSBQQQuotes(
        Integer count,
        String opportunityId,
        String accountId,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();
        commonFields.put('SBQQ__Opportunity2__c', opportunityId);
        commonFields.put('SBQQ__Account__c', accountId);

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<SBQQ__Quote__c>) TestDataFactoryDefaults.generateSObjects(count, 'SBQQ__Quote__c', commonFields, null);
    }


    /**
    * @description Creates ServiceContract records
    * @param count Number of records to create
    * @param oppId Opportunity Id
    * @param orderId Order Id
    * @param additionalFields Map of additional field values to set
    * @return List<ServiceContract> List of created records (not inserted)
    */
    public static List<ServiceContract> createServiceContracts(
        Integer count,
        String oppId,
        String orderId,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();

        commonFields.put('SBQQSC__Opportunity__c', oppId);
        commonFields.put('SBQQSC__Order__c', orderId);

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<ServiceContract>) TestDataFactoryDefaults.generateSObjects(count, 'ServiceContract', commonFields, null);
    }


    /**
    * @description Creates Booking__c records
    * @param count Number of records to create
    * @param opportunityId Opportunity Id
    * @param accountId Account Id
    * @param status Status
    * @param recordTypeName RecordType Name
    * @param additionalFields Map of additional field values to set
    * @return List<Booking__c> List of created records (not inserted)
    */
    public static List<Booking__c> createBookings(
        Integer count,
        String opportunityId,
        String accountId,
        String status,
        String recordTypeName,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();
        Id recordTypeId=Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();

        commonFields.put('Opportunity__c', opportunityId);
        commonFields.put('Account_Name__c', accountId);
        commonFields.put('status__c', status);
        commonFields.put('RecordTypeId', recordTypeId);

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<Booking__c>) TestDataFactoryDefaults.generateSObjects(count, 'Booking__c', commonFields, null);
    }


    /**
    * @description Creates CCR__c records
    * @param count Number of records to create
    * @param opportunityId Opportunity Id
    * @param accountId Account Id
    * @param status Status
    * @param recordTypeName RecordType Name
    * @param additionalFields Map of additional field values to set
    * @return List<CCR__c> List of created records (not inserted)
    */
    public static List<CCR__c> createCCRs(
        Integer count,
        String opportunityId,
        String accountId,
        String recordTypeName,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();
        Id recordTypeId=Schema.SObjectType.CCR__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        commonFields.put('Opportunity__c', opportunityId);
        commonFields.put('Account_Name__c', accountId);
        commonFields.put('RecordTypeId', recordTypeId);

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<CCR__c>) TestDataFactoryDefaults.generateSObjects(count, 'CCR__c', commonFields, null);
    }


    /**
    * @description Creates SOX_Objects_Delete_Access__c records
    * @param count Number of records to create
    * @param userId User Id
    * @param isAllowToDelete to set the true/false value
    * @param additionalFields Map of additional field values to set
    * @return List<SOX_Objects_Delete_Access__c> List of created records (not inserted)
    */
    public static List<SOX_Objects_Delete_Access__c> createSOXObjectsDeleteAccess(
        Integer count,
        String userId,
        Boolean isAllowToDelete,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();
        commonFields.put('setupownerid', userId);
        commonFields.put('Allow_Opportunity_Delete__c', isAllowToDelete);

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<SOX_Objects_Delete_Access__c>) TestDataFactoryDefaults.generateSObjects(count, 'SOX_Objects_Delete_Access__c', commonFields, null);
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
    * @description Creates PricebookEntry records
    * @param count Number of records to create
    * @param pricebook2Id Pricebook2 Id
    * @param product2Id Product2 Id
    * @param additionalFields Map of additional field values to set
    * @return List<PricebookEntry> List of created records (not inserted)
    */
    public static List<PricebookEntry> createPricebookEntries(
        Integer count,
        String pricebook2Id,
        String product2Id,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();

        commonFields.put('Pricebook2Id', pricebook2Id);
        commonFields.put('Product2Id', product2Id);


        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<PricebookEntry>) TestDataFactoryDefaults.generateSObjects(count, 'PricebookEntry', commonFields, null);
    }


    /**
    * @description Creates Product2 records
    * @param count Number of records to create
    * @param additionalFields Map of additional field values to set
    * @return List<Product2> List of created records (not inserted)
    */
    public static List<Product2> createProducts(
        Integer count,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();
        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }
        return (List<Product2>) TestDataFactoryDefaults.generateSObjects(count, 'Product2', commonFields, null);
    }


    /**
    * @description Creates ObjectTerritory2Association records
    * @param count Number of records to create
    * @param objectId Object Id (Account, Opportunity, etc.)
    * @param territory2Id Territory2 Id
    * @param additionalFields Map of additional field values to set
    * @return List<ObjectTerritory2Association> List of created records (not inserted)
    */
    public static List<ObjectTerritory2Association> createObjectTerritory2Associations(
        Integer count,
        String objectId,
        String territory2Id,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();

        commonFields.put('ObjectId', objectId);
        commonFields.put('Territory2Id', territory2Id);

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<ObjectTerritory2Association>) TestDataFactoryDefaults.generateSObjects(count, 'ObjectTerritory2Association', commonFields, null);
    }


    /**
    * @description Creates ContractLineItem records
    * @param count Number of records to create
    * @param serviceContractId ServiceContract Id
    * @param pricebookEntryId PricebookEntry Id
    * @param additionalFields Map of additional field values to set
    * @return List<ContractLineItem> List of created records (not inserted)
    */
    public static List<ContractLineItem> createContractLineItems(
        Integer count,
        String serviceContractId,
        String pricebookEntryId,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();

        commonFields.put('ServiceContractId', serviceContractId);
        commonFields.put('PricebookEntryId', pricebookEntryId);

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<ContractLineItem>) TestDataFactoryDefaults.generateSObjects(count, 'ContractLineItem', commonFields, null);
    }


    /**
    * @description Creates Asset records
    * @param count Number of records to create
    * @param accountId Account Id
    * @param productId Product2 Id
    * @param additionalFields Map of additional field values to set
    * @return List<Asset> List of created records (not inserted)
    */
    public static List<Asset> createAssets(
        Integer count,
        String accountId,
        String productId,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> commonFields = new Map<String, Object>();
        commonFields.put('AccountId', accountId);
        if (String.isNotBlank(productId)) {
            commonFields.put('Product2Id', productId);
        }

        // Add any additional fields
        if (additionalFields != null && !additionalFields.isEmpty()) {
            commonFields.putAll(additionalFields);
        }

        return (List<Asset>) TestDataFactoryDefaults.generateSObjects(count, 'Asset', commonFields, null);
    }
}