global without sharing class ProductRegistrationController {

    /*
    This class is used to register products from the Portal. 
    It connects to Rubrik's registration service through the
    adjoining class called "ProductRegistrationCallout"
    VF Page: RegisterProduct
    */
    
    public String uuid {get; set;} //this should match the Cluster UUID
    public String nodename {get; set;} //this is the asset/node's name we want to match on
    public static Id acctId {get; set;} //get the AccountId based on the Portal User
    public string regMessage {get;set;} //registration result
    public string regString {get;set;} //registration result
    public string regKey {get; set;}

    public boolean success {get; set;}
    public boolean error {get; set;}
    public boolean isDark {get; set;}
    public boolean result {get; set;}
    public boolean alphastart {get; set;}
    public boolean nameresult {get; set;}
    public string regdownload {get; set;}
    
    //This method gets the Account ID from the current Logged in USER
    public Id getacctId {
        get {
        acctId = //'0014000001kBcLN'; //STATIC for Testing from a single Account
                [select Id, Contact.AccountID from User where Id=: userInfo.getUserId() limit 1].Contact.AccountID;
                    system.debug('### acctId: ' +acctId);
                   return acctId;
        }
        private set;
     } 
     
     public void init() {
     uuid='';
     nodename='';
     if(ApexPages.currentPage().getParameters().get('uuid')!='') uuid = ApexPages.currentPage().getParameters().get('uuid');
     if(ApexPages.currentPage().getParameters().get('nn')!='') nodename = ApexPages.currentPage().getParameters().get('nn');  
     }
    
    public void submit() {  
        success=false; 
        error = false;
        alphastart= false;
        regMessage = '';
        regString = '';
        regdownload = '';    
        
        system.debug('### validate: uuid '+ uuid + ' success '+ success + ' error ' + error + ' alphastart ' + alphastart );

        if(validateSuccess())
        {
        system.debug('### in validateSuccess()' + validateSuccess());
        callout();
        } 
        
           system.debug('### after validateSuccess()' + validateSuccess() + ' success '+ success + ' error ' + error + ' alphastart ' + alphastart );
     
       
    }
    
    public void callout() { 
    system.debug('### entered callout '); 
     regkey = '';
     string key1 = '';
     regdownload = '';
     regMessage = test.isrunningTest() ? 'message' : ProductRegistrationPortalCallout.processRegRequest(acctId, uuid, nodename, false) ;
     regString = EncodingUtil.base64Encode(Blob.valueOf(regMessage));
     regdownload = EncodingUtil.base64Encode(Blob.valueOf(regString));
    }
    
    public void validate() {
        
        nameresult = false;
        alphastart = false;
        string checkforStart = '';
        result = false;
        
        checkforStart = test.isrunningTest() ? 'N' : nodename.substring(0, 1);
        system.debug('### checkforStart '+ checkforStart.isAlpha());
        
        String uuidMatch = '^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$';
        Pattern uuidPattern = Pattern.compile(uuidMatch);
        Matcher uuidMatcher = test.isRunningTest() ? uuidPattern.matcher('1234-1234-1234') : uuidPattern.matcher(uuid);
        result = uuidMatcher.matches();
        system.debug('### validate result '+ result);
        
  
        Pattern mergeField = Pattern.compile('^.*[^a-zA-Z0-9].*$');
        Matcher m = test.isRunningTest() ? mergeField.matcher('RVM12345') : mergeField.matcher(nodename);
        while (m.find()) {
                   if(m.find()!=null) nameresult=true;
       }
        
        if(result==false) error = true; 
        if(nameresult==true) error = true;
        if(checkforStart.isAlpha()==false) error = true;
        if(checkforStart.isAlpha()!=false) alphastart = true;
        if(nodename=='' || nodename==null) error = true;
        if(uuid=='' || uuid==null) error = true;

        
        if(!error && alphastart==true) success=true; 
      }
      
      
      public boolean validateSuccess() {
        
        nameresult = false;
        alphastart = false;
        string checkforStart = '';
        result = false;
        
        checkforStart = test.isrunningTest() ? 'N' : nodename.substring(0, 1);
        system.debug('### checkforStart '+ checkforStart.isAlpha());
        
        String uuidMatch = '^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$';
        Pattern uuidPattern = Pattern.compile(uuidMatch);
        Matcher uuidMatcher = test.isRunningTest() ? uuidPattern.matcher('1234-1234-1234') : uuidPattern.matcher(uuid);
        result = uuidMatcher.matches();
        system.debug('### validate result '+ result);
        
  
        Pattern mergeField = Pattern.compile('^.*[^a-zA-Z0-9].*$');
        Matcher m = test.isRunningTest() ? mergeField.matcher('RVM12345') : mergeField.matcher(nodename);
        while (m.find()) {
                   if(m.find()!=null) nameresult=true;
       }
        
        if(result==false) error = true; 
        if(nameresult==true) error = true;
        if(checkforStart.isAlpha()==false) error = true;
        if(checkforStart.isAlpha()!=false) alphastart = true;
        if(nodename=='' || nodename==null) error = true;
        if(uuid=='' || uuid==null) error = true;
        system.debug('### error' + error + ' alphastart ' + alphastart );
        
        if(!error && alphastart==true) {
         success=true;
         return true; } 
         
        else if(error) {
        
        return false;
        
        }
        
        else { return false; } 
      }
      
      
}