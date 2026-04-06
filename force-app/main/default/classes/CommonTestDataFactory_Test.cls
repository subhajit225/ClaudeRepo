@IsTest
private class CommonTestDataFactory_Test {

    @TestSetup
    static void setup() {

        // Create a test user for System.runAs
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@test.com',
            Username = 'testuser01@test.com.new',
            Alias = 'tusr',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert u;

        // disable triggers/flows for test data
        CommonTestDataUtils.setAutomationFlags(true, null);
    }

    @IsTest
    static void testAccountContactOpportunityCreation() {

        // Fetch test user created in TestSetup
        User u = [SELECT Id FROM User WHERE Username = 'testuser01@test.com.new' LIMIT 1];

        System.runAs(u) {

            Account acc = CommonTestDataFactory.createAccount();
            System.assertNotEquals(null, acc.Name);
            System.assertEquals('Technology', acc.Industry);

            List<Account> bulkAccs = CommonTestDataFactory.createAccounts(3);
            System.assertEquals(3, bulkAccs.size());

            Contact con = CommonTestDataFactory.createContact(acc.Id);
            System.assertEquals('John', con.FirstName);

            List<Contact> cons = CommonTestDataFactory.createContacts(acc.Id, 2);
            System.assertEquals(2, cons.size());

            Opportunity opp = CommonTestDataFactory.createOpportunity(acc.Id);
            System.assertEquals('Prospecting', opp.StageName);

            List<Opportunity> opps = CommonTestDataFactory.createOpportunities(acc.Id, 3);
            System.assertEquals(3, opps.size());
        }
    }

    @IsTest
    static void testProductQuoteQuoteLineCreation() {

        User u = [SELECT Id FROM User WHERE Username = 'testuser01@test.com.new' LIMIT 1];

        System.runAs(u) {

            Product2 prod = CommonTestDataFactory.createProduct();
            System.assertEquals(true, prod.IsActive);

            List<Product2> prods = CommonTestDataFactory.createProducts(2);
            System.assertEquals(2, prods.size());

            Account acc = CommonTestDataFactory.createAccount();
            Opportunity opp = CommonTestDataFactory.createOpportunity(acc.Id);

            SBQQ__Quote__c quote = CommonTestDataFactory.createQuote(opp.Id);
            insert quote;

            System.assertEquals('Draft', quote.SBQQ__Status__c);

            List<SBQQ__Quote__c> quotes = CommonTestDataFactory.createQuotes(opp.Id, 2);
            System.assertEquals(2, quotes.size());

            Map<String, Object> overrides = new Map<String, Object>{
                'Status' => 'In Review',
                'Comments' => 'Override Comment'
            };

            sbaa__Approval__c app =
                CommonTestDataFactory.createAdvancedApproval(quote.Id, overrides);

            List<SObject> results =
                CommonTestDataFactory.createApprovalWorkflows(quote.Id, 3);

            List<SBQQ__QuoteLine__c> qls =
                CommonTestDataFactory.createQuoteLines(quote.id, prods);

            System.assertEquals(2, qls.size());
            System.assert(qls[0].SBQQ__Description__c.contains('Quote Line'));
        }
    }
}