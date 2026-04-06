global with sharing class SiteLoginController {
    global String username {get; set;}
    global String password {get; set;}
    global string parentURL {get; set;}
    global  String headerdata {get;set;}
    global  string urlvalue {get;set;}
    global  string url {get;set;}
    global User userRecord{get;set;} //Added By Shadab
    global Boolean optIn {get;set;} //Added By Shadab
    global Boolean showlogin{get;set;} //Added By Shadab
    
    // Code we will invoke on page load.
        public PageReference forwardToCustomAuthPage() {
            if(UserInfo.getUserType() == 'Guest'){
            
                headerdata = ApexPages.currentPage().getHeaders().get('Host');
                urlvalue = Apexpages.currentPage().getUrl();
                url='https://' + headerdata+ urlvalue;
            
                return new PageReference('/customers/startURL?='+url);
            }
            else{
                return null;
            }
        }

    global PageReference login() {
       /* Added By SHADAB GDPR terms and Condition Check*/
        userRecord = [select id,contact.AccountId, Profile.Name from User where username=:username WITH SECURITY_ENFORCED];
        if(userRecord != null && userRecord.Profile.Name =='Rubrik Partner Community User')
        {   
            showlogin=false;return null;
        }
        else{ /*ends here Shadab*/
            parentUrl = System.currentPageReference().getParameters().get('startURL');
            String startUrl = System.currentPageReference().getParameters().get('startURL');//==null || System.currentPageReference().getParameters().get('startURL')=='' ? url : null ;
            
            return Site.login(username, password, parentUrl);
        }
    }
    /*Added New Method to validate the opt In checkbox - SHADAB*/
    global PageReference continueAfterOptInCheck() {
        
        if(!OptIn)
        {
            showlogin=true;
            return null;
        }
        else{
            parentUrl = System.currentPageReference().getParameters().get('startURL');
            String startUrl = System.currentPageReference().getParameters().get('startURL');//==null || System.currentPageReference().getParameters().get('startURL')=='' ? url : null ;
            PageReference  loginref=  Site.login(username, password, parentUrl+'?terms=true');
            return loginref;
        }
        
    }
    /*Ends Here Shadab*/
    global SiteLoginController () {
        showlogin =true;  //added one varibale initialisation
    }
}