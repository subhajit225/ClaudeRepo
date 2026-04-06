/********************************************************************************************************
* Name              : JWT_Test
* Purpose           : JWT_Test is Used for Testing JWT Class
*********************************************************************************************************/
@isTest
public class JWT_Test{ 
    
     static testMethod void testIssueForHS256(){
        String BASE_URL = 'https://api.einstein.ai/v1';
        String OAUTH2 = BASE_URL + '/oauth2/token';
        
        JWT jwt = new JWT('HS256');
        jwt.iss = 'b';
        jwt.sub = 'c';
        jwt.aud = 'd';
        jwt.validFor = 10;
        jwt.cert = 'f';
        jwt.pkcs8 = 'g';
        jwt.privateKey = 'h';
        Map<String,String> claims1 =new Map<String,String>();
        claims1.put('Test1','Test2');
        jwt.claims=claims1;
        
        
        Test.startTest();
        try{
            jwt.issue();
        }catch(Exception exp){
            System.debug('Exception='+exp);
        }
        
        Test.stopTest();
    }

    static testMethod void testIssueForRS256(){
        String BASE_URL = 'https://api.einstein.ai/v1';
        String OAUTH2 = BASE_URL + '/oauth2/token';
        
        JWT jwt = new JWT('RS256');
        jwt.iss = 'b';
        jwt.sub = 'c';
        jwt.aud = 'd';
        jwt.validFor = 10;
        jwt.cert = 'f';
        jwt.pkcs8 = 'g';
        jwt.privateKey = 'h';
        Map<String,String> claims1 =new Map<String,String>();
        claims1.put('Test1','Test2');
        jwt.claims=claims1;
        
        
        Test.startTest();
        try{
            jwt.issue();
        }catch(Exception exp){
            System.debug('Exception='+exp);
        }
        
        Test.stopTest();
    }

    static testMethod void testIssueForNONE(){
        String BASE_URL = 'https://api.einstein.ai/v1';
        String OAUTH2 = BASE_URL + '/oauth2/token';
        
        JWT jwt = new JWT('NONE');
        jwt.iss = 'b';
        jwt.sub = 'c';
        jwt.aud = 'd';
        jwt.validFor = 10;
        jwt.cert = 'f';
        jwt.pkcs8 = 'g';
        jwt.privateKey = 'h';
        Map<String,String> claims1 =new Map<String,String>();
        claims1.put('Test1','Test2');
        jwt.claims=claims1;
        
        
        Test.startTest();
        try{
            jwt.issue();
        }catch(Exception exp){
            System.debug('Exception='+exp);
        }
        
        Test.stopTest();
    }
    
    static testMethod void testIssueForCertNull(){
        String BASE_URL = 'https://api.einstein.ai/v1';
        String OAUTH2 = BASE_URL + '/oauth2/token';
        
        JWT jwt = new JWT('RS256');
        jwt.iss = 'b';
        jwt.sub = 'c';
        jwt.aud = 'd';
        jwt.validFor = 10;
        jwt.pkcs8 = 'g';
        jwt.exp = 'g';
        jwt.cert  = null;
        jwt.iat = 'g';
        jwt.privateKey = 'h';
        Map<String,String> claims1 =new Map<String,String>();
        claims1.put('Test1','Test2');
        jwt.claims=claims1;
        
        
        Test.startTest();
        try{
            jwt.issue();
        }catch(Exception exp){
            System.debug('Exception='+exp);
        }
        
        Test.stopTest();
    }
}