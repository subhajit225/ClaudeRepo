public class PC_TilesController {
    
    public static List<User> users {get;set;}
    
    @AuraEnabled
    public static List<Partner_Page_Configuration__c> getTiles(string pageName, string imageType){
        return getPageConfig(pageName, imageType);
    }
    @AuraEnabled
    public static List<Partner_Page_Configuration__c> getHelpLinks(string pageName, string imageType){
        return getPageConfig(pageName, imageType);
    }
    @AuraEnabled
    public static Partner_Page_Configuration__c getBanner(string pageName, string imageType){
        
        Partner_Page_Configuration__c banner = new Partner_Page_Configuration__c();
        List<Partner_Page_Configuration__c> lstTiles = new List<Partner_Page_Configuration__c>();
        
        lstTiles = getPageConfig(pageName, imageType);
        if(lstTiles.size() > 0){
            banner = lstTiles[0];
        }
        
        return banner;
    }
    
    public static List<Partner_Page_Configuration__c> getPageConfig(string pageName, string imageType){
        getUserInfo();
        system.debug('@@ in');
        string RPSP = 'NOT_RPSP';
        string RASP = 'NOT_RASP';
        
        if(users[0].Contact.Account.RPSP_Status__c == 'Approved'){
            RPSP = 'RPSP';
        }
        if(users[0].Contact.Account.RASP__C){
            RASP = 'RASP';
        } 
        
        
        List<Partner_Page_Configuration__c> lstTiles = new List<Partner_Page_Configuration__c>();
        //ETM-8: Partner Portal objects Theatre values update: Replaced Account.Owner_s_Theatre__c to Theatre__c and Account_Owner_Theater__c to Theatre__c.
        lstTiles=[SELECT Id, Name,Image_Text__c, Link_Type__c, Navigate_Url__c, Order__c, Image_Type__c,Image_Url__c,Static_Resource_Name__c, 
                  Mobile_Image_Url__c,Image_Height__c, Active__c, Partner_Type__c 
                  FROM Partner_Page_Configuration__c
                  WHERE (
                      (Account_Name__c = NULL Or Account_Name__c =: users[0].AccountId)
                      And (Partner_Type__c = NULL Or Partner_Type__c includes(:users[0].contact.Account.type))
                      And (Theatre__c = NULL Or Theatre__c includes(:users[0].Contact.Theatre__c))
                      And (Account_Specialization__c= NULL Or Account_Specialization__c includes(:RPSP) or Account_Specialization__c includes(:RASP))
                      And (Primary_role__c = NULL Or Primary_role__c includes(:users[0].Contact.Primary_Role__c))
                      And (Channel_Program__r.Name = NULL Or Channel_Program__r.Name=:users[0].contact.Account.ChannelProgramName)
                      And (Channel_Program_Level__r.Name = NULL Or Channel_Program_Level__r.Name=:users[0].contact.Account.ChannelProgramLevelName)
                      And (Area__c = NULL OR Area__c =:users[0].contact.Account.ETM_Area__c)
                  )
                  And Active__c = true And Image_Type__c =: imageType And Page_Name__c =:pageName
                  order by Order__c asc];
        system.debug('@@ lstTiles '+lstTiles);
        return lstTiles;
    }
    
    public static void getUserInfo(){
        //ETM-8: Partner Portal objects Theatre values update: Replaced Account.Owner_s_Theatre__c to Theatre__c
        users = [select Id,Name, AccountId, Contact.Primary_Role__c,Contact.Account.Type, Contact.Theatre__c,contact.Account.ETM_Area__c,
                 Contact.Account.ChannelProgramName,Contact.Account.ChannelProgramLevelName,Contact.Account.RPSP_Status__c,Contact.Account.RASP__c
                 from User where Id =: userinfo.getUserId()];        
    }
}