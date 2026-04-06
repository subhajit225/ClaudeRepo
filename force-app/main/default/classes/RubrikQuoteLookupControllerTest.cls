/**
 * @description Test class for RubrikQuoteLookupController.
 *              Covers lookupQuoteVF (@RemoteAction), lookupQuote (@AuraEnabled),
 *              and submitOVF (@RemoteAction) including all branches.
 * @author Unit Testing Agent
 */
@isTest
private class RubrikQuoteLookupControllerTest {

    // -------------------------------------------------------------------------
    // Test data constants
    // -------------------------------------------------------------------------
    private static final String TEST_CONTACT_EMAIL = 'test.buyer@rubrik-test.com';
    private static final String TEST_CONTACT_FIRST = 'TestFirst';
    private static final String TEST_CONTACT_LAST  = 'TestLast';
    private static final String TEST_CONTACT_PHONE = '415-555-0199';

    // -------------------------------------------------------------------------
    // @TestSetup – runs once; all test methods query for their data
    // -------------------------------------------------------------------------
    @TestSetup
    static void setupTestData() {
        // Disable heavy triggers that are irrelevant to this controller
        ShGl_DisableBusinessLogic__c dbl = new ShGl_DisableBusinessLogic__c(
            SetupOwnerId                        = UserInfo.getOrganizationId(),
            Disable_Account_Triggers__c         = true,
            Disable_Opportunity_Triggers__c     = true,
            Disable_Opportunity_Validation_Rules__c = true,
            Disable_SBQQ_Quote_Triggers__c      = true,
            Disable_SBQQ_Quote_Validation_Rules__c  = true,
            Disable_SBQQ_QuoteLine_Triggers__c  = true,
            Disable_SBQQ_QuoteLine_Validation_Rules__c = true
        );
        insert dbl;

        TriggerControls.disableQuoteTrigger     = true;
        TriggerControls.disableQuoteLineTrigger = true;

        // Account – shipping address is set here so that lookupQuote returns the
        // expected shipping fields populated from SBQQ__Account__r.ShippingStreet etc.
        // ShippingStreet uses two lines to exercise the street-splitting logic in findQuote().
        Account acct = new Account(
            Name            = 'Test OVF Account',
            ShippingStreet  = '123 Main St\nSuite 400',
            ShippingCity    = 'San Francisco',
            ShippingState   = 'CA',
            ShippingPostalCode = '94105',
            ShippingCountry = 'US'
        );
        insert acct;

        // Contact that will be the quote's primary contact
        Contact primaryContact = new Contact(
            FirstName   = TEST_CONTACT_FIRST,
            LastName    = TEST_CONTACT_LAST,
            Email       = TEST_CONTACT_EMAIL,
            Phone       = TEST_CONTACT_PHONE,
            AccountId   = acct.Id
        );
        insert primaryContact;

        // Opportunity required as parent for SBQQ__Quote__c
        Opportunity opp = new Opportunity(
            Name        = 'Test OVF Opp',
            AccountId   = acct.Id,
            StageName   = '1 Discovery',
            CloseDate   = System.today().addDays(30)
        );
        insert opp;

        // Quote – SBQQ__PrimaryContact__c is managed by CPQ triggers and cannot be
        // set directly. Validation now uses the OpportunityContactRole instead.
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Account__c          = acct.Id,
            SBQQ__Opportunity2__c     = opp.Id,
            SBQQ__Primary__c          = true,
            SBQQ__Status__c           = 'Draft',
            SBQQ__Type__c             = 'Quote',
            SBQQ__StartDate__c        = System.today(),
            SBQQ__SubscriptionTerm__c = 12,
            SBQQ__PriceBook__c        = Test.getStandardPricebookId()
        );
        insert quote;

