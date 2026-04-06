public with sharing class RubrikQuoteLookupController {

    public class OVFSubmitException extends Exception {}

    public class QuoteLookupResult {
        @AuraEnabled public String quoteUrl;
        @AuraEnabled public String quoteId;
        @AuraEnabled public String contactName;
        @AuraEnabled public String contactEmail;
        @AuraEnabled public String contactPhone;
        @AuraEnabled public String companyName;
        @AuraEnabled public String shippingAddress1;
        @AuraEnabled public String shippingAddress2;
        @AuraEnabled public String shippingCity;
        @AuraEnabled public String shippingState;
        @AuraEnabled public String shippingZipCode;
        @AuraEnabled public String shippingCountry;
        @AuraEnabled public String errorMessage;
    }

    /**
     * Looks up a quote by quote number and validates the contact email.
     * Called from the unauthenticated rubrikQuoteLookup LWC page.
     *
     * @param quoteNumber  The quote number entered by the visitor (e.g. Q-00001234)
     * @param email        The email address entered by the visitor
     * @return             QuoteLookupResult with a redirect URL, or null if not found
     */
    @RemoteAction
    public static QuoteLookupResult lookupQuoteVF(String quoteNumber, String email) {
        return lookupQuote(quoteNumber, email);
    }

    @AuraEnabled(cacheable=false)
    public static QuoteLookupResult lookupQuote(String quoteNumber, String email) {
        if (String.isBlank(quoteNumber) || String.isBlank(email)) {
            return null;
        }

        String sanitisedQuote = quoteNumber.trim();
        String sanitisedEmail = email.trim().toLowerCase();

        // All queries run through GuestQueryHelper (without sharing) because the VF page
        // is accessed by a Site guest user who has no sharing access to CPQ/Opportunity records.
        return new GuestQueryHelper().findQuote(sanitisedQuote, sanitisedEmail);
    }

    /**
     * Creates a new OVF__c record associated with the specified Quote.
     * Called from the RubrikQuotePortal Visualforce page after the user
     * completes the OVF form.
     *
     * @param quoteId             The Id of the SBQQ__Quote__c record
     * @param buyerName           Buyer (End User) Name
     * @param buyerBillingId      Buyer (End User) Billing ID
     * @param buyerTenantId       Buyer (End User) Tenant ID
     * @param resellerName        Reseller Name
     * @param marketplaceSellerId Marketplace Seller ID
     * @param companyName         Company Name
     * @param address1            Address Line 1
     * @param address2            Address Line 2
     * @param city                City
     * @param state               State
     * @param zipCode             Zip Code
     * @param country             Country
     * @param contactName         Contact Name
     * @param contactEmail        Contact Email
     * @param contactPhone        Contact Phone
     * @return                    The Id of the newly created OVF__c record
     */
    @RemoteAction
    public static String submitOVF(String quoteId, String buyerName,
            String buyerBillingId, String buyerTenantId, String resellerName,
            String marketplaceSellerId, String companyName, String address1,
            String address2, String city, String state, String zipCode,
            String country, String contactName, String contactEmail,
            String contactPhone) {

        if (String.isBlank(quoteId)) {
            throw new IllegalArgumentException('Quote Id is required to submit an OVF.');
        }

        // Truncate text inputs to 255 characters to prevent field-length exceptions
        buyerName = buyerName != null ? buyerName.abbreviate(255) : null;
        buyerBillingId = buyerBillingId != null ? buyerBillingId.abbreviate(255) : null;
        buyerTenantId = buyerTenantId != null ? buyerTenantId.abbreviate(255) : null;
        resellerName = resellerName != null ? resellerName.abbreviate(255) : null;
        marketplaceSellerId = marketplaceSellerId != null ? marketplaceSellerId.abbreviate(255) : null;
        companyName = companyName != null ? companyName.abbreviate(255) : null;
        address1 = address1 != null ? address1.abbreviate(255) : null;
        address2 = address2 != null ? address2.abbreviate(255) : null;
        city = city != null ? city.abbreviate(255) : null;
        state = state != null ? state.abbreviate(255) : null;
        zipCode = zipCode != null ? zipCode.abbreviate(255) : null;
        country = country != null ? country.abbreviate(255) : null;
        contactName = contactName != null ? contactName.abbreviate(255) : null;
        contactEmail = contactEmail != null ? contactEmail.abbreviate(255) : null;
        contactPhone = contactPhone != null ? contactPhone.abbreviate(255) : null;

        try {
            OVF__c ovfRecord = new OVF__c(
                Quote__c               = quoteId,
                Buyer_Name__c          = buyerName,
                Buyer_Billing_ID__c    = buyerBillingId,
                Buyer_Tenant_ID__c     = buyerTenantId,
                Reseller_Name__c       = resellerName,
                Marketplace_Seller_ID__c = marketplaceSellerId,
                Company_Name__c        = companyName,
                Address_1__c           = address1,
                Address_2__c           = address2,
                City__c                = city,
                State__c               = state,
                Zip_Code__c            = zipCode,
                Country__c             = country,
                Contact_Name__c        = contactName,
                Contact_Email__c       = contactEmail,
                Contact_Phone__c       = contactPhone
            );

            // DML runs through GuestDmlHelper (without sharing) because the Site
            // guest user has no sharing access to the SBQQ__Quote__c record referenced
            // by the Quote__c lookup, which causes INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY
            // when inserting in the outer with-sharing context.
            Database.SaveResult sr = new GuestDmlHelper().insertOvf(ovfRecord);
            if (sr.isSuccess()) {
                return sr.getId();
            } else {
                String errorMsg = '';
                for (Database.Error err : sr.getErrors()) {
                    errorMsg += err.getMessage() + ' ';
                }
                throw new OVFSubmitException(errorMsg.trim());
            }
        } catch (OVFSubmitException oe) {
            throw oe;
        } catch (Exception ex) {
            throw new OVFSubmitException('Failed to submit OVF: ' + ex.getMessage());
        }
    }

    /**
     * Runs without sharing so that the Site guest user can insert OVF__c records
     * that reference an SBQQ__Quote__c record they have no sharing access to.
     * Without this, the cross-reference lookup causes
     * INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY.
     */
    private without sharing class GuestDmlHelper {
        Database.SaveResult insertOvf(OVF__c record) {
            return Database.insert(record);
        }
    }

    /**
     * Runs without sharing so that the Site guest user can query CPQ and CRM records
     * that are not directly shared to them. This is intentional: the page is a public
     * portal and record access is gated by the quote-number + primary-contact-email check.
     */
    private without sharing class GuestQueryHelper {
        QuoteLookupResult findQuote(String quoteName, String email) {
            // Step 1: find the quote by name
            List<SBQQ__Quote__c> quotes = [
                SELECT Id, Name, SBQQ__Opportunity2__c, SBQQ__ExpirationDate__c,
                       SBQQ__Account__r.Name,
                       SBQQ__Account__r.ShippingStreet, SBQQ__Account__r.ShippingCity,
                       SBQQ__Account__r.ShippingState, SBQQ__Account__r.ShippingPostalCode,
                       SBQQ__Account__r.ShippingCountry
                FROM SBQQ__Quote__c
                WHERE Name = :quoteName
                LIMIT 1
            ];

            if (quotes.isEmpty()) {
                return null;
            }

            // Step 2: validate that the supplied email is a primary contact role on the opp
            List<OpportunityContactRole> ocrs = [
                SELECT Id, Contact.Name, Contact.Email, Contact.Phone
                FROM OpportunityContactRole
                WHERE OpportunityId = :quotes[0].SBQQ__Opportunity2__c
                  AND IsPrimary = true
                  AND Contact.Email = :email
                LIMIT 1
            ];

            if (ocrs.isEmpty()) {
                return null;
            }

            // Step 3: reject expired quotes (only after contact validation so we
            // don't reveal expiry information to someone who cannot prove ownership)
            if (quotes[0].SBQQ__ExpirationDate__c != null
                    && quotes[0].SBQQ__ExpirationDate__c < Date.today()) {
                QuoteLookupResult expired = new QuoteLookupResult();
                expired.errorMessage = 'This quote expired on '
                    + quotes[0].SBQQ__ExpirationDate__c.format()
                    + ' and is no longer available. Please contact your Rubrik account team.';
                return expired;
            }

            QuoteLookupResult result = new QuoteLookupResult();
            result.quoteUrl = '/quotes/' + quotes[0].Id;
            result.quoteId  = quotes[0].Id;
            result.contactName  = ocrs[0].Contact.Name;
            result.contactEmail = ocrs[0].Contact.Email;
            result.contactPhone = ocrs[0].Contact.Phone;
            result.companyName  = quotes[0].SBQQ__Account__r.Name;
            String street = quotes[0].SBQQ__Account__r.ShippingStreet;
            if (String.isNotBlank(street)) {
                List<String> lines = street.replaceAll('\\r', '').split('\n', 2);
                result.shippingAddress1 = lines[0].trim();
                result.shippingAddress2 = lines.size() > 1 ? lines[1].trim() : null;
            } else {
                result.shippingAddress1 = null;
                result.shippingAddress2 = null;
            }
            result.shippingCity    = quotes[0].SBQQ__Account__r.ShippingCity;
            result.shippingState   = quotes[0].SBQQ__Account__r.ShippingState;
            result.shippingZipCode = quotes[0].SBQQ__Account__r.ShippingPostalCode;
            result.shippingCountry = quotes[0].SBQQ__Account__r.ShippingCountry;
            return result;
        }
    }

    /**
     * Wrapper class representing a single field from an OVF__c Field Set.
     * Used to dynamically render form fields on the Visualforce page.
     */
    public class OVFFieldMember {
        @AuraEnabled public String fieldApiName { get; set; }
        @AuraEnabled public String label        { get; set; }
        @AuraEnabled public String fieldType    { get; set; }
        @AuraEnabled public Boolean isRequired  { get; set; }
        @AuraEnabled public Integer maxLength   { get; set; }
    }

    /**
     * Returns the API name of the currently active OVF Field Set.
     * Hardcoded for now; future iterations will add conditional logic.
     *
     * @return The Field Set API name
     */
    private static String getActiveFieldSetNameStatic() {
        return 'AWSOVFFieldSet';
    }

    public String getActiveFieldSetName() {
        return getActiveFieldSetNameStatic();
    }

    /**
     * Reads the active Field Set from the OVF__c schema and returns a list
     * of OVFFieldMember instances describing each field (API name, label,
     * data type, required flag, and max length).
     *
     * @return List of OVFFieldMember for each field in the active Field Set
     */
    private List<OVFFieldMember> cachedOvfFieldMembers;

    public List<OVFFieldMember> getOvfFieldSetMembers() {
        if (cachedOvfFieldMembers != null) { return cachedOvfFieldMembers; }
        List<OVFFieldMember> members = new List<OVFFieldMember>();
        String fieldSetName = getActiveFieldSetName();
        Schema.FieldSet fs = Schema.SObjectType.OVF__c.fieldSets.getMap().get(fieldSetName);
        if (fs == null) {
            return members;
        }
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.OVF__c.fields.getMap();
        for (Schema.FieldSetMember fsm : fs.getFields()) {
            OVFFieldMember m = new OVFFieldMember();
            m.fieldApiName = fsm.getFieldPath();
            m.label        = fsm.getLabel();
            m.isRequired   = fsm.getRequired() || fsm.getDbRequired();
            Schema.SObjectField sof = fieldMap.get(fsm.getFieldPath());
            if (sof == null) { continue; }
            Schema.DescribeFieldResult dfr = sof.getDescribe();
            m.fieldType  = dfr.getType().name().toLowerCase();
            m.maxLength  = dfr.getLength() > 0 ? dfr.getLength() : 255;
            members.add(m);
        }
        cachedOvfFieldMembers = members;
        return cachedOvfFieldMembers;
    }

    /**
     * Creates a new OVF__c record dynamically from a JSON map of field values.
     * Called from the RubrikQuotePortal Visualforce page when the OVF form is
     * rendered dynamically from a Field Set.
     *
     * @param quoteId          The Id of the SBQQ__Quote__c record
     * @param fieldValuesJson  JSON string mapping field API names to their values
     * @return                 The Id of the newly created OVF__c record
     */
    @RemoteAction
    public static String submitOVFDynamic(String quoteId, String fieldValuesJson) {
        if (String.isBlank(quoteId)) {
            throw new IllegalArgumentException('Quote Id is required to submit an OVF.');
        }

        Map<String, Object> fieldValues;
        try {
            fieldValues = (Map<String, Object>) JSON.deserializeUntyped(fieldValuesJson);
        } catch (Exception ex) {
            throw new OVFSubmitException('Invalid field values JSON: ' + ex.getMessage());
        }

        OVF__c ovfRecord = new OVF__c(Quote__c = quoteId);

        // Build an allowlist from the active field set — only fields declared
        // in the field set can be written by the guest user.
        Set<String> allowedFields = new Set<String>();
        Map<String, Integer> fieldMaxLengths = new Map<String, Integer>();
        Schema.FieldSet activeFs = Schema.SObjectType.OVF__c.fieldSets.getMap()
            .get(getActiveFieldSetNameStatic());
        if (activeFs != null) {
            for (Schema.FieldSetMember m : activeFs.getFields()) {
                String path = m.getFieldPath().toLowerCase();
                allowedFields.add(path);
                Schema.DescribeFieldResult dfr = Schema.SObjectType.OVF__c.fields.getMap()
                    .get(m.getFieldPath()).getDescribe();
                fieldMaxLengths.put(path, dfr.getLength() > 0 ? dfr.getLength() : 255);
            }
        }
        // Always exclude the server-trusted lookup, even if it appears in a field set by mistake.
        allowedFields.remove('quote__c');

        for (String apiName : fieldValues.keySet()) {
            if (!allowedFields.contains(apiName.toLowerCase())) {
                continue;
            }
            Integer maxLen = fieldMaxLengths.containsKey(apiName.toLowerCase())
                ? fieldMaxLengths.get(apiName.toLowerCase())
                : 255;
            String rawValue = fieldValues.get(apiName) != null
                ? String.valueOf(fieldValues.get(apiName)).abbreviate(maxLen)
                : null;
            ovfRecord.put(apiName, rawValue);
        }

        try {
            Database.SaveResult sr = new GuestDmlHelper().insertOvf(ovfRecord);
            if (sr.isSuccess()) {
                return sr.getId();
            } else {
                String errorMsg = '';
                for (Database.Error err : sr.getErrors()) {
                    errorMsg += err.getMessage() + ' ';
                }
                throw new OVFSubmitException(errorMsg.trim());
            }
        } catch (OVFSubmitException oe) {
            throw oe;
        } catch (Exception ex) {
            throw new OVFSubmitException('Failed to submit OVF: ' + ex.getMessage());
        }
    }
}
