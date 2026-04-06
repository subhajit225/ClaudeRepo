// =============================================================
// STEP 3 of 3 — Create TemplateSection records (all 16)
// Source: rbkdev1 — Template "Quote Document" (a6R1W0000004UN3UAM)
// Run AFTER templateCreation1.apex AND templateCreation2.apex
//
// Queries all content records and the template by Name,
// then inserts any missing sections.
// =============================================================

// ── Resolve template Id ───────────────────────────────────────

List<SBQQ__QuoteTemplate__c> tmplList = [
    SELECT Id FROM SBQQ__QuoteTemplate__c WHERE Name = 'Quote Document' LIMIT 1
];
if (tmplList.isEmpty()) {
    System.debug('ERROR: QuoteTemplate "Quote Document" not found. Run templateCreation2.apex first.');
    return;
}
Id templateId = tmplList[0].Id;
System.debug('Using template: ' + templateId);


// ── Resolve content Ids by Name ───────────────────────────────

Map<String, Id> contentIdByName = new Map<String, Id>();
for (SBQQ__TemplateContent__c c : [
    SELECT Id, Name FROM SBQQ__TemplateContent__c
    WHERE Name IN (
        'Top Section 2',
        'Line Items',
        'Line Items - MDQ',
        'APJ Sub Term Terms',
        'Shipping 1',
        'verbiage - Additional Month Added',
        'Proactive Promo Term',
        'Conditional PO Verbiage content',
        'Additional Terms',
        'M365 DPC Terms & Condition - RS-GB-CR-MS-PE-PP',
        'M365 DPC Terms & Condition - RS-GB-CR-MS-L3-PP',
        'Addon Verbiage',
        'NAS or UCL verbiage',
        'EULA Account Verbiage'
    )
]) {
    contentIdByName.put(c.Name, c.Id);
}
System.debug('Content records resolved: ' + contentIdByName.keySet());


// ── Skip sections that already exist under this template ──────

Set<String> existingSectionNames = new Set<String>();
for (SBQQ__TemplateSection__c es : [
    SELECT Name FROM SBQQ__TemplateSection__c WHERE SBQQ__Template__c = :templateId
]) {
    existingSectionNames.add(es.Name);
}

List<SBQQ__TemplateSection__c> toInsert = new List<SBQQ__TemplateSection__c>();


// DisplayOrder 10 — no linked content
if (!existingSectionNames.contains('Top Section 1')) {
    toInsert.add(new SBQQ__TemplateSection__c(
        Name                           = 'Top Section 1',
        SBQQ__Template__c              = templateId,
        SBQQ__Content__c               = null,
        SBQQ__DisplayOrder__c          = 10,
        SBQQ__TopMargin__c             = -0.52,
        SBQQ__BottomMargin__c          = 0,
        SBQQ__ConditionalPrintField__c = 'Special_Requirements_Needed__c',
        SBQQ__KeepTogether__c          = 'Auto',
        SBQQ__KeepWithNext__c          = 'Auto',
        SBQQ__ColumnHeaderHidden__c    = false,
        SBQQ__QuoteTotalsPrinted__c    = false
    ));
}

// DisplayOrder 20
if (!existingSectionNames.contains('Top Section 2')) {
    toInsert.add(new SBQQ__TemplateSection__c(
        Name                        = 'Top Section 2',
        SBQQ__Template__c           = templateId,
        SBQQ__Content__c            = contentIdByName.get('Top Section 2'),
        SBQQ__DisplayOrder__c       = 20,
        SBQQ__TopMargin__c          = 0.55,
        SBQQ__BottomMargin__c       = 0,
        SBQQ__KeepTogether__c       = 'Auto',
        SBQQ__KeepWithNext__c       = 'Auto',
        SBQQ__ColumnHeaderHidden__c = false,
        SBQQ__QuoteTotalsPrinted__c = false
    ));
}

