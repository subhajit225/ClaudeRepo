/** @description to update Account Attributes logic linked to Update Attribute button on Account
*/
public without sharing class UpdateAccountAttributesController {

    /**
     * @description search for Accounts
     * @param searchTerm
     * @return Account records
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> searchAccounts(String searchTerm) {
        List<Map<String, String>> accountResults = new List<Map<String, String>>();

        if (String.isBlank(searchTerm)) {
            return accountResults;
        }
        List<Account> accounts = new List<Account>();

        String searchKey = '%' + searchTerm + '%';
        if(searchTerm.contains('001')){
            accounts = [
                SELECT Id, Name
                FROM Account
                WHERE Id =:searchTerm
                LIMIT 10
            ];
        }else{
            accounts = [
                SELECT Id, Name
                FROM Account
                WHERE Name LIKE :searchKey
                LIMIT 10
            ];
        }
        

        for (Account acc : accounts) {
            Map<String, String> accountItem = new Map<String, String>();
            accountItem.put('label', acc.Name + ' - ' + acc.Id);
            accountItem.put('value', acc.Id);
            accountResults.add(accountItem);
        }

        return accountResults;
    }

    /**
     * @description get Industry Subcategory Picklist values
     * @param selectedIndustry
     * @return Industry Subcategory Picklist
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getIndustrySubcategoryPicklistValues(String selectedIndustry) {
        List<Map<String, String>> picklistValues = new List<Map<String, String>>();

        try {
            Schema.DescribeFieldResult fieldDescribe = Account.Industry_Subcategory__c.getDescribe();
            Schema.sObjectField controllingFieldToken = fieldDescribe.getController();

            if (controllingFieldToken != null && String.isNotBlank(selectedIndustry)) {
                // This is a dependent picklist - filter based on controlling value
                picklistValues = getDependentPicklistValues(fieldDescribe, controllingFieldToken, selectedIndustry);
            } else {
                // Not a dependent picklist or no controlling value selected - return all values
                List<Schema.PicklistEntry> picklistEntries = fieldDescribe.getPicklistValues();
                for (Schema.PicklistEntry entry : picklistEntries) {
                    if (entry.isActive()) {
                        Map<String, String> picklistItem = new Map<String, String>();
                        picklistItem.put('label', entry.getLabel());
                        picklistItem.put('value', entry.getValue());
                        picklistValues.add(picklistItem);
                    }
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error getting Industry_Subcategory__c picklist values: ' + e.getMessage());
        }

        return picklistValues;
    }

    /**
     * @description Get dependent picklist values filtered by controlling field value
     * Uses the validFor encoding to determine which values are valid
     * @param dependentField
     * @param controllingFieldToken
     * @param controllingValue
     * @return Dependent picklist values
     */
    private static List<Map<String, String>> getDependentPicklistValues(
        Schema.DescribeFieldResult dependentField,
        Schema.sObjectField controllingFieldToken,
        String controllingValue
    ) {
        List<Map<String, String>> picklistValues = new List<Map<String, String>>();

        try {
            Schema.DescribeFieldResult controllingField = controllingFieldToken.getDescribe();
            List<Schema.PicklistEntry> controllingEntries = controllingField.getPicklistValues();
            List<Schema.PicklistEntry> dependentEntries = dependentField.getPicklistValues();

            // Find the index of the controlling value
            Integer controllingIndex = -1;
            for (Integer i = 0; i < controllingEntries.size(); i++) {
                if (controllingEntries[i].getValue() == controllingValue && controllingEntries[i].isActive()) {
                    controllingIndex = i;
                    break;
                }
            }

            if (controllingIndex == -1) {
                System.debug(LoggingLevel.WARN, 'Controlling value not found: ' + controllingValue);
                return picklistValues;
            }

            // Get the dependent values that are valid for this controlling value
            for (Schema.PicklistEntry entry : dependentEntries) {
                if (entry.isActive()) {
                    // Check if this dependent value is valid for the controlling value
                    // We use JSON serialization as a workaround to access the validFor property
                    String entryJson = JSON.serialize(entry);
                    Map<String, Object> entryMap = (Map<String, Object>) JSON.deserializeUntyped(entryJson);

                    if (entryMap.containsKey('validFor') && entryMap.get('validFor') != null) {
                        String validForEncoded = String.valueOf(entryMap.get('validFor'));

                        if (isValidForControllingValue(validForEncoded, controllingIndex)) {
                            Map<String, String> picklistItem = new Map<String, String>();
                            picklistItem.put('label', entry.getLabel());
                            picklistItem.put('value', entry.getValue());
                            picklistValues.add(picklistItem);
                        }
                    } else {
                        // No validFor means it's valid for all controlling values
                        Map<String, String> picklistItem = new Map<String, String>();
                        picklistItem.put('label', entry.getLabel());
                        picklistItem.put('value', entry.getValue());
                        picklistValues.add(picklistItem);
                    }
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in getDependentPicklistValues: ' + e.getMessage());
        }

        return picklistValues;
    }

    /**
     * @description Check if a dependent picklist value is valid for a controlling value index
     * Decodes the base64-like validFor encoding
     * @param validForEncoded 
     * @param controllingIndex
     * @return valid value
     */
    private static Boolean isValidForControllingValue(String validForEncoded, Integer controllingIndex) {
        try {
            // Decode the validFor string (base64-like encoding)
            List<Integer> validForBytes = new List<Integer>();

            for (Integer i = 0; i < validForEncoded.length(); i++) {
                Integer charCode = validForEncoded.charAt(i);
                Integer decodedValue;

                if (charCode >= 65 && charCode <= 90) {
                    // A-Z
                    decodedValue = charCode - 65;
                } else if (charCode >= 97 && charCode <= 122) {
                    // a-z
                    decodedValue = charCode - 71;
                } else if (charCode >= 48 && charCode <= 57) {
                    // 0-9
                    decodedValue = charCode + 4;
                } else if (charCode == 43) {
                    // +
                    decodedValue = 62;
                } else if (charCode == 47) {
                    // /
                    decodedValue = 63;
                } else {
                    continue;
                }

                validForBytes.add(decodedValue);
            }

            // Check if the bit for the controlling index is set
            Integer byteIndex = controllingIndex / 6;
            Integer bitIndex = Math.mod(controllingIndex, 6);

            if (byteIndex >= validForBytes.size()) {
                return false;
            }

            Integer byteValue = validForBytes[byteIndex];
            Integer bitMask = 1 << (5 - bitIndex);

            return (byteValue & bitMask) != 0;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error decoding validFor: ' + e.getMessage());
            return false;
        }
    }

    /**
     * @description Get Industry Category picklist values
     * @return IndustryCategoryValues
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getIndustryCategoryValues() {
        List<Map<String, String>> categoryValues = new List<Map<String, String>>();

        // Get picklist values from the standard Industry field on Account
        // This is the controlling field for Industry_Subcategory__c dependent picklist
        Schema.DescribeFieldResult fieldDescribe = Account.Industry.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldDescribe.getPicklistValues();

        for (Schema.PicklistEntry entry : picklistEntries) {
            if (entry.isActive()) {
                Map<String, String> item = new Map<String, String>();
                item.put('label', entry.getLabel());
                item.put('value', entry.getValue());
                categoryValues.add(item);
            }
        }

        return categoryValues;
    }



    /**
     * @description Converts Map<Object, Object> to Map<String, Object>
     * @param objMap The map to convert
     * @return Converted map with String keys
     */
    private static Map<String, Object> convertMapToStringObject(Map<Object, Object> objMap) {
        Map<String, Object> result = new Map<String, Object>();
        if (objMap != null) {
            for (Object key : objMap.keySet()) {
                result.put(String.valueOf(key), objMap.get(key));
            }
        }
        return result;
    }

    /**
     * @description Submits account attributes form data
     * @param accountId The Account record ID
     * @param formData Map containing all form field values
     */
    @AuraEnabled
    public static void submitAccountAttributesForm(String accountId, Map<String, Object> formData) {
        	Set<Id> verifyAccIdSet = new Set<Id>();
            system.debug(LoggingLevel.DEBUG, '@@ formData '+formData);
            // Get logged-in user email
            String requestorEmail = UserInfo.getUserEmail();
            String requestId = + 'SFDC_'+Datetime.now().format('YYYYMMddHHmmssSS') ;
	
            // Extract form data
            if(formData != null){
                List<Object> selectedAttributesObj = (List<Object>) formData.get('selectedAttributes');
    
                List<String> selectedAttributes = new List<String>();
                if (selectedAttributesObj != null) {
                    for (Object attr : selectedAttributesObj) {
                        selectedAttributes.add(String.valueOf(attr));
                    }
                }
    
                Map<String, Object> websiteData = convertMapToStringObject((Map<Object, Object>) formData.get('website'));
    
                Map<String, Object> hierarchyData = convertMapToStringObject((Map<Object, Object>) formData.get('hierarchy'));
    
                Map<String, Object> fortuneForbesData = convertMapToStringObject((Map<Object, Object>) formData.get('fortuneForbes'));
    
                Map<String, Object> accountAttributesData = convertMapToStringObject((Map<Object, Object>) formData.get('accountAttributes'));
    
                // Build website section
                Map<String, Object> websiteSection = new Map<String, Object>();
                if (websiteData != null) {
                    Boolean websiteFlag = websiteData.get('flag') != null ? Boolean.valueOf(websiteData.get('flag')) : false;
                    websiteSection.put('flag', websiteFlag);
                    websiteSection.put('url', websiteData.get('url') != null ? websiteData.get('url') : '');
                    websiteSection.put('sfTicket', websiteData.get('sfTicket') != null ? websiteData.get('sfTicket') : '');
                    websiteSection.put('approver', websiteData.get('approver') != null ? websiteData.get('approver') : '');
                }
    
                // Build hierarchy section
                Map<String, Object> hierarchySection = new Map<String, Object>();
                if (hierarchyData != null) {
                    Boolean hierarchyFlag = hierarchyData.get('flag') != null ? Boolean.valueOf(hierarchyData.get('flag')) : false;
                    hierarchySection.put('flag', hierarchyFlag);
                    hierarchySection.put('parentId', hierarchyData.get('parentId') != null ? hierarchyData.get('parentId') : '');
                    hierarchySection.put('globalparentId', hierarchyData.get('globalparentId') != null ? hierarchyData.get('globalparentId') : '');
                    hierarchySection.put('overrideDetails', hierarchyData.get('overrideDetails') != null ? hierarchyData.get('overrideDetails') : '');
                    hierarchySection.put('overrideRequestor', hierarchyData.get('overrideRequestor') != null ? hierarchyData.get('overrideRequestor') : '');
                    hierarchySection.put('overrideFlag','');
                    if(hierarchyFlag == true){
                        hierarchySection.put('overrideFlag', hierarchyData.get('overrideFlag') != null ? Boolean.valueOf(hierarchyData.get('overrideFlag')) : false);
                        try{
                            If(((Id)String.valueOf(hierarchyData.get('globalparentId'))).getSObjectType() == Account.SObjectType){
                                verifyAccIdSet.add((Id)String.valueOf(hierarchyData.get('globalparentId')));
                            }
                            If(((Id)String.valueOf(hierarchyData.get('parentId'))).getSObjectType() == Account.SObjectType){
                                verifyAccIdSet.add((Id)String.valueOf(hierarchyData.get('parentId')));
                            }
                        }catch(Exception e){
                            throw new AuraHandledException('Exception : ' + e.getMessage());
                        }
                        List<Account> accList = new List<Account>();
                        accList = [select Id from Account where Id IN: verifyAccIdSet];
                        if(accList.size() != verifyAccIdSet.size()){
                            throw new AuraHandledException('Error : enetred Parent Id or Global Parent Id are not part of the salesforce application');
                        }
                    }
                }
    
                // Build fortuneForbes section
                Map<String, Object> fortuneForbesSection = new Map<String, Object>();
                if (fortuneForbesData != null) {
                    Boolean fortuneForbesFlag = fortuneForbesData.get('flag') != null ? Boolean.valueOf(fortuneForbesData.get('flag')) : false;
                    fortuneForbesSection.put('flag', fortuneForbesFlag);
                    if(String.valueOf(fortuneForbesData.get('fortuneType')) == 'Fortune'){
                        fortuneForbesSection.put('fortuneRank', fortuneForbesData.get('fortuneRank') != null ? fortuneForbesData.get('fortuneRank') : '');
                        fortuneForbesSection.put('fortuneMainSub', fortuneForbesData.get('fortuneMainSub') != null ? fortuneForbesData.get('fortuneMainSub') : '');
                        fortuneForbesSection.put('forbesRank', '');
                        fortuneForbesSection.put('forbesMainSub', '');
                    }else{
                        fortuneForbesSection.put('fortuneRank', '');
                        fortuneForbesSection.put('fortuneMainSub', '');
                        fortuneForbesSection.put('forbesRank', fortuneForbesData.get('fortuneRank') != null ? fortuneForbesData.get('fortuneRank') : '');
                        fortuneForbesSection.put('forbesMainSub', fortuneForbesData.get('fortuneMainSub') != null ? fortuneForbesData.get('fortuneMainSub') : '');
                    }
                }
    
                // Build accountAttribute section
                Map<String, Object> accountAttributeSection = new Map<String, Object>();
                if (accountAttributesData != null) {
                    Boolean accountAttributeFlag = accountAttributesData.get('flag') != null ? Boolean.valueOf(accountAttributesData.get('flag')) : false;
                    accountAttributeSection.put('flag', accountAttributeFlag);
    
                    Map<String, Object> attributeOverrideValues = convertMapToStringObject((Map<Object, Object>) accountAttributesData.get('attributeOverrideValues'));
    
                    if (attributeOverrideValues != null) {
                        accountAttributeSection.put('siteRevenue', attributeOverrideValues.get('Annual Revenue') != null ? attributeOverrideValues.get('Annual Revenue') : '');
                        accountAttributeSection.put('siteRevenueSource', attributeOverrideValues.get('Override Source') != null ? attributeOverrideValues.get('Override Source') : '');
                        accountAttributeSection.put('guRevenue', attributeOverrideValues.get('GU Revenue') != null ? attributeOverrideValues.get('GU Revenue') : '');
                        accountAttributeSection.put('duns', attributeOverrideValues.get('DUNS') != null ? attributeOverrideValues.get('DUNS') : '');
                        accountAttributeSection.put('industryCategory', attributeOverrideValues.get('Industry Category') != null ? attributeOverrideValues.get('Industry Category') : '');
                        accountAttributeSection.put('industrySubcategory', attributeOverrideValues.get('Industry Subcategory') != null ? attributeOverrideValues.get('Industry Subcategory') : '');
                        accountAttributeSection.put('outofBusinessFlag', attributeOverrideValues.get('Out-of-Business Flag') != null ? attributeOverrideValues.get('Out-of-Business Flag') : '');
                        accountAttributeSection.put('sicCode', attributeOverrideValues.get('SIC Code') != null ? attributeOverrideValues.get('SIC Code') : '');
                        accountAttributeSection.put('tradestyle', attributeOverrideValues.get('Tradestyle') != null ? attributeOverrideValues.get('Tradestyle') : '');
                    }
                }
    
                // Build CMAccount object with proper key order
                Map<String, Object> cmAccount = new Map<String, Object>();
                cmAccount.put('sourceId', accountId);
                cmAccount.put('website', websiteSection);
                cmAccount.put('hierarchy', hierarchySection);
                cmAccount.put('fortuneForbes', fortuneForbesSection);
                cmAccount.put('accountAttribute', accountAttributeSection);
    
                // Build CMAccount array
                List<Map<String, Object>> cmAccountList = new List<Map<String, Object>>();
                cmAccountList.add(cmAccount);
    
                // Build the JSON structure with proper key order using manual JSON construction
                String cmAccountJson = JSON.serialize(cmAccountList);
                String jsonPayload = '{"accountOverride":{"requestId":"' + requestId + '","requestor":"' + requestorEmail + '","CMAccount":' + cmAccountJson + '}}';
    
            
                // POST the JSON payload to Company Master endpoint
                HttpResponse response = makeApiCallout('/account/attributeOverride', 'POST', jsonPayload, 'Company_Master');
    
                if (response.getStatusCode() >= 200 && response.getStatusCode() < 300) {
                    System.debug(LoggingLevel.DEBUG, 'API Response: ' + response.getBody());
    
                    // Parse API response and update Account based on response data
                    updateAccountFromResponse(accountId, response.getBody(), websiteData, hierarchyData, fortuneForbesData, accountAttributesData);
    
                } else {
                    // Insert error log on API failure
                    String errorMessage = 'Status Code: ' + response.getStatusCode() + ', Status: ' + response.getStatus() + ', Response: ' + response.getBody();
                    insertErrorLog(accountId, 'API_CALLOUT_FAILURE', errorMessage, jsonPayload);
                    throw new AuraHandledException('API Error: ' + response.getStatusCode() + ' ' + response.getStatus());
                }
            }
    }

    /**
     * @description Update Account record based on API response data
     * @param accountId The Account record ID
     * @param responseBody The API response body
     * @param websiteData Website section data from form (for flag checking)
     * @param hierarchyData Hierarchy section data from form (for flag checking)
     * @param fortuneForbesData Fortune/Forbes section data from form (for flag checking)
     * @param accountAttributesData Account attributes section data from form (for flag checking)
     */
    private static void updateAccountFromResponse(
        String accountId,
        String responseBody,
        Map<String, Object> websiteData,
        Map<String, Object> hierarchyData,
        Map<String, Object> fortuneForbesData,
        Map<String, Object> accountAttributesData
    ) {
        
        System.debug(LoggingLevel.DEBUG, 'Parsing API response: ' + responseBody);
        
        // Parse the response JSON
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        
        // Check if response has status
        Map<String, Object> statusMap = (Map<String, Object>) responseMap.get('status');
        if (statusMap != null) {
            Integer statusCode = Integer.valueOf(statusMap.get('statusCode'));
            String statusDescription = (String) statusMap.get('statusDescription');
            if(statusCode < 200 || statusCode > 300){
                throw new AuraHandledException('API Error: ' + statusCode+' - '+statusDescription);
            }
        }
        
        // Get accountOverride object from response
        Map<String, Object> accountOverride = (Map<String, Object>) responseMap.get('accountOverride');
        if (accountOverride == null) {
            throw new AuraHandledException('No accountOverride data in response');
        }
		try {
            // Get CMAccount array from accountOverride
            List<Object> cmAccountList = (List<Object>) accountOverride.get('CMAccount');
            if (cmAccountList == null || cmAccountList.isEmpty()) {
                throw new AuraHandledException('No CMAccount data in response');
            }

            // Get the first CMAccount object
            Map<String, Object> cmAccount = (Map<String, Object>) cmAccountList[0];

            // Update Account record with response data
            Account accountToUpdate = new Account(Id = accountId);

            // Extract response data sections
            Map<String, Object> websiteResponse = (Map<String, Object>) cmAccount.get('website');
            Map<String, Object> hierarchyResponse = (Map<String, Object>) cmAccount.get('hierarchy');
            Map<String, Object> fortuneForbesResponse = (Map<String, Object>) cmAccount.get('fortuneForbes');
            Map<String, Object> accountAttributeResponse = (Map<String, Object>) cmAccount.get('accountAttribute');

            // Update Website fields from response
            if (websiteResponse != null && websiteResponse.get('flag') != null && Boolean.valueOf(websiteResponse.get('flag')) == true) {
                String url = (String) websiteResponse.get('url');
                if (String.isNotBlank(url)) {
                    accountToUpdate.Website = url;
                }
            }

            // Update Hierarchy fields from response
            if (hierarchyResponse != null && hierarchyResponse.get('flag') != null && Boolean.valueOf(hierarchyResponse.get('flag')) == true) {
                String parentId = (String) hierarchyResponse.get('parentId');
                String globalParentId = (String) hierarchyResponse.get('globalparentId');
                String sfdcparentId = (String) hierarchyResponse.get('sfdcparentId');

                if (String.isNotBlank(parentId)) {
                    accountToUpdate.put('CM_PARENT_ID__c', parentId);
                }
                if (String.isNotBlank(globalParentId)) {
                    accountToUpdate.put('CM_GLOBAL_PARENT_ID__c', globalParentId);
                }
                accountToUpdate.put('ParentId', sfdcparentId);
                if(hierarchyResponse.get('overrideFlag') != null){
                	accountToUpdate.put('CM_Hierarchy_Overridden_Flag__c',Boolean.valueOf(hierarchyResponse.get('overrideFlag')));
                }
            }

            // Update Fortune/Forbes fields from response
            if (fortuneForbesResponse != null && fortuneForbesResponse.get('flag') != null && Boolean.valueOf(fortuneForbesResponse.get('flag')) == true) {
                String fortuneRankStr = (String) fortuneForbesResponse.get('fortuneRank');
                String forbesRankStr = (String) fortuneForbesResponse.get('forbesRank');
                String fortuneMainSub = (String) fortuneForbesResponse.get('fortuneMainSub');
                String forbesMainSub = (String) fortuneForbesResponse.get('forbesMainSub');

                if (String.isNotBlank(fortuneRankStr)) {
                    accountToUpdate.put('Fortune_500_Rank_2017__c', Decimal.valueOf(fortuneRankStr));
                }
                if (String.isNotBlank(fortuneMainSub)) {
                    accountToUpdate.put('Fortune_500_Main_Sub__c', fortuneMainSub);
                }
                if (String.isNotBlank(forbesRankStr)) {
                    accountToUpdate.put('Forbes_2000_Rank_2017__c', Decimal.valueOf(forbesRankStr));
                }
                if (String.isNotBlank(forbesMainSub)) {
                    accountToUpdate.put('Forbes_2000_Main_Sub__c', forbesMainSub);
                }
            }

            // Update Account Attributes fields from response
            if (accountAttributeResponse != null && accountAttributeResponse.get('flag') != null && Boolean.valueOf(accountAttributeResponse.get('flag')) == true) {
                // Site Revenue (Annual Revenue)
                String siteRevenue = (String) accountAttributeResponse.get('siteRevenue');
                if (String.isNotBlank(siteRevenue)) {
                    accountToUpdate.put('AnnualRevenue', Decimal.valueOf(siteRevenue));
                }

                // Site Revenue Source (Override Source)
                String siteRevenueSource = (String) accountAttributeResponse.get('siteRevenueSource');
                if (String.isNotBlank(siteRevenueSource)) {
                    accountToUpdate.put('Annual_Revenue_Source__c', siteRevenueSource);
                }

                // GU Revenue
                String guRevenue = (String) accountAttributeResponse.get('guRevenue');
                if (String.isNotBlank(guRevenue)) {
                    accountToUpdate.put('GU_Annual_Revenue__c', Decimal.valueOf(guRevenue));
                }

                // DUNS
                String duns = (String) accountAttributeResponse.get('duns');
                if (String.isNotBlank(duns)) {
                    accountToUpdate.put('D_U_N_S__c', duns);
                    accountToUpdate.put('GU_Duns_Number__c', duns);
                }

                // Industry Category
                String industryCategory = (String) accountAttributeResponse.get('industryCategory');
                if (String.isNotBlank(industryCategory)) {
                    accountToUpdate.put('Industry', industryCategory);
                }

                // Industry Subcategory
                String industrySubcategory = (String) accountAttributeResponse.get('industrySubcategory');
                if (String.isNotBlank(industrySubcategory)) {
                    accountToUpdate.put('Industry_Subcategory__c', industrySubcategory);
                }

                // Out of Business Flag
                String outofBusinessFlag = (String) accountAttributeResponse.get('outofBusinessFlag');
                if (String.isNotBlank(outofBusinessFlag)) {
                    Boolean isOutOfBusiness = outofBusinessFlag.equalsIgnoreCase('TRUE') || outofBusinessFlag.equalsIgnoreCase('Yes');
                    accountToUpdate.put('OUT_OF_BUSINESS__c', isOutOfBusiness);
                }

                // SIC Code
                String sicCode = (String) accountAttributeResponse.get('sicCode');
                if (String.isNotBlank(sicCode)) {
                    accountToUpdate.put('Duns_SIC2_code__c', sicCode);
                }

                // Tradestyle
                String tradestyle = (String) accountAttributeResponse.get('tradestyle');
                if (String.isNotBlank(tradestyle)) {
                    accountToUpdate.put('Tradestyle__c', tradestyle);
                }
            }

            // Update the Account record
            update accountToUpdate;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error updating account from response: ' + e.getMessage() + ' at line ' + e.getLineNumber());
            throw new AuraHandledException('Error updating account from response: ' + e.getMessage());
        }
    }

    /**
     * @description Inserts an error log record in Error_Logs__c object
     * @param accountId The Account record ID
     * @param errorType The type of error (e.g., 'API_CALLOUT_FAILURE')
     * @param errorMessage The detailed error message
     * @param requestPayload The request payload that caused the error
     */
    public static void insertErrorLog(String accountId, String errorType, String errorMessage, String requestPayload) {
        try {
            Error_Logs__c errorLog = new Error_Logs__c(Account__c = accountId,Error_Type__c = errorType,Error_Message__c = errorMessage,Object__c = requestPayload,Class__c = 'UpdateAccountAttributesController',Method__c = 'submitAccountAttributesForm',Type__c = 'Integration',Success__c = false,RecordId__c = accountId);
            insert errorLog;
            System.debug(LoggingLevel.DEBUG, 'Error log inserted successfully: ' + errorLog.Id);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error inserting error log: ' + e.getMessage());
        }
    }

    /**
     * @description Generic method to make REST API callouts using named credentials
     * @param endpoint The API endpoint path (e.g., '/company-master/accounts')
     * @param method The HTTP method (GET, POST, PUT, DELETE, PATCH)
     * @param body The request body (optional, for POST/PUT/PATCH)
     * @param namedCredential The named credential name (default: 'CompanyMaster')
     * @return HttpResponse The response from the API
     */
    public static HttpResponse makeApiCallout(String endpoint, String method, String body, String namedCredential) {
        try {

            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:Company_Master/account/attributeOverride');
            request.setMethod(method);
            request.setHeader('Content-Type', 'application/json');
            System.debug(LoggingLevel.DEBUG, 'request: ' + request);
            if (String.isNotBlank(body) && (method.equalsIgnoreCase('POST') || method.equalsIgnoreCase('PUT') || method.equalsIgnoreCase('PATCH'))) {
                request.setBody(body);
            }

            Http http = new Http();
            HttpResponse response = http.send(request);

            if (response.getStatusCode() < 200 || response.getStatusCode() >= 300) {
                System.debug(LoggingLevel.ERROR, 'API Error: ' + response.getStatusCode() + ' ' + response.getStatus());
                System.debug(LoggingLevel.ERROR, 'Response Body: ' + response.getBody());
                throw new AuraHandledException('API Callout Error: ' + response.getBody());
            }

            return response;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'API Callout Error: ' + e.getMessage());
            throw new AuraHandledException('API Callout Error: ' + e.getMessage());
        }
    }

}