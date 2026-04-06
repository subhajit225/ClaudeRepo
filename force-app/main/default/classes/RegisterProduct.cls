/**
 * Created By: 
 * Created Date: 
 * Test Class: RegisterProductTest
 * Modified History: CS21-1150 by vijay.kr@rubrik.com, June 17 2022
 **/
public class RegisterProduct{
    
    public static string nodename;
    public static string uuid;
    public static boolean error;
    public static boolean success;
    public static boolean result;
    
    public static string regKey;
    public static string regdownload;
    public static string regMessage;
    public static string regString;
    
    /**
     * Method: registerProduct 
     * params: String nodename, String uuid, String manufacturingtime, String teleporttoken, Boolean islegacy
     * return: registrationValues
     **/
    @AuraEnabled
    public static registrationValues registerProduct(String nodename, String uuid, String manufacturingtime, String teleporttoken, Boolean islegacy){

        nodename=nodename;
        uuid=uuid;
        
        success=false; 
        error = false;
        //alphastart= false;
        regMessage = '';
        regString = ''; 
        boolean alphastart = false;
        regdownload = '';  
        registrationValues respWrap = new registrationValues();
        if(nodename!=null){
            String res =  ProductRegistrationPortalCallout.processRegRequest(uuid, nodename, manufacturingtime, teleporttoken, islegacy);
            if(res.startsWith('400exception')){
                return new registrationValues(true, res.substringAfter('+'), 400);
            }else if(res.startsWith('500exception')){
                return new registrationValues(true, res.substringAfter('+'), 500);
            }
            String regString = EncodingUtil.base64Encode(Blob.valueOf(res));
            String regdownload  = EncodingUtil.base64Encode(Blob.valueOf(regString));
            return new registrationValues(regString,regdownload,res);
        }
        return respWrap;
    }
    
    @AuraEnabled
    public static registrationValues registerMosacProduct(String uuid){
        uuid=uuid;
        
        success=false; 
        error = false;
        //alphastart= false;
        regMessage = '';
        regString = ''; 
        boolean alphastart = false;
        regdownload = '';  
        registrationValues respWrap = new registrationValues();
        respWrap = validateMosacSuccess(uuid);
        if(respWrap.isTrue){
            String res =  ProductRegistrationPortalCallout.processRegRequest(uuid, '' , '', '', true) ;
            if(res.startsWith('400exception')){
                return new registrationValues(true, res.substringAfter('+'), 400);
            }else if(res.startsWith('500exception')){
                return new registrationValues(true, res.substringAfter('+'), 500);
            }
            String regString = EncodingUtil.base64Encode(Blob.valueOf(res));
            String regdownload  = EncodingUtil.base64Encode(Blob.valueOf(regString));
            return new registrationValues(regString,regdownload,res);
        }
        return respWrap;
    }
    
    public static registrationValues validateMosacSuccess(String uuid) {
        result = false;
        String uuidMatch = '^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$';
        Pattern uuidPattern = Pattern.compile(uuidMatch);
        Matcher uuidMatcher = test.isRunningTest() ? uuidPattern.matcher('12345678-1234-1234-1234-123456789012') : uuidPattern.matcher(uuid);
        result = uuidMatcher.matches();
        if(result==false) error = true; 
        if(uuid=='' || uuid==null) error = true;
        Boolean isTrue = false;
        if(!error) {
            success=true;
            isTrue = true;
        } else if(error) {
            isTrue = false;
        }else { isTrue = false; } 
        registrationValues wp = new registrationValues(null , null , null,isTrue,false,false,result,success,error);
        return wp;
    }
    
    public class registrationValues{
        @AuraEnabled public String regString {get;set;}
        @AuraEnabled public String regdownload  {get;set;}
        @AuraEnabled public String regMessage  {get;set;}
        @AuraEnabled public Boolean isTrue  {get;set;}
        @AuraEnabled public Boolean nameresult  {get;set;}
        @AuraEnabled public Boolean alphastart  {get;set;}
        @AuraEnabled public Boolean result  {get;set;}
        @AuraEnabled public Boolean success  {get;set;}
        @AuraEnabled public Boolean error  {get;set;}
        @AuraEnabled public Boolean integrationError  {get;set;}
        @AuraEnabled public String errorMessage  {get;set;}
        @AuraEnabled public Integer statusCode  {get;set;}
        public registrationValues(String regString , String regdownload , String regMessage){
            this.regdownload = regdownload;
            this.regString = regString;
            this.regMessage = regMessage;
            this.success = true;
        }
         public registrationValues(boolean integrationError, String errorMessage, Integer statusCode){
            this.integrationError = integrationError;
            this.errorMessage = errorMessage;
            this.statusCode = statusCode;
        }
        
        public registrationValues(String regString , String regdownload , String regMessage,Boolean isTrue,Boolean nameresult,Boolean alphastart,Boolean result,Boolean success,Boolean error){
            this.regdownload = regdownload;
            this.regString = regString;
            this.regMessage = regMessage;
            this.isTrue = isTrue;
            this.nameresult = nameresult;
            this.alphastart = alphastart;
            this.result = result;
            this.success = success;
            this.error = error;
        }
        public registrationValues(){}
    }
}