@IsTest 
    public class CMAuthProviderTest { 
        
       
        private static final String OAUTH_TOKEN = 'testToken'; 
        private static final String STATE = 'mocktestState'; 
        private static final String PROVIDER = 'testProvider'; 
        private static final String REDIRECT_URL = 
        'https://rubrikinc--RBKDEV2.cs15.my.salesforce.com/services/authcallback/CompanyMaster'; 
        private static final String KEY = 'testkey'; 
        private static final String SECRET = 'testSecret'; 
        private static final String STATE_TO_PROPOGATE = 'testState'; 
        private static final String ACCESS_TOKEN_URL = 
        'https://apidev.rubrik.com/v1/oauth2/token'; 
        private static final String API_USER_VERSION_URL = 
        'https://rubrikinc--RBKDEV2.cs15.my.salesforce.com/services/auth/link/CompanyMaster'; 
        private static final String AUTH_URL = 
        'https://rubrikinc--RBKDEV2.cs15.my.salesforce.com/services/auth/oauth/CompanyMaster'; 
        private static final String API_USER_URL = 
        'https://rubrikinc--RBKDEV2.cs15.my.salesforce.com/services/auth/link/CompanyMaster'; 
    
   
    private static Map<String,String> setupAuthProviderConfig () 
    { 
        Map<String,String> authProviderConfiguration = new Map<String,String>(); 
        authProviderConfiguration.put('Key__c', KEY); 
        authProviderConfiguration.put('Auth_Url__c', AUTH_URL); 
        authProviderConfiguration.put('Secret__c', SECRET); 
        authProviderConfiguration.put('Access_Token_URL__c', ACCESS_TOKEN_URL); 
        authProviderConfiguration.put('API_User_Url__c',API_USER_URL); 
        authProviderConfiguration.put('API_User_Version_Url__c',
        API_USER_VERSION_URL); 
        authProviderConfiguration.put('Redirect_Url__c',REDIRECT_URL); 
        return authProviderConfiguration; 
    
    } 
    
    static testMethod void testInitiateMethod() 
    { 
        String stateToPropogate = 'mocktestState'; 
        Map<String,String> authProviderConfiguration = setupAuthProviderConfig(); 
        CMAuthProvider CMcls = new CMAuthProvider();   
        CMcls.getCustomMetadataType();
        PageReference actualUrl = CMcls.initiate(authProviderConfiguration, STATE_TO_PROPOGATE); 
        
    } 
    
    static testMethod void testHandleCallback() 
    { 
        Map<String,String> authProviderConfiguration = 
        setupAuthProviderConfig(); 
        CMAuthProvider CMcls = new CMAuthProvider(); 
       
    
        Test.setMock(HttpCalloutMock.class, new 
        CMMockHttpResponseGenerator()); 
    
        Map<String,String> queryParams = new Map<String,String>(); 
        queryParams.put('code','code'); 
        queryParams.put('state',authProviderConfiguration.get('State_c')); 
        Auth.AuthProviderCallbackState cbState = 
        new Auth.AuthProviderCallbackState(null,null,queryParams); 
        Auth.AuthProviderTokenResponse actualAuthProvResponse = 
        CMcls.handleCallback(authProviderConfiguration, cbState); 
        CMcls.refresh(authProviderConfiguration,'samlplerefreshtkn'); 
        
        Auth.AuthProviderTokenResponse response = 
        new Auth.AuthProviderTokenResponse(
        PROVIDER, OAUTH_TOKEN ,'sampleOauthSecret', STATE); 
        Auth.UserData actualUserData = CMcls.getUserInfo(
        authProviderConfiguration, response) ; 

    } 
    
     public class CMMockHttpResponseGenerator implements HttpCalloutMock 
    { 
        public HTTPResponse respond(HTTPRequest req) 
        { 
            // Create a fake response 
            HttpResponse res = new HttpResponse(); 
            res.setHeader('Content-Type', 'application/Json');
            Map<string,string> sampleres = new Map<string,string>{
            'access_token'=>'bar',
            'token_type'=>'Bearer',
            'expires_in'=>'723',
            'scope'=>'test',
            'error_description'=>'ed',
            'error'=>null,
            'errorCode'=>'200',
            'errorSummary'=>'test',
            'errorLink'=>'test.com',
            'errorId'=>'723' 
            } ;
            res.setBody(JSON.Serialize(sampleres)); 
            res.setStatusCode(200); 
            return res; 
        } 
    
    } 
    }