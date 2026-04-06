/**
 * @description Factory class for generating common test data needed across test classes.
 *              Provides helper methods to create Accounts, Contacts, Opportunities,
 *              Products, CPQ Quotes, Quote Lines, and Approval records.
 * @author kiran.kumar2@rubrik.com
 * @date 2025
 */
public class CommonTestDataFactory {

    // =====================================================
    // ACCOUNT CREATION
    // =====================================================
    /**
     * @description Creates a default Account with predefined values.
     * @return Account record (unsaved)
    */
    public static Account createAccount() {
        return createAccount(new Map<String, Object>());
    }
     /**
    * @description Creates an Account applying override field values.
    * @param overrides Map of field names to override
    * @return Account record (unsaved)
    */
    public static Account createAccount(Map<String, Object> overrides) {
        return new Account(
            Name = (String) overrides.get('Name') != null ? (String) overrides.get('Name') : 'Test Account ' + System.currentTimeMillis(),
            Industry = (String) overrides.get('Industry') != null ? (String) overrides.get('Industry') : 'Technology',
            Type = (String) overrides.get('Type') != null ? (String) overrides.get('Type') : 'Prospect',
            Phone = (String) overrides.get('Phone') != null ? (String) overrides.get('Phone') : '9999999999'
        );
    }
    /**
    * @description Creates a list of Accounts for bulk testing.
    * @param count Number of Account records to create
    * @return List of Account records (unsaved)
    */
    public static List<Account> createAccounts(Integer count) {
        List<Account> listAcc = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            listAcc.add(createAccount(new Map<String, Object>{ 'Name' => 'Bulk Account ' + i }));
        }
        return listAcc;
    }

    // =====================================================
    // CONTACT CREATION
    // =====================================================
     /**
    * @description Creates a default Contact for a given Account.
    * @param accountId ID of the parent Account
    * @return Contact record (unsaved)
    */
    public static Contact createContact(Id accountId) {
        return createContact(accountId, new Map<String, Object>());
    }
      /**
    * @description Creates a Contact with field overrides.
    * @param accountId Parent Account Id
    * @param overrides Field value overrides
    * @return Contact record (unsaved)
    */
    public static Contact createContact(Id accountId, Map<String, Object> overrides) {
        return new Contact(
            FirstName = (String) overrides.get('FirstName') != null ? (String) overrides.get('FirstName') : 'John',
            LastName = (String) overrides.get('LastName') != null ? (String) overrides.get('LastName') : 'Doe',
            Email = (String) overrides.get('Email') != null ? (String) overrides.get('Email') : 'john.doe@test.com',
            AccountId = accountId
        );
    }
    /**
     * @description Creates multiple Contacts for a given Account.
     * @param accountId Parent Account Id
     * @param count Number of Contacts to generate
     * @return List of Contact records (unsaved)
     */
    public static List<Contact> createContacts(Id accountId, Integer count) {
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < count; i++) {
            contacts.add(createContact(accountId, new Map<String, Object>{ 'FirstName' => 'Bulk', 'LastName' => 'Contact ' + i }));
        }
        return contacts;
    }

    // =====================================================
    // OPPORTUNITY CREATION
    // =====================================================
    /**
     * @description Creates a default Opportunity for an Account.
     * @param accountId Parent Account Id
     * @return Opportunity record (unsaved)
     */
    public static Opportunity createOpportunity(Id accountId) {
        return createOpportunity(accountId, new Map<String, Object>());
    }
    
    /**
     * @description Creates an Opportunity with override values.
     * @param accountId Parent Account Id
     * @param overrides Map of field overrides
     * @return Opportunity record (unsaved)
     */
    public static Opportunity createOpportunity(Id accountId, Map<String, Object> overrides) {
        return new Opportunity(
            Name = (String) overrides.get('Name') != null ? (String) overrides.get('Name') : 'Test Opportunity ' + System.currentTimeMillis(),
            StageName = (String) overrides.get('StageName') != null ? (String) overrides.get('StageName') : 'Prospecting',
            CloseDate = (Date) overrides.get('CloseDate') != null ? (Date) overrides.get('CloseDate') : System.today().addDays(30),
            Amount = (Decimal) overrides.get('Amount') != null ? (Decimal) overrides.get('Amount') : 10000,
            AccountId = accountId
        );
    }
    /**
     * @description Creates a bulk list of Opportunities.
     * @param accountId Parent Account Id
     * @param count Number of Opportunities to create
     * @return List of Opportunity records (unsaved)
     */
    public static List<Opportunity> createOpportunities(Id accountId, Integer count) {
        List<Opportunity> oppList = new List<Opportunity>();
        for (Integer i = 0; i < count; i++) {
            oppList.add(createOpportunity(accountId, new Map<String, Object>{ 'Name' => 'Bulk Opportunity ' + i }));
        }
        return oppList;
    }

    // =====================================================
    // PRODUCT (STANDARD)
    // =====================================================
    /**
     * @description Creates a default Product2 record.
     * @return Product2 record (unsaved)
     */
    public static Product2 createProduct() {
        return createProduct(new Map<String, Object>());
    }
   /**
     * @description Creates a Product2 with override values.
     * @param overrides Field overrides
     * @return Product2 record (unsaved)
    */
    public static Product2 createProduct(Map<String, Object> overrides) {
        return new Product2(
            Name = (String) overrides.get('Name') != null ? (String) overrides.get('Name') : 'CPQ Product ' + System.currentTimeMillis(),
            ProductCode = (String) overrides.get('ProductCode') != null ? (String) overrides.get('ProductCode') : 'PROD-' + String.valueOf(Math.abs(Crypto.getRandomInteger())),
            Family = (String) overrides.get('Family') != null ? (String) overrides.get('Family') : 'Subscription',
            IsActive = true
        );
    }
    /**
     * @description Creates a list of Products.
     * @param count Number of products to create
     * @return List of Product2 records (unsaved)
     */
    public static List<Product2> createProducts(Integer count) {
        List<Product2> listProd = new List<Product2>();
        for (Integer i = 0; i < count; i++) {
            listProd.add(createProduct(new Map<String, Object>{ 'Name' => 'Bulk Product ' + i }));
        }
        return listProd;
    }

    // =====================================================
    // CPQ QUOTE (SBQQ__QUOTE__C)
    // =====================================================
    /**
     * @description Creates a CPQ Quote for an Opportunity.
     * @param opportunityId Parent Opportunity Id
     * @return CPQ Quote (unsaved)
     */
    public static SBQQ__Quote__c createQuote(Id opportunityId) {
        return createQuote(opportunityId, new Map<String, Object>());
    }
    /**
     * @description Creates a CPQ Quote with override values.
     * @param opportunityId Parent Opportunity Id
     * @param overrides Field overrides
     * @return CPQ Quote (unsaved)
    */
    public static SBQQ__Quote__c createQuote(Id opportunityId, Map<String, Object> overrides) {
        return new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opportunityId,
            SBQQ__Status__c = (String) overrides.get('SBQQ__Status__c') != null ? (String) overrides.get('SBQQ__Status__c') : 'Draft'
        );
    }
    /**
     * @description Creates bulk CPQ Quotes.
     * @param opportunityId Parent Opportunity Id
     * @param count Number of quotes
     * @return List of CPQ Quote records (unsaved)
     */
    public static List<SBQQ__Quote__c> createQuotes(Id opportunityId, Integer count) {
        List<SBQQ__Quote__c> listQuote = new List<SBQQ__Quote__c>();
        for (Integer i = 0; i < count; i++) {
            listQuote.add(createQuote(opportunityId, new Map<String, Object>{ 'Name' => 'Bulk CPQ Quote ' + i }));
        }
        return listQuote;
    }

    // =====================================================
    // CPQ QUOTE LINES (SBQQ__QUOTELINE__C)
    // ===================================================== 
    /**
     * @description Creates Quote Lines for a Quote and list of Products.
     * @param quoteId CPQ Quote Id
     * @param products List of Product2
     * @return List of Quote Line records (unsaved)
     */
    public static List<SBQQ__QuoteLine__c> createQuoteLines(Id quoteId, List<Product2> products) {
        return createQuoteLines(quoteId, products, new Map<String, Object>());
    }
    /**
     * @description Creates Quote Lines using override values.
     * @param quoteId CPQ Quote Id
     * @param products List of Product2 records
     * @param overrides Field overrides map
     * @return List of CPQ Quote Line records (unsaved)
     */
    public static List<SBQQ__QuoteLine__c> createQuoteLines(Id quoteId, List<Product2> products, Map<String, Object> overrides) {
        List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
        for (Product2 p : products) {
            lines.add(new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = quoteId,
                SBQQ__Product__c = p.Id,
                SBQQ__Quantity__c = (Decimal) overrides.get('SBQQ__Quantity__c') != null ? (Decimal) overrides.get('SBQQ__Quantity__c') : 1,
                SBQQ__ListPrice__c = (Decimal) overrides.get('SBQQ__ListPrice__c') != null ? (Decimal) overrides.get('SBQQ__ListPrice__c') : 1000,
                SBQQ__NetPrice__c = (Decimal) overrides.get('SBQQ__NetPrice__c') != null ? (Decimal) overrides.get('SBQQ__NetPrice__c') : 900,
                SBQQ__Description__c = (String) overrides.get('SBQQ__Description__c') != null ? (String) overrides.get('SBQQ__Description__c') : 'Quote Line for ' + p.Name
            ));
        }
        return lines;
    }
    /**
     * @description Creates bulk simple Quote Lines.
     * @param quoteId Quote Id
     * @param count Number of quote lines
     * @return List of CPQ Quote Line records (unsaved)
     */
    public static List<SBQQ__QuoteLine__c> createQuoteLinesBulk(Id quoteId, Integer count) {
        List<SBQQ__QuoteLine__c> qls = new List<SBQQ__QuoteLine__c>();
        for (Integer i = 0; i < count; i++) {
            qls.add(new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = quoteId,
                SBQQ__Quantity__c = 1,
                SBQQ__ListPrice__c = 1000,
                SBQQ__NetPrice__c = 900,
                SBQQ__Description__c = 'Bulk Quote Line ' + i
            ));
        }
        return qls;
    }

    // =====================================================
    // PRICING SCENARIO
    // =====================================================
   /**
     * @description Creates a simple Pricing Scenario map.
     * @param productId Product Id
     * @return Map of pricing values
     */
    public static Map<String, Object> createPricingScenario(Id productId) {
        return new Map<String, Object>{
            'ListPrice' => 1000,
            'DiscountPercent' => 10,
            'NetPrice' => 900,
            'AdjustmentType' => 'Standard Discount',
            'ProductId' => productId
        };
    }

    // =====================================================
    // APPROVAL WORKFLOW // use advanced approvals
    // =====================================================
    /**
     * @description Creates an Advanced Approval (SBQQ/SBAA) record.
     * @param quoteId CPQ Quote Id
     * @param overrides Field overrides
     * @return sbaa__Approval__c record (unsaved)
     */
    public static sbaa__Approval__c  createAdvancedApproval(Id quoteId, Map<String, Object> overrides) {
    sbaa__Approval__c  approval = new sbaa__Approval__c ();
   
    approval.Quote__c  = quoteId;
    approval.sbaa__Status__c = overrides.containsKey('Status')
        ? (String)overrides.get('Status')
        : 'Submitted';

    approval.sbaa__CommentsLong__c  = overrides.containsKey('Comments')
        ? (String)overrides.get('Comments')
        : 'Auto submitted approval';

    return approval;
   }
   /**
     * @description Creates bulk Advanced Approval (SBQQ/SBAA) record.
     * @param quoteId CPQ Quote Id
     * @param count count of approval flows
     * @return List<SObject> (unsaved)
     */
    public static List<SObject> createApprovalWorkflows(Id quoteId, Integer count) {
        List<SObject> listApp = new List<SObject>();
        for (Integer i = 0; i < count; i++) {
            listApp.add(createAdvancedApproval(quoteId, new Map<String, Object>{ 'Name' => 'Approval ' + i }));
        }
        return listApp;
    }
}