/**
* @Author      : (Gaurav Rawat) Partner Portal
* @CreatedDate : Jan 23, 2023 
* @TstClass    : OktaAdminRestPasswordFlowTest
* @Description :
* -------------------------- @History -------------------------------------
* Story Number       Modified By              Date           Description
* 
* -------------------------------------------------------------------------
*/
public class OktaAdminRestPasswordFlow {
    
    @InvocableMethod
    public static List<Response> oktapasswordEmail(List<Requests> requestLists){

        Okta_Attributes__c oktaParams = OktaCalloutSelector.getOktaAttributes();
        String SAML_URL = String.valueOf(oktaParams.get('PortalSAMLUrl__c'));
        String customerUserAppId = String.valueOf(oktaParams.get('Customer_User_AppId__c'));
        String portal ='';
        String partnerUserAppId = String.valueOf(oktaParams.get('Partner_User_AppId__c'));
        User userObj = requestLists[0].userRecord;
        List<User> userRecordList = new List<User>([SELECT Id, UserName, Okta_UserId__c, ProfileId, Email, Profile_Name__c, UserRoleId, UserType 
                                                    FROM USER 
                                                    WHERE Id =: userObj.id LIMIT 1]);
       
        OktaCalloutSelector.UserData resJsonBody = null;
        if(userRecordList[0].Okta_UserId__c != null){
            
            resJsonBody = OktaCalloutHandler.sendUserDetails(userRecordList[0].Okta_UserId__c, '', 'POST', '1009', userRecordList[0].UserType, 'apistatus', userRecordList[0].Id, false);
            System.debug('resJsonBody--->'+resJsonBody);
            List<Response> leadResult = new List<Response>();
            Response responseObj =  new Response();
            if(userRecordList[0].userType == 'PowerPartner'){
                portal = EncodingUtil.urlEncode(SAML_URL + partnerUserAppId, 'UTF-8') + '/46';
                responseObj.orgWideAdrs = 'GoForward@Rubrik.com';
                responseObj.portalName = 'Partner';
            }else if(userRecordList[0].userType == 'CspLitePortal'){
                portal = EncodingUtil.urlEncode(SAML_URL + customerUserAppId, 'UTF-8') + '/46';
                responseObj.orgWideAdrs = 'No Reply';
                responseObj.portalName = userRecordList[0].UserName;
            }
            responseObj.resetPassword = resJsonBody.resetPasswordUrl + '?fromURI=' + portal;
            leadResult.add(responseObj);
            return leadResult;
        }
        return null;
    }

    public class Requests{
        @InvocableVariable
        public User userRecord;
    }

    public class Response{
        @InvocableVariable
        public String resetPassword;
        @InvocableVariable
        public String orgWideAdrs;
        @InvocableVariable
        public String portalName;
    }
    
}