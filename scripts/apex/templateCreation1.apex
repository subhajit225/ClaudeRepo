// =============================================================
// STEP 1 of 3 — Create TemplateContent records (batch 1 of 2)
// Source: rbkdev1 — Template "Quote Document" (a6R1W0000004UN3UAM)
// Run FIRST, then templateCreation2.apex, then templateCreation3.apex
//
// Creates 7 SBQQ__TemplateContent__c records:
//   1. Line Items - MDQ
//   2. Shipping 1
//   3. Additional Terms
//   4. Top Section 2
//   5. Line Items
//   6. APJ Sub Term Terms
//   7. Conditional PO Verbiage content
// =============================================================

Set<String> existingNames = new Set<String>();
for (SBQQ__TemplateContent__c ec : [
    SELECT Name FROM SBQQ__TemplateContent__c
    WHERE Name IN (
        'Line Items - MDQ',
        'Shipping 1',
        'Additional Terms',
        'Top Section 2',
        'Line Items',
        'APJ Sub Term Terms',
        'Conditional PO Verbiage content'
    )
]) {
    existingNames.add(ec.Name);
}

List<SBQQ__TemplateContent__c> toInsert = new List<SBQQ__TemplateContent__c>();

if (!existingNames.contains('Line Items - MDQ')) {
    toInsert.add(new SBQQ__TemplateContent__c(
        Name                = 'Line Items - MDQ',
        SBQQ__Type__c       = 'Line Items',
        SBQQ__FontSize__c   = 8,
        SBQQ__TableStyle__c = 'Price Dimensions as Rows with Summary'
    ));
}

if (!existingNames.contains('Shipping 1')) {
    toInsert.add(new SBQQ__TemplateContent__c(
        Name                = 'Shipping 1',
        SBQQ__Type__c       = 'HTML',
        SBQQ__FontSize__c   = 9,
        SBQQ__TableStyle__c = 'Standard',
        SBQQ__RawMarkup__c  = '<p>&#160;</p>\r\n\r\n<p>&#160;</p>\r\n\r\n<p><span style="font-family:helvetica,sans-serif;"><span style="font-size:9px;"><i>Any domestic US shipments handled by Rubrik will be charged a flat rate of $200 per appliance.</i></span></span></p>'
    ));
}

if (!existingNames.contains('Additional Terms')) {
    toInsert.add(new SBQQ__TemplateContent__c(
        Name                = 'Additional Terms',
        SBQQ__Type__c       = 'HTML',
        SBQQ__TableStyle__c = 'Standard',
        SBQQ__RawMarkup__c  = '<p>&#160;</p>\n\n<p>&#160;</p>\n\n<p><span style="font-size:9px;"><span style="font-family:helvetica,sans-serif;"><strong>Additional Terms:</strong></span></span></p>\n\n<p><span style="font-size:9px;"><span style="font-family:helvetica,sans-serif;">&#160;&#160;{!quote.Legal_Approved_Verbiage__c}</span></span></p>\n\n<p>&#160;</p>'
    ));
}

if (!existingNames.contains('Top Section 2')) {
    toInsert.add(new SBQQ__TemplateContent__c(
        Name                = 'Top Section 2',
        SBQQ__Type__c       = 'HTML',
        SBQQ__TableStyle__c = 'Standard',
        SBQQ__RawMarkup__c  = '<table width="100%">\r\n\t<tbody>\r\n\t\t<tr>\r\n\t\t\t<td>\r\n\t\t\t<p><span style="font-size: xx-small;">{!companyLogo}</span></p>\r\n\r\n\t\t\t<p>&#160;</p>\r\n\r\n\t\t\t<p>&#160;</p>\r\n\r\n\t\t\t<p>&#160;</p>\r\n\t\t\t</td>\r\n\t\t\t<td style="padding: 5px;">\r\n\t\t\t<p>&#160;</p>\r\n\r\n\t\t\t<table style="font-size: 9pt; margin-left: 34px;">\r\n\t\t\t\t<tbody>\r\n\t\t\t\t\t<tr>\r\n\t\t\t\t\t\t<td style="width: 150px; text-align: right;padding: 2px"><span style="font-size:10px;"><span style="font-family:helvetica,sans-serif;"><strong>Date:</strong></span></span></td>\r\n\t\t\t\t\t\t<td style="text-align: right;"><span style="font-size:10px;"><span style="font-family:helvetica,sans-serif;">{!quote.CreatedDate}</span></span></td>\r\n\t\t\t\t\t</tr>\r\n\t\t\t\t\t<tr>\r\n\t\t\t\t\t\t<td style="text-align: right;width: 150px;padding: 2px"><span style="font-size:10px;"><span style="font-family:helvetica,sans-serif;"><strong>Expires On:</strong></span></span></td>\r\n\t\t\t\t\t\t<td style="text-align: right;"><span style="font-size:10px;"><span style="font-family:helvetica,sans-serif;">{!quote.Expiration_Date__c}</span></span></td>\r\n\t\t\t\t\t</tr>\r\n\t\t\t\t\t<tr>\r\n\t\t\t\t\t\t<td style="text-align: right; width: 150px;padding: 2px"><span style="font-size:10px;"><span style="font-family:helvetica,sans-serif;"><strong>Quote #:</strong></span></span></td>\r\n\t\t\t\t\t\t<td style="text-align: right;"><span style="font-size:10px;"><span style="font-family:helvetica,sans-serif;">{!quote.Name}</span></span></td>\r\n\t\t\t\t\t</tr>\r\n\t\t\t\t\t<tr>\r\n\t\t\t\t\t\t<td style="text-align: right; width: 150px;padding: 2px"><span style="font-size:10px;"><span style="font-family:helvetica,sans-serif;"><strong>Payment Terms #:</strong></span></span></td>\r\n\t\t\t\t\t\t<td style="text-align: right;"><span style="font-size:10px;"><span style="font-family:helvetica,sans-serif;"><span style="text-align: right;">{!quote.SBQQ__PaymentTerms__c}</span></span></span></td>\r\n\t\t\t\t\t</tr>\r\n\t\t\t\t</tbody>\r\n\t\t\t</table>\r\n\t\t\t</td>\r\n\t\t</tr>\r\n\t</tbody>\r\n</table>\r\n\r\n<table width="100%">\r\n\t<tbody>\r\n\t\t<tr>\r\n\t\t\t<td><span style="font-size: x-small;">{!template.SBQQ__CompanyStreet__c}<br />\r\n\t\t\t{!template.SBQQ__CompanyCity__c}, {!template.SBQQ__CompanyState__c} {!template.SBQQ__CompanyPostalCode__c}</span>\r\n\r\n\t\t\t<p><span style="font-size: x-small;">{!template.SBQQ__CompanyPhone__c}<br />\r\n\t\t\t<span style="font-size: x-small;">{!quote.Quote_Template_Company_Email__c}</span></span></p>\r\n\t\t\t</td>\r\n\t\t\t<td><span style="font-size: x-small;">{!quote.SBQQ__BillingName__c}</span><br />\r\n\t\t\t<span style="font-size: x-small;">{!quote.SBQQ__BillingStreet__c}</span><br />\r\n\t\t\t<span style="font-size: x-small;">{!quote.SBQQ__BillingCity__c}, {!quote.SBQQ__BillingState__c} {!quote.SBQQ__BillingPostalCode__c}</span> <span style="font-size: x-small;">{!quote.SBQQ__BillingCountry__c}</span></td>\r\n\t\t</tr>\r\n\t</tbody>\r\n</table>\r\n\r\n<p>&#160;</p>\r\n\r\n<p><span style="font-size:small;"><strong>Pricing</strong> </span></p>'
    ));
}

