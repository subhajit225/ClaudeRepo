/**
 * @Author      : Vijay Kumar K R
 * @CreatedDate : Mar 7, 2023 
 * @TstClass    : CommunityTemplateControllerTest
 * -------------------------- @History -------------------------------------
 * Story Number       Modified By              Date           Description
 * CS21-1206          Vijay Kumar K R          Mar 7, 2023     
 * -------------------------------------------------------------------------
 */
public without sharing class CommunityTemplateController {
    
    /**
        * ───────────────────────────────────────────────────────────────────────────────────────────────────┐
        * @description Okta Attributes Custom settings
        * ───────────────────────────────────────────────────────────────────────────────────────────────────
        * Method    getOktaAttributesCustomSettings
        * @param    
        * @return   Okta_Attributes__c
        * ───────────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    @AuraEnabled
    public static Okta_Attributes__c getOktaAttributesCustomSettings() {
        try {
            return Okta_Attributes__c.getInstance('Okta Attributes');
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
        * ───────────────────────────────────────────────────────────────────────────────────────────────────┐
        * @description fetching multiple active customer users 
        * ───────────────────────────────────────────────────────────────────────────────────────────────────
        * Method    fetchMultipleUsers
        * @param    
        * @return   List<User>
        * ───────────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    @AuraEnabled
    public static List<User> fetchMultipleUsers(){
        try {
            return [SELECT Id, Name, UserName, Email, Contact.Account.Name, Contact.Account.GTC__c
                    FROM User
                    WHERE Email =: UserInfo.getUserEmail()
                    AND ContactId != null
                    AND isActive = true
                    AND UserType = 'CspLitePortal'];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
        * ───────────────────────────────────────────────────────────────────────────────────────────────────┐
        * @description Update Selected Active Customer from Dropdown into Okta  
        * ───────────────────────────────────────────────────────────────────────────────────────────────────
        * Method    updateUserinOktaToAccessPortal
        * @param    String userName
        * @return   String
        * ───────────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    @AuraEnabled
    public static wrapper updateUserinOktaToAccessPortal(String userName){
        try {
            
            String userEmail = UserInfo.getUserEmail();

            // Fetching Okta UserId which is stored in Primary Support User which is Sync to Okta
            User objUser = [SELECT Id, Okta_UserId__c, Contact.Account.GTC__c
                                FROM User
                            WHERE Username =: userName
                            AND Okta_UserId__c != null 
                            AND ContactId != null
                            AND isActive = true
                            AND UserType = 'CspLitePortal' Limit 1];
            Set<String> userFieldSet = new Set<String>();
            Map<String, String> oktaFieldNameByCustomerFieldMap = new Map<String, String>();

            for(SF_Okta_Field_Mapping__mdt objMtd : SF_Okta_Field_Mapping__mdt.getAll().values()){
                // Customer Support Fields                                            
                if(objMtd.Common_Field__c 
                    || (!objMtd.isPartner_Field__c && !objMtd.Common_Field__c)){
                        if(!oktaFieldNameByCustomerFieldMap.containsKey(objMtd.SF_Field_API_Name__c)){
                            userFieldSet.add(objMtd.SF_Field_API_Name__c);
                            oktaFieldNameByCustomerFieldMap.put(objMtd.SF_Field_API_Name__c, objMtd.Okta_Field_API_Name__c);
                        }
                }
            }
            
            String userQueryString = 'SELECT UserType, Okta_UserId__c, '+ String.escapeSingleQuotes(String.join(new List<String>(userFieldSet), ', ')) + ' FROM ';
                    userQueryString += 'User WHERE UserName =\''+String.escapeSingleQuotes(userName)+'\' Limit 1';
            // Selected User details from dropdown options to access support portal
            List<User> portalLoginUser = Database.query(userQueryString);
            // Payload of 1004 to Update UserName into Okta sfdcCustomerPortalUsername field
            Map<String, Object> payload = new Map<String, Object>();
            Map<String, Object> portalUserMap = new Map<String, Object>();
            
            portalUserMap.put('sfdcCustomerPortalUsername', userName);
            payload.put('profile', portalUserMap);
            
            // 1004: Updating selected Username in Okta
            OktaCalloutSelector.UserData resJsonBody = OktaCalloutHandler.sendUserDetails(String.valueOf(objUser.Okta_UserId__c), JSON.serialize(payload), 'POST', '1004', 'CspLitePortal', 'API-1004: Multiple User Update App Failure', portalLoginUser[0].Id, false);
            if(resJsonBody.errorSummary == null){
                // 1005: Updating selected User details in Okta
                OktaUserUtility.updateAppAttributesByUserType(oktaFieldNameByCustomerFieldMap, portalLoginUser[0], String.valueOf(objUser.Okta_UserId__c), 'API-1005: Multiple User Update Attributes Failure');
            }
            // Returning SAML Url to create Current session for Selected UserName
            String SAML_URL = EncodingUtil.urlEncode(OktaCalloutHandler.SAML_URL + OktaCalloutHandler.customerUserAppId, 'UTF-8') + '/46';
            String GTCval = String.valueOf(objUser.Contact.Account.GTC__c);
            wrapper newWrap = new wrapper(SAML_URL, GTCval);
            return newWrap;
        } catch (Exception e) {
            System.debug('updateUserinOktaToAccessPortal error:: '+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public class wrapper {
        @AuraEnabled
        public string SAML_URL{get;set;}
        @AuraEnabled
        public string isGTC{get;set;}

        public wrapper(String SAML_URL, String isGTC) {
            this.SAML_URL=SAML_URL;
            this.isGTC=isGTC;
        }
    }
    
    /**
        * ───────────────────────────────────────────────────────────────────────────────────────────────────┐
        * @description Retur Error Message when Account has Expired Entitlement and Opportunity stage 7
        * ───────────────────────────────────────────────────────────────────────────────────────────────────
        * Method    checkForExpiredEntitlement
        * @param    String userName
        * @return   String
        * ───────────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    @AuraEnabled
    public static String checkForExpiredEntitlement(String userName){
    
        User objUser = [SELECT Id, FirstName, LastName, Email, Phone, Title, isActive, Contact.AccountId, ContactId, Daily_Subscription__c 
                        FROM User 
                        WHERE userName=: userName];
        return AccountServiceController.checkService(objUser, true, 'Multiple Support User Login');
    }
    
}