/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Handler for OktaCalloutHandler
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author           : (Vijay Kumar K R)
* @created          : Jan 23, 2023 
* @modified       
* @systemLayer      : Handler for OktaCalloutHandler
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* 
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
**/
public without sharing class OktaCalloutSelector {
    
    public static List<Custom_Error_Log__c> errorLogList = new List<Custom_Error_Log__c>();
    public static Map<Id, User> updateUserMap = new Map<Id, User>();
    public static User userInstance = new User();
    
    public class OktaResponse {
        public UserData[] userData;
    }
    
    public class UserData {
        public String id {get;set;}
        public String status {get;set;}
        public Profile profile {get; set;}
        //ErrorClass
        public String errorCode {get;set;}
        public String errorSummary {get;set;}
        // public String errorLink {get;set;}
        //public String errorId {get;set;}
        // 1003: Activate User
        public String activationUrl {get;set;}
        public String resetPasswordUrl {get;set;}
        public String activationToken {get;set;}
        // 1004: State token
        public String stateToken {get;set;}
        // errorCause
        public List<errorCauses> errorCauses {get;set;}
    }
    
    public class Profile {
        public String email {get;set;}
        public String sfdcCustomerPortalUsername {get;set;}
        public String sfdcPartnerPortalUsername {get;set;}
    }

    public class errorCauses {
        public String errorSummary {get;set;}
    }
    
    /**
    * ───────────────────────────────────────────────────────────────────────────────────────────────────┐
    * @description fetch User record based on Current UserIds from Trigger.new 
    * ───────────────────────────────────────────────────────────────────────────────────────────────────
    * Method    getUserList
    * @param    Set<Id> userIdSet
    * @return   Map<Id, User>
    * ───────────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    public static Map<Id, User> getUserList(Set<Id> userIdSet){
        Set<String> userFieldSet = new Set<String>();
        for(SF_Okta_Field_Mapping__mdt objMtd : [SELECT SF_Field_API_Name__c, Okta_Field_API_Name__c 
                                                 FROM SF_Okta_Field_Mapping__mdt]){
                                                    userFieldSet.add(objMtd.SF_Field_API_Name__c);
                                                 }
                                                 
        String portalProfileFilter = 'UserType = \'CspLitePortal\' OR UserType = \'PowerPartner\'';
        String userQueryString = 'SELECT UserType, Okta_Flow_Status__c , Okta_UserId__c, API_Status__c, '+ String.escapeSingleQuotes(String.join(new List<String>(userFieldSet), ', ')) + ' FROM ';
        userQueryString += 'User WHERE ('+portalProfileFilter+') AND Id IN :userIdSet ';
        return new Map<Id, User>((List<User>)Database.query(userQueryString));
    }
    
    public static eixstingUserWrapper getExistingUser(Set<String> userEmailSet){

        Set<String> userFieldSet = new Set<String>();
        for(SF_Okta_Field_Mapping__mdt objMtd : [SELECT SF_Field_API_Name__c, Okta_Field_API_Name__c 
                                                 FROM SF_Okta_Field_Mapping__mdt]){
                                                     userFieldSet.add(objMtd.SF_Field_API_Name__c);
                                                 }
                                                 
        String portalProfileFilter = ' UserType = \'CspLitePortal\' OR UserType = \'PowerPartner\' ';
        String userQueryString = ' SELECT UserType, Okta_Flow_Status__c, Okta_UserId__c, API_Status__c, '+ String.escapeSingleQuotes(String.join(new List<String>(userFieldSet), ', ')) + ' FROM ';
        userQueryString += ' User WHERE Email IN :userEmailSet AND ('+portalProfileFilter+') Order By CreatedDate Desc ';

        List<User> existingUserList = Database.query(userQueryString);

        Map<String, User> allExistingPortalUserByEmailMap = new Map<String, User>(); 
        // Map<String, User> existingPartnerUserByEmailMap = new Map<String, User>(); 
        // Map<String, User> existingCustomerUserByEmailMap = new Map<String, User>(); 
        Map<String, List<User>> existingActiveUserByEmailMap = new Map<String, List<User>>(); 
        Map<String, List<User>> existingActiveOktaUserByEmailMap = new Map<String, List<User>>(); 
        Map<String, User> existingInActiveUserByEmailMap = new Map<String, User>(); 
        Map<String, List<User>> existingActiveSupportUserByEmailMap = new Map<String, List<User>>(); 

        for(User userObj : existingUserList){
            System.debug('Selector userObj>>>'+userObj);

            // All Portal sers: CU + PU both Active/InActive to get Okta User Id 
            if(String.isNotBlank(userObj.Okta_UserId__c)
                && !String.valueOf(userObj.Okta_UserId__c).containsIgnoreCase('N/A')
                && !String.valueOf(userObj.Okta_UserId__c).containsIgnoreCase('Undefined')){
                    if(!allExistingPortalUserByEmailMap.containsKey(userObj.Email)){
                        allExistingPortalUserByEmailMap.put(userObj.Email, userObj);
                    }
            }
            // Re-Activation Purpose: To make Okta User Re-Activated. 
            if(userObj.isActive){
                if(!existingActiveUserByEmailMap.containsKey(userObj.Email)){
                    existingActiveUserByEmailMap.put(userObj.Email, new List<User>());
                }
                existingActiveUserByEmailMap.get(userObj.Email).add(userObj);
            }
            // Re-Activation Purpose: Active Users with OktaUserId: it will fetch latest record which is Commited into DB
            if(userObj.isActive
                && userObj.Okta_UserId__c != null){
                    if(!existingActiveOktaUserByEmailMap.containsKey(userObj.Email)){
                        existingActiveOktaUserByEmailMap.put(userObj.Email, new List<User>());
                    }
                    existingActiveOktaUserByEmailMap.get(userObj.Email).add(userObj);
            }
            // Re-Activation Purpose: CIAM-99: InActive Portal Users
            if(!userObj.isActive 
                && !existingInActiveUserByEmailMap.containsKey(userObj.Email)){
                    existingInActiveUserByEmailMap.put(userObj.Email, userObj);
            }
            // Active Multiple Customer Users:  
            if(userObj.isActive 
                && userObj.UserType == 'CspLitePortal'){
                if(!existingActiveSupportUserByEmailMap.containsKey(userObj.Email)){
                    existingActiveSupportUserByEmailMap.put(userObj.Email, new List<User>());
                }
                existingActiveSupportUserByEmailMap.get(userObj.Email).add(userObj);
            }
            
        }
        System.debug('SLTR allExistingPortalUserByEmailMap>>>'+allExistingPortalUserByEmailMap);
        System.debug('SLTR existingActiveUserByEmailMap>>>'+existingActiveUserByEmailMap);
        System.debug('SLTR existingActiveOktaUserByEmailMap>>>'+existingActiveOktaUserByEmailMap);
        System.debug('SLTR existingInActiveUserByEmailMap>>>'+existingInActiveUserByEmailMap);
        System.debug('SLTR existingActiveSupportUserByEmailMap>>>'+existingActiveSupportUserByEmailMap);

        return new eixstingUserWrapper(allExistingPortalUserByEmailMap, existingActiveUserByEmailMap, existingActiveOktaUserByEmailMap,
                                        existingInActiveUserByEmailMap, existingActiveSupportUserByEmailMap);
    }

    public class eixstingUserWrapper{
        public Map<String, User> allExistingPortalUserByEmailMap {get;set;}   
        // public Map<String, User> existingPartnerUserByEmailMap {get;set;}   
        // public Map<String, User> existingCustomerUserByEmailMap {get;set;}  
        public Map<String, List<User>> existingActiveUserByEmailMap {get;set;}   
        public Map<String, List<User>> existingActiveOktaUserByEmailMap {get;set;}   
        public Map<String, User> existingInActiveUserByEmailMap {get;set;}   
        public Map<String, List<User>> existingActiveSupportUserByEmailMap {get;set;}   

        public eixstingUserWrapper(Map<String, User> allExistingPortalUserByEmailMap, Map<String, List<User>> existingActiveUserByEmailMap, 
                                        Map<String, List<User>> existingActiveOktaUserByEmailMap, 
                                        Map<String, User> existingInActiveUserByEmailMap, Map<String, List<User>> existingActiveSupportUserByEmailMap){
            this.allExistingPortalUserByEmailMap = allExistingPortalUserByEmailMap;
            // this.existingPartnerUserByEmailMap = existingPartnerUserByEmailMap;
            // this.existingCustomerUserByEmailMap = existingCustomerUserByEmailMap;
            this.existingActiveUserByEmailMap = existingActiveUserByEmailMap;
            this.existingActiveOktaUserByEmailMap = existingActiveOktaUserByEmailMap;
            this.existingInActiveUserByEmailMap = existingInActiveUserByEmailMap;
            this.existingActiveSupportUserByEmailMap = existingActiveSupportUserByEmailMap;
        }
    }

    /**
    * ───────────────────────────────────────────────────────────────────────────────────────────────────┐
    * @description fetch Okta Attributes Custom settings based on org instance
    * ───────────────────────────────────────────────────────────────────────────────────────────────────
    * Method    getOktaAttributes
    * @param    NA
    * @return   Okta_Attributes__c	
    * ───────────────────────────────────────────────────────────────────────────────────────────────────┘
    */
    public static Okta_Attributes__c getOktaAttributes(){
        Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        //sandbox instance
        if(isSandbox) {
            return Okta_Attributes__c.getInstance('Dev Okta Attributes');
        }
        //Production instance
        else {
            return Okta_Attributes__c.getInstance('Okta Attributes');
        }
    }
    
}