if (!existingNames.contains('Line Items')) {
    toInsert.add(new SBQQ__TemplateContent__c(
        Name                = 'Line Items',
        SBQQ__Type__c       = 'Line Items',
        SBQQ__FontSize__c   = 8,
        SBQQ__TableStyle__c = 'Standard'
    ));
}

if (!existingNames.contains('APJ Sub Term Terms')) {
    toInsert.add(new SBQQ__TemplateContent__c(
        Name                = 'APJ Sub Term Terms',
        SBQQ__Type__c       = 'HTML',
        SBQQ__FontSize__c   = 9,
        SBQQ__TableStyle__c = 'Standard',
        SBQQ__RawMarkup__c  = '<div>&#160;</div>\n\n<div><span style="font-size:9px;"><span style="font-family:helvetica,sans-serif;">The support services term and the associated subscription term, if any, referenced above shall include an additional month at no charge if purchased in connection with a Rubrik appliance.&#160;<br />\nWhen issuing the PO to Rubrik, the authorized distributor shall include this additional month in the support services term&#160;and the associated subscription term, if any.</span></span></div>\n\n<div><span style="font-size:9px;"><span style="font-family:helvetica,sans-serif;">This does not apply to renewals.</span></span></div>'
    ));
}

if (!existingNames.contains('Conditional PO Verbiage content')) {
    toInsert.add(new SBQQ__TemplateContent__c(
        Name                = 'Conditional PO Verbiage content',
        SBQQ__Type__c       = 'HTML',
        SBQQ__TableStyle__c = 'Standard',
        SBQQ__RawMarkup__c  = '<p><span style="font-family:helvetica,sans-serif;"><span style="font-size:9px;"><em><span style="background-color: rgb(255, 255, 255);">Condition: Within {!quote.POC_duration__c} days of receipt of the Products, Customer will inspect and test the Products to confirm it meets the below Goals. If the Product meets the Goals, or if Customer fails to return or uninstall the Product as set forth in the applicable agreement, or if Customer otherwise elects to purchase the Products, the Products are deemed accepted. The Goals are as follows: (i) <strong>Ease of installation: </strong>Rubrik discovers all virtual machines (VMs) managed under VMware vCenter Server account specified by user and allows VMs to be protected with drag-and-drop functionality; (ii) <strong>Policy-based management: </strong>Rubrik automatically extracts snapshots of the protected VMs and manages these snapshots according to service level agreement (SLA) policies specified by Customer. Customer assigns protected VMs to specific SLA Domains based on desired snapshot capture frequency, retention duration, and data retention plan; (iii) <strong>Search and Recovery: </strong>Customer can search for specific snapshots and restart a VM instantaneously from any snapshot retained by Rubrik; (iv)<strong> Immediate Data Access: </strong>Customer can run Tier 2/3 workloads such as test/dev/analytics directly&#160;on the snapshots in Rubrik. To such workloads, Rubrik would behave just like any other storage array.</span></em></span></span></p>'
    ));
}

if (!toInsert.isEmpty()) {
    insert toInsert;
    System.debug('Inserted ' + toInsert.size() + ' content record(s). Proceed to templateCreation2.apex.');
} else {
    System.debug('All 7 content records already exist. Proceed to templateCreation2.apex.');
}