// DisplayOrder 30
if (!existingSectionNames.contains('Quote Lines')) {
    toInsert.add(new SBQQ__TemplateSection__c(
        Name                        = 'Quote Lines',
        SBQQ__Template__c           = templateId,
        SBQQ__Content__c            = contentIdByName.get('Line Items'),
        SBQQ__DisplayOrder__c       = 30,
        SBQQ__TopMargin__c          = 0,
        SBQQ__BottomMargin__c       = 1,
        SBQQ__FilterField__c        = 'SBQQ__SegmentIndex__c',
        SBQQ__FilterOperator__c     = 'equals',
        SBQQ__KeepTogether__c       = 'Auto',
        SBQQ__KeepWithNext__c       = 'Auto',
        SBQQ__ColumnHeaderHidden__c = false,
        SBQQ__QuoteTotalsPrinted__c = false
    ));
}

// DisplayOrder 35
if (!existingSectionNames.contains('Quote Lines - MDQ')) {
    toInsert.add(new SBQQ__TemplateSection__c(
        Name                        = 'Quote Lines - MDQ',
        SBQQ__Template__c           = templateId,
        SBQQ__Content__c            = contentIdByName.get('Line Items - MDQ'),
        SBQQ__DisplayOrder__c       = 35,
        SBQQ__TopMargin__c          = 0,
        SBQQ__BottomMargin__c       = 0,
        SBQQ__KeepTogether__c       = 'Auto',
        SBQQ__KeepWithNext__c       = 'Auto',
        SBQQ__ColumnHeaderHidden__c = false,
        SBQQ__QuoteTotalsPrinted__c = true
    ));
}

// DisplayOrder 39
if (!existingSectionNames.contains('APJ Verbiage Section')) {
    toInsert.add(new SBQQ__TemplateSection__c(
        Name                           = 'APJ Verbiage Section',
        SBQQ__Template__c              = templateId,
        SBQQ__Content__c               = contentIdByName.get('APJ Sub Term Terms'),
        SBQQ__DisplayOrder__c          = 39,
        SBQQ__TopMargin__c             = 0,
        SBQQ__BottomMargin__c          = 0,
        SBQQ__ConditionalPrintField__c = 'ShowAPJVerbiage__c',
        SBQQ__KeepTogether__c          = 'Auto',
        SBQQ__KeepWithNext__c          = 'Auto',
        SBQQ__ColumnHeaderHidden__c    = false,
        SBQQ__QuoteTotalsPrinted__c    = false
    ));
}

// DisplayOrder 40
if (!existingSectionNames.contains('Shipping Details 1')) {
    toInsert.add(new SBQQ__TemplateSection__c(
        Name                           = 'Shipping Details 1',
        SBQQ__Template__c              = templateId,
        SBQQ__Content__c               = contentIdByName.get('Shipping 1'),
        SBQQ__DisplayOrder__c          = 40,
        SBQQ__TopMargin__c             = 0,
        SBQQ__BottomMargin__c          = 0,
        SBQQ__ConditionalPrintField__c = 'Show_Domestic_Shipping_for_US_Canada__c',
        SBQQ__KeepTogether__c          = 'Auto',
        SBQQ__KeepWithNext__c          = 'Auto',
        SBQQ__ColumnHeaderHidden__c    = false,
        SBQQ__QuoteTotalsPrinted__c    = false
    ));
}

// DisplayOrder 41
if (!existingSectionNames.contains('verbiage - Additional Month Added')) {
    toInsert.add(new SBQQ__TemplateSection__c(
        Name                           = 'verbiage - Additional Month Added',
        SBQQ__Template__c              = templateId,
        SBQQ__Content__c               = contentIdByName.get('verbiage - Additional Month Added'),
        SBQQ__DisplayOrder__c          = 41,
        SBQQ__TopMargin__c             = 0.25,
        SBQQ__BottomMargin__c          = 0,
        SBQQ__ConditionalPrintField__c = 'Additional_Month_added__c',
        SBQQ__KeepTogether__c          = 'Auto',
        SBQQ__KeepWithNext__c          = 'Auto',
        SBQQ__ColumnHeaderHidden__c    = false,
        SBQQ__QuoteTotalsPrinted__c    = false
    ));
}

