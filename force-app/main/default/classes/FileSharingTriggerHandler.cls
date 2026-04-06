public class FileSharingTriggerHandler {
 	public static string checkAccountSpecializationRPSP(User u){
         if(u.Contact.Account.RPSP_Status__c == 'Approved'){
             return 'RPSP';
         }
         return 'not matched';
    }
    public static string checkAccountSpecializationRASP(User u){
        if(u.Contact.Account.RASP__c){
            return 'RASP';
        } 
        return 'not matched';
    }
	public static List<File_Sharing__share> createShareRecords(string recordId, Set<Id> userIdset){
        List<File_Sharing__share> fsshareList = new List<File_Sharing__share>();
        for(string uId : userIdset){
            File_Sharing__share fsshare = new File_Sharing__share();
            fsshare.ParentId = recordId;
            fsshare.UserOrGroupId = uId;
            fsshare.AccessLevel = 'Read';
            fsshare.RowCause = Schema.File_Sharing__share.RowCause.Manual;
            fsshareList.add(fsshare);
        }
        return fsshareList;
    }
    public static void invokeApexSharing(List<File_Sharing__c> newList){
        List<User> userList = new List<User>();
        Map<Id,List<File_Sharing__share>> fileUserShareMap = new Map<Id,List<File_Sharing__share>>();
        Map<string,Set<Id>> fileUserMap = new Map<string,Set<Id>>();
        userList = [select Id,Name, AccountId,Contact.AccountId, Contact.Primary_Role__c,Contact.Account.Type, Contact.Theatre__c,contact.Account.ETM_Area__c,
                 Contact.Account.ChannelProgramName,Contact.Account.ChannelProgramLevelName,Contact.Account.RPSP_Status__c,Contact.Account.RASP__c
                 from User where isActive = true AND ContactId != null And Profile.UserLicense.Name='Partner Community']; 
        for(File_Sharing__c f : newList){
            for(user u : userList){
                if(f.Active__c
                   && (string.isBlank(f.Partner_Type__c) || (!string.isBlank(u.contact.Account.type) && f.Partner_Type__c.contains(u.contact.Account.type)))
                   && (string.isBlank(f.Account_Specialization__c)  || (f.Account_Specialization__c.contains(FileSharingTriggerHandler.checkAccountSpecializationRPSP(u)) || f.Account_Specialization__c.contains(FileSharingTriggerHandler.checkAccountSpecializationRASP(u))))
                   && (string.isBlank(f.Area__c)  || (!string.isBlank(u.contact.Account.ETM_Area__c) && f.Area__c.contains(u.contact.Account.ETM_Area__c)))
                   && (string.isBlank(f.Primary_Role__c) || (!string.isBlank(u.Contact.Primary_Role__c) && f.Primary_Role__c.contains(u.Contact.Primary_Role__c)))
                   && (string.isBlank(f.Theatre__c) || (!string.isBlank(u.contact.Theatre__c) && f.Theatre__c.contains(u.Contact.Theatre__c)))
                   && (string.isBlank(f.AccountIds__c) || (!string.isBlank(u.contact.AccountId) && ((!f.Exclude_Account_Name__c && f.AccountIds__c.contains(u.contact.AccountId)) || (f.Exclude_Account_Name__c && !f.AccountIds__c.contains(u.contact.AccountId))) ))
                   && (string.isBlank(f.Selected_Channel_Program_Names__c) || (null != u.contact.Account.ChannelProgramName && ((!f.Exclude_Channel_Program__c && f.Selected_Channel_Program_Names__c.contains(u.contact.Account.ChannelProgramName)) || (f.Exclude_Channel_Program__c && !f.Selected_Channel_Program_Names__c.contains(u.contact.Account.ChannelProgramName))) ))
                   && (string.isBlank(f.Selected_Channel_Program_Level_Names__c) || (null != u.contact.Account.ChannelProgramLevelName && ((!f.Exclude_Channel_Program_Level__c && f.Selected_Channel_Program_Level_Names__c.contains(u.contact.Account.ChannelProgramLevelName)) || (f.Exclude_Channel_Program_Level__c && !f.Selected_Channel_Program_Level_Names__c.contains(u.contact.Account.ChannelProgramLevelName))) )) ){
                       if(fileUserMap.isEmpty() || !fileUserMap.containsKey(f.Id))
                            fileUserMap.put(f.Id, new Set<Id>());
                       fileUserMap.get(f.Id).add(u.Id);
                   }
            }
        }
        for(Id recId : fileUserMap.keyset()){
            if(fileUserShareMap.isEmpty() || !fileUserShareMap.containsKey(recId))
                fileUserShareMap.put(recId, new List<File_Sharing__share>());
             fileUserShareMap.get(recId).addAll(FileSharingTriggerHandler.createShareRecords(recId,fileUserMap.get(recId)));    
        }
        try{
            if(!fileUserShareMap.isEmpty()){
                PC_FileSharing_ShareBatchController batch = new PC_FileSharing_ShareBatchController(fileUserShareMap);
                Database.executeBatch(batch,1); //To create FileSharing share records
            }
        }catch(Exception e){
            System.debug('@@ Exception occurred '+e.getMessage()+' at line '+e.getLineNumber());
        }
    }
    
    public static void deleteApexSharing(List<File_Sharing__c> newList){
        delete [select Id from File_Sharing__share where ParentId IN: newList];
    }
}