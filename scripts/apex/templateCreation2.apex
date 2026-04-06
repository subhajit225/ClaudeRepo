// =============================================================
// STEP 2 of 3 — Create TemplateContent records (batch 2 of 2)
//               + Create the parent QuoteTemplate record
// Source: rbkdev1 — Template "Quote Document" (a6R1W0000004UN3UAM)
// Run AFTER templateCreation1.apex, BEFORE templateCreation3.apex
//
// Creates 7 SBQQ__TemplateContent__c records:
//   1. EULA Account Verbiage
//   2. Proactive Promo Term
//   3. verbiage - Additional Month Added
//   4. M365 DPC Terms & Condition - RS-GB-CR-MS-PE-PP
//   5. M365 DPC Terms & Condition - RS-GB-CR-MS-L3-PP
//   6. NAS or UCL verbiage
//   7. Addon Verbiage
// Then creates 1 SBQQ__QuoteTemplate__c record:
//   - "Quote Document"
// =============================================================

// ── Part A: Remaining TemplateContent records ─────────────────

Set<String> existingNames = new Set<String>();
for (SBQQ__TemplateContent__c ec : [
    SELECT Name FROM SBQQ__TemplateContent__c
    WHERE Name IN (
        'EULA Account Verbiage',
        'Proactive Promo Term',
        'verbiage - Additional Month Added',
        'M365 DPC Terms & Condition - RS-GB-CR-MS-PE-PP',
        'M365 DPC Terms & Condition - RS-GB-CR-MS-L3-PP',
        'NAS or UCL verbiage',
        'Addon Verbiage'
    )
]) {
    existingNames.add(ec.Name);
}

List<SBQQ__TemplateContent__c> toInsert = new List<SBQQ__TemplateContent__c>();

if (!existingNames.contains('EULA Account Verbiage')) {
    toInsert.add(new SBQQ__TemplateContent__c(
        Name                = 'EULA Account Verbiage',
        SBQQ__Type__c       = 'HTML',
        SBQQ__TableStyle__c = 'Standard',
        SBQQ__RawMarkup__c  = '<p>&#160;</p>\n\n<p><em><span style="font-family: helvetica, sans-serif; font-size: 9px;">The products and services set forth on this quote are subject to the Rubrik end user terms found at: <a href="http://www.rubrik.com/legal" style="font-family: helvetica, sans-serif; font-size: 9px;">http://www.rubrik.com/legal</a>. Distributor agrees that it (and shall procure that the applicable Rubrik authorized reseller) will put the end customer on notice of these terms.</span></em></p>'
    ));
}

if (!existingNames.contains('Proactive Promo Term')) {
    toInsert.add(new SBQQ__TemplateContent__c(
        Name                = 'Proactive Promo Term',
        SBQQ__Type__c       = 'HTML',
        SBQQ__FontSize__c   = 9,
        SBQQ__TableStyle__c = 'Standard',
        SBQQ__RawMarkup__c  = '<p>&#160;</p>\n\n<div style="background:#eee;border:1px solid #ccc;padding:5px 10px;"><span style="color:#009999;"><strong><span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">Solely with regard to the following SKU(s): {!quote.DiscountedProactiveProducts__c} (&#34;Promotional SKUs&#34;) procured by the party named in the &#39;To:&#39; line above (&#34;You&#34;) set forth in this quote {!quote.Name}, Rubrik agrees that the pricing to you for this purchase of the Promotional SKU(s) for user, {!quote.SBQQ__BillingName__c} includes the one-time promotional discount set forth above in the &#34;Promo Disc %&#34; column (&#34;Promotional Discount&#34;). The Promotional Discount applies only to the initial eligible purchase of the Promotional SKU(s) under this Quote and will not apply to any future renewals, upgrades or additional purchase of the Promotional SKU(s).</span></strong></span></div>'
    ));
}

