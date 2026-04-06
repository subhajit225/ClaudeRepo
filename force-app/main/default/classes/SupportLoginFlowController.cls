public class SupportLoginFlowController {
    
    public string LoginErrorMessage {get;set;}
    public boolean showerror {get;set;}
     public boolean finishflow;
    public void Set(boolean finishflow)
    {
        this.finishflow = false;
    }
    public boolean getfinishflow()
    {
        return finishflow; 
    }
    public SupportLoginFlowController(){}

    public void SupportLoginFlowControllerAction(){
        finishflow=false;
        
        List<User> usrList = new List<User>();
        usrList = [SELECT Id FROM User 
                    WHERE isActive = true
                    AND Email =: userinfo.getUserEmail()
                    AND UserType = 'CspLitePortal'];
        if(usrList.size() > 1){
            showerror=false;
            finishflow=true;
        }else{
            List<user> userList=[SELECT id,FirstName,lastName,email,phone,title,isActive,Contact.AccountId,ContactId, Daily_Subscription__c FROM User WHERE id=:userinfo.getUserId() ];
            if(!userList.isEmpty()){
                User u = userList[0];
                LoginErrorMessage = AccountServiceController.checkService(u, true, 'Login');
                if(String.isBlank(LoginErrorMessage)){
                    showerror=false;
                    finishflow=true;
                }else{
                    showerror=true;
                }
            }
        }
        
    }

    public PageReference FinishLoginFlowHome() {
        //finish the login flow and send you the default homepage
        return Auth.SessionManagement.finishLoginFlow('/s');
    }
   
}