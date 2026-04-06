public class CMAuthProvider extends Auth.AuthProviderPluginClass{
    public static final String RESOURCE_CALLBACK = '/services/authcallback/';
    public static final String DEFAULT_TOKEN_TYPE = 'BearerToken';
    public static final String ENCODING_JSON = 'application/json';
    public static final String DUMMY_CODE = '999';
    public static final String CUSTOM_MDT_NAME = 'Custom_Auth_Provider__mdt'; 

    public static final String CMT_FIELD_CALLBACK_URL = 'Callback_URL__c';
    public static final String CMT_FIELD_PROVIDER_NAME = 'Auth_Provider_Name__c';
    public static final String CMT_FIELD_AUTHTOKEN_URL = 'Access_Token_URL__c';
    public static final String CMT_FIELD_CLIENT_ID = 'Client_Id__c';
    public static final String CMT_FIELD_CLIENT_SECRET = 'Client_Secret__c';
    public static final String CMT_FIELD_SCOPE = 'Scope__c';

    public static final String GRANT_TYPE_PARAM = 'grant_type';
    public static final String CLIENT_ID_PARAM = 'client_id';
    public static final String CLIENT_SECRET_PARAM = 'client_secret';
    public static final String SCOPE_PARAM = 'scope';
    public static final String GRANT_TYPE_CLIENT_CREDS = 'client_credentials'; 
    public static final String STATE = 'state';
    public static final String CODE = 'code';
    
    public String getCustomMetadataType() {
        return CUSTOM_MDT_NAME;
    }
    
    public PageReference initiate(Map<string,string> config, String stateToPropagate) {
        final PageReference pageRef = new PageReference(getCallbackUrl(config));
        pageRef.getParameters().put(STATE, stateToPropagate);
        pageRef.getParameters().put(CODE, DUMMY_CODE); 
        return pageRef;
    }
   
    private String getCallbackUrl(Map<string,string> config) {
        final String overrideUrl = config.get(CMT_FIELD_CALLBACK_URL);
        final String generatedUrl = URL.getSalesforceBaseUrl().toExternalForm() + RESOURCE_CALLBACK + config.get(CMT_FIELD_PROVIDER_NAME);
        return String.isEmpty(overrideUrl) ? generatedUrl : overrideUrl;
    }
   
    public Auth.AuthProviderTokenResponse handleCallback(Map<string,string> config, Auth.AuthProviderCallbackState state) {
        System.debug('handleCallbackconfig==> '+config);
        System.debug('state==>  '+state);
        final TokenResponse response = retrieveToken(config);
        if (response.isError()) {
            throw new TokenException(response.getErrorMessage());
        }
        return new Auth.AuthProviderTokenResponse(
            config.get(CMT_FIELD_PROVIDER_NAME),
            response.access_token,
            config.get(CMT_FIELD_CLIENT_SECRET),
            state.queryParameters.get('state')
        );
    }
   
    public override Auth.OAuthRefreshResult refresh(Map<String,String> config, String refreshToken) {
        System.debug('config==>    '+config);
        System.debug('refreshToken==>  '+refreshToken);
        final TokenResponse response = retrieveToken(config);
        System.debug('response==>  '+response);
        return new Auth.OAuthRefreshResult(response.access_token, response.token_type);
    }
    
    public Auth.UserData getUserInfo(Map<string,string> config, Auth.AuthProviderTokenResponse response) {
        return new Auth.UserData(null, null, null, null, null, null, 'client_credentials', null, config.get('Auth_Provider_Name__c'), null, new Map<String,String>()); 
    }
    
   
    private TokenResponse retrieveToken(Map<String,String> config) {  
        System.debug('config==>  '+config);
        final HttpRequest req = new HttpRequest();
        Map<string,string> authParams = new Map<string,string>();
        final PageReference endpoint = new PageReference(
            config.get(CMT_FIELD_AUTHTOKEN_URL)
        );
        
            /*endpoint.getParameters().put('grant_type',GRANT_TYPE_CLIENT_CREDS);
            endpoint.getParameters().put('client_id',config.get(CMT_FIELD_CLIENT_ID));
            endpoint.getParameters().put('client_secret',config.get(CMT_FIELD_CLIENT_SECRET));
            endpoint.getParameters().put('scope',config.get(CMT_FIELD_SCOPE)); */
       
       
        req.setEndpoint(endpoint.getUrl()); 
        req.setHeader('Content-Type',ENCODING_JSON); 
        authParams.put('grant_type',GRANT_TYPE_CLIENT_CREDS);
        authParams.put('client_id',config.get(CMT_FIELD_CLIENT_ID));
        authParams.put('client_secret',config.get(CMT_FIELD_CLIENT_SECRET));
        authParams.put('scope',config.get(CMT_FIELD_SCOPE));
        req.setBody(JSON.serialize(authParams));
        req.setMethod('POST'); 
        final HTTPResponse res = new Http().send(req); 
        System.debug('Endpoint==> '+req.getEndpoint());
        System.debug('responseStatus==>  ' +res.getStatus());
        System.debug('responseStatusCode==>  ' +res.getStatusCode());
        System.debug('responseBody==>    '+res.getBody());
        final Integer statusCode = res.getStatusCode();
        if ( statusCode == 200) {
            TokenResponse token =  deserializeToken(res.getBody());
            token.token_type = (token.token_type == null) ? DEFAULT_TOKEN_TYPE : token.token_type;
            return token;
    
        } else {
            return deserializeToken(res.getBody());
        }

    }
   
    public TokenResponse deserializeToken(String responseBody) {      
        TokenResponse parsedResponse = (TokenResponse) System.JSON.deserialize(responseBody, TokenResponse.class);
        System.debug('parsedResponse==>   ' + parsedResponse);
        return parsedResponse;
    }
    
   
  
    public class TokenResponse {
        // success scenario variables
        public String access_token {get;set;}
        public String token_type {get;set;}
        public String expires_in {get;set;}
        public String scope {get;set;}
        // error scenario variables
        public String error_description {get; set;}
        public String error {get; set;}
        public String errorCode {get; set;}
        public String errorSummary {get; set;}
        public String errorLink {get; set;}
        public String errorId {get; set;}
        public List<String> errorCauses {get;set;}
        public Boolean isError() {
            return error != null;
        }
        public String getErrorMessage() {
            if (error != null) {
                return errorCode;
            }
            return null;
        }
    }
  
    public class TokenException extends Exception {}
}