// DisplayOrder 43
if (!existingSectionNames.contains('Proactive Promo Verbiage')) {
    toInsert.add(new SBQQ__TemplateSection__c(
        Name                           = 'Proactive Promo Verbiage',
        SBQQ__Template__c              = templateId,
        SBQQ__Content__c               = contentIdByName.get('Proactive Promo Term'),
        SBQQ__DisplayOrder__c          = 43,
        SBQQ__TopMargin__c             = 0,
        SBQQ__BottomMargin__c          = 0,
        SBQQ__ConditionalPrintField__c = 'ShowProactivePromoVerbiage__c',
        SBQQ__KeepTogether__c          = 'Auto',
        SBQQ__KeepWithNext__c          = 'Auto',
        SBQQ__ColumnHeaderHidden__c    = false,
        SBQQ__QuoteTotalsPrinted__c    = false
    ));
}

// DisplayOrder 45
if (!existingSectionNames.contains('Conditional PO Verbiage Sec')) {
    toInsert.add(new SBQQ__TemplateSection__c(
        Name                           = 'Conditional PO Verbiage Sec',
        SBQQ__Template__c              = templateId,
        SBQQ__Content__c               = contentIdByName.get('Conditional PO Verbiage content'),
        SBQQ__DisplayOrder__c          = 45,
        SBQQ__TopMargin__c             = 0,
        SBQQ__BottomMargin__c          = 0,
        SBQQ__ConditionalPrintField__c = 'Is_Conditional_PO__c',
        SBQQ__KeepTogether__c          = 'Auto',
        SBQQ__KeepWithNext__c          = 'Auto',
        SBQQ__ColumnHeaderHidden__c    = false,
        SBQQ__QuoteTotalsPrinted__c    = false
    ));
}

// DisplayOrder 60
if (!existingSectionNames.contains('Additional Terms Section')) {
    toInsert.add(new SBQQ__TemplateSection__c(
        Name                           = 'Additional Terms Section',
        SBQQ__Template__c              = templateId,
        SBQQ__Content__c               = contentIdByName.get('Additional Terms'),
        SBQQ__DisplayOrder__c          = 60,
        SBQQ__TopMargin__c             = 0,
        SBQQ__BottomMargin__c          = 0,
        SBQQ__ConditionalPrintField__c = 'Special_Requirements_Needed__c',
        SBQQ__KeepTogether__c          = 'Auto',
        SBQQ__KeepWithNext__c          = 'Auto',
        SBQQ__ColumnHeaderHidden__c    = false,
        SBQQ__QuoteTotalsPrinted__c    = false
    ));
}

// DisplayOrder 65
if (!existingSectionNames.contains('M365 DPC Terms & Condition - RS-GB-CR-MS-PE-PP')) {
    toInsert.add(new SBQQ__TemplateSection__c(
        Name                           = 'M365 DPC Terms & Condition - RS-GB-CR-MS-PE-PP',
        SBQQ__Template__c              = templateId,
        SBQQ__Content__c               = contentIdByName.get('M365 DPC Terms & Condition - RS-GB-CR-MS-PE-PP'),
        SBQQ__DisplayOrder__c          = 65,
        SBQQ__TopMargin__c             = 0,
        SBQQ__BottomMargin__c          = 0,
        SBQQ__ConditionalPrintField__c = 'Special_Requirements_Needed__c',
        SBQQ__KeepTogether__c          = 'Auto',
        SBQQ__KeepWithNext__c          = 'Auto',
        SBQQ__ColumnHeaderHidden__c    = false,
        SBQQ__QuoteTotalsPrinted__c    = false
    ));
}

