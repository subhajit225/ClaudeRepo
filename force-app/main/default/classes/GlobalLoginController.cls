global with sharing class GlobalLoginController {

    public User portaluser {get; set;}
    public String username {get; set;}
    public String pw {get; set;}    
    public String portalid {get; set;}

    public PageReference go(){
        if(portaluser == null){         
            portaluser = [select Username, UserRoleId, UserType From User u where username =: username];         
        }
        // partner community here
        if(portaluser.UserType == 'PowerPartner') portalid = 'partners';
        // customer community here
        else portalid = 'customers';
        
        return null; 
    } 
}