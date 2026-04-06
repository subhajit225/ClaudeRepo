# Salesforce Design Agent Memory

## Project Conventions
- API Version: 66.0
- Package Directory: force-app/main/default
- Quote Object: SBQQ__Quote__c (Salesforce CPQ managed package)
- Primary Contact on Quote: SBQQ__PrimaryContact__c (managed) gets copied to Primary_Contact__c (custom) by QuoteTriggerHelper.cls trigger logic. Use Primary_Contact__c for queries.
- Trigger bypass: TriggerControls class + ShGl_DisableBusinessLogic__c custom setting
- Controller pattern: `with sharing` for all service classes

## Codebase Knowledge
- [Quote Portal Details](quote-portal.md) - RubrikQuotePortal VF page and controller details
- OVF__c object EXISTS (Order Verification Form) - Lookup to SBQQ__Quote__c, AutoNumber name
- RubrikQuoteLookupController.cls serves the OVF portal (validates quote# + email, submits OVF records)
- OVF portal URL (sandbox): https://rubrikinc--claudepoc.sandbox.my.salesforce-sites.com/rubrikquote
- [CPQ SW-without-HW Validation](cpq-sw-without-hw.md) - Detailed mapping of the "SW without HW" validation logic

## Classification Patterns
- VF page modifications = Development work
- Apex controller modifications = Development work
- Custom object + field creation = Admin work
- Quick action metadata (.quickAction-meta.xml) = Admin work
- LWC + Apex controller for quick action = Development work
- When a request mixes object creation with code changes, Admin must go first (object must exist before Apex references it)
- LWC-backed quick actions: Admin creates the quickAction metadata, Dev creates the LWC + Apex

## Existing Patterns for Reference
- LWC quick actions: lCC_Credit_SDR_ISR_Opportunity_LWC (uses @api recordId, CloseActionScreenEvent)
- Email sending: QuoteTriggerHelperForEmail.cls (Messaging.SingleEmailMessage, setHtmlBody)
- Quote line item fields: SBQQ__Product__r.Name, SBQQ__Quantity__c, SBQQ__ListPrice__c, SBQQ__NetTotal__c
- TriggerHandler base class used for trigger handler pattern
- Email file attachments: renewalDocumentationController.cls lines 187-193 (Messaging.EmailFileAttachment + setFileAttachments)
- Latest QuoteDocument query: GenerateDocumentCustomExt.cls line 71 (ORDER BY CreatedDate DESC LIMIT 1)
- CPQ Quote Document PDF storage: May be ContentVersion (Files) or classic Attachment -- org uses both patterns
- Send OVF implementation: SendOvfEmailController.cls (Apex) + sendOvfQuickAction LWC + SBQQ__Quote__c.Send_OVF.quickAction-meta.xml
- OVF__c has 15 form fields (all Text 255, none required): Buyer_Name__c, Buyer_Billing_ID__c, Buyer_Tenant_ID__c, Reseller_Name__c, Marketplace_Seller_ID__c, Company_Name__c, Address_1__c, Address_2__c, City__c, State__c, Zip_Code__c, Country__c, Contact_Name__c, Contact_Email__c, Contact_Phone__c
- RubrikQuotePortal.page: applyHtmlTag=false, applyBodyTag=false, uses VF Remoting (@RemoteAction), matrix rain animation, split layout, guest user access via Site
- GuestDmlHelper (without sharing inner class in controller) handles DML for guest user context
- GuestQueryHelper (without sharing inner class in controller) handles SOQL for guest user context

## Design Decision Log
- OVF dynamic fieldset: Chose inline <apex:repeat> over @RemoteAction for fieldset metadata (avoids extra round-trip, no guest remoting permission issues)
- OVF dynamic submit: Chose new submitOVFDynamic(quoteId, fieldValuesJson) method rather than modifying existing 16-param submitOVF (backward compat)