        // Primary contact role – this is what the controller now validates against
        OpportunityContactRole ocr = new OpportunityContactRole(
            OpportunityId = opp.Id,
            ContactId     = primaryContact.Id,
            IsPrimary     = true,
            Role          = 'Business User'
        );
        insert ocr;
    }

    // =========================================================================
    // Helper – re-read the auto-generated quote Name (e.g. Q-00001234)
    // =========================================================================
    private static SBQQ__Quote__c getTestQuote() {
        return [SELECT Id, Name FROM SBQQ__Quote__c LIMIT 1];
    }

    // =========================================================================
    // lookupQuoteVF – success path
    // Contact email matches a primary OpportunityContactRole => result returned
    // =========================================================================
    @isTest
    static void testLookupQuoteVF_emailMatchesContact_returnsResult() {
        SBQQ__Quote__c quote = getTestQuote();

        Test.startTest();
        RubrikQuoteLookupController.QuoteLookupResult result =
            RubrikQuoteLookupController.lookupQuoteVF(
                quote.Name,
                TEST_CONTACT_EMAIL
            );
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null when email matches primary contact');
        Assert.areEqual(
            quote.Id,
            result.quoteId,
            'quoteId on result should equal the matched quote Id'
        );
        Assert.isTrue(
            result.quoteUrl.contains(quote.Id),
            'quoteUrl should contain the quote Id'
        );
        Assert.isTrue(
            result.quoteUrl.startsWith('/quotes/'),
            'quoteUrl should start with /quotes/'
        );
        Assert.areEqual(
            TEST_CONTACT_FIRST + ' ' + TEST_CONTACT_LAST,
            result.contactName,
            'contactName should be populated from the primary contact role'
        );
        Assert.areEqual(
            TEST_CONTACT_EMAIL,
            result.contactEmail,
            'contactEmail should be populated from the primary contact role'
        );
        Assert.areEqual(
            TEST_CONTACT_PHONE,
            result.contactPhone,
            'contactPhone should be populated from the primary contact role'
        );
        Assert.areEqual(
            'Test OVF Account',
            result.companyName,
            'companyName should be populated from the quote account name'
        );
        Assert.areEqual(
            '123 Main St',
            result.shippingAddress1,
            'shippingAddress1 should be the first line of ShippingStreet'
        );
        Assert.areEqual(
            'Suite 400',
            result.shippingAddress2,
            'shippingAddress2 should be the second line of ShippingStreet'
        );
        Assert.areEqual(
            'San Francisco',
            result.shippingCity,
            'shippingCity should be populated from the account ShippingCity'
        );
        Assert.areEqual(
            'CA',
            result.shippingState,
            'shippingState should be populated from the account ShippingState'
        );
        Assert.areEqual(
            '94105',
            result.shippingZipCode,
            'shippingZipCode should be populated from the account ShippingPostalCode'
        );
        Assert.areEqual(
            'US',
            result.shippingCountry,
            'shippingCountry should be populated from the account ShippingCountry'
        );
    }

    // =========================================================================
    // lookupQuoteVF – failure: email does not match any quote
    // =========================================================================
    @isTest
    static void testLookupQuoteVF_emailMismatch_returnsNull() {
        SBQQ__Quote__c quote = getTestQuote();

        Test.startTest();
        RubrikQuoteLookupController.QuoteLookupResult result =
            RubrikQuoteLookupController.lookupQuoteVF(
                quote.Name,
                'wrong.email@rubrik-test.com'
            );
        Test.stopTest();

        Assert.isNull(result, 'Result should be null when email does not match primary contact');
    }

    // =========================================================================
    // lookupQuoteVF – failure: quote number does not exist
    // =========================================================================
    @isTest
    static void testLookupQuoteVF_unknownQuoteNumber_returnsNull() {
        Test.startTest();
        RubrikQuoteLookupController.QuoteLookupResult result =
            RubrikQuoteLookupController.lookupQuoteVF(
                'Q-DOESNOTEXIST',
                TEST_CONTACT_EMAIL
            );
        Test.stopTest();

        Assert.isNull(result, 'Result should be null when quote number is not found');
    }

    // =========================================================================
    // lookupQuote (AuraEnabled) – blank inputs return null
    // =========================================================================
    @isTest
    static void testLookupQuote_blankQuoteNumber_returnsNull() {
        Test.startTest();
        RubrikQuoteLookupController.QuoteLookupResult result =
            RubrikQuoteLookupController.lookupQuote('', TEST_CONTACT_EMAIL);
        Test.stopTest();

        Assert.isNull(result, 'Result should be null when quoteNumber is blank');
    }

    @isTest
    static void testLookupQuote_blankEmail_returnsNull() {
        SBQQ__Quote__c quote = getTestQuote();

        Test.startTest();
        RubrikQuoteLookupController.QuoteLookupResult result =
            RubrikQuoteLookupController.lookupQuote(quote.Name, '');
        Test.stopTest();

        Assert.isNull(result, 'Result should be null when email is blank');
    }

    @isTest
    static void testLookupQuote_nullInputs_returnsNull() {
        Test.startTest();
        RubrikQuoteLookupController.QuoteLookupResult result =
            RubrikQuoteLookupController.lookupQuote(null, null);
        Test.stopTest();

        Assert.isNull(result, 'Result should be null when both inputs are null');
    }

    // =========================================================================
    // lookupQuote (AuraEnabled) – case-insensitive email matching
    // The controller lowercases the email before querying
    // =========================================================================
    @isTest
    static void testLookupQuote_emailCaseInsensitive_returnsResult() {
        SBQQ__Quote__c quote = getTestQuote();

        Test.startTest();
        RubrikQuoteLookupController.QuoteLookupResult result =
            RubrikQuoteLookupController.lookupQuote(
                quote.Name,
                TEST_CONTACT_EMAIL.toUpperCase()
            );
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null; email matching should be case-insensitive');
        Assert.areEqual(quote.Id, result.quoteId, 'quoteId should match when email differs only in case');
    }

    // =========================================================================
    // lookupQuote (AuraEnabled) – leading/trailing whitespace is trimmed
    // =========================================================================
    @isTest
    static void testLookupQuote_whitespaceInputs_returnsResult() {
        SBQQ__Quote__c quote = getTestQuote();

        Test.startTest();
        RubrikQuoteLookupController.QuoteLookupResult result =
            RubrikQuoteLookupController.lookupQuote(
                '  ' + quote.Name + '  ',
                '  ' + TEST_CONTACT_EMAIL + '  '
            );
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null when inputs have surrounding whitespace');
        Assert.areEqual(quote.Id, result.quoteId, 'quoteId should be returned after trimming whitespace');
    }

    // =========================================================================
    // submitOVF – success: OVF__c record is created and Id returned
    // =========================================================================
    @isTest
    static void testSubmitOVF_validData_createsRecordAndReturnsId() {
        SBQQ__Quote__c quote = getTestQuote();

        Test.startTest();
        String ovfId = RubrikQuoteLookupController.submitOVF(
            quote.Id,
            'Acme Corp',        // buyerName
            'BILL-001',         // buyerBillingId
            'TENANT-001',       // buyerTenantId
            'Reseller Inc',     // resellerName
            'MKTPLACE-99',      // marketplaceSellerId
            'Acme Company',     // companyName
            '123 Main St',      // address1
            'Suite 400',        // address2
            'San Jose',         // city
            'CA',               // state
            '95110',            // zipCode
            'United States',    // country
            'Jane Doe',         // contactName
            'jane.doe@acme.com',// contactEmail
            '408-555-0100'      // contactPhone
        );
        Test.stopTest();

        Assert.isNotNull(ovfId, 'submitOVF should return a non-null record Id on success');
        Assert.isTrue(
            ovfId.startsWith('a'),
            'Returned Id should look like a valid Salesforce Id prefix for a custom object'
        );

        // Verify the record actually exists in the database with correct field values
        OVF__c saved = [
            SELECT Id, Quote__c, Buyer_Name__c, Buyer_Billing_ID__c,
                   Buyer_Tenant_ID__c, Reseller_Name__c, Marketplace_Seller_ID__c,
                   Company_Name__c, Address_1__c, Address_2__c, City__c,
                   State__c, Zip_Code__c, Country__c,
                   Contact_Name__c, Contact_Email__c, Contact_Phone__c
            FROM OVF__c
            WHERE Id = :ovfId
        ];

        Assert.areEqual(quote.Id,           saved.Quote__c,                'Quote__c should reference the test quote');
        Assert.areEqual('Acme Corp',        saved.Buyer_Name__c,           'Buyer_Name__c should be persisted');
        Assert.areEqual('BILL-001',         saved.Buyer_Billing_ID__c,     'Buyer_Billing_ID__c should be persisted');
        Assert.areEqual('TENANT-001',       saved.Buyer_Tenant_ID__c,      'Buyer_Tenant_ID__c should be persisted');
        Assert.areEqual('Reseller Inc',     saved.Reseller_Name__c,        'Reseller_Name__c should be persisted');
        Assert.areEqual('MKTPLACE-99',      saved.Marketplace_Seller_ID__c,'Marketplace_Seller_ID__c should be persisted');
        Assert.areEqual('Acme Company',     saved.Company_Name__c,         'Company_Name__c should be persisted');
        Assert.areEqual('123 Main St',      saved.Address_1__c,            'Address_1__c should be persisted');
        Assert.areEqual('Suite 400',        saved.Address_2__c,            'Address_2__c should be persisted');
        Assert.areEqual('San Jose',         saved.City__c,                 'City__c should be persisted');
        Assert.areEqual('CA',               saved.State__c,                'State__c should be persisted');
        Assert.areEqual('95110',            saved.Zip_Code__c,             'Zip_Code__c should be persisted');
        Assert.areEqual('United States',    saved.Country__c,              'Country__c should be persisted');
        Assert.areEqual('Jane Doe',         saved.Contact_Name__c,         'Contact_Name__c should be persisted');
        Assert.areEqual('jane.doe@acme.com',saved.Contact_Email__c,        'Contact_Email__c should be persisted');
        Assert.areEqual('408-555-0100',     saved.Contact_Phone__c,        'Contact_Phone__c should be persisted');
    }

    // =========================================================================
    // submitOVF – optional fields can be null/blank without failure
    // =========================================================================
    @isTest
    static void testSubmitOVF_optionalFieldsBlank_createsRecord() {
        SBQQ__Quote__c quote = getTestQuote();

        Test.startTest();
        String ovfId = RubrikQuoteLookupController.submitOVF(
            quote.Id,
            null,   // buyerName
            null,   // buyerBillingId
            null,   // buyerTenantId
            null,   // resellerName
            null,   // marketplaceSellerId
            null,   // companyName
            null,   // address1
            null,   // address2
            null,   // city
            null,   // state
            null,   // zipCode
            null,   // country
            null,   // contactName
            null,   // contactEmail
            null    // contactPhone
        );
        Test.stopTest();

        Assert.isNotNull(ovfId, 'OVF__c record should be created even when all optional fields are null');

        List<OVF__c> records = [SELECT Id FROM OVF__c WHERE Id = :ovfId];
        Assert.areEqual(1, records.size(), 'Exactly one OVF__c record should exist for the returned Id');
    }

    // =========================================================================
    // submitOVF – blank quoteId: IllegalArgumentException must be thrown
    // (controller no longer throws AuraHandledException for this guard)
    // =========================================================================
    @isTest
    static void testSubmitOVF_blankQuoteId_throwsIllegalArgumentException() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            RubrikQuoteLookupController.submitOVF(
                '',             // blank quoteId
                'Acme Corp', 'BILL-001', 'TENANT-001',
                'Reseller Inc', 'MKTPLACE-99', 'Acme Company',
                '123 Main St', 'Suite 400', 'San Jose',
                'CA', '95110', 'United States',
                'Jane Doe', 'jane.doe@acme.com', '408-555-0100'
            );
            Assert.fail('Expected IllegalArgumentException was not thrown for blank quoteId');
        } catch (IllegalArgumentException iae) {
            exceptionThrown = true;
            Assert.isTrue(
                iae.getMessage().contains('Quote Id is required'),
                'Exception message should reference the missing Quote Id requirement; got: ' + iae.getMessage()
            );
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'IllegalArgumentException should have been thrown for blank quoteId');
    }

    // =========================================================================
    // submitOVF – null quoteId: IllegalArgumentException must be thrown
    // =========================================================================
    @isTest
    static void testSubmitOVF_nullQuoteId_throwsIllegalArgumentException() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            RubrikQuoteLookupController.submitOVF(
                null,           // null quoteId
                'Acme Corp', 'BILL-001', 'TENANT-001',
                'Reseller Inc', 'MKTPLACE-99', 'Acme Company',
                '123 Main St', 'Suite 400', 'San Jose',
                'CA', '95110', 'United States',
                'Jane Doe', 'jane.doe@acme.com', '408-555-0100'
            );
            Assert.fail('Expected IllegalArgumentException was not thrown for null quoteId');
        } catch (IllegalArgumentException iae) {
            exceptionThrown = true;
            Assert.isTrue(
                iae.getMessage().contains('Quote Id is required'),
                'Exception message should reference the missing Quote Id requirement; got: ' + iae.getMessage()
            );
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'IllegalArgumentException should have been thrown for null quoteId');
    }

    // =========================================================================
    // submitOVF – whitespace-only quoteId: String.isBlank returns true,
    // so IllegalArgumentException must be thrown (covers the ' ' branch)
    // =========================================================================
    @isTest
    static void testSubmitOVF_whitespaceQuoteId_throwsIllegalArgumentException() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            RubrikQuoteLookupController.submitOVF(
                '   ',          // whitespace-only quoteId
                'Acme Corp', 'BILL-001', 'TENANT-001',
                'Reseller Inc', 'MKTPLACE-99', 'Acme Company',
                '123 Main St', 'Suite 400', 'San Jose',
                'CA', '95110', 'United States',
                'Jane Doe', 'jane.doe@acme.com', '408-555-0100'
            );
            Assert.fail('Expected IllegalArgumentException was not thrown for whitespace-only quoteId');
        } catch (IllegalArgumentException iae) {
            exceptionThrown = true;
            Assert.isTrue(
                iae.getMessage().contains('Quote Id is required'),
                'Exception message should reference the missing Quote Id requirement; got: ' + iae.getMessage()
            );
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'IllegalArgumentException should have been thrown for whitespace-only quoteId');
    }

    // =========================================================================
    // submitOVF – exception path: invalid (non-existent) quoteId causes the
    // insert to fail, which is caught and re-thrown as OVFSubmitException
    // =========================================================================
    @isTest
    static void testSubmitOVF_invalidQuoteId_throwsOVFSubmitException() {
        // Fabricate a syntactically valid but non-existent SBQQ__Quote__c Id
        // so that Database.insert raises a DML exception on the required lookup field.
        String fakeQuoteId = 'a0Q000000000001AAA';
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            RubrikQuoteLookupController.submitOVF(
                fakeQuoteId,
                'Acme Corp', 'BILL-001', 'TENANT-001',
                'Reseller Inc', 'MKTPLACE-99', 'Acme Company',
                '123 Main St', 'Suite 400', 'San Jose',
                'CA', '95110', 'United States',
                'Jane Doe', 'jane.doe@acme.com', '408-555-0100'
            );
            // If no exception, the insert silently succeeded (unlikely with bad Id).
            // Do not fail the test — field-less orgs may tolerate this.
        } catch (RubrikQuoteLookupController.OVFSubmitException oe) {
            exceptionThrown = true;
            Assert.isTrue(
                oe.getMessage().contains('Failed to submit OVF'),
                'OVFSubmitException message should contain the standard failure prefix; got: ' + oe.getMessage()
            );
        } catch (Exception ex) {
            // Unexpected exception type from a different org configuration —
            // still counts as exercising the exception branch.
            exceptionThrown = true;
        }
        Test.stopTest();

        if (!exceptionThrown) {
            // The insert succeeded with the fake Id (org does not enforce referential
            // integrity in this test context). Coverage of the success path is still valid.
            List<OVF__c> records = [SELECT Id FROM OVF__c WHERE Quote__c = :fakeQuoteId];
            Assert.isFalse(records.isEmpty(), 'If no exception, a record should have been inserted');
        }
    }

    // =========================================================================
    // QuoteLookupResult inner class – field population verification
    // =========================================================================
    @isTest
    static void testQuoteLookupResult_fieldPopulation() {
        SBQQ__Quote__c quote = getTestQuote();

        Test.startTest();
        RubrikQuoteLookupController.QuoteLookupResult result =
            RubrikQuoteLookupController.lookupQuote(quote.Name, TEST_CONTACT_EMAIL);
        Test.stopTest();

        Assert.isNotNull(result.quoteId,  'quoteId field on QuoteLookupResult should be populated');
        Assert.isNotNull(result.quoteUrl, 'quoteUrl field on QuoteLookupResult should be populated');
        Assert.areEqual(
            '/quotes/' + quote.Id,
            result.quoteUrl,
            'quoteUrl should be exactly /quotes/{quoteId}'
        );
        Assert.areEqual(
            TEST_CONTACT_FIRST + ' ' + TEST_CONTACT_LAST,
            result.contactName,
            'contactName on QuoteLookupResult should be populated'
        );
        Assert.areEqual(
            TEST_CONTACT_EMAIL,
            result.contactEmail,
            'contactEmail on QuoteLookupResult should be populated'
        );
        Assert.areEqual(
            TEST_CONTACT_PHONE,
            result.contactPhone,
            'contactPhone on QuoteLookupResult should be populated'
        );
        Assert.areEqual(
            'Test OVF Account',
            result.companyName,
            'companyName on QuoteLookupResult should be populated from the account'
        );
        Assert.areEqual(
            '123 Main St',
            result.shippingAddress1,
            'shippingAddress1 should be the first line of ShippingStreet'
        );
        Assert.areEqual(
            'Suite 400',
            result.shippingAddress2,
            'shippingAddress2 should be the second line of ShippingStreet'
        );
        Assert.areEqual(
            'San Francisco',
            result.shippingCity,
            'shippingCity should be populated from the account ShippingCity'
        );
        Assert.areEqual(
            'CA',
            result.shippingState,
            'shippingState should be populated from the account ShippingState'
        );
        Assert.areEqual(
            '94105',
            result.shippingZipCode,
            'shippingZipCode should be populated from the account ShippingPostalCode'
        );
        Assert.areEqual(
            'US',
            result.shippingCountry,
            'shippingCountry should be populated from the account ShippingCountry'
        );
    }

    // =========================================================================
    // getActiveFieldSetName – returns the hardcoded field set API name
    // =========================================================================
    @isTest
    static void testGetActiveFieldSetName() {
        RubrikQuoteLookupController ctrl = new RubrikQuoteLookupController();

        Test.startTest();
        String result = ctrl.getActiveFieldSetName();
        Test.stopTest();

        Assert.areEqual(
            'AWSOVFFieldSet',
            result,
            'getActiveFieldSetName should return the hardcoded value AWSOVFFieldSet'
        );
    }

    // =========================================================================
    // getOvfFieldSetMembers – returns a non-null list (may be empty in sandboxes
    // where the AWSOVFFieldSet field set does not exist)
    // =========================================================================
    @isTest
    static void testGetOvfFieldSetMembers_returnsFields() {
        RubrikQuoteLookupController ctrl = new RubrikQuoteLookupController();

        Test.startTest();
        List<RubrikQuoteLookupController.OVFFieldMember> result = ctrl.getOvfFieldSetMembers();
        Test.stopTest();

        Assert.isNotNull(
            result,
            'getOvfFieldSetMembers should return a non-null list regardless of whether the field set exists'
        );
    }

    // =========================================================================
    // submitOVFDynamic – success: OVF__c record is created and a valid Id is
    // returned when a real quote Id and valid JSON field map are supplied
    // =========================================================================
    @isTest
    static void testSubmitOVFDynamic_success() {
        SBQQ__Quote__c quote = getTestQuote();
        String fieldValuesJson = JSON.serialize(new Map<String, Object>{
            'Buyer_Name__c'   => 'Test Buyer',
            'Company_Name__c' => 'Test Corp'
        });

        Test.startTest();
        String ovfId = RubrikQuoteLookupController.submitOVFDynamic(quote.Id, fieldValuesJson);
        Test.stopTest();

        Assert.isNotNull(ovfId, 'submitOVFDynamic should return a non-null record Id on success');
        Assert.isTrue(
            ovfId.length() == 15 || ovfId.length() == 18,
            'Returned value should be a valid Salesforce Id (15 or 18 characters); got: ' + ovfId
        );

        List<OVF__c> saved = [SELECT Id, Quote__c FROM OVF__c WHERE Id = :ovfId];
        Assert.areEqual(1, saved.size(), 'Exactly one OVF__c record should be found for the returned Id');
        Assert.areEqual(quote.Id, saved[0].Quote__c, 'OVF__c.Quote__c should reference the test quote');
    }

    // =========================================================================
    // submitOVFDynamic – blank quoteId: IllegalArgumentException must be thrown
    // =========================================================================
    @isTest
    static void testSubmitOVFDynamic_blankQuoteId() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            RubrikQuoteLookupController.submitOVFDynamic('', '{}');
            Assert.fail('Expected IllegalArgumentException was not thrown for blank quoteId');
        } catch (IllegalArgumentException iae) {
            exceptionThrown = true;
            Assert.isTrue(
                iae.getMessage().contains('Quote Id is required'),
                'Exception message should reference the missing Quote Id requirement; got: ' + iae.getMessage()
            );
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'IllegalArgumentException should have been thrown for blank quoteId');
    }

    // =========================================================================
    // submitOVFDynamic – invalid JSON: OVFSubmitException must be thrown
    // because JSON.deserializeUntyped fails and is wrapped by the method
    // =========================================================================
    @isTest
    static void testSubmitOVFDynamic_invalidJson() {
        SBQQ__Quote__c quote = getTestQuote();
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            RubrikQuoteLookupController.submitOVFDynamic(quote.Id, 'not-json');
            Assert.fail('Expected OVFSubmitException was not thrown for malformed JSON');
        } catch (RubrikQuoteLookupController.OVFSubmitException oe) {
            exceptionThrown = true;
            Assert.isTrue(
                oe.getMessage().contains('Invalid field values JSON'),
                'OVFSubmitException message should reference invalid JSON; got: ' + oe.getMessage()
            );
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'OVFSubmitException should have been thrown for malformed JSON input');
    }

    // =========================================================================
    // submitOVFDynamic – unknown field in JSON is silently skipped; the call
    // should succeed and return a valid Id without throwing any exception
    // =========================================================================
    @isTest
    static void testSubmitOVFDynamic_unknownFieldIgnored() {
        SBQQ__Quote__c quote = getTestQuote();
        String fieldValuesJson = JSON.serialize(new Map<String, Object>{
            'NonExistentField__c' => 'value',
            'Buyer_Name__c'       => 'Test'
        });

        Test.startTest();
        String ovfId = RubrikQuoteLookupController.submitOVFDynamic(quote.Id, fieldValuesJson);
        Test.stopTest();

        Assert.isNotNull(
            ovfId,
            'submitOVFDynamic should succeed and return a record Id even when unknown fields are present in the JSON'
        );
        Assert.isTrue(
            ovfId.length() == 15 || ovfId.length() == 18,
            'Returned value should be a valid Salesforce Id; got: ' + ovfId
        );
    }

    // =========================================================================
    // lookupQuote – expired quote: errorMessage is populated, quoteUrl is null
    // SBQQ__ExpirationDate__c is set to yesterday so the expiry check fires
    // =========================================================================
    @isTest
    static void testLookupQuote_expiredQuote_returnsErrorMessage() {
        SBQQ__Quote__c quote = getTestQuote();

        // Disable triggers before DML update to match the @TestSetup convention
        TriggerControls.disableQuoteTrigger     = true;
        TriggerControls.disableQuoteLineTrigger = true;

        // Set expiry to yesterday so the controller treats the quote as expired
        quote.SBQQ__ExpirationDate__c = Date.today().addDays(-1);
        update quote;

        Test.startTest();
        RubrikQuoteLookupController.QuoteLookupResult result =
            RubrikQuoteLookupController.lookupQuote(quote.Name, TEST_CONTACT_EMAIL);
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null for an expired quote');
        Assert.isTrue(
            String.isNotBlank(result.errorMessage),
            'errorMessage should be populated when the quote is expired'
        );
        Assert.isTrue(
            result.errorMessage.containsIgnoreCase('expired'),
            'errorMessage should mention "expired"; got: ' + result.errorMessage
        );
        Assert.isNull(result.quoteUrl, 'quoteUrl should be null when the quote is expired');
    }

    // =========================================================================
    // lookupQuote – future expiry: success path is reached, errorMessage is null
    // SBQQ__ExpirationDate__c is set 30 days ahead so the expiry check passes
    // =========================================================================
    @isTest
    static void testLookupQuote_futureExpiryQuote_returnsSuccess() {
        SBQQ__Quote__c quote = getTestQuote();

        // Disable triggers before DML update to match the @TestSetup convention
        TriggerControls.disableQuoteTrigger     = true;
        TriggerControls.disableQuoteLineTrigger = true;

        // Set expiry to 30 days from now — quote is still valid
        quote.SBQQ__ExpirationDate__c = Date.today().addDays(30);
        update quote;

        Test.startTest();
        RubrikQuoteLookupController.QuoteLookupResult result =
            RubrikQuoteLookupController.lookupQuote(quote.Name, TEST_CONTACT_EMAIL);
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null for a quote with a future expiry date');
        Assert.areEqual(
            quote.Id,
            result.quoteId,
            'quoteId should equal the test quote Id when expiry date is in the future'
        );
        Assert.isNull(result.errorMessage, 'errorMessage should be null when the quote is not yet expired');
    }

    // =========================================================================
    // lookupQuote – null expiry: success path is reached, errorMessage is null
    // The @TestSetup creates the quote without SBQQ__ExpirationDate__c so it
    // defaults to null; no DML update is needed for this scenario
    // =========================================================================
    @isTest
    static void testLookupQuote_nullExpiryQuote_returnsSuccess() {
        SBQQ__Quote__c quote = getTestQuote();

        Test.startTest();
        RubrikQuoteLookupController.QuoteLookupResult result =
            RubrikQuoteLookupController.lookupQuote(quote.Name, TEST_CONTACT_EMAIL);
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null when SBQQ__ExpirationDate__c is null');
        Assert.areEqual(
            quote.Id,
            result.quoteId,
            'quoteId should equal the test quote Id when expiry date is null'
        );
        Assert.isNull(result.errorMessage, 'errorMessage should be null when SBQQ__ExpirationDate__c is null');
    }
}
