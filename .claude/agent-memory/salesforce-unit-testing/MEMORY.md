# Unit Testing Agent Memory Index

- [OrderMainTriggerTest patterns](project_order_trigger_test_patterns.md) — Key patterns for extending OrderMainTriggerTest: helper methods, Product2/PricebookEntry setup, Polaris provisioning assertions
- [SBQQ Quote test patterns](sbqq_quote_test_patterns.md) — How to insert SBQQ__Quote__c with PrimaryContact for email-match tests; trigger bypass strategy; OVF__c setup
- [SendOvfEmailController patterns](send_ovf_email_test_patterns.md) — AuraHandledException dual-check, @TestVisible method calls, null-field QuoteLine, HTML escaping assertions
- [Exception type migration pattern](exception_type_migration.md) — When a controller changes from AuraHandledException to IllegalArgumentException/CalloutException, update test catch blocks to match the new type exactly
- [RubrikQuoteLookupController dynamic OVF patterns](rubrik_quote_lookup_dynamic_ovf_patterns.md) — submitOVFDynamic JSON testing, instance method instantiation, field set null-safe assertions
- [OrderInsertHelper guard condition coverage](order_insert_helper_guard_patterns.md) — How to exercise Revenue/POC callout guards in their blocking direction; status transition sequencing; RSC_G_Enabled__c boundary testing