if (!existingNames.contains('verbiage - Additional Month Added')) {
    toInsert.add(new SBQQ__TemplateContent__c(
        Name                = 'verbiage - Additional Month Added',
        SBQQ__Type__c       = 'HTML',
        SBQQ__TableStyle__c = 'Standard',
        SBQQ__RawMarkup__c  = '<p><span style="font-family:helvetica,sans-serif;"><span style="font-size:9px;"><i>Limited Promotional Offer: For the Support Services Term and the associated Subscription Period referenced above and purchased in connection with Rubrik-branded hardware, Rubrik will provide End User a one-month extension (at the same capacity/quantity as set forth on this Quote) at the end of the Subscription Period identified in this Quote, at no additional charge. This Limited Promotional Offer is subject to change and shall expire at the discretion of Rubrik.</i></span></span></p>'
    ));
}

if (!existingNames.contains('M365 DPC Terms & Condition - RS-GB-CR-MS-PE-PP')) {
    toInsert.add(new SBQQ__TemplateContent__c(
        Name                = 'M365 DPC Terms & Condition - RS-GB-CR-MS-PE-PP',
        SBQQ__Type__c       = 'Quote Terms',
        SBQQ__FontSize__c   = 9,
        SBQQ__TableStyle__c = 'Standard'
    ));
}

if (!existingNames.contains('M365 DPC Terms & Condition - RS-GB-CR-MS-L3-PP')) {
    toInsert.add(new SBQQ__TemplateContent__c(
        Name                = 'M365 DPC Terms & Condition - RS-GB-CR-MS-L3-PP',
        SBQQ__Type__c       = 'Quote Terms',
        SBQQ__FontSize__c   = 9,
        SBQQ__TableStyle__c = 'Standard'
    ));
}

if (!existingNames.contains('NAS or UCL verbiage')) {
    toInsert.add(new SBQQ__TemplateContent__c(
        Name                = 'NAS or UCL verbiage',
        SBQQ__Type__c       = 'HTML',
        SBQQ__FontSize__c   = 9,
        SBQQ__TableStyle__c = 'Standard',
        SBQQ__RawMarkup__c  = '<div>&#160;</div>\n\n<div>&#160;</div>\n\n<div><em><span style="font-size:9px;">This quote does not include Rubrik Cloud Vault capacity or it is less than the Parent Dsaas NAS or Dsaas UCL SKU. Rubrik Cloud Vault is required to use Dsaas NAS or Dsaas UCL</span></em></div>\n\n<p>&#160;</p>'
    ));
}

if (!existingNames.contains('Addon Verbiage')) {
    toInsert.add(new SBQQ__TemplateContent__c(
        Name                = 'Addon Verbiage',
        SBQQ__Type__c       = 'Quote Terms',
        SBQQ__FontSize__c   = 9,
        SBQQ__TableStyle__c = 'Standard'
    ));
}

if (!toInsert.isEmpty()) {
    insert toInsert;
    System.debug('Inserted ' + toInsert.size() + ' content record(s).');
} else {
    System.debug('All 7 content records already exist — skipping.');
}


// ── Part B: Parent QuoteTemplate record ───────────────────────

List<SBQQ__QuoteTemplate__c> existingTemplate = [
    SELECT Id FROM SBQQ__QuoteTemplate__c WHERE Name = 'Quote Document' LIMIT 1
];

if (!existingTemplate.isEmpty()) {
    System.debug('QuoteTemplate already exists: ' + existingTemplate[0].Id + ' — skipping creation. Proceed to templateCreation3.apex.');
} else {
    SBQQ__QuoteTemplate__c tmpl = new SBQQ__QuoteTemplate__c(
        Name                       = 'Quote Document',
        SBQQ__CompanyStreet__c     = '3495 Deer Creek Road',
        SBQQ__CompanyCity__c       = 'Palo Alto',
        SBQQ__CompanyState__c      = 'CA',
        SBQQ__CompanyPostalCode__c = '94304',
        SBQQ__CompanyPhone__c      = '(844) 478-2745'
    );
    insert tmpl;
    System.debug('Created QuoteTemplate "Quote Document": ' + tmpl.Id + ' — Proceed to templateCreation3.apex.');
}
