# Documentation Agent Memory

## Project Context
- Salesforce DX project: /Users/subhajitbiswas/Cloud Project/RubrikClaudePOC
- API Version: 66.0
- Package directory: force-app/main/default
- Docs folder: docs/
- Design requirements always at: agent-output/design-requirements.md

## Key Project Dependencies
- CPQ managed package (SBQQ__Quote__c, SBQQ__PrimaryContact__c) is present
- ShGl_DisableBusinessLogic__c custom setting used in tests to suppress CPQ automation
- TriggerControls Apex class used in tests to disable quote/quoteline triggers
- Public-facing Visualforce page: RubrikQuotePortal (controller: RubrikQuoteLookupController)

## Naming Conventions Observed
- Custom object API names: no project prefix (e.g., OVF__c, not Rubrik_OVF__c)
- Auto-number format used for record names: LABEL-{0000}
- Test class naming: [ClassName]Test.cls
- LWC components confirmed in project: sendOvfQuickAction (quick action on SBQQ__Quote__c)
- Quick action metadata lives in force-app/main/default/quickActions/ (flat folder, not inside objects/)
- LWC quick action pattern: lightning__RecordAction target, ScreenAction type, CloseActionScreenEvent
- Apex controller pattern: public with sharing, @AuraEnabled(cacheable=false), AuraHandledException, WITH USER_MODE
- Brand color: #009dac (Rubrik teal) — appears in email HTML and LWC CSS

## Exception Compatibility Notes
- AuraHandledException is ONLY compatible with @AuraEnabled methods — never use in @RemoteAction
- @RemoteAction exception messages propagate via event.message in the JS remoting callback
- Inner exception classes (extends Exception {}) must be public to be catchable in test classes as ClassName.InnerException
- Catch block ordering matters: specific inner exception catch must precede general Exception catch to prevent double-wrap

## Documentation Patterns That Work
- Three-state VF page flows should be documented as a table of section IDs with visible-when conditions
- Always document failing tests explicitly — include the reason and investigation steps
- For CPQ-dependent features, note the CPQ package as a dependency
- Security section should call out public-facing pages explicitly
- Include both client-side and server-side input handling in the Security section
- For LWC components, document all computed getters and the full state model (property + type + initial value + description)
- Document inner/wrapper classes and @TestVisible private methods — reviewers expect them in docs
- Always call out hardcoded environment URLs (sandbox vs production) in Known Limitations
- List upstream trigger/class dependencies under Dependencies so future devs understand the data pipeline

## Custom Label Documentation Patterns
- For Custom Label changes: document the before/after Apex line, the label API name, category, protected flag, and default value
- Always include a "How to Update" step-by-step section with navigation path: Setup > Custom Labels > [Name] > Edit > Value
- Include an environment-type table (sandbox vs production URL patterns) so admins know the correct URL format
- Note that labels ship with a default value (the sandbox value); explicitly warn that an admin must update the value post-deployment in production
- For test class assertions referencing a label, explain WHY the label reference is environment-safe vs a literal string

## File Reading Tips
- RubrikQuotePortal.page is ~658 lines after dynamic fieldset changes; OVF section starts ~line 362, JS starts ~line 419
- OVF__c.object-meta.xml is verbose (action overrides boilerplate) — key config starts around line 143
- design-requirements.md is the authoritative source for original request text
- OrderInsertHelper.cls is very large (3700+ lines); use Grep with -n and -C to locate PRDOPS-tagged blocks rather than reading sequentially
- OrderMainTriggerTest.cls PRDOPS-544 test section begins at line 7688

## Order Provisioning Architecture
- OrderMainTrigger → OrderHandler.execute() → OrderInsertHelper.processOrderData()
- Per-item loop evaluates product flags (lines ~1413-1427); Have_Polaris_Products__c is stamped after the loop (line 1601)
- Revenue callout fires at lines 1794-1808 on Order_Status__c = 'Order Accepted'
- POC callout fires at lines 2781-2787 on ScreenStatus__c → 'Approved' or 'Approved Bypassed'
- Polaris_Fulfillment_Status__c = 'Not Started' is stamped on ALL Revenue/POC orders at insert (line 594-595); override it explicitly for special cases
- RSCP- prefix exclusion: isRSCPProduct guard at line 1413 prevents RSCP products from flipping hasPolarisProduct to true
- Constants for RSCP: PRODUCT_CODE_PREFIX_RSCP and POLARIS_FULFILLMENT_STATUS_NOT_NEEDED (lines 174-175 in Constants.cls)

## Test Pattern for Provisioning Tests
- Tests using 'Polaris_Fulfillment_Status__c' => 'Completed' in setup bypass the provisioning callout path — this is a common shortcut that creates coverage gaps
- To test the callout guard directly: initialize with 'Not Started' or 'Not Needed', then update to the triggering status (Order Accepted for Revenue, ScreenStatus Approved for POC)
- Belt-and-suspenders documentation pattern: when two independent guards protect the same path, add a comment on each explaining it is a secondary guard

