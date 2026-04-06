public class PC_IncentiveTileController {
    @auraEnabled
    public static List<Incentives__c> fetchIncentiveDetails(){
        List<User> userRecord = new List<User>();
        List<Incentives__c>incentiveList=new List<Incentives__c>();
        /** Querying Logged in User Information **/
        //ETM-8: Partner Portal objects Theatre values update: Replaced Account.Owner_s_Theatre__c to Theatre__c
        userRecord = [select id,contact.Account.type,AccountId,contact.Account.ETM_Area__c,contact.Theatre__c,contact.Account.ChannelProgramLevelName,contact.Account.ChannelProgramName,Contact.Primary_Role__c, name from User where Id =: userinfo.getUserId()];
        /** Querying Incentives based on Filters **/
        //ETM-8: Partner Portal objects Theatre values update: Replaced Account.Owner_s_Theatre__c to Theatre__c and Account_Owner_Theater__c to Theatre__c
       incentiveList=[SELECT id, Name, Theatre__c,Navigate_Url__c, Order__c,Channel_Program__c,Channel_Program__r.Name,Channel_Program_Level__c,Channel_Program_Level__r.Name,Claim_Visibility__c, Account_Name__c, Account_Name__r.type, Image_Url__c, Active__c, Partner_Type__c FROM Incentives__c WHERE 
                       ( ((Account_Name__c != NULL AND Account_Name__c =: userRecord[0].AccountId) OR Account_Name__c = NULL)
                        AND 
                        ((Partner_Type__c != NULL AND Partner_Type__c includes(:userRecord[0].contact.Account.type)) OR Partner_Type__c = NULL) 
                        AND 
                        ((Primary_role__c != NULL AND Primary_role__c includes(:userRecord[0].Contact.Primary_Role__c))OR Primary_role__c = NULL)
                        AND 
                        ((Theatre__c != NULL AND Theatre__c includes(:userRecord[0].contact.Theatre__c)) OR Theatre__c = NULL) 
                        AND
                        ( (Channel_Program_Level__r.Name!=NULL AND Channel_Program_Level__r.Name=:userRecord[0].contact.Account.ChannelProgramLevelName) OR(Channel_Program_Level__r.Name=NULL) )
                        AND 
                        ((Channel_Program__r.Name!=NULL AND Channel_Program__r.Name=:userRecord[0].contact.Account.ChannelProgramName)OR Channel_Program__r.Name=NULL)
                        AND 
                        ((Area__c!=NULL AND Area__c=:userRecord[0].contact.Account.ETM_Area__c)OR Area__c=NULL) 
                       ) 
                       AND Active__c=true order by Order__c  asc];
       return incentiveList;
       
        
    }
}