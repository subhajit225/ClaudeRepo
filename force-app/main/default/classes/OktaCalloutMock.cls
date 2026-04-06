/**
 * @Author          : Vijay Kumar K R
 * @CreatedDate     : Mar 15, 2023 
 * @Description     : Mock class for CommunityTemplateControllerTest & OktaUserUtility
 * @TestClass       : CommunityTemplateControllerTest
 * -------------------------- @History -------------------------------------
 * Story Number       Modified By              Date           Description
 * CS21-1582          Vijay Kumar K R          Mar 15, 2023   CIAM: Multiple Customer Users with Same EmailId login to Support portal with different UserNames.  
 * -------------------------------------------------------------------------
 */
@isTest
global class OktaCalloutMock implements HttpCalloutMock{
    global HttpResponse respond(HttpRequest req){
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type','application/json');
        res.setStatusCode(200);
        // 1002: Create okta user
        if (String.valueOf(req.getEndpoint()).containsIgnoreCase('/users?activate')) {
            res.setBody('{\"id\":\"00u6m0y30cHs6NzLV1d7\",\"status\":\"STAGED\",\"created\":\"2023-01-31T09:13:12.000Z\",\"activated\":null,\"statusChanged\":null,\"lastLogin\":null,\"lastUpdated\":\"2023-01-31T09:13:12.000Z\",\"passwordChanged\":null,\"type\":{\"id\":\"oty6gp7ph7DMongG61d7\"},\"profile\":{\"firstName\":\"Donaldo\",\"lastName\":\"Trumpino\",\"sfdcCustomerPortalUsername\":\"customer.djt@example.com\",\"mobilePhone\":null,\"secondEmail\":null,\"login\":\"djt@example.com\",\"email\":\"customer.vijay.kr@rubrik.com\"},\"credentials\":{\"provider\":{\"type\":\"OKTA\",\"name\":\"OKTA\"}},\"_links\":{\"schema\":{\"href\":\"https://rubrik-ciam.oktapreview.com/api/v1/meta/schemas/user/osc6gp7ph7DMongG61d7\"},\"activate\":{\"href\":\"https://rubrik-ciam.oktapreview.com/api/v1/users/00u6upchk8BqHzkzD1d7/lifecycle/activate\",\"method\":\"POST\"},\"self\":{\"href\":\"https://rubrik-ciam.oktapreview.com/api/v1/users/00u6upchk8BqHzkzD1d7\"},\"resetFactors\":{\"href\":\"https://rubrik-ciam.oktapreview.com/api/v1/users/00u6upchk8BqHzkzD1d7/lifecycle/reset_factors\",\"method\":\"POST\"},\"type\":{\"href\":\"https://rubrik-ciam.oktapreview.com/api/v1/meta/types/user/oty6gp7ph7DMongG61d7\"}}}');
            return res;
        } 
        // 1003: Activate User and get activation token
        else if (String.valueOf(req.getEndpoint()).containsIgnoreCase('/lifecycle/activate?')) {
            res.setBody('{\"activationUrl\":\"https://rubrik-ciam.oktapreview.com/tokens/yZeXYIrlaqNgvTXp9DWQ/verify\",\"activationToken\":\"yZeXYIrlaqNgvTXp9DWQ\"}');
            return res;
        } 
        // 1005: Update Application Attributes for User
        else if (String.valueOf(req.getEndpoint()).containsIgnoreCase(OktaCalloutHandler.customerUserAppId)) {
            res.setBody('{\"id\":\"00u6m0y30cHs6NzLV1d7\",\"externalId\":null,\"created\":\"2023-01-18T10:57:49.000Z\",\"lastUpdated\":\"2023-01-18T11:13:52.000Z\",\"scope\":\"GROUP\",\"status\":\"ACTIVE\",\"statusChanged\":\"2023-01-18T10:57:49.000Z\",\"passwordChanged\":null,\"syncState\":\"DISABLED\",\"credentials\":{\"userName\":\"customer.bryanberger@killer.com\"},\"profile\":{\"lastName\":\"\",\"country\":\"UnitedStatesofAmerica\",\"role\":null,\"userLicense\":\"CustomerCommunity\",\"emailEncodingKey\":\"asda3\",\"latitude\":\"105\",\"postalCode\":\"005695\",\"title\":\"Manager\",\"terminationDate\":null,\"provisionType\":null,\"countryCode\":\"US\",\"street\":\"1122KingsRd,Moscow,Idaho\",\"contact\":\"9959758478\",\"alias\":\"BCK\",\"state\":\"Idaho\",\"department\":null,\"longitude\":\"161\",\"nickName\":\"BCK\",\"languageLocaleKey\":\"en\",\"adminPanelUser\":null,\"firstName\":\"\",\"phone\":null,\"profileId\":null,\"localeSidKey\":\"dsada\",\"name\":\"BryanKohberger\",\"geocodeAccuracy\":\"s\",\"stateCode\":\"ID\",\"timezoneSidKey\":\"dasda\"},\"_links\":{\"app\":{\"href\":\"https://rubrik-ciam.oktapreview.com/api/v1/apps/0oa6jgix0hRDb3LGC1d7\"},\"user\":{\"href\":\"https://rubrik-ciam.oktapreview.com/api/v1/users/00u6qbbomrACY1SL51d7\"},\"group\":{\"name\":\"customer-sfdc-dev\",\"href\":\"https://rubrik-ciam.oktapreview.com/api/v1/groups/00g6jgjcjw6pNV6ro1d7\"}}}');
            return res;
        } 
        // 1007: Deactivate User
        else if (String.valueOf(req.getEndpoint()).containsIgnoreCase('/lifecycle/deactivate?')
                // 1011: user suspend
                || String.valueOf(req.getEndpoint()).containsIgnoreCase('/lifecycle/suspend')
                // 1012: user unsuspend
                || String.valueOf(req.getEndpoint()).containsIgnoreCase('/lifecycle/unsuspend')) {
                    res.setBody('{}');
                    return res;
        } 
        // 1009: Reset Password from Admin Page
        else if (String.valueOf(req.getEndpoint()).containsIgnoreCase('/lifecycle/reset_password?')) {
            res.setBody('{\"resetPasswordUrl\":\"https://onepassport-dev.rubrik.com/reset_password/drp-qX3FAFQ6_XTGT0LE\"}');
            return res;
        } 
        // 1004: Update User profile with partial updates
        else if (String.valueOf(req.getEndpoint()).containsIgnoreCase('/users/')) {
            res.setBody('{\"id\":\"00u6m0y30cHs6NzLV1d7\",\"status\":\"ACTIVE\",\"created\":\"2023-01-11T10:40:32.000Z\",\"activated\":\"2023-01-11T10:40:33.000Z\",\"statusChanged\":\"2023-03-09T05:28:03.000Z\",\"lastLogin\":\"2023-03-14T09:28:30.000Z\",\"lastUpdated\":\"2023-03-14T10:26:04.000Z\",\"passwordChanged\":\"2023-03-09T05:28:03.000Z\",\"type\":{\"id\":\"oty6gp7ph7DMongG61d7\"},\"profile\":{\"firstName\":\"VijayKumar\",\"lastName\":\"KR\",\"sfdcCustomerPortalUsername\":\"okta.customer_User1@rbk.com\",\"mobilePhone\":null,\"secondEmail\":null,\"sfdcPartnerPortalUsername\":\"okta.customer_User1@rbk.com\",\"login\":\"customer.vijay.kr@rubrik.com\",\"email\":\"customer.vijay.kr@rubrik.com\"},\"credentials\":{\"password\":{},\"provider\":{\"type\":\"OKTA\",\"name\":\"OKTA\"}},\"_links\":{\"suspend\":{\"href\":\"https://onepassport-dev.rubrik.com/api/v1/users/00u6m0y30cHs6NzLV1d7/lifecycle/suspend\",\"method\":\"POST\"},\"schema\":{\"href\":\"https://onepassport-dev.rubrik.com/api/v1/meta/schemas/user/osc6gp7ph7DMongG61d7\"},\"resetPassword\":{\"href\":\"https://onepassport-dev.rubrik.com/api/v1/users/00u6m0y30cHs6NzLV1d7/lifecycle/reset_password\",\"method\":\"POST\"},\"forgotPassword\":{\"href\":\"https://onepassport-dev.rubrik.com/api/v1/users/00u6m0y30cHs6NzLV1d7/credentials/forgot_password\",\"method\":\"POST\"},\"expirePassword\":{\"href\":\"https://onepassport-dev.rubrik.com/api/v1/users/00u6m0y30cHs6NzLV1d7/lifecycle/expire_password\",\"method\":\"POST\"},\"changeRecoveryQuestion\":{\"href\":\"https://onepassport-dev.rubrik.com/api/v1/users/00u6m0y30cHs6NzLV1d7/credentials/change_recovery_question\",\"method\":\"POST\"},\"self\":{\"href\":\"https://onepassport-dev.rubrik.com/api/v1/users/00u6m0y30cHs6NzLV1d7\"},\"resetFactors\":{\"href\":\"https://onepassport-dev.rubrik.com/api/v1/users/00u6m0y30cHs6NzLV1d7/lifecycle/reset_factors\",\"method\":\"POST\"},\"type\":{\"href\":\"https://onepassport-dev.rubrik.com/api/v1/meta/types/user/oty6gp7ph7DMongG61d7\"},\"changePassword\":{\"href\":\"https://onepassport-dev.rubrik.com/api/v1/users/00u6m0y30cHs6NzLV1d7/credentials/change_password\",\"method\":\"POST\"},\"deactivate\":{\"href\":\"https://onepassport-dev.rubrik.com/api/v1/users/00u6m0y30cHs6NzLV1d7/lifecycle/deactivate\",\"method\":\"POST\"}}}');
            return res;
        } else {
            System.assert(false, 'unexpected endpoint ' + req.getEndpoint());
            return null;
        }
    }
}