// DisplayOrder 65
if (!existingSectionNames.contains('M365 DPC Terms & Condition - RS-GB-CR-MS-L3-PP')) {
    toInsert.add(new SBQQ__TemplateSection__c(
        Name                           = 'M365 DPC Terms & Condition - RS-GB-CR-MS-L3-PP',
        SBQQ__Template__c              = templateId,
        SBQQ__Content__c               = contentIdByName.get('M365 DPC Terms & Condition - RS-GB-CR-MS-L3-PP'),
        SBQQ__DisplayOrder__c          = 65,
        SBQQ__TopMargin__c             = 0,
        SBQQ__BottomMargin__c          = 0,
        SBQQ__ConditionalPrintField__c = 'Special_Requirements_Needed__c',
        SBQQ__KeepTogether__c          = 'Auto',
        SBQQ__KeepWithNext__c          = 'Auto',
        SBQQ__ColumnHeaderHidden__c    = false,
        SBQQ__QuoteTotalsPrinted__c    = false
    ));
}

// DisplayOrder 100
if (!existingSectionNames.contains('Addon Dependency Verbiage')) {
    toInsert.add(new SBQQ__TemplateSection__c(
        Name                        = 'Addon Dependency Verbiage',
        SBQQ__Template__c           = templateId,
        SBQQ__Content__c            = contentIdByName.get('Addon Verbiage'),
        SBQQ__DisplayOrder__c       = 100,
        SBQQ__TopMargin__c          = 0,
        SBQQ__BottomMargin__c       = 0,
        SBQQ__KeepTogether__c       = 'Auto',
        SBQQ__KeepWithNext__c       = 'Auto',
        SBQQ__ColumnHeaderHidden__c = false,
        SBQQ__QuoteTotalsPrinted__c = false
    ));
}

// DisplayOrder 110 — no linked content
if (!existingSectionNames.contains('NFR Doc Section')) {
    toInsert.add(new SBQQ__TemplateSection__c(
        Name                           = 'NFR Doc Section',
        SBQQ__Template__c              = templateId,
        SBQQ__Content__c               = null,
        SBQQ__DisplayOrder__c          = 110,
        SBQQ__TopMargin__c             = 0,
        SBQQ__BottomMargin__c          = 0,
        SBQQ__ConditionalPrintField__c = 'ShowNFROnePager__c',
        SBQQ__KeepTogether__c          = 'Auto',
        SBQQ__KeepWithNext__c          = 'Auto',
        SBQQ__ColumnHeaderHidden__c    = false,
        SBQQ__QuoteTotalsPrinted__c    = false
    ));
}

// DisplayOrder 118
if (!existingSectionNames.contains('NAS or UCL verbiage Section')) {
    toInsert.add(new SBQQ__TemplateSection__c(
        Name                           = 'NAS or UCL verbiage Section',
        SBQQ__Template__c              = templateId,
        SBQQ__Content__c               = contentIdByName.get('NAS or UCL verbiage'),
        SBQQ__DisplayOrder__c          = 118,
        SBQQ__TopMargin__c             = 0,
        SBQQ__BottomMargin__c          = 0,
        SBQQ__ConditionalPrintField__c = 'Check_RCV__c',
        SBQQ__KeepTogether__c          = 'Auto',
        SBQQ__KeepWithNext__c          = 'Auto',
        SBQQ__ColumnHeaderHidden__c    = false,
        SBQQ__QuoteTotalsPrinted__c    = false
    ));
}

// DisplayOrder 120
if (!existingSectionNames.contains('EULA Account Verbiage')) {
    toInsert.add(new SBQQ__TemplateSection__c(
        Name                        = 'EULA Account Verbiage',
        SBQQ__Template__c           = templateId,
        SBQQ__Content__c            = contentIdByName.get('EULA Account Verbiage'),
        SBQQ__DisplayOrder__c       = 120,
        SBQQ__TopMargin__c          = 0,
        SBQQ__BottomMargin__c       = 0,
        SBQQ__KeepTogether__c       = 'Auto',
        SBQQ__KeepWithNext__c       = 'Auto',
        SBQQ__ColumnHeaderHidden__c = false,
        SBQQ__QuoteTotalsPrinted__c = false
    ));
}

if (!toInsert.isEmpty()) {
    insert toInsert;
    System.debug('Done. Inserted ' + toInsert.size() + ' section(s) under template: ' + templateId);
} else {
    System.debug('Done. All 16 sections already exist under template: ' + templateId);
}
