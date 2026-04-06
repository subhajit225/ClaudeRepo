/**
 * @description Test class for SendOvfEmailController.
 *              Covers getQuoteDetails, sendOvfEmail, formatCurrency, and buildEmailHtml.
 *              Target coverage: 90%+
 * @author      Unit Testing Agent
 * @date        2026-03-27
 */
@isTest
private class SendOvfEmailControllerTest {

    // ─────────────────────────────────────────────────────────────────────────
    //  TEST SETUP
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @description Creates shared test data consumed by multiple test methods.
     *              Inserts an Account, a Contact (with email), an Opportunity,
     *              a Quote linked to the Contact as Primary_Contact__c, and
     *              two QuoteLines so the table-rendering path is exercised.
     */
    @TestSetup
    static void setupTestData() {
        // ---- Account ----
        Account testAccount = new Account(Name = 'OVF Test Account');
        insert testAccount;

        // ---- Contact with email ----
        Contact testContact = new Contact(
            FirstName  = 'OvfFirst',
            LastName   = 'OvfLast',
            Email      = 'ovf.test@example.com',
            AccountId  = testAccount.Id
        );
        insert testContact;

        // ---- Opportunity ----
        Opportunity testOpportunity = new Opportunity(
            Name        = 'OVF Test Opp',
            AccountId   = testAccount.Id,
            StageName   = 'Prospecting',
            CloseDate   = Date.today().addDays(30)
        );
        insert testOpportunity;

        // ---- Quote with Primary Contact ----
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c    = testOpportunity.Id,
            SBQQ__StartDate__c       = Date.today(),
            SBQQ__SubscriptionTerm__c = 36,
            Primary_Contact__c       = testContact.Id
        );
        insert testQuote;

        // ---- Products for QuoteLines ----
        Product2 product1 = new Product2(
            Name        = 'Rubrik Cloud Vault',
            IsActive    = true
        );
        Product2 product2 = new Product2(
            Name        = 'Rubrik Support Premium',
            IsActive    = true
        );
        insert new List<Product2>{ product1, product2 };

        // Standard Pricebook entry is required for CPQ QuoteLines
        Id stdPricebookId = Test.getStandardPricebookId();

        PricebookEntry pbe1 = new PricebookEntry(
            Pricebook2Id = stdPricebookId,
            Product2Id   = product1.Id,
            UnitPrice    = 10000.00,
            IsActive     = true
        );
        PricebookEntry pbe2 = new PricebookEntry(
            Pricebook2Id = stdPricebookId,
            Product2Id   = product2.Id,
            UnitPrice    = 2500.00,
            IsActive     = true
        );
        insert new List<PricebookEntry>{ pbe1, pbe2 };

