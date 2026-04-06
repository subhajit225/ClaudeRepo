/**
 * @description Controller for the "Send OVF" quick action on SBQQ__Quote__c.
 *              Provides methods to preview quote details and send the Order
 *              Verification Form email to the primary contact.
 * @author      Claude Code
 * @date        2026-03-27
 * @test        SendOvfEmailControllerTest
 */
public with sharing class SendOvfEmailController {

    /** OVF portal URL where the contact completes their Order Verification Form. */
    private static final String OVF_PORTAL_URL = Label.OVF_Portal_URL;

    /** Rubrik brand color used in the email template. */
    private static final String BRAND_COLOR = '#009dac';

    /**
     * @description Wrapper returned by getQuoteDetails containing quote preview data.
     */
    public class QuoteDetailsWrapper {
        @AuraEnabled public String quoteNumber;
        @AuraEnabled public String contactName;
        @AuraEnabled public String contactEmail;
        @AuraEnabled public List<QuoteLineItem> lineItems;

        /** The validated SBQQ__Quote__c record; not exposed to LWC. */
        public SBQQ__Quote__c quoteRecord;

        /** The queried quote line SObjects; not exposed to LWC. */
        public List<SBQQ__QuoteLine__c> quoteLineRecords;
    }

    /**
     * @description Wrapper for individual quote line items displayed in the preview
     *              and email body.
     */
    public class QuoteLineItem {
        @AuraEnabled public Id id;
        @AuraEnabled public String productName;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public Decimal listPrice;
        @AuraEnabled public Decimal netTotal;
    }

    /**
     * @description Shared helper that queries the quote, validates the primary
     *              contact and email, queries the quote lines, and populates a
     *              QuoteDetailsWrapper. Both getQuoteDetails and sendOvfEmail
     *              delegate to this method to eliminate duplicated SOQL and
     *              validation logic.
     * @param quoteId The Id of the SBQQ__Quote__c record
     * @return QuoteDetailsWrapper with quote, contact, and line-item data
     * @throws AuraHandledException if quoteId is null, quote not found, or
     *         primary contact / email is missing
     */
    @TestVisible
    private static QuoteDetailsWrapper fetchAndValidateQuote(Id quoteId) {
        if (quoteId == null) {
            throw new AuraHandledException('Quote Id is required.');
        }

        List<SBQQ__Quote__c> quotes = [
            SELECT Id,
                   Name,
                   Primary_Contact__c,
                   Primary_Contact__r.Name,
                   Primary_Contact__r.FirstName,
                   Primary_Contact__r.Email,
                   SBQQ__SalesRep__r.Name,
                   SBQQ__SalesRep__r.Email
            FROM SBQQ__Quote__c
            WHERE Id = :quoteId
            WITH USER_MODE
            LIMIT 1
        ];

        if (quotes.isEmpty()) {
            throw new AuraHandledException('Quote not found.');
        }

        SBQQ__Quote__c quote = quotes[0];

        if (quote.Primary_Contact__c == null) {
            throw new AuraHandledException(
                'This quote does not have a Primary Contact assigned. ' +
                'Please set a Primary Contact before sending the OVF email.'
            );
        }

        if (String.isBlank(quote.Primary_Contact__r.Email)) {
            throw new AuraHandledException(
                'The Primary Contact (' + quote.Primary_Contact__r.Name +
                ') does not have an email address. Please update the contact record.'
            );
        }

        List<SBQQ__QuoteLine__c> quoteLines = [
            SELECT Id,
                   SBQQ__Product__r.Name,
                   SBQQ__Quantity__c,
                   SBQQ__ListPrice__c,
                   SBQQ__NetTotal__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :quoteId
            WITH USER_MODE
            ORDER BY SBQQ__Number__c ASC
        ];

        QuoteDetailsWrapper wrapper = new QuoteDetailsWrapper();
        wrapper.quoteNumber = quote.Name;
        wrapper.contactName = quote.Primary_Contact__r.Name;
        wrapper.contactEmail = quote.Primary_Contact__r.Email;
        wrapper.quoteRecord = quote;
        wrapper.quoteLineRecords = quoteLines;
        wrapper.lineItems = new List<QuoteLineItem>();

        for (SBQQ__QuoteLine__c line : quoteLines) {
            QuoteLineItem item = new QuoteLineItem();
            item.id = line.Id;
            item.productName = line.SBQQ__Product__r.Name;
            item.quantity = line.SBQQ__Quantity__c;
            item.listPrice = line.SBQQ__ListPrice__c;
            item.netTotal = line.SBQQ__NetTotal__c;
            wrapper.lineItems.add(item);
        }

        return wrapper;
    }

    /**
     * @description Retrieves quote details including primary contact information
     *              and line items for the LWC preview screen.
     * @param quoteId The Id of the SBQQ__Quote__c record
     * @return QuoteDetailsWrapper containing quote number, contact info, and line items
     * @throws AuraHandledException if quoteId is null, quote not found, or
     *         primary contact / email is missing
     */
    @AuraEnabled(cacheable=false)
    public static QuoteDetailsWrapper getQuoteDetails(Id quoteId) {
        return fetchAndValidateQuote(quoteId);
    }

    /**
     * @description Sends a professional HTML email to the primary contact with
     *              OVF instructions, quote line items, a link to the portal,
     *              and the latest CPQ Quote Document PDF as an attachment (if available).
     * @param quoteId The Id of the SBQQ__Quote__c record
     * @param additionalEmails Optional list of additional email addresses to CC
     * @return Success message string
     * @throws AuraHandledException if validation fails or email send fails
     */
    @AuraEnabled(cacheable=false)
    public static String sendOvfEmail(Id quoteId, List<String> additionalEmails) {
        QuoteDetailsWrapper details = fetchAndValidateQuote(quoteId);
        SBQQ__Quote__c quote = details.quoteRecord;

        try {
            String firstName = String.isNotBlank(quote.Primary_Contact__r.FirstName)
                ? quote.Primary_Contact__r.FirstName
                : quote.Primary_Contact__r.Name;

            String htmlBody = buildEmailHtml(firstName, quote.Name, details.quoteLineRecords);
            String subject = 'Action Required: Complete Your Order Verification Form for Quote ' + quote.Name;

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{ quote.Primary_Contact__r.Email });

            if (additionalEmails != null && !additionalEmails.isEmpty()) {
                // Fix 2: Cap at 10 additional recipients
                if (additionalEmails.size() > 10) {
                    throw new AuraHandledException('A maximum of 10 additional recipients is allowed.');
                }

                // Fix 1: Sanitise + validate each address
                Pattern emailPattern = Pattern.compile('^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$');
                List<String> sanitisedEmails = new List<String>();
                List<String> invalidEmails = new List<String>();

                for (String addr : additionalEmails) {
                    // Strip control characters
                    String cleaned = addr.replaceAll('[\\n\\r\\t]', '');
                    if (!emailPattern.matcher(cleaned).matches()) {
                        invalidEmails.add(cleaned);
                    } else {
                        sanitisedEmails.add(cleaned);
                    }
                }

                if (!invalidEmails.isEmpty()) {
                    throw new AuraHandledException(
                        'Invalid email address(es): ' + String.join(invalidEmails, ', ')
                    );
                }

                email.setCcAddresses(sanitisedEmails);
            }

            email.setSubject(subject);
            email.setHtmlBody(htmlBody);
            email.setSaveAsActivity(false);
            email.setUseSignature(false);

            // Attach the latest CPQ Quote Document PDF if one exists
            Messaging.EmailFileAttachment pdfAttachment = getQuoteDocumentAttachment(quoteId);
            if (pdfAttachment != null) {
                email.setFileAttachments(new List<Messaging.EmailFileAttachment>{ pdfAttachment });
            }

            Messaging.SendEmailResult[] results = Messaging.sendEmail(
                new List<Messaging.SingleEmailMessage>{ email }, false
            );

            if (results[0].isSuccess()) {
                return 'SUCCESS';
            } else {
                String errorMsg = '';
                for (Messaging.SendEmailError err : results[0].getErrors()) {
                    errorMsg += err.getMessage() + ' ';
                }
                throw new AuraHandledException('Failed to send email: ' + errorMsg.trim());
            }
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception ex) {
            throw new AuraHandledException('An error occurred while sending the OVF email: ' + ex.getMessage());
        }
    }

    /**
     * @description Retrieves the latest PDF attachment from the related Opportunity
     *              as a Messaging.EmailFileAttachment. The CPQ Quote Document PDF is
     *              stored as a classic Attachment on the Opportunity record linked via
     *              SBQQ__Quote__c.SBQQ__Opportunity2__c.
     *              Returns null if the quote has no linked Opportunity, no PDF
     *              attachment exists, or the attachment Body is null — allowing the
     *              email to be sent without an attachment (graceful fallback).
     * @param quoteId The Id of the SBQQ__Quote__c record
     * @return Messaging.EmailFileAttachment containing the PDF, or null if not found
     */
    @TestVisible
    private static Messaging.EmailFileAttachment getQuoteDocumentAttachment(Id quoteId) {
        // Step 1: Query the Quote to get the related Opportunity Id
        List<SBQQ__Quote__c> quotes = [
            SELECT SBQQ__Opportunity2__c
            FROM SBQQ__Quote__c
            WHERE Id = :quoteId
            WITH USER_MODE
            LIMIT 1
        ];

        if (quotes.isEmpty() || quotes[0].SBQQ__Opportunity2__c == null) {
            return null;
        }

        Id opportunityId = quotes[0].SBQQ__Opportunity2__c;

        // Step 2: Query the latest PDF Attachment on the Opportunity
        List<Attachment> attachments = [
            SELECT Name, Body
            FROM Attachment
            WHERE ParentId = :opportunityId
              AND Name LIKE '%.pdf'
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (attachments.isEmpty() || attachments[0].Body == null) {
            return null;
        }

        // Step 3: Build and return the EmailFileAttachment
        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        efa.setFileName(attachments[0].Name);
        efa.setBody(attachments[0].Body);
        efa.setContentType('application/pdf');
        return efa;
    }

    /**
     * @description Builds the professional HTML email body with Rubrik branding,
     *              quote line items table, and CTA button.
     * @param contactFirstName The contact's first name for the greeting
     * @param quoteNumber The quote number to display
     * @param quoteLines The list of quote line items
     * @return Complete HTML string for the email body
     */
    @TestVisible
    private static String buildEmailHtml(
        String contactFirstName,
        String quoteNumber,
        List<SBQQ__QuoteLine__c> quoteLines
    ) {
        String html = '';

        // Email wrapper
        html += '<!DOCTYPE html>';
        html += '<html lang="en">';
        html += '<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"></head>';
        html += '<body style="margin:0;padding:0;background-color:#f4f6f9;font-family:Arial,Helvetica,sans-serif;">';

        // Outer container
        html += '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#f4f6f9;">';
        html += '<tr><td align="center" style="padding:30px 10px;">';

        // Inner content card
        html += '<table role="presentation" width="600" cellpadding="0" cellspacing="0" style="background-color:#ffffff;border-radius:8px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.08);">';

        // Header bar
        html += '<tr><td style="background-color:' + BRAND_COLOR + ';padding:28px 40px;">';
        html += '<h1 style="margin:0;color:#ffffff;font-size:22px;font-weight:700;letter-spacing:0.5px;">RUBRIK</h1>';
        html += '</td></tr>';

        // Body content
        html += '<tr><td style="padding:36px 40px 20px 40px;">';

        // Greeting
        html += '<p style="margin:0 0 20px 0;font-size:16px;color:#333333;line-height:1.6;">';
        html += 'Dear ' + String.valueOf(contactFirstName).escapeHtml4() + ',</p>';

        // Introduction
        html += '<p style="margin:0 0 20px 0;font-size:15px;color:#555555;line-height:1.6;">';
        html += 'Thank you for choosing Rubrik. To finalize your order, we need you to complete an ';
        html += '<strong>Order Verification Form (OVF)</strong> for the products listed below. ';
        html += 'The OVF ensures that your deployment details are accurately captured so we can ';
        html += 'provision your licenses without delay.</p>';

        // Quote number badge
        html += '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:0 0 24px 0;">';
        html += '<tr><td style="background-color:#f0fafb;border-left:4px solid ' + BRAND_COLOR + ';padding:14px 20px;border-radius:0 4px 4px 0;">';
        html += '<span style="font-size:13px;color:#777777;text-transform:uppercase;letter-spacing:1px;">Quote Number</span><br/>';
        html += '<span style="font-size:20px;color:' + BRAND_COLOR + ';font-weight:700;">' + String.valueOf(quoteNumber).escapeHtml4() + '</span>';
        html += '</td></tr></table>';

        // Line items heading
        html += '<p style="margin:0 0 12px 0;font-size:15px;color:#333333;font-weight:600;">Quoted Products:</p>';

        // Line items table
        html += '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border-collapse:collapse;margin:0 0 24px 0;">';
        html += '<tr style="background-color:' + BRAND_COLOR + ';">';
        html += '<th style="padding:10px 12px;color:#ffffff;font-size:13px;text-align:left;font-weight:600;">Product</th>';
        html += '<th style="padding:10px 12px;color:#ffffff;font-size:13px;text-align:center;font-weight:600;">Qty</th>';
        html += '<th style="padding:10px 12px;color:#ffffff;font-size:13px;text-align:right;font-weight:600;">List Price</th>';
        html += '<th style="padding:10px 12px;color:#ffffff;font-size:13px;text-align:right;font-weight:600;">Net Total</th>';
        html += '</tr>';

        if (quoteLines != null && !quoteLines.isEmpty()) {
            Integer rowIndex = 0;
            for (SBQQ__QuoteLine__c line : quoteLines) {
                String rowBg = Math.mod(rowIndex, 2) == 0 ? '#ffffff' : '#f9fafb';
                String productName = line.SBQQ__Product__r.Name != null
                    ? String.valueOf(line.SBQQ__Product__r.Name).escapeHtml4()
                    : '';
                String qty = line.SBQQ__Quantity__c != null
                    ? String.valueOf(line.SBQQ__Quantity__c.setScale(0).intValue())
                    : '-';
                String listPrice = line.SBQQ__ListPrice__c != null
                    ? formatCurrency(line.SBQQ__ListPrice__c)
                    : '-';
                String netTotal = line.SBQQ__NetTotal__c != null
                    ? formatCurrency(line.SBQQ__NetTotal__c)
                    : '-';

                html += '<tr style="background-color:' + rowBg + ';">';
                html += '<td style="padding:10px 12px;font-size:13px;color:#333333;border-bottom:1px solid #eef0f3;">' + productName + '</td>';
                html += '<td style="padding:10px 12px;font-size:13px;color:#333333;text-align:center;border-bottom:1px solid #eef0f3;">' + qty + '</td>';
                html += '<td style="padding:10px 12px;font-size:13px;color:#333333;text-align:right;border-bottom:1px solid #eef0f3;">' + listPrice + '</td>';
                html += '<td style="padding:10px 12px;font-size:13px;color:#333333;text-align:right;border-bottom:1px solid #eef0f3;">' + netTotal + '</td>';
                html += '</tr>';
                rowIndex++;
            }
        } else {
            html += '<tr><td colspan="4" style="padding:16px 12px;font-size:13px;color:#999999;text-align:center;border-bottom:1px solid #eef0f3;">';
            html += 'No line items found for this quote.</td></tr>';
        }

        html += '</table>';

        // Instructions
        html += '<p style="margin:0 0 24px 0;font-size:15px;color:#555555;line-height:1.6;">';
        html += 'Please click the button below to access the Order Verification Form. ';
        html += 'You will need your <strong>Quote Number</strong> and your <strong>email address</strong> ';
        html += 'to verify your identity on the portal.</p>';

        // CTA Button
        html += '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:0 0 28px 0;">';
        html += '<tr><td align="center">';
        html += '<a href="' + OVF_PORTAL_URL + '" target="_blank" ';
        html += 'style="display:inline-block;background-color:' + BRAND_COLOR + ';color:#ffffff;';
        html += 'font-size:16px;font-weight:600;text-decoration:none;padding:14px 36px;';
        html += 'border-radius:6px;letter-spacing:0.5px;">Complete Order Verification Form</a>';
        html += '</td></tr></table>';

        // Closing
        html += '<p style="margin:0 0 8px 0;font-size:15px;color:#555555;line-height:1.6;">';
        html += 'If you have any questions or need assistance, please do not hesitate to reach out to your Rubrik account team.</p>';
        html += '<p style="margin:0 0 4px 0;font-size:15px;color:#333333;">Best regards,</p>';
        html += '<p style="margin:0;font-size:15px;color:' + BRAND_COLOR + ';font-weight:600;">The Rubrik Team</p>';

        html += '</td></tr>';

        // Footer
        html += '<tr><td style="background-color:#f9fafb;padding:20px 40px;border-top:1px solid #eef0f3;">';
        html += '<p style="margin:0 0 4px 0;font-size:12px;color:#999999;text-align:center;">';
        html += 'Rubrik, Inc. | Securing the World\'s Data</p>';
        html += '<p style="margin:0;font-size:11px;color:#bbbbbb;text-align:center;">';
        html += 'This is an automated message. Please do not reply directly to this email.</p>';
        html += '</td></tr>';

        // Close tables
        html += '</table>';
        html += '</td></tr></table>';
        html += '</body></html>';

        return html;
    }

    /**
     * @description Formats a Decimal value as a USD currency string (e.g., "$1,234.56").
     * @param value The decimal value to format
     * @return Formatted currency string
     */
    @TestVisible
    private static String formatCurrency(Decimal value) {
        if (value == null) {
            return '-';
        }
        // Round to 2 decimal places
        Decimal rounded = value.setScale(2, RoundingMode.HALF_UP);
        String raw = String.valueOf(rounded);

        // Split into integer and decimal parts
        List<String> parts = raw.split('\\.');
        String intPart = parts[0];
        String decPart = parts.size() > 1 ? parts[1] : '00';

        // Ensure 2 decimal places
        if (decPart.length() < 2) {
            decPart += '0';
        } else if (decPart.length() > 2) {
            decPart = decPart.substring(0, 2);
        }

        // Handle negative numbers
        Boolean isNegative = false;
        if (intPart.startsWith('-')) {
            isNegative = true;
            intPart = intPart.substring(1);
        }

        // Add thousand separators
        String formatted = '';
        Integer count = 0;
        for (Integer i = intPart.length() - 1; i >= 0; i--) {
            if (count > 0 && Math.mod(count, 3) == 0) {
                formatted = ',' + formatted;
            }
            formatted = intPart.substring(i, i + 1) + formatted;
            count++;
        }

        return (isNegative ? '-' : '') + '$' + formatted + '.' + decPart;
    }
}