## VF Page Remoting + Auto-Fill Patterns
- When documenting VF page JS that auto-fills fields, note the timing dependency explicitly: auto-fill MUST follow renderOVFFields() because that method destroys and recreates DOM elements
- For re-lookup stale-data guards (always resetting a field to '' when absent), document the decision as intentional in Known Limitations, not as a code smell
- JS variable scope (page-level var) should be listed in Configuration Details alongside the Apex result fields they mirror
- When a field reuses an already-returned value (e.g., Buyer Name = Contact Name), document the business decision explicitly and note it as a hardcoded assumption that requires a new Apex field if the source ever changes
- For incremental auto-fill tasks (each task adds more fields), include a "Relationship to Previous Task" section with cross-reference to the prior doc file and note which infrastructure was already in place
- For multi-line text field splitting (e.g., ShippingStreet -> Address 1 / Address 2): document the replaceAll('\\r','') + split('\n', 2) pattern; note that a limit of 2 means lines 3+ are concatenated into the second result; note Windows vs Unix line-ending handling explicitly

## Permission Set Documentation Patterns
- When FLS is granted via a PermissionSetGroup, document the GROUP as "not modified" and explain that access flows through its member permission sets — this clarifies why the group itself has no metadata file
- Managed package permission sets (e.g., Tackle_Full_Access_Marketplace, Tackle_Sales_Operator) cannot be modified via metadata deploy — always document them as "not modified" with the reason
- For OVF__c FLS: RubrikFieldSalesUserNew and Tackle_User are the two editable permission sets in this project that grant OVF access to sales reps

## Field Set Documentation Patterns
- Field Set `isRequired` in metadata controls client-side HTML required attribute, not server-side DML enforcement — document this distinction explicitly
- In @isTest context, FieldSet.getFields() returns empty list unless metadata is deployed — note this as a known test limitation
- When a Field Set acts as a server-side write allowlist, explain WHY it is used instead of the full field map — this is a security design decision reviewers will question
- The single-method routing pattern (getActiveFieldSetName returning hardcoded string) is the canonical extension point — always document it and the steps to add condition logic later

## Email Sender Documentation Patterns
- When an OWE (Org-Wide Email Address) is removed, document the before/after in a comparison table: sender address, reply-to, OWE SOQL query, setOrgWideEmailAddressId, setReplyTo, and compliance status
- Document the root cause for OWE removal (Spring '26 domain verification enforcement) so future devs understand why re-adding the OWE requires DNS re-verification first
- Note the UX impact: sender identity shifts from a corporate noreply to the running user's email — document this explicitly in Known Limitations
- For graceful-fallback email attachments (null-safe), document both the null path and the production path, and note that email delivery is never blocked by a missing attachment
- For test classes using try/catch around Messaging.sendEmail: document the sandbox deliverability caveat so reviewers don't mistake the catch branch for a code defect
- For attachment parent object tests: always verify the production query target (which object the Attachment.ParentId points to) before writing tests — a mismatch (e.g., QuoteDocument vs Opportunity) silently produces wrong results

## LWC Incremental Feature Documentation Patterns
- For optional-field additions to an existing LWC, document the full new state model (property name, type, default, purpose) separately from pre-existing properties
- When an Apex method signature changes (e.g., new optional parameter), show a before/after code block for the method signature so reviewers can verify backward compatibility at a glance
- For two-layer validation (client + server), list both layers in a table in the Security section rather than only mentioning the Apex side
- When all existing test call-sites are updated (e.g., passing null for a new optional param), note this explicitly so reviewers know there are no compile errors
- Server-side sanitisation steps should be documented as an ordered table (check name / condition / error thrown or action taken)

## Security Gate Ordering Documentation Patterns
- When an expiry / status check is deliberately placed AFTER an ownership/identity check, always document this in both Configuration Details AND the Security section — reviewers commonly ask "why not check expiry first?"
- The standard rationale: placing a secondary rejection (expiry, status) after identity validation prevents information disclosure (caller cannot determine whether a record exists by observing which error they receive)
- Document this as an explicit security decision with a plain-English explanation, not just a code comment reference

## VF Mobile/UX Documentation Patterns
- For pure CSS color-only changes, document all instances of the changed color in the file and explicitly call out which ones were intentionally left unchanged — future devs need to know the decision was deliberate, not an oversight
- When a color change is accepted for one context but rejected for another due to background contrast, document both decisions in the same "Before and After" table with a Rationale column and include a contrast ratio table
- For pure front-end (CSS/HTML/JS) change sets, use a "Before and After" comparison table instead of separate component tables
- CSS cascade bugs should be documented with an explanation of specificity + source order to help future devs avoid repeating the mistake
- JavaScript animation guards should document both the guard condition AND the teardown path (clearInterval / cancelAnimationFrame)
- Browser-specific quirks (iOS zoom, international postal codes) warrant explicit "intentionally not added" notes so future devs don't revert them
- For Canvas 2D animations, document: particle count, rotation speeds, alpha/size ranges, projection type, and the mobile guard condition in a constants table
- Minor code smells (e.g., redundant guard calls that are no-ops) should be noted in Known Limitations rather than silently ignored