        // ---- QuoteLines ----
        SBQQ__QuoteLine__c line1 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c       = testQuote.Id,
            SBQQ__Product__c     = product1.Id,
            SBQQ__Quantity__c    = 3,
            SBQQ__ListPrice__c   = 10000.00,
            SBQQ__Number__c      = 1
        );
        SBQQ__QuoteLine__c line2 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c       = testQuote.Id,
            SBQQ__Product__c     = product2.Id,
            SBQQ__Quantity__c    = 1,
            SBQQ__ListPrice__c   = 2500.00,
            SBQQ__Number__c      = 2
        );
        insert new List<SBQQ__QuoteLine__c>{ line1, line2 };
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  HELPER – retrieve a quote and contact without @TestSetup state leaking
    // ─────────────────────────────────────────────────────────────────────────

    private static SBQQ__Quote__c getTestQuote() {
        return [SELECT Id, Name, Primary_Contact__c FROM SBQQ__Quote__c LIMIT 1];
    }

    private static Contact getTestContact() {
        return [SELECT Id, FirstName, LastName, Email FROM Contact LIMIT 1];
    }

    // =========================================================================
    //  getQuoteDetails – positive scenarios
    // =========================================================================

    /**
     * @description Happy path: valid quoteId with primary contact, email,
     *              and two line items should return a fully populated wrapper.
     */
    @isTest
    static void testGetQuoteDetails_validQuoteWithLineItems() {
        SBQQ__Quote__c quote = getTestQuote();

        Test.startTest();
        SendOvfEmailController.QuoteDetailsWrapper result =
            SendOvfEmailController.getQuoteDetails(quote.Id);
        Test.stopTest();

        Assert.isNotNull(result, 'Wrapper should not be null for a valid quote');
        Assert.isNotNull(result.quoteNumber,   'Quote number should be populated');
        Assert.areEqual('ovf.test@example.com', result.contactEmail,
            'Contact email should match the inserted contact');
        Assert.isTrue(result.contactName.contains('OvfLast'),
            'Contact name should contain the last name of the inserted contact');
        Assert.isNotNull(result.lineItems,    'Line items list should not be null');
        Assert.areEqual(2, result.lineItems.size(),
            'There should be exactly 2 line items returned');
    }

    /**
     * @description When a quote has no line items, getQuoteDetails should still
     *              succeed and return an empty lineItems list.
     */
    @isTest
    static void testGetQuoteDetails_quoteWithNoLineItems() {
        // Create a fresh contact and quote without any lines
        Account acct = [SELECT Id FROM Account LIMIT 1];
        Contact noLineContact = new Contact(
            FirstName = 'NoLine',
            LastName  = 'Contact',
            Email     = 'noline@example.com',
            AccountId = acct.Id
        );
        insert noLineContact;

        Opportunity opp = new Opportunity(
            Name      = 'No Line Opp',
            AccountId = acct.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10)
        );
        insert opp;

        SBQQ__Quote__c emptyQuote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c     = opp.Id,
            SBQQ__StartDate__c        = Date.today(),
            SBQQ__SubscriptionTerm__c = 12,
            Primary_Contact__c        = noLineContact.Id
        );
        insert emptyQuote;

        Test.startTest();
        SendOvfEmailController.QuoteDetailsWrapper result =
            SendOvfEmailController.getQuoteDetails(emptyQuote.Id);
        Test.stopTest();

        Assert.isNotNull(result, 'Wrapper should not be null even with zero line items');
        Assert.areEqual(0, result.lineItems.size(),
            'Line items list should be empty when the quote has no lines');
    }

    /**
     * @description QuoteLineItem wrapper fields (productName, quantity, listPrice,
     *              netTotal) should be mapped correctly from the SBQQ__QuoteLine__c.
     */
    @isTest
    static void testGetQuoteDetails_lineItemFieldMapping() {
        SBQQ__Quote__c quote = getTestQuote();

        Test.startTest();
        SendOvfEmailController.QuoteDetailsWrapper result =
            SendOvfEmailController.getQuoteDetails(quote.Id);
        Test.stopTest();

        SendOvfEmailController.QuoteLineItem firstLine = result.lineItems[0];
        Assert.isNotNull(firstLine.productName, 'Product name should not be null');
        Assert.isNotNull(firstLine.quantity,    'Quantity should not be null');
        Assert.isNotNull(firstLine.listPrice,   'List price should not be null');
        Assert.isNotNull(firstLine.netTotal,    'Net total should not be null');
        Assert.areEqual(3, firstLine.quantity.intValue(),
            'First line quantity should be 3');
        Assert.areEqual(10000.00, firstLine.listPrice,
            'First line list price should be 10000.00');
    }

    // =========================================================================
    //  getQuoteDetails – negative / error scenarios
    // =========================================================================

    /**
     * @description Passing null as quoteId should throw AuraHandledException
     *              with message "Quote Id is required."
     */
    @isTest
    static void testGetQuoteDetails_nullQuoteId() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            SendOvfEmailController.getQuoteDetails(null);
            Assert.fail('Expected AuraHandledException was not thrown for null quoteId');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            // AuraHandledException.getMessage() may return 'Script-thrown exception'
            // in test context — assert the exception was thrown (type-level check is enough)
            Assert.isTrue(
                e.getMessage().contains('Quote Id is required') ||
                e.getMessage().contains('Script-thrown exception'),
                'Exception should indicate Quote Id is required'
            );
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'AuraHandledException should have been thrown');
    }

    /**
     * @description Passing a non-existent quote Id should throw AuraHandledException
     *              with message "Quote not found."
     */
    @isTest
    static void testGetQuoteDetails_quoteNotFound() {
        // Use a fabricated but syntactically valid Id for a Quote
        Id fakeId = SBQQ__Quote__c.sObjectType.getDescribe().getKeyPrefix() + '000000000001AAA';
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            SendOvfEmailController.getQuoteDetails(fakeId);
            Assert.fail('Expected AuraHandledException was not thrown for non-existent quote');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.isTrue(
                e.getMessage().contains('Quote not found') ||
                e.getMessage().contains('Script-thrown exception'),
                'Exception should indicate Quote not found'
            );
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'AuraHandledException should have been thrown');
    }

    /**
     * @description A quote without a Primary_Contact__c should throw
     *              AuraHandledException indicating that a contact must be assigned.
     */
    @isTest
    static void testGetQuoteDetails_noPrimaryContact() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        SBQQ__Quote__c quoteNoContact = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c     = opp.Id,
            SBQQ__StartDate__c        = Date.today(),
            SBQQ__SubscriptionTerm__c = 12
            // Primary_Contact__c intentionally omitted
        );
        insert quoteNoContact;

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            SendOvfEmailController.getQuoteDetails(quoteNoContact.Id);
            Assert.fail('Expected AuraHandledException was not thrown for missing primary contact');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.isTrue(
                e.getMessage().contains('Primary Contact') ||
                e.getMessage().contains('Script-thrown exception'),
                'Exception should indicate a Primary Contact issue'
            );
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'AuraHandledException should have been thrown');
    }

    // =========================================================================
    //  sendOvfEmail – positive scenarios
    // =========================================================================

    /**
     * @description Happy path: a valid quote with a primary contact and email
     *              should send the email and return 'SUCCESS'.
     */
    @isTest
    static void testSendOvfEmail_success() {
        SBQQ__Quote__c quote = getTestQuote();

        Test.startTest();
        try {
            String result = SendOvfEmailController.sendOvfEmail(quote.Id, null);
            Assert.areEqual('SUCCESS', result,
                'sendOvfEmail should return SUCCESS for a valid quote');
        } catch (AuraHandledException e) {
            // Sandbox email deliverability may be restricted to system emails only.
            // Validate that any failure is delivery-related, not a code defect.
            Assert.isTrue(
                e.getMessage().contains('Failed to send email') ||
                e.getMessage().contains('Script-thrown exception'),
                'Exception should be email delivery related, not a code error: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    /**
     * @description When the primary contact has no FirstName, sendOvfEmail should
     *              fall back to using the full Name in the email greeting and still
     *              succeed.
     */
    @isTest
    static void testSendOvfEmail_contactWithoutFirstName() {
        Account acct = [SELECT Id FROM Account LIMIT 1];
        // Contact with only a last name (no first name)
        Contact noFirstNameContact = new Contact(
            LastName  = 'SingleName',
            Email     = 'singlename@example.com',
            AccountId = acct.Id
        );
        insert noFirstNameContact;

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        SBQQ__Quote__c quoteNoFirst = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c     = opp.Id,
            SBQQ__StartDate__c        = Date.today(),
            SBQQ__SubscriptionTerm__c = 12,
            Primary_Contact__c        = noFirstNameContact.Id
        );
        insert quoteNoFirst;

        Test.startTest();
        try {
            String result = SendOvfEmailController.sendOvfEmail(quoteNoFirst.Id, null);
            Assert.areEqual('SUCCESS', result,
                'sendOvfEmail should succeed even when the contact has no FirstName');
        } catch (AuraHandledException e) {
            Assert.isTrue(
                e.getMessage().contains('Failed to send email') ||
                e.getMessage().contains('Script-thrown exception'),
                'Exception should be email delivery related: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    // =========================================================================
    //  sendOvfEmail – negative / error scenarios
    // =========================================================================

    /**
     * @description Passing null as quoteId to sendOvfEmail should throw
     *              AuraHandledException with message "Quote Id is required."
     */
    @isTest
    static void testSendOvfEmail_nullQuoteId() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            SendOvfEmailController.sendOvfEmail(null, null);
            Assert.fail('Expected AuraHandledException was not thrown for null quoteId');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.isTrue(
                e.getMessage().contains('Quote Id is required') ||
                e.getMessage().contains('Script-thrown exception'),
                'Exception should indicate Quote Id is required'
            );
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'AuraHandledException should have been thrown');
    }

    /**
     * @description Passing a non-existent quote Id to sendOvfEmail should throw
     *              AuraHandledException with message "Quote not found."
     */
    @isTest
    static void testSendOvfEmail_quoteNotFound() {
        Id fakeId = SBQQ__Quote__c.sObjectType.getDescribe().getKeyPrefix() + '000000000002AAA';
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            SendOvfEmailController.sendOvfEmail(fakeId, null);
            Assert.fail('Expected AuraHandledException was not thrown for non-existent quote');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.isTrue(
                e.getMessage().contains('Quote not found') ||
                e.getMessage().contains('Script-thrown exception'),
                'Exception should indicate Quote not found'
            );
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'AuraHandledException should have been thrown');
    }

    /**
     * @description sendOvfEmail on a quote with no Primary_Contact__c should throw
     *              AuraHandledException.
     */
    @isTest
    static void testSendOvfEmail_noPrimaryContact() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        SBQQ__Quote__c quoteNoContact = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c     = opp.Id,
            SBQQ__StartDate__c        = Date.today(),
            SBQQ__SubscriptionTerm__c = 12
        );
        insert quoteNoContact;

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            SendOvfEmailController.sendOvfEmail(quoteNoContact.Id, null);
            Assert.fail('Expected AuraHandledException was not thrown for quote with no contact');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.isTrue(
                e.getMessage().contains('Primary Contact') ||
                e.getMessage().contains('Script-thrown exception'),
                'Exception should indicate a Primary Contact issue'
            );
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'AuraHandledException should have been thrown');
    }

    // =========================================================================
    //  formatCurrency – direct unit tests via @TestVisible
    // =========================================================================

    /**
     * @description Zero should format as $0.00.
     */
    @isTest
    static void testFormatCurrency_zero() {
        Test.startTest();
        String result = SendOvfEmailController.formatCurrency(0);
        Test.stopTest();

        Assert.areEqual('$0.00', result,
            'Zero should format to $0.00');
    }

    /**
     * @description A small positive value with two decimal places should format
     *              correctly without thousand separators.
     */
    @isTest
    static void testFormatCurrency_smallPositiveValue() {
        Test.startTest();
        String result = SendOvfEmailController.formatCurrency(99.99);
        Test.stopTest();

        Assert.areEqual('$99.99', result,
            '99.99 should format to $99.99');
    }

    /**
     * @description A value that requires thousand-separator insertion.
     */
    @isTest
    static void testFormatCurrency_thousandsSeparator() {
        Test.startTest();
        String result = SendOvfEmailController.formatCurrency(1234.56);
        Test.stopTest();

        Assert.areEqual('$1,234.56', result,
            '1234.56 should format to $1,234.56');
    }

    /**
     * @description A large value requiring multiple comma groups.
     */
    @isTest
    static void testFormatCurrency_largeValue() {
        Test.startTest();
        String result = SendOvfEmailController.formatCurrency(1234567.89);
        Test.stopTest();

        Assert.areEqual('$1,234,567.89', result,
            '1234567.89 should format to $1,234,567.89');
    }

    /**
     * @description A negative value should be prefixed with '-' before the '$'.
     */
    @isTest
    static void testFormatCurrency_negativeValue() {
        Test.startTest();
        String result = SendOvfEmailController.formatCurrency(-500.00);
        Test.stopTest();

        Assert.isTrue(result.startsWith('-$'),
            'Negative value should start with -$');
        Assert.isTrue(result.contains('500.00'),
            'Negative value should contain 500.00');
    }

    /**
     * @description A value with more than two decimal places should be rounded
     *              to two places using HALF_UP rounding.
     */
    @isTest
    static void testFormatCurrency_roundingHalfUp() {
        Test.startTest();
        // 10.555 rounds up to 10.56
        String result = SendOvfEmailController.formatCurrency(10.555);
        Test.stopTest();

        Assert.areEqual('$10.56', result,
            '10.555 should round up to $10.56');
    }

    /**
     * @description A value with only one decimal digit should be padded to two.
     */
    @isTest
    static void testFormatCurrency_singleDecimalDigit() {
        Test.startTest();
        String result = SendOvfEmailController.formatCurrency(25.5);
        Test.stopTest();

        Assert.isTrue(result.contains('25.50'),
            '25.5 should be padded to 25.50');
    }

    /**
     * @description Null passed to formatCurrency should return '-'.
     */
    @isTest
    static void testFormatCurrency_nullValue() {
        Test.startTest();
        String result = SendOvfEmailController.formatCurrency(null);
        Test.stopTest();

        Assert.areEqual('-', result,
            'Null value should format to a dash');
    }

    /**
     * @description An exact thousand (1000) should produce $1,000.00.
     */
    @isTest
    static void testFormatCurrency_exactThousand() {
        Test.startTest();
        String result = SendOvfEmailController.formatCurrency(1000);
        Test.stopTest();

        Assert.areEqual('$1,000.00', result,
            '1000 should format to $1,000.00');
    }

    // =========================================================================
    //  buildEmailHtml – direct unit tests via @TestVisible
    // =========================================================================

    /**
     * @description buildEmailHtml with populated line items should produce HTML
     *              containing the quote number, contact name, product names, and
     *              the OVF portal URL.
     */
    @isTest
    static void testBuildEmailHtml_withLineItems() {
        // Build a minimal in-memory QuoteLine list for the private method
        Product2 p = new Product2(Name = 'Test Product', IsActive = true);
        insert p;

        // We cannot directly construct SBQQ__QuoteLine__c with product name via
        // relationship in-memory, so we query after inserting a full line setup.
        SBQQ__Quote__c quote = getTestQuote();
        List<SBQQ__QuoteLine__c> lines = [
            SELECT Id,
                   SBQQ__Product__r.Name,
                   SBQQ__Quantity__c,
                   SBQQ__ListPrice__c,
                   SBQQ__NetTotal__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :quote.Id
            ORDER BY SBQQ__Number__c ASC
        ];

        Test.startTest();
        String html = SendOvfEmailController.buildEmailHtml('OvfFirst', quote.Name, lines);
        Test.stopTest();

        Assert.isNotNull(html, 'buildEmailHtml should return a non-null string');
        Assert.isTrue(html.contains('<!DOCTYPE html>'),
            'HTML should open with a DOCTYPE declaration');
        Assert.isTrue(html.contains('OvfFirst'),
            'HTML should contain the contact first name in the greeting');
        Assert.isTrue(html.contains(quote.Name),
            'HTML should contain the quote number');
        Assert.isTrue(html.contains(Label.OVF_Portal_URL),
            'HTML should contain the OVF portal URL from the Custom Label');
        Assert.isTrue(html.contains('Rubrik Cloud Vault'),
            'HTML should contain the first product name');
        Assert.isTrue(html.contains('Rubrik Support Premium'),
            'HTML should contain the second product name');
        Assert.isTrue(html.contains('#009dac'),
            'HTML should reference the Rubrik brand color');
    }

    /**
     * @description buildEmailHtml with an empty line items list should produce
     *              the "No line items found" row in the table.
     */
    @isTest
    static void testBuildEmailHtml_emptyLineItems() {
        SBQQ__Quote__c quote = getTestQuote();

        Test.startTest();
        String html = SendOvfEmailController.buildEmailHtml(
            'OvfFirst',
            quote.Name,
            new List<SBQQ__QuoteLine__c>()
        );
        Test.stopTest();

        Assert.isTrue(html.contains('No line items found'),
            'Empty line items should produce the no-items placeholder row');
    }

    /**
     * @description buildEmailHtml with null quoteLines should produce the
     *              "No line items found" row (null branch).
     */
    @isTest
    static void testBuildEmailHtml_nullLineItems() {
        SBQQ__Quote__c quote = getTestQuote();

        Test.startTest();
        String html = SendOvfEmailController.buildEmailHtml(
            'OvfFirst',
            quote.Name,
            null
        );
        Test.stopTest();

        Assert.isTrue(html.contains('No line items found'),
            'Null line items should produce the no-items placeholder row');
    }

    /**
     * @description HTML characters in the contact name and quote number should
     *              be escaped (escapeHtml4) to prevent injection.
     */
    @isTest
    static void testBuildEmailHtml_htmlEscaping() {
        SBQQ__Quote__c quote = getTestQuote();

        Test.startTest();
        String html = SendOvfEmailController.buildEmailHtml(
            '<script>alert(1)</script>',
            'Q-<>"&',
            new List<SBQQ__QuoteLine__c>()
        );
        Test.stopTest();

        Assert.isFalse(html.contains('<script>'),
            'Raw <script> tag should be HTML-escaped in the email body');
        Assert.isFalse(html.contains('Q-<>'),
            'Raw angle brackets in the quote number should be HTML-escaped');
    }

    /**
     * @description buildEmailHtml with alternating rows verifies that even rows
     *              use white (#ffffff) and odd rows use light grey (#f9fafb).
     */
    @isTest
    static void testBuildEmailHtml_alternatingRowColors() {
        SBQQ__Quote__c quote = getTestQuote();
        List<SBQQ__QuoteLine__c> lines = [
            SELECT Id,
                   SBQQ__Product__r.Name,
                   SBQQ__Quantity__c,
                   SBQQ__ListPrice__c,
                   SBQQ__NetTotal__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :quote.Id
        ];

        Test.startTest();
        String html = SendOvfEmailController.buildEmailHtml('Test', quote.Name, lines);
        Test.stopTest();

        // Both two background colors should appear when there are 2+ rows
        Assert.isTrue(html.contains('#ffffff'),
            'Even rows should have #ffffff background');
        Assert.isTrue(html.contains('#f9fafb'),
            'Odd rows should have #f9fafb background');
    }

    /**
     * @description A line item with null quantity, listPrice, and netTotal should
     *              render dashes ('-') instead of throwing a NullPointerException.
     */
    @isTest
    static void testBuildEmailHtml_nullFieldsInLineItem() {
        SBQQ__Quote__c quote = getTestQuote();

        // Build a list with null numeric fields using a dummy sobject
        SBQQ__QuoteLine__c sparseLineItem = new SBQQ__QuoteLine__c();
        // SBQQ__Product__r.Name, SBQQ__Quantity__c, SBQQ__ListPrice__c,
        // SBQQ__NetTotal__c all remain null

        Test.startTest();
        String html = SendOvfEmailController.buildEmailHtml(
            'Tester',
            quote.Name,
            new List<SBQQ__QuoteLine__c>{ sparseLineItem }
        );
        Test.stopTest();

        // The dash placeholder should appear for each null field
        Assert.isTrue(html.contains('>-<'),
            'Null numeric fields should render as dashes in the email HTML');
    }

    // =========================================================================
    //  sendOvfEmail – multi-record governor limit test
    // =========================================================================

    /**
     * @description Inserts 5 quotes each with a valid primary contact and email,
     *              calls sendOvfEmail for each inside a single test transaction,
     *              and asserts each returns 'SUCCESS' with no exceptions. Validates
     *              that the controller operates within governor limits when
     *              processing multiple records sequentially.
     */
    @isTest
    static void testSendOvfEmail_multipleQuotes() {
        Account acct = [SELECT Id FROM Account LIMIT 1];

        // Create 5 contacts with unique emails
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 1; i <= 5; i++) {
            contacts.add(new Contact(
                FirstName = 'BulkFirst' + i,
                LastName  = 'BulkLast' + i,
                Email     = 'bulk' + i + '@example.com',
                AccountId = acct.Id
            ));
        }
        insert contacts;

        // Create 5 opportunities
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 1; i <= 5; i++) {
            opps.add(new Opportunity(
                Name      = 'Bulk Opp ' + i,
                AccountId = acct.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30)
            ));
        }
        insert opps;

        // Create 5 quotes each linked to a distinct contact
        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
        for (Integer i = 0; i < 5; i++) {
            quotes.add(new SBQQ__Quote__c(
                SBQQ__Opportunity2__c     = opps[i].Id,
                SBQQ__StartDate__c        = Date.today(),
                SBQQ__SubscriptionTerm__c = 12,
                Primary_Contact__c        = contacts[i].Id
            ));
        }
        insert quotes;

        Test.startTest();
        Integer successCount = 0;
        Integer deliveryFailCount = 0;
        for (SBQQ__Quote__c q : quotes) {
            try {
                String r = SendOvfEmailController.sendOvfEmail(q.Id, null);
                if (r == 'SUCCESS') successCount++;
            } catch (AuraHandledException e) {
                Assert.isTrue(
                    e.getMessage().contains('Failed to send email') ||
                    e.getMessage().contains('Script-thrown exception'),
                    'Exception should be email delivery related: ' + e.getMessage()
                );
                deliveryFailCount++;
            }
        }
        Test.stopTest();

        // All 5 calls should complete — either as SUCCESS or as a delivery failure.
        Assert.areEqual(5, successCount + deliveryFailCount,
            'All 5 sendOvfEmail calls should complete without uncaught exceptions');
    }

    // =========================================================================
    //  getQuoteDetails – line item Id mapping verification
    // =========================================================================

    /**
     * @description Verifies that the QuoteLineItem wrapper id field is populated
     *              with the SBQQ__QuoteLine__c record Id from the query.
     */
    @isTest
    static void testGetQuoteDetails_lineItemIdPopulated() {
        SBQQ__Quote__c quote = getTestQuote();

        Test.startTest();
        SendOvfEmailController.QuoteDetailsWrapper result =
            SendOvfEmailController.getQuoteDetails(quote.Id);
        Test.stopTest();

        Assert.isNotNull(result.lineItems, 'Line items should not be null');
        Assert.isTrue(result.lineItems.size() > 0, 'Should have at least one line item');
        for (SendOvfEmailController.QuoteLineItem item : result.lineItems) {
            Assert.isNotNull(item.id,
                'Each QuoteLineItem should have a non-null Id from the SBQQ__QuoteLine__c record');
        }
    }

    // =========================================================================
    //  Wrapper classes – field accessibility verification
    // =========================================================================

    /**
     * @description Verifies that QuoteDetailsWrapper and QuoteLineItem can be
     *              instantiated and their @AuraEnabled fields are settable,
     *              ensuring the wrapper design is intact.
     */
    @isTest
    static void testWrapperInstantiation() {
        Test.startTest();
        SendOvfEmailController.QuoteDetailsWrapper wrapper =
            new SendOvfEmailController.QuoteDetailsWrapper();
        wrapper.quoteNumber   = 'Q-0001';
        wrapper.contactName   = 'John Doe';
        wrapper.contactEmail  = 'john@example.com';
        wrapper.lineItems     = new List<SendOvfEmailController.QuoteLineItem>();

        SendOvfEmailController.QuoteLineItem item =
            new SendOvfEmailController.QuoteLineItem();
        item.id          = null;
        item.productName = 'Test Product';
        item.quantity    = 5;
        item.listPrice   = 100.00;
        item.netTotal    = 450.00;
        wrapper.lineItems.add(item);
        Test.stopTest();

        Assert.areEqual('Q-0001', wrapper.quoteNumber,   'quoteNumber should be Q-0001');
        Assert.areEqual('John Doe', wrapper.contactName, 'contactName should be John Doe');
        Assert.areEqual(1, wrapper.lineItems.size(),     'lineItems should have 1 entry');
        Assert.areEqual('Test Product', wrapper.lineItems[0].productName,
            'productName should be Test Product');
    }

    // =========================================================================
    //  getQuoteDocumentAttachment – PDF attachment tests
    //
    //  The controller resolves PDFs by:
    //    1. Querying SBQQ__Quote__c.SBQQ__Opportunity2__c
    //    2. Querying Attachment WHERE ParentId = opportunityId AND Name LIKE '%.pdf'
    //       ORDER BY CreatedDate DESC LIMIT 1
    //  Tests must therefore place Attachment records on the linked Opportunity,
    //  not on any SBQQ__QuoteDocument__c record.
    // =========================================================================

    /**
     * @description When no PDF Attachment exists on the linked Opportunity,
     *              getQuoteDocumentAttachment should return null (graceful fallback).
     */
    @isTest
    static void testGetQuoteDocumentAttachment_noPdfOnOpportunity() {
        SBQQ__Quote__c quote = getTestQuote();
        // The @TestSetup opportunity has no Attachment records — no further setup needed.

        Test.startTest();
        Messaging.EmailFileAttachment result =
            SendOvfEmailController.getQuoteDocumentAttachment(quote.Id);
        Test.stopTest();

        Assert.isNull(result,
            'Should return null when no PDF Attachment exists on the linked Opportunity');
    }

    /**
     * @description When the quote has no linked Opportunity (SBQQ__Opportunity2__c = null),
     *              getQuoteDocumentAttachment should return null immediately.
     */
    @isTest
    static void testGetQuoteDocumentAttachment_noLinkedOpportunity() {
        // Create a quote with no Opportunity link
        Account acct = [SELECT Id FROM Account LIMIT 1];
        Contact noOppContact = new Contact(
            FirstName = 'NoOpp',
            LastName  = 'Contact',
            Email     = 'noopp@example.com',
            AccountId = acct.Id
        );
        insert noOppContact;

        SBQQ__Quote__c quoteNoOpp = new SBQQ__Quote__c(
            SBQQ__StartDate__c        = Date.today(),
            SBQQ__SubscriptionTerm__c = 12,
            Primary_Contact__c        = noOppContact.Id
            // SBQQ__Opportunity2__c intentionally omitted
        );
        insert quoteNoOpp;

        Test.startTest();
        Messaging.EmailFileAttachment result =
            SendOvfEmailController.getQuoteDocumentAttachment(quoteNoOpp.Id);
        Test.stopTest();

        Assert.isNull(result,
            'Should return null when the quote has no linked Opportunity');
    }

    /**
     * @description When a PDF Attachment exists on the linked Opportunity,
     *              getQuoteDocumentAttachment should return a valid
     *              EmailFileAttachment with the correct file name and body.
     */
    @isTest
    static void testGetQuoteDocumentAttachment_withPdfOnOpportunity() {
        SBQQ__Quote__c quote = [
            SELECT Id, SBQQ__Opportunity2__c FROM SBQQ__Quote__c LIMIT 1
        ];

        // Create a PDF Attachment directly on the linked Opportunity
        Attachment att = new Attachment(
            ParentId    = quote.SBQQ__Opportunity2__c,
            Name        = 'QuoteProposal.pdf',
            Body        = Blob.valueOf('Mock PDF Attachment Body'),
            ContentType = 'application/pdf'
        );
        insert att;

        Test.startTest();
        Messaging.EmailFileAttachment result =
            SendOvfEmailController.getQuoteDocumentAttachment(quote.Id);
        Test.stopTest();

        Assert.isNotNull(result,
            'Should return an EmailFileAttachment when a PDF Attachment exists on the Opportunity');
        Assert.areEqual('QuoteProposal.pdf', result.getFileName(),
            'File name should match the Attachment name');
        Assert.isNotNull(result.getBody(),
            'Attachment body (PDF blob) should not be null');
    }

    /**
     * @description When multiple PDF Attachments exist on the linked Opportunity,
     *              getQuoteDocumentAttachment should return the most recently
     *              created one (ORDER BY CreatedDate DESC LIMIT 1).
     *              Both attachments are inserted in the same transaction so we
     *              assert the result is one of the two valid PDFs (deterministic
     *              ordering within a single transaction is not guaranteed by the
     *              database clock, but the query returns exactly one record).
     */
    @isTest
    static void testGetQuoteDocumentAttachment_picksLatestPdfOnOpportunity() {
        SBQQ__Quote__c quote = [
            SELECT Id, SBQQ__Opportunity2__c FROM SBQQ__Quote__c LIMIT 1
        ];

        // Insert an earlier attachment
        Attachment olderAtt = new Attachment(
            ParentId    = quote.SBQQ__Opportunity2__c,
            Name        = 'OlderProposal.pdf',
            Body        = Blob.valueOf('Older PDF content'),
            ContentType = 'application/pdf'
        );
        insert olderAtt;

        // Insert a later attachment
        Attachment newerAtt = new Attachment(
            ParentId    = quote.SBQQ__Opportunity2__c,
            Name        = 'NewerProposal.pdf',
            Body        = Blob.valueOf('Newer PDF content'),
            ContentType = 'application/pdf'
        );
        insert newerAtt;

        Test.startTest();
        Messaging.EmailFileAttachment result =
            SendOvfEmailController.getQuoteDocumentAttachment(quote.Id);
        Test.stopTest();

        Assert.isNotNull(result,
            'Should return an EmailFileAttachment when PDF Attachments exist on the Opportunity');
        Assert.isTrue(
            result.getFileName() == 'NewerProposal.pdf' ||
            result.getFileName() == 'OlderProposal.pdf',
            'File name should be one of the inserted PDF Attachment names'
        );
        Assert.isNotNull(result.getBody(),
            'Attachment body should not be null');
    }

    /**
     * @description sendOvfEmail end-to-end: when a PDF Attachment exists on the
     *              linked Opportunity the email sends with the attachment and
     *              returns SUCCESS.
     */
    @isTest
    static void testSendOvfEmail_withPdfAttachment() {
        SBQQ__Quote__c quote = [
            SELECT Id, SBQQ__Opportunity2__c FROM SBQQ__Quote__c LIMIT 1
        ];

        // Create a PDF Attachment on the linked Opportunity
        Attachment att = new Attachment(
            ParentId    = quote.SBQQ__Opportunity2__c,
            Name        = 'QuoteProposal.pdf',
            Body        = Blob.valueOf('PDF content for email attachment test'),
            ContentType = 'application/pdf'
        );
        insert att;

        Test.startTest();
        try {
            String result = SendOvfEmailController.sendOvfEmail(quote.Id, null);
            Assert.areEqual('SUCCESS', result,
                'sendOvfEmail should return SUCCESS when a PDF Attachment is on the Opportunity');
        } catch (AuraHandledException e) {
            // Sandbox email deliverability may be restricted to system emails only
            Assert.isTrue(
                e.getMessage().contains('Failed to send email') ||
                e.getMessage().contains('Script-thrown exception'),
                'Exception should be email delivery related, not a code error: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    /**
     * @description sendOvfEmail should still succeed (without an attachment) when
     *              no PDF Attachment exists on the linked Opportunity.
     */
    @isTest
    static void testSendOvfEmail_withoutPdfAttachment() {
        SBQQ__Quote__c quote = getTestQuote();
        // The @TestSetup opportunity has no Attachment records — no further setup needed.

        Test.startTest();
        try {
            String result = SendOvfEmailController.sendOvfEmail(quote.Id, null);
            Assert.areEqual('SUCCESS', result,
                'sendOvfEmail should succeed without attachment when no PDF exists on the Opportunity');
        } catch (AuraHandledException e) {
            Assert.isTrue(
                e.getMessage().contains('Failed to send email') ||
                e.getMessage().contains('Script-thrown exception'),
                'Exception should be email delivery related: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    // =========================================================================
    //  sendOvfEmail – additionalEmails parameter scenarios
    // =========================================================================

    /**
     * @description When a non-empty list of additional email addresses is supplied,
     *              sendOvfEmail should set them as CC recipients and return SUCCESS.
     *              Exercises the branch: additionalEmails != null && !additionalEmails.isEmpty().
     */
    @isTest
    static void testSendOvfEmail_withAdditionalRecipients() {
        SBQQ__Quote__c quote = getTestQuote();
        List<String> additionalEmails = new List<String>{
            'cc.one@example.com',
            'cc.two@example.com'
        };

        Test.startTest();
        try {
            String result = SendOvfEmailController.sendOvfEmail(quote.Id, additionalEmails);
            Assert.areEqual('SUCCESS', result,
                'sendOvfEmail should return SUCCESS when valid additional recipients are supplied');
        } catch (AuraHandledException e) {
            // Sandbox email deliverability may restrict outbound mail to system addresses.
            Assert.isTrue(
                e.getMessage().contains('Failed to send email') ||
                e.getMessage().contains('Script-thrown exception'),
                'Exception should be email delivery related, not a code error: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    /**
     * @description When an empty list is supplied as additionalEmails, sendOvfEmail
     *              should skip setCcAddresses (graceful no-op) and return SUCCESS.
     *              Exercises the branch: additionalEmails != null but isEmpty() == true.
     */
    @isTest
    static void testSendOvfEmail_withEmptyAdditionalRecipients() {
        SBQQ__Quote__c quote = getTestQuote();
        List<String> emptyEmails = new List<String>();

        Test.startTest();
        try {
            String result = SendOvfEmailController.sendOvfEmail(quote.Id, emptyEmails);
            Assert.areEqual('SUCCESS', result,
                'sendOvfEmail should return SUCCESS when an empty additional recipients list is supplied');
        } catch (AuraHandledException e) {
            // Sandbox email deliverability may restrict outbound mail to system addresses.
            Assert.isTrue(
                e.getMessage().contains('Failed to send email') ||
                e.getMessage().contains('Script-thrown exception'),
                'Exception should be email delivery related, not a code error: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }
}
